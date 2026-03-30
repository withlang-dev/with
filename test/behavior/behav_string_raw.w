//! expect-stdout: ok

// Tests: raw strings (r"...") preserve literal characters.
// No escape processing: \n stays as backslash + n, not newline.
// Braces are literal, not interpolation.

fn test_raw_no_escape_newline:
    let s = r"hello\nworld"
    assert(s.len() == 12)  // \n is 2 chars (backslash + n), not 1 (newline)

fn test_raw_no_escape_tab:
    let s = r"tab\there"
    assert(s.len() == 9)  // \t is 2 chars

fn test_raw_backslash:
    let s = r"back\\slash"
    assert(s.len() == 11)  // \\ is 2 chars, not 1

fn test_raw_backslash_bytes:
    let s = r"hello\nworld"
    // byte 5 should be 92 (backslash), byte 6 should be 110 (n)
    assert(s.byte_at(5) == 92)
    assert(s.byte_at(6) == 110)

fn test_raw_braces_literal:
    let s = r"{not interpolated}"
    assert(s.contains("{"))
    assert(s.contains("}"))

fn test_raw_with_hash:
    let s = r#"she said "hello""#
    assert(s.contains("hello"))

fn test_raw_double_hash:
    let s = r##"has a "# inside"##
    assert(s.contains("#"))

fn test_raw_basic:
    let s = r"abc"
    assert(s.len() == 3)

fn test_raw_empty:
    let s = r""
    assert(s.len() == 0)

fn test_raw_vs_regular:
    let raw = r"line1\nline2"
    let regular = "line1\nline2"
    // Raw: 12 chars (backslash + n literal)
    // Regular: 11 chars (newline escape)
    assert(raw.len() == 12)
    assert(regular.len() == 11)

fn main:
    test_raw_no_escape_newline()
    test_raw_no_escape_tab()
    test_raw_backslash()
    test_raw_backslash_bytes()
    test_raw_braces_literal()
    test_raw_with_hash()
    test_raw_double_hash()
    test_raw_basic()
    test_raw_empty()
    test_raw_vs_regular()
    print("ok")
