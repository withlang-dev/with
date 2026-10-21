//! expect-stdout: 2 x!

// §4.9a (D103): a return's expression keeps its own type under the Option
// demand; a cast and a `++` at the return site lowered at the Option and
// ICE'd ("unsupported cast in MIR") when the return recorded the converted
// type on the node.
enum Kind: i32:
    A = 1
    B = 2

fn pick(raw: Option[i32]) -> Option[Kind]:
    if raw.is_none(): return None
    return raw.unwrap() as Kind

fn text(s: &str) -> Option[str]:
    if s.len() == 0: return None
    return s ++ "!"

fn main:
    print(f"{(pick(Some(2)) ?? Kind.A) as i32} {text("x") ?? "-"}")
