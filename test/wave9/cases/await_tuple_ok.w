async fn left -> i32:
    40

async fn right -> i32:
    2

async fn third -> i32:
    7

fn main -> i32:
    let (a, b) = (left(), right()).await
    let (x, y, z) = (left(), right(), third()).await
    if a == 40 and b == 2 and x == 40 and y == 2 and z == 7 then 0 else 1
