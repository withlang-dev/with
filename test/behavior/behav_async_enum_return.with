//! expect-stdout: ok

async fn returns_ok() -> Result[i32, str]:
    Ok(42)

async fn returns_err() -> Result[i32, str]:
    Err("failed")

async fn returns_some() -> Option[i32]:
    Some(7)

async fn returns_none() -> Option[i32]:
    None

async fn main:
    let r1 = returns_ok().await
    assert(r1.is_ok())
    assert(r1.unwrap() == 42)

    let r2 = returns_err().await
    assert(not r2.is_ok())

    let o1 = returns_some().await
    assert(o1.is_some())
    assert(o1.unwrap() == 7)

    let o2 = returns_none().await
    assert(o2.is_none())

    print("ok")
