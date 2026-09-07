// T18: `use` with trailing paren group — Parser.w:2464-2472 silently skips it.
use foo(bar)

fn main:
    assert(true)
