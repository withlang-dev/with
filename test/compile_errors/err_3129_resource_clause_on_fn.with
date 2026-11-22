//! expect-check-fail: applies to a resource, not an fn item
//! expect-check-fail: = help: move 'drop' under the 'resource <Name>' item it describes

// #3129 (§16.2b): a resource's clause under an fn item.
use c_import("static inline int step(int a) { return 0; }\n")

c contract steps:
    fn step
        drop step

fn main:
    print("unreachable")
