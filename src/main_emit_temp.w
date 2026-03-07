// CLI entry point for With compiler.

use Compilation
use Lexer
use Token
use Ast
use render
use Resolve
use Parser
use InternPool
use Diagnostic
use Source

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_eprintln(s: str) -> void
extern fn with_system(cmd: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn int_to_string(n: i32) -> str
extern fn print(s: str) -> void
extern fn exit(code: i32) -> void
extern fn with_install_interrupt_handlers() -> void
extern fn with_raise_stack_limit() -> void

fn main -> void:
    with_raise_stack_limit()
    with_install_interrupt_handlers()
    let argc = with_arg_count()
    if argc < 2:
        print_usage()
        return

    let command = with_arg_at(1)

    // Parse flags from remaining args.
    var opt_level = 0
    var no_std = false
    var alloc_mode = false
    var release_mode = false
    var dump_tokens_flag = false
    var dump_ast_flag = false
    var dump_resolved_flag = false
    var dump_typed_flag = false
    var dump_mir_flag = false
    var dump_async_mir_flag = false
    var deterministic_mode = false
    var emit_c_mode = false
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "-O0":
            opt_level = 0
        if arg == "-O1":
            opt_level = 1
        if arg == "-O2":
            opt_level = 2
        if arg == "-O3":
            opt_level = 3
        if arg == "--release":
            release_mode = true
            if opt_level < 2:
                opt_level = 2
        if arg == "--no-std":
            no_std = true
        if arg == "--alloc":
            alloc_mode = true
        if arg == "--dump-tokens":
            dump_tokens_flag = true
        if arg == "--dump-ast":
            dump_ast_flag = true
        if arg == "--dump-resolved":
            dump_resolved_flag = true
        if arg == "--dump-typed":
            dump_typed_flag = true
        if arg == "--dump-mir":
            dump_mir_flag = true
        if arg == "--dump-async-mir":
            dump_async_mir_flag = true
        if arg == "--deterministic":
            deterministic_mode = true
        if arg == "--emit-c":
            emit_c_mode = true
        i = i + 1

    // Find the first non-flag positional argument after the command.
    let source_file = find_source_arg(argc)
    let output_path = find_output_arg(argc)

    if command == "build":
        exit(run_build_command(source_file, opt_level, no_std, alloc_mode, emit_c_mode, output_path))
        return
    if command == "run":
        if emit_c_mode:
            with_eprintln("error: '--emit-c' is only supported with 'build'")
            exit(1)
            return
        exit(run_run_command(source_file, opt_level, no_std, alloc_mode))
        return
    if command == "ir":
        if source_file == "":
            with_eprintln("error: 'ir' requires a source file argument")
            exit(1)
            return
        var comp = Compilation.init()
        comp.configure(opt_level, no_std, alloc_mode)
        let pool = comp.compile_file(source_file)
        if pool.decl_count() == 0:
            with_eprintln("error: IR generation failed during compilation")
            exit(1)
            return
        let ok = comp.emit_ir(pool)
        if not ok:
            exit(1)
            return
        return
    if command == "ast":
        if source_file == "":
            with_eprintln("error: 'ast' requires a source file argument")
            exit(1)
            return
        exit(dump_ast(source_file, no_std, alloc_mode, deterministic_mode))
        return
    if command == "check":
        if source_file == "":
            with_eprintln("error: 'check' requires a source file argument")
            exit(1)
            return
        if dump_tokens_flag:
            let rc_tokens = dump_tokens(source_file, true)
            if rc_tokens != 0:
                exit(rc_tokens)
                return
            if not dump_ast_flag:
                exit(0)
                return
        if dump_ast_flag:
            exit(dump_ast(source_file, no_std, alloc_mode, true))
            return
        if dump_resolved_flag:
            exit(dump_resolved_artifact(source_file, no_std, alloc_mode))
            return
        if dump_typed_flag:
            exit(dump_typed_artifact(source_file, no_std, alloc_mode))
            return
        if dump_mir_flag:
            exit(dump_mir_artifact(source_file, no_std, alloc_mode))
            return
        if dump_async_mir_flag:
            exit(dump_async_mir_artifact(source_file, no_std, alloc_mode))
            return
        var comp = Compilation.init()
        comp.configure(0, no_std, alloc_mode)
        let pool = comp.compile_file(source_file)
        if pool.decl_count() == 0:
            with_eprintln("error: check failed during compilation")
            exit(1)
            return
        print("ok\n")
        comp.print_warnings()
        return
    if command == "tokens":
        if source_file == "":
            with_eprintln("error: 'tokens' requires a source file argument")
            exit(1)
            return
        exit(dump_tokens(source_file, deterministic_mode))
        return
    if command == "test":
        exit(run_test_command(argc, opt_level, no_std, alloc_mode))
        return
    if command == "version" or command == "--version":
        print("with 0.0.1\n")
        return
    if command == "help" or command == "--help" or command == "-h":
        print_usage()
        return
    if command == "clean":
        exit(run_clean_command())
        return
    if command == "lsp":
        with_eprintln("error: LSP not yet available in self-hosted compiler")
        exit(1)
        return
    if command == "migrate":
        with_eprintln("error: migrate not yet available in self-hosted compiler")
        exit(1)
        return
    if command == "repl":
        with_eprintln("error: REPL not yet available in self-hosted compiler")
        exit(1)
        return
    if command == "doc":
        with_eprintln("error: doc not yet available in self-hosted compiler")
        exit(1)
        return
    if command == "fmt":
        with_eprintln("error: fmt not yet available in self-hosted compiler")
        exit(1)
        return

    with_eprintln("error: unknown command '{command}'")
    print_usage()
    exit(1)

// ── Command implementations ──────────────────────────────────────

fn find_source_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "-o":
            i = i + 2
            continue
        if arg.starts_with("--output="):
            i = i + 1
            continue
        if arg.len() > 0 and arg[0] != 45: // not '-'
            return arg
        i = i + 1
    ""

fn find_output_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "-o":
            if i + 1 < argc:
                return with_arg_at(i + 1)
            return ""
        if arg.starts_with("--output="):
            return arg.slice(9, arg.len() as i64)
        i = i + 1
    ""

fn run_build_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool, emit_c_mode: bool, output_path: str) -> i32:
    if source_file == "":
        with_eprintln("error: 'build' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
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
    let bin_path = comp.build_binary(source_file)
    if bin_path == "":
        with_eprintln("error: build failed")
        return 1
    comp.print_warnings()
    0

fn run_run_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool) -> i32:
    if source_file == "":
        with_eprintln("error: 'run' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    let bin_path = comp.build_binary(source_file)
    if bin_path == "":
        with_eprintln("error: run command failed to build target")
        return 1
    comp.print_warnings()
    with_system(bin_path)

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
    if kind == NK_FN_DECL(): return "function"
    if kind == NK_TYPE_DECL(): return "type_decl"
    if kind == NK_USE_DECL(): return "use_decl"
    if kind == NK_LET_DECL(): return "let_decl"
    if kind == NK_EXTERN_FN(): return "extern_fn"
    if kind == NK_C_IMPORT(): return "c_import"
    if kind == NK_TRAIT_DECL(): return "trait_decl"
    if kind == NK_IMPL_DECL(): return "impl_decl"
    if kind == NK_POISONED_DECL(): return "poisoned"
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

fn dump_resolved_artifact(source_file: str, no_std: bool, alloc_mode: bool) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    let result = comp.driver.resolve_file(source_file, true)
    if comp.driver.diagnostics.has_errors():
        with_eprintln("error: resolved dump failed")
        return 1
    let resolved_text = dump_resolved(result, comp.driver.pool, source_file)
    print(resolved_text)
    0

fn dump_typed_artifact(source_file: str, no_std: bool, alloc_mode: bool) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    comp.driver.set_emit_typed_during_compile(1)
    let pool = comp.compile_file(source_file)
    if pool.decl_count() == 0:
        with_eprintln("error: typed dump failed during compilation")
        return 1
    if comp.driver.did_emit_typed_during_compile() != 0:
        return 0
    // Stream typed output directly to stdout to avoid constructing a very
    // large immutable string via repeated `++` concatenation.
    if not comp.driver.emit_typed(pool):
        with_eprintln("error: typed dump failed during semantic analysis or emission")
        return 1
    0

fn dump_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    let pool = comp.compile_file(source_file)
    if pool.decl_count() == 0:
        with_eprintln("error: mir dump failed during compilation")
        return 1
    if not comp.driver.print_mir(pool):
        with_eprintln("error: mir dump failed during mir lowering")
        return 1
    0

fn dump_async_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    let pool = comp.compile_file(source_file)
    if pool.decl_count() == 0:
        with_eprintln("error: async-mir dump failed during compilation")
        return 1
    let async_mir_text = comp.driver.dump_async_mir(pool)
    if async_mir_text.len() == 0:
        with_eprintln("error: async-mir dump failed during lowering")
        return 1
    print(async_mir_text)
    0

fn escape_dump_lexeme(text: str) -> str:
    var out = ""
    var run_start = 0
    for i in 0..text.len():
        let ch = text[i]
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
        out = out ++ text.slice(run_start as i64, text.len() as i64)
    out

fn dump_tag_name(tag: i32, lexeme: str) -> str:
    // Keep deterministic dump names identical to Stage0 for brace delimiters.
    if tag == TK_L_BRACE():
        return "'" ++ lexeme ++ "'"
    if tag == TK_R_BRACE():
        return "'" ++ lexeme ++ "'"
    return tag_name(tag)

fn run_test_command(argc: i32, opt_level: i32, no_std: bool, alloc_mode: bool) -> i32:
    // Find test file/dir argument
    let target = find_source_arg(argc)
    if target == "":
        with_eprintln("error: 'test' requires a source file or directory argument")
        return 1
    // Compile and run as test
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    let bin_path = comp.build_binary(target)
    if bin_path == "":
        with_eprintln("error: test build failed")
        return 1
    with_system(bin_path)

fn run_clean_command -> i32:
    let result = with_system("rm -rf .with")
    if result != 0:
        with_eprintln("error: clean failed")
        return 1
    print("cleaned .with/\n")
    0

fn print_usage:
    print("Usage: with <command> [options]\n")
    print("\n")
    print("Commands:\n")
    print("  build [file.w]    Build a source file (use --emit-c to emit C)\n")
    print("  run [file.w]      Build + run a source file\n")
    print("  check <file.w>    Parse and type-check a source file (supports --dump-tokens/--dump-ast/--dump-resolved/--dump-typed/--dump-mir/--dump-async-mir)\n")
    print("  test [file.w]     Run tests\n")
    print("  clean             Delete .with/ artifacts\n")
    print("  ir <file.w>       Dump LLVM IR (debug)\n")
    print("  ast <file.w>      Parse and dump the AST (debug)\n")
    print("  tokens <file.w>   Lex and dump tokens (debug)\n")
    print("  version           Print compiler version\n")
    print("  help              Show this message\n")
