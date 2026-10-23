//! expect-stdout: 1 16
// #2575: the prelude reaches std.engines.mlib.defs, whose alias
// `multimap_ct = [multimap_s; 1]` is over a record of the corpus's harness
// unit. A program declaring `multimap_s` and `multimap_ct` demands the
// interface alias by name, and its `multimap_s` must be the interface's,
// not the program's (which is refused as invisible from std).
pub type multimap_node_s { pub v: i32 }
pub type multimap_s { pub root: *mut multimap_node_s = null, pub size: i64 = 0 }
pub type multimap_ct = [multimap_s; 1]
fn main:
    let m: multimap_ct = [multimap_s { root: null, size: 1 }]
    print(f"{m[0].size} {sizeof[multimap_s]()}")
