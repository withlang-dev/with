//! expect-error: cannot convert error type

async fn text_error_task -> Result[i32, str]:
    Err("bad")

async fn use_tuple_await_question -> Result[(i32, i32), i32]:
    (text_error_task(), text_error_task()).await?
