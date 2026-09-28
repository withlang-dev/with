//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): a callable parameter passed on is invoked as often as the
// parameter it reaches. `apply` forwards `f` to `twice`, so a consuming
// closure handed to `apply` runs twice. Before, `apply` counted no call of
// its own and the second call read the move-blanked capture.
fn twice(f: fn() -> str) -> str:
    let a = f()
    a ++ f()

fn apply(f: fn() -> str) -> str: twice(f)

fn main:
    let s = "abc".clone()
    print(apply(() => s))
