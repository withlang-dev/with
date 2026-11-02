//! expect-stdout: 1
//! expect-stdout: 2 hello!
//! expect-stdout: 3
//! expect-stdout: ok

// D184 (§29.15): a script's top-level `let`/`var` are module globals
// assigned in statement order, so a helper fn sees them; a pattern binding
// stays a local of the implicit main.

var count = 0
let greeting = "hello"

fn bump(): count = count + 1
fn shout() -> str: greeting ++ "!"

bump()
print(count)
bump()
print(f"{count} {shout()}")
let (a, b) = (1, 2)
print(a + b)
print("ok")
