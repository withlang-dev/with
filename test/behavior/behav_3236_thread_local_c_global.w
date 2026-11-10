//! expect-stdout: ok

use pre_d_build_runner

// #3236: a C `_Thread_local` global. The translator marked it
// `@[threadlocal]` and nothing read the mark: the global was declared and
// accessed as an ordinary one, so With read and wrote storage C never
// looked at. C defines the variable and reads it back; With increments it.
fn main:
    let dir = p7_prepare_case("3236_thread_local_c_global", "tls_global")
    p7_write(dir, "with.toml", "[package]\nname = \"tls_global\"\nversion = \"0.1.0\"\n\n[c_import]\ninclude_paths = [\"vendor\"]\n\n[link]\nsearch_paths = [\"out/lib\"]\n")
    p7_write(dir, "vendor/tls.h", "extern _Thread_local int tls_count;\nint tls_read(void);\n")
    p7_write(dir, "vendor/tls.c", "#include \"tls.h\"\n_Thread_local int tls_count = 5;\nint tls_read(void) { return tls_count; }\n")
    p7_write(dir, "build.w", "use std.build\n\ncomptime with BuildCtx as ctx:\npub fn build -> Build:\n    var out = ctx.new_build().compile_c_object(\"tls-object\", \"vendor/tls.c\", \"out/lib/tls.o\")\n    out = out.add_target(target_new(.CreateStaticArchive, \"tls\", \"\").output(\"out/lib/libtls.a\").input(\"out/lib/tls.o\").dep(\"tls-object\"))\n    out = out.add_target(target_new(.Executable, \"tls_global\", \"src/main.w\").include_path(\"vendor\").dep(\"tls\"))\n    out.default(\"tls_global\")\n")
    p7_write(dir, "src/main.w", "use c_import(\"tls.h\", link: \"tls\")\n\nfn main:\n    tls_count = tls_count + 1\n    print(f\"{tls_count} {tls_read()}\")\n")
    let ran = p7_run(dir, "run", "run\0")
    p7_assert_success(ran, "the program builds and runs")
    if not ran.stdout.contains("6 6"): print(ran.stdout)
    assert(ran.stdout.contains("6 6"))
    print("ok")
