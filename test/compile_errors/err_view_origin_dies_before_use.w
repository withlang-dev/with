//! expect-check-fail: may originate from

type Rule6Box { n: i32 }

fn choose_view(a: &Rule6Box, b: &Rule6Box, prefer_a: bool) -> &Rule6Box:
    if prefer_a:
        return a
    return b

fn main:
    let a = Rule6Box { n: 1 }
    var view = choose_view(&a, &a, true)
    with Rule6Box { n: 2 } as b:
        view = choose_view(&a, &b, false)
    assert(view.n == 2)
