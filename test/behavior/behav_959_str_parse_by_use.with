//! expect-stdout: 13 7 -128 255 1.5 42
//! expect-stdout: true true true true true
// #959: `str.parse()` takes its type from its use: a typed binding, or `??`
// against a typed binding. None unless the whole text is one
// value of that type. There was no parse method at all ("unknown method
// 'parse' for type '&str'"), so a field could not become a number.
fn main:
    let f = "a 12 b".fields()
    let n: i64 = f[1].parse() ?? 0
    let small: u8 = "7".parse() ?? 0
    let lo: i8 = "-128".parse() ?? 0
    let top: u8 = "255".parse() ?? 0
    let x: f64 = "1.5".parse() ?? 0.0
    var total: i64 = 0
    for w in "40 x 2".fields():
        let v: i64 = w.parse() ?? 0
        total = total + v
    print(f"{n + 1} {small} {lo} {top} {x} {total}")
    let over: Option[i8] = "128".parse()
    let junk: Option[i64] = "12x".parse()
    let negative: Option[u32] = "-1".parse()
    let empty: Option[i32] = "".parse()
    let two_points: Option[f64] = "1.5.2".parse()
    print(f"{over.is_none()} {junk.is_none()} {negative.is_none()} {empty.is_none()} {two_points.is_none()}")
