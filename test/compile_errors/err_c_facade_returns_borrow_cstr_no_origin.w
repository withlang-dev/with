//! expect-check-fail: fn 'strchr': 'returns borrow CStr from param 1' names param 1: i32 c, which receives no modeled resource and is not a C string; a borrowed CStr is a view of the resource or the C string its origin parameter receives, or of a domain ('from domain <name>') — With does not invent an origin (§16.2b.7)

// D51 stage 7 (ruling §31: "Borrowed foreign memory always has an origin …
// With does not invent lifetimes"): the origin parameter must receive a
// resource or a C string.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    fn strchr
        returns borrow CStr from param 1

fn main:
    print("unreached")
