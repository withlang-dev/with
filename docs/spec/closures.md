# 12. Closures and Escaping

A closure may state its result type as a function does: `(x: i32) -> str
=> f"{x}"`. The annotation is checked like a declared return type — the body
must produce that type — and it is never dropped.

### 12.1 Non-Escaping Closures

A closure is **non-escaping** if passed directly as an argument to a
function that consumes it synchronously. Non-escaping closures may
capture ephemeral values.

### 12.2 Escaping Closures

A closure is **escaping** if stored, returned, or sent to another
thread. Escaping closures may NOT capture ephemeral values.

### 12.3 Precise Rules (v1.0)

A closure is non-escaping if and only if it appears as a **direct
argument to a function call**. All other closures are escaping.

Specifically, the following are all **escaping** in v1.0:

```
let f = x => x + 1           // bound to a named variable: escaping
let closures = [x => x]  // stored in a container: escaping
return x => x + 1            // returned from function: escaping
some_struct.callback = x => x // stored in a field: escaping
```

The following are **non-escaping**:

```
items.for_each(x => print(x))      // direct argument: non-escaping
items |> filter(x => x > 0)          // direct argument: non-escaping
with lock.read() as data:           // with block body: non-escaping
    data.iter() |> map(x => x + 1)   // direct argument: non-escaping
```

This is deliberately conservative. A closure bound to a named local
variable is treated as escaping even if analysis could prove it never
escapes the scope. This avoids complex escape analysis in v1.0 and
can be relaxed in future versions.

### 12.4 Capture Semantics and Effects

Closure captures are **by place**. Unlike function parameters
(§3.8), whose mode is declared in the signature, a closure body sits
lexically next to the variables it captures — by-place capture stays
visible to the reader, so no signature is needed:

- Captures are by place regardless of whether the type is `Copy`; a
  read through a capture of a `Copy` value copies it. The closure
  observes, mutates or consumes the original place according to its
  body.
- `move ||` transfers ownership, which for a `Copy` value is a copy.

Closure bodies receive inferred effect summaries over their captures.
Invoking a closure is checked exactly like invoking a function: if a
closure consumes, mutates, returns, or returns a view derived from a
capture, those effects apply to the originating captured place. A
capture is therefore one of three kinds of view of its place — read,
mutate, or consume. A closure that consumes a capture is a consuming
view: it may be invoked once, and that invocation moves the captured
place; if it is never invoked, the place remains owned and is dropped
by its own scope.

A non-`move` closure holds a view of each captured place while it is
alive, under the ordinary exclusivity rules (§5): mutating a place in
the enclosing scope while a closure holding a read capture of it is
alive is an error. A snapshot is spelled `move ||`.

A `move ||` closure owns its environment: it is an ordinary value that
may be returned, stored, or sent across a channel when every capture
is `Send`. A non-`move` closure is a view of its frame (§12.2) and may
not be returned.

**The callable type.** A callable value has type `fn(A) -> R` whether
it is a function, a non-`move` closure, or a `move ||` closure. There
is no second closure type and no trait split. The compiler tracks
which kind a value is, as it tracks `may_suspend` (§14): a non-`move`
closure is ephemeral (§5); a `move ||` closure owns its environment
and drops it, so a struct holding one has `Drop` and cannot be `Copy`;
a consuming closure may be invoked once.

- `fn(A) -> R` is not `Copy`, including for a bare function: `let g =
  f` moves `f`. Calling through a binding or a field observes it and
  does not move. `.clone()` is free for a bare function or a non-`move`
  closure and requires every capture `Clone` for a `move ||` closure.
  A use of a moved callable is diagnosed with `.clone()` and
  calling through the original as the fix-its.
- A consuming closure may only be handed to a callee that invokes it
  at most once. Within one compilation the compiler proves this from
  the callee's body. Across a bundle boundary (§3.4) a parameter may
  be invoked any number of times, so a consuming closure passed across
  a bundle is rejected until a `once` parameter annotation exists
  (deferred).
- A non-`move` closure passed as an argument is ephemeral in the callee
  exactly as a `&T` parameter is (Rule 8, §22.1): it may be invoked and
  passed on, and may not be stored, returned, or captured by a
  `move ||` closure.
- A call through `fn(A) -> R` is an indirect call through the pair.
  When a closure literal reaches a parameter within one compilation,
  the compiler specializes the callee and the call is direct. Only a
  captureless closure coerces to an `extern "C"` function pointer
  (§14.19): C receives the code pointer alone.

```with
let xs = Vec.new()
let f = || xs.push(1)   // capture effect on xs: {write}
f()                     // mutates xs

var n = 42
let g = || n += 1       // n is captured by place: {write}
g()                     // n is 43

let k = 42
let s = move || k + 1   // move: s holds its own copy of k
let m = s()             // k unchanged, m is 43

let owned = Vec.from([1, 2, 3])
let h = move || owned.len()
// owned is invalid after closure creation; h owns it

let ys = Vec.from([1])
let c = || take(ys)     // consuming view of ys
c()                     // moves ys; a second c() is an error
```

---
