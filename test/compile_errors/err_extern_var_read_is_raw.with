//! expect-check-fail: read of C global `shared_total` may race
// §31.4: a hand-declared `extern var` belongs to no imported header, so no
// contract can say its library runs no threads: reading it is always raw.
extern var shared_total: i32

fn main:
    print(f"{shared_total}")
