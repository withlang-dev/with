//! expect-check-fail: undefined variable

fn main:
    let line = "status=200"
    let ready = true
    if line =~ /^status=(\d+)$/ and ready:
        print($1)
