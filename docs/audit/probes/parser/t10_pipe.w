// T10: pipelines |> and <|.
fn add1(x: i32) -> i32:
    x + 1

fn main:
    assert((5 |> add1) == 6)
    assert((5 <| add1) == 6)
