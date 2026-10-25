# Eliminate `self`: Swift-style implicit receiver

**BDFL ruling (Eric, 2026-07-07):** the receiver `self` and its type
annotation are **unnecessary characters** and must not be written. The
receiver mode is a prefix keyword on `fn` (`mut fn` / `move fn` / plain `fn`),
`self` is implicit in the body, and the receiver's type is always the enclosing
type and is never spelled. **Instance vs. associated is decided by *location*,
with no `static` keyword:** a function declared **inside** an `impl` / `extend` /
`type` is an instance method (receiver synthesised); a function declared at
**top level** — including the dotted `fn Type.name` — is associated / free (no
receiver). This is Rust/Zig/Go's rule (presence of receiver discriminates) with
`self` implicit, so it is strictly less ceremony than any of them.

This document is the implementation plan. The normative surface is amended in
`docs/spec/002_ownership.md` (§2.4, §9.5); the rationale is recorded in
`docs/meetings/2026-07-07-D7-eliminate-self-the-receiver-mode-is-a-fn-prefix-keyword-self.md` (D7).

**Status (2026-10-25, audited against main 0a07df6e6).** The receiver half
(phases 0–3, §4) is the language: `fn` / `mut fn` / `move fn` inside an
`impl` synthesise the receiver, a trait impl may omit it against a trait
method that wrote `self` (verified), the dotted top-level form is
associated, `with migrate-receivers` exists, #644/#645/#646 are closed, and
the tree is written that way. Phase 4's refusal of an explicit receiver
parameter is not done: `fn m(self: &Self)` inside an `impl` and
`fn Type.m(self: &Self)` at top level are both still accepted. What still
writes a receiver: 22 trait *declarations* in `lib/std/traits.w` (the D7
carve-out, by design), 19 trait impls in `lib/std/sync.w` and the
collections' `IndexGet` impls (could drop it today), and 18 dotted
top-level methods in `lib/std/alloc.w` and `lib/std/build.w` (phase 3's
last relocations). The second half — the receiver's *members* by bare name,
so that `self.` itself stops being written — is §8 below: D83 (2026-10-03)
landed bare fields in a method declared in the type's own module; bare
fields in an `impl` elsewhere and bare method calls are the open plan,
proposed, not ruled. Sections 2–7 are kept as the record of the receiver
half; where they are stale, a bracketed note says so.

---

## 1. The design

### Canonical surface (target)

```with
impl Counter:                               # inside a type: instance methods
    fn get() -> i32:                        # read borrow  (implicit `self: &Self`)
        self.n
    mut fn bump():                          # mutable borrow (implicit `mut self: Self`)
        self.n = self.n + 1
    move fn into_n() -> i32:                # consuming      (implicit `move self: Self`)
        self.n

fn Counter.new(n: i32) -> Counter:          # top level: associated function, no receiver
    Counter { n: n }

impl Drop for File:
    move fn drop():                         # the only destructor receiver mode (§2.4)
        close_file(self.fd)
```

- **`self` is never declared.** It is an implicit binding available in the
  body of every instance method (exactly like Swift's `getImplicitSelfDecl()`).
- **The receiver's type is never spelled.** It is always the enclosing type
  (`Self`).
- **The mode is the keyword on `fn` (inside a type); location decides
  instance vs. associated:**
  | declaration | receiver semantics | desugars to |
  |---|---|---|
  | `fn` inside `impl`/`extend`/`type` | read borrow | `self: &Self` |
  | `mut fn` inside a type | by-place mutable borrow | `mut self: Self` |
  | `move fn` inside a type | consuming (owns `self`) | `move self: Self` |
  | `fn` / `fn Type.name` at top level | associated / free | *(no receiver)* |
  | `mut`/`move fn` at top level | **error** — mode with no receiver | — |

### Why this maps cleanly onto our model

Swift stores the receiver mode as a `SelfAccessKind`
(`include/swift/AST/Decl.h:262`: `NonMutating` / `Mutating` / `Consuming` /
`Borrowing`) on the function decl, and synthesises the `self` `ParamDecl` in the
compiler — the user writes neither the parameter nor its type. Our advantage:
we already have working, verified lowering for the three explicit receiver
shapes (`self: &Self`, `mut self: Self`, `move self: Self`). So we do **not**
need to thread a new `SelfAccessKind` through sema/MIR/codegen the way Swift
does. **We desugar in the parser to the existing shapes**, and everything
downstream is unchanged.

`mut fn` = "`self` is passed `inout`" is precisely With's by-place mutable
borrow (caller keeps ownership, callee mutates the caller's place). Swift's own
rationale for `mutating = inout self` (OwnershipManifesto: the caller retains
the storage, the borrow is statically checkable) is verbatim our receiver-mode
rationale (D12) — so this is the same ownership model with less ceremony, not a
new one.

### What this dissolves (not patches)

[2026-10-25: all three issues below are closed; the bare-`mut self` codegen
failure no longer has a surface to occur on.]

- **#646** (unflagged `self: ConcreteType` escapes the mode check) — there is no
  `self` parameter to annotate, so nothing escapes. The mode is the keyword.
- **#645 part 2** (`mut` silently discarded on a non-self param) — already
  fixed by rejecting it; `mut` now only ever appears as `mut fn`.
- **#644** (mut-self on a primitive owner) — the mode is uniform across owner
  kinds; the owner type is inferred whether struct or primitive; the by-pointer
  ABI question is answered once at the desugar (a `mut fn` receiver is always
  `mut self: Self`).
- **bare-`mut self` codegen failure** — bare receiver forms stop existing at the
  surface; the desugar only ever emits the verified-working annotated shapes.

---

## 2. Feasibility (verified, not assumed)

[2026-10-25: this section is the record of the decision; the line numbers
were the tree of 2026-07. The functions it names are `Parser.parse_impl_block`,
`Parser.build_synth_receiver` and `Parser.flush_receiver_only_param`, which
is how the receiver is synthesised today.]

1. **Owner known at parse time.**
   - `impl` form: `parse_impl_block` holds `type_name`.
   - `fn Type.method` form: the owner `type_str` is in hand *before* the
     parameter list is parsed.
2. **Synthesis precedent.** The parser already synthesises declarations and
   params: `synthesize_implicit_main` (`:237`), `queue_synthetic_copy_impl`
   (`:1550`), synthetic parameter patterns (`:7565`), synthetic type nodes
   (`:2067`). Injecting a synthetic receiver param is the same machinery.
3. **Downstream is unchanged.** Confirmed working end-to-end today:
   `fn m(self: &Self)` (read) → runs; `fn m(mut self: Self)` (mut) → mutates;
   `fn m(move self: Self)` (move) → consumes. The desugar targets exactly these.
4. **Mode/method machinery exists.** `SemaDecl.w:1277` already enforces "a
   method receiver requires an explicit mode"; that enforcement moves upstream
   of the desugar.

**Verdict: front-end-only change riding on paths that already work. No new
codegen.**

---

## 3. The discriminator: location, no keyword

Today the *presence of a `self` parameter* distinguishes an instance method from
an associated function. Once `self` is implicit, the discriminator becomes
**lexical location** — a fact the parser already has, requiring no keyword and no
inference:

- **Inside `impl` / `extend` / `type`** → instance method; the receiver is
  synthesised (mode from the keyword).
- **Top level** (incl. the dotted `fn Type.name`) → associated / free function;
  no receiver. A `mut`/`move` prefix here is an error.

Construction is a struct literal (`Counter { n: 0 }`, already in the language) or
a top-level `fn Type.make() -> Counter`. This is exactly Rust/Zig/Go's rule
(Zig: `init` vs `deinit(self)`) with `self` implicit.

The consequence for **existing code**: our compiler writes most instance methods
as *top-level* `fn Type.method(self: Type)`. Under this rule those are "associated
by location", so reaching full self-elimination **relocates them into `impl`
blocks** (dropping `self`). The transition keeps explicit-`self` forms accepted,
so it is gradual, not big-bang.

---

## 4. Implementation phases

Each phase self-hosts and passes the full gate
(`with build && :fixpoint && :test`) before the next. Because phases 1–3 change
**parser semantics**, each requires the self-host flip sweep (see memory
`project_629_selfhost_flips`): instrument old-vs-new decisions, build stage1,
diff the tree, review every flip before gating. Until the campaign-end seed
update, compiler sources must not rely on the new spelling.

[2026-10-25: superseded. Verification is the tiered gate and the one
seed-driven battery per stack (D14, D131, `tools/battery.w`); the flip sweep
and the "campaign-end seed update" were the 2026-07 bootstrap discipline.
A compiler-source spelling that needs a newer seed is cut and pinned
through `seed.lock` (`:seed`; there is no `:update-seed`), never held back.]

### Phase 0 — Grammar (done as part of P1)
- Parser: accept a `mut` / `move` prefix on a method `fn` **inside** an
  `impl`/`extend` block; error it at top level. No `static` keyword. The impl
  loop guard and top-level lookahead admit `mut`/`move`.

### Phase 1 — Synthesise `mut fn` / `move fn` (unambiguous) — **IMPLEMENTED**
- Inside `impl`/`extend`, a `mut fn` / `move fn` **prepends a synthetic receiver
  param** (`mut self: Self` / `move self: Self`) with a literal `Self`
  `NK_TYPE_NAMED` node (the mode machinery keys off the literal `Self`; see
  #646). Both the parenthesised and paren-less method forms are covered
  (`Parser.build_synth_receiver` + `flush_receiver_only_param`, consumed by
  `parse_param_list`). Downstream is untouched.
- Safe/unambiguous: `mut fn` / `move fn` have no prior meaning.
- Migration (relocation): because most `mut self: Self`/`move self: Self` methods
  are top-level `fn Type.method(...)`, converting them to `mut fn`/`move fn`
  means **moving them into an `impl` block**. Deferred to the migrator (§4a) with
  the P3 read-borrow bulk; explicit forms stay accepted meanwhile.

### Phase 2 — Synthesise read-borrow `fn` inside `impl`/`extend` — **DONE**
- A plain `fn` inside `impl`/`extend` with no explicit receiver prepends
  `self: &Self`. (This is where plain `fn` inside a type gains meaning.)
  [The generic blocker below is fixed: `impl[T] Stack[T]:` with receiver
  methods is how every facade is written.]
- Migrate the read-borrow methods **already in** `impl`/`extend` blocks (drop the
  explicit `self: &Self`/`self: Self`).
- **Blocker to fix first:** generic `impl Type[T]:` blocks with receiver methods
  currently fail (pre-existing, independent of this work — the working generic
  form is top-level `fn Type.m[T](self…)`). Generic types can only migrate into
  `impl` blocks once this is fixed.

### Phase 3 — Relocate top-level instance methods into `impl` blocks — **DONE but 18**
- [Remaining: `fn Arena.add_block(mut self: Arena, …)` and its two siblings
  in `lib/std/alloc.w`, and the `ToolFs.*(self: &Self, …)` methods in
  `lib/std/build.w`, which the pinned seed's evaluator compiles (a
  build-layer spelling is seed-gated); they move with the next seed that
  allows it.]
- The ~3,386 top-level `fn Type.method(self: Type)` are associated-by-location;
  to become implicit-`self` instance methods they move into `impl Type:` blocks.
  This is the large mechanical restructuring — needs the migrator (§4a).
  Associated/top-level `fn Type.name()` (no self) stay put.

### Phase 4 — Enforce — **OPEN**
- Reject an explicit `self` parameter with a fix-it (outside a `trait` body,
  where D7's carve-out keeps it as the instance/associated discriminator);
  reject `mut`/`move fn` at top level [done]. Update remaining spec examples
  / `examples/` and the compile-error test pins. [The campaign-end chain
  this phase named (`:update-seed`) no longer exists: the sweep of the 37
  remaining explicit receivers outside trait bodies lands as one stack, its
  battery, a merge, a reseed; a seed cut only if the build layer's spelling
  needs one.] Resumes after §8's sweep, which removes `self.` first.

## 4a. Migration tooling

[2026-10-25: exists — `with migrate-receivers` (`src/ReceiverMigration.w`:
`--report`, `--list`, `--apply`) and `tools/migrate_receivers.w`, selection
from `compiler_analyze_file` facts, byte edits through the Lexer. The same
shape serves §8's sweep.]

The volume (~3,900 receivers + relocations) needs a **compiler-driven migrator**
(`with migrate-receivers`, reusing the parser) — it must handle multi-line
signatures, the paren-less `fn T.m -> R:` form, and P3's decl relocation into
`impl` blocks. It transforms precisely because the parser sees param 0's `self` +
its flags. Regex will not survive 3,900 self-host-critical sites.

---

## 5. Edge cases to design/verify per phase

- **`Self` type node synthesis** — the synthetic receiver must carry a literal
  `Self` (mut/move) or `&Self` (read) type node, not the concrete owner name
  (`self: ConcreteType` is the #646 bug path). Verify the synthesized node
  routes through the working receiver-mode classification.
- **Top-level `fn Type.name` form** — associated by location: **no** receiver is
  synthesised. An explicit `self` there is the transition path (Phase 4 rejects
  it, directing the author to move the method into an `impl` block).
- **Generics** — `mut fn bump[T]()` on a generic owner: `Self` resolves to the
  generic instance, as it does for explicit `mut self: Self` today
  (`behav_mut_self_drop_generic` is the guard test).
- **Trait / interface methods without a body** — the modifier must be parseable
  on a signature-only method declaration and flow into the trait's expected
  receiver shape. [Verified 2026-10-25: a trait method written `fn area(self:
  &Self)` is an instance contract and its impl may write `fn area()`; a trait
  method written `fn area()` is associated and `self` in its impl is
  undefined, with the "call it as `D.area(...)`" help.] **Trait carve-out
  (ruled, see D7):** inside a `trait` body
  only `mut fn` / `move fn` synthesise; plain `fn` keeps the explicit spelling
  because a trait must hold both instance and associated contracts and location
  cannot discriminate there — with a receiver param it is an instance contract,
  without one it is associated (`Default.default`, `Try.from_break`). Trait
  authoring is library-maintainer tier; app-facing `impl` blocks still get the
  fully implicit form.
- **`move fn drop()`** — the only Drop::drop receiver (§2.4); the #642 check
  ("Drop.drop must consume") moves to "Drop.drop must be `move fn`".
- **Explicit `self` uses in the body** — `self`, `self.field`, and passing
  `self` onward (`f(self)`) must resolve against the synthesized binding
  exactly as against a written `self` param today.
- **Associated-function calls** — a top-level `fn Type.name()` is an ordinary
  function namespaced under the type; no receiver ABI. Verify call-site
  resolution (`Type.name()` associated call vs `value.method()` instance call).
- **One-line assignment-body methods** — noted during design: a one-line
  `fn m(...): self.x = e` shape has a separate codegen quirk; ensure the desugar
  does not depend on body shape.

---

## 6. Verification per phase

- Fast check (`out/stage/bin/with-stage2 check src/main.w`) before any build.
- Probe each edge case above with `out/release/bin/with` (never the seed).
- Fixtures: `behav_*` for each mode (read/mut/move + top-level associated) in both `impl` and
  `Type.` forms, generics, trait methods; `compile_errors/` for a modifier on a
  free function, a static call on an instance method, and (Phase 4) an explicit
  `self` parameter.
- Full gate + fixpoint. Fixpoint is the self-host regression proof for the
  parser change.
- `with build :drop-audit` before/after Phase 1 and 3 (receiver-mode drop
  discipline). [The fast check is `with check` with the installed compiler
  and `out/bootstrap/bin/with-stage1` after `:dev`; `with-stage2` exists only
  after a full build.]

---

## 7. Reference inspiration (Swift, `.reference/swift`)

- `include/swift/AST/Decl.h:262` `enum class SelfAccessKind` — the receiver mode
  is a decl property (`NonMutating`/`Mutating`/`Consuming`/`Borrowing`), not a
  parameter. Our `fn`/`mut fn`/`move fn` map to `NonMutating`/`Mutating`/
  `Consuming`; we encode it by desugar rather than as a persisted enum.
- `getImplicitSelfDecl()` (AST) — `self` is a compiler-synthesised `ParamDecl`,
  never user-written. Our parser synthesises the receiver param.
- `docs/OwnershipManifesto.md` — `mutating` ⇒ `inout self`, statically checkable
  because the caller retains the storage. This is With's by-place receiver mode
  (D12).
- SE-0377 `consuming`/`borrowing` — Swift's later split of ownership on the
  receiver; our `move fn` is `consuming`, plain `fn` is `borrowing`.

---

## 8. The second half: the receiver's members by bare name

Proposed 2026-10-25, not ruled. The spec words below are a draft for Eric
to bless or rewrite; until then §9.5 stands as D83 wrote it.

### 8.1 What exists and what does not

The receiver is implicit (§4), but its use is not: the tree writes `self.`
80,137 times (39,241 method calls, 39,930 field reads), the single largest
ceremony count in the codebase. Two rules decide which of those are forced:

- **D83 (§9.5, 2026-10-03):** in an instance method declared in its type's
  *own module*, a receiver field is in scope by its bare name; a parameter or
  local named like a field is a shadowing error (§29.8); a bare name that
  resolves to a field and to any other name in scope is an error at that use,
  `self.field` and the qualified name staying valid. D83's reason for the
  module boundary: "so a field name never enters scope across a module
  boundary the reader cannot see." Its reopen clause: "if the own-module
  boundary proves to split real types."
- **Methods were never in the rule.** `get()` for `self.get()` is refused
  everywhere, the type's own module included (probed on the installed
  compiler, 2026-10-25: `undefined variable`).

The boundary splits real types. `impl Sema` sits in eight files beside
Sema.w (66 blocks); `impl CiProject` in four (CiIR.w declares it; CiContracts,
CiFacadeDraft and CiMigrate hold its methods). Inside those blocks every
field is `self.field`, and every method call is `self.method()` everywhere.
Eric's question, on a line of CiContracts.w:

> why do we need 'self'? Can we make it so instead of
> `let ret_part = ct_is_pointer(self.symbols[si].ret_ty) and self.ct_ret_from(si, 0)`
> they can write `let ret_part = ct_is_pointer(symbols[si].ret_ty) and ct_ret_from(si, 0)`

Two gaps stand between the two spellings: the method lives in another
module than its type (D83's boundary), and `ct_ret_from` is a method (never
ruled).

### 8.2 The brief

**What the others do.** Swift: implicit `self` for stored properties and
methods, in the type's body and in every extension in any file; the compiler
synthesises the receiver (`getImplicitSelfDecl`), and an explicit `self.` is
required only where a closure captures it or a local shadows the member.
Kotlin, Scala, C++ and Java: the same, the whole type, any file. Rust, Zig,
Go, Mojo: always explicit; Vale's own tests write `self.hp`. D7 already chose
Swift's receiver model over Rust's; D83 took the field half of it and stopped
at the module boundary.

**What the spec says.** §9.5 as quoted above; §29.8 no-shadowing; §18 (D100)
package visibility: a member a module cannot see by `self.` it cannot see
bare either, so nothing here widens visibility. §11.4: extension methods
never shadow inherent ones and are resolved by import.

**Mission fit.** Inside `impl CiProject:` the compiler knows exactly one
receiver; a `self.` on a member it resolves uniquely is a character the
program has already determined. The guardrail the mission asks for is D83's
collision rule unchanged: when a bare name could be the receiver's or
something else's, the programmer spells which, and the shadowing error
forces that spelling. D83's boundary argument does not hold for the module
that *declares the impl*: the reader of `impl CiProject:` in CiContracts.w
knows which type's names are in scope exactly as the reader of CiIR.w does;
what carries the fact is the `impl` header, not the file.

**Prediction.** Eric rules yes to both, at about 90 percent: bare receiver
methods wherever a receiver exists, and bare fields in any `impl`/`extend`
of the type within the package, under D83's unchanged collision rule and
D100's unchanged visibility; `self.` stays valid and remains the spelling
for a shadowed name and for passing or returning `self` itself. Not a D98
delegation: a surface rule that code will lean on is hard to reverse.

### 8.3 Proposed §9.5 wording (draft)

> In an instance method, a field or method of the receiver is in scope by
> its bare name wherever the method's module may see it through `self.`;
> `self.field` and `self.method()` remain valid. A bare name that resolves to
> a receiver member and to any other name in scope is an error at that use
> (§29.8); the member is then `self.name` and the other name its qualified
> form. A parameter or local binding named like a receiver member is a
> shadowing error. `self` itself is written where the receiver is passed,
> returned, compared or captured as a value.

### 8.4 Design rules the wording carries

- **One lookup step, after locals, before module scope.** A bare name in an
  instance method resolves to a local or parameter first (which the
  shadowing error has already made unique), then to a receiver member, then
  to module and imported names. A name found in both of the last two is the
  §29.8 error with both candidates named.
- **A field and a method of the same name** (`len` the field, `len()` the
  method) resolve by use: a call is the method, a place is the field. The
  pair is legal today through `self.`; nothing changes.
- **Visibility is D100's.** In an `impl` of a foreign package's type
  (`extend`), only `pub` members are in scope bare, exactly the set `self.`
  reaches.
- **Closures.** A bare member inside a closure body captures `self` as
  `self.member` would. Open question (§8.6): whether an escaping closure
  must write `self.` so the capture is visible at the site, as Swift
  requires.
- **No change to what the receiver is.** A bare method call is
  `self.method()` with the method's own receiver mode; a `mut fn` called
  bare inside a `fn` is the same error as `self.mutating()` there.

### 8.5 Phases

Each phase self-hosts and passes the gate; the sweep is its own PR under
the ceremony census's falling bar.

- **Phase 5a — bare fields in every `impl` of the type.** Sema's name
  resolution gains the receiver-member step for any `impl`/`extend` of the
  receiver's type in the package (today: the type's own module only); the
  collision check runs against module and imported names of the *declaring*
  module. Fixtures: a bare field in an `impl` in another module; a collision
  with that module's own `fn` (error, both named); a `pub` field in an
  `extend` of a foreign type; a private field there (undefined, with the
  `self.`-cannot-reach-it-either help).
- **Phase 5b — bare method calls.** The same step resolves a call to a
  receiver method; a bare `mut fn` call checks the enclosing receiver mode as
  `self.m()` does; the collision rule covers a method name that is also a
  module-level function (error at the use). Fixtures: `get() * 2` in the
  type's module and in another; a method named like a prelude function
  (`len`), which is the collision error until spelled `self.len()`.
- **Phase 5c — the sweep.** A compiler-driven rewrite, not a regex
  (`compiler-driven-rewrites-not-regex`): a tool over `compiler_analyze_file`
  facts selects every `self.member` whose bare spelling resolves to the same
  member under the new rule and no collision, and applies the byte edits
  through the Lexer. Expected: most of the 80,137; the remainder are
  collisions the error names, and `self` as a value. Run per directory,
  `with check src/main.w` and `:dev` between, the census diff at each step.
- **Phase 5d — the census row.** `self.member` where the bare name would
  resolve becomes a counted ceremony pattern, so new code does not reintroduce
  it; the bar is main's count after the sweep.
- **Phase 4, resumed.** With the members implicit, the explicit receiver
  parameter (41 in-impl, 18 dotted) is swept and then refused with its
  fix-it, closing the receiver half.

### 8.6 Open questions

1. Escaping closures: require `self.` for a captured member at the capture
   site (Swift), or let the bare name capture silently?
2. A bare member inside a nested function declared in a method body (no
   receiver of its own): undefined, or an error naming the enclosing
   receiver? Draft: undefined, as today.
3. Whether the sweep also rewrites `self.method()` in the standard library's
   facades at once or leaves `lib/std` to its own PR (D100's sweep policy
   left `lib/std` alone; the census bar decides either way).

### 8.7 Reference

- Swift `lib/Sema/TypeCheckExpr.cpp`, unqualified lookup: locals, then the
  implicit `self`'s members, then module scope; `SE-0269` (implicit `self` in
  escaping closures) is the closure precedent.
- With: `docs/meetings/2026-10-03-D83-receiver-fields-are-in-scope-by-bare-name-in-the-type-s-own-module.md`
  (the collision rule and the boundary this section reopens), §29.8, §18 (D100).
