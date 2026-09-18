# Primary verification — `lib/std/rc.w`

Status: **INCOMPLETE** (core clone/drop balance verified; cycle + thread
probes blocked by an out-of-scope defect — see F1)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 103 lines (single complete read)

## Scope examined

`Rc[T]` (`Rc.new` `:18`, `clone` `:31`, `strong_count` `:36`,
`as_ref` `:40`, `Deref` `:44`, `Drop` `:48`) and `Arc[T]`
(`Arc.new` `:63`, `clone` `:73`, `strong_count` `:79`,
`as_ref` `:85`, `Deref` `:89`, `Drop` `:93`), including the
`RcControl { strong: i64, value: *mut u8 }` layout (`:10`),
the move-assign-into-heap-slot idiom (`:24`, `:65` — same fix
as std.box), and the `Rc` plain-`i64` vs `Arc` `Atomic[i64]`
count discipline. Callers: `lib/std/prelude.w:12` and
`lib/std/prelude_alloc.w:11` (`use std.rc`), `src/main.w:652`
(prelude injects `use std.rc`), `src/CodegenDispatch.w:5007`
(`mir_sema_type_refcount_kind`: Rc=1/Arc=2 branch),
`src/ComptimeEval.w:2825` (`Arc[Rc[i32]]` Send reasoning),
`tools/drop_audit.w:60,122` (`rcbare` shape cell). No `tests/`
files cover rc; no in-repo user callers. No `Weak[T]` exists
anywhere in `lib/std`.

## Behavioral matrix

EXECUTED (oracles independent — Drop-guard trace strings and
`--debug-alloc` allocator verdicts, stage1):

- `docs/audit/probes/rc/rc_clone_count.w`: `strong_count` 1→2→3→2→1
  across nested scopes; aliasing reads via auto-deref, `as_ref()`,
  `deref()` all agree. PASS. Under `--debug-alloc`: `leak count=0`.
- `docs/audit/probes/rc/rc_drop_once.w`: no drop at `new`/clone time;
  inner-clone drop leaves payload alive (`strong_count` back to 1);
  last-owner exit drops payload exactly once (`"G"`). PASS. Under
  `--debug-alloc`: `rc-drop-once-ok` + `leak count=0`.
- `docs/audit/probes/rc/rc_alias.w`: two clones read the same heap
  value through all three access spellings. PASS.
- `docs/audit/probes/rc/arc_clone_drop.w`: `strong_count` 1→3→1,
  exactly-once payload drop (`"A"`). PASS. Under `--debug-alloc`:
  `leak count=0`.
- `docs/audit/probes/rc/rc_explicit_deref_reject.w` (`with check`):
  explicit `*rc` rejected with `cannot dereference non-pointer
  value` — by design: `src/SemaCheck.w:8770` serves unary `*`
  only for `&T`/`TY_REF` and raw `TY_PTR`; `Deref` types use
  auto-deref/`as_ref()`. PASS (negative probe).

HELD (not executed; reason recorded):

- Cycle collectability: `std.rc` has no `Weak[T]` and no cycle
  collector, so any expressible cycle is uncollectable by
  construction (Rust parity; spec §8.2 promises nothing more).
  A `Mutex[Option[Rc[N]]]`-linked cycle probe
  (`docs/audit/probes/rc/rc_cycle_leak.w`) could not reach the
  leak question — blocked by F1 below.
- Cross-thread `Arc` sharing and the `Rc: !Send/!Sync` /
  `Arc[T: Send+Sync]: Send+Sync` facts: `Arc` uses
  `fetch_add(1, .AcqRel)` / `fetch_sub(1, .AcqRel)` + `.Acquire`
  load (`:76`,`:82`,`:97`) vs `Rc`'s plain `i64` (`:33`,`:51`),
  matching the documented single-threaded/thread-safe split by
  inspection only; no thread probe was run.

## Findings

- F1 (out-of-scope, execution-verified): a struct literal
  containing a `Mutex` field misbehaves with zero `Rc`
  involvement — `docs/audit/probes/rc/mutex_struct_no_rc.w`
  (`let m = M { id: 1, link: Mutex.new(0) }`) fails
  `assert(m.id == 1)` at line 10 and exits 134 (SIGABRT from
  the assert panic). Refutation attempt: `Point { x, y }`
  literals read back fine (`rc_alias` PASS) and a `Drop`-guard
  payload passes through `Rc.new` untouched (`rc_drop_once`
  PASS), so this is isolated to `Mutex`-in-struct-literal
  (see `lib/std/sync.w:134` `Mutex.new`), not to `rc.w`.
  Triage belongs to sync.w / struct-literal lowering, not this
  module. Not filed (audit instructions: no issues).
- F2 (consequence of F1, execution-verified): every probe
  combining `Rc` with a `Mutex` payload fails the same way —
  `rc_mutex_nocycle.w:12` assert fails, `rc_mutex_set.w`
  exits 139 (SIGSEGV), `rc_cycle_leak.w` exits 139 — all
  without reaching any `Rc`-specific logic beyond what the
  passing probes already cover. Refutation attempt: removing
  `Rc` from the program (`mutex_struct_no_rc.w`) reproduces
  the failure, so `Rc` is exonerated; F2 is not an independent
  finding.
- In-report notes (not filed): `Arc.new` initializes
  `value` before `strong` (`:67` then `:69`) while `Rc.new`
  does the reverse — harmless (single-threaded construction,
  unpublished pointer); explicit `*` on `Rc`/`Arc` is a
  hard error, so reviewers must use auto-deref/`as_ref()`.

Verdict: INCOMPLETE (F1 blocks the cycle probe; thread-sharing
and Send/Sync facts unprobed)

## Close-out (primary, 2026-09-04)

F1 root-caused by primary to a codegen defect, not Rc/Mutex: struct
literals store a generic-struct-typed field's value at a stale field
index (pre-cleanup IR: `link` value stored at `[0,0]`, clobbering
`id`; 5-case order matrix + scalar/enum/plain-struct controls).
F2 is the same defect surfacing through use of the clobbered
pointer. Filed #1064 (which names the Rc+Mutex segfaults as blast
radius). No Rc defect remains.
