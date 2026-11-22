// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.compare_int
use std.engines.c_algorithms_testing.framework
use std.engines.c_algorithms_testing.list
use std.libc
use std.option
use std.collections

pub fn generate_list() -> *mut _ListEntry writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _ListEntry = ((null as *mut _ListEntry))

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"generate_list".ptr, c"test-list.c".ptr, (38 as i32), c"list_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable2 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"generate_list".ptr, c"test-list.c".ptr, (39 as i32), c"list_append(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable3 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"generate_list".ptr, c"test-list.c".ptr, (40 as i32), c"list_append(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable4 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"generate_list".ptr, c"test-list.c".ptr, (41 as i32), c"list_append(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    return __local_list

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn check_list_integrity(__param_list: *mut _ListEntry) {
    var __local_prev: *mut _ListEntry

    var __local_rover: *mut _ListEntry

    (__local_prev = ((null as *mut _ListEntry)))

    (__local_rover = __param_list)

    while (__local_rover != null) {
        if ((if not (list_prev(__local_rover) == __local_prev): 1 else: 0) as i64) {
            __assert_rtn(c"check_list_integrity".ptr, c"test-list.c".ptr, (55 as i32), c"list_prev(rover) == prev".ptr)
        } else {
            0
        }

        (__local_prev = __local_rover)

        (__local_rover = list_next(__local_rover))

    }

}

pub fn test_list_append() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _ListEntry = ((null as *mut _ListEntry))

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (65 as i32), c"list_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable2 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (67 as i32), c"list_append(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable3 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (69 as i32), c"list_append(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable4 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (71 as i32), c"list_append(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((if not (unsafe { list_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (74 as i32), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (0 as u32)) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (76 as i32), c"list_nth_data(list, 0) == &variable1".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (1 as u32)) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (77 as i32), c"list_nth_data(list, 1) == &variable2".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (2 as u32)) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (78 as i32), c"list_nth_data(list, 2) == &variable3".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (3 as u32)) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (79 as i32), c"list_nth_data(list, 3) == &variable4".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as i32))

    if ((if not (unsafe { list_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (83 as i32), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (84 as i32), c"list_append(&list, &variable1) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_append".ptr, c"test-list.c".ptr, (85 as i32), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    unsafe { list_free(__local_list) }

}

pub fn test_list_prepend() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _ListEntry = ((null as *mut _ListEntry))

    if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (95 as i32), c"list_prepend(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable2 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (97 as i32), c"list_prepend(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable3 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (99 as i32), c"list_prepend(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable4 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (101 as i32), c"list_prepend(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((if not (unsafe { list_nth_data(__local_list, (0 as u32)) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (104 as i32), c"list_nth_data(list, 0) == &variable4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (1 as u32)) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (105 as i32), c"list_nth_data(list, 1) == &variable3".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (2 as u32)) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (106 as i32), c"list_nth_data(list, 2) == &variable2".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (3 as u32)) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (107 as i32), c"list_nth_data(list, 3) == &variable1".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as i32))

    if ((if not (unsafe { list_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (111 as i32), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (112 as i32), c"list_prepend(&list, &variable1) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_prepend".ptr, c"test-list.c".ptr, (113 as i32), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    unsafe { list_free(__local_list) }

}

pub fn test_list_free() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _ListEntry

    (__local_list = generate_list())

    unsafe { list_free(__local_list) }

    unsafe { list_free((null as *mut _ListEntry)) }

}

pub fn test_list_next() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _ListEntry

    var __local_rover: *mut _ListEntry

    (__local_list = generate_list())

    (__local_rover = __local_list)

    if ((if not (unsafe { list_data(__local_rover) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (140 as i32), c"list_data(rover) == &variable1".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { list_next(__local_rover) })

    if ((if not (unsafe { list_data(__local_rover) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (142 as i32), c"list_data(rover) == &variable2".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { list_next(__local_rover) })

    if ((if not (unsafe { list_data(__local_rover) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (144 as i32), c"list_data(rover) == &variable3".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { list_next(__local_rover) })

    if ((if not (unsafe { list_data(__local_rover) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (146 as i32), c"list_data(rover) == &variable4".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { list_next(__local_rover) })

    if ((if not (__local_rover == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_next".ptr, c"test-list.c".ptr, (148 as i32), c"rover == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_nth_entry() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _ListEntry

    var __local_entry: *mut _ListEntry

    (__local_list = generate_list())

    (__local_entry = unsafe { list_nth_entry(__local_list, (0 as u32)) })

    if ((if not (unsafe { list_data(__local_entry) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (162 as i32), c"list_data(entry) == &variable1".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (1 as u32)) })

    if ((if not (unsafe { list_data(__local_entry) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (164 as i32), c"list_data(entry) == &variable2".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (2 as u32)) })

    if ((if not (unsafe { list_data(__local_entry) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (166 as i32), c"list_data(entry) == &variable3".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (3 as u32)) })

    if ((if not (unsafe { list_data(__local_entry) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (168 as i32), c"list_data(entry) == &variable4".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (4 as u32)) })

    if ((if not (__local_entry == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (172 as i32), c"entry == NULL".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { list_nth_entry(__local_list, (400 as u32)) })

    if ((if not (__local_entry == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_entry".ptr, c"test-list.c".ptr, (174 as i32), c"entry == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_nth_data() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _ListEntry

    (__local_list = generate_list())

    if ((if not (unsafe { list_nth_data(__local_list, (0 as u32)) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (186 as i32), c"list_nth_data(list, 0) == &variable1".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (1 as u32)) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (187 as i32), c"list_nth_data(list, 1) == &variable2".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (2 as u32)) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (188 as i32), c"list_nth_data(list, 2) == &variable3".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (3 as u32)) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (189 as i32), c"list_nth_data(list, 3) == &variable4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (4 as u32)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (192 as i32), c"list_nth_data(list, 4) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_nth_data(__local_list, (400 as u32)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_nth_data".ptr, c"test-list.c".ptr, (193 as i32), c"list_nth_data(list, 400) == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_length() -> Unit writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _ListEntry

    (__local_list = generate_list())

    if ((if not (unsafe { list_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_length".ptr, c"test-list.c".ptr, (205 as i32), c"list_length(list) == 4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_length".ptr, c"test-list.c".ptr, (208 as i32), c"list_prepend(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_length(__local_list) } == 5): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_length".ptr, c"test-list.c".ptr, (210 as i32), c"list_length(list) == 5".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

    if ((if not (unsafe { list_length((null as *mut _ListEntry)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_length".ptr, c"test-list.c".ptr, (215 as i32), c"list_length(NULL) == 0".ptr)
    } else {
        0
    }

}

pub fn test_list_remove_entry() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_empty_list: *mut _ListEntry = ((null as *mut _ListEntry))

    var __local_list: *mut _ListEntry

    var __local_entry: *mut _ListEntry

    (__local_list = generate_list())

    (__local_entry = unsafe { list_nth_entry(__local_list, (2 as u32)) })

    if ((if not (unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), __local_entry) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (228 as i32), c"list_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_length(__local_list) } == 3): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (229 as i32), c"list_length(list) == 3".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    (__local_entry = unsafe { list_nth_entry(__local_list, (0 as u32)) })

    if ((if not (unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), __local_entry) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (234 as i32), c"list_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_length(__local_list) } == 2): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (235 as i32), c"list_length(list) == 2".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    if ((if not (unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), (null as *mut _ListEntry)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (240 as i32), c"list_remove_entry(&list, NULL) == 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_remove_entry((&raw mut __local_empty_list as *mut *mut _ListEntry), (null as *mut _ListEntry)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (243 as i32), c"list_remove_entry(&empty_list, NULL) == 0".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

    (__local_list = ((null as *mut _ListEntry)))

    if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (249 as i32), c"list_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((if not (__local_list != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (250 as i32), c"list != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), __local_list) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (251 as i32), c"list_remove_entry(&list, list) != 0".ptr)
    } else {
        0
    }

    if ((if not (__local_list == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (252 as i32), c"list == NULL".ptr)
    } else {
        0
    }

    (__local_list = generate_list())

    (__local_entry = unsafe { list_nth_entry(__local_list, (3 as u32)) })

    if ((if not (unsafe { list_remove_entry((&raw mut __local_list as *mut *mut _ListEntry), __local_entry) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_entry".ptr, c"test-list.c".ptr, (257 as i32), c"list_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    unsafe { list_free(__local_list) }

}

pub fn test_list_remove_data() writes allocation_limit {
    var __local_entries: List[i32] = [89, 4, 23, 42, 4, 16, 15, 4, 8, 99, 50, 30, 4]

    var __local_num_entries: u32 = (((__local_entries.len() as u64) as u32))

    var __local_val: i32

    var __local_list: *mut _ListEntry

    var __local_i: u32

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as u32)))

    while (__local_i < __local_num_entries) {
        if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), (((&raw const __local_entries[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (274 as i32), c"list_prepend(&list, &entries[i]) != NULL".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_val = ((0 as i32)))

    if ((if not (unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), Some(int_equal), ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (279 as i32), c"list_remove_data(&list, int_equal, &val) == 0".ptr)
    } else {
        0
    }

    (__local_val = ((56 as i32)))

    if ((if not (unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), Some(int_equal), ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (281 as i32), c"list_remove_data(&list, int_equal, &val) == 0".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    (__local_val = ((8 as i32)))

    if ((if not (unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), Some(int_equal), ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 1): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (286 as i32), c"list_remove_data(&list, int_equal, &val) == 1".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_length(__local_list) } == ((__local_num_entries as u32) -% (1 as u32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (287 as i32), c"list_length(list) == num_entries - 1".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    (__local_val = ((4 as i32)))

    if ((if not (unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), Some(int_equal), ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (292 as i32), c"list_remove_data(&list, int_equal, &val) == 4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_length(__local_list) } == ((__local_num_entries as u32) -% (5 as u32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (293 as i32), c"list_length(list) == num_entries - 5".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    (__local_val = ((89 as i32)))

    if ((if not (unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), Some(int_equal), ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 1): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (298 as i32), c"list_remove_data(&list, int_equal, &val) == 1".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_length(__local_list) } == ((__local_num_entries as u32) -% (6 as u32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_remove_data".ptr, c"test-list.c".ptr, (299 as i32), c"list_length(list) == num_entries - 6".ptr)
    } else {
        0
    }

    unsafe { check_list_integrity(__local_list) }

    unsafe { list_free(__local_list) }

}

pub fn test_list_sort() -> Unit writes allocation_limit {
    var __local_list: *mut _ListEntry

    var __local_entries: List[i32] = [89, 4, 23, 42, 4, 16, 15, 4, 8, 99, 50, 30, 4]

    var __local_sorted: List[i32] = [4, 4, 4, 4, 8, 15, 16, 23, 30, 42, 50, 89, 99]

    var __local_num_entries: u32 = (((__local_entries.len() as u64) as u32))

    var __local_i: u32

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as u32)))

    while (__local_i < __local_num_entries) {
        if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), (((&raw const __local_entries[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_sort".ptr, c"test-list.c".ptr, (316 as i32), c"list_prepend(&list, &entries[i]) != NULL".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { list_sort((&raw mut __local_list as *mut *mut _ListEntry), Some(int_compare)) }

    if ((if not (unsafe { list_length(__local_list) } == __local_num_entries): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_sort".ptr, c"test-list.c".ptr, (322 as i32), c"list_length(list) == num_entries".ptr)
    } else {
        0
    }

    (__local_i = ((0 as u32)))

    while (__local_i < __local_num_entries) {
        var __local_value: *mut i32

        (__local_value = ((unsafe { list_nth_data(__local_list, __local_i) } as *mut i32)))

        if ((if not ((unsafe *__local_value) == __local_sorted[__local_i]): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_sort".ptr, c"test-list.c".ptr, (329 as i32), c"*value == sorted[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { list_free(__local_list) }

    (__local_list = ((null as *mut _ListEntry)))

    unsafe { list_sort((&raw mut __local_list as *mut *mut _ListEntry), Some(int_compare)) }

    if ((if not (__local_list == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_sort".ptr, c"test-list.c".ptr, (339 as i32), c"list == NULL".ptr)
    } else {
        0
    }

}

pub fn test_list_find_data() writes allocation_limit {
    var __local_entries: List[i32] = [89, 23, 42, 16, 15, 4, 8, 99, 50, 30]

    var __local_num_entries: i32 = (((__local_entries.len() as u64) as i32))

    var __local_list: *mut _ListEntry

    var __local_result: *mut _ListEntry

    var __local_i: i32

    var __local_val: i32

    var __local_data: *mut i32

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as i32)))

    while (__local_i < __local_num_entries) {
        if ((if not (unsafe { list_append((&raw mut __local_list as *mut *mut _ListEntry), (((&raw const __local_entries[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (355 as i32), c"list_append(&list, &entries[i]) != NULL".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as i32)))

    while (__local_i < __local_num_entries) {
        (__local_val = ((__local_entries[__local_i] as i32)))

        (__local_result = unsafe { list_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) })

        if ((if not (__local_result != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (365 as i32), c"result != NULL".ptr)
        } else {
            0
        }

        (__local_data = ((unsafe { list_data(__local_result) } as *mut i32)))

        if ((if not ((unsafe *__local_data) == __local_val): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (368 as i32), c"*data == val".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_val = ((0 as i32)))

    if ((if not (unsafe { list_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (373 as i32), c"list_find_data(list, int_equal, &val) == NULL".ptr)
    } else {
        0
    }

    (__local_val = ((56 as i32)))

    if ((if not (unsafe { list_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_find_data".ptr, c"test-list.c".ptr, (375 as i32), c"list_find_data(list, int_equal, &val) == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_to_array() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _ListEntry

    var __local_array: *mut *mut c_void

    (__local_list = generate_list())

    (__local_array = unsafe { list_to_array(__local_list) })

    if ((if not ((unsafe __local_array[0]) == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (389 as i32), c"array[0] == &variable1".ptr)
    } else {
        0
    }

    if ((if not ((unsafe __local_array[1]) == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (390 as i32), c"array[1] == &variable2".ptr)
    } else {
        0
    }

    if ((if not ((unsafe __local_array[2]) == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (391 as i32), c"array[2] == &variable3".ptr)
    } else {
        0
    }

    if ((if not ((unsafe __local_array[3]) == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (392 as i32), c"array[3] == &variable4".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_array as *mut c_void)) }

    alloc_test_set_limit((0 as i32))

    (__local_array = unsafe { list_to_array(__local_list) })

    if ((if not (__local_array == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_to_array".ptr, c"test-list.c".ptr, (400 as i32), c"array == NULL".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

}

pub fn test_list_iterate() -> Unit writes allocation_limit {
    var __local_list: *mut _ListEntry

    var __local_iter: _ListIterator

    var __local_i: i32

    var __local_a: i32

    var __local_counter: i32

    var __local_data: *mut i32

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as i32)))

    while (__local_i < 50) {
        if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut __local_a as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (418 as i32), c"list_prepend(&list, &a) != NULL".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_counter = ((0 as i32)))

    unsafe { list_iterate((&raw mut __local_list as *mut *mut _ListEntry), (&raw mut __local_iter as *mut _ListIterator)) }

    unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_remove() }

    while unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_has_more() } {
        (__local_data = ((unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_next() } as *mut i32)))

        if ((if not (__local_data != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (432 as i32), c"data != NULL".ptr)
        } else {
            0
        }

        (__local_counter = __local_counter + 1)

        if ((__local_counter % 2) == 0) {
            unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_remove() }

            unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_remove() }

        }

    }

    if ((if not (unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_next() } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (445 as i32), c"list_iter_next(&iter) == NULL".ptr)
    } else {
        0
    }

    unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_remove() }

    if ((if not (__local_counter == 50): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (450 as i32), c"counter == 50".ptr)
    } else {
        0
    }

    if ((if not (unsafe { list_length(__local_list) } == 25): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (451 as i32), c"list_length(list) == 25".ptr)
    } else {
        0
    }

    unsafe { list_free(__local_list) }

    (__local_list = ((null as *mut _ListEntry)))

    (__local_counter = ((0 as i32)))

    unsafe { list_iterate((&raw mut __local_list as *mut *mut _ListEntry), (&raw mut __local_iter as *mut _ListIterator)) }

    while unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_has_more() } {
        (__local_data = ((unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_next() } as *mut i32)))

        if ((if not (__local_data != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (463 as i32), c"data != NULL".ptr)
        } else {
            0
        }

        (__local_counter = __local_counter + 1)

    }

    if ((if not (__local_counter == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_list_iterate".ptr, c"test-list.c".ptr, (467 as i32), c"counter == 0".ptr)
    } else {
        0
    }

}

pub fn test_list_iterate_bad_remove() writes allocation_limit {
    var __local_list: *mut _ListEntry

    var __local_iter: _ListIterator

    var __local_values: List[i32] = [0; 49]

    var __local_i: i32

    var __local_val: *mut i32

    (__local_list = ((null as *mut _ListEntry)))

    (__local_i = ((0 as i32)))

    while (__local_i < 49) {
        (__local_values[__local_i] = __local_i)

        if ((if not (unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), (((&raw const __local_values[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_list_iterate_bad_remove".ptr, c"test-list.c".ptr, (485 as i32), c"list_prepend(&list, &values[i]) != NULL".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { list_iterate((&raw mut __local_list as *mut *mut _ListEntry), (&raw mut __local_iter as *mut _ListIterator)) }

    while unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_has_more() } {
        (__local_val = ((unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_next() } as *mut i32)))

        if (((unsafe *__local_val) % 2) == 0) {
            if ((if not (unsafe { list_remove_data((&raw mut __local_list as *mut *mut _ListEntry), Some(int_equal), (__local_val as *mut c_void)) } != 0): 1 else: 0) as i64) {
                __assert_rtn(c"test_list_iterate_bad_remove".ptr, c"test-list.c".ptr, (500 as i32), c"list_remove_data(&list, int_equal, val) != 0".ptr)
            } else {
                0
            }

            unsafe { (*(&raw mut __local_iter as *mut _ListIterator)).list_iter_remove() }

        }

    }

    unsafe { list_free(__local_list) }

}

// contract: unproved:1:read only
pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_list_append), Some(test_list_prepend), Some(test_list_free), Some(test_list_next), Some(test_list_nth_entry), Some(test_list_nth_data), Some(test_list_length), Some(test_list_remove_entry), Some(test_list_remove_data), Some(test_list_sort), Some(test_list_find_data), Some(test_list_to_array), Some(test_list_iterate), Some(test_list_iterate_bad_remove), null]
