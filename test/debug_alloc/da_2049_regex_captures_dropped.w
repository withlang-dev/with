//! expect-debug-alloc: leak count=0
//! expect-stdout: ERROR 42
//! expect-stdout: a1 b2 2
//! expect-stdout: miss
// #2049: a `=~` match's Captures and its `$N` bindings live in the branch
// or loop body they are visible in and drop at its end. Nothing dropped the
// Captures (a leak per match), and the bindings dropped once, at function
// exit — after each loop iteration overwrote them, and on the no-match path
// that never wrote them.
use std.regex

fn main:
    let line = "error 42"
    if line =~ /(?<kind>error|warning) (\d+)/:
        print(f"{$kind.upper()} {$2}")
    let text = "a1 b2"
    var seen = ""
    var count = 0
    while text =~ /([a-z])(\d)/g:
        seen = seen ++ $0 ++ " "
        count += 1
    print(f"{seen}{count}")
    if "zzz" =~ /(\d)/:
        print($1)
    else:
        print("miss")
