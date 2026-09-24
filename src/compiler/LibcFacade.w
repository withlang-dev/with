// LibcFacade — the toolchain libc facade (D51 ruling §5 "bounded knowledge",
// spec §16.2b.1 and §16.3c: "The toolchain's own knowledge is bounded to the
// C standard library (the curated libc facade), which is a standard
// deliverable").
//
// It is facade code, not compiler folklore: the text below is an ordinary
// `c facade` block, parsed, verified (§61, SemaFacade.w) and rendered
// (FacadeRender.w) exactly like one a program writes. The Frontend splices
// it after every `<c_import …>` translation as the synthetic file
// `<toolchain facade libc>` — the provenance every diagnostic about it names —
// into the module whose c_import declared the functions it describes.
//
// Only what the program imported is described: a `from` line needs its
// producer, a resource needs a kept `from` and its `drop`, and an fn item
// needs its function and the resource its `of` names — each of libc's shape
// (libc_facade_select). A libc function the
// program never declared is never mentioned, so a facade clause can never
// name an absent declaration. A program's own facade outranks this one: a
// resource, producer or fn item the program's facades already name is left
// to the program (§16.2b.2: an explicit facade clause is the program's).
//
// These are the rows the #357 owning-wrapper tables carried (strdup/strndup
// → free, fopen/fdopen/tmpfile → fclose, opendir → closedir, readdir and
// rewinddir borrowing the directory), now under the facade rules: each
// constructor yields `Option[R]` (NULL produced nothing, §16.2b.8), Drop runs
// the destroyer exactly once, and the raw C names stay raw (§16.2b.5).
//
// Stage 7 (ruling §33, §37, §38, §41; spec §16.2b.7-8) adds the borrowed
// strings the #379 overlay vouched for as raw nullable pointers: `getenv`
// borrows from the process environment — the domain `environ` — and
// `strerror` from its own buffer; `strchr`, `strrchr`, `strpbrk` and
// `strstr` return text borrowed from the string they are lent. Each is
// presented under its C name as `Option[CStr]`. The string functions and
// `getenv` state `preserves` on both domains: they read their arguments and
// nothing else, so a view from `getenv` survives a `strchr` over it —
// precision the facade grants (§35); every other libc operation keeps the
// conservative default and invalidates (§38).

use Ast
use InternPool
use compiler.FacadeRender

fn libc_facade_source() -> str:
    "c facade libc:
    resource CHeapStr wraps *mut i8
        from strdup
        from strndup
        drop free
    resource CFile wraps *mut FILE
        from fopen
        from fdopen
        from tmpfile
        drop fclose
    resource CDir wraps *mut DIR
        from opendir
        drop closedir
    fn readdir
        lend
        of CDir
    fn rewinddir
        lend
        of CDir
    domain environ process
    domain strerror_text process
    fn getenv
        returns borrow CStr from domain environ
        preserves domain environ
        preserves domain strerror_text
    fn strerror
        returns borrow CStr from domain strerror_text
        preserves domain environ
    fn strchr
        returns borrow CStr from param 0
        preserves domain environ
        preserves domain strerror_text
    fn strrchr
        returns borrow CStr from param 0
        preserves domain environ
        preserves domain strerror_text
    fn strpbrk
        returns borrow CStr from param 0
        preserves domain environ
        preserves domain strerror_text
    fn strstr
        returns borrow CStr from param 0
        preserves domain environ
        preserves domain strerror_text
"

fn libc_facade_has(names: &Vec[str], name: &str) -> bool:
    for i in 0..names.len() as i32:
        if names[i] == name:
            return true
    false

// The second word of a facade line (`from fopen` → `fopen`).
fn libc_facade_operand(line: &str) -> str:
    let words = line.trim().split(" ")
    if words.len() < 2: "" else: words[1].clone()

// The facade text restricted to what this compilation's c_import
// declarations support (`ci` flags them) and `claimed` (names the program's
// own facades state) leaves to the toolchain; "" when nothing applies. A
// declaration is described only when it has libc's shape: a producer returns
// the representation, the drop takes it (or `void *`, §61), a lend takes it
// first. A declaration of another shape — a program's own `fopen` over
// `void *` — is not described: it stays the raw surface, which removes
// capability and never asserts a contract the declarations do not carry.
pub fn libc_facade_select(pool: AstPool, intern: InternPool, ci: &Vec[i32], claimed: &Vec[str]) -> str:
    let lines = libc_facade_source().split("\n")
    var kept_names: Vec[str] = Vec.new()
    var kept_reprs: Vec[str] = Vec.new()
    // Domain lines are kept when a kept item names the domain (a
    // `from domain D` or `preserves domain D` clause) and the program's own
    // facades do not declare it.
    var domain_lines: Vec[str] = Vec.new()
    var domain_names: Vec[str] = Vec.new()
    var body = ""
    var i = 1
    while i < lines.len() as i32:
        let header = lines[i].clone()
        i = i + 1
        if header.trim().len() == 0:
            continue
        var clauses: Vec[str] = Vec.new()
        while i < lines.len() as i32 and lines[i].starts_with("        "):
            clauses.push(lines[i].clone())
            i = i + 1
        let name = libc_facade_operand(header)
        if libc_facade_has(claimed, name):
            continue
        if header.trim().starts_with("domain "):
            domain_lines.push(header.clone())
            domain_names.push(name.clone())
            continue
        if header.trim().starts_with("resource "):
            let words = header.trim().split(" wraps ")
            if words.len() != 2:
                continue
            let repr = facade_render_unalias(pool, intern, words[1].trim())
            var kept = ""
            var producers = 0
            var has_drop = false
            for ci_ in 0..clauses.len() as i32:
                let clause = clauses[ci_].clone()
                let op = libc_facade_operand(clause)
                let (found, ret, p0) = facade_render_import_shape(pool, intern, ci, op)
                if clause.trim().starts_with("from "):
                    if found and ret == repr and not libc_facade_has(claimed, op):
                        kept = kept ++ clause ++ "\n"
                        producers = producers + 1
                else:
                    if clause.trim().starts_with("drop ") and found and (p0 == repr or ((p0 == "*mut c_void" or p0 == "*const c_void") and repr.starts_with("*"))):
                        has_drop = true
                    kept = kept ++ clause ++ "\n"
            if producers > 0 and has_drop:
                body = body ++ header ++ "\n" ++ kept
                kept_names.push(name)
                kept_reprs.push(repr)
        else:
            let (found, _, p0) = facade_render_import_shape(pool, intern, ci, name)
            if not found:
                continue
            var ok = true
            for ci_ in 0..clauses.len() as i32:
                if clauses[ci_].trim().starts_with("of "):
                    let target = libc_facade_operand(clauses[ci_])
                    var matched = false
                    for ki in 0..kept_names.len() as i32:
                        if kept_names[ki] == target and kept_reprs[ki] == p0:
                            matched = true
                    if not matched:
                        ok = false
            if ok:
                body = body ++ header ++ "\n"
                for ci_ in 0..clauses.len() as i32:
                    body = body ++ clauses[ci_] ++ "\n"
    if body.len() == 0:
        return ""
    var domains = ""
    for di in 0..domain_lines.len() as i32:
        if body.contains(" domain " ++ domain_names[di] ++ "\n"):
            domains = domains ++ domain_lines[di] ++ "\n"
    lines[0] ++ "\n" ++ domains ++ body
