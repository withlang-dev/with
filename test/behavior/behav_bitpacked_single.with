//! expect-stdout: ok
// §4.3b: a @[bitpacked] struct packs its fields MSB-first into a backing
// integer; field read, backing cast, and mutation round-trip.
@[bitpacked]
type Flags { hi: u4, lo: u4 }
fn main:
    var f = Flags { hi: 0xD, lo: 0xC }
    assert(f.hi == 0xD)
    assert(f.lo == 0xC)
    assert((f as u8) == 0xDC)
    f.lo = 0x3
    assert(f.lo == 0x3)
    assert((f as u8) == 0xD3)
    print("ok")
