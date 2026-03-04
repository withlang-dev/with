// Wave 9: select await tie behavior should be deterministic per compiler.

async fn left -> i32: 1
async fn right -> i32: 2

fn pick -> i32:
    select await:
        a = left() -> a
        b = right() -> b

fn main -> i32:
    let r1 = pick()
    let r2 = pick()
    assert(r1 == r2)
    assert(r1 == 1 or r1 == 2)
    0
