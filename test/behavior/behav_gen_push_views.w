//! expect-stdout: item-0 item-1 item-2
//! expect-stdout: alpha gamma
//! expect-stdout: 3
//! expect-stdout: kept item-1

// D69 (§13.4): the consumer's body runs while the generator's frame is live,
// so a generator may yield a view of its own locals, or of what its
// arguments view; keeping an element is spelled `.clone()`.
gen fn labels(count: i32) -> &str:
    var buf = ""
    for i in 0..count:
        buf = f"item-{i}"
        yield &buf

gen fn nonempty(lines: &Vec[str]) -> &str:
    for line in lines:
        if line.len() > 0:
            yield line

type Point {
    x: i32,
    y: i32,
}

gen fn points(n: i32) -> &Point:
    var p = Point { x: 0, y: 0 }
    for i in 0..n:
        p.x = i
        p.y = i * 2
        yield &p

fn main:
    var out = ""
    for s in labels(3):
        out = out ++ (if out.len() > 0: " " else: "") ++ s
    print(out)
    let lines: Vec[str] = ["alpha".clone(), "".clone(), "gamma".clone()]
    var joined = ""
    for line in nonempty(&lines):
        joined = joined ++ (if joined.len() > 0: " " else: "") ++ line
    print(joined)
    var ysum = 0
    for p in points(3):
        ysum += p.y - p.x
    print(ysum)
    var kept = ""
    for s in labels(3):
        if s == "item-1":
            kept = s.clone()
    print("kept " ++ kept)
