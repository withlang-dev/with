//! expect-stdout: ok

type Pair {
    left: i32,
    right: i32,
}

type Holder {
    value: i32,
}

fn pair_from_body(seed: i32) -> Pair:
    let next = seed + 1
    Pair { left: seed, right: next }

fn scalar_from_body(seed: i32) -> i32:
    let next = seed + 2
    next

fn Holder.promote(self: Holder) -> Pair:
    let next = self.value + 10
    Pair { left: self.value, right: next }

fn read_plus(ptr: *const i32) -> i32:
    unsafe:
        let base = *ptr
        base + 3

fn main:
    let pair = pair_from_body(5)
    assert(pair.left == 5)
    assert(pair.right == 6)

    assert(scalar_from_body(7) == 9)

    let promoted = Holder { value: 4 }.promote()
    assert(promoted.left == 4)
    assert(promoted.right == 14)

    let value = 8
    assert(read_plus(&value) == 11)

    print("ok")
