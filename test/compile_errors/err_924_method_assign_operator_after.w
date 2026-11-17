//! expect-check-fail: only method calls follow `.=`: write the assignment out, `x = x.f(args)` and the rest

// #924 (§4.2.5): only method calls follow `.=`. An operator after the
// call is refused.
fn main:
    var line = " a "
    line .= trim() ++ "!"
    print(line)
