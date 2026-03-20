use Ast
use Codegen
use compiler.Zcu

extern fn with_eprintln(s: str) -> void
extern fn with_getenv_str(name: str) -> str
extern fn int_to_string(n: i32) -> str

fn backend_debug_pool_flow_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_POOL_FLOW")
    if raw.len() == 0:
        return 0
    1

fn Zcu.compile_to_object_backend(self: Zcu, pool: AstPool, opt_level: i32, output_path: str, debug_info: bool) -> i32:
    if self.last_mir_module.body_count() == 0:
        with_eprintln("error: missing MIR input for LLVM backend")
        return 1
    var backend_pool = pool
    var backend_intern = self.pool
    if self.last_sema.ast.decl_count() > 0:
        backend_pool = self.last_sema.ast
    if self.last_sema.pool.symbol_texts.len() as i32 > 1:
        backend_intern = self.last_sema.pool
    var cg = Codegen.init_with_opt_and_intern("with_module", opt_level, backend_intern, self.last_sema)
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    cg.decl_source_paths = self.decl_source_paths
    cg.current_decl_source_file = self.current_source_path
    if not debug_info:
        cg.debug_info = 0
    if self.pool.symbol_texts.len() as i32 <= 4 or self.last_sema.pool.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
        with_eprintln("[backend] zcu.pool symbols=" ++ int_to_string(self.pool.symbol_texts.len() as i32))
        with_eprintln("[backend] frontend.pool symbols=" ++ int_to_string(self.frontend_pool.symbol_texts.len() as i32))
        with_eprintln("[backend] sema.pool symbols=" ++ int_to_string(self.last_sema.pool.symbol_texts.len() as i32))
        with_eprintln("[backend] backend_pool decls=" ++ int_to_string(backend_pool.decl_count()) ++ " sema.ast.decls=" ++ int_to_string(self.last_sema.ast.decl_count()))
    if self.pool.symbol_texts.len() as i32 <= 4 or self.last_sema.pool.symbol_texts.len() as i32 <= 4 or cg.intern.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
        with_eprintln("[backend] cg.intern symbols=" ++ int_to_string(cg.intern.symbol_texts.len() as i32))
    if backend_debug_pool_flow_enabled() != 0:
        with_eprintln("[backend-diag] pool.extra_len=" ++ int_to_string(backend_pool.extra_len()) ++ " pool.nodes=" ++ int_to_string(backend_pool.node_count()))
        backend_dump_struct_extras(backend_pool, backend_intern)
    let result = cg.gen_module_from_mir(self.last_mir_module, backend_pool)
    if result != 0:
        with_eprintln("error: code generation failed")
        return 1
    if opt_level > 0:
        cg.optimize(opt_level)
    let emit_result = cg.emit_object_file(output_path)
    if emit_result != 0:
        with_eprintln("error: failed to emit object file")
        return 1
    0

fn Zcu.emit_ir_backend(self: Zcu, pool: AstPool, opt_level: i32) -> bool:
    if self.last_mir_module.body_count() == 0:
        with_eprintln("error: missing MIR input for LLVM backend")
        return false
    var backend_pool = pool
    var backend_intern = self.pool
    if self.last_sema.ast.decl_count() > 0:
        backend_pool = self.last_sema.ast
    if self.last_sema.pool.symbol_texts.len() as i32 > 1:
        backend_intern = self.last_sema.pool
    var cg = Codegen.init_with_opt_and_intern("with_module", opt_level, backend_intern, self.last_sema)
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    cg.decl_source_paths = self.decl_source_paths
    cg.current_decl_source_file = self.current_source_path
    if self.pool.symbol_texts.len() as i32 <= 4 or self.last_sema.pool.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
        with_eprintln("[backend] zcu.pool symbols=" ++ int_to_string(self.pool.symbol_texts.len() as i32))
        with_eprintln("[backend] frontend.pool symbols=" ++ int_to_string(self.frontend_pool.symbol_texts.len() as i32))
        with_eprintln("[backend] sema.pool symbols=" ++ int_to_string(self.last_sema.pool.symbol_texts.len() as i32))
        with_eprintln("[backend] backend_pool decls=" ++ int_to_string(backend_pool.decl_count()) ++ " sema.ast.decls=" ++ int_to_string(self.last_sema.ast.decl_count()))
    if self.pool.symbol_texts.len() as i32 <= 4 or self.last_sema.pool.symbol_texts.len() as i32 <= 4 or cg.intern.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
        with_eprintln("[backend] cg.intern symbols=" ++ int_to_string(cg.intern.symbol_texts.len() as i32))
    let result = cg.gen_module_from_mir(self.last_mir_module, backend_pool)
    if result != 0:
        with_eprintln("error: code generation failed")
        return false
    cg.print_ir()
    true

fn backend_dump_struct_extras(pool: AstPool, intern: InternPool):
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NK_TYPE_DECL:
            continue
        let sub_kind = type_decl_sub_kind(pool.get_data2(decl))
        if sub_kind != TDK_STRUCT:
            continue
        let name_sym = pool.get_data0(decl)
        let name = intern.resolve(name_sym)
        let es = pool.get_data1(decl)
        let fc = pool.get_extra(es)
        if fc <= 0 or fc > 100:
            with_eprintln("[sd] BAD " ++ name ++ " d=" ++ int_to_string(decl) ++ " es=" ++ int_to_string(es) ++ " fc=" ++ int_to_string(fc))
            continue
        var ok = 1
        for fi in 0..fc:
            let o = es + 1 + fi * 3
            let tn = pool.get_extra(o + 1)
            let k = pool.kind(tn)
            if k < 50 or k > 200:
                ok = 0
                with_eprintln("[sd] " ++ name ++ " f" ++ int_to_string(fi) ++ " tn=" ++ int_to_string(tn) ++ " k=" ++ int_to_string(k) ++ " es=" ++ int_to_string(es) ++ " o=" ++ int_to_string(o))
        if ok == 1 and (name == "Codegen" or name == "ContextError"):
            with_eprintln("[sd] OK " ++ name ++ " d=" ++ int_to_string(decl) ++ " es=" ++ int_to_string(es) ++ " fc=" ++ int_to_string(fc))

let _backend_eof_guard = 0
