//! expect-stdout: ok

// Tests: escape sequences in regular strings.
// Verifies the lexer correctly handles backslash escapes without
// confusing them with string terminators.

fn test_escaped_newline:
    let s = "line1\nline2"
    assert(s.len() == 11)

fn test_escaped_tab:
    let s = "col1\tcol2"
    assert(s.len() == 9)

fn test_escaped_backslash:
    let s = "back\\slash"
    assert(s.len() == 10)

fn test_escaped_quote:
    let s = "say \"hello\""
    assert(s.len() == 11)

fn test_escaped_quote_at_end:
    // The \" should not terminate the string
    let s = "end\""
    assert(s.len() == 4)

fn test_escaped_quote_at_start:
    let s = "\"start"
    assert(s.len() == 6)

fn test_multiple_escapes:
    let s = "\"\"\""
    assert(s.len() == 3)

fn test_backslash_before_brace:
    let s = "\\{not interpolated}"
    assert(s.len() == 19)

fn test_carriage_return:
    let s = "cr\rhere"
    assert(s.len() == 7)

fn test_null_escape:
    let s = "null\0here"
    assert(s.len() == 9)

fn test_mixed_escapes:
    let s = "a\nb\tc\\d\"e"
    assert(s.len() == 9)

fn main:
    test_escaped_newline()
    test_escaped_tab()
    test_escaped_backslash()
    test_escaped_quote()
    test_escaped_quote_at_end()
    test_escaped_quote_at_start()
    test_multiple_escapes()
    test_backslash_before_brace()
    test_carriage_return()
    test_null_escape()
    test_mixed_escapes()
    print("ok")
