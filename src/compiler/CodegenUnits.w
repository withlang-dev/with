// Codegen units (#681): per-unit generation from MIR. MIR bodies are
// greedily packed into K size-balanced units (statement count as the cost
// proxy) BEFORE any LLVM exists; Backend.compile_units_generated then
// generates each unit's module serially (one Codegen alive at a time),
// applies the global-ownership surgery here, and writes a small per-unit
// bitcode. Threads finally parse/optimize/emit those ~1/K-size bitcodes
// concurrently (per-thread LLVMContext is the LLVM threading contract).
//
// Cross-unit resolution: would-be-internal planned functions are promoted
// to external under the reserved "__wcu$<plan-index>$" prefix at declare
// time in every unit; non-private global definitions live in unit 0 only;
// private globals stay everywhere (GlobalDCE strips the unused copies);
// appending-linkage globals (llvm.global_ctors, llvm.used) live in unit 0
// only. Unit 0 owns the canonical object path; unit k >= 1 emits
// <obj>.u<k>.o.
//
// Determinism: the assignment and per-unit pipelines are order-driven with
// no map iteration, so stage2 == stage3 holds per unit.

use compiler.LlvmBridge.*
use compiler.Runtime
use compiler.CodegenUnitsPolicy
use Mir
use std.string.parse

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_fs_remove_file(path: &str) -> i32
@[effect(fn_ptr: escape_value, ctx: escape_value)]
extern fn with_thread_spawn(fn_ptr: *mut u8, ctx: *mut u8) -> i64
extern fn with_thread_join(handle: i64) -> i32

// Explicit override; 0 means "unset — use the host-aware default".
pub fn codegen_units_env_count() -> i32:
    let raw = runtime_getenv("WITH_CODEGEN_UNITS")
    if raw.len() == 0:
        return 0
    let n = parse(raw)
    if n < 1: 1 else: if n > 64: 64 else: n

type CodegenUnitsSysInfo {
    cpu_cores: i32,
    memory_total: i64,
    page_size: i64,
}
extern fn with_sysinfo(out: *mut u8) -> i32

// Default unit count for the build-to-binary path: split only when the
// module is large enough for per-unit generation to pay for itself, and
// scale to cores. Decision policy (and why memory never caps the count)
// lives in compiler.CodegenUnitsPolicy.
pub fn codegen_units_default_count(mir_body_count: i32) -> i32:
    if mir_body_count < 2000:
        return 1
    var info = CodegenUnitsSysInfo { cpu_cores: 1, memory_total: 0, page_size: 4096 }
    let _ = with_sysinfo(&info as *mut u8)
    codegen_units_count_for(mir_body_count, info.cpu_cores)

// Emit-phase concurrency width (#681 windowing) — policy in
// compiler.CodegenUnitsPolicy; this wrapper reads the env override and
// host sysinfo.
pub fn codegen_units_emit_width(unit_count: i32, total_mir_cost: i64) -> i32:
    let raw = runtime_getenv("WITH_CODEGEN_EMIT_WIDTH")
    if raw.len() > 0:
        let n = parse(raw)
        return if n < 1: 1 else: if n > unit_count: unit_count else: n
    var info = CodegenUnitsSysInfo { cpu_cores: 1, memory_total: 0, page_size: 4096 }
    let _ = with_sysinfo(&info as *mut u8)
    let mem_total = if info.memory_total > 0: info.memory_total else: 8 as i64 * 1024 * 1024 * 1024
    codegen_units_emit_width_for(unit_count, total_mir_cost, mem_total)

// Global ownership under the multi-unit pipeline (#681): unit 0 owns
// non-private global definitions and appending-linkage arrays
// (llvm.global_ctors, llvm.used); other units keep private globals and
// reference the rest.
pub fn codegen_units_apply_global_ownership(unit_module: i64, k: i32) -> Unit:
    if k != 0:
        var g = wl_get_first_global(unit_module)
        while g != 0:
            let next = wl_get_next_global(g)
            if wl_global_has_initializer(g) != 0:
                let linkage = wl_get_linkage(g)
                if linkage == wl_appending_linkage():
                    wl_delete_global(g)
                else if linkage != wl_private_linkage():
                    if linkage == wl_internal_linkage():
                        wl_set_linkage(g, wl_external_linkage())
                    wl_clear_initializer(g)
            g = next
        return
    // Unit 0 keeps definitions, but internalized globals referenced from other
    // units must be externally visible there too.
    var g0 = wl_get_first_global(unit_module)
    while g0 != 0:
        if wl_global_has_initializer(g0) != 0 and wl_get_linkage(g0) == wl_internal_linkage():
            wl_set_linkage(g0, wl_external_linkage())
        g0 = wl_get_next_global(g0)

// Unit object path: unit 0 owns the canonical object path.
pub fn codegen_unit_object_path(obj_path: &str, k: i32) -> str:
    if k == 0: with_str_clone_ref(obj_path) else: f"{obj_path}.u{k}.o"

// #681 per-unit generation: assign MIR bodies to units BEFORE any LLVM
// exists. Cost proxy = total MIR statements per body; greedy least-loaded
// packing over the fixed MIR body order is deterministic.
pub type CodegenUnitAssign {
    unit_count: i32,
    fn_syms: Vec[i32],
    units: Vec[i32],
    // Total statement cost across all bodies — the emit window's size input.
    total_cost: i64,
}

pub fn codegen_units_assign_from_mir(mir_ptr: i64, unit_count: i32) -> CodegenUnitAssign:
    let fn_syms: Vec[i32] = Vec.new()
    let units: Vec[i32] = Vec.new()
    let bin_loads: Vec[i64] = Vec.new()
    var total_cost: i64 = 0
    var pre = 0
    while pre < unit_count:
        bin_loads.push(0)
        pre = pre + 1
    unsafe:
        let m = mir_ptr as *const MirModule
        for i in 0..(*m).bodies.len() as i32:
            let sym = (*m).body_fn_syms[i]
            let body = &(*m).bodies[i]
            var cost: i64 = 1
            for b in 0..body.block_count():
                cost = cost + body.bb_stmt_counts[b] as i64
            total_cost = total_cost + cost
            var best = 0
            var best_load = bin_loads.get(0)
            var k = 1
            while k < unit_count:
                if bin_loads[k] < best_load:
                    best = k
                    best_load = bin_loads[k]
                k = k + 1
            fn_syms.push(sym)
            units.push(best)
            let best_bin = best as i64
            with bin_loads.slot(best_bin) as mut load_slot:
                load_slot.set(best_load + cost)
    CodegenUnitAssign { unit_count, fn_syms, units, total_cost }

// One GENERATED unit: parse its own small bitcode, optimize, emit. No strip
// — bodies were filtered at generation time (#681).
fn codegen_unit_emit_generated(bc_path: &str, obj_path: &str, opt_level: i32, k: i32, do_profile: bool) -> i32:
    let t_unit = runtime_clock_nanos()
    let ctx = wl_context_create()
    let unit_module = wl_parse_bitcode_in_context(ctx, bc_path)
    if unit_module == 0:
        runtime_eprint(f"error: codegen-units generated bitcode parse failed for unit {k}")
        wl_context_dispose(ctx)
        return 1
    let tm = wl_init_target_machine(unit_module, opt_level)
    if tm == 0:
        runtime_eprint(f"error: codegen-units target machine init failed for unit {k}")
        wl_module_dispose(unit_module)
        wl_context_dispose(ctx)
        return 1
    if opt_level > 0:
        wl_optimize(unit_module, tm, opt_level)
    let unit_obj = codegen_unit_object_path(obj_path, k)
    if wl_emit_object(tm, unit_module, unit_obj) != 0:
        runtime_eprint(f"error: codegen-units emit failed for unit {k}: {unit_obj}")
        wl_dispose_target_machine(tm)
        wl_module_dispose(unit_module)
        wl_context_dispose(ctx)
        return 1
    wl_dispose_target_machine(tm)
    wl_module_dispose(unit_module)
    wl_context_dispose(ctx)
    if do_profile:
        let unit_ns = runtime_clock_nanos() - t_unit
        runtime_eprint(f"[profile] llvm.unit{k}  {unit_ns / 1000000}.{(unit_ns % 1000000) / 1000} ms")
    0

type CodegenUnitEmitJob {
    bc_path: str,
    obj_path: str,
    opt_level: i32,
    unit_index: i32,
    do_profile: i32,
    rc: i32,
}

unsafe fn codegen_unit_emit_thread_entry(arg: *mut u8) -> i32:
    let job = arg as *mut CodegenUnitEmitJob
    (*job).rc = codegen_unit_emit_generated((*job).bc_path, (*job).obj_path, (*job).opt_level, (*job).unit_index, (*job).do_profile != 0)
    0

// Optimize + emit every generated unit bitcode on its own thread, at most
// `window` in flight at once (join-oldest sliding window, the test-runner
// pattern — memory admission per codegen_units_emit_width). A failed spawn
// degrades that unit to inline execution. Removes each unit bitcode file
// on success.
pub fn codegen_units_emit_generated_all(unit_bc_paths: &Vec[str], obj_path: &str, opt_level: i32, do_profile: bool, window: i32) -> i32:
    let unit_count = unit_bc_paths.len() as i32
    var w = if window < 1: 1 else: window
    if w > unit_count:
        w = unit_count
    let jobs: Vec[CodegenUnitEmitJob] = Vec.new()
    var ji = 0
    while ji < unit_count:
        jobs.push(CodegenUnitEmitJob {
            bc_path: with_str_clone_ref(unit_bc_paths[ji]),
            obj_path: with_str_clone_ref(obj_path),
            opt_level,
            unit_index: ji,
            do_profile: if do_profile: 1 else: 0,
            rc: 0,
        })
        ji = ji + 1
    let handles: Vec[i64] = Vec.new()
    var join_rc = 0
    var next_join = 0
    var k = 0
    while k < unit_count:
        unsafe:
            let job_ptr = (jobs.ptr as *mut CodegenUnitEmitJob) + k as u64
            let handle = with_thread_spawn(codegen_unit_emit_thread_entry as *mut u8, job_ptr as *mut u8)
            if handle < 0:
                (*job_ptr).rc = codegen_unit_emit_generated((*job_ptr).bc_path, obj_path, opt_level, k, do_profile)
            else:
                handles.push(handle)
                if handles.len() as i32 - next_join >= w:
                    let rc = with_thread_join(handles[next_join])
                    if rc != 0 and join_rc == 0:
                        join_rc = rc
                    next_join = next_join + 1
        k = k + 1
    while next_join < handles.len() as i32:
        let rc = with_thread_join(handles[next_join])
        if rc != 0 and join_rc == 0:
            join_rc = rc
        next_join = next_join + 1
    var unit_rc = join_rc
    var ri = 0
    while ri < unit_count:
        if jobs[ri].rc != 0 and unit_rc == 0:
            unit_rc = jobs[ri].rc
        let _ = with_fs_remove_file(unit_bc_paths[ri])
        ri = ri + 1
    if unit_rc != 0:
        runtime_eprint(f"error: codegen-units generated emit failed with exit code {unit_rc}")
    unit_rc

pub fn codegen_unit_extra_objects(obj_path: &str, unit_count: i32) -> Vec[str]:
    let extras: Vec[str] = Vec.new()
    var k = 1
    while k < unit_count:
        extras.push(codegen_unit_object_path(obj_path, k))
        k = k + 1
    extras
