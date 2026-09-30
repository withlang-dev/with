//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.sysinfo

fn main:
    let root = p7_prepare_case("link paths $literal", "linkpaths")
    p7_write(root, "src/library.w", "@[c_export(\"link_path_value\")]\nfn value -> i32: 42\n")
    p7_write(root, "src/main.w", "extern fn link_path_value() -> i32\nfn main:\n    assert(unsafe { link_path_value() } == 42)\n")
    p7_write(root, "src/plain.w", "fn main: print(42)\n")
    var build_text = "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    let linked = target_new(.Executable, \"linked\", \"src/main.w\").library_path(\"native libs $literal\").link_system_lib(\"linkpaths\").rpath(\"$ORIGIN/native libs\").rpath(\"@executable_path/native libs\").output(\"out/linked\").dep(\"native\")\n"
    build_text = build_text ++ "    let plain = target_new(.Executable, \"plain\", \"src/plain.w\").output(\"out/plain\")\n"
    build_text = build_text ++ "    let native = target_new(.Archive, \"native\", \"src/library.w\").output(\"native libs $literal/liblinkpaths.a\")\n"
    build_text = build_text ++ "    ctx.new_build().add_target(linked).add_target(plain).add_target(native).default(\"linked\")\n"
    p7_write(root, "build.w", build_text)
    let graph = p7_run(root, "link-path-graph", p7_build_graph_args())
    p7_assert_success(graph, "target library and runtime paths")
    assert(graph.stdout.contains("library_path\t1\tnative libs $literal\n"))
    assert(graph.stdout.contains("rpath\t1\t$ORIGIN/native libs\n"))
    assert(graph.stdout.contains("rpath\t1\t@executable_path/native libs\n"))
    let plain_graph = p7_run(root, "link-path-plain-graph", "build\0--graph\0:plain\0")
    p7_assert_success(plain_graph, "plain target graph")
    assert(not plain_graph.stdout.contains("rpath\t"))
    assert(not plain_graph.stdout.contains("library_path\t"))
    for target in [":linked", ":plain"]:
        let result = p7_run(root, target, p7_build_target_args(target))
        p7_assert_success(result, target)
    let linked = read_file(p7_join(root, "out/linked")).unwrap()
    let plain = read_file(p7_join(root, "out/plain")).unwrap()
    if os() == "Macos" or os() == "Linux":
        assert(linked.contains("$ORIGIN/native libs"))
        assert(linked.contains("@executable_path/native libs"))
    assert(not plain.contains("$ORIGIN/native libs"))
    assert(not plain.contains("@executable_path/native libs"))
    // Graph-cache read must retain the two lists, with the second target empty.
    let cached = p7_run(root, "link-path-cached", p7_build_graph_args())
    p7_assert_success(cached, "cached target paths")
    assert(cached.stdout == graph.stdout)

    p7_write(root, "with.toml", "[package]\nname = \"linkpaths\"\nversion = \"0.1.0\"\n[link]\nrpath = [\"$ORIGIN/manifest space\"]\n")
    let manifest = p7_run(root, "link-path-manifest", p7_build_target_args(":plain"))
    p7_assert_success(manifest, "manifest runtime paths")
    if os() == "Macos" or os() == "Linux":
        assert(read_file(p7_join(root, "out/plain")).unwrap().contains("$ORIGIN/manifest space"))
    print("ok")
