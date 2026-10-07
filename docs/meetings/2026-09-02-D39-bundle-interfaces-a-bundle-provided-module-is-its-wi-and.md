# D39 — Bundle interfaces: a bundle-provided module is its `.wi`, and callable semantics are the declaration

**Laws:** 6 (docs/mission.md).

**Date:** 2026-09-02
**Status:** Ruled by Eric. Verbatim:

> A bundle contains: object code; manifest; canonical textual module
> interfaces (.wi); interface fingerprint. Consumers resolve a
> bundle-provided module to .wi, not its source. .wi is ordinary With
> declaration syntax in an interface-only parser mode. Functions may omit
> bodies and storage-backed globals may omit initializers only in
> interface input. Bundle interface generation happens after full Sema,
> so the emitter works from finalized semantic declarations rather than
> syntactic source projection. Consumers perform ordinary
> declaration/type/layout Sema on .wi, but no function-body analysis or
> MIR generation occurs for bundle implementations.
>
> No body-inferred ownership/effect information is part of the bundle
> interface. Callable semantics are determined by the declared signature.
> If some information is necessary for a caller to safely typecheck and
> cannot be derived unambiguously from the signature, With's source
> declaration language must gain a way to state it explicitly.

**Declared semantics (verbatim).** "A declaration means what its
declaration says. T → consumed; &T → borrowed for the call; &mut T →
mutable borrow; move self → consume receiver; mut self → mutable receiver
semantics; raw pointers → no With ownership semantics beyond their
declared type; return references use deterministic lifetime/view
elision": the receiver if one exists, otherwise the single borrowed
parameter, otherwise ambiguous — a declaration error at bundle build
time, never at a downstream call (`pub fn choose(a: &Foo, b: &Foo) ->
&Foo` cannot produce a valid interface under the default rules). "If
`fn inspect(x: BigThing)` actually doesn't consume x, then the
declaration was wrong. It should have been `fn inspect(x: &BigThing)`.
The bundle boundary exposing that mistake is a feature." Otherwise
parameter ownership would be "partly specified by the signature and
partly by an invisible implementation-derived fact — precisely the sort
of semantic spooky action that becomes painful once separate compilation
exists." An explicit origin spelling (conceptually `pub fn choose(a:
&Foo, b: &Foo) -> &Foo from a`) is a future real language feature for
authors, never an interface-only annotation of inferred Sema facts: "If a
caller must know it for correctness, it belongs in the function's
contract. If Sema can infer it from a body today for convenience, great.
But before that function can cross a separate-compilation boundary, the
contract needs to be representable without its body." Discovering where
With relies on implementation inference more than its declared semantics
admit is healthy.

**Typed body state.** Not a special case threaded through every phase
but an explicit state early in the AST: `FnDecl { signature, body:
SourceBody(...) | InterfaceBody }` and `GlobalDecl { type, initializer:
Expr(...) | InterfaceProvided }`, with the invariant "Anything requiring
implementation information must reject or ignore InterfaceBody; anything
operating on declarations must work identically." Bodyless declarations
exist only in interface input — `pub fn foo(x: i32) -> i32` in ordinary
`.w` source stays an error — so the language never acquires
C-header-style forward-declaration semantics because the compiler needs
interfaces.

**Constants, globals, layouts.** A constant carries its canonical folded
value (`pub const X: usize = 67`, never `A * 4 + 3`), so interface
constants have no implementation dependencies and the consumer's
dependency closure stays tiny. A storage object carries only its
declaration (`pub let TABLE: [256]u8`); the object supplies storage.
Layouts are emitted as the actual declarations needed to reproduce them,
canonicalized, not source alias/import chains.

**Fingerprint invariant.** The bundle build proves that compiling every
exported module against its emitted `.wi` yields exactly the same
externally visible declaration model as compiling it from source: Sema
computes a canonical exported-declaration graph from both paths and
requires hash equality — type layouts, ABI-relevant field offsets, enum
discriminant values, parameter and return types, receiver mode,
declaration-level ownership and borrow modes, calling convention,
visibility, constant type and value, extern function-pointer signatures,
generic constraints when applicable. The fingerprint is recorded in the
manifest so interface N can never be paired with object N+1; a mismatch
is rejected before linking. An emitter bug is a build failure, not an
ABI corruption.

**Context.** Measured 2026-09-02: Sema on pcre2's 155k migrated lines
costs 6.06 s per program that imports it (hello world 0.03 s), and
`std.regex` is in the prelude. The declarations-only projection is 206
functions, 87 types and 3,052 table globals.

**Alternatives (rejected).** Embed the source and skip bodies in Sema:
every program parses 5.5 MB per corpus (~0.4 s and growing), the binary
carries ~100 MB of source at 30 corpora, and unchecked bodies invite
re-coupling. Hand-written facade declarations: duplicated signatures
whose drift is undetectable at link (the #761 class), does not scale,
and is the `with_*` seam respelled (retired by D30). Binary metadata
over Sema's tables (Rust `.rmeta`, Go export data): exact and fastest,
but a serialization format over the most-churning tables in a
three-month-old compiler; the textual interface upgrades to it if ever
needed. Lazy prelude loading and a faster Sema do not remove the
per-program cost at 30 corpora. Swift's `.swiftinterface` is the model;
Zig has no interface unit.

**Would reopen.** An API that cannot state its returned-view origin
under elision (the explicit-origin feature); a With-authored library
with generics crossing the boundary (`docs/abi_roadmap.md` Level 1).

Supersedes D38's "the interface is the source" wording; D38's key,
store, and embedding stand. Design: `docs/wo_bundles.md`.

**Spec projection landed** (2026-09-02, the words blessed by Eric): §3.4
gains the separate-compilation origin rule (declaration's receiver, else
the single reference parameter, else rejected at bundle build; the
explicit-origin spelling is a future language feature), §18.5c "Bundles
and interfaces" states the bundle, the `.wi` flavor, declaration-only
callable semantics, the Level 0 rule that a generic function stays
corpus-internal and is omitted from (and named in) the interface, and
the fingerprint proof; the §18.5 CLI line for `with version --abi-sha`
stands.
