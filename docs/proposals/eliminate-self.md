# Eliminate `self`: the receiver's members by bare name

Status: proposal, revised 2026-10-25 after Eric's review ("mostly yes, and
… three things before blessing it", §8). The receiver half of this plan is
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
- The prelude already has a qualified spelling: every prelude function and
  bare-callable intrinsic is reachable as `builtins.name` without a `use`
  (§18.1; verified: `builtins.print(…)` runs).

## 1. The brief

**What the others do.** Swift: implicit `self` for stored properties and
methods, in the type's body and in every extension in any file; the
compiler synthesises the receiver (`getImplicitSelfDecl`); a parameter or
local wins over a member and the member stays reachable as `self.name`; an
explicit `self.` is required in an escaping closure (SE-0269) because
capturing `self` there creates reference cycles and hidden lifetime
extensions. Kotlin, Scala, C++ and Java: the same resolution, the whole
type, any file; C++ style guides add `this->` or `m_` for readability, not
for the compiler. Rust, Zig, Go, Mojo: always explicit; Vale's own tests
write `self.hp`. Rust's prelude rule: anything declared or imported
explicitly shadows the prelude silently, so the prelude can grow without
breaking anyone. D7 chose Swift's receiver model over Rust's; D83 took the
field half of it and stopped at the module boundary.

**What the spec says.** §9.5: "In an instance method declared in its type's
own module, a field of the receiver is in scope by its bare name … A
parameter or local binding named like a receiver field is a shadowing error
(§29.8) … A bare name that resolves to a receiver field and to any other
name in scope is an error at that use; `self.field` and the other name's
qualified form remain valid. A method declared in another module reaches
the receiver's fields only through `self.`." D83's reason for the boundary:
"so a field name never enters scope across a module boundary the reader
cannot see"; its reopen clause: "if the own-module boundary proves to split
real types." §29.8 no-shadowing; §18 (D100) package visibility; §18.1
`builtins.name`; §11.4: extension methods never shadow inherent ones and are
resolved by import; D62: a closure captures by place and the checker
refuses a non-`move` escaping closure that captures a view of the frame.

**Mission fit.** Inside `impl CiProject:` the compiler knows exactly one
receiver; a `self.` on a member it resolves uniquely is a character the
program has already determined. The guardrail is the collision rule between
names the module chose itself: when a bare name could be the receiver's or
a declaration the same package made, the programmer spells which. Two
things the first draft got wrong, both forms of moving ceremony somewhere
worse: an error on a parameter named like a field would rename every
setter's parameter (`mut fn set_name(name: str): self.name = name` is the
common shape), and an error on a collision with a *foreign* package's
member, or with the prelude, would turn another party's additions into
breakage in code they never saw. Inside a package both sides of a collision
are deliberate choices; across the package line and against the prelude
only one is.

**Prediction.** With §8's three changes folded in, Eric blesses §2 at about
90 percent. Not a D98 delegation: a surface rule code will lean on is hard
to reverse.

## 2. Proposed §9.5 wording (draft, revised)

> In an instance method, a field or method of the receiver is in scope by
> its bare name wherever the method is declared in the receiver's own
> package; `self.field` and `self.method()` remain valid, and in an `extend`
> of another package's type they are the only spelling. A parameter or local
> binding may have the name of a receiver member; within its scope the bare
> name is the binding, and the member is `self.name`. A bare use of a member
> is an error when a later binding in the same function has its name. A
> bare name that resolves to a receiver member and to a declaration or
> explicit import of the method's module is an error at that use (§29.8);
> the member is then `self.name` and the other name its qualified form. A
> receiver member shadows a prelude name silently; the prelude's spelling is
> `builtins.name`. `self` itself is written where the receiver is passed,
> returned, compared or captured as a value.

## 3. Rules the wording carries

- **The lookup order.** A bare name in an instance method resolves to a
  local or parameter first, then to a receiver member, then to the module's
  own declarations and explicit imports, then to the prelude. A name found
  both as a member and as a module declaration or explicit import is the
  §29.8 error with both candidates named: both were deliberate choices and
  the reader deserves to be told which is meant. A member shadows the
  prelude silently: nobody chose the prelude's names (`len`, `max`, `min`,
  `contains`, `print`, `clone` are exactly the names types define), and
  adding a name to the prelude must never break existing code (Rust's
  reasoning for its prelude). `builtins.name` is the spelling that always
  reaches a shadowed prelude function.
- **A parameter or local shadows a member.** Within the binding's scope the
  bare name is the binding and the member is `self.name`. This is a
  deliberate exception to §29.8's general no-shadowing rule and the ruling
  should say so: a local still may not shadow another local, but it may
  shadow a receiver member, because the member always has a second spelling
  and a local does not. The setter pattern works unchanged:
  `mut fn set_name(name: str): self.name = name`.
- **One meaning per name per method.** A `let` in the middle of a method
  must not make one bare name mean two things in one function:

  ```
  fn report():
      print(count)      // the field
      let count = 0
      print(count)      // the local
  ```

  A bare use of a member is an error if a later binding in the same
  function has its name: "`count` here is the field, but a binding declared
  on line N shares its name; write `self.count`." Parameters never hit this
  (declared before any use); a local declared before every use of the name
  never hits it either.
- **The package is the boundary, not the file.** Bare members in every
  `impl`/`extend` of a type in the same package — that is what fixes `impl
  Sema` — and `self.` required in an `extend` of another package's type. A
  library adding a `pub fn print` or `pub fn max` to its type must not break
  a client's `extend` block that calls the prelude's bare; across the
  package line a collision would be breakage by someone else's minor
  release. This keeps D83's reason for a boundary (a reader not seeing the
  names that came into scope), drawn at the package line.
- **A field and a method of the same name** (`len` the field, `len()` the
  method) resolve by use: a call is the method, a place is the field. The
  pair is legal today through `self.`; nothing changes.
- **The receiver mode is unchanged.** A bare method call is `self.method()`
  with that method's receiver mode; a `mut fn` called bare inside a `fn` is
  the error `self.mutating()` is there. The readability cost is real —
  `ct_ret_from(si, 0)` no longer tells the reader whether it is a free
  function or a method that may mutate the receiver — and is answered by the
  collision rule (never ambiguous to the compiler), the mode check, and
  later by semantic highlighting in the LSP showing receiver members in a
  distinct style.
- **Closures need no rule.** With captures by place (D62) and checks it: a
  bare field in a closure body captures that field's place; a non-`move`
  escaping closure cannot capture a view of the frame at all; a `move`
  closure takes what it captures visibly. The checker already catches every
  case Swift's explicit-`self` rule exists for, so requiring `self.` there
  would be ceremony.
- **A nested function inside a method has no receiver.** A bare member
  there is undefined, as today: reaching the enclosing receiver silently
  would be a capture with no spelling.
- **The helpful error.** When a bare call resolves to a member and does not
  type-check, and a prelude function of that name would, the error says so:
  "`max` here is the method `self.max()`, which takes no arguments; for the
  prelude function write `builtins.max(a, b)`."

## 4. Phases

Each phase self-hosts and passes the gate (`src/main build :gate`); the
stack takes one seed-driven battery (`tools/battery.w`). The sweep is its
own PR under the ceremony census's falling bar. A spelling the compiler's
own sources adopt before a seed carrying it is pinned is seed-gated: cut and
pin the seed first, never hold the surface back.

- **5a — bare fields in every `impl` of the type within its package.**
  Sema's name resolution gains the receiver-member step for any
  `impl`/`extend` of the receiver's type in the package (today: the type's
  own module only); the collision check runs against the declarations and
  explicit imports of the *declaring* module, never the prelude; a parameter
  or local wins; the later-binding error. Fixtures: a bare field in an
  `impl` in another module of the package; a collision with that module's
  own `fn` (error, both named); a bare field in an `extend` of a foreign
  package's type (undefined, with the help that it is `self.name` there);
  the setter pattern; the `report()` shape above (error with the line
  number); a field named like a prelude function, used bare (the field).
- **5b — bare method calls.** The same step resolves a call to a receiver
  method; a bare `mut fn` call checks the enclosing receiver mode as
  `self.m()` does; the collision rule covers a method name that is also a
  module-level function or explicit import (error at the use); a method
  named like a prelude function shadows it, with the helpful error when the
  call does not type-check as the method. Fixtures: `get() * 2` in the
  type's module and in another; a `mut fn` called bare from a `fn`; a method
  named `print` beside a bare `print(x)` that only the prelude's signature
  fits.
- **5c — the sweep.** A compiler-driven rewrite, never a regex: a tool over
  `compiler_analyze_file` facts (the shape of `with migrate-receivers`,
  `src/ReceiverMigration.w`) selects every `self.member` whose bare spelling
  resolves to the same member under the new rule with no collision and no
  later binding of the name, and applies the byte edits through the Lexer.
  Before it rewrites, it reports the counts Eric asked for: methods with a
  parameter or local named like a member (the setter shape, which the rule
  keeps working), uses the later-binding rule would refuse, and
  member/module collisions, so the ruling's exceptions are measured on the
  real tree. Expected: most of the 80,137; the remainder are the collisions
  the error names, the later-binding cases, and `self` as a value. Per
  directory, `with check src/main.w` and `:dev` between steps, the census
  diff at each.
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
- The LSP's semantic highlighting of receiver members is a follow-up with
  its own issue, not a condition of the ruling.

## 6. Open question

- Whether the sweep rewrites `lib/std` at once or in its own PR (D100's
  sweep left `lib/std` alone; the census bar decides either way).

## 7. References

- Swift `lib/Sema/TypeCheckExpr.cpp` unqualified lookup (locals, then the
  implicit `self`'s members, then module scope); SE-0269 (why Swift needs
  explicit `self` in escaping closures, which D62 makes unnecessary here).
- Rust's prelude: explicit declarations and imports shadow it silently.
- D7 (the receiver as a `fn` prefix keyword), D83 (bare fields in the
  type's own module; the collision rule this proposal narrows to the
  module's own names and the boundary it moves to the package), D62
  (capture by place), §29.8, §18 (D100), §18.1 (`builtins.name`), §11.4.

## 8. Design meetings

**2026-10-25, Eric on the first draft** ("mostly yes … but I'd change three
things before blessing it"):

> 1. Don't make a parameter named like a field an error. … Every
> setter-style method would have to rename its parameter, which moves
> ceremony somewhere worse. Swift and Kotlin use the obvious rule: a
> parameter or local wins, and the member is still reachable as `self.name`.

> 2. Keep bare members within the package, not in `extend` of foreign types.
> … If a library adds a `pub fn print` or `pub fn max` to its type, every
> client `extend` block that calls the prelude's `print` or `max` bare
> suddenly fails to compile, in code the library author never saw. … That's
> also closer to D83's original reason for a boundary, … just drawn at the
> package line instead of the file.

> 3. Closures: no special rule needed. … With captures by place (D62) and
> checks it … The checker already catches every case Swift's rule exists
> for, so requiring `self.` would be ceremony.

> On bare method calls (5b): yes, with one note. The real cost is
> readability … But the collision rule guarantees it's never ambiguous to the
> compiler, a `mut fn` called from a `fn` is still an error, and semantic
> highlighting in the LSP can show receiver members in a distinct style later.

> Open question 2 (a nested function inside a method): undefined, as drafted.

Replacement wording he supplied, now in §2 and §3: "A parameter or local
binding may have the name of a receiver member; within its scope the bare
name is the binding, and the member is `self.name`"; the lookup rule "to a
local or parameter first, then to a receiver member, then to module and
imported names"; the later-binding error with its message; the deliberate
exception to §29.8 recorded. On the prelude: "Members should win over the
prelude, silently. The collision error should apply only to names the
module chose itself." — with the full order locals → members → the module's
own declarations and explicit imports (collision = §29.8 error) → the
prelude (shadowed silently), a qualified spelling for the prelude (it
exists: `builtins.name`, §18.1), and the helpful type error.
