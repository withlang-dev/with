//! expect-stdout: 2 1 3
// §4.3b (#635): three-level nested bitpacked read accumulates all offsets.
@[bitpacked] type L3 { x: u2, y: u2 }
@[bitpacked] type L2 { m: u2, inner: L3 }
@[bitpacked] type L1 { hi: u4, mid: L2 }
fn main:
    let o = L1 { hi: 0xF, mid: L2 { m: 3, inner: L3 { x: 2, y: 1 } } }
    print(f"{o.mid.inner.x as i32} {o.mid.inner.y as i32} {o.mid.m as i32}")
