//! expect-stdout: 6 one,two, 9 0

// #1197: `for x in xs` over a `&[T]` parameter failed MIR lowering (Sema
// accepted it; indexing worked). Copy and Drop elements, a slice of an array,
// a whole array by reference, and an empty slice.

fn sum(xs: &[i32]) -> i32:
    var total = 0
    for x in xs: total = total + x
    total

fn join(words: &[str]) -> str:
    var out = ""
    for w in words: out = out ++ w ++ ","
    out

fn sum_array(xs: &[3]i32) -> i32:
    var total = 0
    for x in xs: total = total + x
    total

fn main:
    let nums = [1, 2, 3]
    let words = ["one", "two"]
    let big = [4, 5, 6, 7]
    print(f"{sum(nums[..])} {join(words[..])} {sum_array(&nums) + sum(big[0..0]) + 3} {sum(big[2..2])}")
