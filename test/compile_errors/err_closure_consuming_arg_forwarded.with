//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): a callable parameter passed on is invoked as often as the
// parameter it reaches. `apply` forwards `f` to `twice`, so a consuming
// closure handed to `apply` runs twice. Before, `apply` counted no call of
// its own and the second call read the move-blanked capture.
// A List capture, not a str: a str capture is copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn twice(f: fn() -> List[Tok]) -> i64:
    let a = f()
    a.len() + f().len()

fn apply(f: fn() -> List[Tok]) -> i64: twice(f)

fn main:
    let s: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }, Tok { id: 3 }]
    print(apply(() => s))
