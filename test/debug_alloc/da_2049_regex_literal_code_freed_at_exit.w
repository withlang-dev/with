//! expect-debug-alloc: leak count=0
//! expect-stdout: 1 miss
//! expect-stdout: a1 b2 2
// #1036/#2049: a regex literal compiles once into a per-site cache; the
// program's exit frees the cached code (pattern and tables). Nothing did:
// each literal site that ran leaked a 256-byte and a 2048-byte block. The
// `$N` bindings and Captures drop with the branch or loop body they belong to.
use std.regex

fn main:
    var first = ""
    if "x1" =~ /(\d)/:
        first = $1
    var second = "miss"
    if "zzz" =~ /(\d)/:
        second = $1
    print(f"{first} {second}")
    var seen = ""
    var count = 0
    while "a1 b2" =~ /([a-z])(\d)/g:
        seen = seen ++ $0 ++ " "
        count += 1
    print(f"{seen}{count}")
