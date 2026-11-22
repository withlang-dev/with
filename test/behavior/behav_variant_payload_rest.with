//! expect-stdout: ok

// #663 regression guard: after moving the resolver's variant-payload slot to
// node-only binding, a payload binder alongside a rest pattern still binds
// correctly (the rest `..` is a no-op, not a garbage binding).
enum E:
    V(i32, i32)

fn main:
    let e = E.V(5, 9)
    match e:
        V(x, ..) => assert(x == 5)
        _ => assert(false)
    print("ok")
