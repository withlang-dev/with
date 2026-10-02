//! expect-stdout: ok

fn main:
    let options: Vec[Option[i32]] = Vec.new()
    options.push(Some(1))
    options.push(None)
    assert(options.len() == 2)
    assert(options[1].is_none())
    assert(options.remove(0).unwrap() == 1)

    let results: Vec[Result[i32, str]] = Vec.new()
    results.push(Ok(2))
    results.push(Err("bad"))
    assert(results.len() == 2)
    assert(results[1].is_err())
    assert(results.remove(0).unwrap() == 2)

    print("ok")
