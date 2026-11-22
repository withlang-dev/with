//! args: --validate-all
//! expect-check-stdout: validate-all: ok

enum Kind: i32 { A = 7 | B = 8 }

fn tag -> i32:
    return Kind.A

fn main:
    assert(tag() == 7)
