//! expect-stdout: 2 3
//! expect-stdout: 1
//! expect-stdout: 3 1
//! expect-stdout: drop 1
//! expect-stdout: drop 2
//! expect-stdout: drop 3

// D142 (Eric, 2026-10-22): views of resources stay views, so collecting
// them builds a list of views — an ephemeral `List[&T]` (§22.1 rules 3
// and 7) that lives no longer than what it views. A local may hold one,
// a function may return one over its parameter, and `var vs = []` fed
// resource views is one too.
type Res { n: i32 }
impl Drop for Res:
    move fn drop(): print(f"drop {self.n}")

fn big(xs: &List[Res]) -> List[&Res]:
    xs.iter() |> filter(it.n > 1) |> collect[List]()

fn main:
    let xs = [Res { n: 1 }, Res { n: 2 }, Res { n: 3 }]
    let vs = big(xs)
    print(f"{vs[0].n} {vs[1].n}")
    var picked = []
    for x in xs:
        if x.n == 2: picked.push(x)
    print(f"{picked.len()}")
    let ws: List[&Res] = xs.iter().collect[List]()
    print(f"{ws.len()} {ws[0].n}")
