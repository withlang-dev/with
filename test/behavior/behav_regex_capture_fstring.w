//! expect-stdout: ok

use std.regex

fn test_regex_captures_inside_fstring:
    let line = "error 42"
    var got = ""
    if line =~ /(?<kind>error|warning) (\d+)/:
        got = f"{$kind.upper()} code={$2}"
    assert(got == "ERROR code=42")

fn test_regex_capture_method_call_inside_fstring:
    let line = "email=a@b"
    var got = ""
    if line =~ /email=(?<email>\S+)/:
        got = f"{$email.lower()}"
    assert(got == "a@b")

fn test_regex_escaped_metachar_named_captures:
    let line = "[WARN] slow query"
    var got = ""
    if line =~ /^\[(?<level>ERROR|WARN)\]\s+(?<msg>.*)$/:
        got = f"{$level}: {$msg}"
    assert(got == "WARN: slow query")

fn test_regex_capture_names_match_bindings:
    let re = /^\[(?<level>ERROR|WARN)\]\s+(?<msg>.*)$/
    let names = re.capture_names()
    assert(names.len() == 2)
    assert(names.get(0) == "level")
    assert(names.get(1) == "msg")

    let line = "[ERROR] db timeout"
    var got = ""
    if line =~ /^\[(?<level>ERROR|WARN)\]\s+(?<msg>.*)$/:
        got = f"{$level}:{$msg}"
    assert(got == "ERROR:db timeout")

fn test_regex_escaped_slash_named_capture:
    let line = "path/to/file"
    var got = ""
    if line =~ /^path\/to\/(?<file>\w+)$/:
        got = $file
    assert(got == "file")

fn test_regex_escaped_backslash_named_capture:
    let line = r"C:\temp"
    var got = ""
    if line =~ /^C:\\(?<name>\w+)$/:
        got = $name
    assert(got == "temp")

fn test_regex_hex_escape_named_capture:
    let line = "[ok]"
    var got = ""
    if line =~ /^\x5b(?<value>\w+)\x5d$/:
        got = $value
    assert(got == "ok")

fn test_regex_match_arm_escaped_named_captures:
    let line = "[WARN] slow query"
    let out = match line:
        /^\[(?<level>ERROR|WARN)\]\s+(?<msg>.*)$/ => f"{$level}: {$msg}"
        _ => "missing"
    assert(out == "WARN: slow query")

fn main:
    test_regex_captures_inside_fstring()
    test_regex_capture_method_call_inside_fstring()
    test_regex_escaped_metachar_named_captures()
    test_regex_capture_names_match_bindings()
    test_regex_escaped_slash_named_capture()
    test_regex_escaped_backslash_named_capture()
    test_regex_hex_escape_named_capture()
    test_regex_match_arm_escaped_named_captures()
    print("ok")
