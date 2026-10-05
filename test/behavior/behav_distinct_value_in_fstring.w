//! expect-stdout: 1.5 7 ab
// §4.5: a distinct's `.value` has the inner type wherever it is used. MIR
// lowered it as the wrapper's own bytes and kept the wrapper's type, so an
// f-string formatted `t.value` as the wrapper and the compiler stopped with
// "codegen formats type N with no registered `:?` formatter" (found writing
// D97's TotalF64 test; lldb: Codegen.call_debug_formatter reached from
// mir_emit_ext_format_intrinsic_call → coerce_typed_val_to_str).
type Meters = distinct f64
type Count = distinct i32
type Name = distinct str

let m = Meters(1.5)
let c = Count(7)
let n = Name("ab".to_owned())
print(f"{m.value} {c.value} {n.value}")
