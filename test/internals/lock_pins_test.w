//! expect-stdout: ok
// #2355: with.toml says what a project depends on; the lock records how.
// A bare `with get c.<pkg>` bumped an existing pin to the newest version,
// and a restore (`with get`) installed the lock's version over an edited
// with.toml. A restore now installs an exact pin the lock does not hold.
use compiler.LockFile

fn main:
    assert(lock_pin_is_exact("1.3.1"))
    assert(not lock_pin_is_exact("[>=3 <4]"))
    assert(not lock_pin_is_exact("^1.2"))
    assert(not lock_pin_is_exact(""))
    var lock = lock_empty()
    var e = lock_entry_none()
    e.name = "c.zlib"
    e.version = "1.3.2"
    lock.entries.push(e)
    assert(lock_holds_pin(&lock, "zlib", "1.3.2"))
    // with.toml edited back to 1.3.1: the lock does not hold it.
    assert(not lock_holds_pin(&lock, "zlib", "1.3.1"))
    assert(not lock_holds_pin(&lock, "bzip2", "1.0.8"))
    print("ok")
