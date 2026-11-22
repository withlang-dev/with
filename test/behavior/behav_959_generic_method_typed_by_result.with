//! expect-stdout: 12 7
// #959: a generic method whose type parameter no argument mentions takes it
// from the demand on its result, as a free generic function does. With no
// argument it was "cannot infer generic method type parameter 'T'".
trait FromText:
    fn from_text(s: &str) -> Option[Self]
impl FromText for i64:
    fn from_text(s: &str) -> Option[i64]: if s == "12": Some(12) else: None
impl FromText for u8:
    fn from_text(s: &str) -> Option[u8]: if s == "7": Some(7) else: None
type Cell { text: str }
impl Cell:
    fn get[T: FromText]() -> Option[T]: T.from_text(self.text)
fn main:
    let a = Cell { text: "12" }
    let b = Cell { text: "7" }
    let n: Option[i64] = a.get()
    let m: u8 = b.get() ?? 0
    print(f"{n ?? 0} {m}")
