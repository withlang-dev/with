//! expect-stdout: ok

// #962's guard rejects only what escapes the statement. A view into a
// temporary used within its own statement is sound, and a view into a named
// collection binds as before.
fn main:
    let line = "x\tdocs"
    assert(line.split("\t")[1] == "docs")
    assert(line.split("\t").get(1) != "x" and line.split("\t")[1].ends_with("cs"))
    let parts = line.split("\t")
    let path = parts[1]
    assert(path == "docs" and path != "x" and not path.ends_with(".md"))
    let owned: str = line.split("\t")[1]
    assert(owned == "docs")
    print("ok")
