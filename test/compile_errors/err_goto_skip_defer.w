//! expect-check-fail: goto would skip deferred cleanup registration

fn main:
    goto 'after
    defer: print("cleanup")
    'after return
