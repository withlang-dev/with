# comptime Integer Width — Implementation Plan (#943)

## Authority and scope

Execution plan for making comptime integer evaluation agree with runtime
evaluation. Issue of record: #943.

This plan fixes a **correctness** bug in `i64`/`u64` comptime arithmetic. It is
not part of the i128/u128 campaign (#914), though it overlaps it: #914's D4
describes the same evaluator and mis-characterizes it. See "Relationship to
\#914" below.

Verified by reading `main` at `22e534c6`. Runtime measurements were taken with
the released `v0.15.1.7` binary (`04ca1a74`); `src/Overflow.w` and
`src/ComptimeValue.w` are byte-identical between the two revisions, and the
five `src/ComptimeEval.w` hunks that differ are all #679 decl-index caching,
touching neither `:6742` nor `:7862`.

---

## The governing rule

The semantic model this plan implements, stated once so every stage can be
checked against it:

> For any expression comptime evaluates, it must produce the value the runtime
> would produce and detect exactly the same overflow conditions. Where comptime
> cannot faithfully reproduce runtime behavior, it must **refuse to evaluate** —
> never approximate.

**Same, or refuse. Never different.**

This is not a style preference. A `comptime fn` is callable at runtime:

```with
comptime fn f(x: i64) -> i64: x + 1
const C: i64 = comptime f(3000000001)
fn main:
    let r = f(3000000001)
    print(f"comptime = {C}")      // -1294967294
    print(f"runtime  = {r}")      //  3000000002
```

One function, one argument, two answers. Agreement is a soundness requirement,
not a nicety.

Three corollaries, used as invariants below:

1. **Sema is authoritative.** Every comptime integer value carries the sema type
   of the expression that produced it. There is no default and no fallback. A
   failed type lookup is an internal compiler error, not an `i32`.
2. **Representation is canonical.** The payload always holds the value's
   canonical form in its own type. `(type_id = i32, data0 = 3000000001)` must be
   unrepresentable.
3. **Arithmetic is the runtime arithmetic**, under the active overflow mode,
   with checks applied to values *before* any width normalization.

Truncation is a semantic operation the programmer asks for (`as`, `*%`, `+%`).
It is never a repair applied to make an invalid internal state look valid. That
distinction is the whole bug.

---

## Current state

> **Historical.** This section and "Root cause" below record the defect as
> found at `22e534c6`, before any fix. They are kept because the diagnosis is
> what the stages were built against; for what is now true, see **Status** at
> the end.

| Behavior | State | Evidence |
|---|---|---|
| Plain const folding, within 64 bits | correct | `const A: i64 = 3000000001 + 0` returns `3000000001` |
| Plain const folding, beyond 64 bits | **corrupt** | `const ADD: i128 = 18446744073709551616 + 1` folds to `1` — see "The 64-bit ceiling" below |
| Runtime arithmetic | **correct** | measured |
| `comptime` evaluator, values within `i32` | correct | measured |
| `comptime` evaluator, values beyond `i32` | **corrupt** | four symptom classes below |
| Overflow mode honored at comptime | yes | `sema.overflow_mode` is read; `h * 33 + 100` overflowing `u64` errors |
| Refusal on unsupported operations | yes | `s.bytes()` reports "not comptime-evaluable yet" |

The evaluator does integer arithmetic at **32 bits** regardless of declared type,
suffix, annotation, or return type. `2147483647i64 + 1i64` raises
`integer overflow in comptime`, which is itself proof of the width.

### Four symptom classes

```with
3000000001i64 + 0i64        // -1294967295   signed, silent
0i64 - 3000000000i64        //  1294967296   signed, silent
4294967296u64 + 0u64        //  0            unsigned, silent — 2^32 becomes 0
4294967301u64 * 1u64        //  5            unsigned, silent
1i64 << 40                  //  0            shift, silent
3000000001u64 + 0u64        //  error: integer literal does not fit expected type
```

The last is the one accidental guard: when the truncated value lands negative,
the unsigned fit check catches it at materialization — with a message that
blames a literal when no literal is at fault. Whether `u64` fails loudly or
silently depends on which side of zero the corrupted value falls on.

Note the shift case reaches the corruption through `eval_shift_value` rather
than `int_signed_add`, confirming the width is wrong at the source rather than
inside one arithmetic helper.

### The 64-bit ceiling

Separately from the 32-bit defect above, the evaluator cannot represent any
value wider than 64 bits at all. The literal machinery is 128-bit exact; the
evaluator discards the high word on entry.

```with
const LIT: i128 = 18446744073709551617          // 2^64 + 1, literal only
const ADD: i128 = 18446744073709551616 + 1      // 2^64 + 1, via folding
```
```
LIT >> 33 = 2147483648      // correct
ADD >> 33 = 0               // ADD folded to 1
```

`ComptimeEval.w:7861` is the boundary:

```with
comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), exact.lo)
```

`exact.lo` only — `exact.hi` appears nowhere in the file. `2^64` arrives as its
low word, `0`, so `ADD` is `0 + 1`. `9223372036854775807 + 1` in an `i128`
context raises `integer overflow in comptime`, confirming the ceiling from the
other side.

That line is not sloppiness; it is forced. `data0: i64` has nowhere to put
`exact.hi`. This is the concrete form of invariant 2 being unsatisfiable at
128 bits, and the reason widening is structural rather than optional (see
"Relationship to #914"). Still open: the 64-bit ceiling is unchanged by this
campaign — the payload is still one `i64`.

### Workaround for user code (superseded)

`eval_cast` resolves the cast's target type expression itself rather than
trusting sema, so **explicit `as i64` / `as u64` casts set the width reliably
even pre-sema**. Verified against a runtime control:

```with
comptime fn casted -> u64:
    var acc: u64 = 5381
    var i = 0
    while i < 8:
        acc = (acc as u64) * (33 as u64) + (100 as u64)
        i = i + 1
    acc
```
```
comptime = 7572279801686821
runtime  = 7572279801686821      // identical
```

Without the casts the same loop raises `integer overflow in comptime` at the
32-bit boundary. Note the asymmetry worth communicating to users: **`as u64`
works, the `u64` literal suffix does not** — the evaluator never reads suffixes.

**No longer needed.** S2 landed the suffix and annotation handling, so
`5381u64` and `var acc: u64 = 5381` now carry their declared width without
help. Kept as a record of the asymmetry that existed — casts worked because
`eval_cast` resolved its own target type, which is what suggested reading the
suffix in the same way.

---

## Root cause

Three links. The first two are confirmed by reading; the mechanism behind link 1
was inferred when this plan was first written and is now confirmed; see
"Why the lookup misses".

### L1 — the literal constructor guesses a type

`src/ComptimeEval.w:7861-7862`:

```with
return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), exact.lo))
return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), fast.value))
```

Two adjacent construction sites with two different defaults. A literal that fits
`i64` takes the second and falls back to **`ty_i32`** when `node_type_or` finds
no entry in `typed_expr_types`.

The fallback cannot distinguish *"sema assigned i32"* — legitimate, and the
documented default for small unsuffixed literals — from *"I failed to find what
sema assigned"* — a compiler bug. Those require opposite responses. That the two
lines disagree on their default is the tell that neither is principled.

### L2 — the fallback propagates into arithmetic

`src/ComptimeEval.w:6742`:

```with
let result_ty = self.node_type_or(node, if lhs.type_id != 0: lhs.type_id else: rhs.type_id)
```

`lhs.type_id` is now `i32`, so `comptime_int_width(result_ty)` returns 32 for
every subsequent operation.

### L3 — operands are truncated before the overflow check

`src/Overflow.w:152-215`. All six helpers share the ordering:

```with
fn int_signed_add(lhs: i64, rhs: i64, width_raw: i32, mode: i32) -> IntArithmeticResult:
    let width = int_width_clamp(width_raw)
    let lv = int_truncate_to_width(lhs, width, false)   // 3000000001 -> -1294967295
    let rv = int_truncate_to_width(rhs, width, false)
    ...
    let over_hi = rv > 0 and lv > max - rv               // rv == 0 -> false
    if not over_hi and not over_lo:
        return int_arith_ok(wrapped)                     // corrupted value, no diagnostic
```

The check asks whether the *operation* overflows, but the *operands* were
already silently truncated. Adding `0`, subtracting `1`, or multiplying by `1`
cannot overflow, so the corruption is never flagged. `int_signed_sub` `:171-172`,
`int_signed_mul` `:203-204`, `int_unsigned_add` `:109-110`, `int_unsigned_sub`
`:125-126`, `int_unsigned_mul` `:138-139` are identical in this respect.

`OP_DIV` and `OP_MOD` escape because their arms in `ComptimeEval.w` compute on
raw operands and consult the width only for `int_div_overflows`. That is luck,
not design — `3000000000i64 / 1000000000i64` is correct today.

**L3 is what makes the bug silent.** L1 alone would produce loud errors on any
out-of-range literal. This ordering is only tempting because invariant 2 is not
guaranteed, so the helper defensively normalizes inputs it cannot trust.

### Why the lookup misses — confirmed

**Comptime folding runs before sema.** `Frontend.w:1683-1688`:

```with
pre_sema.prepare_for_comptime_transform()
...
pool = pre_sema.comptime_transform_module(pool, self.pool)
```

`prepare_for_comptime_transform` (`Sema.w:6517`) does six things —
`compute_method_origins`, `collect_declarations`, `build_ci_scoping`,
`validate_copy_derives`, `validate_compiler_hooks`,
`validate_generic_type_decls` — and **no `check_expr`**. So `typed_expr_types`
is empty for function bodies while folding runs. Every fold entry point
(`comptime_try_eval_expr` / `comptime_force_eval_expr`) is called from
`ComptimeTransform.w` inside this pass; the only caller outside it is an
`embed_file` path in `SemaCheck.w`.

`typed_expr_types` is a partial `HashMap[i32, i32]` (`Sema.w:960`). It is not
cleared by `prepare_comptime_eval_copy` (`Sema.w:1500`) — a stale-copy
explanation is ruled out. The table is simply not populated yet.

**Three things that should supply the width, and do not:**

- **Literal suffixes are never consulted.** `literal_suffix` appears **zero**
  times in `src/ComptimeEval.w`. `5381u64` evaluates as `i32`. Sema knows the
  rule (`SemaCheck.w:6062`) but has not run. This is why an explicitly suffixed
  `3000000001i64` still corrupts.
- **Parameter types are not applied.** `eval_fn_symbol_call_values` binds
  arguments raw; a declared `a: i64` never reaches the value.
- **`let`/`var` annotations are ignored.** `eval_let_binding` reads `data1` and
  binds without consulting the annotation.

The only type seeding that exists is `ComptimeTransform.w:1105` (local `let`)
and `:2992` (top-level `let`/`const`), which stamp a `const X: T = comptime …`
annotation onto the outermost `NK_COMPTIME` node and its immediate child. That
is why shallow cases pass while anything deeper does not, and why plain const
folding is correct within 64 bits while the explicit `comptime (...)` form is
not.

**Cloned nodes can never be in the table.** `ct_clone_tree_with_subst`
(`ComptimeTransform.w:590`) mints fresh node ids per unrolled `comptime for`
iteration. Those ids are absent from `typed_expr_types` by construction, so any
fix relying on the table alone must also cover them.

**An existing band-aid confirms the class.** `apply_implicit_default_return`
(`ComptimeEval.w:~1847`) masks the *returned* value to the declared return
width, citing #767: "fold-order evaluation can compute an int body value in the
operand's default representation … before the tail expr has its checked type
record." That repairs the final value only — intermediates were already computed
at the wrong width, and a panic-mode overflow has already aborted.

> Source: `with-ui128/docs/comptime-int-width-bug.md`, diagnosed independently
> at `5465144`. Every claim above re-verified against `22e534c6`. That doc's
> predicted reproducer using `hash_str` does **not** fire — it dies earlier on
> `str method 'bytes' is not comptime-evaluable yet` — so use an accumulator
> loop over a range instead.

---

## Stages

Ordering rationale: **S1 before S2.** S1 is local, low-risk, and converts silent
corruption into loud errors — the worst symptom disappears first, and the
guarantee it establishes stays valuable after S2 lands. S3 strictly after S2:
turning a failed lookup into an ICE while lookups still miss would break every
comptime evaluation in the compiler.

### S0 — Pin current behavior (½ day)

Land the differential oracle first. It is cheap and would have caught every
symptom in this issue.

**The oracle:** for any expression `E` of integer type `T` evaluable in all
three paths, these must agree — **and agree with the value written out by
hand**:

```
comptime E   ==   plain-const-fold E   ==   runtime E   ==   expected literal
```

The fourth term is not redundant, and the three paths are not equally
trustworthy:

- **Plain const folding is not independent** — it runs through the same
  evaluator (see "Why the lookup misses"). It differs from the explicit
  `comptime` form only in typing state, and inherits the same 64-bit ceiling:
  `const ADD: i128 = 18446744073709551616 + 1` folds to `1`. Agreement between
  the two const forms therefore proves very little on its own.
- **Runtime is the independent term.** It is correct at 128 bits
  (`let a: i128 = 2^64; a + 1` is exact), so it — not plain folding — is what
  anchors the test.
- **The expected literal** guards against all three drifting together and makes
  a failure readable without re-deriving the arithmetic.

Concretely: above 64 bits, plain folding already disagrees with runtime. That
disagreement is a real finding, not test noise, and it belongs to #914's D4.

Above 64 bits, `expected literal` cannot be checked by printing — D1 (#914)
truncates every format path to 64 bits. Use the `>> n` layer discriminators from
\#914's S0 (`(2^100 literal) >> 90 == 1024`) so the assertion lands on a value
that renders correctly. This also keeps the two campaigns' 128-bit tests
mutually intelligible.

- `test/behavior/behav_comptime_int_width.w` — the agreement matrix across
  `i8/i16/i32/i64` and `u8/u16/u32/u64`, with operands straddling each width
  boundary, exercising `+ 0`, `- 0`, `* 1`, `<< 0`, `/ 1`.
- `test/behavior/behav_comptime_overflow_modes.w` — the same under
  `--overflow=panic|wrap|saturate`; comptime and runtime must make the same
  decision, differing only in whether it surfaces as a compile error or a trap.
- `test/compile_errors/comptime_int_width.w` — pins the current diagnostics so
  later stages show a visible diff, including the misleading
  "integer literal does not fit expected type" for the unsigned case.

Mark expected-fail where the harness supports it.

### S1 — L3: check before normalize (1 day)

`src/Overflow.w`, all six arithmetic helpers.

Replace *truncate-then-check* with *check-then-normalize*. An operand that does
not fit `width` is not silently normalized; it is reported through the existing
`IntArithmeticResult` channel so callers surface it as a diagnostic.

- Add a fits-width predicate over the operand pair, evaluated before any
  truncation.
- On a non-fitting operand, return `int_arith_invalid()` (distinct from
  `int_arith_overflow`, which means the *operation* overflowed) so callers can
  emit an internal-error-grade diagnostic rather than a user-facing overflow.
- Leave the arithmetic itself byte-identical for operands that do fit. **No
  behavior change for any call site that already passes canonical operands.**

That last point is the fixpoint-safety property and must be verified, not
assumed: `Overflow.w` is reached by Sema, the comptime evaluator, and both
codegens.

**Acceptance:** every silent case in S0 becomes a diagnostic; no correct
program changes behavior; full battery green.

> After S1 the bug is loud but not fixed — `3000000001i64 + 0i64` errors instead
> of returning a wrong number. That is a shippable intermediate state under the
> governing rule, and an improvement on silent corruption. It is not the end
> state.

### S2 — L1/L2: seed the width the evaluator is missing (1–2 days)

The mechanism is settled (see "Why the lookup misses — confirmed"), so this
stage builds rather than investigates. Three increments, cheapest first; **S2a
and S2b are compatible and can land together**, and each is independently
shippable.

**S2a — honor literal suffixes.** `ComptimeEval.w:7862`: consult
`self.ast.literal_suffix(node)` → `self.sema.literal_suffix_type(...)` before
falling back. Small, self-evidently correct, and it makes the documented user
workaround behave as users expect. Does not help un-suffixed code.

**S2b — apply declared types at binding sites.** Three edits:

- `eval_fn_symbol_call_values` — coerce each argument to the declared parameter
  type before `bind_value`, reusing the masking in `comptime_bit_result` that
  `apply_implicit_default_return` already applies to returns.
- `eval_let_binding` — resolve the annotation and retype the bound value.
- Tail expressions — use the enclosing fn's return type as demand *before*
  evaluating the body, not only as a post-hoc mask.

Covers most real code. Watch that coercion **masks** rather than silently widens
a value that legitimately overflowed a narrow declared type — that would trade
this bug for a quieter one.

**S2c — structural.** Populate `typed_expr_types` for comptime-reachable bodies
during `prepare_for_comptime_transform` (`Sema.w:6517`) so folding sees checked
types, and carry types across `ct_clone_tree_with_subst` for unrolled bodies.
Fixes the whole class including generic comptime fns and `comptime for`.
Supersedes S2a/S2b. Largest blast radius; needs care about ordering against
declaration collection, and about sema/comptime re-entrancy.

Land S2a+S2b first for the value, then decide whether S2c is worth its cost in
this campaign or belongs to its own issue. **S2c is the only increment that
closes the cloned-node case**, so without it `comptime for` bodies stay broken.

**Acceptance:** the S0 oracle green for all eight integer types; the
`comptime`/runtime divergence in the governing-rule example gone; for S2c, the
unrolled-loop case green too.

### S3 — Make the miss an internal error (½ day)

Once S2 makes the fallback unreachable, a failed lookup becomes a loud internal
compiler error rather than a silent `i32`. This is invariant 1, enforced.

Do this **after** S2, not before — inverting the order turns every currently
working comptime evaluation into an ICE. Note S2a/S2b alone do not make the
lookup reliable for cloned nodes; gate this stage on S2c, or scope the ICE to
node classes S2c covers.

### S4 — Canonical representation (1 day)

Enforce invariant 2 at the constructor. `comptime_value_int` (`ComptimeValue.w:86`)
asserts the payload is canonical in `type_id`:

```
payload == extend(truncate(payload, w, signed), w, signed)
```

With S1 and S2 in place this assertion should never fire; it is the regression
guard that keeps the class closed.

Note `comptime_value_int` already writes `data1: 0` — the second word is
allocated and unused, so the eventual 128-bit widening is a change to the
constructor contract, not to the struct layout.

### S5 — Fixpoint and full battery (½ day)

`with build :fixpoint` — stage2 byte-identical to stage3. `Overflow.w` is shared
across Sema and both codegens, so run fixpoint after S1 **alone**, before
starting S2. Full battery per CONTRIBUTING's "Compiler Changes vs Library
Changes".

---

## Relationship to #914

#914's D4 describes this evaluator as "i64-only", silently narrowing for 128-bit
values, and recommends refusing 128-bit operands with a diagnostic rather than
widening `ComptimeValue`.

Two corrections:

1. The measured boundary is **32 bits**, not 64, and the corruption reaches
   `i64`/`u64` code with no 128-bit involvement.
2. A refusal keyed on the evaluator's own width would be keyed on `32` here, not
   `128`, so it would not fire and these expressions would still be corrupted.

The recommendation itself remains sound as a stopgap for #914's scope. But under
invariant 2, a canonical 128-bit value cannot live in an `i64` payload, so
widening is eventually **forced**, not optional. Worth a line in D4 so the
refusal is not recorded as the intended end state.

This plan should land first; #914's D4 then reduces to the widening alone.

---

## Risks

| Risk | Why it bites | Mitigation |
|---|---|---|
| **`Overflow.w` is shared by Sema and both codegens** | S1 touches helpers reached by four subsystems; the i128 plan flags the same hazard for its own `Overflow.w` work. | Additive predicate only; byte-identical behavior for canonical operands; fixpoint after S1 alone before S2 starts. |
| **S1 surfaces latent errors in existing comptime code** | Any std/lib comptime currently relying on the silent truncation begins erroring. | Full battery on S1 in isolation. Treat each new failure as a real bug found, not as S1 regressing — but budget time to triage them. |
| **Sema/comptime re-entrancy in S2c** | Populating `typed_expr_types` during `prepare_for_comptime_transform` runs checking where none ran before, and comptime folding can re-enter sema. | Recursion guard; check the enclosing declaration once rather than per-node; S2a/S2b carry none of this risk, which is why they land first. |
| **S3 before S2** | Turning the fallback into an ICE while lookups still miss breaks every comptime evaluation. | Strict stage ordering; S3 gated on the S0 oracle being green and on S2c for cloned nodes. |
| **Diagnostic quality regression** | The unsigned path's "integer literal does not fit expected type" already points at the wrong thing. | Fix the message in S2 while the code is open; it is pinned by S0 so the change is visible in the diff. |

## Non-goals

No arbitrary-precision comptime integer. Exactness belongs at the literal layer,
where `set_int_literal_exact` / `int_literal_expr_bits` already provide it
correctly including 128-bit and the `2^(bits-1)` MIN case. Pushing exactness into
`ComptimeValue` would make comptime arithmetic succeed where the same expression
overflows at runtime — the divergence this plan exists to remove, promoted to a
design.

No tagged union over integer widths. That would put width in two places
(`type_id` and the active variant) and make the ill-typed state representable
again in a new shape.

No 128-bit widening here; that stays with #914.

## Estimate

4–7 working days for S0–S5, plus a fixpoint cycle after S1 and after S2. S2
dominates the variance: S2a+S2b are ~1 day and well understood; S2c is the
open-ended one and may warrant its own issue.

## Build environment

Resolved. Follow `docs/with-bootstrap-runbook.md` → **Path A**, with one
deviation: `with build :deps` failed here with

```
error: deps: could not find a release containing asset
       'with-llvm-sdk-22.1.6-darwin-aarch64.tar.gz'
```

even though the asset is published on `v0.15.1.7` and every nightly. The
documented escape hatch is `WITH_LLVM_SDK_VERSION=<tag> with build :deps`;
fetching the asset by hand and extracting into `.deps/` also works, since the
tarball's top-level directory is already `llvm-22.1.6-darwin-arm64` as
`BuildGraphTools.w:58` expects. Note the asset name says `aarch64` while the
directory says `arm64`. Root cause of the `:deps` failure is not established —
the release-lookup parser works on the live API response when simulated, so do
not assume it is the culprit.

With the SDK in `.deps/` and `LLVM_PREFIX` / `WITH_LIBCLANG` / `SDKROOT` set,
the full Path A chain passes on `22e534c6`:

```
with build            → all targets green, v0.15.1.7-g22e534c6c
with build :fixpoint  → FIXPOINT (stage2 byte-identical to stage3)
with build :test      → all green, 35 targets, 618s, 0 failures
otool -L out/release/bin/with | grep -iE 'clang|LLVM'  → no dynamic dependency
```

All three symptom classes reproduce on that build, so this plan is validated
against a compiler built from the commit it targets.

## Status

Branch `issue943`. All commits gate-verified: `:fixpoint` FIXPOINT and the full
`:test` suite green, every target re-run rather than cached.

- **S0 — done** (`b236f1b6`). Three behavior files carrying the four-term
  oracle, plus two compile_errors fixtures pinning the then-current
  diagnostics. The fixtures were deleted and their cases promoted once the
  errors stopped firing, exactly as their own comments instructed.

- **S2 — done**, in four commits. It took more sites than the stage predicted,
  because the same defect was independently re-implemented by every consumer of
  a typed integer payload:

  | commit | sites |
  |---|---|
  | `f668e4f1` | literal type from suffix + sema's value-based default; local `let`/`var` annotation applied at binding |
  | `ff07cf5e` | value write-back to the AST (`ct_build_value_tree`); unsigned `OP_DIV`/`OP_MOD`; unsigned ordering `< > <= >=` |
  | `4c6f87e5` | negated literals in comptime, via `int_literal_expr_bits` on the unary node |
  | `ff201949` | #914 D2 — sema `check_unary` + the negation-aware fit check + both MIR lowering paths |

  Nine sites in total. Every one had narrowed or re-interpreted a payload before
  measuring it.

- **S3 (miss → internal error) — not done, and now lower value.** S2 fixed the
  width resolution rather than making the lookup reliable, so the fallback is
  still reachable in principle. S4 below is the stronger guard and lands first.

- **S4 — done in part.** `checked_int_value` in `ComptimeEval.w` asserts the
  payload is canonical in its own `type_id` and aborts with a `BUG:` diagnostic
  otherwise, matching the `ast_pool_phase_bug` idiom.

  **Partial by choice:** 25 of 102 `comptime_value_int` call sites are routed
  through it — the 21 that build computed arithmetic results plus the literal
  and annotation constructions. Those are where every defect in this campaign
  originated. The remaining 77 construct trivially canonical values
  (`comptime_value_int(ty_i32, 0)` and similar), and mechanical edits at that
  scale in a self-hosting compiler cost more risk than the coverage is worth.
  Anyone extending this should convert the rest rather than assume it is total.

- **S1 — deliberately not done.** See "S1 reassessed" below.

- **S5 — standing.** Every commit above ran `:fixpoint` and the full suite.

### S1 reassessed

S1's value was converting silent corruption into loud errors *while the width
bug was live*, which is why it was ordered first. That rationale is gone: S2
fixed the widths, so S1 now changes no observable behavior — its own acceptance
criterion says as much ("no behavior change for any call site that already
passes canonical operands"). Against that it touches six helpers on a path
reached by Sema, the comptime evaluator, and both codegens: the largest blast
radius left, for no measurable gain.

The decisive evidence is a bug made during this campaign. The `4c6f87e5` fix
stored `0x80000001` into an `i64` payload typed `i32` without sign-extending,
and `-2147483647i32 / 3` silently returned `+715827883`. It was caught by a
differential test that happened to include negative-operand division.

**S1 would not have caught it** — the corruption surfaced through `OP_DIV`,
which computes `lv / rv` directly and never enters the helpers S1 modifies.
**S4 catches it at construction**, before the value reaches any operator, along
with the original `(i32, 3000000001)` defect.

S4 is strictly upstream: every case S1 could see must pass through the
constructor first, plus cases S1 structurally cannot see. Recommendation: leave
S1 undone, and fold it into #914's word-pair work on `Overflow.w`, where the
file is open anyway and the change is close to free.
