//! expect-stdout: ok

// Tests: pointer creation, deref, mutation through pointer,
//        pointer to struct field, pointer in function args

fn test_basic_pointer:
    var x: i32 = 42
    let p = &raw mut x
    unsafe { assert(*p == 42) }

fn test_pointer_mutation:
    var x: i32 = 10
    let p = &raw mut x
    unsafe *p = 20
    assert(x == 20)

fn test_pointer_increment:
    var x: i32 = 0
    let p = &raw mut x
    unsafe *p = unsafe *p + 1
    unsafe *p = unsafe *p + 1
    unsafe *p = unsafe *p + 1
    assert(x == 3)

fn set_to_42(p: *mut i32):
    unsafe *p = 42

fn test_pointer_as_argument:
    var x: i32 = 0
    set_to_42(&raw mut x)
    assert(x == 42)

fn swap(a: *mut i32, b: *mut i32):
    unsafe:
        let tmp = *a
        *a = *b
        *b = tmp

fn test_swap:
    var x: i32 = 10
    var y: i32 = 20
    swap(&raw mut x, &raw mut y)
    assert(x == 20)
    assert(y == 10)

fn add_to(p: *mut i32, val: i32):
    unsafe *p = unsafe *p + val

fn test_pointer_accumulate:
    var sum: i32 = 0
    add_to(&raw mut sum, 10)
    add_to(&raw mut sum, 20)
    add_to(&raw mut sum, 30)
    assert(sum == 60)

type Counter { value: i32 }

fn counter_inc(c: *mut Counter):
    unsafe (*c).value = unsafe (*c).value + 1

fn counter_get(c: *const Counter) -> i32:
    c.value

fn test_pointer_to_struct:
    var c = Counter { value: 0 }
    counter_inc(&raw mut c)
    counter_inc(&raw mut c)
    assert(counter_get(&c) == 2)

fn test_multiple_pointers:
    var a: i32 = 1
    var b: i32 = 2
    var c: i32 = 3
    add_to(&raw mut a, 10)
    add_to(&raw mut b, 20)
    add_to(&raw mut c, 30)
    assert(a == 11)
    assert(b == 22)
    assert(c == 33)

fn main:
    test_basic_pointer()
    test_pointer_mutation()
    test_pointer_increment()
    test_pointer_as_argument()
    test_swap()
    test_pointer_accumulate()
    test_pointer_to_struct()
    test_multiple_pointers()
    print("ok")
