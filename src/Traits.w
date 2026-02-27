// Traits — Trait solver for the With compiler.
//
// Handles trait obligation resolution with a selection cache.
// With has no HKTs, GATs, or specialization, so the solver is
// a straightforward obligation-fulfillment loop with dedup.
//
// Data layout:
//   TraitDef: trait name, list of required method names + signatures
//   ImplInfo: which type implements which trait, method implementations
//   TraitSolver: cache + impls registry + trait definitions
//
// Resolution algorithm:
//   1. Check cache for (trait_name, self_type) → ImplId
//   2. Search impls for matching self_type
//   3. Check coherence (no overlapping impls)
//   4. Cache result
//   5. Return ImplId or error

use Type

// ── Trait definition ─────────────────────────────────────────────────

// A trait definition: list of required methods.
// Methods stored in extra array:
//   [method_count, m1_name, m1_param_count, m1_ret_type,
//    m2_name, m2_param_count, m2_ret_type, ...]
type TraitDef = {
    name: i32,
    method_count: i32,
    extra_start: i32,
}

fn TraitDef.new(name: i32, method_count: i32, extra_start: i32) -> TraitDef:
    TraitDef {
        name: name,
        method_count: method_count,
        extra_start: extra_start,
    }

// ── Impl info ────────────────────────────────────────────────────────

// An impl block: which type implements which trait.
// method_extra_start points into the solver's extra array where
// method implementation info is stored.
type ImplInfo = {
    impl_type: i32,
    trait_name: i32,
    method_count: i32,
    extra_start: i32,
}

fn ImplInfo.new(impl_type: i32, trait_name: i32, method_count: i32, extra_start: i32) -> ImplInfo:
    ImplInfo {
        impl_type: impl_type,
        trait_name: trait_name,
        method_count: method_count,
        extra_start: extra_start,
    }

// ── Trait obligation ─────────────────────────────────────────────────

type TraitObligation = {
    trait_name: i32,
    self_type: i32,
    span_start: i32,
    span_end: i32,
}

fn TraitObligation.new(trait_name: i32, self_type: i32, span_start: i32, span_end: i32) -> TraitObligation:
    TraitObligation {
        trait_name: trait_name,
        self_type: self_type,
        span_start: span_start,
        span_end: span_end,
    }

// ── Resolution result codes ──────────────────────────────────────────

fn TR_OK() -> i32: 0
fn TR_NOT_FOUND() -> i32: 1
fn TR_AMBIGUOUS() -> i32: 2
fn TR_NO_TRAIT() -> i32: 3

// ── Trait solver ─────────────────────────────────────────────────────

type TraitSolver = {
    // Trait definitions: trait_name → TraitDef
    trait_names: Vec[i32],
    trait_defs: Vec[TraitDef],

    // All known impl blocks
    impl_types: Vec[i32],
    impl_traits: Vec[i32],
    impl_infos: Vec[ImplInfo],

    // Selection cache: maps (trait_name, self_type) → impl index
    // Cache key is "trait_name:self_type" encoded as string
    cache: HashMap[str, i32],

    // Extra data for method signatures and implementations
    extra: Vec[i32],
}

fn TraitSolver.new() -> TraitSolver:
    TraitSolver {
        trait_names: Vec.new(),
        trait_defs: Vec.new(),
        impl_types: Vec.new(),
        impl_traits: Vec.new(),
        impl_infos: Vec.new(),
        cache: HashMap.new(),
        extra: Vec.new(),
    }

// ── Trait registration ───────────────────────────────────────────────

// Register a trait definition.
// method_names: Vec of name symbols
// method_param_counts: Vec of param counts
// method_ret_types: Vec of return TypeIds
fn TraitSolver.add_trait(self: TraitSolver, name: i32, method_names: Vec[i32], method_param_counts: Vec[i32], method_ret_types: Vec[i32]) -> void:
    let count = method_names.len() as i32
    let extra_start = self.extra.len() as i32
    var i = 0
    while i < count:
        self.extra.push(method_names.get(i as i64))
        self.extra.push(method_param_counts.get(i as i64))
        self.extra.push(method_ret_types.get(i as i64))
        i = i + 1
    let def = TraitDef.new(name, count, extra_start)
    self.trait_names.push(name)
    self.trait_defs.push(def)

// ── Impl registration ───────────────────────────────────────────────

// Register an impl block: type `impl_type` implements trait `trait_name`.
// method_names: names of implemented methods
fn TraitSolver.add_impl(self: TraitSolver, impl_type: i32, trait_name: i32, method_names: Vec[i32]) -> i32:
    let count = method_names.len() as i32
    let extra_start = self.extra.len() as i32
    var i = 0
    while i < count:
        self.extra.push(method_names.get(i as i64))
        i = i + 1
    let info = ImplInfo.new(impl_type, trait_name, count, extra_start)
    let idx = self.impl_infos.len() as i32
    self.impl_types.push(impl_type)
    self.impl_traits.push(trait_name)
    self.impl_infos.push(info)
    idx

// ── Trait lookup ─────────────────────────────────────────────────────

// Find trait definition by name. Returns index or -1.
fn TraitSolver.find_trait(self: TraitSolver, name: i32) -> i32:
    let count = self.trait_names.len() as i32
    var i = 0
    while i < count:
        if self.trait_names.get(i as i64) == name:
            return i
        i = i + 1
    -1

// Get trait def at index.
fn TraitSolver.get_trait(self: TraitSolver, idx: i32) -> TraitDef:
    self.trait_defs.get(idx as i64)

// Get trait method name at (trait_idx, method_idx).
fn TraitSolver.trait_method_name(self: TraitSolver, trait_idx: i32, method_idx: i32) -> i32:
    let def = self.trait_defs.get(trait_idx as i64)
    self.extra.get((def.extra_start + method_idx * 3) as i64)

// Get trait method param count at (trait_idx, method_idx).
fn TraitSolver.trait_method_param_count(self: TraitSolver, trait_idx: i32, method_idx: i32) -> i32:
    let def = self.trait_defs.get(trait_idx as i64)
    self.extra.get((def.extra_start + method_idx * 3 + 1) as i64)

// Get trait method return type at (trait_idx, method_idx).
fn TraitSolver.trait_method_ret_type(self: TraitSolver, trait_idx: i32, method_idx: i32) -> i32:
    let def = self.trait_defs.get(trait_idx as i64)
    self.extra.get((def.extra_start + method_idx * 3 + 2) as i64)

// ── Cache key encoding ───────────────────────────────────────────────

// Encode (trait_name, self_type) as a cache key string.
fn cache_key(trait_name: i32, self_type: i32) -> str:
    // Simple encoding: "trait:type" as concatenated ints
    let t = trait_name * 100000 + self_type
    // Use a string representation
    if t == 0:
        return "0"
    var result = ""
    var n = t
    if n < 0:
        result = "-"
        n = 0 - n
    var digits = ""
    while n > 0:
        let d = n % 10
        if d == 0 then digits = "0" ++ digits
        else if d == 1 then digits = "1" ++ digits
        else if d == 2 then digits = "2" ++ digits
        else if d == 3 then digits = "3" ++ digits
        else if d == 4 then digits = "4" ++ digits
        else if d == 5 then digits = "5" ++ digits
        else if d == 6 then digits = "6" ++ digits
        else if d == 7 then digits = "7" ++ digits
        else if d == 8 then digits = "8" ++ digits
        else digits = "9" ++ digits
        n = n / 10
    result ++ digits

// ── Resolution ───────────────────────────────────────────────────────

// Resolve an obligation: does self_type implement trait_name?
// Returns impl index (>= 0) on success, or negative error code.
fn TraitSolver.resolve(self: TraitSolver, trait_name: i32, self_type: i32) -> i32:
    // 1. Check cache
    let key = cache_key(trait_name, self_type)
    let cached = self.cache.get(key)
    if cached.is_some():
        return cached.unwrap()

    // 2. Verify trait exists
    let trait_idx = TraitSolver.find_trait(self, trait_name)
    if trait_idx < 0:
        return 0 - TR_NO_TRAIT()

    // 3. Search impls
    let impl_count = self.impl_infos.len() as i32
    var found = -1
    var found_count = 0
    var i = 0
    while i < impl_count:
        if self.impl_traits.get(i as i64) == trait_name:
            if self.impl_types.get(i as i64) == self_type:
                found = i
                found_count = found_count + 1
        i = i + 1

    // 4. Check result
    if found_count == 0:
        return 0 - TR_NOT_FOUND()
    if found_count > 1:
        return 0 - TR_AMBIGUOUS()

    // 5. Cache and return
    self.cache.insert(key, found)
    found

// Check if a type implements a trait (boolean convenience).
fn TraitSolver.implements(self: TraitSolver, trait_name: i32, self_type: i32) -> bool:
    let result = TraitSolver.resolve(self, trait_name, self_type)
    result >= 0

// ── Coherence checking ──────────────────────────────────────────────

// Check for overlapping impls: two impls for the same (trait, type).
// Returns true if coherent (no overlaps), false if there are overlaps.
fn TraitSolver.check_coherence(self: TraitSolver) -> bool:
    let count = self.impl_infos.len() as i32
    var i = 0
    while i < count:
        let t1 = self.impl_traits.get(i as i64)
        let ty1 = self.impl_types.get(i as i64)
        var j = i + 1
        while j < count:
            let t2 = self.impl_traits.get(j as i64)
            let ty2 = self.impl_types.get(j as i64)
            if t1 == t2:
                if ty1 == ty2:
                    return false
            j = j + 1
        i = i + 1
    true

// ── Obligation collection ────────────────────────────────────────────

// A list of pending obligations to be resolved.
type ObligationList = {
    obligations: Vec[TraitObligation],
}

fn ObligationList.new() -> ObligationList:
    ObligationList {
        obligations: Vec.new(),
    }

fn ObligationList.add(self: ObligationList, ob: TraitObligation) -> void:
    self.obligations.push(ob)

fn ObligationList.count(self: ObligationList) -> i32:
    self.obligations.len() as i32

fn ObligationList.get(self: ObligationList, idx: i32) -> TraitObligation:
    self.obligations.get(idx as i64)

// Resolve all pending obligations.
// Returns TR_OK() if all resolved, or the first error code.
fn ObligationList.resolve_all(self: ObligationList, solver: TraitSolver) -> i32:
    let count = self.obligations.len() as i32
    var i = 0
    while i < count:
        let ob = self.obligations.get(i as i64)
        let result = TraitSolver.resolve(solver, ob.trait_name, ob.self_type)
        if result < 0:
            return result
        i = i + 1
    TR_OK()
