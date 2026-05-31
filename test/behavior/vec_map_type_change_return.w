// Regression for #306: a type-changing Vec.map (A -> B) must unify with an
// expected Vec[B] in return position and annotated-let position, not just when
// let-bound without an expected type. Previously the map closure's parameter
// defaulted to i32, so the mapped element type was wrong (Vec[i32]/Vec[U]).

type U { name: str, age: i32 }

// return position, implicit `it`
fn names(v: Vec[U]) -> Vec[str]:
    v.map(it.name)

// return position, explicit closure
fn ages(v: Vec[U]) -> Vec[i32]:
    v.map(u => u.age)

// annotated let
fn first_name(v: Vec[U]) -> str:
    let names: Vec[str] = v.map(it.name)
    names.get(0)

// chained off a type-changing map
fn total_age(v: Vec[U]) -> i32:
    var sum = 0
    for a in v.map(it.age):
        sum = sum + a
    sum

fn main:
    let v: Vec[U] = Vec.new()
    v.push(U { name: "ada", age: 36 })
    v.push(U { name: "bob", age: 24 })

    let ns = names(v)
    assert(ns.len() == 2)
    assert(ns.get(0) == "ada")
    assert(ns.get(1) == "bob")

    let ag = ages(v)
    assert(ag.get(0) == 36)
    assert(ag.get(1) == 24)

    assert(first_name(v) == "ada")
    assert(total_age(v) == 60)
