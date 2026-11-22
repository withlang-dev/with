//! expect-exit: 0

// D27 E1: `&place as *T` keeps address semantics and never materializes the
// pointee before the cast.

type AddressFixture {
    bytes: [32]u8,
}

fn main:
    var arr: [3]i32 = [7, 8, 9]
    let p = &arr[0] as *const i32
    let first = unsafe *p
    assert(first == 7)

    let grouped = &(arr[2]) as *const i32
    let third = unsafe *grouped
    assert(third == 9)

    // Transparent unsafe/grouping wrappers must preserve the same element
    // place and exact &T type as the direct spelling above.
    let wrapped = &(unsafe p[1]) as *const i32
    let second = unsafe *wrapped
    assert(second == 8)

    var fixture = AddressFixture { bytes: [7 as u8; 32] }
    let fixture_ptr = &raw const fixture
    let nested = &(unsafe fixture_ptr.bytes[0]) as *const u8
    let nested_first = unsafe *nested
    assert(nested_first == 7)

    let nested_raw = &raw const (unsafe fixture_ptr.bytes[1])
    let nested_raw_second = unsafe *nested_raw
    assert(nested_raw_second == 7)
