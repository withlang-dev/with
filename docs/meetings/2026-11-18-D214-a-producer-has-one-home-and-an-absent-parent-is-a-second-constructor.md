# D214 — A producer has one home; an absent parent is a second constructor

**Laws:** 4 (one meaning, one spelling), D51 (that NULL is accepted is a
stated fact with a citation).

**Date:** 2026-11-18. **Status:** ruled by Eric. The spec words are derived
and come to him as a diff with the implementation.

**Context.** #3122: a producer that receives another resource was presented
twice, as a constructor of the produced type (`Mime.curl_mime_init(e)`) and
as a forwarder on the parent (`e.curl_mime_init()`). `rename new` named
both, and the forwarder collided with `Easy.new`; `of Mime` did not remove
it. `curl_mime_init(NULL)` is legal since curl 7.87.0 and no clause could
say so: `nullable param 0` and `param 0 fixed null` were both refused on a
resource parameter.

**Ruling.**

- **One home, chosen by `of`.** Without `of`, the producer is a method of
  the first resource it receives (`db.prepare(...)`, as the SQLite scenario
  writes it). With `of Mime` it is a constructor of the produced type and no
  forwarder is generated. `of` then means for a producer what it means for
  every other operation. The call sites of the spelling that goes away are
  counted before landing, and its error offers the surviving spelling as a
  fix-it.
- **An absent parent is a second constructor.** `Mime.new()` returns a value
  with no parent; `Mime.with(e)` returns one that cannot outlive `e`.
  Dependency belongs to a value's origin, not to its type (as one view type
  can be static or borrowed from a parameter), so no clause chooses for the
  whole type.
- **The spelling is `param N fixed null`** on a resource parameter. It is a
  claim and needs a citation: parameters default to non-null. It can carry
  a version floor (this one holds since 7.87.0), and the drafter refuses it
  against an older pinned package.
- **Two entries for one C name.** One C function is presented as two
  operations, once with the parameter and once with it fixed null, each
  item with its own `rename`. That spelling is settled in the same change.

**Warning recorded for #3121.** `curl_slist_append` looks the same and is
not: on failure it returns NULL and the original list is still valid.
"Consumes the list, returns the new one" would leak the whole list on a
failed append. It takes D59's failed-production form, where the error
carries the original resource back.

**Alternatives.** Both homes with `rename` naming both: the defect. Always
on the produced type: breaks `db.prepare` and the SQLite scenario. One
constructor taking `Option[&Easy]` with the result's dependency decided by
the argument: needs an origin analysis that carries "depends on `e` if
present".
