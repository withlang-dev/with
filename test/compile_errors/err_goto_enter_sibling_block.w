//! expect-check-fail: goto would enter a block from outside

fn main:
    if true:
        goto 'sibling
    else:
        'sibling 0
