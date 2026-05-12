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
use CiPrint
use CiMigrate

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_chmod(path: str, mode: i32) -> i32
extern fn with_read_bytes_stdin(count: i32) -> str
extern fn with_str_eq(a: str, b: str) -> i32
extern fn with_str_len(s: str) -> i64
extern fn with_str_byte_at(s: str, index: i64) -> i32
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_str_contains(s: str, needle: str) -> i32
extern fn with_str_slice(s: str, start: i64, end: i64) -> str
extern fn with_eprint(s: str) -> void
extern fn with_ewrite(s: str) -> void
extern fn with_system(cmd: str) -> i32
extern fn with_exec_binary(path: str) -> i32
extern fn with_exec_argv(args: str) -> i32
extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_clock_nanos() -> i64
extern fn with_getpid() -> i32
extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str
extern fn with_write(s: str) -> void
extern fn exit(code: i32) -> void
extern fn with_install_interrupt_handlers() -> void
extern fn with_raise_stack_limit() -> void

enum PreludeMode: i32:
    FullMode = 0
    CoreMode = 1
    NoneMode = 2

const CLI_DEFAULT_DEBUG_OPT_LEVEL: i32 = 0
const CLI_DEFAULT_BUILD_OPT_LEVEL: i32 = 1

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
    dump_project_info_flag: bool,
    dump_mir_flag: bool,
    dump_async_mir_flag: bool,
    deterministic_mode: bool,
    emit_c_mode: bool,
    prelude_mode: i32,
}

enum CliOneLinerMode: i32:
    None = 0
    Eval = 1
    Lines = 2
    Print = 3

type CliOneLiner {
    seen: bool,
    ok: bool,
    mode: i32,
    error_msg: str,
    code_parts: Vec[str],
    args: Vec[str],
    opt_level: i32,
}

type CliSyntheticSource {
    source: str,
    gen_starts: Vec[i32],
    gen_ends: Vec[i32],
    source_names: Vec[str],
    source_texts: Vec[str],
}

type TestDiscovery {
    parse_ok: bool,
    has_main: bool,
    test_names: Vec[str],
}

type TestDirectives {
    expect_stdout: Vec[str],
    expect_stderr: Vec[str],
    has_expect_exit: bool,
    expect_exit: i32,
}

type TestRunResult {
    rc: i32,
    stdout: str,
    stderr: str,
}

type BenchDiscovery {
    parse_ok: bool,
    has_main: bool,
    bench_names: Vec[str],
}

type BuildGraphTarget {
    kind: i32,
    name: str,
    entry: str,
    output: str,
    target_kind: i32,
    optimize_mode: i32,
    system_libs: Vec[str],
    include_paths: Vec[str],
    defines: Vec[str],
    inputs: Vec[str],
    deps: Vec[str],
    args: Vec[str],
}

type BuildGraphGeneratedSource {
    path: str,
    contents: str,
}

type BuildGraph {
    ok: bool,
    error_msg: str,
    raw_text: str,
    package_name: str,
    package_version: str,
    default_target: str,
    targets: Vec[BuildGraphTarget],
    generated_sources: Vec[BuildGraphGeneratedSource],
}

fn empty_test_discovery -> TestDiscovery:
    TestDiscovery { parse_ok: false, has_main: false, test_names: Vec.new() }

fn empty_test_directives -> TestDirectives:
    TestDirectives {
        expect_stdout: Vec.new(),
        expect_stderr: Vec.new(),
        has_expect_exit: false,
        expect_exit: 0,
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
        dump_project_info_flag: false,
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

fn cli_is_build_target_selector(arg: str) -> bool:
    arg.len() > 1 and arg.byte_at(0) == 58

fn cli_build_target_arg(argc: i32) -> str:
    if cli_command(argc) != "build":
        return ""
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if cli_is_build_target_selector(arg):
            return arg.slice(1, arg.len())
        i = i + 1
    ""

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
    opts.dump_project_info_flag = cli_has_flag(argc, "--dump-project-info")
    opts.dump_mir_flag = cli_has_flag(argc, "--dump-mir")
    opts.dump_async_mir_flag = cli_has_flag(argc, "--dump-async-mir")
    opts.deterministic_mode = cli_has_flag(argc, "--deterministic")
    opts.emit_c_mode = cli_has_flag(argc, "--emit-c")
    opts.prelude_mode = cli_prelude_mode(argc)
    opts

fn tokenize_text(text: str) -> TokenList:
    var lexer = Lexer.init(text, 0)
    return lexer.tokenize()

fn cli_one_liner_default(argc: i32) -> CliOneLiner:
    CliOneLiner {
        seen: false,
        ok: true,
        mode: CliOneLinerMode.None,
        error_msg: "",
        code_parts: Vec.new(),
        args: Vec.new(),
        opt_level: cli_default_opt_level(argc),
    }

fn cli_one_liner_mode_for_flag(arg: str) -> i32:
    if arg == "-e":
        return CliOneLinerMode.Eval
    if arg == "-n":
        return CliOneLinerMode.Lines
    if arg == "-p":
        return CliOneLinerMode.Print
    CliOneLinerMode.None

fn cli_one_liner_mode_name(mode: i32) -> str:
    if mode == CliOneLinerMode.Eval:
        return "-e"
    if mode == CliOneLinerMode.Lines:
        return "-n"
    if mode == CliOneLinerMode.Print:
        return "-p"
    ""

fn cli_one_liner_known_value_option(arg: str) -> bool:
    arg == "-o" or arg == "--output"

fn cli_one_liner_known_flag(arg: str) -> bool:
    arg == "-O0" or arg == "-O1" or arg == "-O2" or arg == "-O3" or
    arg == "--release" or arg == "--alloc" or arg == "--no-std" or
    arg == "--freestanding" or arg == "--no-prelude" or
    arg == "-g0" or arg == "-h" or arg == "--help"

fn cli_one_liner_scan(argc: i32) -> CliOneLiner:
    var result = cli_one_liner_default(argc)
    var after_double_dash = false
    var i = 1
    while i < argc:
        let arg = with_arg_at(i)
        if after_double_dash:
            result.args.push(arg)
            i = i + 1
            continue
        if arg == "--":
            after_double_dash = true
            i = i + 1
            continue
        let mode = cli_one_liner_mode_for_flag(arg)
        if mode != CliOneLinerMode.None:
            result.seen = true
            if result.mode != CliOneLinerMode.None and result.mode != mode:
                result.ok = false
                result.error_msg = "error: -e, -n, and -p are mutually exclusive"
                return result
            result.mode = mode
            if i + 1 >= argc:
                result.ok = false
                result.error_msg = "error: " ++ arg ++ " requires a code argument"
                return result
            result.code_parts.push(with_arg_at(i + 1))
            i = i + 2
            continue
        if arg == "-O0":
            result.opt_level = 0
            i = i + 1
            continue
        if arg == "-O1":
            result.opt_level = 1
            i = i + 1
            continue
        if arg == "-O2":
            result.opt_level = 2
            i = i + 1
            continue
        if arg == "-O3":
            result.opt_level = 3
            i = i + 1
            continue
        if arg == "--release":
            if result.opt_level < 2:
                result.opt_level = 2
            i = i + 1
            continue
        if cli_one_liner_known_value_option(arg):
            i = i + 2
            continue
        if has_output_prefix(arg) or cli_one_liner_known_flag(arg) or with_str_starts_with(arg, "--prelude=") != 0:
            i = i + 1
            continue
        if with_str_len(arg) > 0 and with_str_byte_at(arg, 0) != 45:
            if result.seen:
                result.ok = false
                result.error_msg = "error: cannot combine one-liner code with a source file"
                return result
        i = i + 1
    result

fn cli_escape_with_string(value: str) -> str:
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

fn cli_rewrite_semicolons(code: str) -> str:
    var lexer = Lexer.init(code, 0)
    let tokens = lexer.tokenize()
    var out = ""
    var cursor = 0
    for i in 0..tokens.len():
        let tag = tokens.get_tag(i)
        if tag == TokenKind.TK_EOF:
            break
        if tag != TokenKind.TK_SEMICOLON:
            continue
        let start = tokens.get_start(i)
        let end = tokens.get_end(i)
        if start > cursor:
            out = out ++ code.slice(cursor as i64, start as i64)
        out = out ++ "\n"
        cursor = end
    if cursor < code.len() as i32:
        out = out ++ code.slice(cursor as i64, code.len())
    out

fn cli_indent_code(code: str, indent: str) -> str:
    var out = indent
    for i in 0..code.len() as i32:
        let ch = code.byte_at(i as i64)
        out = out ++ code.slice(i as i64, (i + 1) as i64)
        if ch == 10 and i + 1 < code.len() as i32:
            out = out ++ indent
    out

fn cli_one_liner_source_name(mode: i32, count: i32) -> str:
    let name = cli_one_liner_mode_name(mode)
    if count == 1:
        return "<cli " ++ name ++ " #1>"
    "<cli " ++ name ++ ">"

fn cli_build_args_binding(args: Vec[str]) -> str:
    var out = "let args: Vec[str] = Vec.new()\n"
    for i in 0..args.len() as i32:
        let escaped = cli_escape_with_string(args.get(i as i64))
        out = out ++ "args.push(\"" ++ escaped ++ "\")\n"
    out

fn cli_synthetic_source_new -> CliSyntheticSource:
    CliSyntheticSource {
        source: "",
        gen_starts: Vec.new(),
        gen_ends: Vec.new(),
        source_names: Vec.new(),
        source_texts: Vec.new(),
    }

fn cli_synthetic_add_mapping(mut syn: CliSyntheticSource, start: i32, text: str, source_name: str) -> CliSyntheticSource:
    syn.gen_starts.push(start)
    syn.gen_ends.push(start + text.len() as i32 + 1)
    syn.source_names.push(source_name)
    syn.source_texts.push(text)
    syn

fn cli_build_synthetic_source(one: CliOneLiner) -> CliSyntheticSource:
    var syn = cli_synthetic_source_new()
    var source = ""
    source = source ++ "use std.io\n"
    source = source ++ "use std.str\n"
    source = source ++ "use std.regex\n"
    source = source ++ "use std.math\n"
    source = source ++ "use std.collections\n"
    source = source ++ "use std.builtins\n\n"
    source = source ++ cli_build_args_binding(one.args)
    if one.mode == CliOneLinerMode.Eval:
        for i in 0..one.code_parts.len() as i32:
            let rewritten = cli_rewrite_semicolons(one.code_parts.get(i as i64))
            let start = source.len() as i32
            source = source ++ rewritten ++ "\n"
            syn = cli_synthetic_add_mapping(syn, start, rewritten, "<cli -e #" ++ f"{i + 1}" ++ ">")
        syn.source = source
        return syn
    source = source ++ "var nr: i64 = 0\n"
    if one.mode == CliOneLinerMode.Lines:
        source = source ++ "for line in stdin.lines():\n"
        source = source ++ "    nr = nr + 1\n"
        for i in 0..one.code_parts.len() as i32:
            let rewritten = cli_rewrite_semicolons(one.code_parts.get(i as i64))
            let indented = cli_indent_code(rewritten, "    ")
            let start = source.len() as i32 + 4
            source = source ++ indented ++ "\n"
            syn = cli_synthetic_add_mapping(syn, start, rewritten, "<cli -n #" ++ f"{i + 1}" ++ ">")
        syn.source = source
        return syn
    source = source ++ "for __line in stdin.lines():\n"
    source = source ++ "    nr = nr + 1\n"
    source = source ++ "    var line = __line\n"
    for i in 0..one.code_parts.len() as i32:
        let rewritten = cli_rewrite_semicolons(one.code_parts.get(i as i64))
        let indented = cli_indent_code(rewritten, "    ")
        let start = source.len() as i32 + 4
        source = source ++ indented ++ "\n"
        syn = cli_synthetic_add_mapping(syn, start, rewritten, "<cli -p #" ++ f"{i + 1}" ++ ">")
    source = source ++ "    print(line)\n"
    syn.source = source
    syn

fn cli_one_liner_bin_path -> str:
    f"out/tmp/with-cli-one-liner-{with_getpid()}-{with_clock_nanos()}"

fn run_one_liner_command(argc: i32, one: CliOneLiner, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool) -> i32:
    let _ = argc
    let _ = debug_info
    if not one.ok:
        with_eprint(one.error_msg)
        return 1
    if one.code_parts.len() == 0:
        with_eprint("error: one-liner mode requires at least one code argument")
        return 1
    if no_std:
        with_eprint("error: one-liner mode requires the standard library")
        return 1
    let synthetic = cli_build_synthetic_source(one)
    let source = synthetic.source
    let source_name = cli_one_liner_source_name(one.mode, one.code_parts.len() as i32)
    let bin_path = cli_one_liner_bin_path()
    var comp = Compilation.init()
    comp.configure(one.opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(false)
    for mi in 0..synthetic.gen_starts.len() as i32:
        comp.add_cli_diag_mapping(
            synthetic.gen_starts.get(mi as i64),
            synthetic.gen_ends.get(mi as i64),
            synthetic.source_names.get(mi as i64),
            synthetic.source_texts.get(mi as i64),
        )
    let built = comp.build_entry_binary_from_source_to_path(source_name, source, bin_path)
    if built == "":
        return 1
    comp.print_warnings()
    let rc = with_exec_binary(built)
    let _ = with_fs_remove_file(built)
    let _ = with_fs_remove_file(built ++ ".o")
    let _ = with_fs_remove_dir(built ++ ".dSYM")
    rc

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
    let dump_project_info_flag = cli_has_flag(argc, "--dump-project-info")
    let dump_mir_flag = cli_has_flag(argc, "--dump-mir")
    let dump_async_mir_flag = cli_has_flag(argc, "--dump-async-mir")
    let debug_info = not cli_has_flag(argc, "-g0") and not cli_has_flag(argc, "--release")

    // Cache source and output paths — scanned once, used by all subcommands.
    let source = find_source_arg(argc)
    let output = find_output_arg(argc)

    let one_liner = cli_one_liner_scan(argc)
    if one_liner.seen:
        return run_one_liner_command(argc, one_liner, no_std, alloc_mode, prelude_mode, debug_info)

    // `with hello.w` is shorthand for `with run hello.w`
    if cli_is_implicit_run(argc):
        return run_run_command(cli_command(argc), opt_level, no_std, alloc_mode, prelude_mode, debug_info)

    if cli_command(argc) == "build":
        return run_build_command(source, opt_level, no_std, alloc_mode, emit_c_mode, emit_obj_mode, output, prelude_mode, debug_info, cli_build_target_arg(argc), cli_has_flag(argc, "--graph"), cli_has_flag(argc, "--dry-run"))
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
        if dump_project_info_flag:
            return dump_project_info_artifact(source, no_std, alloc_mode, prelude_mode)
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
        let prepared_pool = comp.prepare_pool_after_typecheck_hooks(pool, source)
        if prepared_pool.decl_count() == 0:
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
                if with_str_byte_at(arg, 0) != 45 and not cli_is_build_target_selector(arg): // not '-' or ':target'
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

fn test_unique_binary_path(source_file: str) -> str:
    let base = link_stage_output_path_for_source(source_file)
    f"{base}.test.{with_getpid()}.{with_clock_nanos()}"

fn empty_build_graph -> BuildGraph:
    BuildGraph {
        ok: false,
        error_msg: "",
        raw_text: "",
        package_name: "",
        package_version: "",
        default_target: "",
        targets: Vec.new(),
        generated_sources: Vec.new(),
    }

fn build_graph_generated_source_new(path: str, contents: str) -> BuildGraphGeneratedSource:
    BuildGraphGeneratedSource { path, contents }

fn build_graph_target_new(kind: i32, name: str, entry: str, target_kind: i32, optimize_mode: i32, output: str) -> BuildGraphTarget:
    BuildGraphTarget {
        kind,
        name,
        entry,
        output,
        target_kind,
        optimize_mode,
        system_libs: Vec.new(),
        include_paths: Vec.new(),
        defines: Vec.new(),
        inputs: Vec.new(),
        deps: Vec.new(),
        args: Vec.new(),
    }

fn build_graph_split_fields(line: str) -> Vec[str]:
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

fn build_graph_escape(value: str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 92:
            out = out ++ "\\\\"
        else if ch == 9:
            out = out ++ "\\t"
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

fn build_graph_emit(graph: BuildGraph) -> str:
    var out = "WITH_BUILD_GRAPH\t2\n"
    out = out ++ "package\t" ++ build_graph_escape(graph.package_name) ++ "\t" ++ build_graph_escape(graph.package_version) ++ "\n"
    if graph.default_target.len() > 0:
        out = out ++ "default_target\t" ++ build_graph_escape(graph.default_target) ++ "\n"
    for gi in 0..graph.generated_sources.len() as i32:
        let generated = graph.generated_sources.get(gi as i64)
        out = out ++ "generated_source\t" ++ build_graph_escape(generated.path) ++ "\t" ++ build_graph_escape(generated.contents) ++ "\n"
    for ti in 0..graph.targets.len() as i32:
        let target = graph.targets.get(ti as i64)
        out = out ++ "target\t"
        out = out ++ f"{target.kind}\t"
        out = out ++ build_graph_escape(target.name) ++ "\t"
        out = out ++ build_graph_escape(target.entry) ++ "\t"
        out = out ++ f"{target.target_kind}\t"
        out = out ++ f"{target.optimize_mode}\t"
        out = out ++ build_graph_escape(target.output) ++ "\n"
        for li in 0..target.system_libs.len() as i32:
            out = out ++ "system_lib\t" ++ f"{ti}\t" ++ build_graph_escape(target.system_libs.get(li as i64)) ++ "\n"
        for ii in 0..target.include_paths.len() as i32:
            out = out ++ "include_path\t" ++ f"{ti}\t" ++ build_graph_escape(target.include_paths.get(ii as i64)) ++ "\n"
        for di in 0..target.defines.len() as i32:
            out = out ++ "define\t" ++ f"{ti}\t" ++ build_graph_escape(target.defines.get(di as i64)) ++ "\n"
        for ini in 0..target.inputs.len() as i32:
            out = out ++ "input\t" ++ f"{ti}\t" ++ build_graph_escape(target.inputs.get(ini as i64)) ++ "\n"
        for depi in 0..target.deps.len() as i32:
            out = out ++ "dep\t" ++ f"{ti}\t" ++ build_graph_escape(target.deps.get(depi as i64)) ++ "\n"
        for ai in 0..target.args.len() as i32:
            out = out ++ "arg\t" ++ f"{ti}\t" ++ build_graph_escape(target.args.get(ai as i64)) ++ "\n"
    out

fn build_graph_parse_i32(text: str) -> i32:
    test_parse_i32(text)

fn parse_build_graph(text: str) -> BuildGraph:
    var graph = empty_build_graph()
    graph.raw_text = text
    if text.len() == 0:
        graph.error_msg = "build.w produced an empty build graph"
        return graph
    let lines = split_nonempty_lines(text)
    if lines.len() == 0:
        graph.error_msg = "build.w produced an empty build graph"
        return graph
    let header = build_graph_split_fields(lines.get(0))
    if header.len() != 2 or header.get(0) != "WITH_BUILD_GRAPH" or (header.get(1) != "1" and header.get(1) != "2"):
        graph.error_msg = "build.w produced an invalid build graph header"
        return graph
    let graph_version = build_graph_parse_i32(header.get(1))

    var has_current = false
    var current = build_graph_target_new(0, "", "", 0, 0, "")
    var i = 1
    while i < lines.len() as i32:
        let fields = build_graph_split_fields(lines.get(i as i64))
        if fields.len() == 0:
            i = i + 1
            continue
        let tag = fields.get(0)
        if tag == "package":
            if fields.len() != 3:
                graph.error_msg = "invalid package line in build graph"
                return graph
            graph.package_name = fields.get(1)
            graph.package_version = fields.get(2)
        else if tag == "default_target":
            if fields.len() != 2:
                graph.error_msg = "invalid default_target line in build graph"
                return graph
            graph.default_target = fields.get(1)
        else if tag == "generated_source":
            if fields.len() != 3:
                graph.error_msg = "invalid generated_source line in build graph"
                return graph
            graph.generated_sources.push(build_graph_generated_source_new(fields.get(1), fields.get(2)))
        else if tag == "target":
            if (graph_version == 1 and fields.len() != 6) or (graph_version == 2 and fields.len() != 7):
                graph.error_msg = "invalid target line in build graph"
                return graph
            if has_current:
                graph.targets.push(current)
            let output = if graph_version == 2: fields.get(6) else: ""
            current = build_graph_target_new(
                build_graph_parse_i32(fields.get(1)),
                fields.get(2),
                fields.get(3),
                build_graph_parse_i32(fields.get(4)),
                build_graph_parse_i32(fields.get(5)),
                output,
            )
            has_current = true
        else if tag == "system_lib":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid system_lib line in build graph"
                return graph
            current.system_libs.push(fields.get(2))
        else if tag == "include_path":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid include_path line in build graph"
                return graph
            current.include_paths.push(fields.get(2))
        else if tag == "define":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid define line in build graph"
                return graph
            current.defines.push(fields.get(2))
        else if tag == "input":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid input line in build graph"
                return graph
            current.inputs.push(fields.get(2))
        else if tag == "dep":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid dep line in build graph"
                return graph
            current.deps.push(fields.get(2))
        else if tag == "arg":
            if fields.len() != 3 or not has_current:
                graph.error_msg = "invalid arg line in build graph"
                return graph
            current.args.push(fields.get(2))
        else:
            graph.error_msg = "unknown build graph line: " ++ tag
            return graph
        i = i + 1
    if has_current:
        graph.targets.push(current)
    graph.ok = true
    graph

fn build_tool_runner_source(package_name: str, package_version: str, graph_path: str) -> str:
    "use std.build\n" ++
    "use build\n\n" ++
    "extern fn with_fs_write_file(path: str, data: str) -> i32\n\n" ++
    "fn main:\n" ++
    "    let pkg = Package { name: \"" ++ cli_escape_with_string(package_name) ++ "\", version: \"" ++ cli_escape_with_string(package_version) ++ "\" }\n" ++
    "    let graph = build(new_build(pkg)).emit_graph()\n" ++
    "    assert(with_fs_write_file(\"" ++ cli_escape_with_string(graph_path) ++ "\", graph) == 0)\n"

fn load_build_graph_from_build_w(root: str, cfg: ProjectConfig, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool) -> BuildGraph:
    var graph = empty_build_graph()
    let tmp_dir = resolve_join(root, "out/tmp")
    if with_fs_mkdir_p(tmp_dir) != 0:
        graph.error_msg = "could not create build graph temp directory: " ++ tmp_dir
        return graph
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let runner_path = resolve_join(root, "__with_build_runner." ++ stamp ++ ".w")
    let graph_path = resolve_join(tmp_dir, "build-graph." ++ stamp ++ ".txt")
    let runner_bin = resolve_join(tmp_dir, "build-runner." ++ stamp)
    let runner_source = build_tool_runner_source(cfg.package_name, cfg.package_version, graph_path)
    if with_fs_write_file(runner_path, runner_source) != 0:
        graph.error_msg = "could not write generated build.w runner"
        return graph
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    let built_runner = comp.build_binary_to_path(runner_path, runner_bin)
    let _remove_runner_source = with_fs_remove_file(runner_path)
    if built_runner == "":
        graph.error_msg = "build.w runner compilation failed"
        return graph
    let rc = with_exec_binary(built_runner)
    cleanup_binary_artifacts(built_runner)
    if rc != 0:
        let _remove_graph_on_error = with_fs_remove_file(graph_path)
        graph.error_msg = f"build.w execution failed with exit code {rc}"
        return graph
    let graph_text = with_fs_read_file(graph_path)
    let _remove_graph = with_fs_remove_file(graph_path)
    parse_build_graph(graph_text)

fn build_graph_filter_target(graph: &BuildGraph, target_name: str) -> BuildGraph:
    var out = empty_build_graph()
    out.ok = graph.ok
    out.error_msg = graph.error_msg
    out.raw_text = graph.raw_text
    out.package_name = graph.package_name
    out.package_version = graph.package_version
    out.default_target = graph.default_target
    for gi in 0..graph.generated_sources.len() as i32:
        out.generated_sources.push(graph.generated_sources.get(gi as i64))
    if target_name.len() == 0:
        for ti_all in 0..graph.targets.len() as i32:
            out.targets.push(graph.targets.get(ti_all as i64))
        out.raw_text = build_graph_emit(out)
        return out
    let selected = build_graph_select_target_closure(graph, target_name)
    if not selected.ok:
        out.ok = false
        out.error_msg = selected.error_msg
    else:
        for ti in 0..selected.targets.len() as i32:
            out.targets.push(selected.targets.get(ti as i64))
        out.raw_text = build_graph_emit(out)
    out

type BuildGraphSelectedTargets {
    ok: bool,
    error_msg: str,
    targets: Vec[BuildGraphTarget],
    selected_names: Vec[str],
    visiting_names: Vec[str],
}

fn build_graph_selected_targets_new -> BuildGraphSelectedTargets:
    BuildGraphSelectedTargets {
        ok: true,
        error_msg: "",
        targets: Vec.new(),
        selected_names: Vec.new(),
        visiting_names: Vec.new(),
    }

fn build_graph_name_vec_contains(names: Vec[str], name: str) -> bool:
    for i in 0..names.len() as i32:
        if names.get(i as i64) == name:
            return true
    false

fn build_graph_find_target_index(graph: &BuildGraph, name: str) -> i32:
    for i in 0..graph.targets.len() as i32:
        if graph.targets.get(i as i64).name == name:
            return i
    -1

fn build_graph_find_output_producer_index(graph: &BuildGraph, path: str, consumer_name: str) -> i32:
    if path.len() == 0:
        return -1
    for i in 0..graph.targets.len() as i32:
        let target = graph.targets.get(i as i64)
        if target.name != consumer_name and target.output.len() > 0 and target.output == path:
            return i
    -1

fn build_graph_selected_targets_add(selected: BuildGraphSelectedTargets, graph: &BuildGraph, name: str) -> BuildGraphSelectedTargets:
    var out = selected
    if not out.ok:
        return out
    if build_graph_name_vec_contains(out.selected_names, name):
        return out
    if build_graph_name_vec_contains(out.visiting_names, name):
        out.ok = false
        out.error_msg = "build.w target dependency cycle includes '" ++ name ++ "'"
        return out
    let index = build_graph_find_target_index(graph, name)
    if index < 0:
        out.ok = false
        out.error_msg = "build.w did not declare target '" ++ name ++ "'"
        return out
    let target = graph.targets.get(index as i64)
    out.visiting_names.push(name)
    for di in 0..target.deps.len() as i32:
        out = build_graph_selected_targets_add(move out, graph, target.deps.get(di as i64))
        if not out.ok:
            return out
    let entry_producer = build_graph_find_output_producer_index(graph, target.entry, target.name)
    if entry_producer >= 0:
        out = build_graph_selected_targets_add(move out, graph, graph.targets.get(entry_producer as i64).name)
        if not out.ok:
            return out
    for ii in 0..target.inputs.len() as i32:
        let input_producer = build_graph_find_output_producer_index(graph, target.inputs.get(ii as i64), target.name)
        if input_producer >= 0:
            out = build_graph_selected_targets_add(move out, graph, graph.targets.get(input_producer as i64).name)
            if not out.ok:
                return out
    out.selected_names.push(name)
    out.targets.push(target)
    out

fn build_graph_select_target_closure(graph: &BuildGraph, target_name: str) -> BuildGraphSelectedTargets:
    var selected = build_graph_selected_targets_new()
    build_graph_selected_targets_add(move selected, graph, target_name)

fn build_graph_find_build_root(start_dir: str) -> str:
    var cur = if start_dir.len() > 0: start_dir else: "."
    while true:
        let manifest = resolve_join(cur, "with.toml")
        let build_file = resolve_join(cur, "build.w")
        if project_config_file_exists(manifest) or project_config_file_exists(build_file):
            return project_config_absolutize_path(cur)
        let parent = resolve_dirname(cur)
        if parent == cur:
            break
        cur = parent
    ""

fn build_graph_output_path(root: str, target: BuildGraphTarget, output_path: str, target_count: i32) -> str:
    if output_path.len() > 0:
        if target_count != 1:
            return ""
        return output_path
    if target.output.len() > 0:
        return build_graph_resolve_project_path(root, target.output)
    resolve_join(resolve_join(root, "out/bin"), target.name)

fn build_graph_library_output_path(root: str, target: BuildGraphTarget, output_path: str, target_count: i32) -> str:
    if output_path.len() > 0:
        if target_count != 1:
            return ""
        return output_path
    if target.output.len() > 0:
        return build_graph_resolve_project_path(root, target.output)
    resolve_join(resolve_join(root, "out/lib"), "lib" ++ target.name ++ ".a")

fn build_graph_resolve_project_path(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    resolve_join(root, path)

fn build_graph_resolve_paths(root: str, paths: Vec[str]) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for i in 0..paths.len() as i32:
        out.push(build_graph_resolve_project_path(root, paths.get(i as i64)))
    out

fn build_graph_path_basename(path: str) -> str:
    let dir = build_graph_dirname(path)
    if dir == ".":
        return path
    path.slice((dir.len() + 1) as i64, path.len())

fn build_graph_path_has_glob(path: str) -> bool:
    with_str_contains(path, "*") != 0

fn build_graph_single_star_pattern_matches(pattern: str, name: str) -> bool:
    var star = -1
    for i in 0..pattern.len() as i32:
        if pattern.byte_at(i as i64) == 42:
            if star >= 0:
                return false
            star = i
    if star < 0:
        return pattern == name
    let prefix = pattern.slice(0, star as i64)
    let suffix = pattern.slice((star + 1) as i64, pattern.len())
    if name.len() < prefix.len() + suffix.len():
        return false
    if prefix.len() > 0 and name.slice(0, prefix.len()) != prefix:
        return false
    if suffix.len() > 0:
        let suffix_start = name.len() - suffix.len()
        if name.slice(suffix_start, name.len()) != suffix:
            return false
    true

fn build_graph_test_target_files(root: str, entry: str) -> Vec[str]:
    let files: Vec[str] = Vec.new()
    if not build_graph_path_has_glob(entry):
        files.push(resolve_join(root, entry))
        return files

    let entry_dir = build_graph_dirname(entry)
    let pattern = build_graph_path_basename(entry)
    let search_dir = if entry_dir == ".": root else: build_graph_resolve_project_path(root, entry_dir)
    let candidates = collect_test_files(search_dir)
    for ci in 0..candidates.len() as i32:
        let candidate = candidates.get(ci as i64)
        let base = build_graph_path_basename(candidate)
        if build_graph_single_star_pattern_matches(pattern, base):
            files.push(candidate)
    files

fn build_graph_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)

fn build_graph_generated_path_valid(path: str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47:
        return false
    if with_str_contains(path, "..") != 0:
        return false
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 10 or ch == 13 or ch == 9:
            return false
    true

fn build_graph_define_valid(define: str) -> bool:
    if define.len() == 0:
        return false
    for i in 0..define.len() as i32:
        let ch = define.byte_at(i as i64)
        if ch == 10 or ch == 13:
                return false
    true

fn build_graph_kind_name(kind: i32) -> str:
    if kind == 0: return "executable"
    if kind == 1: return "library"
    if kind == 2: return "test"
    if kind == 3: return "object"
    if kind == 4: return "archive"
    if kind == 5: return "generated_source"
    if kind == 6: return "generated_binary"
    if kind == 7: return "command"
    if kind == 8: return "install"
    if kind == 9: return "group"
    if kind == 10: return "binary_compare"
    if kind == 11: return "fixpoint_compare"
    if kind == 12: return "compile_c_object"
    if kind == 13: return "compile_asm_object"
    if kind == 14: return "compile_llvm_ir_object"
    if kind == 15: return "create_static_archive"
    if kind == 16: return "generate_response_file"
    if kind == 17: return "embed_object_files"
    if kind == 18: return "copy_runtime_tree"
    if kind == 19: return "run_corpus_test"
    if kind == 20: return "promote_tree_if_verified"
    f"unknown({kind})"

fn build_graph_target_name(kind: i32) -> str:
    if kind == 0:
        return "native"
    if kind == 1:
        return "linux_x86_64"
    if kind == 2:
        return "linux_aarch64"
    if kind == 3:
        return "darwin_x86_64"
    if kind == 4:
        return "darwin_aarch64"
    if kind == 5:
        return "windows_x86_64"
    f"unknown({kind})"

fn build_graph_host_target_kind() -> i32:
    let os = with_sysinfo_os()
    let arch = with_sysinfo_arch()
    if os == "Macos":
        if arch == "armv8" or arch == "aarch64":
            return 4
        if arch == "x86_64":
            return 3
    if os == "Linux":
        if arch == "armv8" or arch == "aarch64":
            return 2
        if arch == "x86_64":
            return 1
    if os == "Windows":
        if arch == "x86_64":
            return 5
    0

fn build_graph_target_is_host(kind: i32) -> bool:
    if kind == 0:
        return true
    kind == build_graph_host_target_kind()

fn build_graph_output_seen(outputs: Vec[str], path: str) -> bool:
    for i in 0..outputs.len() as i32:
        if outputs.get(i as i64) == path:
            return true
    false

fn build_graph_register_output(outputs: Vec[str], path: str) -> bool:
    if path.len() == 0:
        return true
    if build_graph_output_seen(outputs, path):
        return false
    outputs.push(path)
    true

fn build_graph_validate_outputs(root: str, graph: BuildGraph, output_path: str) -> i32:
    let outputs: Vec[str] = Vec.new()
    for gi in 0..graph.generated_sources.len() as i32:
        let generated = graph.generated_sources.get(gi as i64)
        if not build_graph_register_output(outputs, resolve_join(root, generated.path)):
            with_eprint("error: duplicate build.w output path: " ++ generated.path)
            return 1
    for ti in 0..graph.targets.len() as i32:
        let target = graph.targets.get(ti as i64)
        var path = ""
        if target.kind == 0:
            path = build_graph_output_path(root, target, output_path, graph.targets.len() as i32)
        else if target.kind == 1:
            path = build_graph_library_output_path(root, target, output_path, graph.targets.len() as i32)
        else if target.kind == 8:
            path = build_graph_expand_install_path(root, target.output)
        else if target.output.len() > 0:
            path = build_graph_resolve_project_path(root, target.output)
        if not build_graph_register_output(outputs, path):
            with_eprint("error: duplicate build.w output path for target '" ++ target.name ++ "': " ++ path)
            return 1
    0

fn run_build_graph_write_generated_sources(root: str, graph: BuildGraph) -> i32:
    for gi in 0..graph.generated_sources.len() as i32:
        let generated = graph.generated_sources.get(gi as i64)
        if not build_graph_generated_path_valid(generated.path):
            with_eprint("error: invalid build.w generated source path: " ++ generated.path)
            return 1
        let output_path = resolve_join(root, generated.path)
        let output_dir = build_graph_dirname(output_path)
        if with_fs_mkdir_p(output_dir) != 0:
            with_eprint("error: could not create generated source directory: " ++ output_dir)
            return 1
        if with_fs_write_file(output_path, generated.contents) != 0:
            with_eprint("error: could not write generated source: " ++ generated.path)
            return 1
    0

fn build_graph_target_input_path(root: str, target: BuildGraphTarget, index: i32) -> str:
    if index == 0:
        if target.entry.len() == 0:
            return ""
        return build_graph_resolve_project_path(root, target.entry)
    let input_index = index - 1
    if input_index < 0 or input_index >= target.inputs.len() as i32:
        return ""
    build_graph_resolve_project_path(root, target.inputs.get(input_index as i64))

fn build_graph_compare_files(root: str, target: BuildGraphTarget, operation_name: str) -> i32:
    let left_path = build_graph_target_input_path(root, target, 0)
    let right_path = if target.args.len() > 0:
        build_graph_resolve_project_path(root, target.args.get(0))
    else:
        build_graph_target_input_path(root, target, 1)
    if left_path.len() == 0 or right_path.len() == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires two input paths")
        return 1
    if with_fs_file_exists(left_path) == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing left input: " ++ left_path)
        return 1
    if with_fs_file_exists(right_path) == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing right input: " ++ right_path)
        return 1
    let left = with_fs_read_file(left_path)
    let right = with_fs_read_file(right_path)
    let min_len = if left.len() < right.len(): left.len() else: right.len()
    var diff_at = -1
    var i = 0
    while i < min_len:
        if left.byte_at(i as i64) != right.byte_at(i as i64):
            diff_at = i
            break
        i = i + 1
    if diff_at < 0 and left.len() != right.len():
        diff_at = min_len
    if diff_at >= 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' failed: " ++ left_path ++ " and " ++ right_path ++ f" differ at byte {diff_at}")
        return 1
    0

fn build_graph_response_arg_valid(arg: str) -> bool:
    for i in 0..arg.len() as i32:
        let ch = arg.byte_at(i as i64)
        if ch == 10 or ch == 13:
            return false
    true

fn build_graph_quote_response_arg(arg: str) -> str:
    var out = "\""
    for i in 0..arg.len() as i32:
        let ch = arg.byte_at(i as i64)
        if ch == 92 or ch == 34:
            out = out ++ "\\"
        out = out ++ arg.slice(i as i64, (i + 1) as i64)
    out ++ "\""

fn build_graph_write_response_file(root: str, target: BuildGraphTarget) -> i32:
    if target.output.len() == 0:
        with_eprint("error: generate_response_file target '" ++ target.name ++ "' requires an output path")
        return 1
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create response file directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    var text = ""
    for ai in 0..target.args.len() as i32:
        let arg = target.args.get(ai as i64)
        if not build_graph_response_arg_valid(arg):
            with_eprint("error: generate_response_file target '" ++ target.name ++ "' contains an argument with a newline")
            return 1
        text = text ++ build_graph_quote_response_arg(arg) ++ "\n"
    if with_fs_write_file(output_path, text) != 0:
        with_eprint("error: could not write response file for target '" ++ target.name ++ "': " ++ output_path)
        return 1
    0

fn build_graph_process_arg_valid(arg: str) -> bool:
    for i in 0..arg.len() as i32:
        if arg.byte_at(i as i64) == 0:
            return false
    true

fn build_graph_argv_append(argv_blob: str, arg: str) -> str:
    argv_blob ++ arg ++ "\0"

fn build_graph_exec_argv(target: BuildGraphTarget, operation_name: str, argv_blob: str) -> i32:
    let rc = with_exec_argv(argv_blob)
    if rc != 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ f"' failed with exit code {rc}")
        return if rc == 0: 1 else: rc
    0

fn build_graph_tool_from_env(env_name: str, fallback: str) -> str:
    let value = with_getenv_str(env_name)
    if value.len() > 0:
        return value
    fallback

fn build_graph_llvm_clang_tool() -> str:
    let explicit = with_getenv_str("WITH_LLVM_CC")
    if explicit.len() > 0:
        return explicit
    let legacy = with_getenv_str("LLVM_CC")
    if legacy.len() > 0:
        return legacy
    let prefix = with_getenv_str("LLVM_PREFIX")
    if prefix.len() > 0:
        return prefix ++ "/bin/clang"
    "clang"

fn build_graph_append_common_compile_args(root: str, target: BuildGraphTarget, argv_blob: str) -> str:
    var out = argv_blob
    for ii in 0..target.include_paths.len() as i32:
        out = build_graph_argv_append(out, "-I" ++ build_graph_resolve_project_path(root, target.include_paths.get(ii as i64)))
    for di in 0..target.defines.len() as i32:
        out = build_graph_argv_append(out, "-D" ++ target.defines.get(di as i64))
    for ai in 0..target.args.len() as i32:
        out = build_graph_argv_append(out, target.args.get(ai as i64))
    out

fn build_graph_validate_process_args(target: BuildGraphTarget) -> i32:
    if not build_graph_process_arg_valid(target.entry):
        with_eprint("error: build.w target '" ++ target.name ++ "' entry contains a NUL byte")
        return 1
    if not build_graph_process_arg_valid(target.output):
        with_eprint("error: build.w target '" ++ target.name ++ "' output contains a NUL byte")
        return 1
    for ii in 0..target.inputs.len() as i32:
        if not build_graph_process_arg_valid(target.inputs.get(ii as i64)):
            with_eprint("error: build.w target '" ++ target.name ++ "' input contains a NUL byte")
            return 1
    for ai in 0..target.args.len() as i32:
        if not build_graph_process_arg_valid(target.args.get(ai as i64)):
            with_eprint("error: build.w target '" ++ target.name ++ "' arg contains a NUL byte")
            return 1
    0

fn build_graph_compile_object(root: str, target: BuildGraphTarget, operation_name: str, compiler: str) -> i32:
    if target.entry.len() == 0 or target.output.len() == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires source and output paths")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let source_path = build_graph_resolve_project_path(root, target.entry)
    let output_path = build_graph_resolve_project_path(root, target.output)
    if with_fs_file_exists(source_path) == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing source: " ++ source_path)
        return 1
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create object output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    var argv = ""
    argv = build_graph_argv_append(argv, compiler)
    argv = build_graph_append_common_compile_args(root, target, argv)
    argv = build_graph_argv_append(argv, "-c")
    argv = build_graph_argv_append(argv, source_path)
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, output_path)
    build_graph_exec_argv(target, operation_name, argv)

fn build_graph_archive_member_seen(inputs: Vec[str], count: i32, basename: str) -> bool:
    for i in 0..count:
        if build_graph_path_basename(inputs.get(i as i64)) == basename:
            return true
    false

fn build_graph_create_archive(root: str, target: BuildGraphTarget) -> i32:
    if target.output.len() == 0:
        with_eprint("error: create_static_archive target '" ++ target.name ++ "' requires an output path")
        return 1
    if target.inputs.len() == 0:
        with_eprint("error: create_static_archive target '" ++ target.name ++ "' requires at least one input object")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create archive output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    let resolved_inputs: Vec[str] = Vec.new()
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: create_static_archive target '" ++ target.name ++ "' missing input: " ++ input_path)
            return 1
        let member = build_graph_path_basename(input_path)
        if build_graph_archive_member_seen(resolved_inputs, resolved_inputs.len() as i32, member):
            with_eprint("error: create_static_archive target '" ++ target.name ++ "' has duplicate archive member name: " ++ member)
            return 1
        resolved_inputs.push(input_path)
    let _remove_old_archive = with_fs_remove_file(output_path)
    var argv = ""
    argv = build_graph_argv_append(argv, build_graph_tool_from_env("AR", "ar"))
    argv = build_graph_argv_append(argv, "rcs")
    argv = build_graph_argv_append(argv, output_path)
    for ri in 0..resolved_inputs.len() as i32:
        argv = build_graph_argv_append(argv, resolved_inputs.get(ri as i64))
    build_graph_exec_argv(target, "create_static_archive", argv)

fn build_graph_asm_quote_path(path: str) -> str:
    var out = "\""
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 92 or ch == 34:
            out = out ++ "\\"
        out = out ++ path.slice(i as i64, (i + 1) as i64)
    out ++ "\""

fn build_graph_symbol_char_ok(ch: i32) -> bool:
    (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or (ch >= 48 and ch <= 57) or ch == 95

fn build_graph_symbol_name_valid(sym: str) -> bool:
    if sym.len() == 0:
        return false
    let first = sym.byte_at(0)
    if first >= 48 and first <= 57:
        return false
    for i in 0..sym.len() as i32:
        if not build_graph_symbol_char_ok(sym.byte_at(i as i64)):
            return false
    true

fn build_graph_emit_embedded_blob(sym: str, input_path: str) -> str:
    ".globl _with_embedded_" ++ sym ++ "_start\n" ++
    ".globl with_embedded_" ++ sym ++ "_start\n" ++
    ".globl _with_embedded_" ++ sym ++ "_end\n" ++
    ".globl with_embedded_" ++ sym ++ "_end\n" ++
    ".p2align 4\n" ++
    "_with_embedded_" ++ sym ++ "_start:\n" ++
    "with_embedded_" ++ sym ++ "_start:\n" ++
    "    .incbin " ++ build_graph_asm_quote_path(input_path) ++ "\n" ++
    "_with_embedded_" ++ sym ++ "_end:\n" ++
    "with_embedded_" ++ sym ++ "_end:\n\n"

fn build_graph_embed_object_files(root: str, target: BuildGraphTarget) -> i32:
    if target.output.len() == 0:
        with_eprint("error: embed_object_files target '" ++ target.name ++ "' requires an output path")
        return 1
    if target.inputs.len() == 0:
        with_eprint("error: embed_object_files target '" ++ target.name ++ "' requires at least one input object")
        return 1
    if target.args.len() != target.inputs.len():
        with_eprint("error: embed_object_files target '" ++ target.name ++ "' requires one stable symbol name per input")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create embedded-object output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    var asm_text = "// Auto-generated by with build embed_object_files - do not edit.\n\n"
    if build_graph_host_target_kind() == 3 or build_graph_host_target_kind() == 4:
        asm_text = asm_text ++ ".section __TEXT,__const\n.subsections_via_symbols\n\n"
    else:
        asm_text = asm_text ++ ".section .rodata\n\n"
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: embed_object_files target '" ++ target.name ++ "' missing input: " ++ input_path)
            return 1
        let sym = target.args.get(ii as i64)
        if not build_graph_symbol_name_valid(sym):
            with_eprint("error: embed_object_files target '" ++ target.name ++ "' has invalid symbol name: " ++ sym)
            return 1
        asm_text = asm_text ++ build_graph_emit_embedded_blob(sym, input_path)
    if with_fs_write_file(output_path, asm_text) != 0:
        with_eprint("error: could not write embedded-object assembly for target '" ++ target.name ++ "': " ++ output_path)
        return 1
    0

fn build_graph_manifest_relative_path_valid(path: str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47:
        return false
    if with_str_contains(path, "..") != 0:
        return false
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 0 or ch == 10 or ch == 13 or ch == 9:
            return false
    true

fn build_graph_copy_manifest_files(root: str, target: BuildGraphTarget, operation_name: str) -> i32:
    if target.entry.len() == 0 or target.output.len() == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires source and output directories")
        return 1
    if target.inputs.len() == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires explicit relative input paths")
        return 1
    let source_dir = build_graph_resolve_project_path(root, target.entry)
    let output_dir = build_graph_resolve_project_path(root, target.output)
    for ii in 0..target.inputs.len() as i32:
        let rel = target.inputs.get(ii as i64)
        if not build_graph_manifest_relative_path_valid(rel):
            with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' has invalid relative input path: " ++ rel)
            return 1
        let source_path = resolve_join(source_dir, rel)
        let dest_path = resolve_join(output_dir, rel)
        if with_fs_file_exists(source_path) == 0:
            with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' missing input: " ++ source_path)
            return 1
        let dest_dir = build_graph_dirname(dest_path)
        if with_fs_mkdir_p(dest_dir) != 0:
            with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' could not create destination directory: " ++ dest_dir)
            return 1
        let contents = with_fs_read_file(source_path)
        if with_fs_write_file(dest_path, contents) != 0:
            with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' could not write destination: " ++ dest_path)
            return 1
    0

fn build_graph_run_corpus_test(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        with_eprint("error: run_corpus_test target '" ++ target.name ++ "' requires a runner")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: run_corpus_test target '" ++ target.name ++ "' missing declared input: " ++ input_path)
            return 1
    let output_dir = if target.output.len() > 0:
        build_graph_resolve_project_path(root, target.output)
    else:
        resolve_join(resolve_join(root, "out/corpus"), target.name)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: could not create corpus output directory for target '" ++ target.name ++ "': " ++ output_dir)
        return 1
    let stdout_path = resolve_join(output_dir, "stdout.txt")
    let stderr_path = resolve_join(output_dir, "stderr.txt")
    var argv = ""
    let runner_path = if target.entry.byte_at(0) == 47 or with_str_contains(target.entry, "/") != 0:
        build_graph_resolve_project_path(root, target.entry)
    else:
        target.entry
    argv = build_graph_argv_append(argv, runner_path)
    for ai in 0..target.args.len() as i32:
        argv = build_graph_argv_append(argv, target.args.get(ai as i64))
    let timeout_ms = 300000
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    if rc == 124:
        with_eprint("error: run_corpus_test target '" ++ target.name ++ f"' timed out after {timeout_ms}ms; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        with_eprint("error: run_corpus_test target '" ++ target.name ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return if rc == 0: 1 else: rc
    0

fn build_graph_run_command(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        with_eprint("error: command target '" ++ target.name ++ "' requires an executable")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: command target '" ++ target.name ++ "' missing declared input: " ++ input_path)
            return 1
    if target.output.len() > 0:
        let output_path = build_graph_resolve_project_path(root, target.output)
        let output_dir = build_graph_dirname(output_path)
        if with_fs_mkdir_p(output_dir) != 0:
            with_eprint("error: command target '" ++ target.name ++ "' could not create output directory: " ++ output_dir)
            return 1
    let capture_dir = resolve_join(resolve_join(root, "out/command"), target.name)
    if with_fs_mkdir_p(capture_dir) != 0:
        with_eprint("error: could not create command output directory for target '" ++ target.name ++ "': " ++ capture_dir)
        return 1
    let stdout_path = resolve_join(capture_dir, "stdout.txt")
    let stderr_path = resolve_join(capture_dir, "stderr.txt")
    var argv = ""
    let runner_path = if target.entry.byte_at(0) == 47 or with_str_contains(target.entry, "/") != 0:
        build_graph_resolve_project_path(root, target.entry)
    else:
        target.entry
    argv = build_graph_argv_append(argv, runner_path)
    for ai in 0..target.args.len() as i32:
        argv = build_graph_argv_append(argv, target.args.get(ai as i64))
    let timeout_ms = 300000
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    if rc == 124:
        with_eprint("error: command target '" ++ target.name ++ f"' timed out after {timeout_ms}ms; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        with_eprint("error: command target '" ++ target.name ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return if rc == 0: 1 else: rc
    if target.output.len() > 0:
        let output_path = build_graph_resolve_project_path(root, target.output)
        if with_fs_file_exists(output_path) == 0:
            with_eprint("error: command target '" ++ target.name ++ "' did not produce declared output: " ++ output_path)
            return 1
    0

fn build_graph_expand_install_path(root: str, path: str) -> str:
    if with_str_starts_with(path, "$HOME/") != 0:
        let home = with_getenv_str("HOME")
        if home.len() > 0:
            return resolve_join(home, path.slice(6, path.len()))
    build_graph_resolve_project_path(root, path)

fn build_graph_parse_octal_mode(text: str) -> i32:
    if text.len() == 0:
        return -1
    var mode = 0
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch < 48 or ch > 55:
            return -1
        mode = mode * 8 + (ch - 48)
    mode

fn build_graph_install_file(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0 or target.output.len() == 0:
        with_eprint("error: install target '" ++ target.name ++ "' requires source and destination paths")
        return 1
    if target.args.len() > 1:
        with_eprint("error: install target '" ++ target.name ++ "' accepts at most one mode argument")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let source_path = build_graph_resolve_project_path(root, target.entry)
    if with_fs_file_exists(source_path) == 0:
        with_eprint("error: install target '" ++ target.name ++ "' missing source: " ++ source_path)
        return 1
    let dest_path = build_graph_expand_install_path(root, target.output)
    if dest_path.len() == 0 or dest_path == target.output and with_str_starts_with(dest_path, "$HOME/") != 0:
        with_eprint("error: install target '" ++ target.name ++ "' could not resolve destination: " ++ target.output)
        return 1
    let dest_dir = build_graph_dirname(dest_path)
    if with_fs_mkdir_p(dest_dir) != 0:
        with_eprint("error: install target '" ++ target.name ++ "' could not create destination directory: " ++ dest_dir)
        return 1
    let contents = with_fs_read_file(source_path)
    if with_fs_write_file(dest_path, contents) != 0:
        with_eprint("error: install target '" ++ target.name ++ "' could not write destination: " ++ dest_path)
        return 1
    let mode = if target.args.len() == 0: 0o644 else: build_graph_parse_octal_mode(target.args.get(0))
    if mode < 0:
        with_eprint("error: install target '" ++ target.name ++ "' has invalid octal mode: " ++ target.args.get(0))
        return 1
    if with_fs_chmod(dest_path, mode) != 0:
        with_eprint("error: install target '" ++ target.name ++ "' could not chmod destination: " ++ dest_path)
        return 1
    0

fn build_graph_target_completed(completed: Vec[str], name: str) -> bool:
    for i in 0..completed.len() as i32:
        if completed.get(i as i64) == name:
            return true
    false

fn build_graph_verify_completed_deps(target: BuildGraphTarget, completed: Vec[str], operation_name: str, require_deps: bool) -> i32:
    if require_deps and target.deps.len() == 0:
        with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' requires verification dependencies")
        return 1
    for di in 0..target.deps.len() as i32:
        let dep = target.deps.get(di as i64)
        if not build_graph_target_completed(completed, dep):
            with_eprint("error: " ++ operation_name ++ " target '" ++ target.name ++ "' dependency has not completed: " ++ dep)
            return 1
    0

fn run_build_graph(root: str, graph: BuildGraph, opt_level: i32, no_std: bool, alloc_mode: bool, output_path: str, prelude_mode: i32, debug_info: bool) -> i32:
    if graph.targets.len() == 0:
        with_eprint("error: build.w did not declare any targets")
        return 1
    let output_rc = build_graph_validate_outputs(root, graph, output_path)
    if output_rc != 0:
        return output_rc
    let generated_rc = run_build_graph_write_generated_sources(root, graph)
    if generated_rc != 0:
        return generated_rc
    let completed_targets: Vec[str] = Vec.new()
    for ti in 0..graph.targets.len() as i32:
        let target = graph.targets.get(ti as i64)
        if target.kind < 0 or target.kind > 20:
            with_eprint("error: invalid build.w target kind " ++ build_graph_kind_name(target.kind) ++ " for '" ++ target.name ++ "'")
            return 1
        if target.kind != 0 and target.kind != 1 and target.kind != 2 and target.kind != 7 and target.kind != 8 and target.kind != 9 and target.kind != 10 and target.kind != 11 and target.kind != 12 and target.kind != 13 and target.kind != 14 and target.kind != 15 and target.kind != 16 and target.kind != 17 and target.kind != 18 and target.kind != 19 and target.kind != 20:
            with_eprint("error: build.w target kind '" ++ build_graph_kind_name(target.kind) ++ "' is not implemented yet for '" ++ target.name ++ "'")
            return 1
        if target.target_kind < 0 or target.target_kind > 5:
            with_eprint("error: invalid build.w target platform " ++ build_graph_target_name(target.target_kind) ++ " for '" ++ target.name ++ "'")
            return 1
        if not build_graph_target_is_host(target.target_kind):
            with_eprint("error: build.w cross-target platform " ++ build_graph_target_name(target.target_kind) ++ " is not implemented yet for '" ++ target.name ++ "'; host is " ++ build_graph_target_name(build_graph_host_target_kind()))
            return 1
        for di in 0..target.defines.len() as i32:
            let define = target.defines.get(di as i64)
            if not build_graph_define_valid(define):
                with_eprint("error: invalid build.w define for '" ++ target.name ++ "': " ++ define)
                return 1
        if target.kind == 9:
            let deps_rc = build_graph_verify_completed_deps(target, completed_targets, "group", false)
            if deps_rc != 0:
                return deps_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 10:
            let compare_rc = build_graph_compare_files(root, target, "binary_compare")
            if compare_rc != 0:
                return compare_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 11:
            let fixpoint_rc = build_graph_compare_files(root, target, "fixpoint_compare")
            if fixpoint_rc != 0:
                return fixpoint_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 16:
            let response_rc = build_graph_write_response_file(root, target)
            if response_rc != 0:
                return response_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 12:
            let c_rc = build_graph_compile_object(root, target, "compile_c_object", build_graph_tool_from_env("CC", "cc"))
            if c_rc != 0:
                return c_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 13:
            let asm_rc = build_graph_compile_object(root, target, "compile_asm_object", build_graph_tool_from_env("CC", "cc"))
            if asm_rc != 0:
                return asm_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 14:
            let ir_rc = build_graph_compile_object(root, target, "compile_llvm_ir_object", build_graph_llvm_clang_tool())
            if ir_rc != 0:
                return ir_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 15:
            let archive_rc = build_graph_create_archive(root, target)
            if archive_rc != 0:
                return archive_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 17:
            let embed_rc = build_graph_embed_object_files(root, target)
            if embed_rc != 0:
                return embed_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 18:
            let copy_rc = build_graph_copy_manifest_files(root, target, "copy_runtime_tree")
            if copy_rc != 0:
                return copy_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 20:
            let deps_rc = build_graph_verify_completed_deps(target, completed_targets, "promote_tree_if_verified", true)
            if deps_rc != 0:
                return deps_rc
            let promote_rc = build_graph_copy_manifest_files(root, target, "promote_tree_if_verified")
            if promote_rc != 0:
                return promote_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 19:
            let corpus_rc = build_graph_run_corpus_test(root, target)
            if corpus_rc != 0:
                return corpus_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 7:
            let command_rc = build_graph_run_command(root, target)
            if command_rc != 0:
                return command_rc
            completed_targets.push(target.name)
            continue
        if target.kind == 8:
            let install_rc = build_graph_install_file(root, target)
            if install_rc != 0:
                return install_rc
            completed_targets.push(target.name)
            continue
        let source_path = resolve_join(root, target.entry)
        var target_opt = opt_level
        if target.optimize_mode == 1 and target_opt < 2:
            target_opt = 2
        let include_paths = build_graph_resolve_paths(root, target.include_paths)
        if target.kind == 2:
            if output_path.len() > 0:
                with_eprint("error: -o cannot be used with build.w test target '" ++ target.name ++ "'")
                return 1
            let test_files = build_graph_test_target_files(root, target.entry)
            if test_files.len() == 0:
                with_eprint("error: build.w test target matched no files: " ++ target.entry)
                return 1
            for fi in 0..test_files.len() as i32:
                let test_path = test_files.get(fi as i64)
                let test_rc = run_test_file_with_build_settings(test_path, target_opt, no_std, alloc_mode, prelude_mode, debug_info, false, false, "", include_paths, target.defines, target.system_libs)
                if test_rc != 0:
                    with_eprint("error: build.w test target failed: " ++ target.name)
                    return test_rc
            if build_graph_path_has_glob(target.entry):
                with_write(f"ok: {test_files.len()} files passed in build.w test target {target.name}\n")
            completed_targets.push(target.name)
            continue
        if target.kind == 1:
            let ar_path = build_graph_library_output_path(root, target, output_path, graph.targets.len() as i32)
            if ar_path.len() == 0:
                with_eprint("error: -o cannot be used when build.w declares multiple targets")
                return 1
            var comp = Compilation.init()
            comp.configure(target_opt, no_std, alloc_mode)
            comp.set_prelude_mode(prelude_mode)
            comp.set_debug_info(debug_info)
            let built = comp.emit_archive_to_path_with_build_settings(source_path, ar_path, include_paths, target.defines, target.system_libs)
            if built == "":
                with_eprint("error: build.w library target failed: " ++ target.name)
                return 1
            comp.print_warnings()
            completed_targets.push(target.name)
            continue
        let bin_path = build_graph_output_path(root, target, output_path, graph.targets.len() as i32)
        if bin_path.len() == 0:
            with_eprint("error: -o cannot be used when build.w declares multiple targets")
            return 1
        var comp = Compilation.init()
        comp.configure(target_opt, no_std, alloc_mode)
        comp.set_prelude_mode(prelude_mode)
        comp.set_debug_info(debug_info)
        let built = comp.build_binary_to_path_with_build_settings(source_path, bin_path, include_paths, target.defines, target.system_libs)
        if built == "":
            with_eprint("error: build.w target failed: " ++ target.name)
            return 1
        comp.print_warnings()
        completed_targets.push(target.name)
    0

fn run_build_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool, emit_c_mode: bool, emit_obj_mode: bool, output_path: str, prelude_mode: i32, debug_info: bool, build_target_name: str, graph_only: bool, dry_run: bool) -> i32:
    var actual_source = source_file
    var actual_output = output_path
    if actual_source == "":
        let root = build_graph_find_build_root(".")
        if root.len() == 0:
            with_eprint("error: 'build' requires a source file argument, build.w, or a with.toml project")
            return 1
        let build_path = resolve_join(root, "build.w")
        let cfg = project_config_load_for_source(root ++ "/src/main.w")
        if cfg.manifest_error.len() > 0:
            with_eprint("error: invalid with.toml: " ++ cfg.manifest_error)
            return 1
        if project_config_file_exists(build_path):
            if emit_c_mode or emit_obj_mode:
                with_eprint("error: build.w tool-mode only supports binary builds")
                return 1
            let graph = load_build_graph_from_build_w(root, cfg, opt_level, no_std, alloc_mode, prelude_mode, debug_info)
            if not graph.ok:
                with_eprint("error: " ++ graph.error_msg)
                return 1
            var selected_target_name = build_target_name
            if selected_target_name.len() == 0 and graph.default_target.len() > 0:
                selected_target_name = graph.default_target
            let selected_graph = build_graph_filter_target(&graph, selected_target_name)
            if not selected_graph.ok:
                with_eprint("error: " ++ selected_graph.error_msg)
                return 1
            if graph_only or dry_run:
                with_write(selected_graph.raw_text)
                return 0
            return run_build_graph(root, selected_graph, opt_level, no_std, alloc_mode, actual_output, prelude_mode, debug_info)
        actual_source = root ++ "/src/main.w"
        if actual_output == "" and cfg.package_name.len() > 0:
            actual_output = "out/bin/" ++ cfg.package_name
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    if emit_c_mode:
        let c_path = comp.emit_c(actual_source, actual_output)
        if c_path == "":
            with_eprint("error: build failed")
            return 1
        with_eprint("emitted C: " ++ c_path)
        with_eprint("compile with zig cc (example):")
        with_eprint("  zig cc -target <triple> -I runtime " ++ c_path ++ " runtime/with_runtime.c runtime/helpers.c runtime/fiber.c runtime/fiber_asm_<arch>.s -o <output>")
        comp.print_warnings()
        return 0
    if emit_obj_mode:
        var obj_path = actual_output
        if obj_path == "":
            obj_path = link_stage_output_path_for_source(actual_source) ++ ".o"
        let result = comp.emit_object_to_path(actual_source, obj_path)
        if result == "":
            with_eprint("error: build failed")
            return 1
        comp.print_warnings()
        return 0
    let bin_path = comp.build_binary_to_path(actual_source, actual_output)
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

fn dump_project_info_artifact(source_file: str, no_std: bool, alloc_mode: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    let text = comp.dump_project_info_file(source_file)
    if text.len() == 0:
        with_eprint("error: project info dump failed")
        return 1
    with_write(text)
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
        var prefix = "        else if "
        if ti == 0:
            prefix = "        if "
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

fn test_parse_i32(text: str) -> i32:
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

fn parse_test_directives_for_target(target: str) -> TestDirectives:
    var result = empty_test_directives()
    let text = with_fs_read_file(target)
    if text.len() == 0:
        return result
    let text_len = text.len() as i32

    let expect_stdout_prefix = "//! expect-stdout: "
    let expect_stderr_prefix = "//! expect-stderr: "
    let expect_exit_prefix = "//! expect-exit: "
    var start = 0
    var i = 0
    while i <= text_len:
        var ch = 10
        if i < text_len:
            ch = text.byte_at(i as i64)
        if ch == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line.byte_at(line.len() as i64 - 1) == 13:
                line = line.slice(0, line.len() - 1)
            if with_str_starts_with(line, expect_stdout_prefix) != 0:
                result.expect_stdout.push(line.slice(expect_stdout_prefix.len(), line.len()))
            else if with_str_starts_with(line, expect_stderr_prefix) != 0:
                result.expect_stderr.push(line.slice(expect_stderr_prefix.len(), line.len()))
            else if with_str_starts_with(line, expect_exit_prefix) != 0:
                result.has_expect_exit = true
                result.expect_exit = test_parse_i32(line.slice(expect_exit_prefix.len(), line.len()))
            else if with_str_starts_with(line, "//!") != 0:
                let _ = 0
            else:
                return result
            start = i + 1
        i = i + 1
    result

fn test_directives_have_run_expectations(directives: TestDirectives) -> bool:
    directives.has_expect_exit or directives.expect_stdout.len() > 0 or directives.expect_stderr.len() > 0

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
    let text_len = text.len() as i32
    var start = 0
    var i = 0
    while i <= text_len:
        var ch = 10
        if i < text_len:
            ch = text.byte_at(i as i64)
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

fn test_capture_suffix(test_name: str) -> str:
    if test_name.len() > 0:
        return "." ++ test_name
    ".run"

fn run_test_process(bin_path: str, test_name: str, quiet: bool) -> TestRunResult:
    let suffix = test_capture_suffix(test_name)
    let out_path = bin_path ++ suffix ++ ".stdout"
    let err_path = bin_path ++ suffix ++ ".stderr"
    let _ = ("rm -f " ++ test_shell_quote(out_path) ++ " " ++ test_shell_quote(err_path)) |> with_system
    var cmd = test_shell_quote(bin_path)
    if test_name.len() > 0:
        cmd = "WITH_TEST_FILTER=" ++ test_shell_quote(test_name) ++ " " ++ cmd
    if quiet:
        cmd = "WITH_TEST_SHORT=1 " ++ cmd
    let rc = with_system(cmd ++ " > " ++ test_shell_quote(out_path) ++ " 2> " ++ test_shell_quote(err_path))
    let stdout = with_fs_read_file(out_path)
    let stderr = with_fs_read_file(err_path)
    let _cleanup = ("rm -f " ++ test_shell_quote(out_path) ++ " " ++ test_shell_quote(err_path)) |> with_system
    if not quiet:
        if stdout.len() > 0:
            with_write(stdout)
        if stderr.len() > 0:
            with_ewrite(stderr)
    TestRunResult { rc, stdout, stderr }

fn test_validate_output(stream_name: str, actual: str, expected_values: Vec[str], target: str, test_name: str) -> bool:
    for ei in 0..expected_values.len() as i32:
        let expected = expected_values.get(ei as i64)
        if with_str_contains(actual, expected) == 0:
            emit_test_stage_error(stream_name ++ " mismatch; missing expected output: " ++ expected, target, "run", test_name)
            return false
    true

fn validate_test_run(result: TestRunResult, directives: TestDirectives, target: str, test_name: str) -> bool:
    if directives.has_expect_exit:
        if result.rc != directives.expect_exit:
            emit_test_stage_error(f"exit code {result.rc}, expected {directives.expect_exit}", target, "run", test_name)
            return false
    else if result.rc != 0:
        emit_test_stage_error(f"exit code {result.rc}", target, "run", test_name)
        return false
    if not test_validate_output("stdout", result.stdout, directives.expect_stdout, target, test_name):
        return false
    if not test_validate_output("stderr", result.stderr, directives.expect_stderr, target, test_name):
        return false
    true

fn run_test_binary_checked(bin_path: str, target: str, test_name: str, quiet: bool, directives: TestDirectives) -> i32:
    let result = run_test_process(bin_path, test_name, quiet)
    if validate_test_run(result, directives, target, test_name):
        return 0
    1

fn run_test_file_with_build_settings(target: str, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool, verbose: bool, quiet: bool, filter: str, include_paths: Vec[str], defines: Vec[str], link_libs: Vec[str]) -> i32:
    let discovery = discover_tests_for_target(target)
    let directives = parse_test_directives_for_target(target)
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    let synthetic_source = maybe_synthesize_test_source(target)
    let test_bin_path = test_unique_binary_path(target)
    var bin_path = ""
    if synthetic_source.len() > 0:
        bin_path = comp.build_binary_from_source_to_path_with_build_settings(target, synthetic_source, test_bin_path, include_paths, defines, link_libs)
    else:
        bin_path = comp.build_binary_to_path_with_build_settings(target, test_bin_path, include_paths, defines, link_libs)
    if bin_path == "":
        emit_test_stage_error("test build failed", target, "build", "")
        return 1
    if discovery.parse_ok and not discovery.has_main and discovery.test_names.len() > 0:
        if test_directives_have_run_expectations(directives) and filter.len() == 0:
            var run_quiet = quiet
            if verbose:
                run_quiet = false
            let rc = run_test_binary_checked(bin_path, target, "", run_quiet, directives)
            cleanup_binary_artifacts(bin_path)
            if rc == 0:
                print_test_summary(target, discovery.test_names.len() as i32, 0, run_quiet)
                return 0
            print_test_summary(target, 0, 1, run_quiet)
            return 1
        var passed = 0
        var failed = 0
        for ti in 0..discovery.test_names.len() as i32:
            let test_name = discovery.test_names.get(ti as i64)
            if filter.len() > 0 and with_str_contains(test_name, filter) == 0:
                continue
            var run_quiet = quiet
            if verbose:
                run_quiet = false
            let rc = run_test_binary_checked(bin_path, target, test_name, run_quiet, empty_test_directives())
            if rc == 0:
                passed = passed + 1
                if verbose:
                    with_write("PASS " ++ test_name ++ "\n")
            else:
                failed = failed + 1
                if verbose:
                    with_eprint("FAIL " ++ test_name)
        cleanup_binary_artifacts(bin_path)
        var summary_quiet = quiet
        if verbose:
            summary_quiet = false
        print_test_summary(target, passed, failed, summary_quiet)
        if failed == 0:
            return 0
        return 1
    var run_quiet = quiet
    if verbose:
        run_quiet = false
    let run_rc = run_test_binary_checked(bin_path, target, "", run_quiet, directives)
    cleanup_binary_artifacts(bin_path)
    if run_rc == 0:
        print_test_summary(target, 1, 0, run_quiet)
        return 0
    print_test_summary(target, 0, 1, run_quiet)
    run_rc

fn run_test_file(target: str, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool, verbose: bool, quiet: bool, filter: str) -> i32:
    let include_paths: Vec[str] = Vec.new()
    let defines: Vec[str] = Vec.new()
    let link_libs: Vec[str] = Vec.new()
    run_test_file_with_build_settings(target, opt_level, no_std, alloc_mode, prelude_mode, debug_info, verbose, quiet, filter, include_paths, defines, link_libs)

fn run_test_command(argc: i32, opt_level: i32, no_std: bool, alloc_mode: bool, prelude_mode: i32, debug_info: bool) -> i32:
    let verbose = cli_test_verbose(argc)
    var quiet = cli_test_quiet(argc)
    if verbose:
        quiet = false
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
        eprint("usage: with migrate <file.c|dir/> [-o output] [-I include_dir] [--exclude basename]")
        return 1

    // Hidden developer mode: run the CiIR/CiPrint roundtrip harness
    // and exit. Used by the cli-selfhost-ir-roundtrip test.
    if with_arg_at(2) == "--ir-roundtrip":
        return ci_ir_roundtrip_test()

    // Parse arguments
    var source_path = ""
    var output_path = ""
    var exclude_basenames = ""
    var reinvoke_args = ""
    var ai = 2
    while ai < argc:
        let arg = with_arg_at(ai)
        if arg == "-o" and ai + 1 < argc:
            output_path = with_arg_at(ai + 1)
            ai = ai + 2
            continue
        if arg == "-I" and ai + 1 < argc:
            with_cimport_add_include_path(with_arg_at(ai + 1))
            reinvoke_args = f"{reinvoke_args} -I {test_shell_quote(with_arg_at(ai + 1))}"
            ai = ai + 2
            continue
        if arg == "-D" and ai + 1 < argc:
            migrate_add_define(with_arg_at(ai + 1))
            reinvoke_args = f"{reinvoke_args} -D {test_shell_quote(with_arg_at(ai + 1))}"
            ai = ai + 2
            continue
        if arg == "--check" or arg == "--diff" or arg == "--stats":
            ai = ai + 1
            continue  // TODO: implement modes
        if arg == "--no-c-export":
            migrate_set_no_c_export(1)
            reinvoke_args = f"{reinvoke_args} --no-c-export"
            ai = ai + 1
            continue
        if arg == "--c-export-functions":
            migrate_set_export_function_defs(1)
            reinvoke_args = f"{reinvoke_args} --c-export-functions"
            ai = ai + 1
            continue
        if arg == "--convert-goto-to-structured":
            migrate_set_convert_goto_to_structured(1)
            reinvoke_args = f"{reinvoke_args} --convert-goto-to-structured"
            ai = ai + 1
            continue
        if arg == "--prefer-curly":
            eprint("error: --prefer-curly was renamed to --prefer-brace")
            return 1
        if arg == "--prefer-brace":
            migrate_set_block_style(2)
            reinvoke_args = f"{reinvoke_args} --prefer-brace"
            ai = ai + 1
            continue
        if arg == "--prefer-colon":
            migrate_set_block_style(0)
            reinvoke_args = f"{reinvoke_args} --prefer-colon"
            ai = ai + 1
            continue
        if arg == "--width-slice" and ai + 1 < argc:
            migrate_set_width_slice(cli_parse_small_int(with_arg_at(ai + 1)))
            reinvoke_args = f"{reinvoke_args} --width-slice {test_shell_quote(with_arg_at(ai + 1))}"
            ai = ai + 2
            continue
        if arg == "--shared-defs" and ai + 1 < argc:
            migrate_set_shared_defs(with_arg_at(ai + 1))
            reinvoke_args = f"{reinvoke_args} --shared-defs {test_shell_quote(with_arg_at(ai + 1))}"
            ai = ai + 2
            continue
        if arg == "--migrate-one" and ai + 1 < argc:
            migrate_set_directory_one_basename(with_arg_at(ai + 1))
            ai = ai + 2
            continue
        if arg == "--shared-fragment" and ai + 1 < argc:
            migrate_set_shared_fragment_path(with_arg_at(ai + 1))
            ai = ai + 2
            continue
        if arg == "--exclude" and ai + 1 < argc:
            exclude_basenames = exclude_basenames ++ "|" ++ with_arg_at(ai + 1) ++ "|"
            reinvoke_args = f"{reinvoke_args} --exclude {test_shell_quote(with_arg_at(ai + 1))}"
            ai = ai + 2
            continue
        if arg.len() > 10 and arg.slice(0, 10) == "--exclude=":
            exclude_basenames = exclude_basenames ++ "|" ++ arg.slice(10, arg.len()) ++ "|"
            reinvoke_args = f"{reinvoke_args} --exclude {test_shell_quote(arg.slice(10, arg.len()))}"
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
        migrate_set_reinvoke_args(reinvoke_args)
        return migrate_c_directory(source_path, output_path, exclude_basenames)

    // Single file mode — default output: replace .c with .w
    if output_path.len() == 0:
        if source_path.len() > 2 and source_path.slice(source_path.len() - 2, source_path.len()) == ".c":
            output_path = source_path.slice(0, source_path.len() - 2) ++ ".w"
        else:
            output_path = source_path ++ ".w"

    migrate_c_file(source_path, output_path)

fn cli_read_all_stdin() -> str:
    var out = ""
    while true:
        let chunk = with_read_bytes_stdin(4096)
        if chunk.len() == 0:
            return out
        out = out ++ chunk
        if chunk.len() < 4096:
            return out
    out

fn run_fmt_command(argc: i32) -> i32:
    let write_mode = cli_has_flag(argc, "-w")
    let list_mode = cli_has_flag(argc, "-l")
    let check_mode = cli_has_flag(argc, "--check")
    if cli_has_flag(argc, "--prefer-curly"):
        eprint("error: --prefer-curly was renamed to --prefer-brace")
        return 1
    let prefer_brace = cli_has_flag(argc, "--prefer-brace")
    let prefer_colon = cli_has_flag(argc, "--prefer-colon")
    var fmt_style = 0
    if prefer_brace: fmt_style = 2
    if prefer_colon: fmt_style = 1
    var files: Vec[str] = Vec.new()
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "-w" or arg == "-l" or arg == "--check" or arg == "--prefer-brace" or arg == "--prefer-colon":
            i = i + 1
            continue
        if with_str_starts_with(arg, "-") != 0:
            i = i + 1
            continue
        files.push(arg)
        i = i + 1
    if files.len() == 0:
        let source = cli_read_all_stdin()
        let formatted = format_source_styled(source, fmt_style)
        with_write(formatted)
        return 0
    var any_changed = false
    var fi = 0
    while fi < files.len() as i32:
        let path = files.get(fi as i64)
        let source = with_fs_read_file(path)
        let formatted = format_source_styled(source, fmt_style)
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
    with_write("Usage: with [command] [options]\n")
    with_write("\n")
    with_write("Commands:\n")
    with_write("\n")
    with_write("  build            Build a source file\n")
    with_write("  run              Build and run a source file\n")
    with_write("  check            Parse and type-check a source file\n")
    with_write("  test             Build and run tests\n")
    with_write("  bench            Build and run benchmarks\n")
    with_write("\n")
    with_write("  fmt              Format With source\n")
    with_write("  lsp              Start the language server\n")
    with_write("  migrate          Migrate C source to With\n")
    with_write("\n")
    with_write("  init             Initialize a With project\n")
    with_write("  get              Add a package dependency\n")
    with_write("  remove           Remove a package dependency\n")
    with_write("  clean            Delete build artifacts\n")
    with_write("\n")
    with_write("  ast              Parse and print the AST\n")
    with_write("  tokens           Lex and print tokens\n")
    with_write("  ir               Compile and print LLVM IR\n")
    with_write("\n")
    with_write("  version          Print version number and exit\n")
    with_write("  help             Print this help and exit\n")
    with_write("\n")
    with_write("General Options:\n")
    with_write("\n")
    with_write("  -e <code>        Compile and run code as top-level statements\n")
    with_write("  -n <code>        Run code for each stdin line as line/nr\n")
    with_write("  -p <code>        Like -n, then print line after each iteration\n")
    with_write("  -- <args>        Pass remaining args to one-liner args\n")
    with_write("  -h, --help       Print this help and exit\n")
    with_write("  -O0|-O1|-O2|-O3  Set optimization level\n")
    with_write("  -o <path>        Write output to path\n")
    with_write("  --release        Enable release defaults\n")
    with_write("  --emit-c         Emit C instead of a binary\n")
    with_write("  --emit-obj       Emit an object file instead of a binary\n")
    with_write("  --dump-project-info\n")
    with_write("                   Print resolved project metadata from 'check'\n")
    with_write("  --no-std         Disable standard library support\n")
    with_write("  --no-prelude     Disable implicit prelude import\n")
    with_write("  --prelude=<mode> Select prelude mode: full, core, none\n")
    with_write("  --freestanding   Alias for --no-std --no-prelude\n")

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
        "  fn let var if then else match for in while loop return break continue goto\n" ++
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
        " 12. unary: not - & &raw const &raw mut\n" ++
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

fn cli_parse_small_int(s: str) -> i32:
    var result = 0
    var i = 0
    let len = s.len() as i32
    while i < len:
        let ch = s.byte_at(i as i64)
        if ch >= 48 and ch <= 57:
            result = result * 10 + (ch - 48)
        i = i + 1
    result

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
    var created_path = target_dir
    if target_dir == ".":
        created_path = name

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
    var version_for_toml = "latest"
    if pkg_version.len() > 0:
        version_for_toml = pkg_version
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
