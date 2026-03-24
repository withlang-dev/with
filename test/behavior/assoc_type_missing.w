//! expect-error: impl missing required associated type 'Item'
extern fn print(s: str) -> void

trait Container =
    type Item
    fn size(self: Self) -> i32

type Empty { x: i32 }

// Missing 'type Item = ...' — should error
impl Container for Empty =
    fn size(self: Empty) -> i32:
        0
