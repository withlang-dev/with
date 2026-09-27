# 20b. Denied Patterns (Compile Errors)

With forbids patterns that are almost always bugs and have clean
alternatives. These are compile errors, not warnings. The philosophy:
if a pattern is wrong 99% of the time, don't warn — forbid.

### 20b.1 `.await` Inside `@[no_await_guard]` Guard

Types annotated `@[no_await_guard]` (synchronization guards like
`MutexGuard`, `ReadGuard`, `WriteGuard`, `ArenaScope`) must not be
held across suspension points. Holding a mutex across `.await` blocks
all other fibers waiting for that lock.

```
// ERROR: RwLock guard is @[no_await_guard]
with lock.read() as data:
    fetch(data.url).await

// FIX: clone out, release guard, then await
let url = with lock.read() as data:
    data.url.clone()
fetch(url).await
```

This does NOT apply to connection pools, transactions, file handles,
or other guarded types that don't carry the annotation. See §7.9.

### 20b.2 Task Disposition

A task in statement position is intentional fire-and-forget
detachment, allowed only when the API does not require observation and
the compiler proves the task can safely outlive the current scope.

```
// OK when `send_analytics` is best-effort and detach-safe:
send_analytics("page_view")

// OK: await the result:
send_invoice(invoice).await?

// OK: explicit cancellation:
let task = warm_cache(key)
cancel(task)

// ERROR: a bound handle says "I will observe this"
let task = send_invoice(invoice)

// ERROR: not the detach spelling
let _ = send_analytics("page_view")
```

When detachment is rejected, the diagnostic must say whether the task
is must-observe or whether detach-safety failed, because the remedies
are different.

See §14.7.

### 20b.3 Unnecessary `unsafe` Block

An `unsafe` block with no unsafe operations dilutes the safety
signal.

```
// ERROR:
unsafe { let x = 1 + 2 }

// FIX: remove the unsafe block
let x = 1 + 2
```

See §19.4.

### 20b.4 Implicit Numeric Narrowing

Assigning a wider type to a narrower type silently truncates.

```
// ERROR:
let big: i64 = 100000
let small: i32 = big

// FIX: explicit cast
let small: i32 = big as i32
```

Signed/unsigned conversions at the same width also require `as`.
See §4.2.

### 20b.5 Unreachable Code

Code after an unconditional `return`, labeled or unlabeled `break`,
labeled or unlabeled `continue`, `goto`, or diverging expression is
dead. It is always either a bug or leftover from refactoring.

```
// ERROR:
fn example -> i32:
    return 42
    print("hello")    // unreachable

// ERROR:
for x in items:
    if should_skip(x):
        continue
        log("skipped")  // unreachable
```

The compiler detects unreachable code via control flow analysis and
rejects it. This applies to all code after unconditional control
flow transfers, including `return`, labeled or unlabeled `break`,
labeled or unlabeled `continue`, `goto`, and calls to functions with
return type `Never` (e.g., `exit()`, `panic()`).

A labeled statement may be reachable only via `goto`. Ordinary
unreachable-code diagnostics are suppressed for a labeled statement
and for following statements until the next control-flow terminator
or the next labeled statement:

```
fn example:
    goto 'done
    print("never")    // unreachable
    'done
    print("finished") // reachable via goto
```

**Exception for `comptime if`:** The unreachable code check runs
**after** comptime evaluation. Branches eliminated by `comptime if`
are erased before the check, so code that is only unreachable due
to comptime decisions does not trigger an error:

```
comptime if cfg.is_debug:
    return debug_value()
// In debug builds, this code is erased — no "unreachable" error
// In release builds, comptime if is false — code is reachable
let result = expensive_computation()
```

### 20b.6 Pointer Compared to Array
Arrays never implicitly decay to pointers, so comparing a pointer
directly with an array is rejected:

```
// ERROR:
ptr == arr
```

Use explicit decay (`&arr[0] as *const T`). See §4.3a.1.

---
