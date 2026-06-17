//! expect-stdout: ok

// §15.1–§15.3: owned String, borrowed StrView, owned CString, borrowed &CStr,
// and the conversions between them.

use std.string

fn build() -> Result[i64, CStringError]:
    let s: String = "hi"
    let v: StrView = s.as_view()
    if v != "hi":
        return Ok(-1)
    let s2: String = v.to_owned()
    if s2 != "hi":
        return Ok(-2)
    let c = s.to_cstring()?
    Ok(c.as_cstr().len())

fn main:
    match build():
        Ok(n) => if n == 2: print("ok") else: print("bad")
        Err(e) => print("err")
