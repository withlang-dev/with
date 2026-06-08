use std.build

fn main:
    let options = BuildOptions {
        source_path: "src/main.w",
        output_path: "out/bin/app",
        output_kind: BuildOutputKind.Binary,
        opt_level: 1,
        debug_info: true,
        no_std: false,
        alloc_mode: false,
        prelude_mode: PreludeMode.Full,
        overflow_mode: OverflowMode.Default,
        deterministic: false,
        target: BuildTarget.native,
        include_paths: Vec.new(),
        defines: Vec.new(),
        link_libs: Vec.new(),
        compiler_hooks_enabled: true,
    }
    assert(options.output_kind == BuildOutputKind.Binary)
    assert(options.prelude_mode == PreludeMode.Full)
    assert(options.target == BuildTarget.native)

    let graph = BuildGraphOptions {
        selected_target: "test",
        graph_only: true,
        dry_run: false,
        no_deps: false,
    }
    assert(graph.selected_target == "test")
    assert(graph.graph_only)

    let migrate = MigrateOptions {
        source_path: "input.c",
        output_path: "out",
        include_paths: Vec.new(),
        forced_includes: Vec.new(),
        defines: Vec.new(),
        exclude_basenames: Vec.new(),
        check_mode: false,
        diff_mode: false,
        stats_mode: false,
        no_c_export: true,
        c_export_functions: false,
        convert_goto_to_structured: false,
        block_style: 0,
        width_slice: 8,
        shared_defs: "",
        migrate_one: "",
        shared_fragment: "",
        ir_roundtrip: false,
    }
    assert(migrate.no_c_export)
    assert(migrate.width_slice == 8)
    print("ok")
