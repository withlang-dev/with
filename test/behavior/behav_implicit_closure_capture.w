//! expect-stdout: ok

type Ctx { multiplier: i32 }

fn scale(x: i32, ctx: implicit Ctx) -> i32:
    x * ctx.multiplier

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main:
    with outer(Ctx { multiplier: 2 }):
        let double = x => scale(x)
        assert(apply(double.clone(), 5) == 10)   // D63: passing a callable moves it
        with inner(Ctx { multiplier: 10 }):
            assert(apply(double.clone(), 5) == 10)   // D63: passing a callable moves it
            let ten_x = x => scale(x)
            assert(apply(ten_x, 5) == 50)
        assert(apply(double, 6) == 12)
    print("ok")
