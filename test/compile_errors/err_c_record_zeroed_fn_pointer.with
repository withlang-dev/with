//! expect-check-fail: 'Stream.zeroed()' is not available: field 'notify' (

// §16.2b.3 (D101): `zeroed()` is safe only when all-zero bits are a value of
// every field's With type. A non-null `extern "C" fn` has no all-zero value
// (D102: a C import's function-pointer field is `Option`, which does; this
// hand-written C mirror keeps the non-null type), so the record has no
// `zeroed()`; the refusal names the field.
@[repr(C)]
type Stream { state: i32, notify: extern "C" fn(i32) -> Unit }

fn main:
    let s = Stream.zeroed()
    print(s.state)
