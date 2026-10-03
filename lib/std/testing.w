// std.testing — stable testing helpers.

extern fn with_panic(msg: str, file: str, line: i32) -> Never

// `assert`, `require` and `check` are compiler-known forms, not functions
// (§18.2, D86): a call evaluates `cond`, and only when it is false
// evaluates `msg` and `loc` and calls the declaration, which must not
// return on a false condition. They cannot be used as values.
pub fn assert(cond: bool, msg: str = "assertion failed", loc: str = src()) -> Unit:
    if not cond:
        with_panic(msg, loc, 0)

pub fn require(cond: bool, msg: str, loc: str = src()) -> Unit:
    if not cond:
        with_panic(msg, loc, 0)

pub fn check(cond: bool, msg: str, loc: str = src()) -> Unit:
    if not cond:
        with_panic(msg, loc, 0)

pub fn assert_eq[T: Eq + Debug](left: T, right: T) -> Unit:
    if left != right:
        with_panic(f"assertion failed: {left:?} != {right:?}", "", 0)

pub fn assert_ne[T: Eq + Debug](left: T, right: T) -> Unit:
    if left == right:
        with_panic(f"assertion failed: {left:?} == {right:?}", "", 0)

pub fn assert_matches_failed() -> Unit:
    with_panic("assertion failed: value did not match the expected pattern", "", 0)
