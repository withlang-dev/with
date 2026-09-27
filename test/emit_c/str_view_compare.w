//! expect-stdout: true true false true false true
//! expect-stdout: true false

// #1560: `==`, `!=` and the orderings on `&str` views compare the text
// (§11.7: a view compares the value it observes; only raw pointers compare
// by address). The C backend compared two `&str` operands' addresses.
fn eq(a: &str, b: &str) -> bool: a == b
fn ne(a: &str, b: &str) -> bool: a != b
fn lt(a: &str, b: &str) -> bool: a < b
fn ge(a: &str, b: &str) -> bool: a >= b
fn mixed(a: &str, b: str) -> bool: a == b

fn main:
    let x = "ab"
    let y = "a" ++ "b"
    let z = "b".clone()
    print(f"{eq(x, y)} {x == y} {ne(x, y)} {lt(x, z)} {lt(z, x)} {ge(x, y)}")
    print(f"{mixed(x, y.clone())} {mixed(z, y.clone())}")
