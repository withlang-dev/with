//! expect-stdout: ok

type TailrecExplicitDropGuard { n: i32 }
impl Drop for TailrecExplicitDropGuard:
    fn drop(move self: Self):
        let _ = self.n

@[tailrec]
fn tailrec_after_explicit_drop(n: i32, acc: i32) -> i32:
    if n <= 0:
        return acc
    let guard = TailrecExplicitDropGuard { n }
    drop(guard)
    tailrec_after_explicit_drop(n - 1, acc + n)

fn main:
    assert(tailrec_after_explicit_drop(5, 0) == 15)
    print("ok")
