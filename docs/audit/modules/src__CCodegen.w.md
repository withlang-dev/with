# Primary verification — `src/CCodegen.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `d079d554867a3e5505e40c4de8b43fa984534a482484d73e276f54e8d4c3d491`
Source examined: child 1-9613 complete; primary: `emit_builtin_numeric_call_term`
ROTATE/SWAP/POPCOUNT/CLZ/CTZ/BITREVERSE arms (full read), width-dispatch
absence (grep-verified), fresh `--emit-c` emission + LLVM-run control +
C-level value proof, plus enum-repro confirmation below

## Scope examined

C emission: builtins, enums, externs, prelude interplay.

Applicable overview targets examined: T2-3 (emission correctness), T13
(coverage), T23 (silent wrong code).

## Behavioral matrix

- `rotate64_probe.w`: LLVM `run` → `rot=2 rot-ok swap=281474976710656`
  rc=0 (correct); fresh `build --emit-c` line 7736 emits the 32-bit rotate
  for the i64 operand (primary emission).
- `rot_demo.c` (preserved): exact emitted expression on `(1<<33)|3` gives 6
  vs correct 17179869190 (`cc -O1`, differing exit). Filed #1006.
- `enumrepr_small.w`: LLVM sizeof=1 vs C sizeof=4 — still reproduces #990
  (dupe, no new filing).

## BIT-001 — 64-bit bit-intrinsics miscompiled (filed #1006)

Classification: **Confirmed silent wrong-codegen (emit-C lane); #1006**
Severity: **High (lane)** — valid C, wrong values, no diagnostic
Confidence: **Very high** (branch + fresh emission + LLVM control + C proof)

Six intrinsics hardcode 32-bit (`uint32_t`/`bswap32`/`popcount`/`? 32`/
`bitreverse32`); `ret_tid` available-but-ignored; no 64-bit path exists.
Same truncation disease as #943 (comptime lane). Lane umbrella #955;
siblings #990/#983/#982 distinct classes.

## Notes (no finding)

- strchr allowlist omission = #955-item3 verbatim (dupe, no filing).
- Enum-repr still-repro noted for #990's owner; no comment posted (repro
  unchanged, no new signal beyond "still").
