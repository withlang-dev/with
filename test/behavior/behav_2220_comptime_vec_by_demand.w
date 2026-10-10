//! expect-stdout: 6 4 7
// #2220: a plain function that builds a List runs under comptime when a
// let annotation names the instance. Folding runs before Sema, so the
// evaluator saw only the generic base for `List.new()` and refused; the
// annotation is the demand that binds it (Law 2), through a call too.

fn total(n: i32) -> i32:
    var v: List[i32] = List.new()
    for i in 0..n: v.push(i)
    var s: i32 = 0
    for x in v: s = s + x
    s

fn count(n: i32) -> i32:
    var v: List[i32] = List.new()
    for i in 0..n: v.push(i * 2)
    v.len() as i32

let k = comptime total(4)
let c = comptime count(4)
let b = comptime:
    var v: List[i32] = List.new()
    v.push(3)
    v.push(4)
    v[0] + v[1]
print(f"{k} {c} {b}")
