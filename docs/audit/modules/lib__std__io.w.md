# Primary verification — `lib/std/io.w`

Status: **INCOMPLETE** (all fns probed except one held branch)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 74 lines (single complete read)

## Scope examined

Externs `with_print_str`/`with_println_str`/`with_println_i32`/
`with_read_line_stdin`/`with_read_bytes_stdin`/`with_write_stdout`/
`with_flush_stdout` (`:9-15`); `Stdin` + `stdin` (`:17-21`);
`print_str` (`:24`), `print_line` (`:28`), `print_int` (`:32`),
`read_line` (`:36`), `read_bytes` (`:40`), `read_all` (`:44`),
`io_strip_trailing_cr` (`:53`), `Stdin.lines` (`:59`),
`write_raw` (`:69`), `flush` (`:73`). Deps: `std.collections`
(`Vec`, `lines`), `std.string`. Callers: `src/main.w:641`
(`use std.io` injected into `-e`/`-n`/`-p` synthesis),
`src/main.w:668,679` (`stdin.lines()` loop driver), `src/Sema.w:1343`
(`std.io` tier-gated as std-only module). `src/main.w:4061`
(`cli_read_all_stdin`) re-implements the `read_all` 4096-chunk loop
instead of calling it; `src/Lsp.w:24-43` and `src/main.w:48,73`
bind the same `with_read_*` externs directly. No lib/test callers of
`print_*`/`read_*`/`write_raw`/`flush`; no io test files.

## Behavioral matrix (EXECUTED vs HELD)

- `with check lib/std/io.w` → ok (stage1). EXECUTED.
- `docs/audit/probes/io/write.w` (`print_str`/`print_line`/`print_int`/
  `write_raw`/`flush` then `MARKER`): stdout bytes observed via `od -c`
  as `a b c d e f \n 4 2 \n G H I M A R K E R \n` (20 bytes), byte-exact
  against the python3 oracle `b'abc'+b'def\n'+b'42\n'+b'GHI'+b'MARKER\n'`
  (`cmp` → `WRITE_BYTE_EXACT`). EXECUTED, PASS.
- `docs/audit/probes/io/read.w` with piped stdin
  `HELLO\nworld\ntail1\ntail2\n` (24 bytes, independent shell oracle):
  observed `first5=[HELLO]`, `rest=[]`, `all_len=18`,
  `all=[world\ntail1\ntail2\n]`, `lines_after_eof=0`. Oracle arithmetic
  (python3): 24−5=19 after `read_bytes(5)`; `read_line` consumes the
  pending `\n` → stripped → `""`; 19−1=18 for `read_all`. Closes
  exactly. EXECUTED, PASS.
- `Stdin.lines` CRLF path (`io_strip_trailing_cr`): only the EOF path
  (`lines_after_eof=0`) was exercised; no `\r\n` input probed. HELD.
- `flush()` in isolation (distinguishing flush from no-flush): called in
  write.w but with no observable contrast. HELD.

## Findings

None filed (per task: no GitHub issues from this audit). In-report notes
(each with refutation attempt):

- `rest=[]` looked wrong on first glance (expected `world`). Refuted by
  byte accounting: `read_bytes(5)` consumed `HELLO`, leaving
  `\nworld\n…`; `read_line` consumed exactly the pending newline and
  stripped it → `""`; the remaining 18 bytes (`world\ntail1\ntail2\n`)
  surfaced intact in `read_all`. Observed output matches the documented
  "strips trailing newline" semantics; not a defect.
- `cli_read_all_stdin` duplicates the `read_all` chunk loop (same 4096
  size). Refuted as a defect for this module: the compiler binary binds
  the runtime extern directly rather than depending on `std.io`; behavior
  is identical. Duplication note only.
- The print/read surface has zero lib/test callers; its only in-repo
  consumer is CLI one-liner synthesis. Coverage risk note, not a defect.

Verdict: INCOMPLETE (CRLF `lines()` branch and flush isolation held)
