//! expect-stdout: 8 49
//! expect-stdout: 3 25
//! expect-stdout: 4 12
//! expect-stdout: 2 bb

// #2142 (§13.6, §17): a list comprehension is comptime-evaluable — over a
// range, an array or a vec, with a filter, and with nested clauses. It was
// "expression kind 64 is not comptime-evaluable yet", and README's
// `squares` kept an accumulator loop for it.
comptime fn squares(n: i32): [i * i for i in 0..n]

comptime fn odd_squares(n: i32): [i * i for i in 0..n if i % 2 == 1]

comptime fn products(rows: i32, cols: i32): [r * c for r in 1..rows for c in 1..cols]

comptime fn long_names: [name for name in ["a", "bb", "ccc"] if name.len() > 1]

const SQUARES = comptime squares(8)
const ODD = comptime odd_squares(6)
const PRODUCTS = comptime products(3, 3)
const LONG = comptime long_names()

fn main:
    print(f"{SQUARES.len()} {SQUARES[7]}")
    print(f"{ODD.len()} {ODD[2]}")
    print(f"{PRODUCTS.len()} {PRODUCTS[0] + PRODUCTS[1] + PRODUCTS[2] + PRODUCTS[3] + 3}")
    print(f"{LONG.len()} {LONG[0]}")
