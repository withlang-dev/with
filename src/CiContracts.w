// CiContracts — D159: the contracts a migrated function's own body proves,
// drawn once over the whole corpus and written as the contracts artifact
// (`with migrate --emit-contracts FILE`, one line per defined function:
// `name<TAB>verdict[,verdict…]`). Step 1 of
// docs/proposals/migrator-contracts-plan.md: the verdicts are recorded and
// diffed; nothing changes a signature yet.
//
// The evidence is the body's (CImport.w ci_body_contract_evidence) joined
// with D121's ownership proofs (CiFacadeDraft.w resolve_ownership:
// `param_stores`, `param_destroys`, `borrow_from`). Every verdict is one
// whose failure can at worst reject a valid program (D51's test, Law 4):
//
//   receiver-mut:<R>     parameter 0 is `*mut R`, R a record, and the body
//                        writes through it, itself or through a corpus
//                        callee proven to (inference a1)
//   out:<i>:<T>          parameter i > 0 is `*mut T`, T a scalar, written
//                        whole on every returning path before any other
//                        use (inference a2); `out-record:<i>:<R>` the same
//                        for a record, whose copy class step 2 checks
//   owned:<i>            the body stores parameter i into a field of the
//                        receiver's record AND a corpus function frees that
//                        field (inference b, both halves)
//   stored-unknown:<i>   stored, no corpus destroyer frees it: stays unsafe
//   ret-from:<i>         every pointer returned is a part of parameter i
//                        (inference c)
//   unproved:<i>:<why>   anything else, with the unproved point named
//   plain                no pointer parameter
//   variadic / unanalyzable
//
// A read-only first pointer is `unproved: read only`: a `&self` receiver is
// not in the ruling's list.

use CiIR
use CImport
use CiFacadeDraft
use std.algorithms
use std.string.parse
use rt.rt_core

fn ct_is_pointer(ty: &str) -> bool: ty.trim().starts_with("*")

// `R` for `*mut R` / `*const R` when R is a record name; "" for a pointer
// to a pointer, to a scalar, to `c_void`, a function pointer, an array.
fn ct_record_pointee(ty: &str) -> str:
    let t = ty.trim()
    var rest = ""
    if t.starts_with("*mut "): rest = t.slice(5, t.len()).trim().to_owned()
    else if t.starts_with("*const "): rest = t.slice(7, t.len()).trim().to_owned()
    else: return ""
    if rest.len() == 0 or rest[0] == '*' or rest[0] == '[' or rest[0] == '(' or rest.starts_with("fn") or rest.starts_with("extern") or rest.starts_with("unsafe"): return ""
    if ct_is_scalar(rest): return ""
    rest

fn ct_is_scalar(name: &str) -> bool:
    name.starts_with("c_") or name == "u8" or name == "i8" or name == "u16" or name == "i16" or name == "u32" or name == "i32" or name == "u64" or name == "i64" or name == "f32" or name == "f64" or name == "bool" or name == "isize" or name == "usize"

// The pointee of `*mut T`, "" when `ty` is not a single-level pointer.
fn ct_pointee(ty: &str) -> str:
    let t = ty.trim()
    let rest = if t.starts_with("*mut "): t.slice(5, t.len()).trim().to_owned() else if t.starts_with("*const "): t.slice(7, t.len()).trim().to_owned() else: ""
    if rest.len() == 0 or rest[0] == '*' or rest[0] == '[' or rest[0] == '(' or rest.starts_with("fn") or rest.starts_with("extern") or rest.starts_with("unsafe"): return ""
    rest

fn ct_has_line(evidence: &str, line: &str) -> bool:
    for l in evidence.split("\n"):
        if l == line: return true
    false

impl CiProject:
    // The pointer parameters each function writes through: a direct write
    // (`mutparam:`), or an argument passed to a corpus callee at a position
    // that callee writes through (a least fixed point; the order of units
    // never enters).
    mut fn resolve_param_mutation():
        let n = self.symbols.len()
        for si in 0..n:
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            while self.symbols[si].param_mutates.len() < self.symbols[si].param_ty.len(): self.symbols[si].param_mutates.push(0)
            let count = self.symbols[si].param_mutates.len()
            for line in self.symbols[si].contract_evidence.split("\n"):
                if not line.starts_with("mutparam:"): continue
                let pi = parse(line.slice(9, line.len()))
                if pi >= 0 and pi < count: self.symbols[si].param_mutates[pi] = 1
        var changed = true
        while changed:
            changed = false
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
                let count = self.symbols[si].param_mutates.len()
                for pi in 0..count:
                    if self.symbols[si].param_mutates[pi] != 0 or not ct_is_pointer(self.symbols[si].param_ty[pi]): continue
                    for sink in self.symbols[si].param_sinks[pi].split(";"):
                        if not sink.contains(":"): continue
                        let kv = sink.split(":")
                        let callee = self.find_symbol(CiProjectSymbolKind.CIPS_FN, kv[0])
                        if callee < 0 or self.symbols[callee].has_definition == 0: continue
                        let index = parse(kv[1])
                        if index < self.symbols[callee].param_mutates.len() and self.symbols[callee].param_mutates[index] != 0:
                            self.symbols[si].param_mutates[pi] = 1
                            changed = true
                            break

    // Whether a corpus function frees field `member` of a `*mut record`
    // parameter: `free(p->member)` in its body, or `p->member` handed to a
    // corpus callee at a position that callee destroys (D121's proof).
    fn ct_destroyer_frees_member(record: &str, member: &str) -> bool:
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            for pi in 0..self.symbols[si].param_ty.len():
                if ct_record_pointee(self.symbols[si].param_ty[pi]) != record: continue
                if ct_has_line(self.symbols[si].contract_evidence, f"freesmember:{pi}:" ++ member): return true
                for line in self.symbols[si].contract_evidence.split("\n"):
                    if not line.starts_with(f"memberarg:{pi}:" ++ member ++ ":"): continue
                    let parts = line.split(":")
                    if parts.len() != 5: continue
                    let callee = self.find_symbol(CiProjectSymbolKind.CIPS_FN, parts[3])
                    if callee < 0 or self.symbols[callee].has_definition == 0: continue
                    let index = parse(parts[4])
                    if index < self.symbols[callee].param_destroys.len() and self.symbols[callee].param_destroys[index] != 0: return true
        false

    // The verdicts of one defined function, as the artifact prints them.
    fn ct_verdicts(si: i32) -> str:
        if self.symbols[si].unanalyzable != 0 or ct_has_line(self.symbols[si].contract_evidence, "unanalyzable"): return "unanalyzable"
        var out: List[str] = List.new()
        let evidence = with_str_clone_ref(self.symbols[si].contract_evidence)
        let n = self.symbols[si].param_ty.len()
        for pi in 0..n:
            let ty = with_str_clone_ref(self.symbols[si].param_ty[pi])
            if not ct_is_pointer(ty): continue
            let record = ct_record_pointee(ty)
            let mutates = pi < self.symbols[si].param_mutates.len() and self.symbols[si].param_mutates[pi] != 0
            if pi == 0 and record.len() > 0 and mutates:
                out.push("receiver-mut:" ++ record)
                continue
            if pi > 0 and ct_has_line(evidence, f"outfull:{pi}"):
                let pointee = ct_pointee(ty)
                if record.len() > 0: out.push(f"out-record:{pi}:" ++ record)
                else if pointee.len() > 0 and ct_is_scalar(pointee): out.push(f"out:{pi}:" ++ pointee)
                else: out.push(f"unproved:{pi}:out-parameter of a type the copy cannot carry")
                continue
            if pi < self.symbols[si].param_stores.len() and self.symbols[si].param_stores[pi] != 0:
                var owned = false
                for line in evidence.split("\n"):
                    if not line.starts_with("fieldstore:"): continue
                    let parts = line.split(":")
                    if parts.len() != 4 or parse(parts[2]) != pi: continue
                    let owner = parse(parts[1])
                    if owner < 0 or owner >= n: continue
                    let owner_record = ct_record_pointee(self.symbols[si].param_ty[owner])
                    if owner_record.len() > 0 and self.ct_destroyer_frees_member(owner_record, parts[3]): owned = true
                out.push(if owned: f"owned:{pi}" else: f"stored-unknown:{pi}")
                continue
            if self.symbols[si].borrow_from == pi:
                out.push(f"ret-from:{pi}")
                continue
            // A pointer the body never writes through is read only; one it
            // writes through is named by how the out-parameter proof failed,
            // or as a second mutated pointer.
            var reason = "read only"
            if mutates:
                reason = if pi == 0: "mutated through a pointer to no corpus record" else: "mutated through a second pointer"
                let cond_prefix = f"outcond:{pi}:"
                for line in evidence.split("\n"):
                    if line.starts_with(cond_prefix): reason = "out-parameter " ++ line.slice(cond_prefix.len(), line.len())
            out.push(f"unproved:{pi}:" ++ reason)
        if self.symbols[si].variadic != 0: out.push("variadic")
        if out.len() == 0: return "plain"
        var text = ""
        for vi in 0..out.len():
            text = text ++ (if vi == 0: "" else: ",") ++ out[vi]
        text

    // D159: every defined function's contract, drawn once after the whole
    // corpus is scanned and D121's ownership proofs are in.
    mut fn resolve_contracts():
        self.resolve_param_mutation()
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            self.symbols[si].contract = self.ct_verdicts(si as i32)

    // The artifact: one line per defined function, sorted by name.
    fn contracts_tsv() -> str:
        // Sorted by name, by insertion: a compiler module calling
        // `List[str].sort()` does not link stage1 (#2618, `undefined symbol:
        // ___closure`); the list is small.
        var names: List[str] = List.new()
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            names.push(with_str_clone_ref(self.symbols[si].name))
        for i in 1..names.len():
            var j = i
            while j > 0 and names[j] < names[j - 1]:
                let later: str = names[j]
                names[j] = names[j - 1]
                names[j - 1] = later
                j = j - 1
        var text = ""
        for name in names:
            let si = self.find_symbol(CiProjectSymbolKind.CIPS_FN, name)
            if si < 0: continue
            text = text ++ name ++ "\t" ++ self.symbols[si].contract ++ "\n"
        text
