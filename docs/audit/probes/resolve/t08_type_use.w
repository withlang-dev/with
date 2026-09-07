fn foo() -> i32:
    1
type foo {
    x: i32
}
fn make() -> foo:
    foo { x: 1 }
fn main() -> i32:
    let v: foo = make()
    v.x
