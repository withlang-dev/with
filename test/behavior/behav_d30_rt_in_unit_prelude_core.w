//! env: WITH_RT_IN_UNIT=1
//! args: --prelude=core
//! expect-stdout: ok

// D30 R3: the runtime bundle is the whole runtime, fiber core included. A
// program whose own object asks for no fiber (--prelude=core spawns
// nothing) still links the bundle, and the bundle's fiber core calls the
// assembly with_fiber_switch: fiber_asm.o joins with the bundle, not on
// the program's undefined symbols (the link refused the bundle's
// with_fiber_switch as undefined).

fn main:
    let opt: Option[i32] = Some(1)
    assert(opt.unwrap() == 1)
    print("ok")
