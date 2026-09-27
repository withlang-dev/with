//! expect-stdout: after arm 5
//! expect-stdout: after arm 5
//! expect-stdout: after loop 205
//! expect-stdout: after loop 205
//! expect-stdout: after else 212
//! expect-stdout: total 212

// §2.5, #1559: a body that is no block — `if c:` then one `let` on its own
// line, a one-statement `while` or `else` body — is the body's own scope.
// Its binding drops at the body's end, on the body's path. It used to join
// the enclosing scope and drop at that scope's exit: after the `print`,
// and on the path that never ran the body too, where the storage was never
// written — the base ran T's destructor over stale stack (total 199, not
// 205). validate-all's Maybe-drop rule named it (cp_patched_text's
// `if ...: let _last = file.pop()`).

var dropped = 0

type T { id: i32 }
impl Drop for T:
    move fn drop():
        dropped += self.id

fn arm(c: bool, id: i32):
    if c:
        let _t = T { id }
    print(f"after arm {dropped}")

var ticks = 0

fn tick() -> i32:
    ticks += 1
    ticks

fn body(n: i32, id: i32):
    ticks = 0
    while tick() <= n:
        let _t = T { id: id / 2 }
    print(f"after loop {dropped}")

fn pick(c: bool, id: i32):
    if c:
        print("then")
    else:
        let _t = T { id }
    print(f"after else {dropped}")

fn main:
    arm(true, 5)
    arm(false, 7)
    body(2, 200)
    body(0, 1000)
    pick(false, 7)
    print(f"total {dropped}")
