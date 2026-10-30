//! expect-stdout: grandchild gone
// A With program that runs a child passes a termination on to it: every
// program forwards SIGINT, SIGTERM and SIGHUP to the child it runs (its own
// process group) and exits with 128 + the signal. Only the compiler did, so
// a timed-out `with run tools/pub_lint.w` died and left its `with analyze`
// running for an hour, and Ctrl-C at a terminal reached only the parent.
// Here the parent times the child out; the grandchild the child runs must be
// gone after.
use std.fs
use std.process
use std.sysinfo
use std.time

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    let temp = env("TEMP")
    if temp.len() > 0: return temp
    "/tmp"

fn main:
    let argv = args()
    let me: str = argv[0]
    if argv.len() > 2 and argv[1] == "grand":
        assert(write_file(argv[2], f"{pid()}") == 0)
        let _ = sleep_secs(30)
        return
    if argv.len() > 2 and argv[1] == "child":
        let _ = run(&[me, "grand", argv[2]])
        return
    // Windows has no process groups; its runner ends a job's whole tree.
    if os() == "Windows":
        print("grandchild gone")
        return
    let base = temp_root() ++ f"/with-behav-timeout-{pid()}"
    remove_tree(base)
    assert(mkdir_p(base) == 0)
    let pid_file = base ++ "/grand.pid"
    let done = run_to_files(&[me, "child", pid_file], base ++ "/out", base ++ "/err", 2000)
    assert(done.timed_out)
    let text: str = read_file(pid_file) ?? ""
    let grand: i32 = text.parse() ?? 0
    assert(grand > 0)
    // The forwarded SIGTERM ends it at once; a moment for the exit to land.
    var waited = 0
    while process_alive(grand) and waited < 3:
        let _ = sleep_secs(1)
        waited += 1
    print(if process_alive(grand): "grandchild alive" else: "grandchild gone")
    remove_tree(base)
