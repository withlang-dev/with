//! check-only

// §9.1c under D30: a program that never runs concurrently mutates its
// globals freely, also when the runtime is compiled into the unit. The
// runtime's own `@[c_export]` entry point (`__isPlatformVersionAtLeast`,
// for clang's @available) is not the program's concurrency, and counting
// it made every global write E0921 "may race" under the lane.
var COUNT = 0

fn bump(): COUNT = COUNT + 1

fn main:
    bump()
    bump()
    print(f"{COUNT}")
