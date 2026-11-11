# D200 — A domain established between two calls is checked at the calls; a resource that requires it is the domain's

**Laws:** 4 (a fact is inferred only when being wrong cannot create
unsafety), 7 (fail loudly or do the work), 9 (one spelling of one meaning),
1 (the compiler never asks for what it already knows).

**Date:** 2026-11-11. **Status:** ruled by Eric (three rulings, 2026-11-11);
words blessed and landed in §16.2b.7 (v7.49). The compiler is NON-COMPLIANT
until it implements them: `establishes domain`, `ends domain` and `requires
domain` are in neither the parser nor the checker.

**Context.** Some foreign state exists only between two calls: raylib's
window and GL context between `InitWindow` and `CloseWindow`, its audio
device, a library's global init. An operation called outside them reaches C
with nothing behind it (`UnloadTexture` after `CloseWindow` calls
`glDeleteTextures` with no context). The raylib facts leave every GL and
audio type unstated for this reason.

**Decision.**

1. `requires domain D` is checked when the operation is called: a domain not
   established is a contract failure naming the function. A flow proof only
   improves on that: proven established, the check is omitted; proven not
   established, a compile error. No valid program is refused.
2. The failure for a resource that outlives its domain is at the ending
   call, not at the later drop: `ends domain D` with a resource of `D` live
   is a contract failure naming the call, and a compile error where the
   compiler proves one is live. The error names the live resource and the
   fix.
3. A resource says it is the domain's with the same clause an operation
   uses: `requires domain D` on the resource. It is live from its
   producer's return to its destroyer's call, and its producers, destroyer
   and operations require `D`.
4. Establishing a domain that is established is a contract failure naming
   the call.

**Alternatives.** Refuse the ending call only by flow proof: refuses valid
programs the proof cannot follow, or needs the run-time check anyway. Make a
drop after the end do nothing: right for a GL context, a leak for audio
(`UnloadSound` also frees CPU buffers), and a leak by default is not With.
`in domain D` on the resource: a second spelling of what `requires domain D`
already says (law 9); withdrawn.

**Notes for the implementation (Eric).** A live resource of `D` proves `D`
is established, so only producers and functions that take no resource of
`D` need the run-time check; a draw loop over live resources carries none,
and a test says so. The exact text of the compile error lives in its test.
The example's `gl` is a `thread` domain: a GL context is current on one
thread, and a `process` domain would let another thread pass the check.
The example's resource is `GpuTexture`, not `Texture`: raylib declares a C
type `Texture`, and a facade never renders a second type of one name.
No UAT fixture or example establishes a domain twice (checked 2026-11-11:
`InitWindow`, `SDL_Init` and `curl_global_init` each appear once, outside
any loop, in `uat/fixtures` and `examples`).

**Reopen if** a library's establishing call is documented as safe to repeat
and programs rely on it (reference-counted init such as `curl_global_init`):
that domain would need a counted form, which this ruling does not give.
