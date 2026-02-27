//! expect-stdout: ok

use Span

fn main:
    let s1 = Span { file: 0, start: 10, end: 20 }
    assert(Span.len(s1) == 10)

    let s2 = Span { file: 0, start: 5, end: 15 }
    let merged = Span.merge(s1, s2)
    assert(merged.start == 5)
    assert(merged.end == 20)

    let z = span_zero()
    assert(z.file == 0)
    assert(z.start == 0)
    assert(z.end == 0)

    println("ok")
