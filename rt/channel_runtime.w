// rt/channel_runtime.w -- channel runtime moved out of fiber.c.
//
// Keeps channel queueing logic in With while the scheduler core remains in
// fiber.c for now. Built early with the seed compiler and linked into both the
// native compiler runtime and embedded runtime payload.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_alloc_origin(size: i64, origin: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> Unit
extern fn with_memset(dst: *mut u8, c: i32, n: i64) -> Unit
extern fn with_fiber_in_fiber() -> i32
extern fn with_fiber_yield() -> Unit
extern fn with_runtime_has_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

let CHAN_INITIAL_CAPACITY: i32 = 16
let DBG_ALLOC_ORIGIN_CHANNEL: i64 = 3
type ChannelDropFn = *const fn(*mut u8) -> Unit

// Packed channel layout:
//   0  *mut u8 buffer
//   8  i32 elem_size
//   12 i32 head
//   16 i32 tail
//   20 i32 count
//   24 i32 capacity
//   28 i32 bounded_capacity
//   32 i32 closed
//   40 drop_fn
//   48 i32 senders
//   52 i32 receivers
// Total size rounded to 56 bytes for 8-byte alignment.
let CHAN_OFF_BUFFER: i64 = 0
let CHAN_OFF_ELEM_SIZE: i64 = 8
let CHAN_OFF_HEAD: i64 = 12
let CHAN_OFF_TAIL: i64 = 16
let CHAN_OFF_COUNT: i64 = 20
let CHAN_OFF_CAPACITY: i64 = 24
let CHAN_OFF_BOUNDED_CAPACITY: i64 = 28
let CHAN_OFF_CLOSED: i64 = 32
let CHAN_OFF_DROP_FN: i64 = 40
let CHAN_OFF_SENDERS: i64 = 48
let CHAN_OFF_RECEIVERS: i64 = 52
let CHAN_SIZE: i64 = 56

fn chan_field_i32(ch: i64, offset: i64) -> i32:
    unsafe:
        *((ch + offset) as *const i32)

fn chan_set_i32(ch: i64, offset: i64, value: i32):
    unsafe:
        *((ch + offset) as *mut i32) = value

fn chan_buffer(ch: i64) -> *mut u8:
    unsafe:
        *((ch + CHAN_OFF_BUFFER) as *const *mut u8)

fn chan_set_buffer(ch: i64, value: *mut u8):
    unsafe:
        *((ch + CHAN_OFF_BUFFER) as *mut *mut u8) = value

fn chan_drop_fn(ch: i64) -> ChannelDropFn:
    unsafe:
        *((ch + CHAN_OFF_DROP_FN) as *const ChannelDropFn)

fn chan_set_drop_fn(ch: i64, value: ChannelDropFn):
    unsafe:
        *((ch + CHAN_OFF_DROP_FN) as *mut ChannelDropFn) = value

fn channel_drop_queued(handle: i64):
    let drop_fn = chan_drop_fn(handle)
    if drop_fn as i64 == 0:
        return
    let buffer = chan_buffer(handle)
    if buffer as i64 == 0:
        return
    let elem_size = chan_field_i32(handle, CHAN_OFF_ELEM_SIZE)
    let cap = chan_field_i32(handle, CHAN_OFF_CAPACITY)
    let count = chan_field_i32(handle, CHAN_OFF_COUNT)
    let head = chan_field_i32(handle, CHAN_OFF_HEAD)
    var i = 0
    while i < count:
        let idx = (head + i) % cap
        let slot = (buffer as i64 + idx as i64 * elem_size as i64) as *mut u8
        drop_fn(slot)
        i = i + 1
    chan_set_i32(handle, CHAN_OFF_COUNT, 0)

fn channel_free(handle: i64):
    channel_drop_queued(handle)
    let buffer = chan_buffer(handle)
    if buffer as i64 != 0:
        with_free(buffer)
        chan_set_buffer(handle, null)
    with_free(handle as *mut u8)

fn channel_release_if_unreferenced(handle: i64):
    if chan_field_i32(handle, CHAN_OFF_SENDERS) <= 0 and chan_field_i32(handle, CHAN_OFF_RECEIVERS) <= 0:
        channel_free(handle)

fn channel_grow(handle: i64) -> i32:
    if handle == 0:
        return 0
    if chan_field_i32(handle, CHAN_OFF_BOUNDED_CAPACITY) > 0:
        return 0

    let old_cap = chan_field_i32(handle, CHAN_OFF_CAPACITY)
    var new_cap = if old_cap > 0: old_cap * 2 else: CHAN_INITIAL_CAPACITY
    if new_cap < CHAN_INITIAL_CAPACITY:
        new_cap = CHAN_INITIAL_CAPACITY

    let elem_size = chan_field_i32(handle, CHAN_OFF_ELEM_SIZE)
    let new_buf = with_alloc_origin(elem_size as i64 * new_cap as i64, DBG_ALLOC_ORIGIN_CHANNEL)
    if new_buf as i64 == 0:
        return 0

    let old_buf = chan_buffer(handle)
    let count = chan_field_i32(handle, CHAN_OFF_COUNT)
    let head = chan_field_i32(handle, CHAN_OFF_HEAD)
    var i = 0
    while i < count:
        let src_idx = (head + i) % old_cap
        let dst = (new_buf as i64 + i as i64 * elem_size as i64) as *mut u8
        let src = (old_buf as i64 + src_idx as i64 * elem_size as i64) as *const u8
        with_memcpy(dst, src, elem_size as i64)
        i = i + 1

    with_free(old_buf)
    chan_set_buffer(handle, new_buf)
    chan_set_i32(handle, CHAN_OFF_CAPACITY, new_cap)
    chan_set_i32(handle, CHAN_OFF_HEAD, 0)
    chan_set_i32(handle, CHAN_OFF_TAIL, count)
    1

fn channel_block_until_progress():
    if with_fiber_in_fiber() != 0:
        with_fiber_yield()
        return
    if with_runtime_has_fibers() != 0:
        with_runtime_run_one_step()

pub fn with_channel_create(capacity: i32, elem_size: i32, drop_fn: ChannelDropFn) -> i64:
    let ch = with_alloc_origin(CHAN_SIZE, DBG_ALLOC_ORIGIN_CHANNEL)
    if ch as i64 == 0:
        return 0
    with_memset(ch, 0, CHAN_SIZE)

    let actual_elem_size = if elem_size > 0: elem_size else: 1
    let actual_cap = if capacity > 0: capacity else: CHAN_INITIAL_CAPACITY
    let buffer = with_alloc_origin(actual_elem_size as i64 * actual_cap as i64, DBG_ALLOC_ORIGIN_CHANNEL)
    if buffer as i64 == 0:
        with_free(ch)
        return 0

    chan_set_buffer(ch as i64, buffer)
    chan_set_i32(ch as i64, CHAN_OFF_ELEM_SIZE, actual_elem_size)
    chan_set_i32(ch as i64, CHAN_OFF_CAPACITY, actual_cap)
    chan_set_i32(ch as i64, CHAN_OFF_BOUNDED_CAPACITY, if capacity > 0: capacity else: 0)
    chan_set_drop_fn(ch as i64, drop_fn)
    chan_set_i32(ch as i64, CHAN_OFF_SENDERS, 1)
    chan_set_i32(ch as i64, CHAN_OFF_RECEIVERS, 1)
    ch as i64

pub fn with_channel_send(ch_handle: i64, value_ptr: *const u8) -> Unit:
    if ch_handle == 0:
        return
    let buffer = chan_buffer(ch_handle)
    if buffer as i64 == 0:
        return

    while chan_field_i32(ch_handle, CHAN_OFF_COUNT) >= chan_field_i32(ch_handle, CHAN_OFF_CAPACITY):
        if chan_field_i32(ch_handle, CHAN_OFF_CLOSED) != 0:
            return
        if chan_field_i32(ch_handle, CHAN_OFF_BOUNDED_CAPACITY) == 0:
            if channel_grow(ch_handle) != 0:
                break
        channel_block_until_progress()
        if with_fiber_in_fiber() == 0 and with_runtime_has_fibers() == 0 and chan_field_i32(ch_handle, CHAN_OFF_COUNT) >= chan_field_i32(ch_handle, CHAN_OFF_CAPACITY):
            return

    if chan_field_i32(ch_handle, CHAN_OFF_CLOSED) != 0:
        return
    let elem_size = chan_field_i32(ch_handle, CHAN_OFF_ELEM_SIZE)
    let tail = chan_field_i32(ch_handle, CHAN_OFF_TAIL)
    let cap = chan_field_i32(ch_handle, CHAN_OFF_CAPACITY)
    let dst = (chan_buffer(ch_handle) as i64 + tail as i64 * elem_size as i64) as *mut u8
    with_memcpy(dst, value_ptr, elem_size as i64)
    chan_set_i32(ch_handle, CHAN_OFF_TAIL, (tail + 1) % cap)
    chan_set_i32(ch_handle, CHAN_OFF_COUNT, chan_field_i32(ch_handle, CHAN_OFF_COUNT) + 1)

pub fn with_channel_recv(ch_handle: i64, out_ptr: *mut u8) -> i32:
    if ch_handle == 0:
        return -1
    let buffer = chan_buffer(ch_handle)
    if buffer as i64 == 0:
        return -1

    while chan_field_i32(ch_handle, CHAN_OFF_COUNT) == 0:
        if chan_field_i32(ch_handle, CHAN_OFF_CLOSED) != 0:
            return -1
        channel_block_until_progress()
        if with_fiber_in_fiber() == 0 and with_runtime_has_fibers() == 0 and chan_field_i32(ch_handle, CHAN_OFF_COUNT) == 0:
            return -1

    let elem_size = chan_field_i32(ch_handle, CHAN_OFF_ELEM_SIZE)
    let head = chan_field_i32(ch_handle, CHAN_OFF_HEAD)
    let cap = chan_field_i32(ch_handle, CHAN_OFF_CAPACITY)
    let src = (chan_buffer(ch_handle) as i64 + head as i64 * elem_size as i64) as *const u8
    with_memcpy(out_ptr, src, elem_size as i64)
    chan_set_i32(ch_handle, CHAN_OFF_HEAD, (head + 1) % cap)
    chan_set_i32(ch_handle, CHAN_OFF_COUNT, chan_field_i32(ch_handle, CHAN_OFF_COUNT) - 1)
    0

pub fn with_channel_try_recv(ch_handle: i64, out_ptr: *mut u8) -> i32:
    if ch_handle == 0:
        return 0
    let buffer = chan_buffer(ch_handle)
    if buffer as i64 == 0:
        return 0
    if chan_field_i32(ch_handle, CHAN_OFF_COUNT) == 0:
        return 0
    let elem_size = chan_field_i32(ch_handle, CHAN_OFF_ELEM_SIZE)
    let head = chan_field_i32(ch_handle, CHAN_OFF_HEAD)
    let cap = chan_field_i32(ch_handle, CHAN_OFF_CAPACITY)
    let src = (buffer as i64 + head as i64 * elem_size as i64) as *const u8
    with_memcpy(out_ptr, src, elem_size as i64)
    chan_set_i32(ch_handle, CHAN_OFF_HEAD, (head + 1) % cap)
    chan_set_i32(ch_handle, CHAN_OFF_COUNT, chan_field_i32(ch_handle, CHAN_OFF_COUNT) - 1)
    1

pub fn with_channel_close(ch_handle: i64) -> Unit:
    if ch_handle == 0:
        return
    chan_set_i32(ch_handle, CHAN_OFF_CLOSED, 1)

pub fn with_channel_destroy(ch_handle: i64) -> Unit:
    if ch_handle == 0:
        return
    channel_free(ch_handle)

pub fn with_channel_release_sender(ch_handle: i64) -> Unit:
    if ch_handle == 0:
        return
    let senders = chan_field_i32(ch_handle, CHAN_OFF_SENDERS)
    if senders > 0:
        chan_set_i32(ch_handle, CHAN_OFF_SENDERS, senders - 1)
    if chan_field_i32(ch_handle, CHAN_OFF_SENDERS) <= 0:
        chan_set_i32(ch_handle, CHAN_OFF_CLOSED, 1)
    channel_release_if_unreferenced(ch_handle)

pub fn with_channel_release_receiver(ch_handle: i64) -> Unit:
    if ch_handle == 0:
        return
    let receivers = chan_field_i32(ch_handle, CHAN_OFF_RECEIVERS)
    if receivers > 0:
        chan_set_i32(ch_handle, CHAN_OFF_RECEIVERS, receivers - 1)
    if chan_field_i32(ch_handle, CHAN_OFF_RECEIVERS) <= 0:
        chan_set_i32(ch_handle, CHAN_OFF_CLOSED, 1)
    channel_release_if_unreferenced(ch_handle)
