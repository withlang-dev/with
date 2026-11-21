//! expect-stdout: a-b-c
//! expect-stdout: abc
//! expect-stdout: 0
//! expect-stdout: x, y
//! expect-stdout: one_two_three
//! expect-stdout: 11|22
//! expect-stdout: a/b/c

// #3483 (D110): `List.join` is declared in the standard library for
// `List[str]`, over the runtime's join; the compiler has no built-in of
// that name. A list of anything else is refused (#3508), with the sentence
// that says how to make each element text (err_vec_join_non_str).
fn main:
    let xs = ["a", "b", "c"]
    print(xs.join("-"))
    print(xs.join(""))
    let none: List[str] = []
    print(none.join(",").len())
    print(["x", "y"].join(", "))
    let words = "one two three".split(" ")
    print(words.join("_"))
    let made = ["1", "2"].iter() |> map(it.repeat(2)) |> collect[List]()
    print(made.join("|"))
    let f = List[str].join
    print(f(xs, "/"))
