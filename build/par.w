module build.par

// A sliding window of child processes for an action whose cases are
// independent: the tools lane's builds, emit-c-smoke's emit and C compile
// steps. At most `width` children are alive (the host's logical cores by
// default); the oldest is reaped to open each slot, so one slow case never
// idles the rest of the window. Every child is reaped before par_run
// returns, and every exit code comes back in job order, so a lane reports
// every failure, not the first.

use std.build
use std.fs
use std.process
use std.string


pub type ParJob {
    argv: List[str],
    stdout: str,
    stderr: str,
    timeout_ms: i32,
}

pub fn par_job(argv: List[str], stdout: str, stderr: str, timeout_ms: i32): ParJob { argv, stdout, stderr, timeout_ms }

// The window is the job count, capped at 32 like the test lanes' own window
// (build_graph_test_jobs): an action may run in the comptime evaluator,
// which cannot read the host core count, and every lane using this holds
// fewer cases than that cap, so the kernel spreads them over the cores.
pub fn par_width(jobs: &List[ParJob]) -> i32: if jobs.len() > 32: 32 else: jobs.len() as i32

// The machine-wide process budget a top-level build driver hands its lanes
// (WITH_BUILD_JOBSERVER, a directory; WITH_BUILD_JOBSERVER_SLOTS, its size;
// the compiler's build_graph_jobserver_acquire): the lane's own slot covers
// one child, and each further child holds a slot, an exclusive symlink in the
// directory, until it is reaped. Without a jobserver every child may start
// (2026-10-14: emit-c-smoke and c-algorithms each ran 14-17 children beside
// 18 lanes, a load of 78, and five invariance lanes hit their 600 s guard).
fn par_slot_acquire(dir: &str, slots: i32) -> i32:
    if dir.len() == 0: return 0
    for k in 0..slots:
        if symlink(f"{pid()}", dir ++ f"/slot-{k}") == 0: return k
    -1

// This lane is on the critical path (the driver lists it in the
// jobserver's `critical` file): its children take no slots.
fn par_lane_critical(dir: &str) -> bool:
    let lane = env("WITH_BUILD_LANE")
    dir.len() > 0 and lane.len() > 0 and ("\n" ++ (read_file(dir ++ "/critical") ?? "")).contains("\n" ++ lane ++ "\n")

fn par_slot_release(dir: &str, slot: i32):
    if dir.len() > 0 and slot >= 0: remove_file(dir ++ f"/slot-{slot}")

/// Runs every job with at most `width` children alive, reaping the oldest
/// to open each slot. Returns each job's exit code in job order; -1 means
/// the job could not be spawned. Returns only after every child is reaped.
pub fn par_run(ctx: &ActionCtx, jobs: &List[ParJob], width: i32) -> List[i32]:
    let limit = if width < 1: 1 else: width
    let js_dir = env("WITH_BUILD_JOBSERVER")
    let js_slots = parse(env("WITH_BUILD_JOBSERVER_SLOTS"))
    let total = jobs.len()
    var rcs: List[i32] = List.new()
    var pids: List[i32] = List.new()
    var slots: List[i32] = List.new()
    var next = 0
    var oldest = 0
    while oldest < total:
        if next < total and next - oldest < limit:
            // The first child alive runs in the lane's own slot; a lane on the
            // critical path takes none.
            let free = next == oldest or par_lane_critical(js_dir)
            let slot = if free: -1 else: par_slot_acquire(js_dir, js_slots)
            if free or slot >= 0:
                let job = &jobs[next]
                pids.push(ctx.process_runner().spawn_capture(job.argv, job.stdout, job.stderr))
                slots.push(slot)
                next += 1
                continue
        let pid = pids[oldest]
        rcs.push(if pid <= 0: -1 else: ctx.process_runner().wait(pid, jobs[oldest].timeout_ms))
        par_slot_release(js_dir, slots[oldest])
        oldest += 1
    rcs
