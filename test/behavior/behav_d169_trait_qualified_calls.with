//! expect-stdout: 1 2
//! expect-stdout: one two
//! expect-stdout: 3
//! expect-stdout: 1 7

// D169: two traits of equal rank give a type a method of one name, so the
// bare call is §11.4's ambiguity; the call names the trait. An instance
// method takes its receiver as the first argument (`Name1.name(p)`, the
// `&Self` borrowed with no `&` written); a static method takes `Self` from
// its use (`let a: f64 = Unit1.one()`, or a parameter's type).
trait Unit1:
    fn one() -> Self
trait Unit2:
    fn one() -> Self
impl Unit1 for f64:
    fn one(): 1.0
impl Unit2 for f64:
    fn one(): 2.0

trait Name1:
    fn name(self: &Self) -> str
trait Name2:
    fn name(self: &Self) -> str
type P { n: i32 }
impl Name1 for P:
    fn name(): "one"
impl Name2 for P:
    fn name(): "two"

// A program trait outranks std's prelude One for a bare `i64.one()`
// (§18.2); `One.one()` still reaches std's.
trait Seven:
    fn one() -> Self
impl Seven for i64:
    fn one(): 7

fn sum(a: f64, b: f64): a + b

fn main:
    let a: f64 = Unit1.one()
    let b: f64 = Unit2.one()
    print(f"{a} {b}")
    let p = P { n: 1 }
    print(f"{Name1.name(p)} {Name2.name(p)}")
    print(f"{sum(Unit1.one(), Unit2.one())}")
    let std_one: i64 = One.one()
    print(f"{std_one} {i64.one()}")
