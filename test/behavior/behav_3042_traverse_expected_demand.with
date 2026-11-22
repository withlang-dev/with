//! expect-stdout: true 6 60
//! expect-stdout: ok

// #3042 (§10.7, D165): `List.traverse` propagates an outer `Option[List[U]]`
// or `Result[List[U], E]` demand as the closure's expected return type so
// return-type-polymorphic expressions (`s.parse()`) infer `U` without ceremony.

fn parse_res[T: Parse](s: &str) -> Result[T, str]:
    let opt: Option[T] = s.parse()
    match opt:
        Some(v) => Ok(v)
        None => Err("bad")

fn main:
    let bad = ["1", "2", "three"]
    let p1: Option[List[i32]] = bad.traverse(s => s.parse())

    let good = ["1", "2", "3"]
    let p2: Option[List[i32]] = good.traverse(s => s.parse())
    let list2 = p2.unwrap()

    let r_good = ["10", "20", "30"]
    let p3: Result[List[i32], str] = r_good.traverse(s => parse_res(s))
    let list3 = p3.unwrap()

    print(f"{p1.is_none()} {list2[0] + list2[1] + list2[2]} {list3[0] + list3[1] + list3[2]}")
    print("ok")
