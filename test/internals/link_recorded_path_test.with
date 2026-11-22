//! expect-stdout: ok

use compiler.Link

// #2016 records the SDK paths in out/lib/llvm_ld relative to the project
// root; a link from any other directory (the release UAT's fresh directory,
// `with -e` beside a project's out/) resolved them against the cwd and
// reported the SDK as missing its C runtime (v0.16.0.0 Windows leg). A
// relative record resolves against the project that owns the runtime root.

fn main:
    // Absolute runtime roots, every layout the build produces, both separators.
    assert(link_stage_recorded_path("/w/proj/out/lib", ".deps/llvm/bin/lld-link.exe") == "/w/proj/.deps/llvm/bin/lld-link.exe")
    assert(link_stage_recorded_path("/w/proj/out/bootstrap/lib", ".deps/x") == "/w/proj/.deps/x")
    assert(link_stage_recorded_path("/w/proj/out/bootstrap-lib", ".deps/x") == "/w/proj/.deps/x")
    assert(link_stage_recorded_path("/w/proj/out/release/../lib", ".deps/x") == "/w/proj/.deps/x")
    assert(link_stage_recorded_path("W:/with-release/out/lib", ".deps/x") == "W:/with-release/.deps/x")
    assert(link_stage_recorded_path("W:\\with-release\\out\\release\\..\\lib", ".deps/x") == "W:\\with-release/.deps/x")
    // A project whose own name contains "out" is not cut at the wrong segment.
    assert(link_stage_recorded_path("/home/scout/without/out/lib", ".deps/x") == "/home/scout/without/.deps/x")
    // An absolute record is itself; an empty one stays empty.
    assert(link_stage_recorded_path("/w/proj/out/lib", "/opt/llvm/bin/ld.lld") == "/opt/llvm/bin/ld.lld")
    assert(link_stage_recorded_path("/w/proj/out/lib", "C:/sdk/bin/lld-link.exe") == "C:/sdk/bin/lld-link.exe")
    assert(link_stage_recorded_path("/w/proj/out/lib", "") == "")
    // A relative runtime root is the cwd's project: the record stays relative.
    assert(link_stage_recorded_path("out/lib", ".deps/x") == ".deps/x")
    // A root with no out segment (an installed layout) leaves the record alone.
    assert(link_stage_recorded_path("/usr/local/lib/with", ".deps/x") == ".deps/x")
    print("ok")
