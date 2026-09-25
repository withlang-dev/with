//! expect-stdout: ok

// D68: use C itself as the oracle, across the binary64 range. This is a
// compiler/runtime conformance test, so the raw foreign buffer stays here.
extern fn snprintf(buffer: *mut u8, capacity: usize, format: *const u8, ...) -> i32

fn check_text(actual: &str, expected: &[2048]u8, n: i32):
    assert(n >= 0 and n < 2048)
    assert(actual.len() == n as i64)
    for i in 0..n as i64:
        assert(actual.byte_at(i) == expected[i] as i32)

fn compare_c(x: f64):
    var buffer: [2048]u8 = [0 as u8; 2048]
    let ptr = &raw mut buffer as *mut u8
    let n = unsafe { snprintf(ptr, 2048 as usize, c"%g".ptr, x) }
    check_text(f"{x}", buffer, n)
    let ng = unsafe { snprintf(ptr, 2048 as usize, c"%.30g".ptr, x) }
    check_text(f"{x:.30g}", buffer, ng)
    let nf0 = unsafe { snprintf(ptr, 2048 as usize, c"%.0f".ptr, x) }
    check_text(f"{x:.0f}", buffer, nf0)
    let nf = unsafe { snprintf(ptr, 2048 as usize, c"%.2f".ptr, x) }
    check_text(f"{x:.2f}", buffer, nf)
    let nf30 = unsafe { snprintf(ptr, 2048 as usize, c"%.30f".ptr, x) }
    check_text(f"{x:.30f}", buffer, nf30)
    let nf1100 = unsafe { snprintf(ptr, 2048 as usize, c"%.1100f".ptr, x) }
    check_text(f"{x:.1100f}", buffer, nf1100)
    let ne = unsafe { snprintf(ptr, 2048 as usize, c"%.30e".ptr, x) }
    check_text(f"{x:.30e}", buffer, ne)
    let ne1100 = unsafe { snprintf(ptr, 2048 as usize, c"%.1100e".ptr, x) }
    check_text(f"{x:.1100e}", buffer, ne1100)

fn sweep(start: f64):
    var x = start
    var i = 0
    while i < 320:
        if i % 11 == 0:
            compare_c(x)
            compare_c(-x)
        x = x / 10.0
        i = i + 1
    x = start * 10.0
    i = 1
    while i < 309:
        if i % 11 == 0:
            compare_c(x)
            compare_c(-x)
        x = x * 10.0
        i = i + 1

fn main:
    sweep(1.0)
    sweep(1.5)
    sweep(20.0 / 3.0)
    sweep(30.0 / 7.0)
    sweep(355.0 / 113.0)
    compare_c(0.0)
    compare_c(-0.0)
    compare_c(5e-324)
    compare_c(1.7976931348623157e308)
    compare_c(0.00009999999)
    compare_c(999999.9)
    compare_c(0.125)
    compare_c(0.375)
    compare_c(0.5)
    compare_c(1.5)
    compare_c(2.5)
    compare_c(9.9999)
    print("ok")
