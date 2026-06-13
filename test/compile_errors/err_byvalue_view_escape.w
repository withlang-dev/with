//! expect-check-fail: consumes 'a' but returns a view derived from it
//! expect-check-fail: take 'a: &Buf'

type Buf {
    data: i32,
}

fn choose_view(a: Buf, b: Buf, take_a: bool) -> &i32:
    if take_a:
        return &a.data
    return &b.data

fn main:
    let a = Buf { data: 1 }
    let b = Buf { data: 2 }
    let _v = choose_view(a, b, true)
