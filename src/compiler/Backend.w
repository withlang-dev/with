use Ast
use Codegen
use CodegenDispatch
use CodegenTraits
use compiler.Zcu

extern fn with_eprint(s: str) -> void
extern fn with_getenv_str(name: str) -> str
extern fn with_clock_nanos() -> i64

fn backend_debug_pool_flow_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_POOL_FLOW")
    if raw.len() == 0:
        return 0
    1

fn Zcu.compile_to_object_backend(self: Zcu, pool: AstPool, opt_level: i32, output_path: str, debug_info: bool, module_object_mode: bool, safety_checks: bool) -> i32:
    if self.last_mir_module.body_count() == 0:
        with_eprint("error: missing MIR input for LLVM backend")
        return 1
    var backend_pool = pool
    var backend_intern = self.pool
    if self.last_sema.ast.decl_count() > 0:
        backend_pool = self.last_sema.ast
    if self.last_sema.pool.state.symbol_texts.len() as i32 > 1:
        backend_intern = self.last_sema.pool
    var cg = Codegen.init_with_opt_and_intern("with_module", opt_level, backend_intern, self.last_sema)
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    cg.decl_source_paths = self.decl_source_paths
    cg.current_decl_source_file = self.current_source_path
    cg.module_object_mode = if module_object_mode: 1 else: 0
    cg.safety_checks = safety_checks
    if not debug_info:
        cg.debug_info = 0
    if self.pool.state.symbol_texts.len() as i32 <= 4 or self.last_sema.pool.state.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
        with_eprint(f"[backend] zcu.pool symbols={self.pool.state.symbol_texts.len() as i32}")
        with_eprint(f"[backend] frontend.pool symbols={self.frontend_pool.state.symbol_texts.len() as i32}")
        with_eprint(f"[backend] sema.pool symbols={self.last_sema.pool.state.symbol_texts.len() as i32}")
        with_eprint(f"[backend] backend_pool decls={backend_pool.decl_count()} sema.ast.decls={self.last_sema.ast.decl_count()}")
    if self.pool.state.symbol_texts.len() as i32 <= 4 or self.last_sema.pool.state.symbol_texts.len() as i32 <= 4 or cg.intern.state.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
        with_eprint(f"[backend] cg.intern symbols={cg.intern.state.symbol_texts.len() as i32}")
    if backend_debug_pool_flow_enabled() != 0:
        with_eprint(f"[backend-diag] pool.extra_len={backend_pool.extra_len()} pool.nodes={backend_pool.node_count()}")
        backend_dump_struct_extras(backend_pool, backend_intern)
    let do_profile = with_getenv_str("WITH_PROFILE").len() > 0
    let t_codegen = with_clock_nanos()
    let result = cg.gen_module_from_mir(self.last_mir_module, backend_pool)
    if result != 0:
        with_eprint("error: code generation failed")
        return 1
    if do_profile:
        let codegen_ns = with_clock_nanos() - t_codegen
        with_eprint(f"[profile] llvm.gen_module  {codegen_ns / 1000000}.{(codegen_ns % 1000000) / 1000} ms")
    if opt_level > 0:
        let t_opt = with_clock_nanos()
        cg.optimize(opt_level)
        if do_profile:
            let opt_ns = with_clock_nanos() - t_opt
            with_eprint(f"[profile] llvm.optimize  {opt_ns / 1000000}.{(opt_ns % 1000000) / 1000} ms")
    let t_emit = with_clock_nanos()
    let emit_result = cg.emit_object_file(output_path)
    if emit_result != 0:
        with_eprint("error: failed to emit object file")
        return 1
    if do_profile:
        let emit_ns = with_clock_nanos() - t_emit
        with_eprint(f"[profile] llvm.emit_object  {emit_ns / 1000000}.{(emit_ns % 1000000) / 1000} ms")
    0

fn Zcu.emit_ir_backend(self: Zcu, pool: AstPool, opt_level: i32) -> bool:
    if self.last_mir_module.body_count() == 0:
        with_eprint("error: missing MIR input for LLVM backend")
        return false
    var backend_pool = pool
    var backend_intern = self.pool
    if self.last_sema.ast.decl_count() > 0:
        backend_pool = self.last_sema.ast
    if self.last_sema.pool.state.symbol_texts.len() as i32 > 1:
        backend_intern = self.last_sema.pool
    var cg = Codegen.init_with_opt_and_intern("with_module", opt_level, backend_intern, self.last_sema)
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    cg.decl_source_paths = self.decl_source_paths
    cg.current_decl_source_file = self.current_source_path
    if self.pool.state.symbol_texts.len() as i32 <= 4 or self.last_sema.pool.state.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
        with_eprint(f"[backend] zcu.pool symbols={self.pool.state.symbol_texts.len() as i32}")
        with_eprint(f"[backend] frontend.pool symbols={self.frontend_pool.state.symbol_texts.len() as i32}")
        with_eprint(f"[backend] sema.pool symbols={self.last_sema.pool.state.symbol_texts.len() as i32}")
        with_eprint(f"[backend] backend_pool decls={backend_pool.decl_count()} sema.ast.decls={self.last_sema.ast.decl_count()}")
    if self.pool.state.symbol_texts.len() as i32 <= 4 or self.last_sema.pool.state.symbol_texts.len() as i32 <= 4 or cg.intern.state.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
        with_eprint(f"[backend] cg.intern symbols={cg.intern.state.symbol_texts.len() as i32}")
    let result = cg.gen_module_from_mir(self.last_mir_module, backend_pool)
    if result != 0:
        with_eprint("error: code generation failed")
        return false
    cg.print_ir()
    true

fn backend_dump_struct_extras(pool: AstPool, intern: InternPool):
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        let sub_kind = type_decl_sub_kind(pool.get_data2(decl))
        if sub_kind != TypeDeclKind.Struct:
            continue
        let name_sym = pool.get_data0(decl)
        let name = intern.resolve(name_sym)
        let es = pool.get_data1(decl)
        let fc = pool.get_extra(es)
        if fc <= 0 or fc > 100:
            with_eprint(f"[sd] BAD {name} d={decl as i32} es={es} fc={fc}")
            continue
        var ok = 1
        for fi in 0..fc:
            let o = es + 1 + fi * 3
            let tn = pool.get_extra(o + 1)
            let k = pool.kind(tn as NodeId)
            if k < 50 or k > 200:
                ok = 0
                with_eprint(f"[sd] {name} f{fi} tn={tn} k={k} es={es} o={o}")
        if ok == 1 and (name == "Codegen" or name == "ContextError"):
            with_eprint(f"[sd] OK {name} d={decl as i32} es={es} fc={fc}")

let _backend_eof_guard = 0
