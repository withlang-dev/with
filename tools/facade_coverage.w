// facade_coverage -- draft every library on the #3115 list with `with get`
// and tabulate what each facade presents and why the rest stays raw (#3116).
//
// For each library a scratch project is made under the work directory,
// `with init .` and `with get c.<lib>` run in it, and the package's
// facade-report.txt is read. The output is one Markdown document: a table
// per library (version, functions, presented safely, raw), the raw verdicts
// clustered by kind across the list (each cluster is a facade-grammar
// feature or a proof-engine fix: the work list of #3115), then each
// library's own clusters. A TSV of the counts is written beside it so two
// runs can be compared after a grammar or proof fix.
//
//   with run tools/facade_coverage.w [--with PATH] [--work DIR] [--out FILE]
//                                    [--reports-only] [LIB ...]
//   --with PATH      the compiler that fetches (default: $WITH, else `with` on PATH)
//   --work DIR       where the scratch projects live (default out/facade-coverage)
//   --out FILE       the Markdown report (default <work>/coverage.md)
//   --reports-only   read the reports already under <work>; fetch nothing
//   --fetch-missing  fetch only the libraries with no report under <work>
//                    (a second pass after transient download failures:
//                    GitHub's release assets 504 for minutes at a time)
//   LIB ...          a subset of the list (default: every library on it)
//
// The fetch is a user's action (D171): `with get` may use the host's tools,
// and a library whose chain this host cannot provide is a row that says so,
// never a port or a substitution.

use std.fs
use std.os
use std.process
use std.string

fn libraries() -> List[str]:
    ["zlib", "zstd", "lz4", "bzip2", "xz_utils", "libarchive",
     "openssl", "libsodium",
     "libcurl", "nghttp2", "libssh2",
     "sqlite3",
     "libxml2", "expat", "libyaml", "yyjson", "cjson",
     "pcre2",
     "libpng", "libjpeg-turbo", "freetype", "harfbuzz",
     "sdl", "glfw", "raylib",
     "libuv", "libevent",
     "libgit2", "protobuf-c"]

// One refusal kind: how many functions it keeps raw, in which libraries,
// and one function that shows it.
type Kind {
    name: str,
    count: i32,
    example: str,
    libs: List[str],
}

type Clusters {
    kinds: List[Kind],
}

impl Clusters:
    mut fn add(name: &str, example: &str, lib: &str):
        var at = -1
        for (i, kind) in self.kinds.enumerate():
            if kind.name == name: at = i
        if at < 0:
            self.kinds.push(Kind { name: name.to_owned(), count: 1, example: lib ++ ": " ++ example, libs: [lib.to_owned()] })
            return
        self.kinds[at].count = self.kinds[at].count + 1
        if not self.kinds[at].libs.contains(lib): self.kinds[at].libs.push(lib.to_owned())

    mut fn sorted():
        self.kinds.sort_by(by_count_desc)

fn by_count_desc(a: &Kind, b: &Kind) -> i32:
    if a.count != b.count: return b.count - a.count
    string_cmp(a.name, b.name)

type Row {
    lib: str,
    version: str,
    // Empty when the report was read; otherwise why there is none.
    status: str,
    total: i32,
    safe: i32,
    raw: i32,
    internal: i32,
    note: str,
    kinds: Clusters,
}

fn empty_row(lib: &str, status: &str) -> Row:
    Row { lib: lib.to_owned(), version: "", status: status.to_owned(), total: 0, safe: 0, raw: 0, internal: 0, note: "", kinds: Clusters { kinds: [] } }

// The pointee class of a C pointer type the facade did not model.
fn pointer_class(ty: &str) -> str:
    let t = ty.trim()
    if t == "*const c_char" or t == "*mut c_char": return "C text (*const c_char)"
    if t.contains("c_void"): return "void pointer (*mut c_void)"
    if t.starts_with("extern"): return "callback"
    if t.starts_with("*mut *") or t.starts_with("*const *"): return "pointer to a pointer"
    var pointee = t
    if pointee.starts_with("*mut "): pointee = pointee.slice(5, pointee.len())
    else if pointee.starts_with("*const "): pointee = pointee.slice(7, pointee.len())
    let scalars = ["i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64", "f32", "f64", "isize", "usize", "bool", "c_int", "c_uint", "c_long", "c_ulong", "c_char"]
    if scalars.contains(pointee): return "pointer to a scalar (an out-pointer or a buffer)"
    if pointee.starts_with("["): return "array"
    "pointer to an unmodeled record"

// The last clause of a retention trail: where the parameter ended up.
fn retention_class(why: &str) -> str:
    let last = why.rfind(", ")
    // Bound before the join: a compiler before #3165 freed the slice at
    // the arm's end and the join read blank bytes.
    let rest = if last < 0: why.to_owned() else: why.slice(last + 2, why.len())
    let tail = rest.trim()
    if tail.starts_with("which no unit defines"): return "passed to a callee no unit defines"
    if tail.starts_with("stored in a field"): return "stored in a field"
    if tail.starts_with("stored through local"): return "stored through a local"
    if tail.starts_with("stored through"): return "stored through a parameter"
    if tail == "stored": return "stored"
    tail.to_owned()

// Why a record-pointer return is unproven, with the function's own locals
// and callees folded away; a callee's reason is folded the same way.
fn origin_class(why: &str) -> str:
    let w = why.trim()
    if w.starts_with("returns a part of"): return "returns a part of a parameter"
    if w.starts_with("returns global state"): return "returns global state"
    if w.starts_with("returns only NULL") or w.starts_with("no single source"): return w.to_owned()
    let callee = w.find(" is unproven (")
    if callee >= 0:
        let inner = w.slice(callee + " is unproven (".len(), w.len())
        let close = inner.rfind(")")
        let reason = if close < 0: inner.to_owned() else: inner.slice(0, close)
        if reason.trim().len() == 0: return "a callee is unproven: no reason given (the proof names itself)"
        // The depth of the chain says nothing about the kind.
        let folded = origin_class(reason)
        return if folded.starts_with("a callee is unproven: "): folded else: "a callee is unproven: " ++ folded
    if w.ends_with(" is not defined in the package"): return "a callee is not defined in the package"
    if w.starts_with("local "):
        if w.contains("is stored or its address taken"): return "a local is stored or its address taken"
        if w.contains("has more than one source"): return "a local has more than one source"
        if w.contains("which retains it"): return "a local is passed to a callee that retains it"
        return "a local " ++ w.slice(w.find(" is ") + 1, w.len())
    if w.starts_with("returns ") and w.contains(" and "): return "returns more than one source"
    w.to_owned()

// The kind of a `raw:` verdict, with the function's own names and types
// folded away so the same gap counts once across libraries. The report's
// trailing notes (the attributes the library ships, the gir and registry
// summaries) say nothing about the kind.
fn classify(verdict: &str) -> str:
    let attrs = verdict.find(" [attributes:")
    let bare = if attrs < 0: verdict.to_owned() else: verdict.slice(0, attrs)
    let v = bare.slice(4, bare.len()).trim()
    if v.starts_with("returns ") and v.contains(", a pointer to no record"):
        let ty = v.slice(8, v.find(", a pointer to no record"))
        return "returns " ++ pointer_class(ty) ++ ", a pointer to no record"
    let unmodeled = "parameter of unmodeled pointer type "
    if v.starts_with(unmodeled): return "parameter of an unmodeled pointer type: " ++ pointer_class(v.slice(unmodeled.len(), v.len()))
    if v.starts_with("parameter of a callback or array type"): return "parameter of a callback or array type"
    if v.starts_with("retains param "):
        let open = v.find("(")
        let close = v.rfind(")")
        if open >= 0 and close > open: return "retains a parameter, " ++ retention_class(v.slice(open + 1, close)) ++ "; not proven"
        return "retains a parameter; not proven"
    let unproven = " unproven: "
    let at = v.find(unproven)
    if at >= 0: return "returns a record pointer, unproven: " ++ origin_class(v.slice(at + unproven.len(), v.len()))
    if v.contains("but variadic"): return "owned producer, but variadic"
    if v.contains("but param ") and v.contains("which the facade does not describe"):
        let is_at = v.find(" is ")
        let ty = v.slice(is_at + 4, v.find(", which the facade does not describe"))
        return "owned producer with an undescribed parameter: " ++ pointer_class(ty)
    if v.contains("no single destroyer"): return "owned return, but no single destroyer in the package"
    if v.contains("which a borrowed return cannot state"):
        return if v.contains(" frees param"): "borrowed return that also frees a parameter" else: "borrowed return that also retains a parameter"
    if v.contains("is not a modeled resource"): return "borrowed return from or to an unmodeled resource"
    if v.starts_with("destroys param ") and v.contains("which is not its first parameter"): return "destroyer whose resource is not its first parameter (§16.2b.13)"
    if v.starts_with("destroys param ") and v.contains("but parameter of unmodeled pointer type "):
        let from = v.find("but parameter of unmodeled pointer type ")
        return "destroyer with an undescribed parameter: " ++ pointer_class(v.slice(from + "but parameter of unmodeled pointer type ".len(), v.len()))
    if v.starts_with("destroys param ") and v.contains("but parameter of a callback or array type"): return "destroyer with an undescribed parameter: callback"
    "other: " ++ v

fn record_class(verdict: &str) -> str:
    if verdict.starts_with("destroyed but never produced"): return "record: destroyed but never produced here (no resource)"
    if verdict.contains("no unary destroyer"): return "record: produced, but no unary destroyer in the package"
    if verdict.contains("but no resource:"): return "record: produced and dropped, but a producer parameter is undescribed"
    "record: produced, with several unary destroyers"

fn is_record_line(verdict: &str) -> bool:
    verdict.starts_with("destroyed but never produced") or verdict.contains("producer(s) and")

fn parse_report(lib: &str, version: &str, text: &str) -> Row:
    var row = empty_row(lib, "")
    row.version = version.to_owned()
    let lines = text.split("\n")
    if lines.len() == 0 or not lines[0].starts_with("facade "): return empty_row(lib, "the report does not start with a facade summary")
    let head = lines[0].fields()
    // facade NAME: T functions, S presented safely, R raw[; I internal ...]
    row.total = parse(head[2])
    row.safe = parse(head[4])
    row.raw = parse(head[7])
    if head.len() > 9: row.internal = parse(head[9])
    for i in 1..lines.len():
        let line = lines[i]
        if not line.starts_with("  ") or line.starts_with("    "): continue
        let body = line.trim()
        if body.len() == 0: continue
        if is_digit(body.as_bytes()[0]):
            row.note = row.note ++ (if row.note.len() > 0: " " else: "") ++ body
            continue
        let colon = body.find(": ")
        if colon < 0: continue
        let name = body.slice(0, colon)
        let verdict = body.slice(colon + 2, body.len())
        if is_record_line(verdict): row.kinds.add(record_class(verdict), name, lib)
        else if verdict.starts_with("raw:"): row.kinds.add(classify(verdict), name, lib)
    row.kinds.sorted()
    row

// The last non-empty line of a log: what `with get` said last.
fn last_line(path: &str) -> str:
    let text = read_file(path) ?? ""
    let lines = text.split("\n")
    var i = lines.len() - 1
    while i >= 0:
        if lines[i].trim().len() > 0: return lines[i].trim().to_owned()
        i = i - 1
    ""

// The line of a log that says why there is no facade.
fn facade_line(path: &str) -> str:
    let text = read_file(path) ?? ""
    let lines = text.split("\n")
    for (i, line) in lines.enumerate():
        if not (line.contains("facade:") or line.contains("with get: facade")): continue
        // The reason may continue on the lines after it that name the
        // archives tried (#3169: `  https://…: did not download (…)`);
        // the fetch's own progress lines (`  downloading …`) are not it.
        var said = line.trim().to_owned()
        var k = i + 1
        while k < lines.len() and (lines[k].starts_with("  https://") or lines[k].starts_with("  file://")):
            said = said ++ " " ++ lines[k].trim()
            k = k + 1
        return said
    ""

fn fetch(with_bin: &str, work: &str, lib: &str) -> str:
    let dir = work ++ "/" ++ lib
    remove_tree(dir)
    if mkdir_p(dir) != 0: return "could not create " ++ dir
    let init = run_to_files_in(dir, &[with_bin.to_owned(), "init", "."], dir ++ ".init.out", dir ++ ".init.err")
    if init.code != 0: return f"with init exited {init.code}: " ++ last_line(dir ++ ".init.err")
    let got = run_to_files_in(dir, &[with_bin.to_owned(), "get", "c." ++ lib], dir ++ ".get.out", dir ++ ".get.err")
    if got.code != 0: return f"with get exited {got.code}: " ++ last_line(dir ++ ".get.err")
    ""

// The report under the project's dependency directory, whatever version
// `with get` resolved.
fn find_report(work: &str, lib: &str) -> (str, str):
    let deps = work ++ "/" ++ lib ++ "/.with/deps/c/" ++ lib
    for version in list_dir_text(deps).split("\n"):
        if version.len() == 0: continue
        let path = deps ++ "/" ++ version ++ "/facade-report.txt"
        if file_exists(path): return (version.to_owned(), path)
    ("", "")

fn percent(part: i32, whole: i32) -> str:
    if whole == 0: return "-"
    f"{part * 100 / whole}%"

fn cell(s: &str) -> str: s.replace("|", "\\|")

fn markdown(rows: &List[Row], all: &Clusters, with_bin: &str) -> str:
    var out = "# Facade coverage across the #3115 list\n\n"
    out = out ++ "Written by `with run tools/facade_coverage.w` (" ++ with_bin ++ " on " ++ os() ++ " " ++ arch() ++ "): each library fetched into a fresh project with `with get c.<lib>`, its `facade-report.txt` read. Regenerate after every facade-grammar or proof-engine change and compare the TSV beside this file.\n\n"
    out = out ++ "## Coverage\n\n| library | version | functions | presented safely | raw | presented | note |\n|---|---|---:|---:|---:|---:|---|\n"
    var total = 0
    var safe = 0
    var raw = 0
    var fetched = 0
    for row in rows:
        if row.status.len() > 0:
            out = out ++ "| " ++ row.lib ++ " | | | | | | no facade: " ++ cell(row.status) ++ " |\n"
            continue
        fetched = fetched + 1
        total = total + row.total
        safe = safe + row.safe
        raw = raw + row.raw
        out = out ++ "| " ++ row.lib ++ " | " ++ row.version ++ f" | {row.total} | {row.safe} | {row.raw} | " ++ percent(row.safe, row.total) ++ " | " ++ cell(row.note) ++ " |\n"
    out = out ++ f"| **{fetched} libraries** | | **{total}** | **{safe}** | **{raw}** | **" ++ percent(safe, total) ++ "** | |\n\n"
    out = out ++ "## Raw verdicts by kind\n\nEach kind is one gap: a facade-grammar feature, a proof-engine misread, or a registry fact the library needs. A `record:` row is a type the facade could not make a resource.\n\n| kind | functions | libraries | example |\n|---|---:|---:|---|\n"
    for kind in all.kinds:
        out = out ++ "| " ++ cell(kind.name) ++ f" | {kind.count} | {kind.libs.len()} | " ++ cell(kind.example) ++ " |\n"
    out = out ++ "\n## Per library\n\n"
    for row in rows:
        if row.status.len() > 0: continue
        out = out ++ "### " ++ row.lib ++ " " ++ row.version ++ f"\n\n{row.total} functions, {row.safe} presented safely, {row.raw} raw"
        if row.internal > 0: out = out ++ f", {row.internal} internal"
        out = out ++ ".\n\n| kind | functions | example |\n|---|---:|---|\n"
        for kind in row.kinds.kinds:
            let example = kind.example.slice(kind.example.find(": ") + 2, kind.example.len())
            out = out ++ "| " ++ cell(kind.name) ++ f" | {kind.count} | " ++ cell(example) ++ " |\n"
        out = out ++ "\n"
    out

fn tsv(rows: &List[Row]) -> str:
    var out = "library\tversion\tfunctions\tpresented\traw\tinternal\tstatus\n"
    for row in rows:
        out = out ++ row.lib ++ "\t" ++ row.version ++ f"\t{row.total}\t{row.safe}\t{row.raw}\t{row.internal}\t" ++ row.status ++ "\n"
    out

var with_bin = env("WITH")
if with_bin.len() == 0: with_bin = "with"
var work = "out/facade-coverage"
var out_path = ""
var reports_only = false
var fetch_missing = false
var selected = []
let argv = args()
var i = 1
while i < argv.len():
    let arg = argv[i]
    if arg == "--with" and i + 1 < argv.len():
        i = i + 1
        with_bin = argv[i].to_owned()
    else if arg == "--work" and i + 1 < argv.len():
        i = i + 1
        work = argv[i].to_owned()
    else if arg == "--out" and i + 1 < argv.len():
        i = i + 1
        out_path = argv[i].to_owned()
    else if arg == "--reports-only": reports_only = true
    else if arg == "--fetch-missing": fetch_missing = true
    else if arg == "--help" or arg == "-h":
        print("usage: with run tools/facade_coverage.w [--with PATH] [--work DIR] [--out FILE] [--reports-only] [LIB ...]")
        exit_code(0)
    else if arg.starts_with("--"):
        eprint("facade_coverage: unknown option " ++ arg)
        exit_code(2)
    else: selected.push(arg.to_owned())
    i = i + 1
// The scratch projects are named by their full path: a compiler whose
// spawner predates #3166 gave a child a relative PWD, and `with get` then
// rooted the project at a relative path.
if not (work.starts_with("/") or (work.len() > 1 and work.slice(1, 2) == ":")): work = current_dir() ++ "/" ++ work
if out_path.len() == 0: out_path = work ++ "/coverage.md"
let libs = if selected.len() > 0: selected else: libraries()
assert(mkdir_p(work) == 0)

var rows = []
var all = Clusters { kinds: [] }
for lib in libs:
    var status = ""
    let fetched_before = find_report(work, lib)
    if not reports_only and not (fetch_missing and fetched_before.1.len() > 0):
        eprint("facade_coverage: fetching c." ++ lib)
        status = fetch(with_bin, work, lib)
    let (version, path) = find_report(work, lib)
    if path.len() == 0:
        if status.len() == 0:
            let said = facade_line(work ++ "/" ++ lib ++ ".get.err")
            status = if said.len() > 0: said else: "no facade-report.txt was written"
        eprint("facade_coverage: " ++ lib ++ ": " ++ status)
        rows.push(empty_row(lib, status))
        continue
    let row = parse_report(lib, version, read_file(path) ?? "")
    eprint(f"facade_coverage: {lib} {version}: {row.total} functions, {row.safe} presented safely, {row.raw} raw")
    for kind in row.kinds.kinds:
        for k in 0..kind.count: all.add(kind.name, kind.example.slice(kind.example.find(": ") + 2, kind.example.len()), lib)
    rows.push(row)
all.sorted()
let doc = markdown(rows, all, with_bin)
assert(write_file(out_path, doc) == 0)
let tsv_path = out_path.slice(0, out_path.rfind(".")) ++ ".tsv"
assert(write_file(tsv_path, tsv(rows)) == 0)
print(doc.slice(0, doc.find("## Raw verdicts by kind")))
print("facade_coverage: wrote " ++ out_path ++ " and " ++ tsv_path)
