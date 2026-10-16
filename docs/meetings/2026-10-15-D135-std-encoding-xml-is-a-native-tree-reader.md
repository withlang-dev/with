# D135 — `std.encoding.xml` is a strict native tree reader (`XmlDocument.parse`), not an expat facade or a token stream (delegated)

**Laws:** docs/mission.md: a tool exists because a task needs it; the
sourcing rule (libstd-spec "Sourced from corpora"): a corpus is added by a
ruling, and a native module is written when it is small.

**Date:** 2026-10-15. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Context:** D121 step 3, the
GObject-introspection half: `.gir` files are XML, and the facade proof
engine (§16.2b.15 item 2) reads transfer annotations from them. The
compiler never `c_import`s, so a C parser was never an option for this
consumer.

**Decision.** `std.encoding.xml` reads a document into a tree:
`XmlDocument.parse(source)` and `XmlDocument.parse_file(path)` return
`Result[XmlDocument, XmlError]`; an `XmlElement` has its name, attributes
in order, child elements in order and the character data written directly
inside it; `attr(name)`, `has_attr`, `child(name)` and `count(name)` query
it. The reader is strict: elements, attributes in either quote, character
data, comments, processing instructions, CDATA, the five predefined
entities and numeric character references; a document type declaration is
skipped unread; a namespace prefix stays on the name it qualifies
(`c:identifier`); malformed input is an `XmlError` naming the line, and
nothing is repaired. 300 lines of With; GLib-2.0.gir (4 MB) reads in 31 ms.

**Why a tree, not the tokenizer the plan sketched.** The consumer asks
questions by name (`return-value` of this `method`, the `free-function` of
that `record`), which is a tree's shape; a token stream makes every reader
rebuild the tree it needs. A tokenizer can be derived from the reader when
a streaming consumer appears; the reverse is what every consumer would
write by hand. **Why native, not expat.** The reader is small, the
compiler itself consumes it, and a corpus is added by a ruling: nothing
here needs one.

**What the others do.** Go's `encoding/xml` offers both a decoder (token
stream) and `Unmarshal` into structures; Rust's ecosystem has `quick-xml`
(events) and `roxmltree` (a read-only tree); Swift's `XMLParser` is
event-based with `XMLDocument` on top. A read-only tree is the common
first layer.

**What the spec says.** libstd-spec §3.6 sketched `std.encoding.xml` as a
tokenizer, status not started, expat a sourcing candidate to rule. This
entry lands the module as a tree reader and updates that status; the
section is a plan, not normative language.

**Mission fit.** `with get` for a GLib-based package reads the package's
own `.gir` and presents what it declares; the user writes nothing.

**Prediction.** Eric accepts (85%): a tree is what the one consumer needs,
and native beats a facade for 300 lines. The likelier veto is the module's
home (`std.xml` rather than `std.encoding.xml`); that is a file move.
