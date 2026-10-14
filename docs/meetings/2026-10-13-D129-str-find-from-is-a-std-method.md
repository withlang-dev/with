# D129 — `str.find(needle, from = 0)`: the start offset is a default parameter of a `std.string` method, not a compiler intrinsic (delegated)

**Laws:** 1, 5 (docs/mission.md).

**Date:** 2026-10-13. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2377 (from #2358).

**Decision.** `find` leaves the compiler and becomes an ordinary `impl str`
method in `lib/std/string.w`, beside `rfind` (D105):

```
pub fn find(needle: &str, from: isize = 0) -> isize
```

- The byte index of the first occurrence of `needle` at or after `from`,
  `-1` when there is none. `s.find(x)` means what it always meant.
- `from` past `len()` finds nothing (`-1`): a search in an empty tail is
  a search, not an index. A negative `from` is out of range and panics
  (D71), as `s[from..]` does; nothing counts from the end.
- An empty needle is found at `from` (at `len()` when `from == len()`).
- `index_of(needle)` stays the one-argument primitive the method is written
  over (the `STR_INDEX_OF` intrinsic); `contains`, `starts_with` and
  `ends_with` take no offset: `s[from..].starts_with(p)` is a view and
  already O(1).
- The second argument is positional and omittable (§9.1a default
  parameters): `s.find(block, first + 1)` is what a tool writes to find
  the next occurrence; `first` is the `isize` `find` returned, so no cast.

**What the others do.** Python and Mojo: `find(sub, start=0)` (a negative
start counts from the end, a start past the end is no match). Zig:
`std.mem.indexOfPos(T, haystack, start_index, needle)`, a separate name
with the index before the needle. Rust and Go: no offset; `&s[from..]`
then `find`, and the caller adds `from` back. Swift: ranges on the
collection. Every one that has the form makes the offset trail the needle.

**What the spec says.** Nothing about `find`: D105 settled that the spec
enumerates no table of `str` methods and that a method the stdlib can
write over `slice`, `starts_with` and `index_of` is stdlib surface, not an
intrinsic. §9.1a gives default parameters and says they are omitted
positionally from the end, so the spelling needs no new rule.

**Why this and not the alternatives.** A compiler row with a default
(`needle: &str, from: isize = 0` in BuiltinSigs, padded in MirLower the
way an Atomic's omitted `Ordering` is) would be a second default-parameter
mechanism for one method; D30's direction is runtime and library in With.
A `from` on `index_of` as well would be the same fact in two places;
`index_of` is the primitive, `find` is the API. A negative `from` meaning
"from the end" (Python) is a second meaning for one integer, which law 1
forbids; `rfind` is the spelling for the other end. `Option[isize]` would
change `find`'s result type, its own decision (D105's reopen clause).

**Also.** `rfind` compared views at every byte position and panicked
inside a UTF-8 sequence ("string slice inside a UTF-8 character") on any
haystack with a multibyte character; it compares bytes now.

**Prediction.** 80% that Eric keeps it: the offset trails the needle in
every reference that has one, the default parameter is a §9.1a feature
doing its job, and the method moves in the direction D104 and D105 set
(`trim`, `rfind`, `trim_start` are already std methods). The alternative
he might want is the same parameter on `index_of`; that is one row and one
line if asked.

**Reopen if** `find` moves to `Option[isize]` (then the default moves with
it), or if the compiler's own `find` calls need the intrinsic for speed
(the std body is one slice and one `index_of`, so it should not).
