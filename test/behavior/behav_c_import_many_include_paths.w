//! expect-stdout: ok
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("c_import_many_include_paths", "manyincludes")
    // The entry header resolves directly; only Clang's nested include search
    // can find the declarations and typed macros in the final directory.
    p7_write(root, "headers/entry.h", "#include <late/value.h>\n")
    p7_write(root, "sdk/late/value.h", "typedef unsigned long long LateId;\n#define LATE_VALUE ((LateId)42)\n#define LATE_ADD(x) ((x) + LATE_VALUE)\n")
    var include_paths = "[c_import]\ninclude_paths = ["
    for i in 0..96:
        include_paths = include_paths ++ f"\"unused{i}\", "
    include_paths = include_paths ++ "\"sdk\"]\n"
    p7_write(root, "with.toml", "[package]\nname = \"manyincludes\"\nversion = \"0.1.0\"\n" ++ include_paths)
    for language in ["c", "c++"]:
        p7_write(root, "src/main.w", "use c_import(\"../headers/entry.h\", lang: \"" ++ language ++ "\")\nfn main:\n    let value: LateId = LATE_VALUE\n    assert(value == 42)\n    assert(LATE_ADD(1u64) == 43)\n    print(\"late include works\")\n")
        let result = p7_run(root, "many-includes", "run\0src/main.w\0")
        p7_assert_success(result, "all include paths reach declaration parsing and macro probes")
        assert(result.stdout.contains("late include works"))
    print("ok")
