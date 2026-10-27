//! expect-error: expected '=>'
// #2744 (§9.7, D163): a match arm's introducer is `=>`, never `:`. Writing
// the arm like every other construct (`Some(v):`) is a parse error naming
// the missing `=>`.

fn main:
    let x = Some(1)
    match x:
        Some(v):
            print(v)
        None => print(0)
