//! check-only
//! args: --emit-c --bundle-corpus std/re

// D39 §3.4 / #955: the emit-C lane compiles a bundle corpus in-unit. The
// corpus's body-only imports (pcre2's `use std.libc`, which declares the
// `stderr` global) are the corpus's own business: a program that reaches the
// corpus only through std.regex may name a local `stderr`, exactly as it
// can when the corpus arrives as a .wi (whose sections carry no std.libc).
// (`check-only`: the runner's native run path applies only the args it
// knows; `check` takes every header arg.)
use std.regex

fn main:
    let stderr = "captured"
    print(stderr ++ " " ++ (if Regex.compile("a+").is_ok(): "ok" else: "no"))
