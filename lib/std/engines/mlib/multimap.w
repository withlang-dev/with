// Migrated from C
use std.engines.mlib.defs
use std.libc

fn multimap_new_node() -> *mut multimap_node_s {
    var __local_n: *mut multimap_node_s = (((with_alloc(((sizeof[multimap_node_s]() as c_ulong) as i64)) as *mut c_void) as *mut multimap_node_s))

    if (((if not ((if not ((if __local_n == null: 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        abort()

    }

    ((unsafe *__local_n).next = ((null as *mut multimap_node_s)))

    ((unsafe *__local_n).prev = ((null as *mut multimap_node_s)))

    ((unsafe *__local_n).num = ((0 as c_int)))

    return __local_n

}

unsafe fn multimap_init(__param_b: *mut multimap_s) {
    ((__param_b[0]).root = multimap_new_node())

    ((__param_b[0]).size = ((0 as c_ulong)))

    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

}

unsafe fn multimap_is_leaf(__param_n: *mut multimap_node_s) -> bool {
    return (((((*__param_n).num <= 0)) as bool))

}

unsafe fn multimap_get_num(__param_n: *mut multimap_node_s) -> c_int {
    var __local_num: c_int = (*__param_n).num

    (__local_num = (((if (if __local_num < 0: 1 else: 0) != 0: ((0 - __local_num) as c_int) else: __local_num) as c_int)))

    if (((if not ((if __local_num <= 5: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_get_num".ptr, c"multimap.c".ptr, (5 as c_int), c"num <= 5".ptr)
    } else {
        0
    }

    return __local_num

}

unsafe fn multimap_reset(__param_b: *mut multimap_s) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    var __local_next: *mut multimap_node_s

    var __local_n: *mut multimap_node_s = (*(&raw const (__param_b[0]) as *const multimap_s)).root


    var __local_pit: [multimap_parent_it_s; 1]

    var __local_np: c_int = ((0 as c_int))

    while ((if not multimap_is_leaf(__local_n): 1 else: 0) != 0) {
        var __ci_expr_old_2: c_int = __local_np

        (__local_np = __local_np + 1)

        (__local_pit[0].parent[__ci_expr_old_2] = __local_n)


        if (((if not ((if __local_np <= ((((1 as c_ulong) +% (((8 as c_ulong) *% (sizeof[c_ulong]() as c_ulong)) as c_ulong)) as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"np <= ((int)(1 + 8*sizeof (size_t)))".ptr)
        } else {
            0
        }

        (__local_n = (*(&raw const (*__local_n).kind as *const multimap_kind_s)).node[0])

    }

    var __ci_expr_old_3: c_int = __local_np

    (__local_np = __local_np + 1)

    (__local_pit[0].parent[__ci_expr_old_3] = __local_n)


    if (((if not ((if __local_np <= ((((1 as c_ulong) +% (((8 as c_ulong) *% (sizeof[c_ulong]() as c_ulong)) as c_ulong)) as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"np <= ((int)(1 + 8*sizeof (size_t)))".ptr)
    } else {
        0
    }

    var __local_i: c_int = ((0 as c_int))

    while ((if __local_i < __local_np: 1 else: 0) != 0) {
        (__local_n = (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).parent[__local_i])

        while ((if __local_n != null: 1 else: 0) != 0) {
            var __local_num: c_int = ((multimap_get_num(__local_n) as c_int))

            var __local_is_leaf: bool = multimap_is_leaf(__local_n)

            var __local_j: c_int = ((0 as c_int))

            while ((if __local_j < __local_num: 1 else: 0) != 0) {

                if __local_is_leaf {

                }


                (__local_j = __local_j + 1)

            }


            (__local_next = (*__local_n).next)

            if ((if __local_i != 0: 1 else: 0) != 0) {
                with_free(((__local_n as *mut c_void) as *mut u8))

            }

            (__local_n = __local_next)

        }


        (__local_i = __local_i + 1)

    }


    ((*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num = ((0 as c_int)))

    ((__param_b[0]).size = ((0 as c_ulong)))

    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if (if __local_num2_1 < 0: 1 else: 0) != 0: ((0 - __local_num2_1) as c_int) else: __local_num2_1) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_4: c_int = 0

                if ((if 0 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_4 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_1 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_1: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_5: c_int = 0

                if ((if __local_c2_1 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_5 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: c_int = ((1 as c_int))

            while ((if __local_i2_1 < __local_num2_1: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_1 = (((if (if __local_num_prev_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_1) as c_int) else: __local_num_prev_1) as c_int)))

                if (((if not ((if __local_num_prev_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_reset".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

}

unsafe fn multimap_clear(__param_b: *mut multimap_s) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_clear".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    multimap_reset((&(__param_b[0]) as *mut multimap_s))

    with_free((((*(&raw const (__param_b[0]) as *const multimap_s)).root as *mut c_void) as *mut u8))

    ((__param_b[0]).root = ((null as *mut multimap_node_s)))

}

unsafe fn multimap_copy_node(__param_dst: *mut *mut multimap_node_s, __param_o: *mut multimap_node_s, __param_root: *mut multimap_node_s) -> Unit {
    var __local_n: *mut multimap_node_s = multimap_new_node()

    ((*__param_dst) = __local_n)


    var __local_num: c_int = ((multimap_get_num(__param_o) as c_int))

    if multimap_is_leaf(__param_o) {
        var __local_i: c_int = ((0 as c_int))

        while ((if __local_i < __local_num: 1 else: 0) != 0) {
            ((*__local_n).key[__local_i] = (((*__param_o).key[__local_i] as c_int)))


            ((*__local_n).kind.value[__local_i] = (((*(&raw const (*__param_o).kind as *const multimap_kind_s)).value[__local_i] as c_int)))




            (__local_i = __local_i + 1)

        }


    } else {
        if (((if not ((if __local_num != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"num != 0".ptr)
        } else {
            0
        }

        var __local_i_1: c_int = ((0 as c_int))

        while ((if __local_i_1 < __local_num: 1 else: 0) != 0) {
            ((*__local_n).key[__local_i_1] = (((*__param_o).key[__local_i_1] as c_int)))



            (__local_i_1 = __local_i_1 + 1)

        }


        var __local_i_2: c_int = ((0 as c_int))

        while ((if __local_i_2 <= __local_num: 1 else: 0) != 0) {
            if (((if not ((if (*(&raw const (*__param_o).kind as *const multimap_kind_s)).node[__local_i_2] != __param_root: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"o->kind.node[i] != root".ptr)
            } else {
                0
            }

            multimap_copy_node(((&raw const (*__local_n).kind.node[__local_i_2] as *const *mut multimap_node_s) as *mut *mut multimap_node_s), (*(&raw const (*__param_o).kind as *const multimap_kind_s)).node[__local_i_2], __param_root)


            (__local_i_2 = __local_i_2 + 1)

        }


        var __local_i_3: c_int = ((0 as c_int))

        while ((if __local_i_3 < __local_num: 1 else: 0) != 0) {
            var __local_current: *mut multimap_node_s = (*(&raw const (*__local_n).kind as *const multimap_kind_s)).node[__local_i_3]

            var __local_next: *mut multimap_node_s = (*(&raw const (*__local_n).kind as *const multimap_kind_s)).node[(__local_i_3 + 1)]

            ((*__local_current).next = __local_next)

            ((*__local_next).prev = __local_current)

            while ((if not multimap_is_leaf(__local_current): 1 else: 0) != 0) {
                if (((if not ((if not multimap_is_leaf(__local_next): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"!multimap_is_leaf(next)".ptr)
                } else {
                    0
                }

                (__local_current = (*(&raw const (*__local_current).kind as *const multimap_kind_s)).node[(*__local_current).num])

                (__local_next = (*(&raw const (*__local_next).kind as *const multimap_kind_s)).node[0])

                ((*__local_current).next = __local_next)

                ((*__local_next).prev = __local_current)

            }


            (__local_i_3 = __local_i_3 + 1)

        }


    }


    ((*__local_n).num = (*__param_o).num)

    loop {
        if (((if not ((if __local_n != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"(n) != ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (if (if __param_o == __param_root: 1 else: 0) != 0: __local_n else: __param_root) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"((o==root) ? n : root) != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_num2: c_int = (*__local_n).num

        var __local_is_leaf2: bool = ((__local_num2 <= 0))

        (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

        if ((if __local_n == (if (if __param_o == __param_root: 1 else: 0) != 0: __local_n else: __param_root): 1 else: 0) != 0) {
            var __ci_expr_logic_0: c_int = 0

            if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
            }

            if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
            } else {
                0
            }


            if ((if __local_num2 == 0: 1 else: 0) != 0) {
                if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                } else {
                    0
                }
            }

        } else {
            var __local_c2: c_int = (((5 / 2) as c_int))

            if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_1: c_int = 0

            if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
            }

            if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
            } else {
                0
            }


        }

        var __local_i2: c_int = ((1 as c_int))

        while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
            if (((if not ((if (if (if (*__local_n).key[(__local_i2 - 1)] < (*__local_n).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(__local_i2 - 1)] > (*__local_n).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[i2-1]) < ((n)->key[i2]) ? -1 : ((n)->key[i2-1]) > ((n)->key[i2])) <= 0".ptr)
            } else {
                0
            }


            (__local_i2 = __local_i2 + 1)

        }


        if ((if (*__local_n).next != null: 1 else: 0) != 0) {
            if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
            } else {
                0
            }

            if (((if not ((if (if (if (*__local_n).key[(__local_num2 - 1)] < (*(*__local_n).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(__local_num2 - 1)] > (*(*__local_n).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[num2-1]) < ((n)->next->key[0]) ? -1 : ((n)->key[num2-1]) > ((n)->next->key[0])) <= 0".ptr)
            } else {
                0
            }

        }

        if ((if (*__local_n).prev != null: 1 else: 0) != 0) {
            if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
            } else {
                0
            }

            var __local_num_prev: c_int = (*(*__local_n).prev).num

            (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

            if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
            } else {
                0
            }

            if (((if not ((if (if (if (*(*__local_n).prev).key[(__local_num_prev - 1)] < (*__local_n).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*(*__local_n).prev).key[(__local_num_prev - 1)] > (*__local_n).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_copy_node".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->prev->key[num_prev-1]) < ((n)->key[0]) ? -1 : ((n)->prev->key[num_prev-1]) > ((n)->key[0])) <= 0".ptr)
            } else {
                0
            }

        }

        if not ((0 != 0)) {
            break
        }
    }

}

unsafe fn multimap_init_set(__param_b: *mut multimap_s, __param_o: *mut multimap_s) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"((o)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_o[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"((o)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_o[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((o)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((o)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((o)->root+0)->key[i2-1]) < (((o)->root+0)->key[i2]) ? -1 : (((o)->root+0)->key[i2-1]) > (((o)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((o)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((o)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((o)->root+0)->key[num2-1]) < (((o)->root+0)->next->key[0]) ? -1 : (((o)->root+0)->key[num2-1]) > (((o)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_o[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((o)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((o)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((o)->root+0)->prev->key[num_prev-1]) < (((o)->root+0)->key[0]) ? -1 : (((o)->root+0)->prev->key[num_prev-1]) > (((o)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_o[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(o)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_o[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(o)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_o[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_o[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_o[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"-(o)->root->num == (int) (o)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    if (((if not ((if (&(__param_b[0]) as *mut c_void) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"b != ((void*)0)".ptr)
    } else {
        0
    }


    var __local_cont: bool = true

    while __local_cont {

        multimap_copy_node(((&raw const (*(&raw const (__param_b[0]) as *const multimap_s)).root as *const *mut multimap_node_s) as *mut *mut multimap_node_s), (*(&raw const (__param_o[0]) as *const multimap_s)).root, (*(&raw const (__param_o[0]) as *const multimap_s)).root)

        ((__param_b[0]).size = (*(&raw const (__param_o[0]) as *const multimap_s)).size)


        (__local_cont = false)

    }


    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if (if __local_num2_1 < 0: 1 else: 0) != 0: ((0 - __local_num2_1) as c_int) else: __local_num2_1) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_2: c_int = 0

                if ((if 0 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_1 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_1: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: c_int = 0

                if ((if __local_c2_1 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: c_int = ((1 as c_int))

            while ((if __local_i2_1 < __local_num2_1: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_1 = (((if (if __local_num_prev_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_1) as c_int) else: __local_num_prev_1) as c_int)))

                if (((if not ((if __local_num_prev_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_set".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

}

unsafe fn multimap_empty_p(__param_b: *mut multimap_s) -> bool {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_empty_p".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    return (((((*(&raw const (__param_b[0]) as *const multimap_s)).size == 0)) as bool))

}

unsafe fn multimap_size(__param_b: *mut multimap_s) -> c_ulong {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_size".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    return (*(&raw const (__param_b[0]) as *const multimap_s)).size

}

unsafe fn multimap_i_search_for_leaf(__param_pit: *mut multimap_parent_it_s, __param_b: *mut multimap_s, __param_key: c_int) -> *mut multimap_node_s {
    var __local_n: *mut multimap_node_s = (*(&raw const (__param_b[0]) as *const multimap_s)).root

    var __local_np: c_int = ((0 as c_int))

    while ((if not multimap_is_leaf(__local_n): 1 else: 0) != 0) {
        if (((if not ((if __local_np <= ((((1 as c_ulong) +% (((8 as c_ulong) *% (sizeof[c_ulong]() as c_ulong)) as c_ulong)) as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"np <= ((int)(1 + 8*sizeof (size_t)))".ptr)
        } else {
            0
        }

        var __local_i: c_int

        var __local_hi: c_int = (*__local_n).num


        if (((if not ((if __local_hi > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"hi > 0".ptr)
        } else {
            0
        }

        (__local_i = ((0 as c_int)))

        while ((if __local_i < __local_hi: 1 else: 0) != 0) {
            if ((if (if (if __param_key < (*__local_n).key[__local_i]: 1 else: 0) != 0: (-1 as c_int) else: ((if __param_key > (*__local_n).key[__local_i]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0) {
                break
            }


            (__local_i = __local_i + 1)

        }


        var __ci_expr_old_0: c_int = __local_np

        (__local_np = __local_np + 1)

        ((__param_pit[0]).parent[__ci_expr_old_0] = __local_n)


        (__local_n = (*(&raw const (*__local_n).kind as *const multimap_kind_s)).node[__local_i])

        if (((if not ((if __local_n != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"n != ((void*)0)".ptr)
        } else {
            0
        }

        loop {
            if (((if not ((if __local_n != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"(n) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"(b->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = (*__local_n).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if __local_n == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_1: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_2: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if (*__local_n).key[(__local_i2 - 1)] < (*__local_n).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(__local_i2 - 1)] > (*__local_n).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[i2-1]) < ((n)->key[i2]) ? -1 : ((n)->key[i2-1]) > ((n)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if (*__local_n).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*__local_n).key[(__local_num2 - 1)] < (*(*__local_n).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(__local_num2 - 1)] > (*(*__local_n).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[num2-1]) < ((n)->next->key[0]) ? -1 : ((n)->key[num2-1]) > ((n)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if (*__local_n).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*(*__local_n).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*(*__local_n).prev).key[(__local_num_prev - 1)] < (*__local_n).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*(*__local_n).prev).key[(__local_num_prev - 1)] > (*__local_n).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_i_search_for_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->prev->key[num_prev-1]) < ((n)->key[0]) ? -1 : ((n)->prev->key[num_prev-1]) > ((n)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

    }

    ((__param_pit[0]).num = __local_np)

    return __local_n

}

unsafe fn multimap_get(__param_b: *mut multimap_s, __param_key: c_int) -> *mut c_int {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    var __local_pit: [multimap_parent_it_s; 1]

    var __local_n: *mut multimap_node_s = multimap_i_search_for_leaf((&__local_pit[0] as *mut multimap_parent_it_s), (&(__param_b[0]) as *mut multimap_s), __param_key)

    var __local_cmp: c_int = ((0 as c_int))

    loop {
        if (((if not ((if __local_n != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(n) != ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_num2_1: c_int = (*__local_n).num

        var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

        (__local_num2_1 = (((if (if __local_num2_1 < 0: 1 else: 0) != 0: ((0 - __local_num2_1) as c_int) else: __local_num2_1) as c_int)))

        if ((if __local_n == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            var __ci_expr_logic_2: c_int = 0

            if ((if 0 <= __local_num2_1: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
            }

            if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
            } else {
                0
            }


            if ((if __local_num2_1 == 0: 1 else: 0) != 0) {
                if (((if not __local_is_leaf2_1: 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                } else {
                    0
                }
            }

        } else {
            var __local_c2_1: c_int = (((5 / 2) as c_int))

            if (((if not ((if __local_c2_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_3: c_int = 0

            if ((if __local_c2_1 <= __local_num2_1: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
            }

            if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
            } else {
                0
            }


        }

        var __local_i2_1: c_int = ((1 as c_int))

        while ((if __local_i2_1 < __local_num2_1: 1 else: 0) != 0) {
            if (((if not ((if (if (if (*__local_n).key[(__local_i2_1 - 1)] < (*__local_n).key[__local_i2_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(__local_i2_1 - 1)] > (*__local_n).key[__local_i2_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[i2-1]) < ((n)->key[i2]) ? -1 : ((n)->key[i2-1]) > ((n)->key[i2])) <= 0".ptr)
            } else {
                0
            }


            (__local_i2_1 = __local_i2_1 + 1)

        }


        if ((if (*__local_n).next != null: 1 else: 0) != 0) {
            if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
            } else {
                0
            }

            if (((if not ((if (if (if (*__local_n).key[(__local_num2_1 - 1)] < (*(*__local_n).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(__local_num2_1 - 1)] > (*(*__local_n).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[num2-1]) < ((n)->next->key[0]) ? -1 : ((n)->key[num2-1]) > ((n)->next->key[0])) <= 0".ptr)
            } else {
                0
            }

        }

        if ((if (*__local_n).prev != null: 1 else: 0) != 0) {
            if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
            } else {
                0
            }

            var __local_num_prev_1: c_int = (*(*__local_n).prev).num

            (__local_num_prev_1 = (((if (if __local_num_prev_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_1) as c_int) else: __local_num_prev_1) as c_int)))

            if (((if not ((if __local_num_prev_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
            } else {
                0
            }

            if (((if not ((if (if (if (*(*__local_n).prev).key[(__local_num_prev_1 - 1)] < (*__local_n).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*(*__local_n).prev).key[(__local_num_prev_1 - 1)] > (*__local_n).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->prev->key[num_prev-1]) < ((n)->key[0]) ? -1 : ((n)->prev->key[num_prev-1]) > ((n)->key[0])) <= 0".ptr)
            } else {
                0
            }

        }

        if not ((0 != 0)) {
            break
        }
    }

    var __local_i: c_int = ((0 as c_int))

    while true {
        var __ci_expr_logic_4: c_int = 0

        if ((if __local_cmp >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __local_i < (0 - (*__local_n).num): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_4 != 0)) {
            break
        }

        (__local_cmp = (((if (if __param_key < (*__local_n).key[__local_i]: 1 else: 0) != 0: (-1 as c_int) else: ((if __param_key > (*__local_n).key[__local_i]: 1 else: 0) as c_int)) as c_int)))

        if ((if __local_cmp == 0: 1 else: 0) != 0) {
            return (((&raw const (*__local_n).kind.value[__local_i] as *const c_int) as *mut c_int))

        }

        (__local_i = __local_i + 1)

    }


    return ((null as *mut c_int))

}

@[repr(C)]
pub type multimap_cget_literal_anon = union { ptr: *mut c_int = null, cptr: *const c_int = null }
impl Copy for multimap_cget_literal_anon
unsafe fn multimap_cget(__param_b: *mut multimap_s, __param_key: c_int) -> *const c_int {
    return (multimap_cget_literal_anon { ptr: multimap_get((&(__param_b[0]) as *mut multimap_s), __param_key) } as multimap_cget_literal_anon).cptr

}

unsafe fn multimap_rewind_transaction(__param_records: *mut m_bptr33_transaction_t_anon) {
    if (((if not ((if (&(__param_records[0]) as *mut c_void) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"records != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_j: c_int = ((((*(&raw const (__param_records[0]) as *const m_bptr33_transaction_t_anon)).size - 1) as c_int))

    while ((if __local_j >= 0: 1 else: 0) != 0) {
        var __local_record: *mut m_bptr33_transaction_record_t = (((&raw const (__param_records[0]).tab[__local_j] as *const m_bptr33_transaction_record_t) as *mut m_bptr33_transaction_record_t))

        while true {
            match (*__local_record).type_ {
                1 => {
                    with_free(((((*__local_record).data_dst as *mut multimap_node_s) as *mut c_void) as *mut u8))
                },
                2 => {
                    0
                },
                3 => {
                    ((*((*__local_record).data_src as *mut c_int)) = (*((*__local_record).data_dst as *mut c_int)))
                },
                4 => {
                    0
                },
                9 => {
                    var __local_t: *mut multimap_s = (((*__local_record).data_dst as *mut multimap_s))

                    if (((if not ((if __local_t != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"t != ((void*)0)".ptr)
                    } else {
                        0
                    }

                    if (((if not ((if (*__local_t).size > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"t->size > 0".ptr)
                    } else {
                        0
                    }

                    ((*__local_t).size = ((*__local_t).size -% 1))

                },
                5 => {
                    var __local_a: *mut multimap_node_s = (((*__local_record).data_dst as *mut multimap_node_s))

                    var __local_b: *mut multimap_node_s = (((*__local_record).data_src as *mut multimap_node_s))

                    var __ci_expr_logic_0: c_int = 0

                    if ((if __local_a != null: 1 else: 0) != 0) {
                        (__ci_expr_logic_0 = (if (if (*__local_a).next == __local_b: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"a != ((void*)0) && a->next == b".ptr)
                    } else {
                        0
                    }


                    var __ci_expr_logic_1: c_int = 0

                    if (multimap_is_leaf(__local_a) != 0) {
                        (__ci_expr_logic_1 = (if multimap_is_leaf(__local_b) != 0: 1 else: 0))
                    }

                    if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_is_leaf(a) && multimap_is_leaf(b)".ptr)
                    } else {
                        0
                    }


                    ((*__local_a).next = (*__local_b).next)

                    if ((if (*__local_b).next != null: 1 else: 0) != 0) {
                        ((*(*__local_b).next).prev = __local_a)

                    }

                    var __local_na: c_int = ((multimap_get_num(__local_a) as c_int))

                    var __local_nb: c_int = ((multimap_get_num(__local_b) as c_int))

                    if (((if not ((if (__local_na + __local_nb) == (5 + 1): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"na + nb == 5 + 1".ptr)
                    } else {
                        0
                    }

                    with_memmove(((((&raw const (*__local_a).key[__local_na] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_b).key[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_nb as c_uint) as c_ulong)) as c_ulong) as i64))

                    with_memmove(((((&raw const (*__local_a).kind.value[__local_na] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_b).kind.value[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_nb as c_uint) as c_ulong)) as c_ulong) as i64))

                    ((*__local_a).num = (*__local_a).num - __local_nb)

                },
                6 => {
                    var __local_a_1: *mut multimap_node_s = (((*__local_record).data_dst as *mut multimap_node_s))

                    var __local_b_1: *mut multimap_node_s = (((*__local_record).data_src as *mut multimap_node_s))

                    var __ci_expr_logic_2: c_int = 0

                    if ((if __local_a_1 != null: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if (if (*__local_a_1).next == __local_b_1: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"a != ((void*)0) && a->next == b".ptr)
                    } else {
                        0
                    }


                    var __ci_expr_logic_3: c_int = 0

                    if ((if not multimap_is_leaf(__local_a_1): 1 else: 0) != 0) {
                        (__ci_expr_logic_3 = (if (if not multimap_is_leaf(__local_b_1): 1 else: 0) != 0: 1 else: 0))
                    }

                    if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"!multimap_is_leaf(a) && !multimap_is_leaf(b)".ptr)
                    } else {
                        0
                    }


                    ((*__local_a_1).next = (*__local_b_1).next)

                    if ((if (*__local_b_1).next != null: 1 else: 0) != 0) {
                        ((*(*__local_b_1).next).prev = __local_a_1)

                    }

                    var __local_na_1: c_int = ((multimap_get_num(__local_a_1) as c_int))

                    var __local_nb_1: c_int = ((multimap_get_num(__local_b_1) as c_int))

                    if (((if not ((if ((__local_na_1 + __local_nb_1) + 1) == (5 + 1): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"na + nb + 1 == 5 + 1".ptr)
                    } else {
                        0
                    }

                    with_memmove(((((&raw const (*__local_a_1).key[(__local_na_1 + 1)] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_b_1).key[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_nb_1 as c_uint) as c_ulong)) as c_ulong) as i64))

                    with_memmove(((((&raw const (*__local_a_1).kind.node[(__local_na_1 + 1)] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__local_b_1).kind.node[0] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as c_ulong) *% (((__local_nb_1 + 1) as c_uint) as c_ulong)) as c_ulong) as i64))

                    ((*__local_a_1).num = (*__local_a_1).num + (__local_nb_1 + 1))

                },
                7 => {
                    var __local_n: *mut multimap_node_s = (((*__local_record).data_dst as *mut multimap_node_s))

                    if (((if not multimap_is_leaf(__local_n): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_is_leaf(n)".ptr)
                    } else {
                        0
                    }

                    var __local_i: c_int = ((((*__local_record).data_src as c_long) as c_int))

                    var __local_num: c_int = with 0 as __ci_expr_seq_94 {
                        ((*__local_n).num = (*__local_n).num + 1)
                        ((0 - (*__local_n).num) as c_int)
                    }

                    with_memmove(((((&raw const (*__local_n).key[__local_i] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_n).key[(__local_i + 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% (((__local_num - __local_i) as c_uint) as c_ulong)) as c_ulong) as i64))

                    with_memmove(((((&raw const (*__local_n).kind.value[__local_i] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_n).kind.value[(__local_i + 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% (((__local_num - __local_i) as c_uint) as c_ulong)) as c_ulong) as i64))

                },
                8 => {
                    var __local_n_1: *mut multimap_node_s = (((*__local_record).data_dst as *mut multimap_node_s))

                    if (((if not ((if not multimap_is_leaf(__local_n_1): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"!multimap_is_leaf(n)".ptr)
                    } else {
                        0
                    }

                    var __local_i_1: c_int = ((((*__local_record).data_src as c_long) as c_int))

                    var __local_num_1: c_int = with 0 as __ci_expr_seq_107 {
                        ((*__local_n_1).num = (*__local_n_1).num - 1)
                        (*__local_n_1).num
                    }

                    with_memmove(((((&raw const (*__local_n_1).key[__local_i_1] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_n_1).key[(__local_i_1 + 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% (((__local_num_1 - __local_i_1) as c_uint) as c_ulong)) as c_ulong) as i64))

                    with_memmove(((((&raw const (*__local_n_1).kind.node[__local_i_1] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__local_n_1).kind.node[(__local_i_1 + 1)] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as c_ulong) *% ((((__local_num_1 - __local_i_1) + 1) as c_uint) as c_ulong)) as c_ulong) as i64))

                },
                _ => {
                    if ((1 as c_long) != 0) {
                        __assert_rtn(c"multimap_rewind_transaction".ptr, c"multimap.c".ptr, (5 as c_int), c"0".ptr)
                    } else {
                        0
                    }
                },
            }

            break

        }


        (__local_j = __local_j - 1)

    }


    ((__param_records[0]).size = ((0 as c_int)))

    return

}

unsafe fn multimap_i_search_and_insert_in_leaf(__param_n: *mut multimap_node_s, __param_key: c_int, __param_value: c_int) -> c_int {
    if (((if not multimap_is_leaf(__param_n): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_search_and_insert_in_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_is_leaf(n)".ptr)
    } else {
        0
    }


    var __local_i: c_int

    var __local_num: c_int = ((multimap_get_num(__param_n) as c_int))


    if (((if not ((if __local_num <= 5: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_search_and_insert_in_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"num <= 5".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < __local_num: 1 else: 0) != 0) {
        var __local_cmp: c_int

        (__local_cmp = (((if (if __param_key < (*__param_n).key[__local_i]: 1 else: 0) != 0: (-1 as c_int) else: ((if __param_key > (*__param_n).key[__local_i]: 1 else: 0) as c_int)) as c_int)))


        if ((if __local_cmp <= 0: 1 else: 0) != 0) {
            with_memmove(((((&raw const (*__param_n).key[(__local_i + 1)] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).key[__local_i] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% (((__local_num - __local_i) as c_uint) as c_ulong)) as c_ulong) as i64))

            with_memmove(((((&raw const (*__param_n).kind.value[(__local_i + 1)] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).kind.value[__local_i] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% (((__local_num - __local_i) as c_uint) as c_ulong)) as c_ulong) as i64))

            break

        }


        (__local_i = __local_i + 1)

    }



    ((*__param_n).num = (*__param_n).num + -1)

    ((*__param_n).key[__local_i] = __param_key)


    ((*__param_n).kind.value[__local_i] = __param_value)


    return __local_i

}

unsafe fn multimap_i_search_and_insert_in_node(__param_n: *mut multimap_node_s, __param_l: *mut multimap_node_s, __param_key: *mut c_int) -> c_int {
    if (((if not ((if not multimap_is_leaf(__param_n): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_search_and_insert_in_node".ptr, c"multimap.c".ptr, (5 as c_int), c"!multimap_is_leaf(n)".ptr)
    } else {
        0
    }


    var __local_i: c_int

    var __local_num: c_int = ((multimap_get_num(__param_n) as c_int))


    if (((if not ((if __local_num <= 5: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_search_and_insert_in_node".ptr, c"multimap.c".ptr, (5 as c_int), c"num <= 5".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < __local_num: 1 else: 0) != 0) {
        if ((if (*(&raw const (*__param_n).kind as *const multimap_kind_s)).node[__local_i] == __param_l: 1 else: 0) != 0) {
            with_memmove(((((&raw const (*__param_n).key[(__local_i + 1)] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).key[__local_i] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% (((__local_num - __local_i) as c_uint) as c_ulong)) as c_ulong) as i64))

            with_memmove(((((&raw const (*__param_n).kind.node[(__local_i + 1)] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).kind.node[__local_i] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as c_ulong) *% ((((__local_num - __local_i) + 1) as c_uint) as c_ulong)) as c_ulong) as i64))

            break

        }


        (__local_i = __local_i + 1)

    }



    ((*__param_n).num = (*__param_n).num + 1)

    if multimap_is_leaf(__param_l) {
        ((*__param_n).key[__local_i] = (*__param_key))


    } else {
        ((*__param_n).key[__local_i] = (*__param_key))


    }

    return __local_i

}

unsafe fn multimap_set_at(__param_b: *mut multimap_s, __param_key: c_int, __param_value: c_int) -> Unit {
    var __local_pit__goto_5_1: [multimap_parent_it_s; 1]

    var __local_num2__goto_5_1: c_int = 0

    var __local_is_leaf2__goto_5_1: bool = false

    var __local_c2__goto_5_1: c_int = 0

    var __local_i2__goto_5_1: c_int = 0

    var __local_num_prev__goto_5_1: c_int = 0

    var __local_cont__goto_5_1: bool = false

    var __local_leaf__goto_5_1: *mut multimap_node_s = null

    var __local_nleaf__goto_5_1: *mut multimap_node_s = null

    var __local_key_ptr__goto_5_1: *mut c_int = null

    var __local_num__goto_5_1: c_int = 0

    var __local_nnum__goto_5_1: c_int = 0

    var __local_i__goto_5_1: c_int = 0

    var __local_parent__goto_5_1: *mut multimap_node_s = null

    var __local_nnp__goto_5_1: c_int = 0

    var __local_np__goto_5_1: c_int = 0

    var __local_nparent__goto_5_1: *mut multimap_node_s = null

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_logic_8: c_int = 0

    var __ci_expr_logic_9: c_int = 0

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_logic_11: c_int = 0

    var __ci_expr_logic_12: c_int = 0

    var __ci_expr_logic_13: c_int = 0

    var __ci_expr_logic_15: c_int = 0

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_logic_16: c_int = 0

    var __ci_expr_logic_17: c_int = 0

    var __ci_expr_logic_18: c_int = 0

    var __ci_expr_logic_19: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        goto '__ci_bb_4
    }

    '__ci_bb_2 {
        if (0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        (__local_cont__goto_5_1 = true)
        goto '__ci_bb_22
    }

    '__ci_bb_4 {
        if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_5 {
        if (0 != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_6 {
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_7 {
        (__ci_expr_logic_0 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_8 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_1 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_9
    }

    '__ci_bb_9 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_12
    }

    '__ci_bb_10 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_11
    }

    '__ci_bb_11 {
        goto '__ci_bb_9
    }

    '__ci_bb_12 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_13 {
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_14
    }

    '__ci_bb_14 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_12
    }

    '__ci_bb_15 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_16 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_18 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        goto '__ci_bb_5
    }

    '__ci_bb_20 {
        if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_21
    }

    '__ci_bb_21 {
        goto '__ci_bb_2
    }

    '__ci_bb_22 {
        if __local_cont__goto_5_1 {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_23 {
        (__local_leaf__goto_5_1 = multimap_i_search_for_leaf((&__local_pit__goto_5_1[0] as *mut multimap_parent_it_s), (&(__param_b[0]) as *mut multimap_s), __param_key))
        (__local_i__goto_5_1 = ((multimap_i_search_and_insert_in_leaf(__local_leaf__goto_5_1, __param_key, __param_value) as c_int)))
        if ((if __local_i__goto_5_1 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_24 {
        (__local_cont__goto_5_1 = false)
        goto '__ci_bb_22
    }

    '__ci_bb_25 {
        return
    }

    '__ci_bb_26 {
        goto '__ci_bb_28
    }

    '__ci_bb_27 {
        ((__param_b[0]).size = ((*(&raw const (__param_b[0]) as *const multimap_s)).size +% 1))
        (__local_num__goto_5_1 = (((0 - (*__local_leaf__goto_5_1).num) as c_int)))
        if (((if not ((if __local_num__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num > 0".ptr)
        } else {
            0
        }
        if (((if not ((if not ((if __local_num__goto_5_1 <= 5: 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_28 {
        goto '__ci_bb_31
    }

    '__ci_bb_29 {
        if (0 != 0) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_30 {
        goto '__ci_bb_49
    }

    '__ci_bb_31 {
        if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_32 {
        if (0 != 0) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_33 {
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_34 {
        (__ci_expr_logic_2 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_35 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_3 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_36
    }

    '__ci_bb_36 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_39
    }

    '__ci_bb_37 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_38
    }

    '__ci_bb_38 {
        goto '__ci_bb_36
    }

    '__ci_bb_39 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_40 {
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_41
    }

    '__ci_bb_41 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_39
    }

    '__ci_bb_42 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_43 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_44
    }

    '__ci_bb_44 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_45 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_46
    }

    '__ci_bb_46 {
        goto '__ci_bb_32
    }

    '__ci_bb_47 {
        if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_48
    }

    '__ci_bb_48 {
        goto '__ci_bb_29
    }

    '__ci_bb_49 {
        goto '__ci_bb_24
    }

    '__ci_bb_50 {
        goto '__ci_bb_52
    }

    '__ci_bb_51 {
        if (((if not ((if __local_num__goto_5_1 == (5 + 1): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num == 5+1".ptr)
        } else {
            0
        }
        (__local_nnum__goto_5_1 = ((((5 + 1) / 2) as c_int)))
        (__local_num__goto_5_1 = ((((5 + 1) - __local_nnum__goto_5_1) as c_int)))
        (__local_nleaf__goto_5_1 = multimap_new_node())
        with_memmove(((((&raw const (*__local_nleaf__goto_5_1).key[0] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_leaf__goto_5_1).key[__local_num__goto_5_1] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_nnum__goto_5_1 as c_uint) as c_ulong)) as c_ulong) as i64))
        with_memmove(((((&raw const (*__local_nleaf__goto_5_1).kind.value[0] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_leaf__goto_5_1).kind.value[__local_num__goto_5_1] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_nnum__goto_5_1 as c_uint) as c_ulong)) as c_ulong) as i64))
        ((*__local_leaf__goto_5_1).num = (((0 - __local_num__goto_5_1) as c_int)))
        ((*__local_nleaf__goto_5_1).num = (((0 - __local_nnum__goto_5_1) as c_int)))
        ((*__local_nleaf__goto_5_1).next = (*__local_leaf__goto_5_1).next)
        ((*__local_leaf__goto_5_1).next = __local_nleaf__goto_5_1)
        ((*__local_nleaf__goto_5_1).prev = __local_leaf__goto_5_1)
        if ((if (*__local_nleaf__goto_5_1).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_52 {
        goto '__ci_bb_55
    }

    '__ci_bb_53 {
        if (0 != 0) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_54 {
        goto '__ci_bb_49
    }

    '__ci_bb_55 {
        if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_56 {
        if (0 != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_57 {
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_72
        }
    }

    '__ci_bb_58 {
        (__ci_expr_logic_4 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_4 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_59 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_5 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_5 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_60
    }

    '__ci_bb_60 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_63
    }

    '__ci_bb_61 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_62
    }

    '__ci_bb_62 {
        goto '__ci_bb_60
    }

    '__ci_bb_63 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_64
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_64 {
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_65
    }

    '__ci_bb_65 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_63
    }

    '__ci_bb_66 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_67 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_68
    }

    '__ci_bb_68 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_69 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_70
    }

    '__ci_bb_70 {
        goto '__ci_bb_56
    }

    '__ci_bb_71 {
        if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_72
    }

    '__ci_bb_72 {
        goto '__ci_bb_53
    }

    '__ci_bb_73 {
        ((*(*__local_nleaf__goto_5_1).next).prev = __local_nleaf__goto_5_1)
        goto '__ci_bb_74
    }

    '__ci_bb_74 {
        goto '__ci_bb_75
    }

    '__ci_bb_75 {
        if (((if not ((if __local_leaf__goto_5_1 != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(leaf) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = (*__local_leaf__goto_5_1).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if __local_leaf__goto_5_1 == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_76 {
        if (0 != 0) {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_77 {
        goto '__ci_bb_91
    }

    '__ci_bb_78 {
        (__ci_expr_logic_6 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_6 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_79 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_7 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_7 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_80
    }

    '__ci_bb_80 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_83
    }

    '__ci_bb_81 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_82
    }

    '__ci_bb_82 {
        goto '__ci_bb_80
    }

    '__ci_bb_83 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_86
        }
    }

    '__ci_bb_84 {
        if (((if not ((if (if (if (*__local_leaf__goto_5_1).key[(__local_i2__goto_5_1 - 1)] < (*__local_leaf__goto_5_1).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_leaf__goto_5_1).key[(__local_i2__goto_5_1 - 1)] > (*__local_leaf__goto_5_1).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((leaf)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(leaf)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((leaf)->key[i2-1]) < ((leaf)->key[i2]) ? -1 : ((leaf)->key[i2-1]) > ((leaf)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_85
    }

    '__ci_bb_85 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_83
    }

    '__ci_bb_86 {
        if ((if (*__local_leaf__goto_5_1).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_87
        } else {
            goto '__ci_bb_88
        }
    }

    '__ci_bb_87 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*__local_leaf__goto_5_1).key[(__local_num2__goto_5_1 - 1)] < (*(*__local_leaf__goto_5_1).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_leaf__goto_5_1).key[(__local_num2__goto_5_1 - 1)] > (*(*__local_leaf__goto_5_1).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((leaf)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(leaf)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((leaf)->key[num2-1]) < ((leaf)->next->key[0]) ? -1 : ((leaf)->key[num2-1]) > ((leaf)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_88
    }

    '__ci_bb_88 {
        if ((if (*__local_leaf__goto_5_1).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_90
        }
    }

    '__ci_bb_89 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*(*__local_leaf__goto_5_1).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*(*__local_leaf__goto_5_1).prev).key[(__local_num_prev__goto_5_1 - 1)] < (*__local_leaf__goto_5_1).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*(*__local_leaf__goto_5_1).prev).key[(__local_num_prev__goto_5_1 - 1)] > (*__local_leaf__goto_5_1).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((leaf)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(leaf)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((leaf)->prev->key[num_prev-1]) < ((leaf)->key[0]) ? -1 : ((leaf)->prev->key[num_prev-1]) > ((leaf)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_90
    }

    '__ci_bb_90 {
        goto '__ci_bb_76
    }

    '__ci_bb_91 {
        if (((if not ((if __local_nleaf__goto_5_1 != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(nleaf) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = (*__local_nleaf__goto_5_1).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if __local_nleaf__goto_5_1 == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_92 {
        if (0 != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_93
        }
    }

    '__ci_bb_93 {
        (__local_key_ptr__goto_5_1 = (((&raw const (*__local_leaf__goto_5_1).key[(__local_num__goto_5_1 - 1)] as *const c_int) as *mut c_int)))
        goto '__ci_bb_107
    }

    '__ci_bb_94 {
        (__ci_expr_logic_8 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_8 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_95 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_9 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_9 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_96
    }

    '__ci_bb_96 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_99
    }

    '__ci_bb_97 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_98
    }

    '__ci_bb_98 {
        goto '__ci_bb_96
    }

    '__ci_bb_99 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_100 {
        if (((if not ((if (if (if (*__local_nleaf__goto_5_1).key[(__local_i2__goto_5_1 - 1)] < (*__local_nleaf__goto_5_1).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_nleaf__goto_5_1).key[(__local_i2__goto_5_1 - 1)] > (*__local_nleaf__goto_5_1).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nleaf)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nleaf)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nleaf)->key[i2-1]) < ((nleaf)->key[i2]) ? -1 : ((nleaf)->key[i2-1]) > ((nleaf)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_101
    }

    '__ci_bb_101 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_99
    }

    '__ci_bb_102 {
        if ((if (*__local_nleaf__goto_5_1).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_104
        }
    }

    '__ci_bb_103 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*__local_nleaf__goto_5_1).key[(__local_num2__goto_5_1 - 1)] < (*(*__local_nleaf__goto_5_1).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_nleaf__goto_5_1).key[(__local_num2__goto_5_1 - 1)] > (*(*__local_nleaf__goto_5_1).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nleaf)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nleaf)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nleaf)->key[num2-1]) < ((nleaf)->next->key[0]) ? -1 : ((nleaf)->key[num2-1]) > ((nleaf)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_104
    }

    '__ci_bb_104 {
        if ((if (*__local_nleaf__goto_5_1).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_105 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*(*__local_nleaf__goto_5_1).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*(*__local_nleaf__goto_5_1).prev).key[(__local_num_prev__goto_5_1 - 1)] < (*__local_nleaf__goto_5_1).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*(*__local_nleaf__goto_5_1).prev).key[(__local_num_prev__goto_5_1 - 1)] > (*__local_nleaf__goto_5_1).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nleaf)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nleaf)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nleaf)->prev->key[num_prev-1]) < ((nleaf)->key[0]) ? -1 : ((nleaf)->prev->key[num_prev-1]) > ((nleaf)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_106
    }

    '__ci_bb_106 {
        goto '__ci_bb_92
    }

    '__ci_bb_107 {
        if (1 != 0) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_109
        }
    }

    '__ci_bb_108 {
        if ((if (*(&raw const __local_pit__goto_5_1[0] as *const multimap_parent_it_s)).num == 0: 1 else: 0) != 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_109 {
        goto '__ci_bb_49
    }

    '__ci_bb_110 {
        (__local_parent__goto_5_1 = multimap_new_node())
        ((*__local_parent__goto_5_1).num = ((1 as c_int)))
        if multimap_is_leaf(__local_leaf__goto_5_1) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_111 {
        (__local_pit__goto_5_1[0].num = (*(&raw const __local_pit__goto_5_1[0] as *const multimap_parent_it_s)).num - 1)
        (__local_parent__goto_5_1 = (*(&raw const __local_pit__goto_5_1[0] as *const multimap_parent_it_s)).parent[(*(&raw const __local_pit__goto_5_1[0] as *const multimap_parent_it_s)).num])
        (__local_i__goto_5_1 = ((multimap_i_search_and_insert_in_node(__local_parent__goto_5_1, __local_leaf__goto_5_1, __local_key_ptr__goto_5_1) as c_int)))
        ((*__local_parent__goto_5_1).kind.node[__local_i__goto_5_1] = __local_leaf__goto_5_1)
        ((*__local_parent__goto_5_1).kind.node[(__local_i__goto_5_1 + 1)] = __local_nleaf__goto_5_1)
        if (((if not ((if not ((if (*__local_parent__goto_5_1).num <= 5: 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_112 {
        ((*__local_parent__goto_5_1).key[0] = (*__local_key_ptr__goto_5_1))
        goto '__ci_bb_114
    }

    '__ci_bb_113 {
        ((*__local_parent__goto_5_1).key[0] = (*__local_key_ptr__goto_5_1))
        goto '__ci_bb_114
    }

    '__ci_bb_114 {
        ((*__local_parent__goto_5_1).kind.node[0] = __local_leaf__goto_5_1)
        ((*__local_parent__goto_5_1).kind.node[1] = __local_nleaf__goto_5_1)
        ((__param_b[0]).root = __local_parent__goto_5_1)
        goto '__ci_bb_115
    }

    '__ci_bb_115 {
        goto '__ci_bb_118
    }

    '__ci_bb_116 {
        if (0 != 0) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_117 {
        goto '__ci_bb_49
    }

    '__ci_bb_118 {
        if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_119 {
        if (0 != 0) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_120
        }
    }

    '__ci_bb_120 {
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_134
        } else {
            goto '__ci_bb_135
        }
    }

    '__ci_bb_121 {
        (__ci_expr_logic_10 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_10 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_122 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_11 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_11 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_11 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_123
    }

    '__ci_bb_123 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_126
    }

    '__ci_bb_124 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_125
    }

    '__ci_bb_125 {
        goto '__ci_bb_123
    }

    '__ci_bb_126 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_127 {
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_128
    }

    '__ci_bb_128 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_126
    }

    '__ci_bb_129 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_130
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_130 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_131
    }

    '__ci_bb_131 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_132
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_132 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_133
    }

    '__ci_bb_133 {
        goto '__ci_bb_119
    }

    '__ci_bb_134 {
        if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        goto '__ci_bb_116
    }

    '__ci_bb_136 {
        goto '__ci_bb_138
    }

    '__ci_bb_137 {
        if (((if not ((if (*__local_parent__goto_5_1).num == (5 + 1): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"parent->num == 5+1".ptr)
        } else {
            0
        }
        (__local_nnp__goto_5_1 = (((5 / 2) as c_int)))
        (__local_np__goto_5_1 = (((5 - __local_nnp__goto_5_1) as c_int)))
        (__ci_expr_logic_15 = 0)
        (__ci_expr_logic_14 = 0)
        if ((if __local_nnp__goto_5_1 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if (if __local_np__goto_5_1 > 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            (__ci_expr_logic_15 = (if (if ((__local_nnp__goto_5_1 + __local_np__goto_5_1) + 1) == (5 + 1): 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_15 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"nnp > 0 && np > 0 && nnp+np+1 == 5+1".ptr)
        } else {
            0
        }
        (__local_nparent__goto_5_1 = multimap_new_node())
        with_memmove(((((&raw const (*__local_nparent__goto_5_1).key[0] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_parent__goto_5_1).key[(__local_np__goto_5_1 + 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_nnp__goto_5_1 as c_uint) as c_ulong)) as c_ulong) as i64))
        with_memmove(((((&raw const (*__local_nparent__goto_5_1).kind.node[0] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__local_parent__goto_5_1).kind.node[(__local_np__goto_5_1 + 1)] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as c_ulong) *% (((__local_nnp__goto_5_1 + 1) as c_uint) as c_ulong)) as c_ulong) as i64))
        ((*__local_parent__goto_5_1).num = __local_np__goto_5_1)
        ((*__local_nparent__goto_5_1).num = __local_nnp__goto_5_1)
        ((*__local_nparent__goto_5_1).next = (*__local_parent__goto_5_1).next)
        ((*__local_parent__goto_5_1).next = __local_nparent__goto_5_1)
        ((*__local_nparent__goto_5_1).prev = __local_parent__goto_5_1)
        if ((if (*__local_nparent__goto_5_1).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_138 {
        goto '__ci_bb_141
    }

    '__ci_bb_139 {
        if (0 != 0) {
            goto '__ci_bb_138
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_140 {
        goto '__ci_bb_49
    }

    '__ci_bb_141 {
        if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_144
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_142 {
        if (0 != 0) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_143 {
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_144 {
        (__ci_expr_logic_12 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_12 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_12 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_147
        } else {
            goto '__ci_bb_148
        }
    }

    '__ci_bb_145 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_13 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_13 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_13 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_146
    }

    '__ci_bb_146 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_149
    }

    '__ci_bb_147 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_148
    }

    '__ci_bb_148 {
        goto '__ci_bb_146
    }

    '__ci_bb_149 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_152
        }
    }

    '__ci_bb_150 {
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_151
    }

    '__ci_bb_151 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_149
    }

    '__ci_bb_152 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_153
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_153 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_154
    }

    '__ci_bb_154 {
        if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_155 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_156
    }

    '__ci_bb_156 {
        goto '__ci_bb_142
    }

    '__ci_bb_157 {
        if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_158
    }

    '__ci_bb_158 {
        goto '__ci_bb_139
    }

    '__ci_bb_159 {
        ((*(*__local_nparent__goto_5_1).next).prev = __local_nparent__goto_5_1)
        goto '__ci_bb_160
    }

    '__ci_bb_160 {
        goto '__ci_bb_161
    }

    '__ci_bb_161 {
        if (((if not ((if __local_parent__goto_5_1 != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(parent) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = (*__local_parent__goto_5_1).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if __local_parent__goto_5_1 == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_162 {
        if (0 != 0) {
            goto '__ci_bb_161
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_163 {
        goto '__ci_bb_177
    }

    '__ci_bb_164 {
        (__ci_expr_logic_16 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_16 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_167
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_165 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_17 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_17 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_166
    }

    '__ci_bb_166 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_169
    }

    '__ci_bb_167 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_168
    }

    '__ci_bb_168 {
        goto '__ci_bb_166
    }

    '__ci_bb_169 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_170
        } else {
            goto '__ci_bb_172
        }
    }

    '__ci_bb_170 {
        if (((if not ((if (if (if (*__local_parent__goto_5_1).key[(__local_i2__goto_5_1 - 1)] < (*__local_parent__goto_5_1).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_parent__goto_5_1).key[(__local_i2__goto_5_1 - 1)] > (*__local_parent__goto_5_1).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((parent)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(parent)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((parent)->key[i2-1]) < ((parent)->key[i2]) ? -1 : ((parent)->key[i2-1]) > ((parent)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_171
    }

    '__ci_bb_171 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_169
    }

    '__ci_bb_172 {
        if ((if (*__local_parent__goto_5_1).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_173
        } else {
            goto '__ci_bb_174
        }
    }

    '__ci_bb_173 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*__local_parent__goto_5_1).key[(__local_num2__goto_5_1 - 1)] < (*(*__local_parent__goto_5_1).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_parent__goto_5_1).key[(__local_num2__goto_5_1 - 1)] > (*(*__local_parent__goto_5_1).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((parent)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(parent)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((parent)->key[num2-1]) < ((parent)->next->key[0]) ? -1 : ((parent)->key[num2-1]) > ((parent)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_174
    }

    '__ci_bb_174 {
        if ((if (*__local_parent__goto_5_1).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_175
        } else {
            goto '__ci_bb_176
        }
    }

    '__ci_bb_175 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*(*__local_parent__goto_5_1).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*(*__local_parent__goto_5_1).prev).key[(__local_num_prev__goto_5_1 - 1)] < (*__local_parent__goto_5_1).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*(*__local_parent__goto_5_1).prev).key[(__local_num_prev__goto_5_1 - 1)] > (*__local_parent__goto_5_1).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((parent)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(parent)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((parent)->prev->key[num_prev-1]) < ((parent)->key[0]) ? -1 : ((parent)->prev->key[num_prev-1]) > ((parent)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_176
    }

    '__ci_bb_176 {
        goto '__ci_bb_162
    }

    '__ci_bb_177 {
        if (((if not ((if __local_nparent__goto_5_1 != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(nparent) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = (*__local_nparent__goto_5_1).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if __local_nparent__goto_5_1 == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_178 {
        if (0 != 0) {
            goto '__ci_bb_177
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_179 {
        (__local_key_ptr__goto_5_1 = (((&raw const (*__local_parent__goto_5_1).key[__local_np__goto_5_1] as *const c_int) as *mut c_int)))
        (__local_leaf__goto_5_1 = __local_parent__goto_5_1)
        (__local_nleaf__goto_5_1 = __local_nparent__goto_5_1)
        goto '__ci_bb_107
    }

    '__ci_bb_180 {
        (__ci_expr_logic_18 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_18 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_183
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_181 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_19 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_19 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_19 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_182
    }

    '__ci_bb_182 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_185
    }

    '__ci_bb_183 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_184
    }

    '__ci_bb_184 {
        goto '__ci_bb_182
    }

    '__ci_bb_185 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_186
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_186 {
        if (((if not ((if (if (if (*__local_nparent__goto_5_1).key[(__local_i2__goto_5_1 - 1)] < (*__local_nparent__goto_5_1).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_nparent__goto_5_1).key[(__local_i2__goto_5_1 - 1)] > (*__local_nparent__goto_5_1).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nparent)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nparent)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nparent)->key[i2-1]) < ((nparent)->key[i2]) ? -1 : ((nparent)->key[i2-1]) > ((nparent)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_187
    }

    '__ci_bb_187 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_185
    }

    '__ci_bb_188 {
        if ((if (*__local_nparent__goto_5_1).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_189 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*__local_nparent__goto_5_1).key[(__local_num2__goto_5_1 - 1)] < (*(*__local_nparent__goto_5_1).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_nparent__goto_5_1).key[(__local_num2__goto_5_1 - 1)] > (*(*__local_nparent__goto_5_1).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nparent)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nparent)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nparent)->key[num2-1]) < ((nparent)->next->key[0]) ? -1 : ((nparent)->key[num2-1]) > ((nparent)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_190
    }

    '__ci_bb_190 {
        if ((if (*__local_nparent__goto_5_1).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_191 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*(*__local_nparent__goto_5_1).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*(*__local_nparent__goto_5_1).prev).key[(__local_num_prev__goto_5_1 - 1)] < (*__local_nparent__goto_5_1).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*(*__local_nparent__goto_5_1).prev).key[(__local_num_prev__goto_5_1 - 1)] > (*__local_nparent__goto_5_1).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_set_at".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nparent)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nparent)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nparent)->prev->key[num_prev-1]) < ((nparent)->key[0]) ? -1 : ((nparent)->prev->key[num_prev-1]) > ((nparent)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_192
    }

    '__ci_bb_192 {
        goto '__ci_bb_178
    }

    __ci_unreachable()

}

unsafe fn multimap_safe_get(__param_b: *mut multimap_s, __param_key: c_int) -> *mut c_int {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_safe_get".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    var __local_ret: *mut c_int = multimap_get((&(__param_b[0]) as *mut multimap_s), __param_key)

    if ((if __local_ret == null: 1 else: 0) != 0) {
        var __local_v: c_int

        (__local_v = ((0 as c_int)))

        var __local_m_var_5: bool = true

        while __local_m_var_5 {

            while __local_m_var_5 {

                while __local_m_var_5 {
                    multimap_set_at((&(__param_b[0]) as *mut multimap_s), __param_key, __local_v)


                    (__local_m_var_5 = false)

                }


                (__local_m_var_5 = false)

            }


            (__local_m_var_5 = false)

        }


        (__local_ret = multimap_get((&(__param_b[0]) as *mut multimap_s), __param_key))

    }

    return __local_ret

}

unsafe fn multimap_i_search_and_remove_in_leaf(__param_n: *mut multimap_node_s, __param_key: c_int) -> c_int {
    if (((if not multimap_is_leaf(__param_n): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_search_and_remove_in_leaf".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_is_leaf(n)".ptr)
    } else {
        0
    }


    var __local_num: c_int = ((multimap_get_num(__param_n) as c_int))

    var __local_i: c_int = ((0 as c_int))

    while ((if __local_i < __local_num: 1 else: 0) != 0) {
        var __local_cmp: c_int

        (__local_cmp = (((if (if __param_key < (*__param_n).key[__local_i]: 1 else: 0) != 0: (-1 as c_int) else: ((if __param_key > (*__param_n).key[__local_i]: 1 else: 0) as c_int)) as c_int)))


        if ((if __local_cmp == 0: 1 else: 0) != 0) {


            with_memmove(((((&raw const (*__param_n).key[__local_i] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).key[(__local_i + 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((((__local_num - 1) - __local_i) as c_uint) as c_ulong)) as c_ulong) as i64))

            with_memmove(((((&raw const (*__param_n).kind.value[__local_i] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).kind.value[(__local_i + 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((((__local_num - 1) - __local_i) as c_uint) as c_ulong)) as c_ulong) as i64))

            ((*__param_n).num = (*__param_n).num - -1)

            return __local_i

        }


        (__local_i = __local_i + 1)

    }


    return -1

}

unsafe fn multimap_i_left_shift(__param_parent: *mut multimap_node_s, __param_k: c_int) -> Unit {
    var __ci_expr_logic_0: c_int = 0

    if ((if __param_parent != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not multimap_is_leaf(__param_parent): 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_left_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"parent != ((void*)0) && !multimap_is_leaf(parent)".ptr)
    } else {
        0
    }


    var __ci_expr_logic_1: c_int = 0

    if ((if 0 <= __param_k: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if __param_k < multimap_get_num(__param_parent): 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_left_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= k && k < multimap_get_num(parent)".ptr)
    } else {
        0
    }



    var __local_left: *mut multimap_node_s = (*(&raw const (*__param_parent).kind as *const multimap_kind_s)).node[__param_k]

    var __local_right: *mut multimap_node_s = (*(&raw const (*__param_parent).kind as *const multimap_kind_s)).node[(__param_k + 1)]

    var __ci_expr_logic_2: c_int = 0

    if ((if __local_left != null: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if __local_right != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_left_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"left != ((void*)0) && right != ((void*)0)".ptr)
    } else {
        0
    }


    var __local_num_left: c_int = ((multimap_get_num(__local_left) as c_int))

    var __local_num_right: c_int = ((multimap_get_num(__local_right) as c_int))

    if (((if not ((if __local_num_left > (5 / 2): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_left_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"num_left > 5/2".ptr)
    } else {
        0
    }

    if (((if not ((if __local_num_right < (5 / 2): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_left_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"num_right < 5/2".ptr)
    } else {
        0
    }

    with_memmove(((((&raw const (*__local_right).key[1] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).key[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_num_right as c_uint) as c_ulong)) as c_ulong) as i64))

    if multimap_is_leaf(__local_left) {
        with_memmove(((((&raw const (*__local_right).kind.value[1] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).kind.value[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_num_right as c_uint) as c_ulong)) as c_ulong) as i64))

        with_memmove(((((&raw const (*__local_right).key[0] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_left).key[(__local_num_left - 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((4 as c_ulong) as i64))

        with_memmove(((((&raw const (*__local_right).kind.value[0] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_left).kind.value[(__local_num_left - 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((4 as c_ulong) as i64))

        ((*__local_right).num = ((((0 - __local_num_right) - 1) as c_int)))

        ((*__local_left).num = ((((0 - __local_num_left) + 1) as c_int)))

        ((*__param_parent).key[__param_k] = (((*__local_left).key[(__local_num_left - 2)] as c_int)))

    } else {
        with_memmove(((((&raw const (*__local_right).kind.node[1] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).kind.node[0] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as c_ulong) *% (((__local_num_right + 1) as c_uint) as c_ulong)) as c_ulong) as i64))

        with_memmove(((((&raw const (*__local_right).key[0] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__param_parent).key[__param_k] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((4 as c_ulong) as i64))

        ((*__local_right).kind.node[0] = (*(&raw const (*__local_left).kind as *const multimap_kind_s)).node[__local_num_left])

        ((*__local_right).num = (((__local_num_right + 1) as c_int)))

        ((*__local_left).num = (((__local_num_left - 1) as c_int)))

        with_memmove(((((&raw const (*__param_parent).key[__param_k] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_left).key[(__local_num_left - 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((4 as c_ulong) as i64))

    }

    if (((if not ((if (*__local_right).num != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_left_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"right->num != 0".ptr)
    } else {
        0
    }

    if (((if not ((if (*__local_left).num != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_left_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"left->num != 0".ptr)
    } else {
        0
    }

}

unsafe fn multimap_i_right_shift(__param_parent: *mut multimap_node_s, __param_k: c_int) -> Unit {
    var __ci_expr_logic_0: c_int = 0

    if ((if __param_parent != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not multimap_is_leaf(__param_parent): 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_right_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"parent != ((void*)0) && !multimap_is_leaf(parent)".ptr)
    } else {
        0
    }


    var __ci_expr_logic_1: c_int = 0

    if ((if 0 <= __param_k: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if __param_k < multimap_get_num(__param_parent): 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_right_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= k && k < multimap_get_num(parent)".ptr)
    } else {
        0
    }



    var __local_left: *mut multimap_node_s = (*(&raw const (*__param_parent).kind as *const multimap_kind_s)).node[__param_k]

    var __local_right: *mut multimap_node_s = (*(&raw const (*__param_parent).kind as *const multimap_kind_s)).node[(__param_k + 1)]

    var __ci_expr_logic_2: c_int = 0

    if ((if __local_left != null: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if __local_right != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_right_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"left != ((void*)0) && right != ((void*)0)".ptr)
    } else {
        0
    }


    var __local_num_left: c_int = ((multimap_get_num(__local_left) as c_int))

    var __local_num_right: c_int = ((multimap_get_num(__local_right) as c_int))

    if (((if not ((if __local_num_left < (5 / 2): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_right_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"num_left < 5/2".ptr)
    } else {
        0
    }

    if (((if not ((if __local_num_right > (5 / 2): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_right_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"num_right > 5/2".ptr)
    } else {
        0
    }

    if multimap_is_leaf(__local_right) {
        with_memmove(((((&raw const (*__local_left).key[__local_num_left] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).key[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((4 as c_ulong) as i64))

        with_memmove(((((&raw const (*__local_right).key[0] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).key[1] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% (((__local_num_right - 1) as c_uint) as c_ulong)) as c_ulong) as i64))

        with_memmove(((((&raw const (*__local_left).kind.value[__local_num_left] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).kind.value[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((4 as c_ulong) as i64))

        with_memmove(((((&raw const (*__local_right).kind.value[0] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).kind.value[1] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% (((__local_num_right - 1) as c_uint) as c_ulong)) as c_ulong) as i64))

        ((*__local_right).num = ((((0 - __local_num_right) + 1) as c_int)))

        ((*__local_left).num = ((((0 - __local_num_left) - 1) as c_int)))

        ((*__param_parent).key[__param_k] = (((*__local_left).key[__local_num_left] as c_int)))

    } else {
        with_memmove(((((&raw const (*__local_left).key[__local_num_left] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__param_parent).key[__param_k] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((4 as c_ulong) as i64))

        with_memmove(((((&raw const (*__param_parent).key[__param_k] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).key[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((4 as c_ulong) as i64))

        with_memmove(((((&raw const (*__local_right).key[0] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).key[1] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% (((__local_num_right - 1) as c_uint) as c_ulong)) as c_ulong) as i64))

        ((*__local_left).kind.node[(__local_num_left + 1)] = (*(&raw const (*__local_right).kind as *const multimap_kind_s)).node[0])

        with_memmove(((((&raw const (*__local_right).kind.node[0] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).kind.node[1] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as c_ulong) *% ((__local_num_right as c_uint) as c_ulong)) as c_ulong) as i64))

        ((*__local_right).num = (((__local_num_right - 1) as c_int)))

        ((*__local_left).num = (((__local_num_left + 1) as c_int)))

    }

    if (((if not ((if (*__local_right).num != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_right_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"right->num != 0".ptr)
    } else {
        0
    }

    if (((if not ((if (*__local_left).num != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_right_shift".ptr, c"multimap.c".ptr, (5 as c_int), c"left->num != 0".ptr)
    } else {
        0
    }

}

unsafe fn multimap_i_merge_node(__param_parent: *mut multimap_node_s, __param_k: c_int, __param_leaf: bool) {
    var __ci_expr_logic_0: c_int = 0

    if ((if __param_parent != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not multimap_is_leaf(__param_parent): 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_merge_node".ptr, c"multimap.c".ptr, (5 as c_int), c"parent != ((void*)0) && !multimap_is_leaf(parent)".ptr)
    } else {
        0
    }


    var __ci_expr_logic_1: c_int = 0

    if ((if 0 <= __param_k: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if __param_k < multimap_get_num(__param_parent): 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_merge_node".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= k && k < multimap_get_num(parent)".ptr)
    } else {
        0
    }


    var __local_left: *mut multimap_node_s = (*(&raw const (*__param_parent).kind as *const multimap_kind_s)).node[__param_k]

    var __local_right: *mut multimap_node_s = (*(&raw const (*__param_parent).kind as *const multimap_kind_s)).node[(__param_k + 1)]

    var __ci_expr_logic_2: c_int = 0

    if ((if __local_left != null: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if __local_right != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_merge_node".ptr, c"multimap.c".ptr, (5 as c_int), c"left != ((void*)0) && right != ((void*)0)".ptr)
    } else {
        0
    }


    var __local_num_parent: c_int = ((multimap_get_num(__param_parent) as c_int))

    var __local_num_left: c_int = ((multimap_get_num(__local_left) as c_int))

    var __local_num_right: c_int = ((multimap_get_num(__local_right) as c_int))

    if __param_leaf {
        if (((if not ((if (__local_num_left + __local_num_right) <= 5: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_i_merge_node".ptr, c"multimap.c".ptr, (5 as c_int), c"num_left + num_right <= 5".ptr)
        } else {
            0
        }

        with_memmove(((((&raw const (*__local_left).key[__local_num_left] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).key[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_num_right as c_uint) as c_ulong)) as c_ulong) as i64))

        with_memmove(((((&raw const (*__local_left).kind.value[__local_num_left] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).kind.value[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_num_right as c_uint) as c_ulong)) as c_ulong) as i64))

        ((*__local_left).num = ((((0 - __local_num_left) - __local_num_right) as c_int)))

    } else {
        if (((if not ((if (__local_num_left + __local_num_right) <= (5 - 1): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_i_merge_node".ptr, c"multimap.c".ptr, (5 as c_int), c"num_left + num_right <= 5 -1".ptr)
        } else {
            0
        }

        with_memmove(((((&raw const (*__local_left).key[(__local_num_left + 1)] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).key[0] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((__local_num_right as c_uint) as c_ulong)) as c_ulong) as i64))

        with_memmove(((((&raw const (*__local_left).kind.node[(__local_num_left + 1)] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__local_right).kind.node[0] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as c_ulong) *% (((__local_num_right + 1) as c_uint) as c_ulong)) as c_ulong) as i64))

        ((*__local_left).key[__local_num_left] = (((*__param_parent).key[__param_k] as c_int)))

        ((*__local_left).num = ((((__local_num_left + 1) + __local_num_right) as c_int)))

    }

    ((*__local_left).next = (*__local_right).next)

    if ((if (*__local_left).next != null: 1 else: 0) != 0) {
        ((*(*__local_left).next).prev = __local_left)

    }

    with_free(((__local_right as *mut c_void) as *mut u8))


    with_memmove(((((&raw const (*__param_parent).key[__param_k] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__param_parent).key[(__param_k + 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((((__local_num_parent - __param_k) - 1) as c_uint) as c_ulong)) as c_ulong) as i64))

    with_memmove(((((&raw const (*__param_parent).kind.node[(__param_k + 1)] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__param_parent).kind.node[(__param_k + 2)] as *const *mut multimap_node_s) as *mut *mut multimap_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as c_ulong) *% ((((__local_num_parent - __param_k) - 1) as c_uint) as c_ulong)) as c_ulong) as i64))

    ((*__param_parent).num = (*__param_parent).num - 1)

}

unsafe fn multimap_i_search_for_node(__param_parent: *mut multimap_node_s, __param_child: *mut multimap_node_s) -> c_int {
    if (((if not ((if not multimap_is_leaf(__param_parent): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_i_search_for_node".ptr, c"multimap.c".ptr, (5 as c_int), c"!multimap_is_leaf(parent)".ptr)
    } else {
        0
    }

    var __local_num: c_int = ((multimap_get_num(__param_parent) as c_int))

    var __local_i: c_int = ((0 as c_int))

    while ((if __local_i <= __local_num: 1 else: 0) != 0) {
        if ((if (*(&raw const (*__param_parent).kind as *const multimap_kind_s)).node[__local_i] == __param_child: 1 else: 0) != 0) {
            return __local_i
        }


        (__local_i = __local_i + 1)

    }


    return -1

}

unsafe fn multimap_erase(__param_b: *mut multimap_s, __param_key: c_int) -> bool {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    var __local_pit: [multimap_parent_it_s; 1]

    var __local_leaf: *mut multimap_node_s = multimap_i_search_for_leaf((&__local_pit[0] as *mut multimap_parent_it_s), (&(__param_b[0]) as *mut multimap_s), __param_key)

    var __local_k: c_int = ((multimap_i_search_and_remove_in_leaf(__local_leaf, __param_key) as c_int))

    if ((if __local_k < 0: 1 else: 0) != 0) {
        return ((false as bool))
    }

    ((__param_b[0]).size = ((*(&raw const (__param_b[0]) as *const multimap_s)).size -% 1))

    var __ci_expr_logic_2: c_int

    if (((if not ((if not ((if multimap_get_num(__local_leaf) >= (5 / 2): 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return ((true as bool))
    }


    if (((if not ((if multimap_get_num(__local_leaf) == ((5 / 2) - 1): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_get_num(leaf) == 5/2-1".ptr)
    } else {
        0
    }

    var __local_pass1: bool = true

    while (1 != 0) {
        if (((if not ((if (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"pit->num > 0".ptr)
        } else {
            0
        }

        var __local_parent: *mut multimap_node_s = with 0 as __ci_expr_seq_158 {
            (__local_pit[0].num = (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num - 1)
            (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).parent[(*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num]
        }

        if (((if not ((if __local_parent != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"parent != ((void*)0)".ptr)
        } else {
            0
        }

        (__local_k = ((multimap_i_search_for_node(__local_parent, __local_leaf) as c_int)))

        if (((if not ((if __local_k >= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"k >= 0".ptr)
        } else {
            0
        }

        var __ci_expr_logic_3: c_int = 0

        if ((if __local_k > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if multimap_get_num((*(&raw const (*__local_parent).kind as *const multimap_kind_s)).node[(__local_k - 1)]) > (5 / 2): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_3 != 0) {
            multimap_i_left_shift(__local_parent, ((__local_k - 1) as c_int))

            return ((true as bool))

        }
        var __ci_expr_logic_4: c_int = 0

        if ((if __local_k < multimap_get_num(__local_parent): 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if multimap_get_num((*(&raw const (*__local_parent).kind as *const multimap_kind_s)).node[(__local_k + 1)]) > (5 / 2): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            multimap_i_right_shift(__local_parent, __local_k)

            return ((true as bool))

        }



        if ((if __local_k == multimap_get_num(__local_parent): 1 else: 0) != 0) {
            (__local_k = __local_k - 1)
        }

        var __ci_expr_logic_5: c_int = 0

        if ((if __local_k >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if __local_k < multimap_get_num(__local_parent): 1 else: 0) != 0: 1 else: 0))
        }

        if (((if not (__ci_expr_logic_5 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_erase".ptr, c"multimap.c".ptr, (5 as c_int), c"k >= 0 && k < multimap_get_num(parent)".ptr)
        } else {
            0
        }


        multimap_i_merge_node(__local_parent, __local_k, __local_pass1)

        if ((if multimap_get_num(__local_parent) >= (5 / 2): 1 else: 0) != 0) {
            return ((true as bool))
        }

        if ((if (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num == 0: 1 else: 0) != 0) {
            if ((if multimap_get_num(__local_parent) == 0: 1 else: 0) != 0) {
                ((__param_b[0]).root = (*(&raw const (*__local_parent).kind as *const multimap_kind_s)).node[0])

                with_free(((__local_parent as *mut c_void) as *mut u8))

            }

            return ((true as bool))

        }

        (__local_leaf = __local_parent)

        (__local_pass1 = false)

    }

}

unsafe fn multimap_pop_at(__param_ptr: *mut c_int, __param_b: *mut multimap_s, __param_key: c_int) -> bool {
    if ((if __param_ptr != null: 1 else: 0) != 0) {
        var __local_ref: *mut c_int = multimap_get((&(__param_b[0]) as *mut multimap_s), __param_key)

        if ((if __local_ref == null: 1 else: 0) != 0) {
            return ((false as bool))

        }

        ((*__param_ptr) = (*__local_ref))

    }

    return multimap_erase((&(__param_b[0]) as *mut multimap_s), __param_key)

}

unsafe fn multimap_min(__param_b: *mut multimap_s) -> *mut c_int {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_min".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    if (((if not ((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).size == 0: 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        return ((null as *mut c_int))
    }

    var __local_n: *mut multimap_node_s = (*(&raw const (__param_b[0]) as *const multimap_s)).root

    while ((if not multimap_is_leaf(__local_n): 1 else: 0) != 0) {
        (__local_n = (*(&raw const (*__local_n).kind as *const multimap_kind_s)).node[0])

    }

    return (((&raw const (*__local_n).kind.value[0] as *const c_int) as *mut c_int))

}

unsafe fn multimap_max(__param_b: *mut multimap_s) -> *mut c_int {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_max".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    if (((if not ((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).size == 0: 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        return ((null as *mut c_int))
    }

    var __local_n: *mut multimap_node_s = (*(&raw const (__param_b[0]) as *const multimap_s)).root

    while ((if not multimap_is_leaf(__local_n): 1 else: 0) != 0) {
        (__local_n = (*(&raw const (*__local_n).kind as *const multimap_kind_s)).node[(*__local_n).num])

    }

    return (((&raw const (*__local_n).kind.value[((0 - (*__local_n).num) - 1)] as *const c_int) as *mut c_int))

}

@[repr(C)]
pub type multimap_cmin_literal_anon = union { ptr: *mut c_int = null, cptr: *const c_int = null }
impl Copy for multimap_cmin_literal_anon
unsafe fn multimap_cmin(__param_tree: *mut multimap_s) -> *const c_int {
    return (multimap_cmin_literal_anon { ptr: multimap_min((&(__param_tree[0]) as *mut multimap_s)) } as multimap_cmin_literal_anon).cptr

}

@[repr(C)]
pub type multimap_cmax_literal_anon = union { ptr: *mut c_int = null, cptr: *const c_int = null }
impl Copy for multimap_cmax_literal_anon
unsafe fn multimap_cmax(__param_tree: *mut multimap_s) -> *const c_int {
    return (multimap_cmax_literal_anon { ptr: multimap_max((&(__param_tree[0]) as *mut multimap_s)) } as multimap_cmax_literal_anon).cptr

}

unsafe fn multimap_init_move(__param_b: *mut multimap_s, __param_ref: *mut multimap_s) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((ref)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_ref[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((ref)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_ref[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->key[i2-1]) < (((ref)->root+0)->key[i2]) ? -1 : (((ref)->root+0)->key[i2-1]) > (((ref)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->key[num2-1]) < (((ref)->root+0)->next->key[0]) ? -1 : (((ref)->root+0)->key[num2-1]) > (((ref)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->prev->key[num_prev-1]) < (((ref)->root+0)->key[0]) ? -1 : (((ref)->root+0)->prev->key[num_prev-1]) > (((ref)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_ref[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(ref)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_ref[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(ref)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_ref[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_ref[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_ref[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"-(ref)->root->num == (int) (ref)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    var __ci_expr_logic_2: c_int = 0

    if ((if (&(__param_b[0]) as *mut c_void) != null: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if (&(__param_b[0]) as *mut multimap_s) != (&(__param_ref[0]) as *mut multimap_s): 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"b != ((void*)0) && b != ref".ptr)
    } else {
        0
    }


    ((__param_b[0]).size = (*(&raw const (__param_ref[0]) as *const multimap_s)).size)

    ((__param_b[0]).root = (*(&raw const (__param_ref[0]) as *const multimap_s)).root)

    ((__param_ref[0]).root = ((null as *mut multimap_node_s)))

    ((__param_ref[0]).size = ((1 as c_ulong)))

    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if (if __local_num2_1 < 0: 1 else: 0) != 0: ((0 - __local_num2_1) as c_int) else: __local_num2_1) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_3: c_int = 0

                if ((if 0 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_1 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_1: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_4: c_int = 0

                if ((if __local_c2_1 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_4 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: c_int = ((1 as c_int))

            while ((if __local_i2_1 < __local_num2_1: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_1 = (((if (if __local_num_prev_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_1) as c_int) else: __local_num_prev_1) as c_int)))

                if (((if not ((if __local_num_prev_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_init_move".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

}

unsafe fn multimap_move(__param_b: *mut multimap_s, __param_ref: *mut multimap_s) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((ref)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_ref[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((ref)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: c_int = ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if (if __local_num2_1 < 0: 1 else: 0) != 0: ((0 - __local_num2_1) as c_int) else: __local_num2_1) as c_int)))

            if ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_ref[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_2: c_int = 0

                if ((if 0 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_1 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_1: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: c_int = 0

                if ((if __local_c2_1 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: c_int = ((1 as c_int))

            while ((if __local_i2_1 < __local_num2_1: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] < ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] > ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->key[i2-1]) < (((ref)->root+0)->key[i2]) ? -1 : (((ref)->root+0)->key[i2-1]) > (((ref)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] < (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] > (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->key[num2-1]) < (((ref)->root+0)->next->key[0]) ? -1 : (((ref)->root+0)->key[num2-1]) > (((ref)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: c_int = (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_1 = (((if (if __local_num_prev_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_1) as c_int) else: __local_num_prev_1) as c_int)))

                if (((if not ((if __local_num_prev_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] < ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] > ((*(&raw const (__param_ref[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->prev->key[num_prev-1]) < (((ref)->root+0)->key[0]) ? -1 : (((ref)->root+0)->prev->key[num_prev-1]) > (((ref)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_ref[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(ref)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_ref[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(ref)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_ref[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_ref[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_ref[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"-(ref)->root->num == (int) (ref)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    if (((if not ((if (&(__param_b[0]) as *mut multimap_s) != (&(__param_ref[0]) as *mut multimap_s): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"b != ref".ptr)
    } else {
        0
    }

    multimap_clear((&(__param_b[0]) as *mut multimap_s))

    multimap_init_move((&(__param_b[0]) as *mut multimap_s), (&(__param_ref[0]) as *mut multimap_s))

    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_2: bool = ((__local_num2_2 <= 0))

            (__local_num2_2 = (((if (if __local_num2_2 < 0: 1 else: 0) != 0: ((0 - __local_num2_2) as c_int) else: __local_num2_2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_4: c_int = 0

                if ((if 0 <= __local_num2_2: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if (if __local_num2_2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_4 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_5: c_int = 0

                if ((if __local_c2_2 <= __local_num2_2: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if (if __local_num2_2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_5 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_2: c_int = ((1 as c_int))

            while ((if __local_i2_2 < __local_num2_2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_2 = __local_i2_2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_2: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_2 = (((if (if __local_num_prev_2 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_2) as c_int) else: __local_num_prev_2) as c_int)))

                if (((if not ((if __local_num_prev_2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_move".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

}

unsafe fn multimap_set(__param_b: *mut multimap_s, __param_o: *mut multimap_s) {
    var __local_tmp: [multimap_s; 1]

    var __local_cont: bool = true

    while __local_cont {
        multimap_init_set((&__local_tmp[0] as *mut multimap_s), (&(__param_o[0]) as *mut multimap_s))

        multimap_move((&(__param_b[0]) as *mut multimap_s), (&__local_tmp[0] as *mut multimap_s))


        (__local_cont = false)

    }


}

unsafe fn multimap_swap(__param_tree1: *mut multimap_s, __param_tree2: *mut multimap_s) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"((tree1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_tree1[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"((tree1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree1[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->key[i2-1]) < (((tree1)->root+0)->key[i2]) ? -1 : (((tree1)->root+0)->key[i2-1]) > (((tree1)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->key[num2-1]) < (((tree1)->root+0)->next->key[0]) ? -1 : (((tree1)->root+0)->key[num2-1]) > (((tree1)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->prev->key[num_prev-1]) < (((tree1)->root+0)->key[0]) ? -1 : (((tree1)->root+0)->prev->key[num_prev-1]) > (((tree1)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_tree1[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(tree1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_tree1[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(tree1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_tree1[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_tree1[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_tree1[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"-(tree1)->root->num == (int) (tree1)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"((tree2)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_tree2[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"((tree2)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: c_int = ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if (if __local_num2_1 < 0: 1 else: 0) != 0: ((0 - __local_num2_1) as c_int) else: __local_num2_1) as c_int)))

            if ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree2[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_2: c_int = 0

                if ((if 0 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_1 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_1: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: c_int = 0

                if ((if __local_c2_1 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: c_int = ((1 as c_int))

            while ((if __local_i2_1 < __local_num2_1: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] < ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] > ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->key[i2-1]) < (((tree2)->root+0)->key[i2]) ? -1 : (((tree2)->root+0)->key[i2-1]) > (((tree2)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] < (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] > (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->key[num2-1]) < (((tree2)->root+0)->next->key[0]) ? -1 : (((tree2)->root+0)->key[num2-1]) > (((tree2)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: c_int = (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_1 = (((if (if __local_num_prev_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_1) as c_int) else: __local_num_prev_1) as c_int)))

                if (((if not ((if __local_num_prev_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] < ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] > ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->prev->key[num_prev-1]) < (((tree2)->root+0)->key[0]) ? -1 : (((tree2)->root+0)->prev->key[num_prev-1]) > (((tree2)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_tree2[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(tree2)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_tree2[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(tree2)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_tree2[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_tree2[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_tree2[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"-(tree2)->root->num == (int) (tree2)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    loop {
        var __local__tmp: c_ulong = (*(&raw const (__param_tree1[0]) as *const multimap_s)).size

        ((__param_tree1[0]).size = (*(&raw const (__param_tree2[0]) as *const multimap_s)).size)

        ((__param_tree2[0]).size = __local__tmp)

        if not ((0 != 0)) {
            break
        }
    }

    loop {
        var __local__tmp_1: *mut multimap_node_s = (*(&raw const (__param_tree1[0]) as *const multimap_s)).root

        ((__param_tree1[0]).root = (*(&raw const (__param_tree2[0]) as *const multimap_s)).root)

        ((__param_tree2[0]).root = __local__tmp_1)

        if not ((0 != 0)) {
            break
        }
    }

    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"((tree1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_tree1[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"((tree1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_2: c_int = ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_2: bool = ((__local_num2_2 <= 0))

            (__local_num2_2 = (((if (if __local_num2_2 < 0: 1 else: 0) != 0: ((0 - __local_num2_2) as c_int) else: __local_num2_2) as c_int)))

            if ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree1[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_4: c_int = 0

                if ((if 0 <= __local_num2_2: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if (if __local_num2_2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_4 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_5: c_int = 0

                if ((if __local_c2_2 <= __local_num2_2: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if (if __local_num2_2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_5 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_2: c_int = ((1 as c_int))

            while ((if __local_i2_2 < __local_num2_2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_2 - 1)] < ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_2 - 1)] > ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->key[i2-1]) < (((tree1)->root+0)->key[i2]) ? -1 : (((tree1)->root+0)->key[i2-1]) > (((tree1)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_2 = __local_i2_2 + 1)

            }


            if ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_2 - 1)] < (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_2 - 1)] > (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->key[num2-1]) < (((tree1)->root+0)->next->key[0]) ? -1 : (((tree1)->root+0)->key[num2-1]) > (((tree1)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_2: c_int = (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_2 = (((if (if __local_num_prev_2 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_2) as c_int) else: __local_num_prev_2) as c_int)))

                if (((if not ((if __local_num_prev_2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_2 - 1)] < ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_2 - 1)] > ((*(&raw const (__param_tree1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->prev->key[num_prev-1]) < (((tree1)->root+0)->key[0]) ? -1 : (((tree1)->root+0)->prev->key[num_prev-1]) > (((tree1)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_tree1[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(tree1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_tree1[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(tree1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_tree1[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_tree1[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_tree1[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"-(tree1)->root->num == (int) (tree1)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"((tree2)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_tree2[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"((tree2)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_3: c_int = ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_3: bool = ((__local_num2_3 <= 0))

            (__local_num2_3 = (((if (if __local_num2_3 < 0: 1 else: 0) != 0: ((0 - __local_num2_3) as c_int) else: __local_num2_3) as c_int)))

            if ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree2[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_6: c_int = 0

                if ((if 0 <= __local_num2_3: 1 else: 0) != 0) {
                    (__ci_expr_logic_6 = (if (if __local_num2_3 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_6 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_3 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_3: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_3: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_3 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_7: c_int = 0

                if ((if __local_c2_3 <= __local_num2_3: 1 else: 0) != 0) {
                    (__ci_expr_logic_7 = (if (if __local_num2_3 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_7 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_3: c_int = ((1 as c_int))

            while ((if __local_i2_3 < __local_num2_3: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_3 - 1)] < ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_3]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_3 - 1)] > ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_3]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->key[i2-1]) < (((tree2)->root+0)->key[i2]) ? -1 : (((tree2)->root+0)->key[i2-1]) > (((tree2)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_3 = __local_i2_3 + 1)

            }


            if ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_3 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_3 - 1)] < (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_3 - 1)] > (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->key[num2-1]) < (((tree2)->root+0)->next->key[0]) ? -1 : (((tree2)->root+0)->key[num2-1]) > (((tree2)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_3 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_3: c_int = (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_3 = (((if (if __local_num_prev_3 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_3) as c_int) else: __local_num_prev_3) as c_int)))

                if (((if not ((if __local_num_prev_3 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_3 - 1)] < ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_3 - 1)] > ((*(&raw const (__param_tree2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->prev->key[num_prev-1]) < (((tree2)->root+0)->key[0]) ? -1 : (((tree2)->root+0)->prev->key[num_prev-1]) > (((tree2)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_tree2[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(tree2)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_tree2[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"(tree2)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_tree2[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_tree2[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_tree2[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_swap".ptr, c"multimap.c".ptr, (5 as c_int), c"-(tree2)->root->num == (int) (tree2)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

}

unsafe fn multimap_it(__param_it_: *mut multimap_it_s, __param_b: *mut multimap_s) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    if (((if not ((if (&(__param_it_[0]) as *mut c_void) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_it".ptr, c"multimap.c".ptr, (5 as c_int), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut multimap_node_s = (*(&raw const (__param_b[0]) as *const multimap_s)).root

    while ((if not multimap_is_leaf(__local_n): 1 else: 0) != 0) {
        (__local_n = (*(&raw const (*__local_n).kind as *const multimap_kind_s)).node[0])

    }

    ((__param_it_[0]).node = __local_n)

    ((__param_it_[0]).idx = ((0 as c_int)))

}

unsafe fn multimap_it_end(__param_it_: *mut multimap_it_s, __param_b: *mut multimap_s) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    if (((if not ((if (&(__param_it_[0]) as *mut c_void) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_it_end".ptr, c"multimap.c".ptr, (5 as c_int), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut multimap_node_s = (*(&raw const (__param_b[0]) as *const multimap_s)).root

    while ((if not multimap_is_leaf(__local_n): 1 else: 0) != 0) {
        (__local_n = (*(&raw const (*__local_n).kind as *const multimap_kind_s)).node[(*__local_n).num])

    }

    ((__param_it_[0]).node = __local_n)

    ((__param_it_[0]).idx = (((0 - (*__local_n).num) as c_int)))

}

unsafe fn multimap_it_set(__param_itd: *mut multimap_it_s, __param_its: *mut multimap_it_s) {
    var __ci_expr_logic_0: c_int = 0

    if ((if (&(__param_itd[0]) as *mut c_void) != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (&(__param_its[0]) as *mut c_void) != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_it_set".ptr, c"multimap.c".ptr, (5 as c_int), c"itd != ((void*)0) && its != ((void*)0)".ptr)
    } else {
        0
    }


    ((__param_itd[0]).node = (*(&raw const (__param_its[0]) as *const multimap_it_s)).node)

    ((__param_itd[0]).idx = (*(&raw const (__param_its[0]) as *const multimap_it_s)).idx)

}

unsafe fn multimap_end_p(__param_it_: *mut multimap_it_s) -> bool {
    var __ci_expr_logic_0: c_int = 0

    if ((if (&(__param_it_[0]) as *mut c_void) != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_end_p".ptr, c"multimap.c".ptr, (5 as c_int), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
    } else {
        0
    }


    if (((if not multimap_is_leaf((*(&raw const (__param_it_[0]) as *const multimap_it_s)).node): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_end_p".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_is_leaf(it->node)".ptr)
    } else {
        0
    }

    return (((((((*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx as c_uint)) >= (((0 - (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).num) as c_uint)))) as bool))

}

unsafe fn multimap_it_equal_p(__param_it1: *mut multimap_it_s, __param_it2: *mut multimap_it_s) -> bool {
    var __ci_expr_logic_0: c_int = 0

    if ((if (*(&raw const (__param_it1[0]) as *const multimap_it_s)).node == (*(&raw const (__param_it2[0]) as *const multimap_it_s)).node: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const (__param_it1[0]) as *const multimap_it_s)).idx == (*(&raw const (__param_it2[0]) as *const multimap_it_s)).idx: 1 else: 0) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

unsafe fn multimap_next(__param_it_: *mut multimap_it_s) {
    var __ci_expr_logic_0: c_int = 0

    if ((if (&(__param_it_[0]) as *mut c_void) != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_next".ptr, c"multimap.c".ptr, (5 as c_int), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
    } else {
        0
    }


    if (((if not multimap_is_leaf((*(&raw const (__param_it_[0]) as *const multimap_it_s)).node): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_next".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_is_leaf(it->node)".ptr)
    } else {
        0
    }

    ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx + 1)

    var __ci_expr_logic_1: c_int = 0

    if ((if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx >= (0 - (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).num): 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).next != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        ((__param_it_[0]).node = (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).next)

        ((__param_it_[0]).idx = ((0 as c_int)))

    }


}

unsafe fn multimap_previous(__param_it_: *mut multimap_it_s) {
    var __ci_expr_logic_0: c_int = 0

    if ((if (&(__param_it_[0]) as *mut c_void) != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_previous".ptr, c"multimap.c".ptr, (5 as c_int), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
    } else {
        0
    }


    if (((if not multimap_is_leaf((*(&raw const (__param_it_[0]) as *const multimap_it_s)).node): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_previous".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_is_leaf(it->node)".ptr)
    } else {
        0
    }

    ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx - 1)

    var __ci_expr_logic_1: c_int = 0

    if ((if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx < 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).prev != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        ((__param_it_[0]).node = (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).prev)

        ((__param_it_[0]).idx = ((((0 - (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).num) - 1) as c_int)))

    }


}

unsafe fn multimap_it_last(__param_it_: *mut multimap_it_s, __param_b: *mut multimap_s) {
    multimap_it_end((&(__param_it_[0]) as *mut multimap_it_s), (&(__param_b[0]) as *mut multimap_s))

    multimap_previous((&(__param_it_[0]) as *mut multimap_it_s))

}

unsafe fn multimap_ref(__param_it_: *mut multimap_it_s) -> *mut multimap_pair_s {
    var __ci_expr_logic_0: c_int = 0

    if ((if (&(__param_it_[0]) as *mut c_void) != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_ref".ptr, c"multimap.c".ptr, (5 as c_int), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
    } else {
        0
    }


    if (((if not multimap_is_leaf((*(&raw const (__param_it_[0]) as *const multimap_it_s)).node): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_ref".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_is_leaf(it->node)".ptr)
    } else {
        0
    }

    var __ci_expr_logic_1: c_int = 0

    if ((if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx >= 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx <= (0 - (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).num): 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_ref".ptr, c"multimap.c".ptr, (5 as c_int), c"it->idx >= 0 && it->idx <= -it->node->num".ptr)
    } else {
        0
    }


    ((__param_it_[0]).pair.key_ptr = (((&raw const (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).key[(*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx] as *const c_int) as *mut c_int)))

    ((__param_it_[0]).pair.value_ptr = (((&raw const (*(*(&raw const (__param_it_[0]) as *const multimap_it_s)).node).kind.value[(*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx] as *const c_int) as *mut c_int)))

    return (((&raw const (*(&raw const (__param_it_[0]) as *const multimap_it_s)).pair as *const multimap_pair_s) as *mut multimap_pair_s))

}

@[repr(C)]
pub type multimap_cref_literal_anon = union { ptr: *mut multimap_pair_s = null, cptr: *const multimap_pair_s = null }
impl Copy for multimap_cref_literal_anon
unsafe fn multimap_cref(__param_it_: *mut multimap_it_s) -> *const multimap_pair_s {
    return (multimap_cref_literal_anon { ptr: multimap_ref((&(__param_it_[0]) as *mut multimap_it_s)) } as multimap_cref_literal_anon).cptr

}

unsafe fn multimap_it_from(__param_it_: *mut multimap_it_s, __param_b: *mut multimap_s, __param_key: c_int) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    if (((if not ((if (&(__param_it_[0]) as *mut c_void) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_pit: [multimap_parent_it_s; 1]

    var __local_n: *mut multimap_node_s = multimap_i_search_for_leaf((&__local_pit[0] as *mut multimap_parent_it_s), (&(__param_b[0]) as *mut multimap_s), __param_key)

    ((__param_it_[0]).node = __local_n)

    var __local_i: c_int

    loop {
        if (((if not ((if __local_n != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(n) != ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_num2_1: c_int = (*__local_n).num

        var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

        (__local_num2_1 = (((if (if __local_num2_1 < 0: 1 else: 0) != 0: ((0 - __local_num2_1) as c_int) else: __local_num2_1) as c_int)))

        if ((if __local_n == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            var __ci_expr_logic_2: c_int = 0

            if ((if 0 <= __local_num2_1: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
            }

            if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
            } else {
                0
            }


            if ((if __local_num2_1 == 0: 1 else: 0) != 0) {
                if (((if not __local_is_leaf2_1: 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                } else {
                    0
                }
            }

        } else {
            var __local_c2_1: c_int = (((5 / 2) as c_int))

            if (((if not ((if __local_c2_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_3: c_int = 0

            if ((if __local_c2_1 <= __local_num2_1: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
            }

            if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
            } else {
                0
            }


        }

        var __local_i2_1: c_int = ((1 as c_int))

        while ((if __local_i2_1 < __local_num2_1: 1 else: 0) != 0) {
            if (((if not ((if (if (if (*__local_n).key[(__local_i2_1 - 1)] < (*__local_n).key[__local_i2_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(__local_i2_1 - 1)] > (*__local_n).key[__local_i2_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[i2-1]) < ((n)->key[i2]) ? -1 : ((n)->key[i2-1]) > ((n)->key[i2])) <= 0".ptr)
            } else {
                0
            }


            (__local_i2_1 = __local_i2_1 + 1)

        }


        if ((if (*__local_n).next != null: 1 else: 0) != 0) {
            if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
            } else {
                0
            }

            if (((if not ((if (if (if (*__local_n).key[(__local_num2_1 - 1)] < (*(*__local_n).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(__local_num2_1 - 1)] > (*(*__local_n).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[num2-1]) < ((n)->next->key[0]) ? -1 : ((n)->key[num2-1]) > ((n)->next->key[0])) <= 0".ptr)
            } else {
                0
            }

        }

        if ((if (*__local_n).prev != null: 1 else: 0) != 0) {
            if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
            } else {
                0
            }

            var __local_num_prev_1: c_int = (*(*__local_n).prev).num

            (__local_num_prev_1 = (((if (if __local_num_prev_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_1) as c_int) else: __local_num_prev_1) as c_int)))

            if (((if not ((if __local_num_prev_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
            } else {
                0
            }

            if (((if not ((if (if (if (*(*__local_n).prev).key[(__local_num_prev_1 - 1)] < (*__local_n).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*(*__local_n).prev).key[(__local_num_prev_1 - 1)] > (*__local_n).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_it_from".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->prev->key[num_prev-1]) < ((n)->key[0]) ? -1 : ((n)->prev->key[num_prev-1]) > ((n)->key[0])) <= 0".ptr)
            } else {
                0
            }

        }

        if not ((0 != 0)) {
            break
        }
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < (0 - (*__local_n).num): 1 else: 0) != 0) {
        if ((if (if (if __param_key < (*__local_n).key[__local_i]: 1 else: 0) != 0: (-1 as c_int) else: ((if __param_key > (*__local_n).key[__local_i]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0) {
            break
        }


        (__local_i = __local_i + 1)

    }


    var __ci_expr_logic_4: c_int = 0

    if ((if __local_i == (0 - (*__local_n).num): 1 else: 0) != 0) {
        (__ci_expr_logic_4 = (if (if (*__local_n).next != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        ((__param_it_[0]).node = (*__local_n).next)

        (__local_i = ((0 as c_int)))

    }


    ((__param_it_[0]).idx = __local_i)

}

unsafe fn multimap_it_until_p(__param_it_: *mut multimap_it_s, __param_key: c_int) -> bool {
    if (((if not ((if (&(__param_it_[0]) as *mut c_void) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_it_until_p".ptr, c"multimap.c".ptr, (5 as c_int), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut multimap_node_s = (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node

    if ((if (((*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx as c_uint)) >= (((0 - (*__local_n).num) as c_uint)): 1 else: 0) != 0) {
        return (((((*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx >= 0)) as bool))
    }

    var __local_cmp: c_int

    (__local_cmp = (((if (if (*__local_n).key[(*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx] < __param_key: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx] > __param_key: 1 else: 0) as c_int)) as c_int)))


    return ((((__local_cmp >= 0)) as bool))

}

unsafe fn multimap_it_while_p(__param_it_: *mut multimap_it_s, __param_key: c_int) -> bool {
    if (((if not ((if (&(__param_it_[0]) as *mut c_void) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_it_while_p".ptr, c"multimap.c".ptr, (5 as c_int), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut multimap_node_s = (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node

    if ((if (((*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx as c_uint)) >= (((0 - (*__local_n).num) as c_uint)): 1 else: 0) != 0) {
        return (((((*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx < 0)) as bool))
    }

    var __local_cmp: c_int

    (__local_cmp = (((if (if (*__local_n).key[(*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx] < __param_key: 1 else: 0) != 0: (-1 as c_int) else: ((if (*__local_n).key[(*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx] > __param_key: 1 else: 0) as c_int)) as c_int)))


    return ((((__local_cmp <= 0)) as bool))

}

unsafe fn multimap_remove(__param_b: *mut multimap_s, __param_it_: *mut multimap_it_s) {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_b[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_b[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_b[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_b[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    var __local_n: *mut multimap_node_s = (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node

    if (((if not ((if (*__local_n).num < 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"n->num < 0".ptr)
    } else {
        0
    }

    var __local_i: c_int = (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx

    var __local_num: c_int = ((multimap_get_num(__local_n) as c_int))

    var __ci_expr_logic_2: c_int = 0

    if ((if __local_i >= 0: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if __local_i < __local_num: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"i >= 0 && i < num".ptr)
    } else {
        0
    }


    var __local_pit: [multimap_parent_it_s; 1]

    var __local_leaf: *mut multimap_node_s = multimap_i_search_for_leaf((&__local_pit[0] as *mut multimap_parent_it_s), (&(__param_b[0]) as *mut multimap_s), ((*__local_n).key[__local_i] as c_int))



    with_memmove(((((&raw const (*__local_n).key[__local_i] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_n).key[(__local_i + 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((((__local_num - 1) - __local_i) as c_uint) as c_ulong)) as c_ulong) as i64))

    with_memmove(((((&raw const (*__local_n).kind.value[__local_i] as *const c_int) as *mut c_int) as *mut c_void) as *mut u8), ((((&raw const (*__local_n).kind.value[(__local_i + 1)] as *const c_int) as *mut c_int) as *const c_void) as *const u8), ((((4 as c_ulong) *% ((((__local_num - 1) - __local_i) as c_uint) as c_ulong)) as c_ulong) as i64))

    ((*__local_n).num = (*__local_n).num - -1)

    ((__param_b[0]).size = ((*(&raw const (__param_b[0]) as *const multimap_s)).size -% 1))

    var __ci_expr_logic_3: c_int = 0

    if ((if __local_i >= (__local_num - 1): 1 else: 0) != 0) {
        (__ci_expr_logic_3 = (if (if (*__local_n).next != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not ((if not (__ci_expr_logic_3 != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        ((__param_it_[0]).node = (*__local_n).next)

        ((__param_it_[0]).idx = ((0 as c_int)))

    }


    var __ci_expr_logic_4: c_int

    if (((if not ((if not ((if multimap_get_num(__local_n) >= (5 / 2): 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_4 = (if (if (*(&raw const (__param_b[0]) as *const multimap_s)).root == __local_n: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        return
    }


    while (((if not ((if not ((if __local_n != __local_leaf: 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        if (((if not ((if (*__local_leaf).next != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"leaf->next != ((void*)0)".ptr)
        } else {
            0
        }

        (__local_leaf = (*__local_leaf).next)

        var __local_p_num: c_int = (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num

        var __local_p_n: *mut multimap_node_s = __local_leaf

        loop {
            if (((if not ((if __local_p_num >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"p_num >= 1".ptr)
            } else {
                0
            }

            var __local_parent: *mut multimap_node_s = with 0 as __ci_expr_seq_208 {
                (__local_p_num = __local_p_num - 1)
                (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).parent[__local_p_num]
            }

            var __local_k: c_int = ((multimap_i_search_for_node(__local_parent, __local_p_n) as c_int))

            if ((if __local_k >= 0: 1 else: 0) != 0) {
                break
            }

            (__local_pit[0].parent[__local_p_num] = (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).parent[__local_p_num].next)

            (__local_p_n = (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).parent[__local_p_num])

            if not ((1 != 0)) {
                break
            }
        }

    }

    if (((if not ((if multimap_get_num(__local_leaf) == ((5 / 2) - 1): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"multimap_get_num(leaf) == 5/2-1".ptr)
    } else {
        0
    }

    var __local_pass1: bool = true

    while (1 != 0) {
        if (((if not ((if (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"pit->num > 0".ptr)
        } else {
            0
        }

        var __local_parent_1: *mut multimap_node_s = with 0 as __ci_expr_seq_225 {
            (__local_pit[0].num = (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num - 1)
            (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).parent[(*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num]
        }

        if (((if not ((if __local_parent_1 != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"parent != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_k_1: c_int = ((multimap_i_search_for_node(__local_parent_1, __local_leaf) as c_int))

        if (((if not ((if __local_k_1 >= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"k >= 0".ptr)
        } else {
            0
        }

        var __ci_expr_logic_5: c_int = 0

        if ((if __local_k_1 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if multimap_get_num((*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[(__local_k_1 - 1)]) > (5 / 2): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            multimap_i_left_shift(__local_parent_1, ((__local_k_1 - 1) as c_int))

            if ((if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[__local_k_1]: 1 else: 0) != 0) {
                ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx + 1)

            } else {
                if ((if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[(__local_k_1 - 1)]: 1 else: 0) != 0) {
                    if ((if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx >= multimap_get_num((*(&raw const (__param_it_[0]) as *const multimap_it_s)).node): 1 else: 0) != 0) {
                        ((__param_it_[0]).idx = ((0 as c_int)))

                        ((__param_it_[0]).node = (*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[(__local_k_1 - 1)])

                    }

                }
            }

            return

        }
        var __ci_expr_logic_6: c_int = 0

        if ((if __local_k_1 < multimap_get_num(__local_parent_1): 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if multimap_get_num((*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[(__local_k_1 + 1)]) > (5 / 2): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            multimap_i_right_shift(__local_parent_1, __local_k_1)

            if ((if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[(__local_k_1 + 1)]: 1 else: 0) != 0) {
                if ((if (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx == 0: 1 else: 0) != 0) {
                    ((__param_it_[0]).node = (*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[__local_k_1])

                    ((__param_it_[0]).idx = (((multimap_get_num((*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[__local_k_1]) - 1) as c_int)))

                } else {
                    ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx - 1)

                }

            }

            return

        }



        if ((if __local_k_1 == multimap_get_num(__local_parent_1): 1 else: 0) != 0) {
            (__local_k_1 = __local_k_1 - 1)
        }

        var __ci_expr_logic_7: c_int = 0

        if ((if __local_k_1 >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if (if __local_k_1 < multimap_get_num(__local_parent_1): 1 else: 0) != 0: 1 else: 0))
        }

        if (((if not (__ci_expr_logic_7 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_remove".ptr, c"multimap.c".ptr, (5 as c_int), c"k >= 0 && k < multimap_get_num(parent)".ptr)
        } else {
            0
        }


        (__local_num = ((multimap_get_num((*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[__local_k_1]) as c_int)))

        var __local_it_to_fix: bool = (((*(&raw const (__param_it_[0]) as *const multimap_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[(__local_k_1 + 1)]))

        multimap_i_merge_node(__local_parent_1, __local_k_1, __local_pass1)

        if __local_it_to_fix {
            ((__param_it_[0]).node = (*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[__local_k_1])

            ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const multimap_it_s)).idx + __local_num)

        }

        if ((if multimap_get_num(__local_parent_1) >= (5 / 2): 1 else: 0) != 0) {
            return
        }

        if ((if (*(&raw const __local_pit[0] as *const multimap_parent_it_s)).num == 0: 1 else: 0) != 0) {
            if ((if multimap_get_num(__local_parent_1) == 0: 1 else: 0) != 0) {
                ((__param_b[0]).root = (*(&raw const (*__local_parent_1).kind as *const multimap_kind_s)).node[0])

                with_free(((__local_parent_1 as *mut c_void) as *mut u8))

            }

            return

        }

        (__local_leaf = __local_parent_1)

        (__local_pass1 = false)

    }

}

unsafe fn multimap_equal_p(__param_t1: *mut multimap_s, __param_t2: *mut multimap_s) -> bool {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_t1[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t1[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[i2-1]) < (((t1)->root+0)->key[i2]) ? -1 : (((t1)->root+0)->key[i2-1]) > (((t1)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[num2-1]) < (((t1)->root+0)->next->key[0]) ? -1 : (((t1)->root+0)->key[num2-1]) > (((t1)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->prev->key[num_prev-1]) < (((t1)->root+0)->key[0]) ? -1 : (((t1)->root+0)->prev->key[num_prev-1]) > (((t1)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_t1[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"-(t1)->root->num == (int) (t1)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"((t2)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_t2[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"((t2)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: c_int = ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if (if __local_num2_1 < 0: 1 else: 0) != 0: ((0 - __local_num2_1) as c_int) else: __local_num2_1) as c_int)))

            if ((if ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t2[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_2: c_int = 0

                if ((if 0 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_1 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_1: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: c_int = 0

                if ((if __local_c2_1 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: c_int = ((1 as c_int))

            while ((if __local_i2_1 < __local_num2_1: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] < ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] > ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t2)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t2)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t2)->root+0)->key[i2-1]) < (((t2)->root+0)->key[i2]) ? -1 : (((t2)->root+0)->key[i2-1]) > (((t2)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((if ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] < (*((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] > (*((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t2)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t2)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t2)->root+0)->key[num2-1]) < (((t2)->root+0)->next->key[0]) ? -1 : (((t2)->root+0)->key[num2-1]) > (((t2)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: c_int = (*((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_1 = (((if (if __local_num_prev_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_1) as c_int) else: __local_num_prev_1) as c_int)))

                if (((if not ((if __local_num_prev_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] < ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] > ((*(&raw const (__param_t2[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t2)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t2)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t2)->root+0)->prev->key[num_prev-1]) < (((t2)->root+0)->key[0]) ? -1 : (((t2)->root+0)->prev->key[num_prev-1]) > (((t2)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_t2[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(t2)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_t2[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"(t2)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_t2[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_t2[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_t2[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_equal_p".ptr, c"multimap.c".ptr, (5 as c_int), c"-(t2)->root->num == (int) (t2)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    if ((if (*(&raw const (__param_t1[0]) as *const multimap_s)).size != (*(&raw const (__param_t2[0]) as *const multimap_s)).size: 1 else: 0) != 0) {
        return ((false as bool))
    }

    if ((if (*(&raw const (__param_t1[0]) as *const multimap_s)).size == 0: 1 else: 0) != 0) {
        return ((true as bool))
    }

    var __local_it1: [multimap_it_s; 1]

    var __local_it2: [multimap_it_s; 1]

    multimap_it((&__local_it1[0] as *mut multimap_it_s), (&(__param_t1[0]) as *mut multimap_s))

    multimap_it((&__local_it2[0] as *mut multimap_it_s), (&(__param_t2[0]) as *mut multimap_s))

    while true {
        var __ci_expr_logic_4: c_int = 0

        if ((if not multimap_end_p((&__local_it1[0] as *mut multimap_it_s)): 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if not multimap_end_p((&__local_it2[0] as *mut multimap_it_s)): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_4 != 0)) {
            break
        }

        var __local_ref1: *const multimap_pair_s = multimap_cref((&__local_it1[0] as *mut multimap_it_s))

        var __local_ref2: *const multimap_pair_s = multimap_cref((&__local_it2[0] as *mut multimap_it_s))

        if ((if not ((if (*((*__local_ref1).key_ptr)) == (*((*__local_ref2).key_ptr)): 1 else: 0) != 0): 1 else: 0) != 0) {
            return ((false as bool))
        }

        if ((if not ((if (*((*__local_ref1).value_ptr)) == (*((*__local_ref2).value_ptr)): 1 else: 0) != 0): 1 else: 0) != 0) {
            return ((false as bool))
        }

        multimap_next((&__local_it1[0] as *mut multimap_it_s))

        multimap_next((&__local_it2[0] as *mut multimap_it_s))

    }

    var __ci_expr_logic_5: c_int = 0

    if (multimap_end_p((&__local_it1[0] as *mut multimap_it_s)) != 0) {
        (__ci_expr_logic_5 = (if multimap_end_p((&__local_it2[0] as *mut multimap_it_s)) != 0: 1 else: 0))
    }

    return (((__ci_expr_logic_5 != 0) as bool))


}

unsafe fn multimap_hash(__param_t1: *mut multimap_s) -> c_ulong {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_t1[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t1[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[i2-1]) < (((t1)->root+0)->key[i2]) ? -1 : (((t1)->root+0)->key[i2-1]) > (((t1)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[num2-1]) < (((t1)->root+0)->next->key[0]) ? -1 : (((t1)->root+0)->key[num2-1]) > (((t1)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->prev->key[num_prev-1]) < (((t1)->root+0)->key[0]) ? -1 : (((t1)->root+0)->prev->key[num_prev-1]) > (((t1)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_t1[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_hash".ptr, c"multimap.c".ptr, (5 as c_int), c"-(t1)->root->num == (int) (t1)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    var __local_hash: c_ulong = ((((0 as c_ulong) ^ (0 as c_ulong)) as c_ulong))

    var __local_it1: [multimap_it_s; 1]

    multimap_it((&__local_it1[0] as *mut multimap_it_s), (&(__param_t1[0]) as *mut multimap_s))

    while ((if not multimap_end_p((&__local_it1[0] as *mut multimap_it_s)): 1 else: 0) != 0) {
        var __local_ref1: *const multimap_pair_s = multimap_cref((&__local_it1[0] as *mut multimap_it_s))

        loop {
            (__local_hash = ((((((__local_hash as c_ulong) *% (2166136261 as c_ulong)) as c_ulong) ^ ((((((*((*__local_ref1).key_ptr)) as c_uint) ^ ((((*((*__local_ref1).key_ptr)) as c_uint) << (11 as c_uint)) as c_uint)) as c_ulong) ^ (0 as c_ulong)) as c_ulong)) as c_ulong)))

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            (__local_hash = ((((((__local_hash as c_ulong) *% (2166136261 as c_ulong)) as c_ulong) ^ ((((((*((*__local_ref1).value_ptr)) as c_uint) ^ ((((*((*__local_ref1).value_ptr)) as c_uint) << (11 as c_uint)) as c_uint)) as c_ulong) ^ (0 as c_ulong)) as c_ulong)) as c_ulong)))

            if not ((0 != 0)) {
                break
            }
        }

        multimap_next((&__local_it1[0] as *mut multimap_it_s))

    }

    return ((((__local_hash as c_ulong) >> (((((sizeof[c_ulong]() as c_ulong) *% (8 as c_ulong)) as c_ulong) / (2 as c_ulong)) as c_uint)) as c_ulong) ^ (__local_hash as c_ulong))

}

unsafe fn multimap_parse_str(__param_t1: *mut multimap_s, __param_str: *mut c_char, __param_endp: *mut *const i8) -> bool {
    var __local_str = __param_str
    var __local_num2__goto_5_1: c_int = 0

    var __local_is_leaf2__goto_5_1: bool = false

    var __local_c2__goto_5_1: c_int = 0

    var __local_i2__goto_5_1: c_int = 0

    var __local_num_prev__goto_5_1: c_int = 0

    var __local_c__goto_5_1: c_int = 0

    var __local__local_cont_key5__goto_5_1: bool = false

    var __local_key__goto_5_1: c_int = 0

    var __local__local_cont_value5__goto_5_1: bool = false

    var __local_value__goto_5_1: c_int = 0

    var __local_b__goto_5_1: bool = false

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_old_2: *mut c_char = null

    var __ci_expr_old_3: *mut c_char = null

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_logic_8: c_int = 0

    var __ci_expr_logic_9: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        goto '__ci_bb_4
    }

    '__ci_bb_2 {
        if (0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        if (((if not ((if (&(__local_str[0]) as *mut c_void) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"str != ((void*)0)".ptr)
        } else {
            0
        }
        multimap_reset((&(__param_t1[0]) as *mut multimap_s))
        (__ci_expr_old_2 = __local_str)
        (__local_str = __local_str + 1)
        (__local_c__goto_5_1 = (((*(&(__ci_expr_old_2[0]) as *mut c_char)) as c_int)))
        if (((if not ((if not ((if __local_c__goto_5_1 != 91: 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_4 {
        if (((if not ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_t1[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t1[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_5 {
        if (0 != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_6 {
        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_7 {
        (__ci_expr_logic_0 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_8 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_1 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_9
    }

    '__ci_bb_9 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_12
    }

    '__ci_bb_10 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_11
    }

    '__ci_bb_11 {
        goto '__ci_bb_9
    }

    '__ci_bb_12 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_13 {
        if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[i2-1]) < (((t1)->root+0)->key[i2]) ? -1 : (((t1)->root+0)->key[i2-1]) > (((t1)->root+0)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_14
    }

    '__ci_bb_14 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_12
    }

    '__ci_bb_15 {
        if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_16 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] < (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] > (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[num2-1]) < (((t1)->root+0)->next->key[0]) ? -1 : (((t1)->root+0)->key[num2-1]) > (((t1)->root+0)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_18 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->prev->key[num_prev-1]) < (((t1)->root+0)->key[0]) ? -1 : (((t1)->root+0)->prev->key[num_prev-1]) > (((t1)->root+0)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        goto '__ci_bb_5
    }

    '__ci_bb_20 {
        if (((if not ((if (0 - (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_t1[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"-(t1)->root->num == (int) (t1)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_21
    }

    '__ci_bb_21 {
        goto '__ci_bb_2
    }

    '__ci_bb_22 {
        (__local_c__goto_5_1 = ((0 as c_int)))
        goto '__ci_bb_24
    }

    '__ci_bb_23 {
        (__ci_expr_old_3 = __local_str)
        (__local_str = __local_str + 1)
        (__local_c__goto_5_1 = (((*(&(__ci_expr_old_3[0]) as *mut c_char)) as c_int)))
        if ((if __local_c__goto_5_1 == 93: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_4 = (if (if __local_c__goto_5_1 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not ((if not (__ci_expr_logic_4 != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_24 {
        if (__param_endp != null) {
            goto '__ci_bb_60
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_25 {
        goto '__ci_bb_24
    }

    '__ci_bb_26 {
        (__local_str = __local_str - 1)
        (__local__local_cont_key5__goto_5_1 = true)
        goto '__ci_bb_27
    }

    '__ci_bb_27 {
        if __local__local_cont_key5__goto_5_1 {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_28 {
        goto '__ci_bb_31
    }

    '__ci_bb_29 {
        goto '__ci_bb_27
    }

    '__ci_bb_30 {
        goto '__ci_bb_24
    }

    '__ci_bb_31 {
        (__ci_expr_logic_5 = 0)
        if (__local__local_cont_key5__goto_5_1 != 0) {
            (__local_key__goto_5_1 = ((0 as c_int)))

            (__ci_expr_logic_5 = (if 1 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_32 {
        goto '__ci_bb_35
    }

    '__ci_bb_33 {
        (__local__local_cont_key5__goto_5_1 = false)
        goto '__ci_bb_31
    }

    '__ci_bb_34 {
        goto '__ci_bb_29
    }

    '__ci_bb_35 {
        if __local__local_cont_key5__goto_5_1 {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_36 {
        (__local__local_cont_value5__goto_5_1 = true)
        goto '__ci_bb_39
    }

    '__ci_bb_37 {
        (__local__local_cont_key5__goto_5_1 = false)
        goto '__ci_bb_35
    }

    '__ci_bb_38 {
        goto '__ci_bb_33
    }

    '__ci_bb_39 {
        if __local__local_cont_value5__goto_5_1 {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_40 {
        goto '__ci_bb_43
    }

    '__ci_bb_41 {
        goto '__ci_bb_39
    }

    '__ci_bb_42 {
        goto '__ci_bb_37
    }

    '__ci_bb_43 {
        (__ci_expr_logic_6 = 0)
        if (__local__local_cont_value5__goto_5_1 != 0) {
            (__local_value__goto_5_1 = ((0 as c_int)))

            (__ci_expr_logic_6 = (if 1 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_6 != 0) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_44 {
        goto '__ci_bb_47
    }

    '__ci_bb_45 {
        (__local__local_cont_value5__goto_5_1 = false)
        goto '__ci_bb_43
    }

    '__ci_bb_46 {
        goto '__ci_bb_41
    }

    '__ci_bb_47 {
        if __local__local_cont_value5__goto_5_1 {
            goto '__ci_bb_48
        } else {
            goto '__ci_bb_50
        }
    }

    '__ci_bb_48 {
        goto '__ci_bb_51
    }

    '__ci_bb_49 {
        (__local__local_cont_value5__goto_5_1 = false)
        goto '__ci_bb_47
    }

    '__ci_bb_50 {
        goto '__ci_bb_45
    }

    '__ci_bb_51 {
        (__local_b__goto_5_1 = m_core_parse_sint((&raw mut __local_key__goto_5_1 as *mut c_int), (&(__local_str[0]) as *mut c_char), ((&raw mut __local_str as *mut []c_char) as *mut *const i8)))
        (__local_c__goto_5_1 = ((m_core_str_nospace(((&raw mut __local_str as *mut []c_char) as *mut *const i8)) as c_int)))
        if ((if __local_b__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_54
        } else {
            goto '__ci_bb_55
        }
    }

    '__ci_bb_52 {
        if ((if __local_c__goto_5_1 == 44: 1 else: 0) != 0) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_53 {
        goto '__ci_bb_49
    }

    '__ci_bb_54 {
        (__local_c__goto_5_1 = ((0 as c_int)))
        goto '__ci_bb_53
    }

    '__ci_bb_55 {
        if ((if __local_c__goto_5_1 != 58: 1 else: 0) != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_56 {
        (__local_c__goto_5_1 = ((0 as c_int)))
        goto '__ci_bb_53
    }

    '__ci_bb_57 {
        (__local_b__goto_5_1 = m_core_parse_sint((&raw mut __local_value__goto_5_1 as *mut c_int), (&(__local_str[0]) as *mut c_char), ((&raw mut __local_str as *mut []c_char) as *mut *const i8)))
        (__local_c__goto_5_1 = ((m_core_str_nospace(((&raw mut __local_str as *mut []c_char) as *mut *const i8)) as c_int)))
        if ((if __local_b__goto_5_1 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_7 = (if (if __local_c__goto_5_1 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_58 {
        (__local_c__goto_5_1 = ((0 as c_int)))
        goto '__ci_bb_53
    }

    '__ci_bb_59 {
        multimap_set_at((&(__param_t1[0]) as *mut multimap_s), __local_key__goto_5_1, __local_value__goto_5_1)
        goto '__ci_bb_52
    }

    '__ci_bb_60 {
        ((*__param_endp) = (((&(__local_str[0]) as *const c_char) as *const c_char)))
        goto '__ci_bb_61
    }

    '__ci_bb_61 {
        goto '__ci_bb_62
    }

    '__ci_bb_62 {
        goto '__ci_bb_65
    }

    '__ci_bb_63 {
        if (0 != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_64 {
        return ((__local_c__goto_5_1 == 93))
    }

    '__ci_bb_65 {
        if (((if not ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(&raw const (__param_t1[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_5_1 = ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num)
        (__local_is_leaf2__goto_5_1 = ((__local_num2__goto_5_1 <= 0)))
        (__local_num2__goto_5_1 = (((if (if __local_num2__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num2__goto_5_1) as c_int) else: __local_num2__goto_5_1) as c_int)))
        if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t1[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_69
        }
    }

    '__ci_bb_66 {
        if (0 != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_67
        }
    }

    '__ci_bb_67 {
        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_68 {
        (__ci_expr_logic_8 = 0)
        if ((if 0 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_8 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        if ((if __local_num2__goto_5_1 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_72
        }
    }

    '__ci_bb_69 {
        (__local_c2__goto_5_1 = (((5 / 2) as c_int)))
        if (((if not ((if __local_c2__goto_5_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_9 = 0)
        if ((if __local_c2__goto_5_1 <= __local_num2__goto_5_1: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if (if __local_num2__goto_5_1 <= 5: 1 else: 0) != 0: 1 else: 0))
        }
        if (((if not (__ci_expr_logic_9 != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
        } else {
            0
        }
        goto '__ci_bb_70
    }

    '__ci_bb_70 {
        (__local_i2__goto_5_1 = ((1 as c_int)))
        goto '__ci_bb_73
    }

    '__ci_bb_71 {
        if (((if not __local_is_leaf2__goto_5_1: 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_72
    }

    '__ci_bb_72 {
        goto '__ci_bb_70
    }

    '__ci_bb_73 {
        if ((if __local_i2__goto_5_1 < __local_num2__goto_5_1: 1 else: 0) != 0) {
            goto '__ci_bb_74
        } else {
            goto '__ci_bb_76
        }
    }

    '__ci_bb_74 {
        if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2__goto_5_1 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2__goto_5_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[i2-1]) < (((t1)->root+0)->key[i2]) ? -1 : (((t1)->root+0)->key[i2-1]) > (((t1)->root+0)->key[i2])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_75
    }

    '__ci_bb_75 {
        (__local_i2__goto_5_1 = __local_i2__goto_5_1 + 1)
        goto '__ci_bb_73
    }

    '__ci_bb_76 {
        if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
            goto '__ci_bb_77
        } else {
            goto '__ci_bb_78
        }
    }

    '__ci_bb_77 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] < (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2__goto_5_1 - 1)] > (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[num2-1]) < (((t1)->root+0)->next->key[0]) ? -1 : (((t1)->root+0)->key[num2-1]) > (((t1)->root+0)->next->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_78
    }

    '__ci_bb_78 {
        if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
            goto '__ci_bb_79
        } else {
            goto '__ci_bb_80
        }
    }

    '__ci_bb_79 {
        if (((if not ((if __local_num2__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_5_1 = (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num)
        (__local_num_prev__goto_5_1 = (((if (if __local_num_prev__goto_5_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev__goto_5_1) as c_int) else: __local_num_prev__goto_5_1) as c_int)))
        if (((if not ((if __local_num_prev__goto_5_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if (((if not ((if (if (if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev__goto_5_1 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->prev->key[num_prev-1]) < (((t1)->root+0)->key[0]) ? -1 : (((t1)->root+0)->prev->key[num_prev-1]) > (((t1)->root+0)->key[0])) <= 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_80
    }

    '__ci_bb_80 {
        goto '__ci_bb_66
    }

    '__ci_bb_81 {
        if (((if not ((if (0 - (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_t1[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_parse_str".ptr, c"multimap.c".ptr, (5 as c_int), c"-(t1)->root->num == (int) (t1)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_82
    }

    '__ci_bb_82 {
        goto '__ci_bb_63
    }

    __ci_unreachable()

}

unsafe fn multimap_out_serial(__param_f: *mut m_serial_write_s, __param_t1: *mut multimap_s) -> i32 {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_t1[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t1[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[i2-1]) < (((t1)->root+0)->key[i2]) ? -1 : (((t1)->root+0)->key[i2-1]) > (((t1)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[num2-1]) < (((t1)->root+0)->next->key[0]) ? -1 : (((t1)->root+0)->key[num2-1]) > (((t1)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->prev->key[num_prev-1]) < (((t1)->root+0)->key[0]) ? -1 : (((t1)->root+0)->prev->key[num_prev-1]) > (((t1)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_t1[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"-(t1)->root->num == (int) (t1)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    var __ci_expr_logic_2: c_int = 0

    if ((if (&(__param_f[0]) as *mut c_void) != null: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if (*(&raw const (__param_f[0]) as *const m_serial_write_s)).m_interface != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_out_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"f != ((void*)0) && f->m_interface != ((void*)0)".ptr)
    } else {
        0
    }


    var __local_ret: i32

    var __local_local: [m_serial_local_s; 1]

    var __local_item: *const multimap_pair_s

    var __local_first_done: bool = false

    var __local_it_: [multimap_it_s; 1]

    (__local_ret = (((*(*(&raw const (__param_f[0]) as *const m_serial_write_s)).m_interface).write_map_start.unwrap()((&__local_local[0] as *mut m_serial_local_s), (&(__param_f[0]) as *mut m_serial_write_s), (*(&raw const (__param_t1[0]) as *const multimap_s)).size) as i32)))

    multimap_it((&__local_it_[0] as *mut multimap_it_s), (&(__param_t1[0]) as *mut multimap_s))

    while ((if not multimap_end_p((&__local_it_[0] as *mut multimap_it_s)): 1 else: 0) != 0) {
        (__local_item = multimap_cref((&__local_it_[0] as *mut multimap_it_s)))

        if __local_first_done {
            (__local_ret = (__local_ret as i32) | ((*(*(&raw const (__param_f[0]) as *const m_serial_write_s)).m_interface).write_map_next.unwrap()((&__local_local[0] as *mut m_serial_local_s), (&(__param_f[0]) as *mut m_serial_write_s)) as i32))
        }

        (__local_ret = (__local_ret as i32) | ((*(*(&raw const (__param_f[0]) as *const m_serial_write_s)).m_interface).write_integer.unwrap()((&(__param_f[0]) as *mut m_serial_write_s), ((*((*__local_item).key_ptr)) as c_longlong), (sizeof[c_int]() as c_ulong)) as i32))

        (__local_ret = (__local_ret as i32) | ((*(*(&raw const (__param_f[0]) as *const m_serial_write_s)).m_interface).write_map_value.unwrap()((&__local_local[0] as *mut m_serial_local_s), (&(__param_f[0]) as *mut m_serial_write_s)) as i32))

        (__local_ret = (__local_ret as i32) | ((*(*(&raw const (__param_f[0]) as *const m_serial_write_s)).m_interface).write_integer.unwrap()((&(__param_f[0]) as *mut m_serial_write_s), ((*((*__local_item).value_ptr)) as c_longlong), (sizeof[c_int]() as c_ulong)) as i32))

        (__local_first_done = true)


        multimap_next((&__local_it_[0] as *mut multimap_it_s))

    }


    (__local_ret = (__local_ret as i32) | ((*(*(&raw const (__param_f[0]) as *const m_serial_write_s)).m_interface).write_map_end.unwrap()((&__local_local[0] as *mut m_serial_local_s), (&(__param_f[0]) as *mut m_serial_write_s)) as i32))

    return ((((__local_ret as c_uint) & (2 as c_uint)) as i32))

}

unsafe fn multimap_in_serial(__param_t1: *mut multimap_s, __param_f: *mut m_serial_read_s) -> i32 {
    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_t1[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: c_int = ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if (if __local_num2 < 0: 1 else: 0) != 0: ((0 - __local_num2) as c_int) else: __local_num2) as c_int)))

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t1[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_0: c_int = 0

                if ((if 0 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_0 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: c_int = 0

                if ((if __local_c2 <= __local_num2: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if __local_num2 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_1 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2: c_int = ((1 as c_int))

            while ((if __local_i2 < __local_num2: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[i2-1]) < (((t1)->root+0)->key[i2]) ? -1 : (((t1)->root+0)->key[i2-1]) > (((t1)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] < (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2 - 1)] > (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[num2-1]) < (((t1)->root+0)->next->key[0]) ? -1 : (((t1)->root+0)->key[num2-1]) > (((t1)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: c_int = (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev = (((if (if __local_num_prev < 0: 1 else: 0) != 0: ((0 - __local_num_prev) as c_int) else: __local_num_prev) as c_int)))

                if (((if not ((if __local_num_prev >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->prev->key[num_prev-1]) < (((t1)->root+0)->key[0]) ? -1 : (((t1)->root+0)->prev->key[num_prev-1]) > (((t1)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_t1[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"-(t1)->root->num == (int) (t1)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    var __ci_expr_logic_2: c_int = 0

    if ((if (&(__param_f[0]) as *mut c_void) != null: 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if (if (*(&raw const (__param_f[0]) as *const m_serial_read_s)).m_interface != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"f != ((void*)0) && f->m_interface != ((void*)0)".ptr)
    } else {
        0
    }


    var __local_local: [m_serial_local_s; 1]

    var __local_ret: i32

    var __local_estimated_size: c_ulong = ((0 as c_ulong))

    multimap_reset((&(__param_t1[0]) as *mut multimap_s))

    var __local__local_cont_key5: bool = true

    while __local__local_cont_key5 {
        var __local_key: c_int

        while true {
            var __ci_expr_logic_3: c_int = 0

            if (__local__local_cont_key5 != 0) {
                (__local_key = ((0 as c_int)))

                (__ci_expr_logic_3 = (if 1 != 0: 1 else: 0))

            }

            if (not (__ci_expr_logic_3 != 0)) {
                break
            }

            while __local__local_cont_key5 {
                var __local__local_cont_value5: bool = true

                while __local__local_cont_value5 {
                    var __local_value: c_int

                    while true {
                        var __ci_expr_logic_4: c_int = 0

                        if (__local__local_cont_value5 != 0) {
                            (__local_value = ((0 as c_int)))

                            (__ci_expr_logic_4 = (if 1 != 0: 1 else: 0))

                        }

                        if (not (__ci_expr_logic_4 != 0)) {
                            break
                        }

                        while __local__local_cont_value5 {
                            (__local_ret = (((*(*(&raw const (__param_f[0]) as *const m_serial_read_s)).m_interface).read_map_start.unwrap()((&__local_local[0] as *mut m_serial_local_s), (&(__param_f[0]) as *mut m_serial_read_s), (&raw mut __local_estimated_size as *mut c_ulong)) as i32)))

                            if (((if not ((if not ((if __local_ret != 1: 1 else: 0) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                                break
                            }

                            loop {
                                (__local_ret = ((m_core_in_serial_sint((&(__param_f[0]) as *mut m_serial_read_s), (&raw mut __local_key as *mut c_int)) as i32)))

                                if ((if __local_ret != 0: 1 else: 0) != 0) {
                                    break
                                }

                                (__local_ret = (((*(*(&raw const (__param_f[0]) as *const m_serial_read_s)).m_interface).read_map_value.unwrap()((&__local_local[0] as *mut m_serial_local_s), (&(__param_f[0]) as *mut m_serial_read_s)) as i32)))

                                if ((if __local_ret != 1: 1 else: 0) != 0) {
                                    break
                                }

                                (__local_ret = ((m_core_in_serial_sint((&(__param_f[0]) as *mut m_serial_read_s), (&raw mut __local_value as *mut c_int)) as i32)))

                                if ((if __local_ret != 0: 1 else: 0) != 0) {
                                    break
                                }

                                multimap_set_at((&(__param_t1[0]) as *mut multimap_s), __local_key, __local_value)

                                (__local_ret = (((*(*(&raw const (__param_f[0]) as *const m_serial_read_s)).m_interface).read_map_next.unwrap()((&__local_local[0] as *mut m_serial_local_s), (&(__param_f[0]) as *mut m_serial_read_s)) as i32)))
                                if not (((if __local_ret == 1: 1 else: 0) != 0)) {
                                    break
                                }
                            }


                            (__local__local_cont_value5 = false)

                        }

                        (__local__local_cont_value5 = false)

                    }

                }


                (__local__local_cont_key5 = false)

            }

            (__local__local_cont_key5 = false)

        }

    }


    loop {

        loop {
            if (((if not ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if (((if not ((if (*(&raw const (__param_t1[0]) as *const multimap_s)).root != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"((t1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: c_int = ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if (if __local_num2_1 < 0: 1 else: 0) != 0: ((0 - __local_num2_1) as c_int) else: __local_num2_1) as c_int)))

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t1[0]) as *const multimap_s)).root: 1 else: 0) != 0) {
                var __ci_expr_logic_5: c_int = 0

                if ((if 0 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_5 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"0 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


                if ((if __local_num2_1 == 0: 1 else: 0) != 0) {
                    if (((if not __local_is_leaf2_1: 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: c_int = (((5 / 2) as c_int))

                if (((if not ((if __local_c2_1 > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_6: c_int = 0

                if ((if __local_c2_1 <= __local_num2_1: 1 else: 0) != 0) {
                    (__ci_expr_logic_6 = (if (if __local_num2_1 <= 5: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_6 != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"c2 <= num2 && num2 <= 5".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: c_int = ((1 as c_int))

            while ((if __local_i2_1 < __local_num2_1: 1 else: 0) != 0) {
                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_i2_1 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[__local_i2_1]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[i2-1]) < (((t1)->root+0)->key[i2]) ? -1 : (((t1)->root+0)->key[i2-1]) > (((t1)->root+0)->key[i2])) <= 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] < (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[(__local_num2_1 - 1)] > (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).next).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[num2-1]) < (((t1)->root+0)->next->key[0]) ? -1 : (((t1)->root+0)->key[num2-1]) > (((t1)->root+0)->next->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if ((if ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev != null: 1 else: 0) != 0) {
                if (((if not ((if __local_num2_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: c_int = (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).num

                (__local_num_prev_1 = (((if (if __local_num_prev_1 < 0: 1 else: 0) != 0: ((0 - __local_num_prev_1) as c_int) else: __local_num_prev_1) as c_int)))

                if (((if not ((if __local_num_prev_1 >= 1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if (((if not ((if (if (if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] < ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) != 0: (-1 as c_int) else: ((if (*((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).prev).key[(__local_num_prev_1 - 1)] > ((*(&raw const (__param_t1[0]) as *const multimap_s)).root + ((0 as isize) as usize)).key[0]: 1 else: 0) as c_int)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                    __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->prev->key[num_prev-1]) < (((t1)->root+0)->key[0]) ? -1 : (((t1)->root+0)->prev->key[num_prev-1]) > (((t1)->root+0)->key[0])) <= 0".ptr)
                } else {
                    0
                }

            }

            if not ((0 != 0)) {
                break
            }
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).next == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if (((if not ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).prev == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"(t1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num <= 0: 1 else: 0) != 0) {
            if (((if not ((if (0 - (*(*(&raw const (__param_t1[0]) as *const multimap_s)).root).num) == (((*(&raw const (__param_t1[0]) as *const multimap_s)).size as c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                __assert_rtn(c"multimap_in_serial".ptr, c"multimap.c".ptr, (5 as c_int), c"-(t1)->root->num == (int) (t1)->size".ptr)
            } else {
                0
            }
        }

        if not ((0 != 0)) {
            break
        }
    }

    return __local_ret

}

unsafe fn fill_in(__param_map: *mut multimap_s) {
    var __local_i: c_int = ((1 as c_int))

    while ((if __local_i < 100: 1 else: 0) != 0) {
        multimap_set_at((&(__param_map[0]) as *mut multimap_s), __local_i, __local_i)

        (__local_i = __local_i + 1)

    }


    var __local_i_1: c_int = ((1 as c_int))

    while ((if __local_i_1 < 100: 1 else: 0) != 0) {
        multimap_set_at((&(__param_map[0]) as *mut multimap_s), __local_i_1, ((__local_i_1 * __local_i_1) as c_int))

        (__local_i_1 = __local_i_1 + 2)

    }


    var __local_i_2: c_int = ((1 as c_int))

    while ((if __local_i_2 < 100: 1 else: 0) != 0) {
        multimap_set_at((&(__param_map[0]) as *mut multimap_s), __local_i_2, (((__local_i_2 * __local_i_2) * __local_i_2) as c_int))

        (__local_i_2 = __local_i_2 + 3)

    }


}

unsafe fn count(__param_map: *mut multimap_s, __param_key: c_int) -> c_int {
    var __local_n: c_int = ((0 as c_int))

    var __local_it_: [multimap_it_s; 1]

    multimap_it_from((&__local_it_[0] as *mut multimap_it_s), (&(__param_map[0]) as *mut multimap_s), __param_key)

    while multimap_it_while_p((&__local_it_[0] as *mut multimap_it_s), __param_key) {
        (__local_n = __local_n + 1)

        multimap_next((&__local_it_[0] as *mut multimap_it_s))

    }


    return __local_n

}

unsafe fn print_(__param_map: *mut multimap_s) {
    var __local_i: c_int = ((0 as c_int))

    while ((if __local_i < 101: 1 else: 0) != 0) {
        printf(c"Key=%d Count=%d ".ptr, __local_i, count((&(__param_map[0]) as *mut multimap_s), __local_i))

        var __local_it_: [multimap_it_s; 1]

        multimap_it_from((&__local_it_[0] as *mut multimap_it_s), (&(__param_map[0]) as *mut multimap_s), __local_i)

        while multimap_it_while_p((&__local_it_[0] as *mut multimap_it_s), __local_i) {
            printf(c"Value=%d ".ptr, (*(multimap_ref((&__local_it_[0] as *mut multimap_it_s)).value_ptr)))


            multimap_next((&__local_it_[0] as *mut multimap_it_s))

        }


        printf(c"\n".ptr)


        (__local_i = __local_i + 1)

    }


}

pub fn main() -> c_int {
    var __local_map: [multimap_s; 1]

    unsafe { multimap_init((&__local_map[0] as *mut multimap_s)) }

    unsafe { fill_in((&__local_map[0] as *mut multimap_s)) }

    unsafe { print_((&__local_map[0] as *mut multimap_s)) }

    unsafe { multimap_clear((&__local_map[0] as *mut multimap_s)) }

    exit((0 as c_int))

}
