//! expect-build-fail: file has both `fn main` and top-level executable statements

fn main:
    print("explicit")

print("top-level")
