// CLI entry point for With compiler.

use Lexer
use Token
use Ast
use render
use Resolve
use Parser
use InternPool
use Diagnostic
use Source
use Compilation
use ConanClient
use Fmt
use Lsp

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_str_eq(a: str, b: str) -> i32
extern fn with_str_len(s: str) -> i64
extern fn with_str_byte_at(s: str, index: i64) -> i32
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_str_contains(s: str, needle: str) -> i32
extern fn with_str_slice(s: str, start: i64, end: i64) -> str
extern fn with_eprint(s: str) -> void
extern fn with_system(cmd: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_getenv_str(name: str) -> str
extern fn with_write(s: str) -> void
extern fn exit(code: i32) -> void
extern fn with_install_interrupt_handlers() -> void
extern fn with_raise_stack_limit() -> void

enum PreludeMode: i32:
    FullMode = 0
    CoreMode = 1
    NoneMode = 2

const CLI_DEFAULT_DEBUG_OPT_LEVEL: i32 = 0
const CLI_DEFAULT_BUILD_OPT_LEVEL: i32 = 0

type CliOptions {
    command: str,
    source_file: str,
    output_path: str,
    opt_level: i32,
    no_std: bool,
    alloc_mode: bool,
    dump_tokens_flag: bool,
    dump_ast_flag: bool,
    dump_resolved_flag: bool,
    dump_typed_flag: bool,
    dump_mir_flag: bool,
    dump_async_mir_flag: bool,
    deterministic_mode: bool,
    emit_c_mode: bool,
    prelude_mode: i32,
}

type TestDiscovery {
    parse_ok: bool,
    has_main: bool,
    test_names: Vec[str],
}

type BenchDiscovery {
    parse_ok: bool,
    has_main: bool,
    bench_names: Vec[str],
}

fn empty_test_discovery -> TestDiscovery:
    TestDiscovery { parse_ok: false, has_main: false, test_names: Vec.new() }

fn cli_options_default -> CliOptions:
    CliOptions {
        command: "",
        source_file: "",
        output_path: "",
        opt_level: 0,
        no_std: false,
        alloc_mode: false,
        dump_tokens_flag: false,
        dump_ast_flag: false,
        dump_resolved_flag: false,
        dump_typed_flag: false,
        dump_mir_flag: false,
        dump_async_mir_flag: false,
        deterministic_mode: false,
        emit_c_mode: false,
        prelude_mode: PreludeMode.FullMode,
    }

fn cli_command(argc: i32) -> str:
    if argc >= 2:
        return with_arg_at(1)
    ""

fn cli_help_topic(argc: i32) -> str:
    if argc >= 3:
        return with_arg_at(2)
    ""

fn cli_is_implicit_run(argc: i32) -> bool:
    if argc < 2:
        return false
    let arg = with_arg_at(1)
    arg.ends_with(".w")

fn cli_has_flag(argc: i32, flag: str) -> bool:
    var i = 2
    while i < argc:
        if with_arg_at(i) == flag:
            return true
        i = i + 1
    false

fn cli_default_opt_level(argc: i32) -> i32:
    if argc >= 2:
        let command = with_arg_at(1)
        if command == "build" or command == "run" or command == "test":
            return CLI_DEFAULT_BUILD_OPT_LEVEL
        if command.ends_with(".w"):
            return CLI_DEFAULT_BUILD_OPT_LEVEL
    CLI_DEFAULT_DEBUG_OPT_LEVEL

fn cli_opt_level(argc: i32) -> i32:
    var level = cli_default_opt_level(argc)
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "-O0":
            level = 0
        else if arg == "-O1":
            level = 1
        else if arg == "-O2":
            level = 2
        else if arg == "-O3":
            level = 3
        else if arg == "--release":
            if level < 2:
                level = 2
        i = i + 1
    level

fn cli_test_verbose(argc: i32) -> bool:
    cli_has_flag(argc, "-v") or cli_has_flag(argc, "--verbose")

fn cli_test_quiet(argc: i32) -> bool:
    cli_has_flag(argc, "-q") or cli_has_flag(argc, "--quiet")

fn cli_test_filter(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if with_str_starts_with(arg, "--filter=") != 0:
            return with_str_slice(arg, 9, with_str_len(arg))
        if (arg == "--filter" or arg == "-f") and i + 1 < argc:
            return with_arg_at(i + 1)
        i = i + 1
    ""

fn cli_prelude_mode(argc: i32) -> i32:
    var mode = PreludeMode.FullMode
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "--no-prelude":
            mode = PreludeMode.NoneMode
        else if arg == "--freestanding":
            mode = PreludeMode.NoneMode
        else if with_str_starts_with(arg, "--prelude=") != 0:
            let value = with_str_slice(arg, 10, with_str_len(arg))
            if value == "core":
                mode = PreludeMode.CoreMode
            else if value == "full":
                mode = PreludeMode.FullMode
            else if value == "none":
                mode = PreludeMode.NoneMode
            else:
                with_eprint("error: invalid --prelude value '" ++ value ++ "' (expected full|core|none)")
                exit(1)
                return PreludeMode.FullMode
        i = i + 1
    mode

fn parse_cli_options(argc: i32) -> CliOptions:
    var opts = cli_options_default()
    opts.command = cli_command(argc)
    opts.source_file = find_source_arg(argc)
    opts.output_path = find_output_arg(argc)
    opts.opt_level = cli_opt_level(argc)
    opts.no_std = cli_has_flag(argc, "--no-std") or cli_has_flag(argc, "--freestanding")
    opts.alloc_mode = cli_has_flag(argc, "--alloc")
    opts.dump_tokens_flag = cli_has_flag(argc, "--dump-tokens")
    opts.dump_ast_flag = cli_has_flag(argc, "--dump-ast")
    opts.dump_resolved_flag = cli_has_flag(argc, "--dump-resolved")
    opts.dump_typed_flag = cli_has_flag(argc, "--dump-typed")
    opts.dump_mir_flag = cli_has_flag(argc, "--dump-mir")
    opts.dump_async_mir_flag = cli_has_flag(argc, "--dump-async-mir")
    opts.deterministic_mode = cli_has_flag(argc, "--deterministic")
    opts.emit_c_mode = cli_has_flag(argc, "--emit-c")
    opts.prelude_mode = cli_prelude_mode(argc)
    opts

fn tokenize_text(text: str) -> TokenList:
    var lexer = Lexer.init(text, 0)
    return lexer.tokenize()

fn run_cli(argc: i32) -> i32:
    let opt_level = cli_opt_level(argc)
    let no_std = cli_has_flag(argc, "--no-std") or cli_has_flag(argc, "--freestanding")
    let alloc_mode = cli_has_flag(argc, "--alloc")
    let emit_c_mode = cli_has_flag(argc, "--emit-c")
    let emit_obj_mode = cli_has_flag(argc, "--emit-obj")
    let prelude_mode = cli_prelude_mode(argc)
    let deterministic_mode = cli_has_flag(argc, "--deterministic")
    let dump_tokens_flag = cli_has_flag(argc, "--dump-tokens")
    let dump_ast_flag = cli_has_flag(argc, "--dump-ast")
    let dump_resolved_flag = cli_has_flag(argc, "--dump-resolved")
    let dump_typed_flag = cli_has_flag(argc, "--dump-typed")
    let dump_mir_flag = cli_has_flag(argc, "--dump-mir")
    let dump_async_mir_flag = cli_has_flag(argc, "--dump-async-mir")
    let debug_info = not cli_has_flag(argc, "-g0") and not cli_has_flag(argc, "--release")

    // Cache source and output paths — scanned once, used by all subcommands.
    let source = find_source_arg(argc)
    let output = find_output_arg(argc)

    // `with hello.w` is shorthand for `with run hello.w`
    if cli_is_implicit_run(argc):
        return run_run_command(cli_command(argc), opt_level, no_std, alloc_mode, prelude_mode, debug_info)

    if cli_command(argc) == "build":
        return run_build_command(source, opt_level, no_std, alloc_mode, emit_c_mode, emit_obj_mode, output, prelude_mode, debug_info)
    if cli_command(argc) == "run":
        if emit_c_mode:
            with_eprint("error: '--emit-c' is only supported with 'build'")
            return 1
        return run_run_command(source, opt_level, no_std, alloc_mode, prelude_mode, debug_info)
    if cli_command(argc) == "ir":
        if source == "":
            with_eprint("error: 'ir' requires a source file argument")
            return 1
        var comp = Compilation.init()
        comp.configure(opt_level, no_std, alloc_mode)
        comp.set_prelude_mode(prelude_mode)
        let pool = comp.compile_file(source)
        if pool.decl_count() == 0:
            with_eprint("error: IR generation failed during compilation")
            return 1
        let ok = comp.emit_ir(pool)
        if not ok:
            return 1
        return 0
    if cli_command(argc) == "ast":
        if source == "":
            with_eprint("error: 'ast' requires a source file argument")
            return 1
        return dump_ast(source, no_std, alloc_mode, deterministic_mode)
    if cli_command(argc) == "check":
        if source == "":
            with_eprint("error: 'check' requires a source file argument")
            return 1
        if dump_tokens_flag:
            let rc_tokens = dump_tokens(source, true)
            if rc_tokens != 0:
                return rc_tokens
            if not dump_ast_flag:
                return 0
        if dump_ast_flag:
            return dump_ast(source, no_std, alloc_mode, true)
        if dump_resolved_flag:
            return dump_resolved_artifact(source, no_std, alloc_mode, prelude_mode)
        if dump_typed_flag:
            return dump_typed_artifact(source, no_std, alloc_mode, prelude_mode)
        if dump_mir_flag:
            return dump_mir_artifact(source, no_std, alloc_mode, prelude_mode)
        if dump_async_mir_flag:
            return dump_async_mir_artifact(source, no_std, alloc_mode, prelude_mode)
        var comp = Compilation.init()
        comp.configure(0, no_std, alloc_mode)
        comp.set_prelude_mode(prelude_mode)
        let pool = comp.compile_file(source)
        if pool.decl_count() == 0:
            with_eprint("error: check failed during compilation")
            return 1
        with_write("ok\n")
        comp.print_warnings()
        return 0
    if cli_command(argc) == "tokens":
        if source == "":
            with_eprint("error: 'tokens' requires a source file argument")
            return 1
        return dump_tokens(source, deterministic_mode)
    if cli_command(argc) == "test":
        return run_test_command(argc, opt_level, no_std, alloc_mode, prelude_mode, debug_info)
    if cli_command(argc) == "bench":
        return run_bench_command(argc, opt_level, no_std, alloc_mode, prelude_mode, debug_info)
    if cli_command(argc) == "version" or cli_command(argc) == "--version":
        with_write("with WITH_VERSION_PLACEHOLDER\n")
        return 0
    if cli_command(argc) == "help" or cli_command(argc) == "--help" or cli_command(argc) == "-h":
        return run_help_command(argc)
    if cli_command(argc) == "clean":
        return run_clean_command()
    if cli_command(argc) == "init":
        return run_init_command(argc)
    if cli_command(argc) == "get":
        return run_get_command(argc)
    if cli_command(argc) == "remove":
        return run_remove_command(argc)
    if cli_command(argc) == "lsp":
        return run_lsp()
    if cli_command(argc) == "migrate":
        return run_migrate_command(argc)
    if cli_command(argc) == "repl":
        with_eprint("error: REPL not yet available in self-hosted compiler")
        return 1
    if cli_command(argc) == "doc":
        with_eprint("error: doc not yet available in self-hosted compiler")
        return 1
    if cli_command(argc) == "fmt":
        return run_fmt_command(argc)
    let command = cli_command(argc)
    with_eprint("error: unknown command '" ++ command ++ "'")
    print_usage()
    1

fn main -> void:
    with_raise_stack_limit()
    with_install_interrupt_handlers()
    let argc = with_arg_count()
    if argc < 2:
        with_eprint("error: REPL not yet available")
        print_usage()
        return
    exit(run_cli(argc))

// ── Command implementations ──────────────────────────────────────

fn str_eq_text(a: str, b: str) -> bool:
    with_str_eq(a, b) != 0

fn has_output_prefix(arg: str) -> bool:
    if with_str_len(arg) < 9:
        return false
    with_str_starts_with(arg, "--output=") != 0

// Find the first positional (non-flag) argument starting from argv[2].
// Skips `-o <path>` pairs and `--output=...` prefixed options.
// Returns "" if no source file found.
fn find_source_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        var step = 1
        var skip = false
        if str_eq_text(arg, "-o"):
            step = 2
            skip = true
        if not skip and has_output_prefix(arg):
            skip = true
        if not skip:
            if with_str_len(arg) > 0:
                if with_str_byte_at(arg, 0) != 45: // not '-'
                    return arg
        i = i + step
    ""

fn find_output_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if str_eq_text(arg, "-o"):
            if i + 1 < argc:
                return with_arg_at(i + 1)
            return ""
        if has_output_prefix(arg):
            return with_str_slice(arg, 9, with_str_len(arg))
        i = i + 1
    ""

fn cleanup_binary_artifacts(bin_path: str):
    if bin_path.len() == 0:
        return
    let _ = ("rm -f " ++ bin_path) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

fn run_build_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool, emit_c_mode: bool, emit_obj_mode: bool, output_path: str, prelude_mode: i32, debug_info: bool) -> i32:
    if source_file == "":
        with_eprint("error: 'build' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    if emit_c_mode:
        let c_path = comp.emit_c(source_file, output_path)
        if c_path == "":
            with_eprint("error: build failed")
            return 1
        with_eprint("emitted C: " ++ c_path)
        with_eprint("compile with zig cc (example):")
        with_eprint("  zig cc -target <triple> -I runtime " ++ c_path ++ " runtime/with_runtime.c runtime/helpers.c runtime/fiber.c runtime/fiber_asm_<arch>.s -o <output>")
        comp.print_warnings()
        return 0
    if emit_obj_mode:
        var obj_path = output_path
        if obj_path == "":
            obj_path = link_stage_output_path_for_source(source_file) ++ ".o"
        let result = comp.emit_object_to_path(source_file, obj_path)
        if result == "":
            with_eprint("error: build failed")
            return 1
        comp.print_warnings()
        return 0
    let bin_path = comp.build_binary_to_path(source_file, output_path)
    if bin_path == "":
        with_eprint("error: build failed")
        return 1
    comp.print_warnings()
    0

fn run_run_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool) -> i32:
    if source_file == "":
        with_eprint("error: 'run' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    let bin_path = comp.build_binary(source_file)
    if bin_path == "":
        with_eprint("error: run failed")
        return 1
    comp.print_warnings()
    let run_rc = with_system(bin_path)
    cleanup_binary_artifacts(bin_path)
    run_rc

fn dump_ast(source_file: str, no_std: bool, alloc_mode: bool, include_header: bool) -> i32:
    let text = with_fs_read_file(source_file)
    if text.len() == 0:
        with_eprint("error: cannot read '{source_file}'")
        return 1

    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var intern = InternPool.init()
    var diags = DiagnosticList.init()
    var parser = Parser.init(tokens, text, 0, intern, diags)
    let pool = parser.parse_module()
    intern = parser.intern
    diags = parser.diags

    if diags.has_errors():
        let source = Source.from_string(source_file, text, 0)
        diags.render_all(source)
        return 1

    if include_header:
        var module_start = 0
        var module_end = 0
        if pool.decl_count() > 0:
            let first_decl = pool.get_decl(0)
            let last_decl = pool.get_decl(pool.decl_count() - 1)
            module_start = pool.get_start(first_decl)
            module_end = pool.get_end(last_decl)
        with_write(f"module span={module_start}..{module_end} decls={pool.decl_count()}\n")
        for i in 0..pool.decl_count():
            let decl = pool.get_decl(i)
            let kind_name = ast_decl_kind_name(pool.kind(decl))
            with_write(f"decl[{i}] kind={kind_name} span={pool.get_start(decl)}..{pool.get_end(decl)}\n")
        with_write("---\n")

    let rendered = render_module(pool, intern)
    if rendered.len() == 0:
        with_eprint("error: parser produced an empty AST without diagnostics")
        return 1
    with_write(rendered)
    0

fn ast_decl_kind_name(kind: i32) -> str:
    if kind == NodeKind.NK_FN_DECL: return "function"
    if kind == NodeKind.NK_TYPE_DECL: return "type_decl"
    if kind == NodeKind.NK_USE_DECL: return "use_decl"
    if kind == NodeKind.NK_LET_DECL: return "let_decl"
    if kind == NodeKind.NK_EXTERN_FN: return "extern_fn"
    if kind == NodeKind.NK_C_IMPORT: return "c_import"
    if kind == NodeKind.NK_TRAIT_DECL: return "trait_decl"
    if kind == NodeKind.NK_IMPL_DECL: return "impl_decl"
    if kind == NodeKind.NK_POISONED_DECL: return "poisoned"
    "unknown"

fn dump_tokens(source_file: str, deterministic: bool) -> i32:
    let text = with_fs_read_file(source_file)
    if text.len() == 0:
        with_eprint("error: cannot read '{source_file}'")
        return 1
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    if deterministic:
        with_write(f"tokens file={source_file} count={tokens.len()}\n")
        for i in 0..tokens.len():
            let tk = tokens.get_tag(i)
            let start = tokens.get_start(i)
            let end = tokens.get_end(i)
            let text_slice = text.slice(start as i64, end as i64)
            let escaped = text_slice |> escape_dump_lexeme
            let tag_text = dump_tag_name(tk, text_slice)
            with_write(f"tok[{i}] tag={tag_text} span={start}..{end} lex=\"{escaped}\"\n")
        return 0

    // Compatibility debug output, similar to stage0 `tokens` command.
    for i in 0..tokens.len():
        let tk = tokens.get_tag(i)
        let start = tokens.get_start(i)
        let end = tokens.get_end(i)
        let text_slice = text.slice(start as i64, end as i64)
        let tag_text = dump_tag_name(tk, text_slice)
        with_write(tag_text ++ " |" ++ text_slice ++ "|\n")
    0

fn dump_resolved_artifact(source_file: str, no_std: bool, alloc_mode: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    let result = comp.resolve_file(source_file, true)
    let has_errors = comp.has_errors()
    if has_errors:
        with_eprint("error: resolved dump failed")
        return 1
    let resolved_text = dump_resolved(result, comp.get_pool(), source_file)
    with_write(resolved_text)
    0

fn dump_typed_artifact(source_file: str, no_std: bool, alloc_mode: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    let typed_ok = comp.emit_typed_file(source_file)
    if not typed_ok:
        with_eprint("error: typed dump failed during compilation or semantic analysis")
        return 1
    0

fn dump_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    let mir_ok = comp.print_mir_file(source_file)
    if not mir_ok:
        with_eprint("error: mir dump failed during compilation or mir lowering")
        return 1
    0

fn dump_async_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    let async_mir_text = comp.dump_async_mir_file(source_file)
    if async_mir_text.len() == 0:
        with_eprint("error: async-mir dump failed during compilation or lowering")
        return 1
    with_write(async_mir_text)
    0

fn escape_dump_lexeme(text: str) -> str:
    var out = ""
    var run_start = 0
    for i in 0..text.len():
        let ch = text.byte_at(i as i64)
        var esc = ""
        if ch == 92:  // '\'
            esc = "\\\\"
        else if ch == 34:  // '"'
            esc = "\\\""
        else if ch == 10:  // '\n'
            esc = "\\n"
        else if ch == 13:  // '\r'
            esc = "\\r"
        else if ch == 9:  // '\t'
            esc = "\\t"
        else:
            continue
        // Flush the non-special run before this escape.
        if i > run_start:
            out = out ++ text.slice(run_start as i64, i as i64)
        out = out ++ esc
        run_start = i + 1
    // Flush any remaining non-special run.
    if run_start < text.len():
        out = out ++ text.slice(run_start as i64, text.len())
    out

fn dump_tag_name(tag: i32, lexeme: str) -> str:
    // Keep deterministic dump names identical to Stage0 for brace delimiters.
    if tag == TokenKind.TK_L_BRACE:
        return "'" ++ lexeme ++ "'"
    if tag == TokenKind.TK_R_BRACE:
        return "'" ++ lexeme ++ "'"
    return tag_name(tag)

fn discover_test_functions(text: str) -> TestDiscovery:
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var intern = InternPool.init()
    var diags = DiagnosticList.init()
    var parser = Parser.init(tokens, text, 0, intern, diags)
    let pool = parser.parse_module()
    intern = parser.intern
    diags = parser.diags

    let test_names: Vec[str] = Vec.new()
    if diags.has_errors():
        return TestDiscovery { parse_ok: false, has_main: false, test_names }

    var has_main = false
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        let fn_name = intern.resolve(pool.get_data0(decl))
        if fn_name == "main":
            has_main = true
        if with_str_starts_with(fn_name, "test_") != 0:
            test_names.push(fn_name)
        else:
            // Check @[test] attribute via fn metadata flags
            let meta = pool.find_fn_meta(decl)
            if meta >= 0 and (pool.fn_meta_flags(meta) % 8192) / 4096 == 1:
                test_names.push(fn_name)
    TestDiscovery { parse_ok: true, has_main, test_names }

fn discover_bench_functions(text: str) -> BenchDiscovery:
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var intern = InternPool.init()
    var diags = DiagnosticList.init()
    var parser = Parser.init(tokens, text, 0, intern, diags)
    let pool = parser.parse_module()
    intern = parser.intern
    diags = parser.diags

    let bench_names: Vec[str] = Vec.new()
    if diags.has_errors():
        return BenchDiscovery { parse_ok: false, has_main: false, bench_names }

    var has_main = false
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        let fn_name = intern.resolve(pool.get_data0(decl))
        if fn_name == "main":
            has_main = true
        if with_str_starts_with(fn_name, "bench_") != 0:
            bench_names.push(fn_name)
        else:
            let meta = pool.find_fn_meta(decl)
            if meta >= 0 and (pool.fn_meta_flags(meta) % 65536) / 32768 == 1:
                bench_names.push(fn_name)
    BenchDiscovery { parse_ok: true, has_main, bench_names }

fn synthesize_bench_main_source(text: str, bench_names: Vec[str]) -> str:
    var out = text
    if out.len() > 0 and with_str_byte_at(out, with_str_len(out) - 1) != 10:
        out = out ++ "\n"
    out = out ++ "\nuse test.bench\n"
    out = out ++ "extern fn with_getenv_str(name: str) -> str\n"
    out = out ++ "extern fn with_str_contains(s: str, needle: str) -> i32\n"
    out = out ++ "\nfn main:\n"
    out = out ++ "    let __with_bench_filter = with_getenv_str(\"WITH_BENCH_FILTER\")\n"
    for bi in 0..bench_names.len() as i32:
        let bench_name = bench_names.get(bi as i64)
        out = out ++ "    if __with_bench_filter.len() == 0 or with_str_contains(\"" ++ bench_name ++ "\", __with_bench_filter) != 0:\n"
        out = out ++ "        var __b = Bench.new()\n"
        out = out ++ "        __b.run(" ++ bench_name ++ ")\n"
        out = out ++ "        __b.report(\"" ++ bench_name ++ "\")\n"
    out

fn synthesize_test_main_source(text: str, test_names: Vec[str]) -> str:
    var out = text
    if out.len() > 0 and with_str_byte_at(out, with_str_len(out) - 1) != 10:
        out = out ++ "\n"
    out = out ++ "\nextern fn with_getenv_str(name: str) -> str\n"
    out = out ++ "extern fn with_str_eq(a: str, b: str) -> i32\n"
    out = out ++ "extern fn exit(code: i32) -> void\n"
    out = out ++ "\nfn __with_test_eq(a: str, b: str) -> bool:\n"
    out = out ++ "    with_str_eq(a, b) != 0\n"
    out = out ++ "\nfn main:\n"
    out = out ++ "    let __with_test_filter = with_getenv_str(\"WITH_TEST_FILTER\")\n"
    out = out ++ "    if __with_test_filter.len() > 0:\n"
    for ti in 0..test_names.len() as i32:
        let test_name = test_names.get(ti as i64)
        let prefix = if ti == 0: "        if " else: "        else if "
        out = out ++ prefix ++ "__with_test_eq(__with_test_filter, \"" ++ test_name ++ "\"):\n"
        out = out ++ "            " ++ test_name ++ "()\n"
        out = out ++ "            return\n"
    out = out ++ "        else:\n"
    out = out ++ "            exit(1)\n"
    out = out ++ "            return\n"
    for ti in 0..test_names.len() as i32:
        out = out ++ "    " ++ test_names.get(ti as i64) ++ "()\n"
    out

fn discover_tests_for_target(target: str) -> TestDiscovery:
    if not target.ends_with(".w"):
        return empty_test_discovery()
    let text = with_fs_read_file(target)
    if text.len() == 0:
        return empty_test_discovery()
    discover_test_functions(text)

fn maybe_synthesize_test_source(target: str) -> str:
    let discovery = discover_tests_for_target(target)
    if not discovery.parse_ok:
        return ""
    let text = with_fs_read_file(target)
    if text.len() == 0:
        return ""
    if discovery.has_main or discovery.test_names.len() == 0:
        return ""
    synthesize_test_main_source(text, discovery.test_names)

fn test_shell_quote(text: str) -> str:
    var out = "'"
    var run_start = 0
    for i in 0..text.len():
        if text.byte_at(i as i64) != 39:
            continue
        if i > run_start:
            out = out ++ text.slice(run_start as i64, i as i64)
        out = out ++ "'\\''"
        run_start = i + 1
    if run_start < text.len():
        out = out ++ text.slice(run_start as i64, text.len())
    out ++ "'"

fn split_nonempty_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    var i = 0
    while i <= text.len() as i32:
        let at_end = i == text.len() as i32
        let ch = if at_end: 10 else: text.byte_at(i as i64)
        if ch == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line.byte_at(line.len() as i64 - 1) == 13:
                line = line.slice(0, line.len() - 1)
            if line.len() > 0:
                lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn test_target_is_directory(target: str) -> bool:
    with_system("[ -d " ++ test_shell_quote(target) ++ " ]") == 0

fn collect_test_files(target_dir: str) -> Vec[str]:
    let files: Vec[str] = Vec.new()
    let _ = with_system("mkdir -p out/tmp")
    let manifest_path = "out/tmp/test-files.txt"
    let cmd = "find " ++ test_shell_quote(target_dir) ++ " -type f -name '*.w' | sort > " ++ test_shell_quote(manifest_path)
    if with_system(cmd) != 0:
        return files
    let listing = with_fs_read_file(manifest_path)
    if listing.len() == 0:
        return files
    split_nonempty_lines(listing)

fn test_count_label(count: i32) -> str:
    if count == 1:
        return "test"
    "tests"

fn emit_test_stage_error(message: str, target: str, stage: str, test_name: str):
    with_eprint("error: " ++ message)
    with_eprint(" = file: " ++ target)
    with_eprint(" = stage: " ++ stage)
    if test_name.len() > 0:
        with_eprint(" = test: " ++ test_name)

fn print_test_summary(target: str, passed: i32, failed: i32, quiet: bool):
    if quiet:
        return
    if failed == 0:
        with_write(f"ok: {passed} {test_count_label(passed)} passed in {target}\n")
        return
    with_eprint(f"error: {failed} of {passed + failed} tests failed in {target}")

fn run_test_binary(bin_path: str, quiet: bool) -> i32:
    var cmd = test_shell_quote(bin_path)
    if quiet:
        cmd = "WITH_TEST_SHORT=1 " ++ cmd
    with_system(cmd)

fn run_named_test_binary(bin_path: str, test_name: str, quiet: bool) -> i32:
    var cmd = "WITH_TEST_FILTER=" ++ test_shell_quote(test_name) ++ " " ++ test_shell_quote(bin_path)
    if quiet:
        cmd = "WITH_TEST_SHORT=1 " ++ cmd
    with_system(cmd)

fn run_test_file(target: str, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool, verbose: bool, quiet: bool, filter: str) -> i32:
    let discovery = discover_tests_for_target(target)
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    let synthetic_source = maybe_synthesize_test_source(target)
    let bin_path = if synthetic_source.len() > 0: comp.build_binary_from_source(target, synthetic_source) else: comp.build_binary(target)
    if bin_path == "":
        emit_test_stage_error("test build failed", target, "build", "")
        return 1
    if discovery.parse_ok and not discovery.has_main and discovery.test_names.len() > 0:
        var passed = 0
        var failed = 0
        for ti in 0..discovery.test_names.len() as i32:
            let test_name = discovery.test_names.get(ti as i64)
            if filter.len() > 0 and with_str_contains(test_name, filter) == 0:
                continue
            let rc = run_named_test_binary(bin_path, test_name, quiet and not verbose)
            if rc == 0:
                passed = passed + 1
                if verbose:
                    with_write("PASS " ++ test_name ++ "\n")
            else:
                failed = failed + 1
                if verbose:
                    with_eprint("FAIL " ++ test_name)
                emit_test_stage_error("test failed", target, "run", test_name)
        cleanup_binary_artifacts(bin_path)
        print_test_summary(target, passed, failed, quiet and not verbose)
        if failed == 0:
            return 0
        return 1
    let run_rc = run_test_binary(bin_path, quiet and not verbose)
    cleanup_binary_artifacts(bin_path)
    if run_rc == 0:
        print_test_summary(target, 1, 0, quiet and not verbose)
        return 0
    emit_test_stage_error("test failed", target, "run", "")
    print_test_summary(target, 0, 1, quiet and not verbose)
    run_rc

fn run_test_command(argc: i32, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool) -> i32:
    let verbose = cli_test_verbose(argc)
    let quiet = if verbose: false else: cli_test_quiet(argc)
    let filter = cli_test_filter(argc)
    // Find test file/dir argument
    let target = find_source_arg(argc)
    if target == "":
        with_eprint("error: 'test' requires a source file or directory argument")
        return 1
    if test_target_is_directory(target):
        let test_files = collect_test_files(target)
        if test_files.len() == 0:
            with_eprint("error: no test sources found in '" ++ target ++ "'")
            return 1
        for ti in 0..test_files.len() as i32:
            let test_file = test_files.get(ti as i64)
            let run_rc = run_test_file(test_file, opt_level, no_std, alloc_mode, prelude_mode, debug_info, verbose, quiet, filter)
            if run_rc != 0:
                with_eprint("error: test failed in '" ++ test_file ++ "'")
                return run_rc
        return 0
    run_test_file(target, opt_level, no_std, alloc_mode, prelude_mode, debug_info, verbose, quiet, filter)

fn run_bench_file(target: str, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool, filter: str) -> i32:
    let text = with_fs_read_file(target)
    if text.len() == 0:
        with_eprint("error: could not read '" ++ target ++ "'")
        return 1
    let discovery = discover_bench_functions(text)
    if not discovery.parse_ok:
        with_eprint("error: parse failed for '" ++ target ++ "'")
        return 1
    if discovery.bench_names.len() == 0:
        with_eprint("error: no benchmarks found in '" ++ target ++ "'")
        return 1
    let synthetic_source = synthesize_bench_main_source(text, discovery.bench_names)
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    let bin_path = comp.build_binary_from_source(target, synthetic_source)
    if bin_path == "":
        with_eprint("error: bench build failed for '" ++ target ++ "'")
        return 1
    var cmd = test_shell_quote(bin_path)
    if filter.len() > 0:
        cmd = "WITH_BENCH_FILTER=" ++ test_shell_quote(filter) ++ " " ++ cmd
    let rc = with_system(cmd)
    cleanup_binary_artifacts(bin_path)
    rc

fn run_bench_command(argc: i32, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool) -> i32:
    let filter = cli_test_filter(argc)
    let target = find_source_arg(argc)
    if target == "":
        with_eprint("error: 'bench' requires a source file or directory argument")
        return 1
    if test_target_is_directory(target):
        let files = collect_test_files(target)
        if files.len() == 0:
            with_eprint("error: no sources found in '" ++ target ++ "'")
            return 1
        var any_failed = false
        for fi in 0..files.len() as i32:
            let file = files.get(fi as i64)
            let text = with_fs_read_file(file)
            if text.len() == 0:
                continue
            let disc = discover_bench_functions(text)
            if not disc.parse_ok or disc.bench_names.len() == 0:
                continue
            let rc = run_bench_file(file, opt_level, no_std, alloc_mode, prelude_mode, debug_info, filter)
            if rc != 0:
                any_failed = true
        if any_failed:
            return 1
        return 0
    run_bench_file(target, opt_level, no_std, alloc_mode, prelude_mode, debug_info, filter)

fn run_migrate_command(argc: i32) -> i32:
    if argc < 3:
        eprint("usage: with migrate <file.c|dir/> [-o output] [-I include_dir]")
        return 1

    // Parse arguments
    var source_path = ""
    var output_path = ""
    var ai = 2
    while ai < argc:
        let arg = with_arg_at(ai)
        if arg == "-o" and ai + 1 < argc:
            output_path = with_arg_at(ai + 1)
            ai = ai + 2
            continue
        if arg == "-I" and ai + 1 < argc:
            with_cimport_add_include_path(with_arg_at(ai + 1))
            ai = ai + 2
            continue
        if arg == "-D" and ai + 1 < argc:
            migrate_add_define(with_arg_at(ai + 1))
            ai = ai + 2
            continue
        if arg == "--check" or arg == "--diff" or arg == "--stats":
            ai = ai + 1
            continue  // TODO: implement modes
        if arg == "--no-c-export":
            migrate_set_no_c_export(1)
            ai = ai + 1
            continue
        if arg.len() > 0 and arg.byte_at(0) != 45:  // not a flag
            source_path = arg
        ai = ai + 1

    if source_path.len() == 0:
        eprint("error: no source file specified")
        return 1

    // Detect if source is a directory (ends with / or doesn't end with .c/.h)
    let is_dir = (source_path.len() > 0 and source_path.byte_at(source_path.len() - 1) == 47) or (source_path.len() > 2 and source_path.slice(source_path.len() - 2, source_path.len()) != ".c" and source_path.slice(source_path.len() - 2, source_path.len()) != ".h")

    if is_dir:
        // Directory mode
        if output_path.len() == 0:
            output_path = source_path ++ "_migrated"
        return migrate_c_directory(source_path, output_path)

    // Single file mode — default output: replace .c with .w
    if output_path.len() == 0:
        if source_path.len() > 2 and source_path.slice(source_path.len() - 2, source_path.len()) == ".c":
            output_path = source_path.slice(0, source_path.len() - 2) ++ ".w"
        else:
            output_path = source_path ++ ".w"

    migrate_c_file(source_path, output_path)

fn run_fmt_command(argc: i32) -> i32:
    let write_mode = cli_has_flag(argc, "-w")
    let list_mode = cli_has_flag(argc, "-l")
    let check_mode = cli_has_flag(argc, "--check")
    // Collect file arguments
    var files: Vec[str] = Vec.new()
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "-w" or arg == "-l" or arg == "--check":
            i = i + 1
            continue
        if with_str_starts_with(arg, "-") != 0:
            i = i + 1
            continue
        files.push(arg)
        i = i + 1
    if files.len() == 0:
        // Read from stdin
        let source = with_fs_read_file("/dev/stdin")
        let formatted = format_source(source)
        with_write(formatted)
        return 0
    var any_changed = false
    var fi = 0
    while fi < files.len() as i32:
        let path = files.get(fi as i64)
        let source = with_fs_read_file(path)
        let formatted = format_source(source)
        if formatted != source:
            any_changed = true
            if list_mode:
                with_write(path ++ "\n")
            if write_mode:
                with_fs_write_file(path, formatted)
        if not write_mode and not list_mode and not check_mode:
            with_write(formatted)
        fi = fi + 1
    if check_mode and any_changed:
        return 1
    0

fn run_clean_command -> i32:
    let result = with_system("rm -rf out .with")
    if result != 0:
        with_eprint("error: clean failed")
        return 1
    with_write("cleaned out/ and legacy .with/\n")
    0

fn print_usage:
    with_write("Usage: with <command> [options]\n")
    with_write("\n")
    with_write("Commands:\n")
    with_write("  build [file.w]    Build a source file (use --emit-c to emit C)\n")
    with_write("  run [file.w]      Build + run a source file\n")
    with_write("  check <file.w>    Parse and type-check a source file (supports --dump-tokens/--dump-ast/--dump-resolved/--dump-typed/--dump-mir/--dump-async-mir)\n")
    with_write("  test <file.w|dir> Run tests from a source file or directory\n")
    with_write("  clean             Delete out/ and legacy .with/ artifacts\n")
    with_write("  ir <file.w>       Dump LLVM IR (debug)\n")
    with_write("  ast <file.w>      Parse and dump the AST (debug)\n")
    with_write("  tokens <file.w>   Lex and dump tokens (debug)\n")
    with_write("  version           Print compiler version\n")
    with_write("  help [topic]      Show CLI help or language quick reference\n")
    with_write("\n")
    with_write("Common options:\n")
    with_write("  -O0|-O1|-O2|-O3      Override optimization level (build/run/test default to -O2)\n")
    with_write("  --release            Alias for -O2 and disable debug info\n")
    with_write("  --no-prelude          Disable implicit std prelude import\n")
    with_write("  --prelude=full|core|none  Select implicit prelude mode\n")
    with_write("  --freestanding        Alias for --no-std --no-prelude\n")
    with_write("  -v, --verbose         Verbose per-test output for 'with test'\n")
    with_write("  -q, --quiet           Suppress success summaries for 'with test'\n")
    with_write("\n")
    with_write("Language quick reference:\n")
    with_write("  with help use         Import syntax and module resolution\n")
    with_write("  with help fn          Function declarations and signatures\n")
    with_write("  with help type        Type declarations and aliases\n")
    with_write("  with help let         Local bindings, mutability, and const\n")
    with_write("  with help extern      FFI declarations and c_import\n")
    with_write("  with help keywords    Reserved words\n")
    with_write("  with help operators   Operator precedence\n")
    with_write("  with help attributes  Common attributes and parser support\n")

fn run_help_command(argc: i32) -> i32:
    let topic = cli_help_topic(argc)
    if topic == "":
        print_usage()
        return 0
    if topic == "use":
        print_help_use()
        return 0
    if topic == "keywords":
        print_help_keywords()
        return 0
    if topic == "fn":
        print_help_fn()
        return 0
    if topic == "type":
        print_help_type()
        return 0
    if topic == "let":
        print_help_let()
        return 0
    if topic == "extern":
        print_help_extern()
        return 0
    if topic == "operators":
        print_help_operators()
        return 0
    if topic == "attributes":
        print_help_attributes()
        return 0
    with_eprint("error: unknown help topic '" ++ topic ++ "'")
    with_eprint("available help topics: use, fn, type, let, extern, keywords, operators, attributes")
    1

fn print_help_use:
    with_write(
        "Import syntax:\n\n" ++
        "  use foo.bar\n" ++
        "  use foo.bar.*\n" ++
        "  use c_import(\"sqlite3.h\", link: \"sqlite3\")\n\n" ++
        "Module resolution:\n\n" ++
        "  use demo.core      -> lib/demo/core.w relative to the project root\n" ++
        "  use foo.bar.*      -> import all public symbols from the module\n\n" ++
        "Not supported:\n\n" ++
        "  use foo.{a, b}     Grouped imports are not implemented\n" ++
        "  use foo as bar     Aliased imports are not implemented\n"
    )

fn print_help_fn:
    with_write(
        "Function declarations:\n\n" ++
        "  fn greet(name: str) -> str:\n" ++
        "      \"hello {name}\"\n\n" ++
        "  pub fn add(x: i32, y: i32) -> i32:\n" ++
        "      x + y\n\n" ++
        "Notes:\n\n" ++
        "  - Indentation starts the function body.\n" ++
        "  - Omit '-> T' for unit-returning functions.\n" ++
        "  - Methods are declared inside 'extend Type:' blocks.\n"
    )

fn print_help_type:
    with_write(
        "Type and enum declarations:\n\n" ++
        "  type Point { x: i32, y: i32 }\n" ++
        "  enum Color { Red | Green | Blue }\n" ++
        "  enum Value { Int(i32) | Float(f64) }\n" ++
        "  type Handle = opaque\n" ++
        "  type Meters = i32\n" ++
        "  type Scalar = union { i: i32, f: f32 }\n\n" ++
        "Related syntax:\n\n" ++
        "  extend Point:\n" ++
        "      fn norm(self: Point) -> i32:\n" ++
        "          self.x + self.y\n"
    )

fn print_help_let:
    with_write(
        "Bindings and constants:\n\n" ++
        "  let answer = 42\n" ++
        "  var total = 0\n" ++
        "  const VERSION: str = \"1.0.0\"\n\n" ++
        "Notes:\n\n" ++
        "  - 'let' introduces immutable locals.\n" ++
        "  - 'var' introduces mutable locals.\n" ++
        "  - 'const' values are compile-time constants and inline at use sites.\n"
    )

fn print_help_extern:
    with_write(
        "FFI declarations:\n\n" ++
        "  extern fn puts(text: *const i8) -> i32\n" ++
        "  use c_import(\"sqlite3.h\", link: \"sqlite3\")\n\n" ++
        "Notes:\n\n" ++
        "  - 'extern fn' declares a foreign symbol directly.\n" ++
        "  - 'c_import' parses C headers and can attach link libraries.\n" ++
        "  - Imported C types use C-compatible layout.\n"
    )

fn print_help_keywords:
    with_write(
        "Reserved words that cannot be used as identifiers:\n\n" ++
        "  fn let var if else then match for in while loop return break continue\n" ++
        "  with as mut type trait impl extend dyn use module pub async await spawn\n" ++
        "  unsafe comptime gen yield defer error extern c_import ephemeral select enum\n" ++
        "  true false not and or const it errdefer move where opaque null union\n"
    )

fn print_help_operators:
    with_write(
        "Operator precedence (low to high):\n\n" ++
        "  1. or\n" ++
        "  2. and\n" ++
        "  3. == != in not in\n" ++
        "  4. < > <= >=\n" ++
        "  5. |>\n" ++
        "  6. |\n" ++
        "  7. ^\n" ++
        "  8. &\n" ++
        "  9. << >>\n" ++
        " 10. + - ++ ??\n" ++
        " 11. * / %\n" ++
        " 12. unary: not - & &mut\n" ++
        " 13. postfix: .await ? .field [i] ()\n"
    )

fn print_help_attributes:
    with_write(
        "Common attributes:\n\n" ++
        "  @[packed]          Packed struct layout\n" ++
        "  @[inline]          Inline hint for functions\n" ++
        "  @[noinline]        Disable inlining for a function\n" ++
        "  @[align(N)]        Per-field alignment inside struct declarations\n\n" ++
        "Notes:\n\n" ++
        "  - Attributes use the syntax '@[name]' or '@[name(args)]'.\n" ++
        "  - The parser currently recognizes packed, inline, noinline, and align.\n" ++
        "  - Other attributes may be documented in the spec but are not all implemented yet.\n"
    )

// ── Package management commands ─────────────────────────────────

fn cli_flag_value(argc: i32, flag: str) -> str:
    var i = 2
    while i < argc - 1:
        if with_arg_at(i) == flag:
            return with_arg_at(i + 1)
        i = i + 1
    ""

fn cli_init_target_dir(argc: i32) -> str:
    let target = find_source_arg(argc)
    if target.len() > 0:
        return target
    "."

fn cli_path_basename(path_raw: str) -> str:
    if path_raw.len() == 0:
        return ""
    let path = resolve_normalize_path(path_raw)
    if path == "/":
        return path

    var end = path.len() as i32
    while end > 1 and path.byte_at((end - 1) as i64) == 47:
        end = end - 1

    var start = 0
    var i = 0
    while i < end:
        if path.byte_at(i as i64) == 47:
            start = i + 1
        i = i + 1

    if start >= end:
        return path.slice(0, end as i64)
    path.slice(start as i64, end as i64)

fn cli_init_default_name(target_dir: str) -> str:
    if target_dir != ".":
        let target_name = cli_path_basename(target_dir)
        if target_name.len() > 0 and target_name != ".":
            return target_name

    let cwd = with_getenv_str("PWD")
    if cwd.len() > 0:
        let cwd_name = cli_path_basename(cwd)
        if cwd_name.len() > 0 and cwd_name != ".":
            return cwd_name

    let fallback = cli_path_basename(target_dir)
    if fallback.len() > 0 and fallback != ".":
        return fallback
    "project"

fn run_init_command(argc: i32) -> i32:
    let target_dir = cli_init_target_dir(argc)
    var name = cli_flag_value(argc, "--name")
    if name.len() == 0:
        name = cli_init_default_name(target_dir)
    let is_lib = cli_has_flag(argc, "--lib")
    let manifest_path = resolve_join(target_dir, "with.toml")
    let src_dir = resolve_join(target_dir, "src")
    let lib_path = resolve_join(src_dir, "lib.w")
    let main_path = resolve_join(src_dir, "main.w")
    let created_path = if target_dir == ".": name else: target_dir

    // Check if with.toml already exists
    let existing = with_fs_read_file(manifest_path)
    if existing.len() > 0:
        with_eprint("error: with.toml already exists in " ++ target_dir)
        return 1

    // Create target directory tree first so named projects can be scaffolded.
    if with_fs_mkdir_p(src_dir) != 0:
        with_eprint("error: failed to create " ++ src_dir ++ " directory")
        return 1

    let toml = "[project]\nname = \"" ++ name ++ "\"\nversion = \"0.1.0\"\n"
    if with_fs_write_file(manifest_path, toml) != 0:
        with_eprint("error: failed to write " ++ manifest_path)
        return 1

    // Create source file
    if is_lib:
        let lib_src = "// " ++ name ++ " library\n\npub fn hello -> str:\n    \"Hello from " ++ name ++ "!\"\n"
        if with_fs_write_file(lib_path, lib_src) != 0:
            with_eprint("error: failed to write " ++ lib_path)
            return 1
        with_eprint("created " ++ created_path ++ " (library)")
    else:
        let main_src = "fn main:\n    print(\"Hello, World!\")\n"
        if with_fs_write_file(main_path, main_src) != 0:
            with_eprint("error: failed to write " ++ main_path)
            return 1
        with_eprint("created " ++ created_path)

    with_eprint("  " ++ manifest_path)
    if is_lib:
        with_eprint("  " ++ lib_path)
    else:
        with_eprint("  " ++ main_path)
    0

fn run_get_command(argc: i32) -> i32:
    if argc < 3:
        with_eprint("usage: with get c.<package>[@version]")
        return 1
    let spec = with_arg_at(2)
    if not spec.starts_with("c."):
        with_eprint("error: only C packages supported. Use c.<name> (e.g. c.sqlite3)")
        return 1
    // Parse name and version from spec
    let pkg_part = spec.slice(2, spec.len())
    var pkg_name = pkg_part
    var pkg_version = ""
    for i in 0..pkg_part.len() as i32:
        if pkg_part.byte_at(i as i64) == 64:
            pkg_name = pkg_part.slice(0, i as i64)
            pkg_version = pkg_part.slice((i + 1) as i64, pkg_part.len())
            break
    if pkg_name.len() == 0:
        with_eprint("error: empty package name")
        return 1

    let root = project_config_find_root(".")
    if root.len() == 0:
        with_eprint("error: no with.toml found. Run 'with init' first.")
        return 1
    let rc = conan_install(pkg_name, pkg_version, root)
    if rc != 0:
        return 1
    let version_for_toml = if pkg_version.len() > 0: pkg_version else: "latest"
    let manifest_path = root ++ "/with.toml"
    let toml = with_fs_read_file(manifest_path)
    if toml.len() > 0:
        var updated = toml
        if not updated.contains("[deps]"):
            updated = updated ++ "\n[deps]\n"
        let dep_line = "c." ++ pkg_name ++ " = \"" ++ version_for_toml ++ "\"\n"
        if not updated.contains("c." ++ pkg_name):
            updated = updated ++ dep_line
        with_fs_write_file(manifest_path, updated)
    with_eprint("added c." ++ pkg_name)
    0

fn run_remove_command(argc: i32) -> i32:
    if argc < 3:
        with_eprint("usage: with remove c.<package>")
        return 1
    let spec = with_arg_at(2)
    if not spec.starts_with("c."):
        with_eprint("error: only C packages supported. Use c.<name>")
        return 1
    // TODO: remove dep from with.toml and clean .with/deps/c/<name>/
    with_eprint("error: remove not yet implemented")
    1
