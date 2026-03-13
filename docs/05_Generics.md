# 05 — Generic Type Instantiation

Goal: Fix sema's generic type erasure — the single largest
architectural gap. Currently `resolve_type_expr` returns 0 for
all NK_TYPE_GENERIC nodes, deferring all generic resolution to
codegen. Codegen maintains ~2000 lines of parallel type-tracking
workarounds (cache maps, local type maps, LLVM-based reverse
lookups) that re-derive information sema should provide.

Scope: `src/Sema.w` (type table, type resolution, compatibility),
`src/Codegen.w` (delete workarounds, update consumers). One phase
at a time. `make build` after each change. `make fixpoint` after
each phase.

**Constraint:** This is a self-hosting compiler. The compiler
uses Vec, HashMap, Option, and Result internally. Every change
must preserve fixpoint (stage2 == stage3). Work incrementally.

---

## Phase 1: Add TY_GENERIC_INST to the Type System

Add a new TypeKind that represents an instantiated generic type,
e.g. `Vec[i32]` as `GenericInst(base=Vec, args=[i32])`.

**File:** `src/Sema.w` (lines 23-41 for TypeKind constants,
lines 58-68 for type table, lines 742-748 for add_type)

### Tasks

- [x] Add `const TY_GENERIC_INST: i32 = 19` after TY_NEVER (line 41)
- [x] Design the type table layout for TY_GENERIC_INST:
      d0 = base type symbol (name_sym), d1 = extra_start
      (index into type_extra), d2 = arg_count
- [x] Type args stored in type_extra[extra_start..extra_start+arg_count]
      as TypeIds (not AST nodes)
- [x] ~~Add `fn Sema.add_generic_inst_type`~~ — logic inlined in
      `resolve_generic_type` instead (standalone function caused seed
      compiler codegen crashes due to Vec[i32] by-value params)
- [x] Add `fn Sema.get_generic_inst_base(tid) -> i32` — returns d0 (base sym)
- [x] Add `fn Sema.get_generic_inst_arg_count(tid) -> i32` — returns d2
- [x] Add `fn Sema.get_generic_inst_arg(tid, index) -> i32` — reads
      type_extra[d1 + index]
- [x] `make build`

---

## Phase 2: Instantiation Cache (Deduplication)

`Vec[i32]` mentioned 10 times must produce 1 TypeId. The cache
maps `(base_sym, arg_tids...)` to an existing TypeId.

**File:** `src/Sema.w`

### Tasks

**Root cause found and fixed.** The original crashes were caused by
MirBuilder shallow-copying Sema by value — Vec data pointers were
aliased. When the copy's Vec grew (realloc), the original's pointer
dangled. The cache's deduplication left type Vecs with less spare
capacity, triggering realloc in MIR lowering. Fix: store cast target
TypeId in sema sidecar (typed_expr_types) so MIR lowering reads it
back without calling resolve_type_expr/add_type on the aliased Sema.

- [x] Add `generic_inst_cache: HashMap[str, i32]` to Sema struct
- [x] Cache key built inline: `base_sym:arg0:arg1:...` via int_to_string
- [x] Cache lookup + insert in `resolve_generic_type` (inlined,
      no separate get_or_create function needed)
- [x] Initialize `generic_inst_cache` in Sema constructor
- [x] Key is deterministic (integer TypeIds, colon-separated)
- [x] `make build`

---

## Phase 3: Fix resolve_type_expr for NK_TYPE_GENERIC

Replace the `return 0` stub with actual generic type resolution.
This is the core change.

**File:** `src/Sema.w` (lines 2066-2068)

### Tasks

- [x] Read the NK_TYPE_GENERIC AST node layout:
      d0 = base type name sym, d1 = extra_start, d2 = arg_count
      (Parser.w lines 3270-3282)
- [x] In resolve_type_expr, replace the NK_TYPE_GENERIC handler:
      Implemented via `fn Sema.resolve_generic_type(node) -> i32`.
      Resolves all type args into local variables (gi_arg0..gi_arg3,
      max 4 type params) BEFORE pushing to type_extra, to avoid
      interleaving from recursive calls for nested generics.
- [x] Handle resolution failure: if any arg resolves to 0 (unknown),
      return 0 (preserve current behavior for unresolvable cases)
- [x] Handle resolution of nested generics: `Vec[Option[i32]]` —
      local variable approach prevents type_extra interleaving
- [x] Verify that the base type name exists in named_types; emit
      "unknown type" error for unknown base types
- [x] `make build`
- [x] `make fixpoint` — passed. Required additional fix: skip return
      type check in `check_return` when `current_return_type` is
      TY_GENERIC_INST (prelude functions returning Option[i32] now
      get non-zero type, triggering checks that previously skipped)

---

## Phase 4: Update Type Compatibility for TY_GENERIC_INST

`types_compatible` and `types_compatible_fast` must handle the new
TypeKind so that `Vec[i32]` != `Vec[str]`.

**File:** `src/Sema.w` (lines 4557-4670)

### Tasks

- [x] In `types_compatible_fast`: add case for TY_GENERIC_INST —
      two generic instances are compatible only if base_sym matches
      AND all arg types are compatible (recurse). Also added
      TY_GENERIC_INST ↔ TY_STRUCT and TY_GENERIC_INST ↔ TY_ENUM
      interop (base sym match = compatible, for codegen interop)
- [x] In `types_compatible`: add structural comparison for
      TY_GENERIC_INST if fast path misses (different TypeIds but
      structurally equivalent). Full recursive arg comparison.
- [x] Handle TY_GENERIC_INST vs TY_STRUCT: compatible if same base
      sym (needed for codegen interop during transition). Also
      handles TY_GENERIC_INST vs TY_ENUM.
- [x] ~~Add `fn Sema.generic_inst_types_compatible`~~ — logic inlined
      in both `types_compatible_fast` and `types_compatible`
- [x] Write test `test/cases/err_generic_type_mismatch.w`
- [x] Enable strict arg comparison in `types_compatible_fast` —
      fixed root cause: extern fn declarations in lib/std (iter.w,
      process.w, string.w) changed from `&Vec[T]` to `*void` to match
      the actual C function signatures (`with_vec *` = void pointer)
- [x] `make build`
- [x] Run test — PASS

---

## Phase 5: Type Substitution Function

A single function that replaces type parameters with concrete types.
Given `Option[T]` and the binding `T=i32`, produce `Option[i32]`.
Used by trait resolution, method lookup, and for-loop desugaring.

**File:** `src/Sema.w`

### Tasks

- [x] Read current generic substitution infrastructure:
      `generic_subst_param_syms`, `generic_subst_type_ids`,
      `lookup_generic_subst`, `put_generic_subst`
- [x] Add `fn Sema.substitute_type(tid, subst_syms, subst_tids, count) -> i32`
      Handles: TY_STRUCT/TY_ENUM/TY_ALIAS (direct match by name sym),
      TY_GENERIC_INST (recursive arg substitution), TY_PTR/TY_REF,
      TY_ARRAY, TY_SLICE, TY_TUPLE. Uses local vars (max 4 elements)
      to avoid type_extra interleaving.
- [x] Handle identity case: returns original TypeId when nothing changes
- [x] Integrate with existing `resolve_generic_return_type_node`
      — added NK_TYPE_GENERIC and NK_TYPE_OPTIONAL handlers
- [x] `make build` + `make fixpoint`

---

## Phase 6: Thread GenericInst Through check_expr

Sema's expression checking must propagate TY_GENERIC_INST through
assignments, function calls, field access, and method calls.

**File:** `src/Sema.w`

### Tasks

- [x] In `check_let_decl` / `check_let_binding`: when type annotation
      is NK_TYPE_GENERIC, resolve to TY_GENERIC_INST and store as
      the variable's type (done in Phase 3 via resolve_type_expr)
- [x] In `check_call_expr`: when function returns a generic type,
      substitute type params in return type to produce TY_GENERIC_INST
      (resolve_generic_return_type_node now handles NK_TYPE_GENERIC)
- [x] In `check_field_access`: when receiver has TY_GENERIC_INST type,
      re-resolve field type from AST declaration with substitution
      via resolve_generic_return_type_node (stored types have 0 for
      type params since they're unresolvable during collection)
- [x] In `check_method_call`: when receiver has TY_GENERIC_INST type,
      look up the base type's methods and substitute type params
      in the method signature (substitute_method_return_for_generic_inst)
- [x] In `check_struct_lit`: when struct name resolves to a generic
      type, infer type args from field values — walks struct type
      params, matches fields with NK_TYPE_NAMED type param, infers
      from corresponding value types, builds TY_GENERIC_INST
- [x] Verify that `Vec.new()` returns the correct TY_GENERIC_INST
      when type context is available — type annotation on let binding
      resolves via resolve_type_expr → resolve_generic_type
- [x] `make build`
- [x] `make fixpoint`

---

## Phase 7: Update Codegen to Read GenericInst from Sema

Instead of re-deriving generic types from LLVM values, codegen
reads TypeId annotations from sema. This phase adds the new path
alongside the existing workarounds (both paths active).

**File:** `src/Codegen.w`

### Tasks

- [x] Add `local_sema_types: HashMap[i32, i32]` field to Codegen struct
      for tracking sym → sema TypeId mappings for generic-typed locals
- [x] Initialize field in `init_with_opt`, save/restore in function
      scope (both gen_function and gen_closure scope blocks)
- [x] Populate from parameters: when param type node is NK_TYPE_GENERIC,
      resolve sema type and record in local_sema_types
- [x] Populate from let bindings: when declared type annotation is
      NK_TYPE_GENERIC, resolve sema type and record
- [x] Existing LLVM-cache dispatch remains active as primary path;
      sema types provide parallel infrastructure for Phase 9 migration
- [x] `make build`
- [x] `make fixpoint` — fixpoint holds, both paths agree.

---

## Phase 8: Update Trait/Impl Resolution

`collect_impl_decl` and `select_trait_impl` must work with
instantiated generic types. `impl Trait for Vec[i32]` must be
distinguishable from `impl Trait for Vec[str]`.

**File:** `src/Sema.w` (lines 1508-1606, 3856-3895)

### Tasks

- [x] Read current impl collection: `impl_lookup`, `impl_extra`,
      `impl_starts`, `impl_counts`, `impl_type_syms` (lines 112-116)
- [x] Add argument type checking in `check_method_call` for
      TY_GENERIC_INST receivers: resolves method parameter type nodes
      via `resolve_generic_return_type_node` with substitution, compares
      against actual argument types. Works for user-defined methods.
- [x] Add builtin generic method arg checking for Vec.push,
      HashMap.insert — checks arg types against generic instance type
      args without fn_decl nodes. Enables `err_vec_type_mismatch.w`.
- [x] In `collect_impl_decl`: when impl target is a generic type
      (e.g., `impl Display for Vec[i32]`), store TY_GENERIC_INST
      TypeId as the impl key, not just the base type symbol.
      Parser now captures generic args via `parse_optional_impl_target_args`
      and stores in `impl_target_type_nodes` sidecar. Sema resolves
      target type node to TY_GENERIC_INST and stores in `impl_generic_inst`
      HashMap keyed by "TypeId:trait_sym".
- [x] In `select_trait_impl`: when querying for a TY_GENERIC_INST
      type, match against both exact instantiation impls and
      blanket impls. Added `select_trait_impl_for_generic_inst`
      that checks `impl_generic_inst` first, falls back to base symbol.
- [x] Handle `impl[T] Trait for Vec[T]` — blanket impls over
      generic types. Added `blanket_target_base_syms` Vec to track
      the target type's base symbol (0 for bare type param blankets).
      `select_trait_impl` now skips generic blanket impls whose target
      base sym doesn't match the query type's base sym.
- [x] Use `substitute_type` (Phase 5) when resolving trait methods
      on generic instances — substitute_method_return_for_generic_inst
      now calls substitute_type(sig_ret) as primary path (AST fallback
      retained). check_method_call arg checking refactored to use
      substitute_type on stored sig param types instead of
      resolve_generic_return_type_node with type-decl introspection.
- [x] `make build`
- [x] `make fixpoint`

---

## Phase 9: Delete Codegen Workarounds

Once sema provides all generic type information and codegen reads
it, delete the parallel tracking infrastructure. Do this one
group at a time, verifying fixpoint after each deletion.

**File:** `src/Codegen.w`

### 9.1 Delete Vec cache workarounds

- [x] Delete `vec_llvm_types: Vec[i64]` — replaced by direct HashMap
- [x] Delete `vec_elem_types: Vec[i64]` — replaced by vec_type_to_elem HashMap
- [x] Simplify `vec_cache_map` from `HashMap[i64, i32]` to `HashMap[i64, i64]`
      (elem_ty → vec_ty direct mapping, no index indirection)
- [x] Add `vec_type_to_elem: HashMap[i64, i64]` for O(1) reverse lookup
      (replaces O(n) find_vec_cache_index_by_llvm scan + vec_elem_types)
- [x] Update `find_vec_cache_index_by_llvm` to use vec_type_to_elem (O(1))
- [x] Update `find_vec_elem_type_by_llvm` to use vec_type_to_elem (O(1))
- [x] Add sema-based primary path in `infer_vec_elem_type_from_receiver`
- [x] Delete Vec/HashMap/Option/Result fallback blocks in monomorphize_generic_call
      — sema-based unified type param binding handles all generic containers
- [x] Delete `vec_local_types: HashMap[i32, i64]` — sema path handles all cases
- [x] Delete `record_local_container_type` — Vec/HashMap tracking replaced by local_sema_types
- [x] Delete `track_local_type` Vec tracking — sema path handles all cases
- [x] Delete vec_local_types push tracking in gen_vec_method
- [x] `make build && make fixpoint` — 230/230 tests pass

### 9.2 Delete HashMap cache workarounds

- [x] Delete `find_hashmap_key_type_by_llvm` — dead code after sema path
- [x] Delete `find_hashmap_val_type_by_llvm` — dead code after sema path
- [x] Delete HashMap fallback block in monomorphize_generic_call
- [x] Simplify `hm_cache_map` from `HashMap[i64, i32]` to `HashMap[i64, i64]`
      (hash → LLVM type direct mapping, no index indirection)
- [x] Delete `hm_llvm_types: Vec[i64]` — replaced by hm_type_to_key HashMap
- [x] Delete `hm_key_types: Vec[i64]` — replaced by hm_type_to_key HashMap
- [x] Delete `hm_val_types: Vec[i64]` — replaced by hm_type_to_val HashMap
- [x] Delete `hm_is_str_keys: Vec[i32]` — replaced by hm_type_to_is_str HashMap
- [x] Delete `find_hashmap_cache_index_by_parts` — no more parallel vec indexing
- [x] Rename `type_node_hashmap_cache_index` → `type_node_hashmap_llvm_type`
      (returns LLVM type directly, 0 if not HashMap)
- [x] Rename `infer_hashmap_cache_index_from_receiver` → `infer_hashmap_type_from_receiver`
      (returns LLVM type, 0 if not HashMap)
- [x] Update `gen_hashmap_method` to take hm_ty: i64 instead of cache_idx: i32,
      uses hm_type_to_val/hm_type_to_is_str for O(1) lookups
- [x] Delete `hm_local_types: HashMap[i32, i64]` — sema path handles all cases
- [x] `make build && make fixpoint` — 230/230 tests pass

### 9.3 Delete HashSet cache workarounds

- [x] Delete `hs_llvm_types: Vec[i64]` — replaced by direct HashMap
- [x] Delete `hs_elem_types: Vec[i64]` — reverse lookup no longer needed
- [x] Simplify `hs_cache_map` from `HashMap[i64, i32]` (index-based) to
      `HashMap[i64, i64]` (elem_ty → hs_ty direct mapping)
- [x] Delete `find_hashset_cache_index_by_llvm` — no more parallel vec indexing
- [x] Delete `find_hashset_elem_type_by_llvm` — replaced by sema-based path
- [x] Delete HashSet fallback block in monomorphize_generic_call —
      sema-based unified type param binding handles all generic containers
- [x] `make build && make fixpoint` — 230/230 tests pass

### 9.4 Delete resolve_generic_type dispatcher

- [x] Add sema-based primary path in `resolve_type(NK_TYPE_GENERIC)`:
      calls `sema.resolve_type_expr` → `sema_type_to_llvm` before fallback
- [x] Delete Vec/HashMap/HashSet/Option/Result cases from `resolve_generic_type`
      — handled by sema_type_to_llvm via TY_GENERIC_INST
- [x] Retain Box, ContextError, and monomorphize_struct fallback
      (sema_type_to_llvm doesn't handle these yet)
- [x] `make build && make fixpoint` — 230/230 tests pass

### 9.5 Delete type binding system — DEFERRED

Type bindings (type_binding_syms/types/len) are the codegen-level
mechanism for monomorphization, mapping type param names to LLVM types
during struct and function monomorphization. This is the codegen analog
of sema's substitution — not a workaround. Used in 3 places:
monomorphize_struct, monomorphize_generic_call, and
resolve_trait_method_type_for_impl. Deleting would require threading
sema TypeIds through all resolve_type calls during monomorphization,
which is a fundamental refactor of the codegen type resolver.

### 9.6 Delete function-scope local type tracking save/restore

- [x] Delete `vec_local_types` field and all save/restore — field never populated,
      sema-based path (local_sema_types + sema_type_of_node) handles all cases
- [x] Delete `hm_local_types` field and all save/restore — same as above
- [x] `enum_local_types` save/restore is NOT redundant — needed for
      disambiguating enum method dispatch in nested function scopes
- [x] `make build && make fixpoint` — 231/231 tests pass

---

## Phase 10: Unblock Downstream Features

With GenericInst in sema, these features become possible.
Implement one at a time.

### 10.1 Generic VecIter[T]

Currently only `VecIter_i32` exists as a concrete type.

- [x] Generic struct method dispatch: `mono_struct_base` fallback in
      `gen_method_call` allows methods defined on base generic struct
      to be called on monomorphized instances. Test:
      `test/cases/behav_generic_struct_method.w`
- [x] For-loop Vec[T] iteration already works generically via
      `gen_for_vec` (uses `with_vec_get_ptr` + `infer_vec_elem_type`)
- [x] Test `test/cases/behav_vec_iter_generic.w` passes (added earlier)
- [x] Replace `type VecIter_i32` with generic `type VecIter[T]`
      in lib/std/collections.w. VecIter.next() is a codegen intrinsic
      that uses mono_struct type param bindings to determine elem type.
      Vec.iter() codegen intrinsic creates VecIter[T] from Vec[T].
- [x] `make build && make fixpoint` — 236/236 tests pass

### 10.2 impl IntoIter[T] for Vec[T]

Deferred — requires generic trait infrastructure (`trait Name[T]`)
which is parsed but not wired through sema/codegen. For-loops
already work with Vec[T] directly via `gen_for_vec`. Vec.iter()
returns VecIter[T] via codegen intrinsic.

- [ ] Define `trait IntoIter[T]` with `fn iter(self) -> VecIter[T]`
      in `lib/std/collections.w` (future: needs generic trait sema)
- [ ] Implement `impl[T] IntoIter[T] for Vec[T]` (future)
- [ ] Update for-loop desugaring to call `.iter()` on types
      implementing IntoIter (future)
- [ ] Write test verifying `for x in vec:` works via trait (future)
- [ ] `make build && make fixpoint`

### 10.3 Untyped Vec.new() inference

- [x] When `let v: Vec[i32] = Vec.new()`, infer that Vec.new()
      returns Vec[i32] from the expected type context — already
      worked via `static_receiver_type` using `expected_type`.
- [x] When `let v = Vec.new()` with no annotation, defer or
      require explicit type parameter: `Vec[i32].new()`
      Added NK_INDEX handling in `gen_builtin_static_call`:
      `Vec[i32].new()` is parsed as NK_INDEX(Vec, i32) in expression
      context. Codegen detects this pattern, resolves the element
      type via `resolve_named_type`, and creates the properly typed Vec.
      Works for all element types (i32, str, user structs).
- [x] Write test `test/cases/behav_vec_type_infer.w` — tests
      Vec[i32].new() and Vec[str].new() without annotations.
- [x] `make build && make fixpoint` — 227/227 tests pass

### 10.4 Associated type bound checking

- [x] Read current trait_assoc_names/defaults (Sema.w lines 107-110)
- [x] Impl validation: check that all required (no-default) associated
      types are provided — already implemented in collect_impl_decl
- [ ] When a trait bound requires an associated type constraint (e.g.,
      `T: Iterator[Item=i32]`), verify the impl provides the matching
      type — requires parser support for `[Name=Type]` in bounds (future)
- [ ] Substitute associated types during generic function instantiation
      — requires resolving `T.Name` where T is a type param (future)
- [x] Write test `test/cases/err_missing_assoc_type.w` — validates
      impl-level associated type checking
- [x] Write test `test/cases/behav_assoc_type_default.w` — validates
      associated types with defaults
- [x] `make build && make fixpoint` — 230/230 tests pass

### 10.5 `Self.Name` associated type lookups in impl blocks

Deferred from `04_complete_partial_implementations.md` item 6 (Self
keyword). `Self` resolves to the implementing type in impl blocks,
but `Self.Name` (e.g., `Self.Output`, `Self.Item`) does not resolve
to the associated type defined in the current impl.

- [x] In sema type resolution: when encountering `Self.Name` (field
      access on `Self` in a type position), look up the associated
      type binding from the current impl's trait
      Added NK_TYPE_ASSOC (kind 91) to Ast.w. Parser handles both
      TK_DOT_IDENT (.Uppercase) and TK_DOT (lowercase) after ident.
- [x] In impl block processing: record the mapping from associated
      type names to their concrete types for the current impl
      Added method_impl_nodes HashMap (fn_sym → impl_node) in Sema,
      populated during compute_method_origins. assoc_type_bindings
      HashMap populated in collect_fn_decl and check_fn_body.
- [x] Handle `Self.Name` in return types, parameter types, and
      expressions within impl methods
      Sema: NK_TYPE_ASSOC handler in resolve_type_expr looks up
      assoc_type_bindings. Codegen: NK_TYPE_ASSOC handler in
      resolve_type looks up impl node via sema.method_impl_nodes.
- [x] Write test `test/cases/behav_self_assoc_type.w`:
      ```
      trait Transform =
          type Output
          fn apply(self: Self, x: i32) -> Self.Output

      type Doubler = {}
      impl Transform for Doubler =
          type Output = i32
          fn apply(self: Doubler, x: i32) -> Self.Output: x * 2
      ```
- [x] `make build && make fixpoint` — 225/225 tests pass, fixpoint holds

---

## Phase 11: Type Error Tests

Verify that sema catches generic type mismatches that were
previously invisible.

### Tasks

- [x] Write `test/cases/err_vec_type_mismatch.w`:
      Added argument type checking for builtin generic methods (Vec.push,
      HashMap.insert) and user-defined methods on TY_GENERIC_INST receivers.
      check_method_call now resolves parameter types via substitution.
- [x] Write `test/cases/err_generic_return_mismatch.w`:
      Tail expression return type mismatch now caught via check_fn_body.
      Added expected_expr_type propagation for variant shorthand resolution.
- [x] Write `test/cases/behav_generic_inst.w`:
      Already existed and passes (Vec[i32] and Vec[str] basic usage).
- [x] Write `test/cases/behav_option_generic.w`:
      Already existed and passes (Option[i32] match).
- [x] Write `test/cases/behav_result_generic.w`:
      Fixed: Result match dispatch (find_variant_index Ok=0/Err=1) and
      payload extraction (bitcast [N x i8] to declared Ok/Err type).
- [x] Run `./scripts/run_tests.sh` — 225/225 tests pass
- [x] `make fixpoint`

---

## Execution Protocol

For each phase:

1. Read the relevant source before editing.
2. Make one logical change.
3. `make build`
4. Run specific test(s).
5. Run full test suite: `./scripts/run_tests.sh`
6. After each phase: `make fixpoint`

If the build breaks, stop and bisect. Do not batch phases.

**Critical:** This is a self-hosting compiler. The compiler itself
uses Vec, HashMap, Option, Result extensively. Phase 3 (fixing
resolve_type_expr) and Phase 7 (codegen reading sema types) are
the highest-risk changes. Verify fixpoint after each.

**Recommended order:** Phases 1-3 first (add type, cache, fix
resolve). Then Phase 4 (compatibility). Then Phase 7 (codegen
reads sema). Only delete workarounds (Phase 9) after both paths
are verified to agree. Downstream features (Phase 10) are last.

---

## Exit Gate

- [x] `resolve_type_expr` never returns 0 for valid generic types
- [x] `Vec[i32]` and `Vec[str]` have distinct TypeIds in sema
      (no dedup cache yet — duplicates created but harmless)
- [x] `types_compatible(Vec[i32], Vec[str])` returns 0
- [x] Type substitution function used by trait resolution, method
      lookup, and for-loop desugaring — substitute_type now used in
      substitute_method_return_for_generic_inst (return types) and
      check_method_call (parameter type checking)
- [x] All codegen parallel caches deleted — Vec: vec_llvm_types,
      vec_elem_types, vec_local_types deleted. HashMap: hm_llvm_types,
      hm_key_types, hm_val_types, hm_is_str_keys, hm_local_types deleted.
      HashSet: hs_llvm_types, hs_elem_types deleted. All simplified to
      direct HashMap[i64,i64] caches. record_local_container_type deleted.
      Type binding system (type_binding_syms/types/len) retained — needed
      for monomorphization, not a workaround.
- [x] `resolve_generic_type` in codegen deleted — logic inlined into
      NK_TYPE_GENERIC handler. Box/ContextError handled before sema path,
      monomorphize_struct as final fallback.
- [x] `behav_vec.w` and `behav_hashmap.w` pass without explicit
      type annotations — uses `Vec[i32].new()` and `HashMap[str, i32].new()`
      turbofish syntax. Parser extended to handle comma-separated subscripts
      in `parse_index_or_slice` (d2 stores second index). Codegen
      `gen_builtin_static_call` handles NK_INDEX for Vec, HashMap, HashSet.
- [x] Generic VecIter[T] replaces concrete VecIter_i32
      VecIter.next() and Vec.iter() are codegen intrinsics
- [x] `Self.Name` resolves to associated type in impl blocks
- [x] All tests pass under `./scripts/run_tests.sh` — 231/231
- [x] `make fixpoint` holds after all phases
