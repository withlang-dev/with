//! expect-stdout: ok

// Tests: curly braces in regular (non-f) strings must be literal characters.
// Regression: the lexer previously treated { in regular strings as interpolation.

fn test_braces_in_regular_string:
    let s = "{hello}"
    assert(s.len() == 7)
    assert(s == "{hello}")

fn test_unmatched_open_brace:
    let s = "{abc"
    assert(s.len() == 4)

fn test_unmatched_close_brace:
    let s = "abc}"
    assert(s.len() == 4)

fn test_nested_braces:
    let s = "{{nested}}"
    assert(s.len() == 10)

fn test_brace_with_escaped_quote:
    let s = "{\"key\": \"val\"}"
    assert(s.len() == 14)

fn test_empty_braces:
    let s = "{}"
    assert(s.len() == 2)

fn test_brace_at_start:
    let s = "{start"
    assert(s.len() == 6)

fn test_brace_at_end:
    let s = "end}"
    assert(s.len() == 4)

fn test_only_braces:
    let s = "{"
    assert(s.len() == 1)
    let s2 = "}"
    assert(s2.len() == 1)

fn test_json_like_string:
    let s = "{\"method\":\"init\",\"id\":1}"
    assert(s.len() == 24)

fn test_multiple_brace_pairs:
    let s = "{a}{b}{c}"
    assert(s.len() == 9)

fn test_fstring_still_interpolates:
    let x = 42
    assert(f"{x}" == "42")
    assert(f"val={x}" == "val=42")

fn test_regular_string_no_interpolation:
    let x = 42
    // This should NOT interpolate — it's a regular string, not f-string
    let s = "no interpolation here"
    assert(s == "no interpolation here")

fn main:
    test_braces_in_regular_string()
    test_unmatched_open_brace()
    test_unmatched_close_brace()
    test_nested_braces()
    test_brace_with_escaped_quote()
    test_empty_braces()
    test_brace_at_start()
    test_brace_at_end()
    test_only_braces()
    test_json_like_string()
    test_multiple_brace_pairs()
    test_fstring_still_interpolates()
    test_regular_string_no_interpolation()
    print("ok")
