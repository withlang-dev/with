//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: boom
// §14.11.1: `ids |> map(f(it)) |> await_all?` over Result tasks is fail-fast.
use std.task.await_all
async fn sq(n: i32) -> Result[i32, str]: if n < 0: Err("boom") else: Ok(n * n)
fn squares(xs: List[i32]) -> Result[List[i32], str]: xs |> map(sq(it)) |> await_all
fn main:
    print(squares([1, 2, 3]).unwrap().len())
    print(await_all([sq(1), sq(2)]).unwrap().len())
    match squares([1, -1]):
        Ok(_) => print("ok")
        Err(e) => print(e)
