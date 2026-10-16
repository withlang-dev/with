//! expect-check-fail: view 'x' may outlive its origin 'v'

// #1406: moving the origin of a live joined element view.

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn mkv() -> List[Tok]:
    var v: List[Tok] = List.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn g(c: bool):
    let v = mkv()
    let x = if c: v[0] else: v[1]
    let w = v
    print(x)
    print(w.len())

fn main:
    g(true)
