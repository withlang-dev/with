# D233 — Making a slot is a write of the collection it comes from

**Laws:** 6 (the signature is the contract), 9 (two spellings of one
meaning are a defect), 4 (infer only what at worst rejects a valid
program), 3 (one owner per fact).

**Date:** 2026-11-23. **Status:** decided by the laws; words blessed by
Eric; implemented (#3565 for `List`, this change for `SlotMap`); the words
are in v7.88 (§6.2).

**Context.** `xs.slot(i)`, `xs.iter_place()` and `xs.get_disjoint(i, j)`
were read-mode built-ins, so a plain `fn`, or a function taking `&T`,
could overwrite an element through the slot. D172 item 1 rules that
write out. The question was where the refusal lands: at the making of
the slot, or only at `slot.set`.

**Decision.** At the making. `slot`, `iter_place` and `get_disjoint` need a
writable place, whether or not the slot is then written.

**Why.** Law 6: a slot's write permission that depended on what its
holder later does, including inside a function the slot is passed to
(`fn bump(s: ListSlot[i32]): s.set(…)` is legal), would make a body
change a contract. Law 9: the only program the narrower rule adds is a
read through a slot from a read-only place, a second spelling of
`xs[i]`. Law 4: this rule at worst rejects a valid program; the narrower
one, wrong, grants a write through a read-only place. Law 3: the
receiver mode sits in the one table that holds the built-ins' modes.

**Measured.** Every `slot.get()` in src, lib, tools, build and examples is
the first half of a read-modify-write. Nothing outside the compiler was
refused; 21 compiler methods declared `fn` wrote through a slot and are
`mut fn` now.

**What others do.** Rust decides at the making (`get_mut`, `iter_mut`,
`split_at_mut` take `&mut self`); Vale by the kind of reference taken;
Swift's mutating access is exclusive from its start.

**Rejected.** Tracking a slot back to its place and refusing only
`slot.set`; a second, read-only slot type.
