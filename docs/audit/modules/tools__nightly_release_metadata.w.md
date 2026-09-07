# Primary verification — `tools/nightly_release_metadata.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-tools-misc (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 84 lines (single complete read)

## Scope examined

Generates immutable nightly/test release metadata for GitHub Actions
(run facts in, wording in With): strict 13-arg argv gate (`:14`),
sha>=12 and non-empty-platforms guards (`:32`/`:35`), schedule-event
channel override (`:40`-`:41`), tag/title per channel — test
(`:46`-`:48`), nightly (`:49`-`:51`), release (`:52`-`:54`) —
`$GITHUB_OUTPUT` append preserving prior content (`:60`-`:66`), release
notes body (`:68`-`:83`). All writes go to caller-supplied paths only.
Implicit-main style, so `with check` rejection is expected, not a defect.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED, `with-stage1 check` → exit 1,
  `expected declaration ...` at `:14` (implicit main; same on stage2).
  Not a defect. Saved: `docs/audit/probes/tools_nightly_release_metadata/check.txt`.
- EXECUTED, no-args run → usage line, exit 1.
  Saved: `docs/audit/probes/tools_nightly_release_metadata/noargs.txt`.
- EXECUTED, test channel → exit 0;
  `channel=test`, `tag=nightly-test-12345-1`,
  `title=Disposable nightly release test 12345.1`; notes open with
  `Automated test compiler prerelease.` plus source commit, workflow
  URL, version, platforms, contents, and per-platform gates.
  Saved: `run_test.txt`, `github.out`, `notes.md`.
- EXECUTED, schedule override (event=`schedule`, requested=`test`) →
  `channel=nightly`, `tag=nightly-20260904-777-1-450733e58a1a`,
  `title=With nightly 2026-09-04 (450733e58a1a)`. Override proven.
  Saved: `run_override.txt`, `github3.out`, `notes4.md`.
- EXECUTED, release channel → `channel=release`, `tag=2.0.0`
  (version verbatim), `title=With 2.0.0`,
  notes open `Automated compiler release.`. Saved: `github4.out`, `notes5.md`.
- EXECUTED, bad channel → `error: unsupported release channel: bogus`,
  exit 1. Short sha → `error: source commit must contain at least 12
  characters`, exit 1. Saved: `run_badchan.txt`, `run_shortsha.txt`.
- HELD: empty-platforms guard (`:35`) — 2-line `len() == 0` check, no
  run; and prior-content preservation append (read-then-write shape is
  visible at `:60`-`:66` and the outputs show correct content).

## Findings

None. In-report notes (not filed):
- `write_file` failures `exit_code(1)` without returning, matching the
  tool's fail-fast shape; fine for a CI leaf.

Verdict: COMPLETE
