# D226 — In-place resources: several initializers, a literal status, the facts file, and the draft's proof

**Laws:** D51 (a destruction contract is stated or proven, never named),
D198 (a proof about C is enumerable), 4 (one meaning, one spelling).

**Date:** 2026-11-21. **Status:** ruled by Eric; the words are blessed and in
spec v7.77.

**Context.** #3173. A record the caller allocates and an init/end pair fill
and release (`z_stream`) is an in-place resource. A survey of six libraries
(zlib, bzip2, xz, libyaml, libuv, expat) found that a draft from proof alone
proposes none: zlib and bzip2 have two pairs over one record and free
through the record's own hook field; xz has about twelve initializers and
one end; libyaml has an unread unit and nested fields. So the pairs must be
stated, and the language had no way to state them in a facts file, to give
several initializers, or to name a literal status.

**Ruling.**

- **The draft's proof (A).** Every unit read; a header the package installs
  defines the record; nothing produces or destroys a pointer to it; the init
  gives one field a fresh allocation nothing else keeps; the end takes the
  record alone and passes that field to a destroyer; one such init and one
  such end. An init that can report success with the allocation failed is no
  proof, unless the destroyer accepts a null pointer. For a prebuilt binary
  the result is evidence and grants nothing.
- **The init's status (B).** A draft states `ok K` only when the init's body
  proves K is its success return; otherwise it states no in-place resource.
  Without `ok` the resource would be live after a failed init and the end
  would run on storage the init never filled.
- **A literal status (C).** `ok` takes an integer literal as well as a
  constant's name. The rule was never that a literal is forbidden, only that
  zero is not assumed to mean success; `ok 0` is the contract saying so.
- **The facts file (D).** It may state `init f(self)`, `ok K` and `drop g`
  on a resource, each line cited, checked against the proof where the source
  allows and refused where it contradicts.
- **Several initializers (E).** Each `init` clause is a constructor. An
  initializer states its own status on its own line, `init f(self), ok K`,
  as `from f, nonnull` states a fact of one producer; a clause never binds
  to "the init above it", which would make the order of lines carry meaning.
  A resource-level `ok` is the convention for every producer that states none.

**Order of work (Eric).** C, D and E; then zlib's real initializers; the
registry facts for zlib, bzip2 and xz; the survey again; then the proofs.
No further work on the proof until a survey shows it drafting something.

**Alternatives.** Binding `ok` to the initializer above it (order carries
meaning). One resource per initializer (xz would be twelve types for one
stream). A draft without `ok` for a status-returning init (unsound).

**Reopen if** a library's init and end do not share one field, or a survey
shows the draft's proof never proposes a resource on real libraries.
