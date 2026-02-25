// Phase 4 gap: select await branches with let-else blocks not implemented
async fn fast() -> i32 = 1
async fn slow() -> i32 = 2

fn main() -> i32 =
    let r = select await:
        a = fast() ->
            let Some(x) = Some(a) else 0
            x
        b = slow() ->
            b
    if r == 1 or r == 2 then 0 else 1
