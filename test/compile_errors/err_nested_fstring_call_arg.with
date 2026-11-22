//! expect-check-fail: nested f-strings are not allowed

fn id(s: str) -> str: s

fn main:
    let x = 7
    let _s = f"outer {id(f\"inner {x}\")} end"
