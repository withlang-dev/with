# macOS compiler partitions and the memory limit

The macOS jobs use a three-core, 7 GiB arm64 host. Macro run 34552488657
and ABI retry 34552490930 passed builds and fixpoints, then exhausted the
three-hour job limit in their test batteries. ABI attempt 1 had already
timed out its stage1 compiler after 1,804 seconds.

The profiling/debugger route located the oversized-work decision in
`codegen_units_count_for`: after the size gate it chose `cpu_cores`, so this
host received three compiler partitions. `codegen_units_emit_width_for`
could only reduce worker concurrency to one; it could not shrink a unit.

With the exact pinned v0.15.2.0 seed, identical ABI source, `-O1`, and one
emitter, native measurements were:

| Units | Maximum RSS (bytes) | Peak physical footprint (bytes) |
| --- | ---: | ---: |
| 3 | 14,413,676,544 | 12,241,906,512 |
| 8 | 8,681,881,600 | 6,354,950,912 |
| 16 | 5,894,586,368 | 3,514,913,544 |

These are `/usr/bin/time -l` measurements, not debug-allocation counts.
The debugger stopped the third unit at `wl_optimize` (0x10049c948) and
`wl_emit_object` (0x1007d9acc), both called from
`codegen_unit_emit_generated`; the module was 0x3b3838000. The emitted
bitcode snapshots show the actual O1 unit. Sampling the same compiler
records an 11.4 GiB peak physical footprint and LLVM SelectionDAG / machine
scheduler work under `LLVMTargetMachineEmitToFile`. Its optimized unit
contains several 16,249–19,412-line functions. This is compiler work and
memory, not a network wait or an external SDK installation.

The causal chain is: the job runs out of time; individual compilations spend
too long on a 7 GiB host; the compiler's measured peak exceeds that host;
the minimum worker window still admits oversized partitions; partition
count was incorrectly coupled to CPU count even though worker count was
already controlled independently.

Large inputs now receive 16 partitions. Small hosts emit one at a time;
larger hosts retain the existing memory-based window. The frozen seed gets
the measured 16/1 configuration for the stage1 invocation only, unless
explicit environment overrides were supplied. Ordinary test programs retain
the size gate. No timeout, optimization level, test, or memory limit changes.

The policy regression covers the 2,000-body boundary, the measured
7,553-body / 409,756-statement input, small-host windows, and larger-host
admission. Full stage, fixpoint, and native CI verification are still required.
