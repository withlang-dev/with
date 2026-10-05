//! expect-debug-alloc: leak count=0
// #2145 (§2.3, §13.1): `names.iter()` over a vector whose elements own
// something yields views. It yielded each element by value, a byte copy
// with a second owner, and every stage that received one (a filter's
// predicate, a map's function, `next()`, `collect`) dropped what `names`
// still owned: a DOUBLE FREE per kept element. Each form below is run
// against the allocator; an owned result is spelled with `clone()`.
enum Token:
    Name(str)
    End

fn a: "A".to_lower()

fn main:
    let names: Vec[str] = [a(), a(), "bc".to_lower()]
    assert((names.iter() |> filter(it.len() > 1) |> count()) == 1)
    assert((names.iter() |> map(it.len()) |> sum()) == 4)
    assert(names.iter() |> any(it == "bc"))
    assert((names.iter() |> take(2) |> count()) == 2)
    let lens = names.iter() |> map(it.len()) |> collect[Vec]()
    assert(lens.len() == 3)
    let kept = names.iter() |> filter(it.len() == 1) |> collect[Vec]()
    assert(kept.len() == 2)
    let owned = names.iter() |> filter(it.len() == 1) |> map(it.clone()) |> collect[Vec]()
    assert(owned.len() == 2)
    let upper = names.iter() |> map(it.to_upper()) |> collect[Vec]()
    assert(upper[2] == "BC")
    var walk = names.iter()
    assert(walk.next().unwrap() == "a")
    var total = 0
    for name in names.iter(): total += name.len() as i32
    assert(total == 4)
    // An element that is an enum with an owned payload.
    let tokens: Vec[Token] = [.Name(a()), .End, .Name("bc".to_lower())]
    let named = tokens.iter() |> filter(match it { .Name(_) => true, _ => false }) |> count()
    assert(named == 2)
    // `names` still owns every element.
    assert(names.len() == 3 and names[2] == "bc")
