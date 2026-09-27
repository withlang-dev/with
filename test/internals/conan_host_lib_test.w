//! expect-stdout: ok
use compiler.ConanClient
use compiler.Runtime
use std.process

// `with get c.raylib` writes the host's GL and X11 as `<name>/system`
// packages. A runtime package installs only `lib<name>.so.<N>`; the
// `lib<name>.so` symlink `-l<name>` needs comes with the -dev package, so on a
// host without one the program did not link ("cannot find -lGL").
fn main:
    var base = env("TMPDIR")
    if base.len() == 0: base = "/tmp"
    let root = base ++ f"/with-conan-host-lib-{pid()}"
    let _clean = runtime_remove_tree(root)
    assert(runtime_mkdir_p(root ++ "/a") == 0)
    assert(runtime_mkdir_p(root ++ "/b") == 0)
    let dirs: Vec[str] = Vec.new()
    dirs.push(root ++ "/a")
    dirs.push(root ++ "/b")
    // Only the runtime soname: link it by path, the highest version, never
    // the real file behind it.
    assert(runtime_write_file(root ++ "/a/libGL.so.1", "") == 0)
    assert(runtime_write_file(root ++ "/a/libGL.so.1.7.0", "") == 0)
    assert(conan_host_lib_path(&dirs, "GL") == root ++ "/a/libGL.so.1")
    assert(runtime_write_file(root ++ "/b/libX11.so.6", "") == 0)
    assert(runtime_write_file(root ++ "/b/libX11.so.3", "") == 0)
    assert(conan_host_lib_path(&dirs, "X11") == root ++ "/b/libX11.so.6")
    // A dev symlink in any dir keeps `-l<name>`.
    assert(runtime_write_file(root ++ "/b/libGL.so", "") == 0)
    assert(conan_host_lib_path(&dirs, "GL") == "")
    // Nothing installed: `-l<name>`, so the linker reports it.
    assert(conan_host_lib_path(&dirs, "udev") == "")
    // A same-prefixed library is not this one.
    assert(runtime_write_file(root ++ "/a/libGLX.so.0", "") == 0)
    assert(conan_host_lib_path(&dirs, "GLX") == root ++ "/a/libGLX.so.0")
    assert(conan_host_lib_path(&dirs, "G") == "")
    let _done = runtime_remove_tree(root)
    print("ok")
