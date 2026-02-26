// Test unit elision: Ok() as shorthand for Ok(())

fn do_work() -> Result[i32, i32] = Ok()

fn do_work2() -> Result[i32, i32] = Ok(0)

fn main() -> i32 =
    let r1 = do_work()
    assert(r1.is_ok())
    let v1 = r1 ?? -1
    assert(v1 == 0)

    let r2 = do_work2()
    assert(r2.is_ok())
    let v2 = r2 ?? -1
    assert(v2 == 0)
    0
