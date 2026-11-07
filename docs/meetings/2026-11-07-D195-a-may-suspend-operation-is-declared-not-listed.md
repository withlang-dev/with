# D195 — A fiber-aware runtime operation is one whose declaration says it may suspend

**Laws:** 1, 3 (docs/mission.md). D65 (one owner per fact), D110 (facts come from declarations).

**Date:** 2026-11-07. **Status:** delegated (D98, 90%) on #3052; not C
interop, ownership or safety-weakening (the set of operations is the same
the day it lands), easy to reverse.

**Ruling.** Whether calling a method may suspend the current fiber — the
fact `no_suspend` (E0702) and `@[no_await_guard]` (E0701) enforce — is
the method's declaration's. A standard-library method states it with
`@[suspends]` (`Mutex.lock`, `enter`, `enter_mut`, `set`; `RwLock.read`,
`write`, `enter`, `enter_mut`, `set`; `Once.call_once`; `Condvar.wait`;
`Barrier.wait`). A method the compiler itself declares — it types
`Sender.send`, `Receiver.recv` and `Task.join_cleanup` by owner and name,
there being no std declaration — carries the fact where the compiler
interns those names (`Sema.w`), beside the declaration. Sema reads one
table (`suspending_fns`, `builtin_suspending_methods`); no stage keeps a
list of method names (§14.3).

**Why.** `Sema.method_may_suspend_current_fiber` matched owner and
method spellings against a hand-written list; #3045 added three entries
and `RwLock.read`, which is `self.enter()`, was listed twice. A new std
method that parks the fiber had to be remembered in the compiler, and a
renamed one silently dropped out of the check. The attribute is the same
shape as `@[must_use]`: one flag on the declaration, recorded once.

**What the others do.** Rust marks nothing (blocking in async is a lint
by name list in clippy); Swift's `async` is the only marker and
synchronous blocking is unmarked; Zig has no fiber-aware checker. None
has a `no_suspend` region to protect, so none needs the fact.

**Reopens it.** Deriving the fact from the body (a call to the runtime's
park) instead of stating it, once the runtime's park entry points are
themselves declared `@[suspends]`; a user library's own blocking
primitive is already covered (`@[suspends]` is not std-only).
