# D254: Dependent-Resource Parent Drop, Retained Resource Parameters, Const-Widened Handle Accessors, and Row-Pointer Buffers

- **Date:** 2026-11-27
- **Status:** Delegated (D237 — mission-settled under Laws 1, 4, 5, 10)
- **Trigger:** `#3153` (`c.libpng`), where:
  1. `png_destroy_info_struct(png_const_structrp png_ptr, png_infopp info_ptr_ptr)` requires its borrowed parent `png_ptr` to free `info_ptr`;
  2. `png_init_io(png_ptr, FILE *fp)` retains a modeled resource (`CFile`) in `png_ptr->io_ptr`;
  3. `png_get_error_ptr(png_const_structrp)` takes `*const png_struct_def` while `png_error_ptr` passes `*mut png_struct_def`;
  4. `png_read_image(png_ptr, png_bytepp image)` and `png_write_image(png_ptr, png_bytepp image)` take a C row-pointer array whose dimensions are `png_get_image_height(png_ptr, info_ptr)` rows of `png_get_rowbytes(png_ptr, info_ptr)` bytes.

## Decision

1. **Dependent-resource parent drop:** A dependent resource (one with borrowed parent slot(s) and no `independent`) may name `drop F(param N)` where another parameter `pi != N` matches the borrowed parent's representation (allowing `*mut T` to `*const T`). `Drop` passes the borrowed parent's `.repr` (selecting the live `Option[&Parent]` slot when multiple producers borrow different parents).
2. **Retained resource parameter:** `retains param N by param 0` (D250) accepts modeled resource parameters (`&CFile`) alongside buffers and value records, enforcing via MIR `FOREIGN_PAIR_RETAIN` that the retained resource outlives the receiver.
3. **Const-widened callback handle accessor:** `user_data from <fn> as &U` accepts an accessor whose parameter is `*const T` for a `handle H wraps *mut T`, widening `*mut T` to `*const T` at the accessor call.
4. **Row-pointer buffers (modes 14/15):** `buffer param P len|capacity rows height <H_FN>(param A, <R>) rowbytes <RB_FN>(param A, <R>)` presents `(image: []u8|[]mut u8, info: &<R>)`, queries height and rowbytes from C, verifies `image.len() >= h * rb`, synthesizes a temporary row-pointer array pointing into `image`, and passes `&raw mut rows[0]` to C.

## Mission Fit

- **Law 1 (The compiler never asks for what it already knows):** *Test: does this make the programmer state something the compiler can establish, or something with no consequence?* A dependent resource already carries its borrowed parent reference, `png_get_image_height`/`png_get_rowbytes` already determine row bounds, and `*mut T` already widens to `*const T`.
- **Law 4 (A fact is inferred only when being wrong cannot create unsafety):** *Test: what happens if this inference is wrong?* Every capability (`drop`, `retains`, `user_data from`, `rows height ... rowbytes ...`) is explicitly declared in the contract and checked against C types and runtime bounds (`h * rb <= image.len()`).
- **Law 5 (Observing is not owning; transport is not duplication):** *Test: does this operation create an owner the type system does not know about?* Dependent drop runs strictly before parent destruction (ephemeral borrow), retained resource parameters are lifetime-checked by `FOREIGN_PAIR_RETAIN`, and row pointers live only for the synchronous C call.
- **Law 10 (The mission is tested, not described):** *Test: what program would fail if this rule were quietly lost?* `test/behavior/behav_d254_parent_drop_and_rows.with` and `uat/libpng.uat`.
