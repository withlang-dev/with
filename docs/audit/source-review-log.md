# Read-only source review log (post-`450733e5`)

Running notes for the systematic module pass. Read-only: no builds,
probes, or test runs. Nothing here marks a module complete — completion
still requires the checklist's executable evidence. Notes are queued
residuals and observations for target work, in checklist order.

Convention: `Module (lines read/total) — notes`. `OK` = no residual noted
at this depth. Line numbers are the new-revision ones.

## Compiler core

- `src/Compilation.w`, `src/ConanClient.w`, `src/Diag.w` (facades, full):
  OK — pure re-exports with EOF guards.
- `src/ComptimeEval.w` (361-530, 607-830, gate call sites targeted;
  7992-line module mostly unsurveyed): tar/path-safety core reads
  carefully layered — normalize-then-gate, separator-boundary
  containment, fail-closed octal/size parsing. Sharp candidate note
  (target 17, Windows-only): `comptime_tool_path_is_project_relative`
  (:442-453) rejects `/`-absolute, `..`, and controls but NOT
  drive-letter (`C:/…`, `C:\…`) or backslash-absolute (`\…`) spellings,
  and tar extraction gates on exactly this predicate
  (`archive_name_safe` :793-796, enforced :5225, :5361). A malicious
  archive entry with a drive-absolute name passes the gate; whether the
  writer then escapes depends on join semantics — confirm on the Windows
  path when execution resumes. Sharp contrast: the SIBLING gate for
  symlink targets (`tool_tar_link_target_safe`, `lib/std/build.w:1084`)
  rejects leading `/`, `\`, AND drive letters — the member-name gate
  (`tool_path_is_project_relative`, `:662-673`) lacks all but `/`.
  Neutralization hypothesis (unproven): `output_dir + "/" + name` joins
  may render `C:`-mid-path illegal (loud fail) and `\evil` contained —
  verify against Windows path semantics, don't assume. Same hole shape
  in both tar implementations (ToolFs + comptime twin). Lesser: bare `.`
  passes the gate; string budget env override has no upper bound
  (:361-368, by design).
- `src/ComptimeTransform.w` (25-230 clone + call sites + 2990-3020
  targeted; 3225-line module mostly unsurveyed): `astpool_clone_deep`
  routes every copied table through the same maintaining methods as
  original construction (maps/sets rebuilt consistently — verified for
  fn_meta, where_meta, must_use/no-await/no-alloc/iter/sealed/extend/
  comptime/const/allocator/closure families, effect pins, param
  defaults, membership) — EXCEPT the per-node `files` column
  (`Ast.w:472-477, :683`): cloned nodes are stamped file 0 via
  `add_node`, dropping true file identity. Fully bounded read-only:
  `pool.file()` (`Ast.w:707-712`) has ZERO readers outside `Ast.w`,
  so the gap is latent today — but the first consumer of the column
  misattributes every transformed multi-file node. Fix is one line
  (copy the column in the clone); record as a must-fix-before-adoption
  (target 8).
- `src/ComptimeValue.w` (1-482, full): refcounted immutable-text
  sharing with consuming destructor (Higher RAII); clone deep-copies
  with a fresh counter, share bumps, drop frees-at-zero else blanks —
  coherent, with the 64 GiB rationale documented. Residuals: (a) the
  counter is a plain i64 — sound iff comptime eval never crosses
  concurrent fibers (target 14/15 assumption to verify); (b) `truthy`
  is three-valued (-1) — callers must handle; (c) STR/BYTES equality
  clones to compare (perf micro-note).
- `src/Mir.w` (1324-1388 printer + kind inventory; 3674-line module
  mostly unsurveyed): `mir_rvalue_text` renders unknown kinds LOUD
  (`rvalue<k>`, :1371) — the asymmetry anchor for the validator
  residual.
- `src/MirSuspendCheck.w` (`suspend_gen_rvalue` :124-164 + structure;
  874-line module mostly unsurveyed): the rvalue layout now has THREE
  spellings (printer / validator decoder / suspend gen). Sharp candidate
  (target 4, needs execution-phase confirmation): `suspend_gen_rvalue`
  has NO `RK_SLICE` arm — a slice's place + index operands generate no
  liveness, so a slice live across a suspend point may read as dead.
  Related inconsistency: suspend gen treats borrow-creation as a use
  (REF/ADDR_OF mark the place, :142-147) while the use-after-kill
  decoder counts zero reads for the same — one of the two philosophies
  is wrong for borrows; reconcile explicitly.
- `src/ReceiverMigration.w` (1-515, full): exemplary migrator
  honesty — lexical scan proposes, compiler facts dispose; duplicate /
  mode-mismatch / unmatched-selection / count-mismatch all fail loud;
  full no-write preflight before the first change; recount after apply;
  report mode returns -1 on skips. Positive pattern reference for
  target 23. Cross-links: (a) the write-rc check (:414-416) is defeated
  by BGR-001 (short writes return 0) — named blast-radius member;
  (b) text scanners (`tparam_names`, `count_args`, `trim`) work on raw
  bytes, not tokens — bracket-in-string and tab-indent skew possible,
  contained by report-first human review; (c) `<embedded-std>/` → `lib/`
  mapping (:122-124) fails safe (mismatch → -1).
- `src/Parse.w` (27 lines, full): thin facade. Note: `parse_source`
  drops the DiagnosticList (returns pool only) — silent parse errors IF
  ever called; zero callers today, so dormant. Same for
  `src/Scaffold.w` (67 lines, full): bootstrap-era tables referencing a
  `bootstrap/src/*.zig` tree that no longer exists, `required_module`
  duplicated verbatim as `canonical_logical_name` (target-24), zero
  callers — dead residue, remove-or-revive question.
- `src/Source.w` (88 lines, full): line mapping with binary search and
  clamping (fail-soft rendering, sound). Notes: (a) `from_file`
  inherits BGO-002 (missing file → empty text, silent); (b) `line_text`
  strips `\n` but not `\r` — CRLF sources show trailing `\r` in
  diagnostics (cosmetic, Windows); (c) `deinit` no-op (same allocator
  question as DiagnosticList).
- `src/Migrate.w` (21 lines, full): honest loud stub (`not yet
  implemented`, exit 1) — the permitted shape for unbuilt tool surface,
  not a silent fallback. OK.
- `src/MirOpt.w` (1-153, full): documented count-only stub, honestly
  labeled, with ZERO consumers outside the module — dormant like
  `BorrowCfg`; real optimization flows through LLVM `wl_optimize`. No
  reporting path reads the counts, so no dishonesty today. Activation
  note: wire-up must not present counts as applied transforms.
- `src/Lexer.w` (73-142, 813-856 read; helper inventory 528-600
  surveyed; body mostly unsurveyed): significant-token tracking for the
  regex/division heuristic, which enumerates regex-allowing predecessors
  explicitly (JS-like shape; standard edge set, no verdict). Positive:
  no integer accumulation anywhere (verified by search) — digit text
  preserved for downstream exact-int handling (BGO-009 contrast:
  overflow decided once, downstream).
- `src/InitTemplates.w` (generated doc blob, skimmed): content is
  generated from `docs/with_for_ai.md` by `tools/gen_init_templates.w`
  with NO freshness gate found (no battery check, unlike `build/abi.w`)
  — refresh rests on human discipline; sync state unverifiable
  read-only. Process note.
- `src/LockFile.w` (facade, full): OK.
- `src/InternPool.w` (1-188, full): arena interning with map-authoritative
  lookup and bounds-checked resolves. Sharp note: `InternPool.init`
  allocates a hardcoded 256 bytes for the state block (:94) instead of
  `sizeof[InternPoolState]()` — the pattern `CiIR` uses everywhere. If
  the state (3 Vecs + arena + 3 HashMaps) ever exceeds 256 bytes, silent
  heap corruption. Verify sizes and switch to `sizeof` when execution
  resumes. Arena pages intentionally never freed (documented); empty
  strings alias without storing (sound).
- `src/Resolve.w` (1196-1290 targeted; 1411-line module mostly
  unsurveyed): `resolve_canonical_module_key` (#592 identity) collapses
  lexically without symlink resolution. Sharp note (target 24, R-8
  related): it anchors relative paths via `getenv("PWD")` (:1236) while
  `FnAbi.codegen_canonical_module_path` anchors via `getcwd()` — env vs
  syscall can disagree (symlinked cd, stale export), so the two module
  identities diverge for the same file. Also: `resolve_normalize_path`
  (:1196-1222) does NOT collapse `..` while the canonical key does — two
  normalizers, different strength, callers must pick right;
  `resolve_find_project_root` still seeks `build.zig` (:1274) —
  stale marker or compat, unconfirmed.
- `src/CCodegen.w` (348-430, 686-740, 1053-1107 targeted; 9613-line
  module mostly unsurveyed): LIVE backend via `Compilation.w:1484`.
  Emission is fail-closed on error (empty source + message, :399-401).
  Sharp residuals (target 23): (a) unresolvable global types silently
  fall back to `i32` (`global_decl_tid`, :1080-1082, :1093-1095) —
  wrong-type C that compiles; (b) `cc_sanitize_ident` (:686-703) maps
  distinct symbols to one C ident (`a.b` and `a_b` → `a_b`) with no
  disambiguation visible — silent duplicate/wrong linkage;
  (c) interrupt mid-sanitize returns the plausible name
  `"__with_interrupted"` (:691-692) instead of failing.
- `src/Lsp.w` (33-130, 242-260, 634-680 targeted; 2078-line module
  mostly unsurveyed): hand-rolled jsmn JSON + LSP framing. Notes:
  (a) `uri_to_path` (:634-638) does NO percent-decoding — files with
  spaces/unicode break definition lookup (minor, real); (b)
  `lsp_parse_int` (:51-61) accumulates unchecked — overflow wraps to
  empty/short reads, bounded impact in the local-editor trust domain
  (pattern-file instance); (c) token alloc bounded by `num_tokens`
  (:85-86), header loop uncapped (same trust domain).
- `src/Parser.w` (3887-3935 escape front-door + structure; 8215-line
  module mostly unsurveyed): #929 enforced at the one front door with
  the three-decoder agreement documented — the right shape; error
  recovery continues after emit (standard). `regex_literal_close_slash`
  skips escaped chars without OOB (loop-guarded). Full grammar review
  deferred.
- `src/SemaDiag.w` (structure + emit family surveyed; 1435-line module
  mostly unsurveyed): D22 join-arm/kind namers plus `emit_error` with
  `__FILE__`/`__LINE__`/`__FN__` provenance defaults — diagnostic
  origin by construction (target-10 positive).
- `src/SemaDecl.w` (541-650 overlay + tier records, 1746-1780 hash;
  3054-line module mostly unsurveyed): curated libc overlay lists are
  incomplete by nature but fail closed ("No evidence -> raw", :611)
  with the `retains:` annotation as the modeled escape hatch — the
  right default direction. Notes: (a) `$ext$` symbols use a 31-bit path
  hash (:1746-1750) — collision needs same-method + colliding files,
  unrealistic but identity-grade hashing would remove the class;
  (b) decl source/file fallbacks (current path / file 0, :1753-1767)
  are consistent with the file-0-unknown convention.
- `src/compiler/CodegenUnits.w` (148-255 emit path + structure;
  assign/global-ownership unsurveyed): join-oldest window, spawn
  failure degrades inline, job+join rcs both captured, bitcode cleanup
  after capture. Pointer-into-Vec is safe here (push phase completes
  before spawn phase — no reallocation under workers). OK at this
  depth.
- `src/compiler/ConanClient.w` (23-80 helpers, 889-967 + 1060-1100
  install paths; 1158-line module partly unsurveyed): two-tier
  integrity. LOCKED restore (:889-923) is exemplary — pinned hash
  verified (:908-912), cleanup on every failure. Unlocked binary
  install (:925-967) and source fallback (:1060+) download + extract
  with NO hash gate visible; `name`/`version` flow into dep-dir paths
  from local config AND remote conaninfo requirements (:945-946) —
  traversal via malicious metadata unexamined; tar-slip containment of
  system-tar extraction unverified (no `--anchored`/member scan
  found). Queued for target-19 deep work with exact lines; not a
  verdict.
- `src/compiler/Backend.w` (1-296, full): take-and-return ownership
  discipline with the #726 postmortem inline; post-emit EXISTENCE checks
  (:95-97, :177-179) defend against the missing-artifact class but NOT
  BGR-001 truncation (file exists, short) — extend to size/content
  where known, or fix #951 at the root; same blindness on unit-bitcode
  writes (:160-163). Multi-unit main-pinning (:114-124) and per-round
  sema take-and-return read correctly. Analysis audits wired on the
  production analysis path (:253-256).
- `src/compiler/CodegenUnitsPolicy.w` (1-46, full): pure policy with
  measured calibration constants and an internals test; guards
  (unit_count<=1, budget<=0, per_unit<=0) all fail toward
  serial/safe. OK.
- `src/compiler/ClangBridge.w` (496-604 targeted; 4129-line module
  mostly unsurveyed): bridge-local `make_str` COPIES (alloc+memcpy),
  so dispose-after-make is safe — the double-free postmortem in the
  comments explains why session tracking was removed from this path.
  Pattern note (target 15/23), refined read-only: the With allocator
  NEVER returns null — every failure path calls `rt_exit(99)`
  (`rt_core.w:1165-1167, :1178-1180, :1199-1201`). Silent-empty
  degradation lives ONLY on libc-malloc paths (`session_strdup` /
  `c_strdup` via `libc_malloc`, :502-504 — null possible, degrades to
  `""`). So: With-allocated OOM is loud (exit 99); libc-allocated OOM
  degrades silent-empty. `buf_append_*` truncates silently (diagnostic
  text only — bounded impact).
- `src/compiler/Compilation.w` (501-585 loader + 395-416 setters;
  1950-line module mostly unsurveyed): bundle loading is fail-closed at
  every step (existence, manifest, prefixes, interface pairing) with
  honest "missing or empty" labeling that names the BGO-002 ambiguity
  instead of hiding it — exemplary messaging. Once-flag resets on
  option mutation (:403-405), closing the earlier residual. Sharp
  residual (target 18): when THIS compiler is unstamped, the ABI
  agreement check is skipped (:520) — either refuse bundles unstamped
  or prove stage1 never links them; silent mixed-ABI is exactly what
  #761 forbids.
- `src/compiler/EmbeddedRuntime.w` + `EmbeddedStdlib.w` (full, tiny):
  thin resolvers over generated Data modules. Same sentinel shape
  (`source.len()==0` = missing) — an empty embedded module falls
  through to the next source; consistent direction, noted.
- `src/compiler/EmbeddedClangResource.w` (1-87, full): versioned cache
  with stamp-LAST ordering for concurrent readers — careful. Rc values
  ignored throughout (BGR-001 echo; short stamp write re-materializes
  = fail-safe; short header write corrupts clang input = loud
  downstream). Identity file uses non-crypto `with_str_hash` (weakest
  hash note; diagnostic stakes). Shared `/tmp/with-cache` fallback
  across users — target-19 micro-question.
- `src/compiler/LockFile.w` (208-310 load/write + structure; helpers
  surveyed): line-shape JSON parsing is fragile (one key per line,
  first-match-wins) but failures land loud — dropped sha256 forces a
  hash mismatch at restore, dropped version breaks URLs loudly. The
  consumption-side hash check is what makes upstream sloppiness
  survivable (defense-in-depth positive). Duplicate entry names: first
  wins silently (:259-262, minor).
- `src/compiler/Runtime.w` (full) + `Compilation/Config.w` (full):
  thin typed-wrapper boundary (the extern-centralization pattern) and
  fail-safe config normalization. `opt_level` default 0 never survives
  — always configured from options before use (`Compilation.w:384-391`;
  -O1 invariant holds by driver discipline). OK.
- `src/compiler/TrackedInputs.w` (83-181 gate + call sites; 181-line
  module mostly read): normalize-then-contain with #585/#801 notes and
  honest errors; recorded reads feed input provenance (target-18
  positive). Sharp bounded residual (target 17/19): with an EMPTY root,
  the containment clause is skipped (`:176`) and only `..` is rejected
  — absolute embeds pass. Setter runs at all three Sema-creation sites,
  so the hole needs `zcu.tracked_input_root()` itself empty to open:
  `Zcu.w:380-383` falls back project-root → source_dir → `""`, so a
  rootless invocation opens it — prove non-empty on embed-capable paths
  or gate it. Third `getenv("PWD")`-vs-syscall instance (:173) in
  anchoring. Seed-miscompile workaround documented inline (#629,
  harmless).
- `src/compiler/Frontend.w` (1660-1764 pipeline + structure; 2513-line
  module mostly unsurveyed): phase discipline is exemplary — pre/post
  sema state cloned (never shared) with double-free rationale inline
  (PR#713), intern-pool handoff documented, transform errors return an
  EMPTY pool (fail-closed), snapshot-only-final-pool, freeze after
  construction. Context for the clone gap: the transformed pool here is
  per-module (single-file), so file-0 stamping misattributes to
  unknown-file rather than cross-file — still latent (zero readers).
  Gate question: `has_comptime_nodes() or has_type_derives()` skips the
  transform — an uncounted comptime-node kind would sail through
  untransformed (target 12 note).
## Build system

- `build/seed.w` (1-320, full): supply-chain front door, exemplary —
  SHA-256 sidecar REQUIRED (missing/invalid → fail, mismatch → delete +
  fail); tags resolved explicitly (no latest-redirect trust); JSON
  fragility fails closed with actionable errors; rename-into-place +
  marker verification. Residual (target 19, minor): integrity verified
  at download only — a later-corrupted `src/main`/SDK passes the marker
  short-circuit (`:213-216`, `:262-264`) silently; re-hash on use or
  document trust-once. Tar-slip containment rests on `fs.extract_tar`
  (same open question as ConanClient).
## Standard library core

- `lib/std/alloc.w` (1-373, full): Arena/FrameArena/TempArena/Pool with
  mark/reset/drop pairing verified coherent; Arena/FrameArena alloc
  paths mirror each other (target-24 sync note); Pool double-free is
  the standard unguarded caveat. Sharp latent candidate (target 15):
  `arena_vec_push` (`:362-368`) byte-copies an owned `T` via
  `mem_copy`, then the local `value` drops — the EXACT Box double-drop
  shape (`box.w` documents the fix as move-assign). For owning `T`
  this dangles; grow (`:349-360`) additionally leaks inner buffers of
  abandoned slots. Fully bounded: ZERO callers exist anywhere, so
  dormant — must-fix-before-adoption (move-assign like `Box.new`),
  same category as the clone files-column gap.
- `lib/std/collections.w` (lines 59-290 BTree + structure; Vec/SlotMap/
  Atomic/IntoIter unsurveyed, 2362 lines total): `BTreeMap` implements
  D22 exactly — `get(&K) -> Option[&V]`, `remove(K) -> Option[V]`,
  `contains(&K)`, Ord-only equality (correct for sorted maps), D27
  clones documented at every owned-materialization site. Insert-reorder
  is O(n) rebuild (perf note; sorted-Vec design). `HashMap` surface is
  compiler-builtin (CodegenDispatch side — verify there).
- BGO reruns at current rev (2026-09-03, stage1 built Sep-3 15:08 from
  450733e5, all with `-O1`): ALL REPRODUCED.
  BGO-001: `run build_graph_ops_clean_root.w` → rc=1 reported, marker
  gone. BGO-002: `:compare-directories` green on differing dirs;
  `:copy-directory` green + zero-byte regular file. BGO-003: 1ms timeout
  ignored (sleep 0.2 completed, green); `:cwd-command` captured project
  root; sentinel count 0, green; `:missing-extra` green with
  `out/never-created` absent. BGO-004: `out/nul.rsp` byte-identical to
  evidence (`22 62...00...22 0a`). BGO-005: after resetting both dst to
  `original`, both targets rc=1 AND both dst == `replacement`.
  BGO-006: sentinel archive + loud failure → output absent. BGO-007:
  both green, both host x86-64 ELF relocatables. BGO-008 (HOME removed):
  green + literal `./$HOME/audit-installed`. BGO-009: green + mode 0000.
  BGO-010: stands by source identity (module byte-identical per catchup
  review; masked-duplicate nature unchanged).
- Filed 2026-09-03 (dupe-searched, no matches): BGO-001→#964,
  BGO-003→#965, BGO-004→#966, BGO-005→#967, BGO-006→#968, BGO-007→#969,
  BGO-008→#970, BGO-009→#971, BGO-010→#972, BGO-011→#973,
  THREAD-001→#974, MEM-001→#975, NARROW-001→#976, CIMPORT-001→#977,
  SYNC-001→#978, JSON-001→#979, REGEX-001→#980, TASK-001→#981,
  CCGEN-001→#982, CCGEN-002→#983, CCGEN-003→#984, SYS-001→#985,
  ASYNC-001→#986, FFI-DOC-001→#987, TRAIT-001→#988. (Prior: BGR-001→#951,
  fs-leak→#952, BGO-002→#953, VALID-001→#989, CCGEN-004→#990,
  CHAN-001→#991, MONO-001→#992, IMPORT-001→#993, MATCH-001→#994.)
- Target-22 (spec mapping) SPOT CHECKS: no spec-section-indexed test
  map exists (manifests map scripts→evidence, not spec→tests).
  FINDING MATCH-001 (candidate, medium → #994): expression-position
  match over integers with no `_` passes check AND silently yields the
  zero value at runtime ('' for str, rc=0) — spec demands
  exhaustiveness; enum/bool subjects correctly error (missing variant
  named; bool case diagnosed). Gap is precisely infinite domains +
  silent zero-fabrication (worse than the missing check). Probes
  `matchx{,2,3}_probe.w` (54 probe files).
- Target-10 (name resolution): local shadowing rejected loudly;
  use-before-decl → 'undefined variable'; duplicate explicit imports
  silently last-wins (probe prints 2). FINDING IMPORT-001 (candidate,
  low-medium → #993): spec §18.2 mandates ambiguity errors for the
  fallback tier but is silent on explicit-import collisions — strictness
  inverted across tiers; reordering `use` lines silently rebinds.
  Probes `scope{,2}_probe.w` + `docs/audit/probes/import_ambig/`
  (43 probe files).
- Target-14 (optimization robustness) VERIFIED by execution:
  `--validate-all` ok; O0/O1/O2/O3 outputs BYTE-IDENTICAL
  (md5 match; 6/6765/13) across Vec[str] iteration, recursion,
  HashMap lookup. Probe `optdiff_probe.w` (49 probe files). Positive
  control for the sampled slice.
- Target-15 (allocator/container ownership) SAMPLED by execution: Vec
  1000-push grow integrity exact (sum 999000, len 1000, leak 0 under
  --debug-alloc); SlotMap stale handle → None after remove (generation
  check works, removed value dropped, leak 0) — no UAF path. Probes
  `realloc_probe.w`, `slotmap_probe.w` (51 probe files). Positive
  control (arenas/Rc/Box covered in std pass).
- Target-11 (closures) PARTIAL: escaping closure capturing borrows
  REJECTED loudly at return position ('escaping closure cannot capture
  ephemeral references', probe `closesc_probe.w`) — but the identical
  shape passes as a `spawn_os` argument (contrast added to #974 as a
  comment; escape analysis covers returns, not params). Non-escaping
  captures + indirect dispatch verified earlier (T2). Remaining:
  FnMut-style mutation discipline internals.
- Target-8 (type identity): aliases transparent (Meters/Seconds mix
  freely — consistent with transparent-alias design); duplicate TYPES
  silently last-wins (second `Dup{w}` hides first; constructing `v`
  fails 'unknown field') while duplicate FUNCTIONS are rejected
  ('already defined') — same defect class as #993, evidence added
  there as a comment with the fn diagnostic as repair template.
  Probes `alias_probe.w`, `duptype{,2}_probe.w`, `dupfn_probe.w`
  (49 probe files).
- Target-19 (platform agreement) SAMPLED by execution: `repr(C)`
  `{u8,i64,u16,i32}` → sizeof 24 / align 8 / usize 8 / isize 8,
  IDENTICAL to `cc` ground truth on x86_64 Linux (probe
  `layout_probe.w` + /tmp/layout.c; field offsets forced equal by
  size+align+order: C prints b@8 d@20, only layout consistent with
  With's 24/8 is the same). No offsetof builtin exists (minor surface
  note). Positive control for LP64; LLP64 covered by CIMPORT-001.
- Target-9 (generics): multi-instantiation correct (`ident(10)`,
  `ident("a")`); FINDING MONO-001 (candidate issue, VERIFIED by
  execution → #992): self-instantiating generic (`rec[T]` calling
  `rec(x)`) SIGSEGVs stage1 at check — gdb shows unbounded
  `check_generic_call → check_fn_body_concrete → …` cycle with no depth
  guard (auto-deref/trait paths have them). Non-generic self-recursion
  checks `ok` (control). Probes `genrec_probe.w` (crash),
  `rec_probe.w` (control), `generics_probe.w` (40 probe files).
- Target-16 (fiber/channel runtime): channel destroy path disciplined
  (`channel_drop_queued` runs drop_fn over live slots, refcounted
  endpoint release); memcpy transport sound given language-level move
  semantics. FINDING CHAN-001 (candidate issue, High, VERIFIED by
  execution → #991): queue counters/indices are plain non-atomic i32,
  zero sync in `rt/channel_runtime.w`; spec-sanctioned multi-worker
  stealing loses messages (199990000 → 167M/165M/178M across 3 runs;
  single-worker control exact twice). Latent UAF in grow path +
  refcount races noted in the issue. Reproducer
  `docs/audit/probes/chan_race_w4/` (main.w + with.toml.w1/w4 + README).
  Move semantics block casual cross-thread handle sharing (second
  capture → 'use of moved value'), so the fiber-stealing path is the
  live one. Note: `Sender`/`Receiver` are move-only RAII (Drop releases
  endpoint); no Clone — single-producer-per-handle by construction.
- R-flag resolutions (Sema-side, VERIFIED by execution):
  TRAIT-001 → DOWNGRADED to candidate-low/note: `select_trait_impl`
  (`SemaCheck.w:16899`) is name-level only — a wrong-arity impl method
  is ACCEPTED at the impl site (probe `trait_probe.w`: error surfaces
  only at the call, against the impl's own signature). So trait decls
  are fail-LATE (use-site), never fail-silent; concrete-impl dispatch
  governs, which is also why `impl Eq for str`'s `&str` param works
  despite the trait's by-value `Self`. The companion fear is DISPROVEN:
  by-value `other: Self` does NOT consume at method call sites even for
  Drop types (probes `trait_probe2/3.w` pass `check` with post-call
  use). Remaining gap is typo'd-impls-satisfy-bounds until
  instantiation — cosmetic-to-low.
  MEM-001 → UPGRADED to FINDING (candidate issue, High, VERIFIED):
  `mem_set`/`mem_copy`/`mem_move` are safe `pub fn`; probe `mem_probe.w`
  zeroes a stack local through `&x as *i8` + `mem_set` with NO `unsafe`
  anywhere, `check` passes. Address-of and pointer casts are safe per
  the primer; dereference requires `unsafe` per spec — these fns are
  dereference-by-proxy marked safe, i.e. safe arbitrary memory write.
  Fix is one word per fn (`unsafe fn`) plus `unsafe` at stdlib internal
  callers. Probes: `docs/audit/probes/readonly_pass_20260903/mem_probe.w`,
  `trait_probe{,2,3}.w`.
- `lib/std/box.w` (full, 43 lines): move-assign (not memcpy) with the
  double-drop postmortem inline; into_inner/drop pairing correct
  (transfer vs destroy). OK.
- `lib/std/sync.w` (full, 443 lines): spinlock Mutex/RwLock with
  fiber-aware yield, semaphore-style Condvar immune to classic
  lost-wakeup, panic-resetting Once (matches spec §7798), correct
  drop-old-then-move-in set/write paths, balanced guard Drop on
  owners. No writer-preference (reader starvation possible — perf
  caveat only). FINDING SYNC-001 (candidate issue, liveness/fail-stop,
  not memory unsafety): the four guard types (`MutexGuard`,
  `MutexGuardMut`, `RwReadGuard`, `RwWriteGuard`) have NO `Drop` impl —
  a forgotten `exit()`, or a panic while a guard is live, leaves the
  spinlock locked forever (deadlock; hard-spin on threads without
  fibers). The header doc claims "a panic while a guard is held
  releases the guard through normal cleanup and does not permanently
  poison the lock" — but cleanup drops the guard *value* without
  unlocking; the described mechanism does not release the lock. No
  must-consume rule for ephemeral guards exists (only Task has
  consume checks). At minimum the doc claim is false; at worst the
  panic path deadlocks.
- `lib/std/mem.w` (full, 51 lines): thin wrappers over `with_alloc` /
  memcpy / memset / memcmp externs. RESOLVED — see MEM-001 resolution
  note above (UPGRADED to verified High finding; `mem_probe.w`).
- `lib/std/rc.w` (full, 103 lines): move-assign (not memcpy) construction
  with the Box double-drop postmortem inline; Rc non-atomic vs Arc
  atomic counts correctly distinguished; last-drop frees value then
  control (right order). Structurally SOUND on threads: both hold
  `*mut u8`, and `type_satisfies_thread_trait` denies all thread traits
  to TY_PTR (`SemaCheck.w:17275-17276`), so Rc can never cross threads —
  fail-closed. Usability gap (not soundness): NO `Send`/`Sync` impl
  exists for `Arc` anywhere, so `Arc` cannot be shared across threads
  either and its atomic count is currently pointless-but-harmless.
- `lib/std/thread.w` (full, 37 lines): `spawn_os` transmutes
  `fn() -> i32` to fn_ptr+ctx and hands both to the runtime unchecked.
  FINDING THREAD-001 (candidate issue, High, VERIFIED by execution —
  R-flag resolved): a capturing closure CAN coerce (spec §16.6: plain
  `fn` values "may carry closure context"; probe `closure_probe.w`
  passes `check` with a mutating capture) and the runtime REALLY spawns
  an OS thread on it (`rt_core.w:1295-1313` `rt_thread_entry` invokes
  `worker(ctx)`). `s.spawn` enforces ScopedSend per capture plus
  mutate-before-join errors (`SemaCheck.w:22438-22460`); `spawn_os`
  enforces NOTHING. Sendable today in safe code: `Rc` (non-atomic count
  → count race → UAF/double-free), `&T` borrows (use-after-scope),
  `var` captures mutated both sides (data race). The no-pin rationale
  in the comment ("`fn() -> i32` is Copy, so an escape_value pin has no
  ownership consequence", :25-30) confuses handle-Copy with
  pointee-Send — the fat pointer is Copy AND points at shared context.
  Fix shapes: `unsafe fn`, or a ScopedSend bound on the closure
  context, or removal in favor of `s.spawn`. Probe:
  `docs/audit/probes/readonly_pass_20260903/closure_probe.w`.
- FINDING NARROW-001 (VERIFIED by execution, spec violation §4.2.6):
  implicit integer narrowing is silently accepted at ALL call-argument
  positions — free-fn args (`take32(big)`, `mem_set(p, 0, big)` pass
  `with check`) and struct-method args (`w.get(big)` passes) — while
  let-bindings correctly error ("implicit integer narrowing or sign
  change; use an explicit `as` cast"). The checker
  (`int_narrowing_requires_cast`, `SemaCheck.w:9072`) is wired to
  let-bindings (:9307), struct-literal fields (:12038), and only
  int/float-receiver method args (:20109) — free-fn and general method
  call args have no call site. In-tree witness: `alloc.w:144,358,367`
  pass i64 byte counts to i32 `n` params. Impact is bounded today
  (allocator sizes are i32 throughout, so >2GB is unrepresentable
  anyway), but any user `fn` taking `i32` silently truncates `i64` args
  — the exact C-inherited bug class §4.2.6 ("No other implicit numeric
  conversion is allowed") exists to catch. Probes in /tmp
  (docs/audit/probes/readonly_pass_20260903/narrow_probe{,2,3}.w).
- `lib/std/alloc.w` (full, 373 lines): Arena/FrameArena/TempArena/Pool
  all own their blocks with balanced Drop impls; ArenaScope and
  PoolAllocator drops carry explicit no-double-free reasoning inline.
  `reset_to` mark encoding validated on decode (:179). Previously
  logged arena_vec_* double-drop/grow-leak shape stands (zero callers
  per prior verification).
- `lib/std/string.w` (full, 238 lines): interior-NUL rejected loudly in
  `to_cstring` (§16.3c-conformant); explicit `as i32` in `parse`;
  byte-wise `string_cmp` correct. Notes (not findings): `as_cstr`
  reinterprets `&CString` as `&CStr` on a shared-layout assumption
  (documented inline — fragile if layouts diverge); `lines()` builds
  `Vec` via struct literal (native field-order dependency, same
  category as the clone files-column gap, compiler-owned layout).
- `lib/std/task.w` (full, 233 lines): await_all/await_first/await_any/
  await_settled all carry defer-based `join_cleanup` for un-awaited
  tasks on early return — disciplined; empty-input `await_first` is
  loud (`todo()`). FINDING TASK-001 (candidate issue):
  `with_concurrency(tasks, n)` is documented "Limit concurrent
  execution to at most `n` tasks at a time" but the body is
  `let _ = n; tasks` — the limit is silently ignored with no
  `todo()`/diagnostic. Same file is loud everywhere else, so this one
  silent no-op is exactly the mishandle-10%-silently shape: callers
  bounding resource use get unbounded execution. Fix is one line
  (`todo()`) or the real limiter.
- `lib/std/os.w` (full, 88 lines), `fs.w` (66), `io.w` (74),
  `process.w` (86): thin documented wrappers; `read_file`/`env`
  empty-on-failure documented inline (design choice, not silent).
  `argv_blob` NUL-joins (prior fix stands); `Stdin.lines` remove(0)
  loop is O(n^2) (perf note); `Vec{...}` literal pattern recurs
  (compiler-owned layout, same noted category).
- `lib/std/sys.w` (full, 106 lines): bandwidth probe with asm
  optimization barrier is careful work; defaults sane. FINDING SYS-001
  (candidate, low): `_ensure_init` lazy-initializes five `var` globals
  with a plain bool flag — no synchronization. First-concurrent-call
  from two OS threads races (writes are idempotent so benign in
  practice, but a race under "exactly as safe as Rust"). std already
  has panic-resetting `Once`; use it.
- `lib/std/ffi.w` (full, 70 lines): box/unbox/drop_ctx pairing is
  exactly-once (read-then-free in both consumers); per-type
  trampoline note correctly refuses a generic destroy shim (wrong-ABI
  risk refused loudly). FINDING FFI-DOC-001 (minor, docs — VERIFIED by
  execution): the module comment (:32-36) claims boxing an ephemeral
  "is not yet rejected at compile time ... the same gap as Box.new"
  — but all three paths now reject loudly (`Box.new(h)`,
  `box_ctx(h)`, even `Vec[&i32]` formation itself). The gap is closed;
  the comment is stale and should describe the §5.1 guard instead.
  Probes preserved at docs/audit/probes/readonly_pass_20260903/box_{escape,ctx,vec}_probe.w.
- `lib/std/regex.w` (full, 541 lines): find_all/captures_all/split/
  replace_impl/replace_all_fn use local cursors (correct for literal AND
  compiled); replace/replace_all go native with the is_global flag.
  `Captures.get` bounds-checks spans. FINDING REGEX-001 (candidate
  issue, source-proven): `captures_match_op` — the `=~` operator path —
  advances /g state ONLY through `global_pos/subject_ptr/subject_len`,
  which are wired solely for literals (`CodegenDispatch.w:381-383,
  415-417` build per-literal LLVM globals). `Regex.compile_flags(pat,
  "g")` values get nulls (`regex.w:146-148`) and hit the silent
  first-match-only fallback (:215-216). Consequence: `while x =~
  compiled_g` never advances (infinite loop on match); `if` is
  indistinguishable from correct. Fix shapes: allocate per-value state
  in compile_flags, or diagnose /g-on-compiled at the `=~` site.
  ENVIRONMENTAL CAVEAT (battery owns the verdict): under BOTH the
  installed seed (Aug 27) and stage1 built Sep 3 from current source,
  `with run` matches NOTHING — not just /g: the in-tree
  `behav_regex_language_semantics.w` fails at :20 (`count == 2`) and
  minimal literal probes (`/([a-z])(\\d)/.is_match("a1 b2")`) fail too —
  while docs record this test PASSING Aug 31 via the `:test` path after
  rebuilding regex-runtime-object. So the `run` path and the `:test`
  path disagree at HEAD: either `run` links a stale embedded
  regex_runtime.o or HEAD regressed matching. Runtime confirmation of
  REGEX-001 is blocked on that; the wiring asymmetry itself is proven
  from source. Probes preserved at docs/audit/probes/readonly_pass_20260903/global_probe*.w. (handoff's "regex /g
  match-count runtime residue" line is plausibly this same residue.)
- `lib/std/json.w` (structure + entry/exit surveyed; jsmn-port body
  skimmed): fixed 256-token cap fails LOUD (`json_panic`, fail-stop —
  fine). FINDING JSON-001 (candidate issue): `JsonDocument`
  (`json.w:30-34`) owns a `with_alloc_zeroed` token buffer but has NO
  `Drop` impl anywhere in the file (zero "Drop" hits) — every
  `JsonDocument.parse` leaks 256 token slots. Under the mission
  ("leaking is a defect"), the fix is a ~5-line Drop freeing `tokens`.
  `JsonView` itself is correctly ephemeral+Copy.
- `lib/std/http.w` (full, 247 lines): fd closed on every path
  (connect-fail / send-fail / read-loop end); #883 raw-write-stale-read
  postmortem inline with the safe byte-copy fix. `https_get` returns ""
  on non-200 — same documented-error-conflation family as
  `fs.read_file`, consistency note only.

## Compiler core (checklist order)

- `src/Analysis.w` (full, 2035 lines): `with analyze` fact surface.
  Fail-loud throughout — lldb recipe refuses to invent breakpoints
  (:1830-1831), unresolved path/closure endpoints reported (:1853,
  :1869, :1888); pool/storage/family mirror audits carry #660/#661/#664
  postmortems and `report.fail` on divergence. Call-path BFS pred-chain
  sound (every queued sym has a pred entry). OK.
- `src/Archive.w` (full, 379 lines): Mach-O/ELF symbol extraction is
  defensively bounds-checked at every read (truncation → break/return,
  never OOB); untrusted `ncmds`/`cmdsize` loops bounded by for-range
  (no infinite loop on cmdsize==0); writer paths eprint + return 1.
  Empty-file vs missing-file conflation still fails loud. OK.
- `src/Ast.w` (layout bible + spot checks): AGENTS.md quoted layouts
  verified exact (LET_DECL/BINDING/IF/FOR/WHILE/MATCH/BLOCK/RETURN/
  STRUCT_LIT; no NK_VAR_DECL). `NK_TYPE_REF.d1` carries an is_mut bit
  but safe `&mut T` is rejected LOUDLY at Sema with a §15.1 diagnostic
  (verified by docs/audit/probes/readonly_pass_20260903/mutref_probe.w; diagnostic emitted twice — cosmetic dup note).
  OK.
- `src/AsyncMir.w` (full, 164 lines) + `src/AsyncLower.w` (full, 424):
  suspend-boundary recorder with #715 aliasing postmortem inline
  (index-into-body, not a bit-copy); yield-outside-generator diagnosed
  loudly; resume_bb=-1 recorded as data, never invented. Coverage
  question (not a finding): walker starts at fn-body node, so `await`
  inside fn-param DEFAULT expressions (if the language allows them)
  would be missed — needs a Sema-side ruling on whether defaults can
  suspend before it matters. RESOLVED — question answered YES by
  execution: `await` in a default-param expression passes `check`
  (probe `default_await_probe.w`), while `AsyncLower.lower_body` walks
  only the fn-body node (:90-92), so the suspend is NEVER recorded.
  FINDING ASYNC-001 (candidate-low): a sync fn can harbor a suspend in
  its defaults, invisible to the suspend artifact that gates runtime
  linkage (`Compilation.w:1146` — a program whose sole suspend hides in
  a default may skip linking the fiber runtime → loud link failure —
  consequence reasoned, not executed) and to `with analyze` suspend
  lists. `MirSuspendCheck` works on MIR bodies so it sees whatever
  MirLower emits; the hole is the AST-walk attribution + flavor gating.
- `src/BorrowCfg.w` (full, 285 lines): honestly-labeled dormant
  scaffolding — ZERO callers, NLL actually lives in
  `SemaCheck.expire_dead_borrows_in_block`; coverage gaps (match/for,
  branch-divergence, back-edges) listed inline. Same
  must-fix-before-adoption category as arena_vec; leaks nothing today.
  OK.
- `src/CCodegen.w` (PARTIAL pass ~5%: terminator/statement emitters,
  fallback discipline, emit-c result plumbing): the dominant pattern is
  exemplary — unknown term/stmt/const/operand/binop kinds all
  `self.fail` + poison, `had_error` discards the source
  (`emit_module:399-400`), and `Compilation.emit_c:1485` eprints and
  stops. Poison `"<unsupported>"` strings never escape (fail set
  first). FINDING CCGEN-001 (candidate issue): `emit_fn_body`
  (:9402-9407) emits EMPTY stub labels for BB indices referenced beyond
  `block_count` — control reaching one falls through into `}`. The
  fail-loud mechanism exists (zero-block fns DO `self.fail`, :9383);
  this path bypasses it. Origin: Eric's Apr-2026 workaround ("switch/
  goto targets exceed emitted BB range", e17d62ce) — the underlying MIR
  inconsistency was never resolved at the source; the stub papers over
  it. Fix shape: `self.fail("terminator references out-of-range BB")`.
  Reachability at HEAD unverified (needs MIR-level proof).
  FINDING CCGEN-002 (candidate issue): `StmtKind.Drop` (:8155-8160) and
  `TK_DROP_AND_GOTO` (:8232-8241) emit `/* drop(p); */` COMMENTS for
  every non-Vec type — the C backend silently skips ALL user destructors
  (files, sockets, mutexes, Boxes) with no diagnostic and no documented
  limitation found (requirements.md calls --emit-c THE C backend for
  bootstrapping new platforms). LLVM-vs-C behavioral divergence, and a
  mission-level leak/defect gap on the C path. FINDING CCGEN-003
  (latent, fold into CCGEN-001 or file separately): switch-default `d2`
  means "no default → abort()" in C (:8170, :8185) but is a plain BB
  index (d2==0 = bb0) in LLVM (`CodegenDispatch.w:15538`); all current
  producers pass nonzero defaults so they agree today, but nothing
  enforces the convention — one default=bb0 lowering silently diverges
  the backends.
- `src/CCodegen.w` string layer (:453-680) VERIFIED: `cc_escape_c_string`
  uses octal (no hex-continuation ambiguity, signed-byte handled);
  `cc_decode_with_string_escapes` compared line-by-line against
  `CodegenDispatch.decode_string_escapes` (:17809) and
  `ComptimeEval.comptime_decode_string_escapes` (:403) — all three agree
  exactly on `\xHH \n \t \r \0 \\ \"` with identical else-fallthrough
  (covers `\' \{ \}` from the allowlist). The #929 front-door claim
  ("the set every decoder accepts") HOLDS; `string_escape_help` renders
  from the same set so the diagnostic can't drift. Positive control.
- Target-1 (validator trustworthiness): rejection logic VERIFIED REAL —
  `validate_mir_body` checks locals-vector skew/return-local presence,
  module level checks duplicate fn_sym bodies + index-map agreement,
  `validate_use_after_kill_body` implements kill-on-zero-fill /
  revive-on-write / linear-reach gating (plus the #927 postmortem proves
  it bites). Coverage is positive-only (`--validate-*` snapshot tests
  on valid programs).
  FINDING VALID-001 (candidate issue, medium-low): negative validator
  coverage is STRUCTURALLY BLOCKED from outside the compiler package —
  `MirBody`/`MirModule` non-pub (`Mir.w:393,490`; contrast `pub type
  InternPool`), `validate_all_mir_module`/`validate_mir_body`/
  `validate_ownership_*` non-pub free fns, and the one pub validator
  takes the non-pub body type. The codebase already solved this exact
  problem (Arena/Ids/InternPool re-homed as `compiler.foundation.*` +
  `test/internals/*_test.w` hostile-input tests, e.g. `arena_id_invalid`
  negative controls); MIR validators never got it. Recommend re-home or
  re-export + hostile-body units (blank-then-read, duplicate bodies,
  locals skew, out-of-range terminator refs — the last also covers
  CCGEN-001's trigger class).
- Target-5 (move/drop): `mir_elaborate_dead_drops` (:2211) is a single
  forward pass; `block_input` joins only lower-numbered preds
  (:1897-1914) — loop back-edges never join, no fixpoint. VERIFIED SOUND
  direction, not a defect: the lattice (`join` :1629, join_into :1638
  with the #729 postmortem) only weakens toward Maybe/MaybeGarbage, and
  elaboration nops ONLY exact-`Moved`; missed facts yield kept drops,
  which are runtime-guarded by reset-on-move sentinels (guard presence
  comes from the lowering-recorded `ever_moved_locals` set, independent
  of this dataflow). Ignoring paths can never invent `Moved`, so the
  failure mode is bounded to missed optimization, never unsound drops —
  modulo sentinel-discipline completeness (separate surface). Drop-audit
  covers loop3 cells (:350) as the execution backstop. Positive control.
- Target-7 (cleanup control flow) VERIFIED by execution + reading:
  `?` fail path runs conversion chain, D17 reset flush, errdefers,
  defers, drops, then return (`MirLower.w:10610-10710`); break runs
  defers but not errdefers (probe → 3, no +100s); goto out of a scope
  runs its defers (probe → +1000); in-tree
  `behav_errdefer_not_run_on_goto.w` asserts the goto/errdefer split.
  Machinery (LoopInfo depth snapshots, scope-stack unwind
  `emit_cleanup_to_target`, full-stack return unwind) matches spec
  §2.4/§13 break/continue/goto/?/return matrix exactly. Panic is
  `_exit(134)` with no landing pads anywhere — no cleanup runs on
  panic; spec never promises it (design question, not a violation),
  but it triply falsifies SYNC-001's doc claim (evidence added to #978
  as a comment). Probe `cleanup_probe.w` (21 probe files). Positive
  control.
- Target-3 (FnAbi authority) VERIFIED by reading: `arg_pass_mode`
  (`Codegen.w:4719`) is the single classifier (Sema share-place verdict
  + platform aggregate rule via `fn_abi_pass_mode`); callee prologue
  (`declare_function_from_sig`) and call sites read it, with #D6/#806
  postmortems at each use site stating the extend-there-never-per-path
  rule. Direct `internal_abi_needs_indirect_param` calls (~10 sites)
  answer ADJACENT questions (closure param shape, sret, marshall temps)
  through the same predicate — not rival classifications; the #806
  closure comment explicitly keeps call sites in agreement. The
  `emit_runtime_panic_value` postmortem (by-value `str` Windows ABI
  divergence → route through `&str`) shows the same bug class caught
  and fixed. Positive control; methods/generics/traits/externs funnel
  through (sig_idx, pi) by construction.
- Target-2/13 (call/return, MIR agreement) PARTIAL — return paths:
  TK_RETURN emission (`CodegenDispatch.w:15457-15524`) covers
  async-rbuf (cancel-guarded store), void, sret (default-filled when
  unassigned), direct-pack, and normal load+`enforce_coerced_type`
  (fail-loud on mismatch, `Codegen.w:1794`). Local 0 ALWAYS gets an
  entry alloca (`:15728-15730`), so the default-value fallbacks are dead
  code — but the alloca is UNINITIALIZED and nothing (validator or pass)
  asserts definite assignment of _0 before TK_RETURN; a MirLower path
  that forgets the store loads garbage. Sema's all-paths-produce-value
  rule makes this unreachable from valid source, but it is an UNCHECKED
  construction invariant and a prime hostile-body unit case for #989
  (dominance of store-to-0 over TK_RETURN). Caller/callee ABI agreement
  via arg_pass_mode already covered under T3. TK_CALL routes through
  `mir_emit_call_term` (mutual-TCO flagged); per-function
  `sroa,mem2reg` + `wl_verify_function` with fail-loud
  (`run_mir_cleanup_passes`) is a strong T13/T14 backstop — malformed IR
  dies at the verifier, not silently. Notes: (a) dispatch missing-body
  paths call `fail_mir_codegen_for_function`, but the two "no
  fn_value/fn_type" eprints inside `gen_function_mir` return WITHOUT
  had_error — failure deferred to link (loud, late; minor);
  (b) ignored-result handling — VERIFIED: discarded owned Vec drops
  with leak count 0 under --debug-alloc; bare captur-less async call
  legally detaches (runs detached, nondeterministic order by design);
  borrowing detach → E0802 hard error with help text (probe); unused
  Task bindings error (source: `check_unused_task_bindings_since`);
  E0801 machinery wired but no `@[must_use]` fn exists in stdlib, so
  that gate is currently user-attribute-only (noted, not a defect).
  Probes `unused_probe.w`, `taskdrop{,2}_probe.w`, `taskdisp_probe.w`.
  (c) indirect calls — VERIFIED by execution: named fn, capturing
  closure, str-taking fn, and inline closure all dispatch correctly
  through `fn()` params incl. 16-byte `str` args (probe
  `indirect_probe.w`; 7/12/hi bob/yo ann). Windows-only shapes rest on
  the T3 classifier + #806 scar tissue. (d) Never-exits — handled at
  SEMA: code after a `-> Never` call is a check-time "unreachable code"
  error (probe `never_probe.w`), so no codegen path exists. T2 CLOSED
  as positive control (30 probe files).
- Target-4 (suspension/cancellation) VERIFIED by execution: unhandled
  Task binding → hard error; select-loser cancellation, nested-unwind
  child cleanup, and live-fiber baseline restoration pass
  (`behav_async_cancel{,_await_cleans_children,_nested_unwind,_noop,_basic}`
  all ok); cancel-nested-unwind under --debug-alloc: leak 0;
  scope-panic runs sibling cleanup THEN propagates with exit 134
  (matches `expect-exit`/`expect-stderr` exactly); double-await is
  sound for both i32 (84) and str (hello|hello, leak 0) — second await
  yields an independent value, no UAF (spec does not pin the
  copy-vs-move semantic; behaviorally sound either way). Probes
  `maysuspend_probe.w` (negative), `dawait{,2}_probe.w` (32 probe
  files). Positive control.
- Target-21 (harness honesty) VERIFIED by reading (`src/main.w`
  :3415-3700 + platform wait decoding): skips REQUIRE reasons;
  malformed gates fail loudly (#795); expected-failures check rc AND
  stderr substring; exit codes compared EXACT (`validate_test_run`);
  signal deaths decode to 128+termsig on all four platform backends
  (never masquerade as 0/134); `known-issue` enforced BOTH directions
  (red tolerated loudly, green fails until directive removed —
  compiletest known-bug model); env directives save/restore. Notes
  (minor): stdout matching is substring (extra output passes;
  `_not` lists bound it); capture-file reads inherit BGO-002's
  missing→"" conflation but fail closed ("" matches nothing). Positive
  control.
- Target-24 (duplicated decisions) SAMPLED — Copy/Drop: single
  computation (`Sema.is_copy`, defaults-to-Copy with explicit str
  carve-out per D28) + frozen twins (`is_copy_frozen`,
  `type_needs_drop_frozen` with loud phase-miss) + joint
  `needs_drop && !is_copy` query pattern consistent across Analysis
  (copy-elem/view/raw-deref-drop tags), MirLower, SemaCheck + DECLARATION
  coherence ("cannot implement Drop because it implements Copy",
  `SemaDecl.w:2274`, probe `copydrop_probe.w` rejects). No rival
  decision site found. Drop emission itself is a structural walk with
  #606/#691/#693/#747 scar tissue (tuple/array elementwise, str
  payload-ownership, enum variant-exclusive). Positive control
  (33 probe files).
- Target-12 (comptime/runtime equivalence) SAMPLED by execution:
  recursive fib identical (55/55); i32 overflow fails loud in BOTH
  phases (runtime panic + comptime error, same class); Vec
  push/len/get identical (32/32). Probes `ctequiv_probe.w`,
  `ctovf{,2}_probe.w`, `ctvec_probe.w` (37 probe files). Positive
  control for the sampled slice (integers, overflow, Vec basics);
  ownership/generics-at-comptime not sampled.
- Target-6 (borrow/view provenance) VERIFIED by execution against the
  D22 matrix: `get().unwrap()` yields a live view; use-after-`clear()`
  rejected with a three-label diagnostic (view site, mutation site,
  later-use site); `?` preserves `&V` through `Option` returns
  (`let r = m.get(k)?; Some(r)`); borrows return across functions;
  NLL expiry permits mutation after last use (`m.clear()` post-use
  passes); returning a local borrow rejected ('returned view may
  outlive its origin'). Probes `borrow_probe{,2,3}.w` (24 probe files).
  Positive control; matrix conformance work itself remains owned by the
  D22 plan lanes.
- `src/CCodegen.w` `place_text` (:2809-2937) + `c_type` (:1852-1948):
  invalid ids fail+poison; str/array/slice index paths match LLVM
  behavior (debug-only bounds checks are SPEC-LICENSED, spec :1811 —
  positive control, not a divergence); Vec goes through panicking
  `with_vec_get_ptr`. Notes (unproven-defensive, likely unreachable):
  `PK_FIELD` pd==0 silently skipped (:2842), `PK_DEREF` on non-ptr/ref
  emits `(*x)` with no fail (:2894-2900), `PK_DOWNCAST` on
  non-payload-enum emits a no-op `/*downcast*/` comment (:2914, an
  lvalue-position silent miscompile IF reachable — LLVM side doesn't
  fail there either, so reachability decides).
  FINDING CCGEN-004 (candidate issue, VERIFIED direction): `c_type`
  maps EVERY fieldless enum to `int32_t` (:1893-1896) regardless of repr
  type, while LLVM uses `{ repr_ty, ... }` (spec :2198-2199). In-tree
  `: u8`/`: u16` enums exist; probes prove LLVM `sizeof[Big:i64]==8`,
  `sizeof[Small:u8]==1`, and 7·10⁹ discriminants accepted
  (`enumrepr{,2}_probe.w`, 19 probe files now). On emit-c: u8/u16 tags
  inflate to 4 bytes (layout/FFI divergence) and wide discriminants
  TRUNCATE (value corruption). Same silent-wrong-type class as the
  `global_decl_tid → i32` residual, but reached from ordinary user
  enums. Final `c_type` fallback `"int64_t"` (:1948, 'Conservative')
  never fails — correction to an earlier suspicion: `dyn` dispatch is
  explicitly LLVM-only BY DESIGN with loud fail+abort (:6102, #301), so
  the fallback's residual risk is other unhandled kinds (e.g. future or
  exotic type kinds), reachability open but bounded by the fail-loud
  neighbors.
- `src/CCodegen.w` continued (checked-int :1961-1990, const/operand
  :2959-3160, call-chain guards :3400-3560/:8084, dyn refusal :6102/:7429,
  module tail :9494-9613, local-decl cascade :9300-9381): checked-int
  and const-kind fallbacks all fail+poison; `.len()>0` guards make ""
  a try-next signal, not silent acceptance; dyn is LLVM-only BY DESIGN
  (loud); tail phases check had_error between stages; prototypes precede
  bodies, thunks precede use. Notes: (a) const-overflow poisons (`"0"`)
  don't set fail — unreachable in practice (Sema rejects `let x: u8 =
  300` loudly, probe `litrng_probe.w`, 20 probe files now);
  (b) hand-written `extern` C decls in the tail must match runtime ABI
  by inspection (e.g. `with_str_clone_ref(const with_str*)`) — drift is
  covered by `:emit-c-smoke`/`:emit-c-test` execution gates, noted not
  re-verified; (c) local-decl inference cascade (override→downcast→
  infer→ref→arith-forcing→option-encoding) retypes silently but decl and
  uses share one cache, so mistyping can only diverge vs LLVM's view —
  rank-2 divergence surface behind enum repr.
- `src/CImport.w` (entry :581-660, ledger :430-501/788, fn translator
  :1652-1796, alias/size tables; 16559-line module mostly unsurveyed):
  omission discipline is HONEST — unsupported fns/macros land in the
  `// @with-cimport-omitted|name|location|category|reason` manifest with
  dependency chains, never as callable stubs (:1736-1737 states the
  policy); cross-target parsing refused loudly (:593-595); statics
  correctly skipped. FINDING CIMPORT-001 (candidate issue, VERIFIED by
  execution): the C scalar alias table is platform-invariant —
  `c_long = i64` (:636), `c_ulonglong` etc., `c_longdouble = f64`
  (:640), sizes `c_long* → 8`, `c_longdouble → 8` (:2321-2323) — with the
  comment's own "arm64 macOS" scope. Mapping is BY NAME
  (`ci_map_base_type`: "long" → "c_long", :5255), never consulting the
  target data layout. Consequences: (a) on native Windows (LLP64) every
  `long` is 8 bytes instead of 4 — silent struct/ABI mismatch on a
  supported platform; (b) on Linux x86_64 `long double` is 16 bytes
  (x87 extended) but the alias is 8 — VERIFIED HERE: stage1 reports
  `sizeof[c_longdouble]() == 8` while `cc` ground truth is 16 (probe
  `docs/audit/probes/readonly_pass_20260903/clongdouble_probe.w`). Bound:
  struct field OFFSETS come from clang (`with_cimport_struct_field_align`)
  so layout is right, but every VALUE crossing the boundary through
  these aliases is mistyped; `ci_estimate_type_size` (:2316) carries the
  same wrong table but has ZERO callers (dead). Nodup in
  `docs/issues/open-issue-triage.md` (#799 is test-gating, not the root
  cause).
- `src/BuildGraphSupport.w` (full, 341) + `BuildGraphTests.w` (60/208)
  + `src/BuildGraphTools.w` (full, 86): validators fail loud with
  target-qualified messages; glob is single-star (no `**` exfiltration
  shape); sort is deterministic insertion sort (fixpoint-safe). Note
  (not a finding): containment is LEXICAL — `..`/absolute/control-byte
  rejected, but symlinks pass through unseen; enforcement rests on
  no-symlink discipline in project roots (document if not already).
- `lib/std/traits.w` (full, 303 lines): operator/trait surface coherent;
  IndexPlace honest about compiler-hardcoded machinery. RESOLVED — see
  TRAIT-001 resolution note above (DOWNGRADED to candidate-low;
  `trait_probe{,2,3}.w`).
- `lib/std/net.w` (52), `time.w` (45): raw-fd C-style layer-1 with
  documented error conflations ("" on EOF-or-error). Question (not
  finding): `sleep` is `async` but calls blocking `with_nanosleep` —
  stalls the fiber worker unless the runtime special-cases it; verify
  runtime-side before judging the "async-compatible" claim.
- `lib/std/random.w` (59): xorshift seeded from crypto source, sane
  fallbacks. Two notes: (1) same class as SYS-001 — `rng_state` global
  mutated non-atomically (fold into SYS-001 fix); (2) `range_i32` /
  `chance` do `0 - v` where v can be INT32_MIN → checked-overflow panic
  at 2^-32 per call — latent, wrapping arithmetic is the one-line fix.
- `lib/std/iter.w` (69): legacy extern-vec helpers; `sum`/`map`/`filter`
  take `Vec` BY VALUE while only observing (callers lose the vec —
  read-only fns should take `&T` per the signature-ownership rule).
  API-shape note, not soundness.
- `lib/std/channel.w` (full, 32 lines): directional types with Drop
  releasing; send/recv are compiler builtins (noted, not reviewed
  here — CodegenDispatch side). Drop→release→close chain matches
  runtime semantics. OK at this depth.
- `lib/std/builtins.w` (56-124 + structure; 124-line module mostly
  read): assert/require/check/panic/todo/unreachable all panic loud
  with `src()` locations. `drop[T](val: T)` consumes-by-signature —
  Higher RAII as documented. OK.
- `lib/std/fs.w` (full, 66 lines): thin pass-throughs. Contract
  alignment verified both ways: `read_file` DOCUMENTS `""`-on-failure
  (BGO-002 is a missing-status-alternative defect, not a hidden one —
  matches #953's framing) while `write_file` documents `0`-on-success,
  which BGR-001 violates (matches #951's framing).
- `lib/std/process.w` (full, 86 lines): `argv_blob` NUL-encodes (the
  contract probed earlier); `env` documents `""`-if-unset (same
  conflation family, stated); `with_vec_push_str` carries an explicit
  escape effect (discipline visible).
- `lib/std/mem.w` (full, 51 lines): docs promise null-on-failure, but
  the allocator exits 99 instead — abort is LOUDER than documented, so
  safe direction, wrong doc; null-checking callers are dead code
  (harmless). Micro-note.

## Runtime

- Platform backends (fn inventories + maxrss offsets; ~1270 lines each
  mostly unsurveyed): exec/spawn/wait/try_wait/maxrss family present on
  all five. `posix_rusage_maxrss` verified per-platform read-only —
  Linux offset 32 ×1024 (kilobytes), Darwin offset 32 unscaled (bytes);
  both correct for their ABIs. Windows uses its own mechanism
  (unsurveyed).
- `rt/regex_runtime.w` (1-297, full): exemplary manual resource
  discipline — every alloc freed on every path including all error
  branches, in reverse order; `regex_to_cstr` callers all free (the
  CORRECT pattern the `with_fs_*` natives should copy for #952).
  Failures panic loud with identity; soft fallbacks (`""`, -1, null)
  only where the signature demands optionality. Interior-NUL safe via
  explicit lengths. Positive reference for target 15.
- `rt/cimport_stubs.w` + gates (full skim + `CImport.w:583-611`,
  `CiMigrate.w:1010-1016`, `Frontend.w:390-420, :897-922` traced):
  weak stubs return empty/0/-1, but both production gates fail loud
  (migrate: eprint+rc 1; frontend: falls to hardcoded tables, which
  error on empty/miss with diagnostics). The `""`+no-error return on
  unavailable is safe ONLY because the caller structurally takes the
  fallback branch — coherent, noted as load-bearing shape. Cross-build
  c_import refused loudly (§18.5, `CImport.w:590-595`).
- `rt/channel_runtime.w` (102-260 core + structure; 260-line module
  mostly read): grow-then-write loop verified correct on second read
  (`break` on grow-SUCCESS; failure re-blocks — first impression of
  inverted logic was wrong, corrected). Unbounded channels grow ×2
  with wraparound guard; closed-channel send silently drops the value
  (:182-183, contract question — delivered vs dropped
  indistinguishable to the sender); null handles fail soft per
  return-type convention. `channel_drop_queued`/`channel_free`
  (71-100) unsurveyed.
- `rt/compat_runtime.w` (full, 67 lines): pure forwarder surface
  (natives → platform backends). OK.
- `rt/panic_runtime.w` + `rt/fiber_stubs.w` (full, tiny): panic
  renders + exits 134, fiber-aware capture; stubs are link-discipline
  dependent (wrong runtime linked = silent async misbehavior, no
  self-check — micro-note). OK.
- `rt/fiber_runtime.w` (54-130 + structure; 320-line module partly
  unsurveyed): scheduler RNG seeded CONSTANT 1 — deterministic
  scheduling, fixpoint-safe by construction. Shutdown tears down before
  the leak walk (verdict hygiene documented); unhandled fiber panics
  exit 1 after reporting (loud). Wrapping-arithmetic operators explicit
  (`*%`/`+%`).
- `rt/rt_core.w` allocator (:1158-1233 targeted): never returns null —
  `rt_exit(99)` on every failure path (refines the ClangBridge OOM
  note: silent-empty lives only on libc-malloc paths).
- `src/DiagnosticRender.w` (69 lines, full) + `src/Diagnostic.w`
  (1-217, full): deterministic diagnostic model. #715 aliasing and #759
  dedup disciplines documented inline. Residuals: (a) `emit` dedups on
  (severity, file, span, message, code) but drops differing
  labels/notes — same words + same node with different labels IS signal
  lost (target 10, minor); (b) `render_with_label_sources_at_offset`
  (:119-150) guards `label_paths` length but indexes `label_texts`
  under the same guard — both call sites push in pairs today, but one
  guard protects two vectors; (c) `DiagnosticList.deinit` is a no-op
  (:170-171) — owned cloned strings' release rests on Vec drop;
  allocator-verdict question for target 15.
- `src/BorrowCfg.w` (1-285, full): explicitly aspirational CFG; NLL
  actually lives in `SemaCheck.expire_dead_borrows_in_block`, and the
  header honestly lists the three uncovered cases. Structural finding:
  no `BorrowCfg` symbol is referenced anywhere despite `use` imports in
  `Sema.w`/`SemaCheck.w` — the builder is currently unreachable, so the
  match/for gaps are TODOs, not live defects. Notes for activation day:
  `CfgGraph.init` allocates 128 bytes with a no-op deinit; post-return
  statements still chain edges (over-approximation).
- `src/CapabilityRegistry.w` (1-64, full): pure capability-identity
  table. Note for the capability-trust pass: std-module recognition uses
  `ends_with("/lib/std/build.w")` suffix matching (:17, :20) — a
  non-std tree carrying that suffix could mint capability-typed values
  unless module identity is canonicalized upstream; review together with
  the 88832131 mint gate.
- `src/Check.w` (8 lines, full): bare re-export facade (`Ast`, `Sema`,
  `InternPool`, `Diagnostic`). OK.
- `src/Codegen.w` (4691-4780, 4325-4454, 5020-5050 targeted; 6516-line
  module mostly unsurveyed): the D6-critical path reads coherently —
  `declare_function_at_inner` consults Sema-finalized
  `sig_param_uses_value_ref_abi` first (:4426-4432) with an explicit
  three-way-agreement comment, matching `arg_pass_mode`'s priority; the
  prologue records ref params for both PLACE and explicit-ref modes
  (:4747-4756). Residuals stand as recorded (R-3 call-site enumeration;
  `declare_function_from_sig` GEN path :4382-4386 not traced).
- `src/CiMigrate.w` (1620-1700 bail conversion + call-site traces;
  2022-line module mostly unsurveyed): fail-loud function granularity
  proven (see placeholder trace); width-family/unsafe-extern/libc
  bookkeeping surveyed structurally only.
- `src/CiPrint.w` (surveyed sections): see placeholder trace; full
  arm-by-arm verification deferred to target-23 work.
- `src/CodegenTraits.w` (1-332 of 2529; const-eval and dispatch
  sections unsurveyed): trait table build + row-level self-audit
  (`audit_trait_table_contracts` — parallel lengths, inverse map,
  AST-row re-read, vtable slot counts; runs only when analysis is
  enabled). Residuals: (a) `codegen_type_node_mentions_self` (:203-236)
  unhandled kinds DECL/INFERRED/TRAIT_OBJ/TYPEOF silently report
  no-Self — prove uncarriable at this phase or extend (target 6/13);
  (b) `dyn_trait_method_fn_type_reporting` (:245-332) rebuilds the
  dispatch type with sret/indirect steps that MUST match
  `declare_function` + `create_dyn_wrapper` step-for-step — same
  predicates, but sequence parity unpinned; needs a win64-aggregate
  dyn-call test (target 3, D6-critical).
- `src/CiIR.w` (1-950, full): uniform pool discipline — distinct id
  types, id 0 reserved null, freeze-trapped mutation, explicit deinits
  (ownership hygiene contrasts with the rt natives' leaks). Notes:
  (a) `set_type` (:384-398) rebuilds the whole types Vec per call —
  O(n²) if invoked per node (perf only); (b) `find_symbol` reverse-linear
  + pipe-delimited `consumers` scan — O(n²) project load (perf only);
  (c) CID flag bits share positions across kinds with different meanings
  (:667-670, documented inline — misread risk for future readers);
  (d) `owner_module_path` fail-softs to `""` (callers must handle).
  Layout comments are the printer/lowering contract (same pattern as
  MIR) — the exhaustiveness question recorded in the placeholder trace
  applies here too.
- `src/CiPrint.w` (1-60, 391-460,
  557-600, 787-935, 1194+ surveyed; 10 placeholder arms counted),
  `src/CiMigrate.w:1620-1700` (bail conversion), `src/CImport.w`
  (traced call sites only — 14k-line module largely unsurveyed):
  migrator placeholder trace. The `<ci:unimpl:*>` arms (FOR, PRE/POST
  INC/DEC, COMMA, SIZEOF_EXPR, +3) are near-unreachable in practice —
  `for` desugars to while, inc/dec lower to effect statements, comma
  merges — and whole-body failure is fail-loud via bail globals
  (`CiMigrate.w:1641-1662`, "never emit partial output"). Residual
  (target 23, precise): a NON-empty body embedding a null child
  (`ci_print_stmt(0)` → `<ci:stmt:0>`) or a surviving placeholder node
  has no text-scan gate found — audit whether null children can embed in
  otherwise good bodies and add a marker scan if so. Initial alarm
  refined, not confirmed.
- `src/AsyncLower.w` (1-424, full): MIR→Async-MIR suspend walker. Notes:
  (a) `walk_expr` has no catch-all — any unlisted NodeKind silently skips
  its subtree (same exhaustiveness class as the rvalue decoder; target
  4/23); (b) bodies with no AST decl get empty suspend lists
  (`async_find_fn_decl` → 0) — sound only if synthesized bodies never
  suspend; (c) snapshot liveness counts spans linearly, not CFG-aware —
  fine for the audit view, must never feed codegen; (d) index-not-copy
  discipline documented inline (#715). Consumers: only `Compilation`
  wires `requires_async_runtime()` into the link plan — so AsyncMir note
  (a) (pure-Yield generators) concretely decides fiber-runtime linking;
  queued for target 4/16.
- `src/Analysis.w` (1-220, 316-340, 828-1193 of 2035; collectors/query
  surface structurally surveyed): the `with analyze` fact engine. Audits
  read as careful validators (parallel tables, strides, mirrors,
  fixpoint re-check via the unified rule). Residuals: (a) the effects
  audit shares the `is_copy`/`is_copy_frozen` agreement question (same as
  75cfc037); (b) `analysis_is_frozen_consumer` (:1097-1100) is a hardcoded
  path-substring list — a new frozen-phase file bypasses the gate
  silently, and matching is substring-based; derive from one authority
  (target 1/24); (c) `analysis_audit_mir` skips `lowering_failed` bodies
  for use-after-kill (:1141-1142) — sound only if failed bodies never
  reach codegen; (d) `analysis_parse_node_id` (:330-339) accumulates
  unchecked — fail-safe direction (garbage id finds nothing), noted for
  the pattern file. Unwrap sites checked are contains-guarded.
- `src/AsyncMir.w` (1-164, full): suspend-boundary data + dump only.
  Notes: (a) `requires_async_runtime` (:110-117) ignores pure-Yield
  generators — correct only if generators never need the runtime; queued
  as a target-4 question; (b) parallel suspend Vecs grow in one writer
  (`add_suspend`) with no length assertion — same family shape the pool
  audit guards elsewhere (target 8 note).
- `src/Ast.w` (1-60, 186-250, 776-930 surveyed + targeted; pool
  accessors and remaining sections unsurveyed): pool header shows
  fail-loud `ast_pool_phase_bug` (eprint+abort) and a distinct-`AstFileId`
  pilot against the #660 id-collision class — directly relevant to the
  441dfc62 residual (migration in progress; Resolve/frontend still share
  numbering). Exact-int arithmetic carries ok/overflow flags (checked
  style — the BGO-009 contrast case for where checked math lives).
  Depth is partial; full accessor-bounds review deferred.
- `src/Archive.w` (1-379, full): BSD/GNU archive writer + LE64-only
  Mach-O/ELF symbol parsers, all reads bounds-checked (OOB yields
  zero/empty, never panics). Notes: (a) `create_static_archive` (:306-309)
  rejects empty members as unreadable — loud, so integrity holds, but the
  BGO-002 conflation echoes (empty .o refused); the BGO-006 deletion
  defect is confirmed in the Ops caller, not here; (b) write paths check
  `with_fs_write_file` rc (:294-295, :375-377) — defeated by BGR-001 all
  the same (short write returns 0), so archive truncation can still go
  silent: BGR-001 blast-radius confirmation; (c) third byte-comparator
  copy (`ar_str_compare`, target-24); (d) symbol parsers cover 64-bit LE
  only — matches all compiler targets, noted.

## FIBER-CAP-001 (filed #995) — spawn >1024 live fibers silently awaits to zero
- Symptom: `await_all` over 1100 (or 3000) tasks: indices 0..1023 correct,
  1024+ read 0. Deterministic, -O1, 1 and 8 workers. Plain-Vec 3000-element
  control passes, exonerating the container.
- Chain: `with_fiber_spawn` returns -1 past 1024 live fibers
  (rt/fiber_core_darwin.w:772-774) → codegen stores unchecked into
  Task.fiber_id (src/CodegenDispatch.w:18362, 18449-18464) →
  `with_fiber_await(-1)` early-returns via is_live==0
  (rt/fiber_runtime.w:212-215; rt/fiber_core_darwin.w:1031-1038) →
  result loaded from never-written buffer (observed 0).
- No-Silent-Fallbacks violation at three layers. #991 (CHAN-001, 2-fiber
  probe) confirmed independent — stands as filed.
- Probes: docs/audit/probes/fiber_spawn_cap_1024/ (bis.w, dbg3.w,
  vec1024_probe.w + README).

## Fiber runtime trio complete (modules 12-14: fiber_runtime, channel_runtime, fiber_core_darwin)
- Steal-race hypothesis REFUTED: all scheduler queue/slot mutations run under
  scheduler_lock (run_one_fiber_for_worker :653-662 covers dequeue+steal);
  #991's corruption is purely the channel layer's lock-free queue. Evidence:
  docs/audit/modules/rt__fiber_core_darwin.w.md.
- Build fact: rt/fiber_core_darwin.w compiles for ALL Unix targets incl.
  Linux (build.w:629,640,672) — the 1024-boundary probes executed this exact
  module. Name is historical.
- Dead surface: with_fiber_set_result / FIBER_OFF_RESULT written never read;
  declared in CodegenDispatch.w:17586-17591, never called. Not filed.
- #991 promoted: fresh w4 runs give 1 segfault (rc=139) + 5 wrong sums; w1
  exact twice. Grow-path UAF now observed; commented on #991.
- #995 chain reconfirmed from the core side: valid fiber ids always > 0, so
  a `<= 0` guard at await/cancel entries is available without lookup changes.

## lib/std/task.w complete (module 15)
- TASK-002 (in #995 as comment): Result-await_all over 1100 all-Ok tasks
  HANGS (rc=124, 60s, zero output) — readiness scan never selects -1
  handles, progress no-ops after real fibers drain. await_first/await_any
  share the shape by inspection.
- TASK-001 upgrade (#981 comment): with_concurrency is unusable — compile
  error inside embedded stdlib (task.w:232-233) misreported as caller
  overload failure. Removes the only stdlib mitigation for #995.
- Defer-cleanup bounds verified accurate in all five combinators.
- Evidence: docs/audit/modules/lib__std__task.w.md; probes conc.w, hangres.w.

## Wave 1 (delegated) complete — 5 modules, 20/287 total
- Amendment 2026-09-04: subagents perform complete examinations; check-off
  still requires primary verification (branch inspection + probe re-runs).
- src/MirSuspendCheck.w: SUSP-001 filed #999 (E0701 false negative through
  aggregates; q1+p5 probes re-run rc=0 silent, p1 control fires rc=1).
  Yield-intrinsic set cross-checked vs MirIntrinsic enum — complete;
  THREAD_SCOPE_JOIN_ALL absence analyzed-and-clear (blocks thread, no yield).
- src/MirOpt.w: self-declared counting stub, zero in-tree users — no defect.
- lib/std/channel.w: CHAN-002 filed #1000 (sync-context silent send-drop +
  recv-None ambiguity contradicting channel.w:7 doc).
- lib/std/sync.w: real atomics, correctly paired orderings; condvar/barrier
  rendezvous re-run coord-ok. notify-without-lock contract undocumented —
  noted, not filed (no deterministic execution).
- src/BorrowCfg.w: stub-by-design, zero consumers (dead `use` imports only);
  builders' AST layouts verified vs layout table; conditions unbuilt —
  flagged for the future wiring diff (same class as #999).
- Process note: stated a BorrowCfg SHA from memory in the evidence draft;
  caught and corrected to computed a57c723e... — hashes must be computed,
  never recalled.

## Wave 2 (delegated) complete — 5 modules, 25/287 total
- src/CodegenTraits.w: VTABLE-001 filed #1002 (omitted impl method → null
  vtable slot → dyn call traps rc=133, check + validate-all clean).
  Matrix re-run: static omission loud rc=1, omission-unnever-called rc=0
  (by #988 design), dup-impl/self-return rc=1, positive ct-ok.
- src/SemaDecl.w: DISC-001 filed #1003 (range check i8/i16-only; u8/300 →
  truncates to 44 + match SIGSEGV 3/3; u32/-1 → silent no-match rc=0).
  All 15 check probes re-run with matching directions.
- src/Mir.w: 1024-local clamp verified dump-only + loud marker; no finding.
- src/SemaDiag.w: error-code matrix spot-verified; no finding.
- src/Codegen.w: ABI-001 NOT filed — per-path classifiers confirmed
  (arg_pass_mode only from declare_function_from_sig; at_inner inline
  4426-4495; compute_fn_abi zero hits) but no divergent behavior
  demonstrated; recorded as architectural risk per execution standard.
- Standard applied: findings need observed behavior; structure-only
  suspicions become evidence-file notes, not issues.

## Wave 3 (delegated) complete — 5 modules, 30/287 total
- src/CodegenDispatch.w: no new finding. Primary seam review confirms the
  call-arg path is D6-compliant (reads sig verdict, loud on missing sig,
  single funnel) and dyn emission is fail-loud at every step except slot
  content (#1002 — fix belongs at construction, confirmed).
- src/SemaCheck.w: 8/8 probes re-run matching. subst_vec_lookup string
  fallback contained (exact-first, count==1, miss→resolve-without-subst).
  View collectors overlap Sema.w's structurally; behavior correct.
- src/Sema.w: 6/6 view probes correct incl. tuples+calls. "Three walkers"
  claim narrowed: collect_* handles aggregates explicitly; only CALL/mask
  corners delegate to sidecars. T24 note retained for decision gate.
- src/MirLower.w: 4/4 validate-all + runtime probes pass; disc consumer
  takes raw values (confirms #1003 fix location).
- src/AsyncLower.w: FSTRING/BREAK inventory gaps confirmed but
  observability-only (link gate is flavor-based, analysis is MIR-based,
  p11 runs v=41). Not filed; arms named for the future diff.
- New issues wave 3: #1002 (null vtable trap), #1003 (discriminant crash).

## Wave 4 (delegated) complete — 5 modules, 35/287 total
- src/Parser.w: PREC-001 filed #1004 (spec §9.9 contradiction: |/^/& inverted
  — spec probe panics rc=134, inverted probe passes; ?? looser than + —
  Some(10)??2+3 yields 10 not 13). 19/19 probes re-run matching.
- src/Lexer.w: LEX-001 filed #1005 (EOF-unterminated string check rc=0;
  swallow-code case loud-but-misdirected rc=1). Block-comment lexes regex,
  loud downstream — not a defect.
- src/Token.w: dead TK_KW_THEN + 11 "unknown" tag_names — cosmetic, noted.
- src/Ast.w: no layout drift; OOB panic-vs-default split by design.
- src/Resolve.w: silent last-wins contained by Sema shadowing ban (3 shapes
  rc=1, message verified). No finding.
- New issues wave 4: #1004 (precedence), #1005 (unterminated string).

## Wave 5 (delegated) complete — 11 modules, 46/287 total
- compiler/Compilation.w + shims: pipeline ordered/gated/frozen; probes pass.
  Check.w comment overclaims zero-fn file — cosmetic. No finding.
- Diag/Diagnostic/DiagnosticRender: multiline renders first-line-only with
  correct location + clamps (120 carets, col 200) — deliberate limit, noted.
- panic_runtime/fiber_stubs: every path loud (134 + locations); stubs form a
  consistent zero-fiber trio; detach asymmetry unreachable. No finding.
- process/fs: exit-code + errno fidelity verified by execution (42/7/127,
  -2); three doc/cosmetic notes. No filing.
- New issues wave 5: none. (Process note: caught a second placeholder-hash
  draft before writing — hashes computed first, always.)

## Wave 6 (delegated) complete — 7 modules, 53/287 total
- src/CCodegen.w: BIT-001 filed #1006 (emit-C 32-bit hardcode for 6 bit
  intrinsics; fresh emission + LLVM control + C value proof 6 vs
  17179869190). strchr = #955-item3 dupe; enum-repr still #990.
- src/CImport.w: 8/8 probes match (supported translate, unsupported loud);
  scalar maps are #977 verbatim. No filing.
- src/ComptimeEval.w: limits loud (loop/recurse/divzero/IO all rc=1);
  i64 truncation still #943 (commented with isolation signal). No filing.
- Fmt/InternPool/InitTemplates: rewrites runtime-neutral (identical runs).
  Style notes only.
- build.w: chain dry-verified; -O1 invariant holds (sole -O0 is CLI flags).
- New issues wave 6: #1006. Comment: #943 still-repro.

## Wave 7 (delegated) complete — 12 modules, 65/287 total
- rt/linux_x86_64.w + darwin: SIG-001 filed #1008 (124B stack smash per
  spawn + 136B OOB read per child restore; Darwin sizes correct; header +
  repo-precedent evidence, no dynamic tooling available).
- rt/rt_core.w: externs match definitions; documented unsafe pattern. Clean.
- collections/hash/option/result: D22-conformant by execution (borrow/get,
  owned/remove), exact-once ownership, OOB loud. No finding.
- build lanes (emit_c/package/runtime/seed/compiler): corpus threading
  works; lane refuses bundles loudly; check-rc1 on emit_c/package is a
  module-root harness artifact. No filing.
- New issues wave 7: #1008.

## Wave 8 (delegated) complete — 13 modules, 78/287 total
- regex_runtime + regex.w: REGEX-001 filed #1009 CRITICAL (matching
  universally false incl. literals; replace panics heap-limit; error paths
  work — fault in migrated corpus by elimination, cell TBD).
- strings: STR-001 filed #1010 (documented is_empty aborts compiler, core
  dump). Ownership/OOB matrix green; lenient OOB noted.
- net/http: NET-001 filed #1011 low (send -errno vs doc -1; close/v4 gaps).
  connect coarseness + recv-"" documented; udp-connect correct. Body repaired
  after shell-backtick mangle — process rule: bodies via files only.
- compat/cimport_stubs: shims faithful; libclang-absent degradation path is
  inspection-grade only (unconstructible here) — note, not filed.
- windows x4: parity holds; single-threaded core divergence flagged for
  #995/#991 fix authors. Inspection-grade by construction.
- New issues wave 8: #1009, #1010, #1011.
- Wave 9 (6 modules): Analysis/Archive/BuildGraphTests/BuildGraphTools
  COMPLETE, no findings. AsyncMir 3 reported findings all refuted
  (Vec.push legal on fn receivers — BuildGraphSupport.w:43-46 control;
  finalize_states unconditional at AsyncLower.w:100; Yield-outside-generator
  already rejected) — COMPLETE. BuildGraphSupport INCOMPLETE: dirname("/")
  -> "" probe-executed — filed #1020 (xclass utf, from tables retry) and
  #1021 (dirname root, Low).
- Wave 10 (6 modules): CapabilityRegistry/CiMigrate/CiPrint/ComptimeValue
  COMPLETE, no findings. CiIR INCOMPLETE: 2 stale layout comments verified
  verbatim (:451 DO_WHILE d2, :456 VAR_DECL flags) — filed #1022 (Low);
  set_type O(n) rebuild noted, not filed (perf-only, leak half unconfirmed).
  ComptimeTransform PARTIAL (lines 1-1100 read, clean) — remainder follow-up
  launched.
- ComptimeTransform follow-up closed: first pass-2 write landed after a stale
  41-line read (false "not updated" alarm); pass 3 independently re-read
  1100-3225 + EXECUTED probes (Display/Clone/Debug/Default/Eq/SoA PASS,
  2 fail-loud negatives). Verdict COMPLETE, 0 defects. Lesson: re-read the
  artifact before declaring a child write missing.
- Wave 11 (6 modules): ConanClient/FnAbi/LockFile/Lsp/Migrate/Parse all
  COMPLETE, 0 findings. Migrate.w verified a loud-failure stub (eprint +
  return 1, zero callers) — correctly COMPLETE per no-silent-fallbacks.
  Lsp.w (2078 lines) traced with refutations. No new issues.
- Wave 12 (6 modules): ReceiverMigration/Scaffold/Source/TypeLayout/Types/
  bootstrap_main all COMPLETE, 0 findings. No new issues.
- Wave 13 (main.w split + render.w): main.w COMPLETE via 2 passes (0 defects).
  render.w INCOMPLETE: stride-3-vs-4 allegation REFUTED against Parser layout
  ([count, 3N triples, N aligns] + trailing is_pub at +1+4N, both body
  variants); union fallthrough CONFIRMED — filed #1023 (Low, no callers).
- Wave 14 (6 modules): AbiStamp/Backend/BundleFingerprint/BundleInterfaceEmit/
  BundleInterfaces COMPLETE, 0 findings. ClangBridge follow-up closed: tail
  read, regex caller search redone, seed probes run — F2 silent-i32 vs loud
  contract CONFIRMED with live callers (:806/:870) — filed #1024; F1 (LP64,
  no callers), F3 (TODO stub), F4 (prefix wart) held with reasoning.
- Wave 15 (6 modules): CodegenUnits/CodegenUnitsPolicy/Compilation-Config/
  ConanClient/DriverOptions/EmbeddedBundles all COMPLETE. Surviving notes
  only (comment accuracy, unused import, fail-loud macOS path) — none filed.
- Wave 16 (6 modules): EmbeddedClangResource/EmbeddedRuntime/EmbeddedStdlib/
  Link/LockFile COMPLETE (resource-dir I/O Low held: stamp-last retry +
  loud downstream failure). LlvmBridge INCOMPLETE closed by primary:
  thiscall=33 vs LLVM22 70 filed #1025; >128-param stack overflow filed
  #1026 (dead actual_count cap, live Codegen callers); DIBuilder leak filed
  #1027. Oracle: version-matched system LLVM22 headers (read-only).
- Wave 17 (5 modules): ModuleSource/ProjectConfig/Runtime/TrackedInputs/Zcu
  all COMPLETE — orchestration area done (25/25). TrackedInputs F1
  (embed_file("") silently embeds "") verified live-probed — filed #1028.
- Wave 18 (6 foundation): Arena/Diagnostic/DiagnosticRender/Ids/Mod COMPLETE.
  InternPool 3 findings closed by primary: F2/F3 REFUTED by landed commit
  de5a0af8 (parallel impls are maintainer-chosen, callsites preserved by
  design; stale plan exit criteria noted, not filed); F1 held as hygiene
  note. No new issues.
- Wave 19 (5 foundation): Source/SourceMap/Span/Types/Values all COMPLETE,
  0 defects — foundation area done (11/11). No new issues.
- Wave 20 (1 rt + 5 build): linux_aarch64/abi/https_fetch/pcre2/retention
  COMPLETE — runtime area done (16/16). clang_resource.w INCOMPLETE closed
  by primary at artifact level (generated embed data has float.h but zero
  __float_* entries; clang22 float.h needs 3) — filed #1030 (Medium, loud).
  Child's "committed test covers it" claim refuted (no test_cimport.w).
- Wave 21 (6 build): zlib/release_uat/zlib_gunzip/wo/selfhost COMPLETE.
  sdk.w INCOMPLETE closed by primary: missing windows-aarch64 tag branch
  CONFIRMED (2ee9f70e claimed it, diff touched only current_platform +
  validate_cache) — filed #1031; packaging splits exclude windows-aarch64
  CONFIRMED (.a/extensionless unix assumptions) — filed #1032; dead fns held.
- Wave 22 (8 build): 6 fixtures + zlib_gzip/zlib_http_fetch — build area done
  (25/25). Both F1s EXECUTED-confirmed by primary (seed check exit 1):
  zlib_gzip wrong extern sig poisons stdlib call — filed #1033;
  zlib_main bare write (§18.1) — filed #1034.
- Wave 23 (6 std): box/build/builtins/cfg-stackify/compiler/component all
  COMPLETE, 0 defects (behavioral probes incl. independent oracles). No new
  issues.
- Crypto-wave follow-up (primary): `[v; N>64]` repeat-init initializes only
  floor(N/sizeof(T)) elements (u32-80: 20/60, u32-100: 25/75, u16-80: 40/40,
  u64-72/80: 9/10 exact, u64-65: 8 real + 1 garbage-luck). MIR count=N ok,
  C backend ok, raw LLVM emission ok (80/80 pre-cleanup, gdb-traced 80
  (GEP,store) pairs), loss is in always-on per-function `sroa,mem2reg`
  cleanup (CodegenDispatch.w:15607) leaving 20/N-sizeof — filed #1049.
  Sibling: `var a = b` for [T; N>64] emits memcpy len = element count
  (100 not 400 for [u32;100]; copy probe 25/75) — filed #1050.
- Crypto close-out (primary, 2026-09-04): monty matrix re-executed
  (s576 PASS / s610+ FAIL, boundary exactly mlen=20 = #1049 prefix;
  s610/b2449 wants oracle-confirmed via python3 pow; 2480/2450 panic).
  Filed #1051 (from_monty >= 590b via #1049), #1052 ([u32;80] overflow
  > 2449b), #1053 (bigint/rsa/crypto suites stale), #1054 (AEAD dead:
  entry not pub + poly1305_finish sema reject, re-executed), #1055
  (ec/ecdsa suites stale + P-256 header-vs-private). NOT filed by
  judgment: ec peer-key validation (no oracle), ecdsa r/s>=n nit
  (refuted vuln, HELD distinguisher), ecdsa on-curve (BearSSL fidelity),
  chacha20 4/64-byte assertion nit. 6 crypto rows checked; 7 delegated
  (sha256+endian, hmac+poly1305, gcm, rsa, x509).
- Crypto wave CLOSED 13/13 (primary, 2026-09-04): finished x509
  (2 findings filed #1056 OOB-escape HIGH + #1057 sig-INTEGER panic
  MEDIUM, both executed with openssl-cert probes), sha256 (4/4
  hashlib vectors incl. padding edges -> COMPLETE), endian child
  COMPLETE, gcm (KAT + 48B/AAD node-oracle vector, all byte-exact ->
  COMPLETE), hmac (5/5 incl. RFC 4231 + empty edges -> COMPLETE),
  poly1305 (uncompilable, owned by #1054), rsa C1 closed via
  oracle-confirmed probe_1024 (band #1051). Wave issues: #1051-#1057.
  Checklist 174/287.
- Std wave 1 partial (primary, 2026-09-04): context/ffi/mem/os/fmt
  children COMPLETE (rows checked); fixed_string F1 reproduced +
  bisected by primary (s[i] -> undef/trap, then-falls-into-else,
  SIGTRAP/SIGSEGV; seed reproduces) — filed #1059; traits/random/
  signal/preludes/str_abi/encoding done by primary (filed #1058 RNG
  MIN-negation panic); json F1 re-executed byte-identical — filed
  #1060 (F2 stale example recorded); io/iter INCOMPLETE-held probes,
  no defects. Checklist 192/287.
- Std wave 2 (primary, 2026-09-04): encoding x5 COMPLETE (child);
  libc/sys COMPLETE (child); sysinfo/testing/thread COMPLETE
  (children); time COMPLETE + filed #1065 (Duration ctors private,
  example red, re-verified); rc done via #1064 (struct-literal
  misindex root-caused by primary: field value at stale GEP index,
  pre-cleanup IR proof, 5-case matrix; Rc exonerated); tls done
  (PRF byte-exact vs python oracle; filed #1061 no-auth HIGH,
  #1062 wire-bounds, #1063 stale test). Checklist 205/287.
