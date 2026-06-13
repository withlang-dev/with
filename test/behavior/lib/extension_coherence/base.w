pub type Target {
    value: i32,
}

extend Target:
    pub fn label(self: &Self) -> str:
        "base"
