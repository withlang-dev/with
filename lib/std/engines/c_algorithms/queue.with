// Migrated from C
use std.engines.c_algorithms.defs

pub fn queue_new() -> *mut _Queue {
    var __local_queue: *mut _Queue

    (__local_queue = (((with_alloc(((sizeof[_Queue]() as u64) as i64)) as *mut c_void) as *mut _Queue)))

    if (__local_queue == null) {
        return ((null as *mut _Queue))

    }

    ((unsafe *__local_queue).head = ((null as *mut _QueueEntry)))

    ((unsafe *__local_queue).tail = ((null as *mut _QueueEntry)))

    return __local_queue

}

// contract: receiver-mut:_Queue,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn queue_push_head(__param_queue: *mut _Queue, __param_data: *mut c_void) -> i32 {
    var __local_new_entry: *mut _QueueEntry

    (__local_new_entry = (((with_alloc(((sizeof[_QueueEntry]() as u64) as i64)) as *mut c_void) as *mut _QueueEntry)))

    if (__local_new_entry == null) {
        return 0

    }

    ((*__local_new_entry).data = __param_data)

    ((*__local_new_entry).prev = ((null as *mut _QueueEntry)))

    ((*__local_new_entry).next = (*__param_queue).head)

    if ((*__param_queue).head == null) {
        ((*__param_queue).head = __local_new_entry)

        ((*__param_queue).tail = __local_new_entry)

    } else {
        ((*(*__param_queue).head).prev = __local_new_entry)

        ((*__param_queue).head = __local_new_entry)

    }

    return 1

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn queue_peek_head(__param_queue: *mut _Queue) -> *mut c_void {
    if (*__param_queue).queue_is_empty() {
        return queue_null_value

    }
    return (*(*__param_queue).head).data


}

// contract: receiver-mut:_Queue,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn queue_push_tail(__param_queue: *mut _Queue, __param_data: *mut c_void) -> i32 {
    var __local_new_entry: *mut _QueueEntry

    (__local_new_entry = (((with_alloc(((sizeof[_QueueEntry]() as u64) as i64)) as *mut c_void) as *mut _QueueEntry)))

    if (__local_new_entry == null) {
        return 0

    }

    ((*__local_new_entry).data = __param_data)

    ((*__local_new_entry).prev = (*__param_queue).tail)

    ((*__local_new_entry).next = ((null as *mut _QueueEntry)))

    if ((*__param_queue).tail == null) {
        ((*__param_queue).head = __local_new_entry)

        ((*__param_queue).tail = __local_new_entry)

    } else {
        ((*(*__param_queue).tail).next = __local_new_entry)

        ((*__param_queue).tail = __local_new_entry)

    }

    return 1

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn queue_peek_tail(__param_queue: *mut _Queue) -> *mut c_void {
    if (*__param_queue).queue_is_empty() {
        return queue_null_value

    }
    return (*(*__param_queue).tail).data


}

impl _Queue {
    pub mut fn queue_free() {
        let __param_queue: *mut _Queue = self as *mut _Queue
        while (not unsafe { (*__param_queue).queue_is_empty() }) {
            unsafe { (*__param_queue).queue_pop_head() }

        }

        with_free(((__param_queue as *mut c_void) as *mut u8))

    }

    pub mut fn queue_pop_head() -> *mut c_void {
        let __param_queue: *mut _Queue = self as *mut _Queue
        var __local_entry: *mut _QueueEntry

        var __local_result: *mut c_void

        if unsafe { (*__param_queue).queue_is_empty() } {
            return queue_null_value

        }

        (__local_entry = (unsafe *__param_queue).head)

        ((unsafe *__param_queue).head = (unsafe *__local_entry).next)

        (__local_result = (unsafe *__local_entry).data)

        if ((unsafe *__param_queue).head == null) {
            ((unsafe *__param_queue).tail = ((null as *mut _QueueEntry)))

        } else {
            ((unsafe *(*__param_queue).head).prev = ((null as *mut _QueueEntry)))

        }

        with_free(((__local_entry as *mut c_void) as *mut u8))

        return __local_result

    }

    pub mut fn queue_pop_tail() -> *mut c_void {
        let __param_queue: *mut _Queue = self as *mut _Queue
        var __local_entry: *mut _QueueEntry

        var __local_result: *mut c_void

        if unsafe { (*__param_queue).queue_is_empty() } {
            return queue_null_value

        }

        (__local_entry = (unsafe *__param_queue).tail)

        ((unsafe *__param_queue).tail = (unsafe *__local_entry).prev)

        (__local_result = (unsafe *__local_entry).data)

        if ((unsafe *__param_queue).tail == null) {
            ((unsafe *__param_queue).head = ((null as *mut _QueueEntry)))

        } else {
            ((unsafe *(*__param_queue).tail).next = ((null as *mut _QueueEntry)))

        }

        with_free(((__local_entry as *mut c_void) as *mut u8))

        return __local_result

    }

    pub fn queue_is_empty() -> i32 {
        let __param_queue: *mut _Queue = (self as *const _Queue) as *mut _Queue
        return (if (unsafe *__param_queue).head == null: 1 else: 0)

    }

}

let queue_null_value: *mut c_void = null
