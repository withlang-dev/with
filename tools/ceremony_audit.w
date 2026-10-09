// with run tools/ceremony_audit.w [--with <compiler>] [--scratch <dir>] [--fix] <file.w | file.md>...
//
// Reports what a With source spells that the compiler already decides
// (#2140; docs/mission.md: "every character the program has already
// determined is a compiler failure if the programmer still writes it"):
//
//   return-type   `fn f(...) -> T:` where the body decides T
//   annotation    `let x: T = init` where the initializer decides T
//   accumulator   `var acc = 0` / `for x in xs: acc += e` / `acc`, which is
//                 `xs.iter() |> map(e) |> sum()`
//
// A return type or an annotation is a finding only when it is proven
// redundant: the audit removes it, compiles the file again, and compares the
// compiler's typed dump (`check --dump-typed`: every signature, binding and
// expression type) with the original's. Identical dumps mean the removed
// text decided nothing. A return type that states a meaning is never a
// candidate: a view (`-> &T`), a `Result` (its error type), `Never`.
//
// A `.md` file is audited through its fenced blocks (``` or ```with). A
// block that does not compile on its own is a fragment, or shows an error
// on purpose; it is counted and not audited.
//
// `--fix` rewrites each proven return-type and annotation finding of a `.w`
// file in place (one at a time, each proven against the text as it then
// stands); an accumulator loop is reported and left to its author.
//
// This is a report for the text we publish (README, examples, UAT
// fixtures), not a diagnostic: the language allows the long form.
// Exit code: 1 when there is a finding, 0 otherwise.

use std.fs
use std.process

type Source { label: str, first_line: i32, text: str }

type Candidate { line: i32, kind: str, replacement: str, detail: str }

fn dump_of(compiler: &str, path: &str, dir: &str) -> Option[str]:
    let out = f"{dir}/dump.out"
    let err = f"{dir}/dump.err"
    let argv: List[str] = [compiler.clone(), "check", path.clone(), "--dump-typed"]
    let done = run_to_files(&argv, out, err, 120000)
    if done.code != 0: return None
    Some(normalized(read_file(out).unwrap_or("")))

// `line` without the digits that follow each `key`.
fn without_ids(line: &str, key: &str) -> str:
    let parts = line.split(key)
    if parts.len() == 0: return ""
    var out = parts[0].clone()
    for i in 1..parts.len() as i32:
        var skip = 0
        while skip < parts[i].len() as i32 and parts[i][skip] >= '0' and parts[i][skip] <= '9': skip += 1
        out = out ++ key ++ parts[i].slice(skip, parts[i].len())
    out

// The dump without source offsets and node ids: removing text moves every
// later span and renumbers every later node.
fn normalized(dump: str) -> str:
    var kept: List[str] = List.new()
    for raw in dump.split("\n"):
        let line = without_ids(raw, "node=")
        // An inferred return type is printed on a line of its own; the
        // signature line above it carries the same type either way.
        if line.trim().starts_with("inferred_return:"): continue
        let at = line.find(" span=")
        if at < 0:
            kept.push(line.clone())
            continue
        let rest = line.slice(at + 6, line.len())
        let end = rest.find(" ")
        kept.push(line.slice(0, at) ++ (if end >= 0: rest.slice(end, rest.len()) else: ""))
    kept.join("\n")

fn indent_of(line: &str) -> i32:
    var n = 0
    while n < line.len() as i32 and line[n] == ' ': n += 1
    n

// `fn f(...) -> T: body` or `fn f(...) -> T:` with the return type removed,
// or "" when the line declares no such function or T states a meaning.
fn without_return_type(line: &str) -> str:
    let body = line.trim()
    let is_fn = body.starts_with("fn ") or body.starts_with("pub fn ") or body.starts_with("comptime fn ") or body.starts_with("mut fn ") or body.starts_with("move fn ") or body.starts_with("pub comptime fn ")
    if not is_fn: return ""
    let arrow = line.find(" -> ")
    if arrow < 0: return ""
    let after = line.slice(arrow + 4, line.len())
    let colon = after.find(":")
    if colon < 0: return ""
    let ty = after.slice(0, colon)
    if ty.starts_with("&") or ty.starts_with("Result[") or ty == "Never": return ""
    line.slice(0, arrow) ++ after.slice(colon, after.len())

// `let x: T = init` with the annotation removed, or "".
fn without_annotation(line: &str) -> str:
    let body = line.trim()
    if not (body.starts_with("let ") or body.starts_with("var ")): return ""
    let eq = line.find(" = ")
    let colon = line.find(": ")
    if eq < 0 or colon < 0 or colon > eq: return ""
    line.slice(0, colon) ++ line.slice(eq, line.len())

// `var acc = init` / `for x in xs: acc += e` / `acc` at lines i, i+1, i+2.
fn accumulator_at(lines: &List[str], i: i32) -> str:
    if i + 2 >= lines.len() as i32: return ""
    let head = lines[i].trim()
    if not head.starts_with("var "): return ""
    let eq = head.find(" = ")
    if eq < 0: return ""
    let acc = head.slice(4, eq)
    let step = lines[i + 1].trim()
    if not step.starts_with("for ") or lines[i + 2].trim() != acc: return ""
    let in_at = step.find(" in ")
    let colon = step.find(": ")
    if in_at < 0 or colon < in_at: return ""
    let body = step.slice(colon + 2, step.len())
    let add = f"{acc} += "
    if not body.starts_with(add): return ""
    let item = step.slice(4, in_at)
    let source = step.slice(in_at + 4, colon)
    let term = body.slice(add.len(), body.len())
    if term == item: return f"{source}.iter() |> sum()"
    f"{source}.iter() |> map({term.replace(item, "it")}) |> sum()"

fn candidates(lines: &List[str]) -> List[Candidate]:
    var out: List[Candidate] = List.new()
    for i in 0..lines.len() as i32:
        let shorter = without_return_type(lines[i])
        if shorter.len() > 0: out.push(Candidate { line: i, kind: "return-type", replacement: shorter, detail: "the body decides the return type" })
        let bare = without_annotation(lines[i])
        if bare.len() > 0: out.push(Candidate { line: i, kind: "annotation", replacement: bare, detail: "the initializer decides the type" })
    out

fn with_line(lines: &List[str], at: i32, replacement: &str) -> str:
    var out: List[str] = List.new()
    for i in 0..lines.len() as i32: out.push(if i == at: replacement.clone() else: lines[i].clone())
    out.join("\n")

// The fenced With blocks of a Markdown file, each with the line it starts on.
fn blocks_of(path: &str, text: &str) -> List[Source]:
    var out: List[Source] = List.new()
    var inside = false
    var audited = false
    var start = 0
    var body: List[str] = List.new()
    var number = 0
    for line in text.split("\n"):
        number += 1
        if line.starts_with("```"):
            if inside:
                if audited: out.push(Source { label: path.clone(), first_line: start, text: body.join("\n") ++ "\n" })
                inside = false
            else:
                inside = true
                let info = line.slice(3, line.len()).trim().to_owned()
                audited = info.len() == 0 or info == "with"
                start = number + 1
                body = List.new()
            continue
        if inside: body.push(line.clone())
    out

fn audit(compiler: &str, source: &Source, dir: &str, fix_path: &str) -> i32:
    let path = f"{dir}/audited.w"
    write_file(path, source.text)
    let Some(baseline) = dump_of(compiler, path, dir) else:
        return -1
    var lines: List[str] = List.new()
    for line in source.text.split("\n"): lines.push(line.clone())
    var findings = 0
    for candidate in candidates(&lines):
        write_file(path, with_line(&lines, candidate.line, candidate.replacement))
        let Some(after) = dump_of(compiler, path, dir) else:
            continue
        if after == baseline:
            findings += 1
            if fix_path.len() > 0: lines[candidate.line] = candidate.replacement.clone()
            print(f"{source.label}:{source.first_line + candidate.line}: {candidate.kind}: {candidate.detail}: {candidate.replacement.trim()}")
    for i in 0..lines.len() as i32:
        let pipeline = accumulator_at(&lines, i)
        if pipeline.len() > 0:
            findings += 1
            print(f"{source.label}:{source.first_line + i}: accumulator: a loop that only adds is a pipeline: {pipeline}")
    if fix_path.len() > 0 and findings > 0: write_file(fix_path, lines.join("\n"))
    findings

fn main:
    let argv = args()
    var compiler = "with"
    var files: List[str] = List.new()
    var fix = false
    var scratch = ""
    var i = 1
    while i < argv.len() as i32:
        if argv[i] == "--with" and i + 1 < argv.len() as i32:
            compiler = argv[i + 1].clone()
            i += 2
            continue
        if argv[i] == "--scratch" and i + 1 < argv.len() as i32:
            scratch = argv[i + 1].clone()
            i += 2
            continue
        if argv[i] == "--fix": fix = true
        else: files.push(argv[i].clone())
        i += 1
    if files.len() == 0:
        print("usage: with run tools/ceremony_audit.w [--with <compiler>] <file.w | file.md>...")
        return 2
    let dir = if scratch.len() > 0: scratch.clone() else: f"out/ceremony-audit-{pid()}"
    mkdir_p(dir)
    var findings = 0
    var audited = 0
    var fragments = 0
    for file in files:
        let text = read_file(file).unwrap_or("")
        var sources: List[Source] = List.new()
        if file.ends_with(".md"): sources = blocks_of(file, text)
        else: sources.push(Source { label: file.clone(), first_line: 1, text: text })
        for source in sources:
            let found = audit(compiler, source, dir, if fix and file.ends_with(".w"): file.clone() else: "")
            if found < 0:
                fragments += 1
                if not file.ends_with(".md"): print(f"{file}: does not compile on its own; not audited")
            else:
                audited += 1
                findings += found
    remove_tree(dir)
    print(f"ceremony-audit: {findings} finding(s) in {audited} program(s); {fragments} fragment(s) not audited")
    if findings > 0: return 1
