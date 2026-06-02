//! expect-stdout: ok

fn main:
    let options: Vec[Option[i32]] = Vec.new()
    options.push(Some(1))
    options.push(None)
    assert(options.len() == 2)
    assert(options.get(0).unwrap() == 1)
    assert(options.get(1).is_none())

    let results: Vec[Result[i32, str]] = Vec.new()
    results.push(Ok(2))
    results.push(Err("bad"))
    assert(results.len() == 2)
    assert(results.get(0).unwrap() == 2)
    assert(results.get(1).is_err())

    print("ok")
