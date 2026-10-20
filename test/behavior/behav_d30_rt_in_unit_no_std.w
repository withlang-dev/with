//! check-only
//! args: --no-std

// D30: a --no-std program brings its own panic handler and entry; the
// in-unit runtime, written against std, does not join its unit (it did,
// and the program failed to check under WITH_RT_IN_UNIT).
@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let opt: Option[i32] = Some(10)
    opt.unwrap()
