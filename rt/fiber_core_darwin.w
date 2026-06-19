// rt/fiber_core_darwin.w -- Darwin fiber core moved out of runtime/fiber.c.
//
// This module owns the remaining scheduler/stack/panic core. It uses manual
// ABI declarations instead of c_import so the runtime stays self-contained.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> Unit
extern fn with_memset(dst: *mut u8, val: i32, len: i64) -> Unit
extern fn mmap(addr: *mut u8, len: u64, prot: i32, flags: i32, fd: i32, offset: i64) -> *mut u8
extern fn mprotect(addr: *mut u8, len: u64, prot: i32) -> i32
extern fn munmap(addr: *mut u8, len: u64) -> i32
extern fn raise(sig: i32) -> i32
extern fn write(fd: i32, buf: *const u8, len: u64) -> i64
extern fn _exit(code: i32) -> Unit
extern fn abort() -> Unit
extern fn rt_fiber_page_size() -> i64
extern fn rt_fiber_mmap_flags() -> i32
extern fn rt_fiber_install_signal_handlers(alt_stack: *mut u8, alt_stack_size: i64, handler: i64) -> Unit
extern fn rt_fiber_reset_signal_handler(sig: i32) -> Unit
extern fn rt_fiber_fault_addr(info: *const u8) -> i64
extern fn rt_thread_spawn(start_routine: *mut u8, arg: *mut u8) -> i64
extern fn rt_thread_join(handle: i64) -> i32
extern fn rt_nanosleep(ns: i64) -> i32
extern fn pthread_self() -> i64
extern fn pthread_mutex_init(mutex: *mut u8, attr: *const u8) -> i32
extern fn pthread_mutex_lock(mutex: *mut u8) -> i32
extern fn pthread_mutex_unlock(mutex: *mut u8) -> i32
extern fn pthread_cond_init(cond: *mut u8, attr: *const u8) -> i32
extern fn pthread_cond_wait(cond: *mut u8, mutex: *mut u8) -> i32
extern fn pthread_cond_broadcast(cond: *mut u8) -> i32

extern fn with_fiber_switch(save: *mut u8, restore: *mut u8) -> Unit
extern fn with_fiber_prepare_initial_context(ctx: *mut u8, stack: *mut u8, stack_size: i64) -> Unit

let MAX_FIBERS: i32 = 1024
let MAX_FIBER_WORKERS: i32 = 8
let FIBER_STACK_SIZE: i64 = 65536
let FIBER_SLOT_BITS: i32 = 10
let FIBER_SLOT_MASK: i32 = 1023

let FIBER_STATE_READY: i32 = 0
let FIBER_STATE_RUNNING: i32 = 1
let FIBER_STATE_SUSPENDED: i32 = 2
let FIBER_STATE_DONE: i32 = 3

let FIBER_CTX_SIZE: i64 = 168
let FIBER_SIZE: i64 = 280
let FIBER_OFF_STATE: i64 = 168
let FIBER_OFF_STACK: i64 = 176
let FIBER_OFF_STACK_SIZE: i64 = 184
let FIBER_OFF_RESULT: i64 = 192
let FIBER_OFF_RESULT_BUF: i64 = 200
let FIBER_OFF_RESULT_SIZE: i64 = 208
let FIBER_OFF_CANCEL_REQUESTED: i64 = 212
let FIBER_OFF_CANCELLED_RETURN: i64 = 216
let FIBER_OFF_ENTRY: i64 = 224
let FIBER_OFF_ARG: i64 = 232
let FIBER_OFF_NEXT: i64 = 240
let FIBER_OFF_ID: i64 = 248
let FIBER_OFF_SLOT: i64 = 252
let FIBER_OFF_HAS_PANIC: i64 = 256
let FIBER_OFF_PANIC_MSG: i64 = 264
let FIBER_OFF_PANIC_MSG_LEN: i64 = 272
let FIBER_OFF_OWNER_WORKER: i64 = 276

let PROT_NONE: i32 = 0
let PROT_READ_WRITE: i32 = 3
let MAP_FAILED: i64 = -1

let SIGBUS: i32 = 10
let SIGSEGV: i32 = 11

let FIBER_ALT_STACK_SIZE: i64 = 131072

var scheduler_mutex: [16]i64 = [0 as i64; 16]
var scheduler_cond: [16]i64 = [0 as i64; 16]
var scheduler_primitives_initialized: i32 = 0
var scheduler_shutdown_requested: i32 = 0
var scheduler_running_fibers: i32 = 0
var configured_worker_count: i32 = 1
var active_worker_count: i32 = 1
var worker_threads_started: i32 = 0
var worker_current_fibers: [8]i64 = [0 as i64; 8]
var worker_scheduler_ctxs: [1344]u8 = [0 as u8; 1344]
var worker_thread_ids: [8]i64 = [0 as i64; 8]
var worker_handles: [8]i64 = [0 as i64; 8]
var worker_queue_entries: [8192]i64 = [0 as i64; 8192]
var worker_queue_heads: [8]i32 = [0 as i32; 8]
var worker_queue_counts: [8]i32 = [0 as i32; 8]
var free_pool_head: i64 = 0
var fiber_page_size: i64 = 0
var fiber_pool_reuse_count: i64 = 0
var fiber_pool_alloc_count: i64 = 0
var fiber_pool_free_count: i32 = 0
var fiber_default_stack_size: i64 = 0
var fiber_pool_limit: i32 = 0
var live_fiber_count: i32 = 0
var fiber_steal_attempts: i64 = 0
var fiber_steal_events: i64 = 0
var scheduler_round: i64 = 0
var cross_thread_cancel_count: i64 = 0
var fibers_by_slot: [1024]i64 = [0 as i64; 1024]
var fiber_slot_generations: [1024]u32 = [0 as u32; 1024]
var free_fiber_slots: [1024]i32 = [0 as i32; 1024]
var free_fiber_slot_count: i32 = 0
var panicked_fiber_ids: [1024]i32 = [0 as i32; 1024]
var panicked_fiber_head: i32 = 0
var panicked_fiber_count: i32 = 0
var fiber_alt_stack_buf: [131072]u8 = [0 as u8; 131072]

fn scheduler_mutex_ptr() -> *mut u8:
    (&raw mut scheduler_mutex) as *mut [16]i64 as *mut u8

fn scheduler_cond_ptr() -> *mut u8:
    (&raw mut scheduler_cond) as *mut [16]i64 as *mut u8

fn scheduler_init_primitives():
    if scheduler_primitives_initialized != 0:
        return
    if pthread_mutex_init(scheduler_mutex_ptr(), 0 as *const u8) != 0:
        abort()
    if pthread_cond_init(scheduler_cond_ptr(), 0 as *const u8) != 0:
        abort()
    scheduler_primitives_initialized = 1

fn scheduler_lock():
    if pthread_mutex_lock(scheduler_mutex_ptr()) != 0:
        abort()

fn scheduler_unlock():
    if pthread_mutex_unlock(scheduler_mutex_ptr()) != 0:
        abort()

fn scheduler_wait():
    if pthread_cond_wait(scheduler_cond_ptr(), scheduler_mutex_ptr()) != 0:
        abort()

fn scheduler_wake_all():
    if pthread_cond_broadcast(scheduler_cond_ptr()) != 0:
        abort()

fn worker_ctx_base() -> i64:
    (&raw mut worker_scheduler_ctxs) as *mut [1344]u8 as i64

fn scheduler_ctx_ptr(worker: i32) -> *mut u8:
    (worker_ctx_base() + worker as i64 * FIBER_CTX_SIZE) as *mut u8

fn current_worker_index() -> i32:
    let tid = pthread_self()
    var i = 0
    while i < active_worker_count:
        if worker_thread_ids[i as i64] == tid:
            return i
        i = i + 1
    0

fn current_worker_fiber() -> i64:
    worker_current_fibers[current_worker_index() as i64]

fn alt_stack_ptr() -> *mut u8:
    (&raw mut fiber_alt_stack_buf) as *mut [131072]u8 as *mut u8

fn worker_queue_base() -> i64:
    (&raw mut worker_queue_entries) as *mut [8192]i64 as i64

fn worker_queue_heads_base() -> i64:
    (&raw mut worker_queue_heads) as *mut [8]i32 as i64

fn worker_queue_counts_base() -> i64:
    (&raw mut worker_queue_counts) as *mut [8]i32 as i64

fn fibers_by_slot_base() -> i64:
    (&raw mut fibers_by_slot) as *mut [1024]i64 as i64

fn fiber_slot_generations_base() -> i64:
    (&raw mut fiber_slot_generations) as *mut [1024]u32 as i64

fn free_fiber_slots_base() -> i64:
    (&raw mut free_fiber_slots) as *mut [1024]i32 as i64

fn panicked_fiber_ids_base() -> i64:
    (&raw mut panicked_fiber_ids) as *mut [1024]i32 as i64

fn load_i32_index(base: i64, index: i32) -> i32:
    unsafe:
        *((base + index as i64 * 4) as *const i32)

fn store_i32_index(base: i64, index: i32, value: i32):
    unsafe:
        *((base + index as i64 * 4) as *mut i32) = value

fn load_u32_index(base: i64, index: i32) -> u32:
    unsafe:
        *((base + index as i64 * 4) as *const u32)

fn store_u32_index(base: i64, index: i32, value: u32):
    unsafe:
        *((base + index as i64 * 4) as *mut u32) = value

fn load_i64_index(base: i64, index: i32) -> i64:
    unsafe:
        *((base + index as i64 * 8) as *const i64)

fn store_i64_index(base: i64, index: i32, value: i64):
    unsafe:
        *((base + index as i64 * 8) as *mut i64) = value

fn load_i32(base: i64, offset: i64) -> i32:
    unsafe:
        *((base + offset) as *const i32)

fn store_i32(base: i64, offset: i64, value: i32):
    unsafe:
        *((base + offset) as *mut i32) = value

fn load_i64(base: i64, offset: i64) -> i64:
    unsafe:
        *((base + offset) as *const i64)

fn store_i64(base: i64, offset: i64, value: i64):
    unsafe:
        *((base + offset) as *mut i64) = value

fn fiber_state(f: i64) -> i32:
    load_i32(f, FIBER_OFF_STATE)

fn fiber_set_state(f: i64, value: i32):
    store_i32(f, FIBER_OFF_STATE, value)

fn fiber_stack(f: i64) -> *mut u8:
    load_i64(f, FIBER_OFF_STACK) as *mut u8

fn fiber_set_stack(f: i64, value: *mut u8):
    store_i64(f, FIBER_OFF_STACK, value as i64)

fn fiber_stack_size(f: i64) -> i64:
    load_i64(f, FIBER_OFF_STACK_SIZE)

fn fiber_set_stack_size(f: i64, value: i64):
    store_i64(f, FIBER_OFF_STACK_SIZE, value)

fn fiber_result_buf(f: i64) -> *mut u8:
    load_i64(f, FIBER_OFF_RESULT_BUF) as *mut u8

fn fiber_set_result_buf(f: i64, value: *mut u8):
    store_i64(f, FIBER_OFF_RESULT_BUF, value as i64)

fn fiber_set_result_size(f: i64, value: i32):
    store_i32(f, FIBER_OFF_RESULT_SIZE, value)

fn fiber_cancel_requested(f: i64) -> i32:
    load_i32(f, FIBER_OFF_CANCEL_REQUESTED)

fn fiber_set_cancel_requested(f: i64, value: i32):
    store_i32(f, FIBER_OFF_CANCEL_REQUESTED, value)

fn fiber_cancelled_return(f: i64) -> i32:
    load_i32(f, FIBER_OFF_CANCELLED_RETURN)

fn fiber_set_cancelled_return_flag(f: i64, value: i32):
    store_i32(f, FIBER_OFF_CANCELLED_RETURN, value)

fn fiber_entry_ptr(f: i64) -> i64:
    load_i64(f, FIBER_OFF_ENTRY)

fn fiber_set_entry_ptr(f: i64, value: i64):
    store_i64(f, FIBER_OFF_ENTRY, value)

fn fiber_arg_ptr(f: i64) -> i64:
    load_i64(f, FIBER_OFF_ARG)

fn fiber_set_arg_ptr(f: i64, value: i64):
    store_i64(f, FIBER_OFF_ARG, value)

fn fiber_next(f: i64) -> i64:
    load_i64(f, FIBER_OFF_NEXT)

fn fiber_set_next(f: i64, value: i64):
    store_i64(f, FIBER_OFF_NEXT, value)

fn fiber_id(f: i64) -> i32:
    load_i32(f, FIBER_OFF_ID)

fn fiber_set_id(f: i64, value: i32):
    store_i32(f, FIBER_OFF_ID, value)

fn fiber_slot(f: i64) -> i32:
    load_i32(f, FIBER_OFF_SLOT)

fn fiber_set_slot(f: i64, value: i32):
    store_i32(f, FIBER_OFF_SLOT, value)

fn fiber_has_panic(f: i64) -> i32:
    load_i32(f, FIBER_OFF_HAS_PANIC)

fn fiber_set_has_panic(f: i64, value: i32):
    store_i32(f, FIBER_OFF_HAS_PANIC, value)

fn fiber_panic_msg(f: i64) -> *const u8:
    load_i64(f, FIBER_OFF_PANIC_MSG) as *const u8

fn fiber_set_panic_msg(f: i64, value: *const u8):
    store_i64(f, FIBER_OFF_PANIC_MSG, value as i64)

fn fiber_panic_msg_len(f: i64) -> i32:
    load_i32(f, FIBER_OFF_PANIC_MSG_LEN)

fn fiber_set_panic_msg_len(f: i64, value: i32):
    store_i32(f, FIBER_OFF_PANIC_MSG_LEN, value)

fn fiber_owner_worker(f: i64) -> i32:
    load_i32(f, FIBER_OFF_OWNER_WORKER)

fn fiber_set_owner_worker(f: i64, value: i32):
    store_i32(f, FIBER_OFF_OWNER_WORKER, value)

fn fiber_compose_id(slot: i32, generation: u32) -> i32:
    ((generation as i32) << (FIBER_SLOT_BITS as u32)) | slot

fn fiber_slot_from_id(fiber_id: i32) -> i32:
    if fiber_id <= 0:
        return -1
    fiber_id & FIBER_SLOT_MASK

fn fiber_ring_index(index: i32) -> i32:
    index & FIBER_SLOT_MASK

fn fiber_lookup(wanted_fiber_id: i32) -> i64:
    let slot = fiber_slot_from_id(wanted_fiber_id)
    if slot < 0 or slot >= MAX_FIBERS:
        return 0
    let f = load_i64_index(fibers_by_slot_base(), slot)
    if f == 0 or fiber_id(f) != wanted_fiber_id:
        return 0
    f

fn allocate_fiber_slot() -> i32:
    if free_fiber_slot_count <= 0:
        return -1
    free_fiber_slot_count = free_fiber_slot_count - 1
    let slot = load_i32_index(free_fiber_slots_base(), free_fiber_slot_count)
    var generation = load_u32_index(fiber_slot_generations_base(), slot) + (1 as u32)
    if generation == 0 as u32:
        generation = 1 as u32
    store_u32_index(fiber_slot_generations_base(), slot, generation)
    slot

fn release_fiber_slot(slot: i32):
    if slot < 0 or slot >= MAX_FIBERS:
        return
    if free_fiber_slot_count >= MAX_FIBERS:
        return
    store_i64_index(fibers_by_slot_base(), slot, 0)
    store_i32_index(free_fiber_slots_base(), free_fiber_slot_count, slot)
    free_fiber_slot_count = free_fiber_slot_count + 1

fn unregister_fiber(f: i64):
    if f == 0:
        return
    let slot = fiber_slot(f)
    if slot >= 0 and slot < MAX_FIBERS and load_i64_index(fibers_by_slot_base(), slot) == f:
        release_fiber_slot(slot)
    fiber_set_slot(f, -1)

fn enqueue_panicked_fiber(fiber_id: i32):
    if fiber_id <= 0:
        return
    if panicked_fiber_count >= MAX_FIBERS:
        return
    let tail = fiber_ring_index(panicked_fiber_head + panicked_fiber_count)
    store_i32_index(panicked_fiber_ids_base(), tail, fiber_id)
    panicked_fiber_count = panicked_fiber_count + 1

fn worker_queue_slot(worker: i32, index: i32) -> i32:
    worker * MAX_FIBERS + fiber_ring_index(index)

fn worker_queue_count(worker: i32) -> i32:
    load_i32_index(worker_queue_counts_base(), worker)

fn worker_queue_head(worker: i32) -> i32:
    load_i32_index(worker_queue_heads_base(), worker)

fn worker_set_queue_count(worker: i32, value: i32):
    store_i32_index(worker_queue_counts_base(), worker, value)

fn worker_set_queue_head(worker: i32, value: i32):
    store_i32_index(worker_queue_heads_base(), worker, value)

fn enqueue_worker(worker: i32, f: i64):
    let count = worker_queue_count(worker)
    if count >= MAX_FIBERS:
        abort()
    fiber_set_owner_worker(f, worker)
    let tail = worker_queue_slot(worker, worker_queue_head(worker) + count)
    store_i64_index(worker_queue_base(), tail, f)
    worker_set_queue_count(worker, count + 1)

fn enqueue_worker_front(worker: i32, f: i64):
    let count = worker_queue_count(worker)
    if count >= MAX_FIBERS:
        abort()
    fiber_set_owner_worker(f, worker)
    let head = fiber_ring_index(worker_queue_head(worker) - 1)
    worker_set_queue_head(worker, head)
    store_i64_index(worker_queue_base(), worker_queue_slot(worker, head), f)
    worker_set_queue_count(worker, count + 1)

fn pop_worker_local(worker: i32) -> i64:
    let count = worker_queue_count(worker)
    if count <= 0:
        return 0
    let tail_index = worker_queue_slot(worker, worker_queue_head(worker) + count - 1)
    let f = load_i64_index(worker_queue_base(), tail_index)
    store_i64_index(worker_queue_base(), tail_index, 0)
    worker_set_queue_count(worker, count - 1)
    f

fn steal_from_worker(victim: i32) -> i64:
    fiber_steal_attempts = fiber_steal_attempts + 1
    let count = worker_queue_count(victim)
    if count <= 0:
        return 0
    let head = worker_queue_head(victim)
    let f = load_i64_index(worker_queue_base(), worker_queue_slot(victim, head))
    store_i64_index(worker_queue_base(), worker_queue_slot(victim, head), 0)
    worker_set_queue_head(victim, fiber_ring_index(head + 1))
    worker_set_queue_count(victim, count - 1)
    fiber_steal_events = fiber_steal_events + 1
    f

fn dequeue_for_worker(worker: i32) -> i64:
    let local = pop_worker_local(worker)
    if local != 0:
        return local
    if active_worker_count <= 1:
        return 0
    var checked = 1
    while checked < active_worker_count:
        let victim_offset = ((scheduler_round + checked as i64) % (active_worker_count as i64)) as i32
        let victim = (worker + victim_offset) % active_worker_count
        if victim != worker:
            let stolen = steal_from_worker(victim)
            if stolen != 0:
                scheduler_round = scheduler_round + 1
                return stolen
        checked = checked + 1
    scheduler_round = scheduler_round + 1
    0

fn total_queued_fibers() -> i32:
    var total = 0
    var i = 0
    while i < active_worker_count:
        total = total + worker_queue_count(i)
        i = i + 1
    total

fn guard_page_size() -> i64:
    if fiber_page_size != 0:
        return fiber_page_size
    fiber_page_size = rt_fiber_page_size()
    if fiber_page_size <= 0:
        abort()
    fiber_page_size

fn fiber_effective_stack_size() -> i64:
    if fiber_default_stack_size > 0: fiber_default_stack_size else: FIBER_STACK_SIZE

fn fiber_effective_pool_limit() -> i32:
    if fiber_pool_limit > 0: fiber_pool_limit else: MAX_FIBERS

fn allocate_stack_region(size: i64) -> *mut u8:
    let page_sz = guard_page_size()
    let total = page_sz + size
    let region = mmap(0 as *mut u8, total as u64, PROT_READ_WRITE, rt_fiber_mmap_flags(), -1, 0)
    if region as i64 == MAP_FAILED:
        return 0 as *mut u8
    let _ = mprotect(region, page_sz as u64, PROT_NONE)
    (region as i64 + page_sz) as *mut u8

fn acquire_fiber() -> i64:
    if free_pool_head != 0:
        let f = free_pool_head
        free_pool_head = fiber_next(f)
        if fiber_pool_free_count > 0:
            fiber_pool_free_count = fiber_pool_free_count - 1
        let stack = fiber_stack(f)
        let stack_size = fiber_stack_size(f)
        with_memset(f as *mut u8, 0, FIBER_SIZE)
        fiber_set_stack(f, stack)
        fiber_set_stack_size(f, stack_size)
        fiber_set_state(f, FIBER_STATE_READY)
        fiber_set_slot(f, -1)
        fiber_pool_reuse_count = fiber_pool_reuse_count + 1
        return f

    let f = with_alloc(FIBER_SIZE) as i64
    if f == 0:
        return 0
    with_memset(f as *mut u8, 0, FIBER_SIZE)
    let default_stack_size = fiber_effective_stack_size()
    fiber_set_stack_size(f, default_stack_size)
    fiber_set_slot(f, -1)
    let stack = allocate_stack_region(default_stack_size)
    if stack as i64 == 0:
        with_free(f as *mut u8)
        return 0
    fiber_set_stack(f, stack)
    fiber_pool_alloc_count = fiber_pool_alloc_count + 1
    f

fn free_fiber_stack(f: i64):
    let stack = fiber_stack(f)
    if stack as i64 == 0:
        return
    let page_sz = guard_page_size()
    let region = (stack as i64 - page_sz) as *mut u8
    let _ = munmap(region, (page_sz + fiber_stack_size(f)) as u64)
    fiber_set_stack(f, 0 as *mut u8)

fn recycle_fiber(f: i64):
    if f == 0:
        return
    if fiber_id(f) != 0 and live_fiber_count > 0:
        live_fiber_count = live_fiber_count - 1
    let stack = fiber_stack(f)
    let stack_size = fiber_stack_size(f)
    let panic_msg = fiber_panic_msg(f)
    if panic_msg as i64 != 0:
        with_free(panic_msg as *mut u8)
    with_memset(f as *mut u8, 0, FIBER_SIZE)
    fiber_set_stack(f, stack)
    fiber_set_stack_size(f, stack_size)
    fiber_set_state(f, FIBER_STATE_DONE)
    fiber_set_slot(f, -1)
    if fiber_pool_free_count >= fiber_effective_pool_limit():
        free_fiber_stack(f)
        with_free(f as *mut u8)
        return
    fiber_set_next(f, free_pool_head)
    free_pool_head = f
    fiber_pool_free_count = fiber_pool_free_count + 1

fn free_fiber_pool():
    while free_pool_head != 0:
        let f = free_pool_head
        free_pool_head = fiber_next(f)
        free_fiber_stack(f)
        with_free(f as *mut u8)
    fiber_pool_free_count = 0

fn fiber_write_i32(fd: i32, n: i32):
    var value = n
    var buf: [16]u8 = [0 as u8; 16]
    var i = 0
    if value < 0:
        let _ = write(fd, "-" as *const u8, 1)
        value = 0 - value
    if value == 0:
        let _ = write(fd, "0" as *const u8, 1)
        return
    while value > 0 and i < 15:
        buf[i] = (48 + (value % 10)) as u8
        value = value / 10
        i = i + 1
    var j = i - 1
    while j >= 0:
        let _ = write(fd, (&buf as i64 + j as i64) as *const u8, 1)
        j = j - 1

pub fn with_fiber_stack_overflow_handler(sig: i32, info: *const u8, ucontext: *mut u8) -> Unit:
    let _ = ucontext
    let fault_addr = rt_fiber_fault_addr(info)
    let current = current_worker_fiber()
    if current != 0:
        let stack = fiber_stack(current)
        if stack as i64 != 0:
            let page_sz = guard_page_size()
            let guard_start = stack as i64 - page_sz
            let guard_end = stack as i64
            if fault_addr >= guard_start and fault_addr < guard_end:
                let _ = write(2, "fatal: fiber stack overflow (fiber #" as *const u8, 36)
                fiber_write_i32(2, fiber_id(current))
                let _ = write(2, ")\n" as *const u8, 2)
                _exit(134)

    rt_fiber_reset_signal_handler(sig)
    let _ = raise(sig)

fn fiber_install_signal_handlers():
    rt_fiber_install_signal_handlers(alt_stack_ptr(), FIBER_ALT_STACK_SIZE, with_fiber_stack_overflow_handler as i64)

pub unsafe fn with_fiber_bootstrap_load(entry_out: *mut i64, arg_out: *mut i64, result_out: *mut i64) -> Unit:
    let current = current_worker_fiber()
    if current == 0:
        *entry_out = 0
        *arg_out = 0
        *result_out = 0
        return
    *entry_out = fiber_entry_ptr(current)
    *arg_out = fiber_arg_ptr(current)
    *result_out = fiber_result_buf(current) as i64

pub fn with_fiber_bootstrap_finish() -> Unit:
    let worker = current_worker_index()
    let current = worker_current_fibers[worker as i64]
    if current == 0:
        abort()
    scheduler_lock()
    fiber_set_state(current, FIBER_STATE_DONE)
    scheduler_wake_all()
    scheduler_unlock()
    with_fiber_switch(current as *mut u8, scheduler_ctx_ptr(worker))
    abort()

fn finish_scheduler_turn(worker: i32, f: i64):
    scheduler_lock()
    if scheduler_running_fibers > 0:
        scheduler_running_fibers = scheduler_running_fibers - 1
    worker_current_fibers[worker as i64] = 0
    if fiber_state(f) == FIBER_STATE_SUSPENDED:
        enqueue_worker_front(worker, f)
    scheduler_wake_all()
    scheduler_unlock()

fn run_one_fiber_for_worker(worker: i32) -> i32:
    scheduler_lock()
    let f = dequeue_for_worker(worker)
    if f == 0:
        scheduler_unlock()
        return 0
    fiber_set_state(f, FIBER_STATE_RUNNING)
    worker_current_fibers[worker as i64] = f
    scheduler_running_fibers = scheduler_running_fibers + 1
    scheduler_unlock()
    with_fiber_switch(scheduler_ctx_ptr(worker), f as *mut u8)
    finish_scheduler_turn(worker, f)
    1

fn scheduler_worker_loop(worker: i32):
    while true:
        if run_one_fiber_for_worker(worker) != 0:
            continue
        scheduler_lock()
        while total_queued_fibers() == 0 and scheduler_shutdown_requested == 0:
            scheduler_wait()
        let done = scheduler_shutdown_requested != 0 and total_queued_fibers() == 0 and scheduler_running_fibers == 0
        scheduler_unlock()
        if done:
            return

fn scheduler_worker_entry(arg: *mut u8) -> *mut u8:
    let worker = (arg as i64) as i32
    scheduler_lock()
    worker_thread_ids[worker as i64] = pthread_self()
    scheduler_wake_all()
    scheduler_unlock()
    scheduler_worker_loop(worker)
    0 as *mut u8

pub fn with_fiber_in_fiber() -> i32:
    if current_worker_fiber() != 0: 1 else: 0

pub fn with_runtime_current_cancel_requested() -> i32:
    let current = current_worker_fiber()
    if current == 0:
        return 0
    if fiber_cancel_requested(current) != 0: 1 else: 0

fn scheduler_start_workers():
    if worker_threads_started != 0:
        return
    worker_threads_started = 1
    var i = 1
    while i < active_worker_count:
        let handle = rt_thread_spawn(scheduler_worker_entry as *mut u8, (i as i64) as *mut u8)
        if handle < 0:
            let _ = write(2, "fatal: could not start fiber scheduler worker\n" as *const u8, 46)
            abort()
        worker_handles[i as i64] = handle
        i = i + 1

pub fn with_runtime_core_init() -> Unit:
    scheduler_init_primitives()
    scheduler_lock()
    scheduler_shutdown_requested = 0
    scheduler_running_fibers = 0
    worker_threads_started = 0
    active_worker_count = if configured_worker_count > 0: configured_worker_count else: 1
    worker_thread_ids[0] = pthread_self()
    fiber_page_size = guard_page_size()
    fiber_pool_reuse_count = 0
    fiber_pool_alloc_count = 0
    free_fiber_pool()
    live_fiber_count = 0
    fiber_steal_attempts = 0
    fiber_steal_events = 0
    cross_thread_cancel_count = 0
    scheduler_round = 0
    free_fiber_slot_count = MAX_FIBERS
    panicked_fiber_head = 0
    panicked_fiber_count = 0
    var i = 0
    while i < MAX_FIBERS:
        store_i64_index(fibers_by_slot_base(), i, 0)
        store_u32_index(fiber_slot_generations_base(), i, 0 as u32)
        store_i32_index(free_fiber_slots_base(), i, MAX_FIBERS - 1 - i)
        store_i32_index(panicked_fiber_ids_base(), i, 0)
        i = i + 1
    i = 0
    while i < MAX_FIBER_WORKERS:
        worker_current_fibers[i as i64] = 0
        worker_thread_ids[i as i64] = 0
        worker_handles[i as i64] = 0
        worker_set_queue_head(i, 0)
        worker_set_queue_count(i, 0)
        i = i + 1
    i = 0
    while i < 8192:
        store_i64_index(worker_queue_base(), i, 0)
        i = i + 1
    worker_thread_ids[0] = pthread_self()
    scheduler_unlock()
    fiber_install_signal_handlers()
    scheduler_start_workers()

pub fn with_runtime_configure_fibers(stack_size: i64, pool_size: i32, worker_count: i32) -> i32:
    let next_stack = if stack_size > 0: stack_size else: FIBER_STACK_SIZE
    let next_pool = if pool_size > 0: pool_size else: MAX_FIBERS
    let next_workers = if worker_count > 0: worker_count else: 1
    if next_workers < 1 or next_workers > MAX_FIBER_WORKERS:
        return -1
    if live_fiber_count != 0 or free_pool_head != 0 or worker_threads_started != 0:
        if next_stack == fiber_effective_stack_size() and next_pool == fiber_effective_pool_limit() and next_workers == active_worker_count:
            return 0
        return -1
    fiber_default_stack_size = next_stack
    fiber_pool_limit = next_pool
    configured_worker_count = next_workers
    0

pub fn with_fiber_spawn(entry_fn: *const u8, arg: *mut u8, result_buf: *mut u8, result_size: i32, stack_size: i32) -> i32:
    scheduler_lock()
    if live_fiber_count >= MAX_FIBERS:
        scheduler_unlock()
        return -1
    let slot = allocate_fiber_slot()
    if slot < 0:
        scheduler_unlock()
        return -1
    let f = acquire_fiber()
    if f == 0:
        release_fiber_slot(slot)
        scheduler_unlock()
        return -1

    let wanted_stack_size = if stack_size > 0: stack_size as i64 else: fiber_effective_stack_size()
    if wanted_stack_size > 0 and fiber_stack_size(f) != wanted_stack_size:
        free_fiber_stack(f)
        fiber_set_stack_size(f, wanted_stack_size)
        let stack = allocate_stack_region(wanted_stack_size)
        if stack as i64 == 0:
            release_fiber_slot(slot)
            with_free(f as *mut u8)
            scheduler_unlock()
            return -1
        fiber_set_stack(f, stack)

    with_memset(f as *mut u8, 0, FIBER_CTX_SIZE)
    fiber_set_entry_ptr(f, entry_fn as i64)
    fiber_set_arg_ptr(f, arg as i64)
    fiber_set_result_buf(f, result_buf)
    fiber_set_result_size(f, result_size)
    fiber_set_state(f, FIBER_STATE_READY)
    fiber_set_slot(f, slot)
    let fiber_id = fiber_compose_id(slot, load_u32_index(fiber_slot_generations_base(), slot))
    fiber_set_id(f, fiber_id)
    fiber_set_cancel_requested(f, 0)
    fiber_set_cancelled_return_flag(f, 0)
    fiber_set_has_panic(f, 0)
    fiber_set_panic_msg(f, 0 as *const u8)
    fiber_set_panic_msg_len(f, 0)
    fiber_set_owner_worker(f, current_worker_index())
    fiber_set_next(f, 0)
    store_i64_index(fibers_by_slot_base(), slot, f)
    live_fiber_count = live_fiber_count + 1

    with_fiber_prepare_initial_context(f as *mut u8, fiber_stack(f), fiber_stack_size(f))
    enqueue_worker(current_worker_index(), f)
    scheduler_wake_all()
    scheduler_unlock()
    return fiber_id

pub fn with_fiber_yield() -> Unit:
    let worker = current_worker_index()
    let current = worker_current_fibers[worker as i64]
    if current == 0:
        return
    scheduler_lock()
    fiber_set_state(current, FIBER_STATE_SUSPENDED)
    scheduler_wake_all()
    scheduler_unlock()
    with_fiber_switch(current as *mut u8, scheduler_ctx_ptr(worker))

pub unsafe fn with_runtime_take_completed_fiber(fiber_id: i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32, cancelled_return_out: *mut i32) -> i32:
    *panic_msg_out = 0 as *const u8
    *panic_msg_len_out = 0
    *cancelled_return_out = 0

    scheduler_lock()
    let f = fiber_lookup(fiber_id)
    if f == 0 or fiber_state(f) != FIBER_STATE_DONE:
        scheduler_unlock()
        return 0

    *cancelled_return_out = fiber_cancelled_return(f)

    if fiber_has_panic(f) != 0:
        *panic_msg_out = fiber_panic_msg(f)
        *panic_msg_len_out = fiber_panic_msg_len(f)
        fiber_set_panic_msg(f, 0 as *const u8)
        fiber_set_has_panic(f, 0)

    unregister_fiber(f)
    recycle_fiber(f)
    scheduler_unlock()
    1

pub unsafe fn with_runtime_take_panicked_fiber(fiber_id_out: *mut i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32) -> i32:
    *fiber_id_out = 0
    *panic_msg_out = 0 as *const u8
    *panic_msg_len_out = 0

    scheduler_lock()
    while panicked_fiber_count > 0:
        let queued_fiber_id = load_i32_index(panicked_fiber_ids_base(), panicked_fiber_head)
        store_i32_index(panicked_fiber_ids_base(), panicked_fiber_head, 0)
        panicked_fiber_head = fiber_ring_index(panicked_fiber_head + 1)
        panicked_fiber_count = panicked_fiber_count - 1

        let f = fiber_lookup(queued_fiber_id)
        if f == 0 or fiber_state(f) != FIBER_STATE_DONE or fiber_has_panic(f) == 0:
            continue

        *fiber_id_out = fiber_id(f)
        *panic_msg_out = fiber_panic_msg(f)
        *panic_msg_len_out = fiber_panic_msg_len(f)
        fiber_set_panic_msg(f, 0 as *const u8)
        fiber_set_has_panic(f, 0)
        unregister_fiber(f)
        recycle_fiber(f)
        scheduler_unlock()
        return 1
    scheduler_unlock()
    0

fn running_worker_for_fiber(f: i64) -> i32:
    var i = 0
    while i < active_worker_count:
        if worker_current_fibers[i as i64] == f:
            return i
        i = i + 1
    -1

pub fn with_runtime_request_cancel(fiber_id: i32) -> i32:
    scheduler_lock()
    let f = fiber_lookup(fiber_id)
    if f == 0 or fiber_state(f) == FIBER_STATE_DONE:
        scheduler_unlock()
        return 0
    fiber_set_cancel_requested(f, 1)
    let running_worker = running_worker_for_fiber(f)
    let owner_worker = if running_worker >= 0: running_worker else: fiber_owner_worker(f)
    if owner_worker >= 0 and owner_worker != current_worker_index():
        cross_thread_cancel_count = cross_thread_cancel_count + 1
    scheduler_wake_all()
    scheduler_unlock()
    1

pub fn with_fiber_set_result(value: i64) -> Unit:
    let current = current_worker_fiber()
    if current != 0:
        store_i64(current, FIBER_OFF_RESULT, value)

pub fn with_runtime_current_set_cancelled_return() -> Unit:
    let current = current_worker_fiber()
    if current != 0:
        fiber_set_cancelled_return_flag(current, 1)

pub fn with_runtime_completed_cancelled_return(fiber_id: i32) -> i32:
    scheduler_lock()
    let f = fiber_lookup(fiber_id)
    if f == 0 or fiber_state(f) != FIBER_STATE_DONE:
        scheduler_unlock()
        return 0
    let out = fiber_cancelled_return(f)
    scheduler_unlock()
    out

pub fn with_runtime_current_set_cancel_requested() -> Unit:
    let current = current_worker_fiber()
    if current != 0:
        fiber_set_cancel_requested(current, 1)

pub fn with_fiber_panic_capture(msg: *const u8, msg_len: i32) -> Unit:
    let worker = current_worker_index()
    let current = worker_current_fibers[worker as i64]
    if current == 0:
        return
    var buf: *mut u8 = 0 as *mut u8
    if msg_len >= 0:
        buf = with_alloc(msg_len + 1)
        if buf as i64 != 0 and msg as i64 != 0 and msg_len > 0:
            with_memcpy(buf, msg, msg_len)
            unsafe:
                *((buf as i64 + msg_len as i64) as *mut u8) = 0 as u8
    scheduler_lock()
    fiber_set_has_panic(current, 1)
    fiber_set_panic_msg(current, buf as *const u8)
    fiber_set_panic_msg_len(current, msg_len)
    fiber_set_state(current, FIBER_STATE_DONE)
    enqueue_panicked_fiber(fiber_id(current))
    scheduler_wake_all()
    scheduler_unlock()
    with_fiber_switch(current as *mut u8, scheduler_ctx_ptr(worker))
    abort()

pub fn with_runtime_core_shutdown() -> Unit:
    scheduler_lock()
    scheduler_shutdown_requested = 1
    scheduler_wake_all()
    scheduler_unlock()
    var wi = 1
    while wi < active_worker_count:
        let handle = worker_handles[wi as i64]
        if handle > 0:
            let _ = rt_thread_join(handle)
        wi = wi + 1

    scheduler_lock()
    var i = 0
    while i < MAX_FIBERS:
        let f = load_i64_index(fibers_by_slot_base(), i)
        if f != 0:
            unregister_fiber(f)
            recycle_fiber(f)
        i = i + 1
    i = 0
    while i < active_worker_count:
        worker_current_fibers[i as i64] = 0
        worker_set_queue_head(i, 0)
        worker_set_queue_count(i, 0)
        i = i + 1
    panicked_fiber_head = 0
    panicked_fiber_count = 0
    free_fiber_pool()
    worker_threads_started = 0
    active_worker_count = 1
    scheduler_running_fibers = 0
    scheduler_unlock()

pub fn with_runtime_core_has_fibers() -> i32:
    scheduler_lock()
    let has = total_queued_fibers() > 0 or scheduler_running_fibers > 0
    scheduler_unlock()
    if has: 1 else: 0

pub fn with_runtime_core_run_one_step() -> Unit:
    if run_one_fiber_for_worker(current_worker_index()) == 0:
        let _ = rt_nanosleep(1000)

pub fn with_runtime_fiber_is_completed(fiber_id: i32) -> i32:
    scheduler_lock()
    let f = fiber_lookup(fiber_id)
    if f == 0:
        scheduler_unlock()
        return 0
    let done = fiber_state(f) == FIBER_STATE_DONE
    scheduler_unlock()
    if done: 1 else: 0

pub fn with_runtime_fiber_is_live(fiber_id: i32) -> i32:
    scheduler_lock()
    let f = fiber_lookup(fiber_id)
    if f == 0:
        scheduler_unlock()
        return 0
    scheduler_unlock()
    1

pub fn with_runtime_fiber_running_worker(fiber_id: i32) -> i32:
    scheduler_lock()
    let f = fiber_lookup(fiber_id)
    if f == 0:
        scheduler_unlock()
        return -1
    let worker = running_worker_for_fiber(f)
    scheduler_unlock()
    worker

pub fn with_fiber_pool_reuses() -> i64:
    fiber_pool_reuse_count

pub fn with_fiber_pool_allocs() -> i64:
    fiber_pool_alloc_count

pub fn with_fiber_stack_size_bytes() -> i64:
    fiber_effective_stack_size()

pub fn with_fiber_current_stack_size_bytes() -> i64:
    let current = current_worker_fiber()
    if current == 0:
        return 0
    fiber_stack_size(current)

pub fn with_fiber_pool_free_count() -> i32:
    fiber_pool_free_count

pub fn with_fiber_pool_size_limit() -> i32:
    fiber_effective_pool_limit()

pub fn with_fiber_max_fibers() -> i32:
    MAX_FIBERS

pub fn with_fiber_live_fibers() -> i32:
    live_fiber_count

pub fn with_fiber_steal_events() -> i64:
    fiber_steal_events

pub fn with_fiber_steal_attempts() -> i64:
    fiber_steal_attempts

pub fn with_fiber_worker_count() -> i32:
    active_worker_count

pub fn with_fiber_current_worker_index() -> i32:
    current_worker_index()

pub fn with_fiber_cross_thread_cancels() -> i64:
    cross_thread_cancel_count
