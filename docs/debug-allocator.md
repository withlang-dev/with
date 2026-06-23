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

## Architecture (first cut): detection in-process, sites via lldb

All additive to `rt/rt_core.w`; pure `.w`.

> **Why no in-process backtraces.** The original design captured alloc/free backtraces by
> walking the frame-pointer chain (read `x29` via inline asm, follow `*(fp)` / `*(fp+8)`).
> Verified by running, this **does not work** in the current With codegen: `x29` does not
> point to a standard aarch64 frame record (reading `[fp]`/`[fp+8]` yields 0 even inside a
> framed, `@[noinline]` function). With's codegen does not maintain a walkable fp chain at
> the opt levels `with run` uses. Rather than chase a codegen change (out of scope), the
> first cut splits the work: the **ledger does detection in-process** (cheap, robust, pure
> `.w`), and **lldb resolves source sites out-of-process**, conditioned on the address the
> ledger reports — lldb uses real DWARF/compact-unwind unwinding that actually works. This
> is a cleaner separation, and drop-origin MIR tagging (the follow-on) will give precise
> sites natively without any unwinding at all.

- **Ledger.** A side table backed by a direct `rt_mmap` region (never recursing through the
  instrumented allocator), an open-addressing hash keyed by payload address:
  `{addr, size, freed_flag}`. Guarded by the existing allocator lock. The gate is read once
  via the non-allocating `rt_getenv` (`with_getenv_str` would deadlock the non-reentrant
  allocator lock) and cached.
- **Instrumented alloc/free.** `rt_alloc` records (or, on address reuse, resets) an entry.
  `rt_free` looks up the entry *before* the existing ownership check: if already freed →
  **double-free**, print `debug-alloc: DOUBLE FREE addr=<a> size=<n>` and abort (exit 134);
  else mark freed. This sees freelist double-pushes the existing
  `rt_payload_start_can_be_owned` panic can miss.
- **Scribble on free (opt-in: `WITH_DEBUG_ALLOC_SCRIBBLE`).** Freed small payloads are
  overwritten with `0xDE` so use-after-free reads corrupt loudly. It is **off by default**
  because, for a `Vec[Drop]` buffer, poisoning the freed payload turns a subsequent
  double-drop's element read into a use-after-free crash *before* the ledger reports the
  buffer's double-free — masking the clean verdict. Enable it to hunt use-after-free
  specifically. The freelist link lives in the header word (`payload-16`), untouched.
  (Not "never-reuse" — that would break the slab; a never-reuse UAF mode is a later refinement.)
- **Leak at exit.** `with_runtime_shutdown` (on the native `with run`/`build` exit path)
  prints `debug-alloc: LEAK addr=<a> size=<n>` for every still-live entry, then a
  `leak count=<k>`. A field-drop that never fires shows up as a live entry (the slab's
  freelist recycle is recorded as a free, so it is *not* a false leak).
- **Site resolution (harness).** Given the address from a double-free abort or a leak line,
  the driver runs lldb conditioned on that address (break on `rt_alloc` returning it / on
  `rt_free` / `with_vec_free` taking it, `bt` at each) to name the alloc and free call sites.

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
allocator, parses the ledger/abort/leak output into a verdict, then drives lldb (plain
command files — the lldb on the dev box has no script interpreter, so no Python) for two
purposes: (1) resolve the alloc/free **source sites** for the address the ledger flagged,
and (2) for the codegen branch, run `lldb --batch` on the compiler to surface the exact
`mir_emit_drop_fields_ptr` branch that routes an inline-drop field to the no-free path.

## Known first-cut limitations

- **Leak-report noise.** The runtime intentionally never-frees some allocations (interned
  strings, arg buffers), so the raw leak list has a baseline. Each leak prints its alloc
  backtrace; the driver symbolizes and filters to blocks whose alloc site resolves into the
  repro. A built-in "user-frame filter" is an easy follow-on.
- **Sites need a second (lldb) pass.** The ledger names the *block* (address + size) and the
  *verdict* (double-free / leak) in-process; the *source sites* come from the harness's lldb
  pass conditioned on that address. In-process backtraces are not used (see the note above).
- **Abnormal exit.** Leak-at-exit fires on normal termination via `with_runtime_shutdown`;
  exits via `rt_exit`/panic skip the report.

## Follow-ons (not in the first cut)

- Drop-origin MIR tagging (the abort names *which* drop) — the highest-value next step.
- A user-frame filter for clean leak attribution.
- No-C ASan-shadow emission for sanitizer-ecosystem interop (the hard-way path above).
- Never-reuse-address UAF mode.
