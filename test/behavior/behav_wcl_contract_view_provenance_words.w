//! expect-stdout: ok
// §31.6.3, §31.9: the contract view prints where each clause came from, in
// the specification's words, marks a grant the compiler does not vouch for
// as a claim, and counts them. A comment in a program's own contract
// vouches for nothing: `// proof:` there is still a stated claim. The view
// printed every clause as `clause:` whoever wrote it, and counted nothing.
use std.fs
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("wcl_contract_view_provenance_words", "provwords")
    p7_write(root, "with.toml", "[package]\nname = \"provwords\"\nversion = \"0.1.0\"\n\n[deps]\nc.fake = \"1.0\"\n")
    p7_write(root, ".with/deps/c/fake/1.0/metadata.json", "{\n  \"name\": \"fake\",\n  \"version\": \"1.0\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": []\n}\n")
    p7_write(root, ".with/deps/c/fake/1.0/include/fake.h", "const char *fake_name(void);\nconst char *fake_motto(void);\nconst char *fake_kind(void);\nint fake_tick(int n);\n")
    p7_write(root, ".with/deps/c/fake/1.0/contract.w",
        "use c_import(\"fake.h\")\n\n" ++
        "c contract fake:\n" ++
        "    fn fake_name\n" ++
        "        returns static CStr    // proof: every return is a string literal\n" ++
        "    fn fake_motto\n" ++
        "        returns static CStr    // registry: fake.h 2: \"the motto is a literal\"\n" ++
        "    fn fake_kind\n" ++
        "        returns static CStr    // annotation: the header marks the return static\n" ++
        "    fn fake_tick\n" ++
        "        rename tick\n")
    p7_write(root, "src/main.w",
        "use c_import(\"fake.h\")\n" ++
        "use c_import(\"const char *own_name(void);\")\n\n" ++
        "c contract own:\n" ++
        "    fn own_name\n" ++
        "        returns static CStr    // proof: trust me\n\n" ++
        "fn main: print(\"x\")\n")
    let view = p7_run(root, "provenance-view", p7_argv_append(p7_argv_append(p7_argv_append("", "analyze"), "src/main.w"), "contract"))
    p7_assert_success(view, "the contract view")
    let shown = view.stdout ++ view.stderr
    assert(shown.contains("[proof@.with/deps/c/fake/1.0/contract.w:5: every return is a string literal]"))
    assert(shown.contains("[claim: registry@.with/deps/c/fake/1.0/contract.w:7: fake.h 2: \"the motto is a literal\"]"))
    assert(shown.contains("[claim: annotation@.with/deps/c/fake/1.0/contract.w:9: the header marks the return static]"))
    // An fn item whose function takes no resource asserts nothing: its
    // parameter row is a default, not a claim (§31.8.1).
    assert(not shown.contains("[claim: stated@.with/deps/c/fake/1.0/contract.w:10]"))
    assert(shown.contains("[default:a described fn lends its resource parameters, and this is none (§31.8.1)]"))
    // A presentation grants nothing and is no claim.
    assert(shown.contains("[stated@.with/deps/c/fake/1.0/contract.w:11]"))
    assert(shown.contains("[claim: stated@src/main.w:6]"))
    assert(not shown.contains("trust me"))
    assert(shown.contains("contract-audit: clauses=4 proven=1 claimed=3"))
    assert(shown.contains("contract-audit: claims: stated=1 registry=1 profile=0 annotation=1"))
    print("ok")
