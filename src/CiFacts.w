// CiFacts — D121 step 4 (§16.2b.15 item 3): the package registry's facts
// file, read for the facade proof engine (CiFacadeDraft.w).
//
// A facts file is a facade fragment in the facade language's own spelling,
// the spelling the draft emits, so a reviewer reads one grammar:
//
//   c facade zlib:
//       resource GzFileS wraps *mut gzFile_s
//           drop gzclose    // zlib.h 1.3.2: "gzclose … deallocates"
//       fn gzopen
//           consumes param 1    // …
//
// Every fact carries its citation after `//`: the source line or document
// that proves it. A fact without one is refused, which is the review rule
// the tool can enforce; the rest of the rule is the pull request. The
// facts are the tier below a proof and the library's own annotations
// (§16.2b.2): the engine applies one only where those said nothing.
//
// Clauses read: on a resource, `from F`, `drop F`, `destroys F`; on a
// function, `consumes param N`, `returns borrow R from param N`, `lend`,
// `nullable param N`, `text param N` and `text return, owned, freed by F`
// (D121 step 6: what a facade states about a parameter or a return that
// neither a proof nor an annotation reaches).
// Anything else in the file is an error naming the line: a registry file
// states facts, and an unreadable line is not silently a non-fact.

use std.fs
use std.string

type FactsEntry {
    pub fn_name: str,
    // Ownership: `owned`, `drop`, `destroys`, `consumes:N`, `borrow:N`,
    // `lend`. Presentation: `nullable:N`, `text_param:N`, `text_return:F`.
    pub kind: str,
    // The C record of the resource a resource fact is stated on, "" for
    // an item fact.
    pub record: str,
    pub cite: str,
}

type Facts {
    pub package: str,
    pub entries: List[FactsEntry],
    // The citation of a facade-level `text utf8` (D134 §16.2b.8: every
    // text return presents as `Option[str]`, validated at the boundary),
    // "" when the file states none.
    pub utf8_cite: str,
}

/// Whether `kind` is a presentation fact (a parameter's or a return's
/// shape) rather than an ownership fact.
fn facts_is_presentation(kind: &str) -> bool:
    kind.starts_with("nullable:") or kind.starts_with("text_param:") or kind.starts_with("text_return:")

impl Facts:
    /// The ownership fact for the C function `name` as `kind|record|cite`,
    /// or "".
    fn of(name: &str) -> str:
        for e in self.entries:
            if e.fn_name == name and not facts_is_presentation(e.kind): return e.kind ++ "|" ++ e.record ++ "|" ++ e.cite
        ""

    /// The presentation facts for `name`, one `kind|record|cite` per line,
    /// in the file's order; "" when it states none.
    fn presentation(name: &str) -> str:
        var out = ""
        for e in self.entries:
            if e.fn_name == name and facts_is_presentation(e.kind): out = out ++ e.kind ++ "|" ++ e.record ++ "|" ++ e.cite ++ "\n"
        out

/// The `kind` of a fact string `of` gave.
fn facts_kind(fact: &str) -> str:
    let bar = fact.find("|")
    if bar < 0: "" else: fact.slice(0, bar)

/// The record of a fact string `of` gave.
fn facts_record(fact: &str) -> str:
    let parts = fact.split("|")
    if parts.len() < 3: "" else: parts[1]

/// The citation of a fact string `of` gave.
fn facts_cite(fact: &str) -> str:
    let parts = fact.split("|")
    if parts.len() < 3: "" else: parts[2]

fn facts_error(path: &str, line: isize, message: &str) -> str: path ++ f":{line}: " ++ message

// `text` split at its `//`: the clause and the citation, trimmed.
fn facts_split_cite(text: &str) -> List[str]:
    let at = text.find("//")
    var out: List[str] = List.new()
    if at < 0:
        out.push(text.trim())
        out.push("")
    else:
        out.push(text.slice(0, at).trim())
        out.push(text.slice(at + 2, text.len()).trim())
    out

/// Reads the facts file at `path`.
fn facts_read_file(path: &str) -> Result[Facts, str]:
    let source = match read_file(path):
        Ok(s) => s
        Err(_) => return Err("cannot read " ++ path)
    facts_read(path, source)

fn facts_read(path: &str, source: str) -> Result[Facts, str]:
    var facts = Facts { package: "", entries: List.new(), utf8_cite: "" }
    var current_fn = ""
    var in_resource = false
    var record = ""
    var line_no: isize = 0
    for raw in source.split("\n"):
        line_no += 1
        let stripped = raw.trim()
        if stripped.len() == 0 or stripped.starts_with("//"): continue
        if stripped.starts_with("c facade ") and stripped.ends_with(":"):
            if facts.package.len() > 0: return Err(facts_error(path, line_no, "a second `c facade` header"))
            facts.package = stripped.slice(9, stripped.len() - 1).trim()
            continue
        if facts.package.len() == 0: return Err(facts_error(path, line_no, "`c facade NAME:` must come first"))
        if stripped.starts_with("resource "):
            if not stripped.contains(" wraps *mut "): return Err(facts_error(path, line_no, "a resource is `resource R wraps *mut record`"))
            in_resource = true
            current_fn = ""
            let at = stripped.find(" wraps *mut ")
            record = stripped.slice(at + 12, stripped.len()).trim()
            if record.len() == 0 or record.contains(" ") or record.contains("|"): return Err(facts_error(path, line_no, "a resource wraps one C record"))
            continue
        if stripped.starts_with("fn "):
            current_fn = stripped.slice(3, stripped.len()).trim()
            in_resource = false
            if current_fn.len() == 0 or current_fn.contains(" "): return Err(facts_error(path, line_no, "an item is `fn NAME`"))
            continue
        let parts = facts_split_cite(stripped)
        let clause = parts[0]
        let cite = parts[1]
        if cite.len() == 0: return Err(facts_error(path, line_no, "a fact needs its citation after `//`: the source line or document that proves it"))
        if cite.contains("|"): return Err(facts_error(path, line_no, "a citation cannot hold `|`"))
        if clause == "text utf8" and not in_resource and current_fn.len() == 0:
            if facts.utf8_cite.len() > 0: return Err(facts_error(path, line_no, "`text utf8` is stated twice"))
            facts.utf8_cite = cite
            continue
        if in_resource:
            let words = clause.fields()
            if words.len() != 2 or not (words[0] == "from" or words[0] == "drop" or words[0] == "destroys"): return Err(facts_error(path, line_no, "a resource fact is `from F`, `drop F` or `destroys F`"))
            facts.entries.push(FactsEntry { fn_name: words[1], kind: if words[0] == "from": "owned" else: words[0], record: record, cite: cite })
            continue
        if current_fn.len() == 0: return Err(facts_error(path, line_no, "a fact belongs to a `resource` or an `fn` item"))
        if clause == "lend":
            facts.entries.push(FactsEntry { fn_name: current_fn, kind: "lend", record: "", cite: cite })
        else if clause.starts_with("consumes param "):
            let n: str = clause.slice(15, clause.len()).trim()
            if n.len() == 0 or not is_digit(n[0]): return Err(facts_error(path, line_no, "`consumes param N` takes a parameter index"))
            facts.entries.push(FactsEntry { fn_name: current_fn, kind: "consumes:" ++ n, record: "", cite: cite })
        else if clause.starts_with("returns borrow ") and clause.contains(" from param "):
            let at = clause.find(" from param ")
            let n: str = clause.slice(at + 12, clause.len()).trim()
            if n.len() == 0 or not is_digit(n[0]): return Err(facts_error(path, line_no, "`returns borrow R from param N` takes a parameter index"))
            facts.entries.push(FactsEntry { fn_name: current_fn, kind: "borrow:" ++ n, record: "", cite: cite })
        else if clause.starts_with("nullable param "):
            let n: str = clause.slice(15, clause.len()).trim()
            if n.len() == 0 or not is_digit(n[0]): return Err(facts_error(path, line_no, "`nullable param N` takes a parameter index"))
            facts.entries.push(FactsEntry { fn_name: current_fn, kind: "nullable:" ++ n, record: "", cite: cite })
        else if clause.starts_with("text param "):
            let n: str = clause.slice(11, clause.len()).trim()
            if n.len() == 0 or not is_digit(n[0]): return Err(facts_error(path, line_no, "`text param N` takes a parameter index"))
            facts.entries.push(FactsEntry { fn_name: current_fn, kind: "text_param:" ++ n, record: "", cite: cite })
        else if clause.starts_with("text return"):
            let words = clause.replace(",", " ").fields()
            if words.len() != 6 or words[2] != "owned" or words[3] != "freed" or words[4] != "by": return Err(facts_error(path, line_no, "a text return is `text return, owned, freed by F`"))
            facts.entries.push(FactsEntry { fn_name: current_fn, kind: "text_return:" ++ words[5], record: "", cite: cite })
        else: return Err(facts_error(path, line_no, "an item fact is `consumes param N`, `returns borrow R from param N`, `lend`, `nullable param N`, `text param N` or `text return, owned, freed by F`"))
    if facts.package.len() == 0: return Err(path ++ ": no `c facade NAME:` header")
    Ok(facts)
