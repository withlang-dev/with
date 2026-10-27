# D163 — A match arm is `pattern [if guard] => body`; the spec says so (delegated)

**Laws:** 6 (docs/mission.md) — what the program means is written once,
and the compiler's rule is the spec's rule.

**Date:** 2026-10-26. **Status:** delegated (D98): implemented on the
prediction below; Eric vetoes by revert or rewords. **Issue:** #2744.

**Decision.** §9.7 states the arm rule the compiler has always enforced:
an arm is a pattern, an optional `if` guard, `=>`, and a body; `=>` takes
the role `:` plays for every other construct, and the body takes the same
three forms as any other body (inline, indented, braced). §29.13's
introducer rule excepts match arms (their introducer is `=>`, never `:`),
§30.4's `MATCH_ARM` production takes an `ARM_BODY` instead of only an
expression, and §30.8 no longer lists match arms among the `:`/`{`
constructs. No compiler behavior changes; `Some(x):` was and stays
"expected '=>'".

**Context.** Writing `std.task.with_concurrency` (#981) by the literal
§29.13/§30.8 text produced `Some(task):` and a correct refusal; Eric
confirmed the compiler's verdict, and #2744 recorded that the words, not
the compiler, were wrong. The two sentences a literal reader follows said
the opposite of the implemented rule, shown until now only by example.

**What the others do.** Rust, Scala and Kotlin spell an arm `pattern =>
body` in their normative grammar, with a block as a body; the separator is
never the block colon because their blocks have no colon. With's twist is
only that `:` introduces every other body, so the arm's `=>` has to be
stated as the exception that introduces one too.

**Prediction.** 90%: the rule content is settled (Eric confirmed the
compiler is right, and #2744 states it); only the exact sentences are
new, and spec text is a one-commit revert. Not C interop, ownership or
safety, so it qualifies under D98.

**Reopens if** Eric prefers different wording — the veto is a reword,
not a semantics change.
