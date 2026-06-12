// std.testing — stable testing helpers.

extern fn with_panic(msg: str, file: str, line: i32) -> Never

pub fn assert(cond: bool, msg: str = "assertion failed", loc: str = src()) -> void:
    if not cond:
        with_panic(msg, loc, 0)

pub fn require(cond: bool, msg: str, loc: str = src()) -> void:
    if not cond:
        with_panic(msg, loc, 0)

pub fn check(cond: bool, msg: str, loc: str = src()) -> void:
    if not cond:
        with_panic(msg, loc, 0)

pub fn assert_eq[T: Eq + Debug](left: T, right: T) -> void:
    if left != right:
        with_panic(f"assertion failed: {left:?} != {right:?}", "", 0)

pub fn assert_ne[T: Eq + Debug](left: T, right: T) -> void:
    if left == right:
        with_panic(f"assertion failed: {left:?} == {right:?}", "", 0)

pub fn assert_matches_failed() -> void:
    with_panic("assertion failed: value did not match the expected pattern", "", 0)
