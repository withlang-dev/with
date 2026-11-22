//! expect-stdout: log=OI|
// §2.4: a field consumed inside the drop body is skipped by the field glue
// (drop_consumed_field) — it drops exactly once, via the consuming local.
var LOG = ""
type Inner { id: i32 }
impl Drop for Inner:
    fn drop(move self: Self): LOG = LOG ++ "I"
type Outer { inner: Inner, tag: i32 }
impl Drop for Outer:
    fn drop(move self: Self):
        LOG = LOG ++ "O"
        let consumed = self.inner
        let _ = consumed.id
fn run():
    var o = Outer { inner: Inner { id: 1 }, tag: 7 }
    o.drop()
    LOG = LOG ++ "|"
fn main:
    run()
    print(f"log={LOG}")
