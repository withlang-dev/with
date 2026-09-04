# Primary verification — `lib/std/json.w`

Status: **INCOMPLETE** (one execution-verified defect: writer emits raw control bytes)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 592 lines (two complete reads: 1–500, 489–592)

## Scope examined

Writer: `JsonWriter` (`:10`), `JsonWriter.new` (`:39`), `finish` (`:43`),
`json_escape_string` (`:50`), `json_quote` (`:70`), `prefix_value` (`:76`),
`begin_object`/`end_object`/`key` (`:85`–`:93`), `value_raw`/`value_str`/
`value_i32`/`value_i64`/`value_bool` (`:95`–`:109`), `Serialize` impls for
str/i32/i64/bool (`:111`–`:125`). No array writer, no float writer, no
`Serialize` impl for containers (grep: only four impls in file).
Tokenizer (jsmn port): `JsonParser` (`:158`, module-private),
`json_parse` (`:359`, `pub unsafe`), `JsonDocument.parse` (`:370`, fixed
256-token buffer), `JsonDocument.root` (`:381`), `JsonView.field`/`raw`
(`:394`/`:392`), `json_str`/`json_find`/`json_int`/`json_i64` (`:405`–`:479`,
all `pub` but take `*const JsonToken`), `json_unescape_string` (`:489`),
`Deserialize` impls for str/i32/i64/bool (`:537`–`:565`), `json_skip` (`:568`).
Callers: `test/behavior/behav_derive_serialize.w`,
`test/behavior/behav_derive_deserialize.w`, two derive-error tests, and
`examples/json_test.w` (stale — see F2). No compiler user of `std.json`
(ProjectConfig/LockFile/ConanClient hand-roll their own scanning).

## Behavioral matrix (oracles independent: python3 json)

- `docs/audit/probes/json/probe.w` — EXECUTED (stage1 `run`, exit 0).
  Writer object/escape/control/i32-neg/i64-bool/raw/empty outputs byte-exact
  vs `json.dumps` oracle (6/6). `JsonDocument` field extraction
  (str/i32/i64/nested/escaped `a"b\c<newline>`) all match `json.loads`
  oracle; `bool.deserialize` prints `true`; `raw()` prints `true`. PASS
  except the `\b` roundtrip (see F1).
- `docs/audit/probes/json/neg_truncated.w` — EXECUTED (exit 134,
  `panic: invalid JSON`). Truncated doc fails loudly, no stub. PASS.
- `docs/audit/probes/json/neg_unicode.w` — EXECUTED (exit 134,
  `panic: JSON unicode escapes above ASCII are not supported yet`).
  Non-ASCII `\u00e9` fails loudly, matching the documented limitation
  (`:530`). PASS (loud, not silent).
- `with check examples/json_test.w` — EXECUTED (exit 1,
  `symbol 'JsonParser' is private`). See F2.
- HELD (not executed): writer behavior for control chars other than 0x08
  (code path identical — `json_escape_string` passes through anything not
  in its 5-case list — but only `\b` was executed end to end); generic
  `Serialize` for user containers (derive path covered by repo behavior
  tests, not re-probed here).

## Findings

- F1 (defect, execution-verified): writer/reader asymmetry on control
  characters. `json_unescape_string` decodes `\b` to byte 0x08, but
  `json_escape_string` (`:50`–`:68`) only escapes `"` `\` `\n` `\r` `\t`
  and passes every other byte through raw. Probe: parse `{"s":"a\bb"}`,
  deserialize, re-serialize → output bytes `7b 22 73 22 3a 22 61 08 62
  22 7d` (xxd-verified raw 0x08). Oracle: `json.loads` on that output
  raises `Invalid control character at: line 1 column 8 (char 7)`;
  `json.dumps` produces `"a\\bb"`. So With round-trips a document it
  accepts into bytes no conforming parser accepts. Refutation attempts:
  (a) "print() mangled the byte" — refuted by xxd on the output file;
  (b) "oracle too strict" — RFC 8259 §7 mandates escaping, and the
  module's own reader enforces the same rule on input; (c) "only `\b`" —
  by code reading, `\f` (0x0C), DEL, and all other C0 controls take the
  identical pass-through branch. Not filed (audit instructions: no issues).
- F2 (stale example, execution-verified): `examples/json_test.w` no longer
  compiles — `JsonParser` is module-private and `json_parse` requires an
  `unsafe` context, but the example uses both directly
  (`check` exit 1, first error at `json_test.w:14`). It predates the
  privatization; the reachable surface is now
  `JsonWriter`/`JsonDocument`/`JsonView`/`Deserialize` only. Refutation:
  "maybe stage1 under test differs from the example's compiler" — no,
  same `out/bootstrap/bin/with-stage1` binary that runs the probes.
  Not filed.
- In-report notes (not defects): fixed 256-token buffer (`:371`) panics
  loudly on overflow (NOMEM → `json_panic("invalid JSON")`), never
  truncates silently; `json_int`/`json_i64` stop at first non-digit and
  return partial values (jsmn-faithful, documented "Returns 0 for
  non-numeric"); `pub fn json_str/json_find/json_int/json_i64` take raw
  token pointers no user code can obtain while `JsonParser` stays
  private — reachable only via `JsonView` methods, so they are
  effectively internal; writer has no array/float support by design
  (minimal surface, derive covers structs of str/i32/i64/bool).

Verdict: INCOMPLETE (F1: writer emits non-conforming bytes for control characters)

## Close-out (primary, 2026-09-04)

F1 re-executed independently (`docs/audit/probes/json/escape_ctrl.w`,
xxd bytes identical: `...61 08 62...`; `json.loads` rejects).
Filed #1060. F2 (stale example) recorded, not filed (example-only).
