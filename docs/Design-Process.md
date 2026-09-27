# Language Design Process

How a change to With happens: from a question about the language, through
a brief and a ruling, to a specification change, an implementation, and a
merge. The rules below are the repository's own (`CLAUDE.md`), collected
here in their original words; this document does not add policy.

## The specification leads

`docs/spec/` is the bible. For D22, `docs/meetings/d22-Eric-Ruling.md` is
the complete controlling ruling: if the spec, requirements, decision summary,
plan, tests, comments, or code omit or conflict with it, those sources are
non-conforming and must be repaired to match it. Two rules are otherwise
absolute:

**The spec leads the implementation.** A spec change is a ruling that the product
is now NON-COMPLIANT until the implementation catches up. No "implement first,
spec after," no "hold the spec text until the code lands," no reverting spec text
to match what the code does. Compliance chases the spec, never the reverse. When
spec and implementation disagree, the implementation is wrong — or the
disagreement is surfaced to Eric for a ruling; it is never resolved by quietly
editing the spec.

**Spec changes are solemn.** Only Eric authors or blesses normative spec text —
the exact words, not just the direction (D16's precedent: "the uniform spec
sentence landing as the ruling itself"). An agent may draft and propose language,
but a general directive, mission statement, or agreed design direction is NOT
approval of specific spec wording. Nothing lands without Eric's explicit blessing
of the words themselves.

## "Do the thing" — the decision procedure

Every spec change, and most decisions surfaced to Eric, go through this. Present
all four parts in one brief, then wait for the ruling:

1. **What the others do.** Compare the reference projects (`.reference/`: go,
   mojo, rust, swift, Vale, zig — plus any that fit), verified in their trees not
   from memory. Name each mechanism and where it diverges.
2. **What the spec currently says.** Quote the exact text. Check whether the spec
   already rules the question (it often does — the implementation may just be
   non-compliant), and whether the proposal duplicates an existing rule (one
   rule, one normative home).
3. **Mission fit.** Relate the choice to `docs/mission.md` and `docs/meetings/`.
   Say which option is most with-y, not just which is safest.
4. **Predict what Eric would say.** A committed BDFL prediction with confidence,
   derived from his decision record — not a menu of options with no stake. It's
   falsifiable; being wrong and told why improves the record.

**Never present an option that plainly fails `docs/mission.md`.** If an
option obviously and unambiguously violates the mission (it makes the
programmer write what the compiler already knows, adds ceremony with no
guardrail, leaks by default, weakens safety), leave it out of the brief —
listing it wastes Eric's time. Keep only options a reasonable reading of
the mission could choose; if you drop one that someone might expect to
see, one clause saying why is enough.

Then Eric rules. For spec changes, the blessed wording lands immediately as the
ruling itself, and the implementation is non-compliant until it conforms.

## Filing bugs

If the spec (`docs/spec/`) says something should work and the
compiler disagrees, that is a **compiler bug**. Do not silently work around it.
File an issue with:

- Spec reference (e.g., "§9.7 Pattern Matching")
- Minimal reproduction
- Expected vs actual behavior
- Workaround used (so the fix can remove it)

## The decision log

`docs/meetings/` records non-obvious design/architecture decisions and **why**
(context, alternatives, reasoning, what would reopen the call). When you make or
reverse a judgment call a future maintainer might re-litigate — an
ownership/safety ruling, a deviation from the reference implementations, a spec
amendment reversing an earlier one — append an entry (newest first) and
cross-link superseded ones. Consult it before reopening a settled question. Keep
it terse; it is reasoning, not a changelog.

Each decision is one file, `docs/meetings/<date>-D<n>-<slug>.md`, listed in
`docs/meetings/README.md`. Eric's canonical rulings
(`d22-Eric-Ruling.md`, `Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md`)
live in the same folder and are never modified.

## Proposals

Live plans and proposals are in `docs/proposals/`; a plan that has been
superseded moves to `docs/proposals/inactive/`, and a phase that has finished
moves to `docs/completed/`. A proposal is a derivative execution plan: it
can't amend a ruling or the specification.

## Landing a change

### Rebuild and verify (tiered — see D14, D19)

**Iterate tier — the only per-change requirement.** `with check src/main.w`
and/or `with build :dev` (seed → stage1, one self-compile), plus the targeted
tests for what you touched. Never run the full battery per edit.

**Batch tier — the default.** Accumulate related commits; ONE battery blesses
the whole batch, driven by the pinned seed (`WITH=$PWD/src/main`):
```
src/main build              # must pass
src/main build :fixpoint    # must pass
```
plus `audit:all`, `:test`, `:test-green`, `:last-green` (`audit:all` and `:test`
may run concurrently — they share no outputs), then `:install-user` once.
Batteries are expensive; batching them is the discipline, not a shortcut.

**Isolation rule — blast radius, not ritual.** A change to ownership/drop
scheduling, codegen determinism, or ABI must be ALONE in its batch (and adds
`:move-audit`/`:drop-audit`), so a red battery indicts one change. Docs,
build-layer, and tooling changes batch freely and skip the drop audits.

If a batch's battery fails: bisect within the batch using iterate-tier evidence.
Do not add changes to a red batch.

### Changes land via pull request

All changes reach `main` through a PR — no direct pushes. Branch protection
requires a PR with zero approvals (Eric, 2026-09-23): the seed-driven battery
is the gate (D56), and a stack merge cannot bypass a review rule, so a
required approval blocked `gh stack merge` on the maintainer's own PRs.
Batch related commits into one PR the way the battery
discipline batches them. The GitHub lanes are not a merge signal (D56: a
lane takes hours); a PR is a draft until its seed-driven battery is green
and posted on it, then marked ready. Lanes run only nightly and on
dispatch — post-hoc evidence, never on a push. The SDK is built only on
release (`sdk-release.yml`).

### Dependent PRs are a `gh stack`, never hand-chained bases

When PRs depend on each other (a battery's chain), they are a GitHub stack
made with the `gh stack` extension (`gh extension install github/gh-stack`;
exit code 9 means stacks are not enabled for the repo). Never stack by hand
with `gh pr edit --base <other-pr-branch>` or by pushing cumulative branches:
hand-chaining merged #1357 into a dead branch, and squash-merging the top of a
cumulative chain (#1360) landed five PRs as one commit (2026-09-22).

- **Create/update:** branches live in staging worktrees, so use
  `gh stack link --base main <bottom> … <top>` (branch names or PR numbers,
  bottom to top; no local tracking). It pushes branches, creates missing PRs,
  and fixes each base to the layer below. Each layer holds only its own
  commits on top of the layer below.
- **Draft until green:** link as drafts; mark the stack ready
  (`gh stack link --open …`, or `gh pr ready` per PR) only after the batch's
  battery is green and posted.
- **Merge:** the whole stack or up to one PR, in order, all-or-nothing:
  `gh stack merge <top-pr> --yes --squash` or the stack UI. Never merge a
  middle layer by hand.
- **Main moved:** `gh stack rebase` from a checkout of the stack (merged
  parents are replayed with `--onto`), then `gh stack push`; a rebase that
  resolves conflicts needs a new battery before the stack is ready again.
- **Independent PRs are not stacked.** A single-PR batch has base `main`.

### Examples are contracts

Release UAT fixtures (`build/release_uat_fixtures/`), `examples/`, and any
code published on the blog or the homepage are contracts with Eric and with
everyone who has read them: they are what an application developer writes.
When a compiler, spec, or stdlib change breaks one, the change is what broke.
Ruling (Eric, 2026-09-22): examples track the current spec. A **spec
change** that breaks an example updates the example in the same change,
under the spec ruling, and says so; a **compiler or stdlib** change that
breaks an example is a defect in the change.
