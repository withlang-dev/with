async fn work() -> i32:
    42

fn main:
    let cb = () =>
        let task = work()
        task.await

    no_suspend:
        let v = cb()
        assert(v == 42)
