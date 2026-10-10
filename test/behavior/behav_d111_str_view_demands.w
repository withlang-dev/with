//! expect-stdout: x y tail y none

// D111 (#2271): an owned str demand is met by a copy of a str view: a final
// expression under a Result return (§4.9 wraps the payload), an if arm
// there, and a view of a view (`&&str`) matched out of `&Option[&str]`.
fn direct(text: &str) -> Result[str, str]: text

fn branchy(text: &str, stop: bool) -> Result[str, str]:
    if stop: text else: "tail"

fn first_some(o: &Option[&str]) -> str:
    match o:
        Some(s) => s
        None => "none"

fn main:
    let a: Option[&str] = Some("y")
    let b: Option[&str] = None
    print(f"{direct("x").unwrap()} {branchy("y", true).unwrap()} {branchy("y", false).unwrap()} {first_some(&a)} {first_some(&b)}")
