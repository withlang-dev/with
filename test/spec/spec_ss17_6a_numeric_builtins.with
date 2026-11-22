//! expect-stdout: smin=3 smax=7 sabs=42 umin=1 umax=4000000000 uabs=4000000000 fmin=2 fmax=7 fabs=3 fma=17
// §17.6a numeric builtins. min/max return the smaller/larger of same-typed
// operands; abs is |x| (identity for unsigned, §17.6a); mul_add is a*b+c.
// Unsigned min/max/abs use unsigned semantics — a value above the signed max
// is not treated as negative (#511).
fn main:
    let s: i32 = -42
    let smn = (3).min(7)
    let smx = (3).max(7)
    let sab = s.abs()
    let a: u32 = 4000000000
    let one: u32 = 1
    let umn = a.min(one)
    let umx = a.max(one)
    let uab = a.abs()
    let x: f64 = 2.0
    let y: f64 = 7.0
    let fmn = x.min(y)
    let fmx = x.max(y)
    let fab = (0.0 - 3.0).abs()
    let fma = (3.0).mul_add(4.0, 5.0)
    print(f"smin={smn} smax={smx} sabs={sab} umin={umn} umax={umx} uabs={uab} fmin={fmn} fmax={fmx} fabs={fab} fma={fma}")
