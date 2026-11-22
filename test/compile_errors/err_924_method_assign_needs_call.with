//! expect-check-fail: expected '(' after the method name: `x .= f(args)` assigns `x.f(args)` to `x`

// #924 (§4.2.5): a method assignment names a method call; a bare member is
// not one.
fn main:
    var line = " a "
    line .= len
    print(line)
