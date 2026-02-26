// spawn returns a task handle (i32 task ID)
async fn compute -> i32: 42

fn main -> i32:
    // Spawn returns task handle that can be bound
    let t = spawn compute()
    println(t)
