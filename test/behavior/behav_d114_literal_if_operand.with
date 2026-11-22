//! expect-stdout: 5 3 1

// D114 (§4.2.1 rules 1, 3, 6): an `if` whose arms are all unsuffixed
// literals is an untyped literal operand, so the context reaches its
// literals as it reaches `1 | 2`: a typed field, a typed peer, a typed
// binding. It is not the isize default.
type Fact { flags: i32 }

fn take(x: i32): x

fn main:
    let a = true
    let b = false
    let c = true
    var fact = Fact { flags: 0 }
    fact.flags = (if a: 1 else: 0) | (if b: 2 else: 0) | (if c: 4 else: 0)
    let base: i32 = 1
    let bits: i32 = (if b: 4 else: 2) | (if a: 1 else: 0)
    print(f"{take(fact.flags)} {take(bits)} {take(base & (if a: 1 else: 0))}")
