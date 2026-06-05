//! expect-stdout: ok

async fn twice(x: i32) -> i32:
    x * 2

async fn main:
    let async_inline = async scope s => s.track(twice(5)).await
    let async_colon = async scope s =>:
        let task = s.track(twice(6))
        task.await
    let sync_inline = scope s => s.spawn(() => 7).join()
    let sync_colon = scope s =>:
        let handle = s.spawn(() => 8)
        handle.join()
    let sync_brace = scope s {
        let handle = s.spawn(() => 9)
        handle.join()
    }
    assert(async_inline + async_colon + sync_inline + sync_colon + sync_brace == 46)
    print("ok")
