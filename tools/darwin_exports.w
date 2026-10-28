// The macOS system libraries' export lists (#2530): what the darwin
// sysroot's stubs may name. A stub generated from a header alone names
// what the header declares, and Apple builds some of it out
// (SQLITE_OMIT_LOAD_EXTENSION drops sqlite3_load_extension): a link
// against such a stub succeeds and the call crashes at run time. The
// sysroot's stub is the header's declarations that macOS exports.
//
//   with run tools/darwin_exports.w            rewrite build/darwin_exports/
//   with run tools/darwin_exports.w --check    every stub symbol in
//                                              out/gen/darwin-sysroot is
//                                              exported by this host
//
// Both read the host's /usr/lib dylibs through dyld_info (base system on
// macOS 13+). Run the rewrite on a Mac and commit the lists; the sysroot
// build reads only the committed lists, never the host.
use std.collections.BTreeSet
use std.fs
use std.os
use std.process

fn libraries -> List[str]:
    "libsqlite3 libz libbz2 libxml2 libcurl libiconv".split(" ")

fn scratch_dir -> str: "out/darwin-exports"

// The exported symbol names of /usr/lib/<lib>.dylib, without the
// leading underscore, sorted. Empty when dyld_info fails.
fn host_exports(lib: &str) -> List[str]:
    mkdir_p(scratch_dir())
    let out_path = scratch_dir() ++ "/" ++ lib ++ ".out"
    let err_path = scratch_dir() ++ "/" ++ lib ++ ".err"
    var argv: List[str] = List.new()
    argv.push("/usr/bin/dyld_info")
    argv.push("-exports")
    argv.push("/usr/lib/" ++ lib ++ ".dylib")
    let done = run_to_files(&argv, out_path, err_path, 60000)
    var names: List[str] = List.new()
    if done.code != 0:
        eprint("error: dyld_info -exports /usr/lib/" ++ lib ++ ".dylib exited " ++ f"{done.code}" ++ ": " ++ (read_file(err_path) ?? ""))
        return names
    var sorted: BTreeSet[str] = BTreeSet.new()
    for line in (read_file(out_path) ?? "").split("\n"):
        let fields = line.fields()
        if fields.len() == 2 and fields[0].starts_with("0x") and fields[1].starts_with("_"):
            sorted.insert(fields[1].slice(1, fields[1].len()))
    for name in sorted.iter(): names.push(name)
    names

fn os_version -> str:
    let out_path = scratch_dir() ++ "/sw_vers.out"
    var argv: List[str] = List.new()
    argv.push("/usr/bin/sw_vers")
    argv.push("-productVersion")
    mkdir_p(scratch_dir())
    run_to_files(&argv, out_path, scratch_dir() ++ "/sw_vers.err", 10000)
    (read_file(out_path) ?? "").trim().to_owned()

fn rewrite -> i32:
    let version = os_version()
    mkdir_p("build/darwin_exports")
    for lib in libraries():
        let names = host_exports(lib)
        if names.len() == 0:
            eprint("error: no exports read for /usr/lib/" ++ lib ++ ".dylib")
            return 1
        var text = "# /usr/lib/" ++ lib ++ ".dylib exports, macOS " ++ version ++ " (tools/darwin_exports.w)\n"
        var prev = ""
        for name in names:
            if name == prev: continue
            text = text ++ name ++ "\n"
            prev = name
        if write_file("build/darwin_exports/" ++ lib ++ ".txt", text) != 0:
            eprint("error: could not write build/darwin_exports/" ++ lib ++ ".txt")
            return 1
        print(lib ++ ": " ++ f"{names.len()}" ++ " exports")
    0

// The symbols a generated .tbd names, without the leading underscore.
fn tbd_symbols(text: &str) -> List[str]:
    var names: List[str] = List.new()
    for part in text.split("'"):
        if part.starts_with("_") and part.len() > 1 and part.find(" ") < 0 and part.find(",") < 0:
            names.push(part.slice(1, part.len()))
    names

fn check -> i32:
    var bad = 0
    for lib in libraries():
        let stub_path = "out/gen/darwin-sysroot/usr/lib/" ++ lib ++ ".tbd"
        let stub = read_file(stub_path) ?? ""
        if stub.len() == 0:
            eprint("error: no stub at " ++ stub_path ++ " (run `with build :darwin-sysroot`)")
            return 1
        let exported = host_exports(lib)
        if exported.len() == 0:
            return 1
        var have: HashSet[str] = HashSet.new()
        for name in exported: have.insert(name)
        var missing = 0
        for name in tbd_symbols(stub):
            if not have.contains(name):
                eprint("error: " ++ stub_path ++ " names _" ++ name ++ ", which /usr/lib/" ++ lib ++ ".dylib does not export")
                missing = missing + 1
        if missing == 0:
            print(lib ++ ": every stub symbol is exported")
        bad = bad + missing
    if bad > 0: 1 else: 0

let argv = args()
if os() != "Macos":
    print("darwin exports: not a macOS host; nothing to read")
    exit_code(0)
let rc = if argv.len() > 1 and argv[1] == "--check": check() else: rewrite()
exit_code(rc)
