//! skip-windows: issue #798: regex-literal comptime validation crashes (0xC0000005) on native Windows
//! expect-check-fail: undefined variable

fn main:
    if "abc" =~ /(a)/:
        assert($1 == "a")
    print($1)
