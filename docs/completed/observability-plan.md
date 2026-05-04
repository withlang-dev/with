# Compiler Instrumentation / Observability Plan

## Goal

Add low-overhead, source-level instrumentation to the With compiler so we can:

- identify which pipeline phases dominate compile time
- correlate time with work size
- drill down from coarse phase timing into specific bottlenecks
- keep profiling off by default and cheap when disabled

This plan is intentionally source-oriented. It complements external sampling profilers, but it does not depend on them.

---

## Guiding Principles

1. Start coarse, then refine.
2. Record counts next to timings.
3. Keep instrumentation opt-in.
4. Do not distort hot loops with excessive logging.
5. Separate compiler time from external tool time.

The first pass should answer:

- frontend or backend?
- LLVM IR generation or LLVM optimization?
- import resolution or semantic analysis?
- object emission or external linking?

---

## Existing Hooks To Reuse

The compiler already has environment-variable-driven debug plumbing in:

- `src/compiler/Compilation.w`
- `src/compiler/Frontend.w`
- `src/compiler/Backend.w`
- `src/compiler/Zcu.w`

The runtime already has a monotonic timer implementation:

- `runtime/helpers.c`: `with_clock_nanos()`

First implementation step:

- expose `with_clock_nanos()` in `runtime/with_runtime.h`
- `extern` it where instrumentation is needed

This is better than inventing a second timing primitive.

---

## Phase 1: Coarse Pipeline Timers

Add one cached `WITH_PROFILE=1` switch and measure the major compilation phases.

### Frontend

Instrument `Zcu.compile_file_frontend` and `Zcu.compile_source_frontend` in:

- `src/compiler/Frontend.w`

Measure these phases separately:

- file read
- lex + parse
- resolve
- import expansion
- `c_import` expansion
- sema

### MIR / Async Lowering

Instrument in:

- `src/compiler/Compilation.w`

Measure separately:

- MIR lowering
- async lowering

### Backend

Instrument in:

- `src/compiler/Backend.w`

Measure separately:

- LLVM module generation
- LLVM optimization
- object emission

### Link

Instrument in:

- `src/compiler/Compilation.w`
- `src/compiler/Link.w`

Measure separately:

- linker invocation
- `dsymutil`

The output should make external tool time visible instead of hiding it under "build".

---

## Phase 2: Add Work-Size Counters

Every coarse timer should report scale so timings are interpretable.

Recommended counters:

- source bytes
- token count
- top-level decl count
- AST node count
- imported module count
- `c_import` count
- `c_import` cache hit count
- `c_import` cache miss count
- type count after sema
- MIR body count
- MIR basic block count
- MIR instruction count
- emitted LLVM function count

Examples:

- parse time with token count
- resolve time with module count
- sema time with decl/type count
- codegen time with MIR/LLVM function counts

Without counts, a slow phase is hard to normalize across different inputs.

---

## Phase 3: Hierarchical Self-Profile Scopes

Once coarse timing identifies the slow stage, add nested scopes.

Suggested scope tree:

- `frontend.read`
- `frontend.parse`
- `frontend.resolve`
- `frontend.imports`
- `frontend.c_import`
- `frontend.sema`
- `mir.lower`
- `async.lower`
- `llvm.gen_module`
- `llvm.optimize`
- `llvm.emit_object`
- `link.invoke`
- `link.dsymutil`

Desired metrics per scope:

- total time
- self time
- call count
- optional attached counters

Output should be sorted by hottest scope.

---

## Phase 4: Per-Module Breakdown

For import-heavy compiles, global phase timing is not enough.

Add per-module timing in:

- `src/Resolve.w`
- `src/compiler/Frontend.w`

Track, per imported module:

- read time
- parse time
- resolve time
- sema time if applicable
- module path
- source bytes
- decl count

Report top N slowest modules.

This is especially useful for:

- pathological import trees
- repeated parsing of large support modules
- slow generated code

---

## Phase 5: `c_import` / Clang Observability

`c_import` should have its own visibility because it can dominate compile time.

Instrument around:

- `process_c_import`
- in-memory cache lookup/store
- filesystem cache lookup/store

Track:

- number of `c_import` declarations
- cache hit/miss counts
- total time spent in libclang
- total time spent parsing synthetic output
- top slowest headers

This will tell us whether the bottleneck is:

- header compilation
- cache misses
- synthetic parse cost

---

## Phase 6: Hot Data-Structure Counters

Only do this after phase timing points at a specific subsystem.

Candidates:

- `HashMap` lookup count
- `HashMap` miss count
- `HashMap` resize count
- `Vec` growth count
- intern pool symbol growth
- repeated string resolution counts

Best targets:

- sema lookups
- resolve import/path lookups
- c_import caches
- AST extra-table growth

This is for answering "why is sema slow?" or "why is resolve allocating so much?" after the coarse profile says where to look.

---

## Output Design

### Human-readable stderr summary

Use a compact table when `WITH_PROFILE=1`:

```text
[profile] frontend.read          3.1 ms  bytes=84213
[profile] frontend.parse        28.4 ms  tokens=15422 decls=318
[profile] frontend.resolve      41.7 ms  modules=27
[profile] frontend.c_import    112.9 ms  imports=3 hits=2 misses=1
[profile] frontend.sema        186.2 ms  types=941
[profile] mir.lower            37.5 ms   bodies=412 blocks=6211
[profile] llvm.gen_module      221.4 ms  funcs=487
[profile] llvm.optimize        604.8 ms
[profile] llvm.emit_object      84.0 ms
[profile] link                 119.6 ms
```

### Optional structured output

Add:

- `WITH_PROFILE_JSON=/tmp/profile.json`

Emit either:

- a flat JSON summary
- or Chrome trace format for nested scope visualization

Structured output is useful once the human-readable table identifies the hot area.

---

## Control Surface

Recommended env vars:

- `WITH_PROFILE=1`
- `WITH_PROFILE_TOP=20`
- `WITH_PROFILE_JSON=/tmp/profile.json`

Keep the first version env-only. That avoids immediate CLI churn and matches existing debug toggles.

Later, if this becomes stable, consider:

- `with build --profile`

But that is not required for the initial rollout.

---

## Implementation Shape

Recommended internal model:

- a cached profile-enabled flag
- a global or compilation-owned profile state
- begin/end scope helpers
- counters attached to named scopes

Possible helper shape:

- `profile_enabled()`
- `profile_scope_begin(name)`
- `profile_scope_end(handle)`
- `profile_count_add(name, key, delta)`
- `profile_dump()`

Where possible, use `defer` to ensure scope closure.

Example pattern:

```with
let scope = profile_scope_begin("frontend.resolve")
defer profile_scope_end(scope)
```

---

## Where To Start In This Codebase

High-value insertion points:

- `src/compiler/Frontend.w`
- `src/compiler/Compilation.w`
- `src/compiler/Backend.w`
- `src/compiler/Link.w`
- `src/Resolve.w`

Start with:

1. frontend coarse timing
2. backend coarse timing
3. linker timing
4. `c_import` timing

That will probably explain most real-world self-compile time without any deeper instrumentation.

---

## What Not To Do First

Avoid these in the first pass:

- per-node timers inside parser/sema/codegen hot loops
- logging every AST/MIR/LLVM entity
- instrumentation spread across too many files at once
- micro-optimizing before phase timing exists

Those approaches create noise before they create understanding.

---

## Recommended Rollout Order

1. Expose `with_clock_nanos()`.
2. Add `WITH_PROFILE=1` and coarse phase timers.
3. Add work-size counters.
4. Add per-module import timing.
5. Add `c_import` timing and cache metrics.
6. Add hierarchical scopes inside the hottest phase.
7. Add optional JSON/trace output.

---

## Success Criteria

This work is successful when a self-compile or benchmark build can answer, with data:

- which phase is hottest
- which modules are hottest
- whether time scales with bytes, decls, types, or MIR size
- whether the hot time is in With code, LLVM optimization, or external tools
- whether cache hits are working as expected

At that point, optimization work becomes targeted instead of speculative.
