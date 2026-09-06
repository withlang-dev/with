# Primary verification — `src/BuildGraphModel.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `77e4059ee5e27821f8fa384ce12652ef860116718df4e74255917e61f8cae982`  
Source examined: all 506 lines

## Scope examined

The complete module was read inline. It defines the ordinary build-graph data
model, graph/text serialization, the legacy text parser, deep-copy operations,
single-target filtering, and recursive dependency-closure selection.

The codebase-memory graph was queried first; it did not extract the `.w`
symbols, so Tilth was used to enumerate current callers and field consumers.
The relevant routes in `main.w`, `BuildGraphMaterialize.w`,
`BuildGraphSupport.w`, `BuildGraphDispatch.w`, `BuildGraphCache.w`, and
`lib/std/build.w` were examined. The current driver calls
`build_graph_filter_target` for both `build` and `run`, and calls
`build_graph_filter_single_target` for `--no-deps`. No production caller of
`parse_build_graph` exists.

Applicable overview targets examined: 1, 8, 12, 15, 17, 18, 21, 23, and 24.
The module does not lower MIR, calculate function ABI, schedule drops, or emit
machine code, so those targets are not credited here.

## Current production route

`BuildGraphMaterialize.w` constructs the graph in memory and calls
`build_graph_emit`. At `main.w:2285-2290`, the driver chooses the requested or
default target and filters the graph before execution. The production filter:

1. deep-copies graph metadata and generated sources;
2. resolves explicit `Target.dep` edges recursively;
3. additionally discovers exact primary-output producers for `entry` and
   `inputs` only;
4. appends dependencies before consumers;
5. deep-copies every retained target, including all owned vector fields; and
6. re-emits the filtered graph text.

The current deep-copy path was checked field by field. It clones all strings,
all nine original `Vec[str]` fields plus `action_source_paths`, and copies every
scalar. The retained matrix exercises a shared-dependency diamond, explicit
cycle, missing dependency, unknown target, declaration-order preservation for
an unfiltered graph, and the one-target `--no-deps` shape. All passed without
an allocator error attributable to graph storage.

## Artifact and executable evidence

The current-stage query ran:

```text
./out/bootstrap/bin/with-stage1 build --explain stage1 :stage1
```

It exited 0, explicitly listed `src/BuildGraphModel.w` in the stage1 inputs,
selected the seed compiler, and carried `-O1`.

The retained direct helper
`docs/audit/probes/build_graph_model_matrix.w` was compiled at `-O1`; its binary
exited 0 with `build-graph-model-matrix: ok`. It pins both the working closure
cases and the legacy-parser acceptance cases described below.

The public fixture `docs/audit/probes/build_graph_model_selection` was evaluated
through the current stage1 compiler. Four `-O1 --graph` selections established
the complete small matrix of producer spellings omitted by the implementation:

| selected consumer | producer representation | filtered result |
|---|---|---|
| `compare` | right operand stored in `args` | right producer omitted |
| `extra-consumer` | producer path in `extra_outputs` | producer omitted |
| `default-consumer` | executable's derived default output | producer omitted |
| `alias-consumer` | equivalent `./out/...` spelling | producer omitted |

The same `compare` target retained the left producer because its left operand is
stored in `entry`. Executing `:compare -O1` exited 1: the edge audit reported
only the left undeclared edge, then dispatch failed because the omitted right
input did not exist.

The native debug allocator isolated graph-owned storage from environment-name
storage. A baseline helper run reported one live 32-byte allocation from the
helper's own mode lookup; the otherwise allocator-clean unfiltered graph case
reported two. An exact-address allocation trap in `lldb` placed the additional
allocation at `rt/rt_core.w:1379` through `with_getenv_str` and
`build_graph_emit`, as detailed in BGMOD-001.

No production source was changed and no full build, full test run, fixpoint,
packaging, or non-Linux execution was performed for this module.

## BGMOD-001 — graph emission and successful filtering leak trace-name buffers

Classification: **Debugger-confirmed shared runtime lifetime defect; candidate unreported**  
Severity: **High**  
Blast radius: every graph emission, successful named filter, and all other
callers of the same runtime environment helper  
Confidence: **Very high**

`build_graph_emit`, `BuildGraphModel.w:158-162`, calls
`with_getenv_str("WITH_TRACE_GRAPH")` on every emission. A successful named
`build_graph_filter_target` performs another lookup at lines 403-405 before it
emits. The variable does not need to be set for the leak to occur.

The exact root is outside the model at `rt/rt_core.w:2440-2445`:
`with_getenv_str` obtains `cname` from `str_to_cstr`, calls `rt_getenv`, and
returns without freeing `cname` on either the present or missing-variable path.
`str_to_cstr` allocated that buffer with `rt_alloc` at `rt_core.w:1379`.

The allocator comparison reported one additional 32-byte live allocation for
the unfiltered graph-emission case. Replaying the precise address with the
debug allocator's trap, then stopping on the exact allocation hit in `lldb`,
produced:

```text
with_panic_core -> dbg_trap_alloc_check -> rt_alloc_with_origin -> rt_alloc
-> str_to_cstr -> with_getenv_str -> build_graph_emit
-> build_graph_filter_target -> main
```

This rules out `BuildGraphSelectedTargets`, its deep copies, and its tracking
vectors as the owner of the live allocation. The existing
`docs/feature_plans/stdlib-getenv-lifetime.md` concerns the separate lifetime
of the borrowed value returned by libc `getenv`; it does not record the
temporary-name leak.

Five Whys:

1. Every emission leaks because its trace gate performs an environment lookup.
2. The lookup leaks because `with_getenv_str` never releases its temporary
   null-terminated name.
3. `str_to_cstr` is documented as call-scoped but exposes an unmanaged raw
   allocation without scope-enforced cleanup.
4. Runtime wrappers independently use the helper without one ownership pattern
   that releases the buffer on every exit.
5. Trace-disabled graph operations were not run under the native allocator, so
   a diagnostic guard was assumed to be allocation-neutral.

Proper repair boundary: have `with_getenv_str` retain the `rt_getenv` result,
release `cname` immediately after the libc call on a shared control path, and
only then select the present/missing return. Audit every internal
call-scoped `str_to_cstr` consumer under the runtime primary report; the
exported conversion API must separately document caller ownership. Add native
allocator coverage for both present and absent environment names.

## BGMOD-002 — target closure implements only a partial implicit producer model

Classification: **Confirmed fail-open graph-selection inconsistency; candidate unreported**  
Severity: **Medium**  
Blast radius: named `build` and `run` selections whose undeclared producer edge
uses anything other than an exact primary-output match through `entry` or
`inputs`  
Confidence: **Very high**

`build_graph_find_output_producer_index`, lines 457-464, recognizes only an
exact textual match against a different target's nonempty primary `output`.
`build_graph_selected_targets_add`, lines 466-502, applies that lookup only to
the consumer's `entry` and `inputs`. It does not include:

- semantic inputs stored in `args`, including the right operand of
  `BinaryCompare` and `FixpointCompare` (`lib/std/build.w:1920-1929`);
- producers whose matching path is an `extra_output`;
- effective default output paths derived later by
  `build_graph_output_path`, such as `out/bin/<target>`; or
- path spellings that resolve to the same project path but are not byte-equal.

The four-case public fixture verified every omission through normal typed
`std.build` construction. The `compare` execution also showed an important
secondary effect: `build_graph_audit_edges` runs after filtering, so an omitted
producer is no longer present for that audit to diagnose. The left edge was
reported because the selector happened to retain its producer; the equally
undeclared right edge was not reported and instead failed later as a missing
file.

`docs/with-build.md:702-707` requires explicit `Target.dep` declarations, and
`BuildGraphSupport.w:297-337` labels path discovery as an audit for undeclared
edges rather than a dependency contract. Therefore this report does not claim
that all path consumers are entitled to automatic dependency inference. The
defect is that the filter contains a partial historical inference mechanism
whose answer varies with field, output representation, and spelling, and then
prevents the full graph from reaching the edge audit.

Five Whys:

1. Equivalent undeclared producer relationships behave differently because
   only some producers survive named filtering.
2. Selection searches only two consumer fields and one producer field by raw
   text.
3. Semantic input/output knowledge is re-derived separately by selection,
   edge audit, output validation, output-path derivation, and dispatch.
4. There is no canonical descriptor that enumerates each target kind's
   produced and consumed paths in resolved form.
5. Tests covered explicit `deps` but not the cross-product of every semantic
   input representation and every output representation.

Proper repair boundary: make explicit `Target.dep` the sole scheduling and
selection authority, as the current documentation says, and run undeclared-edge
validation against the full materialized graph before filtering. Build that
validation from one canonical target-I/O descriptor shared by output
validation, diagnostics, cache inputs, and future scheduling. It must enumerate
kind-specific `args`, primary outputs, extra outputs, and derived outputs after
project-path normalization. If maintainers instead intend implicit dependencies
as contract, the same descriptor must add them uniformly; retaining the current
hybrid is not a valid third design.

Open #680 covers the future topological parallel executor and confirms that
declared dependencies currently affect cache state rather than scheduling. It
does not report this partial selector or the diagnostic loss caused by
filter-before-audit.

## BGMOD-003 — dormant text parser accepts malformed graphs and cannot parse emitted version-2 state

Classification: **Executable legacy parser defect with no current production caller**  
Severity: **Low**  
Blast radius: currently dormant; any future reuse of `parse_build_graph` for
cache, IPC, tooling, or native build-graph ingestion  
Confidence: **Very high for behavior and current non-reachability**

`build_graph_parse_i32`, lines 205-218, returns zero for empty/non-numeric input
and accepts the numeric prefix of trailing junk. It performs no checked
overflow. `parse_build_graph`, lines 220-344, then:

- accepts those permissive integers for target kind, target platform,
  optimization, timeout, and network fields;
- ignores the serialized target-index field on every per-target metadata line
  and attaches the value to whichever target was most recently declared;
- accepts duplicate target names and graphs missing ordinary structural data;
  and
- has no `parallel` branch even though `build_graph_emit`, lines 201-202, emits
  `parallel` records in version 2.

The direct matrix verified valid parsing as a positive control, then verified
that a metadata index of `999` was accepted and attached to target zero,
`16junk`/`0oops`/`0more` were accepted as integer prefixes, empty integer fields
became zero, and duplicate names were accepted. Finally it emitted a graph with
`parallel = 1`; parsing that module-produced text failed on the unknown
`parallel` tag. Thus the format's own writer and reader are not inverses.

Exact current searches found only the definition and retained audit probes.
History identifies `9f932948` (`Evaluate build.w graphs in-process`, 2026-05-20)
as the change that removed the production parse call while leaving the parser.
The change touched the driver, comptime evaluator, and materializer, not this
module. The defect is therefore not represented as active public input
acceptance, but the public function is unsafe to revive or use as a format
validator.

Five Whys:

1. Malformed text is accepted because the parser treats prefixes/default zero
   as successful numeric conversion and ignores record ownership indices.
2. Writer output can be rejected because format fields were added to emission
   without updating the reader.
3. Parsing and emission are manually maintained tag chains with no shared
   schema or exhaustive field accounting.
4. The parser became dead after in-process graph evaluation but remained public
   and compiled into the compiler.
5. No round-trip, malformed-input, or dead-export test guards the boundary.

Proper repair boundary: remove the dead parser if the text is diagnostic-only.
If text ingestion remains a supported or planned boundary, define one versioned
schema consumed by both emitter and parser; use checked full-string numeric
conversion; validate record order, target indices, required/unique fields,
enum domains, and target-name uniqueness; reject unknown escapes and trailing
escape bytes; and require `parse(emit(graph))` equivalence for every serializable
field. Runtime-only fields that cannot be serialized must be explicitly outside
that equivalence rather than silently disappearing.

## Working behavior retained

- Empty graph construction initializes every scalar and owned vector field.
- Emission escapes tabs, newlines, carriage returns, and backslashes used by
  the current writer.
- Named selection rejects unknown targets, missing explicit dependencies, and
  real dependency cycles.
- Dependencies are appended before their consumers; shared dependencies are
  emitted once. The diamond control produced `d, b, c, a`.
- An empty selection preserves every target in declaration order.
- `build_graph_filter_single_target` retains exactly the requested target and
  loudly requires a name.
- Target deep copies clone every current owned buffer, including the action
  source closure added after the original nine-vector warning.
- Generated-source contents and paths are deep-copied by both filter routes.

## Test-coverage audit and required regression matrix

No direct production test import or reference to `BuildGraphModel` was found
under `test/` or `tests/`. Existing integration builds exercise ordinary graph
selection, but they do not pin the module's complete answer space.

Production coverage should add:

- closure selection for a chain, diamond, disjoint graph, self-cycle,
  multi-node cycle, missing dependency, duplicate dep, unknown target, and
  empty/all-target selection;
- every target kind's semantic input fields crossed with primary, extra, and
  derived output forms, including normalized equivalent paths;
- full-graph undeclared-edge diagnostics before selection, proving filtering
  cannot erase a diagnostic;
- deep-copy/drop tests for empty and nonempty values in every owned target and
  generated-source field under the native allocator;
- trace-variable absent, empty, and nonempty cases for emission, named
  filtering, single-target filtering, and all-target filtering;
- if the parser remains, valid versions 1 and 2; every tag; missing, duplicate,
  reordered, unknown, and wrong-arity records; exact target indices; all enum
  domains; empty, signed, overflowed, and junk-suffixed integers; every escape;
  and writer/reader round trips; and
- if the parser is intentionally retired, a source-level prohibition on
  reintroducing a text-ingestion caller without the full parser matrix.

The upstream tracker was searched for implicit producer selection, build-graph
dependency filtering, parser/parallel round trips, environment-name leaks, and
C-string conversion leaks. No exact report was found. Open #680 is related
future scheduler work, not a report of BGMOD-001 through BGMOD-003. No issue was
filed during this report-only audit.

## Completion statement

The primary agent examined all 506 source lines, every data-model field, the
sole current materialization/emission route, all production filter call sites,
the complete recursive selection algorithm, deep-copy ownership, every parser
tag and numeric conversion, artifact inclusion, direct tests, allocator output,
the exact debugger allocation trace, relevant build documentation, history,
and upstream issues. The retained `-O1` fixtures reproduce the active selector
inconsistency and dormant parser defects; the native allocator plus `lldb`
trace pins the active leak to its exact runtime allocation. This evidence
supports marking `src/BuildGraphModel.w` complete while retaining the three
findings for prioritization.

## Catch-up addendum (`450733e5`, read-only source review)

The delta adds `build_graph_output_index` and `build_graph_complete_edges`
(`src/BuildGraphModel.w`, ~line 380): D36 producer-edge inference moved from
`BuildGraphSupport.w`'s removed audit-note into enforced completion, called
once from `BuildGraphMaterialize.w:279` before the graph is emitted.

Review assessment (source only, no execution): the removed audit-note warned
that ordering-only edges must never feed dep_rebuilt staleness. The new
function infers dep edges for every consumed-produced file match, and those
edges feed dep_rebuilt exactly like written `.dep()`s. The design answers the
warning by classifying all inferred edges as data edges, but no branch
distinguishes a consumer whose use is order-only (e.g. an entry path that
must exist but whose bytes don't matter) — such a consumer now gains a dep
edge and can trigger rebuilds (and stale-artifact windows) it previously
avoided. Direction of risk is over-invalidation (perf) unless some
consumption was load-bearing without bytes, in which case it is correctness.
Queued as review note R-1: re-verify the old trap with an order-only consumer
probe when execution resumes. The three retained findings are unaffected
(this hunk touches neither the selector, the parser, nor the leak sites).
