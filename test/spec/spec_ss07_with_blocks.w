//! skip
// Spec test: Section 7 — `with` Blocks (formerly 25.7)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic
fn test(lock: &Mutex[HashMap[str, i32]]):
    with lock.lock() as mut map:
        map.insert("key", 42)

// PASS: multi
fn test(a: &RwLock[Vec[i32]], b: &RwLock[Vec[i32]]):
    with a.read() as xs, b.read() as ys:
        print(xs.len() + ys.len())

// PASS: expression returning owned
fn test(lock: &Mutex[HashMap[str, i32]]) -> Option[i32]:
    with lock.lock() as map:
        map.get("key").cloned()

// FAIL: expression returning ephemeral
fn test(lock: &Mutex[Vec[i32]]):
    let r = with lock.lock() as data:
        &data[0]                  // ERROR

// PASS: collect pipeline escapes
fn test(store: &Shared[SlotMap[Texture]]) -> Vec[Handle[Texture]]:
    with store.read() as textures:
        textures.iter()
        |> filter((_h, t) => t.width > 1024)
        |> map((h, _) => h)
        |> collect()

// PASS: error propagation with implicit Ok wrapping
fn test(lock: &Mutex[File]) -> Result[Unit, IoError]:
    with lock.lock() as mut f:
        f.write_all(b"hello")?
        f.flush()?
    // implicit Ok(())

// PASS: non-local return from with block
fn find_val(lock: &Mutex[HashMap[str, i32]], key: &str) -> Option[i32]:
    with lock.lock() as map:
        match map.get(key):
            Some(v) => return Some(v)    // returns from find_val
            None    => ()
    None

// PASS: break/continue inside with block inside loop
fn process(lock: &Mutex[Vec[Item]]):
    for i in 0..10:
        with lock.lock() as items:
            if items[i].is_done():
                continue                  // continues enclosing for loop
            items[i].process()

// --- Form 2: Builder pattern (scoped mutation) ---

// PASS: basic builder
type Config { timeout: i32, retries: i32, verbose: bool }
fn test:
    let c = with Config { timeout: 0, retries: 0, verbose: false } as mut c:
        c.timeout = 30
        c.retries = 3
        c.verbose = true
    assert(c.timeout == 30)
    assert(c.retries == 3)

// PASS: builder is an expression
fn make_config -> Config:
    with Config { timeout: 0, retries: 0, verbose: false } as mut c:
        c.timeout = 30

// PASS: nested with in builder
fn test:
    let sprite = with Sprite.new() as mut s:
        s.position = Vec2.new(100.0, 200.0)
        s.health = with difficulty_mult() as mult:
            base_health * mult

// --- Form 3: Scoped binding ---

// PASS: basic scoped binding
fn test:
    let area = with shape.bounding_box() as bb:
        bb.width * bb.height
    assert(area > 0.0)

// PASS: scoped binding avoids name leakage
fn test:
    let x = with expensive_compute() as result:
        result + 1
    // `result` is not visible here

// PASS: scoped binding in pipeline context
fn test:
    let label = with user.display_name.unwrap_or(user.username) as name:
        "{name} ({user.role})"
