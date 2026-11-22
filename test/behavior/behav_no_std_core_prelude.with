//! check-only
//! args: --no-std

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let opt: Option[i32] = Some(10)
    let res: Result[i32, i32] = Ok(20)
    let view: &str = "hello"
    let _ = view
    opt.unwrap() + res.unwrap()
