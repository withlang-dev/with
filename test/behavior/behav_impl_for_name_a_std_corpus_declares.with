//! expect-stdout: 3 3
// §18.1 (#1457): a program's type is its own even when a standard-library
// corpus declares the same name — pcre2's migrated defs declare `cmdstruct`
// with `impl Copy`. The program's `impl Copy` is the first for ITS type, not
// a duplicate (E1102), and makes it Copy.
type cmdstruct { value: i32 }
impl Copy for cmdstruct

fn take(c: cmdstruct) -> i32: c.value

fn main:
    let c = cmdstruct { value: 3 }
    let a = take(c)
    print(f"{a} {take(c)}")
