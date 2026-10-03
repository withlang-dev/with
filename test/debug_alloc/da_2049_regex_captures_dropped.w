//! expect-debug-alloc: leak count=0
//! expect-stdout: hit
//! expect-stdout: miss
// #2049: the Option[Captures] a `=~` condition tests is owned by the
// condition. With a compiled Regex nothing binds captures, and nothing
// dropped it: every match leaked its Captures. (A literal's `$N` bindings and
// Captures are scoped to the branch or loop body; behav_regex_capture_fstring
// and behav_regex_language_semantics validate that in deep-debug-tool-tests.)
use std.regex

fn main:
    let re = Regex.compile("([a-z])(\\d)").unwrap()
    if "a1 b2" =~ re:
        print("hit")
    if "zzz" =~ re:
        print("hit")
    else:
        print("miss")
