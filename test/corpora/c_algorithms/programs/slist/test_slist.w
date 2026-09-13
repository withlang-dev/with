// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.compare_int
use std.calg_testing.framework
use std.calg_testing.slist
use std.libc

pub fn generate_list() -> *mut _SListEntry {
    var __local_list: *mut _SListEntry = ((null as *mut _SListEntry))

    if ((((if not ((if unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_list".ptr, c"test-slist.c".ptr, (38 as c_int), c"slist_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable2 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_list".ptr, c"test-slist.c".ptr, (39 as c_int), c"slist_append(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable3 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_list".ptr, c"test-slist.c".ptr, (40 as c_int), c"slist_append(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_list".ptr, c"test-slist.c".ptr, (41 as c_int), c"slist_append(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    return __local_list

}

pub fn test_slist_append() -> Unit {
    var __local_list: *mut _SListEntry = ((null as *mut _SListEntry))

    if ((((if not ((if unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (50 as c_int), c"slist_append(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable2 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (51 as c_int), c"slist_append(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable3 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (52 as c_int), c"slist_append(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (53 as c_int), c"slist_append(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (54 as c_int), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (0 as c_uint)) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (56 as c_int), c"slist_nth_data(list, 0) == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (1 as c_uint)) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (57 as c_int), c"slist_nth_data(list, 1) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (2 as c_uint)) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (58 as c_int), c"slist_nth_data(list, 2) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (3 as c_uint)) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (59 as c_int), c"slist_nth_data(list, 3) == &variable4".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if unsafe { slist_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (63 as c_int), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (64 as c_int), c"slist_append(&list, &variable1) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_append".ptr, c"test-slist.c".ptr, (65 as c_int), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_prepend() -> Unit {
    var __local_list: *mut _SListEntry = ((null as *mut _SListEntry))

    if ((((if not ((if unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (74 as c_int), c"slist_prepend(&list, &variable1) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable2 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (75 as c_int), c"slist_prepend(&list, &variable2) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable3 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (76 as c_int), c"slist_prepend(&list, &variable3) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (77 as c_int), c"slist_prepend(&list, &variable4) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (0 as c_uint)) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (79 as c_int), c"slist_nth_data(list, 0) == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (1 as c_uint)) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (80 as c_int), c"slist_nth_data(list, 1) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (2 as c_uint)) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (81 as c_int), c"slist_nth_data(list, 2) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (3 as c_uint)) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (82 as c_int), c"slist_nth_data(list, 3) == &variable1".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if unsafe { slist_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (86 as c_int), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (87 as c_int), c"slist_prepend(&list, &variable1) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_prepend".ptr, c"test-slist.c".ptr, (88 as c_int), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_free() -> Unit {
    var __local_list: *mut _SListEntry

    (__local_list = generate_list())

    unsafe { slist_free(__local_list) }

    unsafe { slist_free((null as *mut _SListEntry)) }

}

pub fn test_slist_next() -> Unit {
    var __local_list: *mut _SListEntry

    var __local_rover: *mut _SListEntry

    (__local_list = generate_list())

    (__local_rover = __local_list)

    if ((((if not ((if unsafe { slist_data(__local_rover) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (114 as c_int), c"slist_data(rover) == &variable1".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { slist_next(__local_rover) })

    if ((((if not ((if unsafe { slist_data(__local_rover) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (116 as c_int), c"slist_data(rover) == &variable2".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { slist_next(__local_rover) })

    if ((((if not ((if unsafe { slist_data(__local_rover) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (118 as c_int), c"slist_data(rover) == &variable3".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { slist_next(__local_rover) })

    if ((((if not ((if unsafe { slist_data(__local_rover) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (120 as c_int), c"slist_data(rover) == &variable4".ptr)
    } else {
        0
    }

    (__local_rover = unsafe { slist_next(__local_rover) })

    if ((((if not ((if __local_rover == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_next".ptr, c"test-slist.c".ptr, (122 as c_int), c"rover == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_nth_entry() -> Unit {
    var __local_list: *mut _SListEntry

    var __local_entry: *mut _SListEntry

    (__local_list = generate_list())

    (__local_entry = unsafe { slist_nth_entry(__local_list, (0 as c_uint)) })

    if ((((if not ((if unsafe { slist_data(__local_entry) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (136 as c_int), c"slist_data(entry) == &variable1".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (1 as c_uint)) })

    if ((((if not ((if unsafe { slist_data(__local_entry) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (138 as c_int), c"slist_data(entry) == &variable2".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (2 as c_uint)) })

    if ((((if not ((if unsafe { slist_data(__local_entry) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (140 as c_int), c"slist_data(entry) == &variable3".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (3 as c_uint)) })

    if ((((if not ((if unsafe { slist_data(__local_entry) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (142 as c_int), c"slist_data(entry) == &variable4".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (4 as c_uint)) })

    if ((((if not ((if __local_entry == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (146 as c_int), c"entry == NULL".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (400 as c_uint)) })

    if ((((if not ((if __local_entry == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_entry".ptr, c"test-slist.c".ptr, (148 as c_int), c"entry == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_nth_data() -> Unit {
    var __local_list: *mut _SListEntry

    (__local_list = generate_list())

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (0 as c_uint)) } == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (160 as c_int), c"slist_nth_data(list, 0) == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (1 as c_uint)) } == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (161 as c_int), c"slist_nth_data(list, 1) == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (2 as c_uint)) } == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (162 as c_int), c"slist_nth_data(list, 2) == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (3 as c_uint)) } == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (163 as c_int), c"slist_nth_data(list, 3) == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (4 as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (166 as c_int), c"slist_nth_data(list, 4) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_nth_data(__local_list, (400 as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_nth_data".ptr, c"test-slist.c".ptr, (167 as c_int), c"slist_nth_data(list, 400) == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_length() -> Unit {
    var __local_list: *mut _SListEntry

    (__local_list = generate_list())

    if ((((if not ((if unsafe { slist_length(__local_list) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_length".ptr, c"test-slist.c".ptr, (179 as c_int), c"slist_length(list) == 4".ptr)
    } else {
        0
    }

    unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut variable1 as *mut c_int) as *mut c_void)) }

    if ((((if not ((if unsafe { slist_length(__local_list) } == 5: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_length".ptr, c"test-slist.c".ptr, (184 as c_int), c"slist_length(list) == 5".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length((null as *mut _SListEntry)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_length".ptr, c"test-slist.c".ptr, (187 as c_int), c"slist_length(NULL) == 0".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_remove_entry() -> Unit {
    var __local_empty_list: *mut _SListEntry = ((null as *mut _SListEntry))

    var __local_list: *mut _SListEntry

    var __local_entry: *mut _SListEntry

    (__local_list = generate_list())

    (__local_entry = unsafe { slist_nth_entry(__local_list, (2 as c_uint)) })

    if ((((if not ((if unsafe { slist_remove_entry((&raw mut __local_list as *mut *mut _SListEntry), __local_entry) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (202 as c_int), c"slist_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length(__local_list) } == 3: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (203 as c_int), c"slist_length(list) == 3".ptr)
    } else {
        0
    }

    (__local_entry = unsafe { slist_nth_entry(__local_list, (0 as c_uint)) })

    if ((((if not ((if unsafe { slist_remove_entry((&raw mut __local_list as *mut *mut _SListEntry), __local_entry) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (207 as c_int), c"slist_remove_entry(&list, entry) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length(__local_list) } == 2: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (208 as c_int), c"slist_length(list) == 2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_remove_entry((&raw mut __local_list as *mut *mut _SListEntry), __local_entry) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (212 as c_int), c"slist_remove_entry(&list, entry) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_remove_entry((&raw mut __local_list as *mut *mut _SListEntry), (null as *mut _SListEntry)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (215 as c_int), c"slist_remove_entry(&list, NULL) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_remove_entry((&raw mut __local_empty_list as *mut *mut _SListEntry), (null as *mut _SListEntry)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_entry".ptr, c"test-slist.c".ptr, (218 as c_int), c"slist_remove_entry(&empty_list, NULL) == 0".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_remove_data() -> Unit {
    var __local_entries: [13]c_int = [(89 as c_int), (4 as c_int), (23 as c_int), (42 as c_int), (4 as c_int), (16 as c_int), (15 as c_int), (4 as c_int), (8 as c_int), (99 as c_int), (50 as c_int), (30 as c_int), (4 as c_int)]

    var __local_num_entries: c_uint = ((13 as c_uint))

    var __local_val: c_int

    var __local_list: *mut _SListEntry

    var __local_i: c_uint

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), (((&raw const __local_entries[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    (__local_val = ((0 as c_int)))

    if ((((if not ((if unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (240 as c_int), c"slist_remove_data(&list, int_equal, &val) == 0".ptr)
    } else {
        0
    }

    (__local_val = ((56 as c_int)))

    if ((((if not ((if unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (242 as c_int), c"slist_remove_data(&list, int_equal, &val) == 0".ptr)
    } else {
        0
    }

    (__local_val = ((8 as c_int)))

    if ((((if not ((if unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (246 as c_int), c"slist_remove_data(&list, int_equal, &val) == 1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length(__local_list) } == ((__local_num_entries as c_uint) -% (1 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (247 as c_int), c"slist_length(list) == num_entries - 1".ptr)
    } else {
        0
    }

    (__local_val = ((4 as c_int)))

    if ((((if not ((if unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (251 as c_int), c"slist_remove_data(&list, int_equal, &val) == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length(__local_list) } == ((__local_num_entries as c_uint) -% (5 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (252 as c_int), c"slist_length(list) == num_entries - 5".ptr)
    } else {
        0
    }

    (__local_val = ((89 as c_int)))

    if ((((if not ((if unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (256 as c_int), c"slist_remove_data(&list, int_equal, &val) == 1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length(__local_list) } == ((__local_num_entries as c_uint) -% (6 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_remove_data".ptr, c"test-slist.c".ptr, (257 as c_int), c"slist_length(list) == num_entries - 6".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_sort() -> Unit {
    var __local_list: *mut _SListEntry

    var __local_entries: [13]c_int = [(89 as c_int), (4 as c_int), (23 as c_int), (42 as c_int), (4 as c_int), (16 as c_int), (15 as c_int), (4 as c_int), (8 as c_int), (99 as c_int), (50 as c_int), (30 as c_int), (4 as c_int)]

    var __local_sorted: [13]c_int = [(4 as c_int), (4 as c_int), (4 as c_int), (4 as c_int), (8 as c_int), (15 as c_int), (16 as c_int), (23 as c_int), (30 as c_int), (42 as c_int), (50 as c_int), (89 as c_int), (99 as c_int)]

    var __local_num_entries: c_uint = ((13 as c_uint))

    var __local_i: c_uint

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), (((&raw const __local_entries[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { slist_sort((&raw mut __local_list as *mut *mut _SListEntry), int_compare) }

    if ((((if not ((if unsafe { slist_length(__local_list) } == __local_num_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_sort".ptr, c"test-slist.c".ptr, (279 as c_int), c"slist_length(list) == num_entries".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        var __local_value: *mut c_int

        (__local_value = ((unsafe { slist_nth_data(__local_list, __local_i) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_value) == __local_sorted[__local_i]: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_slist_sort".ptr, c"test-slist.c".ptr, (286 as c_int), c"*value == sorted[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { slist_free(__local_list) }

    (__local_list = ((null as *mut _SListEntry)))

    unsafe { slist_sort((&raw mut __local_list as *mut *mut _SListEntry), int_compare) }

    if ((((if not ((if __local_list == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_sort".ptr, c"test-slist.c".ptr, (296 as c_int), c"list == NULL".ptr)
    } else {
        0
    }

}

pub fn test_slist_find_data() -> Unit {
    var __local_entries: [10]c_int = [(89 as c_int), (23 as c_int), (42 as c_int), (16 as c_int), (15 as c_int), (4 as c_int), (8 as c_int), (99 as c_int), (50 as c_int), (30 as c_int)]

    var __local_num_entries: c_int = ((10 as c_int))

    var __local_list: *mut _SListEntry

    var __local_result: *mut _SListEntry

    var __local_i: c_int

    var __local_val: c_int

    var __local_data: *mut c_int

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        unsafe { slist_append((&raw mut __local_list as *mut *mut _SListEntry), (((&raw const __local_entries[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as c_int)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        (__local_val = ((__local_entries[__local_i] as c_int)))

        (__local_result = unsafe { slist_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) })

        if ((((if not ((if __local_result != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_slist_find_data".ptr, c"test-slist.c".ptr, (322 as c_int), c"result != NULL".ptr)
        } else {
            0
        }

        (__local_data = ((unsafe { slist_data(__local_result) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_data) == __local_val: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_slist_find_data".ptr, c"test-slist.c".ptr, (325 as c_int), c"*data == val".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_val = ((0 as c_int)))

    if ((((if not ((if unsafe { slist_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_find_data".ptr, c"test-slist.c".ptr, (330 as c_int), c"slist_find_data(list, int_equal, &val) == NULL".ptr)
    } else {
        0
    }

    (__local_val = ((56 as c_int)))

    if ((((if not ((if unsafe { slist_find_data(__local_list, int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_find_data".ptr, c"test-slist.c".ptr, (332 as c_int), c"slist_find_data(list, int_equal, &val) == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_to_array() -> Unit {
    var __local_list: *mut _SListEntry

    var __local_array: *mut *mut c_void

    (__local_list = generate_list())

    (__local_array = unsafe { slist_to_array(__local_list) })

    if ((((if not ((if (unsafe __local_array[0]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (346 as c_int), c"array[0] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe __local_array[1]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (347 as c_int), c"array[1] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe __local_array[2]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (348 as c_int), c"array[2] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe __local_array[3]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (349 as c_int), c"array[3] == &variable4".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_array as *mut c_void)) }

    alloc_test_set_limit((0 as c_int))

    (__local_array = unsafe { slist_to_array(__local_list) })

    if ((((if not ((if __local_array == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_to_array".ptr, c"test-slist.c".ptr, (357 as c_int), c"array == NULL".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

}

pub fn test_slist_iterate() -> Unit {
    var __local_list: *mut _SListEntry

    var __local_iter: _SListIterator

    var __local_data: *mut c_int

    var __local_a: c_int

    var __local_i: c_int

    var __local_counter: c_int

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 50: 1 else: 0) != 0) {
        unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut __local_a as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_counter = ((0 as c_int)))

    unsafe { slist_iterate((&raw mut __local_list as *mut *mut _SListEntry), (&raw mut __local_iter as *mut _SListIterator)) }

    unsafe { slist_iter_remove((&raw mut __local_iter as *mut _SListIterator)) }

    while (unsafe { slist_iter_has_more((&raw mut __local_iter as *mut _SListIterator)) } != 0) {
        (__local_data = ((unsafe { slist_iter_next((&raw mut __local_iter as *mut _SListIterator)) } as *mut c_int)))

        if ((((if not ((if __local_data != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (390 as c_int), c"data != NULL".ptr)
        } else {
            0
        }

        (__local_counter = __local_counter + 1)

        if ((if (__local_counter % 2) == 0: 1 else: 0) != 0) {
            unsafe { slist_iter_remove((&raw mut __local_iter as *mut _SListIterator)) }

            unsafe { slist_iter_remove((&raw mut __local_iter as *mut _SListIterator)) }

        }

    }

    if ((((if not ((if unsafe { slist_iter_next((&raw mut __local_iter as *mut _SListIterator)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (404 as c_int), c"slist_iter_next(&iter) == SLIST_NULL".ptr)
    } else {
        0
    }

    unsafe { slist_iter_remove((&raw mut __local_iter as *mut _SListIterator)) }

    if ((((if not ((if __local_counter == 50: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (409 as c_int), c"counter == 50".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { slist_length(__local_list) } == 25: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (410 as c_int), c"slist_length(list) == 25".ptr)
    } else {
        0
    }

    unsafe { slist_free(__local_list) }

    (__local_list = ((null as *mut _SListEntry)))

    (__local_counter = ((0 as c_int)))

    unsafe { slist_iterate((&raw mut __local_list as *mut *mut _SListEntry), (&raw mut __local_iter as *mut _SListIterator)) }

    while (unsafe { slist_iter_has_more((&raw mut __local_iter as *mut _SListIterator)) } != 0) {
        (__local_data = ((unsafe { slist_iter_next((&raw mut __local_iter as *mut _SListIterator)) } as *mut c_int)))

        if ((((if not ((if __local_data != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (423 as c_int), c"data != NULL".ptr)
        } else {
            0
        }

        (__local_counter = __local_counter + 1)

        if ((if (__local_counter % 2) == 0: 1 else: 0) != 0) {
            unsafe { slist_iter_remove((&raw mut __local_iter as *mut _SListIterator)) }

        }

    }

    if ((((if not ((if __local_counter == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_slist_iterate".ptr, c"test-slist.c".ptr, (433 as c_int), c"counter == 0".ptr)
    } else {
        0
    }

}

pub fn test_slist_iterate_bad_remove() -> Unit {
    var __local_list: *mut _SListEntry

    var __local_iter: _SListIterator

    var __local_values: [49]c_int

    var __local_i: c_int

    var __local_val: *mut c_int

    (__local_list = ((null as *mut _SListEntry)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 49: 1 else: 0) != 0) {
        (__local_values[__local_i] = __local_i)

        unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    unsafe { slist_iterate((&raw mut __local_list as *mut *mut _SListEntry), (&raw mut __local_iter as *mut _SListIterator)) }

    while (unsafe { slist_iter_has_more((&raw mut __local_iter as *mut _SListIterator)) } != 0) {
        (__local_val = ((unsafe { slist_iter_next((&raw mut __local_iter as *mut _SListIterator)) } as *mut c_int)))

        if ((if ((unsafe *__local_val) % 2) == 0: 1 else: 0) != 0) {
            if ((((if not ((if unsafe { slist_remove_data((&raw mut __local_list as *mut *mut _SListEntry), int_equal, (__local_val as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
                __assert_rtn(c"test_slist_iterate_bad_remove".ptr, c"test-slist.c".ptr, (466 as c_int), c"slist_remove_data(&list, int_equal, val) != 0".ptr)
            } else {
                0
            }

            unsafe { slist_iter_remove((&raw mut __local_iter as *mut _SListIterator)) }

        }

    }

    unsafe { slist_free(__local_list) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [15]extern "C" fn() -> Unit = [test_slist_append, test_slist_prepend, test_slist_free, test_slist_next, test_slist_nth_entry, test_slist_nth_data, test_slist_length, test_slist_remove_entry, test_slist_remove_data, test_slist_sort, test_slist_find_data, test_slist_to_array, test_slist_iterate, test_slist_iterate_bad_remove, null]
