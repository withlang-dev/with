// Regression for #306: a type-changing List.map (A -> B) must unify with an
// expected List[B] in return position and annotated-let position, not just when
// let-bound without an expected type. Previously the map closure's parameter
// defaulted to i32, so the mapped element type was wrong (List[i32]/List[U]).

type U { name: str, age: i32 }

// return position, implicit `it`
fn names(v: List[U]) -> List[str]:
    v.map(it.name)

// return position, explicit closure
fn ages(v: List[U]) -> List[i32]:
    v.map(u => u.age)

// annotated let
fn first_name(v: List[U]) -> str:
    var names: List[str] = v.map(it.name)
    // D27: element access observes, remove transfers — the returned str
    // must be owned (the local List dies here; a view would dangle).
    names.remove(0)

// chained off a type-changing map
fn total_age(v: List[U]) -> i32:
    var sum = 0
    for a in v.map(it.age):
        sum = sum + a
    sum

fn make_users() -> List[U]:
    let v: List[U] = List.new()
    v.push(U { name: "ada", age: 36 })
    v.push(U { name: "bob", age: 24 })
    v

fn main:
    let ns = names(make_users())
    assert(ns.len() == 2)
    assert(ns[0] == "ada")
    assert(ns[1] == "bob")

    let ag = ages(make_users())
    assert(ag[0] == 36)
    assert(ag[1] == 24)

    assert(first_name(make_users()) == "ada")
    assert(total_age(make_users()) == 60)
