//! expect-error: tuple await? requires Task[Result

async fn plain_task -> i32:
    1

async fn result_task -> Result[i32, str]:
    2

async fn use_tuple_await_question -> Result[(i32, i32), str]:
    (plain_task(), result_task()).await?
