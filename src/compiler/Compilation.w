use Ast
use Diagnostic
use Resolve
use InternPool
use Sema
use Span
use Mir
use MirLower
use MirSuspendCheck
use AsyncMir
use AsyncLower
use CCodegen
use render
use compiler.Compilation.Config
use compiler.Backend
use compiler.CodegenUnits
use compiler.Frontend
use compiler.Link
use compiler.ProjectConfig
use compiler.DriverOptions
use compiler.AbiStamp
use compiler.BundleInterfaces
use compiler.BundleInterfaceEmit
use compiler.BundleFingerprint
use compiler.EmbeddedBundles
use FnAbi
use compiler.Zcu
use compiler.Runtime
use Overflow
use Analysis
use TargetSpec

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn wl_set_active_target_triple(triple: &str) -> Unit
extern fn with_str_clone_ref(s: &str) -> str

fn profile_enabled() -> bool:
    runtime_getenv("WITH_PROFILE").len() > 0

fn profile_now() -> i64:
    runtime_clock_nanos()

fn profile_emit(name: &str, start: i64, counters: &str):
    let elapsed_ns = runtime_clock_nanos() - start
    let ms_whole = elapsed_ns / 1000000
    let ms_frac = (elapsed_ns % 1000000) / 1000
    if counters.len() > 0:
        runtime_eprint(f"[profile] {name}  {ms_whole}.{ms_frac} ms  {counters}")
    else:
        runtime_eprint(f"[profile] {name}  {ms_whole}.{ms_frac} ms")

fn compilation_debug_init_enabled() -> i32:
    let raw = runtime_getenv("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn compilation_debug_init(msg: &str):
    if compilation_debug_init_enabled() == 0:
        return
    runtime_eprint("[comp-init] " ++ msg)

fn compilation_debug_pool_flow_enabled() -> i32:
    let raw = runtime_getenv("WITH_DEBUG_POOL_FLOW")
    if raw.len() == 0:
        return 0
    1

fn compilation_debug_pool_flow(label: &str, pool: InternPool, typed_pool: AstPool, sema: &Sema):
    if compilation_debug_pool_flow_enabled() == 0:
        return
    runtime_eprint(f"[comp] {label} pool.symbols={pool.state.symbol_texts.len() as i32} typed.decls={typed_pool.decl_count()} sema.pool.symbols={sema.pool.state.symbol_texts.len() as i32} sema.ast.decls={sema.ast.decl_count()}")

fn compilation_ensure_output_dir(path: &str) -> bool:
    if path.len() == 0:
        return true
    let rc = runtime_mkdir_p(path)
    if rc != 0:
        runtime_eprint(f"error: failed to create output directory '{path}'")
        return false
    true

fn compilation_remove_file_best_effort(path: &str):
    if path.len() == 0:
        return
    let _ = runtime_remove_file(path)

fn compilation_remove_tree_best_effort(path: &str):
    if path.len() == 0:
        return
    let _ = runtime_remove_tree(path)

fn compilation_remove_dsym_best_effort(bin_path: &str):
    if bin_path.len() == 0:
        return
    compilation_remove_tree_best_effort(bin_path ++ ".dSYM")

fn compilation_argv_append(argv: &str, arg: &str) -> str:
    argv ++ arg ++ "\0"

fn compilation_run_dsymutil_best_effort(bin_path: &str):
    if bin_path.len() == 0:
        return
    var argv = ""
    argv = compilation_argv_append(argv, "dsymutil")
    argv = compilation_argv_append(argv, bin_path)
    let _ = runtime_exec_argv_capture(argv, "/dev/null", "/dev/null", 0)

fn compilation_debug_type_names_enabled() -> i32:
    let raw = runtime_getenv("WITH_DEBUG_TYPE_NAMES")
    if raw.len() == 0:
        return 0
    if raw == "0":
        return 0
    1

fn compilation_dump_type_names(stage: &str, pool: AstPool, intern: InternPool):
    if compilation_debug_type_names_enabled() == 0:
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

fn compilation_find_fn_decl_index(pool: AstPool, fn_sym: i32) -> i32:
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        if pool.get_data0(decl) == fn_sym:
            return di
    -1

fn compilation_mir_error_span(zcu: &Zcu, pool: AstPool, fn_sym: i32, raw_span: i32) -> Span:
    let decl_index = compilation_find_fn_decl_index(pool, fn_sym)
    if decl_index >= 0:
        let decl = pool.get_decl(decl_index)
        let file_id = zcu.decl_source_file_id_frontend(decl_index)
        let start = if raw_span > 0: raw_span else: pool.get_start(decl)
        var end = if raw_span > 0: raw_span + 1 else: pool.get_end(decl)
        if end <= start:
            end = start + 1
        return Span { file: file_id, start: start, end: end }
    let start = if raw_span > 0: raw_span else: 0
    Span { file: 0, start: start, end: start + 1 }

fn compilation_bool_digit(value: bool) -> str:
    if value: "1" else: "0"

fn compilation_join_strings(values: &Vec[str], separator: &str) -> str:
    var out = ""
    for i in 0..values.len() as i32:
        if i > 0:
            out = out ++ separator
        out = out ++ values.get(i as i64)
    out

fn compilation_escape_with_string(value: &str) -> str:
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

fn compilation_split_escaped_fields(line: &str) -> Vec[str]:
    let fields: Vec[str] = Vec.new()
    var cur = ""
    var escaped = false
    for i in 0..line.len() as i32:
        let ch = line.byte_at(i as i64)
        if escaped:
            if ch == 110:
                cur = cur ++ "\n"
            else if ch == 116:
                cur = cur ++ "\t"
            else if ch == 114:
                cur = cur ++ "\r"
            else:
                cur = cur ++ line.slice(i as i64, (i + 1) as i64)
            escaped = false
        else if ch == 92:
            escaped = true
        else if ch == 9:
            fields.push(cur)
            cur = ""
        else:
            cur = cur ++ line.slice(i as i64, (i + 1) as i64)
    fields.push(cur)
    fields

fn compilation_split_nonempty_lines(text: &str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if i > start:
                lines.push(text.slice(start as i64, i as i64))
            start = i + 1
    if start < text.len() as i32:
        lines.push(text.slice(start as i64, text.len()))
    lines

fn compilation_parse_i32(text: &str) -> i32:
    var sign = 1
    var i = 0
    if text.len() > 0 and text.byte_at(0) == 45:
        sign = -1
        i = 1
    var value = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch < 48 or ch > 57:
            break
        value = value * 10 + (ch - 48)
        i = i + 1
    value * sign

fn compilation_decl_index_for_node(pool: AstPool, node: NodeId) -> i32:
    for di in 0..pool.decl_count():
        if pool.get_decl(di) == node:
            return di
    -1

fn compilation_relative_source_path(root: &str, path: &str) -> str:
    if root.len() == 0:
        return with_str_clone_ref(path)
    let prefix = if root.ends_with("/"): with_str_clone_ref(root) else: root ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    with_str_clone_ref(path)

fn compilation_module_import_name(root: &str, path: &str) -> str:
    var rel = compilation_relative_source_path(root, path)
    if rel.ends_with(".w"):
        rel = rel.slice(0, rel.len() - 2)
    var out = ""
    for i in 0..rel.len() as i32:
        let ch = rel.byte_at(i as i64)
        if ch == 47:
            out = out ++ "."
        else:
            out = out ++ rel.slice(i as i64, (i + 1) as i64)
    out

fn compilation_span_file_id_for_path(zcu: &Zcu, path: &str) -> i32:
    if path == zcu.current_source_path:
        return 0
    for di in 0..zcu.last_sema.ast.decl_count():
        if zcu.decl_source_path_frontend(di) == path:
            return zcu.decl_source_file_id_frontend(di)
    0

fn compilation_type_decl_is_pub(pool: AstPool, extra_start: i32, sub_kind: i32) -> bool:
    if sub_kind == TypeDeclKind.Struct or sub_kind == TypeDeclKind.Union:
        let field_count = pool.get_extra(extra_start)
        let vis_idx = extra_start + 1 + field_count * 4
        return pool.get_extra(vis_idx) == Visibility.Public
    if sub_kind == TypeDeclKind.Enum:
        var ep = extra_start + 1
        let variant_count = pool.get_extra(extra_start)
        for _ in 0..variant_count:
            ep = ep + 1
            let payload_count = pool.get_extra(ep)
            ep = ep + 1 + payload_count
        return pool.get_extra(ep) == Visibility.Public
    if sub_kind == TypeDeclKind.DiscEnum:
        var ep = extra_start + 2
        let variant_count = pool.get_extra(extra_start + 1)
        for _ in 0..variant_count:
            ep = ep + 1
            ep = ep + 1
            let payload_count = pool.get_extra(ep)
            ep = ep + 1 + payload_count
        return pool.get_extra(ep) == Visibility.Public
    pool.get_extra(extra_start + 1) == Visibility.Public

fn compilation_type_decl_kind_name(sub_kind: i32) -> str:
    if sub_kind == TypeDeclKind.Struct:
        return "struct"
    if sub_kind == TypeDeclKind.Enum:
        return "enum"
    if sub_kind == TypeDeclKind.DiscEnum:
        return "disc_enum"
    if sub_kind == TypeDeclKind.Alias:
        return "alias"
    if sub_kind == TypeDeclKind.Distinct:
        return "distinct"
    if sub_kind == TypeDeclKind.Opaque:
        return "opaque"
    if sub_kind == TypeDeclKind.Union:
        return "union"
    "unknown"

// Transitional orchestration root:
// owns compiler-facing config/Zcu state while reusing Driver execution per call.
// This removes long-lived Driver field ownership from Compilation.
type Compilation {
    zcu: Zcu,
    config: CompilationConfig,
    cli_diag_gen_starts: Vec[i32],
    cli_diag_gen_ends: Vec[i32],
    cli_diag_source_names: Vec[str],
    cli_diag_source_texts: Vec[str],
    compiler_hook_emitted_source: str,
    last_link_command_available: i32,
    last_link_command: LinkStageCommand,
    last_link_rc: i32,
    // D38: `--link-object` paths for this build's link (see build_binary_to_path).
    link_objects: Vec[str],
    // D39: `--link-bundle` prefixes, loaded once by load_link_bundles before
    // the first frontend entry (the interface registry must be populated
    // before any import resolves).
    link_bundles: Vec[str],
    link_bundles_loaded: bool,
    // D38: `--emit-bundle-manifest` path for emit_object_to_path ("" = none).
    bundle_manifest_path: str,
    // D39: `--emit-bundle-interface` / `--bundle-fingerprint` paths ("" =
    // none) and the `--bundle-corpus` module filter they and the manifest
    // share.
    bundle_interface_path: str,
    bundle_fingerprint_path: str,
    bundle_corpus: str,
}

type CompilationBinaryLinkPlan {
    ok: bool,
    obj_path: str,
    bin_path: str,
    command: LinkStageCommand,
}

pub fn Compilation.init -> Compilation:
    compilation_debug_init("Compilation.init:start")
    let zcu: Zcu = Zcu.init()
    compilation_debug_init("Compilation.init:zcu_ready")
    Compilation {
        zcu: zcu,
        config: compilation_config_default(),
        cli_diag_gen_starts: Vec.new(),
        cli_diag_gen_ends: Vec.new(),
        cli_diag_source_names: Vec.new(),
        cli_diag_source_texts: Vec.new(),
        compiler_hook_emitted_source: "",
        last_link_command_available: 0,
        last_link_command: link_stage_empty_command(),
        last_link_rc: 0,
        link_objects: Vec.new(),
        link_bundles: Vec.new(),
        link_bundles_loaded: false,
        bundle_manifest_path: "",
        bundle_interface_path: "",
        bundle_fingerprint_path: "",
        bundle_corpus: "",
    }

impl Compilation:
    mut fn configure(opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool):
        self.config = compilation_config_from_cli(opt_level, no_std, alloc_mode, runtime_available, self.config.prelude_mode)
        var zcu = move self.zcu
        zcu.set_prelude_mode(self.config.prelude_mode)
        self.zcu = zcu

    mut fn configure_options(options: &BuildCommandOptions):
        self.configure(options.opt_level, options.no_std, options.alloc_mode, options.runtime_available)
        self.set_prelude_mode(options.prelude_mode)
        self.set_overflow_mode(options.overflow_mode)
        self.set_debug_info(options.debug_info)
        self.set_compiler_hooks_enabled(options.compiler_hooks_enabled)
        self.set_target_kind(options.target_kind)
        self.link_objects = driver_clone_str_vec(&options.link_objects)
        self.set_link_bundles(&options.link_bundles)
        self.bundle_manifest_path = with_str_clone_ref(options.bundle_manifest_path)
        self.bundle_interface_path = with_str_clone_ref(options.bundle_interface_path)
        self.set_bundle_fingerprint(options.bundle_corpus, options.bundle_fingerprint_path)

    pub mut fn set_link_bundles(prefixes: &Vec[str]):
        self.link_bundles = driver_clone_str_vec(prefixes)
        self.link_bundles_loaded = false

    // D39: `--bundle-corpus <rel>` and `--bundle-fingerprint <path>` — on
    // `check` too, the second fingerprint pass runs on the emitted .wi. The
    // corpus also reaches codegen (Zcu.bundle_corpus): a bundle build owns
    // every module under it (C3).
    pub mut fn set_bundle_fingerprint(corpus: &str, fingerprint_path: &str):
        self.bundle_corpus = with_str_clone_ref(corpus)
        self.bundle_fingerprint_path = with_str_clone_ref(fingerprint_path)
        var zcu = move self.zcu
        zcu.bundle_corpus = with_str_clone_ref(corpus)
        self.zcu = zcu

    // The exported-declaration model of the corpus in the finalized Sema
    // (the one codegen handed back, or the one `check` froze), with every
    // refusal printed. Read through a borrow: a bare read would move the
    // Sema out of the Zcu (the root-15 class).
    fn bundle_model(what: &str) -> BundleInterfaceModel:
        let sema = &self.zcu.last_sema
        let model = bundle_interface_build(sema, self.bundle_corpus, &self.zcu.last_bundle_unlowered_globals)
        for wi in 0..model.warnings.len() as i32:
            runtime_eprint("warning: bundle interface: " ++ model.warnings.get(wi as i64))
        var omitted_fns = 0
        var omitted_globals = 0
        for oi in 0..model.omitted.len() as i32:
            if model.omitted.get(oi as i64).ends_with("\tgeneric-fn"): omitted_fns = omitted_fns + 1
            else: omitted_globals = omitted_globals + 1
        if omitted_fns > 0:
            runtime_eprint(f"warning: bundle interface: {omitted_fns} generic function(s) not exported at Level 0 (corpus-internal; each is named in the .wi and in the manifest's `omitted` lines)")
        if omitted_globals > 0:
            runtime_eprint(f"warning: bundle interface: {omitted_globals} global(s) without a compile-time initializer not exported at Level 0 (corpus-internal, undefined in the object; each is named in the .wi and in the manifest's `omitted` lines)")
        for ei in 0..model.errors.len() as i32:
            runtime_eprint("error: bundle interface: " ++ model.errors.get(ei as i64))
        if not model.ok:
            runtime_eprint(f"error: {what}: {model.errors.len() as i32} declaration(s) have no exact interface spelling (listed above); nothing written")
        model

    // D39: write the exported-declaration fingerprint of the corpus modules
    // to --bundle-fingerprint (the sha on the first line) and the rows it
    // hashes to `<path>.tsv` (for diffing when two passes disagree).
    // Returns the sha, "" on failure.
    fn write_bundle_fingerprint(model: &BundleInterfaceModel) -> str:
        let text = bundle_fingerprint_text(model)
        let sha = bundle_fingerprint_sha(text)
        if runtime_write_file(self.bundle_fingerprint_path, sha ++ "\n") != 0:
            runtime_eprint("error: could not write bundle fingerprint: " ++ self.bundle_fingerprint_path)
            return ""
        if runtime_write_file(self.bundle_fingerprint_path ++ ".tsv", text) != 0:
            runtime_eprint("error: could not write bundle fingerprint rows: " ++ self.bundle_fingerprint_path ++ ".tsv")
            return ""
        sha

    // D39: a `.wi` root holding `module <path>` sections is a whole bundle
    // interface: register every section so the resolver reads them, and
    // compile a root that imports each one — the second fingerprint pass.
    // A `.wi` without sections is one module in interface flavor, as before.
    // The check command's fingerprint pass: the model of the checked root.
    fn write_check_bundle_fingerprint() -> str:
        let model = self.bundle_model("--bundle-fingerprint")
        if not model.ok:
            return ""
        self.write_bundle_fingerprint(&model)

    mut fn compile_bundle_interface_root(wi_path: &str) -> AstPool:
        let wi_text = runtime_read_file(wi_path)
        let sections = bundle_interface_section_paths(wi_text)
        if sections.len() == 0:
            return self.compile_file(wi_path)
        if not self.load_link_bundles():
            return AstPool.new()
        let _ = bundle_interfaces_register_wi(wi_text)
        var root_text = "// bundle interface root for " ++ wi_path ++ "\n"
        for si in 0..sections.len() as i32:
            let dotted = bundle_module_dotted_name(sections.get(si as i64))
            if dotted.len() == 0:
                runtime_eprint("error: " ++ wi_path ++ ": section path '" ++ sections.get(si as i64) ++ "' is not under <embedded-std>/")
                return AstPool.new()
            root_text = root_text ++ "use " ++ dotted ++ "\n"
        let root_path = wi_path ++ ".root.w"
        var zcu = move self.zcu
        let source_dir = frontend_dirname(root_path)
        zcu.reset_for_new_invocation(source_dir, root_path, "")
        zcu.project_config = self.project_config_for_source(root_path)
        zcu.set_current_source(source_dir, root_path, root_text)
        zcu = self.apply_cli_diag_mappings(move zcu)
        let pool = zcu.compile_source_frontend_mode(root_text, root_path, 0, 0)
        self.zcu = zcu
        pool

    // D39 `--link-bundle <prefix>` (docs/wo_bundles.md): `<prefix>.o` joins
    // the link, the manifest's module prefixes make codegen declare (never
    // define) those modules' functions, and `<prefix>.wi` registers with the
    // interface registry so the resolver reads it in place of the source. A
    // manifest whose abi-sha differs from this compiler's is a hard error
    // (#761: never a mixed-ABI link); an unstamped compiler (stage1) carries
    // no identity to compare, so it links on the bootstrap plan's trust.
    mut fn load_link_bundles() -> bool:
        if self.link_bundles_loaded:
            return true
        self.link_bundles_loaded = true
        if not self.register_embedded_bundle_interfaces():
            return false
        for bi in 0..self.link_bundles.len() as i32:
            let prefix_path = self.link_bundles.get(bi as i64)
            let obj_path = prefix_path ++ ".o"
            let manifest_path = prefix_path ++ ".manifest"
            let wi_path = prefix_path ++ ".wi"
            if runtime_file_exists(obj_path) == 0:
                with_eprint("error: --link-bundle: missing bundle object " ++ obj_path)
                return false
            let manifest = runtime_read_file(manifest_path)
            if manifest.len() == 0:
                with_eprint("error: --link-bundle: missing or empty bundle manifest " ++ manifest_path)
                return false
            let bundle_abi = link_stage_bundle_manifest_field(manifest, "abi-sha")
            if compiler_abi_sha_is_stamped() and bundle_abi != compiler_abi_sha():
                with_eprint("error: --link-bundle: " ++ manifest_path ++ " was built for ABI " ++ bundle_abi ++ " but this compiler is " ++ compiler_abi_sha() ++ " (a .wo never links across ABI identities; rebuild the bundle)")
                return false
            let prefixes = bundle_manifest_prefixes(manifest)
            if prefixes.len() == 0:
                with_eprint("error: --link-bundle: no `prefix` lines in " ++ manifest_path)
                return false
            let wi_text = runtime_read_file(wi_path)
            if wi_text.len() == 0:
                with_eprint("error: --link-bundle: missing or empty bundle interface " ++ wi_path)
                return false
            // D39 pairing check: the interface the object was built with is
            // the one being loaded — interface N never pairs with object N+1.
            let manifest_wi_sha = link_stage_bundle_manifest_field(manifest, "interface-sha")
            if manifest_wi_sha.len() == 0:
                with_eprint("error: --link-bundle: " ++ manifest_path ++ " records no interface-sha; rebuild the bundle with --emit-bundle-interface")
                return false
            let loaded_wi_sha = bundle_text_sha256(wi_text)
            if loaded_wi_sha != manifest_wi_sha:
                with_eprint("error: --link-bundle: " ++ wi_path ++ " (sha256 " ++ loaded_wi_sha ++ ") is not the interface " ++ manifest_path ++ " was built with (" ++ manifest_wi_sha ++ "); rebuild the bundle")
                return false
            if bundle_interfaces_register_wi(wi_text) == 0:
                with_eprint("error: --link-bundle: no `module <path>` sections in " ++ wi_path)
                return false
            if not self.link_objects.contains(obj_path):
                self.link_objects.push(with_str_clone_ref(obj_path))
            // The object joins the link explicitly, so on-demand selection
            // must not extract an embedded copy of the same modules.
            link_stage_add_explicit_bundle_prefixes(&prefixes)
            var zcu = move self.zcu
            zcu.add_link_bundle_prefixes(&prefixes)
            self.zcu = zcu
        true

    // D39 (batch C3): every bundle this compiler embeds registers its
    // interface before the first import resolves, after the pairing check —
    // sha256(.wi) equals the manifest's interface-sha, or the binary's
    // embedded bundles are corrupt and compilation stops (never a silent
    // fall back to source). An unfilled slot (stage1) has nothing to
    // register. The corpus a bundle build compiles (--bundle-corpus) stays on
    // its source: that is how the wo-drift lane rebuilds an embedded bundle
    // from the tree.
    fn register_embedded_bundle_interfaces() -> bool:
        for bi in 0..embedded_bundle_count():
            if not embedded_bundle_present(bi):
                continue
            let name = embedded_bundle_name(bi)
            let manifest = embedded_bundle_manifest_text(bi)
            if self.bundle_corpus.len() > 0 and self.manifest_lies_under_bundle_corpus(manifest):
                continue
            let wi_text = embedded_bundle_interface_text(bi)
            let manifest_wi_sha = link_stage_bundle_manifest_field(manifest, "interface-sha")
            let embedded_wi_sha = bundle_text_sha256(wi_text)
            if manifest_wi_sha.len() == 0 or embedded_wi_sha != manifest_wi_sha:
                with_eprint("error: embedded bundle '" ++ name ++ "': its interface (sha256 " ++ embedded_wi_sha ++ ") is not the one its manifest was built with (" ++ manifest_wi_sha ++ "); this compiler's embedded bundles are corrupt")
                return false
            if bundle_interfaces_register_wi(wi_text) == 0:
                with_eprint("error: embedded bundle '" ++ name ++ "': no `module <path>` sections in its interface")
                return false
        true

    fn manifest_lies_under_bundle_corpus(manifest: &str) -> bool:
        let paths = bundle_manifest_paths(manifest)
        for pi in 0..paths.len() as i32:
            if bundle_corpus_contains(self.bundle_corpus, paths.get(pi as i64)):
                return true
        false

    // Install the --target selection (§18.5) before any parse or
    // codegen: @[target] guards, comptime sysinfo, C-ABI decisions,
    // LLVM triple, and the link stage all read the active target.
    mut fn set_target_kind(kind: i32):
        target_spec_set_active(kind)
        wl_set_active_target_triple(target_spec_llvm_triple())

    fn apply_runtime_config(cfg: ProjectConfig) -> ProjectConfig:
        var out = cfg
        if self.config.no_std:
            out.no_std = true
        if self.config.alloc_mode:
            out.alloc_mode = true
        if not self.config.runtime_available:
            out.runtime_available = false
        if out.no_std:
            out.runtime_available = false
        if overflow_mode_valid(self.config.overflow_mode):
            out.overflow_mode = self.config.overflow_mode
        out

    fn project_config_for_source(source_path: &str) -> ProjectConfig:
        self.apply_runtime_config(project_config_load_for_source(source_path))

    mut fn set_prelude_mode(mode: i32):
        var cfg = move self.config
        cfg.prelude_mode = compilation_normalize_prelude_mode(mode)
        let cfg_prelude_mode = cfg.prelude_mode
        self.config = cfg
        var zcu = move self.zcu
        zcu.set_prelude_mode(cfg_prelude_mode)
        self.zcu = zcu

    mut fn set_overflow_mode(mode: i32):
        var cfg = move self.config
        cfg.overflow_mode = if overflow_mode_valid(mode): mode else: -1
        self.config = cfg

    mut fn set_debug_info(enabled: bool):
        var cfg = move self.config
        cfg.debug_info = enabled
        self.config = cfg

    mut fn set_compiler_hooks_enabled(enabled: bool):
        var cfg = move self.config
        cfg.compiler_hooks_enabled = enabled
        self.config = cfg

    mut fn set_tool_mode_entry_path(path: &str):
        var cfg = move self.config
        cfg.tool_mode_entry_path = with_str_clone_ref(path)
        self.config = cfg
        var zcu = move self.zcu
        zcu.tool_mode_entry_path = with_str_clone_ref(path)
        self.zcu = zcu

    fn add_cli_diag_mapping(gen_start: i32, gen_end: i32, source_name: &str, source_text: &str) -> Unit:
        self.cli_diag_gen_starts.push(gen_start)
        self.cli_diag_gen_ends.push(gen_end)
        self.cli_diag_source_names.push(with_str_clone_ref(source_name))
        self.cli_diag_source_texts.push(with_str_clone_ref(source_text))

    fn apply_cli_diag_mappings(zcu: Zcu) -> Zcu:
        zcu.clear_cli_diag_mappings()
        for i in 0..self.cli_diag_gen_starts.len() as i32:
            zcu.add_cli_diag_mapping(
                self.cli_diag_gen_starts.get(i as i64),
                self.cli_diag_gen_ends.get(i as i64),
                self.cli_diag_source_names.get(i as i64),
                self.cli_diag_source_texts.get(i as i64),
            )
        zcu

    mut fn compile_file(path: &str) -> AstPool:
        compilation_debug_init("Compilation.compile_file:start " ++ path)
        if not self.load_link_bundles():
            return AstPool.new()
        var zcu = move self.zcu
        let pool = zcu.compile_file_frontend_with_config(path, self.project_config_for_source(path))
        self.zcu = zcu
        compilation_debug_init(f"Compilation.compile_file:done decls={pool.decl_count()}")
        pool

    mut fn compile_file_with_config(path: &str, cfg: ProjectConfig) -> AstPool:
        compilation_debug_init("Compilation.compile_file_with_config:start " ++ path)
        if not self.load_link_bundles():
            return AstPool.new()
        var zcu = move self.zcu
        let pool = zcu.compile_file_frontend_with_config(path, self.apply_runtime_config(move cfg))
        self.zcu = zcu
        compilation_debug_init(f"Compilation.compile_file_with_config:done decls={pool.decl_count()}")
        pool

    mut fn compile_entry_file(path: &str) -> AstPool:
        compilation_debug_init("Compilation.compile_entry_file:start " ++ path)
        if not self.load_link_bundles():
            return AstPool.new()
        var zcu = move self.zcu
        let pool = zcu.compile_file_frontend_entry_with_config(path, self.project_config_for_source(path))
        self.zcu = zcu
        compilation_debug_init(f"Compilation.compile_entry_file:done decls={pool.decl_count()}")
        pool

    mut fn compile_entry_file_with_config(path: &str, cfg: ProjectConfig) -> AstPool:
        compilation_debug_init("Compilation.compile_entry_file_with_config:start " ++ path)
        if not self.load_link_bundles():
            return AstPool.new()
        var zcu = move self.zcu
        let pool = zcu.compile_file_frontend_entry_with_config(path, self.apply_runtime_config(move cfg))
        self.zcu = zcu
        compilation_debug_init(f"Compilation.compile_entry_file_with_config:done decls={pool.decl_count()}")
        pool

    mut fn resolve_file(path: &str, emit_resolve_diags: bool) -> &ResolveResult:
        let _ = emit_resolve_diags
        let _ = self.compile_file(path)
        &self.zcu.last_resolved

    mut fn dump_project_info_file(source_path: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.dump_project_info(pool)

    fn dump_project_info(pool: AstPool) -> str:
        let zcu = &self.zcu
        var function_count = 0
        var type_count = 0
        for di in 0..pool.decl_count():
            let decl = pool.get_decl(di)
            let kind = pool.kind(decl)
            if kind == NodeKind.NK_FN_DECL:
                function_count = function_count + 1
            else if kind == NodeKind.NK_TYPE_DECL:
                type_count = type_count + 1

        var out = f"project_info modules={zcu.last_resolved.modules.len() as i32} functions={function_count} types={type_count}\n"
        let cfg = &zcu.project_config
        out = out ++ "config root=" ++ cfg.root_dir ++ "\n"
        out = out ++ "config package=" ++ cfg.package_name ++ " version=" ++ cfg.package_version ++ "\n"
        out = out ++ "config c_import_include_paths=" ++ compilation_join_strings(&cfg.c_import_include_paths, ",") ++ "\n"
        out = out ++ "config c_import_defines=" ++ compilation_join_strings(&cfg.c_import_defines, ",") ++ "\n"
        out = out ++ "config link_libs=" ++ compilation_join_strings(&cfg.link_libs, ",") ++ "\n"
        out = out ++ "config link_search_paths=" ++ compilation_join_strings(&cfg.link_search_paths, ",") ++ "\n"
        out = out ++ "config dep_link_libs=" ++ compilation_join_strings(&cfg.dep_link_libs, ",") ++ "\n"
        out = out ++ "config dep_names=" ++ compilation_join_strings(&cfg.dep_names, ",") ++ "\n"
        out = out ++ "config dep_constraints=" ++ compilation_join_strings(&cfg.dep_constraints, ",") ++ "\n"
        out = out ++ "config feature_default=" ++ compilation_join_strings(&cfg.feature_default, ",") ++ "\n"
        out = out ++ "config feature_names=" ++ compilation_join_strings(&cfg.feature_names, ",") ++ "\n"
        out = out ++ "config feature_values=" ++ compilation_join_strings(&cfg.feature_values, ",") ++ "\n"
        out = out ++ "config target_default=" ++ cfg.target_default ++ "\n"
        out = out ++ f"config runtime_fiber_stack_size={cfg.runtime_fiber_stack_size}\n"
        out = out ++ f"config runtime_fiber_pool_size={cfg.runtime_fiber_pool_size}\n"
        out = out ++ f"config runtime_fiber_worker_count={cfg.runtime_fiber_worker_count}\n"
        out = out ++ f"config copy_warn_threshold={cfg.copy_warn_threshold}\n"
        out = out ++ "config lint_partial_statement_match=" ++ if cfg.lint_partial_statement_match: "true\n" else: "false\n"
        for mi in 0..zcu.last_resolved.modules.len() as i32:
            let mod = zcu.last_resolved.modules.get(mi as i64)
            out = out ++ f"module path={mod.path} file={mod.file_id} decls={mod.decl_count}\n"

        for di in 0..pool.decl_count():
            let decl = pool.get_decl(di)
            let kind = pool.kind(decl)
            let path = zcu.decl_source_path_frontend(di)
            if kind == NodeKind.NK_FN_DECL:
                let name = zcu.pool.resolve(pool.get_data0(decl))
                let flags = pool.get_data2(decl)
                let is_pub = (flags / FnFlags.PUB) % 2 == 1
                let meta = pool.find_fn_meta(decl)
                var param_count = 0
                var return_type = "void"
                if meta >= 0:
                    param_count = pool.fn_meta_param_count(meta)
                    let ret_node = pool.fn_meta_ret(meta)
                    if ret_node != 0:
                        return_type = render_type_expr(pool, zcu.pool, ret_node as NodeId)
                out = out ++ f"function path={path} name={name} pub={compilation_bool_digit(is_pub)} params={param_count} return={return_type} span={pool.get_start(decl)}..{pool.get_end(decl)}\n"
            else if kind == NodeKind.NK_TYPE_DECL:
                let name = zcu.pool.resolve(pool.get_data0(decl))
                let packed = pool.get_data2(decl)
                let sub_kind = type_decl_sub_kind(packed)
                let is_pub = compilation_type_decl_is_pub(pool, pool.get_data1(decl), sub_kind)
                let kind_name = compilation_type_decl_kind_name(sub_kind)
                out = out ++ f"type path={path} name={name} pub={compilation_bool_digit(is_pub)} kind={kind_name} span={pool.get_start(decl)}..{pool.get_end(decl)}\n"
        out

    fn project_info_source(pool: AstPool) -> str:
        let zcu = &self.zcu
        var out = "fn __with_compiler_hook_project_info() -> ProjectInfo:\n"
        out = out ++ "    var project = ProjectInfo.new()\n"
        for mi in 0..zcu.last_resolved.modules.len() as i32:
            let mod = zcu.last_resolved.modules.get(mi as i64)
            let module_name = compilation_module_import_name(zcu.project_config.root_dir, mod.path)
            out = out ++ "    project = project.add_module(ModuleInfo.new(\"" ++ compilation_escape_with_string(module_name) ++ "\", \"" ++ compilation_escape_with_string(mod.path) ++ "\"))\n"

        for di in 0..pool.decl_count():
            let decl = pool.get_decl(di)
            let kind = pool.kind(decl)
            let path = zcu.decl_source_path_frontend(di)
            let module_name = compilation_module_import_name(zcu.project_config.root_dir, path)
            let loc = "SourceLocation.new(\"" ++ compilation_escape_with_string(path) ++ "\", " ++ f"{pool.get_start(decl)}" ++ ", " ++ f"{pool.get_end(decl)}" ++ ")"
            if kind == NodeKind.NK_FN_DECL:
                let name = zcu.pool.resolve(pool.get_data0(decl))
                let flags = pool.get_data2(decl)
                let is_pub = (flags / FnFlags.PUB) % 2 == 1
                let meta = pool.find_fn_meta(decl)
                var param_count = 0
                var return_type = "void"
                if meta >= 0:
                    param_count = pool.fn_meta_param_count(meta)
                    let ret_node = pool.fn_meta_ret(meta)
                    if ret_node != 0:
                        return_type = render_type_expr(pool, zcu.pool, ret_node as NodeId)
                out = out ++ "    project = project.add_function(FunctionInfo.new(\"" ++ compilation_escape_with_string(module_name) ++ "\", \"" ++ compilation_escape_with_string(name) ++ "\", " ++ (if is_pub: "true" else: "false") ++ ", false, " ++ f"{param_count}" ++ ", \"" ++ compilation_escape_with_string(return_type) ++ "\", " ++ loc ++ "))\n"
            else if kind == NodeKind.NK_TYPE_DECL:
                let name = zcu.pool.resolve(pool.get_data0(decl))
                let packed = pool.get_data2(decl)
                let sub_kind = type_decl_sub_kind(packed)
                let is_pub = compilation_type_decl_is_pub(pool, pool.get_data1(decl), sub_kind)
                let kind_name = compilation_type_decl_kind_name(sub_kind)
                out = out ++ "    project = project.add_type(TypeInfo.new(\"" ++ compilation_escape_with_string(module_name) ++ "\", \"" ++ compilation_escape_with_string(name) ++ "\", " ++ (if is_pub: "true" else: "false") ++ ", false, \"" ++ kind_name ++ "\", " ++ loc ++ "))\n"
        out ++ "    project\n"

fn compilation_compiler_hook_arg_for_type(pool: AstPool, intern: InternPool, type_node: i32) -> str:
    let rendered = render_type_expr(pool, intern, type_node as NodeId)
    if rendered == "ProjectInfo":
        return "project"
    if rendered == "Diagnostics":
        return "diagnostics"
    if rendered == "SourceEmitter":
        return "source_emitter"
    ""

fn compilation_compiler_hook_call_args(pool: AstPool, intern: InternPool, hook_node: NodeId) -> str:
    let meta = pool.find_fn_meta(hook_node)
    if meta < 0:
        return ""
    let param_start = pool.fn_meta_param_start(meta)
    let param_count = pool.fn_meta_param_count(meta)
    var out = ""
    for pi in 0..param_count:
        if pi > 0:
            out = out ++ ", "
        let type_node = pool.fn_param_type(param_start, pi)
        let arg_name = compilation_compiler_hook_arg_for_type(pool, intern, type_node)
        if arg_name.len() == 0:
            return ""
        out = out ++ arg_name
    out

impl Compilation:
    fn compiler_hook_runner_source(pool: AstPool, source_path: &str, diag_path: &str, emitted_source_path: &str, token: &str) -> str:
        let zcu = &self.zcu
        let root = if zcu.project_config.root_dir.len() > 0: zcu.project_config.root_dir else: frontend_dirname(source_path)
        let hook_count = pool.compiler_hook_count()
        var out = "use std.compiler\n"
        let imported: HashMap[str, i32] = HashMap.new()
        for hi in 0..hook_count:
            let hook_node = pool.compiler_hook_node(hi)
            let di = compilation_decl_index_for_node(pool, hook_node)
            if di < 0:
                continue
            let path = zcu.decl_source_path_frontend(di)
            let import_name = compilation_module_import_name(root, path)
            if import_name.len() > 0 and not imported.contains(import_name):
                out = out ++ "use " ++ import_name ++ ".*\n"
                imported.insert(import_name, 1)
        out = out ++ "\n"
        out = out ++ self.project_info_source(pool)
        out = out ++ "\nfn main:\n"
        out = out ++ "    let project = __with_compiler_hook_project_info()\n"
        // Diagnostics/SourceEmitter capabilities are constructed INLINE at
        // each hook argument position: an owned rvalue temp satisfies every
        // parameter mode (§3.8), so a hook that CONSUMES its capability
        // (fn generate(source: SourceEmitter) storing/dropping it) and one
        // that merely reads it both compile without the generator having to
        // know the hook's inferred effects. Hoisted lets forced a spelling
        // choice the generator cannot make (move vs bare fails one side).
        let diag_ctor = "Diagnostics.__driver_new(\"" ++ compilation_escape_with_string(token) ++ "\", \"" ++ compilation_escape_with_string(diag_path) ++ "\")"
        let emitter_ctor = "SourceEmitter.__driver_new(\"" ++ compilation_escape_with_string(token) ++ "\", \"" ++ compilation_escape_with_string(emitted_source_path) ++ "\")"
        for hi2 in 0..hook_count:
            let hook_node = pool.compiler_hook_node(hi2)
            let phase_name = zcu.pool.resolve(pool.compiler_hook_phase_at(hi2))
            if phase_name != "after_typecheck":
                continue
            let hook_name = zcu.pool.resolve(pool.get_data0(hook_node))
            var call_args = compilation_compiler_hook_call_args(pool, zcu.pool, hook_node)
            call_args = call_args.replace("source_emitter", emitter_ctor)
            call_args = call_args.replace("diagnostics", diag_ctor)
            out = out ++ "    " ++ hook_name ++ "(" ++ call_args ++ ")\n"
        out

    mut fn emit_compiler_hook_diagnostics(diag_text: &str) -> i32:
        if diag_text.len() == 0:
            return 0
        var emitted = 0
        var zcu = move self.zcu
        let lines = compilation_split_nonempty_lines(diag_text)
        for li in 0..lines.len() as i32:
            let fields = compilation_split_escaped_fields(lines.get(li as i64))
            if fields.len() != 5:
                continue
            if fields.get(0) != "error":
                continue
            let path = fields.get(1)
            let start = compilation_parse_i32(fields.get(2))
            let end = compilation_parse_i32(fields.get(3))
            let message = fields.get(4)
            let file_id = compilation_span_file_id_for_path(zcu, path)
            zcu.diagnostics.emit(Diagnostic.err(message, Span { file: file_id, start, end }))
            emitted = emitted + 1
        self.zcu = zcu
        if emitted > 0:
            self.zcu.render_all_diagnostics_frontend()
        emitted

    mut fn run_after_typecheck_hooks(pool: AstPool, source_path: &str) -> bool:
        self.compiler_hook_emitted_source = ""
        if pool.compiler_hook_count() == 0:
            return true
        if not self.config.compiler_hooks_enabled:
            return true
        let root = if self.zcu.project_config.root_dir.len() > 0: self.zcu.project_config.root_dir else: frontend_dirname(source_path)
        // Hook scratch lives in the system temp dir, never beside the source:
        // rooting it at frontend_dirname scattered pid-stamped runners and
        // dSYM bundles into source test directories (#741). The stamped dir
        // is removed as one tree on every exit path. Only the runner SOURCE
        // stays in root — its generated `use` imports resolve from there.
        let stamp = f"{runtime_getpid()}.{runtime_clock_nanos()}"
        let tmp_base_env = runtime_getenv("TMPDIR")
        var tmp_base = if tmp_base_env.len() > 0: tmp_base_env else: "/tmp"
        if tmp_base.ends_with("/"):
            tmp_base = tmp_base.slice(0, tmp_base.len() - 1)
        let tmp_dir = tmp_base ++ "/with-compiler-hook." ++ stamp
        if runtime_mkdir_p(tmp_dir) != 0:
            runtime_eprint("error: could not create compiler hook temp directory: " ++ tmp_dir)
            return false
        let runner_path = root ++ "/__with_compiler_hook_runner." ++ stamp ++ ".w"
        let runner_bin = tmp_dir ++ "/compiler-hook-runner." ++ stamp
        let diag_path = tmp_dir ++ "/compiler-hook-diags." ++ stamp ++ ".txt"
        let emitted_source_path = tmp_dir ++ "/compiler-hook-source." ++ stamp ++ ".w"
        let capability_token = "with-compiler-hook:" ++ stamp
        if runtime_write_file(diag_path, "") != 0:
            let _cleanup_diag_fail = runtime_remove_tree(tmp_dir)
            runtime_eprint("error: could not initialize compiler hook diagnostics")
            return false
        if runtime_write_file(emitted_source_path, "") != 0:
            let _cleanup_emitted_fail = runtime_remove_tree(tmp_dir)
            runtime_eprint("error: could not initialize compiler hook emitted source")
            return false
        let runner_source = self.compiler_hook_runner_source(pool, source_path, diag_path, emitted_source_path, capability_token)
        if runtime_write_file(runner_path, runner_source) != 0:
            let _cleanup_runner_fail = runtime_remove_tree(tmp_dir)
            runtime_eprint("error: could not write compiler hook runner")
            return false
        var runner_comp = Compilation.init()
        runner_comp.configure(self.config.opt_level, self.config.no_std, self.config.alloc_mode, self.config.runtime_available)
        runner_comp.set_prelude_mode(self.config.prelude_mode)
        runner_comp.set_debug_info(self.config.debug_info)
        runner_comp.set_compiler_hooks_enabled(false)
        runner_comp.set_tool_mode_entry_path(runner_path)
        let built_runner = runner_comp.build_binary_to_path(runner_path, runner_bin)
        let _remove_runner_source = runtime_remove_file(runner_path)
        if built_runner == "":
            let _cleanup_build_fail = runtime_remove_tree(tmp_dir)
            runtime_eprint("error: compiler hook runner compilation failed")
            return false
        let old_capability_token = runtime_getenv("WITH_TOOL_CAPABILITY_TOKEN")
        let _set_capability_token = runtime_setenv("WITH_TOOL_CAPABILITY_TOKEN", capability_token)
        let rc = runtime_exec_binary(built_runner)
        let _restore_capability_token = runtime_setenv("WITH_TOOL_CAPABILITY_TOKEN", old_capability_token)
        let diag_text = runtime_read_file(diag_path)
        let emitted_source = runtime_read_file(emitted_source_path)
        // One tree removal covers runner binary, object, dSYM bundle, and
        // both capability files. The old per-file removals used plain rmdir
        // on the dSYM BUNDLE, which silently failed on the non-empty tree —
        // thousands of bundles accumulated per test-suite run (#741).
        let _cleanup_tmp = runtime_remove_tree(tmp_dir)
        let emitted = self.emit_compiler_hook_diagnostics(diag_text)
        if emitted > 0:
            return false
        if rc != 0:
            runtime_eprint(f"error: compiler hook execution failed with exit code {rc}")
            return false
        self.compiler_hook_emitted_source = emitted_source
        true

    mut fn prepare_pool_after_typecheck_hooks(pool: AstPool, source_path: &str) -> AstPool:
        if pool.decl_count() == 0:
            return pool
        if not self.run_after_typecheck_hooks(pool, source_path):
            return AstPool.new()
        if self.compiler_hook_emitted_source.len() == 0:
            return pool
        let base_source = if self.zcu.current_source_text.len() > 0: self.zcu.current_source_text else: runtime_read_file(source_path)
        let cfg = self.zcu.project_config
        let combined = base_source ++ "\n\n// <with compiler hook emitted source>\n" ++ self.compiler_hook_emitted_source
        self.compiler_hook_emitted_source = ""
        self.compile_source_text_with_config(source_path, combined, move cfg)

    fn has_errors() -> bool:
        self.zcu.diagnostics.has_errors()

    fn get_pool() -> InternPool:
        self.zcu.pool

    mut fn emit_ir(pool: AstPool) -> bool:
        let source_path = self.zcu.current_source_path
        let prepared_pool = self.prepare_pool_after_typecheck_hooks(pool, source_path)
        if prepared_pool.decl_count() == 0:
            return false
        if not self.ensure_codegen_mir(prepared_pool):
            return false
        self.zcu.emit_ir_backend(self.active_pool(prepared_pool), self.config.opt_level)

// #650 codegen units: sibling unit objects (<obj>.u1.o ..) follow the
// canonical object's lifetime. The env cap bounds the sweep; removals are
// best-effort so stale higher-K leftovers from earlier runs also clear.
fn compilation_remove_unit_objects_best_effort(obj_path: &str):
    var k = 1
    while k < 64:
        compilation_remove_file_best_effort(f"{obj_path}.u{k}.o")
        k = k + 1

fn compilation_cleanup_build_products(obj_path: &str, bin_path: &str):
    if obj_path.len() > 0:
        compilation_remove_file_best_effort(obj_path)
        compilation_remove_unit_objects_best_effort(obj_path)
    if bin_path.len() > 0:
        compilation_remove_file_best_effort(bin_path)
        compilation_remove_dsym_best_effort(bin_path)

fn compilation_binary_link_plan_fail() -> CompilationBinaryLinkPlan:
    CompilationBinaryLinkPlan {
        ok: false,
        obj_path: "",
        bin_path: "",
        command: link_stage_empty_command(),
    }

impl Compilation:
    mut fn build_binary(source_path: &str) -> str:
        self.build_binary_to_path(source_path, link_stage_output_path_for_source(source_path))

    mut fn build_binary_from_source(source_path: &str, source_text: &str) -> str:
        self.build_binary_from_source_to_path(source_path, source_text, link_stage_output_path_for_source(source_path))

    mut fn build_binary_at(source_path: &str, output_dir: &str) -> str:
        let stem = link_stage_source_stem(source_path)
        self.build_binary_to_path(source_path, output_dir ++ "/" ++ stem)

    mut fn compile_source_text(source_path: &str, source_text: &str) -> AstPool:
        var zcu = move self.zcu
        let source_dir = frontend_dirname(source_path)
        zcu.reset_for_new_invocation(source_dir, source_path, "")
        zcu.project_config = self.project_config_for_source(source_path)
        if zcu.project_config.manifest_error.len() > 0:
            runtime_eprint("error: invalid with.toml: " ++ zcu.project_config.manifest_error)
            self.zcu = zcu
            return AstPool.new()
        zcu.set_current_source(source_dir, source_path, source_text)
        let pool = zcu.compile_source_frontend(source_text, source_path, 0)
        self.zcu = zcu
        pool

    mut fn compile_source_text_with_config(source_path: &str, source_text: &str, cfg: ProjectConfig) -> AstPool:
        var zcu = move self.zcu
        let source_dir = frontend_dirname(source_path)
        zcu.reset_for_new_invocation(source_dir, source_path, "")
        zcu.project_config = self.apply_runtime_config(move cfg)
        if zcu.project_config.manifest_error.len() > 0:
            runtime_eprint("error: invalid with.toml: " ++ zcu.project_config.manifest_error)
            self.zcu = zcu
            return AstPool.new()
        zcu.set_current_source(source_dir, source_path, source_text)
        let pool = zcu.compile_source_frontend(source_text, source_path, 0)
        self.zcu = zcu
        pool

    mut fn compile_entry_source_text(source_path: &str, source_text: &str) -> AstPool:
        let source_paths: Vec[str] = Vec.new()
        let source_texts: Vec[str] = Vec.new()
        source_paths.push(with_str_clone_ref(source_path))
        source_texts.push(with_str_clone_ref(source_text))
        self.compile_entry_source_texts(source_paths, source_texts)

    mut fn compile_entry_source_texts(source_paths: &Vec[str], source_texts: &Vec[str]) -> AstPool:
        if source_paths.len() == 0 or source_texts.len() == 0 or source_paths.len() != source_texts.len():
            runtime_eprint("error: compile_entry_source_texts requires matching non-empty source paths and texts")
            return AstPool.new()
        var zcu = move self.zcu
        let source_path = source_paths.get(0)
        let source_text = source_texts.get(0)
        let source_dir = frontend_dirname(source_path)
        zcu.reset_for_new_invocation(source_dir, source_path, "")
        zcu.project_config = self.project_config_for_source(source_path)
        if zcu.project_config.manifest_error.len() > 0:
            runtime_eprint("error: invalid with.toml: " ++ zcu.project_config.manifest_error)
            self.zcu = zcu
            return AstPool.new()
        zcu.set_current_source(source_dir, source_path, source_text)
        let extra_names: Vec[str] = Vec.new()
        let extra_texts: Vec[str] = Vec.new()
        for i in 1..source_paths.len() as i32:
            extra_names.push(with_str_clone_ref(source_paths.get(i as i64)))
            extra_texts.push(with_str_clone_ref(source_texts.get(i as i64)))
        zcu.set_extra_sources(move extra_names, move extra_texts)
        zcu = self.apply_cli_diag_mappings(move zcu)
        let pool = zcu.compile_source_frontend_mode(source_text, source_path, 0, 1)
        self.zcu = zcu
        pool

    mut fn check_pool(pool: AstPool, source_path: &str) -> bool:
        if pool.decl_count() == 0:
            return false
        if self.zcu.frontend_sema_completed == 0:
            runtime_eprint("internal error: frontend stopped before sema for '" ++ source_path ++ "' yet produced a module — refusing to report success (no-silent-fallbacks guard)")
            return false
        let prepared_pool = self.prepare_pool_after_typecheck_hooks(pool, source_path)
        if prepared_pool.decl_count() == 0:
            return false
        let _ = self.run_mir_lower(prepared_pool)
        not self.has_errors()

    mut fn check_file_with_build_settings(source_path: &str, include_paths: &Vec[str], defines: &Vec[str], link_libs: &Vec[str]) -> bool:
        var cfg = self.project_config_for_source(source_path)
        for ii in 0..include_paths.len() as i32:
            cfg.c_import_include_paths.push(with_str_clone_ref(include_paths.get(ii as i64)))
        for di in 0..defines.len() as i32:
            cfg.c_import_defines.push(with_str_clone_ref(defines.get(di as i64)))
        for li in 0..link_libs.len() as i32:
            cfg.link_libs.push(with_str_clone_ref(link_libs.get(li as i64)))
        let pool = self.compile_file_with_config(source_path, move cfg)
        self.check_pool(pool, source_path)

    mut fn check_source_texts(source_paths: &Vec[str], source_texts: &Vec[str]) -> bool:
        let pool = self.compile_entry_source_texts(source_paths, source_texts)
        if source_paths.len() == 0:
            return false
        self.check_pool(pool, source_paths.get(0))

    mut fn prepare_binary_link_from_pool(pool: AstPool, source_path: &str, obj_path: &str, bin_path: &str) -> CompilationBinaryLinkPlan:
        self.last_link_command_available = 0
        self.last_link_command = link_stage_empty_command()
        self.last_link_rc = 0
        compilation_debug_init(f"build_binary_to_path:compiled {source_path} decls={pool.decl_count()}")
        if pool.decl_count() == 0:
            return compilation_binary_link_plan_fail()
        let prepared_pool = self.prepare_pool_after_typecheck_hooks(pool, source_path)
        if prepared_pool.decl_count() == 0:
            compilation_cleanup_build_products(obj_path, bin_path)
            return compilation_binary_link_plan_fail()
        if not self.ensure_codegen_mir(prepared_pool):
            compilation_debug_init("build_binary_to_path:ensure_codegen_mir FAILED")
            compilation_cleanup_build_products(obj_path, bin_path)
            return compilation_binary_link_plan_fail()
        let active_pool: AstPool = self.active_pool(prepared_pool)
        let opt_level = self.config.opt_level
        let requires_async_runtime = self.zcu.last_async_mir_module.requires_async_runtime()
        compilation_debug_pool_flow("build_binary_to_path:after_codegen", self.zcu.pool, active_pool, self.zcu.last_sema)
        compilation_debug_init("build_binary_to_path:compile_to_object_backend")
        let backend_rc = self.zcu.compile_to_object_backend(active_pool, opt_level, obj_path, self.config.debug_info, false)
        if backend_rc != 0:
            compilation_debug_init(f"build_binary_to_path:backend FAILED rc={backend_rc}")
            compilation_cleanup_build_products(obj_path, bin_path)
            return compilation_binary_link_plan_fail()
        compilation_debug_init("build_binary_to_path:linking")
        // Merge direct and dependency link libraries from project config.
        var all_link_libs = move self.zcu.last_link_lib_names
        for lli in 0..self.zcu.project_config.link_libs.len() as i32:
            all_link_libs.push(with_str_clone_ref(self.zcu.project_config.link_libs.get(lli as i64)))
        for dli in 0..self.zcu.project_config.dep_link_libs.len() as i32:
            all_link_libs.push(with_str_clone_ref(self.zcu.project_config.dep_link_libs.get(dli as i64)))
        var _sp_dla = move self.zcu.project_config.dep_link_args
        var unit_objects = codegen_unit_extra_objects(obj_path, self.zcu.last_codegen_unit_count)
        // D38: `--link-object` objects (a stage link's .wo bundles) join the
        // link exactly as codegen units do — full linker inputs, probed for
        // undefined symbols like any other unit.
        for loi in 0..self.link_objects.len() as i32:
            unit_objects.push(with_str_clone_ref(self.link_objects.get(loi as i64)))
        // D30 R2c: this compile emitted the runtime in-unit iff the lane is
        // on AND the frontend actually parsed the rt prefix (prelude on).
        let rt_in_unit = if runtime_getenv("WITH_RT_IN_UNIT").len() > 0 and self.config.prelude_mode != PRELUDE_NONE(): 1 else: 0
        link_stage_set_rt_in_unit(rt_in_unit)
        var link_plan = link_stage_link_object_to_binary_plan_with_units(obj_path, unit_objects, bin_path, all_link_libs, self.zcu.project_config.link_search_paths, move _sp_dla, requires_async_runtime)
        if not link_plan.ok:
            compilation_cleanup_build_products(obj_path, bin_path)
            return compilation_binary_link_plan_fail()
        CompilationBinaryLinkPlan {
            ok: true,
            obj_path: with_str_clone_ref(obj_path),
            bin_path: with_str_clone_ref(bin_path),
            command: move link_plan.command,
        }

    mut fn execute_binary_link_plan(plan: CompilationBinaryLinkPlan) -> str:
        if not plan.ok:
            return ""
        let bin_path = plan.bin_path
        var link_result = compilation_execute_binary_link_plan(self.config.debug_info, plan)
        self.last_link_command_available = 1
        self.last_link_command = move link_result.command
        self.last_link_rc = link_result.rc
        if not link_result.ok:
            return ""
        bin_path

fn compilation_execute_binary_link_plan(debug_info: bool, plan: CompilationBinaryLinkPlan) -> LinkStageResult:
    if not plan.ok:
        return link_stage_result_fail()
    var owned = move plan
    let t_link = profile_now()
    let link_result = link_stage_result_for_command(move owned.command)
    if not link_result.ok:
        compilation_debug_init("build_binary_to_path:link FAILED")
        compilation_cleanup_build_products(owned.obj_path, owned.bin_path)
        return link_result
    if profile_enabled():
        profile_emit("link", t_link, "")
    if debug_info:
        let t_dsym = profile_now()
        compilation_run_dsymutil_best_effort(owned.bin_path)
        if profile_enabled():
            profile_emit("dsymutil", t_dsym, "")
    compilation_remove_file_best_effort(owned.obj_path)
    compilation_remove_unit_objects_best_effort(owned.obj_path)
    link_result

impl Compilation:
    mut fn finish_binary_from_pool(pool: AstPool, source_path: &str, obj_path: &str, bin_path: &str) -> str:
        let link_plan = self.prepare_binary_link_from_pool(pool, source_path, obj_path, bin_path)
        self.execute_binary_link_plan(link_plan)

    mut fn emit_object_to_path(source_path: &str, obj_path: &str) -> str:
        let output_dir = link_stage_dirname(obj_path)
        if not compilation_ensure_output_dir(output_dir):
            return ""

        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        let prepared_pool = self.prepare_pool_after_typecheck_hooks(pool, source_path)
        if prepared_pool.decl_count() == 0:
            return ""
        if not self.ensure_codegen_mir(prepared_pool):
            return ""
        let active_pool: AstPool = self.active_pool(prepared_pool)
        let opt_level = self.config.opt_level
        let backend_rc = self.zcu.compile_to_object_backend(active_pool, opt_level, obj_path, self.config.debug_info, true)
        if backend_rc != 0:
            compilation_remove_file_best_effort(obj_path)
            return ""
        // D39: the interface and its fingerprint come from one model of the
        // Sema codegen handed back (layouts frozen); the manifest records both.
        var interface_sha = ""
        var fingerprint = ""
        var omitted: Vec[str] = Vec.new()
        if self.bundle_interface_path.len() > 0 or self.bundle_fingerprint_path.len() > 0 or self.bundle_manifest_path.len() > 0:
            let model = self.bundle_model(if self.bundle_interface_path.len() > 0: "--emit-bundle-interface" else if self.bundle_fingerprint_path.len() > 0: "--bundle-fingerprint" else: "--emit-bundle-manifest")
            if not model.ok:
                compilation_remove_file_best_effort(obj_path)
                return ""
            if self.bundle_interface_path.len() > 0:
                interface_sha = self.write_bundle_interface(&model)
                if interface_sha.len() == 0:
                    compilation_remove_file_best_effort(obj_path)
                    return ""
            if self.bundle_fingerprint_path.len() > 0:
                fingerprint = self.write_bundle_fingerprint(&model)
                if fingerprint.len() == 0:
                    compilation_remove_file_best_effort(obj_path)
                    return ""
            omitted = driver_clone_str_vec(&model.omitted)
        if self.bundle_manifest_path.len() > 0 and not self.write_bundle_manifest(obj_path, fingerprint, interface_sha, &omitted):
            compilation_remove_file_best_effort(obj_path)
            return ""
        with_str_clone_ref(obj_path)

    // D39: write the bundle's `.wi` (docs/wo_bundles.md) to
    // --emit-bundle-interface; returns the sha256 of its bytes (the
    // manifest's `interface-sha`), "" on refusal.
    fn write_bundle_interface(model: &BundleInterfaceModel) -> str:
        let rendered = bundle_interface_render(&self.zcu.last_sema, model)
        for ei in 0..rendered.errors.len() as i32:
            runtime_eprint("error: " ++ rendered.errors.get(ei as i64))
        if rendered.errors.len() > 0:
            return ""
        if runtime_write_file(self.bundle_interface_path, rendered.text) != 0:
            runtime_eprint("error: could not write bundle interface: " ++ self.bundle_interface_path)
            return ""
        bundle_text_sha256(rendered.text)

    // D38/D39 (docs/wo_bundles.md): the .wo manifest for the object just
    // emitted — the compiler's ABI identity, the target, the object's file
    // name, the fingerprint and interface-sha of the .wi written beside it
    // (the pairing check --link-bundle makes), and one link-name prefix per
    // corpus module (the on-demand link predicate and the link-time
    // interface check; never a prelude or std module the object happens to
    // contain). build.w adds the bundle name, the key, and the corpus hash
    // it computed.
    mut fn write_bundle_manifest(obj_path: &str, fingerprint: &str, interface_sha: &str, omitted: &Vec[str]) -> bool:
        if not compiler_abi_sha_is_stamped():
            with_eprint("error: --emit-bundle-manifest: this compiler carries no ABI stamp (unstamped binary); a bundle key needs one")
            return false
        var text = "abi-sha " ++ compiler_abi_sha() ++ "\n"
        text = text ++ "target " ++ target_spec_resolved_name() ++ "\n"
        text = text ++ "object " ++ link_stage_basename(obj_path) ++ "\n"
        if fingerprint.len() > 0:
            text = text ++ "fingerprint " ++ fingerprint ++ "\n"
        if interface_sha.len() > 0:
            text = text ++ "interface-sha " ++ interface_sha ++ "\n"
        // D39 Level 0: declarations the boundary cannot carry, one
        // `omitted <module> <name> <why>` line each (the .wi names them too)
        for oi in 0..omitted.len() as i32:
            text = text ++ "omitted " ++ omitted.get(oi as i64).replace("\t", " ") ++ "\n"
        let seen: Vec[str] = Vec.new()
        for pi in 0..self.zcu.decl_source_paths.len() as i32:
            let path = self.zcu.decl_source_paths.get(pi as i64)
            if path.len() == 0:
                continue
            let canonical = codegen_canonical_module_path(path)
            if not bundle_corpus_contains(self.bundle_corpus, canonical):
                continue
            let prefix = fn_abi_module_link_prefix(path)
            if prefix.len() == 0 or seen.contains(prefix):
                continue
            seen.push(with_str_clone_ref(prefix))
            text = text ++ "prefix " ++ prefix ++ " " ++ canonical ++ "\n"
        if seen.len() == 0:
            with_eprint("error: --emit-bundle-manifest: no module under corpus '" ++ self.bundle_corpus ++ "' in " ++ obj_path)
            return false
        if runtime_write_file(self.bundle_manifest_path, text) != 0:
            with_eprint("error: could not write bundle manifest: " ++ self.bundle_manifest_path)
            return false
        true

    mut fn emit_object_to_path_with_build_settings(source_path: &str, obj_path: &str, include_paths: &Vec[str], defines: &Vec[str], link_libs: &Vec[str]) -> str:
        let output_dir = link_stage_dirname(obj_path)
        if not compilation_ensure_output_dir(output_dir):
            return ""

        var cfg = self.project_config_for_source(source_path)
        for ii in 0..include_paths.len() as i32:
            cfg.c_import_include_paths.push(with_str_clone_ref(include_paths.get(ii as i64)))
        for di in 0..defines.len() as i32:
            cfg.c_import_defines.push(with_str_clone_ref(defines.get(di as i64)))
        for li in 0..link_libs.len() as i32:
            cfg.link_libs.push(with_str_clone_ref(link_libs.get(li as i64)))
        let pool = self.compile_file_with_config(source_path, move cfg)
        if pool.decl_count() == 0:
            return ""
        if not self.ensure_codegen_mir(pool):
            return ""
        let active_pool: AstPool = self.active_pool(pool)
        let opt_level = self.config.opt_level
        let backend_rc = self.zcu.compile_to_object_backend(active_pool, opt_level, obj_path, self.config.debug_info, true)
        if backend_rc != 0:
            compilation_remove_file_best_effort(obj_path)
            return ""
        with_str_clone_ref(obj_path)

    mut fn emit_archive_to_path_with_build_settings(source_path: &str, ar_path: &str, include_paths: &Vec[str], defines: &Vec[str], link_libs: &Vec[str]) -> str:
        if ar_path.len() == 0:
            return ""
        let output_dir = link_stage_dirname(ar_path)
        if not compilation_ensure_output_dir(output_dir):
            return ""
        let obj_path = ar_path ++ ".o"
        let obj = self.emit_object_to_path_with_build_settings(source_path, obj_path, include_paths, defines, link_libs)
        if obj == "":
            return ""
        let ar = link_stage_make_archive_to_path(obj, ar_path)
        compilation_remove_file_best_effort(obj)
        ar

    mut fn build_binary_to_path(source_path: &str, bin_path: &str) -> str:
        if bin_path.len() == 0:
            return self.build_binary(source_path)
        let obj_path = bin_path ++ ".o"
        let output_dir = link_stage_dirname(bin_path)
        if not compilation_ensure_output_dir(output_dir):
            return ""
        compilation_remove_dsym_best_effort(bin_path)

        let pool = self.compile_entry_file(source_path)
        self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

    mut fn build_binary_to_path_with_build_settings(source_path: &str, bin_path: &str, include_paths: &Vec[str], defines: &Vec[str], link_libs: &Vec[str]) -> str:
        if bin_path.len() == 0:
            return self.build_binary_to_path(source_path, bin_path)
        let obj_path = bin_path ++ ".o"
        let output_dir = link_stage_dirname(bin_path)
        if not compilation_ensure_output_dir(output_dir):
            return ""
        compilation_remove_dsym_best_effort(bin_path)

        var cfg = self.project_config_for_source(source_path)
        for ii in 0..include_paths.len() as i32:
            cfg.c_import_include_paths.push(with_str_clone_ref(include_paths.get(ii as i64)))
        for di in 0..defines.len() as i32:
            cfg.c_import_defines.push(with_str_clone_ref(defines.get(di as i64)))
        for li in 0..link_libs.len() as i32:
            cfg.link_libs.push(with_str_clone_ref(link_libs.get(li as i64)))
        let pool = self.compile_entry_file_with_config(source_path, move cfg)
        self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

    mut fn build_binary_to_path_with_link_libs(source_path: &str, bin_path: &str, link_libs: &Vec[str]) -> str:
        let include_paths: Vec[str] = Vec.new()
        let defines: Vec[str] = Vec.new()
        self.build_binary_to_path_with_build_settings(source_path, bin_path, include_paths, defines, link_libs)

    mut fn build_binary_from_source_to_path(source_path: &str, source_text: &str, bin_path: &str) -> str:
        if bin_path.len() == 0:
            return self.build_binary_from_source(source_path, source_text)
        let obj_path = bin_path ++ ".o"
        let output_dir = link_stage_dirname(bin_path)
        if not compilation_ensure_output_dir(output_dir):
            return ""
        compilation_remove_dsym_best_effort(bin_path)

        let pool = self.compile_source_text(source_path, source_text)
        self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

    mut fn build_binary_from_source_to_path_with_build_settings(source_path: &str, source_text: &str, bin_path: &str, include_paths: &Vec[str], defines: &Vec[str], link_libs: &Vec[str]) -> str:
        if bin_path.len() == 0:
            return self.build_binary_from_source_to_path(source_path, source_text, bin_path)
        let obj_path = bin_path ++ ".o"
        let output_dir = link_stage_dirname(bin_path)
        if not compilation_ensure_output_dir(output_dir):
            return ""
        compilation_remove_dsym_best_effort(bin_path)

        var cfg = self.project_config_for_source(source_path)
        for ii in 0..include_paths.len() as i32:
            cfg.c_import_include_paths.push(with_str_clone_ref(include_paths.get(ii as i64)))
        for di in 0..defines.len() as i32:
            cfg.c_import_defines.push(with_str_clone_ref(defines.get(di as i64)))
        for li in 0..link_libs.len() as i32:
            cfg.link_libs.push(with_str_clone_ref(link_libs.get(li as i64)))
        let pool = self.compile_source_text_with_config(source_path, source_text, move cfg)
        self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

    mut fn build_entry_binary_from_source_to_path(source_path: &str, source_text: &str, bin_path: &str) -> str:
        let source_paths: Vec[str] = Vec.new()
        let source_texts: Vec[str] = Vec.new()
        source_paths.push(with_str_clone_ref(source_path))
        source_texts.push(with_str_clone_ref(source_text))
        self.build_entry_binary_from_sources_to_path(source_paths, source_texts, bin_path)

    mut fn build_entry_binary_from_sources_to_path(source_paths: &Vec[str], source_texts: &Vec[str], bin_path: &str) -> str:
        if source_paths.len() == 0 or source_texts.len() == 0 or source_paths.len() != source_texts.len():
            runtime_eprint("error: build_entry_binary_from_sources_to_path requires matching non-empty source paths and texts")
            return ""
        let source_path = source_paths.get(0)
        if bin_path.len() == 0:
            return self.build_binary_from_source(source_path, source_texts.get(0))
        let obj_path = bin_path ++ ".o"
        let output_dir = link_stage_dirname(bin_path)
        if not compilation_ensure_output_dir(output_dir):
            return ""
        compilation_remove_dsym_best_effort(bin_path)

        let pool = self.compile_entry_source_texts(source_paths, source_texts)
        self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

    mut fn emit_c(source_path: &str, output_path: &str) -> str:
        // The emit-C lane compiles a corpus in-unit as C; it has no bundle
        // objects to link and no bodies for an interface declaration
        // (docs/wo_bundles.md), so both are refused here rather than emitted
        // as stubs.
        if self.link_bundles.len() > 0:
            runtime_eprint("error: --emit-c cannot link a .wo bundle (--link-bundle): the emit-C lane compiles every module in-unit (docs/wo_bundles.md)")
            return ""
        if source_path.ends_with(".wi"):
            runtime_eprint("error: --emit-c needs source bodies; '" ++ source_path ++ "' is an interface (D39)")
            return ""
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        let prepared_pool = self.prepare_pool_after_typecheck_hooks(pool, source_path)
        if prepared_pool.decl_count() == 0:
            return ""
        if not self.ensure_codegen_mir(prepared_pool):
            runtime_eprint("error: C emission failed during MIR lowering")
            return ""
        let typed_pool: AstPool = self.active_pool(prepared_pool)

        var final_output = with_str_clone_ref(output_path)
        if final_output.len() == 0:
            final_output = link_stage_output_path_for_source(source_path) ++ ".c"
        if not compilation_ensure_output_dir(link_stage_dirname(final_output)):
            return ""

        var emit_intern = self.zcu.pool
        if self.zcu.last_sema.pool.state.symbol_texts.len() as i32 > 1:
            emit_intern = self.zcu.last_sema.pool
        let emitted = c_emit_module(move self.zcu.last_mir_module, typed_pool, emit_intern, move self.zcu.last_sema, self.zcu.current_source_path, self.zcu.current_source_text, self.zcu.project_config.overflow_mode)
        if emitted.ok == 0:
            runtime_eprint("error: C emission failed: " ++ emitted.err_msg)
            return ""

        let write_rc = runtime_write_file(final_output, emitted.source)
        if write_rc != 0:
            runtime_eprint("error: failed to write '" ++ final_output ++ "'")
            return ""

        final_output

    mut fn emit_typed(pool: AstPool) -> bool:
        var zcu = move self.zcu
        let typed_pool = pool
        if typed_pool.decl_count() == 0:
            runtime_eprint("error: no source loaded for typed emission")
            return false
        if zcu.last_sema.ast.decl_count() == typed_pool.decl_count() and typed_pool.decl_count() > 0:
            zcu.last_sema.emit_typed_module(0)
            self.zcu = zcu
            return true

        var sema = zcu.configure_tracked_input_sema(Sema.init(zcu.pool, move zcu.diagnostics, typed_pool))
        // #782: a bare assignment would move the source text out of the Zcu
        // and blank it for later consumers (analyze reads it).
        sema.source_text = with_str_clone_ref(zcu.current_source_text)
        // Clone: see run_mir_lower — bare assignments would move these tables
        // out of the Zcu and blank them for later consumers.
        sema.decl_source_paths = sema_clone_str_vec(&zcu.decl_source_paths)
        sema.decl_source_file_ids = sema_clone_i32_vec(&zcu.decl_source_file_ids)
        sema.decl_is_c_import = sema_clone_i32_vec(&zcu.decl_is_c_import)
        sema.source_text_file_ids = sema_clone_i32_vec(&zcu.source_text_file_ids)
        sema.source_text_names = sema_clone_str_vec(&zcu.source_text_names)
        sema.source_texts = sema_clone_str_vec(&zcu.source_texts)
        sema.tool_mode_entry_path = with_str_clone_ref(zcu.tool_mode_entry_path)
        sema.runtime_available = if zcu.project_config.runtime_available: 1 else: 0
        sema.runtime_fiber_stack_size = zcu.project_config.runtime_fiber_stack_size
        sema.runtime_fiber_pool_size = zcu.project_config.runtime_fiber_pool_size
        sema.runtime_fiber_worker_count = zcu.project_config.runtime_fiber_worker_count
        sema.copy_warn_threshold = zcu.project_config.copy_warn_threshold
        sema.lint_partial_statement_match = if zcu.project_config.lint_partial_statement_match: 1 else: 0
        sema.overflow_mode = zcu.project_config.overflow_mode
        if zcu.project_config.no_std or self.config.no_std:
            sema.no_std = 1
        if zcu.project_config.alloc_mode or self.config.alloc_mode:
            sema.alloc = 1
        sema.check_module()

        zcu.diagnostics = move sema.diags
        // #782: restore sema's wholeness before the whole-value transfer —
        // sync_from_sema must never see the blanked diags slot.
        sema.diags = DiagnosticList.init()
        zcu.sync_from_sema(move sema)
        zcu.set_typed_snapshot("", typed_pool)
        zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")

        if zcu.diagnostics.has_errors():
            zcu.render_current_diagnostics()
            self.zcu = zcu
            return false

        zcu.last_sema.emit_typed_module(0)
        self.zcu = zcu
        true

    mut fn emit_typed_file(source_path: &str) -> bool:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return false
        self.emit_typed(pool)

    mut fn print_mir(pool: AstPool) -> bool:
        if self.zcu.last_mir_module.body_count() == 0:
            let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            return false
        print_mir_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema)
        true

    mut fn print_mir_file(source_path: &str) -> bool:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return false
        self.print_mir(pool)

    mut fn dump_drop_state(pool: AstPool) -> str:
        if self.zcu.last_mir_module.body_count() == 0:
            let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            return ""
        dump_drop_state_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema)

    mut fn dump_drop_state_file(source_path: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.dump_drop_state(pool)

    mut fn trace_place(pool: AstPool, spec: &str) -> str:
        if self.zcu.last_mir_module.body_count() == 0:
            let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            return ""
        trace_place_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema, spec)

    mut fn trace_place_file(source_path: &str, spec: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.trace_place(pool, spec)

    mut fn explain_mir_origin(pool: AstPool, spec: &str) -> str:
        if self.zcu.last_mir_module.body_count() == 0:
            let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            return ""
        explain_mir_origin_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema, spec)

    mut fn explain_mir_origin_file(source_path: &str, spec: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.explain_mir_origin(pool, spec)

    mut fn trace_ownership(pool: AstPool, spec: &str) -> str:
        if self.zcu.last_mir_module.body_count() == 0:
            let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            return ""
        trace_ownership_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema, spec)

    mut fn trace_ownership_file(source_path: &str, spec: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.trace_ownership(pool, spec)

    mut fn dump_drop_plan(pool: AstPool) -> str:
        if self.zcu.last_mir_module.body_count() == 0:
            let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            return ""
        dump_drop_plan_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema)

    mut fn dump_drop_plan_file(source_path: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.dump_drop_plan(pool)

    mut fn dump_place_map(pool: AstPool) -> str:
        if self.zcu.last_mir_module.body_count() == 0:
            let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            return ""
        dump_place_map_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema)

    mut fn dump_place_map_file(source_path: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.dump_place_map(pool)

    mut fn dump_abi_file(source_path: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.zcu.last_sema.dump_abi()

fn analysis_request_is_semantic_snapshot(request: &str) -> bool:
    if request == "audit:receivers" or request == "audit:receiver-surface" or request == "audit:effects" or request == "audit:storage": return true
    if request == "audit:methods": return true
    if request == "move-sites": return true
    if request.starts_with("select:stage=ast") or request.starts_with("select:stage=sema") or request.starts_with("select:stage=diagnostic"): return true
    if request.starts_with("select:kind=declaration") or request.starts_with("select:kind=signature") or request.starts_with("select:kind=parameter"): return true
    if request.starts_with("select:kind=receiver") or request.starts_with("select:kind=effect-edge") or request.starts_with("select:kind=specialization"): return true
    if request.starts_with("select:kind=type") or request.starts_with("select:kind=field") or request.starts_with("select:kind=expression") or request.starts_with("select:kind=diagnostic"): return true
    if request.starts_with("select:kind=method-registration") or request.starts_with("select:kind=method-resolution"): return true
    if request.starts_with("explain:effect:") or request.starts_with("explain:specialization:") or request.starts_with("explain:diagnostic:"): return true
    if request.starts_with("explain:type:") or request.starts_with("explain:field:") or request.starts_with("explain:expression:"): return true
    if request.starts_with("explain:method:") or request.starts_with("explain:resolution:"): return true
    request.starts_with("explain:node:")

fn analysis_request_after_mir(request: &str): request.starts_with("after-mir:")
fn analysis_request_inner(request: &str):
    if analysis_request_after_mir(request): request.slice(10, request.len()) else: with_str_clone_ref(request)

impl Compilation:
    pub mut fn analyze_file(source_path: &str, request: &str) -> CompilerAnalysisResult:
        self.zcu.analysis_partial_semantics = 1
        let pool = self.compile_file(source_path)
        let after_mir = analysis_request_after_mir(request)
        let inner_request = analysis_request_inner(request)
        // Sema diagnostics return an empty public AstPool, but the synchronized
        // last_sema retains the complete declaration/effect state for the flag-day
        // receiver work list and for semantic diagnosis queries.
        if not after_mir and analysis_request_is_semantic_snapshot(inner_request) and self.zcu.last_sema.ast.decl_count() > 0:
            return compiler_analysis_run(self.zcu.last_sema, self.zcu.last_mir_module, self.zcu.pool, self.zcu.current_source_path, self.zcu.current_source_text, inner_request)
        if pool.decl_count() == 0:
            if inner_request.starts_with("select:") and self.zcu.last_sema.ast.decl_count() > 0:
                return compiler_analysis_run(self.zcu.last_sema, self.zcu.last_mir_module, self.zcu.pool, self.zcu.current_source_path, self.zcu.current_source_text, inner_request)
            return CompilerAnalysisResult { text: "error: analysis compilation failed\n", status: 1, needs_codegen: false, codegen_query: "", report: AnalysisReport.init() }
        let active = self.active_pool(pool)
        let _ = self.run_mir_lower(active)
        if self.zcu.last_mir_module.body_count() == 0:
            if after_mir and self.zcu.last_sema.ast.decl_count() > 0:
                return compiler_analysis_run(self.zcu.last_sema, self.zcu.last_mir_module, self.zcu.pool, self.zcu.current_source_path, self.zcu.current_source_text, inner_request)
            return CompilerAnalysisResult { text: "error: analysis produced no MIR\n", status: 1, needs_codegen: false, codegen_query: "", report: AnalysisReport.init() }
        var result = compiler_analysis_run(self.zcu.last_sema, self.zcu.last_mir_module, self.zcu.pool, self.zcu.current_source_path, self.zcu.current_source_text, inner_request)
        if result.needs_codegen:
            let backend = self.zcu.analyze_codegen_backend(self.active_pool(active), self.config.opt_level, result.codegen_query)
            result.report.merge(&backend.report)
            result.text = compiler_analysis_render(&result.report, inner_request)
            if backend.status != 0:
                result.status = 1
        result

// Public one-shot entry for compiler-integrated tools. Compilation remains an
// orchestration implementation detail; tools consume the shared analysis schema.
pub fn compiler_analyze_file(source_path: &str, request: &str) -> CompilerAnalysisResult:
    var comp = Compilation.init()
    comp.analyze_file(source_path, request)

impl Compilation:
    mut fn trace_cleanup_edge(pool: AstPool, spec: &str) -> str:
        if self.zcu.last_mir_module.body_count() == 0:
            let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            return ""
        trace_cleanup_edge_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema, spec)

    mut fn trace_cleanup_edge_file(source_path: &str, spec: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.trace_cleanup_edge(pool, spec)

    mut fn validate_ownership_file(source_path: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return "compile failed before ownership validation"
        let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            if self.zcu.diagnostics.has_errors():
                return "diagnostics present before ownership validation"
            return "MIR lowering produced no bodies"
        let err = validate_ownership_mir_module(self.zcu.last_mir_module)
        if err.len() > 0:
            return err
        "ok"

    mut fn validate_all_file(source_path: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return "compile failed before validation"
        let _ = self.run_mir_lower(pool)
        if self.zcu.last_mir_module.body_count() == 0:
            if self.zcu.diagnostics.has_errors():
                return "diagnostics present before MIR validation"
            return "MIR lowering produced no bodies"
        let mir_err = validate_all_mir_module(self.zcu.last_mir_module)
        if mir_err.len() > 0:
            return mir_err
        "ok"

    mut fn dump_async_mir(pool: AstPool) -> str:
        if self.zcu.last_async_mir_module.body_count() == 0:
            let _ = self.run_async_mir_lower(pool)
        if self.zcu.last_async_mir_module.body_count() == 0:
            return ""
        let text = dump_async_mir_module(self.zcu.last_async_mir_module, self.zcu.pool)
        var mir_snapshot = move self.zcu.last_mir_module
        var async_snapshot = move self.zcu.last_async_mir_module
        self.zcu.set_codegen_snapshot(move mir_snapshot, self.zcu.last_mir_dump, move async_snapshot, text)
        text

    mut fn dump_async_mir_file(source_path: &str) -> str:
        let pool = self.compile_file(source_path)
        if pool.decl_count() == 0:
            return ""
        self.dump_async_mir(pool)

    fn print_warnings():
        self.zcu.print_warnings()

    fn tracked_input_paths() -> Vec[str]:
        var out: Vec[str] = Vec.new()
        for i in 0..self.zcu.tracked_input_paths.len() as i32:
            out.push(with_str_clone_ref(self.zcu.tracked_input_paths.get(i as i64)))
        out

    fn active_pool(pool: AstPool) -> AstPool:
        if self.zcu.typed_pool_cache.decl_count() > 0:
            self.zcu.typed_pool_cache.require_same_storage(&pool, "Compilation.active_pool")
            return self.zcu.typed_pool_cache
        pool

    mut fn run_mir_lower(pool: AstPool) -> Unit:
        let do_profile = profile_enabled()
        let active_pool = pool
        compilation_debug_pool_flow("run_mir_lower:start", self.zcu.pool, active_pool, self.zcu.last_sema)
        // Reuse the frontend's checked sema when it matches this pool (the
        // emit_typed guard at emit_typed): re-running check_module over the
        // same pool is a second full sema pass for zero new facts, and under
        // #747's seed-built stage1 it doubles peak memory. The reused sema
        // takes the Zcu diagnostics exactly like Sema.init does on the fresh
        // path, so diagnostic continuity is unchanged.
        // types_frozen guard: a prior run_mir_lower in this same invocation
        // already consumed and froze last_sema; lowering must start from a
        // still-mutable sema, so that rare flow keeps the fresh-check path.
        let reuse_checked_sema = self.zcu.last_sema.ast.decl_count() == active_pool.decl_count() and active_pool.decl_count() > 0 and self.zcu.last_sema.types_frozen == 0
        var sema = Sema.placeholder(InternPool.init(), DiagnosticList.init(), AstPool.new())
        if reuse_checked_sema:
            sema = move self.zcu.last_sema
            // Reinitialize the moved-out slot immediately: every exit path
            // below syncs the final sema back, but the checker (rightly)
            // wants the field valid on this path before any read.
            self.zcu.last_sema = Sema.placeholder(InternPool.init(), DiagnosticList.init(), AstPool.new())
            sema.diags = move self.zcu.diagnostics
            sema.set_tracked_input_context(self.zcu.tracked_input_root(), &self.zcu.tracked_input_paths)
            // The frontend sema already emitted config warnings; the MIR-phase
            // sema never re-emits them (the fresh path's default is 0 too).
            sema.emit_config_warnings = 0
        else:
            sema = self.zcu.configure_tracked_input_sema(Sema.init(self.zcu.pool, move self.zcu.diagnostics, active_pool))
            sema.source_text = move self.zcu.current_source_text
            // Clone like Frontend's seam: a bare assignment moves the table out of
            // the Zcu (single-owner Vec), and the backend's module-object pruning
            // then sees empty decl paths and emits every imported module's bodies.
            sema.decl_source_paths = sema_clone_str_vec(&self.zcu.decl_source_paths)
            sema.decl_source_file_ids = sema_clone_i32_vec(&self.zcu.decl_source_file_ids)
            sema.decl_is_c_import = sema_clone_i32_vec(&self.zcu.decl_is_c_import)
            sema.source_text_file_ids = sema_clone_i32_vec(&self.zcu.source_text_file_ids)
            sema.source_text_names = sema_clone_str_vec(&self.zcu.source_text_names)
            sema.source_texts = sema_clone_str_vec(&self.zcu.source_texts)
            sema.tool_mode_entry_path = with_str_clone_ref(self.zcu.tool_mode_entry_path)
            sema.runtime_available = if self.zcu.project_config.runtime_available: 1 else: 0
            sema.runtime_fiber_stack_size = self.zcu.project_config.runtime_fiber_stack_size
            sema.runtime_fiber_pool_size = self.zcu.project_config.runtime_fiber_pool_size
            sema.runtime_fiber_worker_count = self.zcu.project_config.runtime_fiber_worker_count
            sema.copy_warn_threshold = self.zcu.project_config.copy_warn_threshold
            sema.lint_partial_statement_match = if self.zcu.project_config.lint_partial_statement_match: 1 else: 0
            sema.overflow_mode = self.zcu.project_config.overflow_mode
            sema.init_module_graph(&self.zcu.last_resolved)
            if self.zcu.project_config.no_std or self.config.no_std:
                sema.no_std = 1
            if self.zcu.project_config.alloc_mode or self.config.alloc_mode:
                sema.alloc = 1
        compilation_debug_pool_flow("run_mir_lower:after_init", self.zcu.pool, active_pool, sema)
        let t_sema = profile_now()
        if not reuse_checked_sema:
            sema.check_module()
        // Prime the query tables for ordinary MIR lowering. Concrete generic
        // specializations are rechecked/lowered below and refresh these tables if
        // they add types. The hard freeze belongs after all MIR exists, not before:
        // codegen is the first phase that must be semantically immutable.
        sema.preregister_mir_types()
        if do_profile:
            profile_emit("sema", t_sema, f"types={sema.type_kinds.len() as i32}")
        compilation_debug_pool_flow("run_mir_lower:after_check", self.zcu.pool, active_pool, sema)

        // Check for sema errors before lowering
        if sema.diags.has_errors():
            self.zcu.diagnostics = move sema.diags
            self.zcu.sync_from_sema(move sema)
            compilation_debug_pool_flow("run_mir_lower:after_sync", self.zcu.pool, active_pool, self.zcu.last_sema)
            self.zcu.render_current_diagnostics()
            self.zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
            return

        let t_mir = profile_now()
        // MIR lowering owns the still-mutable semantic state and returns it with
        // the complete module. This makes the phase transfer explicit: no shallow
        // Sema alias survives a Vec reallocation while generic specializations add
        // their final dependent types.
        var lowered = lower_module(move sema, active_pool, self.zcu.pool)
        sema = move lowered.sema
        let mir_mod = lowered.mir_module
        sema.freeze_symbols()
        sema.freeze_types()
        let tailrec_syms = collect_tailrec_fn_syms(&sema, active_pool, self.zcu.pool)
        if tailrec_syms.len() > 0:
            let tailrec_violations = mir_mod.verify_tailrec_contracts(&sema, active_pool, tailrec_syms)
            if tailrec_violations.len() > 0:
                for vi in 0..tailrec_violations.len() as i32:
                    let violation = tailrec_violations.get(vi as i64)
                    let start = active_pool.get_start(violation.node)
                    let end_raw = active_pool.get_end(violation.node)
                    let end = if end_raw > start: end_raw else: start + 1
                    let span = Span { file: sema.local_file_id, start, end }
                    sema.diags.emit(Diagnostic.err(violation.message, span))
                self.zcu.diagnostics = move sema.diags
                self.zcu.sync_from_sema(move sema)
                compilation_debug_pool_flow("run_mir_lower:after_sync", self.zcu.pool, active_pool, self.zcu.last_sema)
                self.zcu.render_all_diagnostics_frontend()
                self.zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
                return
        if sema.diags.has_errors():
            self.zcu.diagnostics = move sema.diags
            self.zcu.sync_from_sema(move sema)
            compilation_debug_pool_flow("run_mir_lower:after_sync", self.zcu.pool, active_pool, self.zcu.last_sema)
            self.zcu.render_all_diagnostics_frontend()
            self.zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
            return
        if do_profile:
            profile_emit("mir.lower", t_mir, f"bodies={mir_mod.body_count()}")
        let t_suspend_check = profile_now()
        var _sp_diags = move sema.diags
        // #782: the callee borrows &sema while diags is moved out — hand it a
        // whole sema (fresh empty slot; it returns the merged list).
        sema.diags = DiagnosticList.init()
        sema.diags = check_no_await_guard_suspends(mir_mod, active_pool, &sema, move _sp_diags)
        if do_profile:
            profile_emit("mir.suspend_check", t_suspend_check, "")
        if sema.diags.has_errors():
            self.zcu.diagnostics = move sema.diags
            self.zcu.sync_from_sema(move sema)
            compilation_debug_pool_flow("run_mir_lower:after_sync", self.zcu.pool, active_pool, self.zcu.last_sema)
            self.zcu.render_all_diagnostics_frontend()
            self.zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
            return
        let t_mir_validate = profile_now()
        let mir_err = validate_typed_mir_module(mir_mod)
        if do_profile:
            profile_emit("mir.validate", t_mir_validate, "")
        if mir_validation_has_error(mir_err):
            let diag_span = compilation_mir_error_span(self.zcu, active_pool, mir_err.fn_sym, mir_err.span)
            sema.diags.emit(Diagnostic.err("invalid MIR before codegen: " ++ mir_err.message, diag_span))
            self.zcu.diagnostics = move sema.diags
            self.zcu.sync_from_sema(move sema)
            compilation_debug_pool_flow("run_mir_lower:after_sync", self.zcu.pool, active_pool, self.zcu.last_sema)
            self.zcu.render_all_diagnostics_frontend()
            self.zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
            return
        let t_async = profile_now()
        var _async_diags = move sema.diags
        // #782: same shape as the suspend check above — whole sema borrowed
        // while diags is taken; reinit before the borrow.
        sema.diags = DiagnosticList.init()
        var async_artifacts: AsyncLowerResult = lower_async_module(mir_mod, active_pool, self.zcu.pool, &sema, move _async_diags)
        if do_profile:
            profile_emit("async.lower", t_async, "")
        sema.diags = move async_artifacts.diags
        compilation_dump_type_names("post-mir-lower", active_pool, self.zcu.pool)

        // Sync sema AFTER MIR lowering — type tables are frozen but other
        // sema state (e.g. diagnostics) may have been updated.
        self.zcu.diagnostics = move sema.diags
        self.zcu.sync_from_sema(move sema)
        compilation_debug_pool_flow("run_mir_lower:after_sync", self.zcu.pool, active_pool, self.zcu.last_sema)
        var async_mod = move async_artifacts.out_mod
        self.zcu.set_codegen_snapshot(move mir_mod, "", move async_mod, "")

    mut fn run_async_mir_lower(pool: AstPool) -> Unit:
        let _ = self.run_mir_lower(pool)
        if self.zcu.diagnostics.has_errors():
            var mir_snapshot = move self.zcu.last_mir_module
            self.zcu.set_codegen_snapshot(move mir_snapshot, self.zcu.last_mir_dump, AsyncMirModule.init(), "")
            return

    mut fn ensure_codegen_mir(pool: AstPool) -> bool:
        if self.zcu.last_mir_module.body_count() == 0:
            let _ = self.run_mir_lower(pool)
        if self.zcu.diagnostics.has_errors():
            return false
        self.zcu.last_mir_module.body_count() > 0
