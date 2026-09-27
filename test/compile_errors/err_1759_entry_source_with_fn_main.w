//! expect-check-fail: file has both `fn main` and top-level executable statements
// §18.5b (D74, #1759): an entry source's top-level statements are its
// `main`, so it may not also declare `fn main`; `check` refuses it as `run`
// does (it used to report "expected declaration" instead).

fn main:
    print("explicit")

print("implicit")
