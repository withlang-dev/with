# Primary verification — `lib/std/zlib/minigzip.w`

Status: **INCOMPLETE** (checked clean; never behaviorally executed; not filed)
Primary verifier: primary (full source read + check execution)
Source revision: `450733e5`
Source examined: all 428 lines (single complete read).

## Scope examined

`string_copy` (`:17`), `error_` (`:52`), `gz_compress` (`:59`, fread→gzwrite
loop), `gz_uncompress` (`:94`, gzread→fwrite loop), `file_compress` (`:129`,
appends `.gz`, unlinks source), `file_uncompress` (`:176`, strips/adds
`.gz`, unlinks archive), `main` (`:248`: `gunzip`/`zcat` bname modes,
`-c`/`-d`/`-f`/`-h`/`-r`/`-1..-9` flags, default `wb6`, stdin/stdout
streaming via `gzdopen`). Global `prog` (`:428`). Callers: none in-repo
except `build/zlib.w`, which compiles it to `bin/minigzip` and runs it in
the batch-tier UAT (`:394+`).

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `with check lib/std/zlib/minigzip.w` → rc=0 (log at
  `docs/audit/probes/zlib_minigzip/check.log`).
- HELD: no `run` attempted within batch budget. Its engine calls sit on both
  sides of this audit's evidence line — `gzread` (read path) is
  oracle-verified via the gzclose probe, while `gzwrite` (its compress path)
  segfaults (gzwrite report F1), so `gz_compress`/`file_compress` currently
  have no passing execution anywhere. Destructive side effects (`unlink` of
  the source/archive) also unprobed.

## Findings

None filed. In-report notes (not filed):
- `file_compress` unconditionally `unlink`s the input after compressing
  (`:172`) — faithful to C minigzip, but any future behavioral probe must run
  in a scratch dir (as `docs/audit/probes/zlib_minigzip/` was prepared for).
- `string_copy` (`:17`) reimplements `strncpy`-with-NUL semantics by hand;
  bounds look right (`len == 0` → null; always NUL-terminates) but are
  HELD-unexecuted.

Verdict: INCOMPLETE
