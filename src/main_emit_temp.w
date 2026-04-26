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
extern fn with_eprint(s: str) -> void
extern fn with_system(cmd: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_write(s: str) -> void
extern fn exit(code: i32) -> void
extern fn with_install_interrupt_handlers() -> void
extern fn with_raise_stack_limit() -> void

type TestDiscovery {
    parse_ok: bool,
    has_main: bool,
    test_names: Vec[str],
}

fn cli_help_topic(argc: i32) -> str:
    if argc >= 3:
        return with_arg_at(2)
    ""

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
    var emit_obj_mode = false
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
        if arg == "--emit-obj":
            emit_obj_mode = true
        i = i + 1

    // Find the first non-flag positional argument after the command.
    let source_file = find_source_arg(argc)
    let output_path = find_output_arg(argc)

    if command == "build":
        exit(run_build_command(source_file, opt_level, no_std, alloc_mode, emit_c_mode, emit_obj_mode, output_path))
        return
    if command == "run":
        if emit_c_mode:
            with_eprint("error: '--emit-c' is only supported with 'build'")
            exit(1)
            return
        exit(run_run_command(source_file, opt_level, no_std, alloc_mode))
        return
    if command == "ir":
        if source_file == "":
            with_eprint("error: 'ir' requires a source file argument")
            exit(1)
            return
        var comp = Compilation.init()
        comp.configure(opt_level, no_std, alloc_mode)
        let pool = comp.compile_file(source_file)
        if pool.decl_count() == 0:
            with_eprint("error: IR generation failed during compilation")
            exit(1)
            return
        let ok = comp.emit_ir(pool)
        if not ok:
            exit(1)
            return
        return
    if command == "ast":
        if source_file == "":
            with_eprint("error: 'ast' requires a source file argument")
            exit(1)
            return
        exit(dump_ast(source_file, no_std, alloc_mode, deterministic_mode))
        return
    if command == "check":
        if source_file == "":
            with_eprint("error: 'check' requires a source file argument")
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
            with_eprint("error: check failed during compilation")
            exit(1)
            return
        with_write("ok\n")
        comp.print_warnings()
        return
    if command == "tokens":
        if source_file == "":
            with_eprint("error: 'tokens' requires a source file argument")
            exit(1)
            return
        exit(dump_tokens(source_file, deterministic_mode))
        return
    if command == "test":
        exit(run_test_command(argc, opt_level, no_std, alloc_mode))
        return
    if command == "version" or command == "--version":
        with_write("with WITH_VERSION_PLACEHOLDER\n")
        return
    if command == "help" or command == "--help" or command == "-h":
        exit(run_help_command(argc))
        return
    if command == "clean":
        exit(run_clean_command())
        return
    if command == "lsp":
        with_eprint("error: LSP not yet available in self-hosted compiler")
        exit(1)
        return
    if command == "migrate":
        with_eprint("error: migrate not yet available in self-hosted compiler")
        exit(1)
        return
    if command == "repl":
        with_eprint("error: REPL not yet available in self-hosted compiler")
        exit(1)
        return
    if command == "doc":
        with_eprint("error: doc not yet available in self-hosted compiler")
        exit(1)
        return
    if command == "fmt":
        with_eprint("error: fmt not yet available in self-hosted compiler")
        exit(1)
        return

    with_eprint("error: unknown command '{command}'")
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

fn run_build_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool, emit_c_mode: bool, emit_obj_mode: bool, output_path: str) -> i32:
    if source_file == "":
        with_eprint("error: 'build' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
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
    let bin_path = comp.build_binary(source_file)
    if bin_path == "":
        with_eprint("error: build failed")
        return 1
    comp.print_warnings()
    0

fn run_run_command(source_file: str, opt_level: i32, no_std: bool, alloc_mode: bool) -> i32:
    if source_file == "":
        with_eprint("error: 'run' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    let bin_path = comp.build_binary(source_file)
    if bin_path == "":
        with_eprint("error: run command failed to build target")
        return 1
    comp.print_warnings()
    with_system(bin_path)

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

fn dump_resolved_artifact(source_file: str, no_std: bool, alloc_mode: bool) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    let result = comp.resolve_file(source_file, true)
    if comp.has_errors():
        with_eprint("error: resolved dump failed")
        return 1
    let resolved_text = dump_resolved(result, comp.get_pool(), source_file)
    with_write(resolved_text)
    0

fn dump_typed_artifact(source_file: str, no_std: bool, alloc_mode: bool) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    let typed_ok = comp.emit_typed_file(source_file)
    if not typed_ok:
        with_eprint("error: typed dump failed during compilation or semantic analysis")
        return 1
    0

fn dump_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
    let mir_ok = comp.print_mir_file(source_file)
    if not mir_ok:
        with_eprint("error: mir dump failed during compilation or mir lowering")
        return 1
    0

fn dump_async_mir_artifact(source_file: str, no_std: bool, alloc_mode: bool) -> i32:
    var comp = Compilation.init()
    comp.configure(0, no_std, alloc_mode)
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
        if fn_name.starts_with("test_"):
            test_names.push(fn_name)
    TestDiscovery { parse_ok: true, has_main, test_names }

fn synthesize_test_main_source(text: str, test_names: Vec[str]) -> str:
    var out = text
    if out.len() > 0 and out[out.len() - 1] != 10:
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
        out = out ++ text.slice(run_start as i64, text.len() as i64)
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

fn run_test_file(target: str, opt_level: i32, no_std: bool, alloc_mode: bool) -> i32:
    var comp = Compilation.init()
    comp.configure(opt_level, no_std, alloc_mode)
    let synthetic_source = maybe_synthesize_test_source(target)
    let bin_path = if synthetic_source.len() > 0: comp.build_binary_from_source(target, synthetic_source) else: comp.build_binary(target)
    if bin_path == "":
        with_eprint("error: test build failed")
        return 1
    let run_rc = with_system(bin_path)
    cleanup_binary_artifacts(bin_path)
    run_rc

fn run_test_command(argc: i32, opt_level: i32, no_std: bool, alloc_mode: bool) -> i32:
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
            let run_rc = run_test_file(test_file, opt_level, no_std, alloc_mode)
            if run_rc != 0:
                with_eprint("error: test failed in '" ++ test_file ++ "'")
                return run_rc
        return 0
    run_test_file(target, opt_level, no_std, alloc_mode)

fn run_clean_command -> i32:
    let result = with_system("rm -rf .with")
    if result != 0:
        with_eprint("error: clean failed")
        return 1
    with_write("cleaned .with/\n")
    0

fn print_usage:
    with_write("Usage: with <command> [options]\n")
    with_write("\n")
    with_write("Commands:\n")
    with_write("  build [file.w]    Build a source file (use --emit-c to emit C)\n")
    with_write("  run [file.w]      Build + run a source file\n")
    with_write("  check <file.w>    Parse and type-check a source file (supports --dump-tokens/--dump-ast/--dump-resolved/--dump-typed/--dump-mir/--dump-async-mir)\n")
    with_write("  test <file.w|dir> Run tests from a source file or directory\n")
    with_write("  clean             Delete .with/ artifacts\n")
    with_write("  ir <file.w>       Dump LLVM IR (debug)\n")
    with_write("  ast <file.w>      Parse and dump the AST (debug)\n")
    with_write("  tokens <file.w>   Lex and dump tokens (debug)\n")
    with_write("  version           Print compiler version\n")
    with_write("  help [topic]      Show CLI help or language quick reference\n")
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
    if topic == "keywords":
        print_help_keywords()
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
        "  fn let var if else then match for in while loop return break continue goto\n" ++
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
