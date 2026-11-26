# The specification, briefs, bugs and the decision log

Moved verbatim from AGENTS.md (#2374). Nothing here was reworded.

## The Specification Leads

`docs/spec/README.md` is the bible. For D22, `docs/meetings/d22-Eric-Ruling.md`
is the controlling ruling; anything that conflicts with it is repaired to
match. Two absolute rules:

**The spec leads the implementation.** A spec change is a ruling that the
product is NON-COMPLIANT until the implementation catches up. No "implement
first, spec after", no holding spec text until code lands, no reverting spec
text to match code. When they disagree the implementation is wrong — or the
disagreement is surfaced to Eric; never resolved by quietly editing the spec.

**Spec changes are solemn.** Only Eric authors or blesses normative spec text —
the exact words (D16's precedent). An agent may draft and propose; a directive,
mission statement or agreed direction is NOT approval of specific wording.

### "Do the thing" — the decision procedure

Every spec change and most decisions surfaced to Eric go through this; present
all four in one brief, then wait for the ruling:

1. **What the others do.** Compare the reference projects (`.reference/`: go,
   mojo, rust, swift, Vale, zig, plus any that fit), verified in their trees.
2. **What the spec currently says.** Quote it. Check whether the spec already
   rules the question and whether the proposal duplicates an existing rule.
3. **Mission fit.** Read `docs/mission.md` first (not the `CLAUDE.md` summary).
   Cite the governing Law(s) by number (Laws 1–12), quote each Law's *Test*
   question verbatim, and answer it for each option; cross-check
   `docs/meetings/README.md` and say which option is most with-y. A brief
   without cited Law numbers and *Test* answers is incomplete.
4. **Predict what Eric would say.** A committed BDFL prediction with
   confidence, derived from his decision record — falsifiable, not a menu.

**An ownership question states two facts first (Eric, 2026-10-08):** what the
callee does with the argument (stores or reads), and whether the type has
identity. If those decide it, it is not a ruling: do the work (D110, D111).

**Never present an option that plainly fails `docs/mission.md`** (writes what
the compiler knows, ceremony with no guardrail, leaks by default, weaker
safety). One clause saying why it was dropped is enough.

Then Eric rules; blessed wording lands immediately as the ruling and the
implementation is non-compliant until it conforms.

**Delegated decisions (D98, amended by D237).** If `docs/mission.md` settles
a brief (and there is no clearly articulated argument for changing
`docs/mission.md`), take it as Eric's ruling without asking: implement it,
land the normative spec words (and any contract-program updates required by
the settled spec change), and record the brief in the decision log as
**delegated**. Eric vetoes afterwards; a veto is a revert. When
`docs/mission.md` does not settle the question, a question that is not about
C interop, ownership, safety, or contract programs, is easy to reverse, and
has a prediction of 75% or higher is likewise delegated (D98); anything else
stops for Eric.


## Filing Bugs

If the spec says something should work and the compiler disagrees, that is a
compiler bug: never silently work around it. File with the spec reference
(e.g. "§9.7 Pattern Matching"), a minimal reproduction, expected vs actual, and
the workaround used (so the fix can remove it).


## Decision Log

`docs/meetings/README.md` records non-obvious decisions and **why** (context,
alternatives, reasoning, what would reopen the call). When you make or reverse
a judgment call a future maintainer might re-litigate, append an entry (newest
first) and cross-link superseded ones. Consult it before reopening a settled
question. Terse: reasoning, not a changelog.
