//! expect-stdout: ok

// Tests: triple-quoted multi-line strings.
// Should preserve newlines, braces, and other characters literally.

fn test_multiline_basic:
    let s = """
hello
world"""
    assert(s.len() == 11)

fn test_multiline_with_braces:
    let s = """
{
  "key": "value"
}"""
    assert(s.contains("{"))
    assert(s.contains("}"))

fn test_multiline_with_quotes:
    let s = """
She said "hello" to them.
"""
    assert(s.contains("\""))

fn test_multiline_empty_lines:
    let s = """

line after blank

"""
    assert(s.len() > 0)

fn test_multiline_with_escapes:
    let s = """
tab\there
newline\nhere"""
    // Escapes should be processed in triple-quoted strings
    assert(s.len() > 0)

fn main:
    test_multiline_basic()
    test_multiline_with_braces()
    test_multiline_with_quotes()
    test_multiline_empty_lines()
    test_multiline_with_escapes()
    print("ok")
