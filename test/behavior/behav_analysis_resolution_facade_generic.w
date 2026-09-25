//! expect-stdout: ok

use pre_d_build_runner

// A raw C name selects a generic facade with fewer presented parameters.
// MIR must name the selected template, not reconstruct the raw C callee.
fn main:
    let dir = p7_prepare_case("analysis_resolution_facade_generic", "resolution_facade_generic")
    p7_write(dir, "src/main.w", "use c_import(\"static inline void each(const int *values, int count, void (*cb)(void *, int), void *data) { for (int i = 0; i < count; i++) cb(data, values[i]); }\")\nc facade values:\n    fn each\n        buffer param values len param count elements\n        callback param cb userdata param data\nfn visit(data: &i32, value: i32): assert(value == data)\nfn main:\n    let values: [i32; 1] = [7]\n    let data = 7\n    each(values, visit, data)\n")
    let result = p7_run(dir, "resolution_facade_generic", "analyze\0src/main.w\0audit:resolution\0")
    p7_assert_success(result, "generic facade resolution")
    assert(result.stdout.contains("violations=0"))
    print("ok")
