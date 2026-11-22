//! expect-check-fail: cannot consume read-only view binding `items`
// D22 §8 rule 6: an owned result demanded of a join whose arm is a view of
// a non-Copy payload needs an explicit ownership-producing operation.
enum PlVal:
    Str(s: str)
    Arr(items: List[PlVal])

fn main:
    let row = PlVal.Arr([PlVal.Str("a")])
    let cells: List[PlVal] = match row:
        .Arr(items) => items
        _ => return
    print(cells.len())
