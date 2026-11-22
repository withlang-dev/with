//! expect-error: expected an indented block after ':'

// #1391 (§29.13): indentation inside braces is insignificant, but a colon
// body opened inside them still sits deeper than its statement's line.
fn h(c: bool) -> i32 {
  if c:
  return 1
  2
}

fn main:
    print(f"{h(true)}")
