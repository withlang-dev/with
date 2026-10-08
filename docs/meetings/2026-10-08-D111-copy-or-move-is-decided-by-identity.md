# D111 — Copy-or-move is decided by identity; `str` is a value

**Date:** 2026-10-08. **Status:** ruled (Eric Hartford). **Supersedes** D45
for `str` (D45 named this as what would reopen it: "`str` becoming O(1) to
copy").

**Ruling (Eric, verbatim).** "Copy-or-move is decided by identity, not by
representation. Values have no identity (integers, floats, strings, keys):
passing one copies it, and the caller's is untouched. Resources have identity
(files, tasks, sockets, handles, buffers being filled): passing one transfers
it. Having a heap buffer does not make something a resource. str is a value.
Passing a str always copies. Code using str never sees "use of moved value"
and never needs .clone()."

"How str copies cheaply. Semantics are copy. The implementation is an
immutable, shared, reference-counted buffer: a copy is a pointer plus a count
increment, the last holder frees. At a variable's last use the compiler turns
the copy into a move, with no count traffic, using the drop plan's existing
last-use facts. Text that is built or edited goes through a builder type that
produces a str."

**The one open choice, derived (not a ruling).** How a shared buffer crosses
a fiber boundary: atomic count, or deep copy at the crossing. The existing
rules decide it — atomic:
- §14 places fibers on any OS thread (concurrency.md, structured spawn: a
  child may run on another thread), and §14.15/§25.3 require `Send` for
  `spawn_os` captures and channel sends. `str` is `Send` and must stay so.
- `Rc` is neither `Send` nor `ScopedSend` because its count is not atomic;
  a non-atomic `str` count would put `str` in `Rc`'s class.
- A deep copy at the crossing cannot cover shared state: two threads holding
  copies of one buffer through a `Mutex[Vec[str]]`, an `Arc` or a global copy
  and drop it with no crossing at which to copy. Only an atomic count is
  sound there.
Literals are immortal (no count traffic); last-use moves carry none either.

**Consequences.** `.clone()` on a `str` and `move` of a `str` are redundant
and are removed from the tree. A "use of moved value" on a `str` is a
compiler bug. Specification §2.3 carries the ruling; §15.2's "&str → str
(allocates)" describes materializing a view, which is not a copy of a `str`.
