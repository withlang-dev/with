# 3. References and Borrowing

### 3.1 Reference Types

```
&T          shared (read-only) borrow
```

With has a single reference type: `&T`. There is no `&mut T` in safe
code. Mutation is expressed through owned values (`mut self: Self`
receivers), `with` scoped access, and `IndexPlace` projections.

For unsafe FFI, raw pointers (`*const T`, `*mut T`) and address-of
(`&raw mut x`) provide mutable pointer semantics (§19).

### 3.2 Aliasing Rule

Active shared borrows (`&T`) of a place are invalidated when that
place is mutated. Mutation occurs through:

- Assignment to the place (`x = value`)
- Calling a `mut self` method on the place (`x.push(v)`)
- Mutation through `with` scoped access or `IndexPlace` projection

Enforced at compile time via view-liveness analysis.

A `mut self` receiver is **exclusive** for the duration of the call:
an argument to the same call may not retain access to the receiver's
place — a reference to it or one of its fields, an iterator or view
over it, or a shared-representation value (`str`, slice) read from
its fields. Bind such values to a local before the call.

### 3.3 Second-Class Restriction

References are **ephemeral** (Section 5). They may appear as:

- Function parameters
- Local variable bindings
- Arguments to non-escaping closures
- Return values from functions (with ephemeral propagation; see 3.4)

References may NOT appear as:

- Struct or enum fields
- Elements of heap containers
- Captures of escaping closures
- Global or static storage

This restriction eliminates lifetime annotations entirely.

### 3.4 Returning References

A function may return a reference or a type containing a reference
(e.g., `Option[&T]`). The returned value is ephemeral: the caller may
bind it to a local and use it, but may not store it in a struct, place
it in a container, capture it in an escaping closure, or return it from
a function whose return type is not itself ephemeral.

A function whose declared return type is or contains an ephemeral type
is permitted. Both `fn foo -> StrView` and `fn bar -> Option[StrView]`
are legal. Any function that calls such a function and returns its
result must also have an ephemeral return type. This forms a chain:
ephemerality propagates upward through callers until a function
consumes the ephemeral value (by copying data out, converting to
owned, etc.) rather than returning it.

```
fn first(xs: &Vec[i32]) -> Option[&i32]:
    if xs.is_empty(): None else: Some(&xs[0])

fn caller(xs: &Vec[i32]):
    let r = first(xs)        // OK: ephemeral local binding
    match r:
        Some(v) => print(v) // OK: local use
        None    => ()

// OK: wraps ephemeral return in another ephemeral return
fn get_name(user: &User) -> StrView: user.name.as_view()

// OK: chains ephemeral through caller
fn get_name_upper(user: &User) -> StrView:
    get_name(user).to_upper_view()

// OK: consumes ephemeral, returns owned (chain ends here)
fn get_name_owned(user: &User) -> String:
    get_name(user).to_string()
```

When a function returns an ephemeral value and accepts multiple
potential origin parameters, the returned value is tracked as
borrowing from the set of parameters the body may actually derive it
from. Within one compilation this origin set is inferred from the
function body and enforced at the call site.

Across a separate-compilation boundary (a bundle interface, §18.5c) there
is no body, and the origin is the declaration's: the receiver if the
function has one, otherwise the single reference parameter. A declaration
with more than one candidate origin and no stated origin cannot cross the
boundary; the bundle build rejects it. When an API genuinely needs to
state its origin, the source language will provide an explicit spelling
(conceptually `-> &T from a`); that spelling is a language feature for
authors, never an interface-only annotation.

Carrying a view through `Option`, `Result`, a tuple, pattern projection,
or another transparent value carrier does not erase its origin.
Construction, projection, elimination, and control-flow joins preserve
the origins of every view that can flow into the resulting value. The
complete normative rule is §21.1, Rule 10.

### 3.5 Borrow Scope: Non-Lexical Lifetimes

A borrow is active from the point it is created until its **last use**,
not until the end of the enclosing block.

```
var x = 5
let r = &x
print(r)       // last use of r; borrow ends here
x = 10           // OK: no active borrow
```

### 3.6 Disjoint Field Access

The compiler guarantees that simultaneous access to structurally
disjoint fields is permitted, at any nesting depth.

```
world.physics.positions[i] = new_pos    // mutates one field
let v = &world.physics.velocities       // borrows a different field — OK
```

Disjointness is defined over **static field paths**. Two paths are
disjoint if they diverge at any field access.

**Array/slice index disjointness is NOT guaranteed at compile time.**
Use `get_disjoint(i, j)` for safe simultaneous element access.

**Disjoint capture in closures:** Closures capture only the
specific fields they access, not the enclosing struct as a whole.
This is critical for parallel data-oriented code:

```
// Each closure captures disjoint fields of `world`
scope s =>
    s.spawn(() => run_physics(world.transforms, world.velocities))
    s.spawn(() => run_render(world.transforms, world.sprites))
// OK: both closures access non-overlapping field paths.
// No conflict — the captures are disjoint.
```

Without disjoint closure capture, the above code would fail because
both closures would capture `world` as a whole, creating conflicting
borrows. With disjoint capture, the compiler sees that the two
closures access non-overlapping field paths and permits the code.

### 3.7 Auto-Dereferencing

The compiler automatically follows references, boxes, and smart
pointers to find fields and methods. You never write `(*x).field`:

```
let u: Box[User] = Box.new(User { name: "Alice" })
let name = u.name           // auto-derefs Box → User → .name

let r: &User = &alice
let name = r.name           // auto-derefs &User → .name

let rr: &&User = &&alice
let name = rr.name          // follows multiple layers automatically
```

Auto-deref applies to `&T`, `Box[T]`, `Arc[T]`, `Rc[T]`, and any
type implementing the `Deref` trait. The compiler inserts as many
dereferences as needed to reach the target field or method.

**Raw pointers:** Auto-deref also applies to `*const T` and
`*mut T`. When `p` has type `*mut Sha256`, `p.state[0]` is
equivalent to `(*p).state[0]`. The dereference is still unsafe —
the access must be inside an `unsafe` block or `unsafe fn`.

```
unsafe fn compress(ctx: *mut Sha256):
    let a = ctx.state[0]        // auto-deref: (*ctx).state[0]
    ctx.buf[3] = 0x80           // auto-deref: (*ctx).buf[3] = 0x80
```

**The vibe:** "I don't care how many layers of indirection there
are, just give me the `.name` field."

### 3.8 Auto-Referencing

When a function takes `&T` and you pass an owned `T`, the compiler
automatically borrows it:

```
fn print_user(u: &User): print(u.name)

let alice = User { name: "Alice" }
print_user(alice)           // compiler inserts &alice automatically
```

This also works for method calls: `alice.greet()` works when
`greet` takes `self: &Self`.

**Restriction:** Auto-referencing only creates shared borrows
(`&T`). Mutation uses `mut self` receivers on owned values:

```
extend User:
    fn update(mut self: Self):
        self.name = "Bob"

var alice = User { name: "Alice" }
alice.update()              // mutates in place via mut self receiver
```

**The parameter's declared type states the mode.** A `&T` parameter
borrows: auto-ref erases the sigil at the call site, and the caller's
binding remains valid afterward. A plain `T` parameter consumes: the
argument is moved into the callee (copied, for `Copy` types), and the
caller's binding is invalidated. No call-site annotation is ever
required for either mode — a plain call `f(x)` is always legal and
means whatever the signature says. `move x`, `copy x`, and `&x`
remain available as explicit spellings of intent:

```with
take(alice)        // signature take(a: User): consumes alice
peek(alice)        // signature peek(a: &User): borrows alice
take(move alice)   // explicit spelling of the same consume
dup(copy xs)       // duplicate via Copy or Clone instead of consuming
```

The mode is declared exactly once, in the signature — the boundary
where §4.6 already requires explicitness — and never at call sites.
A function that only reads a by-value parameter, or returns a view
derived from one, should take `&T` instead; when the compiler can see
this mistake (for example, a view of a consumed parameter escaping
through the return value), it emits a directed suggestion naming the
parameter and the `&T` fix.

**Contextual Copy materialization (D22).** A shared reference `&T` remains
`&T` during inference and exact-type propagation, including an unannotated
binding, an inferred return, pattern projection, and closure capture. `Copy`
does not silently erase reference identity.

A binding names what's there; an annotation demands what it says: an
unannotated `let` binds the view unchanged, while a typed binding is an
owned-value demand (D22 §6.2, D27). This is uniform across field
projections and collection element access.

When `T: Copy`, an expression of type `&T` may satisfy an independently
established owned-value demand. The compiler copies the pointee, then applies
ordinary value coercions. Thus an `&i32` may satisfy an owned `i32` or `i64`
demand. The produced value is independent of the reference's origin; the
source reference remains borrowed if it is used again.

An owned-value demand is established independently by:

1. an explicit binding, assignment, cast, field, element, or declared return
   type;
2. a resolved by-value parameter, constructor component, or receiver;
3. a resolved operator operand or result type; or
4. the join rule below.

Inference alone does not create an owned demand. In particular, `let x =
view`, an inferred function return (§9.1), a pattern binding, or a closure
capture preserves the reference type. Method and overload resolution first
preserve reference identity and apply ordinary auto-dereferencing; contextual Copy
materialization may satisfy an already-selected by-value receiver but does not
change receiver dispatch or ABI.

At an `if`, `match`, `??`, array-literal, or equivalent multi-expression type
join:

1. If all reaching expressions have the same type, that type is preserved.
2. If an enclosing expected type or any reaching expression independently
   establishes an owned result type `J`, the join result is `J`. Every
   compatible `&T` expression is contextually materialized when `T: Copy`,
   then ordinarily coerced to `J`. A single owned expression is sufficient,
   and arm order does not affect the result.
3. If all reaching expressions are compatible shared references, the result
   remains a shared reference and carries the union of their possible origins.
4. An owned temporary is never implicitly borrowed merely to force a
   reference result.
5. A reference to a non-`Copy` value cannot satisfy an owned demand;
   producing an independent value requires an explicit owning operation such
   as `clone`.

Removing or changing the last owned expression may cause an inferred join to
preserve `&T` instead. This is an ordinary inferred-type change, but it changes
view-origin obligations. An explicit surrounding result type pins the join
across such edits. When a later diagnostic depends on whether a join preserved
views or materialized owned values, the diagnostic must identify the
expression that established the owned join and every relevant arm that was
materialized. Clean builds do not emit coercion notes.

```
let count = counts.get("api").unwrap()          // &i32
let snapshot: i32 = counts.get("api").unwrap() // independent i32
let port = counts.get("port") ?? 8080           // i32: owned arm anchors join

let selected = match source:
    .Api      => counts.get("api").unwrap()      // &i32 -> i32
    .Worker   => counts.get("worker").unwrap()   // &i32 -> i32
    .Queue    => counts.get("queue").unwrap()    // &i32 -> i32
    .Fallback => counts.get("fallback").unwrap() // &i32 -> i32
    .Computed => compute_count()                  // i32 anchors the join
// selected: i32

// Pin the intended result if later arm edits must not change it:
let stable_count: i32 = match source:
    .Api      => counts.get("api").unwrap()
    .Worker   => counts.get("worker").unwrap()
    .Queue    => counts.get("queue").unwrap()
    .Fallback => counts.get("fallback").unwrap()
    .Computed => compute_count()
```

Raw pointers do not participate. Dereferencing a raw pointer still requires
`unsafe` (§19). This rule generalizes the former call-site-only Copy read. It
does not introduce an ambient reference-to-value inference coercion.

**The vibe:** "The function just wants to look at the data. I
shouldn't have to manually type `&`."

### 3.9 Implicit Trait Object Coercion

When a function takes `&dyn Trait` and you pass `&T` where `T`
implements the trait, the compiler coerces automatically. No cast
needed — if it implements the trait, just pass it:

```
trait Logger:
    fn log(self: &Self, msg: &str)
type ConsoleLog {}
impl Logger for ConsoleLog:
    fn log(self: &Self, msg: &str): print(msg)

fn process(logger: &dyn Logger): logger.log("processing")

let my_log = ConsoleLog {}
process(&my_log)            // auto-coerces &ConsoleLog → &dyn Logger
```

This is the Go interface feel — structural satisfaction, implicit
coercion. The same applies to `Box[T]` → `Box[dyn Trait]`:

```
let logger: Box[dyn Logger] = Box.new(ConsoleLog {})  // auto-coerced
```

**The vibe:** "It implements the trait. Just take it."

---
