//! expect-stdout: ok

use pre_d_build_runner

// #3218: a header whose inline function calls malloc, imported by a facade
// module. The translation wraps its `with_alloc` call in `unsafe`, and
// whether that call is a raw operation was read off the module that
// happened to declare the `extern fn with_alloc` first in the compilation
// (the translator declares its support functions once per process). From
// the facade module the declaration was another module's, the call counted
// as a safe runtime call, and the translation's own `unsafe` was refused:
// "unsafe block contains no unsafe operations".
fn main:
    let dir = p7_prepare_case("3218_translation_alloc_in_facade_module", "translation_alloc")
    p7_write(dir, "with.toml", "[package]\nname = \"translation_alloc\"\nversion = \"0.1.0\"\n\n[deps]\nc.demo = \"1.0\"\n")
    p7_write(dir, ".with/deps/c/demo/1.0/metadata.json", "{\n  \"name\": \"demo\",\n  \"version\": \"1.0\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": [],\n  \"defines\": [],\n  \"link_args\": [],\n  \"components\": []\n}\n")
    p7_write(dir, ".with/deps/c/demo/1.0/include/demo.h", "#include <stdlib.h>\ntypedef struct { int *data; int n; } Img;\nstatic inline Img img_new(void) { Img i; i.data = (int *)malloc(sizeof(int) * 4); i.data[0] = 7; i.n = 4; return i; }\nstatic inline void img_free(Img i) { free(i.data); }\n")
    p7_write(dir, ".with/deps/c/demo/1.0/facade.w", "use c_import(\"demo.h\")\n\nc facade demo:\n    resource Picture wraps Img\n        from img_new\n        drop img_free\n")
    p7_write(dir, "src/main.w", "use facades.demo\n\nfn main:\n    let image = Picture.new()\n    print(f\"{image.n}\")\n")
    p7_assert_success(p7_run(dir, "check", "check\0src/main.w\0"), "the translation's own unsafe is not vacuous")
    print("ok")
