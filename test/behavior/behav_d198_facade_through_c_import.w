//! expect-stdout: ok

use pre_d_build_runner

// D198 (§16.2b.15): a facade states facts about C symbols, whichever import
// names them. A `c_import` of a header that resolves to a file inside a
// fetched package applies that package's facade with no `use contracts.<name>`
// written: the by-value record is the resource, and the program that calls
// the imported names is safe. The match is by the resolved file: the same
// header beside the importing module is not the package's file, brings no
// facade, and its by-value function is raw. The raw-call diagnostic says
// when a package's facade is applied and does not model the type.
fn header(extra: &str) -> str: "typedef struct { int *data; int n; } Img;\nstatic inline Img img_new(void) { Img i; i.data = 0; i.n = 4; return i; }\nstatic inline void img_free(Img i) { }\nstatic inline int img_get(Img i, int k) { return i.data ? i.data[k] : i.n + k; }\n" ++ extra

fn main:
    let dir = p7_prepare_case("d198_facade_through_c_import", "facade_through_c_import")
    p7_write(dir, "with.toml", "[package]\nname = \"facade_through_c_import\"\nversion = \"0.1.0\"\n\n[deps]\nc.demo = \"1.0\"\n")
    p7_write(dir, ".with/deps/c/demo/1.0/metadata.json", "{\n  \"name\": \"demo\",\n  \"version\": \"1.0\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": [],\n  \"defines\": [],\n  \"link_args\": [],\n  \"components\": []\n}\n")
    p7_write(dir, ".with/deps/c/demo/1.0/include/demo.h", header("typedef struct { int *slots; } Bag;\nstatic inline int bag_first(Bag b) { return b.slots[0]; }\n"))
    p7_write(dir, ".with/deps/c/demo/1.0/contract.w", "use c_import(\"demo.h\")\n\nc contract demo:\n    resource Picture wraps Img\n        from img_new\n        drop img_free\n    fn img_get\n        of Picture\n")
    p7_write(dir, "src/main.w", "use c_import(\"demo.h\")\n\nfn main:\n    let image = img_new()\n    print(f\"{img_get(image, 0)}\")\n    img_free(image)\n")
    p7_assert_success(p7_run(dir, "applied", "check\0src/main.w\0"), "the package's facade applies through c_import")

    p7_write(dir, "src/unmodeled.w", "use c_import(\"demo.h\")\n\nfn main:\n    let bag = Bag { slots: null }\n    print(f\"{bag_first(bag)}\")\n")
    p7_assert_failure_contains(p7_run(dir, "unmodeled", "check\0src/unmodeled.w\0"), "is applied and does not model `Bag`", "the diagnostic names the applied facade")

    // The applied facade is visible, with the file it came from.
    let contract = p7_run(dir, "contract", "analyze\0src/main.w\0contract\0")
    p7_assert_success(contract, "the contract view")
    let shown = contract.stdout.contains("resource Picture wraps Img") and contract.stdout.contains("facade:demo@") and contract.stdout.contains(".with/deps/c/demo/1.0/contract.w")
    if not shown: print(contract.stdout)
    assert(shown)

    // A facade that disagrees with the header it is applied to is an error,
    // never a silent return to the raw declarations.
    let facade = "use c_import(\"demo.h\")\n\nc contract demo:\n    resource Picture wraps Img\n        from img_new\n        drop img_free\n    fn img_get\n        of Picture\n"
    p7_write(dir, ".with/deps/c/demo/1.0/contract.w", facade ++ "    fn img_missing\n        of Picture\n")
    p7_assert_failure_contains(p7_run(dir, "disagrees", "check\0src/main.w\0"), "'img_missing' is not a declaration in scope", "a facade naming a function the header lacks")
    p7_write(dir, ".with/deps/c/demo/1.0/contract.w", facade)

    p7_write(dir, "src/demo.h", header(""))
    p7_assert_failure_contains(p7_run(dir, "shadowed", "check\0src/main.w\0"), "takes `Img` by value", "a header beside the module is not the package's file")
    print("ok")
