# D134 — A borrowed value's origin is per call; `detaches param N` yields an owned, origin-dependent value; `text utf8` is a facade-level declaration validated at the boundary

**Laws:** 1 (docs/mission.md): the compiler never asks for what it knows;
§16.2b.2: never infer what can create unsafety; §16.2b.3: never half-model
unsafely.

**Date:** 2026-10-15. **Status:** ruled (Eric Hartford); spec wording
blessed verbatim (§16.2b.6, §16.2b.8, changelog v7.34). **Context:** D121
step 2, the facade proof engine, hit all three on its first fixture and on
libxml2's shape. The compiler is NON-COMPLIANT until the renderer and Sema
conform.

**Ruling (Eric, verbatim, on the brief's three predictions).**

1. "Per-value origin: rule it as predicted. The agent's argument is
complete. The call site always knows the origin, because it's the argument,
and every language checked agrees that origin belongs to the value, not the
type. D122 already says this. The one-origin field is a renderer artifact."
"One case to state now so it doesn't surprise you later: a C function that
returns a borrow from either of two params. The result's origin would have to
be the shorter-lived of the two. libxml2 doesn't seem to need this, so a
sentence in the ruling saying 'one param, per call' is enough."

2. "Detach: the shape is right, but check one libxml2 behavior first. As I
recall it, xmlUnlinkNode takes the node out of the tree but leaves node->doc
pointing at the document. xmlFreeNode then reads node->doc->dict to decide
which strings it frees. If the document is freed first, freeing the unlinked
node is a use-after-free. If that holds, the detached node is owned but
still bounded by the document. 'Owned Node with Drop armed on xmlFreeNode'
would let it outlive the document, and the compiler would prove a memory
error safe." Two fixes offered, bounded ownership or detach fully through
`xmlSetTreeDoc`; "I'd lean toward the first, since it doesn't depend on
library internals behaving well."

3. "UTF-8 declaration: rule validate-and-fail, as predicted. A declaration is
a claim about the library. If the claim is false, the facade is wrong, and
the failure should say so, naming the C function, the same way a violated
nonnull does. Repairing with U+FFFD would silently change the user's data to
cover for a wrong declaration." "Facade-level declaration with a per-item
bytes override is the right granularity, and fifty repeated utf8 words would
be exactly the ceremony you keep rejecting."

**Verified in libxml2 2.15.4 `tree.c` (fetched for the check).**
`xmlUnlinkNode` rewires only `parent`, `next` and `prev`; `cur->doc` stays.
`xmlFreeNode` reads `cur->doc->dict` and frees a name or content string only
when the dictionary does not own it (`DICT_FREE`); `xmlFreeDoc` frees the
dictionary last. `xmlSetTreeDoc(node, NULL)` copies dictionary-owned names
and text content out (`xmlNodeSetDoc`), but only for some node types, its
comment calls it internal, and on allocation failure it leaves a
dictionary-owned string on a node whose `doc` is NULL. So: bounded
ownership. The detached value is an owned resource dependent on its origin,
the `Statement`-from-`Database` shape the facade already has.

**What the others do.** Rust binds a returned `&'a Node` to the argument's
lifetime at each call; Swift's `@_lifetime(borrow source)` is per function
and scopes the result to the argument whatever its type; Vale's regions are
where a reference points, not a property of the type. Rust's
`Vec::remove(&mut self) -> T` is the safe precedent for detach: a mutating
operation on the owner that returns the owned element; `Box::from_raw`,
`Unmanaged.takeRetainedValue()` and GObject's `(transfer full)` are unsafe
assertions or declarations. Rust's `CStr::to_str` validates UTF-8 and fails;
Swift's `String(cString:)` repairs with U+FFFD and
`String(validatingCString:)` returns nil; Go copies bytes unvalidated.

**Mission fit.** The origin is the argument: writing it per type was
ceremony and split a tree walk across types. Detach is the collection's
`remove` (D27, D44) for modeled C; dependency by default keeps a detached
node inside its document's life without new machinery. One `text utf8` per
library, not one per function; a broken promise fails loudly instead of
rewriting the user's data.

**Supersedes nothing; extends D122.** D122's "open, its own brief" items
(the detach fact, the UTF-8 declaration) are closed here.

**What would reopen it.** A C API whose borrowed return may come from either
of two parameters (then the shorter-lived origin, not yet ruled); a library
whose detach genuinely severs every reference to the origin and wants
independence stated from evidence.
