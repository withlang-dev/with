//! expect-stdout: ok
use compiler.HostLibs
use compiler.Runtime
use std.process

// An ELF header: class (1 = 32-bit, 2 = 64-bit) and e_machine (3 = i386,
// 62 = x86-64, 183 = aarch64).
fn elf(class: i32, machine: i32):
    var head = "\x7fELF"
    head = head ++ (if class == 2: "\x02" else: "\x01") ++ "\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00"
    head ++ (if machine == 62: ">\x00" else if machine == 183: "\xb7\x00" else: "\x03\x00") ++ "\x01\x00\x00\x00"

fn pad(text: &str, width: isize):
    var field = text.clone()
    while field.len() < width: field = field ++ " "
    field

// name[16] date[12] uid[6] gid[6] mode[8] size[10] "`\n"
fn ar_header(name: &str, size: isize): pad(name, 16) ++ pad("0", 12) ++ pad("0", 6) ++ pad("0", 6) ++ pad("644", 8) ++ pad(f"{size}", 10) ++ "`\n"

// An ar archive whose symbol table (odd-sized, so padded) precedes one object.
fn archive(member: &str):
    let symtab = "\x00\x00\x00"
    "!<arch>\n" ++ ar_header("/", symtab.len()) ++ symtab ++ "\n" ++ ar_header("x.o/", member.len()) ++ member

fn main:
    var base = env("TMPDIR")
    if base.len() == 0: base = "/tmp"
    let root = base ++ f"/with-host-libs-{pid()}"
    let _clean = runtime_remove_tree(root)
    assert(runtime_mkdir_p(root ++ "/a") == 0)
    assert(runtime_mkdir_p(root ++ "/b") == 0)
    let dirs: List[str] = List.new()
    dirs.push(root ++ "/a")
    dirs.push(root ++ "/b")

    // `with get c.raylib` names GL and X11 for the host to provide. A runtime
    // package installs only `lib<name>.so.<N>`; the `lib<name>.so` symlink
    // `-l<name>` needs comes with the -dev package. Only the runtime soname:
    // link it by path, the highest version, never the real file behind it.
    assert(runtime_write_file(root ++ "/a/libGL.so.1", "") == 0)
    assert(runtime_write_file(root ++ "/a/libGL.so.1.7.0", "") == 0)
    assert(host_library_path(&dirs, "GL", "x86_64") == root ++ "/a/libGL.so.1")
    assert(runtime_write_file(root ++ "/b/libX11.so.6", "") == 0)
    assert(runtime_write_file(root ++ "/b/libX11.so.3", "") == 0)
    assert(host_library_path(&dirs, "X11", "x86_64") == root ++ "/b/libX11.so.6")
    // A dev symlink in any dir wins over a soname.
    assert(runtime_write_file(root ++ "/b/libGL.so", "") == 0)
    assert(host_library_path(&dirs, "GL", "x86_64") == root ++ "/b/libGL.so")
    // Nothing installed: "", so the link keeps `-l<name>` and the linker reports it.
    assert(host_library_path(&dirs, "udev", "x86_64") == "")
    // A same-prefixed library is not this one.
    assert(runtime_write_file(root ++ "/a/libGLX.so.0", "") == 0)
    assert(host_library_path(&dirs, "GLX", "x86_64") == root ++ "/a/libGLX.so.0")
    assert(host_library_path(&dirs, "G", "x86_64") == "")

    // Another machine's library is skipped, as GNU ld skips it (lld refuses
    // it): SteamOS's ld.so.conf lists /usr/lib32 beside /usr/lib.
    assert(runtime_write_file(root ++ "/a/libXi.so", elf(1, 3)) == 0)
    assert(runtime_write_file(root ++ "/b/libXi.so", elf(2, 62)) == 0)
    assert(host_library_path(&dirs, "Xi", "x86_64") == root ++ "/b/libXi.so")
    assert(host_library_path(&dirs, "Xi", "aarch64") == "")
    assert(runtime_write_file(root ++ "/a/libz.a", archive(elf(2, 183))) == 0)
    assert(runtime_write_file(root ++ "/b/libz.a", archive(elf(2, 62))) == 0)
    assert(host_library_path(&dirs, "z", "x86_64") == root ++ "/b/libz.a")
    assert(host_library_path(&dirs, "z", "aarch64") == root ++ "/a/libz.a")
    // A linker script is read by the linker, whatever it names.
    assert(runtime_write_file(root ++ "/a/libncurses.so", "INPUT(-lncursesw)\n") == 0)
    assert(host_library_path(&dirs, "ncurses", "x86_64") == root ++ "/a/libncurses.so")
    // `-l:<file>` names the file.
    assert(host_library_path(&dirs, ":libX11.so.3", "x86_64") == root ++ "/b/libX11.so.3")

    // The directories: the loader's trusted ones that exist, then what
    // ld.so.conf names, its includes read in name order; comments, blanks,
    // hwcap lines and repeats ignored.
    let sys = root ++ "/sys"
    for dir in ["/usr/lib", "/usr/lib64", "/usr/lib32", "/opt/one/lib", "/opt/two/lib", "/etc/ld.so.conf.d"]:
        assert(runtime_mkdir_p(sys ++ dir) == 0)
    assert(runtime_write_file(sys ++ "/etc/ld.so.conf", "# loader\ninclude /etc/ld.so.conf.d/*.conf\n\n/usr/lib  # again\n") == 0)
    assert(runtime_write_file(sys ++ "/etc/ld.so.conf.d/b.conf", "/opt/two/lib\nhwcap 0 nosegneg\n") == 0)
    assert(runtime_write_file(sys ++ "/etc/ld.so.conf.d/a.conf", "/usr/lib32\n/opt/one/lib:/opt/missing\n") == 0)
    assert(runtime_write_file(sys ++ "/etc/ld.so.conf.d/c.txt", "/opt/never\n") == 0)
    let found = host_library_dirs(sys, "x86_64")
    var got = ""
    for d in found: got = got ++ d.slice(sys.len(), d.len()) ++ ";"
    assert(got == "/usr/lib64;/usr/lib;/usr/lib32;/opt/one/lib;/opt/two/lib;")
    var trusted = ""
    for d in host_library_trusted_dirs(sys, "x86_64"): trusted = trusted ++ d.slice(sys.len(), d.len()) ++ ";"
    assert(trusted == "/usr/lib64;/usr/lib;")
    // Debian's multiarch pair comes first.
    assert(runtime_mkdir_p(sys ++ "/usr/lib/aarch64-linux-gnu") == 0)
    assert(host_library_dirs(sys, "aarch64")[0] == sys ++ "/usr/lib/aarch64-linux-gnu")

    let _done = runtime_remove_tree(root)
    print("ok")
