//! expect-stdout: 6
//! expect-stdout: 1

// D93 (§4.3c rule 1) in a script: a top-level binding takes its type from
// its uses as a binding in a function does.
fn total(xs: &List[i32]): xs.iter() |> sum()

let xs = [1, 2, 3]
print(total(xs))
var grown = []
grown.push(4)
print(grown.len())
