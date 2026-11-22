//! expect-stdout: vec 3 10 30
//! expect-stdout: strs ab cd
//! expect-stdout: points 2 4
//! expect-stdout: set 3 true false
//! expect-stdout: map 2 1 2
//! expect-stdout: empty 0

// #2017: a collection literal is MirLower's COLLECTION_LITERAL / MAP_LITERAL
// call, which the C backend refused ("emit-c does not support generic
// intrinsic __collection_literal"): the compiler's own C has
// `let get_params: List[i64] = [ptr_ty, ptr_ty, i64_ty]`.

use std.collections

type Point { x: i64, y: i64 }

fn total(v: &List[i64]) -> i64:
    var s: i64 = 0
    for x in v: s = s + x
    s

fn main:
    let base: i64 = 10
    let v: List[i64] = [base, base * 2, base * 3]
    print(f"vec {v.len()} {v[0]} {v[2]}")
    let strs: List[str] = ["a" ++ "b", "cd"]
    print(f"strs {strs[0]} {strs[1]}")
    let points: List[Point] = [Point { x: 1, y: 2 }, Point { x: 3, y: 4 }]
    print(f"points {points.len()} {points[1].y}")
    let set: HashSet[i32] = [1, 2, 3]
    print(f"set {set.len()} {set.contains(2)} {set.contains(5)}")
    let map: HashMap[str, i32] = ["one": 1, "two": 2]
    print(f"map {map.len()} {map.get("one").unwrap()} {map.get("two").unwrap()}")
    let none: List[i64] = []
    print(f"empty {total(&none)}")
