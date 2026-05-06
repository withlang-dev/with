//! expect-check-fail: may outlive its origin

type Box { n: i32 }

fn id_view(x: &Box) -> &Box:
    x

fn leak() -> &Box:
    let s = Box { n: 2 }
    let view = id_view(&s)
    return view

fn main:
    let view = leak()
    assert(view.n == 2)
