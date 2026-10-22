# D144 — A binding from a place of a plain-bits type takes the value; any other binding from a place observes it

**Laws:** 1, 5, 7 (docs/mission.md).

**Date:** 2026-10-21. **Status:** ruled by Eric. **Issue:** #2541, and the
`let i = self.idx` ceremony report raised with its brief. Amends #1531's
application of D27 for plain bits; applies D44's traversal rule to every
binding; applies §9.7's "a place is observed" to variant payloads.

**Ruling (Eric's words).** Rule observe, and rule the ceremony report the
same day, because the two are one rule seen from opposite sides.

#2541: observe. A `match` on a place projects the payload in place. A
mutating call through the binding writes the field when the subject is
mutable and is refused when it isn't, and a copy is spelled. The silent
lost `push` is the worst outcome on the list (Law 7), and Rust's `&mut`
spelling adds a token the program already determines. The usual view rules
then cover the rest: assigning `self.current = None` inside the arm while
`c` is still live is refused like any other conflict with a live view.

The `let i = self.idx` report: fix it, by D44's rule. Making someone write
`let i: isize = self.idx` to snapshot an integer is exactly the absurd case
the ceremony test exists for. Nobody reading `let i = self.idx; self.idx +=
1` expects `i` to follow the field.

Together the two give one rule, the one D44 already states for traversal:
*A binding from a place of a plain-bits type (integers, floats, `bool`,
plain structs of those) takes the value. Any other binding from a place
observes it.* `let i = self.idx` takes the `isize`, and `self.idx += 1`
afterward is fine. `match self.current: Some(c) => c.push(9)` observes the
`List` in place, so the push lands in the field. A plain-bits payload,
`Some(n) => …` on an `Option[isize]` field, takes the value; since bindings
aren't mutable unless declared `var`, `n += 1` is refused rather than
silently changing a copy. That removes the annotation in the common case
without changing #1531 for anything that isn't plain bits, and it makes
`let` and `match` agree. Count the `let x: T = self.field` annotations that
exist only to force a copy, and remove them in the sweep that lands with
the fix.

**Why (the brief).** The binding reads the payload and `List[i32]` is a
value under D120, so the copy was consistent with D111; what it violated
was §9.7's own rule that a place subject is observed, applied for slices
and reference subjects but not for a variant payload of a place. Rust
refuses the by-value match and spells `&mut`; Swift copies silently (value
semantics via copy-on-write), the known gotcha; Scala binds the object. Law
1: two meanings remained and the compiler chose the one that loses the
write. Prediction was observe at 80%.

**Consequence.** Sema: `type_is_plain_bits` (Copy with no drop glue);
`field_let_binds_as_view` returns no view for plain bits; a pattern
identifier on an observed subject of a non-plain-bits payload is marked
view-bound with the subject's borrow (`pattern_place_bindings`), and a
binding observing a place whose root is mutable may take a mutating call
(`binding_observes_mutable_place`); MIR aliases the pattern binding to the
payload's place instead of copying. Census pattern
`plain-bits-field-copy-annotation` marks `let i: T = self.f` where `f` is
plain bits of exactly `T`; `tools/sweep_plain_bits_field_copies.w` removes
them. Fixtures `behav_d144_binding_from_place.w`,
`err_d144_observing_binding_immutable_subject.w`,
`err_d144_assign_while_payload_live.w`. Spec words in §3.8.
