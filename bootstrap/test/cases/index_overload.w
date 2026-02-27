// Test: index operator overloading via get method
type IntArray = {
    a: i32,
    b: i32,
    c: i32,
}

impl IntArray =
    fn get(self: IntArray, idx: i32) -> i32:
        if idx == 0 then self.a
        else if idx == 1 then self.b
        else self.c

fn main -> i32:
    let arr = IntArray { a: 10, b: 20, c: 30 }
    assert(arr[0] == 10)
    assert(arr[1] == 20)
    assert(arr[2] == 30)
