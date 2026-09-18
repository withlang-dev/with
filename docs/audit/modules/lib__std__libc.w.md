# Primary verification — `lib/std/libc.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 104 lines (single complete read)

## Scope examined

`rlimit` struct (`:6`), Darwin stdio globals `__stdinp/__stdoutp/__stderrp`
(`:13`), glibc `stdin/stdout/stderr` (`:22`), `rt_libc_stdin/stdout/stderr`
externs + `libc_stdin/stdout/stderr` wrappers (`:26`), stdio externs
(`:40`: fprintf/printf/snprintf/sprintf/vsnprintf/vfprintf/vprintf,
fopen/fclose/fflush/fileno/fgets/fgetc/fputc/fputs/putc/perror/feof/ferror/
fread/fwrite), strings/locale/conversion (`:63`: strcpy/strncpy/strrchr/
strstr/strerror/strtol/strtoul/strtod/setlocale), process/time/POSIX
(`:74`: abort/exit/clock/time/isatty/mkstemp/realpath, `open/read/write/
close/lseek/unlink` wrappers over `with_libc_*` (`:87`), fcntl/getrlimit/
setrlimit), Darwin `__error` (`:104`). Backing: `rt/rt_core.w:3348`
(`with_libc_open/read/write/close/lseek/unlink`); the `pub extern fn`
surface links the system libc directly.
Callers: `use std.libc` in `lib/std/zlib/{minigzip,gzlib,gzread,example,
gzwrite}.w` and `lib/std/re/{pcre2test,pcre2posix,pcre2_maketables}.w`
(migrated C output; observed bare-call spellings: `strerror(*__error())`,
`close`, `read`, `lseek`, `snprintf`, `open`, `fcntl`); migrator inserts
`use std.libc` (`src/CiMigrate.w:291`); CImport allowlist gates resolution
through it (`src/CImport.w:16156`). `with check lib/std/libc.w` → ok
(stage1).

## Behavioral matrix (EXECUTED unless marked HELD, oracles independent)

- `docs/audit/probes/libc/p0_smoke.w`: `snprintf("%d=%s",40,"two")` returns 6,
  bytes `40=two` exact (C99 §7.19.6.5 oracle). PASS.
- `p1_strconv.w`: `strtol("12345")=12345`, `strtol("0x10",base 0)=16`,
  `strtol("-7")=-7`, `strtoul("4294967295")=4294967295`,
  `strtod("3.5")=3.5`, endptr on `"12x"` stops at `x` (120). PASS.
- `p2_stdio_file.w`: fopen/fputs/fputc/fprintf(`"%s %d\n"`→5)/fflush/
  fileno≥0/ferror=0/fclose=0, reread `fgets` line byte-exact
  `hello wn= 7\n`, `fgetc`→-1 with `feof`≠0, `strerror(2)` byte-exact
  `No such file or directory` (python `os.strerror(2)` oracle),
  `perror` observed on stderr as `audit: Success`, unlink + reopen→null.
  PASS.
- `p3_fd_io.w`: `open(O_RDWR|O_CREAT|O_TRUNC=578,0644)``→fd≥0`,
  `write`=16, `lseek(SEEK_CUR)`=16, `SEEK_SET`→0, seek(4)→4,
  `read`=8 bytes exact `456789AB`, close=0; leftover artifact
  byte-compared with `printf` oracle → ARTIFACT-MATCH. PASS.
- `p4_misc.w`: strcpy/strncpy/strstr/strrchr offsets exact
  (`world`@6, last `o`@7, miss→null), `setlocale(6,NULL)`≠null,
  `mkstemp`→fd≥0 + close + unlink round-trip, `realpath("/")`→`[47,0]`,
  `getrlimit(7)`→0 with 0<cur≤max + `setrlimit` no-op set-back→0
  (python `resource.getrlimit(RLIMIT_NOFILE)`=`(1024,524288)`,
  `ulimit -n`=`1024` corroborate structurally),
  `time()`>1700000000 (python `time.time()`=`1788531552`),
  `clock()` non-decreasing, `isatty(0)`=0 (stdin `/dev/null`). PASS.
- `p5_exit.w`: `exit(42)` → process status 42. PASS.
- `p6_abort.w`: `abort()` → status 134 (SIGABRT). PASS.
- HELD (with rationale): `vsnprintf/vprintf/vfprintf` (`va: *mut i8`
  spelling — no probe constructs a `va_list`); `sprintf` (same family as
  tested `snprintf`); `putc` (stdout-polluting; `fputc` tested);
  `fread/fwrite` (FILE* block IO; char IO + fd IO tested);
  `fcntl` (exercised only via migrated `gzlib.w`, not directly);
  non-null `setlocale` (would mutate process locale);
  Darwin `__stdinp/__stdoutp/__stderrp` + `__error` (wrong platform;
  unreferenced-extern design per `:17`).

## Findings

None. In-report notes (not filed — no GitHub issues filed):

- Two mid-audit probe failures were both probe-side logic errors, and both
  corroborate binding fidelity: asserting `SEEK_CUR==16` after a `SEEK_SET`
  to 0 (correctly returned 0), and `read` on an `O_WRONLY` fd (correctly
  EBADF −1). The binding passed flags through exactly as POSIX specifies.
- No `O_*`/`SEEK_*`/`RLIMIT_*`/`LC_*` constants are exposed; callers spell
  raw ints (`gzlib.w` uses `438` for 0666, bare fcntl cmds). Readability
  hazard at migrated call sites, not a correctness defect; the module is
  declarations-only by design (`:1`).
- `lib/std/zlib/gzread.w:71` spells `__error()` (Darwin-only symbol).
  Migrated output is documented target-specific (`:1`), so this is
  consistent, but a Linux link of that file would fail on `__error` —
  untested here, flagged for whoever links migrated zlib on Linux.

Verdict: COMPLETE
