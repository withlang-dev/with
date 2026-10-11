//! expect-error: use of moved value

// D116 (§15.4.9): elements that are not Copy move, so a List operand of
// them is at its last use; a later use is the usual moved-value error
// (`.clone()` is the spelling for a copy).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): print(f"drop {self.id}")
fn main:
    let toks = [Tok { id: 1 }]
    let joined = toks ++ [Tok { id: 3 }]
    print(f"{joined.len()} {toks.len()}")
