//! expect-check-fail: `writes COUNT`: `COUNT` is no global

// §21.1 rule 1 (Eric 2026-09-29): a `writes` clause names globals; a name
// that denotes none is refused where the clause is written.
fn bump(): 0
fn tally() writes COUNT: bump()

fn main:
    tally()
