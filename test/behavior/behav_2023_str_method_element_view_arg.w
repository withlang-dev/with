//! expect-stdout: a
//! expect-stdout: Xb
//! expect-stdout: aXb
//! expect-stdout: 98
//! expect-stdout: abab
// #2023 (D22/D27): an element of a Vec[i64] is a view (`ss[0]`, or a
// binding of it), and a str method's i64 parameter is an owned demand that
// materializes it, as a user fn's parameter does. Sema checked no argument
// of a str intrinsic, so the view reached codegen as a pointer:
// "wrong argument type actual=ptr expected=i64".
fn splice(text_in: str, starts: &Vec[i64], texts: &Vec[str]) -> str:
    var text = text_in
    for i in 0..texts.len() as i32:
        let s = starts[i]
        text = text.slice(0, s) ++ texts[i] ++ text.slice(s, text.len())
    text

fn main:
    var ss: Vec[i64] = Vec.new()
    ss.push(1)
    ss.push(2)
    print("ab".slice(0, ss[0]))
    let s = ss[0]
    print("X" ++ "ab".slice(s, 2))
    var ts: Vec[str] = Vec.new()
    ts.push("X")
    print(splice("ab", &ss, &ts))
    print(f"{"ab".byte_at(ss[0])}")
    print("ab".repeat(ss[1]))
