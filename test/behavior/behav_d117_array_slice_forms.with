//! expect-stdout: 1 3 2
//! expect-stdout: 2 3
//! expect-stdout: 4 6 2
//! expect-stdout: 2 3 1
//! expect-stdout: none 0

// D117 (§9.5, §13.3): first()/last()/rest() on a fixed array and a slice,
// with the List modes: a place observes (Option[&T], a []T view), an owned
// receiver takes (Option[T]; [T; N-1] for a fixed array's rest()).

fn slice_first(s: []i32) -> i32: s.first() ?? &-1
fn slice_rest_len(s: []i32) -> isize: s.rest().len()
fn mk3() -> [i32; 3]: [4, 5, 6]

fn main:
    let a: [i32; 3] = [1, 2, 3]
    let r = a.rest()
    print(f"{a.first() ?? &-1} {a.last() ?? &-1} {r.len()}")

    var b: [i32; 3] = [1, 2, 3]
    let tail: [i32; 2] = (move b).rest()
    print(f"{tail[0]} {tail[1]}")

    var c: [i32; 3] = [4, 5, 6]
    print(f"{(move c).first() ?? -1} {mk3().last() ?? -1} {slice_rest_len(a[0..3])}")

    print(f"{slice_first(a[1..3])} {a[1..3].last() ?? &-1} {a[1..3].rest().len()}")

    let e: [i32; 0] = []
    print(f"{if e.first().is_none(): "none" else: "some"} {e.rest().len()}")
