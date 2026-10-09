module build.par

// A sliding window of child processes for an action whose cases are
// independent: the tools lane's builds, emit-c-smoke's emit and C compile
// steps. At most `width` children are alive (the host's logical cores by
// default); the oldest is reaped to open each slot, so one slow case never
// idles the rest of the window. Every child is reaped before par_run
// returns, and every exit code comes back in job order, so a lane reports
// every failure, not the first.

use std.build


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
pub fn par_width(jobs: &List[ParJob]) -> i32: if jobs.len() as i32 > 32: 32 else: jobs.len() as i32

/// Runs every job with at most `width` children alive, reaping the oldest
/// to open each slot. Returns each job's exit code in job order; -1 means
/// the job could not be spawned. Returns only after every child is reaped.
pub fn par_run(ctx: &ActionCtx, jobs: &List[ParJob], width: i32) -> List[i32]:
    let limit = if width < 1: 1 else: width
    let total = jobs.len() as i32
    var rcs: List[i32] = List.new()
    var pids: List[i32] = List.new()
    var next = 0
    var oldest = 0
    while oldest < total:
        if next < total and next - oldest < limit:
            let job = &jobs[next]
            pids.push(ctx.process_runner().spawn_capture(job.argv, job.stdout, job.stderr))
            next += 1
            continue
        let pid = pids[oldest]
        rcs.push(if pid <= 0: -1 else: ctx.process_runner().wait(pid, jobs[oldest].timeout_ms))
        oldest += 1
    rcs
