# Storage Types and Caller-Place Parameters — Specification

Feature proposal. Two coupled additions to the With language:

- **Part A — `storage type`**: an aggregate that owns exactly N bytes and
  exposes typed, possibly overlapping *projections* onto regions of them.
- **Part B — `inout` / `byref` parameters**: passing a caller-owned
  *place* to a function, with exclusive or may-alias semantics, without
  introducing `&mut T` as a value.

Notation: `bytes[N]` in this document means `[u8; N]`. It is not a new
type; it is used because "bytes" reads better than "array of u8" in a
layout context and may become a prelude alias, but nothing here depends
on it being distinct.

Both are general-purpose language features. The COBOL modernization
campaign (`docs/COBOL-migrate.md`) is the motivating workload and the
first serious consumer, but no COBOL concept appears in these rules;
`std.cobol`, `cobol_import`, and `dec[P,S]` are separate proposals
layered on top.

Status: proposal. Not spec-normative until accepted and merged into
`docs/with-specification.md` (targets: a new chapter alongside §4 for
Part A; §9 and §21 amendments for Part B; ABI doc for the alias contract).

---

## Part A — Storage types

### A.1 Motivation

An ordinary `type` says: *these fields are values that together form an
object.* A record layout, a wire packet, a database page, a file record,
or a hardware register block says something different: *these bytes
exist, and these names are typed views onto regions of them.*

With today can approximate the second with `@[repr(C)]`,
`@[repr(packed)]`, and `union`, but three things are missing:

1. **Arbitrary overlap at arbitrary offsets.** A union puts every member
   at offset 0. Real layouts overlay a 6-byte region at offset 10 with a
   differently typed 4-byte region at offset 12.
2. **Whole-value copy that is a byte copy.** Struct assignment is
   field-wise. Copying a record with overlapping views must copy the
   bytes once, regardless of how they are projected.
3. **Safe reads of any overlay.** §16.4's union rule (a safe read
   requires the member to be the last one written) is correct for
   unions of arbitrary types. It is the wrong rule for layouts whose
   every projection admits every bit pattern, and weakening it for
   unions would lose the safety it provides.

`storage type` supplies all three without touching `union`.

### A.2 What it looks like to a mainstream developer

```
storage type CustomerRecord[128]:
    customer_id: text[10, ebcdic_037]   at 0
    balance:     packed_dec[9, 2]       at 10
    overlay at 16:
        status_text: text[4, ebcdic_037]
        status_code: bytes[4]
    items: [Item; 10]                   at 32
    // bytes 20..32 and 112..128 are unnamed; they still exist
```

- The type is exactly 128 bytes. `sizeof(CustomerRecord) == 128`,
  alignment 1, array stride 128.
- `record.balance` reads a `packed_dec[9, 2]`; because `packed_dec` is
  `Copy`, that is a plain value you can bind, copy, or pass.
  `record.balance = v` writes it. A projection whose type is *not*
  `Copy` (say a large nested storage record that chose not to
  `impl Copy`) can be borrowed, passed `inout`/`byref`, or explicitly
  snapshotted, but `let c = parent.child` is rejected: `BitwiseCopyable`
  lets the compiler move bytes, `Copy` lets *you* duplicate a value, and
  the two stay separate. No decoding
  happens on either side; if the bytes are not a well-formed packed
  decimal, you still get a `packed_dec[9, 2]` value. Interpreting it is
  a separate call (`record.balance.value(profile)`, defined by
  `std.cobol`, not by this feature).
- `status_text` and `status_code` name the same four bytes. Reading
  either is always fine.
- `a = b` between two `CustomerRecord`s copies 128 bytes. Whether `b` is
  still usable afterwards follows ordinary `Copy`/move rules, exactly as
  for any other type; storage types are not implicitly `Copy`.
- Construction is physical: `CustomerRecord.zeroed()` or
  `CustomerRecord.from_bytes(b)`, then write projections. There is no
  `CustomerRecord { balance: ..., status_text: ... }` literal, because
  with overlays it would have no defined meaning.

The mental model: **a storage value is a byte array with names.** Nothing
inside it is a separately owned thing. That is the whole feature.

### A.3 Syntax

```
StorageDecl  := 'storage' 'type' Ident '[' IntLit ']' AlignClause? ':' NEWLINE INDENT StorageBody DEDENT
AlignClause  := 'align' '(' IntLit ')'
StorageBody       := (Projection | Overlay)+
Projection        := Ident ':' PhysType 'at' IntLit
OverlayProjection := Ident ':' PhysType ('at' IntLit)?
Overlay           := 'overlay' 'at' IntLit ':' NEWLINE INDENT OverlayProjection+ DEDENT
```

Inside an `overlay at O:` block, a projection without `at` is placed at
`O`; with `at K` it is placed at `O + K`. Projections in the same
overlay block are declared to overlap. Projections outside any overlay
block that overlap each other are a compile error (A.5 rule 3).

Reserved words added: `storage` (contextual, only before `type`),
`overlay`, `at` (contextual, only inside a storage body). None of these
are reserved elsewhere; existing identifiers named `at` remain valid.

### A.4 Capabilities

Three compiler-derived properties. User code cannot assert them.

| Capability | Meaning |
|---|---|
| `BitwiseCopyable` | The representation may be transported byte-for-byte. |
| `AnyBitPattern` | Every bit pattern of the type's size is a valid *physical* value. |
| `Copy` | Ordinary With `Copy`: duplication does not consume the source. |

Every storage type is `BitwiseCopyable` and `AnyBitPattern` by
construction. It is `Copy` only if declared `impl Copy for T`.

`AnyBitPattern` is a claim about physical validity only. A
`packed_dec[9, 2]` field holding `0xFF FF FF FF FF` is a valid
`packed_dec[9, 2]` *value*; it is not a valid decimal *number*. The
distinction is the point: malformed legacy data is representable in safe
code without the type system pretending it is well-formed.

### A.5 Rules

1. **Size and alignment.** `storage type T[N]` has exactly `N` bytes and
   alignment 1 by default. `align(A)` is permitted only when
   `N % A == 0`. Therefore `sizeof(T) == N` and an array of `T` has
   stride `N` in every case.

2. **Projection types.** A projection's type must be an exact-size
   physical value type that is `BitwiseCopyable` and `AnyBitPattern`:
   fixed-size integers, `bytes[K]`, `[P; K]` arrays of such types, nested
   storage types, and std-supplied physical field types (`text[K, Enc]`,
   `packed_dec[P, S]`, `zoned_dec[P, S, Enc]`, `binary_dec[...]`,
   `be_i32`, `le_u16`, ...). Writing a projection stores a value of that
   type; reading one as an owned value is permitted only when the
   projection type is `Copy` (rule 13). No decoding, validation, or
   conversion occurs in either direction.

3. **Range and overlap.** Every projection's byte range lies within
   `[0, N)`. Two projections whose ranges intersect must be declared in
   the same `overlay` block; otherwise intersection is a compile error
   with both projections and the intersecting range named.

4. **Storage origin.** Every projection carries a compiler-visible
   *storage origin*: the outermost storage value plus a final byte range.
   Every subprojection refines that range, whether through a nested
   storage field, an ordinary field of an admissible physical type, or an
   array index: `r.address.zip`, `r.header.code`, `r.balance.raw[2]`,
   and `r.items[1]` all keep origin `r` with a narrowed range. A constant
   index yields the exact element range; a runtime index keeps the
   containing array's range. So `inout r.items[0], inout r.items[1]` is
   provably disjoint, and `inout r.items[i], inout r.items[j]` is not
   unless index facts prove `i != j`. Two projections of one origin with
   intersecting ranges are *known to overlap*; with disjoint ranges,
   *known disjoint*. Part B consumes these facts.

5. **Access lowering.** Projection reads and writes lower to alignment-1
   loads and stores, byte assembly, or `memcpy`. Unaligned projections
   have defined semantics on every supported target for by-value access.

6. **Under-aligned places.** Alignment does not itself prohibit
   by-value access to a projection (owned reads remain subject to rule
   13; writes are always permitted). Any typed borrowed or place
   capability that
   assumes the projection type's natural alignment — `&T`, `inout T`,
   `byref T`, slices and `prefix(n)` views over `[P; K]`, and `with ...
   as` place aliases — may be formed only when the compiler can prove
   that the projected address `addr(origin) + offset` is always a
   multiple of `alignof(T)`.
   The proof uses both the origin's guaranteed alignment and the offset;
   an aligned offset does not compensate for an under-aligned origin, so
   `x: i32 at 4` in an alignment-1 storage type may not form an `&i32`.
   *v1 restriction, not fundamental.* It costs nothing for the physical
   field types, which are all alignment-1.

7. **Endianness.** Native multi-byte integer projections (`i16`, `u32`,
   ...) use the target's object byte order and do not promise a
   target-independent representation. Portable layouts use
   explicit-order physical types. A storage type declared portable
   (attribute spelling to be settled with syntax) may not contain a
   native multi-byte integer *anywhere* in its projection types,
   recursively: `[u32; 4]` or a nested non-portable storage type both
   violate it. This is an error.

8. **Construction.** v1 construction is physical only: `T.zeroed()` or
   `T.from_bytes(b: bytes[N])`, followed by explicit projection writes. No fieldwise aggregate
   initializer. A later feature may define one with explicit write
   order.

9. **Resource-free.** A storage type and every projection type are
   resource-free. A storage type may not implement `Drop`, contain owned
   resources, or attach destruction semantics to its representation.
   This is what makes rule A.4's "`BitwiseCopyable` by construction"
   true.

10. **Assignment.** `=` between identical storage types is a bytewise
    representation transfer with ordinary assignment semantics: the
    right-hand value is conceptually materialized before the destination
    is written, so `r.a = r.b` between two overlapping `Copy`
    projections yields the pre-assignment bytes of `r.b` in `r.a`.
    Ownership follows ordinary `Copy`/move rules; there is no
    storage-specific ownership rule. `=` is not
    defined between different storage types or lengths; such movement
    is an explicit domain operation supplied by a library
    (e.g. `dst.cobol_move_from(src, profile)`), which never consumes
    its source.

11. **Arrays and bounded views.** `[P; K]` is an ordinary projection.
    `r.items.prefix(n)` yields a runtime-bounded read view over the
    first `n` elements under ordinary view-origin rules. A projection
    never reads another field to determine its own extent.

12. **Overlays are not unions.** Overlapping projections are ordinary
    places. §16.4's last-written rule for `union` is untouched. Reading
    any overlay member is always defined because every projection type
    is `AnyBitPattern` (rule 2).

12a. **Recursive storage views (v1).** A storage type may not project
    itself, directly or through mutual reference (`storage type A[8]:
    self_view: A at 0`). Although a projection contributes no storage
    and such a layout is not infinitely sized, v1 rejects it with a
    specific diagnostic rather than letting ordinary aggregate
    cycle-checking decide; a later feature may permit it deliberately.

13. **Place capability vs. value; `Copy` governs owned reads.**
    `BitwiseCopyable` authorizes representation transport;
    `Copy` authorizes source-visible duplication. An owned read of a
    projection (`let x = r.field`, passing `r.field` to an owned
    parameter, returning it) is permitted only when the projection type
    is `Copy`, and materializes by byte copy. For a non-`Copy` projection
    type the owned demand is rejected; the projection remains usable as a
    place (borrow, view, `inout`, `byref`, assignment target) and may be
    duplicated only by an explicit operation. Small physical field types
    (`packed_dec`, `text`, integers) will normally be `Copy`; large
    nested storage records need not be. The projection's *place
    capability* is not a first-class value and cannot outlive its
    storage origin. References and other ephemeral views derived from a
    projection follow §3 and §21's view-origin and escape rules; a
    read-only view may be returned where those rules permit.

14. **Ownership.** Storage values otherwise participate in ownership
    like any value: one owner, moved by value, borrowed ephemerally.

### A.6 What it looks like to library authors

Physical field types are ordinary types that satisfy rule 2. A library
supplies them as exact-size, alignment-1, `AnyBitPattern` values with
methods for interpretation:

```
// in std.cobol (sketch; the real one is its own proposal)
@[physical]
type packed_dec[P: comptime u8, S: comptime u8] { raw: [u8; (P + 2) / 2] }

impl packed_dec[P, S]:
    fn value(self, profile: &CobolProfile) -> dec[P, S]: ...
    fn store(mut self, v: dec[P, S], profile: &CobolProfile): ...
```

`@[physical]` is a std/compiler-internal attribute that requests exact
layout (alignment 1, no padding). Every field of a `@[physical]` type
must itself have alignment 1 in v1 (`[u8; N]`, `u8`, `i8`, other
`@[physical]` types), so that ordinary field access on a `@[physical]`
value at an odd address is never under-aligned; a `@[physical] Wrapper
{ x: u32 }` is rejected. It does *not* assert `BitwiseCopyable` or
`AnyBitPattern`; the compiler still derives those structurally from the
fields (A.4). A `@[physical] type Bad { flag: bool }` is rejected as
a projection type because `bool` is not `AnyBitPattern`, attribute or
not.

The library owns validity semantics; the language owns bytes. A library
that wants a different interpretation of the same bytes defines a
different physical type and lets users overlay it.

Comptime reflection (`T.fields()`, §17.2) reports each projection's
name, type, offset, range, and overlay membership, which is what
`cobol_import`-style generators and serializers consume.

### A.7 What it looks like to compiler maintainers

- A new `TypeDeclKind.Storage`, distinct from `Struct`, `Union`, and
  `Enum`. Layout is declared, not computed: the compiler *checks*
  offsets rather than assigning them.
- Projection access is a new place kind carrying `(origin, range)`. The
  borrow checker's overlap query for two storage places is range
  intersection on a shared origin.
- Codegen never emits a typed GEP + load for a projection; it emits an
  `i8` GEP to the offset and an alignment-1 load/store or `memcpy` of
  the projection's size.
- No new runtime support.

### A.8 Interaction with existing features

| Feature | Interaction |
|---|---|
| `union` (§16.4) | Unchanged. Storage overlays are a separate kind. |
| `@[repr(C)]`, `@[repr(packed)]` | Unchanged. Ordinary structs keep computed layout. A `@[repr(C)]` struct is not a valid projection type unless it is also `AnyBitPattern`, which requires every field to be. |
| `c_import` | A C struct can be re-declared as a storage type by hand; automatic conversion is out of scope for v1. |
| Ephemeral types (§5, §22) | A storage type cannot be ephemeral and cannot contain ephemerals (rule 2 excludes them). |
| `with` blocks (§7) | `with record.balance as mut b:` is an ordinary place-scoped access; no special casing. |
| Generics | v1 storage declarations are concrete: `N` is an integer literal and projection types are concrete. Generic storage types (`N: comptime usize`, generic projection types) are deferred to a later feature; copybook-generated records are concrete regardless. |

### A.9 Diagnostics contract

The compiler must diagnose at least:

- Projection range outside `[0, N)`.
- Two projections with intersecting ranges outside a shared overlay block.
- A projection type that is not `BitwiseCopyable + AnyBitPattern`, naming
  which property fails and, for aggregates, the first offending field.
- `impl Drop for` a storage type.
- `align(A)` with `N % A != 0`.
- Forming any typed borrowed or place capability (`&T`, `inout T`,
  `byref T`, a slice or `prefix(n)` view, a `with ... as` alias) from an
  under-aligned projection, with the guaranteed alignment of the origin
  and the offset shown.
- An owned read (`let`, owned argument, return) of a projection whose
  type is not `Copy`, suggesting a borrow, `inout`/`byref`, or an
  explicit snapshot.
- A storage type projecting itself, directly or mutually.
- A fieldwise initializer on a storage type, suggesting `zeroed()` /
  `from_bytes()`.
- A native multi-byte integer projection in a portable storage type.

### A.10 Non-goals (v1)

- Fieldwise initializers.
- Unaligned reference places.
- Automatic C-struct-to-storage conversion.
- Volatile or ordered access (storage types are a layout substrate for
  MMIO, not a sufficient MMIO facility).
- Any interpretation semantics (decimal, text encoding, dates). Those are
  library types.

---

## Part B — Caller-place parameters: `inout` and `byref`

### B.1 Motivation

With's receiver model already distinguishes reading (`fn f(self)`),
mutating in place (`fn f(mut self)`), and consuming (`fn f(move self)`).
`mut self` passes a pointer to the caller's storage (`PassMode
IndirectPlace`); the callee mutates it and does not drop it. Free
function parameters have no equivalent: a plain `T` parameter is owned,
`&T` is a read view, and there is no way to say "mutate the caller's
storage" for a non-receiver argument. §1.5 rules out `&mut T` as a
storable value, and the superseded free-parameter share-place design
(`docs/share_place_minimal_design.md`) inferred mutation rather than
declaring it, which D12/D21 rejected.

This feature adds the missing capability *explicitly*: two parameter
modes that bind a caller-owned place, spelled at both declaration and
call site, with an aliasing contract that is part of the signature.

### B.2 What it looks like to a mainstream developer

```
fn deposit(account: inout Account, amount: dec[11, 2]):
    account.balance = account.balance + amount

fn legacy_post(rec: byref CustomerRecord, ctl: byref CustomerRecord):
    // rec and ctl may be the same record; writes through one are
    // visible through the other immediately
    ...

deposit(inout my_account, 100.00)
legacy_post(byref r, byref r)          // legal
deposit(inout r.a, deposit_amount)     // r.a is a storage projection
```

- `inout T`: the callee has exclusive read/write access to the caller's
  place for the duration of the call: no other tracked caller access (a
  `&T`, a view, a guard, another `inout`/`byref` argument) may overlap
  it. This is `mut self` for any parameter.
- `byref T`: the callee has read/write access to a place that *may
  overlap* other `byref` arguments of the same call. Every write is
  immediately visible through every alias.
- Neither mode lets the callee take the value. `let owned = account`
  inside `deposit` is an error unless `Account: Copy`. The caller keeps
  ownership, always.
- The call site says which mode is used. `deposit(my_account, ...)`
  without `inout` is an error, not a silent by-value pass. Mutation
  through an argument is never hidden inside an ordinary-looking call.

The capability model:

```
&T          READ
inout T     READ + WRITE + EXCLUSIVE
byref T     READ + WRITE + MAY_ALIAS
T (owned)   READ + WRITE + CONSUME
```

`inout` is not "owned `T` through a pointer."

### B.3 Syntax

```
Param       := Ident ':' ParamMode? Type
ParamMode   := 'inout' | 'byref'
Arg         := ('inout' | 'byref')? Expr
```

A call-site `inout`/`byref` marker is required exactly when the
corresponding parameter is declared with that mode, and forbidden
otherwise. `inout`/`byref` are reserved words in parameter and argument
position only.

### B.4 Rules

1. **Place binding.** Both modes bind a place, not a value. Reading the
   parameter reads the caller's storage at that moment; writing writes
   it. No copy-in or copy-out.

2. **Call-site spelling is normative; the argument must be a mutable
   place.** `inout` and `byref` must appear at both declaration and call
   site, and the argument expression must denote a caller-owned place
   under the same predicate that governs `mut self` receivers. Because
   `mut self` is definitionally `inout`, a `let` binding is a valid
   caller-place argument: `let account = Account.new();
   update(inout account)` is legal, exactly as `account.deposit(...)`
   with a `mut self` receiver is legal today. `let` forbids rebinding
   the name, not mutation through an explicitly marked operation.
   `f(inout make_value())` (rvalue), `f(inout some_read_view)` (a `&T`
   or slice view), and `f(byref some_const)` are errors. With named arguments the mode
   sits with the expression: `f(target: inout x)`. Caller-place
   parameters have no default value and cannot be omitted in v1, since
   omission would hide the mutation mode the call site is required to
   show. A parameter may not be both `implicit` and a caller-place
   parameter; that combination is a direct error. Named arguments do not
   change evaluation order: arguments are
   evaluated, and caller-place designators reserved, in *source* order,
   then marshalled in parameter order. No ordinary argument expression is
   implicitly converted to a caller-place argument. Parameter mode is
   part of semantic signature identity: `fn(T)`, `fn(inout T)`, and
   `fn(byref T)` are distinct signatures; overload resolution never
   infers a mode from a bare `f(x)`.

3. **No ownership transfer.** An `inout` or `byref` parameter grants read
   and write access but not consumption of the caller's value. The
   parameter, or a non-`Copy` projection from it, may not satisfy an
   owned demand that would move the value out: passing to a consuming
   parameter, returning as owned, `let` binding as non-`Copy`, explicit
   `move`, or any other consumption is rejected. `Copy` values
   materialize normally; independent owned copies of non-`Copy` values
   require explicit clone or a domain operation. Replacing the place by
   assignment is permitted and leaves the caller owning the replacement.

4. **Call-wide exclusivity.** An `inout` place has exclusive access to
   its storage range for the dynamic extent of the call. *Exclusive*
   means: no other **language-tracked caller-place or live view
   capability** may overlap the range. Any such overlapping argument or
   live access is rejected at the call site: another `inout`, a
   `byref`, a `&T`, a slice or view, a guard, or a mutating receiver.
   Exclusivity does **not** assert universal pointer-provenance
   uniqueness: access through an independently named global, a raw
   pointer, foreign code, or any other provenance not represented by a
   live caller-place capability remains governed by its ordinary rules.
   This is deliberately weaker than LLVM parameter `noalias` (B.5). This is the rule that already rejects
   arguments retaining conflicting access to a `mut self` receiver,
   stated for all places.

5. **`byref` exception.** Two `byref` arguments may overlap each other
   and observe each other's writes. A `byref` still may not overlap an
   `inout`, a `&T`, or any other non-`byref` live access.

6. **Heterogeneous `byref` overlap.** Overlapping `byref` places of
   different static types are permitted only when both are projections
   of a common storage origin (Part A) and both types are
   `AnyBitPattern`. Otherwise overlapping `byref` arguments must have the
   same static type. This keeps the feature from becoming safe arbitrary
   type punning outside the storage system.

7. **Reservation and activation.** A caller-place argument's designator
   is evaluated in normal argument order. From then until invocation its
   *place identity is reserved*: later argument evaluation may perform
   completed reads and other normally sequenced operations, but may not
   move, destroy, rebind, relocate, or otherwise invalidate the
   designated place. At invocation the `inout` exclusivity or `byref`
   may-alias contract becomes *active* for the dynamic extent of the
   call. Consequences:

   ```
   mutate(inout xs, xs.len())               // OK: completed read
   f(inout x, x.compute_and_update())       // OK: place survives
   f(inout r.a, read(r.b))                  // OK: no retained conflict
   f(inout xs[last], xs.pop())              // ERROR: may invalidate place
   f(inout xs[0], xs.push(v))               // ERROR: may relocate
   f(inout x, move x)                       // ERROR: consumes place
   ```

   Reservation is about place validity, not value stability.

8. **Overlap facts.** Overlap is decided from ordinary place facts plus
   Part A's storage-origin facts. Two places rooted in distinct *owned*
   values are disjoint. Two places rooted in `byref` parameters of the
   same may-alias class (rule 9) are potentially overlapping regardless
   of syntactic root, so inside `fn outer(a: byref Rec, b: byref Rec)`,
   the call `inner(inout a.x, inout b.x)` is rejected: `a` and `b` may
   denote the same caller record. Two projections of one storage value
   pass as `inout` only if their ranges are known disjoint. Unprovable
   overlap is a compile error naming both arguments and the origin.

9. **Intra-callee may-alias.** Within a callee, distinct `byref`
   parameters whose *types* could legally overlap at some call site
   (rule 6) are conservatively treated as potentially overlapping: same
   static type, or two admissible `AnyBitPattern` physical types (since
   some caller may pass overlapping storage projections). The callee
   cannot see argument provenance and must assume any legal call. A view derived
   from one conflicts with a mutation through another while the view is
   live:

   ```
   fn f(a: byref i32, b: byref i32) -> &i32:
       let r = &a
       b = 42        // ERROR: may mutate r's origin
       r
   ```

   This keeps §21's view-liveness analysis and the backend's alias
   contract in agreement; a checker that assumed disjointness would be
   unsound at exactly the call sites rule 5 permits.

10. **Semantic contract only.** The `byref` rule that writes are
    immediately observable through every overlapping place is semantic.
    Reload-after-store is one conforming lowering; the language does not
    mandate it, and no LLVM attribute is part of the contract.

11. **`byref` type restriction (v1).** `byref` is restricted to
    `BitwiseCopyable` types: storage values, storage projections, `Copy`
    scalars, and std physical field types. Types with `Drop` or owned
    heap contents may not be passed `byref` until aliased-ownership
    invariants are separately ruled. `inout` has no such restriction.

12. **Escape and returned-view provenance.** The mutable place
    capability of either mode cannot be captured by an escaping closure,
    stored, or returned. Read-only ephemeral views derived from the
    parameter follow §3/§21, and a view returned from a caller-place
    parameter acquires the origin of the *actual argument* at the call
    site:

    ```
    fn balance(r: inout Rec) -> &i32:
        &r.balance
    let p = balance(inout rec)
    rec.balance = 1        // ERROR while p is live
    ```

    For `byref`, escape provenance stays parameter-specific: `return &a`
    originates from `a`'s argument, not from every compatible `byref`
    parameter. The may-alias class (rule 9) governs intra-callee
    conflict checking only. Capture by
    a proven non-escaping closure is not unsound; *v1 rejects it for
    implementation simplicity*, and that restriction is explicitly not
    fundamental.

13. **First-class callables (v1).** A function with any `inout` or
    `byref` parameter cannot be taken as a first-class value, mirroring
    the existing restriction on mutating methods. A later feature may
    add `fn(inout T) -> R` / `fn(byref T) -> R` as callable types with
    the mode part of identity; a mode can never be erased to `fn(T)`.

14. **Suspension (v1).** `inout` and `byref` parameters are prohibited on
    functions that may suspend (`async fn`, `gen fn`, and any function
    the `may_suspend` analysis marks). A caller-place capability
    surviving a suspension point is a semantic question deferred to a
    later feature.

15. **Receivers unchanged.** `mut self` is definitionally an `inout`
    receiver. Existing receiver rules (D12/D21) are unaffected.

16. **Declaration contexts.** Where caller-place modes may appear:

    | Context | v1 |
    |---|---|
    | free functions | yes |
    | inherent method parameters (non-receiver) | yes |
    | `mut self` receiver | already equivalent to `inout` |
    | `extern fn`, `c_import`, any foreign-ABI declaration | **no** — the modes carry With-specific promises (caller ownership, non-escape, reservation, alias contract) a foreign callee cannot be assumed to keep; foreign mutation stays on the C-pointer surface, and a safe With wrapper adds `inout`/`byref` where the contract can be established |
    | closure parameters | no — the callable would need a caller-place function type (rule 13) |
    | explicit `fn(...)` type syntax | no (rule 13) |
    | trait method parameters | **no in v1** — supporting them requires `ParamMode` through trait metadata, vtable function types, indirect calls, and interface matching; deferred as a unit |

17. **No new overloading.** Parameter mode participates in signature
    identity and candidate matching but does not by itself introduce
    same-name overloading where the language does not already permit
    it. Two declarations that differ only in `T` versus `inout T` are
    rejected wherever two declarations differing only in `T` versus `U`
    would be.

### B.5 ABI

Both modes lower through the existing indirect-place path, which gains an
alias contract:

```
PassMode::IndirectPlace { aliasing: Exclusive | MayAlias }

mut self / inout            →  IndirectPlace + Exclusive
byref                       →  IndirectPlace + MayAlias
existing read `self` (non-move, by-place)  →  IndirectPlace + MayAlias
```

The alias contract derives from the *access mode*, not from the pass
mode: `IndirectPlace` only says "pointer to the caller's place." Today's
compiler passes non-`move` read receivers by place as well; those carry
no exclusivity promise and must not acquire one when the field is
introduced. (A future `SharedRead` contract may distinguish them from
`byref`; v1 uses `MayAlias` for both.)

The language promises exclusivity for `Exclusive` places; the backend may
exploit that with whatever optimization metadata is sound for the target
and lowering. Note that LLVM parameter `noalias` is *stronger* than
With's exclusivity: it forbids any access to the pointee during the call
through unrelated provenance, including a global the callee names
directly. Exclusivity as specified here does not by itself exclude
`fn f(a: inout Account): global_account.x = 1` called as
`f(inout global_account)`, so the backend must either prove the stronger
contract or omit the attribute. `MayAlias` places carry no disjointness
assumption and never receive it. This is
an ABI descriptor change (`docs/with-abi.md`, `WITH_ABI_VERSION` bump).

### B.6 What it looks like to library authors

- APIs that today take `mut self` and return nothing can offer a free
  function form: `fn swap(a: inout T, b: inout T)`.
- Serialization and record libraries take `byref` storage values so a
  caller can pass overlapping projections without the library needing to
  know.
- Nothing about `inout` leaks into type signatures beyond the mode word;
  there is no `&mut` type to thread through generics.

### B.7 What it looks like to compiler maintainers

- `ReceiverMode` (`Sema.w`) gains no variants; a parallel `ParamMode`
  (`Value | Inout | Byref`) is added to parameters. Mode participates in
  signature identity and mangling.
- The per-argument ABI descriptor (`FnAbi.w`) gains an alias contract
  derived from access mode; `PM_INDIRECT_PLACE` itself remains purely
  the transport mode and implies nothing about aliasing.
- `apply_noalias_param_attrs` (`Codegen.w`) must skip `MayAlias`
  parameters.
- The borrow checker gains: a "reserved place" liveness state between
  designator evaluation and invocation; range-overlap queries on storage
  origins; a per-function may-alias class for compatible `byref`
  parameters.
- `MirSuspendCheck.w` gains a rule: caller-place parameters on a
  may-suspend body are an error.

### B.8 Diagnostics contract

- Missing or extraneous call-site `inout`/`byref`, with the parameter's
  declared mode shown.
- Consumption of an `inout`/`byref` parameter, suggesting `.clone()` or
  assignment-replacement as applicable.
- Overlapping `inout` with any other live access; overlapping `byref`
  with a non-`byref`; heterogeneous `byref` overlap outside a storage
  origin. Each names both accesses and the origin.
- Reservation violation: which later argument may invalidate which
  reserved place, and why (consume / relocate / destroy).
- Intra-callee `byref` conflict: the live view, its source parameter,
  and the mutating parameter.
- `byref` on a non-`BitwiseCopyable` type.
- Caller-place parameter on a may-suspend function; taking a caller-place
  function as a value; capturing a caller-place in a closure.
- Caller-place mode in a disallowed declaration context (`extern fn`,
  `c_import`, closure parameter, `fn(...)` type, trait method), naming
  the context.
- `implicit` combined with a caller-place mode; a default value on a
  caller-place parameter; omission of a caller-place argument.
- Two same-name declarations differing only in parameter mode, where
  the language does not permit signature-only overloading.

### B.9 Non-goals (v1)

- Place-typed callable values.
- Caller places across suspension.
- `byref` for `Drop`/heap-owning types.
- Non-escaping closure capture of caller places.
- Inferred modes of any kind; this feature is explicit by design.

---

## Rationale summary

Both parts follow one principle: **represent the physical thing first,
and let abstraction be earned by proof.** A storage type is bytes with
names; interpretation is a library operation. A caller place is the
caller's storage; consumption is a different capability. `byref` records
that aliasing has not been disproven; `inout` records that it has. The
migrator, the borrow checker, and the backend all read the same facts.

Ada gets close to Part A with representation clauses but treats the
record as fields; C/C++ get the bytes with unions and give up safety; C#
needs explicit layout plus `unsafe`. No mainstream language has Part B's
two-mode split with the mode in the signature; Swift's `inout` is
exclusive-only, Fortran's aliasing is undefined, and C's `restrict` is
unchecked.
