# The With ABI (version 1)

Status: DRAFT v1 (2026-09-02), the convention as the compiler implements
it today, written down so `.wo` bundles (decisions.md D38,
`docs/wo_bundles.md`) can depend on it. Nothing here is a new rule. The
sources named in §7 define the ABI; this document describes them. When one
of them changes the convention, `WITH_ABI_VERSION` bumps and this document
gets a new section.

This is With's own calling convention. It is not a C ABI and exposes none
(`@[c_export]` is for foreign callers and does not appear in the compiler).
Where the platform ABI appears below it is as LLVM's substrate for lowering
a With value type, not as a contract With makes with another language.

## 1. Scalars and pointers

- `i8/i16/i32/i64`, `u8..u64`, `f32/f64`, `bool` (1 byte), `Unit` (zero
  size) lower to the LLVM integer/float types of that width.
- Raw pointers (`*const T`, `*mut T`), references (`&T`, `&mut T`), function
  values (`fn(...)`), and `extern fn` values are one pointer word.
- A reference is a **value of pointer type**: it is passed as that pointer,
  never as the pointee (D5/D6: "an explicit `&T` is a reference value with
  the ABI of that reference type").

## 2. Aggregates

- **Structs:** fields in declaration order, each at the next offset aligned
  to the field's alignment; size rounded up to the struct's alignment
  (`TypeLayout.type_layout_struct_field_offset`). No reordering, no
  packing, no niche use. `union` types size to the largest member at
  offset 0. Distinct (newtype) declarations have the layout of their
  underlying type.
- **Enums:** a tag followed by the payload area. The tag is the declared
  `repr` type, else 4 bytes; the payload area is the largest variant's
  fields laid out as a struct; the enum is aligned to the larger of the
  tag's and the payloads' alignment
  (`TypeLayout`, the `TY_ENUM` size/align rules). Payload-less enums with
  a `repr` lower to that integer.
- **Tuples** lay out as structs of their elements.
- **Generic instantiations** lay out as the instantiated struct/enum.

## 3. The built-in value types (the runtime's headers)

These are With value types with fixed layouts shared between the compiler's
generated code and `rt/rt_core.w`:

| Type | Layout | Size |
|---|---|---|
| `str` | `{ ptr: *const u8, len: i64 }` | 16 |
| `Vec[T]` | `{ ptr: *mut u8, len: i64, cap: i64, elem_size: i64 }` | 32 |
| `HashMap[K, V]` / `HashSet[T]` | handle: one pointer to a 64-byte runtime header (`keys, vals, occupied, cap, len, key_size, val_size, is_str_key`) | 8 |
| `SlotMap[T]` | handle: one pointer to a 48-byte runtime header (`values, occupied, generations, len, cap, elem_size`) | 8 |
| `Handle[T]` | `{ index: u32, generation: u32 }` | 8 |
| `StringBuilder` / `FmtBuffer` | `{ buf: *mut u8, len: i64, cap: i64 }` | 24 |
| slices `[]T`, `[]mut T` | fat: `{ ptr, len: i64 }` | 16 |

`Option[&T]` and `Option[*T]` lower to a **nullable pointer**: null is
`None`, a live address is `Some` (the D22 lookup representation shared by
`HashMap.get` and `SlotMap.get`). Every other `Option[T]` and every
`Result[T, E]` is an ordinary tagged enum under §2.

## 4. Function calls

The substrate is LLVM's C calling convention for the target. On top of it
With decides, per parameter, ONE pass mode from the signature — computed
once and read by both the callee prologue (`declare_function_from_sig`)
and every call site (D6; `docs/fn_abi_descriptor_design.md`):

| Signature | Pass mode | Physical form |
|---|---|---|
| plain `T`, `T: Copy` | COPY | the LLVM value of `T` (§1–3 layout) |
| plain `T`, not Copy | OWNED | the LLVM value of `T`; the callee owns it |
| `&T` / `&mut T` (explicit reference) | reference value | pointer word |
| receiver `mut self` (in-place), compiler-modeled borrowed places | IndirectPlace (`SHARE-PLACE` in `--dump-abi`) | pointer to the caller's place |
| `[]T` slices | Fat | `{ ptr, len }` by value |

Return values are returned by LLVM value of the return type. One target
exception, applied by the compiler on both sides: on windows-x86_64 a
struct/array larger than 8 bytes is returned through a hidden `sret`
pointer and passed indirectly (`internal_abi_needs_sret`,
`internal_abi_needs_indirect_param`). Other targets return `str`, `Vec`,
and structs by value and let LLVM lower them per the platform.

**Ownership is part of the ABI.** A plain `T` parameter transfers
ownership: the callee drops it (or moves it on). A reference parameter
transfers nothing. A returned value is owned by the caller. Receiver modes
(`fn` read, `mut fn` in-place, `move fn` consume) are encoded the same way
(D5; D21 for in-place receivers). A `.wo` boundary function with an owned
parameter therefore drops it inside the bundle, with the drop glue the
bundle was compiled with.

Effects (`read`/`write`/`consume`/`escape`) are Sema facts carried by the
source interface, not encoded in the object.

## 5. Symbols

A function's link name is its semantic symbol text — `main`, `peek`,
`Vec.push`, and for specializations the mono name Sema assigns
(`Vec.iter__receiver__158_16` style) — qualified by module when objects
are built per module: `__with_mod_<hash>__<base>`, where `<hash>` is
`with_str_hash` (FNV) of the canonical module path
(`module_link_name_for_path`). Runtime ABI symbols (`with_*`) keep their
bare names. Symbols are not otherwise mangled; the source interface, not
the symbol, carries types.

For `.wo`: the bundle's objects are built in module-object mode, so every
exported function is `__with_mod_<hash(canonical path)>__<base>`; the
canonical path is the bundle-relative module path, which makes the name
stable across checkouts.

## 6. Drops

Drop glue is generated per type by codegen (`mir_emit_drop_*`): a `str`
frees its buffer through the runtime allocator; a `Vec[T]` drops each
element then its buffer; enums drop the live variant's payload; structs
drop fields in declaration order. The runtime allocator's header is 16
bytes with the aligned payload size in the first word; `.wo` objects
allocate and free through the same runtime, which is linked once per
executable.

## 7. ABI-defining sources (what `WITH_ABI_VERSION` stamps)

- `src/TypeLayout.w` — §2 layouts.
- the pass-mode classifier and function declaration in `src/Codegen.w`
  (`arg_pass_mode`, `abi_param_source_type`, `declare_function_from_sig`,
  `internal_abi_needs_sret`, `internal_abi_needs_indirect_param`) and
  Sema's `sig_param_uses_value_ref_abi` — §4.
- symbol naming in `src/Codegen.w` (`module_link_name_for_path`,
  `function_symbol_name`, `codegen_canonical_module_path`) and
  `with_str_hash` — §5.
- the header layouts in `rt/rt_core.w` (`str`, Vec, HashMap, SlotMap,
  FmtBuffer sections) and the allocator header — §3, §6.
- drop glue in `src/CodegenDispatch.w` (`mir_emit_drop_*`) — §6.
- the LLVM version and target triple the object is built for (part of
  the `.wo` key, not of the version number).

**Enforcement** (`docs/wo_bundles.md`): these rules move out of the large
files into ABI-owned modules (`src/FnAbi.w` for §4–5 alongside
`src/TypeLayout.w`; the runtime header sections already sit together), a
recorded sha256 of those files is checked in next to this document, and a
battery target fails when the hash changes without a `WITH_ABI_VERSION`
bump. Non-ABI edits to `Codegen.w` then never trip it, and an ABI edit
cannot land unnoticed.

## Version history

- **v1** (2026-09-02): the convention as implemented at `23293bf0`.
