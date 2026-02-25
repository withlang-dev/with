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
static Fiber *current_fiber = NULL;
static FiberContext scheduler_ctx;
static int32_t next_fiber_id = 1;

// Completed fibers indexed by ID for join/await
static Fiber *completed[MAX_FIBERS];
static int completed_count = 0;

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
    current_fiber = NULL;
    completed_count = 0;
    next_fiber_id = 1;
}

// Create a new fiber. Returns fiber ID.
// entry_fn: the async function to run (takes void* arg, returns void — result stored via with_fiber_set_result)
// arg: argument pointer (can be NULL)
int32_t with_fiber_spawn(void (*entry_fn)(void*), void *arg) {
    Fiber *f = (Fiber *)malloc(sizeof(Fiber));
    if (!f) return -1;
    memset(f, 0, sizeof(Fiber));

    f->stack_size = FIBER_STACK_SIZE;
    f->stack = malloc(f->stack_size);
    if (!f->stack) { free(f); return -1; }

    f->entry = entry_fn;
    f->arg = arg;
    f->state = FIBER_READY;
    f->id = next_fiber_id++;
    f->result = 0;

    // Set up initial context: sp at top of stack (aligned), lr to trampoline.
    void *stack_top = (void *)((uintptr_t)f->stack + f->stack_size);
    // Align to 16 bytes (ABI requirement).
    stack_top = (void *)((uintptr_t)stack_top & ~0xFUL);

    f->ctx.regs[12] = (uint64_t)stack_top; // sp
    f->ctx.regs[11] = (uint64_t)fiber_trampoline; // lr (x30)
    f->ctx.regs[10] = (uint64_t)stack_top; // fp (x29)

    enqueue(f);
    return f->id;
}

// Run the scheduler until all fibers complete.
void with_runtime_run(void) {
    while (ready_head) {
        Fiber *f = dequeue();
        if (!f) break;
        f->state = FIBER_RUNNING;
        current_fiber = f;
        with_fiber_switch(&scheduler_ctx, &f->ctx);
        current_fiber = NULL;
        // After switch back, check state.
        if (f->state == FIBER_SUSPENDED) {
            // Re-enqueue for next round.
            enqueue(f);
        }
        // FIBER_DONE fibers are in the completed list.
    }
}

// Yield the current fiber (cooperative scheduling point).
void with_fiber_yield(void) {
    if (!current_fiber) return;
    current_fiber->state = FIBER_SUSPENDED;
    with_fiber_switch(&current_fiber->ctx, &scheduler_ctx);
}

// Helper: run one scheduler step (dequeue one fiber, run it until it yields/completes).
static void run_one_fiber(void) {
    Fiber *f = dequeue();
    if (!f) return;
    f->state = FIBER_RUNNING;
    current_fiber = f;
    with_fiber_switch(&scheduler_ctx, &f->ctx);
    current_fiber = NULL;
    if (f->state == FIBER_SUSPENDED) {
        enqueue(f);
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
                // Clean up.
                free(completed[i]->stack);
                free(completed[i]);
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
            if (ready_head) {
                run_one_fiber();
            } else {
                // No more fibers to run and target not done — shouldn't happen.
                return -1;
            }
        }
    }
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
            free(completed[i]->stack);
            free(completed[i]);
        }
    }
    completed_count = 0;
    // Free any remaining ready fibers.
    while (ready_head) {
        Fiber *f = dequeue();
        if (f) {
            free(f->stack);
            free(f);
        }
    }
}

// Check if any fibers are still running.
int32_t with_runtime_has_fibers(void) {
    return ready_head != NULL;
}
