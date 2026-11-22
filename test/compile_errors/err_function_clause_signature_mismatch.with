//! expect-error: function clause signature mismatch for 'bad'

fn bad(Some(x): Option[i32]) -> i32:
    x

fn bad(None: Option[i32]) -> str:
    "none"

fn main:
    let _ = bad(Some(1))
