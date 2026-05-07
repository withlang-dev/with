//! skip: non-executable spec sketch for Section 20b — Denied Patterns (formerly 25.30); contains pseudo-code for unimplemented feature work
// Spec test: Section 20b — Denied Patterns (formerly 25.30)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: await inside @[no_await_guard] with
fn test:
    let lock = RwLock.new(42)
    with lock.read() as data:
        sleep(Duration.millis(1)).await    // ERROR: ReadGuard is @[no_await_guard]

// PASS: await inside non-@[no_await_guard] with
async fn test(pool: &ConnectionPool):
    with pool.acquire() as conn:
        let row = conn.query("SELECT 1").await?  // OK: Connection not @[no_await_guard]
        Ok(row)

// FAIL: unused Result
fn fallible -> Result[i32, String]: Ok(1)
fn test:
    fallible()              // ERROR: unused Result

// PASS: explicitly discarded Result
fn fallible -> Result[i32, String]: Ok(1)
fn test:
    let _ = fallible()      // OK: intentional discard

// FAIL: unused Task
async fn background -> Unit: ()
fn test:
    background()             // ERROR: unused Task

// PASS: explicitly discarded Task
async fn background -> Unit: ()
fn test:
    let _ = background()     // OK: intentional discard

// FAIL: unnecessary unsafe
fn test:
    unsafe { let x = 1 + 2 }   // ERROR: no unsafe operations

// FAIL: implicit narrowing
fn test:
    let big: i64 = 42
    let small: i32 = big        // ERROR: implicit narrowing

// PASS: explicit narrowing
fn test:
    let big: i64 = 42
    let small: i32 = big as i32  // OK: explicit cast

// PASS: implicit widening
fn test:
    let small: i32 = 42
    let big: i64 = small         // OK: widening is lossless

// FAIL: signed/unsigned at same width
fn test:
    let x: i32 = 42
    let y: u32 = x               // ERROR: sign conversion requires as

// FAIL: unreachable code after return
fn test -> i32:
    return 42
    print("hello")             // ERROR: unreachable

// FAIL: unreachable code after break
fn test:
    for x in 0..10:
        break
        print("hello")        // ERROR: unreachable

// FAIL: unreachable code after continue
fn test:
    for x in 0..10:
        continue
        print("hello")        // ERROR: unreachable

// PASS: conditionally reachable code
fn test(flag: bool) -> i32:
    if flag: return 42
    print("still reachable")   // OK: return is conditional
    0
