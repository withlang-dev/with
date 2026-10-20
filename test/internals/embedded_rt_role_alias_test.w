//! expect-stdout: ok

// D30 step 3: `rt/platform.w` and `rt/fiber_core.w` name the target's
// platform module and fiber core by role, so a standard-library module
// writes `use rt.platform`, never the host's file name. The owner is
// EmbeddedRuntime (the in-unit parse reads the same two functions).
use compiler.EmbeddedRuntime

fn main:
    let platform = embedded_rt_platform_file()
    assert(platform.starts_with("rt/") and platform.ends_with(".w"), "the host has a platform module")
    assert(embedded_rt_source(platform).len() > 0, "the platform module is embedded")
    assert(embedded_rt_resolve_path("rt/platform.w") == "<embedded-rt>/" ++ platform)
    let fiber_core = embedded_rt_fiber_core_file()
    assert(fiber_core == (if platform.starts_with("rt/windows"): "rt/fiber_core_windows.w" else: "rt/fiber_core_darwin.w"))
    assert(embedded_rt_resolve_path("rt/fiber_core.w") == "<embedded-rt>/" ++ fiber_core)
    // A real file keeps its own name; a name nothing embeds resolves to nothing.
    assert(embedded_rt_resolve_path("rt/rt_core.w") == "<embedded-rt>/rt/rt_core.w")
    assert(embedded_rt_resolve_path("rt/no_such_module.w") == "")
    print("ok")
