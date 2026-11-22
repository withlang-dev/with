//! expect-error: `report` is a read-only view; to let `audit` mutate it, declare the parameter `mut report: Report`
// D172 (2), §3.8a: a value reached through `&T` is no mutable place.
type Report:
    lines: List[str]

impl Report:
    mut fn fail(m: str): self.lines.push(m)

fn audit(report: &Report):
    report.fail("bad")

fn main:
    var r = Report { lines: [] }
    audit(r)
    print(r.lines.len())
