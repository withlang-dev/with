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

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_str_eq(a: str, b: str) -> i32
extern fn with_str_len(s: str) -> i64
extern fn with_str_byte_at(s: str, index: i64) -> i32
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_str_slice(s: str, start: i64, end: i64) -> str
extern fn with_eprintln(s: str) -> void
extern fn with_system(cmd: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn int_to_string(n: i32) -> str
extern fn print(s: str) -> void
extern fn exit(code: i32) -> void
extern fn with_install_interrupt_handlers() -> void
extern fn with_raise_stack_limit() -> void

const CLI_PRELUDE_FULL_MODE: i32 = 0
const CLI_PRELUDE_CORE_MODE: i32 = 1
const CLI_PRELUDE_NONE_MODE: i32 = 2

type CliOptions = {
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

type TestDiscovery = {
    parse_ok: bool,
    has_main: bool,
    test_names: Vec[str],
}

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
        prelude_mode: CLI_PRELUDE_FULL_MODE,
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

fn cli_opt_level(argc: i32) -> i32:
    var level = 0
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

fn cli_prelude_mode(argc: i32) -> i32:
    var mode = CLI_PRELUDE_FULL_MODE
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "--no-prelude":
            mode = CLI_PRELUDE_NONE_MODE
        else if arg == "--freestanding":
            mode = CLI_PRELUDE_NONE_MODE
        else if with_str_starts_with(arg, "--prelude=") != 0:
            let value = with_str_slice(arg, 10, with_str_len(arg))
            if value == "core":
                mode = CLI_PRELUDE_CORE_MODE
            else if value == "full":
                mode = CLI_PRELUDE_FULL_MODE
            else if value == "none":
                mode = CLI_PRELUDE_NONE_MODE
            else:
                with_eprintln("error: invalid --prelude value '" ++ value ++ "' (expected full|core|none)")
                exit(1)
                return CLI_PRELUDE_FULL_MODE
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
    let prelude_mode = cli_prelude_mode(argc)
    let deterministic_mode = cli_has_flag(argc, "--deterministic")
    let dump_tokens_flag = cli_has_flag(argc, "--dump-tokens")
    let dump_ast_flag = cli_has_flag(argc, "--dump-ast")
    let dump_resolved_flag = cli_has_flag(argc, "--dump-resolved")
    let dump_typed_flag = cli_has_flag(argc, "--dump-typed")
    let dump_mir_flag = cli_has_flag(argc, "--dump-mir")
    let dump_async_mir_flag = cli_has_flag(argc, "--dump-async-mir")
    let debug_info = not cli_has_flag(argc, "-g0") and not cli_has_flag(argc, "--release")

    // `with hello.w` is shorthand for `with run hello.w`
    if cli_is_implicit_run(argc):
        return run_run_command(cli_command(argc), opt_level, no_std, alloc_mode, prelude_mode, debug_info)

    if cli_command(argc) == "build":
        return run_build_command(find_source_arg(argc), opt_level, no_std, alloc_mode, emit_c_mode, find_output_arg(argc), prelude_mode, debug_info)
    if cli_command(argc) == "run":
        if emit_c_mode:
            with_eprintln("error: '--emit-c' is only supported with 'build'")
            return 1
        return run_run_command(find_source_arg(argc), opt_level, no_std, alloc_mode, prelude_mode, debug_info)
    if cli_command(argc) == "ir":
        if find_source_arg(argc) == "":
            with_eprintln("error: 'ir' requires a source file argument")
            return 1
        var comp = Compilation.init()
        comp.configure(opt_level, no_std, alloc_mode)
        comp.set_prelude_mode(prelude_mode)
        let pool = comp.compile_file(find_source_arg(argc))
        if pool.decl_count() == 0:
            with_eprintln("error: IR generation failed during compilation")
            return 1
        let ok = comp.emit_ir(pool)
        if not ok:
            return 1
        return 0
    if cli_command(argc) == "ast":
        if find_source_arg(argc) == "":
            with_eprintln("error: 'ast' requires a source file argument")
            return 1
        return dump_ast(find_source_arg(argc), no_std, alloc_mode, deterministic_mode)
    if cli_command(argc) == "check":
        if find_source_arg(argc) == "":
            with_eprintln("error: 'check' requires a source file argument")
            return 1
        if dump_tokens_flag:
            let rc_tokens = dump_tokens(find_source_arg(argc), true)
            if rc_tokens != 0:
                return rc_tokens
            if not dump_ast_flag:
                return 0
        if dump_ast_flag:
            return dump_ast(find_source_arg(argc), no_std, alloc_mode, true)
        if dump_resolved_flag:
            return dump_resolved_artifact(find_source_arg(argc), no_std, alloc_mode, prelude_mode)
        if dump_typed_flag:
            return dump_typed_artifact(find_source_arg(argc), no_std, alloc_mode, prelude_mode)
        if dump_mir_flag:
            return dump_mir_artifact(find_source_arg(argc), no_std, alloc_mode, prelude_mode)
        if dump_async_mir_flag:
            return dump_async_mir_artifact(find_source_arg(argc), no_std, alloc_mode, prelude_mode)
        var comp = Compilation.init()
        comp.configure(0, no_std, alloc_mode)
        comp.set_prelude_mode(prelude_mode)
        let pool = comp.compile_file(find_source_arg(argc))
        if pool.decl_count() == 0:
            with_eprintln("error: check failed during compilation")
            return 1
        print("ok\n")
        comp.print_warnings()
        return 0
    if cli_command(argc) == "tokens":
        if find_source_arg(argc) == "":
            with_eprintln("error: 'tokens' requires a source file argument")
            return 1
        return dump_tokens(find_source_arg(argc), deterministic_mode)
    if cli_command(argc) == "test":
        return run_test_command(argc, opt_level, no_std, alloc_mode, prelude_mode, debug_info)
    if cli_command(argc) == "version" or cli_command(argc) == "--version":
        print("with WITH_VERSION_PLACEHOLDER\n")
        return 0
    if cli_command(argc) == "help" or cli_command(argc) == "--help" or cli_command(argc) == "-h":
        return run_help_command(argc)
    if cli_command(argc) == "clean":
        return run_clean_command()
    if cli_command(argc) == "lsp":
        with_eprintln("error: LSP not yet available in self-hosted compiler")
        return 1
    if cli_command(argc) == "migrate":
        with_eprintln("error: migrate not yet available in self-hosted compiler")
        return 1
    if cli_command(argc) == "repl":
        with_eprintln("error: REPL not yet available in self-hosted compiler")
        return 1
    if cli_command(argc) == "doc":
        with_eprintln("error: doc not yet available in self-hosted compiler")
        return 1
    if cli_command(argc) == "fmt":
        with_eprintln("error: fmt not yet available in self-hosted compiler")
        return 1
    let command = cli_command(argc)
    with_eprintln("error: unknown command '" ++ command ++ "'")
    print_usage()
    1

fn main -> void:
    with_raise_stack_limit()
    with_install_interrupt_handlers()
    let argc = with_arg_count()
    if argc < 2:
        with_eprintln("error: REPL not yet available")
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

fn run_build_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool, emit_c_mode: bool, output_path: str, prelude_mode: i32, debug_info: bool) -> i32:
    if source_file == "":
        with_eprintln("error: 'build' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    if emit_c_mode:
        let c_path = comp.emit_c(source_file, output_path)
        if c_path == "":
            with_eprintln("error: build failed")
            return 1
        with_eprintln("emitted C: " ++ c_path)
        with_eprintln("compile with zig cc (example):")
        with_eprintln("  zig cc -target <triple> -I runtime " ++ c_path ++ " runtime/with_runtime.c runtime/helpers.c runtime/fiber.c runtime/fiber_asm_<arch>.s -o <output>")
        comp.print_warnings()
        return 0
    let bin_path = comp.build_binary_to_path(source_file, output_path)
    if bin_path == "":
        with_eprintln("error: build failed")
        return 1
    comp.print_warnings()
    0

fn run_run_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool) -> i32:
    if source_file == "":
        with_eprintln("error: 'run' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    let bin_path = comp.build_binary(source_file)
    if bin_path == "":
        with_eprintln("error: run failed")
        return 1
    comp.print_warnings()
    let run_rc = with_system(bin_path)
    cleanup_binary_artifacts(bin_path)
    run_rc

fn dump_ast(source_file: str, no_std: bool, alloc_mode: bool, include_header: bool) -> i32:
    let text = with_fs_read_file(source_file)
    if text.len() == 0:
        with_eprintln("error: cannot read '{source_file}'")
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
        print("module span=" ++ int_to_string(module_start) ++ ".." ++ int_to_string(module_end) ++ " decls=" ++ int_to_string(pool.decl_count()) ++ "\n")
        for i in 0..pool.decl_count():
            let decl = pool.get_decl(i)
            let kind_name = ast_decl_kind_name(pool.kind(decl))
            print("decl[" ++ int_to_string(i) ++ "] kind=" ++ kind_name ++ " span=" ++ int_to_string(pool.get_start(decl)) ++ ".." ++ int_to_string(pool.get_end(decl)) ++ "\n")
        print("---\n")

    let rendered = render_module(pool, intern)
    if rendered.len() == 0:
        with_eprintln("error: parser produced an empty AST without diagnostics")
        return 1
    print(rendered)
    0

fn ast_decl_kind_name(kind: i32) -> str:
    if kind == NK_FN_DECL: return "function"
    if kind == NK_TYPE_DECL: return "type_decl"
    if kind == NK_USE_DECL: return "use_decl"
    if kind == NK_LET_DECL: return "let_decl"
    if kind == NK_EXTERN_FN: return "extern_fn"
    if kind == NK_C_IMPORT: return "c_import"
    if kind == NK_TRAIT_DECL: return "trait_decl"
    if kind == NK_IMPL_DECL: return "impl_decl"
    if kind == NK_POISONED_DECL: return "poisoned"
    "unknown"

fn dump_tokens(source_file: str, deterministic: bool) -> i32:
    let text = with_fs_read_file(source_file)
    if text.len() == 0:
        with_eprintln("error: cannot read '{source_file}'")
        return 1
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    if deterministic:
        print("tokens file=" ++ source_file ++ " count=" ++ int_to_string(tokens.len()) ++ "\n")
        for i in 0..tokens.len():
            let tk = tokens.get_tag(i)
            let start = tokens.get_start(i)
            let end = tokens.get_end(i)
            let text_slice = text.slice(start as i64, end as i64)
            let escaped = text_slice |> escape_dump_lexeme
            let tag_text = dump_tag_name(tk, text_slice)
            print("tok[" ++ int_to_string(i) ++ "] tag=" ++ tag_text ++ " span=" ++ int_to_string(start) ++ ".." ++ int_to_string(end) ++ " lex=\"" ++ escaped ++ "\"\n")
        return 0

    // Compatibility debug output, similar to stage0 `tokens` command.
    for i in 0..tokens.len():
        let tk = tokens.get_tag(i)
        let start = tokens.get_start(i)
        let end = tokens.get_end(i)
        let text_slice = text.slice(start as i64, end as i64)
        let tag_text = dump_tag_name(tk, text_slice)
        print(tag_text ++ " |" ++ text_slice ++ "|\n")
    0

fn dump_resolved_artifact(source_file: str, no_std: bool, alloc_mode: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    let result = comp.resolve_file(source_file, true)
    let has_errors = comp.has_errors()
    if has_errors:
        with_eprintln("error: resolved dump failed")
        return 1
    let resolved_text = dump_resolved(result, comp.get_pool(), source_file)
    print(resolved_text)
    0

fn dump_typed_artifact(source_file: str, no_std: bool, alloc_mode: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    let typed_ok = comp.emit_typed_file(source_file)
    if not typed_ok:
        with_eprintln("error: typed dump failed during compilation or semantic analysis")
        return 1
    0

fn dump_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    let mir_ok = comp.print_mir_file(source_file)
    if not mir_ok:
        with_eprintln("error: mir dump failed during compilation or mir lowering")
        return 1
    0

fn dump_async_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    let async_mir_text = comp.dump_async_mir_file(source_file)
    if async_mir_text.len() == 0:
        with_eprintln("error: async-mir dump failed during compilation or lowering")
        return 1
    print(async_mir_text)
    0

fn escape_dump_lexeme(text: str) -> str:
    var out = ""
    var run_start = 0
    for i in 0..text.len():
        let ch = text.byte_at((i) as i64)
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
    if tag == TK_L_BRACE:
        return "'" ++ lexeme ++ "'"
    if tag == TK_R_BRACE:
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
        if pool.kind(decl) != NK_FN_DECL:
            continue
        let fn_name = intern.resolve(pool.get_data0(decl))
        if fn_name == "main":
            has_main = true
        if with_str_starts_with(fn_name, "test_") != 0:
            test_names.push(fn_name)
    TestDiscovery { parse_ok: true, has_main, test_names }

fn synthesize_test_main_source(text: str, test_names: Vec[str]) -> str:
    var out = text
    if out.len() > 0 and with_str_byte_at(out, with_str_len(out) - 1) != 10:
        out = out ++ "\n"
    out = out ++ "\nfn main:\n"
    for ti in 0..test_names.len() as i32:
        out = out ++ "    " ++ test_names.get(ti as i64) ++ "()\n"
    out

fn maybe_synthesize_test_source(target: str) -> str:
    if not target.ends_with(".w"):
        return ""
    let text = with_fs_read_file(target)
    if text.len() == 0:
        return ""
    let discovery = discover_test_functions(text)
    if not discovery.parse_ok:
        return ""
    if discovery.has_main or discovery.test_names.len() == 0:
        return ""
    synthesize_test_main_source(text, discovery.test_names)

fn run_test_command(argc: i32, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool) -> i32:
    // Find test file/dir argument
    let target = find_source_arg(argc)
    if target == "":
        with_eprintln("error: 'test' requires a source file or directory argument")
        return 1
    // Compile and run as test
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    let synthetic_source = maybe_synthesize_test_source(target)
    let bin_path = if synthetic_source.len() > 0: comp.build_binary_from_source(target, synthetic_source) else: comp.build_binary(target)
    if bin_path == "":
        with_eprintln("error: test build failed")
        return 1
    let run_rc = with_system(bin_path)
    cleanup_binary_artifacts(bin_path)
    run_rc

fn run_clean_command -> i32:
    let result = with_system("rm -rf out .with")
    if result != 0:
        with_eprintln("error: clean failed")
        return 1
    print("cleaned out/ and legacy .with/\n")
    0

fn print_usage:
    print("Usage: with <command> [options]\n")
    print("\n")
    print("Commands:\n")
    print("  build [file.w]    Build a source file (use --emit-c to emit C)\n")
    print("  run [file.w]      Build + run a source file\n")
    print("  check <file.w>    Parse and type-check a source file (supports --dump-tokens/--dump-ast/--dump-resolved/--dump-typed/--dump-mir/--dump-async-mir)\n")
    print("  test [file.w]     Run tests\n")
    print("  clean             Delete out/ and legacy .with/ artifacts\n")
    print("  ir <file.w>       Dump LLVM IR (debug)\n")
    print("  ast <file.w>      Parse and dump the AST (debug)\n")
    print("  tokens <file.w>   Lex and dump tokens (debug)\n")
    print("  version           Print compiler version\n")
    print("  help [topic]      Show CLI help or language quick reference\n")
    print("\n")
    print("Common options:\n")
    print("  --no-prelude          Disable implicit std prelude import\n")
    print("  --prelude=full|core|none  Select implicit prelude mode\n")
    print("  --freestanding        Alias for --no-std --no-prelude\n")
    print("\n")
    print("Language quick reference:\n")
    print("  with help use         Import syntax and module resolution\n")
    print("  with help keywords    Reserved words\n")
    print("  with help fn          Function declarations and signatures\n")
    print("  with help type        Type declarations and aliases\n")
    print("  with help operators   Operator precedence\n")

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
    if topic == "operators":
        print_help_operators()
        return 0
    with_eprintln("error: unknown help topic '" ++ topic ++ "'")
    with_eprintln("available help topics: use, fn, type, keywords, operators")
    1

fn print_help_use:
    print(r#"Import syntax:

  use foo.bar
  use foo.bar.*
  use c_import("sqlite3.h", link: "sqlite3")

Module resolution:

  use demo.core      -> lib/demo/core.w relative to the project root
  use foo.bar.*      -> import all public symbols from the module

Not supported:

  use foo.{a, b}     Grouped imports are not implemented
  use foo as bar     Aliased imports are not implemented
"#)

fn print_help_fn:
    print(r#"Function declarations:

  fn greet(name: str) -> str:
      "hello {name}"

  pub fn add(x: i32, y: i32) -> i32:
      x + y

Notes:

  - Indentation starts the function body.
  - Omit '-> T' for unit-returning functions.
  - Methods are declared inside 'extend Type:' blocks.
"#)

fn print_help_type:
    print(r#"Type declarations:

  type Point = { x: i32, y: i32 }
  type Color = Red | Green | Blue
  type Value = Int(i32) | Float(f64)
  type Handle = opaque
  type Meters = i32
  type Scalar = union { i: i32, f: f32 }

Related syntax:

  extend Point:
      fn norm(self: Point) -> i32:
          self.x + self.y
"#)

fn print_help_keywords:
    print(
        "Reserved words that cannot be used as identifiers:\n\n" ++
        "  fn let var if else then match for in while loop return break continue\n" ++
        "  with as mut type trait impl extend dyn use module pub async await spawn\n" ++
        "  unsafe comptime gen yield defer error extern c_import ephemeral select\n" ++
        "  true false not and or const it errdefer move where opaque null union\n"
    )

fn print_help_operators:
    print(
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
