//! expect-check-fail: cannot mutate `lines` while `each_line(…)` is a live view into it

// D69 (§13.4, §21.1, #1734): a generator holding a view of its argument keeps it live
// for the whole loop over it — the producer is iterating `lines` while the
// body runs — so the body cannot mutate the viewed place.
gen fn each_line(lines: &Vec[str]) -> &str:
    for line in lines:
        yield line

fn main:
    var lines: Vec[str] = ["a".clone(), "b".clone()]
    var n = 0
    for l in each_line(&lines):
        n += 1
        lines.push(f"line {n}")
    print(n)
