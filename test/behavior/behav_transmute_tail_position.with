//! expect-stdout: ok

// Generic type-argument builtins (transmute, chan) have no signatures, so
// their call types must be recorded by Sema at the call node. Unrecorded,
// MirLower re-derived void and a tail-position transmute silently returned
// the function's default value instead of the transmuted bits.

type RawFn0I32 {
    fn_ptr: *const u8,
    ctx: *mut u8,
}

fn worker() -> i32: 29

fn tail_prefix(w: fn() -> i32) -> RawFn0I32:
    unsafe transmute[RawFn0I32](w)

fn tail_brace(w: fn() -> i32) -> RawFn0I32:
    unsafe { transmute[RawFn0I32](w) }

fn tail_block(w: fn() -> i32) -> RawFn0I32:
    unsafe:
        transmute[RawFn0I32](w)

unsafe fn tail_plain(w: fn() -> i32) -> RawFn0I32:
    transmute[RawFn0I32](w)

fn let_annotated(w: fn() -> i32) -> RawFn0I32:
    let raw: RawFn0I32 = unsafe transmute[RawFn0I32](w)
    raw

fn let_unannotated(w: fn() -> i32) -> RawFn0I32:
    let raw = unsafe { transmute[RawFn0I32](w) }
    raw

// Round-trip: a correct pair must be callable again. Thunk addresses differ
// between coercion sites, so bit-comparing two pairs would over-constrain.
fn call_back(raw: RawFn0I32) -> i32:
    let f: fn() -> i32 = unsafe transmute[fn() -> i32](raw)
    f()

fn check(label: str, raw: RawFn0I32) -> i32:
    if raw.fn_ptr == 0 as *const u8:
        print(label ++ ": zero fn_ptr")
        return 1
    if call_back(raw) != 29:
        print(label ++ ": wrong result")
        return 1
    0

fn main:
    var bad = check("tail_prefix", tail_prefix(worker))
    bad = bad + check("tail_brace", tail_brace(worker))
    bad = bad + check("tail_block", tail_block(worker))
    bad = bad + check("tail_plain", unsafe { tail_plain(worker) })
    bad = bad + check("let_annotated", let_annotated(worker))
    bad = bad + check("let_unannotated", let_unannotated(worker))
    if bad == 0: print("ok")
