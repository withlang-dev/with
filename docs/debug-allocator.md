# Debug Allocator — native, zero-C memory-error instrument

Status: design + first cut. Audience: compiler/runtime contributors.

## Why this exists

Drop/lifetime bugs in compiled With programs — double-free, use-after-free, leak —
were being diagnosed by *characterizing from black-box run-counts*: run a repro, read the
exit count, guess the mechanism. On the #606 inline-drop-field leak that produced four
contradictory characterizations before the truth settled. The cure is an instrument that
**narrates the allocator's own behavior** at the instruction level: which buffer was
allocated where, freed where, freed again where, or never freed.

## Why not AddressSanitizer (and why the answer is permanent)

The With runtime is a **custom slab allocator**: it `rt_mmap`s anonymous pages once and
hands out size-classed sub-blocks from inside them (`rt_alloc` / `free_small_block` in
`rt/rt_core.w`). It never calls libc `malloc`/`free`.

ASan derives its power from interposing libc `malloc`/`free` and redzoning each allocation
in shadow memory. To ASan, our whole mmap region is **one opaque blob** — it cannot see the
thousands of logical sub-allocations inside it, so a double-free of a sub-block is invisible
and a use-after-free reads "valid mapped memory." This was confirmed by linking a known
double-free with `-fsanitize=address`: no report.

This is not a flag we forgot — it is architectural, and it collides with a **hard project
constraint**:

> **With is 100% self-hosted: zero C in the compiler. With + inline asm + syscalls only.**
> This is not a debug-build exception.

That constraint settles the design space permanently:

- **Route allocations through libc `malloc`/`free` so ASan interposes them** — rejected: a
  permanent C allocator dependency.
- **Valgrind** — rejected: external C tool (and unsupported on ARM64, our primary platform).
- **Go-style ASan annotation** of the custom slab (`__asan_poison_memory_region` /
  `__asan_unpoison_memory_region` + redzones) — this is the *standard* technique for making
  a custom allocator visible to ASan, and Go does exactly it for its mspan slab. **Rejected
  as specced**, because `__asan_*` are calls into ASan's C runtime.

What the reference languages do, for the record (`.reference/`): **Rust** ships no custom
allocator (libc `System` alloc → ASan "just works") plus Miri, a separate interpreter.
**Go** annotates its custom slab for ASan (the C-calling path we forbid). **Zig** ships a
native `DebugAllocator` (`lib/std/heap/debug_allocator.zig`) — pure Zig, cross-platform, no
C — whose feature list is essentially this document: stack traces on alloc and free,
double-free reporting all three traces (alloc, first free, second free), leak detection.

The only option that is **constitutive** of the no-C goal rather than in tension with it is
a **native debug allocator written entirely in `.w`** (plus inline asm / syscalls, exactly
as the runtime already does). It is the same discipline as the runtime migration: replace a
C capability with a With one we own. We adopt the Zig model in `.w`.

## The no-C rule does NOT make ASan-compatibility impossible — only harder

If sanitizer-ecosystem interop is pursued later, it is permitted **only by no-C means**:
emit ASan's shadow-memory format with direct memory writes / inline asm (the
Zig-Valgrind-*client-request* pattern — talk to the tool via its in-memory ABI, not its C
API — adapted to ASan's shadow). The C-calling form (`__asan_poison`, linking ASan's
runtime) is **permanently out**. "ASan annotation later" survives only in its no-C form.
Do not let a future contributor read "no C" as "ASan is impossible" — it is possible, just
only the hard way.

## The payoff we get that ASan/Valgrind structurally cannot

Because we own codegen too, the ledger can eventually carry the **MIR origin of each
emitted Drop**, so a double-free abort names *which drop* double-freed — collapsing a
multi-day characterization into one line. No external sanitizer can do this. That is
**drop-origin MIR tagging**, the high-value follow-on (its own session; out of scope here).

## Architecture (first cut)

All additive to `rt/rt_core.w`; pure `.w` + inline asm.

- **Frame-pointer backtrace walker.** `rt_current_fp()` reads the frame-pointer register via
  inline asm (`asm("mov {out}, x29" ...)` on aarch64, `rbp` on x86_64; spec §16.13). The
  walk follows the fp chain with plain unsafe pointer reads (aarch64: `ret = *(fp+8);
  fp = *fp`), filling a fixed-size return-address buffer (depth-capped). Frame pointers are
  preserved (Apple arm64 ABI mandates them; no `-fomit-frame-pointer`).
- **Ledger.** A side table backed by a direct `rt_mmap` region (never recursing through the
  instrumented allocator), keyed by payload address: `{size, alloc_trace, free_trace,
  freed_flag}`. Guarded by the existing allocator lock.
- **Instrumented alloc/free.** `rt_alloc` records an entry with the alloc backtrace.
  `rt_free` looks up the entry *before* the existing ownership check: if already freed →
  **double-free**, print alloc + first-free + this-free traces and abort; else record the
  free trace and mark freed. This sees freelist double-pushes the existing
  `rt_payload_start_can_be_owned` panic can miss, and supplies the first-free site it never had.
- **Scribble on free.** Freed payloads are overwritten with a poison pattern so
  use-after-free reads corrupt loudly. (Not "never-reuse" — that would break the slab; a
  never-reuse UAF mode is a possible later refinement.)
- **Leak at exit.** `with_runtime_shutdown` (on the native `with run`/`build` exit path)
  reports every still-live ledger entry with its size and alloc backtrace. The ledger
  records an *intended* free even where the slab merely recycles via freelist, so a
  field-drop that never fires shows up as a leak-with-site, distinguished from the
  allocator's freelist recycling.

## Gating: runtime-gated, two discoverable front doors

The mechanism is a single cached bool — **runtime-gated**, not a build variant (a build
flag → comptime-define → conditional-compile path is bootstrap/fixpoint risk for no benefit
that matters here; the cost it avoids is one cached branch and a few KB of inert `.w`).
Runtime gating also means the instrument works on *any* existing binary, including release,
with no rebuild — the right shape for a tool whose purpose is to end the
rebuild-and-characterize loop.

Two front doors set the same cached bool:

- **`--debug-alloc`** — a first-class, documented CLI flag (shows in `--help`). It does not
  thread a comptime define; on `with run` it simply sets `WITH_DEBUG_ALLOC=1` in the child's
  environment before exec, which the child's runtime reads.
- **`WITH_DEBUG_ALLOC`** — the env var, for the harness driver and for toggling an
  already-built binary without re-launching.

The gate is read **once and cached** (never `getenv` per allocation — that would be a
hot-path regression fixpoint cannot catch). When off, the cost is one cached-bool branch in
the alloc/free path; the dormant instrumentation is byte-identical at build time (the build
never sets the env), so fixpoint is unaffected.

**General principle this establishes:** diagnostic capabilities get a discoverable CLI flag
*even when runtime-gated* — mechanism (runtime switch) and discoverability (a `--help` flag)
are independent axes.

## Harness driver

`tools/debug_drop.w` (pure `.w`, no shell script): builds and runs a repro under the debug
allocator, parses the ledger/abort/leak output into a verdict, and — for the codegen branch
— emits a **plain-text lldb command file** (the lldb on the dev box has no script
interpreter, so no Python) and runs `lldb --batch` on the compiler to surface the exact
`mir_emit_drop_fields_ptr` branch that routes an inline-drop field to the no-free path.

## Known first-cut limitations

- **Leak-report noise.** The runtime intentionally never-frees some allocations (interned
  strings, arg buffers), so the raw leak list has a baseline. Each leak prints its alloc
  backtrace; the driver symbolizes and filters to blocks whose alloc site resolves into the
  repro. A built-in "user-frame filter" is an easy follow-on.
- **Platform.** Frame-pointer walking is reliable on Darwin arm64 (the primary platform);
  Linux x86_64 may omit frame pointers at `-O1`/`-O2`. Treat Linux fp-walk as best-effort
  until addressed.
- **Abnormal exit.** Leak-at-exit fires on normal termination via `with_runtime_shutdown`;
  exits via `rt_exit`/panic skip the report.

## Follow-ons (not in the first cut)

- Drop-origin MIR tagging (the abort names *which* drop) — the highest-value next step.
- A user-frame filter for clean leak attribution.
- No-C ASan-shadow emission for sanitizer-ecosystem interop (the hard-way path above).
- Never-reuse-address UAF mode.
