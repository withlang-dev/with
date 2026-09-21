# Ruling: modeled C ownership, effects, conventions, and foreign lifetimes

**Status:** final semantic and surface ruling.

---

# 1. Governing principles

With is a pragmatic systems language.

It should exploit reliable conventions that real systems programmers already depend on rather than forcing programmers to restate facts merely because C itself does not encode them formally.

The safety boundary is therefore not “proof or nothing.”

The governing principle is:

> **With uses the strongest reliable evidence available, including conventions where doing so is safe and useful.**

The central asymmetry rule is:

> **A convention may be inferred silently when being wrong can only remove capability or reject a valid program. A convention that can create memory unsafety must be explicit, strongly established, or deliberately trusted.**

The foreign-boundary rule is:

> **With proves what it can, trusts what the facade asserts, exploits safe conventions where appropriate, refuses what none of those justify, and never pretends one category is another.**

This is the pragmatic reading of M3, M4, and M5.

M5 forbids a default that silently selects one semantic meaning over another when getting that choice wrong changes what the program does.

It does not forbid With from taking a restrictive interpretation when stronger permission has not been established.

> **A restrictive interpretation is the absence of a proof, not a choice between program meanings.**

Accordingly, With may silently infer restrictions such as:

* dependency;
* invalidation;
* nullable representation;
* thread affinity;
* coarse state-domain identity;

when a wrong inference can only reject a program that would otherwise have been valid.

It may not silently infer capabilities such as:

* ownership;
* destruction;
* consumption;
* retention;
* independence;
* static lifetime;
* success interpretation;
* unsafe thread crossing;

when a wrong inference could make safe code memory-unsafe.

Raw C remains available under the ordinary raw-C rules.

---

# 2. Proof, trust, and heuristics

With distinguishes three fundamentally different things.

## 2.1 What With proves

The compiler proves the properties under its own control, including:

* whether a With-owned value is live;
* whether it has moved;
* whether it has already been destroyed;
* whether a dependent value outlives its origin;
* whether a borrow remains valid according to modeled invalidation rules;
* whether With performs its modeled destruction exactly once.

## 2.2 What the facade asserts

The C ABI does not encode many semantic facts With needs.

A checked facade may therefore assert facts such as:

* this operation produces ownership;
* this operation destroys ownership;
* this operation consumes an argument;
* this operation retains an argument;
* this returned value borrows from this parent;
* this operation preserves a foreign-state domain;
* this status value means success;
* this callback may execute on another thread.

These assertions form the trusted foreign boundary.

A wrong facade assertion may be unsound, just as an incorrect safe wrapper around Rust `unsafe` FFI may be unsound.

Safe With application code is memory-safe provided the trusted foreign contracts it relies on are correct.

## 2.3 What heuristics may do

Tooling may use aggressive heuristics to discover and propose facade declarations.

It may inspect:

* names;
* signatures;
* source bodies;
* documentation metadata;
* neighboring declarations;
* known API patterns;
* convention families.

For example:

```text
possible resource producer: sqlite3_open

possible destroyers:
    sqlite3_close
    sqlite3_close_v2

possible parent of sqlite3_stmt: parameter 0

possible success constant: SQLITE_OK
```

But:

> **Heuristics may suggest; they do not decide safety-critical semantics.**

A heuristic becomes semantic evidence only when:

* accepted as explicit facade code;
* supplied by an explicitly adopted convention profile;
* or genuinely proven by the compiler.

This is the intended home for useful name-based and structural conventions that are too risky for silent safety decisions.

---

# 3. Evidence classes

Every modeled C fact has both a value and a provenance.

## 3.1 ABI and header facts

These are mechanically established from imported declarations and ABI information, including:

* parameter and return types;
* pointer structure;
* nullability where machine-readable;
* layout;
* calling convention;
* imported constants;
* link identity;
* machine-readable ownership or lifetime annotations.

These constrain all higher-level modeling.

## 3.2 Compiler proofs

Where the compiler can genuinely prove a semantic fact, the proof may grant capability.

A proof must establish the relevant contract, not merely suggest it.

For example, observing that a function eventually calls `free` does not by itself prove that it is the correct semantic destructor for a resource.

## 3.3 Explicit facade assertions

A checked With facade may state semantic facts not encoded by the C type system.

These are trusted foreign-contract evidence.

## 3.4 Convention-profile evidence

A convention profile is reusable facade evidence implementing a recurring API convention.

It is trusted only because a facade explicitly adopts it.

## 3.5 Conservative defaults

Where sufficient evidence is absent, With removes capability or leaves the operation raw.

A conservative default never grants safety-critical capability.

---

# 4. Evidence precedence

ABI/header impossibilities and genuinely proven contradictions are authoritative.

Subject to those constraints, semantic evidence follows:

```text
explicit facade clause
        ↓
adopted convention profile
        ↓
conservative default
```

An explicit facade clause may:

* refine;
* override;
* or suppress

a fact derived from a convention profile.

A convention profile expresses the common case. The facade expresses exceptions.

A facade cannot override an ABI impossibility.

A compiler proof overrides a facade only when it genuinely proves the asserted contract impossible, not merely because implementation details appear suspicious.

Presentation has a separate precedence:

```text
explicit facade presentation
        ↓
safe automatic naming/grouping convention
        ↓
raw imported name
```

Ergonomic presentation never grants ownership or lifetime capability.

---

# 5. C contracts live in facades

Ownership, lifetime, mutation, retention, destruction, error, callback, concurrency, presentation, and foreign-state facts belong primarily to a **With facade**.

A facade is ordinary checked With source associated with one or more imported C declarations.

The construct is scoped:

```with
use c_import("sqlite3.h", link: "sqlite3")

c facade sqlite:
    ...
```

Facade declarations do not exist as unrelated top-level foreign-contract statements.

The block provides:

* the scope in which imported C identifiers resolve;
* a stable provenance identity;
* the scope of convention-profile adoption;
* the scope of overrides;
* the namespace for modeled resources and state domains.

A facade may be:

* written locally;
* shipped by a package;
* shared through `with get`;
* generated;
* supplemented by header annotations;
* supplemented by convention profiles.

This does not revive the open-ended compiler-maintained per-package tables rejected by D46.

The architecture is:

> **The raw C surface supplies ABI truth; the facade supplies semantic meaning.**

The compiler/toolchain does not accumulate permanent special-case knowledge for arbitrary third-party libraries.

Bounded knowledge for genuinely universal runtime facilities may remain toolchain-owned where separately justified.

---

# 6. Facade syntax uses With

Everything after `c_import` is With syntax.

A facade never introduces a second C-like grammar for types.

Therefore:

```with
resource Database wraps *mut sqlite3
```

not:

```text
resource Database wraps sqlite3*
```

Imported types are referred to using the exact With spelling produced by `c_import`.

Facade constants likewise resolve through the ordinary imported With namespace.

---

# 7. Convention profiles

A convention profile is a versioned package of checked facade rules that another facade explicitly adopts.

Conceptually:

```with
c facade gtk:
    use convention gobject.v1
```

The exact package-reference mechanics follow ordinary With package rules.

Profiles are facade code, not compiler folklore.

The toolchain does not ship open-ended ecosystem convention databases beyond separately justified bounded runtime/libc knowledge.

Opting into a profile means:

> **The facade author accepts that profile as trusted foreign-contract evidence for the API to which it applies.**

## 7.1 Unique-or-nothing

A capability-granting convention must resolve uniquely.

If a profile rule finds:

* zero candidates → no evidence;
* exactly one valid candidate → evidence may be contributed;
* more than one candidate → no evidence.

The compiler never chooses among competing convention matches.

Ambiguity fails closed even inside an explicitly trusted profile.

## 7.2 Overrides

Explicit facade declarations override profile-derived facts.

A library may follow a convention for forty operations and violate it for one.

The facade must be able to replace or suppress that one profile-derived result without giving up the profile as a whole.

## 7.3 Versioning

Convention profiles are versioned.

No convention becomes eternal compiler knowledge merely because one library once followed it.

---

# 8. Provenance is mandatory

Every effective modeled-C fact records whether it came from:

* ABI/header evidence;
* compiler proof;
* explicit facade clause;
* named convention profile and rule;
* conservative default.

Every fact inside a facade also records its facade identity:

```text
facade sqlite
```

`with analyze` must expose this provenance.

Diagnostics must use the same information.

For example:

```text
error: Statement may outlive Database
= dependency: conservative default from resource parameter 0
= help: declare this producer independent if the C API guarantees independence
```

or:

```text
note: destroying operation inferred by convention gobject.v1 rule unref
```

This is normative tooling behavior, not optional polish.

---

# 9. Never half-model unsafely

The rule is:

> **Never half-model unsafely.**

A partial model is acceptable when missing information only removes capability.

Acceptable examples:

* ownership is known but status remains uninterpreted;
* a child remains dependent until independence is known;
* a C string remains a borrowed byte view rather than being silently copied;
* an operation invalidates views conservatively because preservation is unknown.

Unacceptable examples:

* safe owned construction with no valid destruction contract;
* a destroying operation callable as a lend;
* a returned pointer guessed to be owned;
* ownership transfer guessed from a name;
* an unknown lifetime silently extended;
* a silent allocation inserted merely to hide unknown provenance.

Existing safe C auto-constructors with no valid destruction semantics are non-compliant and must either become fully modeled or revert to raw.

---

# 10. Resource is the fundamental ownership abstraction

The core modeled abstraction is **resource**, not pointer handle.

C resources appear physically in at least three forms:

```text
opaque pointer
in-place struct
by-value resource token
```

All use the same ownership model.

A resource is a With ownership type whose physical representation is foreign.

Its ownership semantics are distinct from the representation's C copying or layout semantics.

---

# 11. Pointer-backed resources

For an opaque-pointer API:

```with
c facade sqlite:
    resource Database wraps *mut sqlite3
        from sqlite3_open(out param 1)
        drop sqlite3_close
        destroys sqlite3_close_v2
        ok SQLITE_OK
```

the generated With resource owns the non-null foreign pointer.

The raw pointer is not directly exposed to ordinary safe application code except through modeled operations.

The resource is non-Copy unless separate semantic duplication evidence establishes otherwise.

Its automatic destruction invokes the designated `drop` operation exactly once.

---

# 12. By-value foreign resources

A C struct being trivially copyable does not make the modeled With resource Copy.

For example:

```with
c facade raylib:
    resource Texture wraps Texture2D
        from LoadTexture
        drop UnloadTexture
```

`Texture2D` may be a by-value C struct while `Texture` represents ownership of one GPU object.

Moving `Texture` moves ownership.

Copying the underlying representation is not exposed as copying the resource.

If the API provides genuine semantic duplication, the facade may expose that separately.

---

# 13. In-place resources

Caller-allocated resources have explicit states:

```text
storage allocated / not live
        ↓ successful init
live resource
        ↓ destruction
dead
```

For example:

```with
c facade zlib:
    resource InflateStream wraps z_stream
        init inflateInit(self)
        drop inflateEnd

    resource DeflateStream wraps z_stream
        init deflateInit(self, level)
        drop deflateEnd
```

`InflateStream` and `DeflateStream` are distinct modeled resources even though both wrap `z_stream`.

## 13.1 Pre-initialization

The foreign representation exists before `init` runs.

By default it begins as:

```with
Representation.zeroed()
```

using With's ordinary zero-initialization mechanism.

A facade may instead provide custom pre-initialization:

```with
resource Foo wraps FooState
    preinit make_foo_storage
    init foo_init(self)
    drop foo_end
```

`preinit` constructs storage but does not establish a live foreign resource.

## 13.2 Drop arming

`Drop` becomes armed only after initialization establishes production.

If initialization fails:

* the foreign destructor does not run unless the contract says a live resource was nevertheless produced;
* ordinary With storage cleanup still occurs;
* any partially produced ownership follows normal production rules.

Storage existence alone never arms foreign destruction.

---

# 14. Multiple resources over one representation

More than one resource may wrap the same imported representation.

When exactly one resource wraps a representation, ordinary operations accepting that representation may be associated with that resource unless stronger evidence says otherwise.

When multiple resources wrap the same representation, no such semantic assignment is made automatically.

For example:

```with
c facade zlib:
    resource InflateStream wraps z_stream
        ...

    resource DeflateStream wraps z_stream
        ...

    fn inflate
        of InflateStream

    fn deflate
        of DeflateStream
```

The rule is:

> **When a foreign representation maps to multiple modeled resources, an operation is callable through a modeled resource only after resource assignment is known.**

An unassigned `z_stream *` operation is rejected on both modeled resources, with a diagnostic naming the candidates.

Raw access remains available under raw-C rules.

Tooling may suggest likely assignments.

---

# 15. Production forms

A resource may be produced by:

* direct return;
* pointer out-parameter;
* in-place initialization.

The facade states the production shape.

Examples:

```text
direct return
out param 1
init self
```

Production and success are separate facts.

---

# 16. Out-parameter production

For a pointer out-parameter constructor without stronger production evidence, With makes this physical commitment:

1. initialize the out slot to `NULL`;
2. invoke the C function;
3. inspect the slot afterward;
4. null means no resource was produced;
5. non-null means a resource was produced and ownership begins immediately.

This determines **production**, not success.

Therefore:

```text
(status, Option[Resource])
```

is meaningful even when the status convention is unknown.

---

# 17. Status conventions

A producing declaration may state a success condition:

```with
ok SQLITE_OK
```

Imported macro and enum constants are equivalent once materialized as With compile-time values.

There is no universal rule that:

```text
0 == success
```

or that any other integer convention applies across C generally or across an entire library.

Without status evidence, status remains uninterpreted.

A convention profile may supply a known ecosystem status rule only when explicitly adopted.

---

# 18. Failure may still produce ownership

A failed status does not imply that no resource was produced.

The compiler preserves:

* the status;
* whether a resource was produced;
* ownership of any produced resource.

A high-level `Result` API is therefore a projection over the lower-level production model.

A facade-specific error type may itself temporarily own the failure-state resource where required.

---

# 19. Pointer-returning null failure

When the API contract establishes:

```text
NULL     -> no resource
non-null -> produced resource
```

the natural modeled result is:

```text
Option[Resource]
```

No separate `ok` clause is required.

This fact must come from trusted contract evidence; it is not inferred merely from pointer return type.

---

# 20. Ownership effects on parameters

Foreign resource parameters use one unified ownership vocabulary:

```text
borrow
retain
consume
consume ... destroyed_by ...
destroy
```

These are semantically distinct.

---

# 21. Borrow

A borrow temporarily gives the foreign operation access to a live resource.

The caller retains ownership afterward.

Once a resource is modeled, ordinary facade-exposed operations accepting it are treated as borrows unless stronger ownership-effect evidence says otherwise.

This is a trust boundary.

With proves:

* the resource is live;
* it has not moved;
* it has not been destroyed;
* With itself will discharge ownership according to the facade contract.

With does not prove that arbitrary foreign code actually honors borrowing semantics.

> **Lending is trusted foreign semantics, not something proven from the C signature.**

If the facade incorrectly exposes a consuming or destroying operation as a borrow, the facade is unsound.

---

# 22. Consume

A consuming operation takes ownership without necessarily destroying the resource immediately.

Conceptually:

```with
fn submit_to_pool
    consumes param 0
```

At the call site:

* the value moves;
* it cannot be used afterward;
* With suppresses later caller-side destruction.

Consumption is never inferred silently from arbitrary names.

It may come from explicit facade evidence or an explicitly adopted unambiguous convention rule.

---

# 23. Destroy

A destroying operation consumes and terminates ownership.

A resource may have more than one destroying operation.

For example:

```with
resource Database wraps *mut sqlite3
    from sqlite3_open(out param 1)
    drop sqlite3_close
    destroys sqlite3_close_v2
```

One destroyer is designated as automatic `Drop`.

Other destroying operations may be exposed as explicit consuming methods.

Every destroying operation is consuming.

No destroying operation may remain callable as a borrow.

This prevents:

```text
destroy resource through C
...
automatic Drop destroys it again
```

from being expressible in safe code.

---

# 24. Transfer with destructor callback

Some C APIs consume caller-owned userdata and receive a callback which C later invokes to destroy it.

This is modeled directly.

For SQLite:

```with
fn sqlite3_create_function_v2
    consumes param 4 destroyed_by param 8
```

For the C declaration:

```text
sqlite3_create_function_v2(
    db,
    zFunctionName,
    nArg,
    eTextRep,
    pApp,
    xFunc,
    xStep,
    xFinal,
    xDestroy
)
```

`param 4` resolves to `pApp` and `param 8` resolves to `xDestroy`.

Semantics:

1. ownership of the consumed parameter moves into C;
2. With no longer destroys it directly;
3. the named callback becomes its foreign destruction path;
4. the callback must be compatible with destroying that value;
5. ownership remains live in C until the callback occurs.

This is distinct from retention.

If registration can fail without taking ownership, the contract must state when transfer occurs.

Absent that evidence, With preserves caller ownership.

This example is intentionally positional: it demonstrates why facade contracts are compiler-checked and why diagnostics must print the resolved C parameter rather than only its numeric index.

---

# 25. Retain

Retention extends a borrow beyond the foreign call while ownership remains outside C.

Conceptually:

```with
fn register_callback
    retains param 1 by param 0
    retains param 2 by param 0
```

The retaining origin cannot outlive what it retains.

If an API provides an unregister operation, the facade may model release of retention.

If no release is modeled, retention lasts until the retaining origin is destroyed.

D4's existing `retains:` concept is subsumed by this vocabulary.

There is one retention system.

---

# 26. Borrowed foreign returns

A foreign function may return a borrowed resource rather than ownership.

For example:

```with
fn sqlite3_db_handle
    returns borrow Database from param 0
```

The result:

* has no `Drop`;
* cannot outlive the named origin;
* cannot independently be consumed or destroyed.

Nullable borrowed returns become `Option` of the borrowed modeled value.

---

# 27. Parent-child dependencies

When a producing operation receives modeled resources and produces another resource, the result is conservatively dependent on candidate parent resources unless stronger evidence grants independence.

> **Unknown independence means dependency.**

This follows the asymmetry rule because a wrong dependency inference only rejects code.

A facade may make the relationship precise:

```with
resource Statement wraps *mut sqlite3_stmt
    from sqlite3_prepare_v2(out param 3)
    drop sqlite3_finalize
    borrows param 0
```

A resource may depend on multiple parents.

The child remains valid only while all required origins remain valid.

---

# 28. Independence

Independence is capability-granting evidence.

A facade may state:

```text
independent
```

for a produced resource that does not actually depend on resource arguments used during its creation.

Without that evidence, dependency remains.

An omitted independence fact may over-restrict a program but cannot create use-after-free.

---

# 29. Existing lifetime machinery applies

Foreign resource dependencies use ordinary With origin and ephemeral-value analysis.

A dependent resource:

* cannot outlive required parents;
* prevents invalid parent movement or destruction;
* is destroyed before required origins when required;
* cannot be stored where origin relationships cannot be preserved;
* cannot escape through an invalid return.

No hidden reference counting or generation checks are introduced merely for C interop convenience.

---

# 30. Self-referential layouts remain invalid

A layout such as:

```with
type App {
    db: Database,
    stmt: Statement,
}
```

is invalid when `stmt` borrows from `db`.

This is an intentional consequence of compile-time lifetime safety.

Facades and official examples should instead demonstrate compatible patterns such as:

* a statement cache owned internally by the connection;
* stable handles into owner-managed storage;
* another owner-managed indirection.

---

# 31. Borrowed foreign memory always has an origin

A borrowed foreign pointer must be tied to a real modeled origin.

With does not invent lifetimes.

With also does not silently allocate a copy merely because provenance is inconvenient.

The principal origins are:

* modeled resources;
* foreign-state domains;
* static lifetime;
* callback scope where applicable.

---

# 32. Resource-backed borrowed memory

When returned storage depends on a resource, the result borrows from that resource.

For a nullable foreign C string:

```text
Option[&CStr]
```

is the conceptual shape.

Later operations that invalidate the underlying resource also invalidate the view through ordinary With view-liveness rules.

---

# 33. Foreign-state domains

Borrowed memory not tied to a particular resource borrows from a **foreign-state domain**.

Examples include:

* process environment state;
* locale state;
* `errno`;
* diagnostic buffers;
* thread-local error buffers;
* library-global caches.

A facade may declare:

```with
c facade libc:
    domain environ process
    domain errno thread
    domain locale process
```

This gives otherwise ownerless C storage an actual origin.

---

# 34. Default domain identity

The default coarse state-domain identity comes from ABI-level library identity, ordinarily `link:`.

Separate headers for the same linked library therefore share the same coarse domain.

If no stable link identity exists, the facade must explicitly name the relevant foreign-state domain rather than silently creating unrelated per-import origins.

---

# 35. Domains may be refined

A facade may split a coarse library domain into independent domains.

For example libc may distinguish:

* environment;
* locale;
* errno;
* independent diagnostic buffers.

It may also merge domains from distinct imports when they refer to the same actual state.

Domain refinement grants precision.

Without refinement, the conservative coarse domain remains.

---

# 36. Domain scope

Foreign-state domains may be:

```text
process
thread
resource
static
```

A process domain is shared process-wide.

A thread domain is distinct per thread.

A resource domain corresponds to an owned modeled resource.

Static data does not participate in mutable-domain invalidation.

A view borrowed from a thread-local domain inherits that thread restriction.

---

# 37. `errno` is the canonical domain example

Documentation should use `errno` to demonstrate the state-domain model:

```with
c facade libc:
    domain errno thread
```

An operation that may set `errno` mutates this domain.

A value depending on the domain cannot be assumed valid across another relevant libc operation unless preservation is known.

`environ` should be the companion example for mutable process-global storage.

---

# 38. Preservation and invalidation

Ownership borrowing and view invalidation are separate effects.

A borrowing function may mutate or invalidate state without consuming ownership.

For every origin touched by a foreign operation, the relevant view effect is:

```text
invalidate
preserve
```

The conservative default is:

> **Unknown effect means invalidate.**

This may be inferred silently because being wrong only invalidates views too early.

A facade may state:

```with
fn foo
    preserves param 0
```

or:

```with
fn foo
    preserves domain environ
```

`preserves` means views from that origin remain valid.

It does not imply general logical purity.

---

# 39. C `const`

C pointer `const` qualification is useful evidence.

It may contribute to:

* diagnostics;
* convention-profile rules;
* facade generation suggestions.

It does not by itself prove that:

* abstract resource state does not change;
* global state does not change;
* caches remain unchanged;
* prior returned views remain valid.

Likewise, non-const does not prove that all views are invalidated.

Core With does not equate C `const` directly with With preservation semantics.

A trusted convention profile may make that interpretation for an API family.

---

# 40. Static foreign data

Static lifetime grants capability.

A facade may state:

```text
returns static CStr
```

where the foreign API guarantees that the memory remains valid independently of mutable resources or state domains.

Static lifetime is never inferred merely because no owner is visible.

It may come from:

* header evidence;
* facade assertion;
* proof;
* deliberately trusted convention evidence.

---

# 41. Foreign strings

The primitive modeled null-terminated foreign string type is `CStr`.

`CStr` makes no UTF-8 claim.

A nullable borrowed foreign string becomes:

```text
Option[&CStr]
```

Conversion to With text is explicit.

Conceptually:

```with
cstr.to_str()
cstr.to_str_lossy()
cstr.to_owned()
```

`to_str()` validates and does not silently repair invalid UTF-8.

`to_str_lossy()` makes repair explicit.

`to_owned()` makes ownership/allocation explicit.

No `char *` silently becomes `str`.

---

# 42. Owned foreign buffers and strings

Caller-owned returned memory uses the resource model.

For example:

```with
resource SqliteString wraps *mut c_char
    from sqlite3_mprintf
    drop sqlite3_free
```

The owned resource may expose a borrowed `CStr` view.

The foreign allocator/deallocator relationship remains intact.

With never substitutes its allocator unless an explicit conversion copies the contents.

The same model applies to arbitrary foreign-owned buffers, not only strings.

---

# 43. Nullability

`NULL` is information.

Machine-readable nullability is used directly where available.

Where safe modeling requires nullability and the header does not establish it, the facade or a trusted convention profile must.

The conservative rule is:

```text
nullable -> Option
nonnull  -> direct value/reference
unknown  -> nullable/restricted representation
```

Unknown nullability never silently becomes non-null.

Out-resource production remains governed by the null-initialize/inspect rule separately.

---

# 44. Callback parameters

A callback parameter passed from C into With is borrowed for callback scope by default.

It does not become owned merely because C passed a pointer.

The default callback origin is the callback invocation itself.

Such a value cannot escape the callback unless stronger evidence supplies:

* ownership transfer;
* a longer-lived external origin;
* static lifetime.

Callbacks therefore use the same ownership/origin model as ordinary foreign calls.

---

# 45. Callback registration and retention

A callback used only synchronously during a foreign call needs no retained lifetime.

A callback retained by C must be modeled as retained.

Conceptually:

```with
fn register_callback
    retains param 1 by param 0
    retains param 2 by param 0
```

where the callback and userdata must outlive the retaining resource.

An unregister operation may release those retained dependencies.

Absent a modeled release, they persist until the retaining resource is destroyed.

---

# 46. Callback ownership transfer

A callback may receive ownership only through explicit trusted evidence.

Conceptually:

```text
callback consumes param N
```

Because getting this wrong can cause double destruction, it is never silently inferred.

---

# 47. Reentrancy

Foreign callbacks may re-enter With.

The compiler does not need a separate C callback alias-analysis system.

It uses known closure captures.

If callback `C` captures origins:

```text
O1, O2, ... On
```

then a foreign operation that may invoke `C` is treated as potentially affecting those origins according to the callback's allowed capture operations.

This applies to:

* retained callbacks;
* synchronous callbacks supplied for one call.

Immutable captures contribute read dependencies.

Mutable captures contribute mutation/invalidation effects.

Owned captured state follows ordinary ownership and retention rules.

A facade may assert that an operation cannot invoke applicable callbacks, but this is capability-granting trusted evidence.

Absent such evidence, relevant calls are conservatively reentrant.

---

# 48. Thread semantics

Modeled foreign resources are thread-bound by default.

The concurrency capabilities are:

```text
thread creator
send
share
drop_any_thread
```

The default is:

```text
thread creator
```

meaning:

* operations occur on the creating/owning thread;
* destruction occurs on that thread;
* ownership does not move to another thread.

No capability is inferred from pointer representation.

---

# 49. `send`

`send` means ownership may move to another thread.

In v1:

> **`send` requires `drop_any_thread`.**

With does not marshal destruction back to a creator thread.

Therefore a creator-thread-bound resource is not sendable.

A facade declaration granting `send` without `drop_any_thread` is invalid in v1.

---

# 50. `share`

`share` means shared references to the resource may be used across threads according to With's ordinary aliasing rules.

`share` is independent of `send`.

A resource may be movable without permitting concurrent shared calls, or shareable according to its own foreign API contract.

---

# 51. Callback thread behavior

Retained callbacks are assumed to execute on the thread/domain in which registration occurs unless stronger evidence says otherwise.

A foreign API that may invoke a callback from arbitrary threads must state that fact.

Conceptually:

```text
callback_thread any
```

Captured With state must satisfy the corresponding send/share constraints.

A callback cannot move non-sendable With state across threads merely because C performs the call.

---

# 52. Runtime foreign calls

The With runtime is not exempt from the foreign-state model.

> **Hidden runtime behavior must not invalidate a foreign view that safe user code is permitted to hold.**

Runtime foreign calls must themselves be described by an internal facade or equivalent audited contract data.

A runtime change that begins mutating a domain supporting live safe foreign views must be caught by analysis/audit.

There is no hidden “runtime calls don't count” exception.

---

# 53. Resource-operation assignment

Operation membership belongs to the modeled resource contract, not merely to the foreign representation.

When one resource wraps a representation, mechanically safe association may be inferred for presentation.

When multiple resources wrap the same representation, semantic assignment must be known before a modeled-resource call is available.

Assignments may be explicit:

```with
fn inflate
    of InflateStream
```

or derived from trusted unambiguous facade/profile evidence.

Ambiguous semantic assignment fails closed.

Tooling may suggest likely assignments.

---

# 54. Method presentation

Ergonomic method grouping is not safety semantics.

With may silently use naming conventions for harmless presentation transformations such as:

* grouping functions as methods;
* shortening prefixes;
* namespace presentation.

For example:

```text
sqlite3_prepare_v2(...)
```

may be presented as:

```with
db.prepare(...)
```

when a recognizable naming/receiver pattern suggests it.

This is permitted because being wrong changes API presentation, not ownership or lifetime behavior.

Presentation never establishes:

* ownership;
* lending;
* consumption;
* destruction;
* dependency;
* independence;
* retention;
* preservation;
* thread safety;
* static lifetime.

Safety semantics must already be valid independently.

---

# 55. Presentation overrides

A facade may rename, regroup, or suppress automatically presented methods.

Conceptually:

```with
fn sqlite3_prepare_v2
    of Database
    rename prepare
```

or:

```with
fn unusual_api_name
    of Database
    rename query
```

Explicit facade presentation overrides automatic presentation convention.

If automatic grouping is ambiguous, method sugar may simply be omitted while the underlying modeled foreign operation remains available.

---

# 56. Parameter references

C headers frequently omit parameter names.

Facade contracts must therefore support:

```text
param name
param N
param type T
```

where:

* a name must exist and be unambiguous;
* `param N` is zero-based;
* type-based reference is legal only when exactly one parameter matches.

Ambiguous references are compile errors.

This applies to:

* borrow origins;
* consumes;
* retains;
* destroyed-by callbacks;
* ownership transfer;
* lifetime relationships;
* callback contracts;
* operation assignment.

---

# 57. Parameter diagnostics

Because external C documentation commonly numbers arguments from one, positional diagnostics must always print the resolved C parameter.

For example:

```text
dependency refers to param 0:
    sqlite3 *db
```

or:

```text
consumes param 4:
    void *pApp
```

A user-facing diagnostic must not print only an opaque positional index when the resolved declaration is known.

The `sqlite3_create_function_v2` case is the canonical reason: a prose draft misidentified `param 5` as userdata, but checked resolution would immediately have shown that `param 5` is `xFunc` and the userdata is actually `param 4`.

---

# 58. Imported constants

Facade contracts may refer to imported compile-time constants.

Macro and enum constants are equivalent once successfully materialized as With compile-time values.

A contract fails to compile if a referenced constant is:

* missing;
* ambiguous;
* unavailable;
* not compile-time.

---

# 59. Profile use of naming conventions

An explicitly adopted convention profile may infer safety-critical facts from names because adopting the profile is itself trusted facade evidence.

For example, a profile may define:

```text
*_new   -> owned result
*_ref   -> owned/reference increment
*_unref -> destroying operation
*_get   -> borrowed result
```

But every capability-granting match remains subject to unique-or-nothing.

Names are therefore allowed inside trusted conventions.

They are not standalone core-language proof.

---

# 60. Core silent inference

Without profile opt-in, core With may silently infer only conclusions whose failure direction is conservative or purely presentational.

Examples:

```text
unknown independence
    -> dependent

unknown preservation
    -> invalidating

unknown nullability
    -> nullable/restricted

unknown encoding
    -> bytes, not str

unknown thread capability
    -> creator-thread-bound

unknown foreign-state precision
    -> coarse library domain

safe recognizable naming
    -> presentation sugar
```

Core With does not silently infer from names:

* constructors;
* destructors;
* consumers;
* ownership;
* static lifetime;
* status conventions;
* send/share capabilities.

---

# 61. Facade verification

The compiler verifies every facade statement that is mechanically checkable.

Examples:

* referenced declaration exists;
* resource representation resolves;
* parameter references resolve uniquely;
* destroyer accepts the appropriate representation;
* producer return/out parameter matches;
* status constant is compile-time;
* callback parameter is actually callable;
* `consumes` refers to a compatible value;
* state domain exists;
* convention rule resolves uniquely;
* thread-capability combinations are legal.

Verification does not pretend to prove semantic facts that require trusting the foreign API contract.

A structurally valid but semantically false facade remains a trusted-boundary bug.

---

# 62. Facades and profiles are versioned

A facade describes a particular foreign API version or compatible range.

Convention profiles are likewise versioned.

The compiler validates them against the actual imported declarations every build.

ABI compatibility does not imply semantic compatibility.

No facade or convention becomes permanent compiler knowledge merely because it once matched a library.

---

# 63. `with analyze` foreign-contract view

`with analyze` must expose the effective modeled foreign contract.

At minimum it reports:

* resources and representations;
* producers;
* initialization states;
* automatic destroyers;
* alternate destroyers;
* borrow/consume effects;
* retained parameters;
* destroy-callback transfers;
* borrowed-result origins;
* parent dependencies;
* independence;
* status conventions;
* nullability;
* foreign-state domains;
* invalidation/preservation;
* static lifetime;
* callback retention;
* callback execution/thread behavior;
* thread affinity;
* send/share/drop-any-thread capabilities;
* presentation transformations;
* convention-profile facts;
* provenance for every fact.

It must additionally flag suspicious configurations such as:

* producer with no valid destroy path;
* destroying operation still presented as a borrow;
* retained callback with no lifetime owner;
* illegal thread capability combination;
* ambiguous profile inference;
* profile fact shadowed by explicit override;
* a function whose name/signature heuristically resembles a destroying operation but which remains exposed as a borrow.

For the last case, the warning is advisory only.

For example:

```text
warning: sqlite3_close_v2 is exposed as a borrow
= heuristic: name/signature resembles a destroying operation for Database
= this warning does not establish destruction semantics
= help: declare `destroys` if it destroys the resource, or explicitly declare `lend` to confirm borrowing semantics
```

The heuristic must not:

* change the effective contract;
* classify the function as destroying;
* remove the operation;
* or grant/revoke safety capability.

An explicit `lend` declaration suppresses the warning and records that the facade author deliberately reviewed the operation.

This is the intended application of:

> **Heuristics may suggest; they do not decide safety-critical semantics.**

---

# 64. Application-level safety contract

Once a resource is properly modeled:

* construction may be safe;
* borrowing operations may be safe;
* consuming operations move ownership;
* destroying operations terminate ownership correctly;
* alternate destroyers cannot accidentally double-destroy;
* dependent children receive compile-time lifetime enforcement;
* borrowed foreign storage participates in normal view analysis;
* owned foreign memory uses the correct foreign destruction path;
* retained callbacks/userdata have modeled lifetimes;
* thread crossing is restricted according to evidence;
* application developers do not write `unsafe` merely because the implementation crosses a C ABI.

The boundary remains explicit:

> **With proves its own semantics; the facade vouches for foreign semantics that C itself does not encode.**

---

# 65. Existing half-modeled C support

Any existing safe C constructor or automatic wrapper without a complete ownership/destruction contract is non-compliant.

It must either:

* become fully modeled under this ruling;
* or revert to the raw C surface.

The pragmatic allowance for conventions does not permit accidental leaks or double destruction merely because an API pattern appears obvious.

---

# 66. First validation target: SQLite

The first complete facade written against this ruling must be SQLite.

It must cover at least:

* `sqlite3` as an owned pointer resource;
* `sqlite3_open` out-parameter production;
* `SQLITE_OK`;
* failed-open resource production;
* `sqlite3_close`;
* `sqlite3_close_v2`;
* `sqlite3_stmt` as a dependent child resource;
* `sqlite3_prepare_v2`;
* `sqlite3_finalize`;
* borrowed text from `sqlite3_errmsg`;
* nullable borrowed text from `sqlite3_column_text`;
* view invalidation across statement mutation;
* a callback API with userdata;
* `sqlite3_create_function_v2` or equivalent consume-with-destroy-callback behavior;
* retained callback/userdata lifetime;
* thread capability declarations;
* method presentation from `sqlite3_*`;
* at least one explicit presentation override.

The SQLite facade must compile and typecheck before:

* the public C-interoperability example;
* release UAT;
* blog examples;
* documentation examples

are rewritten against the new surface.

> **The facade is intentionally written first because validation artifacts must test the rule, not define it.**

A previous release-UAT campaign demonstrated the failure mode of adapting an example to fit an incomplete rule instead of fixing the rule itself.

No example, UAT, public sample, or blog code may therefore be rewritten against this surface until the SQLite facade compiles against the actual imported API.

The SQLite facade is the executable specification test for the facade language.

The fact that a prose draft of this ruling miscounted `sqlite3_create_function_v2`'s userdata parameter is itself evidence for this ordering: the compiler-checked facade must validate the contract before human-written examples freeze it.

---

# 67. Campaign boundaries

This ruling does not reopen or absorb the `d43-drafts` campaign or the storage-types campaign.

Those remain independent work.

Their only relevant intersection here is §13.1:

```with
Representation.zeroed()
```

uses the storage-types model's ordinary zeroed construction semantics as intended.

This ruling consumes that existing construction rule.

It does not redefine or modify it.

---

# 68. Pragmatism is not permissiveness

This ruling rejects two extremes.

It rejects:

> **Only formal proof counts.**

That would force programmers to restate reliable conventions and recreate the suffering With exists to remove.

It also rejects:

> **If it usually works, infer it.**

That would turn conventions into hidden unsafety.

Instead the language asks:

> **What do we know, what are we intentionally trusting, and what is the failure mode if we are wrong?**

If being wrong causes only:

* earlier invalidation;
* a shorter lifetime;
* loss of method sugar;
* a compile rejection;
* a need for a facade clause;

silent inference is acceptable.

If being wrong can cause:

* double free;
* use-after-free;
* ownership confusion;
* missing destruction;
* lifetime extension;
* error misinterpretation;
* unsafe retention;
* unsafe thread crossing;

the capability requires:

* proof;
* explicit facade evidence;
* machine-readable header evidence;
* or deliberate adoption of trusted convention evidence.

That is the pragmatic standard.

---

# 69. Final normative summary

For modeled C:

> **With uses the strongest reliable evidence available, including conventions where doing so is safe and useful.**

> **A convention may be inferred silently when being wrong can only remove capability or reject a valid program. A convention that can create memory unsafety must be explicit, strongly established, or deliberately trusted.**

> **Heuristics may suggest; they do not decide safety-critical semantics.**

> **With proves what it can, trusts what the facade asserts, exploits safe conventions where appropriate, refuses what none of those justify, and never pretends one category is another.**

Accordingly:

* ABI/header reality constrains all modeling;
* explicit facade evidence overrides convention-profile evidence;
* convention-profile evidence overrides conservative defaults;
* profile ambiguity grants nothing;
* every effective fact retains provenance;
* resource semantics are distinct from physical C representation;
* no destruction evidence means no safe owned resource construction;
* borrowing is trusted facade semantics;
* consuming and destroying semantics require trusted evidence;
* alternate destroyers must all be modeled before safe exposure;
* ownership and status remain independent;
* unknown status remains uninterpreted;
* pointer out-production initializes to `NULL` and inspects afterward;
* API-established null failure becomes `Option`;
* unknown independence means dependency;
* unknown preservation means conservative invalidation;
* borrowed foreign memory always has a real origin;
* unknown encoding does not become `str`;
* unknown nullability does not become non-null;
* unknown thread capability means creator-thread-bound;
* `send` requires `drop_any_thread` in v1;
* callback capture effects participate in normal borrow/liveness analysis;
* retention, consumption, and destroy-callback transfer use one ownership vocabulary;
* runtime foreign calls obey the same state-domain model;
* safe naming conventions may shape presentation but never safety;
* tooling may aggressively suggest contracts without silently adopting them;
* suspicious destroyer-shaped borrows are linted but never silently reclassified;
* the SQLite facade must compile before examples or UATs are allowed to freeze the surface.

The final guardrail is:

> **Never half-model unsafely.**

And the test for every future C-interoperability inference is:

> **What happens if this inference is wrong?**
