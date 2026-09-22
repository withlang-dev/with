pub type Color { r: u8, g: u8, b: u8, a: u8 }
pub type V2 { x: f32, y: f32 }
pub type V3 { x: f32, y: f32, z: f32 }
pub type V4 { x: f32, y: f32, z: f32, w: f32 }
pub type D2 { a: f64, b: f64 }
pub type IF { i: i32, f: f32 }
pub type DI { d: f64, i: i32 }
pub type L2 { a: i64, b: i64 }
pub type I3 { a: i32, b: i32, c: i32 }
pub type L3 { a: i64, b: i64, c: i64 }
impl Copy for Color
impl Copy for V2
impl Copy for V3
impl Copy for V4
impl Copy for D2
impl Copy for IF
impl Copy for DI
impl Copy for L2
impl Copy for I3
impl Copy for L3
extern fn r_color(v: Color) -> Color
extern fn r_v2(v: V2) -> V2
extern fn r_v3(v: V3) -> V3
extern fn r_v4(v: V4) -> V4
extern fn r_d2(v: D2) -> D2
extern fn r_if(v: IF) -> IF
extern fn r_di(v: DI) -> DI
extern fn r_l2(v: L2) -> L2
extern fn r_i3(v: I3) -> I3
extern fn r_l3(v: L3) -> L3
extern fn spill(a: i64, b: i64, c: i64, d: i64, e: i64, s: L2) -> i32
pub fn use_all(c: Color, a: V2, b: V3, d: V4, e: D2, f: IF, g: DI, h: L2, i: I3, j: L3) -> i32:
    let _ = r_color(c)
    let _ = r_v2(a)
    let _ = r_v3(b)
    let _ = r_v4(d)
    let _ = r_d2(e)
    let _ = r_if(f)
    let _ = r_di(g)
    let _ = r_l2(h)
    let _ = r_i3(i)
    let _ = r_l3(j)
    spill(1, 2, 3, 4, 5, h)
