# D136 — The package registry is `registry/c/<package>/facts.w` in the toolchain's repository: a facade fragment in the draft's own spelling, every fact cited, landing by pull request

**Laws:** docs/mission.md: nobody writes what the toolchain can know;
§16.2b.15 item 3 (D121): one reviewed facts file per package, shared by
every With user; §16.2b.2: a registry fact ranks below a proof and the
library's annotations.

**Date:** 2026-10-15. **Status:** ruled; Eric's "proceed" on the brief's
prediction (the brief is reproduced below), so the mechanism is in force
and the spec sentences wait on his exact words. **Context:** D121 step 4.

**Decision.**
- **Where.** `registry/c/<package>/facts.w` in this repository, read by
  the proof engine (`with migrate --facade NAME <dir> --facts FILE`) and,
  through it, by `with get` (step 5), which fetches the file for the
  package's version as it fetches recipes and pins the commit it read in
  the project's `lock.json`. "Beside the Conan recipe" cannot be literal:
  Conan Center's recipes are not ours.
- **What.** A facade fragment in the facade language's own spelling, the
  spelling the draft emits: `c facade NAME:`, `resource R wraps *mut rec`
  with `from F`, `drop F`, `destroys F`; `fn F` with `consumes param N`,
  `returns borrow R from param N`, `lend`. One grammar for the reviewer,
  the draft and the registry. The file names the package; a fact true of
  one version and not another splits the file by version range when the
  second version arrives.
- **Cited.** Every fact carries its citation after `//`, the source line
  or document that proves it; the engine refuses a fact without one. This
  is the half of the review rule a tool can hold.
- **Reviewed.** A fact lands by pull request, as a DefinitelyTyped
  declaration does; the PR names the package version and its test
  compiles the fragment, merged into the engine's draft, against the
  package's header. A proof wins over a fact; the report's DISAGREES line
  is the signal that one of them is wrong, and the PR that finds it fixes
  the wrong one.
- **Provenance.** Each registry fact in the generated facade carries
  `registry:` and its citation; a project overrides any single fact in its
  own facade (§16.2b.15).

**What the others do.** Swift's `.apinotes` sidecars sit in the
toolchain's tree per library and are reviewed as code. DefinitelyTyped is
one repository of per-package files, each landing by pull request with a
test that it compiles against the package. Rust's bindgen has no shared
registry.

**What the spec says.** §16.2b.15 item 3 names the registry and its
place in the order; it does not say where the file lives, what it is
written in, or how a fact is reviewed. Two sentences in
`docs/spec/toolchain/package-management.md` predate D121 and contradict
it: "A locally generated draft facade is never trusted automatically" and
"The toolchain publishes no facade beyond the C standard library's". The
proposed replacements are in the PR that lands this entry and wait on
Eric's words.

**Mission fit.** `with get libxml2` reads the package's source, its
annotations and one shared file, and the programmer reads a report.

**Prediction (as briefed, 80%).** Eric accepts the location, the
fragment-as-grammar, the citation rule and PR review; the likelier veto
is a separate `with-facts` repository, which is a fetch URL change.
