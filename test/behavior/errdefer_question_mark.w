//! expect-stdout: cleanupdone

enum MyResult { Ok(i32) | Err(str) }

fn step1() -> MyResult:
    .Ok(10)

fn step2() -> MyResult:
    .Err("step2-failed")

fn step3() -> MyResult:
    .Ok(30)

fn multi_step() -> MyResult:
    errdefer write("cleanup")
    let a = step1()?
    let b = step2()?
    let c = step3()?
    .Ok(42)

fn main:
    let r = multi_step()
    write("done")
