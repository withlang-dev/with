//! expect-stdout: 42
//! expect-stdout: 4294967295 -9000000000 18446744073709551615 -7 3.25
//! expect-stdout: 9 10 11 12 13 14 15 16 17 18 19 20
//! expect-stdout: 0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 9.5 10.5
//! expect-stdout: 3 hello 2.5 world 9
//! expect-stdout: 1 7 2 7 3 7
//! expect-stdout: 5
//! expect-stdout: -1
//! expect-stdout: 7|2.5|with
//! expect-stdout: 66
//! expect-stdout: 321

// D75 (§16.2b.5): a function defined with a trailing `...` reads its
// variable arguments through `var ap = va_start()` and `ap.arg[T]()`; the
// list ends with the variable's scope. It is unsafe to call.
use std.libc

unsafe fn sum(n: i32, ...) -> i32:
    var ap = va_start()
    var total: i32 = 0
    for i in 0..n:
        total = total + ap.arg[i32]()
    total

// Every promoted integer width and a double, in one list.
unsafe fn each_type(n: i32, ...):
    var ap = va_start()
    let a = ap.arg[u32]()
    let b = ap.arg[i64]()
    let c = ap.arg[u64]()
    let d = ap.arg[isize]()
    let e = ap.arg[f64]()
    print(f"{a} {b} {c} {d} {e}")

// More arguments than the registers hold: the list walks into the stack.
// The literals pass as i32, so they are read as i32: reading a wider type
// than the caller passed is C's undefined va_arg (C11 7.16.1.1p2), and on
// Windows x64 the upper half of a stack slot holding an i32 is whatever
// was there (#1912).
unsafe fn many_ints(n: i32, ...):
    var ap = va_start()
    var out = ""
    for i in 0..n:
        if i > 0: out = out ++ " "
        out = out ++ f"{ap.arg[i32]()}"
    print(out)

unsafe fn many_doubles(n: i32, ...):
    var ap = va_start()
    var out = ""
    for i in 0..n:
        if i > 0: out = out ++ " "
        out = out ++ f"{ap.arg[f64]()}"
    print(out)

// Integers, doubles and pointers interleaved: each class keeps its own
// place in the list.
unsafe fn mixed(n: i32, ...):
    var ap = va_start()
    let a = ap.arg[i32]()
    let b = CStr.from_ptr(ap.arg[*const i8]()).to_owned()
    let c = ap.arg[f64]()
    let d = CStr.from_ptr(ap.arg[*const i8]()).to_owned()
    let e = ap.arg[u64]()
    print(f"{a} {b} {c} {d} {e}")

// A list started inside a loop body ends with each iteration.
unsafe fn restart(n: i32, ...):
    var out = ""
    for i in 0..n:
        var ap = va_start()
        let first = ap.arg[i32]()
        if i > 0: out = out ++ " "
        out = out ++ f"{first + i} {ap.arg[i32]()}"
    print(out)

// An early return ends the list on its way out.
unsafe fn find(target: i32, ...) -> i32:
    var ap = va_start()
    for i in 0i32..10:
        if ap.arg[i32]() == target:
            return i
    -1

// A helper reads the list its caller started, as a C function reads a
// `va_list` parameter (SysV x86_64 passes the caller's list by place).
unsafe fn next_three(ap: c_va_list) -> i32:
    ap.arg[i32]() + ap.arg[i32]() * 10 + ap.arg[i32]() * 100

unsafe fn digits(n: i32, ...) -> i32:
    var ap = va_start()
    next_three(ap)

// An aggregate before the `...` crosses as the C convention passes it.
type Trio { a: i64, b: i64, c: i64 }

unsafe fn with_trio(t: Trio, n: i32, ...) -> i64:
    var ap = va_start()
    var total = t.a + t.b + t.c
    for i in 0..n:
        total = total + ap.arg[i64]()
    total

// The list is C's va_list: it goes on to a C v-function.
unsafe fn format(buffer: *mut i8, size: u64, fmt: *const i8, ...) -> i32:
    var ap = va_start()
    vsnprintf(buffer, size, fmt, ap)

fn main:
    print(unsafe { sum(3, 1, 2, 39) })
    let big: u64 = 18446744073709551615
    var buffer: [64]i8 = [0; 64]
    unsafe:
        each_type(5, 4294967295 as u32, -9000000000 as i64, big, -7 as isize, 3.25)
        many_ints(12, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20)
        many_doubles(11, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5)
        mixed(5, 3, "hello\0" as *const i8, 2.5, "world\0" as *const i8, 9 as u64)
        restart(3, 1, 7)
        print(find(4, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0))
        print(find(42, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10))
        let written = format(&raw mut buffer as *mut i8, 64, "%d|%.1f|%s\0" as *const i8, 7, 2.5, "with\0" as *const i8)
        assert(written == 10)
        print(CStr.from_ptr(&raw const buffer as *const i8).to_owned())
        print(with_trio(Trio { a: 1, b: 2, c: 3 }, 3, 10 as i64, 20 as i64, 30 as i64))
        print(digits(3, 1, 2, 3))
