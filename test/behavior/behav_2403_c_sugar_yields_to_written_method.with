//! expect-stdout: 7
// #2403 (§16.2a): "User-written `impl` methods always take priority over
// auto-generated ones." The written `b2403_doc.root` named like the method
// c_import generates from `b2403_doc_root`; both were registered and MIR
// lowered the generated body unchecked: "BUG: call of `b2403_doc_root` has
// callee kind 0".
use c_import("behav_2403_c_sugar_yields_to_written_method.h")

impl b2403_doc:
    fn root() -> i32: 7

fn main:
    let d = unsafe { b2403_doc_parse(c"x".ptr) }
    print(unsafe { (*d).root() })
