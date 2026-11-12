//! expect-stdout: ok
// A proof about compiled foreign code holds only for the build it analyzed.
// For a package linked as a prebuilt binary `with get` records what it drew
// from separately configured source as evidence, and the contract view
// prints it so, with what was analyzed. It printed every such line as a
// plain clause of the contract, as a proof's is.
use std.fs
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("contract_view_prints_evidence", "evidenceview")
    p7_write(root, "with.toml", "[package]\nname = \"evidenceview\"\nversion = \"0.1.0\"\n\n[deps]\nc.fake = \"1.0\"\n")
    p7_write(root, ".with/deps/c/fake/1.0/metadata.json", "{\n  \"name\": \"fake\",\n  \"version\": \"1.0\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": []\n}\n")
    p7_write(root, ".with/deps/c/fake/1.0/include/fake.h", "const char *fake_name(void);\nconst char *fake_motto(void);\n")
    p7_write(root, ".with/deps/c/fake/1.0/facade.w",
        "// evidence, not proof: the source analyzed and the library linked are not established as the same build.\n" ++
        "// analyzed: the source of fake/1.0 configured for this platform; the library linked is a binary built elsewhere\n" ++
        "use c_import(\"fake.h\")\n\n" ++
        "c facade fake:\n" ++
        "    fn fake_name\n" ++
        "        returns static CStr    // evidence: every return is a string literal\n" ++
        "    fn fake_motto\n" ++
        "        returns static CStr    // registry: fake.h 2: \"the motto is a literal\"\n")
    p7_write(root, "src/main.w", "use c_import(\"fake.h\")\n\nfn main: print(\"x\")\n")
    let view = p7_run(root, "evidence-view", p7_argv_append(p7_argv_append(p7_argv_append("", "analyze"), "src/main.w"), "contract"))
    p7_assert_success(view, "the contract view")
    let shown = view.stdout ++ view.stderr
    assert(shown.contains("[evidence:returns static@.with/deps/c/fake/1.0/facade.w:7]"))
    assert(shown.contains("[clause:returns static@.with/deps/c/fake/1.0/facade.w:9]"))
    assert(shown.contains("contract-audit: evidence, not proof, in .with/deps/c/fake/1.0/facade.w"))
    assert(shown.contains("analyzed: the source of fake/1.0 configured for this platform"))
    print("ok")
