//! expect-stdout: ok
// Spec test: Section 10.5 / 10.7 — sequence / traverse / transpose.

fn maybe_positive(x: i32) -> Option[i32]:
    if x > 0: Some(x) else: None

fn checked_positive(x: i32) -> Result[i32, str]:
    if x > 0: Ok(x) else: Err("negative")

fn assert_vec_123(xs: Vec[i32]):
    assert(xs.len() == 3)
    assert(xs.get(0) == 1)
    assert(xs.get(1) == 2)
    assert(xs.get(2) == 3)

fn test_sequence_option_some:
    let xs: Vec[Option[i32]] = Vec.new()
    xs.push(Some(1))
    xs.push(Some(2))
    xs.push(Some(3))
    assert_vec_123(xs.sequence().unwrap())

fn test_sequence_option_none:
    let xs: Vec[Option[i32]] = Vec.new()
    xs.push(Some(1))
    xs.push(None)
    xs.push(Some(3))
    assert(xs.sequence().is_none())

fn test_sequence_result_ok:
    let xs: Vec[Result[i32, str]] = Vec.new()
    xs.push(Ok(1))
    xs.push(Ok(2))
    xs.push(Ok(3))
    assert_vec_123(xs.sequence().unwrap())

fn test_sequence_result_err:
    let xs: Vec[Result[i32, str]] = Vec.new()
    xs.push(Ok(1))
    xs.push(Err("bad"))
    xs.push(Ok(3))
    match xs.sequence():
        Err(e) => assert(e == "bad")
        Ok(_) => assert(false)

fn test_traverse_option_some:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    assert_vec_123(xs.traverse(x => maybe_positive(x)).unwrap())

fn test_traverse_option_none:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(-2)
    xs.push(3)
    assert(xs.traverse(x => maybe_positive(x)).is_none())

fn test_traverse_result_ok:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    assert_vec_123(xs.traverse(x => checked_positive(x)).unwrap())

fn test_traverse_result_err:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(-2)
    xs.push(3)
    match xs.traverse(x => checked_positive(x)):
        Err(e) => assert(e == "negative")
        Ok(_) => assert(false)

fn test_option_transpose:
    let x: Option[Result[i32, str]] = Some(Ok(5))
    match x.transpose():
        Ok(value) => assert(value.unwrap() == 5)
        Err(_) => assert(false)

    let y: Option[Result[i32, str]] = None
    match y.transpose():
        Ok(value) => assert(value.is_none())
        Err(_) => assert(false)

    let z: Option[Result[i32, str]] = Some(Err("bad"))
    match z.transpose():
        Err(e) => assert(e == "bad")
        Ok(_) => assert(false)

fn test_result_transpose:
    let x: Result[Option[i32], str] = Ok(Some(5))
    match x.transpose():
        Some(value) => assert(value.unwrap() == 5)
        None => assert(false)

    let y: Result[Option[i32], str] = Ok(None)
    assert(y.transpose().is_none())

    let z: Result[Option[i32], str] = Err("bad")
    match z.transpose():
        Some(value) => match value:
            Err(e) => assert(e == "bad")
            Ok(_) => assert(false)
        None => assert(false)

fn main:
    test_sequence_option_some()
    test_sequence_option_none()
    test_sequence_result_ok()
    test_sequence_result_err()
    test_traverse_option_some()
    test_traverse_option_none()
    test_traverse_result_ok()
    test_traverse_result_err()
    test_option_transpose()
    test_result_transpose()
    print("ok")
