//! expect-stdout: drop:after

// Spec test: Section 18.2 — Drop in Prelude.
// `drop` is available from the ambient prelude and triggers cleanup at the
// call site instead of waiting for the end of the enclosing scope.

var PRELUDE_DROP_TRACE = ""

type PreludeDropProbe { label: str }
impl Drop for PreludeDropProbe:
    fn drop(move self: Self):
        PRELUDE_DROP_TRACE = PRELUDE_DROP_TRACE ++ self.label

fn test_drop_is_in_prelude:
    let probe = PreludeDropProbe { label: "drop" }
    drop(probe)
    PRELUDE_DROP_TRACE = PRELUDE_DROP_TRACE ++ ":after"
    assert(PRELUDE_DROP_TRACE == "drop:after")

fn main:
    test_drop_is_in_prelude()
    write(PRELUDE_DROP_TRACE)
