//! expect-check-fail: consumes 'b' but returns a view derived from it
//! expect-check-fail: returned view is derived from 'b' here

type Inner {
    data: i32,
}

type Buf {
    inner: Inner,
}

fn nested_view(b: Buf) -> &i32:
    &b.inner.data

fn main:
    let b = Buf { inner: Inner { data: 1 } }
    let _v = nested_view(b)
