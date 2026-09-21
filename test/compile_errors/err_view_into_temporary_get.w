//! expect-check-fail: binds a view into a temporary `Vec[str]` that is freed when this statement ends

fn main:
    let line = "x\tdocs"
    let path = line.split("\t").get(1)
    print(path)
