# 7.9 `with` Idioms and Rules

**`@[no_await_guard]` enforcement is NLL-based, not syntax-based:**

Some synchronization guard types must not be held across suspension
points — holding a mutex lock while a fiber suspends blocks all
other fibers waiting for that lock. These types are annotated
`@[no_await_guard]`:

```
@[no_await_guard]
type MutexGuard[T] { ... }

@[no_await_guard]
type ReadGuard[T] { ... }

@[no_await_guard]
type WriteGuard[T] { ... }
```

The compiler rejects any same-fiber operation that may suspend the
current fiber while a `@[no_await_guard]` value is **live in the NLL
sense** — regardless of whether it was created via `with` or a plain
`let` binding (see Invariant 5, §14.3):

```
// ERROR: guard is live across .await (via with block)
with lock.read() as data:
    let result = fetch(data.url).await   // compile error E0701

// ERROR: guard is live across .await (via plain let binding)
let guard = lock.lock()
let data = guard.deref()
fetch(data.url).await                    // compile error E0701!
//              ^^^^^^ @[no_await_guard] MutexGuard is live

// ERROR: helper() is may_suspend (it contains .await internally)
with lock.read() as data:
    let result = helper(data.url)        // compile error E0701
    //           ^^^^^^ same-fiber may_suspend call while
    //                  @[no_await_guard] ReadGuard is live

// FIX: drop guard before awaiting
let snapshot = with lock.read() as data:
    data.clone()
// guard dropped here
let result = fetch(snapshot.url).await   // OK: no guard live
```

Other guarded types — connection pools, transactions, file handles
— are not annotated and work naturally with `await`:

```
// OK: ConnectionPool's guard is NOT @[no_await_guard]
with self.pool.acquire() as conn:
    let row = conn.query("SELECT ...").await?   // fine
    Ok(row_to_user(row))

// OK: Transaction guard is NOT @[no_await_guard]
with conn.begin() as tx:
    tx.execute("INSERT ...").await?
    tx.execute("UPDATE ...").await?
    tx.commit()
```

This is the correct distinction. A connection pool lease does not
block other fibers from acquiring their own connections — holding it
across `await` is the entire point. A mutex lock does block other
fibers — holding it across `await` is almost always a bug.

| Type | `@[no_await_guard]` | `.await` in `with`? |
|------|---------------------|-------------------|
| `Mutex[T]` guard | Yes | **Error** |
| `RwLock[T]` guard | Yes | **Error** |
| `Arena` scope | Yes | **Error** |
| `ConnectionPool` lease | No | Fine |
| `Transaction` | No | Fine |
| `File` | No | Fine |

Standard library types that carry `@[no_await_guard]`: `MutexGuard`,
`MutexGuardMut`, `RwReadGuard`, `RwWriteGuard`, and `ArenaScope`.
Library authors should apply this annotation to any guard type that
blocks shared access while held.

The standard `Condvar.wait(lock)` operation is special: when it is called
inside the guarded `with lock.enter_mut() as state:` protocol for the
same `lock`, the wait operation releases that lock before yielding and
reacquires it before returning. That associated-lock wait is allowed.
Waiting while any unrelated `@[no_await_guard]` value is live remains an
error.

Forms 2, 3, and 3a (`with expr as mut name:`, `with expr as name:`,
and `with name(expr):`) are unaffected — they do not create a guard
value and therefore introduce no `@[no_await_guard]` obligation by
themselves.

**Clone at boundary:**

Escaping data from a guarded `with` block requires the data to be
owned, not borrowed. This means cloning is the standard pattern for
extracting values from behind a guard:

```
// Clone at boundary: the idiomatic pattern
let name = with db.read() as users:
    users.get(id)
        .map(u => u.name.clone())   // clone to escape the guard

// If the value is Copy, no explicit clone needed:
let count = with store.read() as data:
    data.len()                      // Int is Copy, escapes freely
```

This is by design — the clone marks the exact point where borrowed
data becomes owned data. Library authors should provide `.cloned()`
and `.copied()` convenience methods on iterators and Option/Result
to make this ergonomic.

---
