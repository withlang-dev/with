//! expect-stdout: ok

// docs/plans/c++_import.md §4: one header read as C and as C++ is two
// entries in the persistent c_import cache, and `lang: "c"` is the import
// with no `lang:` at all — the same entry, so the same translation.

use pre_d_build_runner
use std.process
use std.time

fn run_mode(case_dir: &str, file: &str, label: &str, want: &str, cache_line: &str):
    let run = p7_run(case_dir, label, f"run\0src/{file}\0")
    p7_assert_success(&run, label)
    assert(run.stdout.contains(want))
    assert(run.stderr.contains(cache_line))

fn main:
    let case_dir = p7_prepare_case("c_import_lang_cache_entries", "langcacheentries")
    p7_write(case_dir, "src/modes.h", "#ifdef __cplusplus\nconst int MODE = 2;\nextern \"C\" {\n#else\nenum { MODE = 1 };\n#endif\nstruct Plain { int value; };\n#ifdef __cplusplus\n}\n#endif\n")
    let body = "fn main:\n    print(f\"mode {MODE} {size_of[Plain]()}\")\n"
    p7_write(case_dir, "src/plain.w", "use c_import(\"modes.h\")\n" ++ body)
    p7_write(case_dir, "src/c.w", "use c_import(\"modes.h\", lang: \"c\")\n" ++ body)
    p7_write(case_dir, "src/cxx.w", "use c_import(\"modes.h\", lang: \"c++\")\n" ++ body)
    let previous_epoch = env("WITH_CIMPORT_CACHE_EPOCH").clone()
    let previous_trace = env("WITH_TRACE_CIMPORT_CACHE").clone()
    assert(set_env("WITH_CIMPORT_CACHE_EPOCH", f"lang-entries-{pid()}-{now_ns()}") == 0)
    assert(set_env("WITH_TRACE_CIMPORT_CACHE", "1") == 0)
    run_mode(case_dir, "plain.w", "no lang (miss)", "mode 1 4", "c_import cache miss")
    run_mode(case_dir, "c.w", "lang c (the same entry)", "mode 1 4", "c_import cache hit (fs)")
    run_mode(case_dir, "cxx.w", "lang c++ (its own entry)", "mode 2 4", "c_import cache miss")
    run_mode(case_dir, "cxx.w", "lang c++ (hit)", "mode 2 4", "c_import cache hit (fs)")
    run_mode(case_dir, "plain.w", "no lang (still its entry)", "mode 1 4", "c_import cache hit (fs)")
    assert(set_env("WITH_CIMPORT_CACHE_EPOCH", previous_epoch) == 0)
    assert(set_env("WITH_TRACE_CIMPORT_CACHE", previous_trace) == 0)
    print("ok")
