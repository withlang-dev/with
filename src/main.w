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
extern fn with_eprint(s: str) -> void
extern fn with_ewrite(s: str) -> void
extern fn with_system(cmd: str) -> i32
extern fn with_exec_binary(path: str) -> i32
extern fn with_exec_argv(args: str) -> i32
extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32
extern fn with_fs_read_file(path: str) -> str
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
    expect_check_stdout: Vec[str],
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
        let parsed_build = parse_build_command_options(argc)
        if not parsed_build.ok:
            with_eprint("error: " ++ parsed_build.error_msg)
            return 1
        return run_build_command(parsed_build.build, parsed_build.graph)
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
        with_write("with " ++ "WITH_VERSION" ++ "_PLACEHOLDER\n")
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

fn build_tool_eval_entry_source() -> str:
    "use std.build\n" ++
    "use build\n\n" ++
    "fn __with_build_eval_entry(ctx: BuildCtx) -> Build:\n" ++
    "    build(ctx)\n"

type BuildGraphLoadResult {
    graph: BuildGraph,
    sema: Sema,
}

fn run_build_action_from_build_w(root: str, cfg: ProjectConfig, target: BuildGraphTarget, sema: Sema) -> i32:
    if target.output.len() == 0:
        with_eprint("error: action target '" ++ target.name ++ "' requires a declared output")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if with_fs_file_exists(input_path) == 0:
            with_eprint("error: action target '" ++ target.name ++ "' missing declared input: " ++ input_path)
            return 1
    let output_path = build_graph_resolve_project_path(root, target.output)
    let output_dir = build_graph_dirname(output_path)
    if with_fs_mkdir_p(output_dir) != 0:
        with_eprint("error: action target '" ++ target.name ++ "' could not create output directory: " ++ output_dir)
        return 1
    if target.action_fn == 0:
        with_eprint("error: action target '" ++ target.name ++ "' is missing an evaluator action function")
        return 1
    var action_sema = sema
    let result = comptime_eval_tool_action_result(&raw mut action_sema as *mut Sema, action_sema.ast, action_sema.pool, target.action_fn, cfg.package_name, cfg.package_version, root, target.name, target.inputs, target.output, target.extra_outputs, target.args, target.write_scopes)
    if result.runtime_exit_code != 0:
        if result.runtime_stderr.len() > 0:
            with_ewrite(result.runtime_stderr)
        with_eprint("error: action target '" ++ target.name ++ f"' failed with exit code {result.runtime_exit_code}")
        return result.runtime_exit_code
    if result.error_msg.len() > 0:
        with_eprint("error: action target '" ++ target.name ++ "' failed during comptime evaluation: " ++ result.error_msg ++ "\n")
        return 1
    if result.value.kind != ComptimeValueKind.CV_INT and result.value.kind != ComptimeValueKind.CV_BOOL:
        with_eprint("error: action target '" ++ target.name ++ "' did not return an integer exit code")
        return 1
    let rc = result.value.data0 as i32
    if rc != 0:
        with_eprint("error: action target '" ++ target.name ++ f"' failed with exit code {rc}")
        return rc
    if with_fs_file_exists(output_path) == 0:
        with_eprint("error: action target '" ++ target.name ++ "' did not produce declared output: " ++ output_path)
        return 1
    for oi in 0..target.extra_outputs.len() as i32:
        let extra_output = build_graph_resolve_project_path(root, target.extra_outputs.get(oi as i64))
        if with_fs_file_exists(extra_output) == 0:
            with_eprint("error: action target '" ++ target.name ++ "' did not produce declared output: " ++ extra_output)
            return 1
    0

fn load_build_graph_from_build_w(root: str, cfg: ProjectConfig, options: BuildCommandOptions) -> BuildGraphLoadResult:
    var graph = empty_build_graph()
    let entry_path = resolve_join(root, "__with_build_eval.w")
    var comp = Compilation.init()
    comp.configure_options(options)
    comp.set_tool_mode_entry_path(entry_path)
    let pool = comp.compile_source_text_with_config(entry_path, build_tool_eval_entry_source(), cfg)
    var sema = comp.zcu.last_sema
    if pool.decl_count() == 0 or comp.has_errors():
        graph.error_msg = "build.w evaluation wrapper compilation failed"
        return BuildGraphLoadResult { graph, sema }
    let entry_sym = sema.pool_lookup_symbol("__with_build_eval_entry")
    if entry_sym == 0:
        graph.error_msg = "build.w evaluation entry was not typechecked"
        return BuildGraphLoadResult { graph, sema }
    let eval_result = comptime_eval_tool_build_result(&raw mut sema as *mut Sema, sema.ast, sema.pool, entry_sym, cfg.package_name, cfg.package_version, root)
    if eval_result.error_msg.len() > 0:
        graph.ok = false
        graph.error_msg = eval_result.error_msg
        return BuildGraphLoadResult { graph, sema }
    graph = materialize_build_graph_from_comptime(sema, eval_result.value, eval_result.extras)
    BuildGraphLoadResult { graph, sema }

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

fn build_graph_run_tool_capture(root: str, target: BuildGraphTarget, tool_name: str, argv: str, timeout_ms: i32) -> i32:
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

fn build_graph_run_cli_capture(root: str, target: BuildGraphTarget, compiler_path: str, label: str, argv_tail: str, timeout_ms: i32) -> TestRunResult:
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

fn build_options_for_graph_target(root: str, base: BuildCommandOptions, target: BuildGraphTarget) -> BuildCommandOptions:
    var options = base
    if target.optimize_mode == 1 and options.opt_level < 2:
        options.opt_level = 2
    options.target_kind = target.target_kind
    options.include_paths = build_graph_resolve_paths(root, target.include_paths)
    options.defines = target.defines
    options.link_libs = target.system_libs
    if target.kind == 1 or target.kind == 4:
        options.output_kind = BuildOutputKind.Archive
    else if target.kind == 3:
        options.output_kind = BuildOutputKind.Object
    else:
        options.output_kind = BuildOutputKind.Binary
    options

fn run_build_graph(root: str, cfg: ProjectConfig, graph: BuildGraph, action_sema: Sema, options: BuildCommandOptions) -> i32:
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
        let standard_result = build_graph_dispatch_standard_target(root, target, completed_targets)
        if standard_result.handled:
            if standard_result.rc != 0:
                return standard_result.rc
            completed_targets.push(target.name)
            continue
        if target.kind == 23:
            let action_rc = run_build_action_from_build_w(root, cfg, target, action_sema)
            if action_rc != 0:
                return action_rc
            completed_targets.push(target.name)
            continue
        let source_path = resolve_join(root, target.entry)
        let target_options = build_options_for_graph_target(root, options, target)
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
                    let test_rc = run_test_file_with_build_settings(test_path, target_options.opt_level, target_options.no_std, target_options.alloc_mode, target_options.prelude_mode, target_options.debug_info, false, false, "", target_options.include_paths, target_options.defines, target_options.link_libs)
                    if test_rc != 0:
                        with_eprint("error: build.w test target failed: " ++ target.name)
                        return test_rc
            if build_graph_path_has_glob(target.entry):
                with_write(f"ok: {test_files.len()} files passed in build.w test target {target.name}\n")
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
        completed_targets.push(target.name)
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
        if project_config_file_exists(build_path):
            if actual_options.output_kind != BuildOutputKind.Binary:
                with_eprint("error: build.w tool-mode only supports binary builds")
                return 1
            let load_result = load_build_graph_from_build_w(root, cfg, actual_options)
            let graph = load_result.graph
            if not graph.ok:
                with_eprint("error: " ++ graph.error_msg)
                return 1
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
            if graph_options.graph_only or graph_options.dry_run:
                with_write(selected_graph.raw_text)
                return 0
            return run_build_graph(root, cfg, selected_graph, load_result.sema, actual_options)
        actual_source = root ++ "/src/main.w"
        actual_options.source_path = actual_source
        if actual_options.output_path == "" and cfg.package_name.len() > 0:
            actual_options.output_path = "out/bin/" ++ cfg.package_name
    if graph_options.no_deps:
        with_eprint("error: --no-deps is only supported for build.w action targets")
        return 1
    var comp = Compilation.init()
    comp.configure_options(actual_options)
    if actual_options.output_kind == BuildOutputKind.C:
        let c_path = comp.emit_c(actual_options.source_path, actual_options.output_path)
        if c_path == "":
            with_eprint("error: build failed")
            return 1
        with_eprint("emitted C: " ++ c_path)
        with_eprint("compile with zig cc (example):")
        with_eprint("  zig cc -target <triple> -I runtime " ++ c_path ++ " runtime/with_runtime.c runtime/helpers.c runtime/fiber.c runtime/fiber_asm_<arch>.s -o <output>")
        comp.print_warnings()
        return 0
    if actual_options.output_kind == BuildOutputKind.Object:
        var obj_path = actual_options.output_path
        if obj_path == "":
            obj_path = link_stage_output_path_for_source(actual_options.source_path) ++ ".o"
        let result = comp.emit_object_to_path(actual_options.source_path, obj_path)
        if result == "":
            with_eprint("error: build failed")
            return 1
        comp.print_warnings()
        return 0
    let bin_path = comp.build_binary_to_path(actual_options.source_path, actual_options.output_path)
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
    let expect_check_stdout_prefix = "//! expect-check-stdout: "
    let expect_check_fail_prefix = "//! expect-check-fail: "
    let expect_error_prefix = "//! expect-error: "
    let expect_build_fail_prefix = "//! expect-build-fail: "
    let args_prefix = "//! args: "
    let skip_prefix = "//! skip: "
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

fn test_directives_have_run_expectations(directives: TestDirectives) -> bool:
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

fn run_test_compiler_command(target: str, command_name: str, directives: TestDirectives) -> TestRunResult:
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

fn run_test_directive_command(target: str, directives: TestDirectives, quiet: bool) -> i32:
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
    if directives.expect_check_stdout.len() > 0:
        let result = run_test_compiler_command(target, "check", directives)
        if result.rc != 0:
            emit_test_stage_error(f"check failed with exit code {result.rc}", target, "check", "")
            return 1
        for i in 0..directives.expect_check_stdout.len() as i32:
            let expected = directives.expect_check_stdout.get(i as i64)
            if not test_output_contains_expected(result.stdout, expected):
                emit_test_stage_error("missing expected check stdout: " ++ expected, target, "check", "")
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
    let directives = parse_test_directives_for_target(target)
    let directive_rc = run_test_directive_command(target, directives, quiet)
    if directive_rc >= 0:
        return directive_rc
    let discovery = discover_tests_for_target(target)
    let effective_opt_level = test_effective_opt_level(opt_level, directives.extra_args)
    let effective_no_std = no_std or test_extra_arg_present(directives.extra_args, "--no-std") or test_extra_arg_present(directives.extra_args, "--freestanding")
    let effective_prelude_mode = test_effective_prelude_mode(prelude_mode, directives.extra_args)
    var comp = Compilation.init()
    comp.configure(effective_opt_level, effective_no_std, alloc_mode)
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
        var build_options = build_command_options_default()
        build_options.opt_level = opt_level
        build_options.no_std = no_std
        build_options.alloc_mode = alloc_mode
        build_options.prelude_mode = prelude_mode
        build_options.debug_info = debug_info
        var graph_options = build_graph_command_options_default()
        graph_options.selected_target = "test"
        return run_build_command(build_options, graph_options)
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
    var reinvoke_args = ""
    var ai = 2
    while ai < argc:
        let arg = with_arg_at(ai)
        if arg == "-o" and ai + 1 < argc:
            output_path = with_arg_at(ai + 1)
            ai = ai + 2
            continue
        if arg == "-I" and ai + 1 < argc:
            migrate_add_include_path(with_arg_at(ai + 1))
            reinvoke_args = f"{reinvoke_args} -I {test_shell_quote(with_arg_at(ai + 1))}"
            ai = ai + 2
            continue
        if arg == "-include" and ai + 1 < argc:
            migrate_add_forced_include(with_arg_at(ai + 1))
            reinvoke_args = f"{reinvoke_args} -include {test_shell_quote(with_arg_at(ai + 1))}"
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
    "pub fn build(ctx: BuildCtx) -> Build:\n" ++
    "    var out = ctx.new_build()." ++ product_kind ++ "(\"" ++ name ++ "\", \"" ++ entry ++ "\")\n" ++
    "    var tests = target_new(.Test, \"test\", \"tests/*.w\")\n" ++
    "    out = out.add_target(tests)\n" ++
    "    out.default(\"" ++ name ++ "\")\n"

fn cli_init_readme_template(name: str, is_lib: bool) -> str:
    let run_line = if is_lib: "with build" else: "with run src/main.w"
    "# " ++ name ++ "\n\n" ++
    "Generated by `with init`.\n\n" ++
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
    ".with/\n" ++
    "out/\n" ++
    "*.o\n" ++
    "*.dSYM/\n"

fn cli_init_main_template() -> str:
    "fn main:\n" ++
    "    print(\"Hello, With!\")\n"

fn cli_init_lib_template(name: str) -> str:
    "// " ++ name ++ " library\n\n" ++
    "pub fn hello -> str:\n" ++
    "    \"Hello from " ++ name ++ "!\"\n"

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
    let tests_dir = resolve_join(target_dir, "tests")
    let lib_path = resolve_join(src_dir, "lib.w")
    let main_path = resolve_join(src_dir, "main.w")
    let smoke_test_path = resolve_join(tests_dir, "smoke.w")
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
    if cli_init_file_must_not_exist(smoke_test_path) != 0:
        return 1

    if with_fs_mkdir_p(src_dir) != 0:
        with_eprint("error: failed to create " ++ src_dir ++ " directory")
        return 1
    if with_fs_mkdir_p(tests_dir) != 0:
        with_eprint("error: failed to create " ++ tests_dir ++ " directory")
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
    if is_lib:
        if cli_init_write_new_file(lib_path, cli_init_lib_template(name)) != 0:
            return 1
    else:
        if cli_init_write_new_file(main_path, cli_init_main_template()) != 0:
            return 1
    if cli_init_write_new_file(smoke_test_path, cli_init_test_template()) != 0:
        return 1

    if is_lib:
        with_eprint("created " ++ created_path ++ " (library)")
    else:
        with_eprint("created " ++ created_path)
    cli_init_report_path(manifest_path)
    cli_init_report_path(build_path)
    cli_init_report_path(readme_path)
    cli_init_report_path(gitignore_path)
    cli_init_report_path(agents_path)
    cli_init_report_path(claude_path)
    if is_lib:
        cli_init_report_path(lib_path)
    else:
        cli_init_report_path(main_path)
    cli_init_report_path(smoke_test_path)
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
