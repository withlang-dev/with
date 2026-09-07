# Primary verification — `lib/std/sys.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 106 lines (single complete read)

## Scope examined

`_ensure_init` lazy cache (`:29`), `cpu_count` (`:42`), `total_memory`
(`:47`), `page_size` (`:52`), `memory_bandwidth` (`:58`),
`_measure_bandwidth` 8 MB timed read (`:64`), `_read_pass`/`_write_pass`
with `asm volatile` optimization barriers (`:87`/`:99`). No c_import;
backing is `with_sysinfo`/`with_clock_nanos` from the runtime:
`rt/rt_core.w:3769` → platform `rt_sysinfo` (`rt/linux_x86_64.w:853`:
`sysconf(30)` pagesize, `sysconf(85)` phys-pages, `sysconf(84)`
nproc-online), `rt/rt_core.w:3541` → `rt_clock_ns`.
Callers: NONE in production — no `use std.sys` in `lib/`, `src/`, `rt/`,
`tools/`; sole importer is `test/behavior/behav_sys_info.w` (asserts
cores≥1, mem>0, ps≥4096, bw>0, second-call equality, prints `ok`).
(Sibling `std.sysinfo`/`std.time`/`std.random` declare their own separate
`with_sysinfo_os`/`with_clock_nanos` externs; not callers of this module.)
`with check lib/std/sys.w` → ok (stage1).

## Behavioral matrix (EXECUTED unless marked HELD, oracles independent)

- `docs/audit/probes/sys/s1_values.w` (prints via `print_i32`/`print_i64`):
  output `32` / `100993044480` / `4096` / `ok` — byte-exact vs three
  independent oracles: `nproc`=32 and python
  `os.sysconf('SC_NPROCESSORS_ONLN')`=32; python
  `SC_PHYS_PAGES*SC_PAGE_SIZE`=`100993044480`; `getconf PAGESIZE`=4096.
  `memory_bandwidth()>0.0` asserted (no printer for f64). PASS, twice
  (cross-process stability: identical output both runs).
- `s2_cache.w`: in-process second-call equality for all four getters
  plus lower-bound asserts. PASS.
- `test/behavior/behav_sys_info.w` via `with-stage1 run` → `ok`. PASS
  (repo's own test, unmodified).
- HELD: absolute bandwidth magnitude (no independent GB/s oracle run —
  e.g. no `dd`-based cross-measurement; only >0 and determinism verified).

## Findings

None. In-report notes (not filed — no GitHub issues filed):

- Zero production callers: the module's only consumer is its own behavior
  test. Public surface is correct but currently unused by the compiler,
  stdlib, or tools.
- `total_memory` = `SC_PHYS_PAGES × PAGESIZE` (total, not available) —
  matches the doc comment (`:46`); anyone wanting free memory must look
  elsewhere.
- `cpu_count` = `_SC_NPROCESSORS_ONLN` (online processors), not affinity-
  or cgroup-clamped count. Agrees with `nproc` (=32) and
  `sched_getaffinity` (=32) on this host; could over-report in containers.
- Bandwidth is measured once (8 MB alloc/read/free) and cached for process
  lifetime; first `cpu_count()` call pays the measurement cost.

Verdict: COMPLETE
