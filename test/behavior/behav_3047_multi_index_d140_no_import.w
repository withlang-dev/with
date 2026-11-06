//! args: --prelude=core
//! expect-stdout: 3 9
//! expect-stdout: ok

// #3047 (§11.7, D140): an impl of `MultiIndex` may leave its parameter types
// to the trait, so the user never names `IndexSpec`; the trait's own
// signature resolves in the trait's module under either prelude (here the
// core prelude, which loads no std.collections).

type Matrix { a00: i32, a01: i32, a10: i32, a11: i32 }

impl MultiIndex[i32] for Matrix:
    fn multi_index(self: &Self, specs, count) -> i32:
        assert(count == 2)
        let row = specs[0].start
        let col = specs[1].start
        if row == 0 and col == 0: return self.a00
        if row == 0 and col == 1: return self.a01
        if row == 1 and col == 0: return self.a10
        self.a11

impl MultiIndexMut[i32] for Matrix:
    mut fn multi_index_set(specs, count, value):
        assert(count == 2)
        if specs[0].start == 0 and specs[1].start == 1:
            self.a01 = value
        else:
            self.a11 = value

fn main:
    var m = Matrix { a00: 1, a01: 2, a10: 3, a11: 4 }
    let before = m[1, 0]
    m[0, 1] = 9
    print(f"{before} {m[0, 1]}")
    print("ok")
