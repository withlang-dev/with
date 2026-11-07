# D194 — A retained pointer case of a variadic contract borrows caller-managed storage

**Laws:** 1, 2, 4 (docs/mission.md). Ruling §9 "never half-model
unsafely", §16.2b.5, §16.2b.9, §16.3c.

**Date:** 2026-11-07. **Status:** ruled by Eric on #3010 (ownership and
C interop: not delegable under D98).

**Question.** `curl_easy_setopt(h, CURLOPT_POSTFIELDS, p)` keeps `p` and
reads it at `curl_easy_perform`. The facade engine refused `case CONST:
<type> retains by param N` for a non-callback pointer, and the libcurl
facade left the option raw under `unsafe`. What is the retained thing, and
what lifetime does the resource impose on it?

**Ruling.**
1. The retained value is a borrow of caller-managed storage (§16.3c:
   `&CString`, the common one; `&CStr`; any type the engine classifies as
   caller-managed), held by the resource `by param N` names under the
   §16.2b.9 "Retained borrows" window: the resource is ephemeral while any
   retention is live, through `perform`, so a handle holding a `POSTFIELDS`
   borrow cannot be returned or stored unless the storage outlives it. A
   `str` in the slot is refused; the fix is an owned C string bound to a
   local that outlives the retention.
2. The window ends at destruction, at the abandonment path, when the same
   case is set again, and at each operation the case lists with `until`:
   another case of the same variadic operation (`CURLOPT_COPYPOSTFIELDS`
   replaces the pointer with the library's copy) or a modeled operation of
   the resource. A handle holds several retentions at once, each with its
   own release.
3. A pointer C reads to a length it is told through a second option
   (`CURLOPT_POSTFIELDSIZE`: with it set, curl reads `size` bytes whatever
   the NUL, a buffer overread when the size exceeds the buffer) is one
   presented operation over `&[u8]` that sets both options, under
   §16.2b.8's rule that a pointer and its length are one slice. The length
   option is never listed on its own: a safe pointer beside a raw length
   half-models exactly as §9 forbids.

**Why.** The three spec clauses already decided the shape: §16.2b.5 says
the case states its retention and the retained value is never a copy or an
owned cell; §16.3c says a binding that knows C stores the pointer must
require caller-managed storage or stay raw; §16.2b.9 gives the window. A
`str` cannot be the retained value: its bytes are a counted buffer with no
NUL, and the call-scoped C string dies at the return, so retaining it would
need a secret owned cell beside the handle. Inferring that the program
keeps the `str` alive is an unsafety-creating inference D51 forbids by name.

**What the others do.** The Rust `curl` crate exposes only
`post_fields_copy` (`CURLOPT_COPYPOSTFIELDS`); the zero-copy option is
reachable only through `curl-sys` under `unsafe`. Zig, Swift, Go and Vale
bind the raw variadic. The crate copies because it cannot express the
borrow; With expresses it and copies nothing.

**Reopens it.** A retention whose release is a callback the library runs
(a `freefunc`), which no `until` names; a slice whose elements are
themselves retained pointers (`curl_slist`, `CURLOPT_HTTPHEADER`).
