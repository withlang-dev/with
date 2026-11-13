//! expect-stdout: ok
// §31.7: a proof that contradicts a stated grant is an error naming the
// proof, unless the clause is marked `override`; then the grant stands and
// the contract view prints the proof it stands against, counted apart from
// claims. `with get` records what a package's source proves against a
// grant in contract-proofs.txt, beside the contract it drew; a project's
// own `contracts/<name>.w` is held against it. Nothing was: a stated `lend`
// on a function the source shows storing its parameter was accepted.
use std.fs
use pre_d_build_runner

fn stated(lend: &str) -> str:
    "use c_import(\"fake.h\")\n\n" ++
    "c contract fake:\n" ++
    "    resource Engine wraps *mut engine\n" ++
    "        from engine_new\n" ++
    "        drop engine_free\n" ++
    "    fn engine_peek\n" ++
    "        " ++ lend ++ "\n"

fn main:
    let root = p7_prepare_case("wcl_proof_contradicts_stated_grant", "contradicts")
    p7_write(root, "with.toml", "[package]\nname = \"contradicts\"\nversion = \"0.1.0\"\n\n[deps]\nc.fake = \"1.0\"\n")
    p7_write(root, ".with/deps/c/fake/1.0/metadata.json", "{\n  \"name\": \"fake\",\n  \"version\": \"1.0\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": []\n}\n")
    p7_write(root, ".with/deps/c/fake/1.0/include/fake.h", "typedef struct engine engine;\nengine *engine_new(void);\nvoid engine_free(engine *e);\nint engine_peek(engine *e);\ntypedef struct item item;\nitem *item_of(engine *e);\nvoid item_free(item *i);\n")
    p7_write(root, ".with/deps/c/fake/1.0/contract.w", "use c_import(\"fake.h\")\n\nc contract fake:\n    resource Engine wraps *mut engine\n        from engine_new    // proof: malloc, a fresh allocation never retained\n        drop engine_free    // proof: frees param 0\n")
    p7_write(root, ".with/deps/c/fake/1.0/contract-proofs.txt", "engine_peek\tstores\t0\tpassed to cache_put at param 1, stored in a field\nitem_of\treturns-part\t0\tthe return is a field of param 0\n")
    p7_write(root, "src/main.w", "use contracts.fake\n\nfn main: print(\"x\")\n")

    p7_write(root, "src/contracts/fake.w", stated("lend"))
    let refused = p7_run(root, "contradiction", p7_argv_append(p7_argv_append("", "check"), "src/main.w"))
    let said = refused.stdout ++ refused.stderr
    assert(said.contains("`lend` on `engine_peek` contradicts a proof: the function stores param 0"))
    assert(said.contains("= proof: passed to cache_put at param 1, stored in a field"))
    assert(said.contains("the clause can be marked `override`"))

    p7_write(root, "src/contracts/fake.w", stated("override lend"))
    let view = p7_run(root, "override-view", p7_argv_append(p7_argv_append(p7_argv_append("", "analyze"), "src/main.w"), "contract"))
    p7_assert_success(view, "the contract view with the override")
    let shown = view.stdout ++ view.stderr
    assert(shown.contains("[override@src/contracts/fake.w:8, against proof: passed to cache_put at param 1, stored in a field]"))
    assert(shown.contains("overrides=1 stale-overrides=0"))

    // A producer whose every return is a part of a parameter makes nothing
    // new: `from` on it is contradicted the same way.
    p7_write(root, "src/contracts/fake.w", stated("override lend") ++ "    resource Item wraps *mut item\n        from item_of\n        drop item_free\n")
    let produced = p7_run(root, "from-contradiction", p7_argv_append(p7_argv_append("", "check"), "src/main.w"))
    let told = produced.stdout ++ produced.stderr
    assert(told.contains("`from item_of` on `Item` contradicts a proof: every pointer the function returns is a part of param 0"))
    assert(told.contains("= proof: the return is a field of param 0"))
    print("ok")
