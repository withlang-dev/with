//! expect-stdout: 1 1

// #2977: concurrency evidence counts only where the program can reach it.
// `lazy_async_sleeper.pause` awaits inside a body nothing here calls; the
// program's plain global stays under the single-thread proof (§9.1c) and
// its mutation is not an E0921.
use lazy_async_sleeper

var counter = 0

fn bump(): counter = counter + 1

fn main:
    bump()
    print(f"{counter} {plain()}")
