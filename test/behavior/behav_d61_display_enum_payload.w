//! expect-stdout: ok

// A bare `{expr}` of an enum shows each payload's default display; a
// payload with none of its own (a struct, a collection) shows its `:?` form
// — the one formatter every depth uses (D61), so its strs are quoted.

type Point { label: str, x: i32 }
enum Found:
    At(Point)
    Many(Vec[Point])
    Nowhere

fn check(got: &str, want: &str):
    if got != want:
        print(f"mismatch\n  got:  {got}\n  want: {want}")
        assert(false)

fn main:
    let some: Option[Point] = Some(Point { label: "p\"q", x: 1 })
    check(f"{some}", r#"Some(Point { label: "p\"q", x: 1 })"#)
    let text: Option[str] = Some("plain")
    check(f"{text}", "Some(plain)")
    let at = Found.At(Point { label: "a", x: 2 })
    check(f"{at}", r#"At(Point { label: "a", x: 2 })"#)
    let pts: Vec[Point] = Vec.new()
    pts.push(Point { label: "m", x: 3 })
    let many = Found.Many(pts)
    check(f"{many}", r#"Many([Point { label: "m", x: 3 }])"#)
    check(f"{Found.Nowhere}", "Nowhere")
    print("ok")
