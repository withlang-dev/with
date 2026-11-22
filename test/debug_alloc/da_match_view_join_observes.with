//! expect-debug-alloc: leak count=0
//! expect-stdout: 1 1
// D22 §8 / D144: `let cells = match row: .Arr(items) => items` over an
// owned local joins a pattern-bound view; nothing demands an owned result,
// so `cells` observes `row`. The arm's tail was read after its scope was
// popped, the view went unseen, and the join copied the list into a second
// owner (double free). `if let` the same.
enum PlVal:
    Str(s: str)
    Arr(items: List[PlVal])

fn main:
    let row = PlVal.Arr([PlVal.Str("a heap string long enough to be counted".replace("x", "y"))])
    let cells = match row:
        .Arr(items) => items
        _ => return
    let again = if let .Arr(items) = row: items else: return
    print(f"{cells.len()} {again.len()}")
