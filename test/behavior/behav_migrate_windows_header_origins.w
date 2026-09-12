//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_windows_header_origins", "windows_header_origins")
    for header_dir in ["Windows Kits/ucrt", "VC/Tools/MSVC/include", "SDKs/Fake.sdk/usr/include",
        "mixed\\Windows Kits/ucrt", "mixed/Windows Kits\\ucrt",
        "mixed\\VC/Tools\\MSVC/include", "mixed\\SDKs/Fake.sdk/usr/include"]:
        p7_write(case_dir, "input/" ++ header_dir ++ "/system.h", "#define SDK_NUMBER 43\nextern int __sdk_private;\nstatic inline int sdk_helper(void) { return __sdk_private; }\n")
        p7_write(case_dir, "input/unit.c", "#include \"" ++ header_dir ++ "/system.h\"\n#define PROJECT_NUMBER SDK_NUMBER\nint value(void) { return PROJECT_NUMBER; }\n")
        let migrated = p7_run(case_dir, "windows_header_migrate", "migrate\0input\0--shared-defs\0sample.defs\0--no-c-export\0-o\0lib/sample\0")
        p7_assert_success(migrated, "filter SDK declarations and macros in " ++ header_dir)
        let defs = read_file(p7_join(case_dir, "lib/sample/defs.w")).unwrap()
        let unit = read_file(p7_join(case_dir, "lib/sample/unit.w")).unwrap()
        assert(not defs.contains("SDK_NUMBER"))
        assert(not defs.contains("sdk_helper"))
        assert(not unit.contains("sdk_helper"))
        assert(not unit.contains("__sdk_private"))
        assert(defs.contains("PROJECT_NUMBER"))
        p7_write(case_dir, "src/main.w", "use sample.unit\nuse sample.defs\nfn main:\n    assert(value() == 43)\n    assert(PROJECT_NUMBER == 43)\n    print(\"project ok\")\n")
        let executed = p7_run(case_dir, "windows_header_run", "run\0src/main.w\0")
        p7_assert_success(executed, "run project code after SDK filtering")
    print("ok")
