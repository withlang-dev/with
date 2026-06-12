use Compilation

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_eprint(s: str) -> Unit
extern fn with_write(s: str) -> Unit
extern fn exit(code: i32) -> Unit
extern fn with_raise_stack_limit() -> Unit
extern fn with_install_interrupt_handlers() -> Unit

fn cli_help_topic(argc: i32) -> str:
    if argc >= 3:
        return with_arg_at(2)
    ""

fn main -> Unit:
    with_raise_stack_limit()
    with_install_interrupt_handlers()

    let argc = with_arg_count()
    if argc < 2:
        print_usage()
        return

    let command = with_arg_at(1)
    if command == "version" or command == "--version":
        with_write("with WITH_VERSION_PLACEHOLDER\n")
        return
    if command == "help" or command == "--help" or command == "-h":
        exit(run_help(argc))
        return
    if command == "build":
        exit(run_build(argc))
        return
    if command == "check":
        exit(run_check(argc))
        return

    with_eprint("error: bootstrap recovery entry supports only build/check/version/help")
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

fn parse_output_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "-o":
            if i + 1 < argc:
                return with_arg_at(i + 1)
            return ""
        if has_output_prefix(arg):
            return arg.slice(9, arg.len())
        i = i + 1
    ""

fn run_build(argc: i32) -> i32:
    let source_file = parse_source_arg(argc)
    if source_file == "":
        with_eprint("error: 'build' requires a source file argument")
        return 1
    let emit_c_mode = has_emit_c_flag(argc)
    let output_path = parse_output_arg(argc)
    var comp = Compilation.init()
    comp.configure(0, false, false, true)
    if emit_c_mode:
        let c_path = comp.emit_c(source_file, output_path)
        if c_path == "":
            with_eprint("error: build failed")
            return 1
        with_eprint("emitted C: " ++ c_path)
        comp.print_warnings()
        return 0
    let bin_path = comp.build_binary_to_path(source_file, output_path)
    if bin_path == "":
        with_eprint("error: build failed")
        return 1
    comp.print_warnings()
    0

fn run_check(argc: i32) -> i32:
    let source_file = parse_source_arg(argc)
    if source_file == "":
        with_eprint("error: 'check' requires a source file argument")
        return 1
    var comp = Compilation.init()
    comp.configure(0, false, false, true)
    let pool = comp.compile_file(source_file)
    if pool.decl_count() == 0:
        with_eprint("error: check failed during compilation")
        return 1
    with_write("ok\n")
    comp.print_warnings()
    0

fn print_usage:
    with_write(
        "Usage: with <command> <file.w>\n" ++
        "Commands:\n" ++
        "  build <file.w> [--emit-c] [-o <path>|--output=<path>]\n" ++
        "  check <file.w>\n" ++
        "  version\n" ++
        "  help [topic]\n" ++
        "\n" ++
        "Language quick reference:\n" ++
        "  with help use\n" ++
        "  with help fn\n" ++
        "  with help type\n" ++
        "  with help let\n" ++
        "  with help extern\n" ++
        "  with help keywords\n" ++
        "  with help operators\n" ++
        "  with help attributes\n"
    )

fn run_help(argc: i32) -> i32:
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
        "  use c_import(\"sqlite3.h\", link: \"sqlite3\")\n"
    )

fn print_help_fn:
    with_write(
        "Function declarations:\n\n" ++
        "  fn greet(name: str) -> str:\n" ++
        "      \"hello {name}\"\n"
    )

fn print_help_type:
    with_write(
        "Type declarations:\n\n" ++
        "  type Point { x: i32, y: i32 }\n" ++
        "  type Handle = opaque\n" ++
        "  type Alias = i32\n"
    )

fn print_help_let:
    with_write(
        "Bindings and constants:\n\n" ++
        "  let value = 42\n" ++
        "  var total = 0\n" ++
        "  const NAME: str = \"with\"\n"
    )

fn print_help_extern:
    with_write(
        "FFI declarations:\n\n" ++
        "  extern fn puts(text: *const i8) -> i32\n" ++
        "  use c_import(\"sqlite3.h\", link: \"sqlite3\")\n"
    )

fn print_help_keywords:
    with_write(
        "Reserved words:\n\n" ++
        "  fn let var if else match for in while loop return break continue\n" ++
        "  with as mut type trait impl extend dyn use module pub async await spawn\n" ++
        "  unsafe comptime gen yield defer error extern c_import ephemeral select enum\n" ++
        "  true false not and or const it errdefer move where opaque null union\n"
    )

fn print_help_operators:
    with_write(
        "Operator precedence (low to high):\n\n" ++
        "  or\n" ++
        "  and\n" ++
        "  == != in not in\n" ++
        "  < > <= >=\n" ++
        "  |>\n" ++
        "  |\n" ++
        "  ^\n" ++
        "  &\n" ++
        "  << >>\n" ++
        "  + - ++ ??\n" ++
        "  * / %\n" ++
        "  unary: not - & &raw const &raw mut\n" ++
        "  postfix: .await ? .field [i] ()\n"
    )

fn print_help_attributes:
    with_write(
        "Common attributes:\n\n" ++
        "  @[packed]\n" ++
        "  @[inline]\n" ++
        "  @[noinline]\n" ++
        "  @[align(N)]\n"
    )
