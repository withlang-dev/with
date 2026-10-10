//! expect-stdout: 1 2 5 3

// §21.1 rule 1 (Eric 2026-09-29): `writes` opens a function's declared
// global write set only as the declaration's last clause, and only when a
// name follows; everywhere else it stays an ordinary identifier — here a
// global and a field (behav_writes_identifier_elsewhere.w: a parameter, a
// local, a function). `bump` declares that it writes the global named
// `writes`; `add_to_total` a comma list; `Log.note` a method's clause.
var writes = 0
var TOTAL = 0
var NOTES: i32 = 0

type Log { writes: i32 }

impl Log:
    fn note() -> i32 writes NOTES:
        NOTES = NOTES + self.writes
        NOTES

fn bump() writes writes: writes = writes + 1
fn add_to_total(n: i32) writes TOTAL, NOTES:
    TOTAL = TOTAL + n
    NOTES = NOTES + 1

fn main:
    bump()
    let log = Log { writes: 2 }
    add_to_total(5)
    let noted = log.note()
    print(f"{writes} {log.writes} {TOTAL} {noted}")
