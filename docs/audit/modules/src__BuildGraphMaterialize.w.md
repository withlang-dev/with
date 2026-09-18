# Primary verification — `src/BuildGraphMaterialize.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `9ba08127842f886149fc3d5e161b373ae6796d65855594661029eb05aab806d2`  
Source examined: all 294 lines

## Scope examined

The complete module was read inline. It converts the typechecked comptime value
returned by `build(ctx)` into the compiler's ordinary `BuildGraph`: reflected
field lookup, scalar and string-vector conversion, target validation, action
source-closure discovery, generated-source conversion, package/default fields,
and final graph emission.

The codebase-memory graph was queried first. Its `.w` extraction returned no
materializer symbols, so Tilth was used to enumerate the sole production caller
and exact field consumers. The relevant paths in `main.w`, `ComptimeEval.w`,
`ComptimeValue.w`, `BuildGraphKinds.w`, `BuildGraphModel.w`,
`BuildGraphSupport.w`, `BuildGraphDispatch.w`, `BuildGraphCache.w`,
`BuildGraphOps.w`, and `lib/std/build.w` were examined. The prior primary audits
of `BuildGraphKinds.w`, `BuildGraphCache.w`, and `BuildGraphDispatch.w` supplied
direct cross-boundary controls; no unchecked result from those reports was
accepted as evidence here.

`src/main.w:1298-1302` generates a wrapper whose return type is exactly `Build`,
then `main.w:1529-1556` typechecks and evaluates it, calls
`materialize_build_graph_from_comptime`, records effects, and serializes the
result. There is no second production materialization entry. The layout-only
tool import is not a runtime caller.

Applicable overview targets examined: 1, 8, 12, 18, 21, 23, and 24. The module
does not lower MIR, select an ABI, emit machine code, schedule cleanup, or
implement container storage; those concerns are not credited as complete here.

## Contract boundary and complete conversion route

The generated wrapper's `-> Build` annotation prevents ordinary source from
substituting an unrelated look-alike struct. Within that type, however, enum
casts and arbitrary string contents are representable, and the evaluator hands
the materializer a generic arena-backed `ComptimeValue`. This module is the one
boundary that must either produce a semantically valid `BuildGraph` or return a
named error. It must not silently coerce malformed evaluator state into a
different build.

The complete route was checked:

- `field_index` resolves field positions from the reflected type;
- `field_value` clones an arena element after checking only the reflected index
  against the struct's declared `extra_count`;
- required scalar fields use `expect_str_field`/`expect_i32_field`;
- eight target lists plus action environment use `string_vec_field`;
- target kind and target platform have explicit range authorities in
  `BuildGraphKinds.w`;
- optimization mode has no corresponding validation;
- optional timeout, cwd, network, and parallel fields are copied only when
  their runtime value kind matches, otherwise they retain defaults;
- action targets require a function and non-action targets reject a non-noop
  function;
- action closure discovery walks the defining module and its transitive import
  closure, with an empty result deliberately selecting cache over-invalidation;
- generated sources require a struct with string path and contents; and
- the package, default, generated-source list, and target list are converted
  before `graph.ok` is set and `build_graph_emit` is called.

## Artifact and optimization evidence

The earlier primary stage query in this audit ran:

```text
./out/bootstrap/bin/with-stage1 build --explain stage1 :stage1
```

It exited 0, reported the target fresh, explicitly listed
`src/BuildGraphMaterialize.w` among the stage1 sources, selected the seed
compiler, and carried `-O1`.

The retained public fixture
`docs/audit/probes/build_materialize_invalid_opt` was evaluated by the current
stage1 compiler with `-O1`. Its valid `Build` contains three executable targets
whose `OptimizeMode` values are produced by explicit enum casts: `-1`, `2`, and
`2147483647`. Graph evaluation exited 0. The evaluated graph cache preserved all
three exact integers, proving that the values crossed the comptime
materialization boundary rather than being rejected or normalized.

No production source was changed and no broad build, full test run, fixpoint,
packaging, or non-Linux execution was performed for this module.

The native debug allocator was subsequently applied while auditing the adjacent
graph model. An exact-address trap and `lldb` backtrace reached
`rt/rt_core.w:2441` through `build_graph_emit`; inspection of this module then
confirmed that its own trace probes exercise the same leaking runtime boundary.

## BGM-001 — target names are not validated as storage-safe identifiers

Classification: **Confirmed shared state-containment defect; same root as BGC-006**  
Severity: **High**  
Blast radius: every materialized target name later used for cache state,
effects, test markers, verdicts, action scratch paths, and command capture paths  
Confidence: **Very high**

`materialize_target`, `BuildGraphMaterialize.w:114-119`, rejects only empty and
duplicate names. It does not reject separators, dot segments, control bytes,
or platform-specific path syntax before line 134 copies the string into the
ordinary graph.

The retained public fixture `docs/audit/probes/build_cache_target_name` uses the
normal `std.build` API to name a harmless response-file target `../escaped`.
The `-O1` build succeeded and wrote its state as `out/escaped.state`, outside
the intended `out/.build-state` directory. This result was independently
isolated in the `BuildGraphCache.w` primary audit; here it proves the malformed
identifier crosses this module's exact acceptance branch.

Five Whys:

1. State escapes its intended subdirectory because the raw target name becomes
   part of a pathname.
2. The raw name reaches storage because materialization accepts every nonempty,
   unique string.
3. Name validity is treated only as graph lookup uniqueness, not as the shared
   identifier contract required by later filesystem consumers.
4. Cache, scratch, and capture paths each concatenate names without consuming a
   validated/encoded identifier type.
5. Existing tests exercise ordinary names but not the complete grammar at the
   one source-to-graph boundary.

Proper repair boundary: define one target-name grammar and enforce it in
`materialize_target` before the target is appended. Reject path separators,
`.`/`..` segments, control and NUL bytes, unsupported platform spellings, and
excessive length with a target-named diagnostic. Store or encode the already
validated identifier for all filesystem consumers and retain containment
assertions at write boundaries. Sanitizing silently is not acceptable because
it can collide names and break dependency/default lookup.

## BGM-002 — invalid `OptimizeMode` discriminants become valid graph state

Classification: **Confirmed malformed-enum acceptance defect; candidate unreported**  
Severity: **Medium**  
Blast radius: targets whose typed build source explicitly or indirectly creates
an invalid `OptimizeMode` value, plus any future producer of the same graph
field  
Confidence: **Very high**

`OptimizeMode` has exactly two public values in `lib/std/build.w:68-70`:
`debug = 0` and `release = 1`. `materialize_target` requires only that the
field's comptime representation be `CV_INT`; at
`BuildGraphMaterialize.w:130-134` it validates `target_kind` but copies
`optimize_value.data0 as i32` without any optimization-mode range check.

The retained fixture exhausted the meaningful invalid integer classes around
this two-value enum: negative (`-1`), the first value above the range (`2`), and
the maximum positive `i32` (`2147483647`). A public `with build -O1 --graph`
invocation exited 0, and `out/.build-state/build-graph.cache` recorded all three
values unchanged.

The downstream branch at `main.w:1657-1661` recognizes only the integer `1` as
release and treats every other value as the caller's base optimization. Thus an
invalid discriminant is not merely retained for a later diagnostic; it silently
selects the non-release branch.

Five Whys:

1. Invalid enum values reach executable build planning because materialization
   accepts every integer representation.
2. The materializer checks the representation kind but not the enum's semantic
   domain.
3. Unlike build kind and target platform, optimization mode has no shared
   validator in `BuildGraphKinds.w`.
4. The consumer uses a binary equality test rather than an exhaustive validated
   enum decision.
5. Tests assert the ordinary debug value but include no invalid enum cast or
   malformed-state negative case.

Proper repair boundary: add one optimization-mode validity/name authority next
to the other stable graph enums, reject all values outside `0..1` during
materialization, and require the serialized-graph reader to use the same
authority. Downstream planning should consume the validated enum exhaustively,
with an unreachable/loud diagnostic for impossible state rather than mapping
unknown values to debug behavior.

## BGM-003 — malformed arena-backed fields can be dropped, defaulted, or indexed without a boundary diagnostic

Classification: **Source-confirmed fail-open/robustness defect; no ordinary well-typed producer found**  
Severity: **Low**  
Blast radius: compiler/evaluator defects or corrupted internal comptime values
at the `ComptimeValue`-to-`BuildGraph` boundary  
Confidence: **High for the source behavior; no public runtime occurrence claimed**

Three related branches make the converter non-total over its generic input:

- `string_vec_field`, `BuildGraphMaterialize.w:57-66`, returns an empty vector
  when the field is not a vector/array and silently skips every element whose
  kind is not `CV_STR`;
- `materialize_target`, lines 143-155, silently retains defaults when timeout,
  cwd, network, or parallel has the wrong `ComptimeValueKind`; a wrong-kind
  action field on a non-action target is likewise ignored at lines 156-167; and
- `field_value`, lines 37-43, checks a reflected index against the value's local
  `extra_count` but never proves that `extra_start + index` is nonnegative,
  non-overflowing, and within `self.extras`. The list loops at lines 62-65,
  265-266, and 273-274 have the same unvalidated arena-span assumption.

The generated wrapper guarantees the static `Build` field types, and no
ordinary well-typed source was found that produces these malformed runtime
kinds or spans. Therefore this is not reported as a current public-source data
loss reproduction. It is still a defect in a validator-like boundary: should
the evaluator produce inconsistent aggregate state, some fields are silently
discarded/defaulted while others can terminate in a generic vector-bounds
panic, instead of identifying the invalid field and refusing the graph.

Five Whys:

1. A malformed field can change meaning or panic because conversion assumes
   most evaluator invariants instead of checking them.
2. Scalar required fields have explicit kind checks, but vector elements and
   optional fields use permissive helpers.
3. Helper return types cannot distinguish a legitimate empty/default value from
   conversion failure.
4. Arena coordinates are plain integers with no validated slice/view type.
5. Coverage enters through well-typed `std.build` constructors and never feeds
   inconsistent arena records to the boundary.

Proper repair boundary: validate every arena span with checked arithmetic before
the first `get`; make field/list conversion return an explicit success/error
result; require every declared `Target` field to have its exact expected value
kind; and reject the whole graph on the first mismatch with the target, field,
expected kind, and observed kind. Empty vectors and default-valued optional
fields must remain distinguishable from conversion failure. Do not silently
filter elements or retain defaults after a type mismatch.

## BGM-004 — graph materialization leaks every trace-environment lookup

Classification: **Debugger-confirmed shared runtime lifetime defect; candidate unreported**  
Severity: **High**  
Blast radius: every successful build-graph materialization, with an additional
allocation per materialized target; shared root also affects all other callers
of `with_getenv_str`  
Confidence: **Very high**

`materialize_build` calls `with_getenv_str("WITH_TRACE_GRAPH")` at
`BuildGraphMaterialize.w:248`, `:259`, `:280`, and `:283`, and once per target
at `:277`. It then calls `build_graph_emit` at line 282, whose own trace check
performs another lookup. The trace variable does not need to be set: both the
present and missing-variable branches leak the temporary name buffer.

The exact root is `rt/rt_core.w:2440-2445`. `with_getenv_str` calls
`str_to_cstr(name)`; that helper allocates `name.len() + 1` bytes with
`rt_alloc` at `rt_core.w:1379`. The returned pointer is passed to `rt_getenv`
but is never passed to `rt_free`, including on the early missing-variable
return. The native allocator reported stable live allocations. Replaying the
additional graph-emission address with `WITH_DEBUG_ALLOC_TRAP_FREE`, then
breaking on its exact allocation hit in `lldb`, produced this stack:

```text
with_panic_core -> dbg_trap_alloc_check -> rt_alloc_with_origin -> rt_alloc
-> str_to_cstr -> with_getenv_str -> build_graph_emit
-> build_graph_filter_target -> main
```

That instruction-level trace rules out the graph vectors and target-selection
bookkeeping as the allocation owner. Source inspection also found many other
unreleased internal `str_to_cstr` call sites in `rt_core.w`; those broaden the
runtime defect but are reserved for the primary runtime audit. The existing
`docs/feature_plans/stdlib-getenv-lifetime.md` records a separate question about
the lifetime of the value returned by libc `getenv`; it does not record this
temporary-name leak.

Five Whys:

1. Materialization leaks because each trace gate allocates a C-string name.
2. The allocation survives because `with_getenv_str` never releases `cname`.
3. `str_to_cstr` is described as call-scoped but returns an unmanaged raw
   allocation with no scope-enforced cleanup.
4. Runtime wrappers independently call the conversion helper without a single
   ownership pattern that guarantees release on every return path.
5. Trace-disabled builds were not exercised under the native leak detector, so
   the apparently harmless environment checks escaped coverage.

Proper repair boundary: in `with_getenv_str`, retain the `rt_getenv` result,
release `cname` immediately after the libc call on the shared path, and only
then branch on the returned value. More broadly, every internal call-scoped
`str_to_cstr` use must adopt scope-guaranteed release, while the exported
`with_str_to_cstr_ref` API must keep an explicit caller-owned contract. This is
independent of the unresolved borrowed-versus-owned contract for the value
returned by `getenv`.

## Working behavior retained

- The generated evaluation wrapper requires the imported `build(ctx)` result
  to typecheck as `Build`; unrelated structural look-alikes fail before this
  module.
- Required package, default, target scalar, and generated-source fields fail
  with explicit errors when their broad value kind is wrong.
- Removed, unknown, and unimplemented target kinds are rejected before a target
  is appended.
- Target platform values are checked against the current internal authority.
  The already-reported public/internal Windows-aarch64 mismatch belongs to
  `BuildGraphKinds.w`, not to this call site's use of that authority.
- Action targets require a function. A non-action target carrying a non-noop
  function is rejected.
- Missing action source metadata produces a visible trace message and an empty
  closure. `BuildGraphCache.w` interprets empty as hashing all graph sources, so
  this path over-invalidates rather than silently under-invalidating.
- Generated sources and targets are accumulated only while `error_msg` remains
  empty, and `graph.ok` is set only after both complete loops.
- A nonexistent default target is rejected later by the target filter at
  `main.w:2285-2293`; it does not become a successful no-op build.

## Test-coverage audit and required regression matrix

Exact searches under `test/` and `tests/` found no direct import or reference to
`BuildGraphMaterialize` or `materialize_build_graph_from_comptime`. The only
`optimize_mode` assertion is the ordinary `OptimizeMode.debug` case in
`test/behavior/behav_std_build_api.w`; it tests the library constructor, not
this conversion boundary.

Production coverage should add:

- every required field absent and present with every wrong value kind;
- valid empty and nonempty vectors, wrong container kinds, and one wrong-kind
  element at the beginning, middle, and end;
- negative, overflowed, truncated, and out-of-range arena spans with checked
  diagnostic results rather than panics;
- all valid and invalid build-kind, target-platform, and optimization-mode
  values, including integer boundaries;
- empty, duplicate, separator-bearing, dot-segment, control/NUL, Unicode,
  maximum-length, and platform-reserved target names;
- action/noop/non-action function combinations and missing action metadata;
- import chains with cycles, unresolved import edges, and defining modules at
  every graph position;
- package/default fields, empty target graphs, missing defaults, and generated
  source field/path cases; and
- proof that any invalid field prevents `graph.ok`, graph serialization, target
  execution, and all graph-derived filesystem mutation; and
- allocator-clean trace-variable checks for missing, empty, and nonempty values,
  with zero, one, and multiple materialized targets.

The upstream tracker was searched for optimization-mode validation, target-name
validation, malformed build-graph fields, `with_getenv_str` leaks,
`str_to_cstr` leaks, and environment-allocation leaks. No exact report was
found. Closed
#686 is the source-closure over-invalidation history implemented by this module;
open #921 replaces interpreted build evaluation with a compiled native graph
runner and would remove or redesign this materialization boundary. Neither
reports BGM-001 through BGM-004. No issue was filed during this report-only
audit.

## Completion statement

The primary agent examined all 294 source lines, the sole production caller,
the typed wrapper and evaluator handoff, every reflected field and arena access,
the complete target-kind/platform validation route, optimization consumption,
action closure construction, generated-source conversion, graph completion,
serialization handoff, trace-environment/runtime allocation path, and existing
test references. The public `-O1` fixtures
pin the storage-name and optimization findings to the exact acceptance branches;
the malformed aggregate weakness is explicitly limited to source-proven
internal behavior rather than presented as an executed public bug; and the
allocator trap plus debugger backtrace pins the shared leak to its exact
allocation line. This evidence supports marking `src/BuildGraphMaterialize.w`
complete while retaining the four findings for prioritization.
