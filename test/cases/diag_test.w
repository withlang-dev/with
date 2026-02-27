//! expect-stdout: ok

use Span
use Diag

fn main:
    var diags = DiagList.new()
    let s = Span { file: 0, start: 5, end: 10 }
    DiagList.emit(diags, Diag.err("type mismatch", s))
    DiagList.emit(diags, Diag.warn("unused variable", s))

    assert(DiagList.count(diags) == 2)
    assert(DiagList.has_errors(diags))

    println("ok")
