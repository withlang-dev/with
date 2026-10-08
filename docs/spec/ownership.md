# 2. Values and Ownership

### 2.1 Values

All values have a single owner. When a variable binding goes out of
scope, its value is destroyed. Destruction is deterministic.

### 2.2 Move Semantics

Assignment moves by default. After a move, the source binding is
invalid.

```
let a = Vec.new()
let b = a            // a is moved; b is the new owner
// a.push(1)         // COMPILE ERROR: use of moved value `a`
```

**A field never moves out implicitly — anywhere, in any context.** The
only way to vacate a field is the explicit `move place.field`, and only
through a mutable path (a `var` base, or the receiver of a `mut fn`).
Whole values decompose whole (destructuring, record update). An
implicit field move is a compile error at the move site, with fix-its
offering both intents: `move place.field` to vacate (reset-on-move
leaves the field a valid empty value — the take, §2.5.1), or
`place.field.clone()` to keep the base whole. An explicit `move
place.field` through a read path (a `let` base, or the receiver of a
read `fn`) is a compile error — a vacate is a write. This rule is
uniform over owned locals, receivers, and every other base; there is no
flow condition and no type condition. (D32.)

**Conditional moves are flow-sensitive.** A binding moved on some but
not all control-flow paths reaching a program point is *conditionally
moved* there. Using it is a compile error unless it has been
reinitialized on every path that reaches the use. Whether a binding is
moved at a point is determined by a conservative join over predecessors
(§21.1 rule 9): it is moved if moved on any reaching path that does not
diverge.

```
fn demo(cond: bool):
    let v = Vec.new()
    if cond:
        consume(v)        // moves v on the cond == true path
    v.push(1)             // COMPILE ERROR: v may have been moved
```

```
fn demo(cond: bool):
    var v = Vec.new()
    if cond:
        consume(v)        // moved on this path
    else:
        v = Vec.new()     // reinitialized on this path
    v.push(1)             // COMPILE ERROR: not reinitialized on the
                          // cond == true path
```

A conditionally moved binding becomes usable again only when it is
reinitialized on *every* path reaching the use.

This flow-sensitive check is a *diagnostic*, not the safety mechanism: it
rejects almost-certainly-wrong code at compile time. Memory safety itself —
the soundness of the move and the impossibility of a double-free if the check
were ever wrong — comes from reset-on-move (§2.5): the moved-from binding is
blanked, so its drop is a guarded no-op. It does not come from this analysis.

### 2.3 Copy Types

Types that implement the `Copy` trait are implicitly copied on
assignment, parameter passing, and other value uses. The original
binding remains valid.

```
let a: i32 = 5
let b = a            // copy; both a and b are valid
```

**Safety rules:**

1. **All fields must be `Copy`.** A type can only implement `Copy` if
   every field is itself `Copy`. This is checked recursively by the
   compiler.

2. **`Copy` and `Drop` are mutually exclusive.** A type that
   implements `Drop` cannot implement `Copy`. Bitwise duplication of
   a value with a destructor would cause double-free — the two copies
   would both run `Drop`.

3. **Types containing owning pointers** (`Box[T]`, `String`, `Vec[T]`,
   `Rc[T]`, `Arc[T]`) are not `Copy` because those types implement
   `Drop`. This is enforced by rule 1 (their fields are not `Copy`).

```
type Point { x: f64, y: f64 }         // OK: f64 is Copy
impl Copy for Point                       // OK

type Handle { id: u32, gen: u32 }      // OK: u32 is Copy
impl Copy for Handle                      // OK

type Buffer { data: Vec[u8] }          // Vec is NOT Copy (has Drop)
impl Copy for Buffer                      // ERROR: field `data` is not Copy

type File { fd: i32 }
impl Drop for File:
    move fn drop(): ...
impl Copy for File                        // ERROR: Copy + Drop is forbidden
```

The canonical destructor is `move fn drop()` — a destructor always
consumes, so its receiver mode is `move` (D7; `self` is implicit and never
written). Any other receiver mode on a `Drop` impl's `drop` is a compile-time
error with a fix-it. (The explicit form `fn drop(move self: Self)` remains
accepted during the receiver migration; see `docs/proposals/eliminate-self.md`.) Explicit destructor calls are legal
(Higher RAII): `x.drop()` is an ordinary consuming call that runs the
destructor body AND the field drop glue, after which the binding is
consumed — identical to the scope-exit drop, just earlier. The free
function `drop(x)` remains available as a no-op-body consume.
(BDFL rulings 2026-07-04, #641/#642.)

These rules guarantee that `Copy` is always safe in safe code — it
cannot cause double-free, use-after-free, or resource leaks.

**Transport is not duplication.** The compiler may move a value's bytes
wherever ownership moves: into a parameter, out of a return, between a
container's slots when it grows. It never produces a second live value from
one unless the type is `Copy`. This binds compiler-provided operations —
intrinsics, runtime helpers, derived and generated code — exactly as it
binds user code. An operation that needs an independent value of a
non-`Copy` type clones it, under a `Clone` bound, where the program asks for
that; an operation that only needs to look yields a view.

**Values and resources (D111).** Copy-or-move is decided by identity, not
by representation. Values have no identity (integers, floats, strings,
keys): passing one copies it, and the caller's is untouched. Resources have
identity (files, tasks, sockets, handles, buffers being filled): passing one
transfers it. Having a heap buffer does not make something a resource. `str`
is a value. Passing a `str` always copies. Code using `str` never sees "use
of moved value" and never needs `.clone()`. Semantics are copy; the
implementation is an immutable, shared, reference-counted buffer: a copy is a
pointer plus a count increment, the last holder frees. At a variable's last
use the compiler turns the copy into a move, with no count traffic. Text that
is built or edited goes through a builder type that produces a `str`.

**Size warning:** The compiler emits a **warning** (not an error)
when `Copy` is implemented for types exceeding a size threshold. The
default threshold is 128 bytes. It is configurable via `with.toml`
(`copy_warn_threshold`). The warning does not affect semantics — the
type is still `Copy`.

### 2.4 Destructors and `defer`

Types may implement a `Drop` trait whose `drop` method is called when
the value goes out of scope. The `drop` method takes `self` **by
value** — the value is consumed:

```
impl Drop for Database:
    move fn drop():
        sqlite3_close(self.handle)
```

Because `drop` consumes `self`, there is no need to defensively
null out fields to prevent double-free — the value ceases to exist
after `drop` returns, and a moved-from or reassigned source was
already blanked by reset-on-move (§2.5), so its later scope-exit
drop sees the reset sentinel and is a no-op. The compiler handles
the details: fields you use in your
drop body are consumed, remaining fields are dropped automatically.
No recursion, no leaks, no ceremony:

```
impl Drop for Database:
    move fn drop():
        sqlite3_close(self.handle)
        // self.handle was consumed by the close call
        // compiler drops remaining fields automatically
```

Drop order within a scope is reverse declaration order.

**Drop on reassignment:** When a `var` binding of a Drop type is
reassigned, the compiler drops the old value before storing the new
one. This prevents resource leaks in loops:

```
var h = create_resource()
for i in 0..n:
    h = transform(h)
    // old h dropped here — resource released before new value stored
```

**Conditional drop:** When a value is conditionally moved (§2.2) —
moved on some paths and live on others — its destructor runs on exactly
the paths where it still owns a value, and is skipped on the paths
where it was moved. The compiler arranges this automatically; the
programmer writes nothing and adds no annotations. Drop on
reassignment, above, is the loop case of this rule.

**Drop on expression temporaries:** Temporaries created within an
expression are dropped at the end of the enclosing statement. This
frees intermediate resources automatically:

```
let c = process(combine(a, b))
// combine's result is a temporary — dropped after process reads it
// only c survives
```

**Field moves are explicit, uniformly** (§2.2, D32): an implicit field
move is a compile error for every type — the earlier Drop/non-Drop
conditional is superseded by the one rule. Inside `drop` itself, the
consumed `self` is owned and its fields may be accessed and consumed
freely. Elsewhere, vacate a field with the explicit `move w1.fd`
through a mutable path, clone it, or consume the whole value:

```
type FileWrapper { fd: File, name: String }
impl Drop for FileWrapper:
    fn drop(move self: Self): close_file(self.fd)

var w1 = FileWrapper { fd: open_file(), name: "A" }
let w2 = FileWrapper { fd: move w1.fd, name: "B" }   // explicit vacate
// or: FileWrapper { fd: w1.fd.clone(), name: "B" }  // keep w1 whole
```

Record update syntax (`{ base with field: value }`) consumes the base
whole (§4.3) and is not a field move.

For explicit cleanup of resources not tied to a value's lifetime, `defer`
executes a statement when the enclosing scope exits:

```
fn process(path: str) -> Result[Unit, IoError]:
    let f = fs.open(path)?
    defer f.close()
    // ... use f ...
    // f.close() runs here, regardless of early returns
    // implicit Ok(()) — no trailing expression needed
```

`defer` statements execute in LIFO order.

**Control flow restriction:** `return`, labeled or unlabeled `break`,
labeled or unlabeled `continue`, `goto`, and `?` are **compile errors**
inside `defer` or `errdefer` blocks. Defer runs during scope cleanup
— non-local control flow would silently swallow the function's actual
return value or jump to unexpected locations:

```
// ERROR: return inside defer
defer if file.has_error(): return Err(IoError)
//                         ^^^^^^ ERROR E0901: non-local control
//                         flow is forbidden inside defer

// ERROR: ? inside defer
defer conn.close()?
//                ^ ERROR E0901: ? may return early from defer

// OK: handle errors locally inside defer
defer conn.close().unwrap_or(())
defer if let Err(e) = f.sync(): log.warn("sync failed: {e}")
```

**`errdefer`:** Like `defer` but only executes when the function returns an
error (via `?` propagation). On normal return paths, `errdefer` is skipped:

```
fn connect(url: str) -> Result[Connection, Error]:
    let conn = open_socket(url)?
    errdefer conn.close()       // only runs if a later ? fails
    let auth = authenticate(conn)?  // if this fails, conn.close() runs
    Connection { conn, auth }       // success: errdefer does NOT run
```

`errdefer` and `defer` execute in LIFO order relative to each other. On error
return, both `errdefer` and `defer` blocks run. On success return, only `defer`
blocks run.

### 2.5 Generational Ownership

Ownership in With is enforced by **runtime facts**, not by a static proof of
single ownership: an owner is safe because a move blanks its source and a
blanked value's drop frees nothing (§2.5.1), and a handle is safe because the
slot it names carries a generation it can check (§6). One philosophy —
*validity is a runtime fact, not a static proof* — realized by the cheapest
mechanism each lifetime needs: **reset-on-move for owners, a per-slot
generation for handles.** It is what lets §1.4 promise Rust-level safety
without lifetime annotations.

#### 2.5.1 Reset-on-move and the null drop

An owned value's safety rests on two cheap, complementary runtime facts —
neither of which depends on the compiler's static analysis being correct:

- **Reset-on-move.** A move (§2.2) copies the value's bits to the new binding
  and **resets the source**: its owning pointer is cleared to null (a container
  is left empty — null pointer, zero length). The source binding still
  type-checks as the value, but it no longer owns anything.

- **The guarded drop.** A drop first checks whether the value is the **reset
  sentinel** (its storage zeroed); if so the drop is **skipped entirely** — no
  free, and no user destructor code runs. Built-in containers are inherently
  null-safe (freeing null does nothing, an empty container recurses over
  nothing), so the check folds into their ordinary drop; a user `Drop` whose
  body touches the value is guarded so it never runs against a moved-from
  value. A moved-out value's drop does nothing.

  A `Drop` type whose all-zero storage can be a live value (`Fd { n: 0 }`)
  cannot use its storage as the sentinel. For such a type the compiler adds a
  hidden liveness byte: the reset clears it and the guard reads it, so a live
  zero value is destroyed like any other (D72). A type with an owning
  non-null field keeps the storage test and pays nothing; the programmer
  writes nothing either way.

**Ownership is a property of the handle, not of its contents.** Every value
that owns heap — a container, a box, an owned buffer — releases it when its
owner's scope ends, regardless of whether its *elements* need destruction:
`Vec[i32]` frees its buffer exactly as `Vec[File]` does; trivially-copyable
elements merely skip the per-element destructor loop. (Replacement is
already covered by §2.2's drop-on-reassignment.) Leaking memory therefore
requires a deliberate, visible act — owning the memory from a named scope —
never inaction: a program that does nothing special does not leak.

**The only way to skip a destructor is a spelling that is visible at the
type's own boundary.** Outside a type's own `move fn` methods, no pattern,
binding or call runs a `Drop` value's fields past its destructor (§9.7);
inside them, a total destructure of `self` is the visible disarm.

Together these make **double-free impossible by construction**: the live bits
exist in exactly one binding at a time, every move hands them off and blanks
the source, and dropping a blanked source frees nothing. This makes §2.2's
reassign-after-move correct with no special handling:

```
var r = make()    // r owns allocation A
take(r)           // r moved into take; take drops it → frees A; r is reset to null
r = make()        // drop-before-overwrite: r is null → no-op; r now owns fresh B
take(r)           // moves r into take; take drops B normally
```

No drop flags, no flow-sensitive drop elaboration, no per-path bookkeeping —
the reset settles it. The reset is **unconditional** (every move blanks its
source) and the null guard is part of the destructor itself, so neither relies
on the move analysis (§2.5.2) being correct.

The **generation** that §6 surfaces in `Handle` is the *same philosophy*
applied to long-lived **non-owning** references, realized **per slot** by the
owning `SlotMap`: each slot carries its own generation, bumped when that slot's
value is removed, and a handle access compares its snapshot against the slot's
current generation (mismatch → the slot was reclaimed → use-after-free → a
checked `None`, §2.5.5). The generation lives in the `SlotMap`'s per-slot
metadata, **not** in the allocation header. A `SlotMap` is a single allocation
holding many slots, so a per-allocation header generation cannot tell a
removed-and-reused slot from a live one and is **incapable** of serving
handles; an earlier draft of this section described an allocation-header
generation, which was a spec bug (an impossible mechanism), now corrected.
Owning values do not carry or compare a generation for their own drop —
reset-on-move is their mechanism; the per-slot generation is the handle story.

#### 2.5.2 Static analysis is an optimization, never the guarantee

The compiler still performs the flow-sensitive move analysis of §2.2, for two
reasons — **neither load-bearing for memory safety**:

1. **Ergonomic diagnostic.** Using a moved-from binding is almost always a
   mistake, so the compiler reports it as a *compile error* (§2.2) rather than
   letting it become a silent runtime no-op. This is a courtesy to the
   programmer, not a safety mechanism.

2. **Zero-cost optimizer.** Where the analysis *proves* a value has a single
   owner that is never moved (the overwhelmingly common case), the source-reset
   on move and the null guard at its drop are provably redundant and are
   **elided** — the move skips the reset, the drop becomes an unconditional
   free, byte-for-byte the codegen a static-only model would emit. The reset
   and the guard are paid for only where ownership is genuinely dynamic.

The consequence is a property a static-only model cannot have: **a bug in the
move analysis can only cost performance, never safety.** A missed elision is a
redundant null store and null check; it can never become a double-free or a
leak, because correctness lives in the unconditional reset-on-move, not in the
proof. This is the deliberate inverse of designs (e.g. Rust's `elaborate_drops`)
where the static analysis *is* the safety and an analysis bug is undefined
behavior.

#### 2.5.3 Cost

| Situation | Cost |
|-----------|------|
| Value with a single, never-moved owner (the common case) | **Zero** — reset and null guard elided by the optimizer; identical codegen to a static-only model |
| Ownership transferred dynamically (conditional move, reassignment of a possibly-moved binding, ownership moved through a data structure) | One null store per move, one null check per drop — a single predicted branch, no allocator round-trip |

With trades a predictable, optimizer-elidable null store and null check on the
dynamic paths for the elimination of an entire class of compiler bugs *and* the
lifetime-annotation ceremony of a static borrow checker. The owner-drop path is
cheaper than the §6 handle path — it needs no generation compare, only the
pointer it already holds — yet rests on the same principle: *validity is a
runtime fact, not a static proof.*

#### 2.5.4 Interaction with C

Reset-on-move and the null drop apply to **With-owned values** — those that
carry a `Drop` (an allocation buffer, a wrapped foreign resource). Raw pointers
(`*mut T`, `*const T`) and `c_import`ed C structs have no `Drop`, so they are
never reset and never drop-checked — copying one is a plain bit copy, exactly
as fast and exactly as unsafe as C. Ownership, and therefore the reset, begins
only when a value enters With's care: an allocation, or a `Drop` type wrapping
a foreign handle. `with migrate`'s modeled-C `Drop` types get reset-on-move for
free; raw migrated pointers pay nothing for it. (The handle **generation** of
§2.5.1 lives in the `SlotMap`'s per-slot metadata — see §2.5.1 — not in
allocation headers, so it imposes no per-allocation cost.)

#### 2.5.5 Relationship to handles (§6)

The three rows of §1.4 share one principle — **validity is a runtime fact, not
a static proof** — realized by the cheapest mechanism each lifetime needs:

- **Owned values** (persistent): reset-on-move plus the null drop (§2.5.1). No
  generation and no per-access check — the owner holds either live bits or
  null.
- **Handles** `Handle[T]` (relationships, §6): a generation paired with a
  `SlotMap` index, checked on every access — the explicit, long-lived form for
  references that must outlive the scope that made them.
- **Borrows** (ephemeral, §3): nothing at all — they cannot outlive the scope
  that produced them, so they cannot dangle.

None of the three leans on lifetime annotations, and none leans on the move
analysis for safety; each pays only for what its lifetime actually requires.

---
