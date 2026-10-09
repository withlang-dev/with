//! expect-stdout: 4 2 7.5 3
// §4.3c rule 1 (D93): the type a use demands of a literal binding may be
// one first made at the use (`List[f64]`, a `List` of tuples): the binding
// has that type, as it has `List[i32]`.
fn first(pairs: &List[(str, i32)]): pairs[0].1

fn main:
    let xs = [1.5, 2.5]
    let total = xs.iter() |> sum()
    let count = xs.iter() |> count()
    var ys = [3.5]
    ys.push(4.0)
    let pairs = [("a", 3), ("b", 4)]
    print(f"{total} {count} {ys.iter() |> sum()} {first(pairs)}")
