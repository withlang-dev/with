// Spec test: Section 3.4 — Returning References (formerly 25.3)

let shared_global: i32 = 99

type ReturnRefBuf {
    data: i32,
}

fn same_ref(x: &i32) -> &i32:
    x

fn borrowed_field_ref(b: &ReturnRefBuf) -> &i32:
    &b.data

fn maybe_ref(x: &i32, take: bool) -> Option[&i32]:
    if take: Some(x) else: None

fn global_ref() -> &i32:
    &shared_global

fn test_return_ref_use_locally:
    let x = 42
    let r = same_ref(&x)
    assert(*r == 42)

fn test_return_ref_from_borrowed_field:
    let b = ReturnRefBuf { data: 13 }
    let r = borrowed_field_ref(&b)
    assert(*r == 13)

fn test_return_option_ref_use_locally:
    let x = 7
    let r = maybe_ref(&x, true)
    match r:
        Some(v) => assert(*v == 7)
        None => assert(false)

fn test_return_option_ref_none:
    let x = 7
    let r = maybe_ref(&x, false)
    match r:
        Some(_) => assert(false)
        None => assert(true)

fn test_return_global_ref:
    let r = global_ref()
    assert(*r == 99)
