async fn blows_up -> i32:
    panic("fiber-boom-rt-small")

async fn async_main:
    let pair = (blows_up(), blows_up()).await
    print(f"unreached {pair.0}")

fn main:
    async_main()
