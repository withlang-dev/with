//! skip-windows: issue #798: regex-literal comptime validation crashes (0xC0000005) on native Windows
//! expect-check-fail: undefined variable

fn main:
    let line = "status=200"
    if line =~ /^status=(\d+)$/:
        assert($1 == "200")
    print($1)
