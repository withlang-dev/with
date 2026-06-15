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
use Sema
use Compilation
use ComptimeEval
use ComptimeValue
use ConanClient
use LockFile
use Fmt
use Lsp
use CiPrint
use CiMigrate
use BuildGraphKinds
use BuildGraphModel
use BuildGraphMaterialize
use BuildGraphDispatch
use BuildGraphOps
use BuildGraphSupport
use BuildGraphTools
use BuildGraphTests
use InitTemplates
use BuildGraphRuntime
use BuildGraphCache
use compiler.DriverOptions

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_is_dir(path: str) -> i32
extern fn with_fs_chmod(path: str, mode: i32) -> i32
extern fn with_read_bytes_stdin(count: i32) -> str
extern fn with_str_eq(a: str, b: str) -> i32
extern fn with_str_len(s: str) -> i64
extern fn with_str_byte_at(s: str, index: i64) -> i32
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_str_contains(s: str, needle: str) -> i32
extern fn with_str_slice(s: str, start: i64, end: i64) -> str
extern fn with_eprint(s: str) -> Unit
extern fn with_ewrite(s: str) -> Unit
extern fn with_exec_argv(args: str) -> i32
extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_fs_remove_tree(path: str) -> i32
extern fn with_fs_rename_file(old_path: str, new_path: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
// Used for unique temp paths in one-liners, build.w runner binaries,
// graph-tool captures, and native test captures.
extern fn with_clock_nanos() -> i64
extern fn with_getpid() -> i32
extern fn with_process_alive(pid: i32) -> i32
extern fn with_fs_mkdir(path: str) -> i32
extern fn with_write(s: str) -> Unit
extern fn with_read_line_stdin() -> str
extern fn exit(code: i32) -> Unit
extern fn with_install_interrupt_handlers() -> Unit
extern fn with_raise_stack_limit() -> Unit
extern fn with_sysinfo_os() -> str

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
    runtime_available: bool,
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
    expect_check_stdout: Vec[str],
    expect_check_stdout_not: Vec[str],
    expect_check_fail: str,
    expect_build_fail: str,
    has_expect_exit: bool,
    expect_exit: i32,
    check_only: bool,
    skip: bool,
    skip_reason: str,
    extra_args: str,
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

fn empty_test_discovery -> TestDiscovery:
    TestDiscovery { parse_ok: false, has_main: false, test_names: Vec.new() }

fn empty_test_directives -> TestDirectives:
    TestDirectives {
        expect_stdout: Vec.new(),
        expect_stderr: Vec.new(),
        expect_check_stdout: Vec.new(),
        expect_check_stdout_not: Vec.new(),
        expect_check_fail: "",
        expect_build_fail: "",
        has_expect_exit: false,
        expect_exit: 0,
        check_only: false,
        skip: false,
        skip_reason: "",
        extra_args: "",
    }

fn cli_options_default -> CliOptions:
    CliOptions {
        command: "",
        source_file: "",
        output_path: "",
        opt_level: 0,
        no_std: false,
        alloc_mode: false,
        runtime_available: true,
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
            mode = PreludeMode.CoreMode
        else if with_str_starts_with(arg, "--prelude=") != 0:
            let value = with_str_slice(arg, 10, with_str_len(arg))
            if value == "core":
                mode = PreludeMode.CoreMode
            else if value == "alloc":
                mode = PRELUDE_ALLOC()
            else if value == "full":
                mode = PreludeMode.FullMode
            else if value == "none":
                mode = PreludeMode.NoneMode
            else:
                with_eprint("error: invalid --prelude value '" ++ value ++ "' (expected full|alloc|core|none)")
                exit(1)
                return PreludeMode.FullMode
        i = i + 1
    mode

fn cli_runtime_available(argc: i32) -> bool:
    not cli_has_flag(argc, "--no-runtime") and not cli_has_flag(argc, "--freestanding")

fn parse_cli_options(argc: i32) -> CliOptions:
    var opts = cli_options_default()
    opts.command = cli_command(argc)
    opts.source_file = find_source_arg(argc)
    opts.output_path = find_output_arg(argc)
    opts.opt_level = cli_opt_level(argc)
    opts.no_std = cli_has_flag(argc, "--no-std") or cli_has_flag(argc, "--freestanding")
    opts.alloc_mode = cli_has_flag(argc, "--alloc")
    opts.runtime_available = cli_runtime_available(argc)
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
    arg == "-o" or arg == "--output" or arg == "--target"

fn cli_one_liner_known_flag(arg: str) -> bool:
    arg == "-O0" or arg == "-O1" or arg == "-O2" or arg == "-O3" or
    arg == "--release" or arg == "--alloc" or arg == "--no-std" or
    arg == "--no-runtime" or arg == "--freestanding" or arg == "--no-prelude" or
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
    var out = StringBuilder.with_capacity(value.len())
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 92:
            out.push_str("\\\\")
        else if ch == 34:
            out.push_str("\\\"")
        else if ch == 10:
            out.push_str("\\n")
        else if ch == 13:
            out.push_str("\\r")
        else if ch == 9:
            out.push_str("\\t")
        else:
            out.push_str(value.slice(i as i64, (i + 1) as i64))
    out.to_str()

fn cli_rewrite_semicolons(code: str) -> str:
    var lexer = Lexer.init(code, 0)
    let tokens = lexer.tokenize()
    var out = StringBuilder.with_capacity(code.len())
    var cursor = 0
    var depth = 0
    for i in 0..tokens.len():
        let tag = tokens.get_tag(i)
        if tag == TokenKind.TK_EOF:
            break
        if tag == TokenKind.TK_L_PAREN or tag == TokenKind.TK_L_BRACKET or tag == TokenKind.TK_L_BRACE:
            depth = depth + 1
            continue
        if tag == TokenKind.TK_R_PAREN or tag == TokenKind.TK_R_BRACKET or tag == TokenKind.TK_R_BRACE:
            if depth > 0:
                depth = depth - 1
            continue
        if tag != TokenKind.TK_SEMICOLON or depth != 0:
            continue
        let start = tokens.get_start(i)
        let end = tokens.get_end(i)
        if start > cursor:
            out.push_str(code.slice(cursor as i64, start as i64))
        out.push_str("\n")
        cursor = end
    if cursor < code.len() as i32:
        out.push_str(code.slice(cursor as i64, code.len()))
    out.to_str()

fn cli_indent_code(code: str, indent: str) -> str:
    var out = StringBuilder.with_capacity(code.len() + indent.len())
    out.push_str(indent)
    for i in 0..code.len() as i32:
        let ch = code.byte_at(i as i64)
        out.push_str(code.slice(i as i64, (i + 1) as i64))
        if ch == 10 and i + 1 < code.len() as i32:
            out.push_str(indent)
    out.to_str()

fn cli_one_liner_source_name(mode: i32, count: i32) -> str:
    let name = cli_one_liner_mode_name(mode)
    if count == 1:
        return "<cli " ++ name ++ " #1>"
    "<cli " ++ name ++ ">"

fn cli_build_args_binding(args: &Vec[str]) -> str:
    var out = StringBuilder.new()
    out.push_str("let args: Vec[str] = Vec.new()\n")
    for i in 0..args.len() as i32:
        let escaped = cli_escape_with_string(args.get(i as i64))
        out.push_str("args.push(\"")
        out.push_str(escaped)
        out.push_str("\")\n")
    out.to_str()

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

fn cli_build_synthetic_source(one: &CliOneLiner) -> CliSyntheticSource:
    var syn = cli_synthetic_source_new()
    var source = StringBuilder.new()
    source.push_str("use std.io\n")
    source.push_str("use std.str\n")
    source.push_str("use std.regex\n")
    source.push_str("use std.math\n")
    source.push_str("use std.collections\n")
    source.push_str("use std.builtins\n\n")
    source.push_str(cli_build_args_binding(one.args))
    if one.mode == CliOneLinerMode.Eval:
        for i in 0..one.code_parts.len() as i32:
            let rewritten = cli_rewrite_semicolons(one.code_parts.get(i as i64))
            let start = source.len() as i32
            source.push_str(rewritten)
            source.push_str("\n")
            syn = cli_synthetic_add_mapping(syn, start, rewritten, "<cli -e #" ++ f"{i + 1}" ++ ">")
        syn.source = source.to_str()
        return syn
    source.push_str("var nr: i64 = 0\n")
    if one.mode == CliOneLinerMode.Lines:
        source.push_str("for line in stdin.lines():\n")
        source.push_str("    nr = nr + 1\n")
        for i in 0..one.code_parts.len() as i32:
            let rewritten = cli_rewrite_semicolons(one.code_parts.get(i as i64))
            let indented = cli_indent_code(rewritten, "    ")
            let start = source.len() as i32 + 4
            source.push_str(indented)
            source.push_str("\n")
            syn = cli_synthetic_add_mapping(syn, start, rewritten, "<cli -n #" ++ f"{i + 1}" ++ ">")
        syn.source = source.to_str()
        return syn
    source.push_str("for __line in stdin.lines():\n")
    source.push_str("    nr = nr + 1\n")
    source.push_str("    var line = __line\n")
    for i in 0..one.code_parts.len() as i32:
        let rewritten = cli_rewrite_semicolons(one.code_parts.get(i as i64))
        let indented = cli_indent_code(rewritten, "    ")
        let start = source.len() as i32 + 4
        source.push_str(indented)
        source.push_str("\n")
        syn = cli_synthetic_add_mapping(syn, start, rewritten, "<cli -p #" ++ f"{i + 1}" ++ ">")
    source.push_str("    print(line)\n")
    syn.source = source.to_str()
    syn

fn cli_one_liner_bin_path -> str:
    f"out/tmp/with-cli-one-liner-{with_getpid()}-{with_clock_nanos()}"

fn run_one_liner_command(argc: i32, one: CliOneLiner, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32, debug_info: bool) -> i32:
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
    comp.configure(one.opt_level, no_std, alloc_mode, runtime_available)
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
    let rc = build_graph_rt_exec_binary(built)
    let _bin = build_graph_rt_remove_file(built)
    let _obj = build_graph_rt_remove_file(built ++ ".o")
    let _dsym = build_graph_rt_remove_tree(built ++ ".dSYM")
    rc

fn run_cli(argc: i32) -> i32:
    let opt_level = cli_opt_level(argc)
    let no_std = cli_has_flag(argc, "--no-std") or cli_has_flag(argc, "--freestanding")
    let alloc_mode = cli_has_flag(argc, "--alloc")
    let runtime_available = cli_runtime_available(argc)
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
        return run_one_liner_command(argc, one_liner, no_std, alloc_mode, runtime_available, prelude_mode, debug_info)

    // `with hello.w` is shorthand for `with run hello.w`
    if cli_is_implicit_run(argc):
        return run_run_command(cli_command(argc), "", opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info)

    if cli_command(argc) == "build":
        if cli_has_flag(argc, "--help") or cli_has_flag(argc, "-h"):
            print_build_usage()
            return 0
        let parsed_build = parse_build_command_options(argc)
        if not parsed_build.ok:
            with_eprint("error: " ++ parsed_build.error_msg)
            return 1
        return run_build_command(parsed_build.build, parsed_build.graph)
    if cli_command(argc) == "run":
        if emit_c_mode:
            with_eprint("error: '--emit-c' is only supported with 'build'")
            return 1
        return run_run_command(source, find_target_selector_arg(argc), opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info)
    if cli_command(argc) == "ir":
        if source == "":
            with_eprint("error: 'ir' requires a source file argument")
            return 1
        var comp = Compilation.init()
        comp.configure(opt_level, no_std, alloc_mode, runtime_available)
        comp.set_prelude_mode(prelude_mode)
        comp.set_overflow_mode(driver_internal_overflow_mode())
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
            return dump_resolved_artifact(source, no_std, alloc_mode, runtime_available, prelude_mode)
        if dump_typed_flag:
            return dump_typed_artifact(source, no_std, alloc_mode, runtime_available, prelude_mode)
        if dump_project_info_flag:
            return dump_project_info_artifact(source, no_std, alloc_mode, runtime_available, prelude_mode)
        if dump_mir_flag:
            return dump_mir_artifact(source, no_std, alloc_mode, runtime_available, prelude_mode)
        if dump_async_mir_flag:
            return dump_async_mir_artifact(source, no_std, alloc_mode, runtime_available, prelude_mode)
        var comp = Compilation.init()
        comp.configure(0, no_std, alloc_mode, runtime_available)
        comp.set_prelude_mode(prelude_mode)
        let pool = comp.compile_file(source)
        if pool.decl_count() == 0:
            with_eprint("error: check failed during compilation")
            return 1
        if not comp.check_pool(pool, source):
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
        if cli_has_flag(argc, "--help") or cli_has_flag(argc, "-h"):
            print_test_usage()
            return 0
        return run_test_command(argc, opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info)
    if cli_command(argc) == "bench":
        return run_bench_command(argc, opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info)
    if cli_command(argc) == "version" or cli_command(argc) == "--version":
        with_write("with WITH_VERSION_PLACEHOLDER\n")
        return 0
    if cli_command(argc) == "help" or cli_command(argc) == "--help" or cli_command(argc) == "-h":
        return run_help_command(argc)
    if cli_command(argc) == "clean":
        return run_clean_command()
    if cli_command(argc) == "install-user":
        return run_graph_target_command("install-user")
    if cli_command(argc) == "init":
        return run_init_command(argc)
    if cli_command(argc) == "get":
        return run_get_command(argc)
    if cli_command(argc) == "remove":
        return run_remove_command(argc)
    if cli_command(argc) == "update":
        return run_update_command(argc)
    if cli_command(argc) == "lsp":
        return run_lsp()
    if cli_command(argc) == "migrate":
        return run_migrate_command(argc)
    if cli_command(argc) == "repl":
        if cli_has_flag(argc, "--help") or cli_has_flag(argc, "-h"):
            print_repl_usage()
            return 0
        return run_repl_command(argc, no_std, alloc_mode, runtime_available, prelude_mode)
    if cli_command(argc) == "doc":
        if cli_has_flag(argc, "--help") or cli_has_flag(argc, "-h"):
            print_doc_usage()
            return 0
        return run_doc_command(argc, source, output, no_std, alloc_mode, runtime_available, prelude_mode)
    if cli_command(argc) == "fmt":
        return run_fmt_command(argc)
    let command = cli_command(argc)
    with_eprint("error: unknown command '" ++ command ++ "'")
    print_usage()
    1

fn main -> Unit:
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

fn find_target_selector_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if with_str_len(arg) > 1 and with_str_byte_at(arg, 0) == 58:
            return with_str_slice(arg, 1, with_str_len(arg))
        i = i + 1
    ""

fn cleanup_binary_artifacts(bin_path: str):
    if bin_path.len() == 0:
        return
    let _bin = build_graph_rt_remove_file(bin_path)
    let _dsym = build_graph_rt_remove_tree(bin_path ++ ".dSYM")

fn test_unique_binary_path(source_file: str) -> str:
    let base = link_stage_output_path_for_source(source_file)
    f"{base}.test.{with_getpid()}.{with_clock_nanos()}"

fn build_tool_eval_entry_source() -> str:
    "use std.build\n" ++
    "use build\n\n" ++
    "fn __with_build_eval_entry(ctx: BuildCtx) -> Build:\n" ++
    "    build(ctx)\n"

type BuildGraphLoadResult {
    graph: BuildGraph,
    sema: Sema,
}

type BuildActionRunResult {
    rc: i32,
    effects: Vec[str],
}

fn build_action_run_result(rc: i32) -> BuildActionRunResult:
    BuildActionRunResult { rc: rc, effects: Vec.new() }

fn build_action_run_result_with_effects(rc: i32, effects: Vec[str]) -> BuildActionRunResult:
    BuildActionRunResult { rc: rc, effects: effects }

fn build_action_safe_label(text: str) -> str:
    var out = ""
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        let keep = (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 45 or ch == 46 or ch == 95
        if keep:
            out = out ++ text.slice(i as i64, (i + 1) as i64)
        else:
            out = out ++ "_"
    if out.len() == 0:
        return "unknown"
    out

fn build_action_scratch_dir(target_name: str) -> str:
    "out/tmp/action-scratch/" ++ build_action_safe_label(target_name)

unsafe fn run_build_action_from_build_w(root: str, cfg: ProjectConfig, target: &BuildGraphTarget, sema_ptr: *mut Sema, strict_effects: bool) -> BuildActionRunResult:
    if target.output.len() == 0:
        with_eprint("error: action target '" ++ target.name ++ "' requires a declared output")
        return build_action_run_result(1)
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return build_action_run_result(arg_rc)
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: action target '" ++ target.name ++ "' missing declared input: " ++ input_path)
            return build_action_run_result(1)
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: action target '" ++ target.name ++ "' could not create output directory: " ++ output_dir)
        return build_action_run_result(1)
    let scratch_dir = build_action_scratch_dir(target.name)
    let scratch_abs = build_graph_resolve_project_path(root, scratch_dir)
    let _remove_scratch = with_fs_remove_tree(scratch_abs)
    if with_fs_mkdir_p(scratch_abs) != 0:
        with_eprint("error: action target '" ++ target.name ++ "' could not create scratch directory: " ++ scratch_dir)
        return build_action_run_result(1)
    if target.action_fn == 0:
        with_eprint("error: action target '" ++ target.name ++ "' is missing an evaluator action function")
        return build_action_run_result(1)
    let result = comptime_eval_tool_action_result(sema_ptr, (*sema_ptr).ast, (*sema_ptr).pool, target.action_fn, cfg.package_name, cfg.package_version, root, target.name, target.inputs, target.output, target.extra_outputs, target.args, target.write_scopes, target.timeout_ms, target.cwd, target.env, target.network, if strict_effects: 1 else: 0)
    if result.runtime_exit_code != 0:
        if result.runtime_stderr.len() > 0:
            with_ewrite(result.runtime_stderr)
        with_eprint("error: action target '" ++ target.name ++ f"' failed with exit code {result.runtime_exit_code}")
        return build_action_run_result_with_effects(result.runtime_exit_code, result.effect_records)
    if result.error_msg.len() > 0:
        with_eprint("error: action target '" ++ target.name ++ "' failed during comptime evaluation: " ++ result.error_msg ++ "\n")
        return build_action_run_result_with_effects(1, result.effect_records)
    if result.value.kind != ComptimeValueKind.CV_INT and result.value.kind != ComptimeValueKind.CV_BOOL:
        with_eprint("error: action target '" ++ target.name ++ "' did not return an integer exit code")
        return build_action_run_result_with_effects(1, result.effect_records)
    let rc = result.value.data0 as i32
    if rc != 0:
        with_eprint("error: action target '" ++ target.name ++ f"' failed with exit code {rc}")
        return build_action_run_result_with_effects(rc, result.effect_records)
    if with_fs_file_exists(output_path) == 0:
        with_eprint("error: action target '" ++ target.name ++ "' did not produce declared output: " ++ output_path)
        return build_action_run_result_with_effects(1, result.effect_records)
    for oi in 0..target.extra_outputs.len() as i32:
        let extra_output = build_graph_resolve_project_path(root, target.extra_outputs.get(oi as i64))
        if with_fs_file_exists(extra_output) == 0:
            with_eprint("error: action target '" ++ target.name ++ "' did not produce declared output: " ++ extra_output)
            return build_action_run_result_with_effects(1, result.effect_records)
    build_action_run_result_with_effects(0, result.effect_records)

fn load_build_graph_from_build_w(root: str, cfg: &ProjectConfig, options: &BuildCommandOptions) -> BuildGraphLoadResult:
    var graph = empty_build_graph()
    let entry_path = resolve_join(root, "__with_build_eval.w")
    var comp = Compilation.init()
    comp.configure_options(build_command_options_clone(options))
    comp.set_tool_mode_entry_path(entry_path)
    let compile_cfg = project_config_clone(cfg)
    let pool = comp.compile_source_text_with_config(entry_path, build_tool_eval_entry_source(), compile_cfg)
    var sema = comp.zcu.last_sema
    if pool.decl_count() == 0 or comp.has_errors():
        graph.error_msg = "build.w evaluation wrapper compilation failed"
        return BuildGraphLoadResult { graph, sema }
    let entry_sym = sema.pool_lookup_symbol("__with_build_eval_entry")
    if entry_sym == 0:
        graph.error_msg = "build.w evaluation entry was not typechecked"
        return BuildGraphLoadResult { graph, sema }
    let eval_result = unsafe { comptime_eval_tool_build_result(&raw mut sema as *mut Sema, sema.ast, sema.pool, entry_sym, cfg.package_name, cfg.package_version, root, if options.strict_effects: 1 else: 0) }
    if eval_result.error_msg.len() > 0:
        graph.ok = false
        graph.error_msg = eval_result.error_msg
        return BuildGraphLoadResult { graph, sema }
    let materialized = materialize_build_graph_from_comptime(sema, eval_result.value, eval_result.extras)
    build_cache_record_build_effects(root, eval_result.effect_records)
    BuildGraphLoadResult { graph: materialized.graph, sema: materialized.sema }

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

fn build_graph_restore_env(name: str, old_value: str) -> i32:
    with_setenv_str(name, old_value)

fn build_graph_trim_trailing_line_endings(text: str) -> str:
    var end = text.len() as i32
    while end > 0:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(0, end as i64)

fn build_graph_find_substr(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    if text.len() < needle.len():
        return -1
    let last = text.len() as i32 - needle.len() as i32
    for i in 0..(last + 1):
        var matched = true
        for j in 0..needle.len() as i32:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
        if matched:
            return i
    -1

fn build_graph_replace_once(text: str, needle: str, replacement: str) -> str:
    let at = build_graph_find_substr(text, needle)
    if at < 0:
        return ""
    text.slice(0, at as i64) ++ replacement ++ text.slice((at + needle.len() as i32) as i64, text.len())

fn build_graph_run_tool_capture(root: str, target: &BuildGraphTarget, tool_name: str, argv: str, timeout_ms: i32) -> i32:
    let capture_dir = resolve_join(resolve_join(root, "out/test-graph"), target.name)
    if with_fs_mkdir_p(capture_dir) != 0:
        with_eprint("error: could not create tool capture directory for target '" ++ target.name ++ "': " ++ capture_dir)
        return 1
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let stdout_path = resolve_join(capture_dir, tool_name ++ "." ++ stamp ++ ".stdout")
    let stderr_path = resolve_join(capture_dir, tool_name ++ "." ++ stamp ++ ".stderr")
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    if rc == 124:
        with_eprint("error: " ++ tool_name ++ " for target '" ++ target.name ++ f"' timed out after {timeout_ms}ms; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        with_eprint("error: " ++ tool_name ++ " for target '" ++ target.name ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return rc
    let _remove_stdout = with_fs_remove_file(stdout_path)
    let _remove_stderr = with_fs_remove_file(stderr_path)
    0

fn build_graph_run_cli_capture(root: str, target: &BuildGraphTarget, compiler_path: str, label: str, argv_tail: str, timeout_ms: i32) -> TestRunResult:
    let capture_dir = resolve_join(resolve_join(root, "out/test-graph"), target.name)
    let _mkdir = with_fs_mkdir_p(capture_dir)
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let stdout_path = resolve_join(capture_dir, label ++ "." ++ stamp ++ ".stdout")
    let stderr_path = resolve_join(capture_dir, label ++ "." ++ stamp ++ ".stderr")
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = argv ++ argv_tail
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
    let stdout = with_fs_read_file(stdout_path)
    let stderr = with_fs_read_file(stderr_path)
    let _ = label
    if rc == 0:
        let _remove_stdout = with_fs_remove_file(stdout_path)
        let _remove_stderr = with_fs_remove_file(stderr_path)
    TestRunResult { rc, stdout, stderr }

fn build_graph_trim_space_and_newlines(text: str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn build_options_for_graph_target(root: str, base: &BuildCommandOptions, target: &BuildGraphTarget) -> BuildCommandOptions:
    var options = build_command_options_clone(base)
    if target.optimize_mode == 1 and options.opt_level < 2:
        options.opt_level = 2
    options.target_kind = target.target_kind
    options.include_paths = build_graph_resolve_paths(root, target.include_paths)
    options.defines = build_graph_clone_strings(&target.defines)
    options.link_libs = build_graph_clone_strings(&target.system_libs)
    if target.kind == 1 or target.kind == 4:
        options.output_kind = BuildOutputKind.Archive
    else if target.kind == 3:
        options.output_kind = BuildOutputKind.Object
    else:
        options.output_kind = BuildOutputKind.Binary
    options

unsafe fn run_build_graph(root: str, cfg: ProjectConfig, graph: &BuildGraph, action_sema: *mut Sema, options: &BuildCommandOptions) -> i32:
    if graph.targets.len() == 0:
        with_eprint("error: build.w did not declare any targets")
        return 1
    let output_rc = build_graph_validate_outputs(root, graph, options.output_path)
    if output_rc != 0:
        return output_rc
    let generated_rc = build_graph_write_generated_sources(root, graph)
    if generated_rc != 0:
        return generated_rc
    let completed_targets: Vec[str] = Vec.new()
    let skipped_targets: Vec[str] = Vec.new()
    for ti in 0..graph.targets.len() as i32:
        let target = graph.targets.get(ti as i64)
        if build_graph_kind_removed(target.kind):
            with_eprint("error: build.w target kind " ++ build_graph_kind_name(target.kind) ++ f" ({target.kind}) was removed; regenerate your build graph")
            return 1
        if not build_graph_kind_valid(target.kind):
            with_eprint("error: invalid build.w target kind " ++ build_graph_kind_name(target.kind) ++ " for '" ++ target.name ++ "'")
            return 1
        if not build_graph_kind_implemented(target.kind):
            with_eprint("error: build.w target kind '" ++ build_graph_kind_name(target.kind) ++ "' is not implemented yet for '" ++ target.name ++ "'")
            return 1
        if not build_graph_target_valid(target.target_kind):
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
        var dep_rebuilt = false
        for di in 0..target.deps.len() as i32:
            let dep_name = target.deps.get(di as i64)
            if not skipped_targets.contains(dep_name):
                if completed_targets.contains(dep_name):
                    dep_rebuilt = true
                    break
        if target.kind == 9:
            if not dep_rebuilt:
                skipped_targets.push(target.name)
            completed_targets.push(target.name)
            continue
        if build_cache_is_cacheable(target.kind):
            if build_cache_check_fresh(root, target, dep_rebuilt):
                skipped_targets.push(target.name)
                completed_targets.push(target.name)
                continue
        let standard_result = build_graph_dispatch_standard_target(root, target, completed_targets)
        if standard_result.handled:
            if standard_result.rc != 0:
                return standard_result.rc
            build_cache_record(root, target, Vec.new(), Vec.new())
            completed_targets.push(target.name)
            continue
        if target.kind == 23:
            let action_result = run_build_action_from_build_w(root, cfg, target, action_sema, options.strict_effects)
            if action_result.rc != 0:
                return action_result.rc
            build_cache_record(root, target, Vec.new(), action_result.effects)
            completed_targets.push(target.name)
            continue
        let source_path = resolve_join(root, target.entry)
        let target_options = build_options_for_graph_target(root, options, &target)
        if target.kind == 2:
            if options.output_path.len() > 0:
                with_eprint("error: -o cannot be used with build.w test target '" ++ target.name ++ "'")
                return 1
            let test_files = build_graph_test_target_files(root, target.entry)
            if test_files.len() == 0:
                with_eprint("error: build.w test target matched no files: " ++ target.entry)
                return 1
            let test_compiler = build_graph_test_compiler(root, target)
            if test_compiler.len() > 0:
                let test_rc = build_graph_run_external_test_files(root, target, test_compiler, test_files)
                if test_rc != 0:
                    with_eprint("error: build.w test target failed: " ++ target.name)
                    return test_rc
            else:
                for fi in 0..test_files.len() as i32:
                    let test_path = test_files.get(fi as i64)
                    let test_rc = run_test_file_with_build_settings(test_path, target_options.opt_level, target_options.no_std, target_options.alloc_mode, target_options.runtime_available, target_options.prelude_mode, target_options.debug_info, false, false, "", target_options.include_paths, target_options.defines, target_options.link_libs)
                    if test_rc != 0:
                        with_eprint("error: build.w test target failed: " ++ target.name)
                        return test_rc
            if build_graph_path_has_glob(target.entry):
                with_write(f"ok: {test_files.len()} files passed in build.w test target {target.name}\n")
            build_cache_record_test_success(root, target, test_files, test_compiler)
            completed_targets.push(target.name)
            continue
        if target.kind == 1:
            let ar_path = build_graph_library_output_path(root, target, options.output_path, graph.targets.len() as i32)
            if ar_path.len() == 0:
                with_eprint("error: -o cannot be used when build.w declares multiple targets")
                return 1
            var comp = Compilation.init()
            comp.configure_options(target_options)
            let built = comp.emit_archive_to_path_with_build_settings(source_path, ar_path, target_options.include_paths, target_options.defines, target_options.link_libs)
            if built == "":
                with_eprint("error: build.w library target failed: " ++ target.name)
                return 1
            comp.print_warnings()
            build_cache_record(root, target, comp.tracked_input_paths(), Vec.new())
            completed_targets.push(target.name)
            continue
        if target.kind == 3:
            let obj_path = build_graph_object_output_path(root, target, options.output_path, graph.targets.len() as i32)
            if obj_path.len() == 0:
                with_eprint("error: -o cannot be used when build.w declares multiple targets")
                return 1
            var comp = Compilation.init()
            comp.configure_options(target_options)
            let built = comp.emit_object_to_path_with_build_settings(source_path, obj_path, target_options.include_paths, target_options.defines, target_options.link_libs)
            if built == "":
                with_eprint("error: build.w object target failed: " ++ target.name)
                return 1
            comp.print_warnings()
            build_cache_record(root, target, comp.tracked_input_paths(), Vec.new())
            completed_targets.push(target.name)
            continue
        if target.kind == 4:
            let ar_path = build_graph_library_output_path(root, target, options.output_path, graph.targets.len() as i32)
            if ar_path.len() == 0:
                with_eprint("error: -o cannot be used when build.w declares multiple targets")
                return 1
            var comp = Compilation.init()
            comp.configure_options(target_options)
            let built = comp.emit_archive_to_path_with_build_settings(source_path, ar_path, target_options.include_paths, target_options.defines, target_options.link_libs)
            if built == "":
                with_eprint("error: build.w archive target failed: " ++ target.name)
                return 1
            comp.print_warnings()
            build_cache_record(root, target, comp.tracked_input_paths(), Vec.new())
            completed_targets.push(target.name)
            continue
        let bin_path = build_graph_output_path(root, target, options.output_path, graph.targets.len() as i32)
        if bin_path.len() == 0:
            with_eprint("error: -o cannot be used when build.w declares multiple targets")
            return 1
        var comp = Compilation.init()
        comp.configure_options(target_options)
        let built = comp.build_binary_to_path_with_build_settings(source_path, bin_path, target_options.include_paths, target_options.defines, target_options.link_libs)
        if built == "":
            with_eprint("error: build.w target failed: " ++ target.name)
            return 1
        comp.print_warnings()
        build_cache_record(root, target, comp.tracked_input_paths(), Vec.new())
        completed_targets.push(target.name)
    0

fn explain_kind_name(kind: i32) -> str:
    if kind == 0: return "Executable"
    if kind == 1: return "Library"
    if kind == 2: return "Test"
    if kind == 3: return "Object"
    if kind == 4: return "Archive"
    if kind == 7: return "Command"
    if kind == 8: return "Install"
    if kind == 9: return "Group"
    if kind == 10: return "BinaryCompare"
    if kind == 11: return "FixpointCompare"
    if kind == 12: return "CompileCObject"
    if kind == 13: return "CompileAsmObject"
    if kind == 14: return "CompileLlvmIrObject"
    if kind == 15: return "CreateStaticArchive"
    if kind == 16: return "GenerateResponseFile"
    if kind == 17: return "EmbedObjectFiles"
    if kind == 18: return "CopyTree"
    if kind == 19: return "RunCorpusTest"
    if kind == 20: return "PromoteTreeIfVerified"
    if kind == 21: return "Clean"
    if kind == 22: return "CopyFile"
    if kind == 23: return "Action"
    f"Unknown({kind})"

fn explain_build_target(graph: &BuildGraph, name: str) -> i32:
    var found = false
    for i in 0..graph.targets.len() as i32:
        let target = graph.targets.get(i as i64)
        if target.name == name:
            found = true
            with_write("target: " ++ target.name ++ "\n")
            with_write("  kind: " ++ explain_kind_name(target.kind) ++ "\n")
            if target.entry.len() > 0:
                with_write("  entry: " ++ target.entry ++ "\n")
            if target.output.len() > 0:
                with_write("  output: " ++ target.output ++ "\n")
            if target.deps.len() > 0:
                with_write("  deps:\n")
                for j in 0..target.deps.len() as i32:
                    with_write("    - " ++ target.deps.get(j as i64) ++ "\n")
            if target.inputs.len() > 0:
                with_write("  inputs:\n")
                for j in 0..target.inputs.len() as i32:
                    with_write("    - " ++ target.inputs.get(j as i64) ++ "\n")
            if target.extra_outputs.len() > 0:
                with_write("  extra_outputs:\n")
                for j in 0..target.extra_outputs.len() as i32:
                    with_write("    - " ++ target.extra_outputs.get(j as i64) ++ "\n")
            if target.args.len() > 0:
                with_write("  args:\n")
                for j in 0..target.args.len() as i32:
                    with_write("    - " ++ target.args.get(j as i64) ++ "\n")
            if target.timeout_ms != 0:
                with_write(f"  timeout_ms: {target.timeout_ms}\n")
            if target.cwd.len() > 0:
                with_write("  cwd: " ++ target.cwd ++ "\n")
            if target.env.len() > 0:
                with_write("  env:\n")
                for j in 0..target.env.len() as i32:
                    with_write("    - " ++ target.env.get(j as i64) ++ "\n")
            if target.network != 0:
                with_write("  network: true\n")
            break
    if not found:
        with_eprint("error: target '" ++ name ++ "' not found in build graph\n")
        with_eprint("available targets:\n")
        for i in 0..graph.targets.len() as i32:
            let target = graph.targets.get(i as i64)
            with_eprint("  " ++ target.name ++ " (" ++ explain_kind_name(target.kind) ++ ")\n")
        return 1
    0

fn run_graph_target_command(target_name: str) -> i32:
    let build_options = build_command_options_default()
    var graph_options = build_graph_command_options_default()
    graph_options.selected_target = target_name
    run_build_command(build_options, graph_options)

fn build_graph_find_target_by_name(graph: &BuildGraph, target_name: str) -> BuildGraphTarget:
    for i in 0..graph.targets.len() as i32:
        let target = graph.targets.get(i as i64)
        if target.name == target_name:
            return target
    empty_build_graph_target()

fn repo_lock_path() -> str:
    let out_dir = with_getenv_str("WITH_OUT_DIR")
    let base = if out_dir.len() > 0: out_dir else: "out"
    base ++ "/tmp/repo-serial.lock"

fn repo_lock_owner_path() -> str:
    repo_lock_path() ++ "/owner"

fn repo_lock_parse_pid(owner: str) -> i32:
    var start = -1
    for i in 0..(owner.len() as i32 - 4):
        if owner.slice(i as i64, (i + 4) as i64) == "pid=":
            start = i + 4
            break
    if start < 0:
        return -1
    var end = start
    while end < owner.len() as i32:
        let ch = owner.byte_at(end as i64)
        if ch < 48 or ch > 57:
            break
        end = end + 1
    if end == start:
        return -1
    var pid = 0
    for i in start..end:
        pid = pid * 10 + (owner.byte_at(i as i64) - 48)
    pid

fn repo_lock_acquire(target_name: str) -> bool:
    if with_getenv_str("WITH_REPO_LOCKED").len() > 0:
        return true
    let lock_dir = repo_lock_path()
    let parent = lock_dir.slice(0, lock_dir.len() - "/repo-serial.lock".len())
    let _ = with_fs_mkdir_p(parent)
    let rc = with_fs_mkdir(lock_dir)
    if rc == 0:
        let owner_file = repo_lock_owner_path()
        let pid = with_getpid()
        let _ = with_fs_write_file(owner_file, f"target={target_name} pid={pid}")
        let _ = with_setenv_str("WITH_REPO_LOCKED", "1")
        return true
    if with_fs_file_exists(repo_lock_owner_path()) != 0:
        let owner = with_fs_read_file(repo_lock_owner_path())
        let owner_pid = repo_lock_parse_pid(owner)
        if owner_pid > 0 and owner_pid == with_getpid():
            return true
        if owner_pid > 0 and with_process_alive(owner_pid) == 0:
            let _ = with_fs_remove_tree(lock_dir)
            let rc2 = with_fs_mkdir(lock_dir)
            if rc2 == 0:
                let pid = with_getpid()
                let _ = with_fs_write_file(repo_lock_owner_path(), f"target={target_name} pid={pid}")
                let _ = with_setenv_str("WITH_REPO_LOCKED", "1")
                return true
        with_eprint("error: another build is already running: " ++ owner ++ "\n")
    else:
        with_eprint("error: could not acquire build lock\n")
    false

fn repo_lock_release():
    let lock_dir = repo_lock_path()
    if with_fs_file_exists(repo_lock_owner_path()) != 0:
        let owner = with_fs_read_file(repo_lock_owner_path())
        let owner_pid = repo_lock_parse_pid(owner)
        if owner_pid == with_getpid():
            let _ = with_fs_remove_tree(lock_dir)

fn build_command_apply_project_target_default(options: BuildCommandOptions, cfg: &ProjectConfig) -> BuildCommandOptions:
    var out = options
    if not out.target_explicit and cfg.target_default.len() > 0:
        out.target_kind = driver_target_triple_kind(cfg.target_default)
    if cfg.strict_effects:
        out.strict_effects = true
    out

fn build_command_validate_target(options: &BuildCommandOptions, cfg: &ProjectConfig) -> i32:
    if options.target_kind < 0:
        with_eprint("error: invalid with.toml: unsupported target.default '" ++ cfg.target_default ++ "'")
        return 1
    // §18.5: non-native target selections must fail loudly until
    // cross-target codegen/linking exists; never fall back to native.
    if not build_graph_target_is_host(options.target_kind):
        with_eprint("error: cross-target build for '" ++ build_graph_target_name(options.target_kind) ++ "' is not implemented yet; host is " ++ build_graph_target_name(build_graph_host_target_kind()))
        return 1
    0

fn run_build_command(options: BuildCommandOptions, graph_options: BuildGraphCommandOptions) -> i32:
    var actual_options = options
    var actual_source = actual_options.source_path
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
        actual_options = build_command_apply_project_target_default(actual_options, cfg)
        if build_command_validate_target(actual_options, cfg) != 0:
            return 1
        if project_config_file_exists(build_path):
            if actual_options.output_kind != BuildOutputKind.Binary:
                with_eprint("error: build.w tool-mode only supports binary builds")
                return 1
            var load_result = load_build_graph_from_build_w(root, &cfg, &actual_options)
            let graph = load_result.graph
            if not graph.ok:
                with_eprint("error: " ++ graph.error_msg)
                return 1
            if graph_options.selected_target == "effects":
                return build_cache_print_effects(root, graph, "")
            var selected_target_name = graph_options.selected_target
            if selected_target_name.len() == 0 and graph.default_target.len() > 0:
                selected_target_name = graph.default_target
            let selected_graph = if graph_options.no_deps: build_graph_filter_single_target(&graph, selected_target_name) else: build_graph_filter_target(&graph, selected_target_name)
            if not selected_graph.ok:
                with_eprint("error: " ++ selected_graph.error_msg)
                return 1
            if graph_options.no_deps:
                if selected_graph.targets.len() == 0 or selected_graph.targets.get(0).kind != 23:
                    with_eprint("error: --no-deps is only supported for build.w action targets")
                    return 1
            if graph_options.explain_target.len() > 0:
                return explain_build_target(&graph, graph_options.explain_target)
            if graph_options.graph_only or graph_options.dry_run:
                with_write(selected_graph.raw_text)
                return 0
            if not repo_lock_acquire(selected_target_name):
                return 1
            let build_rc = unsafe { run_build_graph(root, cfg, selected_graph, &raw mut load_result.sema as *mut Sema, actual_options) }
            repo_lock_release()
            link_stage_cleanup_current_process_temp_archives()
            return build_rc
        let root_main = root ++ "/main.w"
        actual_source = if with_fs_file_exists(root_main) != 0: root_main else: root ++ "/src/main.w"
        actual_options.source_path = actual_source
        if actual_options.output_path == "" and cfg.package_name.len() > 0:
            actual_options.output_path = "out/bin/" ++ cfg.package_name
    else:
        let cfg = project_config_load_for_source(actual_source)
        if cfg.manifest_error.len() > 0:
            with_eprint("error: invalid with.toml: " ++ cfg.manifest_error)
            return 1
        actual_options = build_command_apply_project_target_default(actual_options, cfg)
        if build_command_validate_target(actual_options, cfg) != 0:
            return 1
    if graph_options.no_deps:
        with_eprint("error: --no-deps is only supported for build.w action targets")
        return 1
    var comp = Compilation.init()
    comp.configure_options(actual_options)
    if actual_options.output_kind == BuildOutputKind.C:
        let c_path = comp.emit_c(actual_options.source_path, actual_options.output_path)
        if c_path == "":
            with_eprint("error: build failed")
            link_stage_cleanup_current_process_temp_archives()
            return 1
        with_eprint("emitted C: " ++ c_path)
        with_eprint("compile with a C compiler (example):")
        with_eprint("  cc -I runtime " ++ c_path ++ " runtime/with_runtime.c runtime/helpers.c runtime/fiber.c runtime/fiber_asm_<arch>.s -o <output>")
        comp.print_warnings()
        link_stage_cleanup_current_process_temp_archives()
        return 0
    if actual_options.output_kind == BuildOutputKind.Object:
        var obj_path = actual_options.output_path
        if obj_path == "":
            obj_path = link_stage_output_path_for_source(actual_options.source_path) ++ ".o"
        let result = comp.emit_object_to_path(actual_options.source_path, obj_path)
        if result == "":
            with_eprint("error: build failed")
            link_stage_cleanup_current_process_temp_archives()
            return 1
        comp.print_warnings()
        link_stage_cleanup_current_process_temp_archives()
        return 0
    let bin_path = comp.build_binary_to_path(actual_options.source_path, actual_options.output_path)
    if bin_path == "":
        with_eprint("error: build failed")
        link_stage_cleanup_current_process_temp_archives()
        return 1
    comp.print_warnings()
    link_stage_cleanup_current_process_temp_archives()
    0

fn run_run_project_command(selected_target_hint: str, opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32, debug_info: bool) -> i32:
    let root = build_graph_find_build_root(".")
    if root.len() == 0:
        with_eprint("error: 'run' requires a source file argument, build.w, or a with.toml project")
        return 1
    let build_path = resolve_join(root, "build.w")
    if not project_config_file_exists(build_path):
        with_eprint("error: 'run' requires a source file argument or build.w project")
        return 1
    let cfg = project_config_load_for_source(root ++ "/src/main.w")
    if cfg.manifest_error.len() > 0:
        with_eprint("error: invalid with.toml: " ++ cfg.manifest_error)
        return 1
    var options = build_command_options_default()
    options.opt_level = opt_level
    options.no_std = no_std
    options.alloc_mode = alloc_mode
    options.runtime_available = runtime_available
    options.prelude_mode = prelude_mode
    options.debug_info = debug_info
    var load_result = load_build_graph_from_build_w(root, &cfg, &options)
    let graph = load_result.graph
    if not graph.ok:
        with_eprint("error: " ++ graph.error_msg)
        return 1
    var selected_target_name = selected_target_hint
    if selected_target_name.len() == 0:
        selected_target_name = graph.default_target
    if selected_target_name.len() == 0:
        with_eprint("error: 'run' needs an executable default target in build.w or ':target'")
        return 1
    let selected_target = build_graph_find_target_by_name(&graph, selected_target_name)
    if selected_target.name.len() == 0:
        with_eprint("error: target '" ++ selected_target_name ++ "' not found in build graph")
        return 1
    if selected_target.kind != 0:
        with_eprint("error: run target '" ++ selected_target_name ++ "' is not executable")
        return 1
    let selected_graph = build_graph_filter_target(&graph, selected_target_name)
    if not selected_graph.ok:
        with_eprint("error: " ++ selected_graph.error_msg)
        return 1
    if not repo_lock_acquire(selected_target_name):
        return 1
    let build_rc = unsafe { run_build_graph(root, cfg, selected_graph, &raw mut load_result.sema as *mut Sema, options) }
    repo_lock_release()
    if build_rc != 0:
        return build_rc
    let selected_built_target = build_graph_find_target_by_name(&selected_graph, selected_target_name)
    let bin_path = build_graph_output_path(root, selected_built_target, "", selected_graph.targets.len() as i32)
    if bin_path.len() == 0 or with_fs_file_exists(bin_path) == 0:
        with_eprint("error: run target '" ++ selected_target_name ++ "' did not produce executable output")
        return 1
    build_graph_rt_exec_binary(bin_path)

fn run_run_command(source_file: str, selected_target_hint: str, opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32, debug_info: bool) -> i32:
    if source_file == "":
        return run_run_project_command(selected_target_hint, opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info)
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode, runtime_available)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    let bin_path = comp.build_binary(source_file)
    if bin_path == "":
        with_eprint("error: run failed")
        return 1
    comp.print_warnings()
    let run_rc = build_graph_rt_exec_binary(bin_path)
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

fn dump_resolved_artifact(source_file: str, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode, runtime_available)
    comp.set_prelude_mode(prelude_mode)
    let result = comp.resolve_file(source_file, true)
    let has_errors = comp.has_errors()
    if has_errors:
        with_eprint("error: resolved dump failed")
        return 1
    let resolved_text = dump_resolved(result, comp.get_pool(), source_file)
    with_write(resolved_text)
    0

fn dump_typed_artifact(source_file: str, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode, runtime_available)
    comp.set_prelude_mode(prelude_mode)
    let typed_ok = comp.emit_typed_file(source_file)
    if not typed_ok:
        with_eprint("error: typed dump failed during compilation or semantic analysis")
        return 1
    0

fn dump_project_info_artifact(source_file: str, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode, runtime_available)
    comp.set_prelude_mode(prelude_mode)
    let text = comp.dump_project_info_file(source_file)
    if text.len() == 0:
        with_eprint("error: project info dump failed")
        return 1
    with_write(text)
    0

fn dump_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode, runtime_available)
    comp.set_prelude_mode(prelude_mode)
    let mir_ok = comp.print_mir_file(source_file)
    if not mir_ok:
        with_eprint("error: mir dump failed during compilation or mir lowering")
        return 1
    0

fn dump_async_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode, runtime_available)
    comp.set_prelude_mode(prelude_mode)
    let async_mir_text = comp.dump_async_mir_file(source_file)
    if async_mir_text.len() == 0:
        with_eprint("error: async-mir dump failed during compilation or lowering")
        return 1
    with_write(async_mir_text)
    0

fn escape_dump_lexeme(text: str) -> str:
    var out = StringBuilder.with_capacity(text.len())
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
            out.push_str(text.slice(run_start as i64, i as i64))
        out.push_str(esc)
        run_start = i + 1
    // Flush any remaining non-special run.
    if run_start < text.len():
        out.push_str(text.slice(run_start as i64, text.len()))
    out.to_str()

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
    var out = StringBuilder.with_capacity(text.len())
    out.push_str(text)
    if text.len() > 0 and with_str_byte_at(text, with_str_len(text) - 1) != 10:
        out.push_str("\n")
    out.push_str("\nuse std.process\n")
    out.push_str("use test.bench\n")
    out.push_str("\nfn main:\n")
    out.push_str("    let __with_bench_filter = env(\"WITH_BENCH_FILTER\")\n")
    for bi in 0..bench_names.len() as i32:
        let bench_name = bench_names.get(bi as i64)
        out.push_str("    if __with_bench_filter.len() == 0 or \"")
        out.push_str(bench_name)
        out.push_str("\".contains(__with_bench_filter):\n")
        out.push_str("        var __b = Bench.new()\n")
        out.push_str("        __b.run(")
        out.push_str(bench_name)
        out.push_str(")\n")
        out.push_str("        __b.report(\"")
        out.push_str(bench_name)
        out.push_str("\")\n")
    out.to_str()

fn synthesize_test_main_source(text: str, test_names: Vec[str]) -> str:
    var out = StringBuilder.with_capacity(text.len())
    out.push_str(text)
    if text.len() > 0 and with_str_byte_at(text, with_str_len(text) - 1) != 10:
        out.push_str("\n")
    out.push_str("\nuse std.process\n")
    out.push_str("\nfn __with_test_eq(a: str, b: str) -> bool:\n")
    out.push_str("    a == b\n")
    out.push_str("\nfn main:\n")
    out.push_str("    let __with_test_filter = env(\"WITH_TEST_FILTER\")\n")
    out.push_str("    if __with_test_filter.len() > 0:\n")
    for ti in 0..test_names.len() as i32:
        let test_name = test_names.get(ti as i64)
        var prefix = "        else if "
        if ti == 0:
            prefix = "        if "
        out.push_str(prefix)
        out.push_str("__with_test_eq(__with_test_filter, \"")
        out.push_str(test_name)
        out.push_str("\"):\n")
        out.push_str("            ")
        out.push_str(test_name)
        out.push_str("()\n")
        out.push_str("            return\n")
    out.push_str("        else:\n")
    out.push_str("            exit_code(1)\n")
    for ti in 0..test_names.len() as i32:
        out.push_str("    ")
        out.push_str(test_names.get(ti as i64))
        out.push_str("()\n")
    out.to_str()

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
    let expect_check_stdout_prefix = "//! expect-check-stdout: "
    let expect_check_stdout_not_prefix = "//! expect-check-stdout-not: "
    let expect_check_fail_prefix = "//! expect-check-fail: "
    let expect_error_prefix = "//! expect-error: "
    let expect_build_fail_prefix = "//! expect-build-fail: "
    let args_prefix = "//! args: "
    let skip_prefix = "//! skip: "
    let skip_windows_prefix = "//! skip-windows: "
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
            else if with_str_starts_with(line, expect_check_stdout_prefix) != 0:
                result.expect_check_stdout.push(line.slice(expect_check_stdout_prefix.len(), line.len()))
            else if with_str_starts_with(line, expect_check_stdout_not_prefix) != 0:
                result.expect_check_stdout_not.push(line.slice(expect_check_stdout_not_prefix.len(), line.len()))
            else if with_str_starts_with(line, expect_check_fail_prefix) != 0:
                result.expect_check_fail = line.slice(expect_check_fail_prefix.len(), line.len())
            else if with_str_starts_with(line, expect_error_prefix) != 0:
                result.expect_check_fail = line.slice(expect_error_prefix.len(), line.len())
            else if with_str_starts_with(line, expect_build_fail_prefix) != 0:
                result.expect_build_fail = line.slice(expect_build_fail_prefix.len(), line.len())
            else if with_str_starts_with(line, args_prefix) != 0:
                result.extra_args = line.slice(args_prefix.len(), line.len())
            else if with_str_starts_with(line, skip_prefix) != 0:
                result.skip = true
                result.skip_reason = line.slice(skip_prefix.len(), line.len())
                return result
            else if with_str_starts_with(line, skip_windows_prefix) != 0:
                if with_sysinfo_os() == "Windows":
                    result.skip = true
                    result.skip_reason = line.slice(skip_windows_prefix.len(), line.len())
                    return result
            else if line == "//! skip":
                result.skip = true
                result.skip_reason = ""
                return result
            else if line == "//! check-only":
                result.check_only = true
            else if with_str_starts_with(line, "//!") != 0:
                let _ = 0
            else:
                return result
            start = i + 1
        i = i + 1
    result

fn test_directives_have_run_expectations(directives: &TestDirectives) -> bool:
    directives.has_expect_exit or directives.expect_stdout.len() > 0 or directives.expect_stderr.len() > 0

fn test_append_extra_args(argv: str, extra_args: str) -> str:
    var out = argv
    var start = 0
    var i = 0
    while i <= extra_args.len() as i32:
        let at_end = i == extra_args.len() as i32
        let ch = if at_end: 32 else: extra_args.byte_at(i as i64)
        if ch == 32 or ch == 9:
            if i > start:
                out = build_graph_argv_append(out, extra_args.slice(start as i64, i as i64))
            start = i + 1
        i = i + 1
    out

fn test_capture_dir(target: str, suffix: str) -> str:
    let base = build_graph_path_basename(target)
    let stem = if base.ends_with(".w"): base.slice(0, base.len() - 2) else: base
    "out/test-native/" ++ stem ++ "." ++ suffix ++ "." ++ f"{with_getpid()}.{with_clock_nanos()}"

fn run_test_compiler_command(target: str, command_name: str, directives: &TestDirectives) -> TestRunResult:
    let capture_dir = test_capture_dir(target, command_name)
    let _mkdir = with_fs_mkdir_p(capture_dir)
    let stdout_path = capture_dir ++ "/stdout.txt"
    let stderr_path = capture_dir ++ "/stderr.txt"
    var argv = ""
    argv = build_graph_argv_append(argv, with_arg_at(0))
    argv = build_graph_argv_append(argv, command_name)
    if command_name == "build":
        argv = build_graph_argv_append(argv, "-g0")
        argv = build_graph_argv_append(argv, "-o")
        argv = build_graph_argv_append(argv, capture_dir ++ "/out")
    argv = test_append_extra_args(argv, directives.extra_args)
    argv = build_graph_argv_append(argv, target)
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, 60000)
    let stdout = with_fs_read_file(stdout_path)
    let stderr = with_fs_read_file(stderr_path)
    let _remove_stdout = with_fs_remove_file(stdout_path)
    let _remove_stderr = with_fs_remove_file(stderr_path)
    let _remove_bin = with_fs_remove_file(capture_dir ++ "/out")
    let _remove_obj = with_fs_remove_file(capture_dir ++ "/out.o")
    let _remove_dsym = with_fs_remove_dir(capture_dir ++ "/out.dSYM")
    let _remove_dir = with_fs_remove_dir(capture_dir)
    TestRunResult { rc, stdout, stderr }

fn test_output_contains_expected(actual: str, expected: str) -> bool:
    expected.len() == 0 or with_str_contains(actual, expected) != 0

fn run_test_directive_command(target: str, directives: &TestDirectives, quiet: bool) -> i32:
    if directives.skip:
        if directives.skip_reason.len() == 0:
            emit_test_stage_error("skip missing reason", target, "directives", "")
            return 1
        return 0
    if directives.expect_check_fail.len() > 0:
        let result = run_test_compiler_command(target, "check", directives)
        if result.rc == 0:
            emit_test_stage_error("expected check failure", target, "check", "")
            return 1
        if not test_output_contains_expected(result.stderr, directives.expect_check_fail):
            emit_test_stage_error("missing expected check error: " ++ directives.expect_check_fail, target, "check", "")
            return 1
        return 0
    if directives.expect_build_fail.len() > 0:
        let result = run_test_compiler_command(target, "build", directives)
        if result.rc == 0:
            emit_test_stage_error("expected build failure", target, "build", "")
            return 1
        if not test_output_contains_expected(result.stderr, directives.expect_build_fail):
            emit_test_stage_error("missing expected build error: " ++ directives.expect_build_fail, target, "build", "")
            return 1
        return 0
    if directives.expect_check_stdout.len() > 0 or directives.expect_check_stdout_not.len() > 0:
        let result = run_test_compiler_command(target, "check", directives)
        if result.rc != 0:
            emit_test_stage_error(f"check failed with exit code {result.rc}", target, "check", "")
            return 1
        for i in 0..directives.expect_check_stdout.len() as i32:
            let expected = directives.expect_check_stdout.get(i as i64)
            if not test_output_contains_expected(result.stdout, expected):
                emit_test_stage_error("missing expected check stdout: " ++ expected, target, "check", "")
                return 1
        for i in 0..directives.expect_check_stdout_not.len() as i32:
            let forbidden = directives.expect_check_stdout_not.get(i as i64)
            if forbidden.len() > 0 and with_str_contains(result.stdout, forbidden) != 0:
                emit_test_stage_error("unexpected check stdout: " ++ forbidden, target, "check", "")
                return 1
        return 0
    if directives.check_only:
        let result = run_test_compiler_command(target, "check", directives)
        if result.rc == 0:
            return 0
        emit_test_stage_error(f"check failed with exit code {result.rc}", target, "check", "")
        return 1
    let _ = quiet
    -1

fn test_extra_arg_present(args: str, wanted: str) -> bool:
    var start = 0
    var i = 0
    while i <= args.len() as i32:
        let at_end = i == args.len() as i32
        let ch = if at_end: 32 else: args.byte_at(i as i64)
        if ch == 32 or ch == 9:
            if i > start and args.slice(start as i64, i as i64) == wanted:
                return true
            start = i + 1
        i = i + 1
    false

fn test_effective_opt_level(default_opt: i32, args: str) -> i32:
    if test_extra_arg_present(args, "-O0"): return 0
    if test_extra_arg_present(args, "-O1"): return 1
    if test_extra_arg_present(args, "-O2"): return 2
    if test_extra_arg_present(args, "-O3"): return 3
    default_opt

fn test_effective_prelude_mode(default_mode: i32, args: str) -> i32:
    if test_extra_arg_present(args, "--no-prelude") or test_extra_arg_present(args, "--prelude=none"):
        return PreludeMode.NoneMode as i32
    if test_extra_arg_present(args, "--prelude=core"):
        return PreludeMode.CoreMode as i32
    if test_extra_arg_present(args, "--prelude=full"):
        return PreludeMode.FullMode as i32
    default_mode

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
    with_fs_is_dir(target) != 0

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
    let _remove_old_stdout = build_graph_rt_remove_file(out_path)
    let _remove_old_stderr = build_graph_rt_remove_file(err_path)
    let old_filter = build_graph_rt_getenv("WITH_TEST_FILTER") ++ ""
    let old_short = build_graph_rt_getenv("WITH_TEST_SHORT") ++ ""
    if test_name.len() > 0:
        let _set_filter = build_graph_rt_setenv("WITH_TEST_FILTER", test_name)
    if quiet:
        let _set_short = build_graph_rt_setenv("WITH_TEST_SHORT", "1")
    var argv = ""
    argv = build_graph_argv_append(argv, bin_path)
    let rc = with_exec_argv_capture(argv, out_path, err_path, 120000)
    if test_name.len() > 0:
        let _restore_filter = build_graph_rt_setenv("WITH_TEST_FILTER", old_filter)
    if quiet:
        let _restore_short = build_graph_rt_setenv("WITH_TEST_SHORT", old_short)
    let stdout = with_fs_read_file(out_path)
    let stderr = with_fs_read_file(err_path)
    let _cleanup_stdout = build_graph_rt_remove_file(out_path)
    let _cleanup_stderr = build_graph_rt_remove_file(err_path)
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

fn validate_test_run(result: TestRunResult, directives: &TestDirectives, target: str, test_name: str) -> bool:
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

fn run_test_binary_checked(bin_path: str, target: str, test_name: str, quiet: bool, directives: &TestDirectives) -> i32:
    let result = run_test_process(bin_path, test_name, quiet)
    if validate_test_run(result, directives, target, test_name):
        return 0
    1

fn run_test_file_with_build_settings(target: str, opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32, debug_info: bool, verbose: bool, quiet: bool, filter: str, include_paths: &Vec[str], defines: &Vec[str], link_libs: &Vec[str]) -> i32:
    let directives = parse_test_directives_for_target(target)
    let directive_rc = run_test_directive_command(target, directives, quiet)
    if directive_rc >= 0:
        if not directives.skip:
            if directive_rc == 0:
                print_test_summary(target, 1, 0, quiet)
            else:
                print_test_summary(target, 0, 1, quiet)
        return directive_rc
    let discovery = discover_tests_for_target(target)
    let effective_opt_level = test_effective_opt_level(opt_level, directives.extra_args)
    let effective_no_std = no_std or test_extra_arg_present(directives.extra_args, "--no-std") or test_extra_arg_present(directives.extra_args, "--freestanding")
    let effective_runtime_available = runtime_available and not test_extra_arg_present(directives.extra_args, "--no-runtime") and not test_extra_arg_present(directives.extra_args, "--freestanding")
    let effective_alloc_mode = alloc_mode or test_extra_arg_present(directives.extra_args, "--alloc")
    let effective_prelude_mode = test_effective_prelude_mode(prelude_mode, directives.extra_args)
    var comp = Compilation.init()
    comp.configure(effective_opt_level, effective_no_std, effective_alloc_mode, effective_runtime_available)
    comp.set_prelude_mode(effective_prelude_mode)
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

fn run_test_file(target: str, opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32, debug_info: bool, verbose: bool, quiet: bool, filter: str) -> i32:
    let include_paths: Vec[str] = Vec.new()
    let defines: Vec[str] = Vec.new()
    let link_libs: Vec[str] = Vec.new()
    run_test_file_with_build_settings(target, opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info, verbose, quiet, filter, include_paths, defines, link_libs)

fn test_command_option_takes_value(arg: str) -> bool:
    arg == "-o" or arg == "--output" or arg == "-f" or arg == "--filter"

fn test_command_collect_targets(argc: i32) -> Vec[str]:
    let targets: Vec[str] = Vec.new()
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if test_command_option_takes_value(arg):
            i = i + 2
            continue
        if arg.len() > 0 and arg.byte_at(0) == 45:
            i = i + 1
            continue
        if not cli_is_build_target_selector(arg):
            targets.push(arg)
        i = i + 1
    targets

fn run_test_target(target: str, opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32, debug_info: bool, verbose: bool, quiet: bool, filter: str) -> i32:
    if test_target_is_directory(target):
        let test_files = collect_test_files(target)
        if test_files.len() == 0:
            with_eprint(f"error: no test sources found in '{target}'")
            return 1
        for ti in 0..test_files.len() as i32:
            let test_file = test_files.get(ti as i64)
            let run_rc = run_test_file(test_file, opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info, verbose, quiet, filter)
            if run_rc != 0:
                with_eprint(f"error: test failed in '{test_file}'")
                return run_rc
        return 0
    run_test_file(target, opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info, verbose, quiet, filter)

fn run_test_command(argc: i32, opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32, debug_info: bool) -> i32:
    let verbose = cli_test_verbose(argc)
    var quiet = cli_test_quiet(argc)
    if verbose:
        quiet = false
    let filter = cli_test_filter(argc)
    let targets = test_command_collect_targets(argc)
    if targets.len() == 0:
        var build_options = build_command_options_default()
        build_options.opt_level = opt_level
        build_options.no_std = no_std
        build_options.alloc_mode = alloc_mode
        build_options.runtime_available = runtime_available
        build_options.prelude_mode = prelude_mode
        build_options.debug_info = debug_info
        var graph_options = build_graph_command_options_default()
        graph_options.selected_target = "test"
        return run_build_command(build_options, graph_options)
    for ti in 0..targets.len() as i32:
        let target = targets.get(ti as i64)
        let rc = run_test_target(target, opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info, verbose, quiet, filter)
        if rc != 0:
            return rc
    0

fn run_bench_file(target: str, opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32, debug_info: bool, filter: str) -> i32:
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
    comp.configure(opt_level, no_std, alloc_mode, runtime_available)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(debug_info)
    let bin_path = comp.build_binary_from_source(target, synthetic_source)
    if bin_path == "":
        with_eprint("error: bench build failed for '" ++ target ++ "'")
        return 1
    let old_filter = build_graph_rt_getenv("WITH_BENCH_FILTER") ++ ""
    if filter.len() > 0:
        let _set_filter = build_graph_rt_setenv("WITH_BENCH_FILTER", filter)
    let rc = build_graph_rt_exec_binary(bin_path)
    if filter.len() > 0:
        let _restore_filter = build_graph_rt_setenv("WITH_BENCH_FILTER", old_filter)
    cleanup_binary_artifacts(bin_path)
    rc

fn run_bench_command(argc: i32, opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32, debug_info: bool) -> i32:
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
            let rc = run_bench_file(file, opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info, filter)
            if rc != 0:
                any_failed = true
        if any_failed:
            return 1
        return 0
    run_bench_file(target, opt_level, no_std, alloc_mode, runtime_available, prelude_mode, debug_info, filter)

fn run_migrate_command(argc: i32) -> i32:
    if argc < 3:
        eprint("usage: with migrate <file.c|dir/> [-o output] [-I include_dir] [-include header] [--exclude basename]")
        return 1

    // Hidden developer mode: run the CiIR/CiPrint roundtrip harness
    // and exit. Used by the cli-selfhost-ir-roundtrip test.
    if with_arg_at(2) == "--ir-roundtrip":
        return ci_ir_roundtrip_test()

    // Parse arguments
    var source_path = ""
    var output_path = ""
    var exclude_basenames = ""
    var ai = 2
    while ai < argc:
        let arg = with_arg_at(ai)
        if arg == "-o" and ai + 1 < argc:
            output_path = with_arg_at(ai + 1)
            ai = ai + 2
            continue
        if arg == "-I" and ai + 1 < argc:
            migrate_add_include_path(with_arg_at(ai + 1))
            ai = ai + 2
            continue
        if arg == "-include" and ai + 1 < argc:
            migrate_add_forced_include(with_arg_at(ai + 1))
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
        if arg == "--c-export-functions":
            migrate_set_export_function_defs(1)
            ai = ai + 1
            continue
        if arg == "--convert-goto-to-structured":
            migrate_set_convert_goto_to_structured(1)
            ai = ai + 1
            continue
        if arg == "--prefer-curly":
            eprint("error: --prefer-curly was renamed to --prefer-brace")
            return 1
        if arg == "--prefer-brace":
            migrate_set_block_style(2)
            ai = ai + 1
            continue
        if arg == "--prefer-colon":
            migrate_set_block_style(0)
            ai = ai + 1
            continue
        if arg == "--width-slice" and ai + 1 < argc:
            migrate_set_width_slice(cli_parse_small_int(with_arg_at(ai + 1)))
            ai = ai + 2
            continue
        if arg == "--shared-defs" and ai + 1 < argc:
            migrate_set_shared_defs(with_arg_at(ai + 1))
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
            ai = ai + 2
            continue
        if arg.len() > 10 and arg.slice(0, 10) == "--exclude=":
            exclude_basenames = exclude_basenames ++ "|" ++ arg.slice(10, arg.len()) ++ "|"
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
        return migrate_c_directory(source_path, output_path, exclude_basenames)

    // Single file mode — default output: replace .c with .w
    if output_path.len() == 0:
        if source_path.len() > 2 and source_path.slice(source_path.len() - 2, source_path.len()) == ".c":
            output_path = source_path.slice(0, source_path.len() - 2) ++ ".w"
        else:
            output_path = source_path ++ ".w"

    migrate_c_file(source_path, output_path)

fn cli_read_all_stdin() -> str:
    var out = StringBuilder.new()
    while true:
        let chunk = with_read_bytes_stdin(4096)
        if chunk.len() == 0:
            return out.to_str()
        out.push_str(chunk)
        if chunk.len() < 4096:
            return out.to_str()
    out.to_str()

fn doc_field(line: str, key: str) -> str:
    let needle = key ++ "="
    var i = 0
    while i + needle.len() as i32 <= line.len() as i32:
        let at_field = i == 0 or line.byte_at((i - 1) as i64) == 32
        if at_field and line.slice(i as i64, (i + needle.len() as i32) as i64) == needle:
            let start = i + needle.len() as i32
            var end = start
            while end < line.len() as i32 and line.byte_at(end as i64) != 32:
                end = end + 1
            return line.slice(start as i64, end as i64)
        i = i + 1
    ""

fn doc_parse_span_start(span: str) -> i32:
    var value = 0
    var i = 0
    while i < span.len() as i32:
        let ch = span.byte_at(i as i64)
        if ch < 48 or ch > 57:
            return value
        value = value * 10 + (ch - 48)
        i = i + 1
    value

fn doc_path_matches(recorded: str, requested: str) -> bool:
    if recorded == requested:
        return true
    if requested.ends_with("/" ++ recorded):
        return true
    if recorded.ends_with("/" ++ requested):
        return true
    false

fn doc_path_is_project_source(path: str, root: str, requested: str) -> bool:
    if path.starts_with("<"):
        return false
    if doc_path_matches(path, requested):
        return true
    let requested_dir = resolve_dirname(requested)
    if requested_dir.len() > 0:
        let requested_prefix = if requested_dir.ends_with("/"): requested_dir else: requested_dir ++ "/"
        if path.starts_with(requested_prefix):
            return true
    if root.len() == 0:
        return false
    let prefix = if root.ends_with("/"): root else: root ++ "/"
    path.starts_with(prefix)

fn doc_source_line_at(text: str, offset: i32) -> str:
    var start = offset
    if start < 0:
        start = 0
    if start > text.len() as i32:
        start = text.len() as i32
    while start > 0 and text.byte_at((start - 1) as i64) != 10:
        start = start - 1
    var end = offset
    if end < start:
        end = start
    while end < text.len() as i32 and text.byte_at(end as i64) != 10:
        end = end + 1
    text.slice(start as i64, end as i64).trim()

fn doc_extract_comment(text: str, decl_start: i32) -> str:
    var pos = decl_start - 1
    while pos >= 0 and (text.byte_at(pos as i64) == 32 or text.byte_at(pos as i64) == 9 or text.byte_at(pos as i64) == 13 or text.byte_at(pos as i64) == 10):
        pos = pos - 1
    let lines: Vec[str] = Vec.new()
    while pos >= 0:
        var line_start = pos
        while line_start > 0 and text.byte_at((line_start - 1) as i64) != 10:
            line_start = line_start - 1
        let line = text.slice(line_start as i64, (pos + 1) as i64).trim()
        if not line.starts_with("///"):
            break
        lines.push(line.slice(3, line.len()).trim())
        pos = line_start - 1
        while pos >= 0 and (text.byte_at(pos as i64) == 32 or text.byte_at(pos as i64) == 9 or text.byte_at(pos as i64) == 13 or text.byte_at(pos as i64) == 10):
            pos = pos - 1
    var out = ""
    var i = lines.len() as i32 - 1
    while i >= 0:
        if out.len() > 0:
            out = out ++ "\n"
        out = out ++ lines.get(i as i64)
        i = i - 1
    out

fn doc_markdown_entry(kind: str, path: str, name: str, detail: str, source_text: str, span_start: i32) -> str:
    var out = "### " ++ name ++ "\n\n"
    out = out ++ "Module: `" ++ path ++ "`\n\n"
    let docs = doc_extract_comment(source_text, span_start)
    if docs.len() > 0:
        out = out ++ docs ++ "\n\n"
    else:
        out = out ++ "_No documentation comment._\n\n"
    let line = doc_source_line_at(source_text, span_start)
    if line.len() > 0:
        out = out ++ "```with\n" ++ line ++ "\n```\n\n"
    if detail.len() > 0:
        out = out ++ detail ++ "\n\n"
    let _ = kind
    out

fn doc_project_root(info: str) -> str:
    let lines = split_nonempty_lines(info)
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if line.starts_with("config root="):
            return doc_field(line, "root")
    ""

fn doc_collect_modules(info: str, root: str, source_path: str) -> str:
    let lines = split_nonempty_lines(info)
    var out = ""
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if not line.starts_with("module "):
            continue
        let path = doc_field(line, "path")
        if not doc_path_is_project_source(path, root, source_path):
            continue
        out = out ++ "- `" ++ path ++ "`\n"
    out

fn doc_path_seen(paths: &Vec[str], path: str) -> bool:
    for i in 0..paths.len() as i32:
        if paths.get(i as i64) == path:
            return true
    false

fn doc_module_paths(info: str, root: str, source_path: str) -> Vec[str]:
    let paths: Vec[str] = Vec.new()
    let lines = split_nonempty_lines(info)
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if not line.starts_with("module "):
            continue
        let path = doc_field(line, "path")
        if not doc_path_is_project_source(path, root, source_path):
            continue
        if not doc_path_seen(paths, path):
            paths.push(path)
    if paths.len() == 0:
        paths.push(source_path)
    paths

fn doc_collect_entries(info: str, root: str, source_path: str, fallback_source_text: str, wanted_kind: str) -> str:
    let lines = split_nonempty_lines(info)
    var out = ""
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if not line.starts_with(wanted_kind ++ " "):
            continue
        if doc_field(line, "pub") != "1":
            continue
        let path = doc_field(line, "path")
        if not doc_path_is_project_source(path, root, source_path):
            continue
        var source_text = with_fs_read_file(path)
        if source_text.len() == 0 and doc_path_matches(path, source_path):
            source_text = fallback_source_text
        if source_text.len() == 0:
            continue
        let name = doc_field(line, "name")
        let span = doc_field(line, "span")
        let start = doc_parse_span_start(span)
        var detail = ""
        if wanted_kind == "function":
            detail = "Parameters: " ++ doc_field(line, "params") ++ "\n\nReturns: `" ++ doc_field(line, "return") ++ "`"
        else:
            detail = "Kind: `" ++ doc_field(line, "kind") ++ "`"
        out = out ++ doc_markdown_entry(wanted_kind, path, name, detail, source_text, start)
    out

fn doc_default_source(source: str) -> str:
    if source.len() > 0:
        return source
    let root = build_graph_find_build_root(".")
    if root.len() > 0:
        let project_main = resolve_join(root, "src/main.w")
        if with_fs_file_exists(project_main) != 0:
            return project_main
    if with_fs_file_exists("src/main.w") != 0:
        return "src/main.w"
    ""

fn doc_output_path(output: str) -> str:
    if output.len() > 0:
        return output
    "out/doc/index.md"

fn run_doc_command(argc: i32, source: str, output: str, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32) -> i32:
    let source_path = doc_default_source(source)
    if source_path.len() == 0:
        with_eprint("error: with doc requires a source file or a project with src/main.w")
        return 1
    if with_fs_file_exists(source_path) == 0:
        with_eprint("error: with doc source file not found: " ++ source_path)
        return 1
    let source_text = with_fs_read_file(source_path)
    if source_text.len() == 0:
        with_eprint("error: with doc could not read source file: " ++ source_path)
        return 1
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode, runtime_available)
    comp.set_prelude_mode(prelude_mode)
    let pool = comp.compile_file(source_path)
    if pool.decl_count() == 0:
        with_eprint("error: with doc failed during compilation")
        return 1
    if not comp.check_pool(pool, source_path):
        return 1
    let info = comp.dump_project_info(pool)
    let root = doc_project_root(info)
    let module_paths = doc_module_paths(info, root, source_path)
    var all_info = ""
    for mi in 0..module_paths.len() as i32:
        let module_path = module_paths.get(mi as i64)
        var module_comp = Compilation.init()
        module_comp.configure(0, no_std, alloc_mode, runtime_available)
        module_comp.set_prelude_mode(prelude_mode)
        let module_pool = module_comp.compile_file(module_path)
        if module_pool.decl_count() == 0:
            with_eprint("error: with doc failed while compiling module: " ++ module_path)
            return 1
        if not module_comp.check_pool(module_pool, module_path):
            return 1
        all_info = all_info ++ module_comp.dump_project_info(module_pool)
    var markdown = "# With Documentation\n\n"
    markdown = markdown ++ "Source: `" ++ source_path ++ "`\n\n"
    let modules = doc_collect_modules(info, root, source_path)
    if modules.len() > 0:
        markdown = markdown ++ "## Modules\n\n" ++ modules ++ "\n"
    let functions = doc_collect_entries(all_info, root, source_path, source_text, "function")
    let types = doc_collect_entries(all_info, root, source_path, source_text, "type")
    if functions.len() > 0:
        markdown = markdown ++ "## Functions\n\n" ++ functions
    if types.len() > 0:
        markdown = markdown ++ "## Types\n\n" ++ types
    if functions.len() == 0 and types.len() == 0:
        markdown = markdown ++ "_No public functions or types found._\n"
    let out_path = doc_output_path(output)
    let out_dir = resolve_dirname(out_path)
    if out_dir.len() > 0 and with_fs_mkdir_p(out_dir) != 0:
        with_eprint("error: with doc could not create output directory: " ++ out_dir)
        return 1
    if with_fs_write_file(out_path, markdown) != 0:
        with_eprint("error: with doc could not write " ++ out_path)
        return 1
    with_write("generated documentation at " ++ out_path ++ "\n")
    if cli_has_flag(argc, "--open"):
        with_eprint("warning: --open generated documentation but browser opening is not implemented in this compiler build")
    0

fn repl_source_for_line(line: str) -> str:
    "use std.io\n" ++
    "use std.str\n" ++
    "use std.regex\n" ++
    "use std.math\n" ++
    "use std.collections\n" ++
    "use std.builtins\n\n" ++
    line ++ "\n"

fn repl_line_requires_session_state(line: str) -> bool:
    let text = line.trim()
    text.starts_with("let ") or text.starts_with("var ") or text.starts_with("fn ") or text.starts_with("pub ") or text.starts_with("type ") or text.starts_with("trait ") or text.starts_with("impl ") or text.starts_with("extern ") or text.starts_with("use ")

fn repl_bin_path -> str:
    f"out/tmp/with-repl-{with_getpid()}-{with_clock_nanos()}"

fn run_repl_line(line: str, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32) -> i32:
    if no_std:
        with_eprint("error: repl requires the standard library")
        return 1
    let source = repl_source_for_line(line)
    let bin_path = repl_bin_path()
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode, runtime_available)
    comp.set_prelude_mode(prelude_mode)
    comp.set_debug_info(false)
    let built = comp.build_entry_binary_from_source_to_path("<repl>", source, bin_path)
    if built == "":
        return 1
    comp.print_warnings()
    let rc = build_graph_rt_exec_binary(built)
    cleanup_binary_artifacts(built)
    let _obj = build_graph_rt_remove_file(built ++ ".o")
    rc

fn print_repl_help:
    with_write("Commands:\n")
    with_write("  :help     Show REPL commands\n")
    with_write("  :quit     Exit the REPL\n")
    with_write("  :exit     Exit the REPL\n")
    with_write("\n")
    with_write("Each input line is compiled and run as normal With code. Persistent declarations are rejected until session state is implemented.\n")

fn run_repl_command(argc: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32) -> i32:
    let _ = argc
    with_write("With REPL\n")
    print_repl_help()
    while true:
        with_write("with> ")
        let line = with_read_line_stdin()
        if line.len() == 0:
            with_write("\n")
            return 0
        let trimmed = line.trim()
        if trimmed.len() == 0:
            continue
        if trimmed == ":quit" or trimmed == ":exit":
            return 0
        if trimmed == ":help":
            print_repl_help()
            continue
        if trimmed.starts_with(":"):
            with_eprint("error: unknown repl command '" ++ trimmed ++ "'")
            return 1
        if repl_line_requires_session_state(trimmed):
            with_eprint("error: repl persistent declarations are not implemented yet; use expression or statement snippets")
            return 1
        let rc = run_repl_line(trimmed, no_std, alloc_mode, runtime_available, prelude_mode)
        if rc != 0:
            return rc
    0

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
    let root = build_graph_find_build_root(".")
    if root.len() > 0:
        let build_path = resolve_join(root, "build.w")
        if project_config_file_exists(build_path):
            return run_graph_target_command("clean")
    let out_rc = with_fs_remove_tree("out")
    if out_rc != 0 and with_fs_file_exists("out") != 0:
        with_eprint("error: clean failed removing out/")
        return 1
    let legacy_rc = with_fs_remove_tree(".with")
    if legacy_rc != 0 and with_fs_file_exists(".with") != 0:
        with_eprint("error: clean failed removing legacy .with/")
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
    with_write("  doc              Generate documentation\n")
    with_write("  repl             Start an interactive session\n")
    with_write("  lsp              Start the language server\n")
    with_write("  migrate          Migrate C source to With\n")
    with_write("\n")
    with_write("  init             Initialize a With project\n")
    with_write("  get              Add or reinstall a package dependency\n")
    with_write("  remove           Remove a package dependency\n")
    with_write("  update           Update package dependencies\n")
    with_write("  clean            Delete build artifacts\n")
    with_write("  install-user     Install compiler to ~/.local/bin\n")
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
    with_write("  --target <triple>\n")
    with_write("                   Build for a target triple (cross-targets not implemented yet)\n")
    with_write("  --emit-c         Emit C instead of a binary\n")
    with_write("  --emit-obj       Emit an object file instead of a binary\n")
    with_write("  --dump-project-info\n")
    with_write("                   Print resolved project metadata from 'check'\n")
    with_write("  --no-std         Disable standard library support\n")
    with_write("  --no-runtime     Disable the fiber runtime; async constructs are errors\n")
    with_write("  --no-prelude     Disable implicit prelude import\n")
    with_write("  --prelude=<mode> Select prelude mode: full, alloc, core, none\n")
    with_write("  --overflow=<mode>\n")
    with_write("                   Select overflow mode for builds: panic, wrap, saturate\n")
    with_write("  --strict-effects Reject undeclared build-time effects\n")
    with_write("  --freestanding   Alias for --no-std --no-runtime --prelude=core\n")

fn print_doc_usage:
    with_write("Usage: with doc [source.w] [options]\n")
    with_write("\n")
    with_write("Generates deterministic Markdown documentation for public declarations.\n")
    with_write("With no source argument, uses src/main.w from the current project.\n")
    with_write("\n")
    with_write("Doc Options:\n")
    with_write("\n")
    with_write("  -h, --help       Print this help and exit\n")
    with_write("  -o, --output     Write documentation to path (default: out/doc/index.md)\n")
    with_write("  --open           Best-effort open after successful generation\n")
    with_write("  --no-std         Disable standard library support while checking docs\n")
    with_write("  --prelude=<mode> Select prelude mode: full, alloc, core, none\n")

fn print_repl_usage:
    with_write("Usage: with repl [options]\n")
    with_write("\n")
    with_write("Starts a line-oriented session. Each input line is compiled and run through the normal compiler pipeline.\n")
    with_write("\n")
    with_write("REPL Commands:\n")
    with_write("\n")
    with_write("  :help            Show REPL commands\n")
    with_write("  :quit, :exit     Exit the REPL\n")
    with_write("\n")
    with_write("Persistent declarations are rejected until session state is implemented.\n")
    with_write("\n")
    with_write("REPL Options:\n")
    with_write("\n")
    with_write("  -h, --help       Print this help and exit\n")

fn print_build_usage:
    with_write("Usage: with build [source.w|:target] [options]\n")
    with_write("\n")
    with_write("Builds a source file or a target from build.w.\n")
    with_write("\n")
    with_write("Examples:\n")
    with_write("\n")
    with_write("  with build src/main.w\n")
    with_write("  with build :test\n")
    with_write("  with build :fixpoint\n")
    with_write("\n")
    with_write("Build Options:\n")
    with_write("\n")
    with_write("  -h, --help       Print this help and exit\n")
    with_write("  -O0|-O1|-O2|-O3  Set optimization level\n")
    with_write("  -o, --output     Write output to path\n")
    with_write("  --release        Enable release defaults\n")
    with_write("  --target <triple>\n")
    with_write("                   Build for a target triple (cross-targets not implemented yet)\n")
    with_write("  --emit-c         Emit C instead of a binary\n")
    with_write("  --emit-obj       Emit an object file instead of a binary\n")
    with_write("  --graph          Print the build graph and exit\n")
    with_write("  --dry-run        Print planned build actions without running them\n")
    with_write("  --no-deps        Build only the selected target\n")
    with_write("  --explain <name> Explain a build graph target\n")
    with_write("  --strict-effects Reject undeclared build-time effects\n")
    with_write("  :effects         Print recorded build effect ledgers\n")
    with_write("  --no-std         Disable standard library support\n")
    with_write("  --no-runtime     Disable the fiber runtime; async constructs are errors\n")
    with_write("  --no-prelude     Disable implicit prelude import\n")
    with_write("  --prelude=<mode> Select prelude mode: full, alloc, core, none\n")
    with_write("  --overflow=<mode>\n")
    with_write("                   Select overflow mode: panic, wrap, saturate\n")
    with_write("  --freestanding   Alias for --no-std --no-runtime --prelude=core\n")

fn print_test_usage:
    with_write("Usage: with test [source.w|directory ...] [options]\n")
    with_write("\n")
    with_write("Builds and runs explicit test files or all tests in explicit directories.\n")
    with_write("With no explicit source or directory, runs the build.w :test target.\n")
    with_write("\n")
    with_write("Examples:\n")
    with_write("\n")
    with_write("  with test test/behavior/example.w\n")
    with_write("  with test test/behavior/a.w test/behavior/b.w\n")
    with_write("  with test test/behavior\n")
    with_write("  with test\n")
    with_write("\n")
    with_write("Test Options:\n")
    with_write("\n")
    with_write("  -h, --help       Print this help and exit\n")
    with_write("  -v, --verbose    Print each discovered test name\n")
    with_write("  -q, --quiet      Suppress per-file summaries\n")
    with_write("  -f, --filter     Run discovered tests whose name contains the filter\n")
    with_write("  --filter=<text>  Same as --filter <text>\n")
    with_write("  -O0|-O1|-O2|-O3  Set optimization level\n")
    with_write("  -o, --output     Write output to path\n")
    with_write("  --release        Enable release defaults\n")
    with_write("  --no-std         Disable standard library support\n")
    with_write("  --no-runtime     Disable the fiber runtime; async constructs are errors\n")
    with_write("  --no-prelude     Disable implicit prelude import\n")
    with_write("  --prelude=<mode> Select prelude mode: full, alloc, core, none\n")
    with_write("  --freestanding   Alias for --no-std --no-runtime --prelude=core\n")

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
        "  fn let var if else match for in while loop return break continue goto\n" ++
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

fn cli_trim_line(text: str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn cli_dep_line_matches(line: str, pkg_name: str) -> bool:
    let trimmed = cli_trim_line(line)
    var eq = -1
    for i in 0..trimmed.len() as i32:
        if trimmed.byte_at(i as i64) == 61:
            eq = i
            break
    if eq < 0:
        return false
    let key = cli_trim_line(trimmed.slice(0, eq as i64))
    key == "c." ++ pkg_name

fn cli_line_is_section(line: str) -> bool:
    let trimmed = cli_trim_line(line)
    trimmed.len() >= 2 and trimmed.byte_at(0) == 91 and trimmed.byte_at(trimmed.len() - 1) == 93

fn cli_strip_quotes(value: str) -> str:
    let trimmed = cli_trim_line(value)
    if trimmed.len() >= 2 and trimmed.byte_at(0) == 34 and trimmed.byte_at(trimmed.len() - 1) == 34:
        return trimmed.slice(1, trimmed.len() - 1)
    trimmed

type CliManifestRemoveResult {
    ok: bool,
    text: str,
}

type CliManifestDep {
    name: str,
    constraint: str,
}

fn cli_update_manifest_dep(toml: str, pkg_name: str, pkg_version: str) -> str:
    let dep_line = "c." ++ pkg_name ++ " = \"" ++ pkg_version ++ "\""
    var out = ""
    var found_dep = false
    var has_deps = false
    var in_deps = false
    var start = 0
    var i = 0
    let n = toml.len() as i32
    while i <= n:
        let at_end = i == n
        let ch = if at_end: 10 else: toml.byte_at(i as i64)
        if ch == 10:
            let line = toml.slice(start as i64, i as i64)
            let trimmed = cli_trim_line(line)
            if cli_line_is_section(line) and in_deps and not found_dep:
                out = out ++ dep_line ++ "\n"
                found_dep = true
            if trimmed == "[deps]":
                has_deps = true
                in_deps = true
            else if cli_line_is_section(line):
                in_deps = false
            if in_deps and cli_dep_line_matches(line, pkg_name):
                out = out ++ dep_line ++ "\n"
                found_dep = true
            else:
                out = out ++ line
                if not at_end or line.len() > 0:
                    out = out ++ "\n"
            start = i + 1
        i = i + 1
    if found_dep:
        return out
    if not has_deps:
        if out.len() > 0 and not out.ends_with("\n"):
            out = out ++ "\n"
        out = out ++ "\n[deps]\n"
    out ++ dep_line ++ "\n"

fn cli_remove_manifest_dep(toml: str, pkg_name: str) -> CliManifestRemoveResult:
    var out = ""
    var removed = false
    var in_deps = false
    var start = 0
    var i = 0
    let n = toml.len() as i32
    while i <= n:
        let at_end = i == n
        let ch = if at_end: 10 else: toml.byte_at(i as i64)
        if ch == 10:
            let line = toml.slice(start as i64, i as i64)
            let trimmed = cli_trim_line(line)
            if trimmed == "[deps]":
                in_deps = true
            else if cli_line_is_section(line):
                in_deps = false
            if in_deps and cli_dep_line_matches(line, pkg_name):
                removed = true
            else:
                out = out ++ line
                if not at_end or line.len() > 0:
                    out = out ++ "\n"
            start = i + 1
        i = i + 1
    CliManifestRemoveResult { ok: removed, text: out }

fn cli_manifest_c_deps(toml: str) -> Vec[CliManifestDep]:
    let deps: Vec[CliManifestDep] = Vec.new()
    var in_deps = false
    var start = 0
    var i = 0
    let n = toml.len() as i32
    while i <= n:
        let at_end = i == n
        let ch = if at_end: 10 else: toml.byte_at(i as i64)
        if ch == 10:
            let line = toml.slice(start as i64, i as i64)
            let trimmed = cli_trim_line(line)
            if trimmed == "[deps]":
                in_deps = true
            else if cli_line_is_section(line):
                in_deps = false
            else if in_deps:
                var eq = -1
                for j in 0..trimmed.len() as i32:
                    if trimmed.byte_at(j as i64) == 61:
                        eq = j
                        break
                if eq > 0:
                    let key = cli_trim_line(trimmed.slice(0, eq as i64))
                    if key.starts_with("c.") and key.len() > 2:
                        deps.push(CliManifestDep { name: key.slice(2, key.len()), constraint: cli_strip_quotes(trimmed.slice((eq + 1) as i64, trimmed.len())) })
            start = i + 1
        i = i + 1
    deps

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

fn cli_init_write_new_file(path: str, contents: str) -> i32:
    if with_fs_file_exists(path) != 0:
        with_eprint("error: file already exists: " ++ path)
        return 1
    if with_fs_write_file(path, contents) != 0:
        with_eprint("error: failed to write " ++ path)
        return 1
    0

fn cli_init_manifest_template(name: str) -> str:
    "[package]\n" ++
    "name = \"" ++ name ++ "\"\n" ++
    "version = \"0.1.0\"\n"

fn cli_init_build_template(name: str, is_lib: bool) -> str:
    let product_kind = if is_lib: "library" else: "executable"
    let entry = if is_lib: "src/lib.w" else: "src/main.w"
    "use std.build\n\n" ++
    "comptime with BuildCtx as ctx:\n" ++
    "pub fn build -> Build:\n" ++
    "    var out = ctx.new_build()." ++ product_kind ++ "(\"" ++ name ++ "\", \"" ++ entry ++ "\")\n" ++
    "    out = out.test(\"test\", \"test/*.w\")\n" ++
    "    out.default(\"" ++ name ++ "\")\n"

fn cli_init_readme_template(name: str, is_lib: bool) -> str:
    let run_line = if is_lib: "with build" else: "with run"
    "# " ++ name ++ "\n\n" ++
    "## Build\n\n" ++
    "```sh\n" ++
    "with build\n" ++
    "```\n\n" ++
    "## Test\n\n" ++
    "```sh\n" ++
    "with build :test\n" ++
    "```\n\n" ++
    "## Run\n\n" ++
    "```sh\n" ++
    run_line ++ "\n" ++
    "```\n"

fn cli_init_gitignore_template() -> str:
    "out/\n.with/\n!.with/lock.json\n"

fn cli_init_main_template(name: str) -> str:
    "fn main:\n" ++
    "    print(\"hello from " ++ name ++ "\")\n"

fn cli_init_lib_template(name: str) -> str:
    "pub fn hello -> str:\n" ++
    "    \"hello from " ++ name ++ "\"\n"

fn cli_init_test_template() -> str:
    "//! expect-stdout: ok\n\n" ++
    "fn main:\n" ++
    "    print(\"ok\")\n"

fn cli_init_file_must_not_exist(path: str) -> i32:
    if with_fs_file_exists(path) != 0:
        with_eprint("error: file already exists: " ++ path)
        return 1
    0

fn cli_init_report_path(path: str):
    with_eprint("  " ++ path)

fn cli_init_try_git_init(dir: str):
    let stdout_path = resolve_join(dir, ".git_init_stdout")
    let stderr_path = resolve_join(dir, ".git_init_stderr")
    var argv = ""
    argv = build_graph_argv_append(argv, "git")
    argv = build_graph_argv_append(argv, "init")
    argv = build_graph_argv_append(argv, dir)
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, 10000)
    let _rm_stdout = with_fs_remove_file(stdout_path)
    let _rm_stderr = with_fs_remove_file(stderr_path)
    if rc == 0:
        with_eprint("  git init")

fn run_init_command(argc: i32) -> i32:
    let target_dir = cli_init_target_dir(argc)
    var name = cli_flag_value(argc, "--name")
    if name.len() == 0:
        name = cli_init_default_name(target_dir)
    let is_lib = cli_has_flag(argc, "--lib")
    let manifest_path = resolve_join(target_dir, "with.toml")
    let build_path = resolve_join(target_dir, "build.w")
    let readme_path = resolve_join(target_dir, "README.md")
    let gitignore_path = resolve_join(target_dir, ".gitignore")
    let agents_path = resolve_join(target_dir, "AGENTS.md")
    let claude_path = resolve_join(target_dir, "CLAUDE.md")
    let src_dir = resolve_join(target_dir, "src")
    let test_dir = resolve_join(target_dir, "test")
    let lib_path = resolve_join(src_dir, "lib.w")
    let main_path = resolve_join(src_dir, "main.w")
    let test_path = resolve_join(test_dir, "test_main.w")
    var created_path = target_dir
    if target_dir == ".":
        created_path = name

    let ai_guide = init_ai_guide_template()

    if cli_init_file_must_not_exist(manifest_path) != 0:
        return 1
    if cli_init_file_must_not_exist(build_path) != 0:
        return 1
    if cli_init_file_must_not_exist(readme_path) != 0:
        return 1
    if cli_init_file_must_not_exist(gitignore_path) != 0:
        return 1
    if cli_init_file_must_not_exist(agents_path) != 0:
        return 1
    if cli_init_file_must_not_exist(claude_path) != 0:
        return 1
    if is_lib:
        if cli_init_file_must_not_exist(lib_path) != 0:
            return 1
    else:
        if cli_init_file_must_not_exist(main_path) != 0:
            return 1
    if cli_init_file_must_not_exist(test_path) != 0:
        return 1

    if with_fs_mkdir_p(target_dir) != 0:
        with_eprint("error: failed to create " ++ target_dir ++ " directory")
        return 1
    if with_fs_mkdir_p(src_dir) != 0:
        with_eprint("error: failed to create " ++ src_dir ++ " directory")
        return 1
    if with_fs_mkdir_p(test_dir) != 0:
        with_eprint("error: failed to create " ++ test_dir ++ " directory")
        return 1

    if is_lib:
        if cli_init_write_new_file(lib_path, cli_init_lib_template(name)) != 0:
            return 1
    else:
        if cli_init_write_new_file(main_path, cli_init_main_template(name)) != 0:
            return 1
    if cli_init_write_new_file(manifest_path, cli_init_manifest_template(name)) != 0:
        return 1
    if cli_init_write_new_file(build_path, cli_init_build_template(name, is_lib)) != 0:
        return 1
    if cli_init_write_new_file(readme_path, cli_init_readme_template(name, is_lib)) != 0:
        return 1
    if cli_init_write_new_file(gitignore_path, cli_init_gitignore_template()) != 0:
        return 1
    if cli_init_write_new_file(agents_path, ai_guide) != 0:
        return 1
    if cli_init_write_new_file(claude_path, ai_guide) != 0:
        return 1
    if cli_init_write_new_file(test_path, cli_init_test_template()) != 0:
        return 1

    if is_lib:
        with_eprint("created " ++ created_path ++ " (library)")
    else:
        with_eprint("created " ++ created_path)
    if is_lib:
        cli_init_report_path(lib_path)
    else:
        cli_init_report_path(main_path)
    cli_init_report_path(manifest_path)
    cli_init_report_path(build_path)
    cli_init_report_path(readme_path)
    cli_init_report_path(gitignore_path)
    cli_init_report_path(agents_path)
    cli_init_report_path(claude_path)
    cli_init_report_path(test_path)
    cli_init_try_git_init(target_dir)
    0

type GetCommandOptions {
    spec: str,
    force_reinstall: bool,
}

fn get_command_usage():
    with_eprint("usage: with get [--force-reinstall] [c.<package>[@version] | <package>[@version]]")
    with_eprint("  c.<package>     C dependency via Conan Center")
    with_eprint("  <package>       With package (registry not yet available)")
    with_eprint("  (no arguments)  restore dependencies from lock file")

fn get_command_registry_unavailable(name: str):
    with_eprint("error: the With package registry is not available yet; cannot fetch With package '" ++ name ++ "'")
    with_eprint("  With packages (spec §18.8) will come from the With package registry, which is not live yet.")
    with_eprint("  For a C library, use the Conan source instead: with get c.<name>  (e.g. with get c.json-c)")
    with_eprint("  Registry progress is tracked at: https://github.com/withlang-dev/with/issues/547")

fn get_command_valid_pkg_start(ch: i32) -> bool:
    (ch >= 97 and ch <= 122) or ch == 95

fn get_command_valid_pkg_char(ch: i32) -> bool:
    (ch >= 97 and ch <= 122) or (ch >= 48 and ch <= 57) or ch == 95 or ch == 45

fn get_command_with_pkg_name(spec: str) -> str:
    if spec.len() == 0:
        return ""
    var name_end = spec.len() as i32
    for i in 0..spec.len() as i32:
        if spec.byte_at(i as i64) == 64:
            name_end = i
            break
    if name_end <= 0:
        return ""
    if not get_command_valid_pkg_start(spec.byte_at(0)):
        return ""
    for i in 0..name_end:
        if not get_command_valid_pkg_char(spec.byte_at(i as i64)):
            return ""
    if name_end < spec.len() as i32 and name_end + 1 >= spec.len() as i32:
        return ""
    spec.slice(0, name_end as i64)

fn parse_get_command_options(argc: i32) -> GetCommandOptions:
    var spec = ""
    var force_reinstall = false
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "--force-reinstall" or arg == "--force":
            force_reinstall = true
        else if arg.starts_with("-"):
            with_eprint("error: unknown with get option '" ++ arg ++ "'")
            return GetCommandOptions { spec: "", force_reinstall }
        else if spec.len() == 0:
            spec = arg
        else:
            with_eprint("error: unexpected with get argument '" ++ arg ++ "'")
            return GetCommandOptions { spec: "", force_reinstall }
        i = i + 1
    GetCommandOptions { spec, force_reinstall }

fn run_get_command(argc: i32) -> i32:
    let options = parse_get_command_options(argc)
    let root = project_config_find_root(".")
    if root.len() == 0:
        with_eprint("error: no with.toml found. Run 'with init' first.")
        return 1
    if options.spec.len() == 0:
        return lock_restore(root)
    let spec = options.spec
    if not spec.starts_with("c."):
        let with_pkg_name = get_command_with_pkg_name(spec)
        if with_pkg_name.len() > 0:
            get_command_registry_unavailable(with_pkg_name)
            return 1
        with_eprint("error: invalid package spec '" ++ spec ++ "'")
        get_command_usage()
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
        with_eprint("error: invalid package spec '" ++ spec ++ "'")
        get_command_usage()
        return 1

    let resolved_version = conan_install(pkg_name, pkg_version, root, options.force_reinstall)
    if resolved_version.len() == 0:
        return 1
    let loaded_lock = lock_load(root)
    let updated_lock = lock_upsert_installed_c_dep_tree(move loaded_lock, root, pkg_name, resolved_version)
    if updated_lock.entries.len() == 0:
        return 1
    if lock_write(root, updated_lock) != 0:
        return 1
    let manifest_path = root ++ "/with.toml"
    let toml = with_fs_read_file(manifest_path)
    if toml.len() > 0:
        let updated = cli_update_manifest_dep(toml, pkg_name, resolved_version)
        with_fs_write_file(manifest_path, updated)
    with_eprint("added c." ++ pkg_name ++ "@" ++ resolved_version)
    0

fn run_remove_command(argc: i32) -> i32:
    if argc != 3:
        with_eprint("usage: with remove c.<package>")
        return 1
    let spec = with_arg_at(2)
    if not spec.starts_with("c."):
        with_eprint("error: only C packages supported. Use c.<name>")
        return 1
    let pkg_name = spec.slice(2, spec.len())
    if pkg_name.len() == 0:
        with_eprint("error: empty package name")
        return 1
    let root = project_config_find_root(".")
    if root.len() == 0:
        with_eprint("error: no with.toml found. Run 'with init' first.")
        return 1
    let manifest_path = root ++ "/with.toml"
    let toml = with_fs_read_file(manifest_path)
    let removed = cli_remove_manifest_dep(toml, pkg_name)
    if not removed.ok:
        with_eprint("error: dependency c." ++ pkg_name ++ " is not in with.toml")
        return 1
    if with_fs_write_file(manifest_path, removed.text) != 0:
        with_eprint("error: failed to update with.toml")
        return 1
    let dep_root = root ++ "/.with/deps/c/" ++ pkg_name
    if with_fs_file_exists(dep_root) != 0:
        let rm_rc = with_fs_remove_tree(dep_root)
        if rm_rc != 0 and with_fs_file_exists(dep_root) != 0:
            with_eprint("error: failed to remove " ++ dep_root)
            return 1
    if with_fs_file_exists(lock_file_path(root)) != 0:
        let existing_lock = lock_load(root)
        let next_lock = lock_remove(move existing_lock, "c." ++ pkg_name)
        if lock_write(root, next_lock) != 0:
            return 1
    with_eprint("removed c." ++ pkg_name)
    0

fn run_update_command(argc: i32) -> i32:
    if argc != 2:
        with_eprint("usage: with update")
        return 1
    let root = project_config_find_root(".")
    if root.len() == 0:
        with_eprint("error: no with.toml found. Run 'with init' first.")
        return 1
    let manifest_path = root ++ "/with.toml"
    var toml = with_fs_read_file(manifest_path)
    let deps = cli_manifest_c_deps(toml)
    if deps.len() == 0:
        with_eprint("no C dependencies to update")
        return 0
    var next_lock = lock_load(root)
    for i in 0..deps.len() as i32:
        let dep = deps.get(i as i64)
        let resolved_version = conan_install(dep.name, dep.constraint, root, true)
        if resolved_version.len() == 0:
            return 1
        next_lock = lock_upsert_installed_c_dep_tree(move next_lock, root, dep.name, resolved_version)
        if next_lock.entries.len() == 0:
            return 1
        toml = cli_update_manifest_dep(toml, dep.name, resolved_version)
        with_eprint("updated c." ++ dep.name ++ "@" ++ resolved_version)
    if with_fs_write_file(manifest_path, toml) != 0:
        with_eprint("error: failed to update with.toml")
        return 1
    lock_write(root, next_lock)
