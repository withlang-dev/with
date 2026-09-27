//! expect-stdout: 0
//! expect-stdout: 6
//! expect-stdout: drop cap

// A carrier eliminator (`Result.map`, `Option.map`) calls the mapper it
// lowered on one arm only. Lowered as `call move _mapper` it had moved the
// closure out on that arm while the scope-exit drop still ran on every
// path — MaybeMoved to the ownership validator (#1539), a second drop of
// the closure's captures. A call reads its callee, so the mapper's temp
// is dropped exactly once, on both arms.
type Tag:
    name: str

impl Drop for Tag:
    move fn drop(): print("drop " ++ self.name)

fn main:
    let t = Tag { name: "cap" }
    let r: Result[i32, str] = Err("e" ++ "!")
    print(f"{r.map((x) => x + t.name.len() as i32).unwrap_or(0)}")
    let o: Option[i32] = Some(3)
    print(f"{o.map((x) => x + t.name.len() as i32).unwrap_or(0)}")
