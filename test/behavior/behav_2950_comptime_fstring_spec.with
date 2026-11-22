//! expect-stdout: [  42]
//! expect-stdout: [3.14]
//! expect-stdout: [ab  ]
//! expect-stdout: [002a]
// §17 (#2950): a format spec in a comptime f-string formats as the runtime
// one does.
const WIDE: str = comptime f"[{42:4}]"
const PREC: str = comptime f"[{3.14159:.2}]"
const LEFT: str = comptime f"[{"ab":<4}]"
const HEX: str = comptime f"[{42:04x}]"
fn main:
    print(WIDE)
    print(PREC)
    print(LEFT)
    print(HEX)
