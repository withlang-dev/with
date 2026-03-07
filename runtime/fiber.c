// With Language Fiber Runtime
// Minimal M:1 fiber scheduler for async/await support.

#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>

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
    int64_t      result;       // Return value (i64 to hold most types)
    int32_t      cancel_requested; // Cooperative cancel flag (observed at yield/await)
    void       (*entry)(void*); // Entry function
    void        *arg;          // Argument to entry function
    struct Fiber *next;        // For scheduler queue
    int32_t      id;
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
    f->stack = malloc(f->stack_size);
    if (!f->stack) {
        free(f);
        return NULL;
    }
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
    f->next = free_pool_head;
    free_pool_head = f;
}

static void free_fiber_pool(void) {
    while (free_pool_head) {
        Fiber *f = free_pool_head;
        free_pool_head = f->next;
        free(f->stack);
        free(f);
    }
}

// Trampoline: entered when fiber starts executing.
static void fiber_trampoline(void) {
    // current_fiber is set before switching to us.
    current_fiber->entry(current_fiber->arg);
    // Fiber function returned — mark as done.
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

// ── Public API (called from generated code) ─────────────────────────

// Initialize the runtime (called once before main if async is used).
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
}

// Create a new fiber. Returns fiber ID.
// entry_fn: the async function to run (takes void* arg, returns void — result stored via with_fiber_set_result)
// arg: argument pointer (can be NULL)
int32_t with_fiber_spawn(void (*entry_fn)(void*), void *arg) {
    if (live_fiber_count >= MAX_FIBERS) return -1;
    Fiber *f = acquire_fiber();
    if (!f) return -1;

    f->entry = entry_fn;
    f->arg = arg;
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

// Await a fiber by ID. Returns the fiber's result.
// If called from a fiber, yields until target completes.
// If called from main thread, runs scheduler inline until target completes.
int64_t with_fiber_await(int32_t fiber_id) {
    while (1) {
        // Check if fiber is completed.
        for (int i = 0; i < completed_count; i++) {
            if (completed[i] && completed[i]->id == fiber_id) {
                int64_t result = completed[i]->result;
                // Recycle for stack/Fiber reuse.
                recycle_fiber(completed[i]);
                completed[i] = completed[completed_count - 1];
                completed_count--;
                return result;
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
                return -1;
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

// ── Channels ────────────────────────────────────────────────────────

#define CHAN_INITIAL_CAPACITY 16

typedef struct {
    int64_t *buffer;
    int32_t  head;
    int32_t  tail;
    int32_t  count;
    int32_t  capacity;         // allocated ring size
    int32_t  bounded_capacity; // >0 for bounded channels, 0 for unbounded
    int32_t  closed;
} Channel;

static int channel_grow(Channel *ch) {
    if (!ch || ch->bounded_capacity > 0) return 0;

    int32_t old_cap = ch->capacity;
    int32_t new_cap = old_cap > 0 ? old_cap * 2 : CHAN_INITIAL_CAPACITY;
    if (new_cap < CHAN_INITIAL_CAPACITY) new_cap = CHAN_INITIAL_CAPACITY;

    int64_t *new_buf = (int64_t *)malloc(sizeof(int64_t) * (size_t)new_cap);
    if (!new_buf) return 0;

    for (int32_t i = 0; i < ch->count; i++) {
        new_buf[i] = ch->buffer[(ch->head + i) % old_cap];
    }

    free(ch->buffer);
    ch->buffer = new_buf;
    ch->capacity = new_cap;
    ch->head = 0;
    ch->tail = ch->count;
    return 1;
}

// Create a new channel with given capacity (0 = unbounded).
void *with_channel_create(int32_t capacity) {
    Channel *ch = (Channel *)malloc(sizeof(Channel));
    if (!ch) return NULL;
    memset(ch, 0, sizeof(Channel));

    if (capacity > 0) {
        ch->bounded_capacity = capacity;
        ch->capacity = capacity;
    } else {
        ch->bounded_capacity = 0;
        ch->capacity = CHAN_INITIAL_CAPACITY;
    }

    ch->buffer = (int64_t *)malloc(sizeof(int64_t) * (size_t)ch->capacity);
    if (!ch->buffer) {
        free(ch);
        return NULL;
    }

    return ch;
}

// Send a value to a channel. Blocks (yields) if channel is full.
void with_channel_send(void *ch_ptr, int64_t value) {
    Channel *ch = (Channel *)ch_ptr;
    if (!ch || !ch->buffer) return;

    while (ch->count >= ch->capacity) {
        if (ch->closed) return;

        // Unbounded channel: grow instead of blocking.
        if (ch->bounded_capacity == 0) {
            if (channel_grow(ch)) break;
            // Allocation failure: fall back to cooperative waiting.
        }

        if (current_fiber) {
            with_fiber_yield();
        } else {
            if (with_runtime_has_fibers()) run_one_fiber();
            else return; // deadlock prevention
        }
    }
    if (ch->closed) return;
    ch->buffer[ch->tail] = value;
    ch->tail = (ch->tail + 1) % ch->capacity;
    ch->count++;
}

// Receive a value from a channel. Returns the value.
// Blocks (yields) if channel is empty. Returns -1 if channel closed and empty.
int64_t with_channel_recv(void *ch_ptr) {
    Channel *ch = (Channel *)ch_ptr;
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
    int64_t value = ch->buffer[ch->head];
    ch->head = (ch->head + 1) % ch->capacity;
    ch->count--;
    return value;
}

// Try to receive without blocking. Returns 1 if got value (stored in *out), 0 if empty.
int32_t with_channel_try_recv(void *ch_ptr, int64_t *out) {
    Channel *ch = (Channel *)ch_ptr;
    if (!ch || !ch->buffer) return 0;
    if (ch->count == 0) return 0;
    *out = ch->buffer[ch->head];
    ch->head = (ch->head + 1) % ch->capacity;
    ch->count--;
    return 1;
}

// ── Select Await ────────────────────────────────────────────────────

// Select await: wait for the first of N fibers to complete.
// Takes an array of fiber IDs and count.
// Returns the index (0-based) of the first completed fiber.
// The result of the completed fiber is stored in *result_out.
int32_t with_fiber_select(int32_t *fiber_ids, int32_t count, int64_t *result_out) {
    while (1) {
        // Check if any of the target fibers are completed.
        for (int i = 0; i < count; i++) {
            for (int j = 0; j < completed_count; j++) {
                if (completed[j] && completed[j]->id == fiber_ids[i]) {
                    *result_out = completed[j]->result;
                    // Clean up the completed fiber.
                    free(completed[j]->stack);
                    free(completed[j]);
                    completed[j] = completed[completed_count - 1];
                    completed_count--;
                    return i;
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
                return -1; // deadlock
            }
        }
    }
}

// Close the channel.
void with_channel_close(void *ch_ptr) {
    Channel *ch = (Channel *)ch_ptr;
    ch->closed = 1;
}

// Free channel memory.
void with_channel_destroy(void *ch_ptr) {
    Channel *ch = (Channel *)ch_ptr;
    if (!ch) return;
    free(ch->buffer);
    free(ch);
}
