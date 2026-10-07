# D43 — Unannotated tails infer only when every written arm unifies; a missing arm forces `Unit`; a mixed join of written arms is a failure to infer, not a `Unit` function and not an illegal `if`

**Laws:** 2, 7 (docs/mission.md).

**Date:** 2026-09-18. **Status:** ruled (Eric, "make it so"), implemented.
Specification §9.1 (inferred returns, assignment's type) and the §3.8
cross-reference were blessed verbatim by Eric the same day. Reopen if a real corpus shows the `-> Unit`
annotation on mixed tails is frequent enough to be ceremony rather than a
guardrail. **Issue:** #1178.

**Ruling.** A function or closure with no return annotation infers its
return type from its tail expression. When the tail is a branching
expression (`if`, `if let`, `match`):

- **A missing arm forces `Unit`.** An `if` / `if let` with no final `else`
  (including an `else if` chain with no final `else`), or a partial `match`,
  is never a value: §9.1 already requires `else` in expression position and
  §9.7 already requires an expression-position match to be exhaustive. The
  statement reading is forced by the construct's shape, not by its arm
  types, so the join is `Unit` and the written arms are statements.
  `fn f(p): if p: bump(1)` and `fn g(p): if p: seen = 1` are `Unit`
  functions with no annotation, as today and as §9.7 protects.
- **A written empty arm counts as missing.** `else: {}` and `_ => {}` hold
  no expression; they are the programmer spelling "nothing here". This is
  also what lets a `@[must_use]` subject, which §9.7 requires to carry a
  catch-all, stay annotation-free.
- **When every arm is written and non-empty**, inference succeeds only when
  they unify: the common type if all agree, with `Never`-typed arms
  (`return`, `panic`, diverging calls) joining with anything.
- **Explicit `return e`** on any path must unify with the tail under the
  same rule; a value on one path and fall-off on another remains §4.10's
  missing-return error.
- **Entry points do not infer.** `main` (explicit or implicit), `@[entry]`
  functions and `test_*` functions have return types fixed by the runtime
  contract; their tails are statement position.

"Cannot infer" arises only when every arm is present and they do not
unify. Then the compiler does not infer. It does not pick `Unit`; it does
not pick the first arm; it does not fabricate a value. The `if` is not
illegal — its arms keep their own types — the *question* "what does this
function return?" has two answers, and the diagnostic hands it back:

```
error: cannot infer return type
   fn f(x: bool):
       if x: 1 else: log()
             ^         ^^^^^
   if arms have types i32 and Unit
   add `-> i32` or `-> Unit`
```

For a closure, which has no return-annotation syntax, the diagnostic says
instead to give the closure an expected function type. (Closure return
annotations are a separate feature; D43 does not depend on them.)

Once `->` is present the existing rules apply: `-> i32` makes the tail a
demanded join and the `Unit` arm fails #549 at the arm; `-> Unit` makes the
tail statement position, the arms are two statements, and a discarded call
result is the user's business (§10.1).

**Demanded vs. undemanded.** A join is *demanded* if any enclosing context
supplies an expected type or consumes the value: a `let x: T =`, a `-> T`
tail, an argument position, an arm of an enclosing demanded join, a
contextual join (`resolve_contextual_join`, D22). Demanded joins are
unchanged; every arm is checked against the demand. A join is *undemanded*
only when its result reaches a statement boundary, an unannotated function
tail, or an unannotated closure tail with no contextual expectation. D43
applies only to the undemanded unannotated-tail case. `let y = if x: 1
else: log()` has a demand (the `let` consumes the value) and stays #549.

**Both spellings, one rule.** A single-statement body and a block body
whose last statement is the tail are the same case and get the same answer
(`docs/completed/three-block-types.md`: "Body forms do not affect type
checking, return type inference"). `check_fn_body_with_sig_at` and
`check_block` both ask the tail for its type under this rule and stop; there
is no second join at the function level.

**Context.** With combines three things no reference language combines:
assignment is a value (`a = b = 3`), named functions infer their return,
and statements have no terminator. Three code paths decided "is the tail a
value?" differently: a single-statement body was always a value (mixed arms
rejected), a block tail under an unannotated return was always a statement
(so `fn pick(x): seen = 0; if x: 1 else: 2` lowered as a `Unit` function
with both values dropped while Sema typed the call as printable — garbage
at the caller), and a statement-position match kept its first arm's type
(invalid MIR). `parse_if_let` additionally fabricated `else: 0`. The spec
said an omitted `->` returns `Unit` (§9.1) while §3.8 assumed "an inferred
function return"; neither defined the inference.

**Alternatives rejected.**
- *F — `Unit` absorbs at an undemanded join.* The compiler picks `Unit` for
  the user, the signature becomes a property of whether some reaching arm
  is `Unit`, and the mistake surfaces at a caller.
- *C — the `if` is illegal when arms disagree.* The only fixes for a leg
  are `let _ =` or a terminator, both refused; and `if p: bump(1) else:
  print("no")` mid-block is two statements and must compile.
- *B / E — unannotated means `Unit`; branching tails never infer.* `fn
  sign(x): if x < 0: -1 else: 1` and `fn shout(s: str): s ++ "!"` must
  infer; that is the documented style and one meaning is forced.
- *A least-upper-bound rule.* With has no top type; the join of `i32` and
  `Unit` does not exist.

**Mission fit (mission.md ¶2, refined in the same change).** Mixed written
arms are the case where two meanings remain; the programmer spells the
choice with `->`, a spelling they already own. `sign`, `shout`, and every
missing-arm tail have one forced meaning and stay annotation-free.

**References** (verified in `.reference/`). Rust: assignment is `()`
(`rustc_hir_typeck/src/expr.rs`), an omitted `fn` return is `()`
(`rustc_hir_analysis/src/collect.rs`), `;` discards. Swift: assignment is
`()` (`CSGen.cpp` `visitAssignExpr`); the *declared* result decides whether
a trailing `if`/`switch` is an implicit result, never for `Void`, and never
an assignment (`TypeCheckStmt.cpp` `addImplicitReturnIfNeeded`); an implied
closure result may convert to `Void` (`CSSimplify.cpp`
`getImpliedResultConversionKind`). Zig: statement-`if` is its own grammar
production whose arms are never joined, a return type is mandatory, and an
ignored non-void value is an error. Go: statements only. Mojo: `=` is a
statement, `:=` the expression form; an omitted return is `None`, no
inference. Vale: `set` is a value typed as its destination, like With;
every `if` reconciles its branches; `;` voids a block; a top-level function
with no return is void and only lambdas infer. None of the six has With's
combination. (Scala and Kotlin, from memory and not in `.reference/`: LUB
to a top type, and value-discard when `Unit` is expected.)

**Matrix** (both body spellings agree on every row):

| tail of an unannotated fn | result |
|---|---|
| `if let Some(v) = f(): assert(v == 7)` | missing arm → `Unit` |
| `if let Some(v) = f(): seen = v` | missing arm → `Unit`; no fabricated `0` |
| `if p: seen = 1` / `if p: bump(1)` / `if x: 1` | missing arm → `Unit` |
| `if a: 1 else if b: 2` | missing final arm → `Unit` |
| `match e: A => self.n = 1, B => self.name = "b"` (partial) | missing arm → `Unit` |
| `match e: A => self.n = 1, _ => {}` | empty arm counts as missing → `Unit` |
| `if x: 1 else: log()` | `i32` vs `Unit` → cannot infer |
| `if p: bump(1) else: print("no")` | cannot infer; `-> Unit` accepts |
| `if p: seen = 1 else: assert(p)` | cannot infer (follow-up: assignment as result) |
| `match p: true => seen = 1, false => assert(p)` | cannot infer; no invalid MIR |
| `if x: 1 else: "a"` | cannot infer; with a demand, #549 |
| `if x: 1 else: 2` / `match x: true => 1, false => 2` | `i32` |

**Rollout.** The `else: 0` desugar dies in the same batch (#1179), as do
the garbage return, the invalid MIR, and the silent validator (#1180). Sweep
`src/`, `lib/`, `tools/`, `test/` and the audit-probe generators first: an
unannotated function ending in an else-less `if let` with an assignment
body infers `i32` today (returning the value or a fabricated `0`) and
becomes `Unit`, so a caller consuming it stops compiling; a mixed written
tail becomes "cannot infer" and gets its `->`. **Measured 2026-09-18:**
2,861 files under `lib/`, `tools/`, `test/`, `examples/`, `build/` plus the
compiler source: two functions needed `-> Unit` (`MirCore.mark_place`, a call
arm against an assignment arm; `SemaCheck.demand_generic_iter_next`, `insert`
against `remove`), both in `src/`. That is the data point for the reopen
clause and for the assignment-as-result follow-up (one of the two).

**Follow-ups, not part of the ruling.**
- The demanded-join diagnostic names the `Unit` arm.
- Lint: `pub fn` without `->` (a bundle-interface signature should not
  depend on whether someone added an `else: log()`).
- Lint, scheduled: an effect-free expression in a discarded position
  (`v == 3` alone on a line; the `1` in `fn f(x): if x: 1`). It is the
  guardrail for the missing-arm shape. §10.1's discard rule is untouched.
- Candidate: assignment is never an implicit result (Swift). Decide on the
  sweep's count of `if p: x = 1 else: …` tails.
