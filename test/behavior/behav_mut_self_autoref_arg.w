//! expect-stdout: ok

// #568 regression: auto-ref of a pointer-ABI'd mut self receiver into a
// &T parameter must pass the struct pointer, not the address of the
// slot holding it. Before the fix this corrupted memory and crashed.

type Big { a: Vec[i32], names: Vec[i32] }

fn find_in(big: &Big, x: i32) -> i32:
    for i in 0..big.names.len() as i32:
        if big.names.get(i as i64) == x:
            return i
    -1

fn Big.poke(mut self: Big, x: i32) -> i32:
    let idx = find_in(self, x)
    self.a.push(x)
    idx

fn main:
    var b = Big { a: Vec.new(), names: Vec.new() }
    b.names.push(7)
    b.names.push(9)
    let i1 = b.poke(9)
    assert(i1 == 1)
    let i2 = b.poke(7)
    assert(i2 == 0)
    assert(b.a.len() == 2)
    assert(b.a.get(0) == 9)
    assert(b.a.get(1) == 7)
    print("ok")
