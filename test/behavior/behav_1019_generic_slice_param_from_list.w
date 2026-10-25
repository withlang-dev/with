//! expect-stdout: 3 2 3 a
// #1019: a generic slice parameter `[T]` binds T from a List or fixed array
// argument, the #604 coercion such an argument meets the parameter by.
// `count([1, 2, 3])` could not infer T: "the argument's shape does not
// match the parameter type that mentions 'T'".
use std.iter.count

fn first_of[T](xs: [T]) -> T: xs[0]

fn main:
    let names: List[str] = ["a", "b"]
    let arr: [i32; 3] = [7, 8, 9]
    print(f"{count([1, 2, 3])} {count(names)} {count(arr)} {first_of(names)}")
