// Regression: a match-arm pattern binding must only be dropped on the path
// that bound it. Previously the binding's drop ran on every path leaving the
// match, dropping uninitialized garbage when a different arm was taken
// (memory corruption for a Drop-typed payload).

var MABD_DROPS = 0

type Guard { id: i32 }

impl Drop for Guard:
    fn drop(move self: Self):
        MABD_DROPS = MABD_DROPS + 1

fn make(ok: bool) -> Result[Guard, i32]:
    if ok:
        Ok(Guard { id: 7 })
    else:
        Err(2)

fn test_err_arm_does_not_drop_ok_payload:
    MABD_DROPS = 0
    match make(false):
        Ok(g) => assert(false)
        Err(e) => assert(e == 2)
    // The Ok(g) binding was never bound on this path; Guard's Drop must not run.
    assert(MABD_DROPS == 0)
    // A later heap allocation must not hit a corrupted allocator.
    let probe = Guard { id: 9 }
    assert(probe.id == 9)

fn test_ok_arm_drops_binding_once:
    MABD_DROPS = 0
    match make(true):
        Ok(g) => assert(g.id == 7)
        Err(e) => assert(false)
    // g goes out of scope at the arm end and is dropped exactly once.
    assert(MABD_DROPS == 1)
