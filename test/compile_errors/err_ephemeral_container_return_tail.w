//! expect-check-fail: may outlive its origin
// §5.2 (#625, decisions.md D2): a container that borrows a stack local may not
// ESCAPE by tail-position return — the origin outlives the returned container.
type View ephemeral { p: &i32 }

fn leak() -> List[View]:
    var v = List.new()
    let x = 5
    v.push(View { p: &x })
    v

fn main:
    let _ = leak()
