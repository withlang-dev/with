# D161 — An implicit `it` closure is the nearest enclosing argument whose parameter takes a single-parameter function (delegated)

**Laws:** 1, 3 (docs/mission.md).

**Date:** 2026-10-26. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2326.

**Decision.** §9.3.1 said `it` appears "where the surrounding call site
expects a single-parameter function type" without saying which call. The
closure is the nearest enclosing call argument whose parameter takes a
single-parameter function; a call in between whose parameter takes a
value is part of the closure's body. `names |> any(s.contains(it))` is
`any(n => s.contains(n))`. An `it` with no such argument above it stays
an error, and a closure that the rule places inside another `it` closure
is the nested `it` §9.3.1 already forbids (E0951).

**Context.** The parser wrapped the closure at the innermost call argument
holding `it`, so `any(s.contains(it))` was `any(s.contains(x => x))` and
refused (before #2660, it aborted in codegen). Only one reading
type-checks; the programmer had to write `n => s.contains(n)`.

**Mechanism (Law 3).** The parser cannot see types, so it records where
each closure sits and which call argument encloses it; Sema, which owns
the call's parameter types, moves a closure that met no function demand
to the nearest argument that has one (D128's body recheck loop checks the
moved tree again). The parser no longer decides which call owns `it`.

**What the others do.** Scala: `_` expands to the smallest enclosing
expression that properly contains it, so `any(s.contains(_))` means
`x => s.contains(x)`. Kotlin and Swift (`it`, `$0`) need braces, so the
question does not arise. With's §9.4 `s.contains(_)` partial application
already covers the one-call case.

**Alternatives.** (a) Keep innermost: the program states a closure the
compiler can place, Law 1. (b) Scala's syntactic rule (a bare `it`
argument does not wrap there): right for `any(s.contains(it))`, wrong for
`any(s.contains(it.trim()))`; types decide it, so the type owner does.

**Prediction.** 80% (brief on #2326): only one meaning type-checks.

**Reopens if** a program shows an `it` whose nearest function-taking
argument is not the one a reader would pick.
