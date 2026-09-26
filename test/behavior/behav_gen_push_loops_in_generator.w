//! expect-stdout: 60
//! expect-stdout: 3
//! expect-stdout: 9
//! expect-stdout: a!
//! expect-stdout: bb!
//! expect-stdout: 15

// D69 (§13.4, #1534): a generator is an ordinary function, so every loop in
// its body keeps its own state across a yield — a range `for`, a `for` over
// a Vec and over a slice, a `while` — and the generator may yield inside any
// of them.
gen fn upto(count: i32) -> i32:
    for i in 0..count:
        yield i * 10

gen fn evens(values: &Vec[i32]) -> i32:
    for v in values:
        if v % 2 == 0:
            yield v

gen fn doubled(values: &[i32]) -> i32:
    for v in values:
        yield v * 2

gen fn shouted(words: &Vec[str]) -> str:
    for w in words:
        yield w ++ "!"

fn main:
    var sum = 0
    for v in upto(4):
        sum += v
    print(sum)
    let nums: Vec[i32] = [1, 2, 3, 4, 5, 6, 7]
    var count = 0
    for _ in evens(&nums):
        count += 1
    print(count)
    let arr = [1, 2, 3, 4]
    var twice = 0
    for d in doubled(&arr[1..3]):
        twice += d
    print(twice - 1)
    let words: Vec[str] = ["a".clone(), "bb".clone()]
    for s in shouted(&words):
        print(s)
    var n = 0
    for i in upto(3):
        for j in upto(2):
            n += 1 + (i + j) / 10
    print(n)
