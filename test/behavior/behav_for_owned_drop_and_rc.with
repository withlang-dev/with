//! expect-stdout: hello-1
//! expect-stdout: hello-2
//! expect-stdout: opt-1
//! expect-stdout: opt-2
//! expect-stdout: left-1
//! expect-stdout: comp-1
//! expect-stdout: seen:t-1
//! expect-stdout: drop:t-1
//! expect-stdout: seen:t-2
//! expect-stdout: drop:t-2

// Consuming iteration (`into_iter`, `for msg in rx`, comprehension generic
// iterator) owns each stepped element in a per-iteration scope:
// - zero-iteration `for msg in rx:` never drops an unwritten binding;
// - RC `str` and Copy carriers with drop glue (`Option[str]`, `(str, str)`)
//   move out of the step `Option` without leaking holds;
// - `Drop` channel elements drop at the end of each iteration.

use std.channel.chan

type Tracked { tag: str }
impl Drop for Tracked:
    move fn drop():
        print(f"drop:{self.tag}")

fn main:
    let (tx0, rx0) = chan[str](2)
    tx0.close()
    for s in rx0:
        print(s)

    var xs: List[str] = List.new()
    xs.push(f"hello-{1}")
    xs.push(f"hello-{2}")
    for s in xs.into_iter():
        print(s)

    var opts: List[Option[str]] = List.new()
    opts.push(Some(f"opt-{1}"))
    opts.push(None)
    opts.push(Some(f"opt-{2}"))
    for Some(s) in opts.into_iter():
        print(s)

    var pairs: List[(str, str)] = List.new()
    pairs.push((f"left-{1}", f"right-{1}"))
    for (a, _) in pairs.into_iter():
        print(a)

    var opts2: List[Option[str]] = List.new()
    opts2.push(Some(f"comp-{1}"))
    opts2.push(None)
    let got = [s for Some(s) in opts2.into_iter()]
    print(got[0])

    let (txd, rxd) = chan[Tracked](4)
    txd.send(Tracked { tag: f"t-{1}" })
    txd.send(Tracked { tag: f"t-{2}" })
    txd.close()
    for item in rxd:
        print(f"seen:{item.tag}")
