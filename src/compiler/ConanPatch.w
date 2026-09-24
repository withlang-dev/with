// Applying a recipe's patches (unified diff) to an extracted source tree, so a
// source build needs no `patch` program. Strict: a hunk applies where its
// context and removed lines match exactly — at the stated line, or the nearest
// place they do — and anything else is an error naming the file and hunk.

fn cp_lines(text: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for raw in text.split("\n"): out.push(if raw.ends_with("\r"): raw.slice(0, raw.len() - 1).to_owned() else: raw.to_owned())
    out

// `--- a/src/x.c<TAB>date` -> `src/x.c`: the first path component goes (-p1).
fn cp_header_path(line: &str) -> str:
    var path = line.slice(4, line.len()).trim().to_owned()
    let tab = path.find("\t")
    if tab >= 0: path = path.slice(0, tab).to_owned()
    if path == "/dev/null": return path
    let slash = path.find("/")
    if slash >= 0: path.slice(slash + 1, path.len()).to_owned() else: path

// `@@ -12,7 +12,9 @@` -> 12 (1-based line in the old file; 0 for an empty one).
fn cp_hunk_old_start(line: &str) -> i32:
    let dash = line.find("-")
    if dash < 0: return -1
    var n = 0
    var i = dash as i32 + 1
    var digits = 0
    while i < line.len() as i32 and line[i] >= '0' and line[i] <= '9':
        n = n * 10 + (line[i] as i32 - '0' as i32)
        digits = digits + 1
        i = i + 1
    if digits == 0: -1 else: n

fn cp_matches_at(file: &Vec[str], at: i32, old: &Vec[str]) -> bool:
    if at < 0 or at + old.len() as i32 > file.len() as i32: return false
    for i in 0..old.len() as i32:
        if file[at + i] != old[i]: return false
    true

// Where `old` sits in `file`, preferring `want` and then the nearest line; -1 if nowhere.
fn cp_locate(file: &Vec[str], want: i32, old: &Vec[str]) -> i32:
    if cp_matches_at(file, want, old): return want
    for distance in 1..file.len() as i32 + 1:
        if cp_matches_at(file, want - distance, old): return want - distance
        if cp_matches_at(file, want + distance, old): return want + distance
    -1

type CpHunk { old_start: i32, old: Vec[str], new: Vec[str] }

// The patched text of one file, or the problem. Pure: the caller reads and
// writes through its `read`/`write` callables itself — a callable is not
// Copy (D63), and calling through the binding observes it while passing it
// into this helper on every file of the loop would move it.
fn cp_patched_text(path: &str, creates: bool, original: &str, hunks: &Vec[CpHunk]) -> (str, str):
    if not creates and original.len() == 0: return ("", "patch targets " ++ path ++ ", which is not in the source")
    let ends_with_newline = creates or original.ends_with("\n")
    var file = cp_lines(original)
    // A trailing newline leaves one empty piece after the last line.
    if file.len() > 0 and file[file.len() - 1].len() == 0:
        let _last = file.pop()
    var shift = 0
    for hi in 0..hunks.len() as i32:
        let want: i32 = hunks[hi].old_start - 1 + shift
        let at = if hunks[hi].old.len() == 0: (if want < 0: 0 else: want) else: cp_locate(&file, want, &hunks[hi].old)
        if at < 0: return ("", f"hunk {hi + 1} of the patch does not apply to " ++ path)
        let rebuilt: Vec[str] = Vec.new()
        for i in 0..at: rebuilt.push(file[i].clone())
        for line in hunks[hi].new: rebuilt.push(line.to_owned())
        for i in at + hunks[hi].old.len() as i32..file.len() as i32: rebuilt.push(file[i].clone())
        shift = shift + (at - want) + hunks[hi].new.len() as i32 - hunks[hi].old.len() as i32
        file = rebuilt
    var text = file.join("\n")
    if ends_with_newline and file.len() > 0: text = text ++ "\n"
    (text, "")

// Applies every file's hunks. Returns "" or what went wrong.
pub fn conan_apply_patch(patch: &str, root: &str, read: fn(&str) -> str, write: fn(&str, &str) -> i32) -> str:
    let lines = cp_lines(patch)
    var path = ""
    var creates = false
    var hunks: Vec[CpHunk] = Vec.new()
    var in_hunk = false
    var i = 0
    while i <= lines.len() as i32:
        let at_end = i == lines.len() as i32
        let line = if at_end: "" else: lines[i].clone()
        let file_header = not at_end and line.starts_with("--- ") and i + 1 < lines.len() as i32 and lines[i + 1].starts_with("+++ ")
        if at_end or file_header:
            if path.len() > 0 and hunks.len() > 0:
                let full = root ++ "/" ++ path
                let original = if creates: "" else: read(&full)
                let (text, problem) = cp_patched_text(path, creates, &original, &hunks)
                if problem.len() > 0: return problem
                if write(&full, &text) != 0: return "could not write " ++ path
            if at_end: break
            creates = cp_header_path(line) == "/dev/null"
            path = cp_header_path(lines[i + 1])
            if path == "/dev/null": return "patch deletes " ++ cp_header_path(line) ++ "; deleting a file is not supported"
            hunks = Vec.new()
            in_hunk = false
            i = i + 2
            continue
        if line.starts_with("@@ "):
            let start = cp_hunk_old_start(line)
            if start < 0: return "malformed hunk header: " ++ line
            hunks.push(CpHunk { old_start: start, old: Vec.new(), new: Vec.new() })
            in_hunk = true
        else if in_hunk and hunks.len() > 0 and not line.starts_with("\\"):
            let last = hunks.len() as i32 - 1
            if line.starts_with("+"): hunks[last].new.push(line.slice(1, line.len()).to_owned())
            else if line.starts_with("-"): hunks[last].old.push(line.slice(1, line.len()).to_owned())
            // The patch text's own final newline leaves one empty piece: not a context line.
            else if line.len() == 0 and i == lines.len() as i32 - 1: in_hunk = false
            else if line.starts_with(" ") or line.len() == 0:
                let body = if line.len() == 0: "" else: line.slice(1, line.len())
                hunks[last].old.push(body.to_owned())
                hunks[last].new.push(body.to_owned())
            else: in_hunk = false
        i = i + 1
    ""
