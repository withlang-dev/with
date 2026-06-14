//! expect-stdout: ok

fn summarize(arr: [4]i32) -> i32:
    let [first, ..middle, last] = arr else return -1
    first + middle + last

fn main:
    assert(summarize([10, 20, 30, 40]) == 52)
    print("ok")
