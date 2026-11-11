# D201 — Law 12: the programmer has the last word on what the compiler cannot see

**Laws:** this entry records a new one, written into `docs/mission.md` before
the decision that needs it, as the mission requires.

**Date:** 2026-11-11. **Status:** ruled by Eric; the law's words are his,
verbatim. The product is NON-COMPLIANT with it until the override of the With
Contract Language exists (WCL chapter, the precedence rule).

**The law.**

> The programmer has the last word on what the compiler cannot see. The
> compiler proves what it can and restricts what it cannot. Where it
> disagrees with the programmer about what foreign code does, the programmer
> may take responsibility in writing, and the compiler honors it and records
> whose word it is. With guarantees what it proves; the programmer answers
> for what they claim.

**Context.** The With Contract Language chapter, draft 3, section 13.1. Once
a grant a program states in its own contract is a claim like a registry
line, the two precedence rules of §16.2b (a stated clause stands unless the
compiler proves it impossible; a registry line that contradicts a proof is
an error) had to become one. The draft proposed: a proof that contradicts a
grant is always an error.

**Decision.** A proof that contradicts a stated grant is an error, unless
the clause is marked as an override; then the grant stands. An override with
no contradicting proof is stale, not an error: it is accepted, reported by
the contract audit and counted in its own bucket, because a contract must
compile on compiler versions whose proofs differ, in both directions,
including inside a dependency the user cannot edit. The toolchain's own gate
fails on a stale override in this tree. No tool writes an override. Only a
contract the program states may override; a facts file may not, and a
registry line that contradicts a proof stays an error naming both. Run-time
checks are unaffected: an override changes what the compiler trusts, not
what it tests. Overrides are counted apart from claims, and in the standard
library and the runtime an override needs a citation. The contradiction
error prints the proof, names the override, and says how to report a proof
believed wrong: every override is a possible compiler bug.

**Alternative rejected.** A contradicted claim is always an error. The
compiler's proof about foreign code is drawn from the source it could read,
under the model it has; it can be wrong, and a library can be built from
source the drafter never saw. With no override, a wrong proof leaves the
programmer `unsafe` as the only way through, which says neither what is
claimed nor whose word it is, cannot be counted, and does not go stale when
the proof is fixed. The override keeps the disagreement written down,
attributed and visible.

**Scope, so it is not over-read.** The law is about facts concerning code
the compiler cannot fully see. It gives no authority over types, over
ownership inside With, or over ABI and header facts (layout, types,
constants): none of those can be overridden. It does not weaken law 4: the
absence of evidence still grants nothing; what the law adds is that the
presence of a contrary proof does not silence a programmer who takes
responsibility in writing.

**Also in this change.** D198 joins law 4's instances.

**Reopen if** overrides accumulate without reports (the count in `with
analyze … contract`, the census and `:user-programs-safe` rises and the
proofs they contradict are not being fixed), or an override is found
covering a real defect that the error would have caught.
