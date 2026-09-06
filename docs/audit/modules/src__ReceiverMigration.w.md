# Audit: src/ReceiverMigration.w @ 450733e5

Scope: full module (515 lines). Built-in D7 receiver migration (relocate top-level
`fn Type.method(self..)` into `impl Type:` blocks). Targets: T13 ownership/drop,
T15 migration fidelity, T22 spec conformance. Read-only on compiler sources.

## T13 ownership/drop — CLEAN
- Owned-string discipline via `with_str_clone_ref` at every cross-structure hand-off:
  `local_source_path` (124), `target` init (297), header push (379), `unique_relocation_paths`
  (436), `run_receiver_migration` entry/excludes (478,483). `Vec[str]` elements always
  cloned before push (136,433,436); `reindent` clones `pad` per line (85,91).
- No manual free/drop sites; `RelocationFacts` vectors are aggregate-owned and mutated
  via `set_i32` (258,454). No aliasing of `text` slices beyond immutable `slice()` views.
- Refutation: searched for bare `++` aliasing into stored state — only `target` rebuild
  (302,306) rebinds a local, never aliases a caller buffer. No finding.

## T15 migration fidelity — CLEAN
- Authority split is correct: sema selects (`compiler_relocation_facts`, 126-141:
  TopLevelMethod + ExplicitReceiver + Read/Mut/Move mode mask) and the lexer rewrite
  must structurally match every selected decl or fail hard:
  - unmatched semantic decl -> error (397-400, 445-451); duplicate match -> error (255-258);
    source/sema mode mismatch -> error (260-262); preflight selected!=matched -> exit(1)
    (499-501); apply changed!=selected -> exit(1) (511-513).
- Associated functions (no `self` first param) left at top level (244-247); `pub` and
  mode keyword preserved (385-387); self-param deletion eats trailing comma+spaces
  (309-313); body extent stops at next column-0 token with trailing-newline trim (317-327).
- Complex generics never mis-moved: `count(tparams)!=count(target args)` -> `ok=false`,
  skipped+reported (335-350); report mode returns -1 when skipped>0 (405); apply mode
  leaves the whole file unchanged (408-410). `extend` deliberately not used (351-353).
- Grouping: blank NEWLINE tokens do not reset group (167-169); non-relocatable col-0
  decl closes it (188-193); same-header gap reindented inside (375-376), differing header
  re-emits leading gap at col 0 (378-381). `Self`-receiver base taken from dotted name,
  never receiver spelling (294-306).
- Refutation attempts (all refuted, no defect filed):
  - R1 `trim` strips only space (32), not tab (38-46) -> cosmetic only; `count_args`
    (96-112) is whitespace-insensitive and `tp_decl` is a raw slice, so grouping/counts
    unaffected. Tab-indented tparams still compare equal after identical trim on both sides.
  - R2 receiver-args slice takes first `[`..end (299-302) without bracket matching ->
    safe: `recv_type` is already delimited at top-level `,`/`)` (271-284), so the tail
    from the first `[` is exactly the arg list including nestings.
  - R3 `tp_inner_b + 1` (333) assumes 1-byte `]` -> holds: `]` is ASCII single byte in
    the lexer; `tokens.get_start/end` are byte offsets into `text`.
  - R4 keyword method names (182-186): name token kind unchecked, but both uses
    (359,388) are offset slices, kind-agnostic. No finding.

## T22 spec conformance — CLEAN
- Matches header contract (1-17): static-by-location top-level instance methods move
  into `impl`; associated fns stay; unbound-tparam methods skipped+reported.
- CLI `--report|--list|--apply [--exclude] <entry.w>` implemented (456-515) with
  no-write structural preflight over the whole selection before first write (491-501),
  `reset_matches` between phases (505), per-file tail emit + single write (413-418).
- Negative controls: empty file -> 0 (151-152); `count==0` apply -> 0 no write (411-412);
  missing entry / double entry / `--exclude` without arg -> usage/error exits (458-487).

## Probes
- P1 EXECUTED: `with-stage1 check src/ReceiverMigration.w` -> exit 0, no diagnostics
  (module parses/typechecks under seed compiler).
- P2 HELD (reason: apply-mode writes are destructive; report-mode whole-project proof
  `tools/relocate_methods.w --report` not run to avoid tree-wide side effects and to stay
  within the two-batch budget; fidelity instead verified by code-path trace above).
- Negative controls verified by trace (empty-file, no-match, skip-blocks-write paths).

Verdict: COMPLETE
