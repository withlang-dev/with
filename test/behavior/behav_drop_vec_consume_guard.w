//! expect-stdout: ok

// [A5] #607 over-fire guard for the step-2 consume/destructure rejects: they must fire
// ONLY on a by-value List whose elements need drop. The forms below all stay legal:
//   - by-value iteration of a POD-element List (List[i32] is non-drop under the narrow gate)
//   - destructuring a POD-element List field by value
//   - wildcarding a Drop-element List field in a pattern (no move)
// Floor is List[Drop]-blind, so this guards the reject's lower edge explicitly.

use std.builtins.print_i32
type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        ()

type P { nums: List[i32], n: i32 }
type H { items: List[W] }

fn pod_consume_iter() -> i32:
    let ns: List[i32] = List.new()
    ns.push(4)
    ns.push(5)
    var s = 0
    for n in ns:                       // POD List by-value iter — NOT rejected
        s = s + n
    s                                  // 9

fn pod_field_destructure() -> i32:
    let p = P { nums: List.new(), n: 7 }
    p.nums.push(1)
    p.nums.push(2)
    match p:
        P { nums, n } => n + (nums.len() as i32)   // POD List field destructure — NOT rejected; 9

fn wildcard_drop_field() -> i32:
    let h = H { items: List.new() }
    h.items.push(W { tag: 1 })
    match h:
        H { items: _ } => 5            // wildcard the Drop field — NOT rejected (no move)

fn main:
    let a = pod_consume_iter()
    let b = pod_field_destructure()
    let c = wildcard_drop_field()
    if a == 9 and b == 9 and c == 5:
        print("ok")
    else:
        print_i32(a)
