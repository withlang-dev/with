//! expect-stdout: 65 ab ab
//! expect-stdout: 3 ab

// D111, §4.3a: `[s; N]` with `s: &str` under a `[str; N]` demand fills N
// owned strs, each a copy with its own hold. The element type decides the
// fill, not the spelled value's (`&str` is plain bits; the str it copies
// is not): the one-evaluation fill put one str in every slot with no holds.
fn fills(s: &str):
    let wide: [str; 65] = [s; 65]
    print(f"{wide.len()} {wide[0]} {wide[64]}")
    let small: [str; 3] = [s; 3]
    print(f"{small.len()} {small[2]}")

fn main:
    fills("a" ++ "b")
