// Regression for #302: generic functions honor default parameter values.
// Previously a generic call that omitted a trailing default failed with
// "wrong argument count" (Sema), and even when accepted the default was not
// filled at lowering for generic calls (LLVM arg-count mismatch).

fn choose[T: Debug](x: T, y: T, use_first: bool = true) -> T:
    if use_first: x else: y

fn label[T: Debug](x: T, n: i32, sep: str = "::") -> str:
    sep

fn main:
    // Default (use_first = true) omitted -> returns x.
    assert(choose(1, 2) == 1)
    assert(choose("a", "b") == "a")
    // Explicit value for the defaulted param -> returns y.
    assert(choose(1, 2, false) == 2)
    assert(choose("a", "b", false) == "b")

    // Trailing str default omitted vs provided (the assert_eq `loc` shape).
    assert(label(1, 0) == "::")
    assert(label(1, 0, "--") == "--")
