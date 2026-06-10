//! expect-error: orphan rule violation: impl requires a local trait or local type [E1101]

impl Debug for i32:
    fn debug(self: i32) -> str:
        int_to_string(self)
