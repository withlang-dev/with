//! expect-stdout: ok

type Context { multiplier: i32 }

fn compute(x: i32, ctx: implicit Context) -> i32:
    x * ctx.multiplier

fn test_automatic_resolution:
    // The implicit param is resolved automatically from the with binding
    with ctx(Context { multiplier: 3 }):
        let result = compute(5)
        assert(result == 15)

fn test_explicit_override:
    // Explicit named arg overrides the implicit binding
    with ctx(Context { multiplier: 3 }):
        let other = Context { multiplier: 7 }
        let result = compute(5, ctx: other)
        assert(result == 35)

fn test_nested_with:
    with outer(Context { multiplier: 2 }):
        let r1 = compute(5)
        assert(r1 == 10)
        with inner(Context { multiplier: 10 }):
            // Inner shadows outer
            let r2 = compute(5)
            assert(r2 == 50)
        // outer restored after inner scope exits
        let r3 = compute(5)
        assert(r3 == 10)

fn main:
    test_automatic_resolution()
    test_explicit_override()
    test_nested_with()
    print("ok")
