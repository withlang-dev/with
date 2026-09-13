//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("generic_private_field_type", "generic_private_field_type_test")
    p7_write(case_dir, "lib/hidden.w", "type Entry[T] { value: T }\npub type Container[T] { entry: *mut Entry[T] }\npub fn marker(): 37\n")
    p7_write(case_dir, "src/main.w", "use hidden\nfn main: assert(marker() == 37)\n")
    let valid = p7_run(case_dir, "private_field_type_valid", "run\0src/main.w\0")
    p7_assert_success(valid, "generic declarations can name private types in their defining module")
    p7_write(case_dir, "src/main.w", "use hidden\nfn main:\n    var entry: Entry[i32]\n")
    let private_access = p7_run(case_dir, "private_field_type_rejected", "check\0src/main.w\0")
    assert(private_access.rc != 0)
    assert(private_access.stderr.contains("Entry"))
    print("ok")
