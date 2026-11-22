//! expect-error: returned view may outlive its origin 'm'

// #2271 (D39/D122): a view returned through a callable value originates
// from its view arguments. Before, the call erased the origin and this
// dangling `&str` — a view of the local map `m`, returned after `m` dies —
// compiled.

use std.collections.HashMap

fn first_key(f: fn(&str) -> &str) -> &str:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("a", 1)
    var ks = m.keys()
    let k: &str = ks.next().unwrap()
    f(k)

fn main:
    print(first_key(s => s))
