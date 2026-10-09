//! expect-stdout: 4 20 9 3 10 28 5
//! expect-stdout: global 2 3
//! expect-stdout: generic 10 10

// §4.3d (D78, #1874): a vector is an ordinary Copy value — in a List, an
// array, a struct field, an Option, a global — with compound assignment,
// and a generic function may take `Vector[4, T]` for any lane type.
type P { tag: i32, v: f32x4 }

let G = i32x4(1, 2, 3, 4)
var H: i32x4 = 3

fn sum[T](v: Vector[4, T]) -> T: v.reduce_add()

fn main:
    var v = i32x4(1, 2, 3, 4)
    v += i32x4(1, 1, 1, 1)
    v *= 2
    var xs: List[i32x4] = List.new()
    xs.push(v)
    xs.push(v * 2)
    let arr = [v, v + 1]
    let p = P { tag: 1, v: f32x4.splat(3) }
    let o: Option[i32x4] = Some(v)
    let t = o.unwrap()
    print(f"{v[0]} {xs[1][3]} {arr[1][2]} {p.v[1] as i32} {t[3]} {xs[0].reduce_add()} {arr[1].x}")
    print(f"global {G[1]} {H[2]}")
    print(f"generic {sum(i32x4(1, 2, 3, 4))} {sum(f64x4(1, 2, 3, 4)) as i32}")
