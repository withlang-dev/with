# D105 — `str.rfind`, `trim_start`/`trim_end` (views) and `bytes()` are stdlib methods in `std.string` (delegated)

**Laws:** 5, 1 (docs/mission.md).

**Date:** 2026-10-06. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2206.

**Decision.** Three one-liner conveniences a With tool reached for and did
not find are ordinary `impl str` methods in `lib/std/string.w`, beside
`as_bytes`, not compiler intrinsics:

- `rfind(needle: &str) -> i64`: `find` from the other end — the byte index
  of the last occurrence, `-1` when absent; an empty needle is found at
  `len()`.
- `trim_start() -> &str` and `trim_end() -> &str`: the view past leading /
  before trailing ASCII whitespace (`' '`, `'\t'`, `'\n'`, `'\r'`, the set
  `trim` uses). Views, never copies: they are `s[a..b]` (D71), O(1).
- `bytes() -> ByteIter`: the bytes in order, `@[iter_of_self]`, an
  ephemeral iterator over `as_bytes()`; `for b in s.bytes()` as §15.4 and
  iteration.md already name it.

**Why.** The spec enumerates no table of `str` methods; this is stdlib
surface, and D30's direction is runtime in With, so a method the stdlib can
write over `slice`/`starts_with`/`as_bytes` is not an intrinsic (no
`MirIntrinsic`, no codegen, no runtime function per method). `trim` copies
today (#747's "owned, never a view", written before D71 made `s[a..b]` a
`&str` view); the new methods follow D71 and the no-implicit-copy rule
rather than the legacy, and `trim` is left to follow (#2225).

**Prediction.** 85% that Eric keeps it: `rfind` mirrors `find` exactly, the
views are what D71 made cheap, and `bytes()` is the spelling the spec
already uses. The alternative he might prefer is `Option[i64]` from
`rfind`; that would make it differ from `find`, which returns `-1`, and
changing both is its own decision.

**Reopen if** `find` moves to `Option[i64]` (then `rfind` moves with it), or
if `trim` becomes a view and the three should share one whitespace set
spelled in one place.
