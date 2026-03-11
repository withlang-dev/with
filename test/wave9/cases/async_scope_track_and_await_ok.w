async fn one -> i32: 1
async fn two -> i32: 2

fn main -> i32:
    let sum = async scope s =>
        let a = s.track(one())
        let b = s.track(two())
        a.await + b.await
    if sum == 3 then 0 else 1

