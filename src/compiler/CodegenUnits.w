// Codegen units (#681): per-unit generation from MIR. MIR bodies are
// greedily packed into K size-balanced units (statement count as the cost
// proxy) BEFORE any LLVM exists; Backend.compile_units_generated then
// generates each unit's module serially (one Codegen alive at a time),
// applies the global-ownership surgery here, and hands the finished module
// with its own LLVMContext to a thread that optimizes and emits it while
// the next unit generates (per-thread LLVMContext is the LLVM threading
// contract; CodegenUnitPipeline).
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
use MirCore

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_vec_get_ptr(v: *mut u8, idx: i64) -> *mut u8
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

// Partition compiler-sized inputs independently of the available workers.
pub fn codegen_units_default_count(mir_body_count: i32) -> i32: codegen_units_count_for(mir_body_count)

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
    fn_syms: List[i32],
    units: List[i32],
    // Total statement cost across all bodies — the emit window's size input.
    total_cost: i64,
}

pub fn codegen_units_assign_from_mir(mir_ptr: i64, unit_count: i32) -> CodegenUnitAssign:
    let fn_syms: List[i32] = List.new()
    let units: List[i32] = List.new()
    let bin_loads: List[i64] = List.new()
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
            var best: i32 = 0
            var best_load = bin_loads[0]
            var k: i32 = 1
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

// Optimize and emit one unit's module, then dispose it and its context,
// which nothing else touches meanwhile (per-thread LLVMContext is LLVM's
// threading contract). No strip: bodies were filtered at generation (#681).
fn codegen_unit_emit_module(ctx: i64, unit_module: i64, obj_path: &str, opt_level: i32, k: i32, do_profile: bool) -> i32:
    let t_unit = runtime_clock_nanos()
    let tm = wl_init_target_machine(unit_module, opt_level)
    if tm == 0:
        runtime_eprint(f"error: codegen-units target machine init failed for unit {k}")
        wl_module_dispose(unit_module)
        wl_context_dispose(ctx)
        return 1
    // WITH_DUMP_LLIR_PRE: the unit as codegen built it, before any pass
    // (the promotion below crashed on a malformed GEP before the
    // single-module dump could run; WITH_CODEGEN_UNITS=1 for one unit).
    if runtime_getenv("WITH_DUMP_LLIR_PRE").len() > 0:
        runtime_eprint(f"===== PRE-PIPELINE LLVM IR (unit {k}) =====\n")
        wl_print_ir(unit_module)
        runtime_eprint(f"===== END PRE-PIPELINE LLVM IR (unit {k}) =====\n")
    // The promotion each function would have had at generation
    // (Codegen.run_mir_cleanup_passes), off the serial path.
    if wl_run_module_passes(unit_module, tm, "function(sroa,mem2reg)") != 0:
        runtime_eprint(f"error: codegen-units promotion failed for unit {k}")
        wl_dispose_target_machine(tm)
        wl_module_dispose(unit_module)
        wl_context_dispose(ctx)
        return 1
    if opt_level > 0:
        wl_optimize(unit_module, tm, opt_level)
    let unit_obj = codegen_unit_object_path(obj_path, k)
    let emit_rc = wl_emit_object(tm, unit_module, unit_obj)
    wl_dispose_target_machine(tm)
    wl_module_dispose(unit_module)
    wl_context_dispose(ctx)
    if emit_rc != 0:
        runtime_eprint(f"error: codegen-units emit failed for unit {k}: {unit_obj}")
        return 1
    if do_profile:
        let unit_ns = runtime_clock_nanos() - t_unit
        runtime_eprint(f"[profile] llvm.unit{k}  {unit_ns / 1000000}.{(unit_ns % 1000000) / 1000} ms")
    0

type CodegenUnitEmitJob {
    context: i64,
    llmod: i64,
    obj_path: str,
    opt_level: i32,
    unit_index: i32,
    do_profile: bool,
    rc: i32,
}

unsafe fn codegen_unit_emit_thread_entry(arg: *mut u8) -> i32:
    let job = arg as *mut CodegenUnitEmitJob
    (*job).rc = codegen_unit_emit_module((*job).context, (*job).llmod, (*job).obj_path, (*job).opt_level, (*job).unit_index, (*job).do_profile)
    0

// Units optimize and emit on their own threads while the next unit is
// generated: generation hands each finished module over in memory, at most
// `window` in flight (join-oldest, memory admission per
// codegen_units_emit_width). A failed spawn runs the unit inline. The jobs
// are allocated up front so no job moves while a thread reads it, and
// every started thread is joined by `finish` before the pipeline drops.
pub type CodegenUnitPipeline {
    jobs: List[CodegenUnitEmitJob],
    handles: List[i64],
    window: i32,
    next_join: i32,
    rc: i32,
}

pub fn codegen_unit_pipeline(unit_count: i32, obj_path: &str, opt_level: i32, do_profile: bool, window: i32) -> CodegenUnitPipeline:
    let jobs: List[CodegenUnitEmitJob] = List.new()
    for k in 0..unit_count:
        jobs.push(CodegenUnitEmitJob { context: 0, llmod: 0, obj_path: with_str_clone_ref(obj_path), opt_level, unit_index: k, do_profile, rc: 0 })
    let w = if window < 1: 1 else: if window > unit_count: unit_count else: window
    CodegenUnitPipeline { jobs, handles: List.new(), window: w, next_join: 0, rc: 0 }

impl CodegenUnitPipeline:
    // Unit k's module and context now belong to the pipeline.
    mut fn submit(k: i32, context: i64, llmod: i64):
        if self.handles.len() as i32 - self.next_join >= self.window:
            self.join_oldest()
        unsafe:
            let job_ptr = with_vec_get_ptr(&raw mut self.jobs as *mut u8, k as i64) as *mut CodegenUnitEmitJob
            (*job_ptr).context = context
            (*job_ptr).llmod = llmod
            // A one-unit window is a small host: no unit emits while the
            // next generates, as none did before the pipeline.
            let handle = if self.window <= 1: -1 as i64 else: with_thread_spawn(codegen_unit_emit_thread_entry as *mut u8, job_ptr as *mut u8)
            if handle < 0:
                let _ = codegen_unit_emit_thread_entry(job_ptr as *mut u8)
            else:
                self.handles.push(handle)

    mut fn join_oldest():
        let status = with_thread_join(self.handles[self.next_join])
        if status != 0 and self.rc == 0:
            self.rc = status
        self.next_join = self.next_join + 1

    // Joins every started unit; the first failing unit's code, or 0.
    mut fn finish() -> i32:
        while self.next_join < self.handles.len() as i32:
            self.join_oldest()
        for k in 0..self.jobs.len() as i32:
            if self.jobs[k].rc != 0 and self.rc == 0:
                self.rc = self.jobs[k].rc
        if self.rc != 0:
            runtime_eprint(f"error: codegen-units generated emit failed with exit code {self.rc}")
        self.rc

pub fn codegen_unit_extra_objects(obj_path: &str, unit_count: i32) -> List[str]:
    let extras: List[str] = List.new()
    var k: i32 = 1
    while k < unit_count:
        extras.push(codegen_unit_object_path(obj_path, k))
        k = k + 1
    extras
