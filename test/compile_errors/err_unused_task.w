//! expect-error: E0801: unused Task value

async fn compute() -> i32:
    42

async fn main:
    compute()
    let x = 1
