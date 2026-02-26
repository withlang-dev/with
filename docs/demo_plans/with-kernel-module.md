# withkmod — A Linux Kernel Module in With

## 1. What to Build

**`/dev/ringbuf`** — a character device that implements a lock-free
(well, lock-*safe*) shared ring buffer.

Why this module:

- It's the "first real kernel module" that every systems programmer
  recognizes. Nobody has to wonder what it does.
- It exercises every kernel API pattern: char device registration,
  file_operations vtable, ioctl, sysfs, spinlocks, wait queues,
  copy_to_user/copy_from_user, kmalloc/kfree.
- It's small enough to read in 10 minutes. Target: under 400 lines.
- The locking story is the whole pitch.

What it does:

- `open("/dev/ringbuf")` — get a file descriptor
- `write(fd, data, len)` — push bytes into the ring buffer
- `read(fd, buf, len)` — pull bytes out (blocks if empty)
- `ioctl(fd, RINGBUF_RESET)` — clear the buffer
- `ioctl(fd, RINGBUF_STATS)` — get stats (bytes written, read,
  overflows, current fill level)
- `/sys/module/ringbuf/parameters/bufsize` — configurable buffer
  size (module parameter, default 4096)

Multiple processes can write. Multiple processes can read. The
ring buffer is shared. Reads are consuming (what one reader takes,
another won't see). Writes to a full buffer return `-EAGAIN` or
block depending on `O_NONBLOCK`.

---

## 2. Why This is Hard in C (and Where With Helps)

### 2.1 The Lock Problem

Every kernel developer has written this bug:

```c
spin_lock(&ring->lock);
if (ring->count == 0) {
    // Oops — forgot to unlock before returning
    return -EAGAIN;
}
data = ring->buf[ring->tail];
ring->tail = (ring->tail + 1) % ring->size;
ring->count--;
spin_unlock(&ring->lock);
```

In With, this is impossible:

```with
fn read_byte(ring: &mut RingBuf) -> Result[u8, KernelError] =
    with ring.lock:        // acquires spinlock
        if ring.count == 0:
            return Err(.Again)  // lock released by `with` block
        let byte = ring.buf[ring.tail]
        ring.tail = (ring.tail + 1) % ring.size
        ring.count -= 1
        Ok(byte)
    // lock released here too — every exit path is covered
```

The `with` block guarantees unlock on every exit path: normal
return, early return, error propagation with `?`, even panic
(if the kernel module uses a panic handler). This isn't just
syntactic sugar — it's a class of kernel bugs eliminated at
compile time.

### 2.2 The Vtable Problem

Linux kernel modules work by filling in C structs of function
pointers (`file_operations`, `device_operations`, etc.). In C:

```c
static const struct file_operations ringbuf_fops = {
    .owner   = THIS_MODULE,
    .open    = ringbuf_open,
    .release = ringbuf_release,
    .read    = ringbuf_read,
    .write   = ringbuf_write,
    .unlocked_ioctl = ringbuf_ioctl,
};
```

In With, this is a struct literal — the same pattern, but
type-checked:

```with
const RINGBUF_FOPS: file_operations = .{
    .owner   = THIS_MODULE,
    .open    = ringbuf_open,
    .release = ringbuf_release,
    .read    = ringbuf_read,
    .write   = ringbuf_write,
    .unlocked_ioctl = ringbuf_ioctl,
}
```

Nearly identical. The difference: if you misspell a field name
or pass a function with the wrong signature, With catches it.
C silently zero-initializes the field and you get a null
function pointer crash at runtime.

### 2.3 The Error Handling Problem

Kernel C uses negative errno integers for errors. It's easy to
forget to check one, or to return the wrong sign, or to leak
a resource on an error path.

With's `Result` type + `?` propagation makes every error path
explicit:

```with
fn ringbuf_init() -> Result[void, KernelError] =
    let major = register_chrdev(0, "ringbuf", &RINGBUF_FOPS)?
    let buf = kmalloc(bufsize, GFP_KERNEL)?   // returns Err on OOM
    // if kmalloc fails, register_chrdev is already committed
    // so we need cleanup — this is where `defer` shines:
    // (see §3 for the full init pattern)
    Ok(())
```

### 2.4 copy_to_user / copy_from_user

These are the kernel ↔ userspace boundary. In C, you must check
the return value (bytes NOT copied) and handle partial transfers.
Everyone forgets at least once.

```with
fn read_to_user(user_buf: UserPtr[u8], data: &[u8]) -> Result[usize, KernelError] =
    let not_copied = copy_to_user(user_buf, data.as_ptr(), data.len())
    if not_copied != 0:
        Err(.Fault)
    else:
        Ok(data.len())
```

`UserPtr[T]` is a With wrapper type for `__user` pointers. You
can't accidentally dereference it directly — you must go through
`copy_to_user` / `copy_from_user`. This is a compile-time
enforcement of a rule that C enforces with sparse annotations
that most people ignore.

---

## 3. The Full Module Skeleton

This is the target structure. ~350–400 lines of With.

```with
// ringbuf.w — A shared ring buffer character device
//
// Load:   sudo insmod ringbuf.ko bufsize=8192
// Use:    echo "hello" > /dev/ringbuf
//         cat /dev/ringbuf
// Stats:  cat /sys/module/ringbuf/stats

use c_import("linux/module.h")
use c_import("linux/fs.h")
use c_import("linux/cdev.h")
use c_import("linux/uaccess.h")
use c_import("linux/slab.h")
use c_import("linux/wait.h")
use c_import("linux/sched.h")
use c_import("linux/ioctl.h")

// ─── Module metadata ──────────────────────────────────────

module_license("GPL")
module_author("you")
module_description("Ring buffer character device — written in With")

// ─── Module parameter ─────────────────────────────────────

var bufsize: u32 = 4096
module_param(bufsize, uint, 0644)

// ─── Types ────────────────────────────────────────────────

type RingBuf = {
    buf: *mut u8,             // kernel-allocated buffer
    size: u32,                // bufsize
    head: u32,                // write position
    tail: u32,                // read position
    count: u32,               // bytes currently in buffer
    lock: SpinLock,           // protects all fields above
    read_wait: WaitQueueHead, // readers block here when empty

    // stats
    total_written: u64,
    total_read: u64,
    overflows: u64,
}

// ─── Globals ──────────────────────────────────────────────

var ring: RingBuf = undefined   // initialized in module_init
var major: i32 = 0

// ─── Init / Exit ──────────────────────────────────────────

@[init]
fn ringbuf_init() -> Result[void, KernelError] =
    ring.buf = kmalloc(bufsize as usize, GFP_KERNEL)?
    ring.size = bufsize
    ring.head = 0
    ring.tail = 0
    ring.count = 0
    ring.lock = SpinLock.new()
    ring.read_wait = WaitQueueHead.new()
    ring.total_written = 0
    ring.total_read = 0
    ring.overflows = 0

    major = register_chrdev(0, "ringbuf", &RINGBUF_FOPS)?

    pr_info("ringbuf: loaded, major={major}, bufsize={bufsize}\n")
    Ok(())

@[exit]
fn ringbuf_exit() =
    unregister_chrdev(major, "ringbuf")
    kfree(ring.buf)
    pr_info("ringbuf: unloaded\n")

// ─── File operations ──────────────────────────────────────

const RINGBUF_FOPS: file_operations = .{
    .owner   = THIS_MODULE,
    .open    = ringbuf_open,
    .release = ringbuf_release,
    .read    = ringbuf_read,
    .write   = ringbuf_write,
    .unlocked_ioctl = ringbuf_ioctl,
}

fn ringbuf_open(inode: *inode, file: *file) -> i32 =
    0  // nothing to do on open

fn ringbuf_release(inode: *inode, file: *file) -> i32 =
    0  // nothing to do on close

fn ringbuf_read(
    file: *file,
    user_buf: UserPtr[u8],
    count: usize,
    offset: *loff_t,
) -> isize =
    // Block until data is available (unless O_NONBLOCK)
    if file.f_flags & O_NONBLOCK != 0:
        with ring.lock:
            if ring.count == 0:
                return -EAGAIN
    else:
        wait_event_interruptible(ring.read_wait, ring.count > 0)?

    // Read up to `count` bytes
    var bytes_read: usize = 0
    var local_buf: [u8; 256] = undefined  // stack buffer for batching

    with ring.lock:
        let to_read = min(count, ring.count as usize, local_buf.len())
        for i in 0..to_read:
            local_buf[i] = ring.buf[ring.tail]
            ring.tail = (ring.tail + 1) % ring.size
        ring.count -= to_read as u32
        ring.total_read += to_read as u64
        bytes_read = to_read

    // Copy to userspace (outside the lock — good practice)
    let not_copied = copy_to_user(user_buf, &local_buf, bytes_read)
    if not_copied != 0:
        return -EFAULT

    bytes_read as isize

fn ringbuf_write(
    file: *file,
    user_buf: UserPtr[u8],
    count: usize,
    offset: *loff_t,
) -> isize =
    var local_buf: [u8; 256] = undefined
    let to_write = min(count, local_buf.len())

    // Copy from userspace (outside the lock)
    let not_copied = copy_from_user(&mut local_buf, user_buf, to_write)
    if not_copied != 0:
        return -EFAULT

    with ring.lock:
        var written: usize = 0
        for i in 0..to_write:
            if ring.count >= ring.size:
                ring.overflows += 1
                break
            ring.buf[ring.head] = local_buf[i]
            ring.head = (ring.head + 1) % ring.size
            ring.count += 1
            written += 1
        ring.total_written += written as u64

        // Wake up blocked readers
        wake_up_interruptible(&ring.read_wait)

        written as isize

fn ringbuf_ioctl(
    file: *file,
    cmd: u32,
    arg: u64,
) -> i64 =
    match cmd
        RINGBUF_RESET ->
            with ring.lock:
                ring.head = 0
                ring.tail = 0
                ring.count = 0
            0

        RINGBUF_STATS ->
            let stats = with ring.lock:
                RingBufStats {
                    total_written: ring.total_written,
                    total_read: ring.total_read,
                    overflows: ring.overflows,
                    current_fill: ring.count as u64,
                    capacity: ring.size as u64,
                }
            let not_copied = copy_to_user(
                arg as UserPtr[RingBufStats],
                &stats,
                size_of[RingBufStats](),
            )
            if not_copied != 0: -EFAULT else: 0

        _ -> -ENOTTY

// ─── IOCTL definitions ───────────────────────────────────

const RINGBUF_MAGIC: u8 = 'R' as u8
const RINGBUF_RESET: u32 = io(RINGBUF_MAGIC, 0)
const RINGBUF_STATS: u32 = ior(RINGBUF_MAGIC, 1, size_of[RingBufStats]())

type RingBufStats = {
    total_written: u64,
    total_read: u64,
    overflows: u64,
    current_fill: u64,
    capacity: u64,
}
```

---

## 4. What This Showcases

### 4.1 `with` Blocks = Lock Safety

The centerpiece. Every spinlock acquisition is a `with` block.
Every exit path (normal, early return, error, break) releases
the lock. Count the lock acquisitions in the module: there are
7. In C, that's 7 places to forget an unlock. In With, it's 0.

This is not theoretical. CVE databases are full of kernel lock
bugs. The `with` block pattern makes them structurally impossible.

### 4.2 `c_import` = Zero Bindings

Seven `c_import` lines replace what would be hundreds of lines
of bindgen output or hand-written extern declarations. The kernel
headers are used directly. No FFI layer, no build system
complexity, no version skew.

### 4.3 Result Types in Kernel Space

`kmalloc` returning `Result` instead of a raw pointer that you
must null-check is a small thing, but it means "forgot to check
for OOM" is a compile error, not a null pointer dereference
in production.

### 4.4 `UserPtr[T]` = Compile-Time Boundary Enforcement

You cannot accidentally dereference a userspace pointer in kernel
space. The type system requires you to go through `copy_to_user`
/ `copy_from_user`. This enforces a rule that C enforces via
`__user` annotations, which are only checked if you run sparse
(most people don't).

### 4.5 String Interpolation in `pr_info`

Small but visible:

```with
pr_info("ringbuf: loaded, major={major}, bufsize={bufsize}\n")
```

vs C:

```c
pr_info("ringbuf: loaded, major=%d, bufsize=%u\n", major, bufsize);
```

No format string bugs. No `%d` vs `%u` vs `%lu` mismatches.

---

## 5. What to Be Honest About

This showcase only works if you're transparent about the rough
edges. Lying about them will destroy credibility with kernel
developers, who are the most skeptical audience you'll face.

### 5.1 Raw Pointers Are Everywhere

Kernel code is fundamentally pointer-heavy. `ring.buf` is a
`*mut u8`. The file_operations callbacks receive raw `*inode`
and `*file` pointers. With's ownership model can't track these
because the kernel owns the lifetime, not your code.

**Be honest:** "With doesn't make raw pointers safe. It makes
everything *around* the raw pointers safe — the locks, the
error paths, the resource cleanup. The pointers themselves are
the kernel's responsibility."

### 5.2 Global Mutable State

The `ring` global is `var` (mutable) and accessed from multiple
kernel threads. With's borrow checker can't help here because
kernel threads aren't With-managed fibers. The spinlock is the
safety mechanism, and With can enforce that you hold it (via
`with`), but it can't *prevent* you from accessing ring fields
without it.

**Possible future improvement:** A `Locked[T]` wrapper type
where the inner `T` is only accessible inside a `with` block.
This would make unprotected access a compile error. Note this
in the README as a direction, not a shipped feature (unless
you want to build it for launch — it's a small addition to the
type system and it would be a genuine innovation).

### 5.3 Module Macros

`module_license`, `module_param`, `module_init`, `module_exit`
are C preprocessor macros that emit specific ELF section
attributes. With needs either:

- Comptime-evaluated equivalents that emit the right attributes
  in the generated C, or
- A thin C shim file that provides the boilerplate, with With
  supplying the actual logic

The second option is more honest for v1. A 20-line C shim
that handles module registration, with the actual module logic
in With. The shim is boilerplate; the logic is where bugs live.

### 5.4 No Kernel CI

You can't unit test a kernel module the same way you test
userspace code. Testing means: build, insmod, exercise from
userspace, check dmesg, rmmod. Provide a test script:

```bash
#!/bin/bash
set -e
make
sudo insmod ringbuf.ko bufsize=1024
echo "hello from With" > /dev/ringbuf
RESULT=$(cat /dev/ringbuf)
[ "$RESULT" = "hello from With" ] && echo "PASS" || echo "FAIL"
sudo rmmod ringbuf
dmesg | tail -5
```

---

## 6. Build System

The kernel build system (kbuild) expects C source files. With
compiles to C. This is actually a natural fit:

```makefile
# Makefile for ringbuf kernel module

obj-m := ringbuf.o

# Step 1: compile With → C
ringbuf.c: ringbuf.w
	with build --emit-c --target=kernel ringbuf.w -o ringbuf.c

# Step 2: let kbuild compile C → .ko
all: ringbuf.c
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
	rm -f ringbuf.c
```

The `--target=kernel` flag tells the With compiler:

- Don't link libc
- Don't emit a `main()`
- Use kernel-compatible codegen (no floating point in kernel
  space, no stack protector unless kernel config says so)
- Emit `#include <linux/...>` instead of `#include <stdlib.h>`

This flag is a small addition to the compiler but it makes the
kernel story clean.

---

## 7. The README

The README is as important as the code. It should be short and
structured as:

1. **What this is** — a Linux kernel module written in With
2. **Build & run** — 4 commands (make, insmod, echo, cat)
3. **The code** — link to ringbuf.w with a "read it, it's 350 lines"
4. **Why With for kernel modules** — the `with` block / lock safety
   pitch, in 3 paragraphs
5. **What's still hard** — honest about raw pointers, global state,
   and the C shim
6. **What's next** — `Locked[T]`, more kernel APIs wrapped

No marketing speak. Kernel developers will close the tab
instantly if they smell hype. Let the code do the talking.

---

## 8. Stretch Goal: `Locked[T]`

If you have time, this is the feature that would make kernel
developers actually sit up:

```with
// T is only accessible inside a `with` block on the lock
type Locked[T] = {
    inner: T,          // private — cannot access directly
    lock: SpinLock,
}

extend Locked[T]
    fn new(value: T) -> Locked[T] =
        .{ inner: value, lock: SpinLock.new() }

    // The `with` block yields a &mut T while holding the lock
    fn with[R](self: &mut Self, body: fn(&mut T) -> R) -> R =
        self.lock.acquire()
        defer self.lock.release()
        body(&mut self.inner)
```

Usage:

```with
var ring: Locked[RingBuf] = Locked.new(RingBuf.empty(bufsize))

// This is the ONLY way to touch ring's fields:
fn ringbuf_read(...) -> isize =
    ring.with |r|:
        if r.count == 0:
            return -EAGAIN
        let byte = r.buf[r.tail]
        r.tail = (r.tail + 1) % r.size
        r.count -= 1
        byte as isize

// This does NOT compile:
// ring.inner.count   // error: `inner` is private
```

This makes unprotected access a **compile error**. Not a
convention. Not a comment. Not a sparse annotation. A hard
type error. No systems language currently offers this at the
kernel module level.

If you ship `Locked[T]` working in the kernel module demo,
that's the headline. Everything else is supporting evidence.

---

*withkmod — Plan v0.1*