//! expect-stdout: ok

// #692: `audit:storage` checks that a generic instance's argument vector is
// one. A slot read under the wrong kind once typed a literal as a sub-byte
// integer and no audit said so; a table where that has happened is refused.
use Analysis
use SemaTypes

fn main:
    let inst = TypeKind.TY_GENERIC_INST as i32
    let int = TypeKind.TY_INT as i32
    // tid: 0 err, 1 int, 2 int, 3 List[int], 4 Map[int, int]
    let kinds = [0, int, int, inst, inst]
    let starts = [0, 0, 0, 0, 1]
    let counts = [0, 0, 0, 1, 2]
    let clean = analysis_generic_instance_violations(kinds, starts, counts, [1, 1, 2])
    assert(clean.len() == 0)
    // A non-instance's slots are never read as a vector.
    let ignores = analysis_generic_instance_violations([0, int, int], [0, 99, -5], [0, 99, 7], [])
    assert(ignores.len() == 0)
    // An argument that is no type id (the garbage a layout shift exposes).
    let stray = analysis_generic_instance_violations(kinds, starts, counts, [1, 1, 40])
    assert(stray.len() == 1)
    assert(stray[0] == "type 4: generic instance argument 1 is 40, not a type id (types=5)")
    // A vector that leaves the table.
    let long = analysis_generic_instance_violations(kinds, starts, [0, 0, 0, 1, 9], [1, 1, 2])
    assert(long.len() == 1)
    assert(long[0] == "type 4: generic instance argument range start=1 count=9 leaves type_extra (3)")
    let negative = analysis_generic_instance_violations(kinds, [0, 0, 0, -1, 1], counts, [1, 1, 2])
    assert(negative.len() == 1 and negative[0].starts_with("type 3: generic instance argument range start=-1"))
    print("ok")
