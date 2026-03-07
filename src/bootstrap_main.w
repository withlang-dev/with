use Compilation

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_eprintln(s: str) -> void
extern fn print(s: str) -> void
extern fn exit(code: i32) -> void
extern fn with_raise_stack_limit() -> void
extern fn with_install_interrupt_handlers() -> void

fn main -> void:
    with_raise_stack_limit()
    with_install_interrupt_handlers()

    let argc = with_arg_count()
    if argc < 2:
        print_usage()
        return

    let command = with_arg_at(1)
    if command == "version" or command == "--version":
        print("with 0.0.1\n")
        return
    if command == "help" or command == "--help" or command == "-h":
        print_usage()
        return
    if command == "build":
        exit(run_build(argc))
        return
    if command == "check":
        exit(run_check(argc))
        return

    with_eprintln("error: bootstrap recovery entry supports only build/check/version/help")
    exit(1)

fn has_output_prefix(arg: str) -> bool:
    if arg.len() < 9:
        return false
    arg.slice(0, 9) == "--output="

fn parse_source_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "-o":
            i = i + 2
            continue
        if has_output_prefix(arg):
            i = i + 1
            continue
        if arg == "--emit-c":
            i = i + 1
            continue
        if arg.len() > 0 and arg[0] != 45:
            return arg
        i = i + 1
    ""

fn has_emit_c_flag(argc: i32) -> bool:
    var i = 2
    while i < argc:
        if with_arg_at(i) == "--emit-c":
            return true
        i = i + 1
    false

fn run_build(argc: i32) -> i32:
    let source_file = parse_source_arg(argc)
    if source_file == "":
        with_eprintln("error: 'build' requires a source file argument")
        return 1
    let emit_c_mode = has_emit_c_flag(argc)
    var comp = Compilation.init()
    comp.configure(0, false, false)
    if emit_c_mode:
        let c_path = comp.emit_c(source_file, "")
        if c_path == "":
            with_eprintln("error: build failed")
            return 1
        with_eprintln("emitted C: " ++ c_path)
        comp.print_warnings()
        return 0
    let bin_path = comp.build_binary(source_file)
    if bin_path == "":
        with_eprintln("error: build failed")
        return 1
    comp.print_warnings()
    0

fn run_check(argc: i32) -> i32:
    let source_file = parse_source_arg(argc)
    if source_file == "":
        with_eprintln("error: 'check' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(0, false, false)
    let pool = comp.compile_file(source_file)
    if pool.decl_count() == 0:
        with_eprintln("error: check failed during compilation")
        return 1
    print("ok\n")
    comp.print_warnings()
    0

fn print_usage:
    print(
        "Usage: with <command> <file.w>\n" ++
        "Commands:\n" ++
        "  build <file.w> [--emit-c] [-o <path>|--output=<path>]\n" ++
        "  check <file.w>\n" ++
        "  version\n" ++
        "  help\n"
    )
