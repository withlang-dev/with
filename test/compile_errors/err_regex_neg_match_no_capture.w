//! expect-check-fail: undefined variable

fn main:
    let line = "status=200"
    if line !~ /^status=(\d+)$/:
        print($1)
