//! expect-check-fail: undefined variable

fn main:
    let line = "status=200"
    if line =~ /^status=(\d+)$/:
        assert($1 == "200")
    print($1)
