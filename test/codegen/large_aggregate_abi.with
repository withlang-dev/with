//! expect-stdout: ok

type BigExact {
    ok: i32,
    overflow: i32,
    negative: i32,
    lo: i64,
    hi: i64,
}

fn make_big(lo: i64, hi: i64, negative: i32) -> BigExact:
    BigExact { ok: 1, overflow: 0, negative, lo, hi }

fn consume_big(v: BigExact) -> i64:
    v.lo + v.hi + v.negative as i64

fn call_big(f: fn(i64, i64, i32) -> BigExact) -> BigExact:
    f(10, 20, 1)

fn main:
    let direct = make_big(3, 4, 0)
    assert(consume_big(direct) == 7)

    let from_closure = call_big(make_big)
    assert(consume_big(from_closure) == 31)

    print("ok")
