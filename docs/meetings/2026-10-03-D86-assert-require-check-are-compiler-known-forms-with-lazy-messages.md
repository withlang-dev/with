# D86 — `assert`, `require`, `check` are compiler-known forms; the message operand is evaluated only on failure, under `??`'s right-operand rules

**Date:** 2026-10-03. **Status:** BDFL ruling (Eric: "lazy, with the
mechanism stated", then "blessed" on the words). Spec v7.17: modules.md
§18.2, after the prelude list (the spec has no separate preconditions
chapter; the prelude list is where these names are normative). Issue
#1864. **The compiler is NON-COMPLIANT**: `lib/std/builtins.w` declares
`require`/`check` as functions whose message is an ordinary, eagerly
evaluated argument, and `test/behavior/precondition_lazy.w` stays red
until they become compiler-known forms.

**Context.** `precondition_lazy.w` claimed `require(true, side_effect())`
never runs `side_effect`; it did, and the substring runner hid it until
#1855's exact `expect-stdout` rule. The spec named no lazy message form.

**Decision.** `assert`, `require`, `check` and their `std.testing` forms
are compiler-known forms, not functions. Each evaluates its message only
when its condition is false; the message follows the rules of `??`'s
right operand: its effects do not run when the condition holds, and a move
inside it is a conditional move. No general lazy-parameter feature is
introduced.

**Alternatives rejected.** Eager messages (drop the fixture's claim):
users would hoist checks into an `if` to avoid formatting cost, ceremony
for a message obviously needed only on failure. A `fn() -> str` closure
parameter: call-site ceremony. A general lazy/autoclosure parameter
(Swift's `@autoclosure`): a language feature larger than the need; reusing
`??`'s existing operand rules gives one rule for move and effect
semantics. Rust's `assert!` likewise formats only on failure.

**Reopen if** a user-defined function needs the same lazy operand, which
would argue for a general feature instead of a closed set of forms.
