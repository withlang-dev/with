//! expect-error: wrong argument type in call to 'str.contains'
// #2326: a closure is not a `&str` needle. Sema accepted any function
// value where any reference was demanded (types_compatible_fast), so
// this reached codegen and aborted: "BUG: a `&str` runtime argument is
// not a str value".
fn main:
    let s = "xa(y"
    print(s.contains(c => c == 97u8))
