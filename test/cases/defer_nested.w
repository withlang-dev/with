// Test: defer in nested scopes (LIFO order)
extern fn puts(s: *const i8) -> i32

fn main() -> i32 =
    defer puts("defer 1")
    defer puts("defer 2")
    defer puts("defer 3")

    // Verify basic execution still works alongside defers
    let x = 10
    let y = 20
    assert(x + y == 30)

    // More defers
    defer puts("defer 4")

    let z = 42
    assert(z == 42)

    println("all defer nested tests passed")
    0
