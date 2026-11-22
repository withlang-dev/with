//! args: --validate-all
//! expect-check-stdout: validate-all: ok

enum Kind: i32 { A = 1 | B = 2 }

fn raw_kind() -> i32: Kind.B

fn main:
    var kind = Kind.A
    kind = raw_kind()
    assert(kind == Kind.B)
