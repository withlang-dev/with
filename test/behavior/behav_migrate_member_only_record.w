//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_member_only_record", "member_only_record_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    // A record named only through another record's member type — never
    // declared or defined at file scope — must still render as
    // `type config_data = opaque`; otherwise the migrated member's
    // `*mut config_data` names an unknown type (glibc's __locale_data
    // under time.h, #1138 linux x86_64 spec_ss16).
    p7_write(case_dir, "input.c", "struct config { struct config_data *entries[13]; const unsigned short *flags; };\ntypedef struct config *config_t;\nint config_probe(config_t c) { return c == 0; }\n")
    let migrated = p7_run(case_dir, "member_only_record_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/config.w\0")
    p7_assert_success(migrated, "migrate a member-only record type")
    let text = read_file(p7_join(case_dir, "lib/config.w")).unwrap()
    assert(text.contains("type config_data = opaque"))
    p7_write(case_dir, "src/main.w", "use config\nfn main:\n    assert(unsafe { config_probe(null) } == 1)\n    print(\"member-only record ok\")\n")
    let executed = p7_run(case_dir, "member_only_record_run", "run\0src/main.w\0")
    p7_assert_success(executed, "compile and run against the opaque member-only record")
    assert(executed.stdout.contains("member-only record ok"))
    print("ok")
