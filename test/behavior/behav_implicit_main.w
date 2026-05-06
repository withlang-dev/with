//! expect-run-output: "7\n"

let x = 3

print(int_to_string(double(x) + 1))

fn double(n: i32) -> i32:
    n * 2
