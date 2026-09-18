# Audit — `rt/linux_aarch64.w`

Status: **COMPLETE**
Source revision: `450733e5` (HEAD verified `450733e58a1a7cce14f9cb2084943fc178815111`)
Source SHA-256: `e3f61db713d25dbf80659ed185e9b0f2b3ae6cf06feb62ff2410db76b95f219f`
Source examined: full read `rt/linux_aarch64.w` 1-1273; full read sibling
`rt/linux_x86_64.w` 1-1270 for comparison.
Host: `x86_64` — per task note, execution of this backend is impossible;
all execution-dependent probes are HELD by instruction.

## Scope examined

Applicable targets: T13 (ownership/drop), T15 (migration fidelity),
T22 (spec conformance). Full-module read plus line-by-line diff against
sibling `rt/linux_x86_64.w`.

## T15 — migration fidelity: faithful port, 3-hunk diff only

`diff rt/linux_x86_64.w rt/linux_aarch64.w` yields exactly three hunks,
and the post-divergence tails are byte-identical
(`sed` tails md5 `57d244b9b3490d90dfcbaca020afb540` on both):

1. `:1` header comment `x86_64` -> `aarch64` (cosmetic).
2. `:221-224` `LINUX_STAT_MODE_OFFSET` `24` -> `16`, with an in-code
   comment documenting the glibc difference (aarch64 `st_mode` u32@16,
   `st_nlink`@20; x86_64 `st_nlink`@16, `st_mode`@24). Size/mtime
   offsets (`48`, `88`, `96`) coincide on both ABIs and are unchanged;
   the `[144]u8` buffer safely covers the smaller (128-byte) aarch64
   `struct stat`. Correct on static review.
3. `:870` `rt_sysinfo_arch` returns `"aarch64"` instead of `"x86_64"`.
   Correct per spec.

## T13 — ownership/drop: no leak or double-close path

Every resource path is symmetric with the (host-exercised) sibling and
closes/frees on all returns: `rt_copy_file` `:501-544` frees `buf` and
closes both fds on read/write/zero/alloc failures; `rt_remove_tree`
`:469-499` closes DIR on join/child failure; `rt_copy_tree` `:546-585`
same; `rt_net_connect_any` `:719-751` frees addrinfo on success and
exhaustion; `with_net_recv` `:830-846` frees on `r<=0` and after copy.
No aarch64-divergent ownership logic exists (zero diff in these regions).

## T22 — spec conformance: conventions preserved

Negative-errno returns, EINTR(`4`)-retry loops, canonical-to-Linux
O-flag translation (`:184-199`), `mmap` flags `0x22`, sysconf keys
(`30`/`84`/`85`), `clock_gettime` ids — all byte-identical to sibling.

## Findings

1. `rt/linux_aarch64.w:927` (`POSIX_SIGACTION_SIZE = 16`) used for the
   `[16]u8` buffer in `posix_restore_default_signal_handler` `:956-960`,
   while the fiber path uses a 152-byte `sigaction` (`:129`, `:144`) —
   SEVERITY: note only / TARGET: T22 / PROBE STATUS: static review only,
   HELD for runtime. REFUTATION: byte-identical in sibling
   `rt/linux_x86_64.w:924,953-957`; not an aarch64 regression and out of
   this module's diff scope. No defect filed against this module
   (fix, if ever, belongs to shared scope; no issue filed per instruction).
2. `rt/linux_aarch64.w:224` `LINUX_STAT_MODE_OFFSET = 16` — SEVERITY: none
   (correct on review) / TARGET: T15 / PROBE STATUS: HELD (no aarch64
   execution; no `aarch64-linux-gnu-gcc` on host). REFUTATION ATTEMPTED:
   host glibc control probe confirms the sibling's `24` on x86_64, and
   the aarch64 value matches the documented glibc aarch64 layout
   (`st_mode`@16, `st_size`@48, `st_mtim`@88/96, struct <= 144 bytes).
   Consistent; cannot execute here.
3. Carried-over ABI constants (`sigaction` 152 / `sa_flags`@136 at
   `:129-149`; `stack_t` 24 at `:137-142`; `LINUX_DIRENT_NAME_OFFSET = 19`
   at `:372`; fault-addr +16 at `:114-118`) — SEVERITY: none on review /
   TARGET: T15+T22 / PROBE STATUS: HELD for aarch64 runtime. REFUTATION
   ATTEMPTED: host control probe confirms each value on glibc x86_64
   (`sigaction_size=152 sa_flags_off=136 stack_t_size=24`); these layouts
   are arch-shared in glibc (`sigaction`, `stack_t`, `dirent`, `siginfo`
   `si_addr`@16). No divergence to file.
4. `rt/linux_aarch64.w:870` arch string `"aarch64"` — SEVERITY: none /
   TARGET: T22 / PROBE STATUS: static (string literal; no runtime needed).
   Correct; wired via `build.w:93-130`, `src/compiler/Frontend.w:170`
   (`kind == 2`), `src/compiler/Link.w:726-727,1155,1172`.

## Probes run

- P1 `diff rt/linux_x86_64.w rt/linux_aarch64.w` — 3 hunks only (listed above).
- P2 `out/bootstrap/bin/with-stage1 check rt/linux_aarch64.w` — `ok`, rc=0.
- P3 host glibc `offsetof` control (`cc`+run on x86_64): `stat_size=144
  mode_off=24 size_off=48 mtim_sec=88 mtim_nsec=96`,
  `sigaction_size=152 sa_flags_off=136 stack_t_size=24` — matches sibling
  exactly, validating the constants and the probe method.
- P4 caller trace via repo search: `build.w:85-130,404-409,623-630,2046-2053`
  selects `rt/linux_aarch64.w` + `fiber_asm_linux_aarch64.s` for the
  `linux_aarch64` tag; `Frontend.w:170`, `Link.w` embed
  `rt_linux_aarch64.o`. Wiring intact.

## Negative controls

- N1 host control (P3) reproduces the *sibling's* offsets, proving the
  probe discriminates rather than rubber-stamps.
- N2 `command -v aarch64-linux-gnu-gcc` — absent: no cross-compile
  execution probe possible.
- N3 `uname -m` = `x86_64`: native execution of the aarch64 backend is
  impossible; all execution-dependent checks HELD per task instruction,
  not waived.

## Verdict: COMPLETE — no live defect; execution-dependent probes HELD
