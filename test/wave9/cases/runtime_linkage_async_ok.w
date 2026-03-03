async fn one -> i32:
    1

fn main -> i32:
    let t = one()
    let r = t.await
    if r == 1 then 0 else 1
