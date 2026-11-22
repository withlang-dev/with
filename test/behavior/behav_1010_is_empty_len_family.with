//! expect-stdout: str true false
//! expect-stdout: str ref true false
//! expect-stdout: array false
//! expect-stdout: slice false
//! expect-stdout: map true false
//! expect-stdout: set true false
//! expect-stdout: slotmap true false

// #1010: `is_empty()` on a receiver whose `len()` is an intrinsic (str,
// arrays, slices, HashMap, HashSet, SlotMap) type-checked as bool, then
// aborted the compiler in validate_generic_call_contracts: only List and
// FixedString had an is_empty lowering. It lowers as `len() == 0`.

use std.collections.HashMap
use std.collections.HashSet
use std.collections.SlotMap

fn str_ref_empty(s: &str): s.is_empty()

fn slice_empty(xs: []i32): xs.is_empty()

fn main:
    let e = ""
    let s = "x"
    print(f"str {e.is_empty()} {s.is_empty()}")
    print(f"str ref {str_ref_empty(e)} {str_ref_empty(s)}")
    let a: List[i32] = [1, 2, 3]
    print(f"array {a.is_empty()}")
    print(f"slice {slice_empty(a)}")
    var m: HashMap[i32, i32] = HashMap.new()
    let m0 = m.is_empty()
    m.insert(1, 2)
    print(f"map {m0} {m.is_empty()}")
    var hs: HashSet[i32] = HashSet.new()
    let hs0 = hs.is_empty()
    hs.insert(1)
    print(f"set {hs0} {hs.is_empty()}")
    var sm = SlotMap[i32].new()
    let sm0 = sm.is_empty()
    sm.insert(1)
    print(f"slotmap {sm0} {sm.is_empty()}")
