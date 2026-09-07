# Audit: src/render.w @ 450733e5 (1263 lines)

## Verdict: INCOMPLETE

## Scope
- Full read of `src/render.w` lines 1–1263 (read_file limit 2000, single read, all lines observed).
- Commit confirmed: `git rev-parse --short HEAD` = `450733e5` (log: `450733e5 build: the regex runtime shim...`).
- Binary probe: `out/bootstrap/bin/with-stage1` exists; `--help` runs (commands: build/run/check/test/bench/fmt/doc/repl/lsp/migrate/...; no `dump` subcommand surfaced in first 20 lines).
- Caller search: `muse.search` for `render_module|render_decl|render_expr|render_pattern|render_type_expr|render\.w` over `src,tests` returned no hits (spec/ path does not exist); `grep -rln render tests/ spec/` returned nothing. Render appears diagnostic/dump-only with no in-repo callers to cross-check output shape.

## T13 ownership/drop
- No `drop`/`free` in module. Ownership by construction: `StringBuilder.new()` (lines 15, 431, 507, 557) consumed via `to_str()` (lines 20, 446, 524); `out = out ++ ...` rebinding is functional concat, no in-place mutation of shared strings.
- `with_str_clone_ref(prefix)` used at lines 65 (type decl), 679 (do-while), 726/751 (comprehension binding_text), 916 (pattern ident). Refutation: most `var out = prefix` sites (30, 168, 242, 295, 571, 654, 670) do NOT clone yet are safe because `++` does not mutate the aliased `prefix`. The clones are redundant but harmless (one extra ref, no use-after-free path). No defect.

## T15 migration fidelity (Stage0 surface → AstPool indices)
- Coverage is broad: all decl kinds (fn/type/use/let/extern-fn/c-import/trait/impl/poisoned), ~40 expr kinds, 13 pattern kinds, 12 type-expr kinds, helpers (type params, params, flags, indent, braces via `str_from_byte(123/125)`).
- Deterministic: pure functions of `(pool, intern, node, indent)`; no time/random/io.

## Findings
1. `src/render.w:78` — MEDIUM, T15 fidelity, probe: NOT RUN. Struct-only body branch (`if sub_kind == TypeDeclKind.Struct`) while `type_decl_is_pub` (line 1170) explicitly handles `Union` with struct body layout ("A union carries the struct body layout (Parser.parse_struct_body)"). A union decl falls through to line 152 `<unknown type decl>`. Refutation attempt: no in-repo caller or test pins union dump output (search/grep empty), so impact is dump-only; not refuted as intended — needs Parser cross-check.
2. `src/render.w:80-88` vs `src/render.w:1172` — MEDIUM, T15 fidelity, probe: NOT RUN. Field stride mismatch: renderer steps `ep = ep + 3` (name,type,default) but `type_decl_is_pub` computes `vis_idx = extra_start + 1 + field_count * 4` (stride 4). If struct extra is 4-wide per field (incl. per-field vis), the renderer desyncs after field 0. Refutation attempt: could not read Parser struct-body layout within batch budget; no caller pins field rendering. NOT refuted — needs follow-up read of `Parser.parse_struct_body`.
3. `src/render.w:48-49` vs `src/render.w:185` — LOW, T22 spec conformance, probe: NOT RUN. Zero-param `fn` renders `fn name:` (parens omitted) while `extern fn` always renders `extern fn name(...)` with parens. Round-trip/parser-acceptance of `fn name:` is unconfirmed. Refutation attempt: no dump golden files or tests reference render output; Stage0 intent unknown. NOT refuted — needs dump probe (`--help` shows no `dump` command; correct dump entry point unknown).
4. `src/render.w:306-311` — LOW, T15 fidelity, probe: NOT RUN. `NK_IMPL_DECL` renders only the header line (`impl Trait for T` / `extend T`); method bodies/assocs not rendered. Consistent with a header-only dump, but lossy vs full-fidelity pretty-printer. Refutation attempt: no caller requires impl-body rendering; severity capped at LOW.

## Probes run
- P1: `git rev-parse --short HEAD` + log — PASS (450733e5).
- P2: `out/bootstrap/bin/with-stage1 --help` — PASS (binary runs; no dump verb visible).
- P3: caller/negative-control search (`render_*` in src/tests; `grep render tests/ spec/`) — PASS with zero hits (no callers/tests pin render output).

## Negative controls
- No `drop/free` misuse possible: none present; `++` rebinding needs no clone (refutes a naive "missing clone" claim at lines 30/168/242/etc.).
- `flags` decoding differs by design: `top_level_let_type_ann` (`flags/16`, line 1195) vs `local_let_type_ann` (`flags/2`, line 1200) — different flag layouts, not a copy-paste defect.
- `NK_LABEL` dedup (lines 448-467) correctly delegates labeled while/do-while/loop/for/block to the inner renderer instead of double-printing the label.

## Close-out (primary, 2026-09-04)
- Finding 2 (stride 3-vs-4) REFUTED: `Parser.parse_struct_body` (:1750-1816)
  and `parse_struct_body_block` (:1818-~1892) both emit
  `[count, 3N triples, N aligns]`; struct/union/enum callers then append
  `is_pub, tp_start, tp_count` (e.g. :1467-1469, :1548-1552). Renderer stride
  3 covers exactly the triples; `type_decl_is_pub`'s `+1+4N` lands exactly on
  the trailing `is_pub` word in both layouts. No desync.
- Finding 1 (union -> `<unknown type decl>`) CONFIRMED by branch inventory
  (Struct :78, Alias :93, Distinct :100, Enum :106, DiscEnum :129, fallthrough
  :152) — filed #1023 (Low; no in-repo callers, dump-only surface).
- Findings 3 (zero-param parens), 4 (impl header-only) HELD as design
  judgments, not defects: no caller, golden, or spec pins the intended shape.

## Verdict: INCOMPLETE (1 Low filed as #1023; all other findings refuted/held)
