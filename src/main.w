// CLI entry point for the With compiler.
//
// Usage:
//   with run [file.w]     Build + run source file
//   with build [file.w]   Build source file
//   with check <file.w>   Parse and type-check (supports --dump-tokens/--dump-ast)
//   with ir <file.w>      Dump LLVM IR
//   with ast <file.w>     Parse and dump AST
//   with tokens <file.w>  Lex and dump tokens
//   with test [flags]     Run tests
//   with version          Print compiler version
//   with help             Show usage
//
// Direct port of bootstrap/src/main.zig to With.

use Compilation
use Lexer
use Token
use Ast
use render

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_eprintln(s: str) -> void
extern fn with_system(cmd: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn int_to_string(n: i32) -> str
extern fn print(s: str) -> void
extern fn exit(code: i32) -> void

fn main -> void:
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
    var deterministic_mode = false
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
        if arg == "--deterministic":
            deterministic_mode = true
        i = i + 1

    // Find the first non-flag positional argument after the command.
    let source_file = find_source_arg(argc)

    if command == "build":
        exit(run_build_command(source_file, opt_level, no_std, alloc_mode))
        return
    if command == "run":
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
        if arg.len() > 0 and arg[0] != 45: // not '-'
            return arg
        i = i + 1
    ""

fn run_build_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool) -> i32:
    if source_file == "":
        with_eprintln("error: 'build' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
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
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    let pool = comp.compile_file(source_file)
    if pool.decl_count() == 0:
        with_eprintln("error: check failed during compilation")
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

    let rendered = render_module(pool, comp.driver.pool)
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
            let escaped = escape_dump_lexeme(text_slice)
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

fn escape_dump_lexeme(text: str) -> str:
    var out = ""
    for i in 0..text.len():
        let ch = text[i]
        if ch == 92:  // '\'
            out = out ++ "\\\\"
            continue
        if ch == 34:  // '"'
            out = out ++ "\\\""
            continue
        if ch == 10:  // '\n'
            out = out ++ "\\n"
            continue
        if ch == 13:  // '\r'
            out = out ++ "\\r"
            continue
        if ch == 9:  // '\t'
            out = out ++ "\\t"
            continue
        out = out ++ text.slice(i as i64, (i + 1) as i64)
    out

fn dump_tag_name(tag: i32, lexeme: str) -> str:
    // Keep deterministic dump names identical to Stage0 for brace delimiters.
    if tag == TK_L_BRACE() or tag == TK_R_BRACE():
        return "'" ++ lexeme ++ "'"
    tag_name(tag)

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
    print("  build [file.w]    Build a source file\n")
    print("  run [file.w]      Build + run a source file\n")
    print("  check <file.w>    Parse and type-check a source file (supports --dump-tokens/--dump-ast)\n")
    print("  test [file.w]     Run tests\n")
    print("  clean             Delete .with/ artifacts\n")
    print("  ir <file.w>       Dump LLVM IR (debug)\n")
    print("  ast <file.w>      Parse and dump the AST (debug)\n")
    print("  tokens <file.w>   Lex and dump tokens (debug)\n")
    print("  version           Print compiler version\n")
    print("  help              Show this message\n")
