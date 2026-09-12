fn make_pointer_compare[T: Ord](sample: &T):
    let callback: unsafe extern "C" fn(*mut u8, *mut u8) -> i32 = (a, b) => {
        let left = unsafe { &*(a as *mut T) }
        let right = unsafe { &*(b as *mut T) }
        if left < right: -1
        else if left > right: 1
        else: 0
    }
    callback

fn test_generic_closure_reference_identity:
    var left = 7
    var right = 12
    let compare = make_pointer_compare(left)
    assert(unsafe { compare((&raw mut left) as *mut u8, (&raw mut right) as *mut u8) } == -1)
    assert(unsafe { compare((&raw mut right) as *mut u8, (&raw mut left) as *mut u8) } == 1)
    assert(unsafe { compare((&raw mut left) as *mut u8, (&raw mut left) as *mut u8) } == 0)

    var wide_left: i64 = 1099511627776
    var wide_right: i64 = 7
    let wide_compare = make_pointer_compare(wide_left)
    assert(unsafe { wide_compare((&raw mut wide_left) as *mut u8, (&raw mut wide_right) as *mut u8) } == 1)

    var text_left = "alpha".clone()
    var text_right = "beta".clone()
    let text_compare = make_pointer_compare(text_left)
    assert(unsafe { text_compare((&raw mut text_left) as *mut u8, (&raw mut text_right) as *mut u8) } == -1)
