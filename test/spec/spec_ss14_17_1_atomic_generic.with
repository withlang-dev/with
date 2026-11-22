//! expect-stdout: ok

use std.sync

var counter: Atomic[i32]
var byte_counter: Atomic[u8]
var pointer_cell: Atomic[*mut i32]

fn check_compare_exchange_success:
    match counter.compare_exchange(20, 15, .SeqCst, .Acquire):
        Ok(old) => assert(old == 20)
        Err(_) => assert(false)

fn check_compare_exchange_failure:
    match counter.compare_exchange(99, 30, .SeqCst, .Relaxed):
        Ok(_) => assert(false)
        Err(actual) => assert(actual == 15)

fn check_compare_exchange_weak:
    match counter.compare_exchange_weak(15, 16, .SeqCst, .Relaxed):
        Ok(old) => assert(old == 15)
        Err(actual) => assert(actual == 15)

fn check_integer_atomics:
    let constructed: Atomic[i32] = Atomic.new(5)
    assert(constructed.load(.SeqCst) == 5)

    counter.store(1, .Release)
    assert(counter.load(.Acquire) == 1)
    assert(counter.swap(3, .SeqCst) == 1)
    assert(counter.fetch_add(4, .SeqCst) == 3)
    assert(counter.fetch_sub(2, .SeqCst) == 7)
    assert(counter.fetch_or(8, .SeqCst) == 5)
    assert(counter.fetch_and(14, .SeqCst) == 13)
    assert(counter.fetch_xor(7, .SeqCst) == 12)
    assert(counter.fetch_min(2, .SeqCst) == 11)
    assert(counter.fetch_max(20, .SeqCst) == 2)
    check_compare_exchange_success()
    check_compare_exchange_weak()
    counter.store(15, .SeqCst)
    check_compare_exchange_failure()

fn check_unsigned_min_max:
    byte_counter.store(250 as u8, .SeqCst)
    assert(byte_counter.fetch_min(3 as u8, .SeqCst) == 250 as u8)
    assert(byte_counter.load(.SeqCst) == 3 as u8)
    assert(byte_counter.fetch_max(200 as u8, .SeqCst) == 3 as u8)
    assert(byte_counter.load(.SeqCst) == 200 as u8)

fn check_pointer_atomics:
    var first = 1
    var second = 2
    let first_ptr = &raw mut first as *mut i32
    let second_ptr = &raw mut second as *mut i32
    pointer_cell.store(first_ptr, .SeqCst)
    assert(pointer_cell.load(.SeqCst) == first_ptr)
    assert(pointer_cell.swap(second_ptr, .SeqCst) == first_ptr)
    match pointer_cell.compare_exchange(second_ptr, first_ptr, .SeqCst, .Relaxed):
        Ok(old) => assert(old == second_ptr)
        Err(_) => assert(false)
    assert(pointer_cell.load(.SeqCst) == first_ptr)

fn check_legacy_atomic_i64:
    var legacy = atomic_new(10)
    assert(atomic_load(&legacy) == 10)
    legacy.store(12, .SeqCst)
    assert(atomic_load(&legacy) == 12)
    assert(legacy.add(5) == 17)
    assert(atomic_load(&legacy) == 17)

fn main:
    check_integer_atomics()
    check_unsigned_min_max()
    check_pointer_atomics()
    check_legacy_atomic_i64()
    fence(.SeqCst)
    print("ok")
