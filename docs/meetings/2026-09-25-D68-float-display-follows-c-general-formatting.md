# D68 — Float display follows C general formatting

**Laws:** 1 (docs/mission.md).

**Date:** 2026-09-25. **Status:** BDFL ruling (Eric: "we need to match what C
does", resolving #1649's default-display question).

Default float display follows C `printf("%g")`: six significant digits,
notation chosen from the rounded exponent, and fractional trailing zeros
removed. Explicit `g` precision has C's significant-digit meaning, including
zero precision meaning one. This supersedes #1649's proposed shortest
round-trip default; correctly rounded literal parsing remains required.
Formatting remains locale-independent as With text requires.

The reference is C's general-conversion rule, including its rounding-dependent
notation choice: [WG14 DR 233](https://open-std.org/JTC1/SC22/WG14/issues/c99/issue0233.html).
Tests compare against the host C formatter as well as fixed boundary cases.

Credit: the correctly rounded literal parsing and the exact `:e` digits came
from Josh Hickson's #1649, which landed on main through #1683's squash
(a5c6f430) without his authorship; `docs/float-c-format-audit.md` records it.

---
