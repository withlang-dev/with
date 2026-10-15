// CiFacadeDraft — D121 step 2 (§16.2b.15): the ownership facts a package's
// own C source proves, and the facade draft and report drawn from them.
//
// The evidence is what the migrator already reads from every body
// (CImport.w ci_body_ownership_evidence, beside D107's nullability
// walkers); the proofs are a least fixed point over the corpus, in the
// order the facts depend on each other:
//   1. retention: a parameter is retained when the body stores it into a
//      field or a global, or hands it to a callee that retains it; a callee
//      outside the corpus retains what it is given unless it is a C library
//      function known to read and keep nothing (the asymmetry rule);
//   2. destruction: a parameter is destroyed when the body passes it to
//      `free` (or a global the corpus initializes to `free`), or to a corpus
//      destroyer at its destroyed position;
//   3. returns: a function produces an owned pointer when every pointer it
//      returns is a fresh allocation (an allocator, or a corpus producer) it
//      never retained; it returns a borrow of parameter i when every pointer
//      it returns is a part of that parameter's memory (the parameter, a
//      field, an element, an offset), directly or through a corpus function
//      proven to borrow from the argument.
// Anything else is unproven and stays raw, with its reason. No name enters
// any verdict: `xmlNewNode` and `xmlDocGetRootElement` both return
// `xmlNodePtr`, and only their bodies tell them apart.
//
// The draft pairs producers and destroyers by representation: one resource
// per pointer-to-record type that has at least one owned producer and
// exactly one unary destroyer (the `drop`); a representation with producers
// and no destroyer, or several candidates, is reported for the registry
// (§16.2b.15 step 4), never guessed.

use CiIR
use CImport
use std.string.parse

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_getenv_str(name: &str) -> str

// `R` for `*mut R` / `*const R` when R is a record; "" for anything else
// (a pointer to a pointer, to a scalar, to `c_void`, a function pointer).
pub fn fd_record_pointee(ty: &str) -> str:
    let t = ty.trim()
    var rest = ""
    if t.starts_with("*mut "): rest = t.slice(5, t.len()).trim().to_owned()
    else if t.starts_with("*const "): rest = t.slice(7, t.len()).trim().to_owned()
    else: return ""
    if rest.len() == 0 or rest[0] == '*' or rest[0] == '[' or rest[0] == '(' or rest.starts_with("fn") or rest.starts_with("extern") or rest.starts_with("Option"): return ""
    if rest.starts_with("c_") or rest == "u8" or rest == "i8" or rest == "u16" or rest == "i16" or rest == "u32" or rest == "i32" or rest == "u64" or rest == "i64" or rest == "f32" or rest == "f64" or rest == "bool" or rest == "isize" or rest == "usize" or rest == "Unit": return ""
    rest

// The With name of the resource over `R`: `xmlDoc` → `XmlDoc`, `z_stream_s`
// → `ZStreamS`, `sqlite3` → `Sqlite3`; one that would equal the C name
// takes `Handle` so the two never collide. Presentation only (§16.2b.2):
// the project renames it as it likes.
pub fn fd_resource_name(record: &str) -> str:
    var camel = ""
    var upper_next = true
    for i in 0..record.len():
        if record[i] == '_':
            upper_next = true
            continue
        let one = record.slice(i, i + 1)
        camel = camel ++ (if upper_next: one.to_upper() else: one.to_owned())
        upper_next = false
    if camel == record: camel ++ "Handle" else: camel

// `<pos>=p<i>` / `<pos>=l<name>` entries of a `call:` record's argmap:
// the argument at `pos`, or "".
fn fd_argmap_at(argmap: &str, pos: i32) -> str:
    for entry in argmap.split(","):
        let eq = entry.find("=")
        if eq <= 0: continue
        let p: i32 = parse(entry.slice(0, eq))
        if p == pos: return entry.slice(eq + 1, entry.len()).to_owned()
    ""

fn fd_i32(text: &str) -> i32:
    let v: i32 = parse(text)
    v

impl CiProject:
    fn fd_is_alloc_call(name: &str) -> bool: ci_own_is_libc_allocator(name) or self.alloc_aliases.contains(name)
    fn fd_is_free_call(name: &str) -> bool: ci_own_is_libc_free(name) or self.free_aliases.contains(name)

    // Whether what is passed to `callee` at `index` is retained there.
    fn fd_callee_retains(callee: &str, index: i32) -> bool:
        if self.fd_is_free_call(callee) or self.fd_is_alloc_call(callee) or ci_own_is_libc_observer(callee): return false
        let si = self.find_symbol(CiProjectSymbolKind.CIPS_FN, callee)
        if si < 0 or self.symbols[si].has_definition == 0: return true
        index < self.symbols[si].param_stores.len() and self.symbols[si].param_stores[index] != 0

    fn fd_callee_destroys(callee: &str, index: i32) -> bool:
        if self.fd_is_free_call(callee): return true
        let si = self.find_symbol(CiProjectSymbolKind.CIPS_FN, callee)
        if si < 0 or self.symbols[si].has_definition == 0: return false
        index < self.symbols[si].param_destroys.len() and self.symbols[si].param_destroys[index] != 0

    // The verdict for a local of `si`: "owned", "borrow:<i>", "null" (never
    // assigned a pointer), or "unknown:<reason>".
    fn fd_local_verdict(si: i32, local: &str, depth: i32) -> str:
        if depth > 8: return "unknown:a chain of locals too deep to follow"
        var verdict = "null"
        var assigned = false
        for line in self.symbols[si].own_evidence.split("\n"):
            let parts = line.split(":")
            if parts.len() < 2 or parts[1] != local: continue
            if parts[0] == "localstore": return "unknown:local " ++ local ++ " is stored or its address taken"
            if parts[0] == "localsink" and parts.len() == 4:
                if self.fd_callee_retains(parts[2], fd_i32(parts[3])): return "unknown:local " ++ local ++ " is passed to " ++ parts[2] ++ ", which retains it"
            if parts[0] == "localsrc" and parts.len() >= 3:
                assigned = true
                let src = line.slice(("localsrc:" ++ local ++ ":").len(), line.len())
                let v = self.fd_source_verdict(si, src, depth + 1)
                if v == "null": continue
                if verdict == "null": verdict = v
                else if verdict != v: return "unknown:local " ++ local ++ " has more than one source"
        if not assigned: return "unknown:local " ++ local ++ " is never assigned"
        verdict

    // The verdict for one <src> record (CImport.w ci_body_ownership_evidence).
    fn fd_source_verdict(si: i32, src: &str, depth: i32) -> str:
        if src == "null": return "null"
        if src.starts_with("param:"): return "borrow:" ++ src.slice(6, src.len())
        if src.starts_with("field:param:"): return "borrow:" ++ src.slice(12, src.len())
        if src.starts_with("field:local:"):
            let v = self.fd_local_verdict(si, src.slice(12, src.len()), depth)
            return if v.starts_with("borrow:"): v else if v.starts_with("unknown:"): v else: "unknown:a part of local " ++ src.slice(12, src.len()) ++ ", which is not a borrow"
        if src.starts_with("local:"): return self.fd_local_verdict(si, src.slice(6, src.len()), depth)
        if src.starts_with("call:"):
            let rest = src.slice(5, src.len())
            let colon = rest.find(":")
            let callee = if colon >= 0: rest.slice(0, colon).to_owned() else: rest.to_owned()
            let argmap = if colon >= 0: rest.slice(colon + 1, rest.len()).to_owned() else: ""
            if self.fd_is_alloc_call(callee): return "owned"
            let ci = self.find_symbol(CiProjectSymbolKind.CIPS_FN, callee)
            if ci < 0 or self.symbols[ci].has_definition == 0: return "unknown:" ++ callee ++ " is not defined in the package"
            if self.symbols[ci].owns_return != 0: return "owned"
            if self.symbols[ci].borrow_from >= 0:
                let arg = fd_argmap_at(argmap, self.symbols[ci].borrow_from)
                if arg.starts_with("p"): return "borrow:" ++ arg.slice(1, arg.len())
                if arg.starts_with("l"):
                    let v = self.fd_local_verdict(si, arg.slice(1, arg.len()), depth)
                    return if v.starts_with("borrow:"): v else: "unknown:" ++ callee ++ " borrows from an argument that is not a parameter"
                return "unknown:" ++ callee ++ " borrows from an argument that is not a parameter"
            return "unknown:" ++ callee ++ " is unproven (" ++ self.symbols[ci].own_reason ++ ")"
        if src == "global": return "unknown:returns global state"
        "unknown:no single source"

    // Whether any declaration of `si` carries the attribute `name`
    // (`malloc`, `returns_nonnull`, or `nonnull` with its list).
    fn fd_has_attr(si: i32, name: &str) -> bool:
        for a in self.symbols[si].attrs.split(";"):
            if a == name or a.starts_with(name ++ "("): return true
        false

    fn fd_retains_any(si: i32) -> bool:
        for pi in 0..self.symbols[si].param_stores.len():
            if self.symbols[si].param_stores[pi] != 0: return true
        false

    fn fd_destroys_any(si: i32) -> bool:
        for pi in 0..self.symbols[si].param_destroys.len():
            if self.symbols[si].param_destroys[pi] != 0: return true
        false

    // How a function with no record-pointer return is presented: a
    // destroyer, a value-only call, a lend (every pointer parameter is a
    // modeled resource it reads and keeps), or `raw:` with the reason.
    fn fd_lend_verdict(si: i32, modeled: &List[str]) -> str:
        if self.symbols[si].ret_ty.starts_with("*"): return "raw: returns " ++ self.symbols[si].ret_ty ++ ", a pointer to no record"
        var pointer_params = 0
        var destroyed = -1
        var retained = -1
        var unmodeled = ""
        for pi in 0..self.symbols[si].param_ty.len():
            let p = self.symbols[si].param_ty[pi]
            if not p.starts_with("*"): continue
            pointer_params = pointer_params + 1
            if self.symbols[si].param_destroys[pi] != 0: destroyed = pi as i32
            else if self.symbols[si].param_stores[pi] != 0: retained = pi as i32
            else if not modeled.contains(fd_record_pointee(p)) and unmodeled.len() == 0: unmodeled = p
        if destroyed >= 0: return f"destroyer, param {destroyed} (proof: frees it)"
        if retained >= 0: return f"raw: retains param {retained}; its lifetime contract is not proven"
        if unmodeled.len() > 0: return "raw: parameter of unmodeled pointer type " ++ unmodeled
        if pointer_params == 0: return "value-only call"
        "lend (reads its resource parameters, keeps nothing)"

    fn fd_is_lend(si: i32, modeled: &List[str]) -> bool:
        self.symbols[si].header_declared != 0 and self.symbols[si].owns_return == 0 and self.symbols[si].borrow_from < 0 and fd_record_pointee(self.symbols[si].ret_ty).len() == 0 and self.fd_lend_verdict(si, modeled).starts_with("lend")

    fn fd_src_text(src: &str) -> str:
        if src.starts_with("call:"):
            let rest = src.slice(5, src.len())
            let colon = rest.find(":")
            return (if colon >= 0: rest.slice(0, colon).to_owned() else: rest.to_owned()) ++ "(…)"
        if src.starts_with("field:param:"): return "a part of param " ++ src.slice(12, src.len())
        if src.starts_with("param:"): return "param " ++ src.slice(6, src.len())
        if src.starts_with("local:"): return src.slice(6, src.len()).to_owned()
        if src.starts_with("field:local:"): return "a part of " ++ src.slice(12, src.len())
        src.to_owned()

    // The pointer parameter a local stands for: every assignment to the
    // local is that parameter (`gz_statep state = (gz_statep)file`), else -1.
    fn fd_local_alias_param(si: i32, local: &str) -> i32:
        var alias = -1
        for line in self.symbols[si].own_evidence.split("\n"):
            if not line.starts_with("localsrc:" ++ local ++ ":"): continue
            let src = line.slice(("localsrc:" ++ local ++ ":").len(), line.len())
            if not src.starts_with("param:"): return -1
            let pi = fd_i32(src.slice(6, src.len()))
            if alias >= 0 and alias != pi: return -1
            alias = pi
        if alias >= 0 and (alias >= self.symbols[si].param_ty.len() or not self.symbols[si].param_ty[alias].starts_with("*")): return -1
        alias

    fn fd_param_is_pointer(si: i32, pi: i32) -> bool:
        pi >= 0 and pi < self.symbols[si].param_ty.len() and self.symbols[si].param_ty[pi].starts_with("*")

    // D121: the corpus-wide ownership proofs, drawn once after every unit
    // is scanned. Each phase is a monotone fixed point; the order of units
    // never enters. Retention and destruction are facts about pointer
    // parameters, reached directly or through a local that stands for one.
    mut fn resolve_ownership():
        let n = self.symbols.len()
        // 1. Retention.
        for si in 0..n:
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            let count = self.symbols[si].param_sinks.len()
            for pi in 0..count:
                if not self.fd_param_is_pointer(si as i32, pi as i32): continue
                if self.symbols[si].param_sinks[pi].contains("field;") or self.symbols[si].param_sinks[pi].contains("global;"): self.symbols[si].param_stores[pi] = 1
            for line in self.symbols[si].own_evidence.split("\n"):
                if line.starts_with("paramstore:"):
                    let pi = fd_i32(line.slice(11, line.len()))
                    if self.fd_param_is_pointer(si as i32, pi): self.symbols[si].param_stores[pi] = 1
                if line.starts_with("localstore:"):
                    let pi = self.fd_local_alias_param(si as i32, line.slice(11, line.len()))
                    if pi >= 0: self.symbols[si].param_stores[pi] = 1
        var changed = true
        while changed:
            changed = false
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
                let count = self.symbols[si].param_sinks.len()
                for pi in 0..count:
                    if self.symbols[si].param_stores[pi] != 0 or not self.fd_param_is_pointer(si as i32, pi as i32): continue
                    for sink in self.symbols[si].param_sinks[pi].split(";"):
                        if not sink.contains(":"): continue
                        let kv = sink.split(":")
                        if self.fd_callee_retains(kv[0], fd_i32(kv[1])):
                            self.symbols[si].param_stores[pi] = 1
                            changed = true
                            break
                for line in self.symbols[si].own_evidence.split("\n"):
                    if not line.starts_with("localsink:"): continue
                    let parts = line.split(":")
                    if parts.len() != 4: continue
                    let pi = self.fd_local_alias_param(si as i32, parts[1])
                    if pi < 0 or self.symbols[si].param_stores[pi] != 0: continue
                    if self.fd_callee_retains(parts[2], fd_i32(parts[3])):
                        self.symbols[si].param_stores[pi] = 1
                        changed = true
        // 2. Destruction.
        changed = true
        while changed:
            changed = false
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
                let count = self.symbols[si].param_sinks.len()
                for pi in 0..count:
                    if self.symbols[si].param_destroys[pi] != 0 or not self.fd_param_is_pointer(si as i32, pi as i32): continue
                    for sink in self.symbols[si].param_sinks[pi].split(";"):
                        if not sink.contains(":"): continue
                        let kv = sink.split(":")
                        if self.fd_callee_destroys(kv[0], fd_i32(kv[1])):
                            self.symbols[si].param_destroys[pi] = 1
                            changed = true
                            break
                for line in self.symbols[si].own_evidence.split("\n"):
                    if not line.starts_with("localsink:"): continue
                    let parts = line.split(":")
                    if parts.len() != 4: continue
                    let pi = self.fd_local_alias_param(si as i32, parts[1])
                    if pi < 0 or self.symbols[si].param_destroys[pi] != 0: continue
                    if self.fd_callee_destroys(parts[2], fd_i32(parts[3])):
                        self.symbols[si].param_destroys[pi] = 1
                        changed = true
        // 3. Returns.
        changed = true
        while changed:
            changed = false
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
                if self.symbols[si].owns_return != 0 or self.symbols[si].borrow_from >= 0: continue
                if fd_record_pointee(self.symbols[si].ret_ty).len() == 0:
                    self.symbols[si].own_reason = "returns no pointer to a record"
                    continue
                var verdict = "null"
                var reason = ""
                var returns = 0
                for line in self.symbols[si].own_evidence.split("\n"):
                    if not line.starts_with("ret:"): continue
                    returns = returns + 1
                    let src = line.slice(4, line.len())
                    let v = self.fd_source_verdict(si as i32, src, 0)
                    if v == "null": continue
                    if v.starts_with("unknown:"):
                        verdict = v
                        break
                    if verdict == "null":
                        verdict = v
                        reason = "returns " ++ self.fd_src_text(src)
                    else if verdict != v:
                        verdict = "unknown:returns " ++ self.fd_src_text(src) ++ " and " ++ reason.slice(8, reason.len())
                        break
                if returns == 0: verdict = "unknown:no return statement in the body"
                if verdict == "null": verdict = "unknown:returns only NULL"
                // D121 step 3 (§16.2b.15): what the body does not prove, an
                // annotation the library ships may state — `malloc` says the
                // return is a fresh allocation the caller owns. Below a proof,
                // above the registry; a proof that contradicts it (a part of
                // a parameter is returned) wins.
                if verdict.starts_with("unknown:") and self.fd_has_attr(si as i32, "malloc"):
                    verdict = "owned"
                    reason = "annotation: __attribute__((malloc)), the return is a fresh allocation the caller owns"
                if verdict == "owned":
                    self.symbols[si].owns_return = 1
                    self.symbols[si].own_reason = if reason.starts_with("annotation:"): reason else: "proof: " ++ reason ++ ", a fresh allocation never retained"
                    changed = true
                else if verdict.starts_with("borrow:"):
                    self.symbols[si].borrow_from = fd_i32(verdict.slice(7, verdict.len()))
                    self.symbols[si].own_reason = "proof: " ++ reason
                    changed = true
                else: self.symbols[si].own_reason = verdict.slice(8, verdict.len()).to_owned()
        // WITH_DEBUG_MIGRATE_FACADE=1: every definition's evidence and
        // verdicts, for reading a verdict back to the line that gave it.
        if with_getenv_str("WITH_DEBUG_MIGRATE_FACADE").len() > 0:
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
                var stores = ""
                var destroys = ""
                for pi in 0..self.symbols[si].param_ty.len():
                    stores = stores ++ (if self.symbols[si].param_stores[pi] != 0: "1" else: "0")
                    destroys = destroys ++ (if self.symbols[si].param_destroys[pi] != 0: "1" else: "0")
                eprint("facade: " ++ self.symbols[si].name ++ " -> " ++ self.symbols[si].ret_ty ++ (if self.symbols[si].header_declared != 0: " (declared)" else: " (internal)") ++ " stores=" ++ stores ++ " destroys=" ++ destroys ++ f" owns={self.symbols[si].owns_return} borrow_from={self.symbols[si].borrow_from}: " ++ self.symbols[si].own_reason)
                for line in self.symbols[si].own_evidence.split("\n"):
                    if line.len() > 0: eprint("    " ++ line)
                for pi in 0..self.symbols[si].param_sinks.len():
                    if self.symbols[si].param_sinks[pi].len() > 0: eprint(f"    sinks of param {pi}: " ++ self.symbols[si].param_sinks[pi])

    // The pointer-to-record representations the corpus produces or
    // destroys, in first-seen order of the symbol table.
    fn fd_representations() -> List[str]:
        var out: List[str] = List.new()
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            if self.symbols[si].owns_return != 0:
                let r = fd_record_pointee(self.symbols[si].ret_ty)
                if r.len() > 0 and not out.contains(r): out.push(r)
            for pi in 0..self.symbols[si].param_destroys.len():
                if self.symbols[si].param_destroys[pi] == 0: continue
                let r = fd_record_pointee(self.symbols[si].param_ty[pi])
                if r.len() > 0 and not out.contains(r): out.push(r)
        out

    fn fd_producers_of(record: &str) -> List[i32]:
        var out: List[i32] = List.new()
        for si in 0..self.symbols.len():
            if self.symbols[si].kind == CiProjectSymbolKind.CIPS_FN and self.symbols[si].has_definition != 0 and self.symbols[si].header_declared != 0 and self.symbols[si].owns_return != 0 and fd_record_pointee(self.symbols[si].ret_ty) == record: out.push(si as i32)
        out

    // The functions destroying a parameter of `record`; `unary` keeps those
    // whose only parameter it is.
    fn fd_destroyers_of(record: &str, unary: bool) -> List[i32]:
        var out: List[i32] = List.new()
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0 or self.symbols[si].header_declared == 0: continue
            let count = self.symbols[si].param_destroys.len()
            for pi in 0..count:
                if self.symbols[si].param_destroys[pi] != 0 and fd_record_pointee(self.symbols[si].param_ty[pi]) == record:
                    let is_unary = count == 1 and pi == 0
                    if is_unary == unary: out.push(si as i32)
                    break
        out

    // A representation someone can own: a producer and one unary destroyer.
    fn fd_owned_record(record: &str) -> bool:
        self.fd_producers_of(record).len() > 0 and self.fd_destroyers_of(record, true).len() == 1

    // The declared functions proven to return a borrow of `record` from an
    // owned record, retaining nothing.
    fn fd_borrow_candidates(record: &str) -> List[i32]:
        var out: List[i32] = List.new()
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0 or self.symbols[si].header_declared == 0 or self.symbols[si].borrow_from < 0: continue
            if fd_record_pointee(self.symbols[si].ret_ty) != record or self.fd_retains_any(si as i32): continue
            if self.fd_owned_record(fd_record_pointee(self.symbols[si].param_ty[self.symbols[si].borrow_from])): out.push(si as i32)
        out

    // The representations the draft can model: one unary destroyer, and
    // either a producer (an owned resource) or a proven borrow of it from an
    // owned resource (a borrowed-only resource, libxml2's attribute shape).
    // A representation the corpus destroys and never produces or lends is
    // not a resource here.
    fn fd_modeled_records() -> List[str]:
        var out: List[str] = List.new()
        let all = self.fd_representations()
        for record in all:
            if self.fd_destroyers_of(record, true).len() != 1: continue
            if self.fd_producers_of(record).len() > 0 or self.fd_borrow_candidates(record).len() > 0: out.push(record)
        out

    // The facade draft: what the proofs establish, every clause with its
    // proof beside it.
    fn facade_draft(name: &str) -> str:
        let modeled = self.fd_modeled_records()
        var text = "// Facade draft for " ++ name ++ ", proven from the package's own source (§16.2b.15, D121).\n// Every clause records its proof; a project may override any single fact.\n"
        text = text ++ "c facade " ++ name ++ ":\n"
        for record in modeled:
            text = text ++ "    resource " ++ fd_resource_name(record) ++ " wraps *mut " ++ record ++ "\n"
            let producers = self.fd_producers_of(record)
            for si in producers:
                text = text ++ "        from " ++ self.symbols[si].name ++ "    // " ++ self.symbols[si].own_reason ++ "\n"
            let drops = self.fd_destroyers_of(record, true)
            for si in drops:
                text = text ++ "        drop " ++ self.symbols[si].name ++ "    // proof: frees param 0\n"
            let others = self.fd_destroyers_of(record, false)
            for si in others:
                text = text ++ "        destroys " ++ self.symbols[si].name ++ "    // proof: frees its " ++ record ++ " parameter\n"
        // Borrows: a function that retains a pointer argument is not a lend
        // (fd_borrow_candidates). A borrowed value's origin is bound at each
        // call (D134, §16.2b.6), so one representation may be borrowed from
        // several origins.
        for record in modeled:
            let candidates = self.fd_borrow_candidates(record)
            for si in candidates:
                text = text ++ "    fn " ++ self.symbols[si].name ++ "\n        returns borrow " ++ fd_resource_name(record) ++ f" from param {self.symbols[si].borrow_from}    // " ++ self.symbols[si].own_reason ++ "\n"
        // Lends are the default (§16.2b.5); stating each records the proof
        // and presents the operation on its resource.
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            if self.fd_is_lend(si as i32, modeled):
                text = text ++ "    fn " ++ self.symbols[si].name ++ "\n        lend    // proof: reads its resource parameters, keeps nothing\n"
        text

    // One line per function: how the draft presents it, or why it stays
    // raw; a summary first.
    fn facade_report(name: &str) -> str:
        let modeled = self.fd_modeled_records()
        var lines = ""
        var safe = 0
        var raw = 0
        var total = 0
        var internal = 0
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            if self.symbols[si].header_declared == 0:
                internal = internal + 1
                continue
            total = total + 1
            let fname = with_str_clone_ref(self.symbols[si].name)
            let ret = fd_record_pointee(self.symbols[si].ret_ty)
            var verdict = ""
            if self.symbols[si].owns_return != 0 and modeled.contains(ret):
                verdict = "owned producer of " ++ fd_resource_name(ret) ++ " (" ++ self.symbols[si].own_reason ++ ")"
            else if self.symbols[si].owns_return != 0:
                verdict = "raw: owned " ++ self.symbols[si].ret_ty ++ " (" ++ self.symbols[si].own_reason ++ "), but the package has no single destroyer of it: a registry fact names one"
            else if self.fd_retains_any(si as i32) and not self.fd_destroys_any(si as i32):
                var retained = 0
                for pi in 0..self.symbols[si].param_stores.len():
                    if self.symbols[si].param_stores[pi] != 0:
                        retained = pi as i32
                        break
                verdict = f"raw: retains param {retained}; its lifetime contract is not proven"
            else if self.symbols[si].borrow_from >= 0:
                let origin = fd_record_pointee(self.symbols[si].param_ty[self.symbols[si].borrow_from])
                if modeled.contains(ret) and self.fd_owned_record(origin): verdict = "borrows " ++ fd_resource_name(ret) ++ f" from param {self.symbols[si].borrow_from} (" ++ self.symbols[si].own_reason ++ ")"
                else: verdict = "raw: " ++ self.symbols[si].own_reason ++ f", but param {self.symbols[si].borrow_from} or the return is not a modeled resource"
            else if ret.len() > 0:
                verdict = "raw: returns " ++ self.symbols[si].ret_ty ++ " unproven: " ++ self.symbols[si].own_reason
            else: verdict = self.fd_lend_verdict(si as i32, modeled)
            if verdict.starts_with("raw:"): raw = raw + 1 else: safe = safe + 1
            // The annotations the library ships, for the reader: nullability
            // ones are header facts c_import reads directly (§16.2b.8).
            let attrs = self.symbols[si].attrs
            if attrs.len() > 0: verdict = verdict ++ " [attributes: " ++ attrs.replace(";", " ").trim() ++ "]"
            lines = lines ++ "  " ++ fname ++ ": " ++ verdict ++ "\n"
        var head = "facade " ++ name ++ f": {total} functions, {safe} presented safely, {raw} raw" ++ (if internal > 0: f"; {internal} internal (no prototype declares them)" else: "") ++ "\n"
        for record in self.fd_representations():
            if modeled.contains(record): continue
            let producers = self.fd_producers_of(record).len()
            let unary = self.fd_destroyers_of(record, true).len()
            if producers == 0: head = head ++ "  " ++ record ++ ": destroyed but never produced here; no resource\n"
            else if unary == 0: head = head ++ "  " ++ record ++ f": {producers} producer(s) and no unary destroyer in the package; a registry fact names the drop\n"
            else: head = head ++ "  " ++ record ++ f": {producers} producer(s) and {unary} unary destroyers; a registry fact names the drop\n"
        head ++ lines
