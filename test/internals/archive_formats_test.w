//! expect-stdout: ok

use compiler.TarExtract
use compiler.Runtime

// #1915: `with get` unpacks .tar.xz, .tar.bz2 and .zip source archives
// itself (compiler.Xz, compiler.Bzip2, std.zip), told apart by their first
// bytes, not with the host's tar or unzip. The fixtures are one small
// release-shaped tree (pkg-1.0/README, pkg-1.0/src/numbers.txt) packed by
// the reference tools: `xz -9`, `bzip2 -9` and `zip -r`.

fn numbers() -> str:
    var out = ""
    for i in 1..5001: out = out ++ f"{i}\n"
    out

fn main:
    let tmp = runtime_getenv("TMPDIR") ++ f"/with-archive-formats-{runtime_getpid()}"
    let _clean = runtime_remove_tree(tmp)
    let expected = numbers()
    for name in ["pkg-1.0.tar.xz", "pkg-1.0.tar.bz2", "pkg-1.0.zip"]:
        let dest = tmp ++ "/" ++ name
        let problem = archive_extract("test/internals/archives/" ++ name, dest)
        if problem.len() > 0: print(problem)
        assert(problem == "")
        assert(runtime_read_file(dest ++ "/pkg-1.0/README") == "hello from an archive\n")
        assert(runtime_read_file(dest ++ "/pkg-1.0/src/numbers.txt") == expected)
    // A damaged archive is refused with its reason, never half-unpacked quietly.
    let broken = tmp ++ "/broken.tar.xz"
    let good = runtime_read_file("test/internals/archives/pkg-1.0.tar.xz")
    assert(runtime_write_file(broken, good.slice(0, 900) ++ "X" ++ good.slice(901, good.len())) == 0)
    assert(archive_extract(broken, tmp ++ "/broken").len() > 0)
    let _done = runtime_remove_tree(tmp)
    print("ok")
