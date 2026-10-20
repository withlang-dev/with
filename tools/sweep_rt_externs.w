use std.fs
use std.process

// sweep_rt_externs.w <rt.wi> <dir>...: in every .w under the dirs (recursively),
// delete each top-level `extern fn with_*` declaration (and an `@[effect]`
// line directly above it) and add `use rt.<module>` for the runtime modules
// that define the deleted names — `rt.platform` / `rt.fiber_core` for the
// host's platform and fiber-core files (D30 steps 3 and 4). An extern the
// interface does not provide (an LLVM/clang bridge function) stays. Prints a
// report.
let argv = args()
let wi = read_file(argv[1]) ?? ""

// name -> dotted runtime module, from the interface's sections.
var owner: HashMap[str, str] = HashMap.new()
var section = ""
for line in wi.split("\n"):
    if line.starts_with("module "):
        let path: str = line.split(" ")[1]
        let stem: str = path.split("/")[2].replace(".w", "")
        section = if stem == "darwin_aarch64" or stem == "linux_x86_64" or stem == "linux_aarch64" or stem == "windows_x86_64" or stem == "windows_aarch64": "rt.platform" else if stem.starts_with("fiber_core_"): "rt.fiber_core" else: "rt." ++ stem
    else if line.starts_with("pub fn "):
        owner.insert(line.split("(")[0].slice(7, line.split("(")[0].len()), section)

fn sweep(path: &str, owner: &HashMap[str, str]) -> str:
    let text = read_file(path) ?? ""
    if not text.contains("extern fn with_"): return ""
    let lines = text.split("\n")
    var out: List[str] = List.new()
    var modules: List[str] = List.new()
    var removed = 0
    var missing = ""
    var last_use = -1
    var first_extern = -1
    for i in 0..lines.len():
        let line = lines[i]
        let is_extern = line.starts_with("extern fn with_") or line.starts_with("pub extern fn with_")
        if is_extern:
            let name: str = line.split("(")[0].split(" fn ")[1]
            if owner.contains(name):
                let m = owner.get(name) ?? &""
                if not modules.contains(m): modules.push(m ++ "")
            else:
                missing = missing ++ " " ++ name
                out.push(line ++ "")
                continue
            removed = removed + 1
            // The pin above it moved onto the definition (step 2).
            if out.len() > 0 and out[out.len() - 1].starts_with("@[effect("): let _ = out.pop()
            if first_extern < 0: first_extern = out.len() as i32
            continue
        if line.starts_with("use ") and modules.len() == 0 and removed == 0: last_use = out.len() as i32
        out.push(line ++ "")
    if removed == 0: return ""
    // Insert the imports after the last leading `use` line, else where the
    // first extern block stood (top level, after the header).
    let at = if last_use >= 0: last_use + 1 else: first_extern
    var result: List[str] = List.new()
    for i in 0..out.len():
        if i as i32 == at:
            for m in modules: result.push("use " ++ m)
        result.push(out[i] ++ "")
    if at >= out.len() as i32:
        for m in modules: result.push("use " ++ m)
    let _ = write_file(path, result.join("\n"))
    f"{path}: -{removed} externs, +use " ++ modules.join(" ") ++ (if missing.len() > 0: "  KEPT (not the runtime's):" ++ missing else: "")

var total = 0
for di in 2..argv.len():
    for path in list_files_text(argv[di]).split("\n"):
        if not path.ends_with(".w"): continue
        if path.contains("/re/") or path.contains("/zl/") or path.contains("/tommyds/") or path.contains("/c_algorithms/"): continue
        let report = sweep(path, &owner)
        if report.len() > 0:
            print(report)
            total = total + 1
print(f"{total} files rewritten")
