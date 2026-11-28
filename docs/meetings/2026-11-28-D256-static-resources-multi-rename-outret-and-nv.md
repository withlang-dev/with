# D256 — Static Singleton Resources, Multi-Rename Operations, Borrowed Return-Length Out-Buffers, and Name-Value Header Slices

**Date:** 2026-11-28
**Status:** Delegated (D237 — settled by `docs/mission.md` Laws 1, 4, 5, 10, 12; Epic `#3115`, `#3141` `c.openssl`, `#3144` `c.libnghttp2`)

## Context

TLS/crypto (`openssl`) and HTTP/2 (`libnghttp2`) C libraries expose four recurring patterns that WCL previously could not model without forcing user programs into `unsafe`:

1. **Static singleton `*const T` resources (`returns static <Resource>`):** `EVP_sha256()`, `EVP_aes_256_gcm()`, `TLS_client_method()`, `TLS_server_method()`, and `BIO_s_mem()` return pointers to immortal process-static opaque algorithm/method descriptors that are never freed and are passed to other APIs expecting `*const T`.
2. **Multiple distinct `rename` presentations of one C control/dispatch function:** `EVP_CIPHER_CTX_ctrl(ctx, type, arg, ptr)` (and similar command-dispatched C functions) implements distinct safe operations for distinct command constants (`set_ivlen` with `param 1 fixed EVP_CTRL_GCM_SET_IVLEN`, `get_tag` with `buffer param 3 capacity param 2`, `set_tag` with `buffer param 3 len param 2`). `SemaFacade`'s own diagnostic already told users *"to present one C function as two operations, give each item its own 'rename' (§16.2b.11)"*, yet both `SemaFacade` and `FacadeRender` only kept one `fn` stanza per C symbol.
3. **Borrowed out-pointer buffers whose length is the return value (`buffer out param P len return`):** `nghttp2_session_mem_send(session, const uint8_t **data_ptr) -> ssize_t` writes a session-owned pointer into `*data_ptr` and returns the byte count (or negative error). Copying `0..ret` bytes into an owned `List[u8]` inside the wrapper eliminates aliasing and invalidation across subsequent calls.
4. **Name-value header-pair slices and output pairs (`nv_slice param P len param L` and `nv_out param P`):** HTTP/2 frame submission and HPACK compression (`nghttp2_submit_request`, `nghttp2_hd_deflate_hd`, `nghttp2_hd_inflate_hd2`) pass arrays of `{ name, value, namelen, valuelen, flags }` structs on input and receive one filled pair pointing into internal decoder storage on output.

## Decision

Extend WCL with the four cited clauses above:

- **`returns static <Resource>`** on a borrow-only `*const T` resource `R`: renders a safe bridge returning `Option[Borrowed<R>[i32]]` anchored to a module-level immutable static origin, composable with every operation expecting `Borrowed<R>[_]`.
- **Multiple `fn <cname>` items with distinct `rename`:** accepted in `SemaFacade` when each item for `cname` in the same contract carries a distinct `rename` clause, and rendered per-item in `FacadeRender` via active-item tracking.
- **`buffer out param P len return`:** accepts `*mut (*const byte | *mut byte)` with an integer return type; removes `P` from the presented parameters and returns `(status, List[u8])` with `0..status` bytes copied when `status > 0` and the out-pointer is non-null.
- **`nv_slice param P len param L` and `nv_out param P`:** verified against structs carrying pointer fields `name`/`value`, integer fields `namelen`/`valuelen`, and integer field `flags`. `nv_slice` presents `&List[(str, str)]` and passes `flags = 0` so C copies all bytes; `nv_out` removes `P` and returns `(List[u8], List[u8])` copied from C's output struct.

## Mission Fit

- **Law 1 (*The compiler never asks for what it already knows*):**
  - *Test: does this make the programmer state something the compiler can establish, or something with no consequence?*
  - No: the library's cited facts file states each static singleton, command dispatch, return-length out-buffer, and header-pair layout once; application code passes ordinary With values, slices, and `List[(str, str)]` with zero boilerplate.
- **Law 4 (*A fact is inferred only when being wrong cannot create unsafety*):**
  - *Test: what happens if this inference is wrong?*
  - Nothing is inferred: every static lifetime, fixed command constant, out-buffer copy length, and struct-field layout is an explicit cited contract claim verified against the imported C declaration in `SemaFacade`.
- **Law 5 (*Observing is not owning; transport is not duplication*):**
  - *Test: does this operation create an owner the type system does not know about?*
  - No: `returns static <Resource>` yields a borrow-only view with no `Drop`; `buffer out ... len return` and `nv_out` immediately copy foreign-owned bytes into owned `List[u8]` values before returning so no borrowed pointer escapes C's internal buffer; `nv_slice` passes `flags = 0` so C never retains pointers into the temporary header array.
- **Law 10 (*The mission is tested, not described*):**
  - *Test: what program would fail if this rule were quietly lost?*
  - `test/behavior/behav_d256_static_multi_nv_and_outret.with`, `uat/openssl.uat`, and `uat/libnghttp2.uat` (zero `unsafe`, zero project facades).
- **Law 12 (*The programmer has the last word on what the compiler cannot see*):**
  - Every clause is a cited registry claim in `registry/c/openssl/facts.with` and `registry/c/libnghttp2/facts.with`, checked against C signatures by `SemaFacade`.
