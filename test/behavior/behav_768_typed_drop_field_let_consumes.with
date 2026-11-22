//! expect-stdout: log=OI|PJ|
// #768 (§2.4): a field a drop body takes with a typed `let` is consumed, as
// the unannotated binding is, and drops exactly once. The typed spelling was
// aliased instead while the field glue skipped the field, so Inner's
// destructor never ran ("log=O|"). A `&` annotation observes the field,
// which the glue then drops.
var LOG = ""
type Inner { id: i32 }
impl Drop for Inner:
    move fn drop(): LOG = LOG ++ (if self.id == 1: "I" else: "J")
type Outer { inner: Inner }
impl Drop for Outer:
    move fn drop():
        LOG = LOG ++ "O"
        let taken: Inner = self.inner
        let _ = taken.id
type Peek { inner: Inner }
impl Drop for Peek:
    move fn drop():
        LOG = LOG ++ "P"
        let seen: &Inner = self.inner
        let _ = seen.id
fn run():
    let o = Outer { inner: Inner { id: 1 } }
fn peek():
    let p = Peek { inner: Inner { id: 2 } }
fn main:
    run()
    LOG = LOG ++ "|"
    peek()
    LOG = LOG ++ "|"
    print(f"log={LOG}")
