# Audit 009 — build provenance, platform agreement, harness honesty, and specification coverage

Status: **bounded audit complete; no audited module is marked complete**  
Targets: audit-overview 18, 19, 21, and 22  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e` (`main`)  
Edits: this report only; no compiler, runtime, build, test, specification, checklist,
overview, index, or issue changes

## Executive verdict

The build has several strong provenance mechanisms: stage inputs are content-hashed,
all self-host stages and fixpoint objects are built at `-O1`, stage2/stage3 fixpoint
evidence is bound to the release compiler hash, and release stamping is deliberately
separated from the expensive commit-independent link. Those mechanisms do not close
four material assurance gaps:

1. `embedded-clang-resource-source` reads an SDK header tree that is absent from its
   declared or discovered cache inputs. A changed SDK/header tree can therefore leave
   a stale generated header payload marked fresh and later embedded in the compiler.
2. The test directive parser silently ignores unknown `//!` directives, and
   `known-issue` accepts any nonzero inner verdict. Both can turn a test other than the
   one the author wrote into a green suite result.
3. `tools/debug_drop.w run` labels every allocator report other than `DOUBLE FREE` or
   `LEAK addr=` as clean, including `invalid free`, the failure class relevant to #916.
4. The retained green record proves one host only, the allocator lane is deliberately
   green-skipped on Windows, and the normative requirement matrix has no enforceable
   requirement-to-test join. Cross-platform agreement and specification coverage are
   therefore not demonstrated by the present evidence system.

The local checkout is also a hybrid artifact set: stage1 is current according to the
repository's own content-hash ledger, while stage2, the release binary, fixpoint, and
test-green evidence predate HEAD. That is not itself a build-graph defect—the full
graph should rebuild downstream artifacts—but those older artifacts cannot be used as
HEAD evidence.

## Provenance reconciliation with Audit 006

Audit 006's lines 13–29 concluded that the available stage1 executable lacked usable
source provenance, relying in part on its placeholder version string, and inferred
that source and executable did not describe the same semantic-state producers. The
artifact evidence now available requires that conclusion to be narrowed:

- `build/compiler.w:1414-1422` intentionally copies normalized `src/main.w` to
  `out/gen/main.w` without substituting a release version.
- `build.w:1688-1744` compiles stage1, stage2, and stage3 from that unstamped generated
  main. `build.w:2105-2134` reserves post-link stamping for the final release binary;
  `build/compiler.w:1460-1561` implements the fixed-width patch.
- Consequently, `with WITHVERSIONSTAMPv1...` in stage1/stage2 is a designed sentinel,
  not evidence of unknown provenance.
- The current stage1 cache ledger plus its hashed `seed-input.json` extra output record
  the seed identity, every declared compiler source/runtime/stdlib input fingerprint,
  the produced stage1 fingerprint, and the exact process effect. The bounded read-only command
  `out/bootstrap/bin/with-stage1 build --explain stage1 :stage1` reported `fresh`
  against the present tree. Its SHA-256 is
  `d1f65fd87a450c24a00bf2498a9bc10f9cf55a42cb199c5d8ef667a2bb4cab1a`.
- The seed manifest names `/home/shawn/.local/bin/with`, version `v0.15.1.6`, SHA-256
  `4a2d4d65272e550af2c9c8e27ecace8c841a9abcb951665445235d1376a6c38c`.

This is the strongest repository-internal artifact/source binding available without a
rebuild: it proves that the current cache model attributes stage1 to the current input
contents and recorded seed. It is not an independent reproducible-build attestation,
nor fixpoint proof. It does, however, refute “unattributable stale binary” and
“placeholder means unknown revision” as explanations for Audit 006's executable
observations.

The remaining contradiction is narrower and more useful: direct textual searches did
not locate the ordinary `typed_expr_types` and concrete-specialization descriptor
writes, while a stage1 built from the current inputs emitted those facts. That means
the direct-write search was not a sound producer proof (an indirect mutation, alias,
generated path, compiler semantic effect, or defect remains possible). This audit does
not guess which. Audit 006's validator findings remain source findings, but its claimed
source/binary provenance failure is not supported by the stronger evidence above.

## Revision and artifact evidence

| Evidence | Observed state | What it proves |
|---|---|---|
| HEAD | `31f77937abad3bc6573df3b71a0c99b605d6ea8e` | Audited source revision |
| stage1 | 2026-09-01 03:34; SHA `d1f65f…`; cache says fresh | Current repository-internal source/input binding |
| stage2 | 2026-08-31 08:16; SHA `39471e…`; unstamped | Existing artifact only; not HEAD verification |
| stage3 | absent | No current full stage-chain artifact |
| release | `v0.15.1.7-gc83b13f66`; SHA `c8a46e…` | Release belongs to commit `c83b13f…`, not HEAD |
| last-green/test-green | commit `c83b13f…`, host `Linux/x86_64` | Valid retained evidence for that commit/host only |
| old fixpoint | stage2/stage3 object SHA `4941bc…` | Byte fixpoint for the retained `c83b13f…` compiler |

No broad build, test suite, fixpoint, packaging, cache mutation, or non-Linux execution
was performed. Read-only work was limited to graph/source inspection, hashes, metadata,
version probes, and the stage1 freshness explanation above.

## Source authority map

### Build, cache, generated inputs, seed, fixpoint, and release

- `build.w:1511-1524` — generated stdlib/runtime inputs are declared; the Clang
  resource action declares only its output.
- `build/clang_resource.w:136-207` — the action discovers and reads the SDK Clang
  header tree at execution time.
- `src/BuildGraphCache.w:503-533,555-669` — signature, declared-input,
  discovered-dependency/effect, and output freshness checks.
- `build.w:1688-1789` — stage chain and `-O1` object fixpoint.
- `build/compiler.w:1414-1561` and `build.w:2105-2134` — unstamped stage source,
  release link, atomic version patch, and macOS re-signing.
- `build/retention.w:614-705` — compiler-bound fixpoint evidence and single-host
  last-green manifest.
- `src/BuildGraphCache.w:177-209,503-533` — current compiler fingerprinting and
  special handling of `compiler=seed`.

### Platforms and packaging

- `build.w:624-633` — native release hosts are Linux/x86_64, Darwin/aarch64,
  Windows/x86_64, and Windows/aarch64.
- `build.w:663-690,1490-1500` — native package gates and platform package targets;
  SDK packaging additionally names Linux/aarch64.
- `build.w:1081-1134` — debug-allocator lane and wholesale Windows green skip.
- Test directives presently contain ten `skip-on: windows` fixtures tied to #369,
  #799, #800, or #802, and five `only-on` fixtures.

### Test verdicts and normative traceability

- `src/main.w:2934-3042` — directive grammar and unknown-directive sink.
- `src/main.w:3094-3112,3261-3295` — skip discipline, exact exit/output checks, and
  known-issue verdict conversion.
- `tools/debug_drop.w:95-138` — debug allocator run/check parsers.
- `docs/requirements.md:1-38` — 3,167 normative requirements, triage semantics, and
  hand-maintained sentence traceability.
- `test/spec/README.md:1-35` — historical Section 25 fixture mapping.
- `test/coverage_manifest.txt` and `test/coverage_matrix.md` — driver/link/c-import
  migration coverage, not a normative requirement-to-test map.

## Findings

### A009-01 — SDK header changes do not invalidate the embedded Clang resource action

**Severity:** High  
**Blast radius:** every compiler containing cached `EmbeddedClangResourceData.w`;
first-use `c_import` on clean hosts; all supported hosts  
**Confidence:** High, source- and state-proven

Exact branch and condition:

- `build.w:1522-1524` creates `embedded-clang-resource-source` with an output and
  action but no input.
- `build/clang_resource.w:142-167,188-207` lists `.deps/.../lib/clang`, selects
  headers, and reads their contents through `ToolFs`.
- `src/BuildGraphCache.w:620-656` can invalidate only declared inputs, recorded
  dependencies/environment, and a recorded effects log.
- The current action state contains a signature and output hash only: no `in:`,
  `dep:`, `env:`, or `effects:` entry.

Therefore changing/replacing a Clang builtin header does not change any recorded
freshness fact. The old generated With module may be reused and compiled into later
stages/releases.

Five Whys:

1. Why can shipped builtin headers be stale? The generator is allowed to remain fresh
   after its source headers change.
2. Why? The resource tree is absent from the action's cache inputs.
3. Why? Headers are discovered dynamically inside the action via `list_files` and
   `read_text`.
4. Why is dynamic discovery insufficient? Those filesystem reads/listings produce no
   persisted dependency/effect facts for this action.
5. Why is the consequence silent? Downstream stages correctly depend on the generated
   output, but only see its old, still-valid output hash.

Repair boundary: make a deterministic SDK resource manifest (version, sorted relative
paths, content hashes) an explicit input, or teach action effects to record and replay
`ToolFs` listings/reads. Fail on absent/multiple resource versions. Do not invalidate
all actions globally; preserve #686's scoped action-code hashing.

Issue relationship: this is in the #312 embedded-resource surface and crosses #686's
cache-action provenance boundary; it is distinct from #650's intentional release
stamping cache.

### A009-02 — `known-issue` accepts an unrelated failure as success

**Severity:** High  
**Blast radius:** all current and future `//! known-issue` fixtures; currently five
fixtures (#916 and four #723 cases)  
**Confidence:** High, source-proven

Exact branch and condition: `src/main.w:3290-3295` converts every nonzero result from
the inner test pipeline to outer success. It retains neither failing stage nor expected
diagnostic, exit class, signal, allocator verdict, or timeout identity.

Five Whys:

1. Why can the wrong regression stay green? Any inner failure satisfies the wrapper.
2. Why? The contract records only “must stay red.”
3. Why is that insufficient? A test run is a composition of parse/check/build/link/run
   and verdict checks, any of which can fail.
4. Why is the intended failure not distinguished? The wrapper consumes only one `i32`.
5. Why is this broad? The directive carries issue text but no structured failure pin.

Repair boundary: make the inner runner return a structured stage/failure identity and
require known-issue fixtures to pin the intended stage plus stable diagnostic/verdict
fragment. Preserve the reverse check that an unexpectedly fixed fixture fails until
the directive is removed.

Issue relationship: #916 is especially exposed because its intended allocator/runtime
failure can be replaced by a parser, compiler, link, crash, or harness failure. The
four #723 fixtures have the same weakness.

### A009-03 — unknown `//!` test directives are silently discarded

**Severity:** High  
**Blast radius:** behavior, compile-error, and spec fixtures using the shared parser  
**Confidence:** High, source-proven

Exact branch and condition: after all recognized directive branches,
`src/main.w:3036-3037` accepts any remaining line beginning `//!` and executes a no-op.
A misspelling such as `//! expect-stder:` therefore falls through to default behavior.

Five Whys:

1. Why can a misspelled assertion produce green? It is ignored.
2. Why? Unknown directive-shaped lines have an explicit no-op branch.
3. Why does default execution continue? No `directive_error` is recorded.
4. Why can the test still pass? The omitted expectation is no longer part of its
   verdict.
5. Why is review insufficient? The accepted directive set is not mechanically checked
   against fixture spelling.

Repair boundary: reject unknown `//!` directives with file/line and the accepted
spellings. If prose comments need this prefix, introduce one explicit comment directive
rather than a wildcard sink. Add typo tests for every directive family.

Issue relationship: #795 correctly made malformed platform gates loud, but this final
fallback bypasses the same discipline for every unknown directive family.

### A009-04 — allocator `run` mode reports invalid frees as clean

**Severity:** High  
**Blast radius:** developer/debugger conclusions from `tools/debug_drop.w run`; memory
defects outside its two recognized report strings  
**Confidence:** High, source-proven; `invalid free` relevance is corroborated by #916

Exact branch and condition: `tools/debug_drop.w:100-108` recognizes only `DOUBLE FREE`
and `LEAK addr=`. Every other report reaches `verdict: clean` and exits zero, without
requiring the child exit code to be zero. An allocator report containing `invalid free`
therefore takes the clean branch.

Five Whys:

1. Why is an invalid free called clean? It matches neither recognized substring.
2. Why does process failure not prevent clean? `rc` is printed but not checked.
3. Why is the verdict incomplete? “Clean” is defined as absence of two strings, not a
   positive successful-exit/no-allocator-error contract.
4. Why can new allocator verdicts regress silently? There is no exhaustive parser or
   unknown-verdict failure.
5. Why does this matter operationally? Project workflow treats this tool as the first
   authority for memory bugs.

Repair boundary: define a shared exhaustive allocator-result parser; clean requires
`rc == 0` and no allocator error prefix. Recognize invalid free/use-after-free/metadata
corruption explicitly and fail closed on unknown `debug-alloc:` errors. Test parser
strings independently and through real fixtures.

The `check` lane is narrower than this defect: its clean fixture branch also requires
`rc == 0`, so a normal abort should fail the lane. The report does **not** claim that
every invalid free currently false-greens `with build :test`; it claims the developer
`run` verdict is false and incomplete.

### A009-05 — platform agreement is neither executed nor retained as one release fact

**Severity:** High assurance gap  
**Blast radius:** Darwin/aarch64, Linux/x86_64, Windows/x86_64, Windows/aarch64 release
claims; Linux/aarch64 SDK/cross surfaces  
**Confidence:** High for the evidence gap; no unexecuted platform behavior verdict

The source names four native compiler package platforms, but `last-green.json` and
`test-green.json` each store one `host` string. Current retained evidence is only
`Linux/x86_64`. There is no aggregated manifest requiring the same revision and test
contract to be green on all release hosts.

The gap is concrete on Windows: `build.w:1094-1100` writes an `ok` stamp and returns
zero without running any debug allocator fixture (#807). Ten additional fixtures are
skipped on Windows for #369/#799/#800/#802. These gates are visible and reasoned—better
than silent skips—but the resulting green cannot mean behavioral agreement with
Linux/macOS.

Five Whys:

1. Why is cross-platform agreement unproven? Evidence is retained per local host.
2. Why can't release evidence join hosts? The manifest schema has one `host` and no
   platform-matrix inputs.
3. Why is Windows weaker? One entire safety lane and ten fixtures are excluded.
4. Why can packaging still be invoked? Native package dependencies validate the
   current host, not a multi-host evidence quorum.
5. Why is this a release-level gap? The package list presents several platforms as one
   product surface without a same-revision agreement artifact.

Repair boundary: CI must publish signed/content-addressed per-platform evidence keyed
by exact commit, compiler SHA, SDK manifest, test-input fingerprint, and required lane
set. Release assembly must require the complete platform quorum, while recording every
approved issue-bound exclusion. Port #807 instead of treating the Windows skip as a
permanent pass.

No Darwin or Windows execution occurred in this audit, so this finding does not infer
that unskipped tests fail there.

### A009-06 — normative requirements are not mechanically joined to executable tests

**Severity:** High assurance/composition gap  
**Blast radius:** all 3,167 normative requirements across 275 sections  
**Confidence:** High, source/documentation-proven

`docs/requirements.md:18-26` explicitly says a checked box means triaged, not
implemented. An entry without an issue suffix is assumed implemented-and-tested or
non-testable, but the row contains no executable test IDs or test polarity.
`test/spec/README.md` maps historical sections to fixtures, while the coverage manifest
tracks nine driver/link/c-import migration categories. None forms an enforceable join
from requirement ID to positive, negative, boundary, platform, optimization, and
composition tests.

Five Whys:

1. Why can normative coverage drift? Requirement and fixture inventories are separate.
2. Why does a checked requirement not prove coverage? Its checkbox records triage.
3. Why can't section-named fixtures close the gap? A fixture can cover several rules,
   and a rule can require several polarity/composition cases.
4. Why doesn't the build detect drift? The surviving requirement check only preserves
   Section 30's informative status.
5. Why is composition particularly invisible? Cross-section semantic dependencies are
   only hints, not test obligations or executable joins.

Repair boundary: create one machine-readable coverage relation keyed by stable
requirement ID, with test path, assertion/polarity, platforms, optimization modes, and
composition partners. Build checks should reject orphan normative requirements, stale
test references, issue-free uncovered rows, and mappings whose fixtures are skipped on
all required platforms. Do not equate one fixture per section with complete coverage.

The count difference (3,167 requirements versus roughly two hundred spec fixtures) is
not itself proof of missing behavior—a fixture may cover many requirements. The defect
is absence of auditable mapping and enforced coverage semantics.

### A009-07 — seed identity is not independently visible in the stage cache signature

**Severity:** Medium/High candidate  
**Blast radius:** seed-to-stage1 freshness after the selected installed seed changes  
**Confidence:** Medium; source/state evidence, no mutation negative control

`src/BuildGraphCache.w:201-208` maps `compiler=seed` to an empty explicit compiler
path, so `:COMPILER:<hash>` is omitted at `:529-532`. The stage1 state also contains an
empty `compiler:` field. A seed manifest with the correct resolved seed/hash is written
when stage1 runs, but it is an extra output, not a declared freshness input.

The generic action signature may still be influenced by the current build-driver
fingerprint at `:514-515`; the current stage1 was rebuilt and its seed manifest is
specific. Without changing the selected seed and rerunning `--explain`, this audit does
not claim a demonstrated stale hit. It identifies an ambiguity the cache schema should
remove.

Repair boundary: resolve the selected seed exactly during graph materialization and
include its path/hash as an explicit stage1 signature/input fact. A blank or unresolved
seed fingerprint should fail closed. Add a mutation test that replaces the selected
seed bytes without changing project sources and requires stage1 to become stale.

## Secondary false-green candidates

- Expected check/build failures require a nonzero result plus a stderr substring, but
  do not structurally distinguish a normal diagnostic from a crash/timeout that happens
  to contain the text. This is lower confidence than A009-02 because the substring
  constraint narrows the outcome.
- Ten panic fixtures pin exit `134`; `validate_test_run` correctly checks exact exit and
  requested stream substrings, but any fixture that lacks a panic-specific stderr pin
  can accept an unrelated abort after satisfying its other output. Audit each fixture's
  asserted signal provenance before treating the exit code alone as semantic proof.
- `package_current_host_target` falls back to Darwin/aarch64 on an unrecognized host
  (`build.w:679-690`). Existing supported hosts return earlier, so this is not a current
  supported-host defect, but future host additions should fail loudly instead of
  selecting another platform.

## Mechanisms worth preserving

- Stage targets explicitly use `-O1`; object fixpoint compares stage2/stage3 outputs at
  the production optimization level.
- Stage sources include compiler, runtime, stdlib, generated compatibility data, and
  the embedded resource output; ordinary declared inputs are content-hashed.
- Release version patching is atomic, bounded to a fixed slot, and re-signs macOS
  binaries after mutation.
- Fixpoint evidence is bound to the exact release compiler hash, and last-green refuses
  evidence for a different compiler.
- Platform skip gates validate values and reasons, and known-issue correctly fails when
  an issue fixture unexpectedly turns green. Repairs should strengthen identity, not
  remove these reverse checks.

## Regression matrix

| Area | Required negative control | Required positive/composition control |
|---|---|---|
| Embedded Clang cache | Change one header/add/remove/rename a header and require stale | Unchanged manifest remains fresh; clean host `c_import` uses embedded headers |
| Seed provenance | Change seed bytes/path/version and require stage1 stale | Same seed and same inputs remain fresh |
| Generated inputs | Change stdlib/runtime/generated main and require every dependent stage stale | Unchanged generated payload remains reusable |
| Stage chain | Corrupt/delete each output and require rebuild | stage2/stage3 `-O1` object equality and compiler-bound evidence |
| Release stamping | HEAD-only change reruns stamp, not link | binary version, SHA, macOS signature, and provenance agree |
| Unknown directives | One typo per directive family fails with file/line | Every supported directive parses and asserts its intended stage |
| Known issue | Parser/check/build/link/run/timeout/crash substitutions all fail the pin | Exact issue stage/diagnostic stays red; actual fix forces directive removal |
| Allocator parser | invalid free, UAF, corrupt metadata, signal, and unknown prefix never report clean | zero exit plus no allocator error is the only clean result |
| Platforms | Same-revision required lanes absent on any release host block release | Darwin/aarch64, Linux/x86_64, Windows/x86_64, Windows/aarch64 evidence quorum |
| Requirements | Orphan/stale/skipped-only requirement mappings fail | positive/negative/boundary/platform/optimization/composition joins resolve |

## Limitations and completion boundary

- Codebase graph discovery was attempted first, but it does not index enough With `.w`
  bodies for these questions; exact Tilth source slices and literal searches supplied
  the evidence.
- No SDK mutation, seed mutation, cache deletion, full build, fixpoint, test suite,
  release UAT, packaging, debugger, or allocator execution was performed.
- No Darwin, Windows, aarch64, or cross-target verdict was observed.
- The current stage1 binding relies on the repository's own cache implementation; a
  clean independent rebuild/fixpoint would be stronger.
- This audit did not locate the indirect semantic producer that resolves Audit 006's
  typed-fact observation; it only removes stale/unattributed provenance as the supported
  explanation.
- No target is marked complete. Completion requires repairs plus the regression matrix,
  current HEAD build/fixpoint/test evidence, and same-revision platform evidence.

## Rule 13 / production-readiness self-evaluation

This report does not present known-deficient behavior as production-ready. Confirmed
defects are separated from candidates, exact branches and conditions are named, claims
are bounded to executed/source evidence, and no passing claim is made for an unrun
build, platform, or test. The report-only scope forbids implementing the repairs here;
they remain explicit rather than silently shipped or discarded.
