use Ast
use Lexer
use Parser
use Source
use Sema
use SemaDecl
use SemaCheck
use SemaDiag
use ComptimeTransform
use Resolve
use Span
use Diagnostic
use CImport
use render
use compiler.EmbeddedStdlib
use compiler.EmbeddedRuntime
use compiler.EmbeddedClangResource
use TargetSpec

extern fn with_str_clone_ref(s: &str) -> str
use compiler.ProjectConfig
use compiler.Runtime
use compiler.TrackedInputs
use compiler.Zcu
// Frontend pipeline: lex -> parse -> import resolution -> sema.

var frontend_cimport_compiler_fingerprint_ready: i32 = 0
var frontend_cimport_compiler_fingerprint: str = ""
var frontend_cimport_lock_word: Atomic[i32]

fn frontend_cimport_lock():
    var spins = 0
    while frontend_cimport_lock_word.swap(1, .Acquire) != 0:
        spins = spins + 1
        if spins >= 1024:
            let _ = runtime_nanosleep(1000)
            spins = 0

fn frontend_cimport_unlock():
    frontend_cimport_lock_word.store(0, .Release)

fn frontend_owned_text(text: &str) -> str:
    if text.len() == 0:
        return ""
    runtime_str_clone(text)

fn frontend_new_vec_str -> Vec[str]:
    let out: Vec[str] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 16 }
    out

fn frontend_normalize_source_text(text: &str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    var i = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 13:
            if i + 1 < text.len() as i32 and text.byte_at((i + 1) as i64) == 10:
                i = i + 1
            out.push_byte(10 as u8)
        else:
            out.push_byte(ch as u8)
        i = i + 1
    out.to_str()

fn frontend_str_contains_byte(text: &str, target: i32) -> bool:
    for i in 0..text.len():
        if text.byte_at(i as i64) == target:
            return true
    false

fn frontend_resolve_executable_path(argv0: &str) -> str:
    if argv0.len() == 0:
        return ""
    if runtime_read_file(argv0).len() > 0:
        return with_str_clone_ref(argv0)
    if frontend_str_contains_byte(argv0, 47):
        return ""

    let search_path = runtime_getenv("PATH")
    if search_path.len() == 0:
        return ""

    var segment_start = 0
    var i = 0
    while i <= search_path.len() as i32:
        let at_end = i == search_path.len() as i32
        let ch = if at_end: 58 else: search_path.byte_at(i as i64)
        if ch == 58:
            let dir = search_path.slice(segment_start as i64, i as i64)
            let candidate = if dir.len() == 0: "./" ++ argv0 else: dir ++ "/" ++ argv0
            if runtime_read_file(candidate).len() > 0:
                return candidate
            segment_start = i + 1
        i = i + 1
    ""

fn frontend_cimport_compiler_fingerprint_line() -> str:
    if frontend_cimport_compiler_fingerprint_ready != 0:
        // #761 instance 2: independent copy, never the global's own header.
        return frontend_cimport_compiler_fingerprint ++ ""
    frontend_cimport_compiler_fingerprint_ready = 1
    let compiler_path = frontend_resolve_executable_path(runtime_arg_at(0))
    if compiler_path.len() == 0:
        return ""
    let compiler_image = runtime_read_file(compiler_path)
    if compiler_image.len() == 0:
        return ""
    frontend_cimport_compiler_fingerprint = frontend_owned_text(f"\n#compiler-hash:{runtime_str_hash(compiler_image)}")
    frontend_cimport_compiler_fingerprint ++ ""

fn c_import_absolute_quoted_path(header_spec: &str) -> str:
    let decoded = c_import_trim(c_import_decode_escapes(header_spec))
    if decoded.len() < 3:
        return ""
    if decoded.byte_at(0) != 34 or decoded.byte_at(decoded.len() as i64 - 1) != 34:
        return ""
    let path = decoded.slice(1, decoded.len() - 1)
    if path.len() == 0 or path.byte_at(0) != 47:
        return ""
    path

impl Zcu:
    mut fn record_frontend_tracked_input(path: &str):
        if path.len() == 0:
            return
        if runtime_read_file(path).len() == 0:
            return
        // #747 instance C: capture by move, not copy — an unspelled field
        // read left the field's stale Vec header live while insert_unique
        // consumed (and freed) the buffer; the NEXT call iterated recycled
        // memory (release-lane c_import SEGV: quoted-path text read as a
        // str header in tracked_input_str_compare).
        var paths = move self.tracked_input_paths
        self.tracked_input_paths = tracked_input_insert_unique(move paths, path)

fn count_non_use_decls_frontend(pool: AstPool) -> i32:
    var count = 0
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_USE_DECL:
            count = count + 1
    count

impl Zcu:
    mut fn emit_missing_import_frontend(pool: AstPool, decl: i32):
        let span = Span {
            file: 0,
            start: pool.get_start(decl),
            end: pool.get_end(decl),
        }
        self.diagnostics.emit(Diagnostic.err("import module not found", span))

fn frontend_rt_in_unit_enabled() -> i32:
    if runtime_getenv("WITH_RT_IN_UNIT").len() > 0: 1 else: 0

fn frontend_rt_in_unit_platform_file() -> str:
    var kind = target_spec_active_kind()
    if kind == 0:
        kind = target_spec_host_kind()
    if kind == 1: return "rt/linux_x86_64.w"
    if kind == 2: return "rt/linux_aarch64.w"
    if kind == 4: return "rt/darwin_aarch64.w"
    if kind == 5: return "rt/windows_x86_64.w"
    if kind == 6: return "rt/windows_aarch64.w"
    ""

fn c_import_str_contains(text: &str, needle: &str) -> bool:
    if needle.len() == 0:
        return true
    if needle.len() > text.len():
        return false
    var i = 0
    let limit = text.len() as i32 - needle.len() as i32
    while i <= limit:
        if text.slice(i as i64, (i + needle.len() as i32) as i64) == needle:
            return true
        i = i + 1
    false

impl Zcu:
    fn read_trace_c_import_cache_frontend() -> i32:
        let _ = self
        let raw = runtime_getenv("WITH_TRACE_CIMPORT_CACHE")
        if raw.len() == 0:
            return 0
        if raw == "0":
            return 0
        1

fn frontend_debug_type_names_enabled() -> i32:
    let raw = runtime_getenv("WITH_DEBUG_TYPE_NAMES")
    if raw.len() == 0:
        return 0
    if raw == "0":
        return 0
    1

fn frontend_dump_type_decl_names(stage: &str, pool: AstPool, intern: InternPool):
    if frontend_debug_type_names_enabled() == 0:
        return
    runtime_eprint(f"[type-names] stage={stage} decls={pool.decl_count()}")
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        let sub_kind = type_decl_sub_kind(pool.get_data2(decl))
        var kind_name = "alias"
        if sub_kind == TypeDeclKind.Struct:
            kind_name = "struct"
        else if sub_kind == TypeDeclKind.Enum:
            kind_name = "enum"
        else if sub_kind == TypeDeclKind.DiscEnum:
            kind_name = "disc_enum"
        else if sub_kind == TypeDeclKind.Distinct:
            kind_name = "distinct"
        let name_sym = pool.get_data0(decl)
        let name = intern.resolve(name_sym)
        let msg = f"[type-names] {stage} decl={di} node={decl as i32} kind={kind_name} name_sym={name_sym} name={name}"
        runtime_eprint(msg)

impl Sema:
    mut fn init_module_graph(resolved: &ResolveResult) -> Unit:
        self.module_paths = sema_new_vec_str()
        self.module_import_starts = sema_new_vec_i32()
        self.module_import_counts = sema_new_vec_i32()
        self.module_import_targets = sema_new_vec_i32()
        self.module_import_paths = sema_new_vec_str()
        self.module_index_by_path = HashMap.new()
        self.global_visible_module_paths = HashMap.new()
        self.module_visibility_cache = HashMap.new()

        for mi in 0..resolved.modules.len() as i32:
            let mod = resolved.modules.get(mi as i64)
            let owned_path = frontend_owned_text(mod.path)
            self.module_paths.push(owned_path)
            self.module_import_starts.push(self.module_import_targets.len() as i32)
            var visible_count = 0
            for ii in 0..mod.import_count:
                let imp = resolved.imports.get((mod.import_start + ii) as i64)
                if imp.target_module >= 0:
                    self.module_import_targets.push(imp.target_module)
                    self.module_import_paths.push(frontend_owned_text(imp.path_text))
                    visible_count = visible_count + 1
            self.module_import_counts.push(visible_count)
            self.module_index_by_path.insert(frontend_owned_text(mod.path), mod.module_id)
        if resolved.modules.len() > 0:
            let global_frontier: Vec[i32] = Vec.new()
            let root = resolved.modules.get(0)
            for ii in 0..root.import_count:
                let imp = resolved.imports.get((root.import_start + ii) as i64)
                if imp.target_module < 0:
                    continue
                if imp.path_text == "std.prelude" or imp.path_text == "std.prelude_core" or imp.path_text == "std.prelude_alloc":
                    global_frontier.push(imp.target_module)
            let seen_global: HashMap[i32, i32] = HashMap.new()
            while global_frontier.len() as i32 > 0:
                let last = global_frontier.len() as i32 - 1
                let mid: i32 = global_frontier.get(last as i64)
                global_frontier.pop()
                if seen_global.contains(mid):
                    continue
                seen_global.insert(mid, 1)
                let mod = resolved.modules.get(mid as i64)
                self.global_visible_module_paths.insert(frontend_owned_text(mod.path), 1)
                for ii in 0..mod.import_count:
                    let imp = resolved.imports.get((mod.import_start + ii) as i64)
                    if imp.target_module >= 0:
                        global_frontier.push(imp.target_module)

impl Zcu:
    mut fn expand_c_imports_frontend(pool: AstPool) -> AstPool:
        var out = pool
        let ordered: Vec[i32] = Vec.new()
        let ordered_paths = frontend_new_vec_str()
        let ordered_file_ids: Vec[i32] = Vec.new()
        let ordered_ci: Vec[i32] = Vec.new()
        let base_count = out.decl_count()
        var has_c_import = 0
        var c_import_count = 0
        for i in 0..base_count:
            let decl = out.get_decl(i)
            if out.kind(decl) == NodeKind.NK_C_IMPORT:
                has_c_import = 1
                c_import_count = c_import_count + 1
        if has_c_import == 0:
            return out

        // CImport, CiMigrate, and the clang bridge still own process-global
        // mutable session state. Parallel workspaces may compile ordinary With
        // code concurrently, but c_import expansion must remain serialized until
        // those globals move behind explicit session handles.
        frontend_cimport_lock()
        // Emitted names deduplicate declarations only within this compilation.
        // `with test` can compile several targets in one process, so carrying the
        // bridge table across Zcu instances would make a later single-import cache
        // entry omit the required C support prelude.
        with_cimport_reset_names()

        // Materialize clang's builtin headers embedded in this binary before
        // libclang parses anything, so c_import is self-contained at runtime (#312).
        // (Also keeps the materializer in the compile graph for the bridge's
        // with_ensure_clang_resource_dir extern.)
        let _resource_dir = ensure_clang_resource_dir()
        self.record_frontend_tracked_input(ensure_clang_resource_identity_file())

        // Pass project config include paths to clang bridge. Always rebuild the
        // list (clear+set) so a prior compile in the same process — `with test`
        // runs many — cannot leak stale include dirs.
        ci_set_include_paths(self.project_config.c_import_include_paths)
        // Native Windows: libclang has no default system-header search path, so
        // add the MSVC CRT + Windows SDK include dirs (WITH_WINDOWS_*_INCDIR).
        // No-op off Windows / when unset; include-side analog of the
        // WITH_WINDOWS_*_LIBDIR link wiring.
        ci_add_windows_system_includes()
        // §16.1: pass the configured target SDK sysroot (empty resets any prior).
        ci_set_sdk_path(self.project_config.c_import_sdk_path)

        for i in 0..base_count:
            let decl = out.get_decl(i)
            if out.kind(decl) != NodeKind.NK_C_IMPORT:
                ordered.push(decl as i32)
                ordered_paths.push(frontend_owned_text(self.decl_source_path_frontend(i)))
                ordered_file_ids.push(self.decl_source_file_id_frontend(i))
                let ci_f = if i < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(i as i64) else: 0
                ordered_ci.push(ci_f)
                continue

            // Preserve the original c_import declaration as an ownership marker so
            // later sema passes can still tell which modules directly use c_import,
            // even if header expansion is deduplicated elsewhere in the merged AST.
            ordered.push(decl as i32)
            ordered_paths.push(frontend_owned_text(self.decl_source_path_frontend(i)))
            ordered_file_ids.push(self.decl_source_file_id_frontend(i))
            ordered_ci.push(0)

            let header_sym = out.get_data0(decl)
            let header_spec: str = with_str_clone_ref(self.pool.resolve(header_sym))
            let decl_dir = self.decl_source_dir_frontend(i)
            let resolved_header_spec = project_config_resolve_c_import_header(self.project_config, decl_dir, header_spec)
            self.record_frontend_tracked_input(c_import_absolute_quoted_path(resolved_header_spec))
            let cache_key = self.c_import_cache_key_frontend(out, decl, resolved_header_spec)

            var synthetic = ""
            let cached = self.c_import_cache_lookup(cache_key)
            if cached.len() > 0:
                // Already injected in this compilation — skip to avoid duplicate declarations
                if self.trace_c_import_cache != 0:
                    runtime_eprint("c_import cache hit (memory) — skipping duplicate")
                continue
            else:
                // CImport output is context-sensitive because generation deduplicates
                // shared declarations across all c_imports in a compilation. A cached
                // expansion is only reusable when this compilation has exactly one
                // c_import; otherwise generate in-order so the dedup table is truthful.
                let fs_cached = if c_import_count == 1: c_import_fs_cache_lookup(cache_key) else: ""
                if fs_cached.len() > 0:
                    if self.trace_c_import_cache != 0:
                        runtime_eprint("c_import cache hit (fs)")
                    synthetic = fs_cached
                    self.c_import_cache_store(cache_key, synthetic)
                    // Populate dedup table so subsequent c_imports don't re-emit these names
                    ci_mark_cached_names(synthetic)
                    // The cached translation depends on every header in its manifest;
                    // track them so incremental builds re-translate on header changes.
                    let hit_dep_paths = c_import_deps_manifest_paths(c_import_fs_cache_deps_manifest(cache_key))
                    for dpi in 0..hit_dep_paths.len() as i32:
                        self.record_frontend_tracked_input(hit_dep_paths.get(dpi as i64))
                else:
                    if self.trace_c_import_cache != 0:
                        runtime_eprint("c_import cache miss")
                    let libclang_header_spec = c_import_decode_escapes(resolved_header_spec)
                    // §16.2a: apply no_methods opt-out for this import before generation.
                    let nm_packed = out.get_data2(decl)
                    let nm_start = out.get_data1(decl)
                    let nm_base = nm_start + c_import_link_count(nm_packed) + c_import_allow_count(nm_packed)
                    let nm_types = frontend_new_vec_str()
                    for nmi in 0..c_import_no_methods_count(nm_packed):
                        nm_types.push(frontend_owned_text(self.pool.resolve(out.get_extra(nm_base + nmi))))
                    ci_set_no_methods(c_import_no_methods_all(nm_packed), move nm_types)
                    // #357: register this import's ownership annotations for the
                    // duration of translation (annotation evidence, §16.3c).
                    let ann_owns = frontend_new_vec_str()
                    for aoi in 0..self.c_import_owns_count_frontend(out, decl):
                        ann_owns.push(frontend_owned_text(self.c_import_owns_entry_frontend(out, decl, aoi)))
                    let ann_borrows = frontend_new_vec_str()
                    for abi in 0..self.c_import_borrows_count_frontend(out, decl):
                        ann_borrows.push(frontend_owned_text(self.c_import_borrows_entry_frontend(out, decl, abi)))
                    ci_set_owned_annotations(move ann_owns, move ann_borrows)
                    let libclang_result = process_c_import_with_defines(libclang_header_spec, self.project_config.c_import_defines)
                    ci_clear_owned_annotations()
                    ci_clear_no_methods()
                    if self.trace_c_import_cache != 0 and libclang_result.len() > 0:
                        runtime_eprint("c_import generated:")
                        runtime_eprint(libclang_result)
                    if libclang_result.len() > 0:
                        synthetic = libclang_result
                        let gen_dep_paths = cimport_deps_sorted_unique_paths(c_import_included_files())
                        for dpi in 0..gen_dep_paths.len() as i32:
                            self.record_frontend_tracked_input(gen_dep_paths.get(dpi as i64))
                    else:
                        let libclang_error = c_import_last_error()
                        if libclang_error.len() > 0:
                            self.c_import_emit_header_error_detail_frontend(decl, header_spec, libclang_error)
                            continue
                        else:
                            synthetic = self.c_import_expand_header_spec_frontend(header_spec, out, decl)
                            if self.diagnostics.has_errors():
                                continue
                    self.c_import_cache_store(cache_key, synthetic)
                    // Store to file-system cache only when the expansion is not shaped
                    // by another c_import's dedup state.
                    if synthetic.len() > 0 and c_import_count == 1:
                        c_import_fs_cache_store(cache_key, synthetic)

            if synthetic.len() == 0:
                continue
            self.c_import_record_omissions_frontend(synthetic)

            let before = out.decl_count()
            var lexer = Lexer.init(synthetic, 0)
            let tokens = lexer.tokenize()
            var parser = Parser.init_with_pool(move tokens, synthetic, 0, self.pool, move self.diagnostics, out)
            out = parser.parse_module()
            self.pool = parser.intern
            self.diagnostics = move parser.diags

            let after = out.decl_count()
            // Mark all c_import-synthesized declarations
            let ci_owner_path = self.decl_source_path_frontend(i)
            let ci_owner_file_id = self.decl_source_file_id_frontend(i)

            // §16.2 selective import: keep only the requested symbols (and their
            // auto-methods); strict completeness is validated below.
            let only_count = self.c_import_only_count_frontend(out, decl)
            var di = before
            while di < after:
                let dnode = out.get_decl(di)
                var include = true
                if only_count > 0:
                    let dname = self.c_import_decl_bound_name_frontend(out, dnode)
                    include = frontend_is_cimport_support_name(dname) or self.c_import_only_matches_frontend(out, decl, dname)
                if include:
                    ordered.push(dnode as i32)
                    ordered_paths.push(frontend_owned_text(ci_owner_path))
                    ordered_file_ids.push(ci_owner_file_id)
                    ordered_ci.push(1)  // c_import origin
                di = di + 1

            // A requested symbol that was never produced (omitted, untranslated, or
            // absent from the header) is a loud failure (§16.2).
            if only_count > 0:
                for oi in 0..only_count:
                    let oname = self.c_import_only_name_frontend(out, decl, oi)
                    if not self.c_import_produced_name_frontend(out, before, after, oname):
                        self.c_import_emit_selective_missing_frontend(out, decl, oname)

            // strict: any unacknowledged omission turns the whole import non-zero.
            if self.c_import_is_strict_frontend(out, decl):
                self.c_import_emit_strict_omissions_frontend(out, decl, synthetic)

        while out.decl_count() > 0:
            out.state.decls.pop()
        for oi in 0..ordered.len() as i32:
            out.add_decl(ordered.get(oi as i64))
        self.decl_source_paths = ordered_paths
        self.decl_source_file_ids = ordered_file_ids
        self.decl_is_c_import = ordered_ci
        frontend_cimport_unlock()
        out

    fn c_import_cache_key_frontend(pool: AstPool, decl: i32, header_spec: &str) -> str:
        // v16: evaluated macro constants annotate by value range (#775); v15
        // suffixed >i64::MAX literals.
        var key = header_spec ++ "\n#format:cimport-v16\n#links:"
        let link_start = pool.get_data1(decl)
        let packed_counts = pool.get_data2(decl)
        let link_count = c_import_link_count(packed_counts)
        let allow_count = c_import_allow_count(packed_counts)
        for li in 0..link_count:
            let lib_sym = pool.get_extra(link_start + li)
            key = key ++ "|" ++ self.pool.resolve(lib_sym)
        key = key ++ "\n#allow-untranslated:"
        for ai in 0..allow_count:
            let allow_sym = pool.get_extra(link_start + link_count + ai)
            key = key ++ "|" ++ self.pool.resolve(allow_sym)
        key = key ++ "\n#no-methods:" ++ f"{c_import_no_methods_all(packed_counts)}"
        let nm_count = c_import_no_methods_count(packed_counts)
        for ni in 0..nm_count:
            let nm_sym = pool.get_extra(link_start + link_count + allow_count + ni)
            key = key ++ "|" ++ self.pool.resolve(nm_sym)
        // §16.2 selective/strict imports must not share cached output with a
        // permissive whole import of the same header.
        let strict_flag = if self.c_import_is_strict_frontend(pool, decl): 1 else: 0
        key = key ++ "\n#strict:" ++ f"{strict_flag}" ++ "\n#only:"
        let only_count = self.c_import_only_count_frontend(pool, decl)
        for oi in 0..only_count:
            key = key ++ "|" ++ self.c_import_only_name_frontend(pool, decl, oi)
        // #357: ownership annotations shape the generated wrappers — a cached
        // translation must not survive an annotation edit.
        key = key ++ "\n#owns:"
        for koi in 0..self.c_import_owns_count_frontend(pool, decl):
            key = key ++ "|" ++ self.c_import_owns_entry_frontend(pool, decl, koi)
        key = key ++ "\n#borrows:"
        for kbi in 0..self.c_import_borrows_count_frontend(pool, decl):
            key = key ++ "|" ++ self.c_import_borrows_entry_frontend(pool, decl, kbi)
        key = key ++ "\n#defines:"
        for di in 0..self.project_config.c_import_defines.len() as i32:
            key = key ++ "|" ++ self.project_config.c_import_defines.get(di as i64)
        key = key ++ c_import_header_content_fingerprint_line(header_spec)
        key = key ++ frontend_cimport_compiler_fingerprint_line()
        let epoch = runtime_getenv("WITH_CIMPORT_CACHE_EPOCH")
        if epoch.len() > 0:
            key = key ++ "\n#epoch:" ++ epoch
        key

fn c_import_header_content_fingerprint_line(header_spec: &str) -> str:
    let decoded = c_import_trim(c_import_decode_escapes(header_spec))
    if decoded.len() < 3:
        return ""
    if decoded.byte_at(0) != 34 or decoded.byte_at(decoded.len() as i64 - 1) != 34:
        return ""
    let path = decoded.slice(1, decoded.len() - 1)
    if path.len() == 0 or path.byte_at(0) != 47:
        return ""
    let text = runtime_read_file(path)
    if text.len() == 0:
        return "\n#header-path:" ++ path ++ "\n#header-missing"
    "\n#header-path:" ++ path ++ "\n#header-len:" ++ f"{text.len()}" ++ "\n#header-hash:" ++ f"{runtime_str_hash(text)}"

fn c_import_fs_cache_dir() -> str:
    let home = runtime_getenv("HOME")
    if home.len() == 0:
        return ""
    home ++ "/.cache/with/c_import"

fn c_import_fs_cache_entry_path(cache_key: &str, ext: &str) -> str:
    let dir = c_import_fs_cache_dir()
    if dir.len() == 0:
        return ""
    let h = runtime_str_hash(cache_key)
    // Make hash positive for filename
    var hash_str = f"{h}"
    if h < 0:
        hash_str = f"n{0 - h}"
    f"{dir}/{hash_str}{ext}"

fn cimport_deps_str_compare(a: &str, b: &str) -> i32:
    let al = a.len()
    let bl = b.len()
    var i: i64 = 0
    while i < al and i < bl:
        let ab = a.byte_at(i) as i32
        let bb = b.byte_at(i) as i32
        if ab != bb:
            return ab - bb
        i = i + 1
    (al - bl) as i32

fn cimport_deps_sorted_unique_paths(files: &str) -> Vec[str]:
    var out = frontend_new_vec_str()
    var pos = 0
    let total = files.len() as i32
    while pos < total:
        var line_end = pos
        while line_end < total and files.byte_at(line_end as i64) != 10:
            line_end = line_end + 1
        if line_end > pos:
            let path = files.slice(pos as i64, line_end as i64)
            var exists = false
            for i in 0..out.len() as i32:
                if out.get(i as i64) == path:
                    exists = true
            if not exists:
                var inserted = false
                let next = frontend_new_vec_str()
                for i in 0..out.len() as i32:
                    let existing = out.get(i as i64)
                    if not inserted and cimport_deps_str_compare(path, existing) < 0:
                        next.push(with_str_clone_ref(path))
                        inserted = true
                    next.push(with_str_clone_ref(existing))
                if not inserted:
                    next.push(path)
                out = next
        pos = line_end + 1
    out

// Dependency manifest stored beside each cached translation (#553). The set
// of transitively included headers is only known after parsing, so it cannot
// live in the cache key; instead the manifest records each file's length and
// content hash, and lookup re-validates them. Any mismatch is a cache miss.
let CIMPORT_DEPS_MANIFEST_HEADER: str = "cimport-deps-v1"

fn c_import_build_deps_manifest(files: &str) -> str:
    var manifest = CIMPORT_DEPS_MANIFEST_HEADER ++ "\n"
    let paths = cimport_deps_sorted_unique_paths(files)
    for i in 0..paths.len() as i32:
        let path = paths.get(i as i64)
        let text = runtime_read_file(path)
        manifest = manifest ++ f"{text.len()}|{runtime_str_hash(text)}|{path}\n"
    manifest

fn c_import_deps_manifest_entries_valid(manifest: &str) -> bool:
    var pos = 0
    let total = manifest.len() as i32
    var saw_header = false
    while pos < total:
        var line_end = pos
        while line_end < total and manifest.byte_at(line_end as i64) != 10:
            line_end = line_end + 1
        if line_end > pos:
            let line = manifest.slice(pos as i64, line_end as i64)
            if not saw_header:
                if line != CIMPORT_DEPS_MANIFEST_HEADER:
                    return false
                saw_header = true
            else:
                var sep1 = -1
                var sep2 = -1
                for i in 0..line.len() as i32:
                    if line.byte_at(i as i64) == 124:
                        if sep1 < 0:
                            sep1 = i
                        else if sep2 < 0:
                            sep2 = i
                if sep1 <= 0 or sep2 <= sep1 or sep2 as i64 + 1 >= line.len():
                    return false
                let want_len = line.slice(0, sep1 as i64)
                let want_hash = line.slice(sep1 as i64 + 1, sep2 as i64)
                let path = line.slice(sep2 as i64 + 1, line.len())
                let text = runtime_read_file(path)
                if f"{text.len()}" != want_len:
                    return false
                if f"{runtime_str_hash(text)}" != want_hash:
                    return false
        pos = line_end + 1
    saw_header

fn c_import_deps_manifest_paths(manifest: &str) -> Vec[str]:
    var out = frontend_new_vec_str()
    var pos = 0
    let total = manifest.len() as i32
    while pos < total:
        var line_end = pos
        while line_end < total and manifest.byte_at(line_end as i64) != 10:
            line_end = line_end + 1
        if line_end > pos:
            let line = manifest.slice(pos as i64, line_end as i64)
            var sep2 = -1
            var seen = 0
            for i in 0..line.len() as i32:
                if line.byte_at(i as i64) == 124:
                    seen = seen + 1
                    if seen == 2:
                        sep2 = i
            if sep2 > 0 and (sep2 as i64) + 1 < line.len():
                out.push(line.slice(sep2 as i64 + 1, line.len()))
        pos = line_end + 1
    out

fn c_import_fs_cache_deps_manifest(cache_key: &str) -> str:
    let path = c_import_fs_cache_entry_path(cache_key, ".deps")
    if path.len() == 0:
        return ""
    runtime_read_file(path)

fn c_import_fs_cache_lookup(cache_key: &str) -> str:
    let path = c_import_fs_cache_entry_path(cache_key, ".w")
    if path.len() == 0:
        return ""
    // A cached translation is only valid while every header it read is
    // unchanged. No manifest means an unverifiable entry: treat as a miss.
    if not c_import_deps_manifest_entries_valid(c_import_fs_cache_deps_manifest(cache_key)):
        return ""
    runtime_read_file(path)

fn c_import_fs_cache_store(cache_key: &str, value: &str):
    let dir = c_import_fs_cache_dir()
    if dir.len() == 0:
        return
    runtime_mkdir_p(dir)
    // Write the manifest before the content: a partial entry then lacks the
    // content and reads as a plain miss instead of an unvalidated hit.
    runtime_write_file(c_import_fs_cache_entry_path(cache_key, ".deps"), c_import_build_deps_manifest(c_import_included_files()))
    runtime_write_file(c_import_fs_cache_entry_path(cache_key, ".w"), value)

impl Zcu:
    fn c_import_record_omissions_frontend(synthetic: &str):
        let prefix = "// @with-cimport-omitted|"
        var pos = 0
        let total = synthetic.len() as i32
        while pos <= total:
            let line_start = pos
            var line_end = pos
            while line_end < total and synthetic.byte_at(line_end as i64) != 10:
                line_end = line_end + 1
            if line_end > line_start:
                let line = synthetic.slice(line_start as i64, line_end as i64)
                if c_import_starts_with(line, prefix):
                    let rest = line.slice(prefix.len(), line.len())
                    var sep = -1
                    for ri in 0..rest.len() as i32:
                        if rest.byte_at(ri as i64) == 124:
                            sep = ri
                            break
                    if sep > 0:
                        let name = rest.slice(0, sep as i64)
                        let reason = rest.slice((sep + 1) as i64, rest.len())
                        self.c_import_omitted_symbols.insert(name, reason)
                    else if rest.len() > 0:
                        self.c_import_omitted_symbols.insert(rest, "untranslated C construct")
            if line_end >= total:
                break
            pos = line_end + 1

    mut fn c_import_emit_header_error_detail_frontend(decl: i32, header_spec: &str, detail: &str):
        let _ = decl
        let span = Span {
            file: 0,
            start: self.current_source_text.len() as i32,
            end: self.current_source_text.len() as i32,
        }
        let msg = if header_spec.len() > 0:
            "failed to compile C header snippet: " ++ header_spec
        else:
            "failed to compile C header snippet"
        var full_msg = if detail.len() > 0: msg ++ ": " ++ detail else: msg
        // §16.1: if the target macOS SDK could not be resolved, name the missing
        // target input and the remedies (never a host tool — none is used).
        if with_cimport_macos_sdk_missing() != 0:
            full_msg = full_msg ++ "; no macOS SDK found for target headers — set SDKROOT/WITH_SDKROOT, configure [c_import] sdk_path in with.toml, or install the Command Line Tools"
        self.diagnostics.emit(Diagnostic.err(full_msg, span))

    mut fn c_import_emit_header_error_frontend(decl: i32, header_spec: &str):
        self.c_import_emit_header_error_detail_frontend(decl, header_spec, "")

    mut fn c_import_emit_untranslated_error_frontend(pool: AstPool, decl: i32, kind: &str, name: &str):
        let display_name = if name.len() > 0: with_str_clone_ref(name) else: "<unknown>"
        let span = Span {
            file: 0,
            start: pool.get_start(decl),
            end: pool.get_end(decl),
        }
        self.diagnostics.emit(Diagnostic.err("c_import: untranslated " ++ kind ++ " '" ++ display_name ++ "'; add it to allow_untranslated to acknowledge omission", span))

    // §16.2 selective-import record, appended to the extra array after the
    // no_methods group: [strict_flag, only_count, only_name_0, ...].
    fn c_import_select_base_frontend(pool: AstPool, decl: i32) -> i32:
        let link_start = pool.get_data1(decl)
        let packed = pool.get_data2(decl)
        link_start + c_import_link_count(packed) + c_import_allow_count(packed) + c_import_no_methods_count(packed)

    fn c_import_is_strict_frontend(pool: AstPool, decl: i32) -> bool:
        pool.get_extra(self.c_import_select_base_frontend(pool, decl)) != 0

    fn c_import_only_count_frontend(pool: AstPool, decl: i32) -> i32:
        pool.get_extra(self.c_import_select_base_frontend(pool, decl) + 1)

    fn c_import_only_name_frontend(pool: AstPool, decl: i32, idx: i32) -> str:
        with_str_clone_ref(self.pool.resolve(pool.get_extra(self.c_import_select_base_frontend(pool, decl) + 2 + idx)))

    // #357 ownership-annotation record: [owns_count, owns..., borrows_count,
    // borrows...] follows the selective-import record [strict, only_count, only...].
    fn c_import_ann_base_frontend(pool: AstPool, decl: i32) -> i32:
        let sel = self.c_import_select_base_frontend(pool, decl)
        sel + 2 + pool.get_extra(sel + 1)

    fn c_import_owns_count_frontend(pool: AstPool, decl: i32) -> i32:
        pool.get_extra(self.c_import_ann_base_frontend(pool, decl))

    fn c_import_owns_entry_frontend(pool: AstPool, decl: i32, idx: i32) -> str:
        with_str_clone_ref(self.pool.resolve(pool.get_extra(self.c_import_ann_base_frontend(pool, decl) + 1 + idx)))

    fn c_import_borrows_count_frontend(pool: AstPool, decl: i32) -> i32:
        let ab = self.c_import_ann_base_frontend(pool, decl)
        pool.get_extra(ab + 1 + pool.get_extra(ab))

    fn c_import_borrows_entry_frontend(pool: AstPool, decl: i32, idx: i32) -> str:
        let ab = self.c_import_ann_base_frontend(pool, decl)
        with_str_clone_ref(self.pool.resolve(pool.get_extra(ab + 2 + pool.get_extra(ab) + idx)))

    // A produced declaration's bound name (fn/type/const/extern all store the
    // name symbol in d0). For `Type.method` names, the leading segment before the
    // dot is the type a selective import would have requested.
    fn c_import_decl_bound_name_frontend(pool: AstPool, decl: i32) -> str:
        with_str_clone_ref(self.pool.resolve(pool.get_data0(decl)))

// Foundational scaffolding a selective import must always keep: the unnamed
// helper decls and the `c_*` C-primitive typedefs (c_int, c_char, …) that the
// requested symbols resolve through. (A header type a requested symbol depends
// on must itself be listed in `only`.)
fn frontend_is_cimport_support_name(name: &str) -> bool:
    if name.len() == 0:
        return true
    name.len() as i32 >= 2 and name.byte_at(0) == 99 and name.byte_at(1) == 95

// True when `dname` is `want` or a `want.member` method of it — so selecting a
// type keeps its auto-generated methods.
fn frontend_name_selects(want: &str, dname: &str) -> bool:
    if dname == want:
        return true
    let wl = want.len() as i32
    if dname.len() as i32 > wl and dname.byte_at(wl as i64) == 46:
        return dname.slice(0, wl as i64) == want
    false

impl Zcu:
    fn c_import_only_matches_frontend(pool: AstPool, decl: i32, dname: &str) -> bool:
        let n = self.c_import_only_count_frontend(pool, decl)
        for oi in 0..n:
            if frontend_name_selects(self.c_import_only_name_frontend(pool, decl, oi), dname):
                return true
        false

    fn c_import_produced_name_frontend(pool: AstPool, before: i32, after: i32, want: &str) -> bool:
        var di = before
        while di < after:
            if frontend_name_selects(want, self.c_import_decl_bound_name_frontend(pool, pool.get_decl(di))):
                return true
            di = di + 1
        false

    mut fn c_import_emit_selective_missing_frontend(pool: AstPool, decl: i32, name: &str):
        let span = Span { file: 0, start: pool.get_start(decl), end: pool.get_end(decl) }
        var msg = "c_import: requested symbol '" ++ name ++ "' is not available"
        if self.c_import_omitted_symbols.contains(name):
            msg = msg ++ " (omitted: " ++ self.c_import_omitted_symbols.get(name).unwrap() ++ ")"
        else:
            msg = msg ++ " (no such declaration in the header, or it was not translated)"
        self.diagnostics.emit(Diagnostic.err(msg, span))

    // strict: every omission recorded in `synthetic` that is not acknowledged via
    // allow_untranslated becomes a non-zero import failure.
    mut fn c_import_emit_strict_omissions_frontend(pool: AstPool, decl: i32, synthetic: &str):
        let prefix = "// @with-cimport-omitted|"
        var pos = 0
        let total = synthetic.len() as i32
        while pos <= total:
            let line_start = pos
            var line_end = pos
            while line_end < total and synthetic.byte_at(line_end as i64) != 10:
                line_end = line_end + 1
            if line_end > line_start:
                let line = synthetic.slice(line_start as i64, line_end as i64)
                if c_import_starts_with(line, prefix):
                    let rest = line.slice(prefix.len(), line.len())
                    var sep = -1
                    for ri in 0..rest.len() as i32:
                        if rest.byte_at(ri as i64) == 124:
                            sep = ri
                            break
                    let name = if sep > 0: rest.slice(0, sep as i64) else: rest
                    if name.len() > 0 and not self.c_import_decl_allows_untranslated_frontend(pool, decl, name):
                        let span = Span { file: 0, start: pool.get_start(decl), end: pool.get_end(decl) }
                        self.diagnostics.emit(Diagnostic.err("c_import: strict import omitted '" ++ name ++ "'; add it to allow_untranslated to acknowledge omission, or drop strict", span))
            if line_end >= total:
                break
            pos = line_end + 1

    fn c_import_decl_allows_untranslated_frontend(pool: AstPool, decl: i32, name: &str) -> bool:
        if name.len() == 0:
            return false
        let link_start = pool.get_data1(decl)
        let packed_counts = pool.get_data2(decl)
        let link_count = c_import_link_count(packed_counts)
        let allow_count = c_import_allow_count(packed_counts)
        for ai in 0..allow_count:
            let allow_sym = pool.get_extra(link_start + link_count + ai)
            if self.pool.resolve(allow_sym) == name:
                return true
        false

    fn c_import_first_unallowed_untranslated_frontend(pool: AstPool, decl: i32, names: &str) -> str:
        var i = 0
        let total = names.len() as i32
        while i < total:
            while i < total and names.byte_at(i as i64) == 124:
                i = i + 1
            let start = i
            while i < total and names.byte_at(i as i64) != 124:
                i = i + 1
            if i > start:
                let name = names.slice(start as i64, i as i64)
                if not self.c_import_decl_allows_untranslated_frontend(pool, decl, name):
                    return name
        ""

    mut fn c_import_expand_header_spec_frontend(header_spec_raw: &str, pool: AstPool, decl: i32) -> str:
        let decoded = c_import_decode_escapes(header_spec_raw)
        let rendered = c_import_render_header_spec(decoded)
        let header = c_import_trim(rendered)
        if header.len() == 0:
            self.c_import_emit_header_error_frontend(decl, header_spec_raw)
            return ""

        var generated = ""
        var body = ""

        var line_start = 0
        var i = 0
        let total = header.len() as i32
        while i <= total:
            if i == total or header.byte_at(i as i64) == 10:
                let raw_line = header.slice(line_start as i64, i as i64)
                let line = c_import_trim(raw_line)
                if line.len() > 0:
                    if c_import_starts_with(line, "#include"):
                        let inc = self.c_import_include_decls_frontend(line, decl, header_spec_raw)
                        if self.diagnostics.has_errors():
                            return ""
                        generated = generated ++ inc
                    else if c_import_starts_with(line, "#define"):
                        let macro_decl = c_import_macro_decl(line)
                        if macro_decl.len() > 0:
                            generated = generated ++ macro_decl
                        else:
                            let macro_name = c_import_define_name(line)
                            if macro_name.len() > 0:
                                self.c_import_omitted_symbols.insert(macro_name, "untranslated macro")
                    else:
                        body = body ++ line ++ "\n"
                line_start = i + 1
            i = i + 1

        var stmt_start = 0
        var si = 0
        let body_len = body.len() as i32
        while si <= body_len:
            if si == body_len or body.byte_at(si as i64) == 59:
                let stmt = c_import_trim(body.slice(stmt_start as i64, si as i64))
                if stmt.len() > 0:
                    let fn_decl = c_import_function_decl(stmt)
                    if fn_decl.len() == 0:
                        let decl_name = c_import_statement_name(stmt)
                        if decl_name.len() > 0:
                            self.c_import_omitted_symbols.insert(decl_name, "untranslated declaration")
                    else:
                        generated = generated ++ fn_decl
                stmt_start = si + 1
            si = si + 1

        generated

    mut fn c_import_include_decls_frontend(line: &str, decl: i32, header_spec_raw: &str) -> str:
        let rest = c_import_trim(line.slice(8, line.len()))
        if rest.len() < 3:
            self.c_import_emit_header_error_frontend(decl, header_spec_raw)
            return ""

        var header_name = ""
        let first = rest.byte_at(0)
        let last = rest.byte_at(rest.len() as i64 - 1)
        if first == 60 and last == 62:
            header_name = rest.slice(1, rest.len() - 1)
        else if first == 34 and last == 34:
            header_name = rest.slice(1, rest.len() - 1)
        else:
            self.c_import_emit_header_error_frontend(decl, header_spec_raw)
            return ""

        if header_name == "stdio.h":
            return "extern fn puts(p0: *const i8) -> i32\n" ++
                   "extern fn printf(p0: *const i8, ...) -> i32\n" ++
                   "extern fn fopen(p0: *const i8, p1: *const i8) -> *const i8\n" ++
                   "extern fn fclose(p0: *const i8) -> i32\n" ++
                   "extern fn fputs(p0: *const i8, p1: *const i8) -> i32\n" ++
                   "extern fn fread(p0: *const i8, p1: i64, p2: i64, p3: *const i8) -> i64\n" ++
                   "extern fn remove(p0: *const i8) -> i32\n" ++
                   "extern fn rename(p0: *const i8, p1: *const i8) -> i32\n"
        if header_name == "string.h":
            return "extern fn strlen(p0: *const i8) -> i64\n" ++
                   "extern fn strcmp(p0: *const i8, p1: *const i8) -> i32\n" ++
                   "extern fn memcpy(p0: *const i8, p1: *const i8, p2: i64) -> *const i8\n" ++
                   "extern fn memmove(p0: *const i8, p1: *const i8, p2: i64) -> *const i8\n" ++
                   "extern fn memset(p0: *const i8, p1: i32, p2: i64) -> *const i8\n" ++
                   "extern fn memcmp(p0: *const i8, p1: *const i8, p2: i64) -> i32\n"
        if header_name == "stdlib.h":
            return "extern fn malloc(p0: i64) -> *const i8\n" ++
                   "extern fn free(p0: *const i8) -> Unit\n" ++
                   "extern fn calloc(p0: i64, p1: i64) -> *const i8\n" ++
                   "extern fn realloc(p0: *const i8, p1: i64) -> *const i8\n" ++
                   "extern fn atol(p0: *const i8) -> i64\n" ++
                   "extern fn rand() -> i32\n" ++
                   "extern fn srand(p0: i32) -> Unit\n"
        if header_name == "unistd.h":
            return "extern fn access(p0: *const i8, p1: i32) -> i32\n" ++
                   "extern fn rmdir(p0: *const i8) -> i32\n"
        if header_name == "sys/stat.h":
            return "extern fn mkdir(p0: *const i8, p1: u16) -> i32\n"
        if header_name == "ctype.h":
            return "extern fn isalpha(p0: i32) -> i32\n" ++
                   "extern fn isdigit(p0: i32) -> i32\n" ++
                   "extern fn isspace(p0: i32) -> i32\n"
        if header_name == "math.h":
            return "extern fn sqrt(p0: f64) -> f64\n" ++
                   "extern fn pow(p0: f64, p1: f64) -> f64\n" ++
                   "extern fn floor(p0: f64) -> f64\n" ++
                   "extern fn ceil(p0: f64) -> f64\n" ++
                   "extern fn round(p0: f64) -> f64\n" ++
                   "extern fn sin(p0: f64) -> f64\n" ++
                   "extern fn cos(p0: f64) -> f64\n" ++
                   "extern fn tan(p0: f64) -> f64\n" ++
                   "extern fn log(p0: f64) -> f64\n" ++
                   "extern fn log10(p0: f64) -> f64\n" ++
                   "extern fn exp(p0: f64) -> f64\n" ++
                   "extern fn fabs(p0: f64) -> f64\n" ++
                   "extern fn fmod(p0: f64, p1: f64) -> f64\n" ++
                   "extern fn asin(p0: f64) -> f64\n" ++
                   "extern fn acos(p0: f64) -> f64\n" ++
                   "extern fn atan(p0: f64) -> f64\n" ++
                   "extern fn atan2(p0: f64, p1: f64) -> f64\n"

        self.c_import_emit_header_error_frontend(decl, header_spec_raw)
        ""

fn c_import_render_header_spec(spec_raw: &str) -> str:
    let spec = c_import_trim(spec_raw)
    if spec.len() == 0:
        return ""

    let has_newline = c_import_str_contains(spec, "\n")
    let has_directive = c_import_starts_with(spec, "#")
    let has_statement = c_import_str_contains(spec, ";")
    if has_newline or has_directive or has_statement:
        return spec

    let first = spec.byte_at(0)
    let last = spec.byte_at(spec.len() as i64 - 1)
    if (first == 60 and last == 62) or (first == 34 and last == 34):
        return "#include " ++ spec
    "#include <" ++ spec ++ ">"

fn c_import_macro_decl(line: &str) -> str:
    var rest = with_str_clone_ref(line)
    if c_import_starts_with(rest, "#define"):
        rest = c_import_trim(rest.slice(7, rest.len()))
    else:
        return ""
    if rest.len() == 0:
        return ""

    var i = 0
    while i < rest.len() as i32 and c_import_is_ident_char(rest.byte_at(i as i64)):
        i = i + 1
    if i <= 0:
        return ""
    let name = rest.slice(0, i as i64)
    if i < rest.len() as i32 and rest.byte_at(i as i64) == 40:
        return ""

    var value = c_import_trim(rest.slice(i as i64, rest.len()))
    if value.len() == 0:
        return ""
    value = c_import_trim_outer_parens(value)

    if c_import_is_int_literal(value) != 0:
        return "let " ++ name ++ " = " ++ value ++ "\n"

    if value.len() >= 2 and value.byte_at(0) == 34 and value.byte_at(value.len() as i64 - 1) == 34:
        let inner = value.slice(1, value.len() - 1)
        let escaped = c_import_escape_with_string(inner)
        return "let " ++ name ++ " = \"" ++ escaped ++ "\"\n"

    ""

fn c_import_define_name(line: &str) -> str:
    var rest = with_str_clone_ref(line)
    if c_import_starts_with(rest, "#define"):
        rest = c_import_trim(rest.slice(7, rest.len()))
    else:
        return ""
    var i = 0
    while i < rest.len() as i32 and c_import_is_ident_char(rest.byte_at(i as i64)):
        i = i + 1
    if i <= 0:
        return ""
    rest.slice(0, i as i64)

fn c_import_statement_name(stmt_raw: &str) -> str:
    let stmt = c_import_trim(stmt_raw)
    if stmt.len() == 0:
        return ""

    var open = -1
    for i in 0..stmt.len() as i32:
        if stmt.byte_at(i as i64) == 40:
            open = i
            break
    if open > 0:
        var ne = open - 1
        while ne >= 0 and c_import_is_space(stmt.byte_at(ne as i64)):
            ne = ne - 1
        var ns = ne
        while ns >= 0 and c_import_is_ident_char(stmt.byte_at(ns as i64)):
            ns = ns - 1
        ns = ns + 1
        if ns <= ne:
            return stmt.slice(ns as i64, (ne + 1) as i64)

    var end = stmt.len() as i32 - 1
    while end >= 0 and not c_import_is_ident_char(stmt.byte_at(end as i64)):
        end = end - 1
    if end < 0:
        return ""
    var start = end
    while start >= 0 and c_import_is_ident_char(stmt.byte_at(start as i64)):
        start = start - 1
    stmt.slice((start + 1) as i64, (end + 1) as i64)

fn c_import_function_decl(stmt_raw: &str) -> str:
    let stmt = c_import_trim(stmt_raw)
    if stmt.len() == 0:
        return ""

    var open = -1
    var close = -1
    for i in 0..stmt.len() as i32:
        let ch = stmt.byte_at(i as i64)
        if ch == 40 and open < 0:
            open = i
        if ch == 41:
            close = i
    if open <= 0 or close <= open:
        return ""

    let trailing = c_import_trim(stmt.slice((close + 1) as i64, stmt.len()))
    if trailing.len() > 0:
        return ""

    var ne = open - 1
    while ne >= 0 and c_import_is_space(stmt.byte_at(ne as i64)):
        ne = ne - 1
    if ne < 0:
        return ""
    var ns = ne
    while ns >= 0 and c_import_is_ident_char(stmt.byte_at(ns as i64)):
        ns = ns - 1
    ns = ns + 1
    if ns > ne:
        return ""

    let fn_name = stmt.slice(ns as i64, (ne + 1) as i64)
    let ret_spec = c_import_trim(stmt.slice(0, ns as i64))
    if ret_spec.len() == 0:
        return ""
    let ret_ty = c_import_map_c_type(ret_spec)

    let params_text = c_import_trim(stmt.slice((open + 1) as i64, close as i64))
    var params_out = ""
    var has_variadic = 0
    var param_index = 0
    if params_text.len() > 0 and params_text != "void":
        var seg_start = 0
        var i = 0
        let plen = params_text.len() as i32
        while i <= plen:
            if i == plen or params_text.byte_at(i as i64) == 44:
                let seg = c_import_trim(params_text.slice(seg_start as i64, i as i64))
                if seg.len() > 0:
                    if seg == "...":
                        has_variadic = 1
                    else:
                        let pty = c_import_param_type(seg)
                        if pty.len() == 0:
                            return ""
                        if params_out.len() > 0:
                            params_out = params_out ++ ", "
                        params_out = params_out ++ f"p{param_index}: " ++ pty
                        param_index = param_index + 1
                seg_start = i + 1
            i = i + 1

    if has_variadic != 0:
        if params_out.len() > 0:
            params_out = params_out ++ ", ..."
        else:
            params_out = "..."

    "extern fn " ++ fn_name ++ "(" ++ params_out ++ ") -> " ++ ret_ty ++ "\n"

fn c_import_param_type(param_raw: &str) -> str:
    var param = c_import_trim_outer_parens(c_import_trim(param_raw))
    if param.len() == 0:
        return ""
    if param == "void":
        return ""

    let len = param.len() as i32
    var end = len - 1
    while end >= 0 and c_import_is_space(param.byte_at(end as i64)):
        end = end - 1

    var type_spec = with_str_clone_ref(param)
    if end >= 0 and c_import_is_ident_char(param.byte_at(end as i64)):
        var j = end
        while j >= 0 and c_import_is_ident_char(param.byte_at(j as i64)):
            j = j - 1
        let prefix = c_import_trim(param.slice(0, (j + 1) as i64))
        if prefix.len() > 0:
            type_spec = prefix

    c_import_map_c_type(type_spec)

fn c_import_map_c_type(spec_raw: &str) -> str:
    let spec = c_import_trim(spec_raw)
    if spec.len() == 0:
        return "i32"

    var star_count = 0
    for i in 0..spec.len() as i32:
        if spec.byte_at(i as i64) == 42:
            star_count = star_count + 1

    var base = "i32"
    if c_import_str_contains(spec, "unsigned __int128"):
        base = "u128"
    else if c_import_str_contains(spec, "__int128"):
        base = "i128"
    else if c_import_str_contains(spec, "unsigned long long"):
        base = "u64"
    else if c_import_str_contains(spec, "unsigned long"):
        base = "u64"
    else if c_import_str_contains(spec, "long long"):
        base = "i64"
    else if c_import_str_contains(spec, "size_t"):
        base = "u64"
    else if c_import_str_contains(spec, "unsigned int"):
        base = "u32"
    else if c_import_str_contains(spec, "unsigned short"):
        base = "u16"
    else if c_import_str_contains(spec, "unsigned char"):
        base = "u8"
    else if c_import_str_contains(spec, "short"):
        base = "i16"
    else if c_import_str_contains(spec, "char"):
        base = "i8"
    else if c_import_str_contains(spec, "double"):
        base = "f64"
    else if c_import_str_contains(spec, "float"):
        base = "f32"
    else if c_import_str_contains(spec, "long"):
        base = "i64"
    else if c_import_str_contains(spec, "void"):
        base = "void"
    else if c_import_str_contains(spec, "int"):
        base = "i32"

    if star_count <= 0:
        return base

    var inner = base
    if inner == "void":
        inner = "i8"
    var out = inner
    for i in 0..star_count:
        out = "*const " ++ out
    out

fn c_import_decode_escapes(raw: &str) -> str:
    var out = ""
    var i = 0
    let len = raw.len() as i32
    while i < len:
        let ch = raw.byte_at(i as i64)
        if ch != 92 or i + 1 >= len:
            out = out ++ raw.slice(i as i64, (i + 1) as i64)
            i = i + 1
            continue

        let esc = raw.byte_at((i + 1) as i64)
        if esc == 110:
            out = out ++ "\n"
        else if esc == 114:
            out = out ++ "\r"
        else if esc == 116:
            out = out ++ "\t"
        else if esc == 92:
            out = out ++ "\\"
        else if esc == 34:
            out = out ++ "\""
        else:
            out = out ++ raw.slice((i + 1) as i64, (i + 2) as i64)
        i = i + 2
    out

fn c_import_trim_outer_parens(value_raw: &str) -> str:
    var v = c_import_trim(value_raw)
    while v.len() >= 2 and v.byte_at(0) == 40 and v.byte_at(v.len() as i64 - 1) == 41:
        v = c_import_trim(v.slice(1, v.len() - 1))
    v

fn c_import_escape_with_string(value: &str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 92:
            out = out ++ "\\\\"
        else if ch == 34:
            out = out ++ "\\\""
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else if ch == 9:
            out = out ++ "\\t"
        else:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

fn c_import_is_int_literal(text_raw: &str) -> i32:
    let text = c_import_trim(text_raw)
    if text.len() == 0:
        return 0

    var i = 0
    if text.byte_at(0) == 45 or text.byte_at(0) == 43:
        i = 1
    if i >= text.len() as i32:
        return 0

    if i + 1 < text.len() as i32 and text.byte_at(i as i64) == 48 and (text.byte_at((i + 1) as i64) == 120 or text.byte_at((i + 1) as i64) == 88):
        i = i + 2
        if i >= text.len() as i32:
            return 0
        while i < text.len() as i32:
            let ch = text.byte_at(i as i64)
            let is_digit = ch >= 48 and ch <= 57
            let is_hex_lo = ch >= 97 and ch <= 102
            let is_hex_hi = ch >= 65 and ch <= 70
            if not (is_digit or is_hex_lo or is_hex_hi):
                return 0
            i = i + 1
        return 1

    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch < 48 or ch > 57:
            return 0
        i = i + 1
    1

fn c_import_is_space(ch: i32) -> bool:
    ch == 32 or ch == 9 or ch == 10 or ch == 13

fn c_import_trim(s: &str) -> str:
    var start = 0
    var end = s.len() as i32
    while start < end and c_import_is_space(s.byte_at(start as i64)):
        start = start + 1
    while end > start and c_import_is_space(s.byte_at((end - 1) as i64)):
        end = end - 1
    s.slice(start as i64, end as i64)

fn c_import_starts_with(text: &str, prefix: &str) -> bool:
    if prefix.len() > text.len():
        return false
    text.slice(0, prefix.len()) == prefix

fn c_import_is_ident_char(ch: i32) -> bool:
    let is_alpha = (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122)
    let is_digit = ch >= 48 and ch <= 57
    is_alpha or is_digit or ch == 95

impl Zcu:
    // #682-inc1: expand the prelude USE (decl 0) and its transitive closure
    // into the pool AHEAD of the user source. Dedup (imported_paths) and
    // decl_source_paths bookkeeping match process_imports_frontend phase 1,
    // which later sees these paths as already imported and skips re-parsing;
    // its prelude tier is collected from the recorded prefix range instead.
    mut fn expand_prelude_closure_frontend(pool: AstPool) -> AstPool:
        var merged_pool = pool
        if merged_pool.decl_count() == 0 or merged_pool.kind(merged_pool.get_decl(0)) != NodeKind.NK_USE_DECL:
            return merged_pool
        let first = merged_pool.get_decl(0)
        let ps = merged_pool.get_data0(first)
        let pc = merged_pool.get_data1(first)
        if pc > 0:
            let pname = self.use_path_name_frontend(merged_pool, ps, pc)
            let fpath = self.resolve_module_path_frontend(pname, self.decl_source_dir_frontend(0))
            if fpath.len() > 0 and self.has_imported_path(fpath) == 0:
                self.add_imported_path(fpath)
                merged_pool = self.parse_imported_file_frontend(fpath, merged_pool)
            else if fpath.len() == 0:
                self.emit_missing_import_frontend(merged_pool, first)
        var pi = 1
        while pi < merged_pool.decl_count():
            let decl = merged_pool.get_decl(pi)
            if merged_pool.kind(decl) == NodeKind.NK_USE_DECL:
                let pps = merged_pool.get_data0(decl)
                let ppc = merged_pool.get_data1(decl)
                if ppc > 0 and not self.use_decl_is_local_type_selector_frontend(merged_pool, decl):
                    let ppname = self.use_path_name_frontend(merged_pool, pps, ppc)
                    let ppfpath = self.resolve_module_path_frontend(ppname, self.decl_source_dir_frontend(pi))
                    if ppfpath.len() > 0 and self.has_imported_path(ppfpath) == 0:
                        self.add_imported_path(ppfpath)
                        merged_pool = self.parse_imported_file_frontend(ppfpath, merged_pool)
                    else if ppfpath.len() == 0:
                        self.emit_missing_import_frontend(merged_pool, decl)
            pi = pi + 1
        merged_pool

    // D30 R2b (dark): with WITH_RT_IN_UNIT set, the runtime module set
    // parses into the unit right after the prelude closure, from the
    // embedded sources. The nm-driven link then self-suppresses the
    // .w-derived rt objects (their symbols are defined in-unit); only
    // fiber_asm.o still comes from the object world (platform assembly).
    // Off by default until R2c retargets codegen and the flip is ruled.
    mut fn parse_runtime_modules_frontend(pool: AstPool) -> AstPool:
        var merged_pool = pool
        let platform = frontend_rt_in_unit_platform_file()
        if platform.len() == 0:
            self.diagnostics.emit(Diagnostic.err("rt-in-unit: no runtime platform source for target '" ++ target_spec_name() ++ "'", Span { file: 0, start: 0, end: 0 }))
            return merged_pool
        let fiber_core = if platform.starts_with("rt/windows"): "rt/fiber_core_windows.w" else: "rt/fiber_core_darwin.w"
        let files: Vec[str] = Vec.new()
        files.push("rt/rt_core.w")
        files.push(with_str_clone_ref(platform))
        files.push("rt/panic_runtime.w")
        files.push("rt/channel_runtime.w")
        files.push("rt/fiber_runtime.w")
        files.push(with_str_clone_ref(fiber_core))
        files.push("rt/compat_runtime.w")
        for i in 0..files.len() as i32:
            let rel = files.get(i as i64)
            let path = embedded_rt_resolve_path(rel)
            if path.len() == 0:
                self.diagnostics.emit(Diagnostic.err("rt-in-unit: runtime source not embedded: " ++ rel, Span { file: 0, start: 0, end: 0 }))
                return merged_pool
            if self.has_imported_path(path) == 0:
                self.add_imported_path(path)
                merged_pool = self.parse_imported_file_frontend(path, merged_pool)
        merged_pool

    mut fn compile_file_frontend(path: &str) -> AstPool:
        self.compile_file_frontend_with_config(path, project_config_load_for_source(path))

    mut fn compile_file_frontend_with_config(path: &str, cfg: ProjectConfig) -> AstPool:
        let do_profile = runtime_getenv("WITH_PROFILE").len() > 0
        if zcu_debug_init_enabled() != 0:
            runtime_eprint("[frontend] compile_file:start " ++ path)
        let source_dir = frontend_dirname(path)
        self.reset_for_new_invocation(source_dir, path, "")
        self.project_config = cfg
        self.set_prelude_mode(compilation_effective_prelude_mode(self.prelude_mode, self.project_config.no_std, self.project_config.alloc_mode))
        if self.project_config.manifest_error.len() > 0:
            runtime_eprint("error: invalid with.toml: " ++ self.project_config.manifest_error)
            self.set_resolve_snapshot(ResolveResult.init(), path)
            return AstPool.new()

        let t_read = runtime_clock_nanos()
        let raw_text = runtime_read_file(path)
        if raw_text.len() == 0:
            runtime_eprint("error: cannot open '" ++ path ++ "'")
            self.set_resolve_snapshot(ResolveResult.init(), path)
            return AstPool.new()
        if do_profile:
            let read_ns = runtime_clock_nanos() - t_read
            runtime_eprint(f"[profile] frontend.read  {read_ns / 1000000}.{(read_ns % 1000000) / 1000} ms  bytes={raw_text.len() as i32}")

        let text = frontend_normalize_source_text(raw_text)
        self.set_current_source(source_dir, path, text)
        if zcu_debug_init_enabled() != 0:
            runtime_eprint(f"[frontend] compile_file:source_ready bytes={text.len() as i32}")
        let pool = self.compile_source_frontend(text, path, 0)
        if pool.decl_count() == 0 and not self.diagnostics.has_errors():
            runtime_eprint("error: compiler produced an empty module for '" ++ path ++ "'")
        pool

    mut fn compile_file_frontend_entry(path: &str) -> AstPool:
        self.compile_file_frontend_entry_with_config(path, project_config_load_for_source(path))

    mut fn compile_file_frontend_entry_with_config(path: &str, cfg: ProjectConfig) -> AstPool:
        let do_profile = runtime_getenv("WITH_PROFILE").len() > 0
        if zcu_debug_init_enabled() != 0:
            runtime_eprint("[frontend] compile_file_entry:start " ++ path)
        let source_dir = frontend_dirname(path)
        self.reset_for_new_invocation(source_dir, path, "")
        self.project_config = cfg
        self.set_prelude_mode(compilation_effective_prelude_mode(self.prelude_mode, self.project_config.no_std, self.project_config.alloc_mode))
        if self.project_config.manifest_error.len() > 0:
            runtime_eprint("error: invalid with.toml: " ++ self.project_config.manifest_error)
            self.set_resolve_snapshot(ResolveResult.init(), path)
            return AstPool.new()

        let t_read = runtime_clock_nanos()
        let raw_text = runtime_read_file(path)
        if raw_text.len() == 0:
            runtime_eprint("error: cannot open '" ++ path ++ "'")
            self.set_resolve_snapshot(ResolveResult.init(), path)
            return AstPool.new()
        if do_profile:
            let read_ns = runtime_clock_nanos() - t_read
            runtime_eprint(f"[profile] frontend.read  {read_ns / 1000000}.{(read_ns % 1000000) / 1000} ms  bytes={raw_text.len() as i32}")

        let text = frontend_normalize_source_text(raw_text)
        self.set_current_source(source_dir, path, text)
        let pool = self.compile_source_frontend_mode(text, path, 0, 1)
        if pool.decl_count() == 0 and not self.diagnostics.has_errors():
            runtime_eprint("error: compiler produced an empty module for '" ++ path ++ "'")
        pool

    mut fn compile_source_frontend(text: &str, name: &str, file_id: i32) -> AstPool:
        self.compile_source_frontend_mode(text, name, file_id, 0)

    mut fn compile_source_frontend_mode(text: &str, name: &str, file_id: i32, implicit_main_mode: i32) -> AstPool:
        let do_profile = runtime_getenv("WITH_PROFILE").len() > 0
        if zcu_debug_init_enabled() != 0:
            runtime_eprint("[frontend] compile_source:parse")
        let normalized_text = frontend_normalize_source_text(text)
        self.current_source_path = with_str_clone_ref(name)
        self.current_source_text = with_str_clone_ref(normalized_text)

        // Phase 1+2: Lex + Parse.  When prelude is enabled, parse the prelude
        // USE declaration first, then (#682-inc1) expand the prelude closure
        // into the pool BEFORE the user source parses: the closure occupies a
        // node/intern/file-id PREFIX that is byte-deterministic for a given
        // compiler fingerprint + prelude mode — the snapshot boundary for
        // #682's later increments. Final decl ORDER is unchanged: the
        // three-tier import merge already emits prelude → user imports → root.
        let t_parse = runtime_clock_nanos()
        var pool: AstPool = AstPool.new()
        self.prelude_prefix_decls = 0
        self.prelude_prefix_non_use = 0
        if self.prelude_mode != PRELUDE_NONE():
            let prelude_module = if self.prelude_mode == PRELUDE_CORE(): "std.prelude_core" else if self.prelude_mode == PRELUDE_ALLOC(): "std.prelude_alloc" else: "std.prelude"
            let synthetic = "use " ++ prelude_module ++ "\n"
            var plexer = Lexer.init(synthetic, 0)
            let ptokens = plexer.tokenize()
            var pparser = Parser.init(move ptokens, synthetic, 0, self.pool, move self.diagnostics)
            pool = pparser.parse_module()
            self.pool = pparser.intern
            self.diagnostics = move pparser.diags
            self.seed_decl_source_paths(pool, name, file_id)
            pool = self.expand_prelude_closure_frontend(pool)
            if frontend_rt_in_unit_enabled() != 0:
                pool = self.parse_runtime_modules_frontend(pool)
            self.prelude_prefix_decls = pool.decl_count()
            self.prelude_prefix_non_use = count_non_use_decls_frontend(pool)
            let before_user = pool.decl_count()
            var ulexer = Lexer.init(normalized_text, file_id)
            let utokens = ulexer.tokenize()
            var uparser = Parser.init_with_pool(move utokens, normalized_text, file_id, self.pool, move self.diagnostics, pool)
            if implicit_main_mode != 0:
                uparser.enable_implicit_main_mode()
            pool = uparser.parse_module()
            self.pool = uparser.intern
            self.diagnostics = move uparser.diags
            self.append_decl_source_paths(pool.decl_count() - before_user, name, file_id)
        else:
            var lexer = Lexer.init(normalized_text, file_id)
            let tokens = lexer.tokenize()
            var parser = Parser.init(move tokens, normalized_text, file_id, self.pool, move self.diagnostics)
            if implicit_main_mode != 0:
                parser.enable_implicit_main_mode()
            pool = parser.parse_module()
            self.pool = parser.intern
            self.diagnostics = move parser.diags
            self.seed_decl_source_paths(pool, name, file_id)
        for extra_i in 0..self.extra_source_names.len() as i32:
            let extra_name: str = with_str_clone_ref(self.extra_source_names.get(extra_i as i64))
            let extra_text = frontend_normalize_source_text(self.extra_source_texts.get(extra_i as i64))
            let extra_file_id = self.next_file_id
            self.next_file_id = self.next_file_id + 1
            self.add_source_text_mapping(extra_file_id, extra_name, extra_text)
            let before = pool.decl_count()
            var extra_lexer = Lexer.init(extra_text, extra_file_id)
            let extra_tokens = extra_lexer.tokenize()
            var extra_parser = Parser.init_with_pool(move extra_tokens, extra_text, extra_file_id, self.pool, move self.diagnostics, pool)
            pool = extra_parser.parse_module()
            self.pool = extra_parser.intern
            self.diagnostics = move extra_parser.diags
            self.append_decl_source_paths(pool.decl_count() - before, extra_name, extra_file_id)
        if do_profile:
            let parse_ns = runtime_clock_nanos() - t_parse
            runtime_eprint(f"[profile] frontend.parse  {parse_ns / 1000000}.{(parse_ns % 1000000) / 1000} ms  decls={pool.decl_count()}")

        // #682-inc1: the pool now carries the prelude prefix ahead of user
        // decls — the root file's own decl count excludes it.
        let root_local_decl_count = count_non_use_decls_frontend(pool) - self.prelude_prefix_non_use

        if self.diagnostics.has_errors():
            self.render_all_diagnostics_frontend()
            self.set_resolve_snapshot(ResolveResult.init(), name)
            return AstPool.new()

        if zcu_debug_init_enabled() != 0:
            runtime_eprint("[frontend] compile_source:resolve")
        // Wave 4: sidecar resolved artifact.
        let t_resolve = runtime_clock_nanos()
        var _sp_diag = move self.diagnostics
        var artifacts = resolve_from_root_pool_with_prefix(name, normalized_text, file_id, pool, self.pool, move _sp_diag, false, self.prelude_prefix_decls)
        if do_profile:
            let resolve_ns = runtime_clock_nanos() - t_resolve
            runtime_eprint(f"[profile] frontend.resolve  {resolve_ns / 1000000}.{(resolve_ns % 1000000) / 1000} ms")
        self.pool = artifacts.pool
        self.diagnostics = move artifacts.diags
        self.set_resolve_snapshot(artifacts.result, name)
        self.capture_last_link_lib_names(self.pool, self.last_resolved)
        if self.diagnostics.has_errors():
            // #661: resolve-phase parse errors carry resolve-generation file
            // ids the render lookup can't resolve, so rendering used to fall
            // back to the ROOT text (phantom carets at root EOF). Register the
            // resolved texts for this render only. Registering them on the
            // success path is forbidden: those ids collide with the merge
            // generation's ids and poison every span-derived fact (#667).
            self.register_resolved_source_texts()
            self.render_all_diagnostics_frontend()
            self.set_typed_snapshot("", AstPool.new())
            return AstPool.new()

        if zcu_debug_init_enabled() != 0:
            runtime_eprint("[frontend] compile_source:imports")
        // Build the sema/codegen pool via recursive syntactic import expansion.
        // The prelude closure is already in the pool as the #682-inc1 prefix
        // (its `use` decl sits at position 0); the merge collects that tier
        // from the prefix range and expands only user imports.
        let t_imports = runtime_clock_nanos()
        pool = self.process_imports_frontend(pool)
        if do_profile:
            let imports_ns = runtime_clock_nanos() - t_imports
            runtime_eprint(f"[profile] frontend.imports  {imports_ns / 1000000}.{(imports_ns % 1000000) / 1000} ms")
        let t_cimport = runtime_clock_nanos()
        self.trace_c_import_cache = self.read_trace_c_import_cache_frontend()
        pool = self.expand_c_imports_frontend(pool)
        if do_profile:
            let cimport_ns = runtime_clock_nanos() - t_cimport
            runtime_eprint(f"[profile] frontend.c_import  {cimport_ns / 1000000}.{(cimport_ns % 1000000) / 1000} ms")
        pool.set_local_decl_count(root_local_decl_count)
        self.set_frontend_pool(self.pool)
        frontend_dump_type_decl_names("post-imports", pool, self.pool)

        if self.diagnostics.has_errors():
            self.render_all_diagnostics_frontend()
            self.set_typed_snapshot("", AstPool.new())
            return AstPool.new()

        // D7's trait body carve-out keeps receiver-vs-associated information in
        // the trait signature. Once every import is present, desugar that known
        // receiver into each impl method before either Sema pass observes it.
        pool.inherit_trait_impl_receivers(self.pool)

        // Comptime transform: fold forced comptime expressions and prune dead
        // comptime branches before final sema.
        let t_comptime = runtime_clock_nanos()
        if pool.has_comptime_nodes() or pool.has_type_derives():
            if zcu_debug_init_enabled() != 0:
                runtime_eprint("[frontend] compile_source:comptime-transform")
            var pre_sema = self.configure_tracked_input_sema(Sema.init(self.pool, move self.diagnostics, pool))
            pre_sema.source_text = with_str_clone_ref(text)
            pre_sema.decl_source_paths = sema_clone_str_vec(&self.decl_source_paths)
            pre_sema.decl_source_file_ids = sema_clone_i32_vec(&self.decl_source_file_ids)
            pre_sema.decl_is_c_import = sema_clone_i32_vec(&self.decl_is_c_import)
            pre_sema.source_text_file_ids = sema_clone_i32_vec(&self.source_text_file_ids)
            pre_sema.source_text_names = sema_clone_str_vec(&self.source_text_names)
            pre_sema.source_texts = sema_clone_str_vec(&self.source_texts)
            // PR#713: clone — the same map is handed to pre_sema AND sema below;
            // a shared header is a teardown double-free.
            pre_sema.ci_omitted_symbols = sema_clone_str_str_hashmap(&self.c_import_omitted_symbols)
            pre_sema.tool_mode_entry_path = frontend_owned_text(self.tool_mode_entry_path)
            pre_sema.runtime_available = if self.project_config.runtime_available: 1 else: 0
            pre_sema.runtime_fiber_stack_size = self.project_config.runtime_fiber_stack_size
            pre_sema.runtime_fiber_pool_size = self.project_config.runtime_fiber_pool_size
            pre_sema.runtime_fiber_worker_count = self.project_config.runtime_fiber_worker_count
            pre_sema.copy_warn_threshold = self.project_config.copy_warn_threshold
            pre_sema.emit_config_warnings = 0
            pre_sema.lint_partial_statement_match = if self.project_config.lint_partial_statement_match: 1 else: 0
            pre_sema.overflow_mode = self.project_config.overflow_mode
            pre_sema.init_module_graph(&self.last_resolved)
            pre_sema.prepare_for_comptime_transform()
            // The comptime transform must run against the same intern pool that
            // pre-sema prepared, otherwise cloned AST symbol ids may be resolved
            // against a stale symbol table in the transform pass.
            self.pool = pre_sema.pool
            pool = pre_sema.comptime_transform_module(pool, self.pool)
            self.diagnostics = move pre_sema.diags
            self.decl_source_paths = sema_clone_str_vec(&pre_sema.decl_source_paths)
            self.decl_source_file_ids = sema_clone_i32_vec(&pre_sema.decl_source_file_ids)
            self.decl_is_c_import = sema_clone_i32_vec(&pre_sema.decl_is_c_import)
            self.source_text_file_ids = sema_clone_i32_vec(&pre_sema.source_text_file_ids)
            self.source_text_names = sema_clone_str_vec(&pre_sema.source_text_names)
            self.source_texts = sema_clone_str_vec(&pre_sema.source_texts)
            self.c_import_omitted_symbols = sema_clone_str_str_hashmap(&pre_sema.ci_omitted_symbols)
            var tracked_paths = move self.tracked_input_paths
            self.tracked_input_paths = tracked_input_merge_unique(move tracked_paths, &pre_sema.tracked_input_paths)
            if self.diagnostics.has_errors() and self.analysis_partial_semantics == 0:
                self.render_all_diagnostics_frontend()
                self.set_typed_snapshot("", AstPool.new())
                return AstPool.new()

            // The transform deep-clones function metadata. This is normally a
            // no-op, and also covers any generated trait impls before freeze.
            pool.inherit_trait_impl_receivers(self.pool)

        if do_profile:
            let comptime_ns = runtime_clock_nanos() - t_comptime
            if comptime_ns > 100000:
                runtime_eprint(f"[profile] frontend.comptime  {comptime_ns / 1000000}.{(comptime_ns % 1000000) / 1000} ms")

        // The comptime transform may replace the AstPool and remap every node. Cache
        // only the final pool: MIR preparation must never re-enter Sema with the
        // pre-transform pool against post-transform semantic/intern state.
        self.set_typed_snapshot("", pool)
        // AstPool construction is complete — freeze to catch any future mutations.
        pool.freeze()

        if zcu_debug_init_enabled() != 0:
            runtime_eprint("[frontend] compile_source:sema")
        let t_sema = runtime_clock_nanos()
        var sema = self.configure_tracked_input_sema(Sema.init(self.pool, move self.diagnostics, pool))
        sema.source_text = with_str_clone_ref(text)
        sema.decl_source_paths = sema_clone_str_vec(&self.decl_source_paths)
        sema.decl_source_file_ids = sema_clone_i32_vec(&self.decl_source_file_ids)
        sema.decl_is_c_import = sema_clone_i32_vec(&self.decl_is_c_import)
        sema.source_text_file_ids = sema_clone_i32_vec(&self.source_text_file_ids)
        sema.source_text_names = sema_clone_str_vec(&self.source_text_names)
        sema.source_texts = sema_clone_str_vec(&self.source_texts)
        sema.ci_omitted_symbols = sema_clone_str_str_hashmap(&self.c_import_omitted_symbols)
        sema.tool_mode_entry_path = frontend_owned_text(self.tool_mode_entry_path)
        sema.runtime_available = if self.project_config.runtime_available: 1 else: 0
        sema.runtime_fiber_stack_size = self.project_config.runtime_fiber_stack_size
        sema.runtime_fiber_pool_size = self.project_config.runtime_fiber_pool_size
        sema.runtime_fiber_worker_count = self.project_config.runtime_fiber_worker_count
        sema.copy_warn_threshold = self.project_config.copy_warn_threshold
        sema.lint_partial_statement_match = if self.project_config.lint_partial_statement_match: 1 else: 0
        sema.emit_config_warnings = 1
        sema.overflow_mode = self.project_config.overflow_mode
        if self.project_config.no_std:
            sema.no_std = 1
        if self.project_config.alloc_mode:
            sema.alloc = 1
        sema.init_module_graph(&self.last_resolved)
        sema.check_module()
        if do_profile:
            let sema_ns = runtime_clock_nanos() - t_sema
            runtime_eprint(f"[profile] frontend.sema  {sema_ns / 1000000}.{(sema_ns % 1000000) / 1000} ms  decls={pool.decl_count()}")
        self.diagnostics = move sema.diags
        self.sync_from_sema(move sema)
        frontend_dump_type_decl_names("post-sema", self.last_sema.ast, self.last_sema.pool)
        self.last_typed_dump = ""

        if self.diagnostics.has_errors():
            self.render_all_diagnostics_frontend()
            self.set_typed_snapshot("", AstPool.new())
            return AstPool.new()

        if pool.decl_count() == 0:
            runtime_eprint("error: parser returned an empty module without diagnostics for '" ++ name ++ "'")
            return AstPool.new()

        // Positive completion evidence for the no-silent-fallbacks guard:
        // only this return has run sema. Every earlier bail leaves the
        // marker unset, so a success verdict downstream cannot be minted
        // from a pipeline that silently stopped after parse (03f false-green).
        self.frontend_sema_completed = 1
        pool

    // Make every resolved module's source text findable by file id for
    // diagnostic rendering, regardless of whether its parse produced any
    // decls or the merge loop ever ran (#661).
    mut fn register_resolved_source_texts():
        for mi in 0..self.last_resolved.modules.len() as i32:
            let mod = self.last_resolved.modules.get(mi as i64)
            if mod.module_id == 0 or mod.path.len() == 0:
                continue
            var already = false
            for si in 0..self.source_text_file_ids.len() as i32:
                if self.source_text_file_ids.get(si as i64) == mod.file_id:
                    already = true
                    break
            if already:
                continue
            let embedded_rel = embedded_std_rel_path(mod.path)
            let embedded_rt_rel = embedded_rt_rel_path(mod.path)
            let raw_text = if embedded_rel.len() > 0: embedded_std_source(embedded_rel)
                else if embedded_rt_rel.len() > 0: embedded_rt_source(embedded_rt_rel)
                else: runtime_read_file(mod.path)
            let text = frontend_normalize_source_text(raw_text)
            if text.len() > 0:
                self.add_source_text_mapping(mod.file_id, mod.path, text)

    mut fn merge_resolved_modules_frontend(root_pool: AstPool, root_path: &str) -> AstPool:
        var merged_pool = root_pool

        for mi in 0..self.last_resolved.modules.len() as i32:
            let mod = self.last_resolved.modules.get(mi as i64)
            if mod.module_id == 0:
                continue

            let path = mod.path
            if path.len() == 0 or path == root_path:
                continue

            let text = frontend_normalize_source_text(runtime_read_file(path))
            if text.len() == 0:
                let span = Span { file: 0, start: 0, end: 0 }
                self.diagnostics.emit(Diagnostic.err("failed to read imported module", span))
                continue

            var lexer = Lexer.init(text, mod.file_id)
            let tokens = lexer.tokenize()
            let before = merged_pool.decl_count()
            var parser = Parser.init_with_pool(move tokens, text, mod.file_id, self.pool, move self.diagnostics, merged_pool)
            merged_pool = parser.parse_module()
            self.pool = parser.intern
            self.diagnostics = move parser.diags
            self.add_source_text_mapping(mod.file_id, path, text)
            self.append_decl_source_paths(merged_pool.decl_count() - before, path, mod.file_id)

        self.strip_use_decls_frontend(merged_pool)

    mut fn strip_use_decls_frontend(pool: AstPool) -> AstPool:
        var out = pool
        var has_use = 0
        for i in 0..out.decl_count():
            let decl = out.get_decl(i)
            if out.kind(decl) == NodeKind.NK_USE_DECL:
                has_use = 1
                break
        if has_use == 0:
            return out

        let ordered: Vec[i32] = Vec.new()
        let ordered_paths = frontend_new_vec_str()
        let ordered_file_ids: Vec[i32] = Vec.new()
        let ordered_c_import: Vec[i32] = Vec.new()
        for i in 0..out.decl_count():
            let decl = out.get_decl(i)
            if out.kind(decl) != NodeKind.NK_USE_DECL or out.get_data2(decl) > 0:
                ordered.push(decl as i32)
                ordered_paths.push(frontend_owned_text(self.decl_source_path_frontend(i)))
                ordered_file_ids.push(self.decl_source_file_id_frontend(i))
                let ci_flag = if i < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(i as i64) else: 0
                ordered_c_import.push(ci_flag)

        while out.decl_count() > 0:
            out.state.decls.pop()
        for oi in 0..ordered.len() as i32:
            out.add_decl(ordered.get(oi as i64))
        self.decl_source_paths = ordered_paths
        self.decl_source_file_ids = ordered_file_ids
        self.decl_is_c_import = ordered_c_import
        out

    mut fn process_imports_frontend(pool: AstPool) -> AstPool:
        // Three-tier import resolution (later-wins in the decl list):
        //   1. Prelude imports   (lowest priority — first in list)
        //   2. Explicit user imports (middle)
        //   3. Root-file definitions (highest — last in list)
        // Shadowed fn/extern_fn decls are dropped entirely so the sema and
        // codegen never see the duplicate.
        var merged_pool = pool
        let initial_count = merged_pool.decl_count()
        if initial_count > 0:
            let root_src_path = self.decl_source_path_frontend(0)
            if root_src_path.len() > 0 and self.has_imported_path(root_src_path) == 0:
                self.add_imported_path(root_src_path)
        var prelude_ordered: Vec[i32] = Vec.new()
        var prelude_paths = frontend_new_vec_str()
        var prelude_file_ids: Vec[i32] = Vec.new()
        var prelude_c_import: Vec[i32] = Vec.new()
        var user_import_ordered: Vec[i32] = Vec.new()
        var user_import_paths = frontend_new_vec_str()
        var user_import_file_ids: Vec[i32] = Vec.new()
        var user_import_c_import: Vec[i32] = Vec.new()
        var root_ordered: Vec[i32] = Vec.new()
        var root_paths = frontend_new_vec_str()
        var root_file_ids: Vec[i32] = Vec.new()
        var root_c_import: Vec[i32] = Vec.new()

        // Phase 1: Expand prelude USE (position 0) and its transitive imports.
        let has_prelude = self.prelude_mode != PRELUDE_NONE() and initial_count > 0 and merged_pool.kind(merged_pool.get_decl(0)) == NodeKind.NK_USE_DECL
        if has_prelude:
            let first = merged_pool.get_decl(0)
            let ps = merged_pool.get_data0(first)
            let pc = merged_pool.get_data1(first)
            if pc > 0:
                let pname = self.use_path_name_frontend(merged_pool, ps, pc)
                let fpath = self.resolve_module_path_frontend(pname, self.decl_source_dir_frontend(0))
                if fpath.len() > 0 and self.has_imported_path(fpath) == 0:
                    self.add_imported_path(fpath)
                    merged_pool = self.parse_imported_file_frontend(fpath, merged_pool)
                else if fpath.len() == 0:
                    self.emit_missing_import_frontend(merged_pool, first)
            // Scan the prelude-closure decls. #682-inc1: when the frontend
            // pre-expanded the closure, it sits at the deterministic PREFIX
            // [1..prelude_prefix_decls) ahead of the user decls (and the
            // use-expansion above deduped to a no-op); otherwise (legacy
            // entries) the closure was just appended from initial_count on.
            // Nested USE decls get expanded transitively either way.
            let prefix_decls = self.prelude_prefix_decls
            var pi = if prefix_decls > 0: 1 else: initial_count
            while (prefix_decls > 0 and pi < prefix_decls) or (prefix_decls == 0 and pi < merged_pool.decl_count()):
                let decl = merged_pool.get_decl(pi)
                let kind = merged_pool.kind(decl)
                if kind != NodeKind.NK_USE_DECL:
                    prelude_ordered.push(decl as i32)
                    prelude_paths.push(self.decl_source_path_frontend(pi))
                    prelude_file_ids.push(self.decl_source_file_id_frontend(pi))
                    prelude_c_import.push(if pi < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(pi as i64) else: 0)
                    pi = pi + 1
                    continue
                let pps = merged_pool.get_data0(decl)
                let ppc = merged_pool.get_data1(decl)
                if ppc > 0:
                    if self.use_decl_is_local_type_selector_frontend(merged_pool, decl):
                        prelude_ordered.push(decl as i32)
                        prelude_paths.push(self.decl_source_path_frontend(pi))
                        prelude_file_ids.push(self.decl_source_file_id_frontend(pi))
                        prelude_c_import.push(if pi < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(pi as i64) else: 0)
                    else:
                        let ppname = self.use_path_name_frontend(merged_pool, pps, ppc)
                        let ppfpath = self.resolve_module_path_frontend(ppname, self.decl_source_dir_frontend(pi))
                        if ppfpath.len() > 0 and self.has_imported_path(ppfpath) == 0:
                            self.add_imported_path(ppfpath)
                            merged_pool = self.parse_imported_file_frontend(ppfpath, merged_pool)
                        else if ppfpath.len() == 0:
                            self.emit_missing_import_frontend(merged_pool, decl)
                pi = pi + 1
        let after_prelude = merged_pool.decl_count()

        // Phase 2: Process root-file decls. With the #682-inc1 prefix they
        // start after it; legacy entries start right after the use decl.
        let user_start = if self.prelude_prefix_decls > 0: self.prelude_prefix_decls else: if has_prelude: 1 else: 0
        for ui in user_start..initial_count:
            let decl = merged_pool.get_decl(ui)
            let kind = merged_pool.kind(decl)
            if kind != NodeKind.NK_USE_DECL:
                root_ordered.push(decl as i32)
                root_paths.push(self.decl_source_path_frontend(ui))
                root_file_ids.push(self.decl_source_file_id_frontend(ui))
                root_c_import.push(if ui < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(ui as i64) else: 0)
                continue
            let ups = merged_pool.get_data0(decl)
            let upc = merged_pool.get_data1(decl)
            if upc > 0:
                if self.use_decl_is_local_type_selector_frontend(merged_pool, decl):
                    root_ordered.push(decl as i32)
                    root_paths.push(self.decl_source_path_frontend(ui))
                    root_file_ids.push(self.decl_source_file_id_frontend(ui))
                    root_c_import.push(if ui < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(ui as i64) else: 0)
                else:
                    let upname = self.use_path_name_frontend(merged_pool, ups, upc)
                    let upfpath = self.resolve_module_path_frontend(upname, self.decl_source_dir_frontend(ui))
                    if upfpath.len() > 0 and self.has_imported_path(upfpath) == 0:
                        self.add_imported_path(upfpath)
                        merged_pool = self.parse_imported_file_frontend(upfpath, merged_pool)
                    else if upfpath.len() == 0:
                        self.emit_missing_import_frontend(merged_pool, decl)

        // Scan decls added by user-import expansion (from after_prelude onward).
        var ui2 = after_prelude
        while ui2 < merged_pool.decl_count():
            let decl = merged_pool.get_decl(ui2)
            let kind = merged_pool.kind(decl)
            if kind != NodeKind.NK_USE_DECL:
                user_import_ordered.push(decl as i32)
                user_import_paths.push(self.decl_source_path_frontend(ui2))
                user_import_file_ids.push(self.decl_source_file_id_frontend(ui2))
                user_import_c_import.push(if ui2 < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(ui2 as i64) else: 0)
                ui2 = ui2 + 1
                continue
            let ups = merged_pool.get_data0(decl)
            let upc = merged_pool.get_data1(decl)
            if upc > 0:
                if self.use_decl_is_local_type_selector_frontend(merged_pool, decl):
                    user_import_ordered.push(decl as i32)
                    user_import_paths.push(self.decl_source_path_frontend(ui2))
                    user_import_file_ids.push(self.decl_source_file_id_frontend(ui2))
                    user_import_c_import.push(if ui2 < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(ui2 as i64) else: 0)
                else:
                    let upname = self.use_path_name_frontend(merged_pool, ups, upc)
                    let upfpath = self.resolve_module_path_frontend(upname, self.decl_source_dir_frontend(ui2))
                    if upfpath.len() > 0 and self.has_imported_path(upfpath) == 0:
                        self.add_imported_path(upfpath)
                        merged_pool = self.parse_imported_file_frontend(upfpath, merged_pool)
                    else if upfpath.len() == 0:
                        self.emit_missing_import_frontend(merged_pool, decl)
            ui2 = ui2 + 1

        var prelude_reordered = self.reorder_import_tier_frontend(prelude_ordered, prelude_paths, prelude_file_ids, prelude_c_import)
        prelude_ordered = move prelude_reordered.decls
        prelude_paths = move prelude_reordered.paths
        prelude_file_ids = move prelude_reordered.file_ids
        prelude_c_import = move prelude_reordered.ci_flags

        var user_reordered = self.reorder_import_tier_frontend(user_import_ordered, user_import_paths, user_import_file_ids, user_import_c_import)
        user_import_ordered = move user_reordered.decls
        user_import_paths = move user_reordered.paths
        user_import_file_ids = move user_reordered.file_ids
        user_import_c_import = move user_reordered.ci_flags

        // Collect fn names from higher-priority tiers for deduplication.
        var root_fn_names: Vec[i32] = Vec.new()
        for ri in 0..root_ordered.len() as i32:
            let rd = root_ordered.get(ri as i64)
            let rk = merged_pool.kind(rd)
            if rk == NodeKind.NK_FN_DECL or rk == NodeKind.NK_EXTERN_FN:
                root_fn_names.push(merged_pool.get_data0(rd))

        var user_fn_names: Vec[i32] = Vec.new()
        for ui in 0..user_import_ordered.len() as i32:
            let ud = user_import_ordered.get(ui as i64)
            let uk = merged_pool.kind(ud)
            if uk == NodeKind.NK_FN_DECL or uk == NodeKind.NK_EXTERN_FN:
                user_fn_names.push(merged_pool.get_data0(ud))

        var higher_type_names: Vec[i32] = Vec.new()
        for ri in 0..root_ordered.len() as i32:
            let rd = root_ordered.get(ri as i64)
            if merged_pool.kind(rd) == NodeKind.NK_TYPE_DECL:
                higher_type_names.push(merged_pool.get_data0(rd))
        for ui in 0..user_import_ordered.len() as i32:
            let ud = user_import_ordered.get(ui as i64)
            if merged_pool.kind(ud) == NodeKind.NK_TYPE_DECL:
                higher_type_names.push(merged_pool.get_data0(ud))

        // Rebuild decl list: prelude → user imports → root.
        // Drop fn/extern_fn decls shadowed by a higher-priority tier.
        while merged_pool.decl_count() > 0:
            merged_pool.state.decls.pop()
        let rebuilt_paths = frontend_new_vec_str()
        let rebuilt_file_ids: Vec[i32] = Vec.new()
        let rebuilt_c_import: Vec[i32] = Vec.new()
        // Combine user + root fn names for prelude cross-tier shadowing.
        var higher_fn_names: Vec[i32] = Vec.new()
        for hi in 0..root_fn_names.len() as i32:
            higher_fn_names.push(root_fn_names.get(hi as i64))
        for hi in 0..user_fn_names.len() as i32:
            higher_fn_names.push(user_fn_names.get(hi as i64))
        // D30 R2c: runtime DEFINITIONS (bodied fns from <embedded-rt>/) are
        // never decl-dropped by a bodiless extern in a higher tier — the
        // extern is the redundant one (its symbol resolves in-unit) and is
        // dropped from the higher tier instead. Higher-tier BODIED fns
        // still shadow normally. Empty outside the WITH_RT_IN_UNIT lane.
        var embedded_rt_fn_names: Vec[i32] = Vec.new()
        var higher_bodied_fn_names: Vec[i32] = Vec.new()
        for oi in 0..prelude_ordered.len() as i32:
            let pd = prelude_ordered.get(oi as i64)
            if merged_pool.kind(pd) == NodeKind.NK_FN_DECL and prelude_paths.get(oi as i64).starts_with("<embedded-rt>/"):
                embedded_rt_fn_names.push(merged_pool.get_data0(pd))
        for ri in 0..root_ordered.len() as i32:
            let rd = root_ordered.get(ri as i64)
            if merged_pool.kind(rd) == NodeKind.NK_FN_DECL:
                higher_bodied_fn_names.push(merged_pool.get_data0(rd))
        for ui in 0..user_import_ordered.len() as i32:
            let ud = user_import_ordered.get(ui as i64)
            if merged_pool.kind(ud) == NodeKind.NK_FN_DECL:
                higher_bodied_fn_names.push(merged_pool.get_data0(ud))
        // D29 scaffolding (#750): NON-GENERIC user type declarations shadow
        // prelude/std types through Sema's tier-aware resolution (std
        // blindness + the §18.2 import gate + per-tier codegen symbols).
        // The Box/Rc module drops below stay: a user GENERIC Box/Rc is
        // outside the shadow mask (generic identity waits on #751), and the
        // std-Box/Rc special-casing keys type paths by flat symbol — both
        // generic Boxes coexisting mislays std Box's pointer representation
        // (invalid frees). Leaf-module drops remain sound. FN decls shadow
        // by decl-drop: the flat signature table holds one entry per symbol.
        for oi in 0..prelude_ordered.len() as i32:
            let id = prelude_ordered.get(oi as i64)
            let ik = merged_pool.kind(id)
            let prelude_path = prelude_paths.get(oi as i64)
            if frontend_path_is_std_box_module(prelude_path) and frontend_vec_contains_i32(higher_type_names, self.pool.intern("Box")):
                continue
            if frontend_path_is_std_rc_module(prelude_path) and (frontend_vec_contains_i32(higher_type_names, self.pool.intern("Rc")) or frontend_vec_contains_i32(higher_type_names, self.pool.intern("Arc"))):
                continue
            // Runtime defs ignore higher-tier EXTERNS (def-wins: the extern
            // is dropped from its tier instead) but keep within-tier dedupe
            // and still yield to higher-tier BODIED fns.
            let rt_def = ik == NodeKind.NK_FN_DECL and prelude_path.starts_with("<embedded-rt>/")
            let shadow_names = if rt_def: &higher_bodied_fn_names else: &higher_fn_names
            if (ik == NodeKind.NK_FN_DECL or ik == NodeKind.NK_EXTERN_FN) and frontend_fn_shadowed_in_tier(prelude_ordered, prelude_paths, merged_pool, self.pool, oi, shadow_names):
                // Error when a prelude fn (with a body) is shadowed by an extern fn
                // (no body). The extern silently replaces the real function with an
                // unresolved C symbol, causing a cryptic linker error later.
                if ik == NodeKind.NK_FN_DECL:
                    let shadowed_name = merged_pool.get_data0(id)
                    if frontend_name_shadowed_by_extern(root_ordered, merged_pool, shadowed_name):
                        let sname = self.pool.resolve(shadowed_name)
                        self.diagnostics.emit(Diagnostic.err(f"extern fn '{sname}' shadows prelude function '{sname}'", Span { file: 0, start: merged_pool.get_start(id), end: merged_pool.get_end(id) }))
                continue
            if ik == NodeKind.NK_EXTERN_VAR:
                if frontend_extern_var_shadowed_in_tier(prelude_ordered, merged_pool, self.pool, oi) or frontend_extern_var_shadowed_by_tier(user_import_ordered, merged_pool, self.pool, id) or frontend_extern_var_shadowed_by_tier(root_ordered, merged_pool, self.pool, id):
                    continue
            merged_pool.add_decl(id)
            rebuilt_paths.push(frontend_owned_text(prelude_path))
            rebuilt_file_ids.push(prelude_file_ids.get(oi as i64))
            rebuilt_c_import.push(prelude_c_import.get(oi as i64))
        for oi in 0..user_import_ordered.len() as i32:
            let id = user_import_ordered.get(oi as i64)
            let ik = merged_pool.kind(id)
            if ik == NodeKind.NK_EXTERN_FN and frontend_vec_contains_i32(embedded_rt_fn_names, merged_pool.get_data0(id)):
                continue
            if (ik == NodeKind.NK_FN_DECL or ik == NodeKind.NK_EXTERN_FN) and frontend_fn_shadowed_in_tier(user_import_ordered, user_import_paths, merged_pool, self.pool, oi, root_fn_names):
                continue
            if ik == NodeKind.NK_EXTERN_VAR:
                if frontend_extern_var_shadowed_in_tier(user_import_ordered, merged_pool, self.pool, oi) or frontend_extern_var_shadowed_by_tier(root_ordered, merged_pool, self.pool, id):
                    continue
            merged_pool.add_decl(id)
            rebuilt_paths.push(frontend_owned_text(user_import_paths.get(oi as i64)))
            rebuilt_file_ids.push(user_import_file_ids.get(oi as i64))
            rebuilt_c_import.push(user_import_c_import.get(oi as i64))
        for oi in 0..root_ordered.len() as i32:
            let id = root_ordered.get(oi as i64)
            let ik = merged_pool.kind(id)
            if ik == NodeKind.NK_EXTERN_FN and frontend_vec_contains_i32(embedded_rt_fn_names, merged_pool.get_data0(id)):
                continue
            if ik == NodeKind.NK_EXTERN_VAR and frontend_extern_var_shadowed_in_tier(root_ordered, merged_pool, self.pool, oi):
                continue
            merged_pool.add_decl(id)
            rebuilt_paths.push(frontend_owned_text(root_paths.get(oi as i64)))
            rebuilt_file_ids.push(root_file_ids.get(oi as i64))
            rebuilt_c_import.push(root_c_import.get(oi as i64))
        self.decl_source_paths = rebuilt_paths
        self.decl_source_file_ids = rebuilt_file_ids
        self.decl_is_c_import = rebuilt_c_import
        merged_pool

fn frontend_path_is_std_box_module(path: &str) -> bool:
    if path == "lib/std/box.w" or path == "<embedded-std>/std/box.w":
        return true
    if path.ends_with("/lib/std/box.w") or path.ends_with("\\lib\\std\\box.w"):
        return true
    false

fn frontend_path_is_std_rc_module(path: &str) -> bool:
    if path == "lib/std/rc.w" or path == "<embedded-std>/std/rc.w":
        return true
    if path.ends_with("/lib/std/rc.w") or path.ends_with("\\lib\\std\\rc.w"):
        return true
    false

fn frontend_name_shadowed_by_extern(tier: &Vec[i32], pool: AstPool, name: i32) -> bool:
    for i in 0..tier.len() as i32:
        let d = tier.get(i as i64)
        if pool.kind(d) == NodeKind.NK_EXTERN_FN and pool.get_data0(d) == name:
            return true
    false

fn frontend_fn_decl_rank(kind: i32) -> i32:
    if kind == NodeKind.NK_FN_DECL:
        return 2
    if kind == NodeKind.NK_EXTERN_FN:
        return 1
    0

fn frontend_fn_decl_is_method(pool: AstPool, intern: InternPool, decl: i32) -> bool:
    if pool.kind(decl) != NodeKind.NK_FN_DECL:
        return false
    frontend_str_contains_byte(intern.resolve(pool.get_data0(decl)), 46)

fn frontend_fn_decl_is_generic(pool: AstPool, decl: i32) -> bool:
    if pool.kind(decl) != NodeKind.NK_FN_DECL:
        return false
    let meta = pool.find_fn_meta(decl as NodeId)
    meta >= 0 and pool.fn_meta_tp_count(meta) > 0

fn frontend_fn_shadowed_in_tier(tier: &Vec[i32], paths: &Vec[str], pool: AstPool, intern: InternPool, idx: i32, higher_names: &Vec[i32]) -> bool:
    // Check if this fn is shadowed by a higher-priority tier.
    let current = tier.get(idx as i64)
    let current_kind = pool.kind(current)
    if frontend_fn_decl_is_method(pool, intern, current):
        return false
    let iname = pool.get_data0(current)
    if frontend_vec_contains_i32(higher_names, iname):
        return true

    // Within-tier precedence:
    // - a real fn beats any extern fn of the same name, regardless of order
    // - otherwise, a later decl of the same rank wins
    if current_kind == NodeKind.NK_EXTERN_FN:
        for j in 0..tier.len() as i32:
            if j == idx:
                continue
            let jd = tier.get(j as i64)
            if pool.kind(jd) == NodeKind.NK_FN_DECL and pool.get_data0(jd) == iname:
                return true
        return false

    let current_rank = frontend_fn_decl_rank(current_kind)
    var j = idx + 1
    while j < tier.len() as i32:
        let jd = tier.get(j as i64)
        let jk = pool.kind(jd)
        if (jk == NodeKind.NK_FN_DECL or jk == NodeKind.NK_EXTERN_FN) and pool.get_data0(jd) == iname:
            // Same-module generic declarations are structural overload
            // candidates, not shadowing declarations. Keep each template for
            // sema to select after argument types are known. A same-name fn
            // from another module still follows normal later-wins import rules.
            if frontend_fn_decl_is_generic(pool, current) and frontend_fn_decl_is_generic(pool, jd) and paths.get(idx as i64) == paths.get(j as i64):
                j = j + 1
                continue
            let other_rank = frontend_fn_decl_rank(jk)
            if other_rank >= current_rank:
                return true
        j = j + 1
    false

fn frontend_global_decl_mut(pool: AstPool, decl: i32) -> i32:
    let kind = pool.kind(decl)
    if kind == NodeKind.NK_EXTERN_VAR:
        return if pool.get_data2(decl) != 0: 1 else: 0
    if kind == NodeKind.NK_LET_DECL:
        return pool.get_data2(decl) % 2
    -1

fn frontend_global_decl_type_text(pool: AstPool, intern: InternPool, decl: i32) -> str:
    let kind = pool.kind(decl)
    if kind == NodeKind.NK_EXTERN_VAR:
        return render_type_expr(pool, intern, (pool.get_data1(decl)) as NodeId)
    if kind == NodeKind.NK_LET_DECL:
        let type_ann = top_level_let_type_ann(pool, pool.get_data2(decl))
        if type_ann != 0:
            return render_type_expr(pool, intern, (type_ann) as NodeId)
    ""

fn frontend_extern_var_matches_decl(pool: AstPool, intern: InternPool, decl: i32, other: i32) -> bool:
    if pool.kind(decl) != NodeKind.NK_EXTERN_VAR:
        return false
    let other_kind = pool.kind(other)
    if other_kind != NodeKind.NK_EXTERN_VAR and other_kind != NodeKind.NK_LET_DECL:
        return false
    if pool.get_data0(other) != pool.get_data0(decl):
        return false
    if frontend_global_decl_mut(pool, other) != frontend_global_decl_mut(pool, decl):
        return false
    let decl_type = frontend_global_decl_type_text(pool, intern, decl)
    let other_type = frontend_global_decl_type_text(pool, intern, other)
    if decl_type.len() == 0 or other_type.len() == 0:
        return false
    other_type == decl_type

fn frontend_extern_var_shadowed_by_tier(tier: &Vec[i32], pool: AstPool, intern: InternPool, decl: i32) -> bool:
    for i in 0..tier.len() as i32:
        if frontend_extern_var_matches_decl(pool, intern, decl, tier.get(i as i64)):
            return true
    false

fn frontend_extern_var_shadowed_in_tier(tier: &Vec[i32], pool: AstPool, intern: InternPool, idx: i32) -> bool:
    let decl = tier.get(idx as i64)
    for j in 0..tier.len() as i32:
        if j == idx:
            continue
        let jd = tier.get(j as i64)
        if pool.kind(jd) == NodeKind.NK_LET_DECL and frontend_extern_var_matches_decl(pool, intern, decl, jd):
            return true
    var j = idx + 1
    while j < tier.len() as i32:
        let jd = tier.get(j as i64)
        if pool.kind(jd) == NodeKind.NK_EXTERN_VAR:
            if frontend_extern_var_matches_decl(pool, intern, decl, jd):
                return true
        j = j + 1
    false

fn frontend_vec_contains_i32(v: &Vec[i32], target: i32) -> bool:
    for i in 0..v.len() as i32:
        if v.get(i as i64) == target:
            return true
    false

impl Zcu:
    fn find_module_id_by_path_frontend(path: &str) -> i32:
        for mi in 0..self.last_resolved.modules.len() as i32:
            let mod = self.last_resolved.modules.get(mi as i64)
            if mod.path == path:
                return mod.module_id
        -1

type DepOrderAccumState {
    order: Vec[str],
    seen: HashMap[str, i32],
}

type DepOrderAccum {
    state: *mut DepOrderAccumState,
}
impl Copy for DepOrderAccum

fn DepOrderAccum.new() -> DepOrderAccum:
    let ptr = with_alloc(64) as *mut DepOrderAccumState
    unsafe:
        *ptr = DepOrderAccumState { order: Vec.new(), seen: HashMap.new() }
    DepOrderAccum { state: ptr }

type ReorderedTier {
    decls: Vec[i32],
    paths: Vec[str],
    file_ids: Vec[i32],
    ci_flags: Vec[i32],
}

impl Zcu:
    fn collect_module_dependency_order_frontend(path: &str, wanted_paths: &HashMap[str, i32], accum: DepOrderAccum) -> Unit:
        if path.len() == 0:
            return
        if accum.state.seen.contains(path):
            return
        accum.state.seen.insert(frontend_owned_text(path), 1)
        let module_id = self.find_module_id_by_path_frontend(path)
        if module_id >= 0:
            let mod = self.last_resolved.modules.get(module_id as i64)
            for ii in 0..mod.import_count:
                let imp = self.last_resolved.imports.get((mod.import_start + ii) as i64)
                if imp.target_module < 0:
                    continue
                let dep = self.last_resolved.modules.get(imp.target_module as i64)
                if wanted_paths.contains(with_str_clone_ref(dep.path)):
                    self.collect_module_dependency_order_frontend(dep.path, wanted_paths, accum)
        accum.state.order.push(frontend_owned_text(path))

    fn reorder_import_tier_frontend(decls: &Vec[i32], paths: &Vec[str], file_ids: &Vec[i32], ci_flags: &Vec[i32]) -> ReorderedTier:
        let wanted_paths: HashMap[str, i32] = HashMap.new()
        let first_seen_paths = frontend_new_vec_str()
        for i in 0..paths.len() as i32:
            let path = paths.get(i as i64)
            if path.len() == 0:
                continue
            if wanted_paths.contains(path):
                continue
            wanted_paths.insert(frontend_owned_text(path), 1)
            first_seen_paths.push(frontend_owned_text(path))

        let accum = DepOrderAccum.new()
        for i in 0..first_seen_paths.len() as i32:
            self.collect_module_dependency_order_frontend(first_seen_paths.get(i as i64), wanted_paths, accum)

        let module_order = accum.state.order
        let out_decls: Vec[i32] = Vec.new()
        let out_paths = frontend_new_vec_str()
        let out_file_ids: Vec[i32] = Vec.new()
        let out_c_import: Vec[i32] = Vec.new()
        for oi in 0..module_order.len() as i32:
            let module_path = module_order.get(oi as i64)
            for di in 0..decls.len() as i32:
                if paths.get(di as i64) != module_path:
                    continue
                out_decls.push(decls.get(di as i64))
                out_paths.push(frontend_owned_text(paths.get(di as i64)))
                out_file_ids.push(file_ids.get(di as i64))
                out_c_import.push(ci_flags.get(di as i64))
        for di in 0..decls.len() as i32:
            let path = paths.get(di as i64)
            if path.len() != 0:
                continue
            out_decls.push(decls.get(di as i64))
            out_paths.push(frontend_owned_text(path))
            out_file_ids.push(file_ids.get(di as i64))
            out_c_import.push(ci_flags.get(di as i64))
        ReorderedTier { decls: out_decls, paths: out_paths, file_ids: out_file_ids, ci_flags: out_c_import }

fn frontend_parent_module_rel(module_rel: &str) -> str:
    var last_slash = -1
    for i in 0..module_rel.len():
        if module_rel[i] == 47:
            last_slash = i as i32
    if last_slash <= 0:
        return ""
    module_rel.slice(0, last_slash as i64)

fn frontend_resolve_module_rel(module_dir: &str, rel_path: &str) -> str:
    let cand1 = resolve_join(module_dir, rel_path)
    if resolve_file_exists(cand1):
        return cand1

    let parent_walk = resolve_parent_lib_candidate(module_dir, rel_path)
    if parent_walk.len() > 0:
        return parent_walk

    let rooted = resolve_project_root_candidate(module_dir, rel_path)
    if rooted.len() > 0:
        return rooted

    // Generated With modules live under out/gen but still participate in
    // normal module resolution. They are source modules, not runtime exports.
    let gen_cand = resolve_join("out/gen", rel_path)
    if resolve_file_exists(gen_cand):
        return gen_cand

    let cand5 = resolve_join("src", rel_path)
    if resolve_file_exists(cand5):
        return cand5

    let cand6 = resolve_join("lib", rel_path)
    if resolve_file_exists(cand6):
        return cand6

    ""

impl Zcu:
    fn use_path_name_frontend(pool: AstPool, path_start: i32, path_count: i32) -> str:
        var path = ""
        for pi in 0..path_count:
            if pi > 0:
                path = path ++ "/"
            let seg = pool.get_extra(path_start + pi)
            path = path ++ self.pool.resolve(seg)
        path

fn frontend_pool_has_type_decl_named(pool: AstPool, sym: i32) -> bool:
    if sym == 0:
        return false
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) == NodeKind.NK_TYPE_DECL and pool.get_data0(decl) == sym:
            return true
    false

impl Zcu:
    fn use_decl_is_local_type_selector_frontend(pool: AstPool, decl: i32) -> bool:
        if pool.kind(decl) != NodeKind.NK_USE_DECL:
            return false
        let selector_count = pool.get_data2(decl)
        if selector_count <= 0:
            return false
        let path_start = pool.get_data0(decl)
        let path_count = pool.get_data1(decl)
        if path_count != 1:
            return false
        let type_sym = pool.get_extra(path_start)
        frontend_pool_has_type_decl_named(pool, type_sym)

    fn resolve_module_path_frontend(module_name: &str, source_dir_raw: &str) -> str:
        let module_rel = frontend_normalize_module_path(module_name)
        let rel_primary = module_rel ++ ".w"
        let rel_fallback = if frontend_parent_module_rel(module_rel).len() > 0: frontend_parent_module_rel(module_rel) ++ ".w" else: ""

        if embedded_std_is_module_rel(module_rel):
            let embedded_primary = embedded_std_resolve_path(rel_primary)
            if embedded_primary.len() > 0:
                return embedded_primary
            if rel_fallback.len() > 0:
                let embedded_fallback = embedded_std_resolve_path(rel_fallback)
                if embedded_fallback.len() > 0:
                    return embedded_fallback
            // Not embedded — fall through to filesystem resolution

        let source_dir = if source_dir_raw.len() > 0: with_str_clone_ref(source_dir_raw) else: self.source_dir
        let has_root_fallback = source_dir != self.source_dir

        let primary = frontend_resolve_module_rel(source_dir, rel_primary)
        if primary.len() > 0:
            return primary
        if has_root_fallback:
            let root_primary = frontend_resolve_module_rel(self.source_dir, rel_primary)
            if root_primary.len() > 0:
                return root_primary
        if rel_fallback.len() > 0:
            let fallback = frontend_resolve_module_rel(source_dir, rel_fallback)
            if fallback.len() > 0:
                return fallback
            if has_root_fallback:
                return frontend_resolve_module_rel(self.source_dir, rel_fallback)
        ""

    mut fn parse_imported_file_frontend(path: &str, target_pool: AstPool) -> AstPool:
        let embedded_rel = embedded_std_rel_path(path)
        let embedded_rt_rel = embedded_rt_rel_path(path)
        let raw_text = if embedded_rel.len() > 0: embedded_std_source(embedded_rel)
            else if embedded_rt_rel.len() > 0: embedded_rt_source(embedded_rt_rel)
            else: runtime_read_file(path)
        let text = frontend_normalize_source_text(raw_text)
        if text.len() == 0:
            return target_pool

        let before = target_pool.decl_count()
        let file_id = self.next_file_id
        self.next_file_id = self.next_file_id + 1
        self.add_source_text_mapping(file_id, path, text)

        var lexer = Lexer.init(text, file_id)
        let tokens = lexer.tokenize()

        var parser = Parser.init_with_pool(move tokens, text, file_id, self.pool, move self.diagnostics, target_pool)
        let merged_pool = parser.parse_module()
        self.pool = parser.intern
        self.diagnostics = move parser.diags
        self.append_decl_source_paths(merged_pool.decl_count() - before, path, file_id)
        merged_pool

fn frontend_normalize_module_path(module_name: &str) -> str:
    var out = ""
    for i in 0..module_name.len():
        if module_name[i] == 46: // '.'
            out = out ++ "/"
        else:
            out = out ++ module_name.slice(i as i64, (i + 1) as i64)
    out

fn frontend_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len():
        if path[i] == 47: // '/'
            last_slash = i as i32
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)
