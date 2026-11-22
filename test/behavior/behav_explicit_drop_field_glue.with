//! expect-stdout: log=OI|
// §2.4/#641b: explicit x.drop() runs the destructor body AND the field drop
// glue (identical to scope-exit drop), then the binding is consumed — nothing
// drops again at scope end.
var LOG = ""
type Inner { id: i32 }
impl Drop for Inner:
    fn drop(move self: Self): LOG = LOG ++ "I"
type Outer { inner: Inner }
impl Drop for Outer:
    fn drop(move self: Self): LOG = LOG ++ "O"
fn run():
    var o = Outer { inner: Inner { id: 1 } }
    o.drop()
    LOG = LOG ++ "|"
fn main:
    run()
    print(f"log={LOG}")
