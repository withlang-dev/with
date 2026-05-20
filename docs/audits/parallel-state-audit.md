# Parallel State Audit

Status: pre-Phase-D audit complete.

This audit identifies mutable state that matters for D6 parallel workspaces.
It does not implement parallelism. Its job is to separate state that is
already per-compilation from state that must be isolated, locked, or removed
before multiple workspaces can run concurrently in one compiler process.

## Summary

The current compiler is mostly shaped around explicit per-compilation owners:
`Zcu` owns semantic state, diagnostics, import state, MIR sidecars, and the
project config; `Sema` and `Codegen` are instantiated per pipeline run. That is
the right baseline for D6.

The main blockers are not in ordinary semantic state. They are:

- process-global runtime state, especially allocator, fiber scheduler, env, and
  bridge scratch buffers
- C import and migration globals in `CImport.w`, `CiMigrate.w`, and
  `rt/clang_bridge.w`
- generated-runner capability dispatch that mutates process environment
- any future attempt to share parsed modules, intern pools, or embedded stdlib
  caches without deterministic ownership and locking rules

D6 should start with one `Zcu`, one `Sema`, one MIR module set, one `Codegen`,
and one LLVM context per workspace. Shared caches can come later, only when the
cache is immutable after publication or protected by a deterministic protocol.

## State Inventory

| State | Evidence | Current Ownership | D6 Strategy | Complexity |
| --- | --- | --- | --- | --- |
| `Zcu` compilation state | `src/compiler/Zcu.w:42` defines `pool`, diagnostics, import state, typed sidecars, MIR dumps, link libs, and project config; `Zcu.init` creates fresh instances at `src/compiler/Zcu.w:82`. | Per compilation. | One `Zcu` per workspace. Do not share mutable `Zcu` fields across workspaces. | Medium |
| Intern pools | `Zcu` owns `pool` and `frontend_pool` at `src/compiler/Zcu.w:43`; `InternPool` is a heap-backed handle at `src/compiler/foundation/InternPool.w:57`. | Per `Zcu`/`Sema`, not currently process-global. Internal ids are monotonic allocation-order ids. | Keep per workspace initially. If a shared intern cache is introduced, ids that affect output must be content-stable, not allocation-order-stable. | Medium |
| Sema state | `src/Sema.w:186` defines a large `Sema` value with pool, diagnostics, scopes, typed sidecars, generic caches, borrow state, module mappings, and C import fields. | Per semantic pass, stored back into `Zcu.last_sema`. | Keep one `Sema` instance per workspace/pass. Generic caches must not be shared until cache keys and publication are deterministic. | Medium |
| Parsed/imported module state | `Zcu.imported_paths`, `decl_source_paths`, `c_import_cache_*`, and `last_resolved` live in `src/compiler/Zcu.w:46`; dependency ordering uses per-call maps in `src/compiler/Frontend.w:1509`. | Per `Zcu`. | Keep per workspace. A future parsed-stdlib cache must publish immutable parse results only, never mutable resolution state. | Medium |
| Embedded stdlib source | `src/compiler/EmbeddedStdlib.w:8` delegates to generated immutable source data; `Zcu.source_for_file_id_frontend` reads embedded text at `src/compiler/Zcu.w:242`. | Read-only data accessor. | Safe to share as immutable data. If caching decoded/parsed stdlib modules is added, make the cache immutable-after-publish. | Low |
| Diagnostics | `Zcu.diagnostics` is per `Zcu` at `src/compiler/Zcu.w:45`; rendering writes through `with_eprint` in `src/compiler/Zcu.w:247`. | Diagnostic collection is per compilation; rendering is process output. | Collect per workspace, then serialize rendering in deterministic workspace/phase order. | Medium |
| LLVM codegen state | `Codegen` owns `context`, `llmod`, `builder`, target machine, and many caches at `src/Codegen.w:351`; `Codegen.init_with_opt` creates a fresh LLVM context/module at `src/Codegen.w:757`. | Per codegen instance. LLVM native target init and bridge scratch buffers are process-global. | One LLVM context/module/builder per workspace. Guard one-time LLVM target init if LLVM is called from multiple host threads. | Large |
| LLVM bridge string scratch | `rt/llvm_bridge.w:344` uses global `cstr_bufs` and `cstr_idx` for `to_cstr`. | Process-global rotating buffers. | Replace with caller-owned buffers, thread-local scratch, or a lock before concurrent LLVM bridge calls. | Medium |
| C import bridge globals | `rt/clang_bridge.w:568` stores emitted names, include paths, SDK/resource-dir caches, and counters globally. | Process-global C import session support. | Move into explicit session handles or serialize C import work. Required before parallel C import/migration. | Large |
| C import/migrator globals | `src/CImport.w:72` realpath cache; `src/CImport.w:10957` macro/session/current-input/temp/bail/stats globals; `src/CiMigrate.w:59` shared-def state and include paths; `src/CiMigrate.w:1519` migration options and counters. | Process-global, mutable, reused across files. | Move into `CiSession`/`MigrateSession` objects or declare C migration single-threaded until that refactor lands. | Large |
| Runtime allocator | `rt/rt_core.w:280` global freelists and `rt/rt_core.w:291` global slab pointer. | Process-global allocator state. | If D6 parallelism uses OS threads, allocator needs locking, thread-local arenas, or a per-workspace arena. Fiber-only interleaving on one thread is less risky but still shares retention. | Large |
| Fiber scheduler | `rt/fiber_core_darwin.w:75` global current fiber, scheduler context, queues, pools, and counters. | Single process-global scheduler. | D6 cannot assume independent schedulers unless scheduler state becomes per scheduler/workspace or host parallelism avoids fibers. | Large |
| Process env and capability tokens | `src/main.w:844` and `src/compiler/Compilation.w:599` set `WITH_TOOL_CAPABILITY_TOKEN`; `lib/std/build.w:424` temporarily clears/restores env around process calls. | Process-global environment mutation. | D1 should remove generated runner/env-token dispatch. Before D6, process execution must pass env per child without mutating parent env. | Large |
| Process cwd/stdout/stderr | Process execution APIs in `lib/std/build.w:455` and related methods call runtime exec helpers; diagnostics use `with_eprint`. | Process-global output streams; cwd is per exec call where supported. | Make process invocation fully parameterized by cwd/env/stdin/stdout/stderr. Serialize direct console output or capture per workspace. | Medium |
| ToolFs write scopes | `ToolFs` carries root and write scope at `lib/std/build.w:86`; action targets carry `write_scopes` at `lib/std/build.w:148`. | Capability-local state, copied into actions. | Safe as a per-action capability model. Parallel actions need shared filesystem conflict detection by declared outputs/scopes. | Medium |
| Build graph ordering | Target closure selection is serial and deterministic through `BuildGraphModel.w`; selected names are appended after dependencies at `src/BuildGraphModel.w:363`. | Single-threaded executor. | D6 build execution can parallelize ready nodes only after dependency order and output conflicts are explicit. Final diagnostic/output order must be deterministic. | Medium |
| HashMap usage | Compiler state contains many `HashMap` fields, but no broad `.keys()`/`.values()` output iteration showed up in the quick audit. Some ordering algorithms keep side `Vec`s, e.g. `first_seen_paths` in `src/compiler/Frontend.w:1529`. | HashMaps are mostly lookup caches. | Continue to avoid emitting output by iterating map storage. For any shared cache, preserve insertion-order side vectors when deterministic output needs iteration. | Medium |
| Frontend compiler fingerprint cache | `src/compiler/Frontend.w:30` stores a global readiness bit and fingerprint string. | Process-global lazy cache of current compiler binary hash. | Safe if immutable after first write and all workspaces agree on compiler binary. Add a once guard if host threads are introduced. | Low |
| Generated temp names | Build and hook runners use `with_getpid()` and `with_clock_nanos()` at `src/main.w:823` and `src/compiler/Compilation.w:567`. | Process-global time/pid based names. | D1 should remove generated runner binaries for capability execution. Remaining temp APIs should use workspace/action ids and declared scratch roots. | Medium |

## HashMap Determinism

The quick source audit did not find a central pattern of iterating `HashMap`
keys or values for emitted compiler output. The dominant pattern is lookup plus
side vectors for deterministic iteration. That is the right shape.

The D6 rule should be explicit: hash maps may be used for lookup caches, but
observable output must be ordered by AST order, source order, dependency order,
or a separately maintained insertion-order vector. Parallel cache publication
must not let pointer addresses, thread scheduling, or hash bucket order affect
symbol names, diagnostics, object file contents, or generated build graphs.

## Required Work Before Parallel Workspaces

1. Replace generated-runner/env-token capability dispatch with in-process
   capability invocation or another boundary-safe mechanism that does not mutate
   process environment.
2. Keep `Zcu`, `Sema`, MIR, and `Codegen` ownership per workspace. Do not
   introduce shared mutable compiler caches during D1-D5.
3. Decide whether D6 excludes C import/migration from parallel execution. If it
   does not, move the `CImport.w`, `CiMigrate.w`, and `rt/clang_bridge.w` globals
   into explicit session state first.
4. Make runtime and bridge state safe for the chosen host parallelism model:
   single-threaded fibers, OS threads, or child processes have different
   requirements.
5. Define deterministic output ordering for diagnostics, generated sources,
   link libraries, object emission, and build action logs.
6. Add a stress test that runs two independent workspaces concurrently once D6
   exists. One should include ordinary stdlib imports; a later version should
   include C import/migration only after session state is fixed.

## Non-Goals

This audit does not require solving C import global state before D1. It also
does not require making the allocator or fiber scheduler thread-safe before
D1-D5. Those are D6 blockers, not prerequisites for the initial compiler as
library work.
