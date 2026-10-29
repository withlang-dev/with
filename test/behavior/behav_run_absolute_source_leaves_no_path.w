//! expect-stdout: ok
// `with run` builds a program in a directory of its own (#1374), which is
// scratch and so the system's. It was out/<the source's directory> under the
// caller's directory, and an absolute source left that whole path behind,
// empty: running /…/tools/hello.w from a project made ./out/…/tools there.
use pre_d_build_runner
use std.fs

fn main:
    let case = p7_prepare_case("run_absolute_source_leaves_no_path", "runabs")
    let tool = p7_join(case, "elsewhere/tools/hello.w")
    p7_write(case, "elsewhere/tools/hello.w", "print(\"hello\")\n")
    let run = p7_run_without_out_dir(case, "run_absolute_source", "run\0" ++ tool ++ "\0")
    p7_assert_success(&run, "with run of an absolute source")
    assert(run.stdout.trim() == "hello")
    // The source's directory, mirrored under out/ as the artifact path names it.
    let tools_dir = p7_dirname(tool).replace(":", "").replace("\\", "/")
    let relative = if tools_dir.starts_with("/"): tools_dir.slice(1, tools_dir.len()) else: tools_dir
    let mirrored = p7_join(case, "out/" ++ relative)
    assert(not file_exists(mirrored))
    print("ok")
