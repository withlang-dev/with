//! expect-check-fail: consumes 'b' but returns a view derived from it
//! expect-check-fail: take 'b: &Buf'

type Buf {
    data: i32,
}

fn first_view(b: Buf) -> &i32:
    &b.data

fn main:
    let b = Buf { data: 1 }
    let _v = first_view(b)
