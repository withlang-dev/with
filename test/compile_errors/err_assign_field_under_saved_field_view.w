//! expect-check-fail: cannot mutate `a` while `saved` is a live view into it
// §3.8 / D22 / D27: an unannotated `let saved = a.buf` binds a VIEW of the
// field, and mutating the viewed field while the view is live is refused.
// The pre-D27 phase pin dump_mir_str_field_concat_saved_alias_copy expected
// the concatenation to read through the alias; the independent value is
// spelled `let saved = a.buf.clone()`
// (behav_str_field_concat_saved_clone).
type Acc { buf: str, name: str }

fn saved_alias -> str:
    var a = Acc { buf: "", name: "n" }
    let saved = a.buf
    a.buf = a.buf ++ "x"
    saved ++ a.buf

fn main: print(saved_alias())
