//! expect-check-fail: `List` expects 1 type argument(s), found 2

// A declared generic type takes as many arguments as it declares
// parameters. `HashMap[i32, i32, i32]` was accepted and the map miscompiled
// (`get` found nothing); every surplus argument is refused now.
fn main:
    var xs: List[i32, i32] = []
    xs.push(1)
    print(f"{xs.len()}")
