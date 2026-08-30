//! expect-stdout: 12 8

// §16.4 conforming form: explicit member initializer per union field.
type Ufc = union { freq: u16 = 0, code: u16 = 0 }
type Udl = union { dad: u16 = 0, len: u16 = 0 }
type Cell { fc: Ufc, dl: Udl }
impl Copy for Ufc
impl Copy for Udl
impl Copy for Cell
fn main:
    let c = Cell { fc: Ufc { freq: 12 }, dl: Udl { dad: 8 } }
    print(f"{c.fc.freq as i32} {c.dl.dad as i32}")
