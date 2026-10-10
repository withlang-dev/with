# 19. Safety Boundaries

### 19.1 Safe by Default

All code is safe unless explicitly `unsafe`.

### 19.2 `unsafe` Required For

- Raw pointer dereference
- Raw pointer indexing
- Manual `extern` calls and raw/unmodeled ABI calls
- Inline assembly (`asm` expressions)
- Intrusive / self-referential structures
- Manual memory management beyond allocators
- Calling functions marked `unsafe`

### 19.2a `unsafe fn` — Function-Level Unsafe Context

Functions that pervasively perform unsafe memory accesses may be
declared `unsafe fn`:

```
unsafe fn sha256_compress(ctx: *mut Sha256):
    ctx.state[0] +%= a          // raw pointer indexing permitted
    let b = ctx.buf[off]        // auto-deref through pointer permitted
```

Inside an `unsafe fn` body, all operations that would normally
require `unsafe`, `unsafe:`, or `unsafe {}` are permitted without a wrapper.
The `unsafe` keyword on the function signature is the declaration
of intent — every line in the body is implicitly unsafe.

**Callers must acknowledge the unsafety:** Calling an `unsafe fn`
from safe code requires an unsafe block at the call site (or being
inside another `unsafe fn`):

```
unsafe { sha256_compress(&raw mut ctx) }    // caller acknowledges
```

This preserves the audit trail — `grep unsafe` finds every
boundary where safe code transitions to unsafe code.

### 19.3 `unsafe` Constraints Across Suspension Points

**Language rule:** Unsafe code must not retain raw pointers (`*const T`,
`*mut T`) to fiber stack locals across `await` points. A raw pointer
to a stack-allocated value is valid only until the next `await` in the
same fiber.

```
// UNDEFINED BEHAVIOR:
async fn bad:
    let x = 42
    let p: *const i32 = &raw x
    some_io().await          // stack may be relocated
    unsafe { *p }            // UB: p may be dangling

// OK: pointer used before await
async fn ok:
    let x = 42
    let p: *const i32 = &raw x
    unsafe { use(p) }        // fine: no intervening await
    some_io().await
```

Safe code is not affected by this rule — ephemeral references across
`await` points are handled correctly by the compiler. This constraint
applies only to raw pointers obtained through `unsafe`.

### 19.4 Unnecessary `unsafe` is a Compile Error

An `unsafe` block that contains no unsafe operations is a compile
error:

```
// ERROR: unnecessary unsafe block
unsafe {
    let x = 1 + 2    // nothing here requires unsafe
}
```

Every `unsafe` block in a codebase is a place reviewers must
scrutinize. False positives dilute that signal. If the block contains
no raw pointer dereference, no raw ABI call, and no `unsafe fn` call,
the compiler rejects it.

**Proof-dependent operations are the exception.** Some operations
require `unsafe` only when a whole-program proof fails — e.g. bare
global mutation under §9.1c's single-thread proof. When the compiler
*can* prove such an operation safe, an `unsafe` block containing it
produces a **warning** (not an error): otherwise, improving the
compiler's proof precision would turn previously-required `unsafe`
blocks into hard errors and break existing code. Categorically safe
contents (plain arithmetic, safe calls) remain a hard error as above.

---
