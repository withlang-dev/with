//! expect-error: slice rest pattern in let ... else is not implemented yet

fn main:
    let arr = [1, 2, 3]
    let [first, ..rest] = arr else return
    let _x = first
