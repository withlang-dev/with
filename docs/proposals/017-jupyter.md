# With Jupyter Engine
## Normative architecture, semantics, protocols, debugging, and verification

**Status:** Proposed architecture for approval; **not** an assertion that features are already implemented.  
**Baseline:** With repository commit `94195e2` (2026-11-27), as named in the supplied v0.17 plan.  
**Scope:** The persistent execution engine and every dependency required to run, inspect, debug, and reliably operate With code as a Jupyter kernel.  
**Out of scope:** The v0.17 release schedule, REPL product UX, shell one-liners, game/desktop SDKs, general editor plugins, general-purpose math/jq/SQL Server initiatives, browser notebook UI, and independent query-language design.  
**Precedence:** Once accepted, this document supersedes contradictory Jupyter-engine provisions in the v0.17 release plan and the earlier broad normative addendum. It does not silently override the core With language specification. Explicit semantic changes are recorded in §2.  
**Notation:** **MUST** is mandatory; **MUST NOT** prohibited; **SHOULD** a strong default with documented reason for any exception; **MAY** optional. Rule IDs are stable references for agent tasks and conformance tests. Names of internal APIs below are conceptual unless explicitly presented as existing With CLI syntax.

---

## 1. Product contract and architectural boundary

**ENG-001 — Mission.** A Jupyter frontend MUST be able to submit independent With cells to one persistent native-code session; retain owned values, types, functions, imports, and scheduler state between executions; interact with native C libraries; receive precise protocol-compatible outputs and diagnostics; interrupt supported running computations; and inspect the session's history and debugger state. Executing cell N MUST NOT reexecute earlier cells implicitly.

**ENG-002 — One engine.** Jupyter is an adapter over a reusable `SessionEngine`, not an alternative language interpreter. The parser, resolver, type/ownership checker, compiler, LLVM ORC materializer, scheduler, global store, diagnostic mapper, and semantic inspection APIs MUST be shared by any future REPL or notebook-file runner. The Jupyter adapter owns wire protocol, connection file, message routing, frontend-specific display, and kernelspec installation.

**ENG-003 — In-process execution.** The core engine executes LLVM ORC JIT code in the kernel process. The native execution model is deliberately in-process; arbitrary native-memory corruption, `abort()`, or native deadlock is **not** promised to be recoverable. Any later out-of-process execution backend MUST obey the same session-semantic interface but may offer stronger isolation.

**ENG-004 — Supported platforms.** The acceptance matrix includes macOS arm64, Linux, and Windows on the architectures distributed as supported. Every claimed platform MUST pass native JIT, unwind, networking, JupyterLab, SQLite, and raylib checks; unsupported OS/ABI combinations fail with a named, actionable diagnostic. A platform cannot be advertised solely because a build succeeds.

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
      Frontend/   Ownership/   Scheduler + global store
      compiler    source map          |
            \        |              /
                LLVM ORC JIT
             /       |       \
        With runtime  C/Clang  Native libraries
                  |
            Timeline/recorder
```

**ENG-006 — Dependencies that are in scope.** Session-scoped compiler state; LLVM bridge and ORC; main-thread execution executor; runtime drop/unwind/cancellation; C import/migration and native-symbol resolution; `std.net` byte I/O/poll; pure-With ZMTP; Jupyter message implementation; parser-backed completeness and read-only semantic inspection; `Present`/MIME display; local kernelspec installation and diagnostics; source/debug metadata; timeline and explicitly gated reverse-debug backends; corresponding conformance/UAT tooling.

**ENG-007 — Features that consume the engine but do not define it.** A future `with repl`, notebook conversion utility, text-notebook editor integration, game SDK, `from` query optimizer, or database backend may consume this API. Their distinct semantics and implementation are **not** prerequisites for this specification. The existing `with get` package manager is an integration dependency for the `%get` command, not a license to redesign package management here.

## 2. Locked decisions and departures from the source plan

The following choices are **proposed normative replacements**, made to eliminate ambiguity across independent implementations. Accept or revise each *before* assigning downstream implementation tasks.

| ID | Decision to lock | Reason |
|---|---|---|
| DEC-01 | Compile/link errors have zero user-visible execution effect. A runtime panic/interrupt does **not** roll back completed effects. | Arbitrary in-process native side effects cannot be transacted. |
| DEC-02 | Top-level rebinding is by name, not by notebook-file cell ID. | Jupyter `execute_request` does not reliably convey an authored cell identity. |
| DEC-03 | Incompatible type redefinition is rejected while live values/ABI dependents exist; do not silently drop transitive globals. | Preserve ownership and prevent surprising destruction. |
| DEC-04 | Same-ABI function replacement uses stable versioned dispatch; stored safe function values follow the replacement. | Cross-cell hot replacement must survive optimized code and escaped handles. |
| DEC-05 | The persistent session compiler is versioned; compilation and introspection operate on coherent snapshots. | Avoid races and stale semantic results. |
| DEC-06 | Only controlled With state is session-isolated. Native process globals, file descriptors, OS environment, and arbitrary C state are not. | In-process isolation has hard boundaries. |
| DEC-07 | Time-travel **inspection** and live-state **restoration** are different operations with different eligibility checks. | Historical observation cannot undo real-world side effects. |
| DEC-08 | Full native reverse stepping is backend-gated; DWARF maps recorded machine states to source but does not record execution. | Never advertise unsupported reverse execution. |
| DEC-09 | `with kernel install` is Python-free; the external Jupyter frontend may itself require Python. | Distinguish kernel distribution from frontend installation. |
| DEC-10 | Protocol 5.5 features are advertised only if implemented and exercised end-to-end. | Clients must not infer nonexistent debugger, comm, or subshell capability. |

**ENG-008 — Change control.** A decision change MUST update: this normative text, the session API schema, associated golden test fixtures, affected UAT, and downstream consumers in the same change set or a coordinated versioned transition. Independent agents MUST NOT silently redefine these choices.

## 3. Terminology, state, identities, and lifecycle

**SES-001 — Session.** A `Session` contains: a unique `session_id`; versioned compiler/semantic catalog; session-specific Clang/C migration handles; import table; project root; owned-global slots with initialization/move states; persistent task registry and scheduler; source/submission ledger; executable-code tracker; Jupyter execution counter (when attached to Jupyter); output router; cancellation state; diagnostic history; and optional recorder/timeline. Process-global immutable compiler tables and synchronized content-addressed caches may be shared.

**SES-002 — Submission.** A submission is one complete source string delivered for evaluation. In Jupyter it comes from an `execute_request`. Its internal `submission_id` is unique and independent of notebook cell IDs or execution counters. The source is immutable after acceptance and is retained for source maps and debugging until no debugger/history references remain.

**SES-003 — Execution count.** The Jupyter prompt counter increments exactly for executed requests that store history, following the protocol's `store_history` rules; `silent=true` forces `store_history=false`. Failures of counted requests still receive their count. A `submission_id`, Jupyter execution count, and notebook-file `cell.id` are three different identifiers. No state rebinding may depend on equality of these identifiers.

**SES-004 — Binding identity.** `(session_id, logical_name, generation)` identifies a persistent binding version. The public name resolves to the latest valid generation. `let` is immutable within ordinary program execution but may be explicitly replaced by a subsequent top-level declaration; `var` permits in-place mutation under existing language rules. Moved/uninitialized and dropped states are tracked without inventing sentinel values.

**SES-005 — Declaration identity.** A function's ABI identity includes resolved parameters, return type, calling convention, ABI attributes, generics/specialization, and compiler-required layout details. A nominal type identity includes its definition version, even if a new version happens to have the same field layout. Trait/impl changes have versioned dependent catalogs.

**SES-006 — Source location.** Every diagnostic references `submission_id`, optional Jupyter execution number, original source line/column, compiler phase, and ownership provenance. User-facing cross-cell diagnostics say e.g. `value moved in cell [2], line 1` or `view ended with cell [2]`, not raw synthesized function names.

**SES-007 — Session states.** A session is one of `starting`, `ready`, `executing`, `paused`, `closing`, `closed`, or `poisoned`. The transition `poisoned → ready` is forbidden. A poisoned session rejects new code and requests a process/kernel restart if reset cannot establish a safe state.

**SES-008 — Single writer.** Compiler publication, owned-global mutations, scheduler advancement, and cell execution have one serialized session executor. At most one With cell body is running in the process-main-thread executor at a time. Network/heartbeat/control threads MAY collect, authenticate, queue, and service read-only requests but MUST NOT mutate user-owned values directly.

### 3.1 Submission lifecycle and atomicity

**EXE-001** Each source submission follows:

```text
received → queued → parse → resolve/check → lower → materialize
      → publish declarations → execute statements → finalize output
```

The compiler MUST check against one coherent snapshot of the currently published catalog together with candidate declarations from the submission. Materialization may allocate *unpublished* JIT resources. Before publication, failure MUST release candidate resources and leave all user-visible compiler/session state unchanged, apart from diagnostic/history records.

**EXE-002 — Compile-phase failure.** If parsing, resolution, ownership validation, code generation, native-symbol resolution, or JIT materialization fails, the submission executes **no user statements**, publishes no declarations or slots, and schedules no user tasks. A cache may change internally, but not observable source semantics.

**EXE-003 — Publish and execute.** Once the complete submission has compiled and linked, declarations are published together. Executable top-level statements then run **in source order**, exactly once. Successful earlier statements remain effective if a later statement fails. There is no cell-wide runtime rollback guarantee.

**EXE-004 — Error recovery.** A supported With panic, checked runtime error, or cooperative interruption unwinds current With frames; drops owned live stack values in reverse construction order; releases cell-local views; records a structured error; and returns to `ready` **only** if owner tracking and runtime invariants remain consistent. Already-completed moves, mutations, drops, file/network writes, and native side effects remain.

**EXE-005 — Destructor failure.** User `Drop` implementations MUST satisfy the non-unwinding destructor contract. If a destructor panics during unwinding or leaves an ambiguous owner graph, transition to `poisoned`, reject new execution, and require restart if no proven-safe cleanup path exists. Never resume based on guessed ownership state.

**EXE-006 — Statement failure ordering.** A failing initializer does not publish its incomplete new slot. However, side effects or moves it already performed on existing values remain, consistently with ordinary runtime failure. A succeeding initializer may replace an old value only after the new value is fully constructed and the replacement point is reached.

### 3.2 Top-level globals, moves, and views

**OWN-001** Top-level `let`/`var` declarations introduce persistent owned slots. Read/move/assign/drop follow the same ownership rules as equivalent function-local operations. The session preserves ownership and move provenance between submissions.

**OWN-002 — Rebinding.** A repeated top-level name is an explicit rebind of that *name*. It does not implicitly erase other bindings that appeared in the same notebook editor cell previously. An initializer is evaluated to a temporary owned result; then the slot replacement and old-value drop occur exactly once under the language's drop semantics. If a rebind requires changing a slot's static type while compiled dependents exist, reject with the complete known dependency chain rather than reinterpret old code.

**OWN-003 — Rebind corner cases.** For `x = f(x)` and similar self-referential initializers, reads of an existing live `x` use its current value and obey its existing ownership rules. A move of `x` may leave the old slot empty before `f` finishes. If `f` fails, that move is **not** reversed. No old value may be dropped twice. This rule takes precedence over any informal expectation that failed rebinds always preserve the previous value.

**OWN-004 — Views.** Cell-top-level views are lexical to the submission. They MUST NOT escape to globals, closures, or persistent tasks unless an existing language rule proves an independently owned representation. Later access produces a precise `view ended with cell [N]` diagnostic. The script top level counts as one submission for this purpose.

**OWN-005 — Old compilation.** Previously compiled code that operates on persistent globals MUST consult the correct current slot/version/ownership state, or fail before unsafe access. A later move or rebind cannot cause an older function to read freed memory. Static rejection is preferred when the state is known; dynamic guards are required across versioned boundaries.

**OWN-006 — Drops and reset.** Normal rebinding drops only the previous live value in the named slot, not unrelated state. A reset drains/cancels supported tasks, performs dependency-safe drops, revokes session handles, invalidates live runtime history, and retains the project manifest. It cannot undo external effects or guarantee unloading an arbitrary native library.

### 3.3 Functions and type redefinition

**DEF-001 — Same-ABI function.** Redefining an identical fully resolved function identity creates an immutable implementation version and updates one stable dispatch entry atomically. Future calls through safe With handles—including stored function values and old compiled callers—use the latest body. An active frame finishes on the body it entered.

**DEF-002 — Stable boundary.** Calls crossing replaceable code-version boundaries MUST use indirection. Cross-version inlining or devirtualization is forbidden where it would change the above semantics at `-O1` or production optimization. Internal helpers within one immutable version MAY be optimized freely.

**DEF-003 — Changed ABI.** A differing signature creates a distinct version/overload if the core language allows it; old compiled callers keep their original ABI target. New callers follow ordinary overload resolution; ambiguity is an error. Return-type-only or constraint changes cannot silently overload if language resolution cannot distinguish them. Report earlier call sites that still refer to the old version.

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

**JIT-001 — Persistent context.** A session uses one persistent logical compiler and an ORC execution context for all its submissions. Declarations join the session's versioned catalog; executable top-level statements become uniquely named synthesized cell functions that run once. Separate sessions MUST NOT share mutable compilation state, symbol catalogs, or owned globals.

**JIT-002 — Version bookkeeping.** Each materialized compilation unit has a unique version ID, ORC resource tracker, symbol/export list, imported-native dependency set, debug/unwind registrations, executable bytes, pin reasons, and state (`candidate`, `published`, `retired`, `retained`). Publication is all-or-nothing at the catalog boundary.

**JIT-003 — Reclamation.** Code MUST NOT be reclaimed while an active frame, task continuation, safe function handle, C callback trampoline, debugger history snapshot, or recorder checkpoint may reference it. The conservative default is to retain superseded versions until a safe reset/teardown. Retention MUST be observable, have configurable memory limits, and fail with a named resource-limit error rather than crash or silently evict reachable code.

**JIT-004 — Native resolution.** Resolve symbols in deterministic order: explicitly imported session bindings → explicit locked package dependencies → With runtime/standard symbols. Ambiguity at the same priority is a hard link error. Do not accidentally import symbols from an unrelated module merely because they are already loaded in the process.

**JIT-005 — Archives/frameworks.** ORC MUST resolve dynamic shared libraries, static archives, platform frameworks, relocation requirements, and transitive dependencies through explicit target/lockfile metadata. Error messages identify the missing symbol, object/library, target, and import that required it. Tests MUST exercise `sqlite3` and `raylib`, including static archives and macOS frameworks as applicable.

**JIT-006 — Session-scoped C bridge.** Mutable Clang parser, `c_import`, C migrator, header search, and C facade state MUST be per session. Shared immutable tables or synchronized content-addressed caches are allowed. Two sessions importing the same header concurrently must not contaminate one another's ABI assumptions.

**JIT-007 — Native-library lifetime.** A native library or callback remains pinned while live values, code, tasks, and registered callbacks depend on it. If a C API cannot unregister a callback safely, keep the corresponding code and trampoline pinned until kernel-process exit, report it, and prevent unsafe hot-replacement.

**JIT-008 — Platform JIT validity.** Executable-memory permissions, code signing/entitlements, allocator protections, relocation, stack unwinding, symbol/debug registration, and platform-required JIT write/execute transitions are **foundation checks**, not documentation-only release polish. `with doctor` must show actionable capability failures.

**JIT-009 — Unwinding.** Register target-appropriate unwind information for every executable code range (`.eh_frame` on relevant ELF systems, `__unwind_info` or equivalent on macOS arm64, `.pdata`/SEH unwind metadata on Windows as appropriate). Register before publication; deregister only after code is unreachable. Prove With panic, async panic, and cancellation unwind through ORC-created frames on each claimed platform.

**JIT-010 — Optimized debugging.** Generate native source mappings and target-correct debugging metadata; on DWARF platforms this includes line tables, location lists where required, inlining ranges, and usable call-frame info. Optimized-away variables MUST be reported unavailable, not fabricated. Debug metadata is a source interpretation layer, not a reverse-execution recorder.

**JIT-011 — Teardown ordering.** Stop accepting submissions → request cancellation and drain supported tasks → deactivate exported callbacks/trampolines → drop live globals safely → release debug/recorder pins → retire JIT versions → unload native libraries only where safe → close session. If teardown cannot meet these invariants, report retained pinned resources and request full process exit.

**JIT-012 — Observability.** Engine metrics MUST include live/pinned/retired code bytes, code versions per symbol, count/reasons of pinned callbacks, unresolved imports, compilation/materialization time, per-session global/heap use, and retained timeline storage. A long-running session cannot accumulate unbounded resources without showing usage and enforcing configured ceilings.

## 5. Main-thread executor, isolation, cancellation, and failure classes

**RUN-001 — Execution threading.** All user With cell bodies and scheduled With fibers execute on the process main thread (required for supported native GUI/window operations). Protocol, heartbeat, and network I/O use other threads. Concurrent frontends or two `Session` objects queue to one main-thread executor; they do not execute user cells concurrently within a process.

**RUN-002 — Consistent read-only inspection.** Completion/inspection/history/debug reads MUST use an immutable published snapshot or a main-thread safe point. No frontend request may dereference mutable JIT-owned memory concurrently without synchronization and ownership validation.

**RUN-003 — Per-session isolation.** Symbol tables, owned globals, source maps, import catalogs, JIT domains, tasks, and cancellation flags are session-specific. OS file descriptors, loaded shared libraries, environment variables, process working directory, signal handlers, and arbitrary C static variables remain process-scoped. The two-session gate compares controlled outputs/diagnostics after normalizing addresses, timestamps, and generated IDs; it does not promise arbitrary native-process isolation.

**RUN-004 — Working directory.** Each session captures its absolute project root at creation. Paths for package imports and kernel-local resources resolve relative to that root without process-wide `chdir`. If native code changes CWD, that is an explicitly unisolated native side effect.

**RUN-005 — Cancellation token.** Cancellation is keyed by session ID and active submission. Instrument With function entry, loop back-edges, and fiber suspend/resume points in **session-compiled** code. Control-channel `interrupt_request` sets the token promptly, even while a cell is executing. Do not silently add equivalent checks to unrelated noninteractive binaries.

**RUN-006 — Interrupt semantics.** The kernel acknowledges that an interrupt was **requested**, not that execution necessarily stopped. It becomes effective when With code reaches a checkpoint. Blocking native C calls and foreign deadlocks are not guaranteed interruptible. Stdin waits and With scheduler waits must be woken cooperatively.

**RUN-007 — Foreign failure boundary.** A With panic may be recovered only across supported With runtime frames. Foreign segmentation faults, `abort()`, arbitrary C++ exceptions, memory corruption, and uninterruptible native calls are outside that guarantee. A With panic MUST NOT unwind across an unsupported C ABI frame. Facades must use ABI-safe error/reporting or reject an unsafe callback mode.

**RUN-008 — Output capture.** Capture kernel-process FD 1/2 once at startup through nonblocking pipes or equivalent, forwarding native `printf` and With output to IOPub stream messages. During serialized cell execution, assign controlled output to the current request; native background-thread output is best-effort and may be unattributable. Restore descriptors at teardown. Authentication, Control, and heartbeat MUST remain responsive when output is backpressured.

**RUN-009 — Poisoning.** Failure of core ownership or unwind invariants marks the session poisoned. A poisoned session may answer read-only diagnostics and shutdown requests but MUST NOT execute arbitrary user code. It must not respond with a superficially healthy `ready` state.

**RUN-010 — Operational limits.** Configurable limits MUST exist for: compile/runtime memory, JIT code cache, global heap, task count, message sizes, output size/queue, timeline storage, and execution timeouts where cooperatively enforceable. Resource-limit messages MUST distinguish user-configured ceilings from OS allocation failure.

## 6. `std.net` substrate and pure-With ZMTP 3.0

This layer is required for the Jupyter kernel but is intentionally reusable independently of Jupyter.

**NET-001** Socket send/receive APIs operate on byte slices and return actual transferred lengths. Never assume UTF-8 or NUL termination. Explicitly distinguish EOF, partial read/write, timeout, interruption, closed socket, and OS errors.

**NET-002** A multi-socket readiness poller supports read/write/hangup/error, monotonic deadlines, a wakeup channel for shutdown/interrupt, and handles POSIX `EINTR`/Windows equivalents. Close while polling must not cause an FD-reuse use-after-close. Busy spinning is prohibited.

**NET-003** A buffered multi-part framing layer MUST handle partial reads/writes, oversized lengths, malformed frame flags, peer disconnection, slow peers, and bounded memory use independently of Jupyter message content.

**ZMQ-001** The internal pure-With `std.internal.zmtp` implements the required **ZMTP 3.0 NULL** greeting, mechanism negotiation, READY metadata, framing, and routing for Jupyter's Shell/Control/Stdin ROUTER sockets, IOPub XPUB socket, and heartbeat REP behavior over local TCP. No `libzmq` or C++ runtime is required by the kernel.

**ZMQ-002** Application messages MUST NOT be accepted or published before the respective peer finishes the ZMTP handshake. Bad peers are disconnected without poisoning other peers or stopping the kernel. Correctly preserve DEALER identities and multi-client ROUTER envelopes.

**ZMQ-003** XPUB subscribe/unsubscribe frames MUST be consumed and represented as subscription state. Initial status publication SHOULD account for subscribers already connected, but startup MUST NOT block indefinitely awaiting subscribers. A late subscriber can obtain kernel state using protocol requests; the transport must not fabricate historical IOPub events.

**ZMQ-004** Conformance MUST use both the pure-With protocol test client and an independent real `libzmq` peer. Test fragmented frames, multipart routes, disconnection, subscriptions, authentication-frame boundaries, duplicate client identities where applicable, and backpressure.

## 7. Jupyter Protocol 5.5 kernel adapter

**JUP-001 — Version contract.** Implement the Jupyter Messaging Protocol **5.5** message/channel contracts used by the supported feature set. Supported features are enumerated in `kernel_info_reply`; message-type conformance is independently tested. The network transport and Jupyter envelope serializer/verifier MUST have separable tests.

**JUP-002 — Connection security.** Read and validate the Jupyter connection file **before** listening. The baseline supports `transport=tcp`, `ip=127.0.0.1`, five distinct valid ports, `signature_scheme=hmac-sha256`, and an explicit key. Unsupported transport, non-loopback binding, malformed ports, or unknown signature scheme MUST fail with actionable errors. An empty signing key is allowed only on loopback and triggers a visible warning; it is never described as authenticated.

**JUP-003 — Connection-file handling.** Keys and full authenticated request bodies MUST NOT appear in logs, crash reports, or `with doctor` output. File permissions and bind failures are checked. Binding multiple sockets is all-or-nothing: on partial startup failure, close previously bound sockets, report the failure, and exit without a half-working kernel.

**JUP-004 — Wire envelope.** Encode/decode `identity frames → <IDS|MSG> → signature → header → parent_header → metadata → content → optional binary buffers`. HMAC-SHA256 covers the **exact serialized byte frames** of the four JSON header/content objects in order. Verify before JSON parsing/executing instructions. Reject invalid signature length, malformed frame count, JSON errors, or unsigned messages (except a deliberately configured empty key) without disclosing secrets.

**JUP-005 — Integrity and bounds.** HMAC comparison is constant-time for fixed-length valid digests. Default inbound limits are 64 MiB/frame, 128 MiB/whole message, and 256 frames/message, configurable downward for restricted environments. Bounds are checked before large allocation. Protocol errors must release buffers and disconnect the offending peer without destroying unrelated sessions.

**JUP-006 — Channels.** Shell, Control, Stdin, IOPub, and heartbeat have separate queues and correct routing. IOPub events retain the corresponding `parent_header`; Shell replies go only to the requesting frontend. Stdin requests route to the frontend associated with the active execution; a reply from the wrong identity is rejected. Heartbeat remains responsive independent of compiler or user-code progress.

**JUP-007 — Lifecycle.** At startup publish `status: starting` according to protocol behavior, then service requests and publish correct `busy`/`idle` around handled requests. For a normal execution publish `busy`, `execute_input` when applicable, interleaved stream/display/error outputs, `execute_reply`, then `idle` with correct parent linkage. Flush ordered cell output before publishing `idle` to the extent it is controlled; late native asynchronous output is explicitly best-effort.

**JUP-008 — `execute_request`.** Accept and honor `code`, `silent`, `store_history`, `user_expressions`, `allow_stdin`, and `stop_on_error`. `silent=true` suppresses ordinary execution IOPub output and forces no history storage. History count advances only where protocol says it advances. `user_expressions` are evaluated after successful code execution under normal safety/effect rules; errors are recorded individually per expression. They are **not** presumed side-effect-free merely because the field is called an expression.

**JUP-009 — Queue errors.** When `stop_on_error` is true and an execution errors, abort the relevant pending execution queue according to the protocol, return explicit aborted/error replies as required, and keep heartbeat/control/shutdown functional. Never silently discard a queued request. The exact queue draining policy MUST be fixture-tested with two frontends so one frontend's error cannot arbitrarily destroy unrelated client state.

**JUP-010 — State reporting.** `kernel_info_request/reply` work on Shell and Control as applicable, including actual `protocol_version`, With `language_info`, banner, and `supported_features`. Do not advertise comms, debugger, subshells, or completion modes that are not backed by passing UAT. `comm_info_request` returns a valid empty `comms` object while widget comm traffic is unsupported.

**JUP-011 — Read-only semantic services.** `complete_request`, `inspect_request`, `is_complete_request`, and `history_request` use the session compiler's read-only semantic/history services. They MUST NOT execute user code or advance fibers. `is_complete` uses the parser, not bracket-counting heuristics. Completion cursor offsets use Unicode code-point indexing as Jupyter requires, not byte offsets; translated LSP offsets are not part of this kernel's protocol contract.

**JUP-012 — Interrupt/shutdown.** Handle `interrupt_request/reply` and `shutdown_request/reply` on Control. `interrupt_reply` confirms the request was received; it does not guarantee a stalled native library has exited. Graceful shutdown drains owned tasks and releases kernel resources when safe. When a frontend requests restart, follow the frontend/kernel manager's process-restart convention; do not pretend to restart a corrupted kernel in place.

**JUP-013 — Stdin.** Route a With `read_line()`-like operation to `input_request`/`input_reply` on the Stdin channel. When `allow_stdin=false`, fail immediately with a meaningful error; do not fall back to reading kernel terminal stdin. Interrupt and shutdown must unblock a pending frontend input request.

**JUP-014 — Multi-client behavior.** Multiple frontends share one kernel session. Submissions are linearized in the main-thread executor's accepted order. Replies preserve requester identity. Completion and inspection are snapshot-consistent. Clients must not assume notebook page order and must not receive another client's private Shell/Stdin reply.

**JUP-015 — Protocol test obligations.** The same transport/message implementation MUST pass independent pure-With tests, an external `libzmq` peer, and real JupyterLab. Conformance tests cover startup, authenticating, executing, display, errors, cancellation, completion, introspection, multi-client routes, and clean shutdown on each claimed platform.


## 8. Results, rich display, source introspection, and kernel commands

### 8.1 Display contract

**DSP-001 — Presentation interface.** A `Present`-style compiler/runtime trait (final name subject to the core language's naming conventions) converts a value into a Jupyter MIME bundle. It may include `text/plain`, `text/html`, `image/png`, `image/svg+xml`, `application/json`, and `text/markdown`. A compiler-derived Debug string is the safe plain-text fallback. Every emitted user result MUST provide `text/plain` unless the relevant protocol intentionally permits its omission.

**DSP-002 — Implicit result.** The completed expression result of a non-silent cell is emitted at most once as `execute_result` when the language's expression-result semantics provide a value. Explicit `display(value)` produces `display_data`. Do not implicitly display each intermediate statement, re-evaluate a final expression, or print non-displayable unit values unless language policy explicitly requires it.

**DSP-003 — Safety.** Presentation MUST NOT implicitly consume or move a persistent value. A `Present` implementation that has side effects is user code and follows ordinary runtime semantics; the engine MUST NOT secretly invoke it on completion/inspection paths that promise read-only behavior. Inspector preview requests therefore use a separate certified read-only formatter or return only type/provenance metadata.

**DSP-004 — Tables.** `List[Struct]` or an equivalent statically introspectable record collection MAY derive table display through `T.fields()`. Truncate long tables by row/byte limits with visible notices; escape HTML, bound cell sizes, preserve plain-text alternatives, and avoid allocating an unbounded copy just to render output. The notebook engine does not require a new `from` query language to demonstrate tables.

**DSP-005 — Binary and content types.** Binary `image/png` uses the Jupyter-compatible representation; other MIME entries follow protocol JSON serialization rules. Reject malformed MIME values, excessive payloads, and invalid markup inputs as explicit display errors rather than sending plausible but corrupt output. Do not silently accept arbitrary HTML injection from untrusted external data without the documented escaping/sanitization policy; explicitly user-authored trusted HTML remains a deliberate action.

**DSP-006 — Output queues.** Keep output ordering per submission. Output backpressure cannot stall heartbeat or authentication; cap queues, report truncation to the user, and keep compiler diagnostics intact where feasible. A cell's failure MUST NOT suppress its already completed output without telling the user.

### 8.2 Semantic analysis and kernel magic commands

**SEM-001** The compiler exposes a consistent read-only semantic snapshot supporting symbol lookup, type inspection, ownership/move provenance, completion, signature/hover information, expression completeness, and source-mapped diagnostics. This is a dependency of the kernel's Jupyter completion/inspection and debugger interfaces, **not** a mandate to build an entire language-server/editor ecosystem.

**SEM-002 — Command parsing.** Kernel `%` commands are interpreted at submission start by a shared command dispatcher rather than compiled as ordinary With. A command never triggers replay of previous submissions. Unsupported/unknown commands fail with their exact name and available commands.

**SEM-003 — Core command set.** The kernel command dispatcher supports `%get`, `%remove`, `%deps`, `%reset`, `%time`, `%who`, `%type`, and `%help`. `%get` uses existing package-manager semantics and updates future import resolution, without retroactively rewriting old compiled code. The project root is discovered at session startup or defaults to the kernel's startup directory, not an imagined notebook-file path. `%remove` checks dependencies; removing a package does not unload pinned native code. `%who` shows name, static type, live/moved/uninitialized state, generation, and provenance. `%type` is read-only. `%time SOURCE` executes exactly once, showing compilation and execution time separately. `%reset` follows `OWN-006`. The command table itself generates `%help`.

**SEM-004 — Source history.** Store submission source, execution order, result class, error summary, and metadata for Jupyter `history_request`, debugger source mapping, and the timeline. History source is not the same as a replayable native-memory snapshot. History retention is bounded and configurable. Non-persisted (`store_history=false`) Jupyter submissions still require ephemeral source maps while executing, but are not silently appended to the public input-history collection.

## 9. Debugger integration and source-level stepping

**DBG-001 — Two independent capabilities.** The kernel has (a) forward source debugging over live JIT code and (b) historical inspection/reverse navigation when an execution recorder provides history. It MUST NOT equate debugger source metadata (DWARF/PDB or equivalent) with an execution recorder. Debug metadata only interprets machine states obtained by some other mechanism.

**DBG-002 — Jupyter debugger protocol.** When debugging is supported, accept Jupyter `debug_request`/`debug_reply` on Control and emit `debug_event` on IOPub. Contents follow the Jupyter debugger extensions to DAP, including notebook-specific source registration (`dumpCell`), debugger state restoration (`debugInfo`), and supported variable inspection. Advertise `'debugger'` in `kernel_info_reply.supported_features` **only after** the required request/event compatibility suite passes.

**DBG-003 — Immutable source identities.** Every submission has a canonical immutable virtual source identity and source text. Where a debugger requires actual files, mirror exact source bytes in a secure kernel-owned temp directory with stable versioned paths, user-only permissions, and cleanup policy. A new submission or edited cell MUST NOT overwrite the source corresponding to an earlier compiled code version or recorded event. The Jupyter `dumpCell` mapping must be deterministic for identical source bytes within the session without implying that edited content is the same execution.

**DBG-004 — Debug state.** Maintain breakpoints, source-version references, selected execution/frame, paused state, and active recorder backend in session-owned debugger state. The `debugInfo` response MUST be consistent with what has actually been installed, including behavior after a frontend reconnects.

**DBG-005 — Safe pause.** When paused at a With safe point, the main-thread executor runs a restricted debugger control loop and does not start unrelated user submissions. Control channel remains responsive. Source inspection uses paused-state read-only views. Stepping resumes only the selected recorded/live execution domain. Native code outside With-controlled safe points may not be pausable by the core engine without a platform debugger backend.

**DBG-006 — Stack and variable truthfulness.** Source mapping uses statement boundaries, actual compilation versions, inline frame info, live owner states, and target-native debug information. If a value has been moved, dropped, optimized out, or made inaccessible by the runtime, report that exact status rather than inventing a historical value. A debug print must not accidentally call an unsafe formatter or perform arbitrary user side effects.

**DBG-007 — Debug capabilities.** DAP capabilities including `supportsStepBack`, `supportsReverseContinue`, and normal stepping/variable requests are negotiated according to the active backend's proven support. If native reverse stepping is unavailable, fail explicitly. Do not synthesize a `stepBack` success by merely moving a source-code cursor to a previous line.

## 10. Time travel: event history, checkpoints, reverse inspection, and restoration

This section is deliberately part of the **core engine architecture**, not a general UI feature. It formalizes the earlier reverse-debugging discussion and avoids the misleading assumption that in-process JIT execution is automatically reversible.

### 10.1 Required data model

**TT-001 — Two clocks.** Maintain (i) a monotonic `event_id` for runtime/debug/timeline events and (ii) a monotonic `submission_id`/Jupyter execution order for cell requests. A source line can execute many times; program counters and source lines are not unique historical events. Timeline entries MUST refer to concrete execution instances, not simply source locations.

**TT-002 — Versioned metadata.** The session's symbol catalog, declaration/version graph, source maps, code pins, global-slot identifiers, and task registry metadata are versioned or snapshot-addressable at cell boundaries. Versioned metadata does **not** imply that arbitrary native heap, stacks, file descriptors, and C library state have been snapshotted.

**TT-003 — Timeline entry.** At minimum, record: event ID; branch ID; parent event; submission/execution ID; outcome (`success`, `compile_error`, `runtime_error`, `interrupt`, `fatal`); touched root bindings and owner transitions when known; declaration/code versions; source provenance; checkpoint status; replay/inspection eligibility; and any reason that restoration is forbidden. Event payloads and source text obey bounded retention and privacy rules.

**TT-004 — Recorder abstraction.** Define a pluggable `ExecutionRecorder` with capabilities `none`, `cell_state_snapshot`, `deterministic_replay`, and `native_instruction_history`. These capabilities are *orthogonal*: a backend may support cell snapshots without instruction history, or historical inspection without live restore. Report capabilities explicitly per session, target, and current state.

Conceptual interface (not frozen public With syntax):

```text
SessionTimeline:
    list_events(range) -> List[TimelineEvent]
    inspect(event_id) -> HistoricalView | EligibilityError
    checkpoint() -> CheckpointResult
    restore(checkpoint_id) -> RestoreResult
    branch_from(checkpoint_id) -> BranchId
    status() -> TimelineCapabilities

ExecutionRecorder:
    begin_submission(submission_id)
    record(runtime_event)
    finish_submission(outcome)
    available_range() -> EventRange
    reverse_step(execution_point, granularity) -> ExecutionPoint | Unsupported
    reverse_continue(criteria) -> ExecutionPoint | Unsupported
```

**TT-005 — Observation versus mutation.** `inspect(event_id)` returns a read-only historical view. It MUST NOT change the live running session, reexecute user code, resend network messages, or change files. `restore(checkpoint_id)` is a *state-mutating* operation, and MUST pass a comprehensive eligibility check before touching any live state.

### 10.2 Cell-level rewind eligibility

**TT-010 — Baseline checkpoint.** At the beginning and completed boundary of each submission, record enough managed metadata to establish source, symbol versions, binding/move provenance, and what recorder capability was active. A full restorable heap snapshot is required **only when** the engine asserts that the checkpoint is `restorable`.

**TT-011 — Restorable classification.** A cell checkpoint is `restorable` only when the recorder can reconstruct **all** semantically relevant With-owned memory, owner states, globals, task/fiber frames, code-version references, and registered managed resources, and no uncontrolled effect invalidates the state-continuation guarantee. Values with unsupported native handles/raw pointers/callback ownership make the checkpoint `inspect_only` unless an explicit backend-specific safe snapshot mechanism covers them.

**TT-012 — External effects.** The engine cannot undo writes to arbitrary files, a database, a network, an opened GUI window, environment mutations, or C static state. Once such an effect is possible but not tracked/compensated by a proven backend, a *live* session restore across that boundary is forbidden. The timeline may remain inspectable; label the boundary with the reason. Recording that an effect occurred does **not** mean it was reversed.

**TT-013 — Restoring.** A restore must occur at an executor quiescence point with no active untracked callback, no outstanding native call, no untracked concurrent mutation, and no paused machine frame whose ABI would be invalidated. Restore versioned declarations and owned state **together**; update dispatch entries atomically; reconcile/destroy the current branch's owned values without double-drop; revoke any handles that cannot remain valid. Any uncertainty aborts before state mutation or poisons the session if partial recovery already occurred.

**TT-014 — New futures.** The first new execution after restoring a checkpoint creates a new branch. Historical event IDs remain immutable and may still be inspected while retained. `forward` through recorded history is inspection/navigation, not blind reexecution; to resume a former state as live requires a separate eligibility-checked restore.

**TT-015 — Limits.** Snapshot interval, retained bytes, event count, and recorded duration are configurable with explicit expiration/eviction diagnostics. Evicting a checkpoint must unpin its code references safely. Never evict state required by an active debugger stop or reachable task without an explicit failure/transition.

**TT-016 — Runtime errors and moves.** A runtime-failed cell is still represented in timeline history with its completed mutations/moves/drops. A previous checkpoint may be restorable only if the intervening state changes can all be reversed under the active recorder's contract. A compile error records a diagnostic event but has no execution effects to undo.

**TT-017 — User operations.** The engine MAY expose `%timeline` to list checkpoints, `%back` to request a *live* restore of the preceding eligible cell checkpoint, and `%forward` to inspect later history. If implemented, `%back` MUST fail with a specific reason for `inspect_only` checkpoints and MUST NOT degrade into a visually convincing but fake rewind. For notebook clients lacking these commands, equivalent operations may be exposed through a documented kernel-specific API; neither is automatically a standard Jupyter message.

### 10.3 Native reverse debugging

**TT-020 — Machine history required.** Source-level `reverse-step`, `reverse-next`, and `reverse-continue` require a recorder capable of restoring prior registers, memory, instruction pointer, thread/scheduler context, and relevant nondeterministic events. Walking DWARF `.debug_line` backward is insufficient, particularly through loops, branches, function calls, and foreign code.

**TT-021 — Debug information.** DWARF `.debug_line`, `.debug_info`, location lists, range lists, and call-frame/unwind information (or target-equivalent formats) interpret a restored machine state. They do not themselves generate a previous state. Generated JIT code must register debug metadata so the debugger can resolve each retired-but-pinned version correctly.

**TT-022 — Backends.** A Linux record/replay backend (e.g., rr-compatible infrastructure) and LLDB/GDB remote reverse packets are potential implementations; platform support is conditional on **working execution-recording coverage**, not the existence of a CLI flag. Other operating systems may use a different recorder. No undocumented platform parity is promised.

**TT-023 — DAP reverse.** Only when actual native reverse history is present and tested may the debugger advertise DAP `supportsStepBack`/`supportsReverseContinue` and honor the associated requests. If only cell-level historical inspection exists, expose it as a distinct timeline capability; never label it native instruction/source reverse stepping.

**TT-024 — Fidelity tests.** The native reverse-debug conformance lane MUST include loops revisiting a source line, branches, nested calls, inlined/optimized functions, moves/drops, panic recovery, JIT function replacement, source edits, asynchronous fibers, and native C calls to the extent the recorder claims support. Unsupported cross-FFI history MUST report the exact recording boundary.

### 10.4 Why it must be designed now

**TT-030 — Architectural invariants.** From the first JIT implementation, source identity, code versions, native callback pins, ownership provenance, and event IDs MUST be usable by the recorder. Deferring full reverse execution is permitted; deferring these identity/lifetime hooks is not. Otherwise future historical views may refer to unloaded code or source that has been overwritten.

## 11. Installation, local diagnostics, and headless acceptance harness

**OPS-001 — Kernel CLI.** `with kernel install` installs a discoverable `kernel.json` with an absolute path to `with`, proper `argv` connection-file placeholder, `language=with`, display name, and `interrupt_mode=message` on all supported OSes. Installation MUST NOT require a Python dependency in With itself.

**OPS-002 — Installation paths.** Default to the current user's standard Jupyter data path, respecting documented environment overrides. `--prefix` and `--sys-prefix` are mutually exclusive; `--sys-prefix` must resolve to an explicitly known prefix and fail helpfully otherwise. `--check` verifies actual kernelspec discoverability and executable correctness without modifying files. Reinstalling With preserves unrelated kernelspecs.

**OPS-003 — Doctor.** `with doctor` reports kernel discovery paths, stale paths, native dependencies, transport bind capability, JIT executable-memory and unwind readiness, source/debug registration availability, and whether an authenticated localhost kernel handshake succeeds. It MUST NOT print connection secrets. It distinguishes available recorders from merely compiled-in debugger hooks.

**OPS-004 — Headless protocol driver.** Ship a pure-With Jupyter protocol client for conformance, plus a real `libzmq` interoperability lane and real JupyterLab smoke tests. Use the same production kernel path; no separate interpreter, mock compiler, or replay of earlier cells. These are required support infrastructure.

**OPS-005 — Notebook runner adapter.** A minimal `with notebook run` adapter MAY execute nbformat 4.5 code cells through the **same SessionEngine** in file order to support integration tests and reproducible examples. If provided, preserve source/metadata/attachments; default output is a separate `.executed.ipynb`; in-place overwrite requires explicit request and atomic replacement. This adapter is not permitted to define different ownership, error, or scheduler semantics from Jupyter.

**OPS-006 — Security posture.** The default kernel is local-only, authenticated by the connection-file key, and should be run with user-level OS privileges. This is not a hostile multi-tenant sandbox. Do not claim that `127.0.0.1`, HMAC, or in-process JIT contains malicious code supplied by an authenticated local user.


## 12. Verification gates (engineering dependencies, not release milestones)

These gates define **architectural readiness**, not dates or separate releases. Independent work may proceed in parallel when it consumes stable interfaces; merging a dependent feature requires its prerequisite gate to be green. Every gate executes on each platform the kernel claims to support.

### Gate A — Persistent native-session vertical slice

**GATE-A-1:** Compile, materialize, and execute a cell through ORC; publish one top-level global; execute another cell using it without replay. Assert source-specific diagnostics.  
**GATE-A-2:** Import a C header through a session-scoped compiler, call one real native function from JIT code, and resolve a static/archive symbol.  
**GATE-A-3:** Start a minimal actual Jupyter Protocol 5.5 handshake, execute one With cell, and observe proper Shell/IOPub/Control behavior through the pure-With client.  
**GATE-A-4:** Verify JIT code signing/executable-memory/unwind registration on macOS, Linux, and Windows supported targets **before** widening session semantics.

### Gate B — Ownership, versions, and recovery

**GATE-B-1:** Move a global in cell 2 and attempt to read it in cell 3. Reject with original-cell provenance. Rebind afterward and verify the new owner is live.  
**GATE-B-2:** Create a top-level view, then try to access it later. Reject with `view ended with cell [N]`.  
**GATE-B-3:** Compile failure with declarations plus top-level side effects must execute nothing and publish nothing.  
**GATE-B-4:** A runtime panic after global mutation and file output must unwind safely while preserving already completed effects.  
**GATE-B-5:** Successful same-name rebind drops the previous owned value once, does not erase unrelated names; failed initializer with an earlier move does not fabricate a restored old value.  
**GATE-B-6:** Same-ABI function replacement changes calls originating in previously compiled cells at `-O0`, `-O1`, and production optimization; saved safe function handles observe the new body. Active frames finish their entered version.  
**GATE-B-7:** A changed-signature function creates the exact required old/new call split. Ambiguous new overload resolution fails.  
**GATE-B-8:** Type redefinition with `List[Old]`, maps, captured closures, suspended task, or native callback that depends on `Old` is rejected with concrete blocker paths; unrelated values are not dropped.  
**GATE-B-9:** Persistent async task advances only during a deliberate cell-run/scheduler drive. An async-cell panic and interrupt unwind without orphan references.  
**GATE-B-10:** A panic during `Drop` poisons the session and prevents subsequent code from running.

### Gate C — Transport and multi-client protocol

**GATE-C-1:** Actual libzmq interoperability and JupyterLab can connect through authenticated ZMTP 3.0 on all five channels. Test XPUB subscribe/unsubscribe, ROUTER identities, and repeated connect/disconnect.  
**GATE-C-2:** Verify exact-frame HMAC; reject invalid signature, malformed JSON, oversized multipart messages, malformed greeting, and wrong Stdin identity without executing code.  
**GATE-C-3:** Execute success/error/interrupt with correct `busy → messages → reply → idle`, count/history semantics, parent headers, and targeted client replies.  
**GATE-C-4:** `silent`, `store_history`, `allow_stdin`, `stop_on_error`, and `user_expressions` each have positive and adversarial fixtures; two clients submit queued commands and continue to receive correctly routed replies.  
**GATE-C-5:** Main-thread execution of a GUI-sensitive native function coexists with Control/heartbeat responsiveness; C `printf` appears in IOPub `stream` output.  
**GATE-C-6:** Two sessions in one process have independent compiler state/owned globals/cancellation; a cancellation for one never cancels the other. Explicitly demonstrate the documented limits of native process-global isolation.

### Gate D — Inspector, display, and debugger

**GATE-D-1:** Completion, inspect, and completeness checks never execute a user statement, advance a task, or consume/move a global. Unicode cursor positions are correct.  
**GATE-D-2:** `Present` emits correct MIME bundles; HTML table output is escaped/truncated safely; exceptions in a user-authored renderer produce honest cell errors.  
**GATE-D-3:** Source maps remain accurate after repeated cell edits and function replacement; older JIT code still maps to its own immutable source version.  
**GATE-D-4:** A paused debugger can inspect a moved/optimized-out variable without fabricating a value; Control channel remains responsive. `debugger` is advertised only when the Jupyter debugger protocol tests pass.  
**GATE-D-5:** Unsupported DAP reverse stepping is rejected with `supportsStepBack=false`, never handled as cursor movement.

### Gate E — Timeline and reverse-execution foundations

**GATE-E-1:** Three pure managed-state cells (`x=10`, `x+=5`, `x*=2`) yield distinct immutable historical records. Historical inspection reports 10/15/30 accurately without changing the live value.  
**GATE-E-2:** With a recorder that declares safe managed-state snapshotting, restoring the cell-2 checkpoint returns owned values, declaration versions, and function dispatch to cell-2 state; a new execution creates a new branch with no double-drop.  
**GATE-E-3:** A cell performing untracked file/native side effects marks prior-crossing checkpoints `inspect_only`; attempting a live restore returns a clear nonrestorable explanation and leaves the live state untouched.  
**GATE-E-4:** Old code and debug maps are pinned as long as any retained checkpoint/active frame can reference them. Eviction and session reset release pins only when safe.  
**GATE-E-5:** Any backend advertising native reverse step passes branch/loop/call/FFI/optimized-code replay tests on its claimed platform. Unsupported platforms truthfully expose no native reverse capability.

### Gate F — Installation and endurance

**GATE-F-1:** `with kernel install`/`--check`/`with doctor` work on clean target systems without requiring Python in the With kernel installation itself; real JupyterLab sees the kernelspec.  
**GATE-F-2:** Real notebooks covering ownership, prior-cell function replacement, native SQLite, native raylib, rich display, async cells, interrupts, and source/debugger maps execute successfully through production paths.  
**GATE-F-3:** A soak test executes thousands of submissions, redefinitions, asynchronous tasks, compile failures, runtime errors, and optional timeline recordings. Memory use, pinned code versions, descriptor counts, and compilation latency remain within configured budgets or fail visibly at limits.  
**GATE-F-4:** The shutdown path does not leave owned live handles dangling or hide registered unwind/debug resources. When a native library prevents unloading, the kernel records and reports that limitation honestly.

### 12.1 Adversarial scenario matrix

| Scenario | Required outcome | Rules |
|---|---|---|
| Re-execute edited cell that removed `b` | `b` remains unless explicitly removed; rebinding of `a` affects only `a` | SES-004, OWN-002 |
| New initializer moves old `a`, then panics | Prior move remains; no double-drop or fake rollback | EXE-006, OWN-003 |
| Compile error follows proposed `fn` declaration | Candidate function not published | EXE-002 |
| Runtime panic follows successfully published `fn` | Function remains published, prior side effects remain | EXE-003, EXE-004 |
| Old stored safe `fn` value after replacement | Calls latest same-ABI body | DEF-001, DEF-004 |
| Redefine `T` while `Task[List[T]]` is live | Block redefinition with dependency path | DEF-005 |
| Interrupt during pure With infinite loop | Cooperative unwind and ready session, if no poison | RUN-005, RUN-006 |
| Interrupt inside uncooperative C call | Request acknowledged; completion not falsely guaranteed | RUN-006, RUN-007 |
| Frontend reconnects while source version is retired | Debug mapping still resolves correct original submission | JIT-003, DBG-003 |
| Reverse inspect after file write | Historical view permitted if recorded; no filesystem modification | TT-005, TT-012 |
| Live restore over unknown C state | Refuse, explain exact eligibility blocker | TT-011–TT-013 |
| Jupyter requests reverse step without recorder | DAP says unsupported; no fake movement | DBG-007, TT-023 |
| Two frontends issue Shell requests, one requests input | Stdin and Shell replies go only to rightful requester | JUP-006, JUP-014 |
| Invalid HMAC and valid request arrive together | Invalid request never executes; valid connection remains functional | JUP-004, JUP-005 |

## 13. Shared interfaces and swarm coordination contract

The following are **semantic boundaries**. Exact API names and wire schemas should be captured in machine-readable fixtures before parallel implementation begins.

| Contract | Primary owner | Consumers | Stability gate |
|---|---|---|---|
| Session lifecycle, submission and state snapshot API | Session engine | Jupyter host, CLI adapters, debugger | Gate A |
| Ownership slot, move-state, provenance, destructor API | Compiler/runtime | JIT, inspector, timeline | Gate B |
| Definition version/dispatch and resource pin API | Compiler/ORC | Runtime, debugger, timeline, C facades | Gate B |
| Cancellation/safe-point and scheduler API | Runtime | Jupyter Control, debugger, async cells | Gates B/C |
| Native import and callback ABI contract | C/Clang bridge | ORC, facades, timeline blockers | Gates A/B |
| Socket/poller and multipart framing contract | `std.net`/ZMTP | Jupyter wire host | Gate C |
| Jupyter message serialization/validation fixtures | Kernel protocol | Kernel host, test client, JupyterLab | Gate C |
| Presentation MIME and readonly-inspection contract | Runtime/semantic API | Jupyter display/inspect, debugger | Gate D |
| Recorder capabilities, event identity, checkpoint eligibility | Timeline/debugger | Session engine, DAP, future UI | Gate E |
| Platform JIT/permissions/unwind manifest | Platform integration | ORC, doctor, native callbacks | Gates A/F |

**AGT-001 — Single source of truth.** Every owner publishes a versioned API description, normative error taxonomy, and executable positive/negative fixtures. Agents must reference the contract version they implement. No parallel team redefines language behavior privately to make tests pass.

**AGT-002 — Failure taxonomy.** Standard error kinds MUST distinguish `CompileError`, `LinkError`, `OwnershipError`, `RuntimePanic`, `Interrupted`, `UninterruptibleNativeCall`, `UnsupportedFeature`, `StaleVersion`, `NonRestorableCheckpoint`, `ResourceLimit`, `ProtocolError`, `SecurityError`, and `PoisonedSession`. Error text can be human-friendly; the kind and structured provenance must be stable for tests.

**AGT-003 — Source of truth for tests.** Unit tests supplement, but never replace, complete user-facing `with uat` and real frontend scenarios. Every semantic contract has at least one passing and one adversarial test. Platform-dependent omissions must be explicit, not silently skipped while claiming support.

**AGT-004 — Integration cadence.** Agents can work concurrently on independently versioned modules. Main branch integration MUST continuously run the vertical Jupyter lane and relevant ownership/protocol tests; downstream changes may not bypass a failing foundation gate with mocked assumptions.

**AGT-005 — Law 7.** Unsupported operations fail loudly and state the precise missing capability or reason. No fallback may produce plausible but incorrect state, protocol output, debugger variable, historical checkpoint, or safety guarantee.

## 14. Conformance examples (conceptual With syntax)

These examples describe intended behavior, not final parser-approved spellings. Actual source syntax MUST come from the canonical With language specification and be used in UAT fixtures.

### 14.1 Stateful execution

```python
# Submission 1
var x = 10
# Submission 2
x += 5
# Submission 3
x *= 2
```

After Submission 3, the current state has `x = 30`. The timeline contains boundaries with 10, 15, and 30 **if** that value was recorded by a capable recorder; history source alone does not make all three value snapshots available. `inspect` is read-only; `restore` is separately guarded.

### 14.2 Rebinding without editor-cell identity

```python
# First submission
let a = 10
let b = 20
# Later submission (possibly from edited same notebook cell)
let a = 30
```

`a` refers to a new owned generation with value 30; `b` remains 20. Notebook-cell location or notebook JSON cell ID does not delete `b`.

### 14.3 Declaration and runtime failure

```python
# Candidate submission whose final declaration fails to compile:
fn helper(...) -> ...: ...
# If any part of this submission fails before publication, helper is absent.
```

By contrast, a successfully compiled submission that publishes `helper`, mutates a global, then panics retains its published declaration and completed mutation, after safe With unwinding.

### 14.4 Source versioning and a native C side effect

If an earlier `fn compute` is replaced, older compiled callers using safe handles invoke the new same-ABI implementation; active old frames finish the old one. If a cell calls a C function that writes a file, the timeline records the submission, but a checkpoint prior to that effect is not advertised restorable without a recorder proven capable of managing those external effects.

## 15. Source basis and standards boundaries

**User-provided inputs, preserved as design sources:**

1. *v0.17.0 Lifestyle Enablement Release: Plan*, dated 2026-11-27, measured against commit `94195e2` (persistent ORC session, Jupyter kernel, net primitives, core rich display, cross-platform UAT).
2. *With v0.17.0 — Normative Specification Addendum* (previous broad companion document; this spec extracts and supersedes its Jupyter-engine contracts).
3. *Reverse debugging / DWARF / LLDB* technical discussion provided in the conversation (distinction between native execution history and source/debug metadata).

**External specifications to follow at implementation time:**

- Jupyter Messaging Protocol / `jupyter_client` message details: <https://jupyter-client.readthedocs.io/en/stable/messaging.html>
- Jupyter debugger protocol: <https://jupyter.org/enhancement-proposals/jupyter-debugger-protocol/>
- Kernelspec format and interrupt mode: <https://github.com/jupyter/jupyter_client/blob/main/docs/kernels.rst>
- JupyterLab services execute options: <https://jupyter.org/services/interfaces/kernelmessage.iexecuteoptions.html>
- ZeroMQ ZMTP 3.0 protocol specifications (use published normative wire rules, not assumptions from libzmq behavior)
- LLVM ORC, target-specific unwind/debug metadata, and platform JIT entitlement documentation (use matching LLVM/OS versions)
- Microsoft Debug Adapter Protocol and Jupyter's documented debugger extensions (advertise only implemented requests)

If these external standards and an illustrative description here conflict on message format, **the external wire standard wins**; update this document and fixtures accordingly. This exception does **not** permit changing With's ownership or runtime contracts without explicit architectural approval.

---

**Definition of done for the core Jupyter engine:** A real notebook frontend can create one persistent With session, execute JIT-compiled native code cell-by-cell without replay, preserve ownership and compiler state safely, call C libraries, display useful results, receive accurate semantic feedback, interrupt supported execution, debug according to actually available backends, inspect timeline history without falsifying restoration, and shut down honestly—with the above adversarial tests green on every advertised platform.
