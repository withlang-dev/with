# Primary verification — `src/BuildGraphOps.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `0e5b5faba5aed6bf47091959d41436b60f7dc87c11ce36796560064a91f5377c`  
Source examined: all 632 lines

## Scope examined

The complete module was read inline. It implements standard build-graph
operations: binary/fixpoint comparison, clean, response-file generation,
C/LLVM/assembly compilation, archive creation, embedded-object assembly,
manifest copying, verified promotion, corpus and command execution, single-file
copy, install-path expansion, mode parsing, and atomic install replacement.

The codebase-memory graph was queried first. Its current `.w` index returned no
operation symbols, so Tilth was used to enumerate definitions, callers, public
constructors, runtime wrappers, tests, and platform-symbol consumers. The
relevant paths in `BuildGraphDispatch.w`, `BuildGraphRuntime.w`,
`BuildGraphSupport.w`, `BuildGraphModel.w`, `Archive.w`, `main.w`, `build.w`,
`lib/std/build.w`, `rt/rt_core.w`, and `src/compiler/Link.w` were examined.

`BuildGraphDispatch.w` is the production router for these operations. The
module receives already-materialized targets, but it remains responsible for
operation-specific validation and for preserving the artifact and process
contracts expressed by each target. Applicable overview targets examined: 1,
18–19, and 21–24. The module does not lower MIR, compute function ABI, schedule
drops, implement suspension, or own container layouts; none of those targets
is credited here.

## Complete operation matrix

| Operation | Source branch | Executed evidence | Verdict |
|---|---:|---|---|
| binary/fixpoint compare | 22–52 | differing directories compare green | BGO-002 |
| clean | 54–75 | `"."` removes the confined root contents | BGO-001 |
| response file | 77–112 | interior NUL written verbatim | BGO-004 |
| C object | 114–147 | root graph declares ordinary targets | working path retained |
| assembly object | 149–175 | unknown and empty triple args use host | BGO-007 |
| LLVM IR object | 177–193 | root graph declares ordinary targets | working path retained |
| static archive | 195–232 | failed replacement deletes prior output | BGO-006 |
| embedded objects | 234–345 | fallback set omits Linux aarch64 | BGO-010 |
| manifest copy | 347–374 | late missing input leaves earlier copy | BGO-005 |
| verified promotion | 376–423 | late missing input leaves earlier promotion | BGO-005 |
| corpus runner | 425–462 | contract compared with command runner | BGO-003 |
| command runner | 464–509 | timeout/cwd/env/extra-output matrix | BGO-003 |
| copy file | 511–544 | directory becomes empty regular file | BGO-002 |
| install expansion/install | 546–632 | missing HOME writes under literal `$HOME` | BGO-008/BGO-011 |
| octal parser | 575–584 | `10000` accepted and masked to mode `0000` | BGO-009 |

## Artifact and optimization evidence

The retained stage explanation from this audit ran the current stage1 compiler
against `:stage1`; it exited 0, listed `src/BuildGraphOps.w` as a stage input,
and showed `-O1`. The root graph declares normal object, archive, embed,
response, copy, compare, and install targets, and the retained artifacts show
that those paths have built successfully. Neither the fresh explanation nor
those artifacts are treated as negative-case proof.

The retained fixture `docs/audit/probes/build_graph_ops_io` uses only public
`std.build` values and executes each malformed case with the current stage1
compiler at `-O1`. The separate
`docs/audit/probes/build_graph_ops_clean_root.w` imports the real module and confines
the destructive clean reproduction to an ignored disposable directory. No
production source was changed. No full build, fixpoint run, test suite,
packaging run, or non-Linux execution was performed for this module.

## BGO-001 — clean accepts the project root and recursively removes its contents

Classification: **Confirmed destructive containment defect; candidate unreported**  
Severity: **Critical**  
Blast radius: any clean target whose argument is `.` or another spelling that
resolves to its build root  
Confidence: **Very high**

`build_graph_run_clean`, `BuildGraphOps.w:54-75`, rejects an argument only when
it is empty, starts with `/`, or contains the byte substring `..`. The relative
path `.` satisfies that predicate. Line 61 resolves it to `<root>/.`; lines
62–63 recognize it as a directory and recursively remove it. The final removal
of `<root>/.` fails only after its children have already been deleted.

The direct confined probe created a marker below
`docs/audit/probes/build_graph_ops_clean_sandbox`, passed `.` with that directory as
the operation root, and observed:

```text
error: clean target 'clean-root' could not remove directory tree: docs/audit/probes/build_graph_ops_clean_sandbox/.
clean-root rc=1 marker-removed
```

The probe exited 0 only because both assertions held: the operation reported
failure and the marker had nevertheless been removed. The sandbox root itself
remained. Historical Phase-F audit text explicitly exempted clean from global
containment because this function was believed to have its own validation;
this reproduction disproves that premise.

Five Whys:

1. The root contents are removed because `.` resolves to the operation root.
2. `.` is accepted because the check searches for `..` rather than parsing path
   components and identity.
3. The function assumes a relative spelling is necessarily a strict descendant.
4. Clean bypasses the shared target-containment route on the claim that this
   local predicate is stronger.
5. Coverage tests ordinary artifact directories but not root identity, dot
   segments, normalized aliases, symlinks, or failure atomicity.

Proper repair boundary: parse and canonicalize every requested removal before
the first deletion, reject root identity and any path not proven to be a strict
descendant of the allowed clean roots, and preferably restrict deletion to
declared build-artifact roots rather than arbitrary project descendants.
Preflight the complete argument list before mutating the first path. Symlink and
platform-path cases require the same canonical containment authority; another
substring filter is not a repair.

## BGO-002 — file reads conflate directories/errors with empty files

Classification: **Confirmed false-green verification and silent artifact corruption defect**  
Filed as upstream [#953](https://github.com/withlang-dev/with/issues/953)  
Severity: **Critical**  
Blast radius: binary and fixpoint comparison, copy-file, promotion, manifest
copy, install, and any operation that treats `build_graph_rt_read_file` as an
infallible byte source  
Confidence: **Very high**

`build_graph_compare_files`, lines 31–38, checks only that each path exists and
then reads both as strings. `build_graph_copy_file_to_path`, lines 511–525, does
the same before writing the returned string. The runtime wrapper at
`BuildGraphRuntime.w:74-75` forwards directly to `with_fs_read_file`; that
function returns the same empty string for a directory, open failure, and a
legitimate empty file at `rt_core.w:3257-3267`.

The public fixture supplied two directories containing different files:

- `:compare-directories -O1` exited 0 and produced a green survey verdict;
- `:copy-directory -O1` exited 0; the source remained a directory, while the
  destination was a zero-byte regular file.

Because fixpoint comparison shares this exact function, a malformed or
unreadable pair of stage paths can be reported byte-identical when both reads
collapse to `""`. This is a false-green integrity failure, not merely a poor
diagnostic.

Five Whys:

1. Different inputs compare equal and directories copy as empty files because
   both reads yield an indistinguishable empty string.
2. Existence is checked, but regular-file type and read success are not.
3. The filesystem read API has no status-bearing return value.
4. Operations treat a convenience string result as proof that bytes were read.
5. Tests cover ordinary files and do not enumerate directory, permission,
   disappearing-file, short-read, device, and real empty-file cases.

Proper repair boundary: introduce a status-bearing exact-read result that
distinguishes empty success from every failure, validate regular-file inputs
where the operation requires files, and make all consumers handle the error
before comparing or writing. Artifact writes must likewise surface short or
partial writes and should use sibling temporaries when replacing established
outputs. Fixpoint must fail closed on any non-regular or unreadable stage input.

## BGO-003 — command and corpus targets ignore declared execution contracts

Classification: **Confirmed target-contract loss and false-green output-validation defect**  
Severity: **High**  
Blast radius: all `Command` and `RunCorpusTest` targets using timeout, working
directory, environment, or extra outputs  
Confidence: **Very high**

The public `Target.timeout`, `working_dir`, and `with_env` methods populate
generic target fields at `lib/std/build.w:1831-1844`; `extra_output` is likewise
a generic declaration at lines 2232–2235. The operation branches do not consume
those fields:

- corpus and command hardcode `timeout_ms = 300000` at
  `BuildGraphOps.w:454` and `:496`;
- both call `build_graph_rt_exec_argv_capture`, although the runtime facade
  already exposes a cwd-capable variant;
- neither applies `target.env`; and
- command checks only `target.output` at lines 504–508 and never verifies
  `target.extra_outputs`.

The `-O1` public matrix proved each loss independently:

- a command configured for a 1 ms timeout ran `/usr/bin/sleep 0.2` for about
  0.2 seconds and exited green;
- `/bin/pwd` with working directory `left` captured the project root;
- `/usr/bin/env` with `WITH_AUDIT_SENTINEL=present` omitted that variable; and
- `/usr/bin/true` declaring only `out/never-created` as an extra output exited
  green while the path was absent.

The action branch in `main.w:1496-1511` verifies its primary and every extra
output, confirming that two execution paths implement divergent versions of
the same target contract.

Five Whys:

1. Configured execution semantics disappear because the operation rebuilds a
   smaller process request from entry and args alone.
2. Timeout is replaced by a literal and cwd/env fields are never read.
3. Process setup and output verification are duplicated between action,
   command, and corpus paths.
4. There is no single validated process descriptor that must consume every
   declared field.
5. Tests exercise successful commands but not a complete field-by-kind matrix
   or missing-extra-output negative control.

Proper repair boundary: construct one process-execution descriptor from the
validated target and use it for action, command, and corpus execution. It must
define the zero-timeout default, pass a child-specific cwd and environment
without mutating shared parent state, preserve capture paths, and verify the
primary plus every extra output after success. If a field is unsupported for a
kind, materialization must reject it explicitly instead of silently ignoring it.

## BGO-004 — response files accept and preserve interior NUL bytes

Classification: **Confirmed invalid process-argument serialization defect**  
Severity: **Medium**  
Blast radius: generated response files consumed by native tools  
Confidence: **Very high**

`build_graph_response_arg_valid`, lines 77–82, rejects only line feed and
carriage return. It does not share the process-argument validator's NUL rule.
The fixture constructed an argument with `StringBuilder.push_byte(0)` and
`:response-nul -O1` exited green. The resulting bytes were:

```text
22 62 65 66 6f 72 65 00 61 66 74 65 72 22 0a
```

Thus the output is quote, `before`, NUL, `after`, quote, newline. A NUL cannot
represent one ordinary native process argument and downstream consumers may
truncate or reject it.

Five Whys: the specialized validator omits NUL; response serialization and
process invocation have separate argument contracts; strings are assumed to be
interchangeable with native arguments; and no byte-domain test compares both
paths. The repair is one shared textual-process-argument predicate, complete
preflight before creating output directories or files, and a normal named
diagnostic for NUL rather than emitting it.

## BGO-005 — manifest copy and verified promotion mutate before full validation

Classification: **Confirmed loud-failure/partial-artifact defect**  
Severity: **High**  
Blast radius: multi-file `CopyTree` and `PromoteTreeIfVerified` targets with a
bad later entry or a later filesystem failure  
Confidence: **Very high**

Both loops validate, read, and write one entry before inspecting the next:
`build_graph_copy_manifest_files` at lines 356–373 and
`build_graph_promote_tree_if_verified` at lines 387–418. The retained fixture
placed a valid stale first file before a missing second file. Both public
targets exited nonzero on the missing path, but inspection afterward showed the
first destination had already changed from `original` to `replacement`.

The promotion result is especially misleading: a target explicitly named
“if verified” can leave a mixed old/new destination even though its build
failed. A later run may consume that partial tree.

Five Whys: validation is interleaved with mutation; the target is modeled as a
loop of independent copies rather than one artifact transaction; dependency
completion is mistaken for proof that the destination update cannot fail; and
coverage checks the exit code but not filesystem state after a late failure.

Proper repair boundary: first validate the complete relative-path set, every
source's type/readability, destination containment, duplicates, and expected
write plan. For promotion, stage all changed files in a sibling tree and commit
the completed set atomically or through a recoverable manifest protocol. At a
minimum, all predictable validation failures must occur before the first write,
and regression tests must assert post-failure destination contents.

## BGO-006 — failed archive replacement deletes the prior good artifact

Classification: **Confirmed destructive failure-order defect**  
Severity: **Medium**  
Blast radius: archive targets whose inputs pass existence checks but cannot be
read or whose replacement write fails  
Confidence: **Very high**

`build_graph_create_archive` validates only path existence and duplicate
basenames, then unconditionally removes `output_path` at line 227 before
calling `create_static_archive`. The archive helper can still fail while
reading members at `Archive.w:300-309` or writing the result.

The fixture started with a sentinel archive and supplied an existing directory
as its member. The target failed loudly with `archive: cannot read member`, and
the prior output was absent afterward. Loud failure therefore destroys the
last known artifact.

Five Whys: deletion precedes replacement validation; archive creation writes to
the final pathname; input existence is treated as readability; no atomic
replacement primitive defines the operation; and tests do not assert old-output
preservation after failure. The proper repair is to read/validate every member,
write a uniquely named sibling temporary, verify/close it, and atomically rename
it over the destination only after success, cleaning the temporary on all
failures.

## BGO-007 — unsupported assembly arguments silently select the host assembler

Classification: **Confirmed forbidden silent fallback**  
Severity: **Medium**  
Blast radius: assembly-object targets with malformed, unsupported, empty, or
additional target arguments  
Confidence: **Very high**

`build_graph_assemble_to_object`, lines 162–172, looks only at the first
argument. It sets a cross triple only when that string begins `triple=` and the
suffix is nonempty. Unknown first arguments, `triple=`, and all additional
arguments are silently ignored, selecting the host assembler.

Both `unsupported-option` and `triple=` fixtures exited green and produced
host x86-64 ELF relocatables. This is exactly the repository's prohibited
“simplify into something that builds differently” behavior.

Five Whys: optional parsing is permissive; empty and unrecognized values share
the host default; cardinality is not validated; the operation has no typed
assembly-target field; and ordinary host/cross paths never test malformed
arguments. The repair is to accept exactly zero args or exactly one nonempty,
canonical, supported `triple=<value>` argument, reject every other spelling and
extra argument before creating the output, and validate agreement with the
target platform authority.

## BGO-008 — unresolved `$HOME` installs into a literal project directory

Classification: **Confirmed fail-open path-expansion defect**  
Severity: **Medium**  
Blast radius: install targets using `$HOME/...` when HOME is missing or empty  
Confidence: **Very high**

At `BuildGraphOps.w:546-559`, a recognized `$HOME/` prefix expands only when
the environment value is nonempty; otherwise execution falls through to the
ordinary project-relative resolver. `build_graph_install_file` then checks
whether the already-resolved result both equals the original string and starts
with `$HOME/` at lines 600–603, a condition that cannot catch the prefixed root.

Running `:install-home -O1` with HOME removed exited green and created the
regular file `$HOME/audit-installed` beneath the fixture root. The requested
home install did not occur, yet the build reported success.

Five Whys: expansion has no error result; recognized-but-unresolved variables
fall through as literal paths; the guard runs after resolution and compares
different representations; success is defined only by a completed copy; and
coverage assumes HOME exists. The repair is a status-bearing expansion result
that rejects missing/empty variables before project resolution, with separate
tests for missing, empty, set, absolute, DESTDIR, BINDIR, and PREFIX cases.

## BGO-009 — octal mode parsing accepts values outside the permission domain

Classification: **Confirmed unchecked numeric-domain defect**  
Severity: **Medium**  
Blast radius: copy and install targets with oversized octal mode arguments  
Confidence: **Very high**

`build_graph_parse_octal_mode`, lines 575–584, checks only that all digits are
octal. It has neither checked arithmetic nor a maximum permission value. The
fixture passed `10000`; the build exited green and the host masked it to a
regular file with mode `0000`, making the artifact inaccessible to ordinary
users rather than rejecting the unsupported mode.

Five Whys: lexical validity is treated as semantic validity; parser arithmetic
is unchecked; OS masking is relied on implicitly; accepted mode semantics are
undocumented; and boundary/overflow cases are absent. The repair is checked
accumulation with an explicit supported maximum (normally `07777`, or a narrower
documented policy), validation before any copy/install mutation, and tests for
empty, invalid digit, exact bounds, overflow, and host parity.

## BGO-010 — embedded-runtime fallback has a stale duplicated platform list

Classification: **Source-confirmed masked duplicate-authority defect**  
Severity: **Low**  
Blast radius: embed targets that rely on this module's implicit runtime
placeholders instead of supplying the complete platform set  
Confidence: **Very high**

`build_graph_embed_object_files`, lines 299–341, tracks and emits fallback
symbols for Darwin arm64, Linux x86-64, Windows x86-64, and Windows arm64. It
omits Linux arm64. A custom-only embed fixture emitted those four placeholder
families and no `rt_linux_aarch64_o` symbol.

The current root build is a negative control: `build.w:376-390` independently
lists all five runtime symbols and passes explicit empty inputs, while
`src/compiler/Link.w:28-37` and `:721-730` declare/read all five. `nm` on the current
`out/lib/embedded_objects.o` found start/end symbols for Linux arm64 as well.
Thus the shipped root graph masks this stale fallback today; the duplicate
authority remains a latent regression path.

Five Whys: the platform set is hardcoded in more than one module; the implicit
fallback predates Linux arm64; the root graph compensates explicitly; tests
inspect the root artifact but not a minimal embed target; and no shared enum-to-
symbol table drives producer and consumer. The repair is to remove the implicit
fallback and require a canonical complete input set, or derive all producer and
consumer symbols from one platform authority with an exhaustive test.

## BGO-011 — install-path expansion inherits the shared environment-name leak

Classification: **Debugger-confirmed shared runtime lifetime defect**  
Severity: **High**  
Blast radius: install expansion through `$HOME`, `$INSTALL_BINDIR`, or
`$INSTALL_LIBDIR`, plus the broader set of `with_getenv_str` callers  
Confidence: **Very high**

`build_graph_expand_install_path` and its helpers call
`build_graph_rt_getenv` at lines 548, 562, and 570. The facade forwards directly
to `with_getenv_str` at `BuildGraphRuntime.w:56-57`. During the adjacent graph
audit, the native allocator and an exact-address `lldb` trap pinned this runtime
function's temporary allocation to `rt_core.w:2440-2445`: `str_to_cstr(name)`
allocates through `rt_alloc` and `with_getenv_str` never frees that buffer on
either the present or missing-variable branch.

The debugger stack was captured through `build_graph_emit`, not through an
install invocation; the lifetime conclusion here follows from the same
unconditional callee branch, not from a second claimed stack trace. The broader
filesystem-wrapper C-string lifetime remains reserved for the primary
`rt_core.w` audit.

Five Whys: every lookup allocates a temporary C name; the wrapper does not
release it; the conversion helper returns unmanaged raw storage despite its
call-scoped purpose; callers cannot enforce cleanup hidden inside the wrapper;
and ordinary build tests do not run trace/install lookups under the leak
detector. The repair belongs in `with_getenv_str`: call libc, release the name
buffer on one shared path, then interpret the returned value. All call-scoped
`str_to_cstr` uses need the same ownership audit.

## Working behavior retained

- Required entry/output/input fields are diagnosed for each ordinary target.
- C and LLVM-IR object operations propagate their backend return code; the root
  graph declares ordinary targets using these operation families.
- Archive creation rejects duplicate member basenames before removing the old
  output.
- Embed symbol names reject empty, digit-leading, and non-identifier spellings.
- Manifest relative paths reject empty, absolute, traversal-bearing, NUL,
  newline, carriage-return, and tab spellings through the shared support helper.
- Command and corpus execution propagate nonzero and timeout return codes from
  the runtime call they actually make and retain stdout/stderr paths in their
  diagnostics.
- Install writes through a sibling temporary and rename, cleaning the temporary
  on write, chmod, and rename failures. BGO-006 identifies that archive creation
  does not yet preserve this stronger pattern.
- Unknown/removed kinds and output containment are handled by the surrounding
  materialization/dispatch pipeline; the defects above are all inside paths
  that pass those outer checks.

## Test-coverage audit and required regression matrix

Exact graph and Tilth searches found no production unit importing
`BuildGraphOps` or directly asserting its diagnostics. The behavior suite's
`binary_compare` use checks the public value constructor, not execution. The
root build supplies broad happy-path integration coverage but lacks the
negative cases retained here.

Production coverage should add:

- clean: `.`, `./`, repeated separators, nested dot segments, symlinks, absolute
  and platform paths, root aliases, multiple args with a late invalid item, and
  proof of zero mutation on every rejection;
- reads/comparison/copy: empty files, directories, permissions, disappearing
  files, short/partial reads, devices, and fixpoint failure-closed behavior;
- process targets: every timeout boundary, cwd success/failure, empty and
  inherited environments, duplicate keys, primary/extra output combinations,
  and parity among action/command/corpus paths;
- response arguments: all control bytes, quotes, backslashes, Unicode, empty and
  maximum-size values, with preflight-before-write assertions;
- copy/promotion/archive: first/middle/last validation and I/O failures, existing
  destinations, rollback/atomic replacement, duplicate manifest paths, and
  exact post-failure filesystem state;
- assembly: zero/one/multiple args, empty/unknown/supported triples, target
  mismatch, every supported host/cross pair, and no output on rejection;
- install: all variable presence states, destination containment, file kinds,
  mode bounds/overflow, temp collisions, chmod/rename failures, and old-output
  preservation; and
- embedding: every platform symbol exactly once, custom-only inputs, missing and
  duplicate symbols, section format for ELF/Mach-O/COFF, and producer/Link
  agreement.

The upstream tracker was searched for the exact clean-root, directory
copy/compare, command-field, missing-extra-output, response-NUL, assembly-triple,
manifest partial-write, archive preservation, install-HOME, octal-mode, and
Linux-arm64 placeholder defects. No exact report was found. Open #680 is related
to graph scheduling/single-writer guarantees, but it does not report these
operation semantics. No issue was filed during the report-only audit
itself; BGO-002 was subsequently filed as upstream #953.

## Completion statement

The primary agent examined all 632 source lines, every standard operation and
its production dispatcher, the public target fields/constructors, filesystem
and process runtime facades, archive helper, platform-symbol producers and
consumers, root build integration, and existing test references. Confined
`-O1` fixtures pinned every executed finding to its exact acceptance, mutation,
fallback, or omission branch; the platform-list issue is explicitly identified
as masked rather than presented as a current root-artifact failure; and the
shared environment leak states exactly which stack was observed. This evidence
supports marking `src/BuildGraphOps.w` complete while retaining BGO-001 through
BGO-011 for prioritization.
