// Regression for #293: comparing a `&str` to a string literal (or another
// `&str`) does a string value compare, not a pointer compare — previously it
// either mis-codegened (icmp ptr vs str) or was rejected by Sema.
fn is_x(k: &str) -> bool: k == "x"
fn eq(a: &str, b: &str) -> bool: a == b
fn ne(s: &str) -> bool: s != "x"
fn main:
    assert(is_x("x"))
    assert(not is_x("y"))
    assert(eq("a", "a"))
    assert(not eq("a", "b"))
    assert(ne("y"))
    assert(not ne("x"))
