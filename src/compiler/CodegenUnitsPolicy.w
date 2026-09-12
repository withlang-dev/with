// Pure decision policy for codegen units (#681) — no Mir/LLVM deps so
// internals tests can import it (test/internals/codegen_units_count_test.w).
// The sysinfo-reading wrappers live in compiler.CodegenUnits.

// Partition size and worker count are separate decisions. A three-core
// host still needs small units: the compiler at K=3/W=1 peaked at 13.4 GiB
// RSS; K=16/W=1 peaked at 5.5 GiB. Capping partitions at the core count
// cannot be repaired by serializing their emission. Keep small programs
// single-unit, and use bounded partitions for compiler-sized programs.
pub fn codegen_units_count_for(mir_body_count: i32) -> i32:
    if mir_body_count < 2000: 1 else: 16

// Estimated in-memory bytes per MIR statement once a unit's IR is parsed,
// optimized, and emitted (LLVMContext + module + pass working set).
// Calibrated on the compiler itself, 2026-07-18: emit-phase RSS delta over
// the frontend baseline (15.4 GB − 4.9 GB ≈ 10.5 GB) divided by
// plan_cost=289004 at K=16 → ~36.3 KB/stmt.
pub fn codegen_units_bytes_per_stmt() -> i64: 36000

// Emit-phase concurrency width (#681 windowing): during the threaded
// optimize+emit, peak memory ≈ frontend (measured 4.9 GB on the compiler;
// #682/#685 shrink it) + in-flight units × (total IR / K). Bound the
// in-flight count so that fits mem_total minus the 5 GiB frontend reserve.
// Big hosts resolve to W = K. Hosts above 8 GiB use the estimated window;
// smaller hosts serialize units to leave room for their measured peaks.
pub fn codegen_units_emit_width_for(unit_count: i32, total_mir_cost: i64, mem_total: i64) -> i32:
    if unit_count <= 1:
        return 1
    // LLVM's per-function optimization/emission peaks exceed the average
    // statement estimate. On small hosts retain headroom for that peak;
    // the 7 GiB macOS runner must not admit two units from the average.
    if mem_total <= 8 as i64 * 1024 * 1024 * 1024:
        return 1
    let budget = mem_total - 5 as i64 * 1024 * 1024 * 1024
    if budget <= 0:
        return 1
    let per_unit = (total_mir_cost * codegen_units_bytes_per_stmt()) / unit_count as i64
    if per_unit <= 0:
        return unit_count
    var w = (budget / per_unit) as i32
    if w < 1:
        w = 1
    if w > unit_count:
        w = unit_count
    w
