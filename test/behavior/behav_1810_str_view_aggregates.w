//! expect-stdout: Rec { name: "a", n: 1 }
//! expect-stdout: ("x", 2)
//! expect-stdout: Some("y")
//! expect-stdout: pair a-b
//! expect-stdout: 3
//! expect-stdout: arr b
//! expect-stdout: joined a+b+c
//! expect-stdout: eq

// #1810: a `&str` is 16 bytes, `{ptr, len}`, wherever it is held — a tuple
// field, an Option payload, an array element — and `:?` formats the text.
// An array of views built from literals used to fail codegen ("wrong
// argument type actual=str expected=ptr"); a reference to an element view
// (`&&str`) concatenates and compares as the text, never as an address.

type Rec { name: str, n: i32 }
impl Rec:
    fn name_of() -> &str: self.name

fn split2(s: &str) -> (&str, &str): (s[..1], s[2..])
fn join3(parts: &[&str; 3]) -> str: parts[0] ++ "+" ++ parts[1] ++ "+" ++ parts[2]

fn main:
    let rec = Rec { name: "a", n: 1 }
    print(f"{rec:?}")
    let v: &str = "x"
    let t = (v, 2)
    print(f"{t:?}")
    let o: Option[&str] = Some("y")
    print(f"{o:?}")
    let (a, b) = split2("a-b")
    print(f"pair {a}-{b}")
    print(rec.name_of().len() + 2)
    let arr: [&str; 3] = ["a", "b", "c"]
    print("arr " ++ arr[1])
    print("joined " ++ join3(&arr))
    let e0 = &arr[0]
    let other: [&str; 1] = ["a"]
    let e1 = &other[0]
    if e0 == e1: print("eq")
