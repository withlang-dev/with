//! expect-stdout: ok

// #687: a reference constructed from a raw-pointer deref (`&(*(p as *const
// T))`) inside unsafe and RETURNED forwards the pointer value — the standard
// raw-to-ref reborrow. It used to segfault: the ref expression had no
// fallback type in MIR lowering, so the ref temp was void-typed and the fn
// returned `const ()` instead of the reference. This pins the reborrow for a
// struct owner, a scalar owner, and the &raw mut form that writes through.

type T { xs: List[i64], tag: i32 }

fn view(p: i64) -> &T:
    unsafe { &(*(p as *const T)) }

fn scalar_view(p: i64) -> &i64:
    unsafe { &(*(p as *const i64)) }

fn bump(p: i64):
    unsafe:
        let r = &raw mut (*(p as *mut i64))
        *r = *r + 1

fn main:
    var t = T { xs: List.new(), tag: 7 }
    t.xs.push(9)
    let p = &raw const t as i64
    assert(view(p).xs[0] == 9)
    assert(view(p).xs.len() == 1)
    assert(view(p).tag == 7)

    var n: i64 = 41
    let np = &raw const n as i64
    let sv = scalar_view(np)
    assert(*sv == 41)

    var m: i64 = 100
    let mp = &raw mut m as i64
    bump(mp)
    bump(mp)
    assert(m == 102)

    print("ok")
