// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.compare_int
use std.engines.c_algorithms_testing.framework
use std.engines.c_algorithms_testing.slist
use std.libc
use std.option
use std.collections

pub fn generate_list() -> *mut _SListEntry writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _SListEntry = ((null as *mut _SListEntry))

    if ((if not (unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"generate_list".ptr, c"test-slist.c".ptr, (38 as i32), c"slist_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable2 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"generate_list".ptr, c"test-slist.c".ptr, (39 as i32), c"slist_append(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable3 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"generate_list".ptr, c"test-slist.c".ptr, (40 as i32), c"slist_append(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable4 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"generate_list".ptr, c"test-slist.c".ptr, (41 as i32), c"slist_append(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    return __local_list

}

pub fn test_slist_append() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _SListEntry = ((null as *mut _SListEntry))

    if ((if not (unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (50 as i32), c"slist_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable2 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (51 as i32), c"slist_append(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable3 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (52 as i32), c"slist_append(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable4 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (53 as i32), c"slist_append(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (54 as i32), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (0 as u32)) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (56 as i32), c"slist_nth_data(list, 0) == &variable1".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (1 as u32)) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (57 as i32), c"slist_nth_data(list, 1) == &variable2".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (2 as u32)) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (58 as i32), c"slist_nth_data(list, 2) == &variable3".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (3 as u32)) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (59 as i32), c"slist_nth_data(list, 3) == &variable4".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as i32))

    if ((if not (unsafe { slist_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (63 as i32), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (64 as i32), c"slist_append(&list, &variable1) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (65 as i32), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_prepend() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _SListEntry = ((null as *mut _SListEntry))

    if ((if not (unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (74 as i32), c"slist_prepend(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable2 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (75 as i32), c"slist_prepend(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable3 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (76 as i32), c"slist_prepend(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable4 as *mut i32) as *mut c_void)) } != null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (77 as i32), c"slist_prepend(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (0 as u32)) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (79 as i32), c"slist_nth_data(list, 0) == &variable4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (1 as u32)) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (80 as i32), c"slist_nth_data(list, 1) == &variable3".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (2 as u32)) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (81 as i32), c"slist_nth_data(list, 2) == &variable2".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (3 as u32)) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (82 as i32), c"slist_nth_data(list, 3) == &variable1".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as i32))

    if ((if not (unsafe { slist_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (86 as i32), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (87 as i32), c"slist_prepend(&list, &variable1) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (88 as i32), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_free() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _SListEntry

    (__local_list = generate_list())

    unsafe { slist_free(__local_list) }

    unsafe { slist_free((null as *mut _SListEntry)) }

}

pub fn test_slist_next() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _SListEntry

    var __local_rover: *mut _SListEntry

    (__local_list = generate_list())

    (__local_rover = __local_list)

    if ((if not (unsafe { slist_data(__local_rover) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (114 as i32), c"slist_data(rover) == &variable1".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { slist_next(__local_rover) })

    if ((if not (unsafe { slist_data(__local_rover) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (116 as i32), c"slist_data(rover) == &variable2".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { slist_next(__local_rover) })

    if ((if not (unsafe { slist_data(__local_rover) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (118 as i32), c"slist_data(rover) == &variable3".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { slist_next(__local_rover) })

    if ((if not (unsafe { slist_data(__local_rover) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (120 as i32), c"slist_data(rover) == &variable4".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { slist_next(__local_rover) })

    if ((if not (__local_rover == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (122 as i32), c"rover == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_nth_entry() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _SListEntry

    var __local_entry: *mut _SListEntry

    (__local_list = generate_list())

    (__local_entry = unsafe { slist_nth_entry(__local_list, (0 as u32)) })

    if ((if not (unsafe { slist_data(__local_entry) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (136 as i32), c"slist_data(entry) == &variable1".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (1 as u32)) })

    if ((if not (unsafe { slist_data(__local_entry) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (138 as i32), c"slist_data(entry) == &variable2".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (2 as u32)) })

    if ((if not (unsafe { slist_data(__local_entry) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (140 as i32), c"slist_data(entry) == &variable3".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (3 as u32)) })

    if ((if not (unsafe { slist_data(__local_entry) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (142 as i32), c"slist_data(entry) == &variable4".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (4 as u32)) })

    if ((if not (__local_entry == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (146 as i32), c"entry == NULL".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (400 as u32)) })

    if ((if not (__local_entry == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (148 as i32), c"entry == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_nth_data() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _SListEntry

    (__local_list = generate_list())

    if ((if not (unsafe { slist_nth_data(__local_list, (0 as u32)) } == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (160 as i32), c"slist_nth_data(list, 0) == &variable1".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (1 as u32)) } == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (161 as i32), c"slist_nth_data(list, 1) == &variable2".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (2 as u32)) } == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (162 as i32), c"slist_nth_data(list, 2) == &variable3".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (3 as u32)) } == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (163 as i32), c"slist_nth_data(list, 3) == &variable4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (4 as u32)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (166 as i32), c"slist_nth_data(list, 4) == NULL".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_nth_data(__local_list, (400 as u32)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (167 as i32), c"slist_nth_data(list, 400) == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_length() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _SListEntry

    (__local_list = generate_list())

    if ((if not (unsafe { slist_length(__local_list) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_length".ptr, c"test-slist.c".ptr, (179 as i32), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut i32) as *mut c_void)) }

    if ((if not (unsafe { slist_length(__local_list) } == 5): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_length".ptr, c"test-slist.c".ptr, (184 as i32), c"slist_length(list) == 5".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length((null as *mut _SListEntry)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_length".ptr, c"test-slist.c".ptr, (187 as i32), c"slist_length(NULL) == 0".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_remove_entry() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_empty_list: *mut _SListEntry = ((null as *mut _SListEntry))

    var __local_list: *mut _SListEntry

    var __local_entry: *mut _SListEntry

    (__local_list = generate_list())

    (__local_entry = unsafe { slist_nth_entry(__local_list, (2 as u32)) })

    if ((if not (unsafe { slist_remove_entry((&raw mut __local_list as *mut *mut _SListEntry), __local_entry) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (202 as i32), c"slist_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length(__local_list) } == 3): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (203 as i32), c"slist_length(list) == 3".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (0 as u32)) })

    if ((if not (unsafe { slist_remove_entry((&raw mut __local_list as *mut *mut _SListEntry), __local_entry) } != 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (207 as i32), c"slist_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length(__local_list) } == 2): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (208 as i32), c"slist_length(list) == 2".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_remove_entry((&raw mut __local_list as *mut *mut _SListEntry), __local_entry) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (212 as i32), c"slist_remove_entry(&list, entry) == 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_remove_entry((&raw mut __local_list as *mut *mut _SListEntry), (null as *mut _SListEntry)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (215 as i32), c"slist_remove_entry(&list, NULL) == 0".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_remove_entry((&raw mut __local_empty_list as *mut *mut _SListEntry), (null as *mut _SListEntry)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (218 as i32), c"slist_remove_entry(&empty_list, NULL) == 0".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_remove_data() writes allocation_limit {
    var __local_entries: List[i32] = [89, 4, 23, 42, 4, 16, 15, 4, 8, 99, 50, 30, 4]

    var __local_num_entries: u32 = (((__local_entries.len() as u64) as u32))

    var __local_val: i32

    var __local_list: *mut _SListEntry

    var __local_i: u32

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as u32)))

    while (__local_i < __local_num_entries) {
        unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), (((&raw const __local_entries[__local_i] as *const i32) as *mut i32) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    (__local_val = ((0 as i32)))

    if ((if not (unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (240 as i32), c"slist_remove_data(&list, int_equal, &val) == 0".ptr)
    } else {
        0
    }

    (__local_val = ((56 as i32)))

    if ((if not (unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (242 as i32), c"slist_remove_data(&list, int_equal, &val) == 0".ptr)
    } else {
        0
    }

    (__local_val = ((8 as i32)))

    if ((if not (unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 1): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (246 as i32), c"slist_remove_data(&list, int_equal, &val) == 1".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length(__local_list) } == ((__local_num_entries as u32) -% (1 as u32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (247 as i32), c"slist_length(list) == num_entries - 1".ptr)
    } else {
        0
    }

    (__local_val = ((4 as i32)))

    if ((if not (unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 4): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (251 as i32), c"slist_remove_data(&list, int_equal, &val) == 4".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length(__local_list) } == ((__local_num_entries as u32) -% (5 as u32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (252 as i32), c"slist_length(list) == num_entries - 5".ptr)
    } else {
        0
    }

    (__local_val = ((89 as i32)))

    if ((if not (unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) } == 1): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (256 as i32), c"slist_remove_data(&list, int_equal, &val) == 1".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length(__local_list) } == ((__local_num_entries as u32) -% (6 as u32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (257 as i32), c"slist_length(list) == num_entries - 6".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_sort() -> Unit writes allocation_limit {
    var __local_list: *mut _SListEntry

    var __local_entries: List[i32] = [89, 4, 23, 42, 4, 16, 15, 4, 8, 99, 50, 30, 4]

    var __local_sorted: List[i32] = [4, 4, 4, 4, 8, 15, 16, 23, 30, 42, 50, 89, 99]

    var __local_num_entries: u32 = (((__local_entries.len() as u64) as u32))

    var __local_i: u32

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as u32)))

    while (__local_i < __local_num_entries) {
        unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), (((&raw const __local_entries[__local_i] as *const i32) as *mut i32) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { slist_sort((&raw mut __local_list as *mut *mut _SListEntry), int_compare) }

    if ((if not (unsafe { slist_length(__local_list) } == __local_num_entries): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_sort".ptr, c"test-slist.c".ptr, (279 as i32), c"slist_length(list) == num_entries".ptr)
    } else {
        0
    }

    (__local_i = ((0 as u32)))

    while (__local_i < __local_num_entries) {
        var __local_value: *mut i32

        (__local_value = ((unsafe { slist_nth_data(__local_list, __local_i) } as *mut i32)))

        if ((if not ((unsafe *__local_value) == __local_sorted[__local_i]): 1 else: 0) as i64) {
            __assert_rtn(c"test_slist_sort".ptr, c"test-slist.c".ptr, (286 as i32), c"*value == sorted[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { slist_free(__local_list) }

    (__local_list = ((null as *mut _SListEntry)))

    unsafe { slist_sort((&raw mut __local_list as *mut *mut _SListEntry), int_compare) }

    if ((if not (__local_list == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_sort".ptr, c"test-slist.c".ptr, (296 as i32), c"list == NULL".ptr)
    } else {
        0
    }

}

pub fn test_slist_find_data() writes allocation_limit {
    var __local_entries: List[i32] = [89, 23, 42, 16, 15, 4, 8, 99, 50, 30]

    var __local_num_entries: i32 = (((__local_entries.len() as u64) as i32))

    var __local_list: *mut _SListEntry

    var __local_result: *mut _SListEntry

    var __local_i: i32

    var __local_val: i32

    var __local_data: *mut i32

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as i32)))

    while (__local_i < __local_num_entries) {
        unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), (((&raw const __local_entries[__local_i] as *const i32) as *mut i32) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as i32)))

    while (__local_i < __local_num_entries) {
        (__local_val = ((__local_entries[__local_i] as i32)))

        (__local_result = unsafe { slist_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) })

        if ((if not (__local_result != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_slist_find_data".ptr, c"test-slist.c".ptr, (322 as i32), c"result != NULL".ptr)
        } else {
            0
        }

        (__local_data = ((unsafe { slist_data(__local_result) } as *mut i32)))

        if ((if not ((unsafe *__local_data) == __local_val): 1 else: 0) as i64) {
            __assert_rtn(c"test_slist_find_data".ptr, c"test-slist.c".ptr, (325 as i32), c"*data == val".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_val = ((0 as i32)))

    if ((if not (unsafe { slist_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_find_data".ptr, c"test-slist.c".ptr, (330 as i32), c"slist_find_data(list, int_equal, &val) == NULL".ptr)
    } else {
        0
    }

    (__local_val = ((56 as i32)))

    if ((if not (unsafe { slist_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut i32) as *mut c_void)) } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_find_data".ptr, c"test-slist.c".ptr, (332 as i32), c"slist_find_data(list, int_equal, &val) == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_to_array() writes allocation_limit, variable1, variable2, variable3, variable4 {
    var __local_list: *mut _SListEntry

    var __local_array: *mut *mut c_void

    (__local_list = generate_list())

    (__local_array = unsafe { slist_to_array(__local_list) })

    if ((if not ((unsafe __local_array[0]) == ((&raw mut variable1 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (346 as i32), c"array[0] == &variable1".ptr)
    } else {
        0
    }

    if ((if not ((unsafe __local_array[1]) == ((&raw mut variable2 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (347 as i32), c"array[1] == &variable2".ptr)
    } else {
        0
    }

    if ((if not ((unsafe __local_array[2]) == ((&raw mut variable3 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (348 as i32), c"array[2] == &variable3".ptr)
    } else {
        0
    }

    if ((if not ((unsafe __local_array[3]) == ((&raw mut variable4 as *mut i32))): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (349 as i32), c"array[3] == &variable4".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_array as *mut c_void)) }

    alloc_test_set_limit((0 as i32))

    (__local_array = unsafe { slist_to_array(__local_list) })

    if ((if not (__local_array == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (357 as i32), c"array == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_iterate() -> Unit writes allocation_limit {
    var __local_list: *mut _SListEntry

    var __local_iter: _SListIterator

    var __local_data: *mut i32

    var __local_a: i32

    var __local_i: i32

    var __local_counter: i32

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as i32)))

    while (__local_i < 50) {
        unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut __local_a as *mut i32) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_counter = ((0 as i32)))

    unsafe { slist_iterate((&raw mut __local_list as *mut *mut _SListEntry), (&raw mut __local_iter as *mut _SListIterator)) }

    unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_remove() }

    while unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_has_more() } {
        (__local_data = ((unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_next() } as *mut i32)))

        if ((if not (__local_data != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (390 as i32), c"data != NULL".ptr)
        } else {
            0
        }

        (__local_counter = __local_counter + 1)

        if ((__local_counter % 2) == 0) {
            unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_remove() }

            unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_remove() }

        }

    }

    if ((if not (unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_next() } == null): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (404 as i32), c"slist_iter_next(&iter) == SLIST_NULL".ptr)
    } else {
        0
    }

    unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_remove() }

    if ((if not (__local_counter == 50): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (409 as i32), c"counter == 50".ptr)
    } else {
        0
    }

    if ((if not (unsafe { slist_length(__local_list) } == 25): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (410 as i32), c"slist_length(list) == 25".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

    (__local_list = ((null as *mut _SListEntry)))

    (__local_counter = ((0 as i32)))

    unsafe { slist_iterate((&raw mut __local_list as *mut *mut _SListEntry), (&raw mut __local_iter as *mut _SListIterator)) }

    while unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_has_more() } {
        (__local_data = ((unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_next() } as *mut i32)))

        if ((if not (__local_data != null): 1 else: 0) as i64) {
            __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (423 as i32), c"data != NULL".ptr)
        } else {
            0
        }

        (__local_counter = __local_counter + 1)

        if ((__local_counter % 2) == 0) {
            unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_remove() }

        }

    }

    if ((if not (__local_counter == 0): 1 else: 0) as i64) {
        __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (433 as i32), c"counter == 0".ptr)
    } else {
        0
    }

}

pub fn test_slist_iterate_bad_remove() writes allocation_limit {
    var __local_list: *mut _SListEntry

    var __local_iter: _SListIterator

    var __local_values: List[i32] = [0; 49]

    var __local_i: i32

    var __local_val: *mut i32

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as i32)))

    while (__local_i < 49) {
        (__local_values[__local_i] = __local_i)

        unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), (((&raw const __local_values[__local_i] as *const i32) as *mut i32) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    unsafe { slist_iterate((&raw mut __local_list as *mut *mut _SListEntry), (&raw mut __local_iter as *mut _SListIterator)) }

    while unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_has_more() } {
        (__local_val = ((unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_next() } as *mut i32)))

        if (((unsafe *__local_val) % 2) == 0) {
            if ((if not (unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, (__local_val as *mut c_void)) } != 0): 1 else: 0) as i64) {
                __assert_rtn(c"test_slist_iterate_bad_remove".ptr, c"test-slist.c".ptr, (466 as i32), c"slist_remove_data(&list, int_equal, val) != 0".ptr)
            } else {
                0
            }

            unsafe { (*(&raw mut __local_iter as *mut _SListIterator)).slist_iter_remove() }

        }

    }

    unsafe { slist_free(__local_list) }

}

// contract: unproved:1:read only
pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_slist_append), Some(test_slist_prepend), Some(test_slist_free), Some(test_slist_next), Some(test_slist_nth_entry), Some(test_slist_nth_data), Some(test_slist_length), Some(test_slist_remove_entry), Some(test_slist_remove_data), Some(test_slist_sort), Some(test_slist_find_data), Some(test_slist_to_array), Some(test_slist_iterate), Some(test_slist_iterate_bad_remove), null]
