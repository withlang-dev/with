//! expect-stdout: 2 1 2 249
// §4.3b (#635): a nested bitpacked chained read (o.inner.a) must accumulate the
// outer+inner bit offsets against the shared backing integer. Was 3 3 2 249.
@[bitpacked] type Inner { a: u2, b: u2 }
@[bitpacked] type Outer { hi: u4, inner: Inner }
fn main:
    let o = Outer { hi: 0xF, inner: Inner { a: 2, b: 1 } }
    print(f"{o.inner.a as i32} {o.inner.b as i32} {(o.inner).a as i32} {(o as u8) as i32}")
