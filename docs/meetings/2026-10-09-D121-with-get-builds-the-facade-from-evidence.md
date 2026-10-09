# D121 — `with get` builds a package's facade from evidence, strongest first; users never write facades for packages

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). Extends D51 (the
modeled-C ruling) within its terms: proof, header annotations and adopted
profiles are evidence D51 already accepts; this ruling orders them, adds a
shared per-package registry, and makes `with get` the producer. **The
toolchain is NON-COMPLIANT** until implemented.

**Context.** A UAT for `with get libxml2` needed a facade: without one every
call is raw and a user program may not write `unsafe`. The facade was
written by hand, as the SQLite, curl, zlib, bzip2 and SDL ones were. The
brief proposed generating facades mostly from name conventions ("`Get` means
borrow") adopted through profiles, which D51 permits but which is the
weakest evidence: libxml2's `xmlNewNode` and `xmlDocGetRootElement` both
return `xmlNodePtr`, one owned and one a pointer into the document, and a
naming rule is one wrong guess from a double free.

**Ruling (Eric, verbatim).** "I do not want users hand-writing facades for
conan packages."

"The brief misses that With already has much stronger evidence lying
around. Conan packages come with their source, and With already has a tool
that reads C function bodies: the migrator. That's how nullability is
decided now, by evidence instead of declaration site. The same analysis
answers ownership questions as proofs, which D51 explicitly accepts:
xmlNewNode's body allocates and returns without storing the pointer
anywhere, so the result is owned. xmlDocGetRootElement's body returns a
field of its doc argument, so the result is borrowed from doc. A function
that calls free on its parameter, or passes it to another destroyer, is a
destroyer, and that pairs it with the matching producers. No names
involved, and the libxml2 trap disappears, because the two functions'
bodies say different things."

"So with get libxml2 builds the facade from evidence, strongest first:
Proof from the library's own source. This should cover most functions in
ordinary C libraries. Annotations the library ships: `__attribute__((malloc))`,
`nonnull`, `returns_nonnull`, and full ownership metadata where it exists
(GObject-introspection files declare transfer full/transfer none for the
whole GTK stack). A shared registry of facts, one per package, alongside the
Conan recipe, for the few things neither proof nor annotations settle. Each
is written once, reviewed, and used by every With user, the way
TypeScript's DefinitelyTyped works. Nobody writes one per project.
Name-convention profiles only as a last resort, explicitly adopted, as D51
requires. Anything still unproven stays raw and appears in a report."

"The user experience is then: with get libxml2, and a summary like '212
functions safe, 14 raw: here they are.' The user never writes a facade, and
can still override any single fact in their project."

"The three gaps the hand-written attempt hit are needed under any approach:
a borrow that can come from either the document or another node, unsigned
char* as text, and buffer-plus-length inputs on producers. Facade-language
features come first, because a generator can only emit what the language
can express."

"Binary-only packages (no source in the recipe) fall back to annotations,
registry and profiles. That's the minority case, so it shouldn't drive the
design."

**What the references do** (checked in `.reference/`). Swift imports C raw
and takes ownership facts from header attributes (`swift_attr("retain:…")`)
and sidecar `.apinotes` files (`swift/apinotes/`), never from names. Rust's
bindgen and Zig's `@cImport` emit raw bindings; safe wrappers are written by
hand. None proves ownership from the library's own source.

**Facts the ruling rests on, checked.** D107 already decides a migrated
function-pointer parameter's nullability from bodies, callers and sinks, as
a corpus fixed point. `src/compiler/ConanRecipe.w` already reads a recipe's
`conandata.yml` for its source archive (`with get` source builds), so the
source a proof needs is reachable for Conan Center packages.

**Order of work.**
1. The three facade-language features (each its own brief): a borrow whose
   origin is the origin of a borrowed argument (a node borrowed from a node
   is borrowed from the node's document); `unsigned char *` as text input;
   a buffer-plus-length input on a producer.
2. The proof engine over a package's C source, reusing the migrator's body
   analysis: owned producer, borrowed return with its origin, destroyer and
   its pairing.
3. Header annotations (`malloc`, `nonnull`, `returns_nonnull`, GObject
   introspection transfer annotations).
4. The per-package registry beside the Conan recipe, and its review rule.
5. `with get` writes the facade and the report; project overrides.
6. The libxml2 UAT over the generated facade (its program: parse, walk the
   tree, read attributes, no `unsafe`).

**What would reopen it.** A Conan Center majority of binary-only packages,
or proofs that cover too little of ordinary libraries to make the registry
the minority source.
