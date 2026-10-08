//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process

// A build action that appends one byte at a time to a StringBuilder, run by
// the comptime evaluator: the forced action worker, the path a build takes
// before the native runner exists (#1944).
fn bytes_build_source(count: i32):
    "use std.build\nuse std.string.StringBuilder\nfn write_bytes(ctx: ActionCtx) -> i32:\n" ++ f"    var out = StringBuilder.with_capacity({count})\n    for i in 0..{count}:\n" ++ "        out.push_byte((97 + i % 26) as u8)\n" ++ f"    if out.len() != {count}: return 1\n" ++ "    ctx.fs().write_text(ctx.output(), out.to_str())\npub fn build(ctx: BuildCtx) -> Build:\n    var bytes = target_new(.Action, \"bytes\", \"\").output(\"out/bytes.txt\")\n    bytes.action = write_bytes\n    ctx.new_build().add_target(bytes).default(\"bytes\")\n"

// Peak RSS of the evaluator worker running the action for `count` bytes.
fn worker_peak_rss(dir: &str, count: i32) -> i64:
    p7_write(dir, "build.w", bytes_build_source(count))
    let stdout_path = p7_join(dir, "worker.stdout")
    let stderr_path = p7_join(dir, "worker.stderr")
    let result = run_to_files_in(dir, &[p7_compiler_path(), "build", ":bytes", "--no-deps"], stdout_path, stderr_path)
    if result.code != 0:
        print(f"FAILED [{count} bytes]: rc={result.code}")
        print(read_file(stderr_path).unwrap())
    assert(result.code == 0)
    let text = read_file(p7_join(dir, "out/bytes.txt")).unwrap()
    assert(text.len() == count as i64)
    assert(text[0] == 97)
    assert(text[count - 1] as i32 == 97 + (count - 1) % 26)
    result.peak_rss

fn main:
    let dir = p7_prepare_case("comptime_string_builder_bytes", "sb_bytes")
    let saved_out = env("WITH_OUT_DIR")
    let saved_worker = env("WITH_BUILD_ACTION_WORKER")
    let saved_force = env("WITH_BUILD_ACTION_FORCE")
    assert(set_env("WITH_OUT_DIR", p7_join(dir, "out")) == 0)
    assert(set_env("WITH_BUILD_ACTION_WORKER", "bytes") == 0)
    assert(set_env("WITH_BUILD_ACTION_FORCE", "1") == 0)
    // The worker's own floor (compiling build.w, evaluating the graph)
    // differs by host and compiler; the bound is on what the bytes add.
    let floor = worker_peak_rss(dir, 1)
    let million = worker_peak_rss(dir, 1000000)
    assert(set_env("WITH_OUT_DIR", saved_out) == 0)
    assert(set_env("WITH_BUILD_ACTION_WORKER", saved_worker) == 0)
    assert(set_env("WITH_BUILD_ACTION_FORCE", saved_force) == 0)
    // One growable buffer: a 1 MB builder costs a few MB over the floor.
    // A value per pushed byte (three blocks per push, every chunk cloned
    // twice to materialize) cost 171 to 211 MiB more.
    let grown = million - floor
    if grown >= 50331648:
        print(f"FAILED: 1 MB byte by byte grew the worker by {grown} bytes (floor {floor}, 1 MB {million})")
    assert(grown < 50331648)
    print("ok")
