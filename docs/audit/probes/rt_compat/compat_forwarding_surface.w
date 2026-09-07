// Probe: 1:1 forwarding surface of rt/compat_runtime.w.
// Snapshot 450733e5. Pure-logic mirror — the file declares 15 extern
// rt_compat_* fns (:6-:20) and 15 pub with_* wrappers (:22-:67) that forward
// unchanged, so this probe mirrors the arity/count contract, not the FFI.
// Run via seed:
//   out/bootstrap/bin/with-stage1 run .audit/probes/rt_compat/compat_forwarding_surface.w
//
// Mirror source: rt/compat_runtime.w:1-67 (fully read).
// T19: build.w host_runtime_spec() uses compat_source "rt/compat_runtime.w" on
// ALL five host configs (linux x86_64/aarch64, darwin aarch64, windows
// x86_64/aarch64); only the backend satisfying the externs varies
// (rt/linux_x86_64.w, rt/linux_aarch64.w, rt/darwin_aarch64.w,
// rt/windows_x86_64.w, rt/windows_aarch64.w). No platform needs a shim
// *instead* — the file IS the portable surface; T19 answer: none.

// Each forwarder is (name_index, argc). Order matches file order :22-:67.
fn fwd_argc(idx: i32) -> i32:
    if idx == 0: return 2    // with_setenv_str
    if idx == 1: return 0    // with_install_interrupt_handlers
    if idx == 2: return 0    // with_raise_stack_limit
    if idx == 3: return 0    // with_interrupt_requested
    if idx == 4: return 1    // with_exec_binary
    if idx == 5: return 1    // with_exec_argv
    if idx == 6: return 2    // with_exec_argv_cwd
    if idx == 7: return 4    // with_exec_argv_capture
    if idx == 8: return 5    // with_exec_argv_capture_input
    if idx == 9: return 5    // with_exec_argv_capture_cwd
    if idx == 10: return 3   // with_exec_argv_capture_spawn
    if idx == 11: return 2   // with_exec_wait
    if idx == 12: return 1   // with_exec_try_wait (#921: -2 while running)
    if idx == 13: return 0   // with_exec_child_maxrss
    if idx == 14: return 0   // with_self_maxrss
    -99

fn main:
    // 15 externs, 15 forwarders, each forwarding with identical arity.
    var total = 0
    var i = 0
    while i < 15:
        total = total + fwd_argc(i)
        assert(fwd_argc(i) >= 0)
        i = i + 1
    // 2+0+0+0+1+1+2+4+5+5+3+2+1+0+0 = 26
    assert(total == 26)
    print("compat surface ok: 15 externs, 15 forwarders, argc sum 26")
    // #921 contract spot-check: try_wait is unary like wait's pid half.
    assert(fwd_argc(12) == 1)
    print("try_wait unary ok")
