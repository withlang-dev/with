//! expect-stdout: 3
//! expect-stdout: 1 2 3
//! expect-stdout: err
// #3051 (§4.3 / D93, §10.7): the demand on a method call is its result's,
// never its receiver's. `[1, 2, 3].traverse(...)` under a
// `Result[List[Tracked], str]` annotation typed the literal by the
// annotation and refused `traverse` "for type Result[isize]".
type Tracked { n: isize }
fn main:
    let r: Result[List[Tracked], str] = [1, 2, 3].traverse(n => Ok(Tracked { n }))
    let items = r.unwrap()
    print(items.len())
    print(f"{items[0].n} {items[1].n} {items[2].n}")
    let bad: Result[List[Tracked], str] = [1, 2, 3].traverse(n => if n == 2: Err("two") else: Ok(Tracked { n }))
    match bad:
        Ok(_) => print("never")
        Err(_) => print("err")
