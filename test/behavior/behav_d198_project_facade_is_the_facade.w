//! expect-stdout: ok

use pre_d_build_runner

// D198 (§16.2b.15): a project's own `contracts/<name>.w` is the facade of the
// package. Its `c_import` of the header is what it describes, never an
// import of a facade: resolving `facades.<name>` from inside that file
// found another file of the same name up the directory tree (the
// toolchain's own lib/contracts/zlib.w, from a project inside a checkout) and
// loaded both, so `with run` reported every item of the facade twice. The
// zlib, sqlite3, bzip2 and libcurl acceptance scenarios failed this way.
fn main:
    let dir = p7_prepare_case("d198_project_facade_is_the_facade", "project_facade")
    p7_write(dir, "with.toml", "[package]\nname = \"project_facade\"\nversion = \"0.1.0\"\n\n[deps]\nc.zlib = \"9.9\"\n")
    p7_write(dir, ".with/deps/c/zlib/9.9/metadata.json", "{\n  \"name\": \"zlib\",\n  \"version\": \"9.9\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": [],\n  \"defines\": [],\n  \"link_args\": [],\n  \"components\": []\n}\n")
    p7_write(dir, ".with/deps/c/zlib/9.9/include/zlib.h", "static inline int tally(const int *values, int count) { int t = 0; for (int i = 0; i < count; i++) t += values[i]; return t; }\n")
    p7_write(dir, "src/contracts/zlib.w", "use c_import(\"zlib.h\")\n\nc contract zlib:\n    fn tally\n        buffer param values len param count elements\n")
    p7_write(dir, "src/main.w", "use contracts.zlib\nuse c_import(\"zlib.h\")\n\nfn main:\n    let values: [i32; 3] = [1, 2, 3]\n    print(f\"{tally(values)}\")\n")
    p7_write(dir, "build.w", "use std.build\n\ncomptime with BuildCtx as ctx:\npub fn build -> Build:\n    let out = ctx.new_build().executable(\"project_facade\", \"src/main.w\")\n    out.default(\"project_facade\")\n")
    let built = p7_run(dir, "build", p7_build_args())
    p7_assert_success(built, "the project's own facade is the only one")
    print("ok")
