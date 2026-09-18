use std.builtins.print
async fn fetch() -> str: "hello"
async fn main:
    let t = fetch()
    let a = t.await
    let b = t.await
    print(a ++ "|" ++ b)
