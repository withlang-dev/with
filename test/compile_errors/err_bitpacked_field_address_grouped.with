//! expect-check-fail: cannot take address of bitpacked field

@[bitpacked]
type Flags { priority: u4, flags: u4 }

fn main:
    var flags = Flags { priority: 1, flags: 2 }
    let ptr = &raw const (flags.priority)
    print("no")
