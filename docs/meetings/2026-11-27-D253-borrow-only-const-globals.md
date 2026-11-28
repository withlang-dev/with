# D253: Borrow-Only `*const T` Resources From Immutable C Globals

- **Date:** 2026-11-27
- **Status:** Delegated (D237 — mission-settled under Laws 1, 4, 5, 10)
- **Trigger:** `#3163` (`c.protobuf-c`), where `protoc-c` emits static read-only `extern const ProtobufCMessageDescriptor <msg>__descriptor;` descriptors passed to `protobuf_c_message_unpack`, `protobuf_c_message_descriptor_get_field_by_name`, and `protobuf_c_message_descriptor_get_field`.

## Decision

When a contract declares a borrow-only resource `resource R wraps *const T` (D246, no `from`/`init`/`drop`/`destroys`), and the compilation unit's `c_import` headers declare immutable C globals `extern let G: T` (`NK_EXTERN_VAR` with `flags % 2 == 0`, i.e., `extern const T G;` in C):

1. `FacadeRender` emits `type BorrowedR[Origin] ephemeral` and its `impl[Origin] BorrowedR[Origin]` methods even when no `returns borrow R from param N` function exists.
2. For each immutable C global `G: T`, `FacadeRender` emits `pub type R {}` and `pub fn R.G() -> BorrowedR[T]` borrowing `&G` and `&raw const G`.
3. Direct-return resource producers taking a borrow-only resource parameter thread `bridge.generics` (`[__FO0]`) into `fn R.<ctor>[__FO0](...)`.
4. `CiFacts` accepts `resource R wraps *const T` alongside `wraps *mut T` and carries borrow-only `*const` resources into drafted contracts.

## Mission Fit

- **Law 1 (The compiler never asks for what it already knows).** *Test: does this make the programmer state something the compiler can establish, or something with no consequence?* The C header already declares `extern const T G;` and the contract already states `resource R wraps *const T`. Requiring the programmer to write `unsafe` or a per-schema project contract merely to borrow a `const` C descriptor global forces ceremony for a fact the compiler already knows.
- **Law 4 (A fact is inferred only when being wrong cannot create unsafety).** *Test: what happens if this inference is wrong?* Restricted strictly to immutable (`const` in C) `extern let` globals whose type exactly matches the pointee `T` of a `*const T` borrow-only resource. Mutable globals, user-constructed structs, and `*mut` resources are excluded; static `const` C globals live for the process, cannot be forged in safe With code, and are never freed.
- **Law 5 (Observing is not owning; transport is not duplication).** *Test: does this operation create an owner the type system does not know about?* The returned `BorrowedR[T]` is an ephemeral borrowed view with no `Drop`, observing `&G`.
- **Law 10 (The mission is tested, not described).** *Test: what program would fail if this rule were quietly lost?* `test/behavior/behav_d253_borrow_only_const_global.with` and `uat/protobuf_c.uat`.
