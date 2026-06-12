//! expect-check-fail: may originate from

type Rule6SingleBox { n: i32 }

fn id_rule6_view(x: &Rule6SingleBox) -> &Rule6SingleBox:
    x

fn main:
    let outer = Rule6SingleBox { n: 1 }
    var view = id_rule6_view(&outer)
    with Rule6SingleBox { n: 2 } as inner:
        view = id_rule6_view(&inner)
    assert(view.n == 2)
