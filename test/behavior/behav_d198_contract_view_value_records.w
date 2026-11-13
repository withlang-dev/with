//! expect-stdout: ok

use pre_d_build_runner

// D198 (§16.2b.5): the contract view states a value record by what the
// callee does with it and how it is presented, with the clause as its
// provenance. The view had no row for `reads`, `fills` or `updates`: the
// parameter showed only the default "lend, the described fn's assertion".
fn main:
    let dir = p7_prepare_case("d198_contract_view_value_records", "contract_view_value_records")
    p7_write(dir, "src/main.w", "use c_import(\"typedef struct { int w; int h; } Size; static inline int area(const Size *s) { return s->w * s->h; } static inline void unit(Size *s) { s->w = 1; s->h = 1; } static inline void grow(Size *s) { s->w = s->w + 1; }\")\n\nc contract sizes:\n    fn area\n        reads param s\n    fn unit\n        fills param s\n    fn grow\n        updates param s\n\nfn main:\n    print(f\"{area(Size { w: 2, h: 3 })}\")\n")
    let view = p7_run(dir, "contract", "analyze\0src/main.w\0contract\0")
    p7_assert_success(view, "the contract view")
    let ok = view.stdout.contains("value record, reads; presented as &T") and view.stdout.contains("value record, fills; With passes T.zeroed()") and view.stdout.contains("value record, updates; presented as a mut parameter") and view.stdout.contains("[claim: stated@")
    if not ok: print(view.stdout)
    assert(ok)
    print("ok")
