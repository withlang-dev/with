//! expect-debug-alloc: leak count=0
//! expect-stdout: 4
//! expect-stdout: xy
//! expect-stdout: zw
//! expect-stdout: 3
// D111: `++` copies each element of a borrowed operand, and an element with
// copy glue of its own (a List of values) takes its glue over the appended
// range. By bits alone `a ++ a` of a List[List[str]] shared each inner
// buffer with no count, and freed it twice.
fn main:
    let a = [["x" ++ "y"], ["z" ++ "w"]]
    let b = a ++ a
    print(b.len())
    print(a[0][0])
    print(b[3][0])
    var c = [["p" ++ ""]]
    c ++= a
    print(c.len())
