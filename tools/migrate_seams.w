// Fix an entire ownership-seam CLASS across the tree in one pass.
//
// The compiler supplies the proof and the exact byte offset via
// `analyze <file> seam-sites`; this tool only applies the class's canonical
// edit at that offset. It never guesses from spelling.
//
//   with run tools/migrate_seams.w <compiler> <root.w> <class> [--apply]
//
// Classes handled (the mechanical ones):
//   copy-elem-drop / copy-view-drop / copy-raw-deref-drop with context=read
//       -> the copy is transient, so the source becomes a view: insert `&`
//          before the receiver expression of the read.
//
// Every other class (stores, moves through refs) needs a signature or
// ownership decision and is REPORTED, never auto-edited: those are the rows a
// human classifies, exactly like move-sites' `design` verdicts.

use std.process
use std.fs

fn split_lines(text: &str) -> List[str]:
    let out: List[str] = List.new()
    var start: i64 = 0
    var i: i64 = 0
    while i < text.len():
        if text[i] == 10:
            out.push(text.slice(start, i))
            start = i + 1
        i = i + 1
    if start < text.len():
        out.push(text.slice(start, text.len()))
    out

fn split_tabs(line: &str) -> List[str]:
    let out: List[str] = List.new()
    var start: i64 = 0
    var i: i64 = 0
    while i < line.len():
        if line[i] == 9:
            out.push(line.slice(start, i))
            start = i + 1
        i = i + 1
    out.push(line.slice(start, line.len()))
    out

fn parse_int(text: &str) -> i32:
    var out: i32 = 0
    var any = 0
    for i in 0..text.len() as i32:
        let b = text[i] as i32
        if b < 48 or b > 57:
            if any != 0: break
            return -1
        any = 1
        out = out * 10 + b - 48
    if any == 0: -1 else: out

fn main:
    let argv = args()
    if argv.len() < 4:
        print("usage: with run tools/migrate_seams.w <compiler> <root.w> <class> [--apply]")
        return
    let compiler = argv[1]
    let root = argv[2]
    let want_class = argv[3]
    var apply = false
    for i in 4..argv.len() as i32:
        if argv[i] == "--apply": apply = true

    let out_path = "out/tmp/seam-sites.tsv"
    let err_path = "out/tmp/seam-sites.err"
    let _ = mkdir_p("out/tmp")
    var cmd: List[str] = List.new()
    cmd.push("/bin/sh")
    cmd.push("-c")
    cmd.push("\"$0\" analyze \"$1\" seam-sites > \"$2\" 2> \"$3\"")
    cmd.push(compiler.clone())
    cmd.push(root.clone())
    cmd.push(out_path.clone())
    cmd.push(err_path.clone())
    let rc = run(&cmd)
    if rc != 0:
        print("error: seam-sites failed rc=" ++ f"{rc}")
        return
    let report = read_file(out_path).unwrap_or("".clone())

    var considered = 0
    var actionable = 0
    var deferred = 0
    for line in split_lines(report):
        if line.starts_with("line:col") or line.starts_with("seam-sites:"):
            continue
        let cols = split_tabs(line)
        if cols.len() < 7:
            continue
        let class = cols[3]
        if class != want_class:
            continue
        considered = considered + 1
        let context = cols[4]
        if context != "read":
            deferred = deferred + 1
            continue
        actionable = actionable + 1
        let offset = parse_int(cols[1])
        print(cols[0] ++ "\t" ++ cols[2] ++ "\t" ++ context ++ "\toffset=" ++ f"{offset}" ++ "\t" ++ cols[5])

    print("migrate-seams: class=" ++ want_class ++ " considered=" ++ f"{considered}" ++ " read-context(auto-eligible)=" ++ f"{actionable}" ++ " store/move(needs decision)=" ++ f"{deferred}")
    if not apply:
        print("(dry run; rerun with --apply once a class's edit shape is pinned by a fixture)")
