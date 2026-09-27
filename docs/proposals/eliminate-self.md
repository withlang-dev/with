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
`docs/with-specification.md` (§2.4, §9.5); the rationale is recorded in
`docs/decisions.md` (D7).

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

1. **Owner known at parse time.**
   - `impl` form: `parse_impl_block` holds `type_name` (`src/Parser.w:3023`).
   - `fn Type.method` form: the owner `type_str` is in hand at
     `src/Parser.w:1179`, *before* the parameter list is parsed
     (`src/Parser.w:1187`).
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

### Phase 2 — Synthesise read-borrow `fn` inside `impl`/`extend`
- A plain `fn` inside `impl`/`extend` with no explicit receiver prepends
  `self: &Self`. (This is where plain `fn` inside a type gains meaning.)
- Migrate the read-borrow methods **already in** `impl`/`extend` blocks (drop the
  explicit `self: &Self`/`self: Self`).
- **Blocker to fix first:** generic `impl Type[T]:` blocks with receiver methods
  currently fail (pre-existing, independent of this work — the working generic
  form is top-level `fn Type.m[T](self…)`). Generic types can only migrate into
  `impl` blocks once this is fixed.

### Phase 3 — Relocate top-level instance methods into `impl` blocks
- The ~3,386 top-level `fn Type.method(self: Type)` are associated-by-location;
  to become implicit-`self` instance methods they move into `impl Type:` blocks.
  This is the large mechanical restructuring — needs the migrator (§4a).
  Associated/top-level `fn Type.name()` (no self) stay put.

### Phase 4 — Enforce
- Reject an explicit `self` parameter with a fix-it; reject `mut`/`move fn` at
  top level. Update remaining spec examples / `examples/` and the compile-error
  test pins. Campaign-end bootstrap: one chain
  `:test → :last-green → :update-seed → :install-user`; verify the new seed
  compiles a self-less probe.

## 4a. Migration tooling

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
  receiver shape. **Trait carve-out (ruled, see D7):** inside a `trait` body
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
- `/drop-audit` before/after Phase 1 and 3 (receiver-mode drop discipline).

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
