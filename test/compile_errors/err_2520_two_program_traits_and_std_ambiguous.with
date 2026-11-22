//! expect-check-fail: ambiguous trait method 'one' for type 'f64'
// #2520: two program traits give f64 a static `one`, and std's prelude `One`
// gives it a third. The program's traits outrank std's, but they rank
// equal with each other: the bare call is §11.4's ambiguity. The candidate
// chain held only the first two candidates (std's One, Unit1), so Unit2 went
// unseen and the call silently took Unit1's.
trait Unit1:
    fn one() -> Self
trait Unit2:
    fn one() -> Self
impl Unit1 for f64:
    fn one(): 1.0
impl Unit2 for f64:
    fn one(): 2.0
fn main:
    print(f64.one())
