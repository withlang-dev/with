//! expect-stdout: ok

use compiler.Link
use compiler.ProjectConfig
use BuildGraphModel
use BuildGraphCache
use std.fs

fn main:
    var paths: List[str] = List.new()
    paths.push("$ORIGIN/native libs")
    paths.push("@executable_path/lib,more")
    paths.push("relative $literal")
    for os in ["Linux", "Macos"]:
        let driver = link_stage_rpath_driver_args(paths, os)
        assert(driver.len() == 12)
        for i in 0..3:
            assert(driver[i * 4] == "-Xlinker")
            assert(driver[i * 4 + 1] == "-rpath")
            assert(driver[i * 4 + 2] == "-Xlinker")
            assert(driver[i * 4 + 3] == paths[i])
        let direct = link_stage_driver_args_for_ld(driver)
        assert(direct.len() == 6)
        for i in 0..3:
            assert(direct[i * 2] == "-rpath")
            assert(direct[i * 2 + 1] == paths[i])
    assert(link_stage_rpath_driver_args(paths, "Windows").len() == 0)
    assert(link_stage_rpath_driver_args(paths, "Wasi").len() == 0)

    let graph_text = "WITH_BUILD_GRAPH\t2\npackage\tdemo\t1\ntarget\t0\tlinked\tsrc/main.w\t0\t0\tout/linked\nlibrary_path\t0\tnative libs $literal\nrpath\t0\t$ORIGIN/lib,more\ntarget\t0\tplain\tsrc/main.w\t0\t0\tout/plain\n"
    let graph = parse_build_graph(graph_text)
    assert(graph.ok)
    assert(graph.targets[0].library_paths[0] == "native libs $literal")
    assert(graph.targets[0].rpaths[0] == "$ORIGIN/lib,more")
    assert(graph.targets[1].library_paths.len() == 0)
    assert(graph.targets[1].rpaths.len() == 0)
    let roundtrip = parse_build_graph(build_graph_emit(graph))
    assert(roundtrip.ok)
    assert(roundtrip.targets[0].rpaths[0] == "$ORIGIN/lib,more")
    let selected = build_graph_filter_single_target(roundtrip, "linked")
    assert(selected.ok)
    assert(selected.targets[0].rpaths[0] == "$ORIGIN/lib,more")

    let root = "out/tmp/link-rpath-config"
    assert(mkdir_p(root ++ "/src") == 0)
    assert(write_file(root ++ "/src/main.w", "fn main: print(42)\n") == 0)
    assert(write_file(root ++ "/with.toml", "[link]\nsearch_paths = [\"native libs $literal\"]\nrpath = [\"$ORIGIN/lib,more\", \"@executable_path/lib space\"]\n") == 0)
    let cfg = project_config_load_for_source(root ++ "/src/main.w")
    assert(cfg.manifest_error == "")
    assert(cfg.link_search_paths[0] == cfg.root_dir ++ "/native libs $literal")
    assert(cfg.link_rpaths[0] == "$ORIGIN/lib,more")
    assert(cfg.link_rpaths[1] == "@executable_path/lib space")
    let cloned = project_config_clone(cfg)
    assert(cloned.link_rpaths[0] == "$ORIGIN/lib,more")
    build_cache_graph_write(root, "paths", graph)
    let cached = build_cache_graph_try_read(root, "paths")
    assert(cached.ok)
    assert(cached.targets[0].library_paths[0] == "native libs $literal")
    assert(cached.targets[0].rpaths[0] == "$ORIGIN/lib,more")
    assert(cached.targets[1].rpaths.len() == 0)
    print("ok")
