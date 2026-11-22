//! expect-stdout: some_int=Some(2)
//! expect-stdout: none_int=None
//! expect-stdout: some_str=Some(hi)
//! expect-stdout: debug=Some(2)
//! expect-stdout: lookup=Some(7)
//! expect-stdout: missing=None

// An Option[&T] is a nullable pointer (D22 niche representation), not a
// tag + payload struct. Formatting one used to walk the struct that is
// not there and crash the compiler (LLVMTypeOf on a null payload).

use std.collections.HashMap

fn main:
    let v: i32 = 2
    let some_int: Option[&i32] = Option.Some(&v)
    let none_int: Option[&i32] = None
    print(f"some_int={some_int}")
    print(f"none_int={none_int}")
    let s = "hi"
    let some_str: Option[&str] = Option.Some(&s)
    print(f"some_str={some_str}")
    print(f"debug={some_int:?}")
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("k", 7)
    print(f"lookup={m.get("k")}")
    print(f"missing={m.get("z")}")
