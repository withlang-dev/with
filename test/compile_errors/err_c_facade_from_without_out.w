//! expect-check-fail: expected 'out param <ref>'

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c facade lib:
    resource H wraps *mut u8
        from open(param 1)

fn main:
    print("ok")
