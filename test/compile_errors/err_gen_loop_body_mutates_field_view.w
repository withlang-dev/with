//! expect-check-fail: cannot mutate `d` while `each_line(…)` is a live view into it

// D69 (§13.4, §21.1, #1734): the generator views the field `d.lines`; the body writing
// that field while the generator iterates it is refused (path-precise: a
// sibling field stays writable, behav_gen_push_view_borrow_disjoint).
type Doc {
    lines: Vec[str],
    title: str,
}

gen fn each_line(lines: &Vec[str]) -> &str:
    for line in lines:
        yield line

fn main:
    var d = Doc { lines: ["a".clone(), "b".clone()], title: "t".clone() }
    for l in each_line(&d.lines):
        d.lines.push(l.clone())
    print(d.lines.len())
