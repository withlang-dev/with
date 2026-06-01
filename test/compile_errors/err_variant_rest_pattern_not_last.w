//! expect-error: variant '..' rest pattern must be last

enum Pair { Both(str, str) | Empty }

fn main:
    let p = Pair.Both("a", "b")
    match p:
        .Both(.., "b") => ()
        _ => ()
