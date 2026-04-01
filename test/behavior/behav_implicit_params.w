//! expect-stdout: ok

type Context { multiplier: i32 }

fn compute(x: i32, ctx: implicit Context) -> i32:
    x * ctx.multiplier

fn test_with_implicit:
    with ctx(Context { multiplier: 3 }):
        // ctx is in scope, pass explicitly via named arg
        let result = compute(5, ctx: ctx)
        assert(result == 15)

fn test_nested_with:
    with outer(Context { multiplier: 2 }):
        let r1 = compute(5, ctx: outer)
        assert(r1 == 10)
        with inner(Context { multiplier: 10 }):
            let r2 = compute(5, ctx: inner)
            assert(r2 == 50)
        // outer still in scope
        let r3 = compute(5, ctx: outer)
        assert(r3 == 10)

fn main:
    test_with_implicit()
    test_nested_with()
    print("ok")
