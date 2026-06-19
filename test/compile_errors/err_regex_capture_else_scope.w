//! expect-check-fail: undefined variable

fn main:
    let line = "debug"
    if line =~ /^status=(\d+)$/:
        print($1)
    else:
        print($1)
