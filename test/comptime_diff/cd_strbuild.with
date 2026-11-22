//! expect-stdout: ok

// Comptime differential: string building and round-trips.

comptime fn build_battery(n: i32) -> str:
    var out = "hdr"
    for i in 0..n:
        out = out ++ "-" ++ if i % 2 == 0: "even" else: "odd"
    let parts = out.split("-")
    var glued = ""
    for i in 0..parts.len() as i32:
        glued = glued ++ parts[i as i64]
    glued.replace("evenodd", "X")

const CT_BUILD: str = comptime build_battery(8)

fn main:
    assert(CT_BUILD == build_battery(8))
    print("ok")
