// rt/fiber_core_darwin.w -- Darwin fiber core moved out of runtime/fiber.c.
//
// This module owns the remaining scheduler/stack/panic core. It uses manual
// ABI declarations instead of c_import so the runtime stays self-contained.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> void
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> void
extern fn with_memset(dst: *mut u8, val: i32, len: i64) -> void
extern fn mmap(addr: *mut u8, len: u64, prot: i32, flags: i32, fd: i32, offset: i64) -> *mut u8
extern fn mprotect(addr: *mut u8, len: u64, prot: i32) -> i32
extern fn munmap(addr: *mut u8, len: u64) -> i32
extern fn sigaltstack(ss: *const u8, old_ss: *mut u8) -> i32
extern fn sigaction(sig: i32, act: *const u8, old_act: *mut u8) -> i32
extern fn raise(sig: i32) -> i32
extern fn write(fd: i32, buf: *const u8, len: u64) -> i64
extern fn _exit(code: i32) -> void
extern fn abort() -> void

extern fn with_fiber_switch(save: *mut u8, restore: *mut u8) -> void
extern fn with_fiber_prepare_initial_context(ctx: *mut u8, stack: *mut u8, stack_size: i64) -> void

let MAX_FIBERS: i32 = 1024
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

let PROT_NONE: i32 = 0
let PROT_READ_WRITE: i32 = 3
let MAP_PRIVATE_ANON: i32 = 0x1002
let MAP_FAILED: i64 = -1
// SC_PAGESIZE_DARWIN removed — page size hardcoded to 16384 (aarch64 Darwin)

let SIGBUS: i32 = 10
let SIGSEGV: i32 = 11
let SA_ONSTACK: i32 = 0x0001
let SA_SIGINFO: i32 = 0x0040

let STACK_T_SIZE: i64 = 24
let STACK_T_OFF_SP: i64 = 0
let STACK_T_OFF_SIZE: i64 = 8
let STACK_T_OFF_FLAGS: i64 = 16

let SIGACTION_SIZE: i64 = 16
let SIGACTION_OFF_HANDLER: i64 = 0
let SIGACTION_OFF_FLAGS: i64 = 12

let SIGINFO_OFF_ADDR: i64 = 24
let FIBER_ALT_STACK_SIZE: i64 = 131072

var current_fiber: i64 = 0
var scheduler_ctx: [168]u8 = [0 as u8; 168]
var free_pool_head: i64 = 0
var fiber_page_size: i64 = 0
var fiber_pool_reuse_count: i64 = 0
var fiber_pool_alloc_count: i64 = 0
var live_fiber_count: i32 = 0
var fiber_steal_events: i64 = 0
var scheduler_round: i64 = 0
var ready_queue: [1024]i64 = [0 as i64; 1024]
var ready_queue_head: i32 = 0
var ready_queue_count: i32 = 0
var steal_queue: [1024]i64 = [0 as i64; 1024]
var steal_queue_head: i32 = 0
var steal_queue_count: i32 = 0
var fibers_by_slot: [1024]i64 = [0 as i64; 1024]
var fiber_slot_generations: [1024]u32 = [0 as u32; 1024]
var free_fiber_slots: [1024]i32 = [0 as i32; 1024]
var free_fiber_slot_count: i32 = 0
var panicked_fiber_ids: [1024]i32 = [0 as i32; 1024]
var panicked_fiber_head: i32 = 0
var panicked_fiber_count: i32 = 0
var fiber_alt_stack_buf: [131072]u8 = [0 as u8; 131072]

fn scheduler_ctx_ptr() -> *mut u8:
    (&mut scheduler_ctx) as *mut [168]u8 as *mut u8

fn alt_stack_ptr() -> *mut u8:
    (&mut fiber_alt_stack_buf) as *mut [131072]u8 as *mut u8

fn ready_queue_base() -> i64:
    (&mut ready_queue) as *mut [1024]i64 as i64

fn steal_queue_base() -> i64:
    (&mut steal_queue) as *mut [1024]i64 as i64

fn fibers_by_slot_base() -> i64:
    (&mut fibers_by_slot) as *mut [1024]i64 as i64

fn fiber_slot_generations_base() -> i64:
    (&mut fiber_slot_generations) as *mut [1024]u32 as i64

fn free_fiber_slots_base() -> i64:
    (&mut free_fiber_slots) as *mut [1024]i32 as i64

fn panicked_fiber_ids_base() -> i64:
    (&mut panicked_fiber_ids) as *mut [1024]i32 as i64

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

fn enqueue(f: i64):
    if ready_queue_count >= MAX_FIBERS:
        abort()
    let tail = fiber_ring_index(ready_queue_head + ready_queue_count)
    store_i64_index(ready_queue_base(), tail, f)
    ready_queue_count = ready_queue_count + 1

fn dequeue() -> i64:
    if ready_queue_count <= 0:
        return 0
    let f = load_i64_index(ready_queue_base(), ready_queue_head)
    store_i64_index(ready_queue_base(), ready_queue_head, 0)
    ready_queue_head = fiber_ring_index(ready_queue_head + 1)
    ready_queue_count = ready_queue_count - 1
    f

fn enqueue_steal(f: i64):
    if steal_queue_count >= MAX_FIBERS:
        abort()
    let tail = fiber_ring_index(steal_queue_head + steal_queue_count)
    store_i64_index(steal_queue_base(), tail, f)
    steal_queue_count = steal_queue_count + 1

fn dequeue_steal() -> i64:
    if steal_queue_count <= 0:
        return 0
    let f = load_i64_index(steal_queue_base(), steal_queue_head)
    store_i64_index(steal_queue_base(), steal_queue_head, 0)
    steal_queue_head = fiber_ring_index(steal_queue_head + 1)
    steal_queue_count = steal_queue_count - 1
    f

fn dequeue_any() -> i64:
    let ready = dequeue()
    if ready != 0:
        return ready
    let stolen = dequeue_steal()
    if stolen != 0:
        fiber_steal_events = fiber_steal_events + 1
    stolen

fn guard_page_size() -> i64:
    if fiber_page_size != 0:
        return fiber_page_size
    // Darwin aarch64 always uses 16K pages; x86_64 uses 4K.
    // Hardcoded to avoid sysconf libc dependency.
    fiber_page_size = 16384
    fiber_page_size

fn allocate_stack_region(size: i64) -> *mut u8:
    let page_sz = guard_page_size()
    let total = page_sz + size
    let region = mmap(0 as *mut u8, total as u64, PROT_READ_WRITE, MAP_PRIVATE_ANON, -1, 0)
    if region as i64 == MAP_FAILED:
        return 0 as *mut u8
    let _ = mprotect(region, page_sz as u64, PROT_NONE)
    (region as i64 + page_sz) as *mut u8

fn acquire_fiber() -> i64:
    if free_pool_head != 0:
        let f = free_pool_head
        free_pool_head = fiber_next(f)
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
    fiber_set_stack_size(f, FIBER_STACK_SIZE)
    fiber_set_slot(f, -1)
    let stack = allocate_stack_region(FIBER_STACK_SIZE)
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
    fiber_set_next(f, free_pool_head)
    free_pool_head = f

fn free_fiber_pool():
    while free_pool_head != 0:
        let f = free_pool_head
        free_pool_head = fiber_next(f)
        free_fiber_stack(f)
        with_free(f as *mut u8)

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

@[c_export("with_fiber_stack_overflow_handler")]
pub fn fiber_stack_overflow_handler(sig: i32, info: *const u8, ucontext: *mut u8):
    let _ = ucontext
    let fault_addr = if info as i64 != 0: unsafe: *((info as i64 + SIGINFO_OFF_ADDR) as *const i64) else: 0
    if current_fiber != 0:
        let stack = fiber_stack(current_fiber)
        if stack as i64 != 0:
            let page_sz = guard_page_size()
            let guard_start = stack as i64 - page_sz
            let guard_end = stack as i64
            if fault_addr >= guard_start and fault_addr < guard_end:
                let _ = write(2, "fatal: fiber stack overflow (fiber #" as *const u8, 36)
                fiber_write_i32(2, fiber_id(current_fiber))
                let _ = write(2, ")\n" as *const u8, 2)
                _exit(134)

    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&mut sa) as *mut [16]u8 as i64
    with_memset(sa_base as *mut u8, 0, SIGACTION_SIZE)
    let _ = sigaction(sig, sa_base as *const u8, 0 as *mut u8)
    let _ = raise(sig)

fn fiber_install_signal_handlers():
    var ss: [24]u8 = [0 as u8; 24]
    let ss_base = (&mut ss) as *mut [24]u8 as i64
    with_memset(ss_base as *mut u8, 0, STACK_T_SIZE)
    store_i64(ss_base, STACK_T_OFF_SP, alt_stack_ptr() as i64)
    store_i64(ss_base, STACK_T_OFF_SIZE, FIBER_ALT_STACK_SIZE)
    store_i32(ss_base, STACK_T_OFF_FLAGS, 0)
    let _ = sigaltstack(ss_base as *const u8, 0 as *mut u8)

    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&mut sa) as *mut [16]u8 as i64
    with_memset(sa_base as *mut u8, 0, SIGACTION_SIZE)
    store_i64(sa_base, SIGACTION_OFF_HANDLER, fiber_stack_overflow_handler as i64)
    store_i32(sa_base, SIGACTION_OFF_FLAGS, SA_SIGINFO | SA_ONSTACK)
    let _ = sigaction(SIGSEGV, sa_base as *const u8, 0 as *mut u8)
    let _ = sigaction(SIGBUS, sa_base as *const u8, 0 as *mut u8)

@[c_export("with_fiber_bootstrap_load")]
pub fn fiber_bootstrap_load(entry_out: *mut i64, arg_out: *mut i64, result_out: *mut i64):
    if current_fiber == 0:
        unsafe:
            *entry_out = 0
            *arg_out = 0
            *result_out = 0
        return
    unsafe:
        *entry_out = fiber_entry_ptr(current_fiber)
        *arg_out = fiber_arg_ptr(current_fiber)
        *result_out = fiber_result_buf(current_fiber) as i64

@[c_export("with_fiber_bootstrap_finish")]
pub fn fiber_bootstrap_finish():
    if current_fiber == 0:
        abort()
    fiber_set_state(current_fiber, FIBER_STATE_DONE)
    with_fiber_switch(current_fiber as *mut u8, scheduler_ctx_ptr())
    abort()

fn run_one_fiber():
    let f = dequeue_any()
    if f == 0:
        return
    fiber_set_state(f, FIBER_STATE_RUNNING)
    current_fiber = f
    with_fiber_switch(scheduler_ctx_ptr(), f as *mut u8)
    current_fiber = 0
    if fiber_state(f) == FIBER_STATE_SUSPENDED:
        if (scheduler_round & 1) == 0:
            enqueue_steal(f)
        else:
            enqueue(f)
        scheduler_round = scheduler_round + 1

@[c_export("with_fiber_in_fiber")]
pub fn fiber_in_fiber() -> i32:
    if current_fiber != 0: 1 else: 0

@[c_export("with_runtime_current_cancel_requested")]
pub fn runtime_current_cancel_requested() -> i32:
    if current_fiber == 0:
        return 0
    if fiber_cancel_requested(current_fiber) != 0: 1 else: 0

@[c_export("with_runtime_core_init")]
pub fn runtime_core_init():
    current_fiber = 0
    fiber_page_size = guard_page_size()
    fiber_pool_reuse_count = 0
    fiber_pool_alloc_count = 0
    live_fiber_count = 0
    fiber_steal_events = 0
    scheduler_round = 0
    ready_queue_head = 0
    ready_queue_count = 0
    steal_queue_head = 0
    steal_queue_count = 0
    free_fiber_slot_count = MAX_FIBERS
    panicked_fiber_head = 0
    panicked_fiber_count = 0
    var i = 0
    while i < MAX_FIBERS:
        store_i64_index(ready_queue_base(), i, 0)
        store_i64_index(steal_queue_base(), i, 0)
        store_i64_index(fibers_by_slot_base(), i, 0)
        store_u32_index(fiber_slot_generations_base(), i, 0 as u32)
        store_i32_index(free_fiber_slots_base(), i, MAX_FIBERS - 1 - i)
        store_i32_index(panicked_fiber_ids_base(), i, 0)
        i = i + 1
    fiber_install_signal_handlers()

@[c_export("with_fiber_spawn")]
pub fn fiber_spawn(entry_fn: *const u8, arg: *mut u8, result_buf: *mut u8, result_size: i32, stack_size: i32) -> i32:
    if live_fiber_count >= MAX_FIBERS:
        return -1
    let slot = allocate_fiber_slot()
    if slot < 0:
        return -1
    let f = acquire_fiber()
    if f == 0:
        release_fiber_slot(slot)
        return -1

    let wanted_stack_size = if stack_size > 0: stack_size as i64 else: FIBER_STACK_SIZE
    if wanted_stack_size > 0 and fiber_stack_size(f) != wanted_stack_size:
        free_fiber_stack(f)
        fiber_set_stack_size(f, wanted_stack_size)
        let stack = allocate_stack_region(wanted_stack_size)
        if stack as i64 == 0:
            release_fiber_slot(slot)
            with_free(f as *mut u8)
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
    fiber_set_next(f, 0)
    store_i64_index(fibers_by_slot_base(), slot, f)
    live_fiber_count = live_fiber_count + 1

    with_fiber_prepare_initial_context(f as *mut u8, fiber_stack(f), fiber_stack_size(f))

    if (fiber_id & 1) == 0:
        enqueue_steal(f)
    else:
        enqueue(f)
    return fiber_id

@[c_export("with_fiber_yield")]
pub fn fiber_yield():
    if current_fiber == 0:
        return
    fiber_set_state(current_fiber, FIBER_STATE_SUSPENDED)
    with_fiber_switch(current_fiber as *mut u8, scheduler_ctx_ptr())

@[c_export("with_runtime_take_completed_fiber")]
pub fn runtime_take_completed_fiber(fiber_id: i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32, cancelled_return_out: *mut i32) -> i32:
    unsafe:
        *panic_msg_out = 0 as *const u8
        *panic_msg_len_out = 0
        *cancelled_return_out = 0

    let f = fiber_lookup(fiber_id)
    if f == 0 or fiber_state(f) != FIBER_STATE_DONE:
        return 0

    unsafe:
        *cancelled_return_out = fiber_cancelled_return(f)

    if fiber_has_panic(f) != 0:
        unsafe:
            *panic_msg_out = fiber_panic_msg(f)
            *panic_msg_len_out = fiber_panic_msg_len(f)
        fiber_set_panic_msg(f, 0 as *const u8)
        fiber_set_has_panic(f, 0)

    unregister_fiber(f)
    recycle_fiber(f)
    1

@[c_export("with_runtime_take_panicked_fiber")]
pub fn runtime_take_panicked_fiber(fiber_id_out: *mut i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32) -> i32:
    unsafe:
        *fiber_id_out = 0
        *panic_msg_out = 0 as *const u8
        *panic_msg_len_out = 0

    while panicked_fiber_count > 0:
        let queued_fiber_id = load_i32_index(panicked_fiber_ids_base(), panicked_fiber_head)
        store_i32_index(panicked_fiber_ids_base(), panicked_fiber_head, 0)
        panicked_fiber_head = fiber_ring_index(panicked_fiber_head + 1)
        panicked_fiber_count = panicked_fiber_count - 1

        let f = fiber_lookup(queued_fiber_id)
        if f == 0 or fiber_state(f) != FIBER_STATE_DONE or fiber_has_panic(f) == 0:
            continue

        unsafe:
            *fiber_id_out = fiber_id(f)
            *panic_msg_out = fiber_panic_msg(f)
            *panic_msg_len_out = fiber_panic_msg_len(f)
        fiber_set_panic_msg(f, 0 as *const u8)
        fiber_set_has_panic(f, 0)
        unregister_fiber(f)
        recycle_fiber(f)
        return 1
    0

@[c_export("with_runtime_request_cancel")]
pub fn runtime_request_cancel(fiber_id: i32) -> i32:
    let f = fiber_lookup(fiber_id)
    if f == 0 or fiber_state(f) == FIBER_STATE_DONE:
        return 0
    fiber_set_cancel_requested(f, 1)
    1

@[c_export("with_fiber_set_result")]
pub fn fiber_set_result(value: i64):
    if current_fiber != 0:
        store_i64(current_fiber, FIBER_OFF_RESULT, value)

@[c_export("with_runtime_current_set_cancelled_return")]
pub fn runtime_current_set_cancelled_return():
    if current_fiber != 0:
        fiber_set_cancelled_return_flag(current_fiber, 1)

@[c_export("with_runtime_completed_cancelled_return")]
pub fn runtime_completed_cancelled_return(fiber_id: i32) -> i32:
    let f = fiber_lookup(fiber_id)
    if f == 0 or fiber_state(f) != FIBER_STATE_DONE:
        return 0
    fiber_cancelled_return(f)

@[c_export("with_runtime_current_set_cancel_requested")]
pub fn runtime_current_set_cancel_requested():
    if current_fiber != 0:
        fiber_set_cancel_requested(current_fiber, 1)

@[c_export("with_fiber_panic_capture")]
pub fn fiber_panic_capture(msg: *const u8, msg_len: i32):
    if current_fiber == 0:
        return
    fiber_set_has_panic(current_fiber, 1)
    var buf: *mut u8 = 0 as *mut u8
    if msg_len >= 0:
        buf = with_alloc(msg_len + 1)
        if buf as i64 != 0 and msg as i64 != 0 and msg_len > 0:
            with_memcpy(buf, msg, msg_len)
            unsafe:
                *((buf as i64 + msg_len as i64) as *mut u8) = 0 as u8
    fiber_set_panic_msg(current_fiber, buf as *const u8)
    fiber_set_panic_msg_len(current_fiber, msg_len)
    fiber_set_state(current_fiber, FIBER_STATE_DONE)
    enqueue_panicked_fiber(fiber_id(current_fiber))
    with_fiber_switch(current_fiber as *mut u8, scheduler_ctx_ptr())
    abort()

@[c_export("with_runtime_core_shutdown")]
pub fn runtime_core_shutdown():
    var i = 0
    while i < MAX_FIBERS:
        let f = load_i64_index(fibers_by_slot_base(), i)
        if f != 0:
            unregister_fiber(f)
            recycle_fiber(f)
        i = i + 1
    ready_queue_head = 0
    ready_queue_count = 0
    steal_queue_head = 0
    steal_queue_count = 0
    current_fiber = 0
    panicked_fiber_head = 0
    panicked_fiber_count = 0
    free_fiber_pool()

@[c_export("with_runtime_core_has_fibers")]
pub fn runtime_core_has_fibers() -> i32:
    if ready_queue_count > 0 or steal_queue_count > 0: 1 else: 0

@[c_export("with_runtime_core_run_one_step")]
pub fn runtime_core_run_one_step():
    if ready_queue_count > 0 or steal_queue_count > 0:
        run_one_fiber()

@[c_export("with_runtime_fiber_is_completed")]
pub fn runtime_fiber_is_completed(fiber_id: i32) -> i32:
    let f = fiber_lookup(fiber_id)
    if f == 0:
        return 0
    if fiber_state(f) == FIBER_STATE_DONE: 1 else: 0

@[c_export("with_fiber_pool_reuses")]
pub fn fiber_pool_reuses() -> i64:
    fiber_pool_reuse_count

@[c_export("with_fiber_pool_allocs")]
pub fn fiber_pool_allocs() -> i64:
    fiber_pool_alloc_count

@[c_export("with_fiber_stack_size_bytes")]
pub fn fiber_stack_size_bytes() -> i64:
    FIBER_STACK_SIZE

@[c_export("with_fiber_max_fibers")]
pub fn fiber_max_fibers() -> i32:
    MAX_FIBERS

@[c_export("with_fiber_live_fibers")]
pub fn fiber_live_fibers() -> i32:
    live_fiber_count

@[c_export("with_fiber_steal_events")]
pub fn fiber_steal_events_fn() -> i64:
    fiber_steal_events
