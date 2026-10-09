# D122 — A borrow through a borrow is a borrow of the same origin; `text param` and owned text returns, proved from the body

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). Two of the three
facade-language features D121 puts first; the third (a buffer-plus-length
input on a producer) is a compiler defect against §16.2b.8, fixed in the
D121 work with nothing to rule. **The compiler is NON-COMPLIANT** until
implemented.

**Context.** A hand-written libxml2 facade (D121's UAT probe) hit three
refusals. Walking from the root to a child was refused: the child is
borrowed from a node, the root from the document, and "a borrowed value with
several origin types is not ruled". `xmlReadDoc`'s `const xmlChar *` input
stayed raw: only `const char *` accepts a `str`. `xmlReadMemory`'s buffer was
refused on a producer.

**References** (checked). Rust: a reborrow carries the input's lifetime
(`fn first_child<'a>(n: &'a Node) -> Option<&'a Node>`). Vale: a reference
taken through a borrowed reference stays in its region. Swift bridges
`String` only to `const char *` (`CChar`); `const unsigned char *` stays
`UnsafePointer<UInt8>`. Rust's `CStr` is `c_char` only.

**Ruling (Eric, verbatim).** "Both predictions are right. Rule them, with one
addition to each."

"Gap 1: yes. A borrow taken through a borrow is a borrow of the same origin,
which is Rust's rule and the only one that makes tree walking usable. One
node type, always borrowed from the document. The addition is what the rule
makes visible next: libxml2 also has operations that take a node *out* of
the document. `xmlUnlinkNode` detaches a node, and the caller then owns it
and must free it. `xmlFreeNode` on a node that's still in the tree is a
double free waiting to happen. So the follow-on is a facade fact for 'this
call detaches param N from its origin and returns ownership.' Without it,
unlinking either gets refused or gets modeled wrong. That shouldn't block
this ruling, but the proof engine will hit it on the first real libxml2
program that edits a tree."

"Gap 2: yes, a `text param` fact, proven from the body. The proof has to
establish two things, not one: the function reads only up to the NUL, *and*
it doesn't keep the pointer. Then a `str` passes exactly as it does for
`const char*`. The addition is the output side, which libxml2 needs just as
badly: `xmlNodeGetContent` returns an owned `xmlChar*` that must be released
with `xmlFree`. So the same fact should cover returns ('text return, owned,
freed by `xmlFree`'), giving the caller a `str` with the copy and free
handled, and the existing 'unknown encoding → bytes' rule still applies to
anything not proven or declared UTF-8."

"Gap 3: a defect, fixed in the D121 work. Nothing to rule."

**Spec projection.** §16.2b.6 "A borrow through a borrow"; §16.2b.8
"Text": `text param P` and `text return, owned, freed by F`.

**Follow-on, not ruled here.** The detach fact: a call that detaches
`param N` from its origin and returns ownership of it (`xmlUnlinkNode`),
after which the destroyer (`xmlFreeNode`) applies to the detached value and
never to one still in its origin. Its spelling is its own brief, before the
first libxml2 program that edits a tree.

**What would reopen it.** A C API where a node borrowed through another
node outlives the document it came from (an origin that is not transitive).
