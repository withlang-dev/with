# D255 — C Struct-Prefix Subtyping, Fat-Pointer/Iovec Buffers, and Async Event-Loop Handles/Requests

**Date:** 2026-11-27
**Status:** Delegated (D237 — settled by `docs/mission.md` Laws 1, 4, 5, 10, 12; Epic `#3115`, `#3160` `c.libuv`)

## Context

Event-loop and POSIX networking C libraries (`libuv`, BSD sockets, GTK/GObject, X11) share five general C patterns that WCL previously could not describe without forcing user programs into `unsafe`:

1. **C struct-prefix inheritance (`extends Base`):** Concrete handle structs (`uv_tcp_t`, `uv_timer_t`) share an identical leading field prefix with abstract base handles (`uv_stream_t`, `uv_handle_t`), and base operations (`uv_close`, `uv_listen`, `uv_handle_get_loop`) accept the base pointer.
2. **C struct-prefix value records (`reads|fills|updates param N as T [len param L]`):** Socket APIs (`uv_tcp_bind`, `uv_tcp_getsockname`) accept `const struct sockaddr *` / `struct sockaddr *` + `int *namelen` while callers pass concrete flat records (`struct sockaddr_in`).
3. **Fat-pointer / iovec buffer struct arrays (`buffer param P len|capacity param L via <init_fn>`):** Scatter-gather I/O (`uv_fs_read`, `uv_fs_write`, `uv_try_write`, `uv_write`) accepts `(const uv_buf_t bufs[], unsigned int nbufs)` initialized via a portable constructor (`uv_buf_init`).
4. **Borrowed views of in-place resources (`returns borrow R from param N` on an in-place resource `R`):** `uv_handle_get_loop(const uv_handle_t *) -> uv_loop_t *` returns a borrowed pointer to a caller-initialized `Loop`, which callbacks pass to `Tcp.init_on(&borrowed_loop)`.
5. **Async-closed handles and heap-owned async requests (`async_close <close> check <check>`, `read_pair alloc param A via <buf_init> read param R via <set>, <get>`, `close_release via <get>, <set>`, `async_req param R via <set>, <get>`):** Event-loop handles cannot be freed synchronously until their close callback runs, and async write requests must own their request struct and byte copy until the write completion callback finishes.

## Decision

Extend WCL with the five cited clauses above:

- `resource R wraps T extends Base` / `handle H wraps *mut T extends Base`: inherits `Base`'s operations onto `R`/`H` with pointer upcast.
- `reads|fills|updates param N as T [len param L]`: presents a flat concrete record `&T` / filled `T` (and initializes `len` to `sizeof[T]()`).
- `buffer param P len|capacity param L via <init_fn>`: presents `[]u8` / `[]mut u8`, constructing a single-element descriptor via `<init_fn>` and passing `(&buf, 1)`.
- `returns borrow R from param N` on an in-place resource `R`: renders `Borrowed<R>[Origin]` wrapping `*mut Repr` and emits `<Child>.<init>_on[Origin](&Borrowed<R>[Origin])` for async-close children.
- `async_close`, `read_pair`, `close_release`, `async_req`: safely manage heap-pinned handles, alloc/read callback buffers, and async write requests with zero leaks, zero use-after-free, and zero `unsafe` in user code.

## Mission Fit

- **Law 1 (*The compiler never asks for what it already knows*):**
  - *Test: does this make the programmer state something the compiler can establish, or something with no consequence?*
  - No: the library's cited facts file states the struct-prefix subtyping, iovec constructor, and async-completion ownership once; application code passes ordinary With slices, `&sockaddr_in`, and safe callbacks with zero boilerplate.
- **Law 4 (*A fact is inferred only when being wrong cannot create unsafety*):**
  - *Test: what happens if this inference is wrong?*
  - Nothing is inferred: every subtyping relation, record cast, iovec constructor, and async-close / async-request lifecycle is an explicitly stated, cited contract claim verified against C signatures in `SemaFacade`.
- **Law 5 (*Observing is not owning; transport is not duplication*):**
  - *Test: does this operation create an owner the type system does not know about?*
  - No: scope-owned handles drop via `async_close` (reclaiming immediately if already closing, or scheduling a freeing close callback otherwise); `read_pair` consumes the handle (`move fn`, `self.live = false`) and transfers ownership to `close_release`; `async_req` owns its request struct and copied byte buffer until its completion callback runs or the call fails.
- **Law 10 (*The mission is tested, not described*):**
  - *Test: what program would fail if this rule were quietly lost?*
  - `test/behavior/behav_d255_subtypes_iovec_and_async.with` and `uat/libuv.uat` (`uat/fixtures/libuv_main.with`, zero `unsafe`, zero project facade).
- **Law 12 (*The programmer has the last word on what the compiler cannot see*):**
  - Every clause is a cited registry claim in `registry/c/libuv/facts.with` with full Sema type/signature checking.
