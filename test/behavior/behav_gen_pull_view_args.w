//! expect-stdout: a
//! expect-stdout: c
//! expect-stdout: 1:a 1:c
//! expect-stdout: done

// D69 (§13.4 Pulling, #1732): a generator whose arguments are views may be
// pulled; the pulled iterator is as ephemeral as the generator value and
// steps it while the viewed place is live. Both element shapes: a yielded
// view into the argument, and an owned element computed from it.
use std.task.Pulled

gen fn nonempty(lines: &Vec[str]) -> &str:
    for line in lines:
        if line.len() > 0:
            yield line

gen fn lens(lines: &Vec[str]) -> i64:
    for line in lines:
        if line.len() > 0:
            yield line.len()

fn lockstep[A, B](left: impl Iter[A], right: impl Iter[B]) -> Vec[(A, B)]:
    var l = left
    var r = right
    var out: Vec[(A, B)] = Vec.new()
    while true:
        match l.next():
            None => break
            Some(x) =>
                match r.next():
                    None => break
                    Some(y) => out.push((x, y))
    out

fn main:
    let v: Vec[str] = ["a", "", "c"]
    var p = nonempty(&v).pull()
    print(p.next().unwrap())
    print(p.next().unwrap())
    let pairs = lockstep(lens(&v).pull(), nonempty(&v).pull())
    var out = ""
    for (n, s) in pairs:
        out = if out.len() == 0: f"{n}:{s}" else: out ++ f" {n}:{s}"
    print(out)
    print("done")
