//! check-only
//! args: --no-std

// Spec test: Section 18.7 - FixedString[N] is the stack-owned
// string option available in freestanding core code.

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    var s = FixedString[8].new()
    if not s.is_empty():
        return 1
    if s.capacity() != 8:
        return 2
    if not s.push_str("core"):
        return 3
    if s.len_i32() != 4:
        return 4
    if not s.equals("core"):
        return 5
    0
