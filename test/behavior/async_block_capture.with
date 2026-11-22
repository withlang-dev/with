//! expect-stdout: ok

// Test: async block with captured local variables.

fn main:
    let x = 10
    let y = 20

    // Async block captures x and y from enclosing scope
    let task = async:
        x + y

    let result = task.await
    assert(result == 30)

    print("ok")
