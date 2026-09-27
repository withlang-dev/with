# With specification audit — 2026-09-26

Status: review findings and proposed resolutions, not adopted language changes.

Reviewed document: [with-specification.md](/Users/eric/with/docs/with-specification.md), v7.2, 13,213 lines. Repository HEAD: ea77639cf8aeacfa2bba36d53dba0bcdb30d8a8c. Specification SHA-256: 41f0ce48019af02f93dc17700bb63d4438ecc7429f1b142d9304bc027460ef83.

This is a targeted semantic and editorial audit, not a proof of soundness or an exhaustive verification of every production and example. It checks conflicting requirements, safety arguments, important missing definitions, and the boundary between the language and its implementation/toolchain. Compiler behavior was not used to decide which rule is correct. The specification itself has not been edited.

## Assessment

The document currently combines a language definition, design rationale, implementation prescription, tutorial, standard-library requirements, toolchain product specification, and decision history. These layers have drifted independently. Several conflicts change which programs a conforming compiler must accept, rather than merely explaining the same rule differently.

The most urgent issues are the universal zero sentinel for destruction, unconditional ScopedSend for borrowed values, and claims that safety does not depend on static analysis. Next come incompatible rules for ephemerals, closure escape, suspension, and separate compilation.

Twenty findings below distinguish direct contradictions from incomplete contracts and invalid arguments. “High” means the issue affects safety reasoning or fundamental program validity; “Medium” means a substantive contract, rationale, or specification-maintenance problem. These are findings about the specification, not claims that the current compiler exhibits every described failure.

## What the reference specifications suggest

| Reference | Useful precedent | Qualification |
|---|---|---|
| [C# scope](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/scope) and [conformance](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/conformance) | State what constitutes a program, its meaning, required diagnostics, and implementation obligations. Explicitly separate normative and informative material. Translation/invocation mechanisms are outside the stated scope. | C# includes a required core library by reference. “No library contracts in a language spec” would be too strong. |
| [Swift Language Reference introduction, official source](https://raw.githubusercontent.com/swiftlang/swift-book/main/TSPL.docc/ReferenceManual/AboutTheLanguageReference.md) | Separate the language from common library types, functions, and operators, while allowing library examples to explain language behavior. | Swift explicitly says this reference is for understanding the language, not sufficient by itself to implement a parser or compiler. It is not a complete formal-conformance template. |
| [Scala 3.4 specification](https://www.scala-lang.org/files/archive/spec/3.4/) and [Types chapter](https://www.scala-lang.org/files/archive/spec/3.4/03-types.html) | Define syntax and semantic relations directly; distinguish surface syntax from semantic type forms. Its stated purpose is a language/core-library reference, not a tutorial. | This published Scala 3 specification explicitly lists missing features and points to the Scala 3 Reference. It is useful precedent, not evidence that Scala's documentation is complete. |

For With, the boundary should be: **keep requirements that determine source validity, program meaning, observable behavior, or required safety guarantees; move compiler construction, command-line workflows, benchmark claims, library inventories, and project process elsewhere.**

This already agrees with [D48](/Users/eric/with/docs/decisions.md:875): the spec should not catalogue lib/std, but must retain the contracts that syntax and ownership semantics depend on. A small informative overview and illustrative examples are appropriate; promotional claims and implementation plans should not acquire normative force.

## Findings

### F01 — An all-zero value cannot universally mean “already moved”

**High — representation/semantic defect.**

Evidence: [§2.5.1](/Users/eric/with/docs/with-specification.md:626) defines the reset sentinel as zeroed storage and skips the entire destructor for it. [§2.3](/Users/eric/with/docs/with-specification.md:451) permits user Drop types with ordinary integer fields. [§2.4](/Users/eric/with/docs/with-specification.md:488) requires destruction at scope exit.

A live value can legitimately have all-zero user storage:

~~~with
type Ticket { id: u32 }
impl Drop for Ticket:
    move fn drop(): print("released")
~~~

Ticket { id: 0 } still owes its destructor. There is no stated restriction reserving zero for invalid instances, nor a separate liveness discriminator. A payload-only zero test cannot distinguish that live value from a moved-from Ticket. The same issue applies to foreign resources whose valid token can be zero. Optimizing away the guard in some easy cases does not resolve the general representation collision.

The field-take rule also promises that blanking leaves a “valid empty value” for every field type; not every user type has a defined empty state.

**Proposed resolution:** Specify destruction in terms of abstract ownership/liveness, independently of the representation. Require exactly one destruction obligation for every live value. Leave drop flags, reserved niches, tagged representations, or reset strategies to implementation notes, unless With deliberately restricts types to guarantee an unambiguous sentinel. Define whether a moved-out field is uninitialized or a usable empty value. This needs an explicit semantic decision, not just an editorial replacement.

**Conformance cases:** live zero-valued Drop instance; moved zero-valued instance; conditional move; multiple owning fields; explicit field take followed by access to the base.

### F02 — Joining a thread proves lifetime, not thread safety

**High — invalid safety inference.**

Evidence: [§14.16](/Users/eric/with/docs/with-specification.md:7919) says ephemeral types implement ScopedSend because scoped work joins before their data dies. Its table admits every &T and ephemeral struct, while rejecting Rc[T].

A borrowed &Rc[T] is still an ephemeral &T. Letting two scoped workers operate on that shared Rc can race its non-atomic reference count even though both workers finish before the owner is destroyed. A borrowed wrapper must not erase the thread-safety restrictions of its referent. Thread-affine resources raise a similar problem.

**Proposed resolution:** Define ScopedSend structurally, with lifetime and concurrency requirements separately. Shared borrowed transfer needs a suitable Sync contract on the referent; aggregates must preserve component restrictions; guard and thread-affinity restrictions must survive wrapping. Specify which non-Send tasks are pinned to a worker, since §14.18 also permits work stealing.

**Conformance cases:** scoped shared access to Sync data accepted; scoped access to non-Sync interior state rejected; wrapping the latter in an ephemeral struct must not change the result.

### F03 — The optimizer invalidates the claimed immunity to analysis bugs

**High — self-contradictory safety argument.**

Evidence: [§2.5.2](/Users/eric/with/docs/with-specification.md:689) permits analysis to remove source resets and drop guards, then claims a bug in that analysis can only cost performance and never safety.

A missed optimization is harmless. An incorrect proof that permits removing a needed reset or guard is not. The text reasons only about false negatives, while making a claim about every analysis bug. Once emitted protections depend on the analysis, their removal belongs to the trusted correctness argument.

**Proposed resolution:** State that correct implementations preserve ownership/destruction semantics under optimization. If a separate non-elidable safety mechanism exists, define it. Otherwise remove the immunity claim and the unsupported comparison with Rust's drop elaboration. “Unconditional reset” and “the optimizer may omit the reset” cannot jointly justify independence from optimizer correctness.

### F04 — Ephemerality alone does not prevent dangling borrows

**High — invalid safety inference and inconsistent safety description.**

Evidence: [§1.1](/Users/eric/with/docs/with-specification.md:124) promises compile-time detection “Always”; [§1.4](/Users/eric/with/docs/with-specification.md:217) says guarantees do not depend on lifetime tracking; [§2.5.5](/Users/eric/with/docs/with-specification.md:752) says borrows need no mechanism because they cannot leave their originating scope. But [§3.2](/Users/eric/with/docs/with-specification.md:775) and [§21.1](/Users/eric/with/docs/with-specification.md:12185) require static invalidation, move exclusion, and origin tracking.

Consider this deliberately invalid program:

~~~with
var values = Vec.from([1])
let view = values[0]
values = Vec.new()
print(view)
~~~

Under §3.8/D27, the unannotated element binding preserves a reference to the stored i32. Everything occurs within one scope. Replacing values can free that element's backing storage before view's last use. A source-reset mechanism does not protect the existing reference. The program is safe only because the borrowing rules reject it, or because an additional runtime mechanism enforces validity.

The statement that the standard library can use unsafe when the compiler cannot prove safety ([§1.1](/Users/eric/with/docs/with-specification.md:126)) is also not a safety argument: unsafe implementation code must uphold a sound public contract.

**Proposed resolution:** Distinguish static borrowing/origin guarantees, abstract ownership guarantees, and checked handle lookup. Say “no user-written lifetime parameters” if that is the intended benefit; do not equate that with no lifetime analysis.

### F05 — Owner destruction simultaneously uses and does not use generations

**High — direct contradiction.**

Evidence: [§2.5.1](/Users/eric/with/docs/with-specification.md:675) explicitly assigns generations to SlotMap slots and states that owning values do not compare a generation at drop. [§21.1 rule 9](/Users/eric/with/docs/with-specification.md:12261) says owner destruction is made safe by a runtime generation check.

These are different mechanisms, not two descriptions of the same one. A compiler implementing either passage violates the other.

**Proposed resolution:** Remove stale generation-based owner wording and give the abstract destruction rule one normative home. However, fix F01 before treating the current replacement mechanism as a sound universal contract.

### F06 — Ephemeral aggregates and borrowing iterators are both forbidden and allowed

**High — direct contradictions in type validity.**

Evidence:

| Prohibition | Permission |
|---|---|
| [§3.3](/Users/eric/with/docs/with-specification.md:801): references cannot be struct/enum fields or heap-container elements. | [§5.5](/Users/eric/with/docs/with-specification.md:2680): ephemeral structs hold references. |
| [§3.4](/Users/eric/with/docs/with-specification.md:812), [§5.1](/Users/eric/with/docs/with-specification.md:2615): ephemeral values cannot be put in containers. | [§5.2](/Users/eric/with/docs/with-specification.md:2624), [§22.1](/Users/eric/with/docs/with-specification.md:12349): containers propagate ephemerality. |
| [§5.2](/Users/eric/with/docs/with-specification.md:2632): boxing an ephemeral container is a compile error. | The same section explicitly includes Box[T], Rc[T], and Arc[T] in structural propagation. |
| [§13.1](/Users/eric/with/docs/with-specification.md:5872): borrowing iterators cannot be returned. | [Immediately following text](/Users/eric/with/docs/with-specification.md:5876): concrete ephemeral borrowing iterators can be returned. |

**Proposed resolution:** State the intended structural propagation and origin/escape rule once, then qualify all prohibitions accordingly. Separate “cannot outlive the origin,” “cannot be stored in a non-ephemeral aggregate,” and “cannot be erased behind this particular interface.” They are different restrictions. Allocating a local container is not itself an escape. D2 already points toward this distinction.

### F07 — The parser example gives opposite answers to the same collection pattern

**Medium — contradictory worked examples tied to origin semantics.**

Evidence: [§5.5](/Users/eric/with/docs/with-specification.md:2720) says accumulating tokens prevents the next parser mutation, so tokens must be converted to owned offsets. [§22.1](/Users/eric/with/docs/with-specification.md:12362) uses repeated parser.next_token() followed by toks.push(tok) as an accepted example.

Whether a token borrows the parser's mutable state or the external source referenced by the parser matters. Structural ephemerality alone does not decide it.

**Proposed resolution:** Declare the parser and origin relationship in both examples. Give one accepted case that borrows stable external input and one rejected case that borrows invalidated parser storage, if that is the intended distinction. Otherwise choose a single verdict and make both chapters agree.

### F08 — Named local closures are simultaneously forbidden and demonstrated

**High — direct contradiction in escape classification.**

Evidence: [§12.3](/Users/eric/with/docs/with-specification.md:5753) and [§22.2](/Users/eric/with/docs/with-specification.md:12385) classify every closure outside direct argument position as escaping. [§12.2](/Users/eric/with/docs/with-specification.md:5748) forbids ephemeral captures by escaping closures. [§12.4](/Users/eric/with/docs/with-specification.md:5804) makes non-move closures views of their frame, then shows:

~~~with
var n = 42
let g = || n += 1
g()
~~~

That local binding cannot satisfy the older escape rule. There is a second mismatch: §12.1 requires synchronous consumption by the callee, whereas §12.3 declares direct argument syntax alone sufficient. A call can retain an argument; the contract of the callee matters.

**Proposed resolution:** Bring escape rules into agreement with the newer capture/provenance model, or explicitly prohibit the newer example. Direct argument position can be a useful syntactic check, but cannot be the entire semantic definition of non-escape. Preserve and check callable effects when a closure is passed onward.

### F09 — The universal explicit-field-move rule has an unstated destructor exception

**High — direct contradiction.**

Evidence: [§2.2](/Users/eric/with/docs/with-specification.md:366) says implicit field moves are forbidden everywhere, without type or context conditions. [§2.4](/Users/eric/with/docs/with-specification.md:545) permits freely consuming fields inside drop and illustrates close_file(self.fd), where fd is a File.

The latter is an implicit move of a non-Copy field. Moreover, the first rule names mutable paths, while the destructor's receiver is consuming rather than a mut fn receiver.

**Proposed resolution:** Decide explicitly whether destructors are exempt, whether consuming receivers permit an explicit field take, or whether total destructuring is required. Then make the rule and example match. [D32](/Users/eric/with/docs/decisions.md:1866) expressly chose the strict rule; [D55](/Users/eric/with/docs/decisions.md:552) separately permits total destructuring inside the type's consuming methods. Neither justifies silently inventing an additional exception.

### F10 — Ephemeral tasks cannot be returned, except that they explicitly can

**High — direct contradiction.**

Evidence: [§14.7](/Users/eric/with/docs/with-specification.md:7294) prohibits returning borrowing tasks. [§14.22](/Users/eric/with/docs/with-specification.md:8341) explicitly allows returning them with propagated ephemerality.

**Proposed resolution:** Define return as an origin-preserving transfer, permitted when the task's borrows remain valid in the caller, if §14.22 is the intended rule. A return that would outlive a local referent remains invalid. Do not confuse returning an ephemeral value with detaching it.

### F11 — Calling async code is both allowed and forbidden without its runtime

**High — direct contradiction.**

Evidence: [§14.3](/Users/eric/with/docs/with-specification.md:7034) says a call that creates a Task without awaiting works in any build and only suspension is gated. [Invariant 4](/Users/eric/with/docs/with-specification.md:7051) and [§24.3](/Users/eric/with/docs/with-specification.md:12516) make async fn itself an error under no_runtime. [§14.4](/Users/eric/with/docs/with-specification.md:7175) requires an async call to start a fiber.

**Proposed resolution:** Distinguish ordinary functions running in a runtime-enabled program from programs built without the fiber runtime. The former may start tasks without suspending; the latter cannot start fibers under the stated model. Keep one feature-gate definition.

### F12 — “The only implicit suspension” contradicts transitive suspension

**High — direct contradiction affecting scheduling expectations.**

Evidence: [§14.1](/Users/eric/with/docs/with-specification.md:6963) requires source-visible suspension and names ephemeral cleanup as its only implicit exception. [§14.3 invariant 5](/Users/eric/with/docs/with-specification.md:7058) explicitly rejects syntactic visibility as the model, permitting ordinary same-fiber calls and fiber-aware I/O/synchronization to suspend.

**Proposed resolution:** Use the newer compiler-tracked suspension rule consistently if it is intended. Enumerate primitives and propagation through calls once. Keep restrictions for guards, callbacks, and no_suspend; remove the obsolete promise that every other yield is visible at its call site.

### F13 — Safety facts must cross interfaces, but interfaces prohibit carrying them

**High — unresolved separate-compilation contract.**

Evidence: [§22](/Users/eric/with/docs/with-specification.md:12330) requires capture, origin, ephemerality, and may_suspend summaries across interfaces. [§14.3](/Users/eric/with/docs/with-specification.md:7114) says programmers never annotate may_suspend. [§18.5c](/Users/eric/with/docs/with-specification.md:11561) says no body-inferred information is part of an interface.

For example, an exported ordinary fn pause() may call an await internally. Its declaration is indistinguishable from a non-suspending fn pause(). A client enforcing no_suspend or an FFI callback restriction cannot make the required distinction from that signature alone.

[§3.4](/Users/eric/with/docs/with-specification.md:854) already gives returned views a boundary-specific rule and rejects ambiguous origins. [§12.4](/Users/eric/with/docs/with-specification.md:5828) similarly rejects consuming closures at bundle boundaries until an invocation-count contract exists. The corresponding policy is missing for the broader required summaries.

**Proposed resolution:** Respect [D39](/Users/eric/with/docs/decisions.md:1470): define what is derivable from declarations, what has a conservative boundary meaning, and which exports are rejected until a source-level contract can express the missing fact. Do not silently serialize inferred effects and claim to preserve D39. A language decision is needed where existing declarations cannot express necessary safety facts.

### F14 — Absorbing cancellation leaves a value-producing scope without a value

**High — incomplete control-flow and typing contract.**

Evidence: [§14.7](/Users/eric/with/docs/with-specification.md:7378) makes awaiting a cancelled task unwind to an async-scope boundary, where cancellation is absorbed without producing an error value. [§14.9](/Users/eric/with/docs/with-specification.md:7552) says async scope is an expression returning its body's value.

Consider a scope whose tail awaits a task producing i32, but that task is cancelled. The tail never produces i32. If cancellation is absorbed and execution resumes after the scope, what initializes the enclosing i32 binding?

**Proposed resolution:** Define normal completion, early return, panic, and cancellation as distinct completion outcomes. State whether cancellation propagates past a value-demanding scope, whether such a scope has a carrier type, or whether some forms are rejected. An implementation must not fabricate a default result. Also define root-task cancellation and races between cancel, completion, and was_cancelled; the shown cancellation test must not imply a stronger synchronization guarantee than the API provides.

### F15 — Handle validity needs arena identity and generation-exhaustion rules

**Medium — incomplete library contract supporting a core safety claim.**

Evidence: [§6.1](/Users/eric/with/docs/with-specification.md:2756) defines Handle[T] as an index and u32 generation. [§2.5.1](/Users/eric/with/docs/with-specification.md:675) relies on generation mismatch to reject stale handles.

Two SlotMap[T] instances can have matching index/generation pairs. Nothing here specifies the result of using one map's handle with the other. Finite generation counters also eventually exhaust or wrap; blindly wrapping can make a stale handle match a new object.

These are identity/validity gaps, not proof that a checked lookup dereferences freed memory: returning the wrong live object can still be memory-safe.

**Proposed resolution:** Put complete SlotMap semantics in its library contract: arena provenance or an explicit foreign-handle limitation; counter exhaustion/slot retirement; clear/replace semantics. Keep only the language-facing type/borrow contracts in the core spec. Do not advertise unconditional stale-handle rejection without stating its limits.

### F16 — A generator storing a reference does not necessarily refer to itself

**Medium — invalid rationale, not automatically a demand to add a feature.**

Evidence: [§13.4](/Users/eric/with/docs/with-specification.md:6237) says a generator taking src: &str cannot yield a slice of src because storing src in its state machine makes the result self-referential.

This confuses a reference value stored in the frame with its referent. A slice of caller-owned input can point into the caller's buffer. Moving the generator frame does not move that buffer. Yielding a reference into the generator's own owned storage is a different case.

**Proposed resolution:** If With deliberately bans both cases, state that restriction as a design choice. If the intended restriction is self-borrowing, distinguish internal referents from external origins and specify the lifetime constraint. The claimed impossibility is not a valid justification for the broader ban.

### F17 — Pooling is described as eliminating allocation even when the pool grows

**Medium — inconsistent cost claim and misplaced implementation detail.**

Evidence: [§14.4](/Users/eric/with/docs/with-specification.md:7175) and [§20](/Users/eric/with/docs/with-specification.md:11970) include fiber/task allocation. [§14.19](/Users/eric/with/docs/with-specification.md:8086) says fiber creation is a pool grab, not allocation; [later text](/Users/eric/with/docs/with-specification.md:8193) repeats the claim, then says the pool lazily grows.

Reusing an available stack avoids obtaining new stack storage. A cold or exhausted pool cannot make unbounded new fibers without obtaining more storage or rejecting/waiting. Task metadata can also have a distinct cost.

**Proposed resolution:** Keep the semantic permission to allocate and define failure behavior. Move pool algorithms, stack sizes, instruction-count claims, and measurements to runtime documentation. Describe a pool-hit optimization as conditional, with pool-miss behavior stated.

### F18 — Foundational observable behavior is less specified than tooling details

**High — gaps found by targeted searches, not a claim of exhaustive absence.**

Three contracts need a defined owning section or an explicit normative reference:

1. **Evaluation order.** [§9.1a](/Users/eric/with/docs/with-specification.md:3518) defines argument resolution and default evaluation, but not their complete evaluation sequence. Local rules exist for chained comparisons and index components. I did not find a general rule for receiver/argument evaluation, reordered named arguments, defaults, or ordinary binary operands. Decide the permitted side-effect order for f(mark(1), mark(2)) and f(b: mark(2), a: mark(1)). Resolution order is not necessarily execution order. [§10.5](/Users/eric/with/docs/with-specification.md:4880) also calls unwrap_or(U) “lazy branch selection”; clarify whether its already supplied argument is evaluated eagerly, unlike unwrap_or_else.
2. **Panic and unwinding.** [§14.7](/Users/eric/with/docs/with-specification.md:7374) relies on unwinding/destructor guarantees, [§14.9](/Users/eric/with/docs/with-specification.md:7556) propagates child panics, and [§18.7](/Users/eric/with/docs/with-specification.md:11685) defines a freestanding panic hook. A unified hosted panic contract, panic during drop/defer, and foreign-boundary behavior are not supplied by these passages.
3. **Memory model.** [§14.17.1](/Users/eric/with/docs/with-specification.md:8018) gives brief atomic-order descriptions but no complete reads-from/synchronization contract. [§16.11](/Users/eric/with/docs/with-specification.md:10340) explicitly defers usable pointer provenance to a memory-model section without identifying it. I did not find that defining section in this document. These rules are essential to judging unsafe code and concurrent implementations.

**Proposed resolution:** Establish the execution model before adding further operational detail to CLI and build sections. It is acceptable to adopt a precisely identified external model or document an intentional implementation-defined choice; leaving incompatible interpretations open is not a substitute.

### F19 — Several comparisons are factually wrong or unsupported

**Medium — rationale quality.**

- [§14.3](/Users/eric/with/docs/with-specification.md:7028) says Rust cannot call an async function from a non-async context without an executor. Rust can make the call and obtain a future; executing that future is the separate step. The meaningful comparison is eager task start versus future construction. See the [Rust Reference](https://doc.rust-lang.org/reference/items/functions.html#async-functions).
- [§13.1](/Users/eric/with/docs/with-specification.md:5923) says Rust requires lifetime annotations on every struct and function in a borrowing-iterator chain. That overstates the requirement; function lifetime elision is explicitly specified. See [Rust lifetime elision](https://doc.rust-lang.org/reference/lifetime-elision.html#lifetime-elision-in-functions).
- [§1.1](/Users/eric/with/docs/with-specification.md:114) and [§1.4](/Users/eric/with/docs/with-specification.md:212) quantify “90%” reductions in pain/cognitive load without evidence.
- [§6.3](/Users/eric/with/docs/with-specification.md:2791) gives absolute nanosecond handle/pointer costs; [§14.19](/Users/eric/with/docs/with-specification.md:8141) gives stack-switch timing without a workload, target, or measurement method. These cannot serve as portable language guarantees.

**Proposed resolution:** Correct factual comparisons, label design hypotheses as hypotheses, and move comparisons/measurements to rationale and benchmark documents. They do not define what With programs mean.

### F20 — Normative authority and conformance scope are fragmented

**Medium — specification architecture defect.**

Evidence: the [header](/Users/eric/with/docs/with-specification.md:5) makes an external D22 ruling authoritative; Part I contains language requirements; [Part II](/Users/eric/with/docs/with-specification.md:12166) is named “Normative Rules”; [§30](/Users/eric/with/docs/with-specification.md:12971) explicitly makes the grammar appendix informative. Implementation status and historical rulings are interleaved throughout.

The D22 precedence rule is explicit, so referencing it is not itself a contradiction. The problem is that readers cannot treat this document alone as the complete versioned language contract, and the general normative/informative and conformance boundaries are not comparably clear.

**Proposed resolution:** Add a scope/conformance chapter. Give each rule one authoritative home and a stable identifier. Clearly mark informative notes and examples. Either consolidate approved semantics or publish a version-pinned set of normative documents. Keep historical rationale and implementation status outside that set. Do not silently demote D22 or any other approved ruling while reorganizing.

## Secondary corrections

These should be fixed during editorial reconciliation, without confusing them with the major semantic decisions:

- [§3.6](/Users/eric/with/docs/with-specification.md:901) calls two captures disjoint although both use world.transforms. Shared read access could be valid, but it is not disjointness. Supply function modes and explain the actual reason.
- [§2.4](/Users/eric/with/docs/with-specification.md:521) says h = transform(h) drops the old resource on reassignment. If transform consumes h, the source is moved and reassignment must not destroy that transferred value again. Give transform a signature and distinguish consuming from borrowing transformations. The process(combine(...)) temporary example has the same missing-signature problem.
- [§12.4](/Users/eric/with/docs/with-specification.md:5845) mutates a Vec captured from a let binding, despite the mutable-place rule. Use var if mutation is intended.
- [§10.3](/Users/eric/with/docs/with-specification.md:4793) desugars optional field access into implicit field moves, including owned str fields. Reconcile that lowering with D32 instead of allowing compiler-generated code to bypass it.
- [§30.8](/Users/eric/with/docs/with-specification.md:13201) still gives unsafe all three body forms, whereas [§29.13](/Users/eric/with/docs/with-specification.md:12751) explicitly restricts it. The precedence rule resolves authority but does not make the misleading appendix useful.
- [§22](/Users/eric/with/docs/with-specification.md:12310) says users write no ephemerality annotations, but the language requires declared ephemeral structs. Distinguish type qualifiers from inferred origin/lifetime information.
- [§14.17.1](/Users/eric/with/docs/with-specification.md:8034) spells an Atomic.store return as void, not Unit.
- [§18.6](/Users/eric/with/docs/with-specification.md:11619) points to docs/libstd-spec.md, which does not exist at that path in this checkout. A file exists at docs/feature_plans/libstd-spec.md, titled a standard-library plan; do not silently elevate a plan into a normative API specification.

## What to move out, and what must remain

These are extraction proposals. Moving material is not permission to discard a product requirement or change program semantics.

| Current material | Destination | What the core language specification retains |
|---|---|---|
| Header changelog, issue numbers, dated implementation status, receiver migration schedule | Changelog, decision log, compatibility/implementation status | Current accepted syntax and semantics; versioned compatibility profile if needed |
| §1 promotional comparisons; §7.8 frequency; tutorial parts of §7.9, §9.5, §29.9 | Design rationale and programming guide | A short informative overview; precise with/receiver/pipeline rules |
| §2.5 reset stores, guarded-drop lowering, instruction counts | [Implementation notes](/Users/eric/with/docs/with-implementation-notes.md) | Move validity, field state, destruction obligations, observable effects |
| §6 SlotMap API and timings; general collection/combinator API catalogues | Standard-library reference and benchmark reports | Handle type relationships if language-defined; ownership/borrowing doctrine; syntax-dependent traits and operations |
| §14 pool/work-stealing algorithms, stack-pool configuration, performance and scaling advice | Runtime specification/implementation guide | Task start/completion, suspension, cancellation, joining, thread-safety and stack/reference preservation guarantees |
| §17 driver capability provisioning, build integration and operational policy | Tool-mode/build-system specification | Comptime syntax, staging, permissible effects, determinism and safety rules; an explicit profile boundary |
| §18.5 CLI, §18.5a build graphs/RSS budgets/cache policy, §18.5b one-liners, §18.5d UAT runner, §18.8 package/Conan workflows | Toolchain, build, package, and UAT specifications | Module/name resolution; entry-point semantics; any explicitly defined alternative source-input profile |
| §18.5c artifact storage, manifests, fingerprints, ABI-hash command | Bundle format and ABI specification | Separate-compilation semantic contract, admissible declarations, preservation of safety information |
| §29.12 error numbers; fix-it rendering; diagnostic message templates and debugging commands | Diagnostics/tooling contract | Required rejection conditions and enough semantic explanation to identify the violation |
| §§25–28 moved-test/roadmap placeholders and test invocation commands | Conformance-suite guide, roadmap, historical redirect/index | Stable references from language rules to conformance tests, without making test-runner commands language semantics |

**Keep FFI and the facade language.** Foreign ownership, borrowing, callback retention, ABI promises, and unsafe obligations determine program meaning and safety. Their core clauses belong in the language or a clearly incorporated FFI annex. Heuristic facade generation, audit-command output, platform profiles, and migration workflows can have separate documents. Likewise, do not remove memory-order semantics merely because Atomic is a library type.

**Keep semantic configuration; move its user interface.** For example, checked/wrapping/saturating arithmetic changes values and therefore needs a language contract. The precise with.toml key and command-line switch belong in the toolchain reference. no_std/no_runtime need clearly defined language profiles even if the build flags live elsewhere.

## Recommended structure

1. Scope, conformance, normative references, terminology, and implementation-defined choices.
2. Lexical structure and grammar.
3. Declarations, names, modules, visibility, and separate compilation.
4. Types, traits, conversions, and inference.
5. Values, places, ownership, borrowing, ephemerality, and destruction.
6. Expressions, evaluation order, control flow, functions, and closures.
7. With blocks, guards, implicit contexts, and syntax-dependent library contracts.
8. Concurrency, memory model, tasks, cancellation, and completion outcomes.
9. Compile-time evaluation and effects.
10. Unsafe, FFI, layout, and semantic ABI contracts.
11. Hosted/freestanding/runtime profiles.
12. Informative examples and an index; a generated grammar summary if maintained.

Do not preserve duplicate “design” and “normative” versions of the same rule. Put explanatory notes beside a single authoritative rule, or in the rationale document. Assign stable rule IDs so moving a paragraph does not invalidate decisions, tests, or bug reports.

## Repair order

1. Resolve F01–F04 and F13–F14 before using the document as a soundness/conformance baseline.
2. Reconcile F05–F12 against already approved decisions; where approved text conflicts, bring the smallest explicit choice forward rather than inferring approval.
3. Define the execution/memory-model gaps in F18. Record the supported minimum analysis guarantees so conforming implementations are not judged solely by whether they can prove an arbitrary safe program.
4. Extract non-language material while preserving stable references and product requirements. D48 provides an existing policy basis for the library boundary.
5. Reconcile examples and desugarings with the final rules. Add conformance cases for accepted and rejected programs, including zero-valued destruction, scoped non-Sync capture, local closures, borrowed containers/tasks, no-runtime async calls, and interface suspension.
6. Generate or mechanically check repeated indexes/grammar summaries. Tests should verify the adopted semantics, not silently choose between conflicting paragraphs.

The direction most consistent with With's stated mission is fewer competing rules and less implementation ceremony in the language definition, while retaining explicit safety obligations. Small syntax and concise user code still require precise ownership, lifetime, effect, and completion semantics in the specification.
