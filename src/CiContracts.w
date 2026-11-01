// CiContracts — D159: the contracts a migrated function's own body proves,
// drawn once over the whole corpus and written as the contracts artifact
// (`with migrate --emit-contracts FILE`, one line per defined function:
// `name<TAB>verdict[,verdict…]`), and the shape each proved function is
// printed in (migrator-contracts-plan.md, steps 1 and 2).
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
//
// Step 2, the shape (resolve_method_shapes): a function whose first
// parameter is `receiver-mut:R` on a record the corpus declares, with every
// other pointer parameter an out-parameter, is printed as the method
// `pub mut fn <m>` of `impl R:` (CiMigrate.w ci_migrate_push_method); the
// out-parameter comes back as the return, `T` or `(status, T)`; a return
// that is the receiver itself (`return self`, the one source that is a part
// of it for certain) is `-> &R from self`. Every other function keeps its
// raw signature. A corpus call to a method is printed as one (CImport.w
// lower_method_call_ir).

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

// Functions outside the corpus that read their pointer arguments and write
// nothing (Amendment 2): an explicit list, never a name's guess. `memset`
// and `memcpy` write; `free` destroys; `printf` is not here either.
fn ct_is_pure_reader(name: &str) -> bool:
    name == "memcmp" or name == "memchr" or name == "strlen" or name == "strcmp" or name == "strncmp"

// The method name for C function `c_name` on `record`: the C name less the
// record's prefix (`stc_word_stack_push` on `stc_word_stack` is `push`,
// `GHashTable`'s `g_hash_table_` prefix the same way), the whole C name
// when it has no such prefix; reserved words escape as everywhere else.
fn ct_method_name(c_name: &str, record: &str) -> str:
    var method = ci_strip_snake_prefix(c_name, record ++ "_")
    if method.len() == 0: method = ci_strip_snake_prefix(c_name, ci_compute_snake_prefix(record))
    // An iterator record's functions carry the collection's prefix
    // (`stc_word_stack_next` on `stc_word_stack_iter`): `next`.
    if method.len() == 0 and record.ends_with("_iter"): method = ci_strip_snake_prefix(c_name, record.slice(0, record.len() - 4))
    if method.len() == 0: method = c_name.to_owned()
    ci_escape_reserved(method)

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
            while self.symbols[si].param_array.len() < self.symbols[si].param_ty.len(): self.symbols[si].param_array.push(0)
            let count = self.symbols[si].param_mutates.len()
            for line in self.symbols[si].contract_evidence.split("\n"):
                if line.starts_with("mutparam:"):
                    let pi = parse(line.slice(9, line.len()))
                    if pi >= 0 and pi < count: self.symbols[si].param_mutates[pi] = 1
                else if line.starts_with("arrayparam:"):
                    let pi = parse(line.slice(11, line.len()))
                    if pi >= 0 and pi < count: self.symbols[si].param_array[pi] = 1
                else if line.starts_with("mutlocal:"):
                    // Amendment 2: a write through a local that aliases a
                    // parameter is a write through the parameter.
                    let pi = self.fd_local_alias_param(si as i32, line.slice(9, line.len()))
                    if pi >= 0 and pi < count: self.symbols[si].param_mutates[pi] = 1
        // Through the corpus callees: a parameter handed to a position a
        // callee writes through is written through; one handed to a
        // position a callee indexes is an array.
        var changed = true
        while changed:
            changed = false
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
                let count = self.symbols[si].param_mutates.len()
                for pi in 0..count:
                    if not ct_is_pointer(self.symbols[si].param_ty[pi]): continue
                    if self.symbols[si].param_mutates[pi] != 0 and self.symbols[si].param_array[pi] != 0: continue
                    for sink in self.symbols[si].param_sinks[pi].split(";"):
                        if not sink.contains(":"): continue
                        let kv = sink.split(":")
                        let callee = self.find_symbol(CiProjectSymbolKind.CIPS_FN, kv[0])
                        if callee < 0 or self.symbols[callee].has_definition == 0: continue
                        let index = parse(kv[1])
                        if self.symbols[si].param_mutates[pi] == 0 and index < self.symbols[callee].param_mutates.len() and self.symbols[callee].param_mutates[index] != 0:
                            self.symbols[si].param_mutates[pi] = 1
                            changed = true
                        if self.symbols[si].param_array[pi] == 0 and index < self.symbols[callee].param_array.len() and self.symbols[callee].param_array[index] != 0:
                            self.symbols[si].param_array[pi] = 1
                            changed = true
        // The read side (Amendment 2): a pointer parameter the body provably
        // never writes through — not mutated (aliases and corpus callees
        // included), not indexed, not stored, no part of it freed, not cast
        // away from `const` — whose every sink is a corpus position proved
        // read-only or a pure reader. A greatest fixed point: every
        // candidate is read-only until one of its sinks says otherwise.
        for si in 0..n:
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            while self.symbols[si].param_readonly.len() < self.symbols[si].param_ty.len(): self.symbols[si].param_readonly.push(0)
            for pi in 0..self.symbols[si].param_ty.len():
                self.symbols[si].param_readonly[pi] = if ct_is_pointer(self.symbols[si].param_ty[pi]) and self.ct_read_only_local(si as i32, pi).len() == 0: 1 else: 0
        var shrinking = true
        while shrinking:
            shrinking = false
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
                for pi in 0..self.symbols[si].param_readonly.len():
                    if self.symbols[si].param_readonly[pi] != 0 and self.ct_sinks_refusal(si as i32, pi).len() > 0:
                        self.symbols[si].param_readonly[pi] = 0
                        shrinking = true

    // Why parameter `pi` is not read-only by the body's own operations ("" when
    // it is): the local half of Amendment 2's proof.
    fn ct_read_only_local(si: i32, pi: isize) -> str:
        if pi < self.symbols[si].param_mutates.len() and self.symbols[si].param_mutates[pi] != 0: return "written through"
        if pi < self.symbols[si].param_array.len() and self.symbols[si].param_array[pi] != 0: return "indexed as an array"
        if pi < self.symbols[si].param_stores.len() and self.symbols[si].param_stores[pi] != 0: return "stored"
        let const_param = self.symbols[si].param_ty[pi].trim().starts_with("*const ")
        for line in self.symbols[si].contract_evidence.split("\n"):
            if line.starts_with(f"freesmember:{pi}:"): return "frees a part of it"
            if const_param and line.starts_with(f"castaway:{pi}:*mut "): return "casts away const"
        ""

    // Why a sink of parameter `pi` may write through it ("" when none can):
    // a corpus callee not proved read-only at that position, or a function
    // outside the corpus that is not on the pure list. The callee half of
    // Amendment 2's proof; the locals that alias the parameter count too.
    fn ct_sinks_refusal(si: i32, pi: isize) -> str:
        var sinks: List[str] = List.new()
        for sink in self.symbols[si].param_sinks[pi].split(";"):
            if sink.len() > 0: sinks.push(sink)
        for line in self.symbols[si].own_evidence.split("\n"):
            if not line.starts_with("localsink:"): continue
            let parts = line.split(":")
            if parts.len() == 4 and self.fd_local_alias_param(si, parts[1]) == pi: sinks.push(parts[2] ++ ":" ++ parts[3])
        for line in self.symbols[si].contract_evidence.split("\n"):
            if not line.starts_with(f"memberarg:{pi}:"): continue
            let parts = line.split(":")
            if parts.len() == 5: sinks.push(parts[3] ++ ":" ++ parts[4])
        for sink in sinks:
            if not sink.contains(":"): return "stored"
            let kv = sink.split(":")
            let callee = self.find_symbol(CiProjectSymbolKind.CIPS_FN, kv[0])
            if callee >= 0 and self.symbols[callee].has_definition != 0:
                let index = parse(kv[1])
                if index < self.symbols[callee].param_readonly.len() and self.symbols[callee].param_readonly[index] != 0: continue
                return kv[0] ++ " may write through it"
            if ct_is_pure_reader(kv[0]): continue
            return kv[0] ++ " is outside the corpus and not a known pure reader"
        ""

    // Whether every `return` of the body hands back parameter `pi` itself or
    // the address of one of its members (inference c, Amendment 2's tightening):
    // the walker's `retaddr:` lines account for every return.
    fn ct_ret_from(si: i32, pi: isize) -> bool:
        var returns = 0
        for line in self.symbols[si].own_evidence.split("\n"):
            if line.starts_with("ret:"): returns = returns + 1
        var parts = 0
        for line in self.symbols[si].contract_evidence.split("\n"):
            if line == f"retaddr:{pi}": parts = parts + 1
        returns > 0 and parts == returns and not self.ct_returns_null(si)

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
            let readonly = pi < self.symbols[si].param_readonly.len() and self.symbols[si].param_readonly[pi] != 0
            if pi == 0 and record.len() > 0 and (mutates or readonly):
                // A handle the body accepts as NULL, or a corpus caller
                // passes NULL (D107's evidence), is a nullable argument, not
                // a receiver: a method's `self` is never NULL.
                let nullable = (pi < self.symbols[si].param_tested.len() and self.symbols[si].param_tested[pi] != 0) or (pi < self.symbols[si].param_null_caller.len() and self.symbols[si].param_null_caller[pi].len() > 0) or (pi < self.symbols[si].param_nullable.len() and self.symbols[si].param_nullable[pi] != 0)
                if nullable:
                    out.push(f"unproved:{pi}:NULL is an accepted argument")
                    continue
                // A handle the body indexes or steps (`p[k]`, `p + k`), itself
                // or through a corpus callee, is an array of records, not the
                // one a `self` would be.
                if pi < self.symbols[si].param_array.len() and self.symbols[si].param_array[pi] != 0:
                    out.push("unproved:0:indexed as an array")
                    continue
                // (c) beside the receiver: the return is the receiver itself
                // or the address of one of its members.
                let ret_part = ct_is_pointer(self.symbols[si].ret_ty) and self.ct_ret_from(si, 0)
                if mutates:
                    out.push("receiver-mut:" ++ record)
                    if ret_part: out.push("ret-from:0")
                    continue
                // Amendment 2: the read receiver may not return a pointer
                // derived from itself unless (c) carries the origin; the
                // view would otherwise outlive the borrow.
                if ct_is_pointer(self.symbols[si].ret_ty) and not ret_part:
                    out.push("unproved:0:returns a pointer the receiver's view cannot carry")
                    continue
                out.push("receiver:" ++ record)
                if ret_part: out.push("ret-from:0")
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
            if ct_is_pointer(self.symbols[si].ret_ty) and self.ct_ret_from(si, pi):
                out.push(f"ret-from:{pi}")
                continue
            if self.symbols[si].borrow_from == pi:
                // The ownership proof's borrow is broader than a view: a
                // pointer loaded from a field, arithmetic on one, or a NULL
                // on some path (which that proof skips) is no part of the
                // parameter for certain.
                out.push(f"unproved:{pi}:returns a pointer loaded from the parameter")
                continue
            // A pointer the body never writes through is read only; one it
            // writes through is named by how the out-parameter proof failed,
            // or as a second mutated pointer. A first parameter that failed
            // the read receiver's proof names the failing condition.
            var reason = "read only"
            if pi == 0 and record.len() > 0 and not mutates:
                let local = self.ct_read_only_local(si, 0)
                reason = if local.len() > 0: local else: self.ct_sinks_refusal(si, 0)
                if reason.len() == 0: reason = "read only"
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
        self.resolve_handle_nullability()
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            self.symbols[si].contract = self.ct_verdicts(si as i32)
        self.resolve_method_shapes()

    // D107's closure for the handle (the first pointer parameter): it
    // accepts NULL when its body tests it and continues, a corpus caller
    // passes NULL, or it is forwarded untested to a corpus parameter that
    // accepts NULL or to a function defined outside the corpus. Without
    // the forwarding step the verdict depended on which program the unit
    // was migrated with: c-algorithms' `sortedarray_remove` hands its
    // handle to `sortedarray_remove_range`, which tests it; only the
    // sortedarray test program passes NULL directly, so it was a method
    // in every other program and a raw function in that one (the shared
    // engine/ layout refused the corpus). The verdict is a function of the
    // evidence alone, never of the order of units.
    mut fn resolve_handle_nullability():
        let n = self.symbols.len()
        for si in 0..n:
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].param_ty.len() == 0: continue
            if not ct_is_pointer(self.symbols[si].param_ty[0]) or ct_record_pointee(self.symbols[si].param_ty[0]).len() == 0: continue
            self.symbols[si].grow_params(1)
            if self.symbols[si].param_fn_ptr[0] != 0: continue
            if self.symbols[si].param_tested[0] != 0 or self.symbols[si].param_null_caller[0].len() > 0:
                self.symbols[si].param_nullable[0] = 1
        var changed = true
        while changed:
            changed = false
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].param_ty.len() == 0: continue
                if not ct_is_pointer(self.symbols[si].param_ty[0]) or ct_record_pointee(self.symbols[si].param_ty[0]).len() == 0: continue
                if self.symbols[si].param_fn_ptr[0] != 0 or self.symbols[si].param_nullable[0] != 0: continue
                for sink in self.symbols[si].param_sinks[0].split(";"):
                    if not sink.contains(":"): continue
                    let kv = sink.split(":")
                    let callee = self.find_symbol(CiProjectSymbolKind.CIPS_FN, kv[0])
                    if callee < 0: continue   // a system prototype: D102 non-null
                    let index = parse(kv[1])
                    var accepts = self.symbols[callee].has_definition == 0
                    if not accepts and index < self.symbols[callee].param_nullable.len():
                        accepts = self.symbols[callee].param_nullable[index] != 0 or self.symbols[callee].param_tested[index] != 0 or self.symbols[callee].param_null_caller[index].len() > 0
                    if accepts:
                        self.symbols[si].param_nullable[0] = 1
                        self.symbols[si].param_reason[0] = "NULL accepted: forwarded to " ++ kv[0] ++ f" param {index}"
                        changed = true
                        break

    // Whether a `return` of the body may hand back NULL.
    fn ct_returns_null(si: i32) -> bool:
        for line in self.symbols[si].own_evidence.split("\n"):
            if line.starts_with("ret:") and self.fd_source_verdict(si, line.slice(4, line.len()), 0) == "null": return true
        false

    // The shape one function prints in, `record|method|out|out_ty|view`, or
    // "" for the raw signature (the module comment above).
    fn ct_method_shape(si: i32) -> str:
        let contract = self.symbols[si].contract
        if self.symbols[si].variadic != 0 or self.symbols[si].static_definition != 0 or contract == "plain" or contract == "unanalyzable": return ""
        var record = ""
        var is_mut = 1
        var out = -1
        var out_ty = ""
        var view = 0
        for verdict in contract.split(","):
            if verdict.starts_with("receiver-mut:"): record = verdict.slice(13, verdict.len()).to_owned()
            else if verdict.starts_with("receiver:"):
                record = verdict.slice(9, verdict.len()).to_owned()
                is_mut = 0
            else if verdict.starts_with("out:") or verdict.starts_with("out-record:"):
                let parts = verdict.split(":")
                if out >= 0 or parts.len() != 3: return ""
                out = parse(parts[1])
                out_ty = parts[2].to_owned()
            else if verdict == "ret-from:0": view = 1
            else: return ""
        if record.len() == 0 or not self.records.contains(record): return ""
        if view != 0 and ct_pointee(self.symbols[si].ret_ty).len() == 0: return ""
        f"{record}|" ++ ct_method_name(self.symbols[si].name, record) ++ f"|{out}|{out_ty}|{view}|{is_mut}"

    // D159 step 2: every proved function's shape, once. Two functions that
    // would share a method name both keep their raw signatures, and the
    // artifact says which.
    mut fn resolve_method_shapes():
        var taken: HashMap[str, str] = HashMap.new()
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            let shape = self.ct_method_shape(si as i32)
            if shape.len() == 0: continue
            let parts = shape.split("|")
            let key = parts[0] ++ "." ++ parts[1]
            if taken.contains(key):
                let other_name = (taken.get(key) ?? "").to_owned()
                let other = self.find_symbol(CiProjectSymbolKind.CIPS_FN, other_name)
                self.symbols[si].contract = self.symbols[si].contract ++ ",method-collision:" ++ other_name
                if other >= 0:
                    self.symbols[other].contract = self.symbols[other].contract ++ ",method-collision:" ++ self.symbols[si].name
                    self.symbols[other].method_record = ""
                continue
            taken.insert(key, self.symbols[si].name)
            self.symbols[si].method_record = parts[0].to_owned()
            self.symbols[si].method_name = parts[1].to_owned()
            self.symbols[si].method_out = parse(parts[2])
            self.symbols[si].method_out_ty = parts[3].to_owned()
            self.symbols[si].method_view = parse(parts[4])
            self.symbols[si].method_mut = parse(parts[5])

    // The artifact: one line per defined function, sorted by name.
    fn contracts_tsv() -> str:
        var names: List[str] = List.new()
        for si in 0..self.symbols.len():
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            names.push(self.symbols[si].name)
        names.sort()
        var text = ""
        for name in names:
            let si = self.find_symbol(CiProjectSymbolKind.CIPS_FN, name)
            if si < 0: continue
            text = text ++ name ++ "\t" ++ self.symbols[si].contract ++ "\n"
        text
