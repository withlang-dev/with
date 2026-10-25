# Claims: a human-known fact enters the type system through the front door

Status: proposal (Eric, 2026-10-25: "write both tiers into a proposal, not
a decision"). Nothing here is normative until its words land in the spec.

## Summary

`unsafe` carries responsibility; it cannot carry a fact. With's checker runs
on facts — a view's origin, a pointer's non-nullness, an index's range — and
today a fact the programmer knows but the compiler cannot prove has one
spelling, `unsafe`, which says neither what is claimed nor why, so nothing
can check it, count it by kind, or carry it forward in a type. A modeled-C
facade already has the other spelling: a clause the compiler treats as true
(`returns borrow R from param N`, `nullable param N`), cited, reviewed,
applied below a proof. This proposal gives With code the same door, in two
tiers that ask different amounts of the language:

1. **Declaration-site claims about a migrated engine**, written in the
   package's facts file that D121 step 4 already reads, under the precedence
   D121 already fixed. No new syntax, no new concept.
2. **Expression-site claims in With code**: `let v = claim p != null`,
   `let v = claim r from self`. A declaration, not a block; typed, so the
   checker carries the fact forward; checked at run time in a debug build
   where the fact is decidable; counted by kind.

A tool never writes a claim. The migrator proves or stays raw; a human
writes the facts line.

## Motivation

D159 (steps 1–5, `docs/proposals/migrator-contracts-plan.md`) made the
migrator emit a safe signature wherever a migrated function's body proves
its contract: a mutating or read-only receiver, an out-parameter returned as
a value, a returned pointer that is the receiver or the address of one of
its members. The proof stops exactly where a C body stops saying: STC's
`stc_word_stack_at`, `_top`, `_front` and `_back` return `self->data + k`,
a pointer loaded from a field and stepped, which the body cannot show is
non-null or inside the engine's own storage (the body *asserts* `idx <
size`; the proof does not read assertions). Those 58 STC rows stay `pub
unsafe fn`, and the facades' element reads (`s[i]`, `peek`, `front`) keep
their `unsafe { &*self.place(i) }`: 285 blocks across `lib/std/collections`
after step 5, most of them this shape.

The STC maintainer knows the fact: after `idx < size`, `data + idx` is a
valid element of the stack's own buffer, never null. For a `c_import`'d
header the With author would state exactly that in a facade clause, with a
citation, and the compiler would treat it as true. For a migrated engine
and for With code there is no such form. The reference projects offer only
the unchecked escape: Rust's `unsafe { NonNull::new_unchecked(p) }` and
`unwrap_unchecked`, C's `__builtin_assume`, Zig's `orelse unreachable` with
runtime safety off; Swift's `unsafelyUnwrapped` is the one that checks in a
debug build and trusts in release, which is the split this proposal keeps.
SPARK's `pragma Assume` and Dafny's `assume` are the proof-system form: a
stated fact the prover takes, flagged for review. Nobody ties the claim to a
citation; With already does, for facades.

The mission line fits exactly: the compiler cannot decide, so the programmer
spells the choice, and the spelling is a guardrail. `unsafe` fails the
guardrail half.

## Detailed design

### Tier 1: declaration-site claims about a migrated engine

**Where.** The package's facts file (`CiFacts.w`, §16.2b.15 item 3), the
file a facade registry already uses, in the facade language's own spelling.
A corpus's facts file lives beside the corpus's build record (`build/stc.w`
names it), never inside the generated modules (D112: a corpus is never
edited by hand; the facts file is the human's input to the migrator).

**What a line says.** The existing clauses, applied to a function the
corpus defines rather than a header it imports: `returns borrow R from
param N`, `nullable param N`, and one addition, `nonnull`, on a return,
which the facade language does not need (a header's nullability is a
separate import rule, §16.2b.9) and a migrated engine does:

```
c facts stc:
    fn stc_word_stack_at
        returns borrow u64 from param 0, nonnull    // stack.h 5.0: asserts idx < size; data + idx is inside self->data
    fn stc_word_stack_top
        returns borrow u64 from param 0, nonnull    // stack.h 5.0: asserts self->size; data + size - 1 is inside self->data
    fn stc_word_stack_front
        returns borrow u64 from param 0, nonnull    // stack.h 5.0: asserts self->size
```

**Precedence.** Unchanged from D121: a proof first, then the library's own
annotations, then the facts file, then a convention profile. A claim applies
only where the proof said nothing: the migrator's `receiver`/`receiver-mut`
verdict is the proof's, and the facts line supplies the return's origin and
non-nullness that inference (c) could not. A facts line that contradicts a
proof is an error naming both (the engine already says `DISAGREES` for a
facade; a corpus gets the same).

**What the migrator does with it.** A read receiver whose return the facts
file makes `returns borrow R from param 0, nonnull` is printed
`pub fn <m>(…) -> &R from self`, exactly as inference (c) prints one it
proved; a mutating receiver likewise `pub mut fn`. The contracts artifact
records the provenance beside the verdict: `receiver:stc_word_stack,
ret-from:0:registry` against `ret-from:0` (a proof), so the drift report and
the promotion's printed diff show which rows rest on a human's word. A
claimed row changes when the facts file changes, which the PR shows.

**Citation is mandatory, the cap on uncited claims is zero.** CiFacts refuses
a fact without a citation; for a corpus the rule is the same, and in the
standard library an uncited claim is refused, not merely reviewed. The
citation names the source line or document that proves the fact.

**What tier 1 does not do.** It never infers: a tool never writes a facts
line, and the migrator's proof tier never consults the facts file to widen a
verdict it could not reach (the facts are read at emission, after the
contracts are drawn, so `proof:` and `registry:` never blur). It does not
reach the slot pushes (`stored-unknown`: the facade owns the slot by D148,
and ownership is a record's property, `docs/proposals/` owned-field
proposal) nor the destroyers (a `drop` that frees a part of the record is
consuming; a facts line cannot make it a receiver).

**Effect on the facades.** A dozen cited lines for STC's word and slot
shapes turn `at`/`top`/`front`/`back` into `-> &u64 from self` methods; the
facades' `unsafe fn place(i)` and the `unsafe { &*self.place(i) }` around
every element read go. What remains `unsafe` in a facade after tier 1 is
the slot-lifetime step the facade owns and the raw pointer the slot shape
stores.

### Tier 2: expression-site claims in With code

**Spelling.** A declaration, never a block:

```
let v = claim p != null          // from here, p: *const T is non-null
let e = claim r from self        // from here, the view r has self's origin
let k = claim i < n              // from here, i is in 0..n (a range the checker tracks)
```

`claim <fact>` is an expression whose value is the fact's subject with its
type strengthened by the fact; it binds like any other initializer. The
vocabulary is the checker's own: the facts it proves today and carries in
types — non-null, view origin, range — and nothing a type does not carry.
Block syntax is deliberately absent: a region invites wrapping, the
`unsafe {}` habit this exists to replace.

**A claim is a boundary, not a paint.** Two rules keep it one:

- A claim is stated once, where the fact enters the program (where the
  pointer comes out of the engine, where the view is made), and the type
  carries it from there. The checker refuses a claim on a value whose fact
  it already knows, with a fix-it to delete it: a redundant claim is the
  same defect as a redundant `unsafe` prefix (#1704).
- A claim only strengthens a value's type; it never changes a program's
  meaning. Removing every claim from a program gives the same program with
  more checker errors, never a different behavior. (So a claim can never be
  the reason a value is moved, dropped, copied or evaluated differently.)

**The debug check is mandatory for every decidable claim.** `claim p !=
null` and `claim i < n` are decidable: a debug build (`with build` without
`--release`, `with run`, `with test`) evaluates the fact at the claim and
panics with the claim's own text when it is false; a release build trusts
it. This is Swift's `unsafelyUnwrapped` split, and it is what makes a claim
better than `unsafe` rather than a politer spelling of it: a wrong claim
traps on the first debug run instead of corrupting memory in release. An
origin claim is not decidable at run time and is trusted outright.

**Counted by kind.** The ceremony census counts claims in two buckets:
checked (non-null, range) and unchecked (origin), the unchecked ones in
their own bucket because they are the ones nothing will ever catch. The
bar is main's own count, as for every other pattern; `:user-programs-safe`
treats an unchecked claim in a user program as it treats `unsafe` (an
application developer writes neither; the compiler forced it).

**How a claim reaches the checker.** A claim is a Sema fact (D65: Sema
decides what): it adds the stated fact to the value's record — the non-null
bit on a raw pointer type, the origin set on a view, the range on an index —
exactly as a proof would have, and the typed tree carries it. MIR lowers a
decidable claim to the debug check (a branch to a panic carrying the claim
text) and nothing else; codegen sees no new construct. A claim's subject
must be a place or a binding, never a temporary: the fact must have
something to attach to.

**Interaction with `unsafe`.** A claim does not make a raw operation safe by
itself: `claim p != null` yields a non-null raw pointer, and dereferencing
it is still a raw operation. The composition that removes an `unsafe` is the
origin claim on the view: `let e = claim &*p from self` states that the
deref is valid and the view is of `self`, the two facts the facade's
`unsafe { &*self.place(i) }` asserted without saying. Whether the deref
inside an origin claim needs its own `unsafe` prefix is an open question
below.

**What tier 2 does not do.** A claim is never written by a tool: not by the
migrator, not by a fix-it, not by a formatter. An agent answering a checker
complaint with a claim is the failure mode the boundary rules exist for;
the redundancy refusal and the census bar are the mechanical halves, the PR
the rest.

## Why this is not `unsafe` with a nicer name

A `claim` states *what* is claimed; it is checked where it can be; it is
typed, so the checker carries it forward and refuses it where it is already
known; it is counted by kind. `unsafe` does none of those. The decision
record, when there is one, should say this in these words.

## Drawbacks

- A new keyword and a new Sema fact source. The vocabulary must stay the
  checker's own, or claims become a second type system.
- Two census buckets to watch. An unchecked claim is as dangerous as an
  `unsafe` block and easier to type.
- Tier 1 adds a second input to a corpus's migration (the facts file) that
  the drift report must show moving; the provenance mark in the artifact is
  the mitigation.

## Alternatives considered

- **Keep `unsafe`.** It carries no fact into the type system; the facades'
  element reads would stay `unsafe` forever, and the ruling on the read
  receiver left exactly that gap.
- **A runtime-checked operator** (`p!`, Kotlin's `!!`): checked in every
  build, never typed as a fact, no origin form. Rejected as a type-system
  door; the debug check in tier 2 keeps its one virtue.
- **`Option[&T]` returns from the migrator** for a loaded pointer: sound for
  null, silent on validity (`data + idx` on an empty stack is non-null and
  wrong), and it moves a check the C body already made into every caller.
  Rejected; a facts line states what the C assert established.
- **Proving non-nullness from the C assertions** (`assert(idx < size)` as
  evidence that `data + idx` is inside the buffer): a real proof tier, worth
  its own brief, not a reason to withhold the human form.
- **A block form** `claim p != null:` over a region: invites wrapping, the
  habit this replaces; rejected (constraint 3).

## Unresolved questions

1. The keyword: `claim` (Eric's word, names what it is), `trust` (reads as
   the compiler's act), `assume` (the proof-system word). This proposal
   writes `claim`.
2. Whether an expression claim may appear outside an initializer (`f(claim p
   != null)`): the declaration form is the ruling's; the rest is open.
3. Whether the deref inside an origin claim (`claim &*p from self`) carries
   its own `unsafe` prefix or the claim subsumes it: the claim states
   validity, which is what the prefix would state.
4. Whether a claim in a facade cites like a facts line. This proposal says
   no: the citation is a review device for a corpus's facts; a claim in
   code is reviewed as code.
5. The exact fact vocabulary beyond non-null, origin and range (non-aliasing
   between two views? a length relation between a pointer and a count?):
   each is its own spec sentence and its own census row.
6. Where a debug check lands in MIR (a conditional panic at the claim) and
   whether `--release` strips it or `-O1` alone does: a build-system line.

## Implementation sketch

Tier 1, one PR: `nonnull` in the facts grammar; `CiMigrate` reads the
package's facts file for a migrated corpus and applies `returns borrow R
from param N, nonnull` at emission under D121's precedence; the artifact's
`:registry` provenance; `bs_check_migrate_contracts` rows for a claimed
return, a claim contradicting a proof, an uncited claim refused;
`build/stc.w` names the facts file; the STC lines; re-promotion under
`migrator-pin`; the facades call `at`/`top`/`front`/`back` as methods and
drop `unsafe fn place`.

Tier 2, spec words first (§19 a new section, §29 the keyword, §21.1 the
origin claim beside rule 6), then Sema's fact entry, MIR's debug check, the
census buckets, the redundancy refusal, behavior fixtures for each fact and
each refusal, and only then the facades that a tier-1 line does not reach.

## Design meetings

**2026-10-25, brief and reply.** The brief proposed the two tiers (facts
file for an engine; `claim <fact>` for With code, checked in debug where
decidable, counted by kind, never written by a tool). Eric:

> Yes, it belongs, and the argument that convinces me is the one about
> types: `unsafe` can carry responsibility but it can't carry an origin or a
> non-null into the checker, and With's whole model runs on origins. A claim
> is the form that lets a human-known fact enter the type system through the
> front door.

> **Declaration-site claims: adopt now.** … The one requirement I'd add is a
> per-corpus cap on *uncited* claims of zero, the same rule CiFacts already
> enforces for facades: in the standard library a claim without a citation
> is refused, not merely reviewed.

> **Expression-site claims: adopt the form, with three constraints** …
> 1. The debug check is mandatory for every decidable claim, not optional.
> … Origin and range claims that can't be checked at run time are trusted
> outright, and the census should count them in their own bucket, because
> they're the ones nothing will ever catch.
> 2. A claim is a boundary, not a paint. … a claim must be stated once at
> the point the fact enters the program … the checker should refuse a claim
> on a value whose fact is already known, with a fix-it to delete it. … a
> claim only strengthens a value's type and never changes a program's
> meaning, so removing every claim gives the same program with more checker
> errors, never a different behavior.
> 3. The spelling should be a declaration, not a block. `let v = claim p !=
> null` reads as "from here, `p` is non-null," which is what it is.

> **One thing I'd keep off the table:** claims written by tools. … If the
> migrator could emit a claim where its proof failed, "proved" and "claimed"
> would blur within a generation. The migrator proves or stays raw; a human
> writes the facts line.

> Worth saying in the decision record why this isn't Rust's `unsafe` with a
> nicer name: a `claim` states *what*, is checked where it can be, is typed
> so the checker carries it forward, and is counted by kind. `unsafe` does
> none of those.

Asked for as a proposal, not a decision; the spec words wait for a ruling.
