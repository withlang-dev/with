# Primary verification — `lib/std/math.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 134 lines (single complete read)

## Scope examined

libm externs (`:9`–`:25`: sqrt/pow/floor/ceil/round/sin/cos/tan/log/
log10/exp/fabs/fmod/asin/acos/atan/atan2 — same symbols LLVM intrinsic
lowering uses; Linux links `-lm`), pure With fns (`:30`–`:57`: generic
`abs`/`min`/`max`/`clamp`, `abs64`/`min64`/`max64`), thin wrappers
`sqrt_f64`…`atan2_f64` (`:62`–`:127`), constants `PI`/`E`/`TAU` (`:130`–
`:134`). Callers: none in-tree — no `use std.math` outside generated
scaffold strings in `src/main.w:644,4330` (test-source templates, not a
real dependency) and `examples/ecs/src/math.w` (a local, unrelated
`math` module: `math.Vec2`/`math.AABB`). No dedicated std.math test
file (`test/behavior/behav_math_ops.w` exercises operators, not this
module).

## Behavioral matrix (all EXECUTED, oracle independent: python3 math)

- `docs/audit/probes/math/probe.w` (stage1 `run`, exit 0): 35 printed values,
  f64 results scaled ×1e9 and truncated to i64. All 35 match the python3
  oracle with |Δ| ≤ 2 (all in fact exact or ±1 libm rounding):
  abs/min/max/clamp incl. boundaries (clamp(1,1,10)=1, clamp(10,1,10)=10,
  below/above), abs64/min64/max64 at ±5e9, sqrt(2)→1414213562,
  pow(2,10)→1024000000000, floor(2.7)→2, ceil(2.1)→3, round(2.5)→3 (C
  half-away-from-zero — oracle used C semantics, not Python banker's),
  sin/cos/tan(0.5), log(E)→1, log10(100)→2, exp(1)→2718281828,
  fabs(−3.5)→3.5, fmod(5.5,2)→1.5, asin/acos(0.5), atan(1), atan2(1,1),
  PI→3141592653, E→2718281828, TAU→6283185307. PASS.
- HELD (not executed): generic `abs`/`min`/`max`/`clamp` at type
  arguments other than i32 (e.g. whether `abs` infers for f64 given the
  `if x < 0` literal) — probed only at i32; the i64 behavior is pinned
  via the `*64` twins instead.

## Findings

None. In-report notes (not filed):
- `round_f64` follows C `round` (half away from zero: 2.5→3), not Python
  `round` (banker's: 2.5→2). Verified value, C-consistent; callers
  porting Python numeric code should note it.
- `atan2_f64(y, x)` keeps C argument order; `log_f64` is natural log
  (`log10_f64` is the base-10 one). Both match the doc comments.
- The module is currently uncalled by the compiler/stdlib (surface
  exists for user programs; linking is the user's `-lm` on Linux per
  the header comment).

Verdict: COMPLETE
