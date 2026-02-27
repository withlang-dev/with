// NEGATIVE: dyn Trait with no-self method should be rejected (§11.3)
// Object-safe traits must have a self parameter on all methods
// EXPECT: check fails with object safety error

trait BadTrait =
    fn compute() -> i32

type Thing = { val: i32 }
impl BadTrait for Thing =
    fn compute() -> i32: 42

fn use_dyn(d: dyn BadTrait) -> i32:
    d.compute()

fn main -> i32:
    let t = Thing { val: 42 }
    let r = use_dyn(t)
    println(r)
