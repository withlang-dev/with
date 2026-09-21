//! expect-check-fail: returns a view into a temporary `Vec[str]` that is freed when this statement ends

fn second(line: &str) -> &str: line.split("\t")[1]

fn main:
    print(second("x\tdocs"))
