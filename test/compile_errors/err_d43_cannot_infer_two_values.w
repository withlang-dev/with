//! expect-check-fail: cannot infer return type: if arms have types i32 and str

// D43: two different values are an error with or without a demand.

fn f(p: bool):
    if p: 1
    else: "a"

fn main: f(true)
