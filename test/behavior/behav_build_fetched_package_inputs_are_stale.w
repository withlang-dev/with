//! expect-stdout: ok
// Which fetched package a header belongs to, and so which contract applies
// to an import, is decided by the project's with.toml and each package's
// metadata.json. A build that asked recorded neither, so a change to one
// kept the old binary and the old safety verdict.
use std.fs
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("fetched_package_inputs_are_stale", "fetchedinputs")
    p7_write(root, "build.w",
        "use std.build\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    ctx.new_build().executable(\"fetchedinputs\", \"src/main.w\").default(\"fetchedinputs\")\n")
    p7_write(root, "with.toml", "[package]\nname = \"fetchedinputs\"\nversion = \"0.1.0\"\n\n[deps]\nc.fake = \"1.0\"\n")
    let metadata = "{\n  \"name\": \"fake\",\n  \"version\": \"1.0\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": []\n}\n"
    p7_write(root, ".with/deps/c/fake/1.0/metadata.json", metadata)
    p7_write(root, ".with/deps/c/fake/1.0/include/fake.h", "#define FAKE_ANSWER 41\n")
    p7_write(root, ".with/deps/c/fake/1.0/facade.w", "use c_import(\"fake.h\")\n\nc facade fake:\n    runs threads\n")
    p7_write(root, "src/main.w", "use c_import(\"fake.h\")\n\nfn main: print(f\"{FAKE_ANSWER}\")\n")
    p7_assert_success(p7_run(root, "fetched-first", p7_build_args()), "first build")
    let state: str = read_file(p7_join(root, "out/.build-state/fetchedinputs.state")) ?? ""
    assert(state.contains("with.toml:"))
    assert(state.contains(".with/deps/c/fake/1.0/metadata.json:"))
    assert(state.contains(".with/deps/c/fake/1.0/facade.w:"))

    // Unchanged inputs: the target is not rebuilt.
    let again = p7_run(root, "fetched-again", p7_build_args())
    p7_assert_success(again, "unchanged build")
    assert(not again.stderr.contains("[time] fetchedinputs"))

    // A changed metadata.json, with.toml or contract each rebuilds it.
    p7_write(root, ".with/deps/c/fake/1.0/metadata.json", metadata ++ "\n")
    let after_metadata = p7_run(root, "fetched-metadata", p7_build_args())
    p7_assert_success(after_metadata, "build after metadata.json changed")
    assert(after_metadata.stderr.contains("[time] fetchedinputs"))

    p7_write(root, "with.toml", "[package]\nname = \"fetchedinputs\"\nversion = \"0.1.1\"\n\n[deps]\nc.fake = \"1.0\"\n")
    let after_toml = p7_run(root, "fetched-toml", p7_build_args())
    p7_assert_success(after_toml, "build after with.toml changed")
    assert(after_toml.stderr.contains("[time] fetchedinputs"))

    p7_write(root, ".with/deps/c/fake/1.0/facade.w", "use c_import(\"fake.h\")\n\n// edited\nc facade fake:\n    runs threads\n")
    let after_contract = p7_run(root, "fetched-contract", p7_build_args())
    p7_assert_success(after_contract, "build after the contract changed")
    assert(after_contract.stderr.contains("[time] fetchedinputs"))
    print("ok")
