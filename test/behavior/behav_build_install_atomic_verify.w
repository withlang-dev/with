//! expect-stdout: ok
// The one install path (the .Install kind and the driver's `:install-user`
// fast path): the destination gets a fresh inode by rename, never an
// in-place write, and `verify=` proves the installed executable starts and
// is the source. 2026-09-22: `:install-user` truncated the installed, already
// executed signed compiler in place (same inode), printed success, and macOS
// SIGKILLed the next launch.
use BuildGraphOps
use pre_d_build_runner
use std.fs
use std.process
use std.sysinfo

// `print` ends the line.
const PROBE_OUTPUT: str = "install-probe\n"

fn text(path: &str): read_file(path) ?? ""

fn hard_link(existing: &str, alias: &str) -> bool:
    var argv: Vec[str] = Vec.new()
    argv.push("/bin/ln")
    argv.push(existing.clone())
    argv.push(alias.clone())
    run(&argv) == 0

// A plain file: the rename leaves a hard link to the old destination holding
// the old bytes. An in-place write would have changed them through the link.
fn check_fresh_inode(root: &str):
    let dest = root ++ "/plain/artifact"
    assert(write_file(root ++ "/first", "first payload") == 0)
    assert(write_file(root ++ "/second", "second payload") == 0)
    assert(build_graph_install_path("plain", root ++ "/first", "first payload", dest, 0o644, "") == 0)
    let alias = root ++ "/plain-alias"
    assert(hard_link(dest, alias))
    assert(build_graph_install_path("plain", root ++ "/second", "second payload", dest, 0o644, "") == 0)
    assert(text(dest) == "second payload")
    assert(text(alias) == "first payload")

// Two signed executables (on Darwin, both linker-signed): the compiler and
// this test's own binary, whose `version` prints PROBE_OUTPUT. The compiler
// is installed and run, then this binary is installed over it: new inode,
// and the installed file launches and prints what its source prints. Then
// the compiler goes back over the executed test binary.
fn check_signed_executable_over_executed(root: &str, self_path: &str):
    let compiler = p7_compiler_path()
    assert(file_exists(compiler))
    let compiler_bytes = text(compiler)
    let self_bytes = text(self_path)
    assert(compiler_bytes.len() > 0 and self_bytes.len() > 0)
    let dest = root ++ "/bin/with"
    assert(build_graph_install_path("signed", compiler, compiler_bytes, dest, 0o755, "version") == 0)
    let alias = root ++ "/with-alias"
    assert(hard_link(dest, alias))
    assert(build_graph_install_path("signed", self_path, self_bytes, dest, 0o755, "version") == 0)
    assert(text(alias) == compiler_bytes)
    assert(text(dest) == self_bytes)
    assert(build_graph_install_verify_failure(dest, "version", PROBE_OUTPUT) == "")
    assert(remove_file(alias) == 0)
    assert(hard_link(dest, alias))
    assert(build_graph_install_path("signed", compiler, compiler_bytes, dest, 0o755, "version") == 0)
    assert(text(alias) == self_bytes)
    assert(text(dest) == compiler_bytes)

// Verification fails loudly: a destination that cannot execute, one that
// exits non-zero, and one that prints something other than its source.
fn check_verify_fails(root: &str, self_path: &str):
    let not_exec = root ++ "/not-exec"
    assert(write_file(not_exec, "not a program") == 0)
    assert(chmod(not_exec, 0o644) == 0)
    assert(build_graph_install_verify_failure(not_exec, "version", "").starts_with("exited "))
    assert(build_graph_install_verify_failure(self_path, "fail", "").starts_with("exited "))
    assert(build_graph_install_verify_failure(self_path, "version", "other\n").starts_with("printed "))
    // A source that cannot run is never installed: the destination keeps its
    // old bytes.
    let dest = root ++ "/kept/artifact"
    assert(build_graph_install_path("kept", root ++ "/first", "first payload", dest, 0o644, "") == 0)
    assert(build_graph_install_path("kept", not_exec, "not a program", dest, 0o755, "version") == 1)
    assert(text(dest) == "first payload")

fn main:
    let argv = args()
    if argv.len() > 1 and argv[1] == "version":
        print("install-probe")
        return
    if argv.len() > 1 and argv[1] == "fail":
        exit_code(3)
    let self_path = p7_abs(argv[0])
    let root = p7_abs(f"out/build-install-atomic-{pid()}")
    assert(mkdir_p(root) == 0)
    // Hard links, and running this binary as an installed executable, are
    // POSIX-host checks; the code-signature kill they guard is Darwin's.
    if os() != "Windows":
        check_fresh_inode(root)
        check_signed_executable_over_executed(root, self_path)
        check_verify_fails(root, self_path)
    assert(remove_tree(root) == 0)
    print("ok")
