// .audit/probes/rt_core/t15_foundations.w
// T15: exercise runtime foundations linked from rt_core.w:
// alloc/free (Vec churn), string helpers (concat/eq/len),
// int helpers (to_str), ewrite.
use std.builtins.ewrite
fn main:
    var v: Vec[i64] = Vec.new()
    var i: i64 = 0
    while i < 100:
        v.push(i * 2)
        i = i + 1
    var total: i64 = 0
    for x in v:
        total = total + x
    if total != 9900:
        ewrite("FAIL vec total\n")
    let s = "ab" ++ "cd"
    if s != "abcd":
        ewrite("FAIL concat\n")
    if s.len() != 4:
        ewrite("FAIL len\n")
    let f = (42 as i64).to_string()
    if f != "42":
        ewrite("FAIL fmt\n")
    ewrite("t15-ok\n")
    print("t15-ok total=${total} s=${s} f=${f}")
