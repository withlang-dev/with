// With Language Fiber Runtime
// Minimal M:1 fiber scheduler for async/await support.

#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>
#include <signal.h>
#include <setjmp.h>

// ── Fiber context (must match assembly layout) ─────────────────────

typedef struct {
    uint64_t regs[13]; // x19-x28, x29(fp), x30(lr), sp
    double   fpregs[8]; // d8-d15
} FiberContext;

// ── Fiber states ────────────────────────────────────────────────────

typedef enum {
    FIBER_READY,
    FIBER_RUNNING,
    FIBER_SUSPENDED,
    FIBER_DONE,
} FiberState;

// ── Fiber structure ─────────────────────────────────────────────────

typedef struct Fiber {
    FiberContext ctx;
    FiberState   state;
    void        *stack;        // Base of allocated stack memory
    size_t       stack_size;
    int64_t      result;       // Return value (legacy)
    void        *result_buf;   // Heap-allocated result buffer (new)
    int32_t      result_size;  // Size of result buffer
    int32_t      cancel_requested; // Cooperative cancel flag (observed at yield/await)
    void       (*entry)(void*, void*); // Entry: trampoline(args, result_buf)
    void        *arg;          // Argument to entry function
    struct Fiber *next;        // For scheduler queue
    int32_t      id;
    // Panic capture: setjmp/longjmp for catching panics inside fibers
    jmp_buf      panic_jmp;
    int32_t      has_panic;
    const char  *panic_msg;
    int32_t      panic_msg_len;
} Fiber;

// ── Scheduler ───────────────────────────────────────────────────────

#define MAX_FIBERS 1024
#define FIBER_STACK_SIZE (64 * 1024) // 64KB per fiber

static Fiber *ready_head = NULL;
static Fiber *ready_tail = NULL;
static Fiber *steal_head = NULL;
static Fiber *steal_tail = NULL;
static Fiber *current_fiber = NULL;
static FiberContext scheduler_ctx;
static int32_t next_fiber_id = 1;
static Fiber *free_pool_head = NULL;
static int64_t fiber_pool_reuse_count = 0;
static int64_t fiber_pool_alloc_count = 0;
static int32_t live_fiber_count = 0;
static int64_t fiber_steal_events = 0;
static int64_t scheduler_round = 0;

// Completed fibers indexed by ID for join/await
static Fiber *completed[MAX_FIBERS];
static int completed_count = 0;

int32_t with_fiber_in_fiber(void) {
    return current_fiber != NULL;
}

int32_t with_fiber_is_cancelled(void) {
    return (current_fiber && current_fiber->cancel_requested) ? 1 : 0;
}

// Assembly-implemented context switch
extern void with_fiber_switch(FiberContext *save, FiberContext *restore);

// ── Internal helpers ─────────────────────────────────────────────────

static void enqueue(Fiber *f) {
    f->next = NULL;
    if (ready_tail) {
        ready_tail->next = f;
    } else {
        ready_head = f;
    }
    ready_tail = f;
}

static Fiber *dequeue(void) {
    if (!ready_head) return NULL;
    Fiber *f = ready_head;
    ready_head = f->next;
    if (!ready_head) ready_tail = NULL;
    f->next = NULL;
    return f;
}

static void enqueue_steal(Fiber *f) {
    f->next = NULL;
    if (steal_tail) {
        steal_tail->next = f;
    } else {
        steal_head = f;
    }
    steal_tail = f;
}

static Fiber *dequeue_steal(void) {
    if (!steal_head) return NULL;
    Fiber *f = steal_head;
    steal_head = f->next;
    if (!steal_head) steal_tail = NULL;
    f->next = NULL;
    return f;
}

static Fiber *dequeue_any(void) {
    Fiber *f = dequeue();
    if (f) return f;
    f = dequeue_steal();
    if (f) fiber_steal_events++;
    return f;
}

static size_t guard_page_size(void) {
    long ps = sysconf(_SC_PAGESIZE);
    return ps > 0 ? (size_t)ps : 4096;
}

static Fiber *acquire_fiber(void) {
    if (free_pool_head) {
        Fiber *f = free_pool_head;
        free_pool_head = f->next;
        memset(&f->ctx, 0, sizeof(FiberContext));
        f->state = FIBER_READY;
        f->result = 0;
        f->cancel_requested = 0;
        f->entry = NULL;
        f->arg = NULL;
        f->next = NULL;
        f->id = 0;
        fiber_pool_reuse_count++;
        return f;
    }

    Fiber *f = (Fiber *)malloc(sizeof(Fiber));
    if (!f) return NULL;
    memset(f, 0, sizeof(Fiber));
    f->stack_size = FIBER_STACK_SIZE;

    // Allocate stack with guard page via mmap.
    // Layout: [guard page (PROT_NONE)] [usable stack (PROT_READ|PROT_WRITE)]
    size_t page_sz = guard_page_size();
    size_t total = page_sz + f->stack_size;
    void *region = mmap(NULL, total, PROT_READ | PROT_WRITE,
                        MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (region == MAP_FAILED) {
        free(f);
        return NULL;
    }
    // Guard page at low address — stack overflow hits PROT_NONE → SIGSEGV/SIGBUS.
    mprotect(region, page_sz, PROT_NONE);
    f->stack = (char *)region + page_sz; // usable stack starts above guard
    f->stack_size = FIBER_STACK_SIZE;
    fiber_pool_alloc_count++;
    return f;
}

static void recycle_fiber(Fiber *f) {
    if (!f) return;
    if (f->id != 0 && live_fiber_count > 0) {
        live_fiber_count--;
    }
    memset(&f->ctx, 0, sizeof(FiberContext));
    f->state = FIBER_DONE;
    f->result = 0;
    f->cancel_requested = 0;
    f->entry = NULL;
    f->arg = NULL;
    f->id = 0;
    if (f->panic_msg) { free((void *)f->panic_msg); f->panic_msg = NULL; }
    f->has_panic = 0;
    f->panic_msg_len = 0;
    f->next = free_pool_head;
    free_pool_head = f;
}

static void free_fiber_stack(Fiber *f) {
    if (!f->stack) return;
    size_t page_sz = guard_page_size();
    void *region = (char *)f->stack - page_sz;
    munmap(region, page_sz + f->stack_size);
    f->stack = NULL;
}

static void free_fiber_pool(void) {
    while (free_pool_head) {
        Fiber *f = free_pool_head;
        free_pool_head = f->next;
        free_fiber_stack(f);
        free(f);
    }
}

// Trampoline: entered when fiber starts executing.
static void fiber_trampoline(void) {
    // current_fiber is set before switching to us.
    // Call trampoline(args, result_buf).
    // If a panic occurs, with_fiber_panic_capture() switches back
    // to the scheduler directly — we never reach the code below.
    current_fiber->entry(current_fiber->arg, current_fiber->result_buf);
    // Fiber function returned normally — mark as done.
    current_fiber->state = FIBER_DONE;
    // Store in completed list for await.
    if (completed_count < MAX_FIBERS) {
        completed[completed_count++] = current_fiber;
    }
    // Switch back to scheduler.
    with_fiber_switch(&current_fiber->ctx, &scheduler_ctx);
    // Should never reach here.
    __builtin_unreachable();
}

// ── Stack overflow signal handler ──────────────────────────────────

// Alternate signal stack so the handler can run when the fiber stack overflows.
static uint8_t fiber_alt_stack_buf[SIGSTKSZ];

static void fiber_write_i32(int fd, int32_t n) {
    char buf[16];
    int i = 0;
    if (n < 0) { write(fd, "-", 1); n = -n; }
    if (n == 0) { write(fd, "0", 1); return; }
    while (n > 0 && i < 15) { buf[i++] = '0' + (n % 10); n /= 10; }
    for (int j = i - 1; j >= 0; j--) write(fd, &buf[j], 1);
}

static void fiber_stack_overflow_handler(int sig, siginfo_t *info, void *ucontext) {
    (void)ucontext;
    void *fault_addr = info->si_addr;
    size_t page_sz = guard_page_size();

    // Check if fault is in current fiber's guard page
    if (current_fiber && current_fiber->stack) {
        void *guard_start = (char *)current_fiber->stack - page_sz;
        void *guard_end = current_fiber->stack;
        if (fault_addr >= guard_start && fault_addr < guard_end) {
            write(2, "fatal: fiber stack overflow (fiber #", 36);
            fiber_write_i32(2, current_fiber->id);
            write(2, ")\n", 2);
            _exit(134);
        }
    }

    // Not a fiber guard page hit — restore default and re-raise
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = SIG_DFL;
    sigaction(sig, &sa, NULL);
    raise(sig);
}

static void fiber_install_signal_handlers(void) {
    // Set up alternate signal stack (needed because fiber stack is what overflowed)
    stack_t ss;
    ss.ss_sp = fiber_alt_stack_buf;
    ss.ss_size = sizeof(fiber_alt_stack_buf);
    ss.ss_flags = 0;
    sigaltstack(&ss, NULL);

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = fiber_stack_overflow_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sigaction(SIGSEGV, &sa, NULL);
#ifdef SIGBUS
    sigaction(SIGBUS, &sa, NULL);
#endif
}

// ── Public API (called from generated code) ─────────────────────────

// Initialize the runtime (called once before main if async is used).
// Panic hooks — defined in support_runtime.c, set here during init
extern void (*with_fiber_panic_hook)(const char *msg, int32_t msg_len);
extern int32_t (*with_fiber_in_fiber_hook)(void);
// Forward declaration
void with_fiber_panic_capture(const char *msg, int32_t msg_len);

void with_runtime_init(void) {
    ready_head = NULL;
    ready_tail = NULL;
    steal_head = NULL;
    steal_tail = NULL;
    current_fiber = NULL;
    completed_count = 0;
    next_fiber_id = 1;
    fiber_pool_reuse_count = 0;
    fiber_pool_alloc_count = 0;
    live_fiber_count = 0;
    fiber_steal_events = 0;
    scheduler_round = 0;
    fiber_install_signal_handlers();
    // Register panic hooks so with_panic captures inside fibers
    with_fiber_panic_hook = with_fiber_panic_capture;
    with_fiber_in_fiber_hook = with_fiber_in_fiber;
}

// Create a new fiber. Returns fiber ID.
// entry_fn: trampoline(args, result_buf)
// arg: heap-allocated args struct
// result_buf: heap-allocated result buffer (caller owns)
// result_size: sizeof(return type)
// stack_size: 0 = default (FIBER_STACK_SIZE)
int32_t with_fiber_spawn(void (*entry_fn)(void*, void*), void *arg,
                          void *result_buf, int32_t result_size,
                          int32_t stack_size) {
    if (live_fiber_count >= MAX_FIBERS) return -1;
    Fiber *f = acquire_fiber();
    if (!f) return -1;

    // Honor custom stack size if requested and this is a fresh allocation.
    // Pooled fibers keep their original stack — reallocating would be wasteful.
    if (stack_size > 0 && f->stack_size != (size_t)stack_size) {
        free_fiber_stack(f);
        f->stack_size = (size_t)stack_size;
        size_t page_sz = guard_page_size();
        size_t total = page_sz + f->stack_size;
        void *region = mmap(NULL, total, PROT_READ | PROT_WRITE,
                            MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (region == MAP_FAILED) { free(f); return -1; }
        mprotect(region, page_sz, PROT_NONE);
        f->stack = (char *)region + page_sz;
    }

    f->entry = entry_fn;
    f->arg = arg;
    f->result_buf = result_buf;
    f->result_size = result_size;
    f->state = FIBER_READY;
    f->id = next_fiber_id++;
    f->result = 0;
    f->cancel_requested = 0;
    live_fiber_count++;

    // Set up initial context with ABI-correct stack alignment.
    void *stack_top = (void *)((uintptr_t)f->stack + f->stack_size);
    stack_top = (void *)((uintptr_t)stack_top & ~0xFUL); // 16-byte alignment

#if defined(__x86_64__)
    // SysV entry expects RSP%16 == 8. Seed a dummy return slot.
    uint8_t *initial_rsp = ((uint8_t *)stack_top) - 8;
    *(uint64_t *)initial_rsp = 0;
    f->ctx.regs[12] = (uint64_t)initial_rsp;      // rsp
    f->ctx.regs[11] = (uint64_t)fiber_trampoline; // rip
    f->ctx.regs[10] = (uint64_t)initial_rsp;      // rbp
#else
    f->ctx.regs[12] = (uint64_t)stack_top;        // sp
    f->ctx.regs[11] = (uint64_t)fiber_trampoline; // lr (x30)
    f->ctx.regs[10] = (uint64_t)stack_top;        // fp (x29)
#endif

    if ((f->id & 1) == 0) {
        enqueue_steal(f);
    } else {
        enqueue(f);
    }
    return f->id;
}

// Run the scheduler until all fibers complete.
void with_runtime_run(void) {
    while (ready_head || steal_head) {
        Fiber *f = dequeue_any();
        if (!f) break;
        f->state = FIBER_RUNNING;
        current_fiber = f;
        with_fiber_switch(&scheduler_ctx, &f->ctx);
        current_fiber = NULL;
        // After switch back, check state.
        if (f->state == FIBER_SUSPENDED) {
            // Re-enqueue and alternate queues to simulate work-stealing churn.
            if ((scheduler_round++ & 1) == 0) enqueue_steal(f);
            else enqueue(f);
        }
        // FIBER_DONE fibers are in the completed list.
    }

    // Report unhandled panics from fire-and-forget fibers
    int had_unhandled_panic = 0;
    for (int i = 0; i < completed_count; i++) {
        if (completed[i] && completed[i]->has_panic) {
            fprintf(stderr, "unhandled panic in fiber #%d: %.*s\n",
                    completed[i]->id,
                    (int)completed[i]->panic_msg_len,
                    completed[i]->panic_msg ? completed[i]->panic_msg : "(null)");
            had_unhandled_panic = 1;
        }
    }
    if (had_unhandled_panic) {
        _exit(1);
    }
}

// Yield the current fiber (cooperative scheduling point).
void with_fiber_yield(void) {
    if (!current_fiber) return;
    if (current_fiber->cancel_requested) {
        current_fiber->state = FIBER_DONE;
        current_fiber->result = -1;
        if (completed_count < MAX_FIBERS) {
            completed[completed_count++] = current_fiber;
        }
        with_fiber_switch(&current_fiber->ctx, &scheduler_ctx);
        return;
    }
    current_fiber->state = FIBER_SUSPENDED;
    with_fiber_switch(&current_fiber->ctx, &scheduler_ctx);
}

// Helper: run one scheduler step (dequeue one fiber, run it until it yields/completes).
static void run_one_fiber(void) {
    Fiber *f = dequeue_any();
    if (!f) return;
    f->state = FIBER_RUNNING;
    current_fiber = f;
    with_fiber_switch(&scheduler_ctx, &f->ctx);
    current_fiber = NULL;
    if (f->state == FIBER_SUSPENDED) {
        if ((scheduler_round++ & 1) == 0) enqueue_steal(f);
        else enqueue(f);
    }
}

// Await a fiber by ID.
// If called from a fiber, yields until target completes.
// If called from main thread, runs scheduler inline until target completes.
// Result is read from the fiber's heap-allocated result_buf by codegen, not returned here.
void with_fiber_await(int32_t fiber_id) {
    while (1) {
        // Check if fiber is completed.
        for (int i = 0; i < completed_count; i++) {
            if (completed[i] && completed[i]->id == fiber_id) {
                // Check if the fiber panicked — re-raise in awaiter's context
                if (completed[i]->has_panic) {
                    // Take ownership of panic message before recycling
                    const char *msg = completed[i]->panic_msg;
                    int32_t msg_len = completed[i]->panic_msg_len;
                    completed[i]->panic_msg = NULL; // prevent double-free in recycle
                    completed[i]->has_panic = 0;
                    recycle_fiber(completed[i]);
                    completed[i] = completed[completed_count - 1];
                    completed_count--;
                    // Re-raise: print message and abort
                    if (msg && msg_len > 0) {
                        fprintf(stderr, "%.*s\n", (int)msg_len, msg);
                        free((void *)msg);
                    }
                    abort();
                }
                // Recycle for stack/Fiber reuse.
                recycle_fiber(completed[i]);
                completed[i] = completed[completed_count - 1];
                completed_count--;
                return;
            }
        }
        // Not done yet.
        if (current_fiber) {
            // Inside a fiber: yield back to scheduler.
            with_fiber_yield();
        } else {
            // On main thread: run one scheduler step inline.
            if (ready_head || steal_head) {
                run_one_fiber();
            } else {
                // No more fibers to run and target not done — shouldn't happen.
                return;
            }
        }
    }
}

// Cancel a fiber by ID.
// Returns 1 if canceled/found, 0 if the fiber ID is unknown.
int32_t with_fiber_cancel(int32_t fiber_id) {
    // If already completed, clean it up now.
    for (int i = 0; i < completed_count; i++) {
        if (completed[i] && completed[i]->id == fiber_id) {
            recycle_fiber(completed[i]);
            completed[i] = completed[completed_count - 1];
            completed_count--;
            return 1;
        }
    }

    // Remove from ready queue if present.
    Fiber *cur = ready_head;
    while (cur) {
        if (cur->id == fiber_id) {
            cur->cancel_requested = 1;
            return 1;
        }
        cur = cur->next;
    }

    // Search steal queue as well.
    cur = steal_head;
    while (cur) {
        if (cur->id == fiber_id) {
            cur->cancel_requested = 1;
            return 1;
        }
        cur = cur->next;
    }

    // Best-effort handling if current fiber cancels itself.
    if (current_fiber && current_fiber->id == fiber_id) {
        current_fiber->cancel_requested = 1;
        return 1;
    }

    return 0;
}

// Set the result of the current fiber (called before returning).
void with_fiber_set_result(int64_t value) {
    if (current_fiber) {
        current_fiber->result = value;
    }
}

// Capture a panic inside a fiber. Called from with_panic when in fiber context.
// For v1: mark the fiber as panicked and yield back to the scheduler.
// The fiber will not resume; the panic is reported at await or during drain.
void with_fiber_panic_capture(const char *msg, int32_t msg_len) {
    if (!current_fiber) return;
    current_fiber->has_panic = 1;
    // Copy the message since the original may be stack-allocated
    char *buf = (char *)malloc((size_t)msg_len + 1);
    if (buf) {
        memcpy(buf, msg, (size_t)msg_len);
        buf[msg_len] = '\0';
    }
    current_fiber->panic_msg = buf;
    current_fiber->panic_msg_len = msg_len;
    // Mark fiber as done and switch back to scheduler
    current_fiber->state = FIBER_DONE;
    if (completed_count < MAX_FIBERS) {
        completed[completed_count++] = current_fiber;
    }
    with_fiber_switch(&current_fiber->ctx, &scheduler_ctx);
    // Should never reach here — scheduler won't re-run this fiber
    __builtin_unreachable();
}

// Shutdown the runtime (cleanup).
void with_runtime_shutdown(void) {
    // Free any remaining completed fibers.
    for (int i = 0; i < completed_count; i++) {
        if (completed[i]) {
            recycle_fiber(completed[i]);
        }
    }
    completed_count = 0;
    // Free any remaining ready fibers.
    while (ready_head) {
        Fiber *f = dequeue();
        if (f) {
            recycle_fiber(f);
        }
    }
    while (steal_head) {
        Fiber *f = dequeue_steal();
        if (f) {
            recycle_fiber(f);
        }
    }
    free_fiber_pool();
}

// Check if any fibers are still running.
int32_t with_runtime_has_fibers(void) {
    return (ready_head != NULL) || (steal_head != NULL);
}

// Debug/introspection helpers for validating pool reuse behavior.
int64_t with_fiber_pool_reuses(void) {
    return fiber_pool_reuse_count;
}

int64_t with_fiber_pool_allocs(void) {
    return fiber_pool_alloc_count;
}

int64_t with_fiber_stack_size_bytes(void) {
    return (int64_t)FIBER_STACK_SIZE;
}

int32_t with_fiber_max_fibers(void) {
    return MAX_FIBERS;
}

int32_t with_fiber_live_fibers(void) {
    return live_fiber_count;
}

int64_t with_fiber_steal_events(void) {
    return fiber_steal_events;
}

// ── Channels (sized element slots) ──────────────────────────────────

#define CHAN_INITIAL_CAPACITY 16

typedef struct {
    uint8_t *buffer;           // ring buffer of elem_size-byte slots
    int32_t  elem_size;        // bytes per element
    int32_t  head;
    int32_t  tail;
    int32_t  count;
    int32_t  capacity;         // allocated ring size (in elements)
    int32_t  bounded_capacity; // >0 for bounded channels, 0 for unbounded
    int32_t  closed;
} Channel;

static int channel_grow(Channel *ch) {
    if (!ch || ch->bounded_capacity > 0) return 0;

    int32_t old_cap = ch->capacity;
    int32_t new_cap = old_cap > 0 ? old_cap * 2 : CHAN_INITIAL_CAPACITY;
    if (new_cap < CHAN_INITIAL_CAPACITY) new_cap = CHAN_INITIAL_CAPACITY;

    uint8_t *new_buf = (uint8_t *)malloc((size_t)ch->elem_size * (size_t)new_cap);
    if (!new_buf) return 0;

    // Linearize the ring buffer into new_buf.
    for (int32_t i = 0; i < ch->count; i++) {
        int32_t src_idx = (ch->head + i) % old_cap;
        memcpy(new_buf + (size_t)i * ch->elem_size,
               ch->buffer + (size_t)src_idx * ch->elem_size,
               (size_t)ch->elem_size);
    }

    free(ch->buffer);
    ch->buffer = new_buf;
    ch->capacity = new_cap;
    ch->head = 0;
    ch->tail = ch->count;
    return 1;
}

// Create a new channel with given capacity and element size.
// capacity=0 means unbounded. elem_size is sizeof(element type).
int64_t with_channel_create(int32_t capacity, int32_t elem_size) {
    Channel *ch = (Channel *)malloc(sizeof(Channel));
    if (!ch) return 0;
    memset(ch, 0, sizeof(Channel));
    ch->elem_size = elem_size > 0 ? elem_size : 1;

    if (capacity > 0) {
        ch->bounded_capacity = capacity;
        ch->capacity = capacity;
    } else {
        ch->bounded_capacity = 0;
        ch->capacity = CHAN_INITIAL_CAPACITY;
    }

    ch->buffer = (uint8_t *)malloc((size_t)ch->elem_size * (size_t)ch->capacity);
    if (!ch->buffer) {
        free(ch);
        return 0;
    }

    return (int64_t)(uintptr_t)ch;
}

// Send a value to a channel. Copies elem_size bytes from value_ptr.
// Blocks (yields) if channel is full.
void with_channel_send(int64_t ch_handle, void *value_ptr) {
    Channel *ch = (Channel *)(uintptr_t)ch_handle;
    if (!ch || !ch->buffer) return;

    while (ch->count >= ch->capacity) {
        if (ch->closed) return;

        // Unbounded channel: grow instead of blocking.
        if (ch->bounded_capacity == 0) {
            if (channel_grow(ch)) break;
        }

        if (current_fiber) {
            with_fiber_yield();
        } else {
            if (with_runtime_has_fibers()) run_one_fiber();
            else return; // deadlock prevention
        }
    }
    if (ch->closed) return;
    memcpy(ch->buffer + (size_t)ch->tail * ch->elem_size,
           value_ptr, (size_t)ch->elem_size);
    ch->tail = (ch->tail + 1) % ch->capacity;
    ch->count++;
}

// Receive a value from a channel. Copies elem_size bytes to out_ptr.
// Blocks (yields) if channel is empty. Returns 0 on success, -1 if closed+empty.
int32_t with_channel_recv(int64_t ch_handle, void *out_ptr) {
    Channel *ch = (Channel *)(uintptr_t)ch_handle;
    if (!ch || !ch->buffer) return -1;
    while (ch->count == 0) {
        if (ch->closed) return -1;
        if (current_fiber) {
            with_fiber_yield();
        } else {
            if (with_runtime_has_fibers()) run_one_fiber();
            else return -1; // deadlock prevention
        }
    }
    memcpy(out_ptr, ch->buffer + (size_t)ch->head * ch->elem_size,
           (size_t)ch->elem_size);
    ch->head = (ch->head + 1) % ch->capacity;
    ch->count--;
    return 0;
}

// Try to receive without blocking. Returns 1 if got value, 0 if empty.
int32_t with_channel_try_recv(int64_t ch_handle, void *out_ptr) {
    Channel *ch = (Channel *)(uintptr_t)ch_handle;
    if (!ch || !ch->buffer) return 0;
    if (ch->count == 0) return 0;
    memcpy(out_ptr, ch->buffer + (size_t)ch->head * ch->elem_size,
           (size_t)ch->elem_size);
    ch->head = (ch->head + 1) % ch->capacity;
    ch->count--;
    return 1;
}

// ── Select Await ────────────────────────────────────────────────────

// Select await: wait for the first of N fibers to complete.
// Takes an array of fiber IDs, count, and pointer to store winner index.
// Writes the 0-based index of the first completed fiber to *result_index.
// The caller is responsible for loading the result from the winning task's
// result buffer and cancelling/freeing the losers.
void with_fiber_select(int32_t *fiber_ids, int32_t count, int32_t *result_index) {
    while (1) {
        // Check if any of the target fibers are completed.
        for (int i = 0; i < count; i++) {
            for (int j = 0; j < completed_count; j++) {
                if (completed[j] && completed[j]->id == fiber_ids[i]) {
                    *result_index = i;
                    return;
                }
            }
        }
        // None done yet — yield or run a fiber.
        if (current_fiber) {
            with_fiber_yield();
        } else {
            if (with_runtime_has_fibers()) {
                run_one_fiber();
            } else {
                *result_index = -1; // deadlock
                return;
            }
        }
    }
}

// Close the channel.
void with_channel_close(int64_t ch_handle) {
    Channel *ch = (Channel *)(uintptr_t)ch_handle;
    if (ch) ch->closed = 1;
}

// Free channel memory.
void with_channel_destroy(int64_t ch_handle) {
    Channel *ch = (Channel *)(uintptr_t)ch_handle;
    if (!ch) return;
    free(ch->buffer);
    free(ch);
}
