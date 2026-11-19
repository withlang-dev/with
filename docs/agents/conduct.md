# Conduct: fallbacks, done, verifying, anti-patterns

Moved verbatim from AGENTS.md (#2374). Nothing here was reworded.

## No Silent Fallbacks

When code can't be correctly generated, fail loudly with a diagnostic and exit
non-zero. Forbidden regardless of what tests say: emitting a placeholder body
(`-> Never`, `comptime_error(...)`, `panic("TODO")`, `return 0`); emitting an
`extern fn` to paper over a function the translator couldn't handle; silently
dropping a clause, arm or statement; "simplifying" a construct into something
that behaves differently; adding a `TODO` to emitted output and continuing.
**A migrator that produces 30/30 files with silent stubs is worse than one that
produces 0/30 with a loud error.** Emit a diagnostic naming the function and
location, return non-zero, leave the work visible. If a helper has no
error-return plumbing, wire it. Never invent a placeholder.


## "Done" Is a Claim That Requires Evidence

Not done because tests pass, the build succeeds, the commit was accepted or
output files exist. Done when the output is correct (what a human familiar with
the source would expect), the edge cases you noticed have tests or comments
explaining why they're uncovered, and anything unsolved is filed or surfaced as
a loud failure. Gut check: *did I make the success condition true by doing the
work, or by redefining the success condition?* This applies especially to
translation, migration and codegen tasks where "the build is green" says almost
nothing.


## Verify by Running, Not by Reasoning

The compiler's half-implemented corners — mutable aliasing, slice mutability,
coercions, which types are spellable — are where reasoning from layout,
signatures or spec text goes wrong.

**Spell it and run it.** Before concluding a type, mechanism or API works, write
the smallest program that uses it and compile it. A type usable-looking from its
layout may be unspellable as a parameter (`ListRange`); a `mut` parameter may
*move*; `&raw place` may need `const`/`mut`.

**Exhaust small answer-spaces in one pass.** When a question has an enumerable
set of answers ("how many ways can a mutable buffer cross a call?"), test all at
once and write the matrix — a verdict from partial evidence flips with the next
case. Concluding-and-patching the same question twice means stop and enumerate.

**Code settles facts; intent is the maintainer's call.** When a spec promise and
an implementation fact disagree, settle the facts by running, then surface the
contradiction rather than assuming which side is canonical. Test the
inconvenient premise first.

**Otherwise, keep moving.** Stop only for a decision genuinely the maintainer's
— intent, scope, or a go/no-go on real risk. When the path is clear and
self-scoped, proceed and report; restraint on a clear path is under-autonomy
wearing discipline's clothes.


## Anti-Patterns

**Weakening the check.** If a check fails, make the code pass it, or confirm
with a human that the check is wrong. Never downgrade it, add an exemption, or
route around it.

**Editing a user program to make it pass.** Release UAT fixtures
(`build/release_uat_fixtures/`), `examples/`, and any code on the blog or the
homepage are contracts with Eric and everyone who read them. When a compiler,
spec or stdlib change breaks one, the change is what broke: stop and take it to
Eric; never edit the program (2026-06-17 a c_import rule change broke the
raylib spiral UAT; it was rewritten to `unsafe` to go green without Eric's
knowledge). Ruling (Eric, 2026-09-22): examples track the current spec. A
**spec change** that breaks an example updates the example in the same change,
under the ruling, and says so; a **compiler or stdlib** change that breaks an
example is a defect in the change. Silently rewriting a program to go green is
never either.

**`unsafe` in a user program.** An application developer never writes
`unsafe`. If a UAT fixture or example needs it, the compiler forced it and the
defect is the compiler's: model the C surface, prove the call, or make it safe.
`with build :user-programs-safe` (a gate of `:release-uat`) fails on any
`unsafe` in those programs. `unsafe` belongs to library maintainers and the
runtime.

**"Pre-existing" without evidence.** A failure is pre-existing only if verified
on the previous commit — never with `git stash`; use `git worktree` or a clone.

**"Good enough for now."** A 90%-working translator that silently mishandles
10% is 0% done with a reporting problem. The bar is correctness, not coverage.


## Common Mistakes

- Misreading AST layouts; guessing APIs — read the source.
- Working around compiler bugs instead of fixing the root cause.
- Writing C when With works; `@[c_export]` for internal boundaries.
- Guessing linker flags: know which link path you're on (cc vs lld).
- Using `with build` as a debugging tool (5 minutes) instead of `grep`, `nm`,
  `lldb`, `with check`.
- Iterating unordered maps or using pointer-address ordering: breaks fixpoint
  determinism.
- **Never use `git stash`** (it has destroyed uncommitted work; `pop` and
  `drop` too). Use `git worktree` or a clone.


## Success Checklist

A change is acceptable only if, driven by the pinned seed
(`WITH=$PWD/src/main`): `src/main build`, `src/main build :test`,
`src/main build :test-green` all pass (the battery), and before a seed cut or
a release, `src/main build :release-checks`. If any fails,
continue debugging until it passes.
