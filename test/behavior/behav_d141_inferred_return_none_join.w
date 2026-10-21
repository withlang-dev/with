//! expect-stdout: 5 0 6 0 7 0

// D141: where a return type is inferred, branches of type T and None join
// to Option[T] — an explicit `return None` beside a tail, beside another
// return, and if-arms.
fn tail_after_return(n: i32):
    if n < 0: return None
    n

fn two_returns(n: i32):
    if n < 0: return None
    return n

fn arms(n: i32):
    if n < 0: None else: n

fn main:
    print(f"{tail_after_return(5) ?? 0} {tail_after_return(-1) ?? 0} {two_returns(6) ?? 0} {two_returns(-1) ?? 0} {arms(7) ?? 0} {arms(-1) ?? 0}")
