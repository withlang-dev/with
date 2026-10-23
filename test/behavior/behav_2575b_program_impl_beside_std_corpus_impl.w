//! expect-stdout: 3
// #2575: the program declares a union and a record named like
// std.engines.mlib.defs's, each with `impl Copy`; its alias over the
// record demands the interface's, whose own `impl Copy` records first.
// The name record is per tier: the program's Copy impl is recorded
// beside std's, and the program's record is Copy by its own union.
pub type m_serial_ll_u = union { pub b: bool = false, pub i: i32 = 0 }
impl Copy for m_serial_ll_u
pub type m_serial_read_s { pub tmp: m_serial_ll_u }
impl Copy for m_serial_read_s
pub type m_serial_read_t = [m_serial_read_s; 1]
fn main:
    let r = m_serial_read_s { tmp: m_serial_ll_u { i: 3 } }
    let t: m_serial_read_t = [r]
    print(t[0].tmp.i)
