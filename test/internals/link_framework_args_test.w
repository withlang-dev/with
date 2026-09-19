//! expect-stdout: ok

use compiler.Link

// #357: `link: "framework:Name"` maps to `-framework Name` on Darwin, to a
// loud error on other targets, and plain libs always map to `-l<lib>`. Tested
// as pure arg-mapping logic (both is_darwin branches) so it needs no live
// framework and runs on every platform.

fn join_args(v: &Vec[str]) -> str:
    var out = ""
    for i in 0..v.len() as i32:
        if i > 0: out = out ++ " "
        out = out ++ v.get(i as i64)
    out

fn main:
    assert(link_stage_framework_name("framework:CoreFoundation") == "CoreFoundation")
    assert(link_stage_framework_name("m") == "")
    assert(link_stage_framework_name("framework:") == "")

    // Darwin: framework → two args
    let da = link_stage_lib_args("framework:CoreFoundation", 1)
    assert(join_args(&da) == "-framework CoreFoundation")

    // Any target: plain lib → -l<lib>
    let plain = link_stage_lib_args("z", 1)
    assert(join_args(&plain) == "-lz")

    // Non-Darwin framework → loud error, no args (stderr line ignored here)
    let bad = link_stage_lib_args("framework:CoreFoundation", 0)
    assert(bad.len() == 0)

    // #1193: ELF linkers resolve static archives left to right, once, so the
    // user's libraries are linked as one group; ld64 and lld-link take none.
    assert(link_stage_archive_group_marker(1, 1, 1) == "-Wl,--start-group")
    assert(link_stage_archive_group_marker(1, 1, 0) == "-Wl,--end-group")
    assert(link_stage_archive_group_marker(1, 0, 1) == "--start-group")
    assert(link_stage_archive_group_marker(1, 0, 0) == "--end-group")
    assert(link_stage_archive_group_marker(0, 1, 1) == "")
    assert(link_stage_archive_group_marker(0, 0, 0) == "")

    print("ok")
