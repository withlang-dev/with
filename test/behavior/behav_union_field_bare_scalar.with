//! expect-check-fail: a union-typed field requires an explicit member initializer

// §16.4: "Construction requires exactly one field initializer." A bare scalar
// for a union-typed struct field is not a construction form; accepting it
// silently stored the wrong value (#886, the zlib Huffman-table corruption).
type Ufc = union { freq: u16 = 0, code: u16 = 0 }
type Cell { fc: Ufc }
impl Copy for Ufc
impl Copy for Cell
fn main:
    let c = Cell { fc: 12 }
    print(f"{c.fc.freq as i32}")
