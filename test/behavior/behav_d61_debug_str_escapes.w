//! expect-stdout: ok

// §15.4.7 / D61: a `str` under `:?` is quoted and escaped — `"` as `\"`, `\`
// as `\\`, U+0000–U+001F and U+007F as `\n` `\t` `\r` `\0` or `\xHH` — and
// every other character, printable non-ASCII included, appears as itself.
// The same text at every depth: top level, a struct field, a Vec element,
// an enum payload, and two levels down. Every cell is exact.

type Label { text: str }
type Shelf { labels: Vec[Label], note: Option[str] }

fn check(got: &str, want: &str):
    if got != want:
        print(f"mismatch\n  got:  {got}\n  want: {want}")
        assert(false)

fn controls() -> Vec[str]:
    let out: Vec[str] = Vec.new()
    out.push("\0")
    out.push("\x01")
    out.push("\x02")
    out.push("\x03")
    out.push("\x04")
    out.push("\x05")
    out.push("\x06")
    out.push("\x07")
    out.push("\x08")
    out.push("\t")
    out.push("\n")
    out.push("\x0b")
    out.push("\x0c")
    out.push("\r")
    out.push("\x0e")
    out.push("\x0f")
    out.push("\x10")
    out.push("\x11")
    out.push("\x12")
    out.push("\x13")
    out.push("\x14")
    out.push("\x15")
    out.push("\x16")
    out.push("\x17")
    out.push("\x18")
    out.push("\x19")
    out.push("\x1a")
    out.push("\x1b")
    out.push("\x1c")
    out.push("\x1d")
    out.push("\x1e")
    out.push("\x1f")
    out.push("\x7f")
    out

// The escape each control character takes, in `controls()` order.
fn escapes() -> Vec[str]:
    let out: Vec[str] = Vec.new()
    out.push(r"\0")
    for b in 1..9:
        out.push(f"\\x0{b}")
    out.push(r"\t")
    out.push(r"\n")
    out.push(r"\x0b")
    out.push(r"\x0c")
    out.push(r"\r")
    out.push(r"\x0e")
    out.push(r"\x0f")
    for b in 16..26:
        out.push(f"\\x1{b - 16}")
    out.push(r"\x1a")
    out.push(r"\x1b")
    out.push(r"\x1c")
    out.push(r"\x1d")
    out.push(r"\x1e")
    out.push(r"\x1f")
    out.push(r"\x7f")
    out

fn main:
    // Depth 0: every control character.
    let all = controls()
    let want = escapes()
    assert(all.len() == 33 and want.len() == 33)
    var joined = ""
    for i in 0..all.len():
        let s = all.get(i)
        let esc = want.get(i)
        check(f"{s:?}", f"\"{esc}\"")
        joined = joined ++ (if i > 0: ", " else: "") ++ f"\"{esc}\""
    // Depth 1: the same strings as Vec elements.
    check(f"{all:?}", "[" ++ joined ++ "]")
    // Quote, backslash, printable ASCII that is not escaped, non-ASCII, empty.
    let quote = "say \"hi\""
    let slash = "a\\b"
    let plain = "{braces} 'single' ~ `tick`"
    let accented = "café"
    let wide = "日本 😀"
    let empty = ""
    check(f"{quote:?}", r#""say \"hi\"""#)
    check(f"{slash:?}", r#""a\\b""#)
    check(f"{plain:?}", r#""{braces} 'single' ~ `tick`""#)
    check(f"{accented:?}", "\"café\"")
    check(f"{wide:?}", "\"日本 😀\"")
    check(f"{empty:?}", r#""""#)
    // A view formats its pointee.
    let view: &str = &quote
    check(f"{view:?}", r#""say \"hi\"""#)
    // Depth 1: a struct field and an enum payload.
    let label = Label { text: "tab\there" }
    check(f"{label:?}", r#"Label { text: "tab\there" }"#)
    let some: Option[str] = Some("line\nbreak")
    check(f"{some:?}", r#"Some("line\nbreak")"#)
    // Depth 2: a struct in a Vec in a struct, and a payload in a field.
    let labels: Vec[Label] = Vec.new()
    labels.push(Label { text: "q\"t" })
    labels.push(Label { text: "" })
    let shelf = Shelf { labels, note: Some("back\\slash") }
    check(f"{shelf:?}", r#"Shelf { labels: [Label { text: "q\"t" }, Label { text: "" }], note: Some("back\\slash") }"#)
    // The Debug trait's str impl is the same form.
    check(quote.debug_str(), r#""say \"hi\"""#)
    print("ok")
