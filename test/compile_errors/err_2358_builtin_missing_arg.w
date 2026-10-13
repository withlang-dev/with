//! expect-error: `push` expects 1 argument(s), found 0

// #2358: a builtin method called with fewer arguments than its declared
// BuiltinSigs row is a diagnostic at the call; it compiled silently before.

fn main:
    var xs: List[i32] = List.new()
    xs.push()
    print(xs.len())
