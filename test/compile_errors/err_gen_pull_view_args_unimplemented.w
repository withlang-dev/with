//! expect-check-fail: g.pull() of a generator whose arguments are views is not implemented yet (#1732)

// D69 (§13.4 Pulling) allows pulling a generator whose arguments are views;
// the pulled iterator must then be as ephemeral as the generator value.
// Until #1732 lands it is a loud error.
gen fn nonempty(lines: &Vec[str]) -> &str:
    for line in lines:
        if line.len() > 0:
            yield line

fn main:
    let v: Vec[str] = ["a".clone(), "".clone(), "c".clone()]
    var p = nonempty(&v).pull()
    print(p.next().unwrap())
