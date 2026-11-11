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
use CiGir
use CiFacts
use std.string.parse
use rt.rt_core


// `R` for `*mut R` / `*const R` when R is a record; "" for anything else
// (a pointer to a pointer, to a scalar, to `c_void`, a function pointer).
fn fd_record_pointee(ty: &str) -> str:
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
fn fd_resource_name(record: &str) -> str:
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
        let p = parse(entry.slice(0, eq))
        if p == pos: return entry.slice(eq + 1, entry.len()).to_owned()
    ""

fn fd_i32(text: &str) -> i32:
    let v = parse(text)
    v

// D187 (§16.2b.6): the parameters a "borrow:<i>" / "borrow:<i>,<j>"
// verdict names, in order.
fn fd_borrow_members(verdict: &str) -> List[i32]:
    let out: List[i32] = []
    for part in verdict.slice(7, verdict.len()).split(","):
        if part.len() > 0: out.push(fd_i32(part))
    out

// The union of two borrow verdicts as one, "" when it would name more than
// the two parameters the clause can state.
fn fd_borrow_union(a: &str, b: &str) -> str:
    if not a.starts_with("borrow:") or not b.starts_with("borrow:"): return ""
    let members = fd_borrow_members(a)
    for m in fd_borrow_members(b):
        if not members.contains(m): members.push(m)
    if members.len() > 2: return ""
    members.sort()
    var text = "borrow:"
    for i in 0..members.len():
        text = text ++ (if i > 0: "," else: "") ++ f"{members[i]}"
    text

// A pointer to a C character type in the engine's spelling (`char`,
// `unsigned char` such as libxml2's `xmlChar`, any constness).
fn fd_is_char_pointer(ty: &str) -> bool:
    ty == "*mut u8" or ty == "*const u8" or ty == "*mut i8" or ty == "*const i8" or ty == "*mut c_char" or ty == "*const c_char"

impl CiProject:
    // An allocator call: libc's, a global initialized to one, or a function
    // of the package the library itself annotates `__attribute__((malloc))`
    // (#3179/libpng: png_malloc_base, PNG_ALLOCATED, returns `void *`; the
    // annotation was honoured only on a function returning a record, so
    // every producer that casts its result stayed raw).
    fn fd_is_alloc_call(name: &str) -> bool:
        if ci_own_is_libc_allocator(name) or self.alloc_aliases.contains(name): return true
        let role = self.fd_field_role(name)
        if role == "allocator" or role == "reallocator": return true
        let si = self.find_symbol(CiProjectSymbolKind.CIPS_FN, name)
        si >= 0 and self.symbols[si].ret_ty.starts_with("*") and self.fd_has_attr(si, "malloc")
    fn fd_is_free_call(name: &str) -> bool:
        if ci_own_is_libc_free(name) or self.free_aliases.contains(name): return true
        let role = self.fd_field_role(name)
        role == "deallocator" or role == "reallocator"

    // §16.2b.15: the role the registry states for the function-pointer
    // field a `*Record.field` callee names: a call through an `allocator`
    // returns a fresh allocation the caller owns, one through a
    // `reallocator` consumes its argument and returns one, one through a
    // `deallocator` destroys its argument. "" when none is stated; a role is
    // never drawn from the field's name.
    fn fd_field_role(callee: &str) -> str:
        if not callee.starts_with("*") or not self.field_roles.contains(callee.slice(1, callee.len())): return ""
        facts_kind(self.field_roles.get(callee.slice(1, callee.len())).unwrap())

    // D198 (#3206, Eric 2026-11-09): a proof about C is accepted only when
    // the drafter can enumerate everything it depends on. A function-pointer
    // field's callee is proven only when the field is written in exactly
    // one place, that place names a package function, and the record never
    // leaves what the drafter reads (no pointer to it passed to a function
    // without a body here, none converted to another pointer type, no
    // initializer that maps to no field, every unit read). Anything else
    // is a registry fact, and the verdict says which condition failed, so
    // the facts author knows what to state.
    //
    // One verdict per `Record.field`, `fn:<name>` or `why:<reason>`, and
    // one per record under `Record.*` when the record itself escapes.
    mut fn fd_draw_fnptr_verdicts():
        if self.fnptr_verdicts_drawn: return
        self.fnptr_verdicts_drawn = true
        let seen: HashMap[str, i32] = HashMap.new()
        let count: HashMap[str, i32] = HashMap.new()
        let named: HashMap[str, str] = HashMap.new()
        let fields = []
        for line in self.fnptr_evidence.split("\n"):
            if line.len() == 0 or seen.contains(line): continue
            seen.insert(line.to_owned(), 1)
            let f = line.split("\t")
            let record_key = if f.len() > 1: f[1] ++ ".*" else: ""
            if f[0] == "fw" and f.len() == 5 and f[2] == "*":
                if not self.fnptr_verdicts.contains(record_key): self.fnptr_verdicts.insert(record_key, "why:an initializer of the record maps to no field, or a field's address is taken (" ++ f[4] ++ ")")
            else if f[0] == "fw" and f.len() == 5:
                let key = f[1] ++ "." ++ f[2]
                let so_far = count.get(key).copied() ?? 0
                if so_far == 0:
                    fields.push(key.to_owned())
                    named.insert(key.to_owned(), f[3].to_owned())
                else if so_far == 1:
                    named.insert(key.to_owned(), with_str_clone_ref(named.get(key).unwrap()) ++ ", " ++ f[3])
                count.insert(key, so_far + 1)
            else if f[0] == "ra" and f.len() == 4:
                if not self.fnptr_verdicts.contains(record_key) and not self.fd_reads_callee(f[2]):
                    self.fnptr_verdicts.insert(record_key, "why:a pointer to the record is passed to " ++ (if f[2] == "?": "a function pointer" else: f[2]) ++ ", which the proofs cannot read (" ++ f[3] ++ ")")
            else if f[0] == "rc" and f.len() == 3:
                if not self.fnptr_verdicts.contains(record_key): self.fnptr_verdicts.insert(record_key, "why:a pointer to the record is converted to another pointer type (" ++ f[2] ++ ")")
        for key in fields:
            let writes = count.get(key).copied() ?? 0
            let value = with_str_clone_ref(named.get(key).unwrap())
            if writes > 1: self.fnptr_verdicts.insert(key, f"why:it is written in {writes} places (" ++ value ++ (if writes > 2: ", …)" else: ")"))
            else if value == "?": self.fnptr_verdicts.insert(key, "why:its one write is not a named function")
            else if not self.fd_reads_callee(value): self.fnptr_verdicts.insert(key, "why:its one write names " ++ value ++ ", which the proofs cannot read")
            else: self.fnptr_verdicts.insert(key, "fn:" ++ value)

    // A function whose body the proofs read (or `free`, which writes no
    // field): a record passed to it has not left what the drafter sees.
    fn fd_reads_callee(name: &str) -> bool:
        if name == "?": return false
        if self.fd_is_free_call(name): return true
        let si = self.find_symbol(CiProjectSymbolKind.CIPS_FN, name)
        si >= 0 and self.fd_subject(si) and self.symbols[si].has_definition != 0

    // The verdict of the field a `Record.field` callee names (D198).
    fn fd_fnptr_field_verdict(record_field: &str) -> str:
        if self.unread.len() > 0: return "why:a unit of the package could not be read"
        let dot = record_field.rfind(".")
        if dot <= 0: return "why:its record is not known"
        let record_key = record_field.slice(0, dot) ++ ".*"
        if self.fnptr_verdicts.contains(record_key): return with_str_clone_ref(self.fnptr_verdicts.get(record_key).unwrap())
        if self.fnptr_verdicts.contains(record_field): return with_str_clone_ref(self.fnptr_verdicts.get(record_field).unwrap())
        "why:the package never writes it (its value is the caller's)"

    // The package function a `*Record.field` callee is proven to be, or "".
    fn fd_fnptr_proven_callee(callee: &str) -> str:
        if not callee.starts_with("*"): return ""
        let verdict = self.fd_fnptr_field_verdict(callee.slice(1, callee.len()))
        if verdict.starts_with("fn:"): verdict.slice(3, verdict.len()) else: ""

    // What the report says of an unproven `*Record.field` callee.
    fn fd_fnptr_why(callee: &str) -> str:
        let record_field = callee.slice(1, callee.len())
        let dot = record_field.rfind(".")
        let field = if dot >= 0: record_field.slice(dot + 1, record_field.len()) else: record_field
        let verdict = self.fd_fnptr_field_verdict(record_field)
        "the function pointer field " ++ field ++ ", which no unit decides: " ++ verdict.slice(4, verdict.len())

    // Whether what is passed to `callee` at `index` is retained there.
    fn fd_callee_retains(callee: &str, index: i32) -> bool:
        // D198: through a function-pointer field, the one function it is
        // proven to hold decides; an unproven field retains.
        if callee.starts_with("*"):
            if self.fd_field_role(callee).len() > 0: return false
            let proven = self.fd_fnptr_proven_callee(callee)
            return proven.len() == 0 or self.fd_callee_retains(proven, index)
        if self.fd_is_free_call(callee) or self.fd_is_alloc_call(callee) or ci_own_is_libc_observer(callee): return false
        let si = self.find_symbol(CiProjectSymbolKind.CIPS_FN, callee)
        if si < 0: return true
        // #3179: a callee that destroys the argument keeps nothing of it: a
        // producer's error path (`if (!fill(p)) { thing_free(p); return
        // NULL; }`, cJSON_Duplicate_rec) read as the local being retained.
        if index < self.symbols[si].param_destroys.len() and self.symbols[si].param_destroys[index] != 0: return false
        // A callee no unit defines retains what it is given (the asymmetry
        // rule), unless the introspection file says it takes nothing there.
        if self.symbols[si].has_definition == 0: return gir_param_transfer(self.symbols[si].gir, index) != "none"
        index < self.symbols[si].param_stores.len() and self.symbols[si].param_stores[index] != 0

    // A sink's callee by name: the function a `*Record.field` is proven to hold (D198).
    fn fd_sink_callee(callee: &str) -> str:
        let proven = self.fd_fnptr_proven_callee(callee)
        if proven.len() > 0: proven else: callee.to_owned()

    // `to f`, or for a proven `*Record.field`: `through the function
    // pointer field F (only ever f) to f`.
    fn fd_sink_text(callee: &str) -> str:
        let proven = self.fd_fnptr_proven_callee(callee)
        if proven.len() == 0: return "to " ++ callee
        "through the function pointer field " ++ fd_field_of(callee) ++ " (only ever " ++ proven ++ ") to " ++ proven

    fn fd_callee_destroys(callee: &str, index: i32) -> bool:
        if callee.starts_with("*"):
            if self.fd_is_free_call(callee): return true
            let proven = self.fd_fnptr_proven_callee(callee)
            return proven.len() > 0 and self.fd_callee_destroys(proven, index)
        if self.fd_is_free_call(callee): return true
        let si = self.find_symbol(CiProjectSymbolKind.CIPS_FN, callee)
        if si < 0 or not self.fd_subject(si): return false
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
                let src = line.slice(("localsrc:" ++ local ++ ":").len(), line.len())
                // A local assigned from itself or a part of itself (`ret =
                // ret->next` walking a list) adds no source: its value is
                // still whatever its other assignments gave it.
                if src == "local:" ++ local or src == "field:local:" ++ local: continue
                assigned = true
                let v = self.fd_source_verdict(si, src, depth + 1)
                if v == "null": continue
                if verdict == "null": verdict = v
                else if verdict != v:
                    // D187: parts of two parameters on different paths
                    // are a borrow from both.
                    let joined = fd_borrow_union(verdict, v)
                    if joined.len() == 0: return "unknown:local " ++ local ++ " has more than one source"
                    verdict = joined
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
        // #3172: a call through a function-pointer field has no body to
        // read; which function the field holds is a registry fact.
        if src.starts_with("indirect:"):
            // D198: the one function the field is proven to hold decides.
            if self.fd_is_alloc_call("*" ++ src.slice(9, src.len())): return "owned"
            let proven = self.fd_fnptr_proven_callee("*" ++ src.slice(9, src.len()))
            if proven.len() > 0: return self.fd_source_verdict(si, "call:" ++ proven ++ ":", depth + 1)
            return "unknown:returns what " ++ self.fd_fnptr_why("*" ++ src.slice(9, src.len()))
        if src.starts_with("call:"):
            let rest = src.slice(5, src.len())
            let colon = rest.find(":")
            let callee = if colon >= 0: rest.slice(0, colon).to_owned() else: rest.to_owned()
            let argmap = if colon >= 0: rest.slice(colon + 1, rest.len()).to_owned() else: ""
            if self.fd_is_alloc_call(callee): return "owned"
            let ci = self.find_symbol(CiProjectSymbolKind.CIPS_FN, callee)
            if ci < 0 or not self.fd_subject(ci): return "unknown:" ++ callee ++ " is not defined in the package"
            if self.symbols[ci].owns_return != 0: return "owned"
            if self.symbols[ci].borrow_from >= 0:
                // D187: a callee borrowing from two parameters borrows from
                // what both arguments are.
                var joined = ""
                for origin in [self.symbols[ci].borrow_from, self.symbols[ci].borrow_from2]:
                    if origin < 0: continue
                    let arg = fd_argmap_at(argmap, origin)
                    var v = ""
                    if arg.starts_with("p"): v = "borrow:" ++ arg.slice(1, arg.len())
                    else if arg.starts_with("l"): v = self.fd_local_verdict(si, arg.slice(1, arg.len()), depth)
                    if not v.starts_with("borrow:"): return "unknown:" ++ callee ++ " borrows from an argument that is not a parameter"
                    joined = if joined.len() == 0: v else: fd_borrow_union(joined, v)
                    if joined.len() == 0: return "unknown:" ++ callee ++ " borrows from more than two parameters' arguments"
                return joined
            // A callee the returns pass has not reached yet has no reason
            // of its own: say what its type says, never an empty `()`.
            let why = if self.symbols[ci].own_reason.len() > 0: with_str_clone_ref(self.symbols[ci].own_reason)
                else if fd_record_pointee(self.symbols[ci].ret_ty).len() == 0: "returns no pointer to a record"
                else: "its return is not proven"
            return "unknown:" ++ callee ++ " is unproven (" ++ why ++ ")"
        if src == "global": return "unknown:returns global state"
        "unknown:no single source"

    // Whether any declaration of `si` carries the attribute `name`
    // (`malloc`, `returns_nonnull`, or `nonnull` with its list).
    // `__name__` is GCC's reserved spelling of `name` (libpng's
    // `__attribute__((__malloc__))`): the same attribute.
    fn fd_has_attr(si: i32, name: &str) -> bool:
        let reserved = "__" ++ name ++ "__"
        for a in self.symbols[si].attrs.split(";"):
            if a == name or a.starts_with(name ++ "(") or a == reserved or a.starts_with(reserved ++ "("): return true
        false

    // A function the proofs are about: one a unit defines, or one the
    // package's introspection files declare facts for (D121 step 3).
    fn fd_subject(si: i32) -> bool:
        self.symbols[si].kind == CiProjectSymbolKind.CIPS_FN and (self.symbols[si].has_definition != 0 or self.symbols[si].gir.len() > 0 or self.symbols[si].registry.len() > 0)

    // The pointer parameters of `si`: how many, and the index of the one
    // when there is exactly one (else -1).
    fn fd_sole_pointer_param(si: i32) -> i32:
        var count = 0
        var sole = -1
        for pi in 0..self.symbols[si].param_ty.len():
            if self.symbols[si].param_ty[pi].starts_with("*"):
                count = count + 1
                sole = pi as i32
        if count == 1: sole else: -1

    // Parameter `pi` of `si` the introspection file says the callee takes
    // (`transfer-ownership="full"`), a pointer to a record.
    fn fd_gir_takes(si: i32, pi: i32) -> bool:
        self.fd_param_is_pointer(si, pi) and fd_record_pointee(self.symbols[si].param_ty[pi]).len() > 0 and gir_param_transfer(self.symbols[si].gir, pi) == "full"

    // The first modeled resource parameter the introspection file says the
    // callee takes and the body does not destroy, else -1.
    fn fd_consumed_param(si: i32, modeled: &List[str]) -> i32:
        for pi in 0..self.symbols[si].param_ty.len():
            if self.symbols[si].param_destroys[pi] != 0: continue
            if self.fd_gir_takes(si, pi as i32) and modeled.contains(fd_record_pointee(self.symbols[si].param_ty[pi])): return pi as i32
        // The registry's `consumes param N` (D121 step 4), below the file.
        let kind = facts_kind(self.symbols[si].registry)
        if kind.starts_with("consumes:"):
            let pi = fd_i32(kind.slice(9, kind.len()))
            if self.fd_param_is_pointer(si, pi) and self.symbols[si].param_destroys[pi] == 0 and modeled.contains(fd_record_pointee(self.symbols[si].param_ty[pi])): return pi
        -1

    // Why `si` consumes the parameter `fd_consumed_param` found.
    fn fd_consumed_reason(si: i32, pi: i32) -> str:
        if self.fd_gir_takes(si, pi): "annotation: gir transfer-ownership=\"full\", the callee takes it" else: "registry: " ++ facts_cite(self.symbols[si].registry)

    // Why `si` destroys its parameter: the body's proof, the introspection
    // file naming it the record's destroyer, or the registry's fact.
    fn fd_destroy_reason(si: i32, what: &str) -> str:
        if self.symbols[si].gir.contains("dropby=gir"): return "annotation: the introspection file names it the record's free function"
        if self.symbols[si].registry.contains("|by=registry"): return "registry: " ++ facts_cite(self.symbols[si].registry)
        let named_by_file = self.symbols[si].gir.contains("drop=1")
        let named_by_registry = facts_kind(self.symbols[si].registry) == "drop"
        "proof: frees " ++ what ++ (if named_by_file: "; the introspection file names it the record's free function" else if named_by_registry: "; the registry names it the drop: " ++ facts_cite(self.symbols[si].registry) else: "")

    // What the registry says about `si`, for the report.
    fn fd_registry_summary(si: i32) -> str:
        let r = self.symbols[si].registry
        var parts = ""
        if r.len() > 0:
            parts = facts_kind(r) ++ ": " ++ facts_cite(r)
            if self.symbols[si].borrow_from >= 0 and facts_kind(r) == "owned" and self.symbols[si].own_reason.starts_with("proof:"): parts = parts ++ "; DISAGREES: the proof returns a borrow"
            if self.symbols[si].owns_return != 0 and facts_kind(r).starts_with("borrow:") and self.symbols[si].own_reason.starts_with("proof:"): parts = parts ++ "; DISAGREES: the proof returns a fresh allocation"
        for line in self.symbols[si].registry_more.split("\n"):
            if line.len() == 0: continue
            parts = parts ++ (if parts.len() > 0: "; " else: "") ++ facts_kind(line) ++ ": " ++ facts_cite(line)
        if parts.len() == 0: return ""
        " [registry: " ++ parts ++ "]"

    // D121 step 6: the registry's presentation facts for `si` (CiFacts.w
    // `presentation`): the function F a `text return` is freed by, or "".
    fn fd_registry_text_return(si: i32) -> str:
        for line in self.symbols[si].registry_more.split("\n"):
            let kind = facts_kind(line)
            if kind.starts_with("text_return:"): return kind.slice(12, kind.len())
        ""

    // Whether the registry states `what` (`nullable` or `text_param`) of
    // parameter `pi`.
    fn fd_registry_names_param(si: i32, what: &str, pi: i32) -> bool:
        for line in self.symbols[si].registry_more.split("\n"):
            let kind = facts_kind(line)
            if kind.starts_with(what ++ ":") and fd_i32(kind.slice(what.len() + 1, kind.len())) == pi: return true
        false

    // The registry's presentation clauses for `si`, each with its citation,
    // in the draft's spelling.
    fn fd_registry_presentation_lines(si: i32) -> str:
        var out = self.fd_value_record_lines(si)
        if self.fd_registry_text_return(si).len() == 0 and self.fd_returns_literal_text(si, 0):
            out = out ++ "        returns static CStr    // proof: every return is a string literal\n"
        for line in self.symbols[si].registry_more.split("\n"):
            if line.len() == 0: continue
            let kind = facts_kind(line)
            let clause = if kind.starts_with("nullable:"): "nullable param " ++ kind.slice(9, kind.len()) else if kind.starts_with("text_param:"): "text param " ++ kind.slice(11, kind.len()) else: "text return, owned, freed by " ++ kind.slice(12, kind.len())
            out = out ++ "        " ++ clause ++ "    // registry: " ++ facts_cite(line) ++ "\n"
        out

    // Why parameter `pi` of `si` counts as retained: the store itself, or
    // the first callee that retains what it is given, followed to where the
    // proof stops (a store, or a callee no unit defines).
    fn fd_retain_reason(si: i32, pi: i32, depth: i32) -> str:
        if depth > 6: return "a chain of calls too deep to follow"
        let sinks = if pi < self.symbols[si].param_sinks.len(): with_str_clone_ref(self.symbols[si].param_sinks[pi]) else: ""
        if sinks.contains("field;"): return "stored in a field"
        if sinks.contains("global;"): return "stored in a global"
        for line in self.symbols[si].own_evidence.split("\n"):
            if line == f"paramstore:{pi}": return "stored"
        for sink in sinks.split(";"):
            if not sink.contains(":"): continue
            let kv = sink.split(":")
            if not self.fd_callee_retains(kv[0], fd_i32(kv[1])): continue
            // #3174: a sink through a function-pointer field (glfw's platform
            // dispatch) is said as such; which function the field holds is
            // a registry fact, not a missing unit.
            if kv[0].starts_with("*") and self.fd_fnptr_proven_callee(kv[0]).len() == 0: return "passed through " ++ self.fd_fnptr_why(kv[0])
            let ci = self.find_symbol(CiProjectSymbolKind.CIPS_FN, self.fd_sink_callee(kv[0]))
            if ci < 0 or self.symbols[ci].has_definition == 0: return "passed to " ++ kv[0] ++ ", which no unit defines"
            return "passed " ++ self.fd_sink_text(kv[0]) ++ " at param " ++ kv[1] ++ ", " ++ self.fd_retain_reason(ci, fd_i32(kv[1]), depth + 1)
        for line in self.symbols[si].own_evidence.split("\n"):
            if line.starts_with("localstore:") and self.fd_local_alias_param(si, line.slice(11, line.len())) == pi: return "stored through local " ++ line.slice(11, line.len())
            if not line.starts_with("localsink:"): continue
            let parts = line.split(":")
            if parts.len() != 4 or self.fd_local_alias_param(si, parts[1]) != pi or not self.fd_callee_retains(parts[2], fd_i32(parts[3])): continue
            if parts[2].starts_with("*") and self.fd_fnptr_proven_callee(parts[2]).len() == 0: return "passed through " ++ self.fd_fnptr_why(parts[2])
            let ci = self.find_symbol(CiProjectSymbolKind.CIPS_FN, self.fd_sink_callee(parts[2]))
            if ci < 0 or self.symbols[ci].has_definition == 0: return "passed to " ++ parts[2] ++ ", which no unit defines"
            return "passed " ++ self.fd_sink_text(parts[2]) ++ " at param " ++ parts[3] ++ ", " ++ self.fd_retain_reason(ci, fd_i32(parts[3]), depth + 1)
        "retained by evidence the report cannot restate"

    // D198 (§16.2b.5): the records with identity. Some function produces,
    // destroys or retains a pointer to one (zlib's `deflateInit` keeps the
    // `z_stream`'s address), so a pointer to it is that resource, never a
    // value record, whatever a signature looks like.
    mut fn fd_draw_identity_records():
        let found = []
        var si: i32 = -1
        for symbol in self.symbols:
            si = si + 1
            if symbol.kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si): continue
            if symbol.owns_return != 0: found.push(fd_record_pointee(symbol.ret_ty))
            var pi = -1
            for p in symbol.param_ty:
                pi = pi + 1
                let kept = pi < symbol.param_stores.len() and symbol.param_stores[pi] != 0
                let ended = pi < symbol.param_destroys.len() and symbol.param_destroys[pi] != 0
                if kept or ended: found.push(fd_record_pointee(p))
        for record in found:
            if record.len() > 0: self.identity_records.insert(record, true)

    // D198 (§16.2b.5): the value-record clause the proofs give parameter
    // `pi` of `si`, or "". Stated only when everything it depends on is
    // read: the record is flat (no pointer inside it, so the callee cannot
    // leave it through its own fields) and complete in a header the
    // package installs, and
    // has no identity; the body keeps no pointer to it or into it, touches
    // only the one record (no index, no arithmetic, no part's address, no
    // copy of the pointer), and passes it on only to functions of the
    // package the same holds for. `const T *` is `reads`; `T *` written
    // and never read is `fills`; any other `T *` is `updates`.
    fn fd_value_record_word(si: i32, pi: i32, depth: i32) -> str:
        if depth > 6 or self.unread.len() > 0 or self.symbols[si].has_definition == 0 or pi >= self.symbols[si].param_ty.len(): return ""
        let p = with_str_clone_ref(self.symbols[si].param_ty[pi])
        let is_const = p.starts_with("*const ")
        if not is_const and not p.starts_with("*mut "): return ""
        let record = fd_record_pointee(p)
        if record.len() == 0 or not self.installed_records.contains(record) or self.identity_records.contains(record): return ""
        if pi < self.symbols[si].param_stores.len() and self.symbols[si].param_stores[pi] != 0: return ""
        if pi < self.symbols[si].param_destroys.len() and self.symbols[si].param_destroys[pi] != 0: return ""
        var reads = false
        var writes = false
        for line in self.symbols[si].own_evidence.split("\n"):
            if line == f"vx:{pi}": return ""
            if line == f"vr:{pi}": reads = true
            if line == f"vw:{pi}": writes = true
            if not line.starts_with(f"va:{pi}:"): continue
            let parts = line.split(":")
            if parts.len() != 4: return ""
            let ci = self.find_symbol(CiProjectSymbolKind.CIPS_FN, parts[2])
            if ci < 0 or not self.fd_subject(ci): return ""
            let passed = self.fd_value_record_word(ci, fd_i32(parts[3]), depth + 1)
            if passed.len() == 0: return ""
            if passed != "fills": reads = true
            if passed != "reads": writes = true
        if is_const: return if writes: "" else: "reads"
        if writes and not reads: "fills" else: "updates"

    // Why parameter `pi` of `si`, a pointer to a record, is no value record
    // the proofs can state ("" when it is one, or is no record pointer):
    // fd_value_record_word's conditions, in its order, for the report.
    fn fd_value_record_why(si: i32, pi: i32, depth: i32) -> str:
        let p = with_str_clone_ref(self.symbols[si].param_ty[pi])
        let record = fd_record_pointee(p)
        if record.len() == 0 or not (p.starts_with("*const ") or p.starts_with("*mut ")): return ""
        if self.fd_value_record_word(si, pi, depth).len() > 0: return ""
        if self.unread.len() > 0: return "a unit of the package could not be read"
        if self.symbols[si].has_definition == 0: return "no unit defines the function, so nothing proves what it does with the record"
        if not self.installed_records.contains(record): return record ++ " is not a flat record complete in a header the package installs (it holds a pointer, or is opaque there)"
        if self.identity_records.contains(record): return "some function of the package produces, destroys or retains a pointer to " ++ record ++ ", so it is a resource, not a value"
        for line in self.symbols[si].own_evidence.split("\n"):
            if line == f"vx:{pi}": return "the body indexes it, moves the pointer, takes the address of a part, or copies the pointer"
            if not line.starts_with(f"va:{pi}:"): continue
            let parts = line.split(":")
            let ci = if parts.len() == 4: self.find_symbol(CiProjectSymbolKind.CIPS_FN, parts[2]) else: -1
            if ci < 0 or not self.fd_subject(ci): return "it is passed to " ++ (if parts.len() == 4 and parts[2] != "?": parts[2] else: "a function pointer") ++ ", which the proofs cannot read"
            if depth < 6 and self.fd_value_record_word(ci, fd_i32(parts[3]), depth + 1).len() == 0: return "it is passed to " ++ parts[2] ++ ", where " ++ self.fd_value_record_why(ci, fd_i32(parts[3]), depth + 1)
        if p.starts_with("*const "): return "the body writes through a `const` pointer"
        "the proofs do not cover it"

    // The report's verdict with value records said as such: an operation
    // presented over them alone names its clauses; one left raw for a
    // record pointer says why that pointer is no value record.
    fn fd_value_record_verdict(si: i32, verdict: &str, modeled: &List[str]) -> str:
        if verdict.starts_with("lend (proof:") and not self.fd_takes_modeled_resource(si, modeled):
            let clauses = self.fd_value_record_lines(si)
            if clauses.len() == 0: return verdict.to_owned()
            var said = ""
            for line in clauses.split("\n"):
                let end = line.find("    //")
                if end > 0: said = said ++ (if said.len() > 0: ", " else: "") ++ line.slice(0, end).trim()
            return "value records: " ++ said ++ " (proof: touches only the one record, keeps no pointer to it or into it)"
        if not verdict.starts_with("raw: parameter of unmodeled pointer type "): return verdict.to_owned()
        var pi: i32 = -1
        for p in self.symbols[si].param_ty:
            pi = pi + 1
            if not p.starts_with("*") or self.fd_param_presentable(si, pi, modeled): continue
            let why = self.fd_value_record_why(si, pi, 0)
            return if why.len() > 0: verdict ++ f"; param {pi} is no value record: " ++ why else: verdict.to_owned()
        verdict.to_owned()

    // The value-record clauses of `si`, one line each with its proof.
    fn fd_value_record_lines(si: i32) -> str:
        var out = ""
        var pi: i32 = -1
        for p in self.symbols[si].param_ty:
            pi = pi + 1
            let word = if p.starts_with("*"): self.fd_value_record_word(si, pi, 0) else: ""
            if word.len() == 0: continue
            let proof = if word == "reads": "reads the one record, keeps no pointer to it or into it" else if word == "fills": "writes the one record without reading it, keeps no pointer to it or into it" else: "reads and writes the one record, keeps no pointer to it or into it"
            out = out ++ "        " ++ word ++ f" param {pi}    // proof: " ++ proof ++ "\n"
        out

    // Whether some parameter of `si` receives a modeled resource.
    fn fd_takes_modeled_resource(si: i32, modeled: &List[str]) -> bool:
        for p in self.symbols[si].param_ty:
            let record = fd_record_pointee(p)
            if record.len() > 0 and modeled.contains(record): return true
        false

    // Whether parameter `pi` of `si` is one the facade language presents
    // without a clause the draft does not write (SemaFacade.w
    // facade_op_raw_beyond): a value, a `const char *` (§16.3c), a text
    // parameter the registry states, or a pointer to a modeled record (a
    // borrow of that resource). A callback, a pointer to a pointer, an
    // array or a pointer to an unmodeled record leaves the call raw.
    fn fd_param_presentable(si: i32, pi: i32, modeled: &List[str]) -> bool:
        let p = with_str_clone_ref(self.symbols[si].param_ty[pi])
        if not (p.starts_with("*") or p.starts_with("&") or p.starts_with("[") or p.starts_with("fn(") or p.starts_with("extern") or p.starts_with("unsafe ") or p.starts_with("Option[")): return true
        if p == "*const i8" or p == "*const c_char": return true
        if fd_is_char_pointer(p) and self.fd_registry_names_param(si, "text_param", pi): return true
        // D198 (§16.2b.5): a value record the proofs can describe.
        if self.fd_value_record_word(si, pi, 0).len() > 0: return true
        let rec = fd_record_pointee(p)
        rec.len() > 0 and modeled.contains(rec)

    // The first parameter of `si` the facade language cannot present, or
    // -1 (`repr_param` is the resource's own, handed by the rendering).
    fn fd_unpresentable_param(si: i32, repr_param: i32, modeled: &List[str]) -> i32:
        for pi in 0..self.symbols[si].param_ty.len():
            if pi as i32 == repr_param: continue
            if not self.fd_param_presentable(si, pi as i32, modeled): return pi as i32
        -1

    // Whether the draft can state `si` as an item whose return the clause
    // covers (`skip_return`) or whose return must be a value, with every
    // other parameter presentable: the renderer's "still a raw call" rule.
    fn fd_presentable(si: i32, repr_param: i32, skip_return: bool, modeled: &List[str]) -> bool:
        if self.symbols[si].variadic != 0: return false
        if not skip_return and self.symbols[si].ret_ty.starts_with("*") and not (fd_is_char_pointer(self.symbols[si].ret_ty) and self.fd_registry_text_return(si).len() > 0): return false
        self.fd_unpresentable_param(si, repr_param, modeled) < 0

    fn fd_retains_verdict(si: i32, pi: i32) -> str:
        f"raw: retains param {pi} (" ++ self.fd_retain_reason(si, pi, 0) ++ "); its lifetime contract is not proven"

    // What the introspection file says about `si`, for the report.
    fn fd_gir_summary(si: i32) -> str:
        let g = self.symbols[si].gir
        if g.len() == 0: return ""
        var parts = ""
        let ret = gir_fact(g, "ret")
        let rtype = gir_fact(g, "rtype")
        if ret != "-" and ret.len() > 0 and rtype != "none": parts = "return transfer " ++ ret
        if gir_fact(g, "rnull") == "1": parts = parts ++ (if parts.len() > 0: ", " else: "") ++ "nullable return"
        if rtype == "utf8" or rtype == "filename": parts = parts ++ (if parts.len() > 0: ", " else: "") ++ "returns " ++ rtype
        for pi in 0..self.symbols[si].param_ty.len():
            let t = gir_param_transfer(g, pi as i32)
            if t == "full" or t == "container": parts = parts ++ (if parts.len() > 0: ", " else: "") ++ f"param {pi} transfer " ++ t
        if g.contains("drop=1"): parts = parts ++ (if parts.len() > 0: ", " else: "") ++ "a record's free function"
        // A proof and the file disagreeing is worth a loud line: one of
        // them is wrong, and the proof stands (§16.2b.2).
        if self.symbols[si].borrow_from >= 0 and ret == "full" and not self.symbols[si].own_reason.starts_with("annotation:"): parts = parts ++ "; DISAGREES: the proof returns a borrow"
        if self.symbols[si].owns_return != 0 and ret == "none" and not self.symbols[si].own_reason.starts_with("annotation:"): parts = parts ++ "; DISAGREES: the proof returns a fresh allocation"
        if parts.len() == 0: "" else: " [gir: " ++ parts ++ "]"

    fn fd_retains_any(si: i32) -> bool:
        for pi in 0..self.symbols[si].param_stores.len():
            if self.symbols[si].param_stores[pi] != 0: return true
        false

    fn fd_destroys_any(si: i32) -> bool:
        for pi in 0..self.symbols[si].param_destroys.len():
            if self.symbols[si].param_destroys[pi] != 0: return true
        false

    // #3127 (§16.2b.8): a function returns static text when every `return`
    // of its body is a string literal, or a call of a function of the
    // package that returns static text. The proof depends on the body
    // alone (D198): a literal is not the caller's, not allocated, never
    // freed and never written.
    fn fd_returns_literal_text(si: i32, depth: i32) -> bool:
        if depth > 8 or not fd_is_char_pointer(self.symbols[si].ret_ty) or not self.fd_subject(si): return false
        var returns = 0
        for line in self.symbols[si].own_evidence.split("\n"):
            if not line.starts_with("ret:"): continue
            returns = returns + 1
            let src = line.slice(4, line.len())
            if src == "literal": continue
            if not src.starts_with("call:"): return false
            let rest = src.slice(5, src.len())
            let colon = rest.find(":")
            let callee = self.find_symbol(CiProjectSymbolKind.CIPS_FN, if colon >= 0: rest.slice(0, colon) else: rest)
            if callee < 0 or callee == si or not self.fd_returns_literal_text(callee, depth + 1): return false
        returns > 0

    // How a function with no record-pointer return is presented: a
    // destroyer, a value-only call, a lend (every pointer parameter is a
    // modeled resource it reads and keeps), or `raw:` with the reason.
    fn fd_lend_verdict(si: i32, modeled: &List[str]) -> str:
        // A variadic call stays raw until a facade states its cases
        // (§16.2b.5): the draft has none to state, and the report said
        // `lend ... presented safely` of a printf-style function.
        if self.symbols[si].variadic != 0: return "raw: variadic: the arguments after the fixed ones are an unmodeled contract; a facade states them as cases (§16.2b.5)"
        // A character pointer the registry says is new text the caller owns
        // (`text return, owned, freed by F`) is presented; any other pointer
        // to no record stays raw.
        if self.symbols[si].ret_ty.starts_with("*") and not (fd_is_char_pointer(self.symbols[si].ret_ty) and self.fd_registry_text_return(si).len() > 0) and not self.fd_returns_literal_text(si, 0): return "raw: returns " ++ self.symbols[si].ret_ty ++ ", a pointer to no record"
        var pointer_params = 0
        var destroyed = -1
        var retained = -1
        var unmodeled = ""
        for pi in 0..self.symbols[si].param_ty.len():
            let p = self.symbols[si].param_ty[pi]
            let is_pointer = p.starts_with("*")
            if is_pointer: pointer_params = pointer_params + 1
            if is_pointer and self.symbols[si].param_destroys[pi] != 0: destroyed = pi as i32
            else if is_pointer and self.symbols[si].param_stores[pi] != 0: retained = pi as i32
            else if unmodeled.len() == 0 and not self.fd_param_presentable(si, pi as i32, modeled): unmodeled = p
        // A `destroys` item hands the resource as the first parameter
        // (§16.2b.13); a destroyer of a later one is not stated.
        if destroyed > 0: return f"raw: destroys param {destroyed}, which is not its first parameter (§16.2b.13)"
        if destroyed == 0 and unmodeled.len() > 0: return "raw: destroys param 0, but parameter of " ++ (if unmodeled.starts_with("*"): "unmodeled pointer type " else: "a callback or array type the facade does not describe: ") ++ unmodeled
        if destroyed >= 0: return f"destroyer, param {destroyed} (" ++ self.fd_destroy_reason(si, "it") ++ ")"
        // A retained parameter the introspection file says the callee
        // takes is consumed: the caller hands it over (§16.2b.15 item 2).
        let consumed = self.fd_consumed_param(si, modeled)
        if consumed >= 0 and (retained < 0 or retained == consumed): return f"consumes param {consumed} (" ++ self.fd_consumed_reason(si, consumed) ++ ")"
        // The registry may state a lend the proofs could not reach (a
        // retention the body only appears to make, an unmodeled type).
        if facts_kind(self.symbols[si].registry) == "lend" and pointer_params > 0: return "lend (registry: " ++ facts_cite(self.symbols[si].registry) ++ ")"
        if retained >= 0: return self.fd_retains_verdict(si, retained)
        if unmodeled.len() > 0: return "raw: parameter of " ++ (if unmodeled.starts_with("*"): "unmodeled pointer type " else: "a callback or array type the facade does not describe: ") ++ unmodeled
        if pointer_params == 0: return "value-only call"
        "lend (proof: reads its resource parameters, keeps nothing)"

    fn fd_is_lend(si: i32, modeled: &List[str]) -> bool:
        self.symbols[si].header_declared != 0 and self.symbols[si].owns_return == 0 and self.symbols[si].borrow_from < 0 and fd_record_pointee(self.symbols[si].ret_ty).len() == 0 and self.fd_lend_verdict(si, modeled).starts_with("lend")

    // The clause's origin spelling: `param N`, or `params N, M` (D187).
    fn fd_borrow_origin_text(si: i32) -> str:
        if self.symbols[si].borrow_from2 >= 0: f"params {self.symbols[si].borrow_from}, {self.symbols[si].borrow_from2}" else: f"param {self.symbols[si].borrow_from}"

    fn fd_src_text(src: &str) -> str:
        if src.starts_with("call:"):
            let rest = src.slice(5, src.len())
            let colon = rest.find(":")
            return (if colon >= 0: rest.slice(0, colon).to_owned() else: rest.to_owned()) ++ "(…)"
        if src.starts_with("indirect:"):
            let proven = self.fd_fnptr_proven_callee("*" ++ src.slice(9, src.len()))
            return if proven.len() > 0: proven ++ "(…) through the function pointer field " ++ fd_field_of(src.slice(9, src.len())) else: "(*" ++ fd_field_of(src.slice(9, src.len())) ++ ")(…)"
        if src.starts_with("field:param:"): return "a part of param " ++ src.slice(12, src.len())
        if src.starts_with("param:"): return "param " ++ src.slice(6, src.len())
        if src.starts_with("local:"): return src.slice(6, src.len()).to_owned()
        if src.starts_with("field:local:"): return "a part of " ++ src.slice(12, src.len())
        src.to_owned()

    // The pointer parameter a local stands for: every assignment to the
    // local is that parameter (`gz_statep state = (gz_statep)file`), else -1.
    // #3195: a local that walks from the parameter (`cur = t; while (cur) {
    // next = cur->next; free(cur); cur = next; }`, cJSON_Delete) stands for
    // it at the first destroying sink. A source that is a part of the local
    // itself, or a local made only of such parts, recorded after that sink
    // keeps the alias (the first iteration frees the parameter); one
    // recorded before it (`cur = cur->next; free(cur)`) breaks it. The
    // evidence is in source order; a for statement's increment is recorded
    // after its body (ci_own_walk).
    fn fd_local_alias_param(si: i32, local: &str) -> i32:
        var alias = -1
        var destroyed_seen = false
        for line in self.symbols[si].own_evidence.split("\n"):
            if line.starts_with("localsink:" ++ local ++ ":"):
                let parts = line.split(":")
                if parts.len() == 4 and self.fd_callee_destroys(parts[2], fd_i32(parts[3])): destroyed_seen = true
                continue
            if not line.starts_with("localsrc:" ++ local ++ ":"): continue
            let src = line.slice(("localsrc:" ++ local ++ ":").len(), line.len())
            if not src.starts_with("param:"):
                if destroyed_seen and self.fd_src_is_part_of_local(si, src, local): continue
                return -1
            let pi = fd_i32(src.slice(6, src.len()))
            if alias >= 0 and alias != pi: return -1
            alias = pi
        if alias >= 0 and (alias >= self.symbols[si].param_ty.len() or not self.symbols[si].param_ty[alias].starts_with("*")): return -1
        alias

    // `src` is a part of `local` (`cur->next`), or a local whose every
    // source is such a part (`next = cur->next`).
    fn fd_src_is_part_of_local(si: i32, src: &str, local: &str) -> bool:
        if src == "field:local:" ++ local: return true
        if not src.starts_with("local:"): return false
        let other = src.slice(6, src.len())
        if other == local: return true
        var sources = 0
        for line in self.symbols[si].own_evidence.split("\n"):
            if not line.starts_with("localsrc:" ++ other ++ ":"): continue
            if line.slice(("localsrc:" ++ other ++ ":").len(), line.len()) != "field:local:" ++ local: return false
            sources = sources + 1
        sources > 0

    fn fd_param_is_pointer(si: i32, pi: i32) -> bool:
        pi >= 0 and pi < self.symbols[si].param_ty.len() and self.symbols[si].param_ty[pi].starts_with("*")

    // A parameter is destroyed when the body passes it, or a local that
    // stands for it, to a destroyer at its destroyed position: to a fixed
    // point over the corpus.
    mut fn fd_propagate_destruction():
        let n = self.symbols.len()
        var changed = true
        while changed:
            changed = false
            for si in 0..n:
                if not self.fd_subject(si as i32): continue
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

    // D121: the corpus-wide ownership proofs, drawn once after every unit
    // is scanned. Each phase is a monotone fixed point; the order of units
    // never enters. Retention and destruction are facts about pointer
    // parameters, reached directly or through a local that stands for one.
    mut fn resolve_ownership():
        // D198: which function-pointer fields have a proven callee.
        self.fd_draw_fnptr_verdicts()
        let n = self.symbols.len()
        // 1. Retention.
        for si in 0..n:
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si as i32): continue
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
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si as i32): continue
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
        // 2. Destruction: the bodies' proofs first; then the introspection
        // file's `free-function` seeds a unary pointer-parameter function
        // no body proved (D121 step 3), and the fixed point reaches its
        // callers.
        self.fd_propagate_destruction()
        var seeded = false
        for si in 0..n:
            if not self.fd_subject(si as i32) or not self.symbols[si].gir.contains("drop=1"): continue
            if self.symbols[si].param_ty.len() != 1 or not self.fd_param_is_pointer(si as i32, 0) or self.symbols[si].param_destroys[0] != 0: continue
            self.symbols[si].param_destroys[0] = 1
            self.symbols[si].gir = self.symbols[si].gir ++ ";dropby=gir"
            seeded = true
        // The registry's `drop F` / `destroys F` on a resource: F destroys
        // its parameter of that record (D121 step 4), where nothing above
        // proved it.
        for si in 0..n:
            let kind = facts_kind(self.symbols[si].registry)
            if not self.fd_subject(si as i32) or not (kind == "drop" or kind == "destroys"): continue
            let record = facts_record(self.symbols[si].registry)
            for pi in 0..self.symbols[si].param_ty.len():
                if self.symbols[si].param_destroys[pi] != 0 or fd_record_pointee(self.symbols[si].param_ty[pi]) != record: continue
                self.symbols[si].param_destroys[pi] = 1
                self.symbols[si].registry = self.symbols[si].registry ++ "|by=registry"
                seeded = true
                break
        if seeded: self.fd_propagate_destruction()
        // 3. Returns.
        changed = true
        while changed:
            changed = false
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si as i32): continue
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
                        // D187 (§16.2b.6): a part of one parameter on one
                        // path and of another on another is a borrow from
                        // both, `returns borrow R from params N, M`.
                        let joined = fd_borrow_union(verdict, v)
                        if joined.len() == 0:
                            verdict = "unknown:returns " ++ self.fd_src_text(src) ++ " and " ++ reason.slice(8, reason.len())
                            break
                        // A return naming an origin already named adds
                        // nothing to the reason.
                        if joined != verdict: reason = reason ++ " and " ++ self.fd_src_text(src)
                        verdict = joined
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
                // The introspection file's transfer on the return: `full`
                // is the caller's; `none` is a borrow, of the instance
                // parameter when the function is a method, else of its
                // one pointer parameter (D134: one origin per call).
                let gir = self.symbols[si].gir
                if verdict.starts_with("unknown:") and gir.len() > 0:
                    let transfer = gir_fact(gir, "ret")
                    if transfer == "full":
                        verdict = "owned"
                        reason = "annotation: gir transfer-ownership=\"full\", the caller owns the return"
                    else if transfer == "none":
                        let inst = fd_i32(gir_fact(gir, "inst"))
                        let origin = if inst >= 0: inst else: self.fd_sole_pointer_param(si as i32)
                        if origin >= 0:
                            verdict = f"borrow:{origin}"
                            reason = "annotation: gir transfer-ownership=\"none\", " ++ (if inst >= 0: "a part of the instance parameter" else: "a part of its one pointer parameter")
                        else: verdict = "unknown:gir transfer-ownership=\"none\" names no single origin parameter"
                    else if transfer == "container": verdict = "unknown:gir transfer-ownership=\"container\": the caller owns the container and not its elements, which the facade language does not state"
                // The registry's `from F` / `returns borrow R from param N`
                // (D121 step 4), where nothing above settled the return.
                let registry = self.symbols[si].registry
                if verdict.starts_with("unknown:") and registry.len() > 0:
                    let kind = facts_kind(registry)
                    if kind == "owned":
                        verdict = "owned"
                        reason = "registry: " ++ facts_cite(registry)
                    else if kind.starts_with("borrow:"):
                        let origin = fd_i32(kind.slice(7, kind.len()))
                        if self.fd_param_is_pointer(si as i32, origin):
                            verdict = kind
                            reason = "registry: " ++ facts_cite(registry)
                        else: verdict = f"unknown:the registry's borrow origin, param {origin}, is not a pointer parameter"
                if verdict == "owned":
                    self.symbols[si].owns_return = 1
                    self.symbols[si].own_reason = if reason.starts_with("annotation:") or reason.starts_with("registry:"): reason else: "proof: " ++ reason ++ ", a fresh allocation never retained"
                    changed = true
                else if verdict.starts_with("borrow:"):
                    let members = fd_borrow_members(verdict)
                    self.symbols[si].borrow_from = members[0]
                    self.symbols[si].borrow_from2 = if members.len() > 1: members[1] else: -1
                    self.symbols[si].own_reason = if reason.starts_with("annotation:") or reason.starts_with("registry:"): reason else: "proof: " ++ reason
                    changed = true
                else: self.symbols[si].own_reason = verdict.slice(8, verdict.len()).to_owned()
        // WITH_DEBUG_MIGRATE_FACADE=1: every definition's evidence and
        // verdicts, for reading a verdict back to the line that gave it.
        if with_getenv_str("WITH_DEBUG_MIGRATE_FACADE").len() > 0:
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si as i32): continue
                var stores = ""
                var destroys = ""
                for pi in 0..self.symbols[si].param_ty.len():
                    stores = stores ++ (if self.symbols[si].param_stores[pi] != 0: "1" else: "0")
                    destroys = destroys ++ (if self.symbols[si].param_destroys[pi] != 0: "1" else: "0")
                eprint("facade: " ++ self.symbols[si].name ++ " -> " ++ self.symbols[si].ret_ty ++ (if self.symbols[si].header_declared != 0: " (declared)" else: " (internal)") ++ " stores=" ++ stores ++ " destroys=" ++ destroys ++ f" owns={self.symbols[si].owns_return} borrow_from={self.symbols[si].borrow_from}" ++ (if self.symbols[si].borrow_from2 >= 0: f",{self.symbols[si].borrow_from2}" else: "") ++ ": " ++ self.symbols[si].own_reason ++ (if self.symbols[si].gir.len() > 0: " gir=" ++ self.symbols[si].gir else: ""))
                for line in self.symbols[si].own_evidence.split("\n"):
                    if line.len() > 0: eprint("    " ++ line)
                for pi in 0..self.symbols[si].param_sinks.len():
                    if self.symbols[si].param_sinks[pi].len() > 0: eprint(f"    sinks of param {pi}: " ++ self.symbols[si].param_sinks[pi])

    // The pointer-to-record representations the corpus produces or
    // destroys, in first-seen order of the symbol table.
    fn fd_representations() -> List[str]:
        let out: List[str] = []
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si as i32): continue
            if self.symbols[si].owns_return != 0:
                let r = fd_record_pointee(self.symbols[si].ret_ty)
                if r.len() > 0 and not out.contains(r): out.push(r)
            for pi in 0..self.symbols[si].param_destroys.len():
                if self.symbols[si].param_destroys[pi] == 0: continue
                let r = fd_record_pointee(self.symbols[si].param_ty[pi])
                if r.len() > 0 and not out.contains(r): out.push(r)
        out

    fn fd_producers_of(record: &str) -> List[i32]:
        let out: List[i32] = []
        for si in 0..self.symbols.len():
            if self.symbols[si].kind == CiProjectSymbolKind.CIPS_FN and self.fd_subject(si as i32) and self.symbols[si].header_declared != 0 and self.symbols[si].owns_return != 0 and fd_record_pointee(self.symbols[si].ret_ty) == record: out.push(si as i32)
        out

    // The functions destroying a parameter of `record`; `unary` keeps those
    // whose only parameter it is.
    fn fd_destroyers_of(record: &str, unary: bool) -> List[i32]:
        let out: List[i32] = []
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si as i32) or self.symbols[si].header_declared == 0: continue
            let count = self.symbols[si].param_destroys.len()
            for pi in 0..count:
                if self.symbols[si].param_destroys[pi] != 0 and fd_record_pointee(self.symbols[si].param_ty[pi]) == record:
                    let is_unary = count == 1 and pi == 0
                    if is_unary == unary: out.push(si as i32)
                    break
        out

    // The `drop` of `record`: its one unary destroyer, or among several the
    // one the introspection file names as the record's free function
    // (D121 step 3); -1 when neither settles it (the registry's question).
    fn fd_drop_of(record: &str) -> i32:
        let unary = self.fd_destroyers_of(record, true)
        if unary.len() == 1: return unary[0]
        var named = -1
        for si in unary:
            if not self.symbols[si].gir.contains("drop=1"): continue
            if named >= 0: return -1
            named = si
        if named >= 0: return named
        // The registry's `drop F` (D121 step 4), below the file.
        for si in unary:
            if facts_kind(self.symbols[si].registry) != "drop": continue
            if named >= 0: return -1
            named = si
        named

    // A representation someone can own: a producer and a drop.
    fn fd_owned_record(record: &str) -> bool:
        self.fd_producers_of(record).len() > 0 and self.fd_drop_of(record) >= 0

    // The declared functions proven to return a borrow of `record` from a
    // modeled record (`origins`), retaining nothing. A borrowed value's
    // origin is bound per call (D134), so a borrow of a node from a node
    // (`xmlFirstElementChild`) is one candidate, its origin whatever the
    // caller holds.
    fn fd_borrow_candidates_from(record: &str, origins: &List[str]) -> List[i32]:
        let out: List[i32] = []
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si as i32) or self.symbols[si].header_declared == 0 or self.symbols[si].borrow_from < 0: continue
            if fd_record_pointee(self.symbols[si].ret_ty) != record or self.fd_retains_any(si as i32): continue
            if not origins.contains(fd_record_pointee(self.symbols[si].param_ty[self.symbols[si].borrow_from])): continue
            // D187: both origins of a two-parameter borrow are modeled.
            if self.symbols[si].borrow_from2 >= 0 and not origins.contains(fd_record_pointee(self.symbols[si].param_ty[self.symbols[si].borrow_from2])): continue
            if self.fd_presentable(si as i32, -1, true, origins): out.push(si as i32)
        out

    // The producers of `record` the draft can state as `from F`: owned
    // return, every parameter presentable over `modeled`.
    fn fd_presentable_producers_of(record: &str, modeled: &List[str]) -> List[i32]:
        let out: List[i32] = []
        for si in self.fd_producers_of(record):
            if self.fd_presentable(si, -1, true, modeled): out.push(si)
        out

    // The `destroys F` items of `record` the draft can state: the record is
    // F's first parameter (§16.2b.13), the return a value, the rest
    // presentable.
    fn fd_presentable_destroyers_of(record: &str, unary: bool, modeled: &List[str]) -> List[i32]:
        let out: List[i32] = []
        for si in self.fd_destroyers_of(record, unary):
            if self.symbols[si].param_destroys.len() > 0 and self.symbols[si].param_destroys[0] != 0 and fd_record_pointee(self.symbols[si].param_ty[0]) == record and self.fd_presentable(si, 0, false, modeled): out.push(si)
        out

    fn fd_borrow_candidates(record: &str) -> List[i32]:
        self.fd_borrow_candidates_from(record, self.fd_modeled_records())

    // The representations the draft can model: one unary destroyer, and
    // either a producer (an owned resource) or a proven borrow of it from a
    // modeled resource (a borrowed-only resource, libxml2's node shape): a
    // fixed point from the owned ones, so a chain of borrows reaches an
    // owner and a record borrowed only from itself is not a resource. A
    // representation the corpus destroys and never produces or lends is
    // not a resource here.
    fn fd_modeled_records() -> List[str]:
        let out: List[str] = []
        let all = self.fd_representations()
        var changed = true
        while changed:
            changed = false
            for record in all:
                if out.contains(record) or self.fd_drop_of(record) < 0: continue
                if self.fd_presentable_producers_of(record, out).len() > 0 or self.fd_borrow_candidates_from(record, out).len() > 0:
                    out.push(record)
                    changed = true
        out

    // #3123: every typedef of `void` is one representation to the checker
    // (`*mut c_void`), so an operation on a handle of one names its resource:
    // the `of` line for the first parameter the header spells through a
    // modeled void typedef, "" when there is none.
    fn fd_void_typedef_of(si: i32, modeled: &List[str]) -> str:
        for p in self.symbols[si].param_ty:
            let pointee = fd_record_pointee(p)
            if pointee.len() > 0 and modeled.contains(pointee) and self.void_typedefs.contains(pointee):
                return "        of " ++ fd_resource_name(pointee) ++ "    // the header spells the parameter `" ++ pointee ++ " *`\n"
        ""

    // The facade draft: what the proofs establish, every clause with its
    // proof beside it.
    mut fn facade_draft(name: &str) -> str:
        // D198: which records have identity, before any parameter is judged.
        self.fd_draw_identity_records()
        let modeled = self.fd_modeled_records()
        self.presented = List.new()
        var text = "// Facade draft for " ++ name ++ ", proven from the package's own source (§16.2b.15, D121).\n// Every clause records its proof; a project may override any single fact.\n"
        // §16.2b.15: the roles the registry states for function-pointer
        // fields; a proof below that says "a fresh allocation" or "frees"
        // over a call through one rests on these.
        if self.field_role_text.len() > 0: text = text ++ "// Function-pointer fields, as the registry states them:\n" ++ self.field_role_text
        text = text ++ "c facade " ++ name ++ ":\n"
        if self.registry_utf8.len() > 0: text = text ++ "    text utf8    // registry: " ++ self.registry_utf8 ++ "\n"
        if self.registry_threads.len() > 0: text = text ++ "    runs threads    // registry: " ++ self.registry_threads ++ "\n"
        for record in modeled:
            text = text ++ "    resource " ++ fd_resource_name(record) ++ " wraps *mut " ++ record ++ "\n"
            let producers = self.fd_presentable_producers_of(record, modeled)
            for si in producers:
                self.presented.push(si)
                text = text ++ "        from " ++ self.symbols[si].name ++ "    // " ++ self.symbols[si].own_reason ++ "\n"
            let drop = self.fd_drop_of(record)
            self.presented.push(drop)
            text = text ++ "        drop " ++ self.symbols[drop].name ++ "    // " ++ self.fd_destroy_reason(drop, "param 0") ++ "\n"
            for si in self.fd_presentable_destroyers_of(record, true, modeled):
                if si != drop:
                    self.presented.push(si)
                    text = text ++ "        destroys " ++ self.symbols[si].name ++ "    // " ++ self.fd_destroy_reason(si, "its " ++ record ++ " parameter") ++ "\n"
            for si in self.fd_presentable_destroyers_of(record, false, modeled):
                self.presented.push(si)
                text = text ++ "        destroys " ++ self.symbols[si].name ++ "    // " ++ self.fd_destroy_reason(si, "its " ++ record ++ " parameter") ++ "\n"
        // Borrows: a function that retains a pointer argument is not a lend
        // (fd_borrow_candidates). A borrowed value's origin is bound at each
        // call (D134, §16.2b.6), so one representation may be borrowed from
        // several origins.
        // Each fn block carries the registry's presentation facts for its
        // function (D121 step 6); `blocks` keeps one block per function.
        let blocks: List[i32] = []
        for record in modeled:
            let candidates = self.fd_borrow_candidates(record)
            for si in candidates:
                self.presented.push(si)
                blocks.push(si)
                text = text ++ "    fn " ++ self.symbols[si].name ++ "\n        returns borrow " ++ fd_resource_name(record) ++ " from " ++ self.fd_borrow_origin_text(si) ++ "    // " ++ self.symbols[si].own_reason ++ "\n" ++ self.fd_registry_presentation_lines(si)
        // Lends are the default (§16.2b.5); stating each records the proof
        // and presents the operation on its resource.
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si as i32): continue
            // D198: an operation the registry states on a by-value resource
            // is that resource's; its block is the registry's.
            if self.registry_value_fns.contains(self.symbols[si].name):
                if self.symbols[si].header_declared != 0: self.presented.push(si as i32)
                continue
            if self.fd_is_lend(si as i32, modeled):
                self.presented.push(si as i32)
                blocks.push(si as i32)
                let verdict = self.fd_lend_verdict(si as i32, modeled)
                // D198: an operation over value records alone lends no
                // resource; its clauses are its item.
                let lends = self.fd_takes_modeled_resource(si as i32, modeled)
                text = text ++ "    fn " ++ self.symbols[si].name ++ "\n" ++ self.fd_void_typedef_of(si as i32, modeled) ++ (if lends: "        lend    // " ++ verdict.slice(verdict.find("(") + 1, verdict.len() - 1) ++ "\n" else: "") ++ self.fd_registry_presentation_lines(si as i32)
            else if self.symbols[si].header_declared != 0 and self.symbols[si].owns_return == 0 and self.symbols[si].borrow_from < 0 and fd_record_pointee(self.symbols[si].ret_ty).len() == 0 and self.fd_lend_verdict(si as i32, modeled).starts_with("consumes param "):
                self.presented.push(si as i32)
                blocks.push(si as i32)
                let consumed = self.fd_consumed_param(si as i32, modeled)
                text = text ++ "    fn " ++ self.symbols[si].name ++ f"\n        consumes param {consumed}    // " ++ self.fd_consumed_reason(si as i32, consumed) ++ "\n" ++ self.fd_registry_presentation_lines(si as i32)
            else if self.symbols[si].header_declared != 0 and self.fd_returns_literal_text(si as i32, 0) and self.fd_lend_verdict(si as i32, modeled) == "value-only call":
                // #3127: a value-only call that returns static text has one
                // fact to state, its return's.
                self.presented.push(si as i32)
                blocks.push(si as i32)
                text = text ++ "    fn " ++ self.symbols[si].name ++ "\n" ++ self.fd_registry_presentation_lines(si as i32)
        // A producer or a destroyer has no fn block above; the registry's
        // presentation facts on one (`xmlReadFile`'s nullable encoding) get
        // their own.
        for si in self.presented:
            if blocks.contains(si) or self.symbols[si].registry_more.len() == 0: continue
            blocks.push(si)
            text = text ++ "    fn " ++ self.symbols[si].name ++ "\n" ++ self.fd_registry_presentation_lines(si)
        text ++ self.registry_value_text

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
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or not self.fd_subject(si as i32): continue
            if self.symbols[si].header_declared == 0:
                internal = internal + 1
                continue
            total = total + 1
            let fname = with_str_clone_ref(self.symbols[si].name)
            let ret = fd_record_pointee(self.symbols[si].ret_ty)
            var verdict = ""
            let unpresentable = if self.symbols[si].owns_return != 0 and modeled.contains(ret): self.fd_unpresentable_param(si as i32, -1, modeled) else: -1
            if self.symbols[si].owns_return != 0 and modeled.contains(ret) and self.symbols[si].variadic != 0:
                verdict = "raw: owned producer of " ++ fd_resource_name(ret) ++ ", but variadic, which the facade does not describe"
            else if unpresentable >= 0:
                verdict = "raw: owned producer of " ++ fd_resource_name(ret) ++ f", but param {unpresentable} is " ++ self.symbols[si].param_ty[unpresentable] ++ ", which the facade does not describe"
            else if self.symbols[si].owns_return != 0 and modeled.contains(ret):
                verdict = "owned producer of " ++ fd_resource_name(ret) ++ " (" ++ self.symbols[si].own_reason ++ ")"
                // The proofs' unproven retention of a parameter, which a
                // registry producer's fact covers, is still said.
                if self.symbols[si].own_reason.starts_with("registry:") and self.fd_retains_any(si as i32):
                    for pi in 0..self.symbols[si].param_stores.len():
                        if self.symbols[si].param_stores[pi] != 0:
                            verdict = verdict ++ f"; the proofs could not clear param {pi} (" ++ self.fd_retain_reason(si as i32, pi as i32, 0) ++ ")"
                            break
            else if self.symbols[si].owns_return != 0:
                // #3176: with a drop proven, the gap is elsewhere: a
                // parameter the facade does not describe (curl_mime_init's
                // `CURL *`), said as such; the drop message was a lie.
                let dropped_by = if ret.len() > 0: self.fd_drop_of(ret) else: -1
                let undescribed = if dropped_by >= 0: self.fd_unpresentable_param(si as i32, -1, modeled) else: -1
                if undescribed >= 0: verdict = "raw: owned " ++ self.symbols[si].ret_ty ++ " (" ++ self.symbols[si].own_reason ++ f"), dropped by " ++ self.symbols[dropped_by].name ++ f", but param {undescribed} is " ++ self.symbols[si].param_ty[undescribed] ++ ", which the facade does not describe"
                else if dropped_by >= 0: verdict = "raw: owned " ++ self.symbols[si].ret_ty ++ " (" ++ self.symbols[si].own_reason ++ "), dropped by " ++ self.symbols[dropped_by].name ++ ", but the record is not modeled"
                else: verdict = "raw: owned " ++ self.symbols[si].ret_ty ++ " (" ++ self.symbols[si].own_reason ++ "), but the package has no single destroyer of it: a registry fact names one"
            else if self.fd_retains_any(si as i32) and not self.fd_destroys_any(si as i32):
                var retained = 0
                for pi in 0..self.symbols[si].param_stores.len():
                    if self.symbols[si].param_stores[pi] != 0:
                        retained = pi as i32
                        break
                // Retained, and the introspection file says the callee
                // takes it: consumed (the lend verdict's rule).
                let consumed = self.fd_consumed_param(si as i32, modeled)
                if ret.len() == 0 and consumed == retained: verdict = self.fd_lend_verdict(si as i32, modeled)
                else: verdict = self.fd_retains_verdict(si as i32, retained)
            else if self.symbols[si].borrow_from >= 0 and (self.fd_destroys_any(si as i32) or self.fd_retains_any(si as i32)):
                // A borrow of what it also frees or keeps (libxml2's
                // xmlTextMerge returns one node and frees the other): never
                // presented (fd_borrow_candidates_from), and said so, not
                // counted as a borrow.
                let frees = self.fd_destroys_any(si as i32)
                let marks = if frees: &self.symbols[si].param_destroys else: &self.symbols[si].param_stores
                var held = 0
                for pi in 0..marks.len():
                    if marks[pi] != 0:
                        held = pi as i32
                        break
                verdict = "raw: " ++ self.symbols[si].own_reason ++ ", but it " ++ (if frees: "frees" else: "retains") ++ f" param {held}, which a borrowed return cannot state"
            else if self.symbols[si].borrow_from >= 0:
                let origin = fd_record_pointee(self.symbols[si].param_ty[self.symbols[si].borrow_from])
                let origin2_modeled = self.symbols[si].borrow_from2 < 0 or modeled.contains(fd_record_pointee(self.symbols[si].param_ty[self.symbols[si].borrow_from2]))
                if modeled.contains(ret) and modeled.contains(origin) and origin2_modeled: verdict = "borrows " ++ fd_resource_name(ret) ++ " from " ++ self.fd_borrow_origin_text(si as i32) ++ " (" ++ self.symbols[si].own_reason ++ ")"
                else: verdict = "raw: " ++ self.symbols[si].own_reason ++ ", but " ++ self.fd_borrow_origin_text(si as i32) ++ " or the return is not a modeled resource"
            else if ret.len() > 0:
                verdict = "raw: returns " ++ self.symbols[si].ret_ty ++ " unproven: " ++ self.symbols[si].own_reason
            else: verdict = self.fd_lend_verdict(si as i32, modeled)
            // D198: an operation over value records says so, and one left raw
            // for a record pointer says why it is no value record.
            verdict = self.fd_value_record_verdict(si as i32, verdict, modeled)
            if verdict.starts_with("raw:"): raw = raw + 1 else: safe = safe + 1
            // The annotations the library ships, for the reader: nullability
            // ones are header facts c_import reads directly (§16.2b.8).
            let attrs = self.symbols[si].attrs
            if attrs.len() > 0: verdict = verdict ++ " [attributes: " ++ attrs.replace(";", " ").trim() ++ "]"
            verdict = verdict ++ self.fd_gir_summary(si as i32) ++ self.fd_registry_summary(si as i32)
            lines = lines ++ "  " ++ fname ++ ": " ++ verdict ++ "\n"
        var head = "facade " ++ name ++ f": {total} functions, {safe} presented safely, {raw} raw" ++ (if internal > 0: f"; {internal} internal (no prototype declares them)" else: "") ++ "\n"
        for record in self.fd_representations():
            if modeled.contains(record): continue
            let producers = self.fd_producers_of(record).len()
            let unary = self.fd_destroyers_of(record, true).len()
            if producers == 0: head = head ++ "  " ++ record ++ ": destroyed but never produced here; no resource\n"
            else if unary == 0: head = head ++ "  " ++ record ++ f": {producers} producer(s) and no unary destroyer in the package; a registry fact names the drop\n"
            else if unary == 1:
                // #3176: produced and dropped, yet not a resource: every
                // producer takes a parameter the facade does not describe.
                let first = self.fd_producers_of(record)[0]
                let bad = self.fd_unpresentable_param(first, -1, modeled)
                let why = if bad >= 0: f"param {bad} of " ++ self.symbols[first].name ++ " is " ++ self.symbols[first].param_ty[bad] else: "its producers are not presentable"
                head = head ++ "  " ++ record ++ f": {producers} producer(s) and a destroyer, but no resource: " ++ why ++ ", which the facade does not describe\n"
            else: head = head ++ "  " ++ record ++ f": {producers} producer(s) and {unary} unary destroyers; a registry fact names the drop\n"
        head ++ lines

// The field of a `Record.field` (or `*Record.field`) callee.
fn fd_field_of(record_field: &str) -> str:
    let dot = record_field.rfind(".")
    if dot >= 0: record_field.slice(dot + 1, record_field.len()) else: record_field.to_owned()
