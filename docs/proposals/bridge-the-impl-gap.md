# Bridge the implementation gap: everything between the spec and the compiler, and how it closes

Status: plan (Eric, 2026-11-02: "our #1 goal right now is to fix the lag
between Spec and Implementation"). Nothing here is normative; the spec and
the decision log are. This is the work list, the mechanism that keeps the
list from growing back, and the order.

## Summary

The spec leads (D20): a ruling makes the compiler non-compliant until it
catches up. That is the right rule, and it has a cost nobody was measuring:
on 2026-11-02 a probe of the spec's own text against the installed compiler
found eleven rulings or sections the compiler does not implement, one it
regressed on, fourteen `NON-COMPLIANT until it catches up` lines in the
spec's changelog with no owner, three places where the spec contradicts
itself, and a `#752` (the §18.1 fallback tier, ruled on 2026-08-01) open for
three months while every user wrote `use` lines the compiler printed for
them. The lag is not one bug; it is the absence of three things:

1. **An inventory.** Nothing lists what the spec promises and what the
   compiler does; the changelog's `NON-COMPLIANT` sentences are the only
   record, and they are never cleared.
2. **A test per promise.** Law 10 says every principle has an adversarial
   program; most rulings landed with none, so a regression (D91, #2949) is
   invisible until a reader tries the example.
3. **A closing discipline.** A ruling's PR records the words and stops; the
   implementation is "next" and next never comes, because the next ruling
   arrives first.

This plan supplies all three, then burns the inventory down in an order that
pays the user first.

## What "the gap" is, as of 2026-11-02

### Rulings with no implementation (the compiler refuses what the spec says)

| ruling | spec | state | issue |
| --- | --- | --- | --- |
| D29 fallback tier | §18.1 | gate still on, three months | #752 |
| D183 checked narrowing, `isize` positions | §4.2.6 | ruled 2026-11-02 | #2522 |
| D184 script bindings as captures | §29.15 | implementing (branch `d184-captures`) | #2951 |
| D185 one comprehension family | §13.6, §13.6a | ruled 2026-11-02 | #2960 |
| D186 iterable `zip`/`chain`/`zip_with` | §13.3 | ruled 2026-11-02 | #2962 |
| D187 union borrow origins | §16.2b.6 | ruled 2026-11-02 | #2965 |
| D97 facade-wide `error E` | §16.2b.4 | parser refuses it | #2953 |
| D126/D127 slice demand types a literal / a constant | §4.3c, §3.1 | refused | #2944 |
| D95 structural `clone()` on tuples and `Option` | §11.8 | missing (#2161 was partial) | #2945 |
| §13.3 fifteen collection operations | collection-operations.md | missing or broken | #2943 |
| §13.5a label alone on a line | §13.5a | parse error | #2947 |
| §18.1 grouped import at the package root | §18.1 | resolver | #2948 |
| §14.10 channel receive as a `select await` arm | §14.10 | refused | #2956 |
| §14.11.1 `… \|> await_all` | §14.11.1 | no overload | #2954 |
| `?` in `fn main:` and in a script | §10, §18.5 | refused | #2935 |
| §14.19 `@[ffi_stack]` | §14.19 | never started | #583 |
| §8.3 `List.new_in(allocator)` | §8.3 | never started | #570 |

### Regressions (the spec was implemented, then lost)

| ruling | symptom | issue |
| --- | --- | --- |
| D91 `comptime match Target.os` | "runtime value is not available at comptime" on the release compiler; #2124 implemented it, #2248 closed | #2949 |
| D95 `clone()` | tuple and `Option` lost it after #2161 | #2945 |

### The compiler's own admissions

Diagnostics in `src/` that say "not implemented yet" for a spec'd thing:
REPL persistent declarations, UAT `expect image:`, comptime enum payload
shorthand, comptime f-string format specs, bitfields in member records
(D147), two diagnostics citing closed issues (#1652, #2180). #2950.

### Where the spec itself is wrong (#2955 and its children)

Examples that cannot compile (`50.millis()`, `timeout(...)`, `Ok(a + b)`,
`String`), a rule the spec's own example violates (§13.6 under D108, #2522),
a promise the next section breaks (one comprehension family, #2960), two
meanings of one name (`drop`, #2961, now ruled), an arity cap copied from
Rust (#2963, ruled), a rationale the rulings outran (§4.2.6, #2964, done),
a hole in normative text (#2965, ruled), stale text (#2966).

### The fourteen `NON-COMPLIANT until it catches up` lines

`docs/spec/README.md`'s changelog, v7.17 through v7.35, each ending with the
sentence and none ever edited when the implementation caught up. Some did
catch up (D100, D93, D97's `Ord`), some did not (D126/D127, D97's `error`,
D91 regressed), and the text cannot tell a reader which.

### The ceremony the tree teaches

Not spec gaps, but the same lag between a ruling and the code everyone
reads: 1757 explicit `&x` at `&T` parameters, 1158 call-site `move x`, 1345
`let _ =`, 483 `.clone()` on a `str`, 839 `.len() as i32`. #2939–#2942,
#2522.

## The mechanism: three things that did not exist

### 1. The conformance inventory is a file the build checks

`docs/spec/conformance.tsv`: one row per ruling and per normative section
with a testable claim: `D-number or §`, `claim` (one sentence), `state`
(`implemented` / `open` / `regressed`), `fixture` (the test file that pins
it, or empty), `issue`. The gate (`:spec-inventory-check`, which already
reads the spec) refuses:

- a ruling in `docs/meetings/README.md` with no row;
- a row with `state=implemented` and no fixture;
- a `NON-COMPLIANT until it catches up` sentence in the spec changelog
  whose row says `implemented` (the sentence is deleted when the row flips),
  and a row that says `open` with no issue.

The fourteen changelog sentences become fourteen rows on day one, with
the truth in the `state` column.

### 2. Every ruling lands with its adversarial program (Law 10, enforced)

A ruling's PR carries, in the same PR: the spec words, the decision record,
the row in `conformance.tsv`, and the fixture. The fixture is a
`test/behavior/behav_d<N>_*.w` (or `test/compile_errors/err_d<N>_*.w`) that
spells the spec's own example. Until the implementation lands the fixture
is listed in `test/conformance/open.txt`, which a lane runs expecting
failure: a fixture that starts passing is the signal to flip the row and
delete the changelog sentence; a fixture that stops failing *the way it
did* is a regression caught the night it happens. D91's regression would
have been one red line instead of a reader's surprise.

Spec examples are fixtures too: a `with check` over every fenced `with`
block in `docs/spec/*.md` whose first line is not `// not With` (the
grammar, the desugars, the C). Today §14.6, §14.10, §13.6 and §4.3c examples
do not compile, and nothing noticed.

### 3. A ruling is not done until the compiler conforms, and the queue is visible

- The decision log's index line gains a state suffix: `(ruled; open #N)`
  becomes `(ruled; implemented)` when the row flips. `docs/meetings/README.md`
  is read every session; the open suffixes are the queue.
- The `spec-gap` label (created today) is the queue in GitHub; the
  `do-before-release` label marks the ones a release waits for.
- D98's delegation includes the implementation: a delegated ruling that is
  not implemented in the same stack is reverted at the next reseed, not
  carried.
- The audit that produced this list (probe the spec's text against the
  installed compiler) runs on every reseed as a lane, over `conformance.tsv`'s
  fixtures, not by hand.

## The order

Each item is a PR with its battery; the order pays users first and keeps the
compiler-internal work last.

1. **Mechanism first** (one PR, docs and build): `conformance.tsv` seeded
   from this document, the gate rules, `test/conformance/open.txt`, the spec
   example lane. Nothing else lands without a row after this.
2. **The user-facing refusals**: #752 fallback tier; #2935 `?` in main;
   D184 (in flight); D183 checked narrowing with `isize` positions (#2522),
   which also retires the largest ceremony pattern; D185 comprehensions
   (#2960); #2944 slice demands; #2945 structural `clone`.
3. **The library surface**: #2943 collection operations; #2962 iterable
   `zip`/`chain`; #2954 `await_all` over a pipeline; #2956 channel arms;
   #2947 labels; #2948 grouped imports.
4. **Modeled C**: #2953 facade-wide `error`; D187 union origins (#2965); the
   migrator's unity build and SQLite (#2980, #2972), which are what a
   packager hits first.
5. **Regressions and admissions**: #2949 D91 (with its fixture under the
   release compiler, not only stage1); #2950's list, each either implemented
   or its diagnostic naming an open issue.
6. **The tree**: the four ceremony sweeps (#2939–#2942) as `with fmt`
   sections (#2519), so the compiler stops teaching the idiom the mission
   forbids.
7. **The long tail**: #583 `@[ffi_stack]`, #570 `List.new_in`, the test
   coverage issues (#490, #491, #507), #739's plan docs.

## What is not in scope

Rulings themselves. Every item here is ruled; the only decisions this plan
asks for are the words of the gate rules in item 1, which land under D98.

## Done when

- `conformance.tsv` has a row for every D-number in the decision log and
  every row says `implemented` with a fixture, or `open` with an issue in
  the `spec-gap` queue;
- the spec changelog carries no `NON-COMPLIANT until it catches up` sentence
  that is false, and the gate refuses a new one without a row;
- every fenced With example in the spec compiles under the installed
  compiler, in a lane;
- the `spec-gap` queue is empty of everything in the tables above, and a new
  ruling cannot join it without its fixture;
- the conformance audit of 2026-11-02, re-run as a lane, finds nothing.
