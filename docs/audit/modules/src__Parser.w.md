# Primary verification — `src/Parser.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `063a5ea2a07ff07c1e1dcf47044bb6c9cbffd2c2c7e372fd7a080f23224d33db`
Source examined: child 1-8215 complete (five reads); primary: precedence
table + climber :3430-3507 (full read), `infix_op` :3529-3573 (full read),
chain-compare desugar :3463-3498 (full read), plus full probe-matrix re-runs below

## Scope examined

Expression/statement grammar, precedence climbing, AST construction, error
recovery, fuzz robustness.

Applicable overview targets examined: T10 (precedence/associativity), T13
(AST layout adherence), T18 (error quality), T23 (recovery silence).

## Behavioral matrix

All 19 probes in `docs/audit/probes/parser/` re-run by primary (`check` rc):
bitwise pair + qq pair + chain/nonassoc/dangling/pipe/qq-prec/big-range/
nodes/recovery/fuzz x6/paren/pat-range/impl-pair — all directions reproduced
exactly (details in PREC-001; fuzz inputs all rc=1 loud except the
Lexer-owned EOF-string case, filed #1005; `t10_chain_cmp` runs rc=0;
`t10_nonassoc` errors with exact span).

## PREC-001 — spec §9.9 contradiction (filed #1004)

Classification: **Confirmed spec violation, silent misgrouping; #1004**
Severity: **High** — wrong arithmetic with no diagnostic, normative text contradicted
Confidence: **Very high** (table-vs-code + climbing-direction reads + 4 probes)

1. `|`/`^`/`&` inverted: parser `&`=7/`^`=8/`|`=9 (`:3552-3554`) with
   higher-binds-tighter climbing (`:3436`) vs spec L6/L7/L8. `2|3&5` → 1
   (spec: 3); spec probe panics rc=134, inverted probe passes rc=0.
2. `??` a level looser than `+` (`:3555` vs `:3556-3562`) vs spec
   same-level-Left L10. `Some(10) ?? 2 + 3` → 10 (spec: 13). Right-assoc
   carve-out (`:3436`) unobservable (outcome-associative) — level is the complaint.
3. Range `..` at level 5 is absent from the spec table; pipeline shifted to 6
   (spec L5) — absolute numbers match nowhere above L4.

## Notes (no finding)

- Chain-compare desugar (`1<2<3` → `(1<2) and (2<3)`, temp intro for
  non-trivial shared operands) verified working; `==` non-assoc errors loudly.
- Fuzz battery (garbled/truncated/unclosed-fstr) all loud; the one silent
  fuzz shape (EOF string) belongs to the Lexer (#1005).
