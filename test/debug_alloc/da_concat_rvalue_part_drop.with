//! expect-debug-alloc: leak count=0

// #747: ordinary ++ observes its operands. Named owners retain their scope
// drops, but an anonymous owned rvalue part (a call/slice result) has no
// later owner — MirLower takes it as a statement temporary dropped at the
// pending-reset flush. It must neither leak (temp orphaned) nor double-free
// (named observe preserved).
fn shout(s: &str): s ++ "!"

fn main:
    let text = "abcdef".to_owned()
    let left = text.slice(1, 3) ++ "]"
    let right = "[" ++ text.slice(2, 5)
    let mid = "[" ++ text.slice(1, 5) ++ "]"
    print(left)
    print(right)
    print(mid)
    print(shout(text))
    print(text)
