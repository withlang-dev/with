//! expect-stdout: 42
// §4.1 (#627): a user `type String` shadows the String→str prelude alias.
type String { n: i32 }
fn main:
    let s = String { n: 42 }
    print_i32(s.n)
