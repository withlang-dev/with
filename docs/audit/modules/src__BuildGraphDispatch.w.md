# Primary verification — `src/BuildGraphDispatch.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `2d4300dfe712a20072d3ceb41d743db3bf9db9aba15a3a27df935a80f97ee7ef`  
Source examined: all 151 lines

## Scope examined

The complete module was read inline. It owns graph-wide output collision
validation, generated-source writes, completed-dependency checks for group and
promotion targets, and routing of standard target kinds 7–22 to their operation
implementations.

The codebase-memory graph was queried first. Its `.w` extraction returned no
dispatch symbols, so Tilth was used to enumerate every importer and call site.
The entire `BuildGraphKinds.w`, `BuildGraphOps.w`, and `BuildGraphTests.w`
modules were read, along with the relevant `BuildGraphSupport.w`,
`BuildGraphMaterialize.w`, `BuildGraphCache.w`, `BuildGraphModel.w`,
`lib/std/build.w`, and `main.w` paths.

`src/main.w` is the sole production caller. It validates graph outputs, writes
generated sources, audits dependency edges, checks every target kind/platform,
checks freshness, calls the standard dispatcher, and handles test, action, and
compiled kinds outside this module. `tools/debug_sema_layout.w` imports the
module only as part of its compiler-layout inventory.

Applicable overview targets examined: 18–19 and 21–24. The module contains no
MIR, ABI, ownership, suspension, drop, or allocator decisions. Operation
internals were not credited from routing alone; the subsequent primary audit
of `BuildGraphOps.w` independently examined every standard routed branch, while
`BuildGraphTools.w` remains pending its own primary audit.

## Routing closure

The primary agent traced the complete finite kind space:

| Kinds | Authority after validation | Result |
|---|---|---|
| 0, 1, 3, 4 | compiled-target branches in `main.w` | intentionally unhandled here |
| 2 | test branch in `main.w` | intentionally unhandled here |
| 5–6 | removed-kind rejection in `main.w` | exits nonzero before dispatch |
| 7–22 | `build_graph_dispatch_standard_target` | every value has one explicit branch |
| 23 | action branch in `main.w` | intentionally unhandled here |
| other integers | validity rejection in `main.w` | exits nonzero before dispatch |

The standard branches preserve the operation return code. Fixpoint comparison
prints `FIXPOINT` only after a zero comparison result. Promotion alone requires
at least one verification dependency and all group/promotion dependency names
must already appear in `completed_targets`. Group targets allow an empty set,
which is their ordinary aggregation/no-op behavior.

## Artifact and optimization evidence

The earlier primary stage query in this audit ran:

```text
./out/bootstrap/bin/with-stage1 build --explain stage1 :stage1
```

It exited 0, reported `fresh`, explicitly listed
`src/BuildGraphDispatch.w` among the stage1 inputs, selected the seed compiler,
and carried `-O1`.

`docs/audit/probes/build_dispatch_matrix.w` imports the real module and was compiled
with `-O1`. It verified:

- a unique generated/primary/extra output set passes;
- duplicate generated-source paths fail;
- a generated-source/target-primary collision fails;
- two target-primary paths collide and fail;
- an extra-output/primary collision fails;
- a valid generated source is created with exact contents; and
- a traversal-bearing generated path fails before a write.

Execution exited 0 with `build-dispatch-matrix: ok`; the expected negative
diagnostics named each duplicate or invalid path.

`docs/audit/probes/build_dispatch_unknown_kind` created a normal cached executable
graph, changed only the serialized kind from 0 to 999, and invoked the public
build path again. It exited nonzero with
`invalid build.w target kind unknown(999) for 'mystery'` at
`main.w:1722-1729`. This is the negative control for the permissive graph parser
reported as BGC-007: malformed kind data is not silently routed to the final
executable branch.

The later confined `docs/audit/probes/build_graph_ops_clean_root.w` check supplied
the negative control for dispatch's clean exemption. It passed `.` under a
disposable ignored root, observed a nonzero operation result, and proved that
the root's marker had already been recursively removed.

## BGD-001 — generated-source validation accepts interior NUL and writes earlier entries before panicking

Classification: **Confirmed loud-failure/partial-mutation defect; candidate unreported**  
Severity: **Low**  
Blast radius: build graphs that compute a generated-source path containing an
interior NUL, and any earlier generated sources in the same graph  
Confidence: **Very high**

The public fixture `docs/audit/probes/build_dispatch_generated_nul` constructs the
path dynamically with `StringBuilder.push_byte(0)`, avoiding a malformed source
literal. Its graph contains one valid generated source followed by the NUL path.
The `-O1` build exited nonzero with:

```text
panic: str to C string conversion: interior NUL byte
```

The earlier `out/gen/first.w` nevertheless existed afterward with the requested
contents. The direct module probe independently observed
`validation-rc=0`; when the writer reached the NUL path it produced the same
panic, after its preceding normal write.

The exact source chain is:

1. `build_graph_generated_path_valid`, `BuildGraphSupport.w:107-118`, rejects
   empty, absolute, `..`, newline, carriage-return, and tab paths but omits NUL.
   The sibling manifest and process validators do reject NUL.
2. `build_graph_validate_outputs`, `BuildGraphDispatch.w:38-72`, accepts the
   graph and compares the byte-distinct path as an ordinary output identity.
3. `build_graph_write_generated_sources`, lines 74-88, validates and writes one
   item at a time; there is no whole-list preflight.
4. The native path conversion rejects the interior NUL by panic. Because prior
   entries were already written, failure is loud but not atomic.

Five Whys:

1. The build panics because a native pathname cannot represent the accepted
   With string.
2. The generated-path validator omits a byte rejected by adjacent validators.
3. Validation and native pathname conversion do not share one path contract.
4. The writer interleaves validation and mutation rather than validating the
   complete set first.
5. Tests cover ordinary traversal and output collisions but not the complete
   byte-domain or failure atomicity of a generated-source batch.

Proper repair boundary: use the same pathname validator for every build-graph
filesystem field, explicitly reject NUL with a normal target/source diagnostic,
and preflight every generated path plus output collision before the first
write. If generated-source batches promise transactional behavior, write each
to a temporary path and promote only after the full batch succeeds; otherwise
the documented contract must state the visible partial-write behavior. The
current panic is loud, so this is not classified as a silent-success defect.

## BGD-002 — dispatch explicitly exempts destructive clean targets from containment

Classification: **Confirmed cross-module containment bypass; same root as BGO-001**  
Severity: **Critical**  
Blast radius: every clean target, especially an argument resolving to the
project root or an unintended project subtree  
Confidence: **Very high**

`build_graph_dispatch_standard_target` calls the shared containment check at
`BuildGraphDispatch.w:107-110`, then routes clean directly to
`build_graph_run_clean` at lines 146–147. The shared check is not merely blind
to clean arguments: `build_graph_validate_target_containment`,
`BuildGraphSupport.w:166-172`, explicitly returns success whenever
`target.kind == 21`.

The prior report treated this as sound delegation to a stricter per-argument
check. The completed `BuildGraphOps.w` audit disproved that assumption:
`build_graph_run_clean`, lines 54–75, accepts `.` because it rejects only empty,
absolute, or substring-`..` spellings. The confined reproduction resolved that
argument to `<root>/.`, recursively removed the root's children, and returned
nonzero only when removing the final root spelling failed.

Five Whys:

1. Dispatch permits a root-deleting target because clean bypasses the common
   containment decision.
2. The bypass assumes the operation-local substring check proves containment.
3. No shared strict-descendant path type or canonical identity check connects
   dispatch to the destructive runtime call.
4. Validation ownership was split between modules without an executable
   contract at the seam.
5. The routing matrix covered kind ownership and return propagation but omitted
   the destructive operation's boundary-value paths.

Proper repair boundary: remove the unconditional clean exemption. Materialize
and validate each clean argument through one canonical path authority, require
it to be a strict descendant of an allowed artifact root, and preflight the
entire list before dispatch permits the first deletion. The operation should
retain a final defense immediately before `remove_tree`, but that defense must
consume the same validated representation rather than re-derive containment.

## Working behavior retained

- `build_graph_validate_outputs` resolves executable/library/object/archive
  default and CLI output paths with the same support helpers used by execution,
  expands install destinations, and considers every primary and extra output.
  The false-fresh default/CLI output defect belongs to `BuildGraphCache.w`,
  which does not consume this effective set; it is not a failure of dispatch's
  collision calculation.
- Generated source writes check directory creation and file-write return codes
  and return nonzero with a named diagnostic on either failure.
- Target containment runs before standard operations and, because the
  dispatcher is called before special branches, also covers compiled, test,
  and action targets. Clean is explicitly exempted; BGD-002 proves that this
  exception is unsound.
- Unknown and removed kinds are rejected before the dispatcher, including when
  they arrive from a manually altered serialized graph.
- Every routed branch returns `handled=true`; unhandled valid kinds return
  `handled=false, rc=0` for the caller's explicit implementation.

## Test-coverage audit and required regression matrix

Exact searches found no direct production test importing
`BuildGraphDispatch` or asserting its diagnostics. Current build-graph suites
exercise it through CLI fixtures. The retained direct matrix closes the
module's pure output-set behavior, but production coverage should add:

- a table-driven 0–23 routing ownership test, plus removed and unknown values;
- return-code propagation for every standard operation and the fixpoint
  success-marker condition;
- group with zero/multiple completed deps, missing deps, and duplicate names;
- promotion with no deps, incomplete deps, completed deps, and failed prior
  verification;
- generated/generated, generated/primary, primary/primary, primary/extra, and
  extra/extra collisions across explicit, default, CLI, absolute, and expanded
  install paths;
- complete pathname byte-domain coverage, including NUL, separators, Unicode,
  dot segments, platform spellings, and maximum lengths;
- clean arguments at root identity, dot aliases, nested descendants, symlinks,
  platform spellings, and late-invalid multi-argument lists, with proof that
  every rejection occurs before mutation;
- directory-creation, write-failure, and multi-entry failure-order cases; and
- proof that validation completes before any generated-source mutation.

The upstream tracker was searched for generated-source NUL handling, duplicate
build output paths, dispatch/kind routing, and clean-root containment. No exact
issue was found. Open
#680 discusses the single-writer output guarantee for a future parallel graph
executor, and open #921 changes graph-runner architecture; neither reports
BGD-001 or BGD-002. No issue was filed during this report-only audit.

## Completion statement

The primary agent examined all 151 lines, the sole caller, the entire finite
kind space, every routed operation boundary, output identity construction,
generated-source write order, dependency-completion semantics, containment,
cache interaction, and existing test references. The direct `-O1` matrix
verified every output-collision category and valid/invalid generated writes;
the public NUL fixture pinned BGD-001 to the exact validator and write order;
the clean-root probe corrected the earlier containment assumption; and an
altered-kind control proved unknown serialized kinds still fail loudly before
dispatch. Operation internals remain credited only to their own primary
reports. This evidence supports retaining `src/BuildGraphDispatch.w` as
complete with BGD-001 and BGD-002 recorded.
