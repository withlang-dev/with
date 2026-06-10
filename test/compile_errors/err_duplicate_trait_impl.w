//! expect-error: duplicate implementation of trait for type [E1102]

trait Show:
    fn show(self: i32) -> str

impl Show for i32:
    fn show(self: i32) -> str:
        int_to_string(self)

impl Show for i32:
    fn show(self: i32) -> str:
        int_to_string(self)
