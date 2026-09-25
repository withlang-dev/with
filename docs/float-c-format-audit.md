# Float formatting and unsigned conversion audit

D68 resolves #1649's default-display choice to C `%g`: six significant
digits, notation chosen after rounding, and fractional trailing zeros removed.
Literal parsing still rounds once directly into the destination float type.

## Exact defects

The fixed formatter converted the integer part to `u64` at `rt_core.w:152`
and computed fractional digits using `frac * scale + 0.5` at line 162
(line numbers before this change). LLDB stopped in that function with
`val=0.125, precision_arg=2`, then `val=1e30, precision_arg=2`.
The disassembly showed the integer conversion and floating multiply/add.
The probe printed `0.13` and `9223372036854775808.07`; C prints `0.12`
and `1000000000000000019884624838656.00` for those binary64 values.

The implementation assumed a bounded integer part and used half-up rounding.
Existing small-value tests did not challenge either assumption. Fixed output
now rounds the exact terminating decimal expansion to the requested decimal
place, with ties to even. Scientific output no longer clamps precision to 18.
Output storage includes the requested precision and the largest binary64
integer part; high precision uses explicitly freed temporary storage.
Obsolete approximate and shortest-display paths are removed.

The same disassembly exposed a separate conversion defect:
`CodegenDispatch.w:3890` selected float-to-integer conversion from
`src_unsigned`. A float source has no integer signedness. For
`fn convert(x: f64) -> u64: x as u64`, the emitted block was:

```llvm
mir.bb0:
  %1 = fptosi double %0 to i64
  ret i64 %1
```

The destination type recorded by Sema now selects `fptoui` or `fptosi`.
A constant-only regression was insufficient: LLVM could optimize the invalid
conversion's poison and erase its assertion. The regression obtains inputs
through `strtod`, then checks f64 conversions to u8/u16/u32/u64, f32
conversions to u32/u64, and a signed control.

## Verification

The direct C oracle covers 592 positive/negative values across the binary64
range, zero, the smallest subnormal, the largest finite value, ties and
rounding-induced notation changes. Each is compared with `snprintf` for
`%g`, `%.30g`, `%.0f`, `%.2f`, `%.30f`, `%.1100f`, `%.30e`, and `%.1100e`.
These comparisons use the default C locale and round-to-nearest environment.
Separate assertions cover general precision zero and precision beyond the
exact expansion, signed padding, and correctly rounded literals.

Local evidence in the float worktree:

- `out/float-fixed-lldb-proof.log`: debugger and instruction evidence.
- `out/c-fixed-before.log`: fixed-rounding regression fails before its fix.
- `out/c-fixed-boundaries.log`, `out/c-fixed-sweep.log`: runtime tests pass.
- `out/c-fixed-sweep-alloc.log`: the same sweep passes, leak count zero.
- `out/float-unsigned-before.ll`: wrong conversion instruction.
- `out/float-unsigned-regression-before.log`: runtime conversion fails.

The combined code at `1012a32b` passed the pinned-seed build, byte-identical
stage2/stage3 fixpoint, drop/move audits, full test suite, test-green,
last-green and user-programs-safe. All 1,290 behavior files reran with a fresh
C-import cache epoch. Evidence: `out/combined-battery.log` and
`out/ready-battery-status.txt` (`all passed`).

The rebuilt compiler also passes the runtime unsigned-cast regression
(`out/float-unsigned-after.log`) and the C comparison sweep under the debug
allocator (`out/c-float-final-sweep-alloc.log`, zero leaks). The literal
regression passes through compiled emit-C output as well as LLVM
(`out/float-literal-c-run.log`), including the f32 double-rounding case.
