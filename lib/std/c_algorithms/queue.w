// Migrated from C
use std.c_algorithms.defs

pub fn queue_new() -> *mut _Queue {
    var __local_queue: *mut _Queue

    (__local_queue = (((unsafe { with_alloc(((sizeof[_Queue]() as c_ulong) as i64)) } as *mut c_void) as *mut _Queue)))

    if ((if __local_queue == null: 1 else: 0) != 0) {
        return ((null as *mut _Queue))

    }

    ((unsafe *__local_queue).head = ((null as *mut _QueueEntry)))

    ((unsafe *__local_queue).tail = ((null as *mut _QueueEntry)))

    return __local_queue

}

pub unsafe fn queue_free(__param_queue: *mut _Queue) -> Unit {
    while ((if not (queue_is_empty(__param_queue) != 0): 1 else: 0) != 0) {
        queue_pop_head(__param_queue)

    }

    with_free(((__param_queue as *mut c_void) as *mut u8))

}

pub unsafe fn queue_push_head(__param_queue: *mut _Queue, __param_data: *mut c_void) -> c_int {
    var __local_new_entry: *mut _QueueEntry

    (__local_new_entry = (((with_alloc(((sizeof[_QueueEntry]() as c_ulong) as i64)) as *mut c_void) as *mut _QueueEntry)))

    if ((if __local_new_entry == null: 1 else: 0) != 0) {
        return 0

    }

    ((unsafe *__local_new_entry).data = __param_data)

    ((unsafe *__local_new_entry).prev = ((null as *mut _QueueEntry)))

    ((unsafe *__local_new_entry).next = (unsafe *__param_queue).head)

    if ((if (unsafe *__param_queue).head == null: 1 else: 0) != 0) {
        ((unsafe *__param_queue).head = __local_new_entry)

        ((unsafe *__param_queue).tail = __local_new_entry)

    } else {
        ((unsafe *(unsafe *__param_queue).head).prev = __local_new_entry)

        ((unsafe *__param_queue).head = __local_new_entry)

    }

    return 1

}

pub unsafe fn queue_pop_head(__param_queue: *mut _Queue) -> *mut c_void {
    var __local_entry: *mut _QueueEntry

    var __local_result: *mut c_void

    if (queue_is_empty(__param_queue) != 0) {
        return queue_null_value

    }

    (__local_entry = (unsafe *__param_queue).head)

    ((unsafe *__param_queue).head = (unsafe *__local_entry).next)

    (__local_result = (unsafe *__local_entry).data)

    if ((if (unsafe *__param_queue).head == null: 1 else: 0) != 0) {
        ((unsafe *__param_queue).tail = ((null as *mut _QueueEntry)))

    } else {
        ((unsafe *(unsafe *__param_queue).head).prev = ((null as *mut _QueueEntry)))

    }

    with_free(((__local_entry as *mut c_void) as *mut u8))

    return __local_result

}

pub unsafe fn queue_peek_head(__param_queue: *mut _Queue) -> *mut c_void {
    if (queue_is_empty(__param_queue) != 0) {
        return queue_null_value

    }
    return (unsafe *(unsafe *__param_queue).head).data


}

pub unsafe fn queue_push_tail(__param_queue: *mut _Queue, __param_data: *mut c_void) -> c_int {
    var __local_new_entry: *mut _QueueEntry

    (__local_new_entry = (((with_alloc(((sizeof[_QueueEntry]() as c_ulong) as i64)) as *mut c_void) as *mut _QueueEntry)))

    if ((if __local_new_entry == null: 1 else: 0) != 0) {
        return 0

    }

    ((unsafe *__local_new_entry).data = __param_data)

    ((unsafe *__local_new_entry).prev = (unsafe *__param_queue).tail)

    ((unsafe *__local_new_entry).next = ((null as *mut _QueueEntry)))

    if ((if (unsafe *__param_queue).tail == null: 1 else: 0) != 0) {
        ((unsafe *__param_queue).head = __local_new_entry)

        ((unsafe *__param_queue).tail = __local_new_entry)

    } else {
        ((unsafe *(unsafe *__param_queue).tail).next = __local_new_entry)

        ((unsafe *__param_queue).tail = __local_new_entry)

    }

    return 1

}

pub unsafe fn queue_pop_tail(__param_queue: *mut _Queue) -> *mut c_void {
    var __local_entry: *mut _QueueEntry

    var __local_result: *mut c_void

    if (queue_is_empty(__param_queue) != 0) {
        return queue_null_value

    }

    (__local_entry = (unsafe *__param_queue).tail)

    ((unsafe *__param_queue).tail = (unsafe *__local_entry).prev)

    (__local_result = (unsafe *__local_entry).data)

    if ((if (unsafe *__param_queue).tail == null: 1 else: 0) != 0) {
        ((unsafe *__param_queue).head = ((null as *mut _QueueEntry)))

    } else {
        ((unsafe *(unsafe *__param_queue).tail).next = ((null as *mut _QueueEntry)))

    }

    with_free(((__local_entry as *mut c_void) as *mut u8))

    return __local_result

}

pub unsafe fn queue_peek_tail(__param_queue: *mut _Queue) -> *mut c_void {
    if (queue_is_empty(__param_queue) != 0) {
        return queue_null_value

    }
    return (unsafe *(unsafe *__param_queue).tail).data


}

pub unsafe fn queue_is_empty(__param_queue: *mut _Queue) -> c_int {
    return (if (unsafe *__param_queue).head == null: 1 else: 0)

}

let queue_null_value: *mut c_void = null
