//! expect-stdout: 5 5 2 2 hello

// #1244 / §3.8: a reference-annotated let over an owned place borrows it
// (auto-referencing, as at a call argument). The place stays live and owned;
// no bytes move, nothing is freed twice.

type Point { x: i32, y: i32 }

fn main:
    let x = "hel" ++ "lo"
    let s: &str = x
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("b".clone())
    let vv: &Vec[str] = v
    let p = Point { x: 1, y: 2 }
    let pr: &Point = p
    print(f"{s.len()} {x.len()} {vv.len()} {v.len()} {x}")
    assert(pr.y == p.y)
