# Eliminate `self`: the receiver's members by bare name

Status: proposal (2026-10-25), not ruled. The receiver half of this plan is
the language and is recorded in D7 (`docs/meetings/2026-07-07-D7-…`) and
D83 (`docs/meetings/2026-10-03-D83-…`); this document holds only what is
still to do. The spec words in §2 are a draft for Eric to bless or rewrite;
until then §9.5 stands as D83 wrote it.

## 0. Where the language is

- The receiver is implicit. `fn` / `mut fn` / `move fn` inside an
  `impl`/`extend` synthesise it (`self: &Self`, `mut self: Self`,
  `move self: Self`); the dotted top-level `fn Type.name` is associated. A
  trait method that writes `self` is an instance contract, one that does not
  is associated (D7's carve-out: location cannot discriminate inside a
  `trait` body), and an impl of either may omit the receiver.
- A receiver *field* is in scope by its bare name in an instance method
  declared in the type's own module (D83, §9.5); a method declared in
  another module reaches fields only through `self.`; receiver *methods* are
  never in scope bare.
- What this costs: the tree writes `self.` 80,137 times (39,241 method
  calls, 39,930 field reads), the largest ceremony count in the codebase.
  `impl Sema` sits in eight files beside Sema.w (66 blocks) and
  `impl CiProject` in four, so D83's own-module rule reaches almost none of
  the compiler's own methods. Eric's question, on a line of CiContracts.w
  (2026-10-25):

  > why do we need 'self'? Can we make it so instead of
  > `let ret_part = ct_is_pointer(self.symbols[si].ret_ty) and self.ct_ret_from(si, 0)`
  > they can write `let ret_part = ct_is_pointer(symbols[si].ret_ty) and ct_ret_from(si, 0)`

  Two gaps stand between the two spellings: the method lives in another
  module than its type (D83's boundary), and `ct_ret_from` is a method.
- An explicit receiver parameter is still accepted (`fn m(self: &Self)`
  inside an `impl`, `fn Type.m(self: &Self)` at top level). Outside trait
  bodies 37 remain: 19 trait impls (`lib/std/sync.w`, the collections'
  `IndexGet` impls) and 18 dotted top-level methods (`lib/std/alloc.w`,
  `lib/std/build.w`, build-layer spellings the pinned seed's evaluator
  compiles).

## 1. The brief

**What the others do.** Swift: implicit `self` for stored properties and
methods, in the type's body and in every extension in any file; the
compiler synthesises the receiver (`getImplicitSelfDecl`), and an explicit
`self.` is required only where a closure captures it (SE-0269) or a local
shadows the member. Kotlin, Scala, C++ and Java: the same, the whole type,
any file. Rust, Zig, Go, Mojo: always explicit; Vale's own tests write
`self.hp`. D7 chose Swift's receiver model over Rust's; D83 took the field
half of it and stopped at the module boundary.

**What the spec says.** §9.5: "In an instance method declared in its type's
own module, a field of the receiver is in scope by its bare name … A bare
name that resolves to a receiver field and to any other name in scope is an
error at that use; `self.field` and the other name's qualified form remain
valid. A method declared in another module reaches the receiver's fields
only through `self.`." D83's reason for the boundary: "so a field name never
enters scope across a module boundary the reader cannot see"; its reopen
clause: "if the own-module boundary proves to split real types." §29.8
no-shadowing; §18 (D100) package visibility; §11.4: extension methods never
shadow inherent ones and are resolved by import.

**Mission fit.** Inside `impl CiProject:` the compiler knows exactly one
receiver; a `self.` on a member it resolves uniquely is a character the
program has already determined. The guardrail the mission asks for is D83's
collision rule unchanged: when a bare name could be the receiver's or
something else's, the programmer spells which, and the shadowing error
forces that spelling. D83's boundary argument does not hold for the module
that *declares the impl*: the reader of `impl CiProject:` in CiContracts.w
knows which type's names are in scope exactly as the reader of CiIR.w does;
what carries the fact is the `impl` header, not the file. Nothing here
widens visibility: a member a module cannot see by `self.` it cannot see
bare either.

**Prediction.** Eric rules yes to both, at about 90 percent: bare receiver
methods wherever a receiver exists, and bare fields in any `impl`/`extend`
of the type within the package, under D83's unchanged collision rule and
D100's unchanged visibility; `self.` stays valid and remains the spelling
for a shadowed name and for `self` as a value. Not a D98 delegation: a
surface rule code will lean on is hard to reverse.

## 2. Proposed §9.5 wording (draft)

> In an instance method, a field or method of the receiver is in scope by
> its bare name wherever the method's module may see it through `self.`;
> `self.field` and `self.method()` remain valid. A bare name that resolves to
> a receiver member and to any other name in scope is an error at that use
> (§29.8); the member is then `self.name` and the other name its qualified
> form. A parameter or local binding named like a receiver member is a
> shadowing error. `self` itself is written where the receiver is passed,
> returned, compared or captured as a value.

## 3. Rules the wording carries

- **One lookup step, after locals, before module scope.** A bare name in an
  instance method resolves to a local or parameter first (the shadowing
  error has already made those unique), then to a receiver member, then to
  module and imported names. A name found in both of the last two is the
  §29.8 error with both candidates named.
- **A field and a method of the same name** (`len` the field, `len()` the
  method) resolve by use: a call is the method, a place is the field. The
  pair is legal today through `self.`; nothing changes.
- **Visibility is D100's.** In an `extend` of another package's type, only
  `pub` members are in scope bare, exactly the set `self.` reaches.
- **The receiver mode is unchanged.** A bare method call is `self.method()`
  with that method's receiver mode; a `mut fn` called bare inside a `fn` is
  the error `self.mutating()` is there.
- **Closures.** A bare member inside a closure body captures `self` as
  `self.member` would (open question §6.1 on escaping closures).

## 4. Phases

Each phase self-hosts and passes the gate (`src/main build :gate`); the
stack takes one seed-driven battery (`tools/battery.w`). The sweep is its
own PR under the ceremony census's falling bar. A spelling the compiler's
own sources adopt before a seed carrying it is pinned is seed-gated: cut and
pin the seed first, never hold the surface back.

- **5a — bare fields in every `impl` of the type.** Sema's name resolution
  gains the receiver-member step for any `impl`/`extend` of the receiver's
  type in the package (today: the type's own module only); the collision
  check runs against the module and imported names of the *declaring*
  module. Fixtures: a bare field in an `impl` in another module; a collision
  with that module's own `fn` (error, both named); a `pub` field in an
  `extend` of a foreign type; a private field there (undefined, with the
  help that `self.` cannot reach it either).
- **5b — bare method calls.** The same step resolves a call to a receiver
  method; a bare `mut fn` call checks the enclosing receiver mode as
  `self.m()` does; the collision rule covers a method name that is also a
  module-level or prelude function (error at the use until spelled
  `self.len()`). Fixtures: `get() * 2` in the type's module and in another;
  a method named like a prelude function.
- **5c — the sweep.** A compiler-driven rewrite, never a regex: a tool over
  `compiler_analyze_file` facts (the shape of `with migrate-receivers`,
  `src/ReceiverMigration.w`) selects every `self.member` whose bare spelling
  resolves to the same member under the new rule with no collision, and
  applies the byte edits through the Lexer. Expected: most of the 80,137;
  the remainder are the collisions the error names, and `self` as a value.
  Per directory, `with check src/main.w` and `:dev` between steps, the
  census diff at each.
- **5d — the census row.** `self.member` where the bare name would resolve
  becomes a counted ceremony pattern, so new code does not reintroduce it;
  the bar is main's count after the sweep.
- **Phase 4, resumed: refuse the explicit receiver.** With the members
  implicit, the 37 explicit receivers outside trait bodies are swept (19
  trait impls now, the 18 build-layer dotted methods when the pinned seed's
  evaluator allows), then an explicit `self` parameter outside a `trait`
  body is refused with a fix-it; `examples/`, the spec examples and the
  compile-error pins follow. This closes the receiver half.

## 5. Verification

- Fixtures (`test/behavior/behav_*`, `test/compile_errors/`) for each rule
  in §3 and each refusal in §4; `with build :drop-audit` before and after
  5b (a bare `mut fn` call is a receiver call, drop discipline unchanged).
- `with run tools/ceremony_census.w --diff <base>` at every step of 5c; the
  `:ceremony-census` gate after.
- Fixpoint (stage2 == stage3) at the seed-cut tier, the self-host proof for
  a resolution change.

## 6. Open questions

1. Escaping closures: require `self.` for a captured member at the capture
   site (Swift's SE-0269), or let the bare name capture silently?
2. A bare member inside a nested function declared in a method body (no
   receiver of its own): undefined, or an error naming the enclosing
   receiver? Draft: undefined, as today.
3. Whether the sweep rewrites `lib/std` at once or in its own PR (D100's
   sweep left `lib/std` alone; the census bar decides either way).

## 7. References

- Swift `lib/Sema/TypeCheckExpr.cpp` unqualified lookup (locals, then the
  implicit `self`'s members, then module scope); SE-0269.
- D7 (the receiver as a `fn` prefix keyword), D83 (bare fields in the
  type's own module; the collision rule this proposal keeps and the boundary
  it reopens), §29.8, §18 (D100), §11.4.
