//! expect-error: unknown method 'map' for type 'List[str]'
//! expect-error: a pipeline iterates it — `xs |> map(…)`
// #2772 (§13.5, D142): a List's adapters are its iterator's. The eager
// List.map this used to reach freed every str element twice.
fn main:
    let ys = "a1 b2".split(" ")
    let xs = ys.map(it.to_owned())
    print(xs.len())
