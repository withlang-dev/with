# With Jupyter Engine
## Normative architecture, semantics, protocols, debugging, and verification

**Status:** Approved architecture rulings incorporated; **not** an assertion that features are already implemented.  
**Baseline:** With repository commit `94195e2` (2026-11-27), as named in the supplied v0.17 plan.  
**Scope:** The persistent execution engine and every dependency required to run, inspect, debug, and reliably operate With code as a Jupyter kernel in v0.17.  
**Out of scope:** The v0.17 release schedule, REPL product UX, shell one-liners, game/desktop SDKs, general editor plugins, general-purpose math/jq/SQL Server initiatives, browser notebook UI, independent query-language design, and full time-travel debugging (branching timelines, `%back`/`%forward`, snapshotting/replay, and `rr` reverse-stepping — split into a separate future proposal; v0.17 retains only the identity/pinning invariants in §10).  
**Precedence:** Once accepted, this document supersedes contradictory Jupyter-engine provisions in the v0.17 release plan and the earlier broad normative addendum. It does not silently override the core With language specification. Explicit session-mode semantic rules and divergences are recorded in §2.  
**Notation:** **MUST** is mandatory; **MUST NOT** prohibited; **SHOULD** a strong default with documented reason for any exception; **MAY** optional. Rule IDs are stable references for agent tasks and conformance tests. Names of internal APIs below are conceptual unless explicitly presented as existing With CLI syntax.

---

## 1. Product contract and architectural boundary

**ENG-001 — Mission.** A Jupyter frontend MUST be able to submit independent With cells to one persistent native-code session; retain owned values, types, functions, imports, and scheduler state between executions; interact with native C libraries; receive precise protocol-compatible outputs and diagnostics; interrupt supported running computations; and inspect the session's submission history and debugger state. Executing cell N MUST NOT reexecute earlier cells implicitly.

**ENG-002 — One engine.** Jupyter is an adapter over a reusable `SessionEngine`, not an alternative language interpreter. The parser, resolver, type/ownership checker, compiler, LLVM ORC materializer, scheduler, session-frame store, diagnostic mapper, and semantic inspection APIs MUST be shared by any future REPL or notebook-file runner. The Jupyter adapter owns wire protocol, connection file, message routing, frontend-specific display, and kernelspec installation.

**ENG-003 — In-process execution.** The core engine executes LLVM ORC JIT code in the kernel process. The native execution model is deliberately in-process; arbitrary native-memory corruption, `abort()`, C-frame crashes, or native deadlock is **not** promised to be recoverable until a future out-of-process worker backend exists. Any later out-of-process execution backend MUST obey the same session-semantic interface while offering stronger isolation.

**ENG-004 — Supported platforms.** The acceptance matrix includes macOS arm64, Linux, and Windows on the architectures distributed as supported. Every claimed platform MUST pass hermetic battery checks (native JIT, structured session unwind, networking, pure-With protocol, and `libzmq` fetched via `with get`) and `uat/` interoperability checks (real JupyterLab, SQLite, and raylib); unsupported OS/ABI combinations fail with a named, actionable diagnostic. A platform cannot be advertised solely because a build succeeds.

**ENG-005 — Separation of concerns.** No notebook cell logic belongs in the ZMTP transport. No Jupyter message framing belongs in the compiler. No language semantics may depend on a particular GUI frontend, notebook location, or editor cell ID.

### 1.1 Required modules and dependencies

```text
JupyterLab / notebook frontend
             |
     Jupyter Protocol 5.5
             |
      Kernel protocol host
      /        |         \
  ZMTP/I-O  Semantic      Display + debugger/DAP adapter
             requests               |
                \                 /
                  SessionEngine
            /       |        \
      Frontend/   Ownership/   Scheduler + session-frame store
      compiler    source map          |
            \        |              /
                LLVM ORC JIT
             /       |       \
        With runtime  C/Clang  Native libraries
                  |
       Submission & version ledger (TT-030)
```

**ENG-006 — Dependencies that are in scope.** Session-scoped compiler state; LLVM bridge and ORC; main-thread execution executor; runtime drop and structured session unwinding/cancellation; C import/migration (`c contract` / `c facts`) and native-symbol resolution; `std.net` byte I/O/poll; pure-With ZMTP; Jupyter message implementation; parser-backed completeness and read-only semantic inspection; `Present`/MIME display; local kernelspec installation and `with kernel status` diagnostics; source/debug metadata; immutable submission/version identity hooks (`TT-030`); corresponding hermetic battery and `uat/` conformance tooling.

**ENG-007 — Features that consume the engine but do not define it.** A future `with repl`, notebook conversion utility, text-notebook editor integration, game SDK, `from` query optimizer, database backend, or future time-travel/reverse-debugging proposal may consume this API. Their distinct semantics and implementation are **not** prerequisites for this specification. `%get` is a strict 1:1 passthrough to `with get`, not a second package manager or a license to redesign package management here.

## 2. Locked decisions and explicit session-mode semantic rules

Every normative decision below is locked against `docs/mission.md`, citing its governing Law(s) and answering each Law's *Test* question verbatim. Explicit session-mode semantic rules that differ from ordinary AOT compilation — **session-frame locals**, **structured session unwinding**, **`let` rebinding**, and **cross-cell indirection** — are explicitly enumerated here.

### 2.1 Explicit session-mode semantic rules

1. **Session-frame locals (preserving D52 for module globals):** Top-level `let`/`var` bindings in interactive submissions are modeled as **session-frame locals**, not module globals. Ordinary module globals remain governed strictly by **D52** (never moved out). Session-frame locals follow function-local ownership, move, drop, and provenance rules across submissions without weakening D52.
2. **Structured session unwinding (no native Itanium/SEH exception tables for v0.17):** Session-compiled With code reuses the compiler-generated structured unwinding path that task cancellation already uses so panics and cooperative interrupts unwind cleanly and run drops in reverse construction order across macOS, Linux, and Windows. Native Itanium/SEH exception unwinding (`__unwind_info`, `.eh_frame`, `.pdata` personality/landingpads) is **not** built for v0.17. C-frame crashes remain process-fatal until out-of-process worker recovery exists.
3. **`let` rebinding at session top level:** Within a submission or function body, `let` remains immutable. A subsequent top-level submission may explicitly rebind an existing `let` name by introducing a new binding generation; the previous live value is dropped only after the new initializer succeeds.
4. **Cross-cell indirection (`DEF-002`):** Calls crossing replaceable session-defined function boundaries use stable versioned dispatch indirection at both `-O1` and release optimization so later same-ABI redefinitions take effect for previously compiled callers and stored safe function handles. `std` and package bundles remain direct-called unless explicitly redefined in the session.

### 2.2 Locked decisions (mission-tested)

| ID | Decision to lock | Governing Law(s) & verbatim *Test* answer |
|---|---|---|
| DEC-01 | Compile/link errors have zero user-visible execution effect. A runtime panic or interrupt unwinds cleanly via structured session unwinding and does **not** roll back completed effects. | **Law 7** (*"did I make the success condition true by doing the work, or by redefining it?"*): Arbitrary in-process native side effects cannot be transacted; promising fake rollback would fabricate a guarantee. **Law 5** (*"does this operation create an owner the type system does not know about?"*): Preserving completed moves/drops keeps ownership tracking truthful. |
| DEC-02 | Top-level session bindings are **session-frame locals** (not module globals, preserving D52 intact for module globals), and top-level `let`/`var` rebinding is by name, not by notebook-file cell ID. | **Law 5** (*"does this operation create an owner the type system does not know about?"*): Modeling cell bindings as session-frame locals preserves exact single-owner move/drop rules without breaking D52 for module globals. **Law 1** (*"does this make the programmer state something the compiler can establish, or something with no consequence?"*): Notebook JSON cell IDs are unstable frontend metadata, never language identity. |
| DEC-03 | Incompatible type redefinition is rejected while live values or ABI dependents exist; never silently drop transitive session bindings. | **Law 5** (*"does this operation create an owner the type system does not know about?"*): Silently dropping or reinterpreting live values violates ownership and type-representation safety. **Law 7** (*"did I make the success condition true by doing the work, or by redefining it?"*): Failing with the exact dependency chain beats destructive workarounds. |
| DEC-04 | Same-ABI function replacement uses stable versioned dispatch at `-O1` and release optimization; stored safe function values follow the replacement. `std` and package bundles stay direct-called unless redefined in the session. Changing a function's signature is a **redefinition** replacing the name in session scope (no overload sets); live/earlier callers keep their pinned old version and the kernel reports which earlier functions still call the old signature. | **Law 3** (*"if deleting this downstream code could change which programs are accepted, the boundary is wrong."*): Sema owns the versioned declaration/indirection contract; codegen materializes it identically across optimization levels without inventing overload resolution. **Law 6** (*"is the programmer promising something to a reader who cannot see the body? Then spell it. Otherwise never."*): The signature remains the ABI contract; changing it replaces the binding rather than silently overloading. |
| DEC-05 | Session-mode panics and cooperative interrupts use **structured session unwinding** (reusing compiler-generated structured cancellation unwind) across macOS, Linux, and Windows rather than native Itanium/SEH exception unwinding. C-frame crashes remain process-fatal until out-of-process worker recovery. | **Law 9** (*"is this route still the unique way to say something, or a habit?"*): Reusing the existing structured unwind mechanism avoids building a second OS-specific exception runtime. **Law 7** (*"did I make the success condition true by doing the work, or by redefining it?"*): Declaring C-frame crashes unrecoverable in-process is honest rather than promising unsound cross-C unwinding. |
| DEC-06 | The persistent session compiler is versioned; compilation and introspection operate on coherent immutable snapshots. | **Law 3** (*"if deleting this downstream code could change which programs are accepted, the boundary is wrong."*): Single-owner immutable snapshots keep Sema, MIR, codegen, and read-only inspection consistent without re-deriving facts. |
| DEC-07 | Only controlled With state is session-isolated. Native process globals, file descriptors, OS environment, and arbitrary C state are not. | **Law 4** (*"what happens if this inference is wrong?"*): Never claim isolation the compiler cannot prove across foreign C state. **Law 7** (*"did I make the success condition true by doing the work, or by redefining it?"*): Document hard in-process boundaries explicitly. |
| DEC-08 | Superseded JIT code uses **pin-counted retention**: retain while any active stack frame, closure, or C callback pins it, and reclaim once pins drop to zero. | **Law 5** (*"does this operation create an owner the type system does not know about?"*): Pin counts track every live reference so reachable code is never freed prematurely and unreferenced code is never leaked by default (mission: leaking is a defect). |
| DEC-09 | v0.17 includes immutable submission IDs and pinned code versions (`TT-030`) as foundational architectural hooks; full time-travel (branching timelines, `%back`/`%forward`, snapshotting/replay, and `rr` reverse-stepping) is split into a separate future proposal. | **Law 7** (*"did I make the success condition true by doing the work, or by redefining it?"*): Never advertise reverse execution or checkpoint restore without a proven recorder. **Law 9** (*"is this route still the unique way to say something, or a habit?"*): Keep v0.17 focused on the core kernel without bolting speculative subsystems onto it. |
| DEC-10 | `%get` remains explicit and is defined as a strict 1:1 passthrough to `with get` (handling version pins, offline safety, and header-vs-package name mismatches). | **Law 1** (*"does this make the programmer state something the compiler can establish, or something with no consequence?"*): Package source, version pin, and network fetch are real choices with consequences, so spelling `%get` is a guardrail, not ceremony. **Law 9** (*"is this route still the unique way to say something, or a habit?"*): Strict 1:1 passthrough guarantees one package model, never a second one. |
| DEC-11 | `Present` provides an automatic `text/plain` fallback from `Display` (and `Debug` otherwise) so users never have to implement two traits. | **Law 1** (*"does this make the programmer state something the compiler can establish, or something with no consequence?"*): If a type already implements `Display` or `Debug`, the compiler already knows how to render `text/plain`. **Law 9** (*"is this route still the unique way to say something, or a habit?"*): Reuses `std.traits.Display` rather than duplicating plain-text formatting. |
| DEC-12 | `with kernel install`, `with kernel install --check`, and `with kernel status` are Python-free. Conformance splits cleanly under D171: hermetic With-native wire/protocol tests (plus `libzmq` fetched via `with get`, never host-installed) run in the **battery**; real Python/JupyterLab interoperability tests run in **`uat/`**. | **Law 8** (*"does carrying this remove an environmental dependency from an ordinary build, or does it just add a tool?"*): Keeps the compiler battery 100% hermetic and free of host Python or host-installed `libzmq`, while `uat/` validates real external frontends (D171). **Law 10** (*"what program would fail if this rule were quietly lost? If there is none, write it before the rule lands."*): Both battery tests and `uat/` scenarios fail loudly if wire protocol or frontend interop regresses. |
| DEC-13 | Protocol 5.5 features are advertised only if implemented and exercised end-to-end; all JIT/redefinition conformance runs at `-O1` and release optimization (never `-O0`). | **Law 7** (*"did I make the success condition true by doing the work, or by redefining it?"*): No `-O0` to go green, and never advertise unimplemented debugger, comm, or subshell capabilities. |

**ENG-008 — Change control.** A decision change MUST update: this normative text, the session API schema, associated golden test fixtures, affected UAT, and downstream consumers in the same change set or a coordinated versioned transition. Independent agents MUST NOT silently redefine these choices.

## 3. Terminology, state, identities, and lifecycle

**SES-001 — Session.** A `Session` contains: a unique `session_id`; versioned compiler/semantic catalog; session-specific Clang/C migration handles; import table; project root; session-frame local slots with initialization/move states; persistent task registry and scheduler; immutable source/submission ledger (`TT-030`); pin-counted executable-code tracker; Jupyter execution counter (when attached to Jupyter); output router; cancellation state; and diagnostic history. Process-global immutable compiler tables and synchronized content-addressed caches may be shared.

**SES-002 — Submission.** A submission is one complete source string delivered for evaluation. In Jupyter it comes from an `execute_request`. Its internal `submission_id` is unique and independent of notebook cell IDs or execution counters. The source is immutable after acceptance and is retained for source maps and debugging until no debugger/history references remain.

**SES-003 — Execution count.** The Jupyter prompt counter increments exactly for executed requests that store history, following the protocol's `store_history` rules; `silent=true` forces `store_history=false`. Failures of counted requests still receive their count. A `submission_id`, Jupyter execution count, and notebook-file `cell.id` are three different identifiers. No state rebinding may depend on equality of these identifiers.

**SES-004 — Binding identity.** `(session_id, logical_name, generation)` identifies a persistent session-frame local binding version. The public name resolves to the latest valid generation. `let` is immutable within ordinary program execution but may be explicitly replaced by a subsequent top-level declaration; `var` permits in-place mutation under existing language rules. Moved/uninitialized and dropped states are tracked without inventing sentinel values. Ordinary module globals declared inside imported modules remain subject to D52 (never moved out).

**SES-005 — Declaration identity.** A function's ABI identity includes resolved parameters, return type, calling convention, ABI attributes, generics/specialization, and compiler-required layout details. A nominal type identity includes its definition version, even if a new version happens to have the same field layout. Trait/impl changes have versioned dependent catalogs.

**SES-006 — Source location.** Every diagnostic references `submission_id`, optional Jupyter execution number, original source line/column, compiler phase, and ownership provenance. User-facing cross-cell diagnostics say e.g. `value moved in cell [2], line 1` or `view ended with cell [2]`, not raw synthesized function names.

**SES-007 — Session states.** A session is one of `starting`, `ready`, `executing`, `paused`, `closing`, `closed`, or `poisoned`. The transition `poisoned → ready` is forbidden. A poisoned session rejects new code and requests a process/kernel restart if reset cannot establish a safe state.

**SES-008 — Single writer.** Compiler publication, session-frame local mutations, scheduler advancement, and cell execution have one serialized session executor. At most one With cell body is running in the process-main-thread executor at a time. Network/heartbeat/control threads MAY collect, authenticate, queue, and service read-only requests but MUST NOT mutate user-owned values directly.

### 3.1 Submission lifecycle and atomicity

**EXE-001** Each source submission follows:

```text
received → queued → parse → resolve/check → lower → materialize
      → publish declarations → execute statements → finalize output
```

The compiler MUST check against one coherent snapshot of the currently published catalog together with candidate declarations from the submission. Materialization may allocate *unpublished* JIT resources. Before publication, failure MUST release candidate resources and leave all user-visible compiler/session state unchanged, apart from diagnostic/history records.

**EXE-002 — Compile-phase failure.** If parsing, resolution, ownership validation, code generation, native-symbol resolution, or JIT materialization fails, the submission executes **no user statements**, publishes no declarations or slots, and schedules no user tasks. A cache may change internally, but not observable source semantics.

**EXE-003 — Publish and execute.** Once the complete submission has compiled and linked, declarations are published together. Executable top-level statements then run **in source order**, exactly once. Successful earlier statements remain effective if a later statement fails. There is no cell-wide runtime rollback guarantee.

**EXE-004 — Error recovery.** A supported With panic, checked runtime error, or cooperative interruption triggers **structured session unwinding** through current With frames; drops owned live stack values in reverse construction order; releases cell-local views; records a structured error; and returns to `ready` **only** if owner tracking and runtime invariants remain consistent. Already-completed moves, mutations, drops, file/network writes, and native side effects remain.

**EXE-005 — Destructor failure.** User `Drop` implementations MUST satisfy the non-unwinding destructor contract. If a destructor panics during unwinding or leaves an ambiguous owner graph, transition to `poisoned`, reject new execution, and require restart if no proven-safe cleanup path exists. Never resume based on guessed ownership state.

**EXE-006 — Statement failure ordering.** A failing initializer does not publish its incomplete new slot. However, side effects or moves it already performed on existing values remain, consistently with ordinary runtime failure. A succeeding initializer may replace an old value only after the new value is fully constructed and the replacement point is reached.

### 3.2 Session-frame locals, moves, and views

**OWN-001** Top-level `let`/`var` declarations in a session introduce persistent **session-frame local** slots (not module globals; D52 remains intact for module globals). Read/move/assign/drop follow the same ownership rules as equivalent function-local operations. The session preserves ownership and move provenance between submissions.

**OWN-002 — Rebinding.** A repeated top-level name is an explicit rebind of that *name*. It does not implicitly erase other bindings that appeared in the same notebook editor cell previously. An initializer is evaluated to a temporary owned result; then the slot replacement and old-value drop occur exactly once under the language's drop semantics. If a rebind requires changing a slot's static type while compiled dependents exist, reject with the complete known dependency chain rather than reinterpret old code.

**OWN-003 — Rebind corner cases.** For `x = f(x)` and similar self-referential initializers, reads of an existing live `x` use its current value and obey its existing ownership rules. A move of `x` may leave the old slot empty before `f` finishes. If `f` fails, that move is **not** reversed. No old value may be dropped twice. This rule takes precedence over any informal expectation that failed rebinds always preserve the previous value.

**OWN-004 — Views.** Cell-top-level views are lexical to the submission. They MUST NOT escape to session-frame locals, closures, or persistent tasks unless an existing language rule proves an independently owned representation. Later access produces a precise `view ended with cell [N]` diagnostic. The script top level counts as one submission for this purpose.

**OWN-005 — Old compilation.** Previously compiled code that operates on persistent session-frame locals MUST consult the correct current slot/version/ownership state, or fail before unsafe access. A later move or rebind cannot cause an older function to read freed memory. Static rejection is preferred when the state is known; dynamic guards are required across versioned boundaries.

**OWN-006 — Drops and reset.** Normal rebinding drops only the previous live value in the named slot, not unrelated state. A reset drains/cancels supported tasks, performs dependency-safe drops, revokes session handles, clears session history state as requested, and retains the project manifest. It cannot undo external effects or guarantee unloading an arbitrary native library.

### 3.3 Functions and type redefinition

**DEF-001 — Same-ABI function.** Redefining an identical fully resolved function identity creates an immutable implementation version and updates one stable dispatch entry atomically. Future calls through safe With handles—including stored function values and old compiled callers—use the latest body. An active frame finishes on the body it entered.

**DEF-002 — Stable boundary.** Calls crossing replaceable session-defined function boundaries MUST use indirection. Cross-version inlining or devirtualization is forbidden where it would change the above semantics at `-O1` or release optimization. Internal helpers within one immutable version MAY be optimized freely, and `std` / package bundles remain direct-called unless explicitly redefined in the session.

**DEF-003 — Changed signature (redefinition, no overloading).** With does not have ad-hoc function overloading. Defining a function with the same name and a differing signature is a **redefinition** that replaces the name in session scope for all subsequent submissions. Live and earlier compiled callers keep their pinned old version (with its original ABI); they are not silently retargeted to the incompatible signature. On publication, the kernel MUST report which earlier functions still call the old signature so the user can see stale call sites explicitly.

**DEF-004 — Escaped function pointers.** Safe With function values are stable versioned handles. A raw C function pointer requires an exact-ABI trampoline or explicit unsafe pinning. Registered callbacks cannot be revoked or rebound in a way that leaves C with a dangling pointer. Never propagate a With panic through an unsupported C ABI frame.

**DEF-005 — Type redefinition.** A new `type` declaration creates a new nominal version. Before publishing, analyze live transitive dependents, including containers, closures, active frames, suspended tasks, registered callback contexts, exported native handles, and ABI-bound function values. If incompatible live dependents exist, **reject** and show root bindings plus paths. Do not automatically destroy user data.

**DEF-006 — Stale code.** If no live/ABI blockers exist, publish the new type and mark older dependent compiled code as stale. A stale invocation fails with a targeted version error, not a reinterpretation of bytes. Traits/impls must invalidate dependent caches, and changes with live ABI-incompatible dispatch state are rejected. `const` replacement creates a new version; older compiled code retains captured constant values.

**DEF-007 — Completeness of dependency tracking.** If a dependency cannot be proven absent because opaque native code may retain an address or callback, conservatively block unsafe replacement or pin the old version through a deliberately unsafe API. Missing dependence information MUST NOT be interpreted as no dependency.

### 3.4 Tasks and top-level await

**ASY-001** A submission using top-level `.await` lowers to an async cell and is driven to completion by the With fiber scheduler. Owned persistent `Task` values may survive between submissions. The scheduler runs With user code only while a cell is executing or an explicitly defined debug/control operation is driving it; no invisible background advancement of With fibers between cells.

**ASY-002** Task ownership, cancellation, and drop follow the core language's contracts. Interrupting the active async cell cancels/unwinds its *active execution context*; independently owned persistent tasks remain pending unless explicitly consumed or canceled. No suspended task may retain a view into a completed cell.

**ASY-003** The scheduler MUST be fair among runnable fibers and avoid unbounded starvation, but external event readiness and OS timing are not deterministic. A cell awaiting input or I/O MUST remain interruptible at its With suspension point even if a native blocking call itself cannot be interrupted.

**ASY-004** Main-thread code MUST NOT synchronously wait on a control/I/O worker whose completion requires the main-thread executor. Such cycles are diagnosed as unsupported deadlock-risk conditions, not silently blocked.


## 4. Persistent LLVM ORC JIT and native-code lifecycle

**JIT-001 — Persistent context.** A session uses one persistent logical compiler and an ORC execution context for all its submissions. Declarations join the session's versioned catalog; executable top-level statements become uniquely named synthesized cell functions that run once. Separate sessions MUST NOT share mutable compilation state, symbol catalogs, or session-frame locals.

**JIT-002 — Version bookkeeping.** Each materialized compilation unit has a unique version ID, ORC resource tracker, symbol/export list, imported-native dependency set, debug registrations, executable bytes, explicit pin count and pin reasons, and state (`candidate`, `published`, `retired`, `retained`). Publication is all-or-nothing at the catalog boundary.

**JIT-003 — Pin-counted reclamation.** Superseded JIT code uses **pin-counted retention**: a compilation unit MUST be retained while any active stack frame, task continuation, closure, safe function handle, C callback trampoline, or active debugger reference pins it, and MUST be reclaimed promptly once its pin count drops to zero. Code MUST NOT be retained indefinitely by default once unpinned. Retention MUST be observable, have configurable memory limits, and fail with a named resource-limit error rather than crash or silently evict pinned code.

**JIT-004 — Native resolution.** Resolve symbols in deterministic order: explicitly imported session bindings → explicit locked package dependencies → With runtime/standard symbols. Ambiguity at the same priority is a hard link error. Do not accidentally import symbols from an unrelated module merely because they are already loaded in the process.

**JIT-005 — Archives/frameworks.** ORC MUST resolve dynamic shared libraries, static archives, platform frameworks, relocation requirements, and transitive dependencies through explicit target/lockfile metadata. Error messages identify the missing symbol, object/library, target, and import that required it. UATs MUST exercise `sqlite3` and `raylib`, including static archives and macOS frameworks as applicable.

**JIT-006 — Session-scoped C bridge.** Mutable Clang parser, `c_import`, C migrator, header search, and `c contract` / `c facts` state MUST be per session. Shared immutable tables or synchronized content-addressed caches are allowed. Two sessions importing the same header concurrently must not contaminate one another's ABI assumptions.

**JIT-007 — Native-library lifetime.** A native library or callback remains pinned while live values, code, tasks, and registered callbacks depend on it. If a C API cannot unregister a callback safely, keep the corresponding code and trampoline pinned until kernel-process exit, report it, and prevent unsafe hot-replacement.

**JIT-008 — Platform JIT validity.** Executable-memory permissions, code signing/entitlements, allocator protections, relocation, structured session unwinding, symbol/debug registration, and platform-required JIT write/execute transitions are **foundation checks**, not documentation-only release polish. `with kernel status` must show actionable capability failures.

**JIT-009 — Structured session unwinding.** For v0.17, session-compiled With code uses **structured session unwinding**—reusing the compiler-generated structured unwind path already used by task cancellation—so panics and cooperative interrupts unwind cleanly and run drops in reverse construction order across macOS, Linux, and Windows without building native Itanium/SEH exception tables (`__unwind_info`, `.eh_frame`, `.pdata` personality/landingpads). Prove With panic, async panic, and cancellation unwind through ORC-created frames on each claimed platform. Native C-frame crashes remain process-fatal until out-of-process worker recovery is added.

**JIT-010 — Optimized debugging.** Generate native source mappings and target-correct debugging metadata; on DWARF platforms this includes line tables, location lists where required, inlining ranges, and usable call-frame info for backtraces and debugger inspection. Optimized-away variables MUST be reported unavailable, not fabricated. Debug metadata is a source interpretation layer, not a reverse-execution recorder.

**JIT-011 — Teardown ordering.** Stop accepting submissions → request cancellation and drain supported tasks → deactivate exported callbacks/trampolines → drop live session-frame locals safely → release debug pins → reclaim unpinned JIT versions → unload native libraries only where safe → close session. If teardown cannot meet these invariants, report retained pinned resources and request full process exit.

**JIT-012 — Observability.** Engine metrics MUST include live/pinned/retired code bytes, pin counts and pin reasons per version, code versions per symbol, count/reasons of pinned callbacks, unresolved imports, compilation/materialization time, and per-session frame/heap use. A long-running session cannot accumulate unbounded resources without showing usage and enforcing configured ceilings.

## 5. Main-thread executor, isolation, cancellation, and failure classes

**RUN-001 — Execution threading.** All user With cell bodies and scheduled With fibers execute on the process main thread (required for supported native GUI/window operations). Protocol, heartbeat, and network I/O use other threads. Concurrent frontends or two `Session` objects queue to one main-thread executor; they do not execute user cells concurrently within a process.

**RUN-002 — Consistent read-only inspection.** Completion/inspection/history/debug reads MUST use an immutable published snapshot or a main-thread safe point. No frontend request may dereference mutable JIT-owned memory concurrently without synchronization and ownership validation.

**RUN-003 — Per-session isolation.** Symbol tables, session-frame locals, source maps, import catalogs, JIT domains, tasks, and cancellation flags are session-specific. OS file descriptors, loaded shared libraries, environment variables, process working directory, signal handlers, and arbitrary C static variables remain process-scoped. The two-session gate compares controlled outputs/diagnostics after normalizing addresses, timestamps, and generated IDs; it does not promise arbitrary native-process isolation.

**RUN-004 — Working directory.** Each session captures its absolute project root at creation. Paths for package imports and kernel-local resources resolve relative to that root without process-wide `chdir`. If native code changes CWD, that is an explicitly unisolated native side effect.

**RUN-005 — Cancellation token.** Cancellation is keyed by session ID and active submission. Instrument With function entry, loop back-edges, and fiber suspend/resume points in **session-compiled** code. Control-channel `interrupt_request` sets the token promptly, even while a cell is executing. Do not silently add equivalent checks to unrelated noninteractive binaries.

**RUN-006 — Interrupt semantics.** The kernel acknowledges that an interrupt was **requested**, not that execution necessarily stopped. It becomes effective when With code reaches a checkpoint and triggers structured session unwinding. Blocking native C calls and foreign deadlocks are not guaranteed interruptible. Stdin waits and With scheduler waits must be woken cooperatively.

**RUN-007 — Foreign failure boundary.** A With panic may be recovered only across supported With frames via structured session unwinding. Foreign segmentation faults, `abort()`, C-frame crashes, arbitrary C++ exceptions, memory corruption, and uninterruptible native calls are outside that guarantee and remain process-fatal until out-of-process worker recovery exists. A With panic MUST NOT unwind across an unsupported C ABI frame. `c contract` / `c facts` bindings must use ABI-safe error/reporting or reject an unsafe callback mode.

**RUN-008 — Output capture.** Capture kernel-process FD 1/2 once at startup through nonblocking pipes or equivalent, forwarding native `printf` and With output to IOPub stream messages. During serialized cell execution, assign controlled output to the current request; native background-thread output is best-effort and may be unattributable. Restore descriptors at teardown. Authentication, Control, and heartbeat MUST remain responsive when output is backpressured.

**RUN-009 — Poisoning.** Failure of core ownership or unwind invariants marks the session poisoned. A poisoned session may answer read-only diagnostics and shutdown requests but MUST NOT execute arbitrary user code. It must not respond with a superficially healthy `ready` state.

**RUN-010 — Operational limits.** Configurable limits MUST exist for: compile/runtime memory, JIT code cache, session heap, task count, message sizes, output size/queue, submission history retention, and execution timeouts where cooperatively enforceable. Resource-limit messages MUST distinguish user-configured ceilings from OS allocation failure.

## 6. `std.net` substrate and pure-With ZMTP 3.0

This layer is required for the Jupyter kernel but is intentionally reusable independently of Jupyter.

**NET-001** Socket send/receive APIs operate on byte slices and return actual transferred lengths. Never assume UTF-8 or NUL termination. Explicitly distinguish EOF, partial read/write, timeout, interruption, closed socket, and OS errors.

**NET-002** A multi-socket readiness poller supports read/write/hangup/error, monotonic deadlines, a wakeup channel for shutdown/interrupt, and handles POSIX `EINTR`/Windows equivalents. Close while polling must not cause an FD-reuse use-after-close. Busy spinning is prohibited.

**NET-003** A buffered multi-part framing layer MUST handle partial reads/writes, oversized lengths, malformed frame flags, peer disconnection, slow peers, and bounded memory use independently of Jupyter message content.

**ZMQ-001** The internal pure-With `std.internal.zmtp` implements the required **ZMTP 3.0 NULL** greeting, mechanism negotiation, READY metadata, framing, and routing for Jupyter's Shell/Control/Stdin ROUTER sockets, IOPub XPUB socket, and heartbeat REP behavior over local TCP. No `libzmq` or C++ runtime is required by the kernel.

**ZMQ-002** Application messages MUST NOT be accepted or published before the respective peer finishes the ZMTP handshake. Bad peers are disconnected without poisoning other peers or stopping the kernel. Correctly preserve DEALER identities and multi-client ROUTER envelopes.

**ZMQ-003** XPUB subscribe/unsubscribe frames MUST be consumed and represented as subscription state. Initial status publication SHOULD account for subscribers already connected, but startup MUST NOT block indefinitely awaiting subscribers. A late subscriber can obtain kernel state using protocol requests; the transport must not fabricate historical IOPub events.

**ZMQ-004** Hermetic **battery** conformance MUST exercise both the pure-With protocol test client and an independent real `libzmq` peer fetched via `with get` (never a host-installed library). Test fragmented frames, multipart routes, disconnection, subscriptions, authentication-frame boundaries, duplicate client identities where applicable, and backpressure.

## 7. Jupyter Protocol 5.5 kernel adapter

**JUP-001 — Version contract.** Implement the Jupyter Messaging Protocol **5.5** message/channel contracts used by the supported feature set. Supported features are enumerated in `kernel_info_reply`; message-type conformance is independently tested. The network transport and Jupyter envelope serializer/verifier MUST have separable tests.

**JUP-002 — Connection security.** Read and validate the Jupyter connection file **before** listening. The baseline supports `transport=tcp`, `ip=127.0.0.1`, five distinct valid ports, `signature_scheme=hmac-sha256`, and an explicit key. Unsupported transport, non-loopback binding, malformed ports, or unknown signature scheme MUST fail with actionable errors. An empty signing key is allowed only on loopback and triggers a visible warning; it is never described as authenticated.

**JUP-003 — Connection-file handling.** Keys and full authenticated request bodies MUST NOT appear in logs, crash reports, or `with kernel status` output. File permissions and bind failures are checked. Binding multiple sockets is all-or-nothing: on partial startup failure, close previously bound sockets, report the failure, and exit without a half-working kernel.

**JUP-004 — Wire envelope.** Encode/decode `identity frames → <IDS|MSG> → signature → header → parent_header → metadata → content → optional binary buffers`. HMAC-SHA256 covers the **exact serialized byte frames** of the four JSON header/content objects in order. Verify before JSON parsing/executing instructions. Reject invalid signature length, malformed frame count, JSON errors, or unsigned messages (except a deliberately configured empty key) without disclosing secrets.

**JUP-005 — Integrity and bounds.** HMAC comparison is constant-time for fixed-length valid digests. Default inbound limits are 64 MiB/frame, 128 MiB/whole message, and 256 frames/message, configurable downward for restricted environments. Bounds are checked before large allocation. Protocol errors must release buffers and disconnect the offending peer without destroying unrelated sessions.

**JUP-006 — Channels.** Shell, Control, Stdin, IOPub, and heartbeat have separate queues and correct routing. IOPub events retain the corresponding `parent_header`; Shell replies go only to the requesting frontend. Stdin requests route to the frontend associated with the active execution; a reply from the wrong identity is rejected. Heartbeat remains responsive independent of compiler or user-code progress.

**JUP-007 — Lifecycle.** At startup publish `status: starting` according to protocol behavior, then service requests and publish correct `busy`/`idle` around handled requests. For a normal execution publish `busy`, `execute_input` when applicable, interleaved stream/display/error outputs, `execute_reply`, then `idle` with correct parent linkage. Flush ordered cell output before publishing `idle` to the extent it is controlled; late native asynchronous output is explicitly best-effort.

**JUP-008 — `execute_request`.** Accept and honor `code`, `silent`, `store_history`, `user_expressions`, `allow_stdin`, and `stop_on_error`. `silent=true` suppresses ordinary execution IOPub output and forces no history storage. History count advances only where protocol says it advances. `user_expressions` are evaluated after successful code execution under normal safety/effect rules; errors are recorded individually per expression. They are **not** presumed side-effect-free merely because the field is called an expression.

**JUP-009 — Queue errors.** When `stop_on_error` is true and an execution errors, abort the relevant pending execution queue according to the protocol, return explicit aborted/error replies as required, and keep heartbeat/control/shutdown functional. Never silently discard a queued request. The exact queue draining policy MUST be fixture-tested with two frontends so one frontend's error cannot arbitrarily destroy unrelated client state.

**JUP-010 — State reporting.** `kernel_info_request/reply` work on Shell and Control as applicable, including actual `protocol_version`, With `language_info`, banner, and `supported_features`. Do not advertise comms, debugger, subshells, or completion modes that are not backed by passing tests. `comm_info_request` returns a valid empty `comms` object while widget comm traffic is unsupported.

**JUP-011 — Read-only semantic services.** `complete_request`, `inspect_request`, `is_complete_request`, and `history_request` use the session compiler's read-only semantic/history services. They MUST NOT execute user code or advance fibers. `is_complete` uses the parser, not bracket-counting heuristics. Completion cursor offsets use Unicode code-point indexing as Jupyter requires, not byte offsets; translated LSP offsets are not part of this kernel's protocol contract.

**JUP-012 — Interrupt/shutdown.** Handle `interrupt_request/reply` and `shutdown_request/reply` on Control. `interrupt_reply` confirms the request was received; it does not guarantee a stalled native library has exited. Graceful shutdown drains owned tasks and releases kernel resources when safe. When a frontend requests restart, follow the frontend/kernel manager's process-restart convention; do not pretend to restart a corrupted kernel in place.

**JUP-013 — Stdin.** Route a With `read_line()`-like operation to `input_request`/`input_reply` on the Stdin channel. When `allow_stdin=false`, fail immediately with a meaningful error; do not fall back to reading kernel terminal stdin. Interrupt and shutdown must unblock a pending frontend input request.

**JUP-014 — Multi-client behavior.** Multiple frontends share one kernel session. Submissions are linearized in the main-thread executor's accepted order. Replies preserve requester identity. Completion and inspection are snapshot-consistent. Clients must not assume notebook page order and must not receive another client's private Shell/Stdin reply.

**JUP-015 — Protocol test split (D171 / Law 8).** Conformance is cleanly separated into two tiers:
1. **Battery (hermetic, no host Python or host-installed `libzmq`):** pure-With protocol client tests plus an independent real `libzmq` peer fetched via `with get`, covering startup, authentication, execution, display, errors, cancellation, completion, introspection, multi-client routing, and clean shutdown on each claimed platform.
2. **UAT (`uat/`, host frontend permitted under D171):** real Python / JupyterLab end-to-end interoperability scenarios exercising the same production kernel binary.


## 8. Results, rich display, source introspection, and kernel commands

### 8.1 Display contract

**DSP-001 — Presentation interface.** `Present` converts a value into a Jupyter MIME bundle, supporting `text/plain`, `text/html`, `image/png`, `image/svg+xml`, `application/json`, and `text/markdown`. `Present` MUST provide an automatic `text/plain` fallback from `std.traits.Display` (and from `Debug` otherwise) so users never have to implement two traits just to get plain-text output. Every emitted user result MUST provide `text/plain` unless the relevant protocol intentionally permits its omission.

**DSP-002 — Implicit result.** The completed expression result of a non-silent cell is emitted at most once as `execute_result` when the language's expression-result semantics provide a value. Explicit `display(value)` produces `display_data`. Do not implicitly display each intermediate statement, re-evaluate a final expression, or print non-displayable unit values unless language policy explicitly requires it.

**DSP-003 — Safety.** Presentation MUST NOT implicitly consume or move a persistent session-frame local. A `Present` (or `Display`) implementation that has side effects is user code and follows ordinary runtime semantics; the engine MUST NOT secretly invoke it on completion/inspection paths that promise read-only behavior. Inspector preview requests therefore use a separate certified read-only formatter or return only type/provenance metadata.

**DSP-004 — Tables.** `List[Struct]` or an equivalent statically introspectable record collection MAY derive table display through `T.fields()`. Truncate long tables by row/byte limits with visible notices; escape HTML, bound cell sizes, preserve plain-text alternatives, and avoid allocating an unbounded copy just to render output. The notebook engine does not require a new `from` query language to demonstrate tables.

**DSP-005 — Binary and content types.** Binary `image/png` uses the Jupyter-compatible representation; other MIME entries follow protocol JSON serialization rules. Reject malformed MIME values, excessive payloads, and invalid markup inputs as explicit display errors rather than sending plausible but corrupt output. Do not silently accept arbitrary HTML injection from untrusted external data without the documented escaping/sanitization policy; explicitly user-authored trusted HTML remains a deliberate action.

**DSP-006 — Output queues.** Keep output ordering per submission. Output backpressure cannot stall heartbeat or authentication; cap queues, report truncation to the user, and keep compiler diagnostics intact where feasible. A cell's failure MUST NOT suppress its already completed output without telling the user.

### 8.2 Semantic analysis and kernel magic commands

**SEM-001** The compiler exposes a consistent read-only semantic snapshot supporting symbol lookup, type inspection, ownership/move provenance, completion, signature/hover information, expression completeness, and source-mapped diagnostics. This is a dependency of the kernel's Jupyter completion/inspection and debugger interfaces, **not** a mandate to build an entire language-server/editor ecosystem.

**SEM-002 — Command parsing.** Kernel `%` commands are interpreted at submission start by a shared command dispatcher rather than compiled as ordinary With. A command never triggers replay of previous submissions. Unsupported/unknown commands fail with their exact name and available commands.

**SEM-003 — Core command set.** The kernel command dispatcher supports `%get`, `%remove`, `%deps`, `%reset`, `%time`, `%who`, `%type`, and `%help`. `%get` is explicit and MUST be a strict 1:1 passthrough to `with get` (preserving version pins, offline safety, and header-vs-package name handling with no second package model); it updates future import resolution without retroactively rewriting old compiled code. The project root is discovered at session startup or defaults to the kernel's startup directory, not an imagined notebook-file path. `%remove` checks dependencies; removing a package does not unload pinned native code. `%who` shows name, static type, live/moved/uninitialized state, generation, and provenance. `%type` is read-only. `%time SOURCE` executes exactly once, showing compilation and execution time separately. `%reset` follows `OWN-006`. The command table itself generates `%help`.

**SEM-004 — Source history.** Store submission source, execution order, result class, error summary, and metadata for Jupyter `history_request` and debugger source mapping. History source is not a replayable native-memory snapshot. History retention is bounded and configurable. Non-persisted (`store_history=false`) Jupyter submissions still require ephemeral source maps while executing, but are not silently appended to the public input-history collection.

## 9. Debugger integration and source-level stepping

**DBG-001 — Scope of v0.17 debugging.** In v0.17, the kernel provides forward source debugging over live JIT code. It MUST NOT equate debugger source metadata (DWARF/PDB or equivalent) with an execution recorder. Reverse execution and time-travel inspection belong to a separate future proposal (§10).

**DBG-002 — Jupyter debugger protocol.** When debugging is supported, accept Jupyter `debug_request`/`debug_reply` on Control and emit `debug_event` on IOPub. Contents follow the Jupyter debugger extensions to DAP, including notebook-specific source registration (`dumpCell`), debugger state restoration (`debugInfo`), and supported variable inspection. Advertise `'debugger'` in `kernel_info_reply.supported_features` **only after** the required request/event compatibility suite passes.

**DBG-003 — Immutable source identities.** Every submission has a canonical immutable virtual source identity and source text. Where a debugger requires actual files, mirror exact source bytes in a secure kernel-owned temp directory with stable versioned paths, user-only permissions, and cleanup policy. A new submission or edited cell MUST NOT overwrite the source corresponding to an earlier compiled code version. The Jupyter `dumpCell` mapping must be deterministic for identical source bytes within the session without implying that edited content is the same execution.

**DBG-004 — Debug state.** Maintain breakpoints, source-version references, selected execution/frame, and paused state in session-owned debugger state. The `debugInfo` response MUST be consistent with what has actually been installed, including behavior after a frontend reconnects.

**DBG-005 — Safe pause.** When paused at a With safe point, the main-thread executor runs a restricted debugger control loop and does not start unrelated user submissions. Control channel remains responsive. Source inspection uses paused-state read-only views. Stepping resumes only the selected live execution domain. Native code outside With-controlled safe points may not be pausable by the core engine without a platform debugger backend.

**DBG-006 — Stack and variable truthfulness.** Source mapping uses statement boundaries, actual compilation versions, inline frame info, live owner states, and target-native debug information. If a value has been moved, dropped, optimized out, or made inaccessible by the runtime, report that exact status rather than inventing a historical value. A debug print must not accidentally call an unsafe formatter or perform arbitrary user side effects.

**DBG-007 — Debug capabilities.** DAP capabilities are negotiated strictly according to proven support. In v0.17, `supportsStepBack` and `supportsReverseContinue` MUST be advertised as `false`, and any reverse-stepping request MUST fail explicitly with `UnsupportedFeature`. Never synthesize a `stepBack` success by merely moving a source-code cursor to a previous line.

## 10. Architectural invariants for future time-travel (v0.17 scope boundary)

Full time-travel debugging—including `SessionTimeline`, `ExecutionRecorder`, branching futures, `%timeline`/`%back`/`%forward`, managed-state checkpointing/restoration, and `rr`/GDB/LLDB native reverse-stepping—is **out of scope for v0.17** and will be specified in a separate future proposal.

**TT-030 — Architectural invariants (in scope for v0.17).** From the first JIT implementation, the engine MUST assign and preserve:
1. **Immutable `submission_id`s** and immutable submission source text (`SES-002`, `DBG-003`) that are never overwritten by later edits or re-executions.
2. **Versioned code identities and explicit pin counts** (`JIT-002`, `JIT-003`) for every compiled unit, native callback trampoline, and debug mapping so a future recorder can pin and resolve retired versions cleanly.
3. **Explicit ownership/move provenance** (`SES-004`, `SES-006`) tying binding generations and moves to the `submission_id` that performed them.

Deferring full time-travel execution is required to keep v0.17 focused; omitting these lightweight identity and pin-counting hooks is forbidden because retrofitting them after JIT publication risks dangling source maps and unpinned code references.

## 11. Installation, local diagnostics, and headless acceptance harness

**OPS-001 — Kernel CLI.** `with kernel install` installs a discoverable `kernel.json` with an absolute path to `with`, proper `argv` connection-file placeholder, `language=with`, display name, and `interrupt_mode=message` on all supported OSes. Installation MUST NOT require a Python dependency in With itself.

**OPS-002 — Installation paths.** Default to the current user's standard Jupyter data path, respecting documented environment overrides. `--prefix` and `--sys-prefix` are mutually exclusive; `--sys-prefix` must resolve to an explicitly known prefix and fail helpfully otherwise. `with kernel install --check` verifies actual kernelspec discoverability, path validity, and executable correctness without modifying files. Reinstalling With preserves unrelated kernelspecs.

**OPS-003 — Kernel status.** `with kernel status` (alongside `with kernel install --check`) reports kernel discovery paths, stale paths, native dependencies, transport bind capability, JIT executable-memory and structured-unwind readiness, source/debug registration availability, and whether an authenticated localhost kernel handshake succeeds. It MUST NOT print connection secrets.

**OPS-004 — Headless protocol driver and UAT split.** Ship a pure-With Jupyter protocol client and a `with get`-fetched `libzmq` peer for the hermetic **battery**, plus real Python/JupyterLab interoperability scenarios in **`uat/`**. Both tiers use the same production kernel binary; no separate interpreter, mock compiler, or replay of earlier cells.

**OPS-005 — Notebook runner adapter.** A minimal `with notebook run` adapter MAY execute nbformat 4.5 code cells through the **same SessionEngine** in file order to support integration tests and reproducible examples. If provided, preserve source/metadata/attachments; default output is a separate `.executed.ipynb`; in-place overwrite requires explicit request and atomic replacement. This adapter is not permitted to define different ownership, error, or scheduler semantics from Jupyter.

**OPS-006 — Security posture.** The default kernel is local-only, authenticated by the connection-file key, and should be run with user-level OS privileges. This is not a hostile multi-tenant sandbox. Do not claim that `127.0.0.1`, HMAC, or in-process JIT contains malicious code supplied by an authenticated local user.


## 12. Verification gates (engineering dependencies, not release milestones)

These gates define **architectural readiness**, not dates or separate releases. Independent work may proceed in parallel when it consumes stable interfaces; merging a dependent feature requires its prerequisite gate to be green. Every gate executes on each platform the kernel claims to support, respecting the **battery** (hermetic) vs **`uat/`** (external frontend) boundary from D171.

### Gate A — Persistent native-session vertical slice (battery)

**GATE-A-1:** Compile, materialize, and execute a cell through ORC; publish one top-level session-frame local; execute another cell using it without replay. Assert source-specific diagnostics.  
**GATE-A-2:** Import a C header through a session-scoped compiler (`c contract` / `c facts`), call one real native function from JIT code, and resolve a static/archive symbol.  
**GATE-A-3:** Start a minimal actual Jupyter Protocol 5.5 handshake, execute one With cell, and observe proper Shell/IOPub/Control behavior through the pure-With client.  
**GATE-A-4:** Verify JIT code signing/executable-memory permissions and structured session unwinding on macOS, Linux, and Windows supported targets **before** widening session semantics.

### Gate B — Ownership, versions, and recovery (battery)

**GATE-B-1:** Move a session-frame local in cell 2 and attempt to read it in cell 3. Reject with original-cell provenance. Rebind afterward and verify the new owner is live. Verify ordinary module globals still obey D52 (cannot be moved out).  
**GATE-B-2:** Create a top-level view, then try to access it later. Reject with `view ended with cell [N]`.  
**GATE-B-3:** Compile failure with declarations plus top-level side effects must execute nothing and publish nothing.  
**GATE-B-4:** A runtime panic after session-frame local mutation and file output must unwind cleanly via structured session unwinding while preserving already completed effects.  
**GATE-B-5:** Successful same-name rebind drops the previous owned value once, does not erase unrelated names; failed initializer with an earlier move does not fabricate a restored old value.  
**GATE-B-6:** Same-ABI function replacement changes calls originating in previously compiled cells at **`-O1` and release optimization** (never `-O0`); saved safe function handles observe the new body; active frames finish their entered version; `std` and package bundles remain direct-called unless redefined in the session.  
**GATE-B-7:** Redefining a function with a changed signature replaces the name in session scope for new callers (no overload sets); earlier compiled callers keep their pinned old version, and the kernel reports which earlier functions still call the old signature.  
**GATE-B-8:** Type redefinition with `List[Old]`, maps, captured closures, suspended task, or native callback that depends on `Old` is rejected with concrete blocker paths; unrelated values are not dropped.  
**GATE-B-9:** Persistent async task advances only during a deliberate cell-run/scheduler drive. An async-cell panic and interrupt unwind cleanly via structured session unwinding without orphan references.  
**GATE-B-10:** A panic during `Drop` poisons the session and prevents subsequent code from running.

### Gate C — Transport and multi-client protocol (battery + `uat/`)

**GATE-C-1:** In the **battery**, the pure-With client and a `with get`-fetched `libzmq` peer connect through authenticated ZMTP 3.0 on all five channels (testing XPUB subscribe/unsubscribe, ROUTER identities, and repeated connect/disconnect). In **`uat/`**, real JupyterLab connects and executes cells through the same kernel binary.  
**GATE-C-2:** Verify exact-frame HMAC; reject invalid signature, malformed JSON, oversized multipart messages, malformed greeting, and wrong Stdin identity without executing code.  
**GATE-C-3:** Execute success/error/interrupt with correct `busy → messages → reply → idle`, count/history semantics, parent headers, and targeted client replies.  
**GATE-C-4:** `silent`, `store_history`, `allow_stdin`, `stop_on_error`, and `user_expressions` each have positive and adversarial fixtures; two clients submit queued commands and continue to receive correctly routed replies.  
**GATE-C-5:** Main-thread execution of a GUI-sensitive native function coexists with Control/heartbeat responsiveness; C `printf` appears in IOPub `stream` output.  
**GATE-C-6:** Two sessions in one process have independent compiler state, session-frame locals, and cancellation; a cancellation for one never cancels the other. Explicitly demonstrate the documented limits of native process-global isolation.

### Gate D — Inspector, display, and debugger (battery)

**GATE-D-1:** Completion, inspect, and completeness checks never execute a user statement, advance a task, or consume/move a session-frame local. Unicode cursor positions are correct.  
**GATE-D-2:** `Present` emits correct MIME bundles and automatically falls back to `Display` (and `Debug` otherwise) for `text/plain`; HTML table output is escaped/truncated safely; panics in a user-authored renderer unwind honestly as cell errors.  
**GATE-D-3:** Source maps remain accurate after repeated cell edits and function replacement; older JIT code still maps to its own immutable `submission_id` source version (`TT-030`).  
**GATE-D-4:** A paused debugger can inspect a moved/optimized-out variable without fabricating a value; Control channel remains responsive. `debugger` is advertised only when the Jupyter debugger protocol tests pass.  
**GATE-D-5:** DAP reverse stepping is advertised `supportsStepBack=false` / `supportsReverseContinue=false` in v0.17 and rejected with `UnsupportedFeature`, never faked as cursor movement.

### Gate E — Pin-counted reclamation and submission identity (battery)

**GATE-E-1:** Three sequential cells (`var x = 10`, `x += 5`, `x *= 2`) yield distinct immutable `submission_id` entries (`TT-030`) with accurate source text and provenance.  
**GATE-E-2:** Superseded JIT code remains pinned while an active frame, closure, or C callback holds a pin, and is reclaimed automatically once all pins drop to zero (`JIT-003`).  
**GATE-E-3:** Pin metrics accurately report live, pinned, and retired code bytes and pin reasons; session reset and teardown release pins in `JIT-011` order.

### Gate F — Installation, UAT, and endurance (battery + `uat/`)

**GATE-F-1:** `with kernel install`, `with kernel install --check`, and `with kernel status` work on clean target systems without requiring Python in the With kernel installation itself (battery); real JupyterLab discovers and launches the installed kernelspec (`uat/`).  
**GATE-F-2 (`uat/`):** Real notebooks covering ownership, prior-cell function replacement, `%get` passthrough, native SQLite, native raylib, rich display, async cells, interrupts, and source/debugger maps execute successfully through production paths.  
**GATE-F-3 (battery):** A soak test executes thousands of submissions, redefinitions, asynchronous tasks, compile failures, and runtime errors. Memory use, pin-counted JIT code bytes, descriptor counts, and compilation latency remain bounded (proving unpinned superseded code is reclaimed) or fail visibly at configured limits.  
**GATE-F-4 (battery):** The shutdown path does not leave owned live handles dangling or leak debug/JIT registrations. When a native library prevents unloading, the kernel records and reports that limitation honestly.

### 12.1 Adversarial scenario matrix

| Scenario | Required outcome | Rules |
|---|---|---|
| Re-execute edited cell that removed `b` | `b` remains unless explicitly removed; rebinding of `a` affects only `a` | SES-004, OWN-002 |
| New initializer moves old `a`, then panics | Prior move remains; structured unwind runs drops; no double-drop or fake rollback | EXE-004, EXE-006, OWN-003 |
| Move a module global inside a cell | Rejected per D52; only session-frame locals may be moved out | SES-004, OWN-001 |
| Compile error follows proposed `fn` declaration | Candidate function not published | EXE-002 |
| Runtime panic follows successfully published `fn` | Function remains published, prior side effects remain | EXE-003, EXE-004 |
| Old stored safe `fn` value after same-ABI replacement | Calls latest same-ABI body at `-O1` and release | DEF-001, DEF-002, DEF-004 |
| Redefine `fn` with different signature | Replaces name in session scope; old callers keep pinned old version; kernel reports stale callers | DEF-003 |
| Redefine `T` while `Task[List[T]]` is live | Block redefinition with dependency path | DEF-005 |
| Superseded JIT code after all pins drop | Reclaimed automatically; memory does not grow unboundedly | JIT-003 |
| Interrupt during pure With infinite loop | Cooperative structured unwind and ready session, if no poison | RUN-005, RUN-006, JIT-009 |
| Interrupt inside uncooperative C call | Request acknowledged; completion not falsely guaranteed | RUN-006, RUN-007 |
| Frontend reconnects while source version is retired | Debug mapping still resolves correct original `submission_id` | JIT-003, DBG-003, TT-030 |
| Jupyter requests DAP `stepBack` in v0.17 | Rejected with `UnsupportedFeature` (`supportsStepBack=false`); no fake cursor move | DBG-007 |
| Two frontends issue Shell requests, one requests input | Stdin and Shell replies go only to rightful requester | JUP-006, JUP-014 |
| Invalid HMAC and valid request arrive together | Invalid request never executes; valid connection remains functional | JUP-004, JUP-005 |

## 13. Shared interfaces and swarm coordination contract

The following are **semantic boundaries**. Exact API names and wire schemas should be captured in machine-readable fixtures before parallel implementation begins.

| Contract | Primary owner | Consumers | Stability gate |
|---|---|---|---|
| Session lifecycle, submission (`TT-030`), and state snapshot API | Session engine | Jupyter host, CLI adapters, debugger | Gate A |
| Session-frame local slot, move-state, provenance, destructor API | Compiler/runtime | JIT, inspector, debugger | Gate B |
| Definition version/dispatch and pin-counted resource API | Compiler/ORC | Runtime, debugger, `c contract` / `c facts` | Gate B |
| Structured session unwind, cancellation safe-point, and scheduler API | Runtime | Jupyter Control, debugger, async cells | Gates B/C |
| Native import and callback ABI contract | C/Clang bridge | ORC, `c contract` / `c facts` | Gates A/B |
| Socket/poller and multipart framing contract | `std.net`/ZMTP | Jupyter wire host | Gate C |
| Jupyter message serialization/validation fixtures | Kernel protocol | Kernel host, battery clients, `uat/` JupyterLab | Gate C |
| `Present` MIME (with `Display`/`Debug` fallback) and readonly-inspection contract | Runtime/semantic API | Jupyter display/inspect, debugger | Gate D |
| Platform JIT/permissions/status manifest | Platform integration | ORC, `with kernel status`, native callbacks | Gates A/F |

**AGT-001 — Single source of truth.** Every owner publishes a versioned API description, normative error taxonomy, and executable positive/negative fixtures. Agents must reference the contract version they implement. No parallel team redefines language behavior privately to make tests pass.

**AGT-002 — Failure taxonomy.** Standard error kinds MUST distinguish `CompileError`, `LinkError`, `OwnershipError`, `RuntimePanic`, `Interrupted`, `UninterruptibleNativeCall`, `UnsupportedFeature`, `StaleVersion`, `ResourceLimit`, `ProtocolError`, `SecurityError`, and `PoisonedSession`. Error text can be human-friendly; the kind and structured provenance must be stable for tests.

**AGT-003 — Source of truth for tests.** Unit tests supplement, but never replace, hermetic battery conformance tests and user-facing `with uat` real-frontend scenarios. Every semantic contract has at least one passing and one adversarial test. Platform-dependent omissions must be explicit, not silently skipped while claiming support.

**AGT-004 — Integration cadence.** Agents can work concurrently on independently versioned modules. Main branch integration MUST continuously run the vertical Jupyter lane and relevant ownership/protocol tests; downstream changes may not bypass a failing foundation gate with mocked assumptions.

**AGT-005 — Law 7.** Unsupported operations fail loudly and state the precise missing capability or reason. No fallback may produce plausible but incorrect state, protocol output, debugger variable, or safety guarantee.

## 14. Conformance examples (conceptual With syntax)

These examples describe intended behavior, not final parser-approved spellings. Actual source syntax MUST come from the canonical With language specification and be used in test and UAT fixtures.

### 14.1 Stateful execution

```with
// Submission 1
var x = 10
// Submission 2
x += 5
// Submission 3
x *= 2
```

After Submission 3, the session-frame local `x` holds `30`, and the submission ledger (`TT-030`) holds three immutable `submission_id` entries with their original source text and provenance.

### 14.2 Rebinding without editor-cell identity

```with
// First submission
let a = 10
let b = 20
// Later submission (possibly from edited same notebook cell)
let a = 30
```

`a` refers to a new owned generation with value `30`; `b` remains `20`. Notebook-cell location or notebook JSON cell ID does not delete `b`.

### 14.3 Declaration and runtime failure

```with
// Candidate submission whose final declaration fails to compile:
fn helper(n: i64) -> i64:
    n + 1
// If any part of this submission fails before publication, helper is absent.
```

By contrast, a successfully compiled submission that publishes `helper`, mutates a session-frame local, then panics retains its published declaration and completed mutation after structured session unwinding runs local drops.

### 14.4 Function redefinition and pin-counted code reclamation

```with
// Submission 1
fn compute(x: i64) -> i64:
    x + 1
fn caller() -> i64:
    compute(41)

// Submission 2 (same-ABI replacement)
fn compute(x: i64) -> i64:
    x + 10
```

`caller()` invokes the new `compute` body (`51`) via versioned dispatch at both `-O1` and release optimization; any active frame finishes the version it entered, and the superseded version is reclaimed once its pin count drops to zero. If Submission 3 instead defines `fn compute(x: i64, y: i64) -> i64`, `compute` is redefined in session scope (no overload set), `caller()` keeps its pinned 1-arg version, and the kernel reports that `caller` still calls the old signature.

## 15. Source basis and standards boundaries

**User-provided inputs, preserved as design sources:**

1. *v0.17.0 Lifestyle Enablement Release: Plan*, dated 2026-11-27, measured against commit `94195e2` (persistent ORC session, Jupyter kernel, net primitives, core rich display, cross-platform UAT).
2. *With v0.17.0 — Normative Specification Addendum* (previous broad companion document; this spec extracts and supersedes its Jupyter-engine contracts).
3. *Mission & Architecture Audit Rulings* (2026-11-27): session-frame locals preserving D52, structured session unwinding, pin-counted JIT retention, hermetic battery vs `uat/` split (D171), `c contract` / `c facts` (D202), no function overloading, `Present` automatic `Display`/`Debug` fallback, `%get` strict 1:1 `with get` passthrough, `with kernel status` / `with kernel install --check`, `-O1`/release-only optimization testing, and splitting full time-travel debugging into a separate future proposal while keeping `TT-030` in v0.17.

**External specifications to follow at implementation time:**

- Jupyter Messaging Protocol / `jupyter_client` message details: <https://jupyter-client.readthedocs.io/en/stable/messaging.html>
- Jupyter debugger protocol: <https://jupyter.org/enhancement-proposals/jupyter-debugger-protocol/>
- Kernelspec format and interrupt mode: <https://github.com/jupyter/jupyter_client/blob/main/docs/kernels.rst>
- JupyterLab services execute options: <https://jupyter.org/services/interfaces/kernelmessage.iexecuteoptions.html>
- ZeroMQ ZMTP 3.0 protocol specifications (use published normative wire rules, not assumptions from libzmq behavior)
- LLVM ORC, target-specific debug metadata, and platform JIT entitlement documentation (use matching LLVM/OS versions)
- Microsoft Debug Adapter Protocol and Jupyter's documented debugger extensions (advertise only implemented requests)

If these external standards and an illustrative description here conflict on message format, **the external wire standard wins**; update this document and fixtures accordingly. This exception does **not** permit changing With's ownership or runtime contracts without explicit architectural approval.

---

**Definition of done for the v0.17 Jupyter engine:** A real notebook frontend can create one persistent With session, execute JIT-compiled native code cell-by-cell without replay, preserve session-frame ownership and compiler state safely, call C libraries via `c contract` / `c facts`, display useful results with automatic `Display`/`Debug` fallback, receive accurate semantic feedback, interrupt and recover from supported With panics via structured session unwinding, reclaim unpinned JIT code, preserve immutable submission/version identities (`TT-030`), debug honestly with forward DAP stepping, and shut down cleanly—with hermetic battery gates and `uat/` frontend tests green on every advertised platform.
