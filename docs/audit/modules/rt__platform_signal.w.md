# Primary verification — `rt/linux_x86_64.w` + `rt/darwin_aarch64.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: linux `57b50463c01a515184759080f587c9b234980748dc27b7223e4f76eeec46dc4c`;
darwin `158554d97b3a457a9d9ef2be76639db3bc45a53f564204b0d928c2f1f9b0f8ea`
Source examined: child both complete (1270 + 1305 lines); primary: signal
helpers :915-968 + spawn path :1001-1085 (full reads), sigaction.h header
evidence, spawn-behavior control (wave-5 process probe), `check` rc=0 both

## Scope examined

Platform backends: process spawn, signal handling, fd redirection, wait/timeout.

Applicable overview targets examined: T15 (backend correctness), T19
(platform divergence), T22 (no atomics here — libc only), T23 (failure loudness).

## Behavioral matrix

- Child's ABI probe (`signal_abi_sizes.w`): compat buf=16 vs fiber 152 —
  the size mismatch that became this finding.
- Wave-5 `process_probe` (true/false/exit42 correct) = spawning works
  despite the overflow (first word covers the blocked bits).

## SIG-001 — Darwin-sized signal structs on Linux (filed #1008)

Classification: **Confirmed stack smash + OOB read; reported as #1008**
Severity: **High** — 124 B stack write on every process spawn (default platform)
Confidence: **Very high** (branch + caller + header + precedent reads)

1. `posix_block_interrupt_signals` (:959-964): 4 B `u32` set + 4 B stack
   oldset against glibc's 128 B `sigset_t` → 124 B stack write + 124 B read,
   every `posix_run_argv` (:1059, :1079, :1083; entry points :1163-1223).
2. `posix_restore_default_signal_handler` (:953-957): 16 B buffer against
   152 B `struct sigaction` (header-verified field layout) → 136 B OOB read,
   4x per spawned child (:1049-1052).
3. Origin is Darwin copy-paste (`POSIX_SIGACTION_SIZE=16`, :924 — correct on
   Darwin); the repo's own fiber path uses 152 B (:129/:144 of
   fiber_core_darwin.w). Darwin file verified correct throughout (16 B
   struct, 4 B sigset_t are right there).

## Notes (no finding)

- Backend is libc-only (no raw syscalls): fork/execvp/wait4/pthread/mmap —
  per-platform constants (mmap flags, SIGBUS 7/10, RLIMIT_AS 9/5, dirent,
  addrinfo) verified correct by child; recorded as child evidence.
- Benign absorption today (first-word bits cover HUP/INT/TERM) explains the
  green spawn tests — layout luck, stated as such in #1008.
