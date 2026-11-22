//! expect-stdout: ok

use std.regex

fn test_direct_positive_if_captures:
    let line = "[WARN] status=200"
    var got = ""
    if line =~ /^\[(?<level>ERROR|WARN)\]\s+status=(\d+)$/:
        got = f"{$0}|{$level}|{$2}"
    else:
        got = "missing"
    assert(got == "[WARN] status=200|WARN|200")

fn test_nested_if_for_compound_capture_use:
    let line = "status=503"
    let ready = true
    var got = ""
    if ready:
        if line =~ /^status=(\d+)$/:
            got = $1
    assert(got == "503")

fn test_match_precedence_with_parentheses:
    let line = "status=200"
    let values = [1, 2, 3]
    assert((line =~ /^status=\d+$/) == true)
    assert((line !~ /debug/) == true)
    assert((1 in values) == true)
    assert((line =~ /^status=\d+$/) and (line !~ /debug/))

fn test_regex_value_match_is_boolean:
    let r = /^status=\d+$/
    let line = "status=200"
    assert(line =~ r)
    assert(line !~ /debug/)

fn main:
    test_direct_positive_if_captures()
    test_nested_if_for_compound_capture_use()
    test_match_precedence_with_parentheses()
    test_regex_value_match_is_boolean()
    print("ok")
