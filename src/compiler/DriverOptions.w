// Structured CLI option values for compiler-driver commands.

extern fn with_arg_at(idx: i32) -> str
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_str_len(s: str) -> i64
extern fn with_str_byte_at(s: str, index: i64) -> i32
extern fn with_str_slice(s: str, start: i64, end: i64) -> str

pub enum BuildOutputKind: i32:
    Binary = 0
    Object = 1
    C = 2
    LlvmIr = 3
    Archive = 4

pub enum DriverPreludeMode: i32:
    Full = 0
    Core = 1
    None = 2

pub type BuildCommandOptions {
    source_path: str,
    output_path: str,
    output_kind: BuildOutputKind,
    opt_level: i32,
    debug_info: bool,
    no_std: bool,
    alloc_mode: bool,
    runtime_available: bool,
    prelude_mode: i32,
    deterministic: bool,
    target_kind: i32,
    include_paths: Vec[str],
    defines: Vec[str],
    link_libs: Vec[str],
    compiler_hooks_enabled: bool,
}

pub type BuildGraphCommandOptions {
    selected_target: str,
    graph_only: bool,
    dry_run: bool,
    no_deps: bool,
    explain_target: str,
}

pub type TestCommandOptions {
    filter: str,
    verbose: bool,
    quiet: bool,
}

pub type MigrateCommandOptions {
    source_path: str,
    output_path: str,
    include_paths: Vec[str],
    forced_includes: Vec[str],
    defines: Vec[str],
    exclude_basenames: Vec[str],
    check_mode: bool,
    diff_mode: bool,
    stats_mode: bool,
    no_c_export: bool,
    c_export_functions: bool,
    convert_goto_to_structured: bool,
    block_style: i32,
    width_slice: i32,
    shared_defs: str,
    migrate_one: str,
    shared_fragment: str,
    ir_roundtrip: bool,
}

pub type BuildCommandParseResult {
    ok: bool,
    error_msg: str,
    build: BuildCommandOptions,
    graph: BuildGraphCommandOptions,
}

pub fn build_command_options_default -> BuildCommandOptions:
    BuildCommandOptions {
        source_path: "",
        output_path: "",
        output_kind: BuildOutputKind.Binary,
        opt_level: 1,
        debug_info: true,
        no_std: false,
        alloc_mode: false,
        runtime_available: true,
        prelude_mode: DriverPreludeMode.Full,
        deterministic: false,
        target_kind: 0,
        include_paths: Vec.new(),
        defines: Vec.new(),
        link_libs: Vec.new(),
        compiler_hooks_enabled: true,
    }

pub fn build_graph_command_options_default -> BuildGraphCommandOptions:
    BuildGraphCommandOptions {
        selected_target: "",
        graph_only: false,
        dry_run: false,
        no_deps: false,
        explain_target: "",
    }

pub fn migrate_command_options_default -> MigrateCommandOptions:
    MigrateCommandOptions {
        source_path: "",
        output_path: "",
        include_paths: Vec.new(),
        forced_includes: Vec.new(),
        defines: Vec.new(),
        exclude_basenames: Vec.new(),
        check_mode: false,
        diff_mode: false,
        stats_mode: false,
        no_c_export: false,
        c_export_functions: false,
        convert_goto_to_structured: false,
        block_style: 0,
        width_slice: 0,
        shared_defs: "",
        migrate_one: "",
        shared_fragment: "",
        ir_roundtrip: false,
    }

fn driver_has_output_prefix(arg: str) -> bool:
    if with_str_len(arg) < 9:
        return false
    with_str_starts_with(arg, "--output=") != 0

fn driver_is_build_target_selector(arg: str) -> bool:
    with_str_len(arg) > 1 and with_str_byte_at(arg, 0) == 58

fn driver_has_flag(argc: i32, flag: str) -> bool:
    var i = 2
    while i < argc:
        if with_arg_at(i) == flag:
            return true
        i = i + 1
    false

fn driver_build_source_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        var step = 1
        var skip = false
        if arg == "-o":
            step = 2
            skip = true
        if not skip and (arg == "--output" or arg == "--filter" or arg == "-f" or arg == "--explain"):
            step = 2
            skip = true
        if not skip and driver_has_output_prefix(arg):
            skip = true
        if not skip:
            if with_str_len(arg) > 0:
                if with_str_byte_at(arg, 0) != 45 and not driver_is_build_target_selector(arg):
                    return arg
        i = i + step
    ""

fn driver_output_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "-o" or arg == "--output":
            if i + 1 < argc:
                return with_arg_at(i + 1)
            return ""
        if driver_has_output_prefix(arg):
            return with_str_slice(arg, 9, with_str_len(arg))
        i = i + 1
    ""

fn driver_explain_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "--explain":
            if i + 1 < argc:
                return with_arg_at(i + 1)
            return ""
        i = i + 1
    ""

fn driver_build_target_arg(argc: i32) -> str:
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if driver_is_build_target_selector(arg):
            return with_str_slice(arg, 1, with_str_len(arg))
        i = i + 1
    ""

fn driver_build_opt_level(argc: i32) -> i32:
    var level = 1
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

type DriverPreludeParseResult {
    ok: bool,
    mode: i32,
    invalid_value: str,
}

fn driver_parse_prelude_mode(argc: i32) -> DriverPreludeParseResult:
    var mode = DriverPreludeMode.Full
    var i = 2
    while i < argc:
        let arg = with_arg_at(i)
        if arg == "--no-prelude" or arg == "--freestanding":
            mode = DriverPreludeMode.None
        else if with_str_starts_with(arg, "--prelude=") != 0:
            let value = with_str_slice(arg, 10, with_str_len(arg))
            if value == "core":
                mode = DriverPreludeMode.Core
            else if value == "full":
                mode = DriverPreludeMode.Full
            else if value == "none":
                mode = DriverPreludeMode.None
            else:
                return DriverPreludeParseResult { false, DriverPreludeMode.Full, value }
        i = i + 1
    DriverPreludeParseResult { true, mode, "" }

pub fn parse_build_command_options(argc: i32) -> BuildCommandParseResult:
    var build = build_command_options_default()
    var graph = build_graph_command_options_default()
    build.source_path = driver_build_source_arg(argc)
    build.output_path = driver_output_arg(argc)
    build.opt_level = driver_build_opt_level(argc)
    build.no_std = driver_has_flag(argc, "--no-std") or driver_has_flag(argc, "--freestanding")
    build.alloc_mode = driver_has_flag(argc, "--alloc")
    build.runtime_available = not driver_has_flag(argc, "--no-runtime") and not driver_has_flag(argc, "--freestanding")
    build.debug_info = not driver_has_flag(argc, "-g0") and not driver_has_flag(argc, "--release")
    build.deterministic = driver_has_flag(argc, "--deterministic")
    let prelude = driver_parse_prelude_mode(argc)
    if not prelude.ok:
        return BuildCommandParseResult {
            ok: false,
            error_msg: "invalid --prelude value '" ++ prelude.invalid_value ++ "' (expected full|core|none)",
            build,
            graph,
        }
    build.prelude_mode = prelude.mode

    let emit_c = driver_has_flag(argc, "--emit-c")
    let emit_obj = driver_has_flag(argc, "--emit-obj")
    if emit_c and emit_obj:
        return BuildCommandParseResult {
            ok: false,
            error_msg: "--emit-c and --emit-obj are mutually exclusive",
            build,
            graph,
        }
    if emit_c:
        build.output_kind = BuildOutputKind.C
    else if emit_obj:
        build.output_kind = BuildOutputKind.Object

    graph.selected_target = driver_build_target_arg(argc)
    graph.graph_only = driver_has_flag(argc, "--graph")
    graph.dry_run = driver_has_flag(argc, "--dry-run")
    graph.no_deps = driver_has_flag(argc, "--no-deps")
    graph.explain_target = driver_explain_arg(argc)
    BuildCommandParseResult { ok: true, error_msg: "", build, graph }
