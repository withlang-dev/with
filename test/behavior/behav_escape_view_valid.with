//! expect-stdout: ok

type Box { n: i32 }

fn id_view(x: &Box) -> &Box:
    x

fn main:
    let s = Box { n: 5 }
    let view = id_view(&s)
    assert(view.n == 5)
    print("ok")
