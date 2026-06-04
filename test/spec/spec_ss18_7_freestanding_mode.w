//! check-only
//! args: --no-std

// Spec test: Section 18.7 - Freestanding Mode.
// Focused negative and alloc-tier coverage lives in:
// - test/compile_errors/err_no_std_*.w
// - test/behavior/behav_no_std_alloc_prelude.w

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let x: i32 = 42
    let y: bool = true
    let opt: Option[i32] = Some(10)
    let arr: [u8; 4] = [1, 2, 3, 4]
    let view: &str = "hello"
    let _ = arr
    let _ = view
    if not y:
        return 1
    x - 32 + opt.unwrap()
