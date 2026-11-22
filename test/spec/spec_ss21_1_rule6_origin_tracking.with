//! expect-stdout: ok

type Rule6OkBox { n: i32 }

fn choose_rule6_ok(a: &Rule6OkBox, b: &Rule6OkBox, prefer_a: bool) -> &Rule6OkBox:
    if prefer_a:
        return a
    return b

fn main:
    let a = Rule6OkBox { n: 1 }
    let b = Rule6OkBox { n: 2 }
    let view = choose_rule6_ok(&a, &b, false)
    assert(view.n == 2)
    with Rule6OkBox { n: 3 } as inner:
        let inner_view = choose_rule6_ok(&a, &inner, false)
        assert(inner_view.n == 3)
    print("ok")
