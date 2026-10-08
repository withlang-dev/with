//! expect-stdout: 3 2 true 4 ab 9

// #2043 (D65): which intrinsic a builtin method call is (Vec, str, HashMap,
// Option, integer methods) is Sema's record per call and instance
// (method_intrinsic_in_body). Codegen's generic-call path had a second copy
// of the table keyed by the method's spelling, and a third keyed by the
// receiver's LLVM type; both are gone. A generic body exercises the
// per-instance record.
use std.collections.HashMap

fn count_of[T](xs: &Vec[T]) -> i64: xs.len()

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    let words: Vec[str] = ["a", "b"]
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("k", 4)
    let joined = words[0] ++ words[1]
    let o: Option[i32] = Some(9)
    print(f"{count_of(&xs)} {count_of(&words)} {joined.contains(\"b\")} {m.get(\"k\").unwrap()} {joined} {o.unwrap()}")
