//! expect-exit: 0
//! args: -O0

// A single stack frame larger than one page, exercised on a fiber. On
// Windows x64 the compiler must probe every page of a frame this size as
// it is established; those probes read the thread's stack bounds. While a
// fiber runs those bounds only describe the fiber stack if the context
// switch installs them, so this returns normally on a correct backend and
// faults on one that leaves the OS's stack bounds pointing at the main
// thread. Elsewhere a large frame is unremarkable; the check is portable.

fn big(seed: i32) -> i32:
    var buf: [16384]i32 = [0; 16384]
    var i = 0
    while i < 16384:
        buf[i] = seed + i as i32
        i = i + 1
    var sum = 0
    i = 0
    while i < 16384:
        sum = sum + buf[i]
        i = i + 1
    sum

@[stack_size(262144)]
async fn run() -> i32:
    big(1)

async fn main:
    let t = run()
    let got = t.await
    // sum of (1 + k) for k in 0..16384 = 16384 + 16383*16384/2 = 134225920
    if got != 134225920:
        panic("wrong checksum")
