// std.ffi — boxing/unboxing closure context across C callback boundaries (§16.7).
//
// The C callback pattern is `extern "C" fn(ctx: *mut c_void, ...)` plus a
// `*mut c_void` context and a `destroy` hook. `box_ctx` moves a With value onto
// the heap and hands back the type-erased pointer for the `ctx` slot. The
// recovery helpers take a typed `*mut T` — inside the callback you cast the
// incoming `ctx` back to its real type (`ctx as *mut State`) and the helper's
// `T` is inferred from that pointer. (A turbofish form like `unbox_ctx[State](ctx)`
// is not yet expressible: explicit type arguments on a free generic function
// with value arguments are unsupported, so `T` must be carried by the argument.)
//
// `box_ctx` is `Box.new(value)` erased to `*mut c_void`: `Box.new` moves the
// value to the heap (consuming it, so it is not dropped), and casting the box
// to a raw pointer surrenders ownership of that allocation without running the
// box's `Drop`. Recovery reads the value back and frees the same allocation, so
// the value's `Drop` runs exactly once — at `unbox_ctx`/`drop_ctx`, never at
// box time.
//
// Boxing is safe; the unsafe boundary is exactly on the recovery side, where
// the caller asserts the pointer really is a live `T` (§16.11, the
// raw-pointer-to-reference boundary).

use std.box

extern fn with_free(ptr: *i8) -> Unit

/// Heap-allocate `value` and return a type-erased context pointer suitable for
/// a C callback's `void *ctx` slot. `value`'s `Drop` is deferred until
/// `unbox_ctx` or `drop_ctx` — do not let the pointer leak. `T` is inferred
/// from `value`.
///
/// `T` must be an owned (non-ephemeral) type: the value outlives the call, so
/// boxing a borrow-holding ephemeral would let the borrow escape. This is not
/// yet rejected at compile time (the type-erased copy hides the escape — the
/// same gap as `Box.new[T]`); the recovery helpers are `unsafe`, so the
/// caller's liveness assertion is the backstop.
pub fn box_ctx[T](value: T) -> *mut c_void:
    Box.new(value) as *mut c_void

/// Borrow the boxed context immutably. The caller recovers the type by casting
/// (`ctx_ref(cb.ctx as *mut State)`) and asserts the pointer is a live `T`.
/// For mutation, write through the `*mut T` directly under `unsafe`
/// (`(*p).field = ...`).
pub unsafe fn ctx_ref[T](ctx: *mut T) -> &T:
    (ctx as *const T) as &T

/// Move the boxed value out and free its allocation (consuming unbox). After
/// this call the pointer is dangling; do not reuse it.
pub unsafe fn unbox_ctx[T](ctx: *mut T) -> T:
    let value = *ctx
    with_free(ctx as *i8)
    value

/// Run `T`'s drop glue and free the allocation, for wiring into a C API's
/// `destroy` slot via a per-type named trampoline (see the module note).
pub unsafe fn drop_ctx[T](ctx: *mut T) -> Unit:
    let value = *ctx
    drop(value)
    with_free(ctx as *i8)

// Note: generic functions cannot coerce to `extern "C" fn` directly (no
// per-instantiation C-ABI symbol guarantee yet), so a generic
// `destroy_trampoline[T]` is intentionally not provided — shipping one would
// hand out a wrong-ABI pointer. Instead write a two-line per-type trampoline:
//
//     fn destroy_state(ctx: *mut c_void):
//         unsafe { drop_ctx(ctx as *mut State) }
//
// and store `destroy_state` (a non-capturing named fn, which does coerce) in
// the `destroy` slot.
