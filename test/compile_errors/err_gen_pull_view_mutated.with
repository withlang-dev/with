//! expect-error: cannot mutate `v` while `p` is a live view into it

// D69 (§13.4, #1732): the pulled iterator keeps the generator's views live:
// the viewed place cannot be written while the iterator is.
gen fn lens(lines: &List[str]) -> i64:
    for line in lines:
        yield line.len()

fn main:
    var v: List[str] = ["a".clone(), "c".clone()]
    var p = lens(&v).pull()
    v.push("zz".clone())
    print(p.next().unwrap())
