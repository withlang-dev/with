//! expect-check-fail: cannot take address of bitpacked field
@[bitpacked]
type F { priority: u4, flags: u4 }
fn main:
    var f = F { priority: 1, flags: 2 }
    let p = &raw const f.priority
    print("no")
