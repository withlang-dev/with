//! expect-build-fail: Drop local 'guard' is live across the call

type TailrecDropGuard { n: i32 }
impl Drop for TailrecDropGuard:
    fn drop(move self: Self):
        let _ = self.n

@[tailrec]
fn bad_tailrec_drop_live(n: i32) -> i32:
    if n <= 0:
        return 0
    let guard = TailrecDropGuard { n }
    bad_tailrec_drop_live(n - 1)

fn main:
    let _ = bad_tailrec_drop_live(3)
