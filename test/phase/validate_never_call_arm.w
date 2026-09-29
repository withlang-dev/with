//! args: --validate-all --no-prelude
//! expect-check-stdout: validate-all: ok

fn stop -> Never:
    loop: continue

fn choose(flag: bool) -> i32:
    if flag: 7 else: stop()
