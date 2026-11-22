//! expect-stdout: 1
//! expect-stdout: cos
//! expect-stdout: 2
// A block tail that reads through an element place of a local the block
// drops (`let t = table(); t[id].arity`) reads before the scope-exit drop.
// Before the fix the drop was scheduled first and the read saw the freed
// List ("index out of bounds").

type Row { name: str, arity: i32 }

fn table() -> List[Row]:
    let t: List[Row] = List.new()
    t.push(Row { name: "sin", arity: 1 })
    t.push(Row { name: "cos", arity: 2 })
    t

fn arity_tail(id: i32) -> i32:
    let t = table()
    t[id].arity

fn name_tail(id: i32) -> str:
    let t = table()
    t[id].name

fn main:
    print(arity_tail(0))
    print(name_tail(1))
    print(arity_tail(1))
