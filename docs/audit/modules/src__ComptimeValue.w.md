# Audit: src/ComptimeValue.w @ 450733e5

Verdict: COMPLETE (no findings)

Scope: read-only source audit. No compiler sources modified. Targets: T13 ownership/drop, T15 migration fidelity, T22 spec conformance. Full module read (482 lines).

## T13 ownership/drop: no findings

Refcount design (lines 40-60, 469-484): str/bytes/chunk constructors clone text via with_str_clone_ref and pair it with a fresh 1-count cell from comptime_text_refs (null iff len==0). comptime_value_clone deep-clones text plus a fresh cell (line 471). comptime_value_share bumps the shared cell and bitwise-copies the str header through a raw const pointer (lines 478-483), with documented rationale (loop-evaluator quadratic-clone note, lines 473-477). Drop decrements the cell; the last dropper frees the cell and runs normal str cleanup while non-last droppers zero their own header first so only the last release runs (lines 47-60).

Refutation attempts, all survived (no defect filed):

- R1 empty-string share double-drop: every constructor sets text_refs null exactly when text is empty (comptime_text_refs len==0 gate lines 41-42; str/bytes/chunk sites lines 110-120, 230-240, 254-264). Shared empties therefore take the text_refs==0 Drop path plus ordinary empty-str cleanup, which is a no-op for zero-length values. No constructor in-module can produce non-empty text with null refs.
- R2 header-blanking width (lines 58-60 write two i64 zeros): matches the 2-word str header used consistently by the share-path raw-const copy (lines 481-483); share and Drop are the only two bitwise sites and they agree with each other.
- R3 accidental moves of the now-owned str: both clone-site uses pass v.text to extern fns taking ref-str (lines 4, 471), i.e. borrows, not moves. The single bitwise copy is the intentional share path.
- R4 comptime_values_equal temporaries (lines 394, 458, 464-465): with_str_clone_ref results there are plain str values compared by with_str_eq_ref, not ComptimeValue, so no text_refs cell is created or leaked.

## T15 migration fidelity: no findings

Module is fully migrated to the owned-str model (header note line 38, clone note line 469): every text-producing site spells clone explicitly, Drop is implemented with move fn drop, and no Copy-era residue remains in-module. No silent semantic change versus the value-shaped evaluator API: share preserves value semantics while fixing the documented quadratic clone.

## T22 spec conformance: no findings

- kind_name (lines 286-303) names all 17 kinds 0-16, invalid via fallback.
- format (lines 305-380) handles every kind including struct/vec/map/enum/capability/fn/bytes/builder/chunk, with sane fallbacks for unresolved struct shape (falls to typed fallback line 378) and unknown kinds.
- equal (lines 382-467) covers every kind; invalid never equals (line 386), void always equals (line 388), range compares inclusive flag via extra_start (line 396), map pair indexing (base i asterisk 2, lines 429-439) agrees with format pair indexing (lines 353-356), so the two agree on the entry-count convention for extra_count.
- truthy (lines 279-284) and is_intlike (lines 271-274) agree on the int/bool set; truthy returns -1 sentinel for other kinds.

## Probes

- P1 seed-compiler check of module: out/bootstrap/bin/with-stage1 check src/ComptimeValue.w exit 1. Output: error: unknown method 'primitive_type_by_sym' for type '&Sema'
 --> src/Sema.w:1195:20
1195 |         let prim = self.primitive_type_by_sym(sym)
  |                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

error: unknown method 'type_decl_source_path' for type '&Sema'
 --> src/Sema.w:1318:27
1318 |             let bs_path = self.type_decl_source_path(sym)
  |                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

error: unknown method 'type_decl_source_path' for type '&Sema'
 --> src/Sema.w:1323:37
1323 |         sema_path_is_std_box_module(self.type_decl_source_path(sym))
  |                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

error: unknown method 'fn_symbol_source_path' for type '&Sema'
 --> src/Sema.w:1334:37
1334 |         sema_path_is_std_box_module(self.fn_symbol_source_path(fn_sym))
  |                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

error: unknown method 'type_decl_source_path' for type '&Sema'
 --> src/Sema.w:1340:36
1340 |         sema_path_is_std_rc_module(self.type_decl_source_path(sym))
  |                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

error: unknown method 'emit_error' for type 'Sema'
 --> src/Sema.w:1440: Status: EXECUTED.
- P2 negative control (deliberately broken /tmp/cv_neg_probe.w): exit 1. Output: error: expected pattern
 --> /tmp/cv_neg_probe.w:1:12
1 | fn broken( -> i32:
  |            ^^

error: expected ')'
 --> /tmp/cv_neg_probe.w:1:15
1 | fn broken( -> i32:
  |               ^^^

error: expected declaration (fn, type, enum, let, use, extern)
 --> /tmp/cv_neg_probe.w:1:15
1 | fn broken( -> i32:
  |               ^^^
error: check failed during compilation Status: EXECUTED.
- P3 caller/counterexample search (refutation): rg comptime_value_share and comptime_value_clone in src, per-file counts: src/ComptimeValue.w:3
src/BuildGraphMaterialize.w:1
src/ComptimeEval.w:37 Matches: src/BuildGraphMaterialize.w:43:        comptime_value_clone(self.extras.get((value.extra_start + index) as i64))
src/ComptimeValue.w:470:pub fn comptime_value_clone(v: &ComptimeValue) -> ComptimeValue:
src/ComptimeValue.w:477:// order safe; retained semantic values still use comptime_value_clone above.
src/ComptimeValue.w:478:pub fn comptime_value_share(v: &ComptimeValue) -> ComptimeValue:
src/ComptimeEval.w:1217:        out.push(comptime_value_clone(values.get(i as i64)))
src/ComptimeEval.w:1247:        options: comptime_value_clone(r.options),
src/ComptimeEval.w:1248:        migrate_options: comptime_value_clone(r.migrate_options),
src/ComptimeEval.w:1573:        comptime_value_clone(self.extra_values.get(index))
src/ComptimeEval.w:2227:            return comptime_control_value(comptime_value_share(self.slot_values.get(idx as i64)))
src/ComptimeEval.w:2255:        let base_value: ComptimeValue = comptime_value_clone(self.slot_values.get(idx as i64))
src/ComptimeEval.w:2264:                self.extra_values.push(comptime_value_clone(value))
src/ComptimeEval.w:2881:            self.extra_values.push(comptime_value_clone(payload_values.get(pi as i64)))
src/ComptimeEval.w:2900:            self.extra_values.push(comptime_value_clone(payload_values.get(pi as i64)))
src/ComptimeEval.w:3132:                self.extra_values.push(comptime_value_clone(old_key))
src/ComptimeEval.w:3134:                    self.extra_values.push(comptime_value_clone(value_signal.value))
src/ComptimeEva
- P4 runtime extern survey: files mentioning with_str_clone_ref: tools/migrate_param_borrows.w
tools/migrate_shareplace.w
tools/wrap_diag_spans.w
runtime/with_runtime.h
rt/regex_runtime.w
rt/rt_core.w
lib/std/build.w
docs/handoff.md
lib/std/regex.w
lib/std/process.w
src/ComptimeTransform.w
src/Mir.w
src/InternPool.w
src/MirLower.w
src/Sema.w
src/Archive.w
src/SemaDecl.w
src/BuildGraphModel.w
src/BuildGraphCache.w
src/Codegen.w

Note: P1/P2 outcomes recorded verbatim above; verdict COMPLETE rests on the static audit plus refutation searches, probe outputs are supporting evidence only.
