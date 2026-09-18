// Pure decision policy for codegen units (#681) — no Mir/LLVM deps so
// internals tests can import it (test/internals/codegen_units_count_test.w).
// The sysinfo-reading wrappers live in compiler.CodegenUnits.

// Unit count: size gate, then cores, clamped at 16. Memory does NOT cap the
// count — measured peaks are K-independent when every unit optimizes at
// once (13.2 GB @ K=8, 15.5 GB @ K=16, 15.3 GB @ K=5 on the compiler),
// because in-flight IR totals the whole program however it is sliced.
// More, smaller units only shrink the serial-gen spike. Memory instead
// bounds emit CONCURRENCY — codegen_units_emit_width_for below.
pub fn codegen_units_count_for(mir_body_count: i32, cpu_cores: i32) -> i32:
    if mir_body_count < 2000:
        return 1
    var k = if cpu_cores > 0: cpu_cores else: 1
    if k > 16:
        k = 16
    k

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
// Big hosts resolve to W = K (all units concurrent — today's behavior);
// an 8 GB host runs a few units at a time instead of dying.
pub fn codegen_units_emit_width_for(unit_count: i32, total_mir_cost: i64, mem_total: i64) -> i32:
    if unit_count <= 1:
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
