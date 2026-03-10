Generic Type Instantiation
Goal: Fix the single largest architectural gap — sema's generic
type erasure. This is a standalone plan because it touches the core
type system and has far-reaching effects.
Scope: src/Sema.w (type table), src/Codegen.w (delete
workarounds). This is the plan from spec-generic-instantiation.md.
Checklist

 Add GenericInst to TypeKind. A type kind that stores
base_type_id + type_arg_ids.
 Instantiation cache. Map (base_type, type_args) →
TypeId. Deduplicate: Vec[i32] mentioned 10 times = 1 TypeId.
 Fix resolve_type_expr for NK_TYPE_GENERIC. Stop returning
0. Recursively resolve base and args, create GenericInst.
 Type substitution function. Given Option[T] and T=i32,
produce Option[i32]. Single function, used everywhere.
 Update trait/impl resolution. collect_impl_decl stores
full instantiation. Method lookup performs substitution.
 Delete codegen workarounds. Remove vec_cache_map,
vec_local_types, vec_elem_types,
find_vec_cache_index_by_llvm, resolve_generic_type.
 Unblock downstream features:

Generic VecIter[T]
impl IntoIter[T] for Vec[T]
Implicit .iter() insertion
Untyped Vec.new() inference
Associated type bound checking


 Type error tests. Vec[i32] assigned to Vec[str] caught
by sema. Method on Vec[i32] doesn't apply to Vec[str].

Exit gate
resolve_type_expr never returns 0 for generic types. All codegen
parallel caches deleted. behav_vec.w and behav_hashmap.w pass
without explicit type annotations. Fixpoint holds.