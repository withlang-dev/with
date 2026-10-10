# D128 — A local its literal typed takes the type its demanding uses agree on; the UAT contract is never annotated to make a rule pass

**Date:** 2026-10-10. **Status:** ruled (Eric Hartford: "Yes. The socratic
approach helps me validate the laws."). **Completes** D126's deferred
locals rule. **Amends** §4.2.1. **Implemented** on the D114 stack (the
layer above D127), gated as D126 asked.

**Context.** The battery for the D114 stack went red on three release UAT
scenarios (`libcurl`, `sqlite3`, `raylib_spiral`): `var total = 0`
returned from `-> i32`, `var sum = 0` as an `Ok` payload of
`Result[i32, _]`, `var x = 40` passed to C `int` parameters. Under D114's
follow-up rule (locals are not typed by their uses) each is an `isize` and
each use a narrowing. The brief first offered annotating the four locals,
as D126 had done for `examples/c-interop`. Read against the laws:

- **Law 1**: the compiler can establish `i32` from the body it is already
  checking; the annotation asks for what it knows. An option that asks for
  it fails the mission and should not have been offered.
- **Law 7** names the UAT contract: editing the user's program to make a
  rule pass is the thing it forbids.
- **Law 10**: the UAT scenarios are the adversarial programs; their failing
  is the mission reporting that "locals are not typed by their uses" had
  quietly lost law 1.
- **Law 2**: the literal's default picks a representation of one meaning
  (preamble; D114 made it `isize`); a default may stand in only while
  nothing demands, so a demand that arrives after the declaration is the
  demand propagation law applied to a local. Of the references, only Rust
  (an integer literal is an inference variable, fallback `i32`) passes law
  1 here; Go, Swift, Scala and Mojo fix the type at the declaration; Zig
  refuses `var x = 0` outright.

So the viable set was one option: implement the rule D126 deferred, with
D126's two gates, as a layer of the same stack, and never touch the
fixtures. D126's "do not hold D114 hostage to a perf measurement" was a
sequencing preference; laws 7 and 10 outrank it.

**Ruling (Eric, verbatim).** "Yes. The socratic approach helps me validate
the laws. Continue." (to the brief above and its recommendation), and
"go ahead and amend it" (mission.md's preamble, `i32` → `isize`, #2340).

**The rule (delegated wording, §4.2.1; Eric vetoes after).**

> **Locals typed by their uses (D128).** A binding with no annotation whose
> initializer is an untyped integer literal expression has the type its
> demanding uses in its own function agree on: a parameter, a return, an
> `Ok` payload, a typed place, reached by the name or through arithmetic on
> it. Where no use demands a type narrower than `isize`, the binding is
> `isize`. Uses that demand two different types are an error at the second,
> naming both. The rule never changes the type of a binding in a program
> that compiles without it. A list literal's binding takes the element type
> a slice demand names the same way (§4.3c).

**Implementation.** One wrapper around every body check
(`check_fn_body_with_sig_at`): the first check records each demand
narrower than `isize` on a literal-typed local instead of refusing it; a
body that recorded one is checked again, once, with each such `let` at its
first demand; a use that cannot take that type reports both uses. A body
that records nothing is checked once, which is the guarantee by
construction. D93 carries the list-literal case (one mechanism for
collections). Law 2's example is honored the same way: a literal operand
of a generic call leaves `T` open, the demand binds it, and a carrier
demand (`Option[i32]`) binds `T` to its payload (D103), so
`let x: Option[i32] = ident(3)` is `Some(ident(3))` with `T := i32`.

**Gates (D126).** Type diff: `WITH_PROFILE=1` prints
`int-local-rechecks=N` on the sema line; `N = 0` over `src/main.w`
(17,493 decls), `build.w`, `lib/std/build.w` and three std-heavy tools, so
no local in the compiler or std changed type. Sema time: measured on the
gate's release binary against the pre-rule one on `src/main.w` (recorded
on the PR).

**What follows.** `examples/c-interop` drops the two annotations D126 made
necessary; `behav_law2_demand_order` spells `ident(3)` again; the three
UAT scenarios pass unedited. The behavior fixtures annotated for D114 keep
their `: i32` (they are tests, not users' programs); a later ceremony
sweep may drop them.

**What would reopen it.** A body the rule rechecks in the compiler or std
(the gate reads non-zero), or a demand shape the rule misses that a user
program shows (a demand through a method on the local, a comparison peer).
