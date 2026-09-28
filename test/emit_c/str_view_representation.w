//! expect-stdout: ell
//! expect-stdout: llo
//! expect-stdout: true false
//! expect-stdout: 3 2
//! expect-stdout: Some(v1) None
//! expect-stdout: v1 dflt
//! expect-stdout: k=a v=x
//! expect-stdout: joined he-o

// #1810: a `&str` is its own `{ptr, len}` view, in the C backend exactly as
// in the LLVM backend (D71 §4.8a). A range view returned from a function
// carries only its parameter's origin; a view is passed by value to the
// runtime's `_ref` seams (print, compare, concat, contains) and to a
// c_imported `const char *` (D47 lends a NUL-terminated copy — a range view
// is not terminated at its end); an Option[&str] from a map lookup is a
// tagged Option whose Some holds the view.

use std.collections.HashMap
use c_import("unsigned long strlen(const char *s);\n")

fn mid(s: &str) -> &str: s[1..s.len() - 1]
fn tail(s: &str) -> &str:
    let t = s[2..]
    t

fn main:
    let h = "hello"
    print(mid(h)[..3])
    print(tail(h))
    let v = mid(h)
    print(f"{v == "ell"} {v.contains("x")}")
    print(f"{strlen(v)} {strlen(v[1..3])}")
    var m: HashMap[i32, str] = HashMap.new()
    m.insert(1, "v1")
    print(f"{m.get(1)} {m.get(2)}")
    let d: &str = "dflt"
    print(m.get(1).unwrap() ++ " " ++ (m.get(2) ?? d))
    var kv: HashMap[str, str] = HashMap.new()
    kv.insert("a", "x")
    for (k, x) in kv: print(f"k={k} v={x}")
    print("joined " ++ h[..2] ++ "-" ++ h[4..])
