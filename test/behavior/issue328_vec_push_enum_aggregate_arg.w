//! expect-stdout: ok

fn main:
    let options: List[Option[i32]] = List.new()
    options.push(Some(1))
    options.push(None)
    assert(options.len() == 2)
    assert(options[1].is_none())
    assert(options.remove(0).unwrap() == 1)

    let results: List[Result[i32, str]] = List.new()
    results.push(Ok(2))
    results.push(Err("bad"))
    assert(results.len() == 2)
    assert(results[1].is_err())
    assert(results.remove(0).unwrap() == 2)

    print("ok")
