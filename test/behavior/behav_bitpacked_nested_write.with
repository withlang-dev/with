//! expect-stdout: 2 1
// §4.3b (#635): a nested bitpacked field WRITE (o.inner.a = v) uses the same
// accumulated projection, so it targets the right bits.
@[bitpacked] type Inner { a: u2, b: u2 }
@[bitpacked] type Outer { hi: u4, inner: Inner }
fn main:
    var o = Outer { hi: 0xF, inner: Inner { a: 0, b: 0 } }
    o.inner.a = 2
    o.inner.b = 1
    print(f"{o.inner.a as i32} {o.inner.b as i32}")
