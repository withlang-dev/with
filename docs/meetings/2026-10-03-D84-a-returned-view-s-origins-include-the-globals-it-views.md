# D84 — A returned view's origins include every global it views; a global origin is part of the interface and widens D79's writes clause

**Date:** 2026-10-03. **Status:** BDFL ruling (Eric: direction "B", then
"blessed" on the words; approved the D79 consequence). Spec v7.17:
borrow-checker-rules.md §21.1 rule 6; toolchain/wo_bundles.md "Global
writes are the declaration". Amends D79. Issue #1903. **The compiler is
NON-COMPLIANT** until Sema records global origins, checks declared
`from G`/`from p` against the body, and bundle interfaces carry them.

**Context.** `fn first(p: &Vec[i32]) -> &i32: &HIDDEN[0]` was accepted
with origin `p`; the caller's view of `HIDDEN` was invisible to §21.1 rule
1, so `grow()` freed the buffer under a live `r` (`--debug-alloc` read
`5668928`, 41 expected). Rule 6 named parameter origins only.

**Decision.** A returned view's origins are every parameter it derives
from and every global the body returns a view of, directly or through a
callee's returned view. A signature names a global origin with `from G`
beside `from p`; a declared origin the body does not derive from is an
error, never a silent widening. A global origin is part of the interface:
a bundle records it by an identity that does not export the global, and
every exported function writing it declares it in `writes`. D79's
"exported globals only" now reads "exported globals, and every global that
is an origin of an exported function's returned view"; this ruling
supersedes that sentence of D79 (D79 carries the amendment note).

**Alternatives rejected.** (A) refuse a body returning a view of a global
under a parameter origin: also outlaws the accessor `fn peek() -> &Config:
&CONFIG`, ceremony for a pattern the compiler can check. Rust denies
references to `static mut`; Swift checks exclusivity at run time; neither
fits "globals are places" (§9.1c), whose conclusion is B.

**Reopen if** recording private global identities in `.wi` interfaces
leaks layout or breaks D39's fingerprint, or `from G` turns out to be
needed on items other than function returns.
