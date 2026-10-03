//! expect-stdout: deferred 1
//! expect-stdout: 1
// #916: a defer body runs with only the defers registered before it still
// pending, so the cancellation unwind an `.await` inside it lowers runs
// those, not the defer itself. Lowering it once recursed without end
// (`with check` died of a stack overflow).
async fn tick() -> i32: 1

async fn f() -> i32:
    defer:
        print(f"deferred {tick().await}")
    let a = tick().await
    a

async fn main:
    print(f"{f().await}")
