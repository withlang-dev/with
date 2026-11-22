//! expect-stdout: x
// #3026 (D111, D179): `let saved = a.buf` takes the str, so appending to
// the field afterwards reads the independent saved value: "" ++ "x". This
// was err_assign_field_under_saved_field_view (#1530, D27), whose independent
// value was spelled `a.buf.clone()`; the unannotated binding is that value.
type Acc { buf: str, name: str }

fn saved_alias -> str:
    var a = Acc { buf: "", name: "n" }
    let saved = a.buf
    a.buf = a.buf ++ "x"
    saved ++ a.buf

fn main: print(saved_alias())
