# With Language Version History

One entry per specification version, in the specification's own words: each
entry is the **Changelog vX.Y** paragraph from the front matter of
[docs/spec/README.md](spec/README.md), verbatim, newest first.

## v7.4

**Changelog v7.4:** Ten rulings from the modeled-C close-out (D71): string
range slices are `&str` views (§4.8a); a positional collection has no `get`,
`xs[i]` is the one spelling (§ Element access, D27); `@[flags]` doubles
without a representation type and `from_int` requires unit variants
(§4.4a); a closure's `-> T` is checked (§12); `:?` refuses types with no
Debug form (§15.4.7); `@[repr(packed(N))]` (§16.4); and the facade gains
`ok` lists, `valid on failed`, and callback-scope `handle`s (§16.2b.4,
§16.2b.9; modeled-C ruling Amendment 1).

## v7.3

**Changelog v7.3:** Generators are push-based (§13.4, D69): a `gen fn`
is an ordinary function that calls the consumer's loop body at each
`yield`. A consumer's stop leaves the generator at its `yield`, releasing
its scopes; a generator may yield views of its own locals; `g.pull()`
gives a fiber-backed `Iter[T]` where code must step the sequence itself.
The state-machine model, its no-references-across-`yield` rule, and its
`.await` prohibition are retired (§13.4, §14.20).

## v7.2

**Changelog v7.2:** Owning keyed-map lookup has one uniform contract: `get`
returns `Option[&V]`; ownership transfer is performed by `remove`, which
returns `Option[V]`. A shared reference to a `Copy` value remains a reference
during inference and structural projection, but may satisfy an independently
established owned-value demand through contextual Copy materialization.
Pattern bindings preserve exact projected types. Option/Result elimination
preserves exact payload types, while `??`, `unwrap_or`, `unwrap_or_else`, and
other multi-expression joins use the contextual join rule. View origins
propagate through transparent carriers and eliminators until an operation
actually produces an independent owned value (§3.4, §3.8, §9.7, §10,
§13.3, §21.1, D22).

## v7.1

**Changelog v7.1:** Unit-returning `mut fn` pipeline stages thread the
receiver place; non-Unit stages thread their returned value, with resolved
generic returns and ordinary temporary/drop/alias rules (§9.6, D21). A
`mut fn` may not duplicate ownership still retained by its receiver into an
owned return; receiver-returning fluency is consuming (§9.5). Global
declarations specified (§9.1c): `global`
(stable) / `global var` (rebindable), pre-`main` initialization, and
the usage-based data-race rule — never-mutated and synchronized
globals always safe; bare mutation safe iff the program is provably
single-threaded, `unsafe` past the proof (E0921). §19.4 amended:
proof-dependent operations inside `unsafe` warn (not error) when
newly proven safe. **Integrated collections syntax** (Scala-inspired
target polymorphism): one bracket comprehension family with
expected-type-driven targets and `key: value` map form (§13.6);
collection literals incl. map literals `[k: v]` and `[:]` (§4.3c);
`vec![...]` examples replaced with collection literals; §30.5
grammar updated. **`loop` specified** (§13.5d): expression-valued
via `break expr`; §13.5a value-break text refined; §30.4 grammar.

## v7.0

**Changelog v7.0:** Parameter passing: the signature states the mode —
`&T` borrows, plain `T` consumes; share-place call semantics removed
(§3.8; §12.4 retains by-place capture for closures; §21.1 example
fixed). Cancellation observation moved to the `Task` handle
(`was_cancelled`); the `TaskCancelled`/`.is_cancelled()` error story
removed — awaiting a cancelled task unwinds, never returns `Err`
(§14.7). `Result` removed from `@[must_use]` match exhaustiveness
(§9.7). `with ... as mut` always returns the binding (§7.2, §23.1).
Iterator borrow-origin via `@[iter_of_self]` specified for all
libraries (§13.2). `[]mut T` exclusivity rules and
`split_at`/`split_at_mut` (§4.8a). Ephemeral diagnostic contract
(§22.3). Fiber stack conforming baseline = fixed pooled stacks;
growth and FFI stack switching are roadmap (§14.19). c_import
contract metadata sources named, including the curated libc overlay
(§16.3c). Implicit default return gated to bodies with no explicit
value return (§4.10). Consuming-rebind shadowing exception (§29.8).
String-literal elision is an optimization, not a guarantee (§15.3,
§20). Hygiene: enum-only sum-type syntax swept (§10.1, §11.7, §30.3);
keyword list synced to the lexer (§29.11, §30.9 now defers to it);
`usize`/`isize` documented (§4.1, §4.2.1); duplicate §18.7 renumbered
to §18.8; `let mut` removed from §30.4 grammar; §14.21 match arms
fixed to `=>`; f-string examples fixed (§15.4.5, §15.4.7); generator
return type wording fixed (§13.1, §13.4); select-await dead panic
clause removed (§14.10); §22.1 Rule 6 distinguished from Rule 4;
module resolution and `pub` enforcement stated (§18.1, §18.3).

## v6.9

**Changelog v6.9:** CLI one-liners (`with -e`, `with -n`, `with -p`)
are specified as normal compiled With entry sources with implicit-main
semantics, stdin line bindings, `args`, semicolon splitting, and regex
capture behavior (§18.5b).

## v6.8

**Changelog v6.8:** Three universal body forms (§29.13) — inline colon,
indented colon, and braced — now apply to every block-introducing construct
including `defer`, `errdefer`, `comptime`, and `unsafe`. `if`, `else if`,
and `else` use those same body forms; every arm requires `:` or `{`.
`else if` is a two-token keyword pair parsed as a chain continuation.

## v6.7

**Changelog v6.7:** Reorganized — extracted test cases to `test/spec/`,
roadmap to `docs/roadmap.md`, and stdlib API tables to
`docs/libstd-spec.md`. Added grammar appendix (§30). Added labels on
arbitrary statements and `goto` (§13.5a, §13.5b).
