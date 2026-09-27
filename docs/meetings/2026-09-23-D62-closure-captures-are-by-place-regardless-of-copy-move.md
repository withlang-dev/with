# D62 — Closure captures are by place regardless of `Copy`; `move ||` closures own their environment

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric, on #1586 and #1567:
"Copy captures are by place, always. Not only when the body writes" and
"`move ||` closures own their environment"). §12.4 carries the text.

**Decision.** A capture is by place whether or not the type is `Copy`; a
read through a capture of a `Copy` value copies it; `move ||` transfers
ownership, which for a `Copy` value is a copy. Captures are one of three
views of the place — read, mutate, consume — and a consuming capture makes
the closure callable once, leaving the place owned by its scope if never
called. A `move ||` closure is an ordinary value that owns its environment
(inline when every capture is `Copy`, otherwise a heap cell owned by the
closure value, freed when the closure drops, captured `Drop` values
destroyed then — never the caller's frame); it may be returned, stored, or
sent when every capture is `Send`. A non-`move` closure stays a view of its
frame and may not be returned; the diagnostic's fix-it is `move ||`.

**Why "always" and not "when the body writes".** A capture mode that flips
on the body means adding one `+= 1` inside a closure silently changes how
the outer variable is held, and the error appears at an unrelated site
(the caller's later use of `n`) — the same body-dependent hazard as origin
inference in §3.4, with nothing bought for it. One rule is simpler to
state and check, and it is what Go, Swift and Rust do (Rust borrows `Copy`
captures too; only `move` copies). The behavior that changes: mutating `n`
while a read-only closure over `n` is alive was allowed under by-copy (the
closure saw a stale value) and is now an exclusivity error — the correct
outcome; the snapshot is spelled `move ||`, which now says exactly that.
This retires the "assignment to a `Copy` capture" diagnostic proposed
under #1486 before it ever reached main: `count += 1` in a closure is what
the user meant.

**Why `move` closures own their environment.** The spec's own example
(`let h = move || owned.len()` — "owned is invalid after closure creation")
only makes sense if the closure took `owned` somewhere that outlives the
frame; putting a `move` environment in the caller's frame was the #1567
wrong code. Vale and Rust both give a moved closure an owned environment.

**Not decided here.** The type of a returned closure: `fn(i32) -> i32`
carries no environment, so whether the spelling is `impl Fn`-style, a
named `Closure[...]`, or a trait — and with it whether closures can be
trait objects — is its own brief before code.

---
