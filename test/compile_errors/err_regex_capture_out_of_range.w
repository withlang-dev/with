//! expect-check-fail: undefined variable

fn main:
    if "ab" =~ /(a)(b)/:
        print($3)
