# Debug Allocator — native, zero-C memory-error instrument

Status: implemented. Audience: compiler/runtime contributors.

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

Because we own codegen too, the ledger carries the **MIR origin of each emitted Drop**, so
a double-free abort names *which drop* freed the block first and which drop freed it again
-- collapsing a multi-day characterization into one line. No external sanitizer can do
this.

## Architecture: detection in-process, origin tags in reports

All additive to `rt/rt_core.w`; pure `.w`.

> **Why no in-process backtraces.** The original design captured alloc/free backtraces by
> walking the frame-pointer chain (read `x29` via inline asm, follow `*(fp)` / `*(fp+8)`).
> Verified by running, this **does not work** in the current With codegen: `x29` does not
> point to a standard aarch64 frame record (reading `[fp]`/`[fp+8]` yields 0 even inside a
> framed, `@[noinline]` function). With's codegen does not maintain a walkable fp chain at
> the opt levels `with run` uses. Rather than chase a codegen change (out of scope), the
> first cut split the work: the **ledger does detection in-process** (cheap, robust, pure
> `.w`), and **lldb resolves source sites out-of-process**, conditioned on the address the
> ledger reports — lldb uses real DWARF/compact-unwind unwinding that actually works.
> Compiler-emitted Drop sites now also carry MIR-origin tags directly into the free path,
> so double-free reports name both drops without requiring unwinding.

- **Ledger.** A side table backed by a direct `rt_mmap` region (never recursing through the
  instrumented allocator), an open-addressing hash keyed by payload address:
  `{addr, size, freed_flag, alloc_origin, first_drop_ptr, first_drop_len, root_flag,
  root_reason}`. Guarded by the existing allocator lock. The gate is read once via the
  non-allocating `rt_getenv` (`with_getenv_str` would deadlock the non-reentrant allocator
  lock) and cached.
- **Instrumented alloc/free.** `rt_alloc` records (or, on address reuse, resets) an entry.
  Tagged front doors such as `with_alloc`, Vec buffer growth, channel allocation, and fiber
  record allocation store a coarse allocation-origin token. `rt_free` looks up the entry
  *before* the existing ownership check: if already freed -> **double-free**, print
  `debug-alloc: DOUBLE FREE addr=<a> size=<n> origin=<site> first_drop=<tag> second_drop=<tag>`
  and abort (exit 134); else mark freed and remember the first drop tag. This sees freelist
  double-pushes the existing `rt_payload_start_can_be_owned` panic can miss.
- **Scribble on free (opt-in: `WITH_DEBUG_ALLOC_SCRIBBLE`).** Freed small payloads are
  overwritten with `0xDE` so use-after-free reads corrupt loudly. It is **off by default**
  because, for a `Vec[Drop]` buffer, poisoning the freed payload turns a subsequent
  double-drop's element read into a use-after-free crash *before* the ledger reports the
  buffer's double-free — masking the clean verdict. Enable it to hunt use-after-free
  specifically. The freelist link lives in the header word (`payload-16`), untouched.
  (Not "never-reuse" — that would break the slab; a never-reuse UAF mode is a later refinement.)
- **Leak at exit.** `with_runtime_shutdown` (on the native `with run`/`build` exit path)
  prints `debug-alloc: LEAK addr=<a> size=<n> origin=<site>` for every still-live entry,
  then a `leak count=<k>`. Runtime code can call
  `with_debug_alloc_mark_root(ptr, reason_ptr, reason_len)` to label an intentional
  process-lifetime root. `WITH_DEBUG_ALLOC_FILTER=all|non-root|roots` controls whether
  all leaks, only non-root leaks, or only root leaks are printed. A field-drop that never
  fires shows up as a live non-root entry (the slab's freelist recycle is recorded as a
  free, so it is *not* a false leak).
- **Site resolution (harness).** The in-process report names the coarse origin token
  directly, and double-free reports name first/second compiler Drop tags when the free came
  through generated drop code. When an exact source line is needed, the driver can still run
  lldb conditioned on the address (break on `rt_alloc` returning it / on `rt_free` /
  `with_vec_free` taking it, `bt` at each) to name precise alloc and free call sites.

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

Leak filtering is controlled separately by **`--debug-alloc-filter=<mode>`** or
`WITH_DEBUG_ALLOC_FILTER`, where mode is `all`, `non-root`, or `roots`. The default is
`all`. Use `non-root` when process-lifetime roots would otherwise hide a real leak.

The gate is read **once and cached** (never `getenv` per allocation — that would be a
hot-path regression fixpoint cannot catch). When off, the cost is one cached-bool branch in
the alloc/free path; the dormant instrumentation is byte-identical at build time (the build
never sets the env), so fixpoint is unaffected.

**General principle this establishes:** diagnostic capabilities get a discoverable CLI flag
*even when runtime-gated* — mechanism (runtime switch) and discoverability (a `--help` flag)
are independent axes.

## Harness driver

`tools/debug_drop.w` (pure `.w`, no shell script): runs a repro or fixture corpus under the
debug allocator and parses the ledger/abort/leak output into a verdict. The
`:debug-alloc-tests` target builds it to `out/debug-alloc-tests/debug_drop` and runs it in
`check` mode over the committed corpus. For one-off repros:

```sh
./out/release/bin/with build tools/debug_drop.w -o out/debug-alloc-tests/debug_drop
out/debug-alloc-tests/debug_drop run ./out/release/bin/with repro.w
```

Source sites are resolved separately with lldb command files (the lldb on the dev box has
no script interpreter, so no Python): `tools/debug_drop_sites.lldb` for alloc/free sites and
`tools/debug_drop_fields.lldb` when the allocator verdict points at a drop/codegen bug.

`test/debug_alloc/` is also the regression gate for #607. Its inline-drop field
fixtures must all report `leak count=0` and never `DOUBLE FREE`, including the
field-receiver push-tail and field-chaining cases that the ordinary floor cannot
see. `da_manual_double_free` intentionally remains a `DOUBLE FREE` fixture, and
`da_drop_origin_double_free` intentionally checks that generated drops report
`first_drop=`/`second_drop=` tags. `da_root_filter` marks a live allocation as a root and
runs under `//! debug-alloc-filter: non-root`, proving root leaks can be suppressed without
suppressing ordinary leaks. `da_pod_vec` intentionally remains `leak count=1` for #608.

## Known first-cut limitations

- **Leak-report noise.** The runtime intentionally never-frees some allocations (interned
  strings, arg buffers). Marked roots plus `--debug-alloc-filter=non-root` suppress known
  process-lifetime roots, but unmarked roots still appear in the raw leak list until they
  are classified.
- **Exact source sites still need a second (lldb) pass.** The ledger names the *block*
  (address + size), the *verdict* (double-free / leak), the allocation-origin token, and
  generated Drop tags in-process; exact source lines still come from the harness's lldb pass
  conditioned on that address. In-process backtraces are not used (see the note above).
- **Abnormal exit.** Leak-at-exit fires on normal termination via `with_runtime_shutdown`;
  exits via `rt_exit`/panic skip the report.

## Follow-ons (not in the first cut)

- A user-frame filter for clean leak attribution.
- No-C ASan-shadow emission for sanitizer-ecosystem interop (the hard-way path above).
- Never-reuse-address UAF mode.
