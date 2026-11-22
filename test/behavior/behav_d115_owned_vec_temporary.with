//! expect-stdout: first 1 rest 2 last 4
//! expect-stdout: rest0 2
//! expect-stdout: drop 2
//! expect-stdout: drop 3
//! expect-stdout: drop 1
//! expect-stdout: drop 4
//! expect-stdout: drop 6
//! expect-stdout: head 5
//! expect-stdout: drop 5

// D115 (§9.7): a temporary is owned, so the pattern takes it apart by
// value: each binding owns its element and `rest` is the owned remainder,
// a `List[W]` in the temporary's own buffer. Under a bare `..` the remainder
// drops with the subject at the end of the `let`; the bound element lives
// on (it once bound a view into the dropped temporary).
type W { id: i32 }
impl Drop for W:
    move fn drop(): print(f"drop {self.id}")

fn mk() -> List[W]: [W { id: 1 }, W { id: 2 }, W { id: 3 }, W { id: 4 }]
fn pair() -> List[W]: [W { id: 5 }, W { id: 6 }]

fn ends() -> i32:
    let [first, ..rest, last] = mk() else return -1
    print(f"first {first.id} rest {rest.len()} last {last.id}")
    print(f"rest0 {rest[0].id}")
    0

fn head() -> i32:
    let [first, ..] = pair() else return -1
    print(f"head {first.id}")
    0

fn main:
    let _ = ends()
    let _ = head()
