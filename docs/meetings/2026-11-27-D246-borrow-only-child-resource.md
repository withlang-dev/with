# D246 — Borrow-only child resources (`resource Part wraps *mut T` with `returns borrow Part from param N`, delegated)

**Date:** 2026-11-27. **Status:** delegated under D237 (mission-settled; Eric vetoes by revert).

**Laws:** Law 1 (*The compiler never asks for what it already knows*), Law 4 (*A fact is inferred only when being wrong cannot create unsafety*), Law 5 (*Observing is not owning; transport is not duplication*), Law 12 (*The programmer has the last word on what the compiler cannot see*).

---

## Question

C container APIs frequently expose opaque child sub-objects that have no standalone constructor or destructor — they are created inside a parent container, borrowed from it, configured through methods, and destroyed automatically when the parent is freed. The canonical example is libcurl's multipart MIME API (#3111, #3114, #3143):
- `curl_mime *curl_mime_init(CURL *easy)` / `void curl_mime_free(curl_mime *mime)` (owned parent `Mime`)
- `curl_mimepart *curl_mime_addpart(curl_mime *mime)` (returns a pointer owned by `mime`, NEVER freed directly)
- `curl_mime_name(part, ...)`, `curl_mime_filename(part, ...)`, `curl_mime_type(part, ...)`, `curl_mime_data(part, ...)` (methods on the borrowed `curl_mimepart`)

Under #3114 (`ae20d89`), declaring `resource Part wraps *mut curl_mimepart` with no `from` and no `drop` was refused at `returns borrow Part from param 0` because `FacadeRender` returned empty text when a resource had no `drop`, leaving `BorrowedPart` undefined.

Should a resource with no `from`, no `init`, no `drop`, and no `destroys` be accepted as a **borrow-only child resource** — rendering only `Borrowed<R>[Origin]` (with its `lend` methods and no owned type `R`, no `Drop`, and no constructors)?

## What the spec says

- §16.2b.3 ("Resources"): an owned resource with a producer requires a destruction contract (`drop`/`destroys`); a resource never produced as an owned value has no owned instances to destroy.
- §16.2b.6 ("Borrowed resources"): `returns borrow R from param N` yields an ephemeral `Borrowed<R>[Origin]` view carrying `R`'s non-consuming `lend` methods, no `Drop`, and bounded to the origin parameter's lifetime.

## Mission fit

- **Law 1:** *Test: does this make the programmer state something the compiler can establish, or something with no consequence?* A child handle like `curl_mimepart` has no standalone destructor in C. Refusing borrow-only resources forces callers of `curl_mime` into `unsafe` for no semantic reason.
- **Law 4:** *Test: what happens if this inference is wrong?* Nothing is inferred. The contract explicitly declares `resource Part wraps *mut curl_mimepart` (with zero owned producers, so an owned `Part` can never be constructed) and `fn curl_mime_addpart` explicitly states `returns borrow Part from param 0`. Because `BorrowedPart[Origin]` is ephemeral, carries `&Origin`, has no `Drop`, and exposes only `lend` methods, the child handle can never outlive its parent `Mime` and can never be double-freed.
- **Law 5:** *Test: does this operation create an owner the type system does not know about?* No. Zero owned `Part` values exist; every `BorrowedPart[Origin]` observes the parent `Origin` that owns it.
- **Law 12:** The contract states which C types are parent-owned child handles (`resource Part wraps *mut T`) and which functions hand out borrows of them (`returns borrow Part from param N`).

## Decision

Accept a `resource R wraps *mut T` with no `from`, `init`, `drop`, or `destroys` as a **borrow-only resource**:

- `FacadeRender` emits only `type Borrowed<R>[Origin] ephemeral { origin: &Origin, repr: *mut T }` and `impl[Origin] Borrowed<R>[Origin]:` with `R`'s `lend` methods (no owned `type R`, no `Drop`, no constructors).
- `SemaFacade` accepts `returns borrow R from param N` targeting a borrow-only resource `R`.
- A resource that states a producer (`from` / `init`) or `destroys` without a `drop` remains refused as before (§16.2b.3).
