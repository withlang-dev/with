//! expect-stdout: ok

async fn ready(value: i32) -> i32:
    value

async fn delayed(value: i32) -> i32:
    let _ = ready(0).await
    value

async fn fallible(value: i32) -> Result[i32, str]:
    if value < 0:
        Err("negative")
    else:
        Ok(value)

fn test_first_completed_branch:
    let fast = ready(42)
    let slow = delayed(99)
    select await:
        value = fast => assert(value == 42)
        value = slow => assert(value == 99)

fn test_select_branch_break:
    var sum = 0
    var current = 1
    loop:
        let item = ready(current)
        select await:
            value = item =>
                sum = sum + value
                if current == 2:
                    break
                current = current + 1
    assert(sum == 3)

async fn select_with_question -> Result[i32, str]:
    let task = fallible(-1)
    select await:
        value = task => value?

async fn main:
    test_first_completed_branch()
    test_select_branch_break()
    let result = select_with_question().await
    match result:
        Ok(_) => assert(false)
        Err(message) => assert(message == "negative")
    print("ok")
