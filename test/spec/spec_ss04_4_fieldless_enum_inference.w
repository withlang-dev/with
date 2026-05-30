// Spec test: Section 4.4 — fieldless enums infer an integer (i32) backing
// (#309). A backing-less enum whose variants carry no payload supports
// explicit discriminants, auto-increment from the last explicit value, and
// `as i32` — identical to writing `: i32:`. Enums with payloads stay ADTs.

enum Term:
    Br = 0
    CondBr
    Select
    Return

fn test_explicit_then_autoincrement:
    assert(Term.Br as i32 == 0)
    assert(Term.CondBr as i32 == 1)
    assert(Term.Select as i32 == 2)
    assert(Term.Return as i32 == 3)

enum Dir:
    North
    South
    East
    West

fn test_pure_autoincrement:
    assert(Dir.North as i32 == 0)
    assert(Dir.West as i32 == 3)

enum Gap:
    A = 5
    B
    C = 10
    D

fn test_explicit_gaps:
    assert(Gap.A as i32 == 5)
    assert(Gap.B as i32 == 6)
    assert(Gap.C as i32 == 10)
    assert(Gap.D as i32 == 11)

fn classify(d: Dir) -> str:
    match d:
        .North => "n"
        .South => "s"
        .East  => "e"
        .West  => "w"

fn test_match_on_fieldless:
    assert(classify(Dir.East) == "e")
