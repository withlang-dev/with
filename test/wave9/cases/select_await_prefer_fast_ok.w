async fn slow -> i32:
    let _ = (async: 0).await
    10

async fn fast -> i32: 20

fn main -> i32:
    let r = select await:
        a = slow() -> a
        b = fast() -> b
    if r == 20 then 0 else 1

