//! expect-stdout: ab-abx
// §3.8 / D22, D111: saving a field before mutating it is spelled with its
// type (`let saved: str = a.buf`, an owned demand that copies the str):
// the saved value is independent, so the concatenation that reassigns the
// field leaves it intact (an unannotated `let saved = a.buf` is a view and
// the mutation is refused: err_assign_field_under_saved_field_view).
type Acc { buf: str, name: str }

fn saved_then_grown -> str:
    var a = Acc { buf: "a" ++ "b", name: "n" }
    let saved: str = a.buf
    a.buf = a.buf ++ "x"
    saved ++ "-" ++ a.buf

fn main: print(saved_then_grown())
