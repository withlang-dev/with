//! expect-check-fail: `Unit1.one()` takes `Self` from its use; write the type it makes
// D169: a static trait method's `Self` is the type its use demands; with
// no demand the call is refused, never guessed.
trait Unit1:
    fn one() -> Self
impl Unit1 for f64:
    fn one(): 1.0
fn main:
    print(Unit1.one())
