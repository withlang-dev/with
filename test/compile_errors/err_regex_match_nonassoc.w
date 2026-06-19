//! expect-check-fail: operator '=~' is non-associative; parenthesize the expression

fn main:
    let line = "status=200"
    let _x = line =~ /^status=\d+$/ == true
