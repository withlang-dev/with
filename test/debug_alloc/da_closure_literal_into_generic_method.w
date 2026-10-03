//! expect-debug-alloc: leak count=0
//! expect-stdout: apply 9
//! expect-stdout: collect 6 8
//! expect-stdout: take 2

// A closure literal handed to a generic method's by-value `fn` parameter is
// the callee's: Sema's signature consumes it, the specialization drops it at
// its scope exit. The generic-call arm of MIR lowering registered that move
// only for language machinery (`s.spawn(..)`), so a user generic method kept
// the statement temporary's scope-exit drop after `move _t` into the call:
// the capturing closure's environment was freed twice (debug allocator:
// DOUBLE FREE first_drop=__closure_env_drop second_drop=__closure_env_drop),
// and std.generators' `collect` over a stage was the ownership validator's
// "drop of _4 after a path reaching it moved it out"
// (behav_gen_push_generic_and_methods, #1647).
use std.generators.{map, take, collect}

type Holder {
    v: i32,
}

impl Holder:
    fn apply[T](t: T, f: fn(T) -> i32) -> i32:
        f(t) + self.v

gen fn nums() -> i32:
    yield 3
    yield 4
    yield 5

fn main:
    let h = Holder { v: 1 }
    let s = "hello".clone()
    print(f"apply {h.apply(3, move (x: i32) -> i32 => x + s.len() as i32)}")
    let doubled = nums() |> map(p => p * 2) |> take(2) |> collect[Vec]()
    print(f"collect {doubled[0]} {doubled[1]}")
    let firsts = nums() |> take(2) |> collect[Vec]()
    print(f"take {firsts.len()}")
