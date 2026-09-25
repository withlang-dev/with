//! expect-stdout: ok
use UnitReturnReview

fn main:
    let inferred = "pub fn work(x: i32): assert(x > 0)\n"
    let explicit = "pub fn work(x: i32) -> Unit: assert(x > 0)\n"
    let additions = added_unit_returns(inferred, explicit)
    assert(additions.len() == 1)
    assert(additions[0] == "fn work ( x : i32 ) -> Unit")
    assert(added_unit_returns(explicit, inferred).len() == 0)
    assert(added_unit_returns(explicit, explicit).len() == 0)
    assert(added_unit_returns(explicit, explicit ++ explicit).len() == 1)
    assert(explicit_unit_returns("// fn fake -> Unit:\nfn f(cb: fn(i32) -> Unit): cb(1)\nlet s = \"fn fake -> Unit:\"\n").len() == 0)
    assert(explicit_unit_returns("fn f[T](\n x: T,\n cb: fn(T) -> Unit\n) -> Unit:\n cb(x)\n").len() == 1)
    assert(explicit_unit_returns("extern fn foreign() -> Unit\nfn Receiver.f() -> Unit: assert(true)\n").len() == 2)
    assert(explicit_unit_returns("fn make() -> fn() -> Unit: handler\n").len() == 0)
    assert(not unit_return_reviewed("", "a.w", additions[0]))
    assert(not unit_return_reviewed("a.w\t" ++ additions[0] ++ "\t   \n", "a.w", additions[0]))
    assert(unit_return_reviewed("a.w\t" ++ additions[0] ++ "\tD43: incompatible branch values are deliberately discarded.\n", "a.w", additions[0]))
    assert(not unit_return_reviewed("b.w\t" ++ additions[0] ++ "\tD43 choice\n", "a.w", additions[0]))
    print("ok")
