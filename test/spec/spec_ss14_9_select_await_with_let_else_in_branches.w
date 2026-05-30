//! expect-stdout: ok

async fn maybe_item(value: i32) -> Option[i32]:
    if value <= 2:
        Some(value)
    else:
        None

async fn maybe_connection(attempt: i32) -> Result[i32, str]:
    if attempt < 2:
        Err("retry")
    else:
        Ok(7)

async fn maybe_control(attempt: i32) -> Option[str]:
    let _ = maybe_item(1).await
    if attempt < 3:
        Some("keep-going")
    else:
        None

fn test_let_else_break:
    var sum = 0
    var current = 1
    loop:
        let task = maybe_item(current)
        select await:
            opt = task =>
                let Some(item) = opt else: break
                sum = sum + item
                current = current + 1
    assert(sum == 3)

fn test_let_else_continue_and_break:
    var attempts = 0
    var accepted = 0
    loop:
        attempts = attempts + 1
        let conn_task = maybe_connection(attempts)
        let ctrl_task = maybe_control(attempts)
        select await biased:
            result = conn_task =>
                let Ok(conn) = result else: continue
                accepted = conn
                break
            opt = ctrl_task =>
                let Some(_) = opt else: break
    assert(attempts == 2)
    assert(accepted == 7)

fn main:
    test_let_else_break()
    test_let_else_continue_and_break()
    print("ok")
