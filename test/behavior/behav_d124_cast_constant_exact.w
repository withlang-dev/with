//! expect-stdout: 4294967295 4294967295 1099511627776 18446744073709551615 3 44

// D124 (§4.2.1 rule 7): an untyped constant expression under a cast is
// evaluated exactly, never in isize, and the cast wraps or truncates it as
// at run time; float constants follow the runtime rule.
fn main:
    let minus_one = (0 - 1) as u32
    let max = 4294967295 as u32
    let big = (1 << 40) as u64
    let all = 18446744073709551615 as u64
    let float = 3.7 as i32
    let wrapped = 300 as u8
    print(f"{minus_one} {max} {big} {all} {float} {wrapped}")
