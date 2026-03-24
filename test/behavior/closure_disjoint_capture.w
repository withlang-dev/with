//! expect-stdout: 31
type World { x: i32, y: i32 }

fn run_both(f: fn(i32) -> i32, g: fn(i32) -> i32) -> i32: f(0) + g(0)

fn inc(p: &mut i32) -> i32:
    *p = *p + 1
    *p

fn main:
    var w = World { x: 10, y: 20 }
    // Disjoint fields: &mut w.x and &w.y — allowed by field-level capture
    let r = run_both(v => inc(&mut w.x), v => w.y + v)
    print(int_to_string(r) ++ "\n")
