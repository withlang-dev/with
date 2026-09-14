// Migrated from C
use std.tommyds.defs
use std.tommyds.tommyalloc
use std.tommyds.tommylist
use std.libc

fn tommy_ilog2_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).clz() as c_int) ^ (31 as c_int))

}

fn tommy_ilog2_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).clz() as c_int) ^ (63 as c_int))

}

fn tommy_ctz_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).ctz() as c_uint))

}

fn tommy_ctz_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).ctz() as c_uint))

}

fn tommy_roundup_pow2_u32(__param_value: c_uint) -> c_uint {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (1 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (2 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (4 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (8 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (16 as c_uint)) as c_uint))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: c_ulonglong) -> c_ulonglong {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (1 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (2 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (4 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (8 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (16 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (32 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: c_uint) -> c_int {
    return (if ((((((__param_value as c_uint) -% (16843009 as c_uint)) as c_uint) & ((~__param_value) as c_uint)) as c_uint) & ((2155905152 as c_uint) as c_uint)) != 0: 1 else: 0)

}

pub unsafe fn tommy_trie_init(__param_trie: *mut tommy_trie_struct, __param_alloc: *mut tommy_allocator_struct) -> Unit {
    var __local_i: c_uint

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 32: 1 else: 0) != 0) {
        ((unsafe *__param_trie).bucket[__local_i] = null)

        (__local_i = (__local_i +% 1))

    }


    ((unsafe *__param_trie).count = ((0 as c_ulonglong)))

    ((unsafe *__param_trie).node_count = ((0 as c_ulonglong)))

    ((unsafe *__param_trie).alloc = __param_alloc)

}

pub unsafe fn tommy_trie_insert(__param_trie: *mut tommy_trie_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void, __param_key: c_ulonglong) -> Unit {
    var __local_let_ptr: *mut *mut tommy_node_struct

    var __ci_expr_ternary_7: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_7 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_6: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_6 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_5: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_5 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_4: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_4 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_3: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_3 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_2: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_2 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_1: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_1 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_0: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_0 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_0 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_1 = __ci_expr_ternary_0)

                            }

                            (__ci_expr_ternary_2 = __ci_expr_ternary_1)

                        }

                        (__ci_expr_ternary_3 = __ci_expr_ternary_2)

                    }

                    (__ci_expr_ternary_4 = __ci_expr_ternary_3)

                }

                (__ci_expr_ternary_5 = __ci_expr_ternary_4)

            }

            (__ci_expr_ternary_6 = __ci_expr_ternary_5)

        }

        (__ci_expr_ternary_7 = __ci_expr_ternary_6)

    }

    var __ci_expr_ternary_15: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_15 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_14: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_14 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_13: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_13 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_12: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_12 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_11: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_11 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_10: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_10 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_9: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_9 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_8: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_8 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_8 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_9 = __ci_expr_ternary_8)

                            }

                            (__ci_expr_ternary_10 = __ci_expr_ternary_9)

                        }

                        (__ci_expr_ternary_11 = __ci_expr_ternary_10)

                    }

                    (__ci_expr_ternary_12 = __ci_expr_ternary_11)

                }

                (__ci_expr_ternary_13 = __ci_expr_ternary_12)

            }

            (__ci_expr_ternary_14 = __ci_expr_ternary_13)

        }

        (__ci_expr_ternary_15 = __ci_expr_ternary_14)

    }

    if ((((if not ((if ((__param_key as c_ulonglong) >> ((32 - ((32 % __ci_expr_ternary_7) + __ci_expr_ternary_15)) as c_uint)) < 32: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"tommy_trie_insert".ptr, c"tommytrie.c".ptr, (158 as c_int), c"key >> TOMMY_TRIE_BUCKET_SHIFT < TOMMY_TRIE_BUCKET_MAX".ptr)
    } else {
        0
    }


    ((unsafe *__param_node).data = __param_data)

    ((unsafe *__param_node).index = __param_key)

    var __ci_expr_ternary_23: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_23 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_22: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_22 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_21: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_21 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_20: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_20 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_19: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_19 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_18: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_18 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_17: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_17 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_16: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_16 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_16 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_17 = __ci_expr_ternary_16)

                            }

                            (__ci_expr_ternary_18 = __ci_expr_ternary_17)

                        }

                        (__ci_expr_ternary_19 = __ci_expr_ternary_18)

                    }

                    (__ci_expr_ternary_20 = __ci_expr_ternary_19)

                }

                (__ci_expr_ternary_21 = __ci_expr_ternary_20)

            }

            (__ci_expr_ternary_22 = __ci_expr_ternary_21)

        }

        (__ci_expr_ternary_23 = __ci_expr_ternary_22)

    }

    var __ci_expr_ternary_31: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_31 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_30: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_30 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_29: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_29 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_28: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_28 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_27: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_27 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_26: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_26 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_25: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_25 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_24: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_24 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_24 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_25 = __ci_expr_ternary_24)

                            }

                            (__ci_expr_ternary_26 = __ci_expr_ternary_25)

                        }

                        (__ci_expr_ternary_27 = __ci_expr_ternary_26)

                    }

                    (__ci_expr_ternary_28 = __ci_expr_ternary_27)

                }

                (__ci_expr_ternary_29 = __ci_expr_ternary_28)

            }

            (__ci_expr_ternary_30 = __ci_expr_ternary_29)

        }

        (__ci_expr_ternary_31 = __ci_expr_ternary_30)

    }

    (__local_let_ptr = (((&raw const (unsafe *__param_trie).bucket[((__param_key as c_ulonglong) >> ((32 - ((32 % __ci_expr_ternary_23) + __ci_expr_ternary_31)) as c_uint))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))


    trie_bucket_insert(__param_trie, (27 as c_uint), __local_let_ptr, __param_node, __param_key)

    ((unsafe *__param_trie).count = ((unsafe *__param_trie).count +% 1))

}

pub unsafe fn tommy_trie_remove(__param_trie: *mut tommy_trie_struct, __param_key: c_ulonglong) -> *mut c_void {
    var __local_ret: *mut tommy_node_struct

    var __local_let_ptr: *mut *mut tommy_node_struct

    var __ci_expr_ternary_7: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_7 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_6: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_6 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_5: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_5 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_4: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_4 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_3: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_3 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_2: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_2 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_1: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_1 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_0: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_0 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_0 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_1 = __ci_expr_ternary_0)

                            }

                            (__ci_expr_ternary_2 = __ci_expr_ternary_1)

                        }

                        (__ci_expr_ternary_3 = __ci_expr_ternary_2)

                    }

                    (__ci_expr_ternary_4 = __ci_expr_ternary_3)

                }

                (__ci_expr_ternary_5 = __ci_expr_ternary_4)

            }

            (__ci_expr_ternary_6 = __ci_expr_ternary_5)

        }

        (__ci_expr_ternary_7 = __ci_expr_ternary_6)

    }

    var __ci_expr_ternary_15: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_15 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_14: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_14 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_13: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_13 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_12: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_12 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_11: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_11 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_10: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_10 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_9: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_9 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_8: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_8 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_8 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_9 = __ci_expr_ternary_8)

                            }

                            (__ci_expr_ternary_10 = __ci_expr_ternary_9)

                        }

                        (__ci_expr_ternary_11 = __ci_expr_ternary_10)

                    }

                    (__ci_expr_ternary_12 = __ci_expr_ternary_11)

                }

                (__ci_expr_ternary_13 = __ci_expr_ternary_12)

            }

            (__ci_expr_ternary_14 = __ci_expr_ternary_13)

        }

        (__ci_expr_ternary_15 = __ci_expr_ternary_14)

    }

    if ((((if not ((if ((__param_key as c_ulonglong) >> ((32 - ((32 % __ci_expr_ternary_7) + __ci_expr_ternary_15)) as c_uint)) < 32: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"tommy_trie_remove".ptr, c"tommytrie.c".ptr, (261 as c_int), c"key >> TOMMY_TRIE_BUCKET_SHIFT < TOMMY_TRIE_BUCKET_MAX".ptr)
    } else {
        0
    }


    var __ci_expr_ternary_23: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_23 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_22: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_22 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_21: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_21 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_20: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_20 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_19: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_19 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_18: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_18 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_17: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_17 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_16: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_16 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_16 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_17 = __ci_expr_ternary_16)

                            }

                            (__ci_expr_ternary_18 = __ci_expr_ternary_17)

                        }

                        (__ci_expr_ternary_19 = __ci_expr_ternary_18)

                    }

                    (__ci_expr_ternary_20 = __ci_expr_ternary_19)

                }

                (__ci_expr_ternary_21 = __ci_expr_ternary_20)

            }

            (__ci_expr_ternary_22 = __ci_expr_ternary_21)

        }

        (__ci_expr_ternary_23 = __ci_expr_ternary_22)

    }

    var __ci_expr_ternary_31: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_31 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_30: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_30 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_29: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_29 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_28: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_28 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_27: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_27 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_26: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_26 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_25: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_25 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_24: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_24 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_24 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_25 = __ci_expr_ternary_24)

                            }

                            (__ci_expr_ternary_26 = __ci_expr_ternary_25)

                        }

                        (__ci_expr_ternary_27 = __ci_expr_ternary_26)

                    }

                    (__ci_expr_ternary_28 = __ci_expr_ternary_27)

                }

                (__ci_expr_ternary_29 = __ci_expr_ternary_28)

            }

            (__ci_expr_ternary_30 = __ci_expr_ternary_29)

        }

        (__ci_expr_ternary_31 = __ci_expr_ternary_30)

    }

    (__local_let_ptr = (((&raw const (unsafe *__param_trie).bucket[((__param_key as c_ulonglong) >> ((32 - ((32 % __ci_expr_ternary_23) + __ci_expr_ternary_31)) as c_uint))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))


    (__local_ret = trie_bucket_remove_existing(__param_trie, (27 as c_uint), __local_let_ptr, null, __param_key))

    if ((if not (__local_ret != null): 1 else: 0) != 0) {
        return ((0 as *mut c_void))
    }

    ((unsafe *__param_trie).count = ((unsafe *__param_trie).count -% 1))

    return (unsafe *__local_ret).data

}

pub unsafe fn tommy_trie_bucket(__param_trie: *mut tommy_trie_struct, __param_key: c_ulonglong) -> *mut tommy_node_struct {
    var __local_node__goto_298_19: *mut tommy_node_struct = null

    var __local_ptr__goto_299_8: *mut c_void = null

    var __local_type___goto_300_15: c_uint = 0

    var __local_shift__goto_301_15: c_uint = 0

    var __ci_expr_ternary_7: c_int = 0

    var __ci_expr_ternary_15: c_int = 0

    var __ci_expr_ternary_23: c_int = 0

    var __ci_expr_ternary_31: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__ci_expr_ternary_7 = 0)
        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
            (__ci_expr_ternary_7 = ((8 as c_int)))
        } else {
            var __ci_expr_ternary_6: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
                (__ci_expr_ternary_6 = ((7 as c_int)))
            } else {
                var __ci_expr_ternary_5: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                    (__ci_expr_ternary_5 = ((6 as c_int)))
                } else {
                    var __ci_expr_ternary_4: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                        (__ci_expr_ternary_4 = ((5 as c_int)))
                    } else {
                        var __ci_expr_ternary_3: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                            (__ci_expr_ternary_3 = ((4 as c_int)))
                        } else {
                            var __ci_expr_ternary_2: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                                (__ci_expr_ternary_2 = ((3 as c_int)))
                            } else {
                                var __ci_expr_ternary_1: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_1 = ((2 as c_int)))
                                } else {
                                    var __ci_expr_ternary_0: c_int = 0

                                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                        (__ci_expr_ternary_0 = ((1 as c_int)))
                                    } else {
                                        (__ci_expr_ternary_0 = ((0 as c_int)))
                                    }

                                    (__ci_expr_ternary_1 = __ci_expr_ternary_0)

                                }

                                (__ci_expr_ternary_2 = __ci_expr_ternary_1)

                            }

                            (__ci_expr_ternary_3 = __ci_expr_ternary_2)

                        }

                        (__ci_expr_ternary_4 = __ci_expr_ternary_3)

                    }

                    (__ci_expr_ternary_5 = __ci_expr_ternary_4)

                }

                (__ci_expr_ternary_6 = __ci_expr_ternary_5)

            }

            (__ci_expr_ternary_7 = __ci_expr_ternary_6)

        }
        (__ci_expr_ternary_15 = 0)
        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
            (__ci_expr_ternary_15 = ((8 as c_int)))
        } else {
            var __ci_expr_ternary_14: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
                (__ci_expr_ternary_14 = ((7 as c_int)))
            } else {
                var __ci_expr_ternary_13: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                    (__ci_expr_ternary_13 = ((6 as c_int)))
                } else {
                    var __ci_expr_ternary_12: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                        (__ci_expr_ternary_12 = ((5 as c_int)))
                    } else {
                        var __ci_expr_ternary_11: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                            (__ci_expr_ternary_11 = ((4 as c_int)))
                        } else {
                            var __ci_expr_ternary_10: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                                (__ci_expr_ternary_10 = ((3 as c_int)))
                            } else {
                                var __ci_expr_ternary_9: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_9 = ((2 as c_int)))
                                } else {
                                    var __ci_expr_ternary_8: c_int = 0

                                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                        (__ci_expr_ternary_8 = ((1 as c_int)))
                                    } else {
                                        (__ci_expr_ternary_8 = ((0 as c_int)))
                                    }

                                    (__ci_expr_ternary_9 = __ci_expr_ternary_8)

                                }

                                (__ci_expr_ternary_10 = __ci_expr_ternary_9)

                            }

                            (__ci_expr_ternary_11 = __ci_expr_ternary_10)

                        }

                        (__ci_expr_ternary_12 = __ci_expr_ternary_11)

                    }

                    (__ci_expr_ternary_13 = __ci_expr_ternary_12)

                }

                (__ci_expr_ternary_14 = __ci_expr_ternary_13)

            }

            (__ci_expr_ternary_15 = __ci_expr_ternary_14)

        }
        if ((((if not ((if ((__param_key as c_ulonglong) >> ((32 - ((32 % __ci_expr_ternary_7) + __ci_expr_ternary_15)) as c_uint)) < 32: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"tommy_trie_bucket".ptr, c"tommytrie.c".ptr, (304 as c_int), c"key >> TOMMY_TRIE_BUCKET_SHIFT < TOMMY_TRIE_BUCKET_MAX".ptr)
        } else {
            0
        }
        (__ci_expr_ternary_23 = 0)
        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
            (__ci_expr_ternary_23 = ((8 as c_int)))
        } else {
            var __ci_expr_ternary_22: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
                (__ci_expr_ternary_22 = ((7 as c_int)))
            } else {
                var __ci_expr_ternary_21: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                    (__ci_expr_ternary_21 = ((6 as c_int)))
                } else {
                    var __ci_expr_ternary_20: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                        (__ci_expr_ternary_20 = ((5 as c_int)))
                    } else {
                        var __ci_expr_ternary_19: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                            (__ci_expr_ternary_19 = ((4 as c_int)))
                        } else {
                            var __ci_expr_ternary_18: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                                (__ci_expr_ternary_18 = ((3 as c_int)))
                            } else {
                                var __ci_expr_ternary_17: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_17 = ((2 as c_int)))
                                } else {
                                    var __ci_expr_ternary_16: c_int = 0

                                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                        (__ci_expr_ternary_16 = ((1 as c_int)))
                                    } else {
                                        (__ci_expr_ternary_16 = ((0 as c_int)))
                                    }

                                    (__ci_expr_ternary_17 = __ci_expr_ternary_16)

                                }

                                (__ci_expr_ternary_18 = __ci_expr_ternary_17)

                            }

                            (__ci_expr_ternary_19 = __ci_expr_ternary_18)

                        }

                        (__ci_expr_ternary_20 = __ci_expr_ternary_19)

                    }

                    (__ci_expr_ternary_21 = __ci_expr_ternary_20)

                }

                (__ci_expr_ternary_22 = __ci_expr_ternary_21)

            }

            (__ci_expr_ternary_23 = __ci_expr_ternary_22)

        }
        (__ci_expr_ternary_31 = 0)
        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
            (__ci_expr_ternary_31 = ((8 as c_int)))
        } else {
            var __ci_expr_ternary_30: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
                (__ci_expr_ternary_30 = ((7 as c_int)))
            } else {
                var __ci_expr_ternary_29: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                    (__ci_expr_ternary_29 = ((6 as c_int)))
                } else {
                    var __ci_expr_ternary_28: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                        (__ci_expr_ternary_28 = ((5 as c_int)))
                    } else {
                        var __ci_expr_ternary_27: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                            (__ci_expr_ternary_27 = ((4 as c_int)))
                        } else {
                            var __ci_expr_ternary_26: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                                (__ci_expr_ternary_26 = ((3 as c_int)))
                            } else {
                                var __ci_expr_ternary_25: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_25 = ((2 as c_int)))
                                } else {
                                    var __ci_expr_ternary_24: c_int = 0

                                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                        (__ci_expr_ternary_24 = ((1 as c_int)))
                                    } else {
                                        (__ci_expr_ternary_24 = ((0 as c_int)))
                                    }

                                    (__ci_expr_ternary_25 = __ci_expr_ternary_24)

                                }

                                (__ci_expr_ternary_26 = __ci_expr_ternary_25)

                            }

                            (__ci_expr_ternary_27 = __ci_expr_ternary_26)

                        }

                        (__ci_expr_ternary_28 = __ci_expr_ternary_27)

                    }

                    (__ci_expr_ternary_29 = __ci_expr_ternary_28)

                }

                (__ci_expr_ternary_30 = __ci_expr_ternary_29)

            }

            (__ci_expr_ternary_31 = __ci_expr_ternary_30)

        }
        (__local_ptr__goto_299_8 = (((unsafe *__param_trie).bucket[((__param_key as c_ulonglong) >> ((32 - ((32 % __ci_expr_ternary_23) + __ci_expr_ternary_31)) as c_uint))] as *mut c_void)))
        (__local_shift__goto_301_15 = ((27 as c_uint)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        if ((if not (__local_ptr__goto_299_8 != null): 1 else: 0) != 0) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_2 {
        return ((0 as *mut tommy_node_struct))
    }

    '__ci_bb_3 {
        (__local_type___goto_300_15 = (((((__local_ptr__goto_299_8 as c_ulong) as c_ulong) & (1 as c_ulong)) as c_uint)))
        goto '__ci_bb_4
    }

    '__ci_bb_4 {
        if (__local_type___goto_300_15 == 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_6 {
        (__local_node__goto_298_19 = ((__local_ptr__goto_299_8 as *mut tommy_node_struct)))
        if ((if (unsafe *__local_node__goto_298_19).index != __param_key: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_7 {
        return ((0 as *mut tommy_node_struct))
    }

    '__ci_bb_8 {
        return __local_node__goto_298_19
    }

    '__ci_bb_9 {
        (__local_ptr__goto_299_8 = (((unsafe *((((__local_ptr__goto_299_8 as c_ulong) as c_ulong) -% (1 as c_ulong)) as *mut tommy_trie_tree_struct)).map[((((__param_key as c_ulonglong) >> (__local_shift__goto_301_15 as c_uint)) as c_ulonglong) & (7 as c_ulonglong))] as *mut c_void)))
        (__local_shift__goto_301_15 = (__local_shift__goto_301_15 -% 3))
        goto '__ci_bb_1
    }

    '__ci_bb_10 {
        if (__local_type___goto_300_15 == 1) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_9
        }
    }

    __ci_unreachable()

}

unsafe fn tommy_trie_search(__param_trie: *mut tommy_trie_struct, __param_key: c_ulonglong) -> *mut c_void {
    var __local_i: *mut tommy_node_struct = tommy_trie_bucket(__param_trie, __param_key)

    if ((if not (__local_i != null): 1 else: 0) != 0) {
        return ((0 as *mut c_void))
    }

    return (unsafe *__local_i).data

}

pub unsafe fn tommy_trie_remove_existing(__param_trie: *mut tommy_trie_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    var __local_ret: *mut tommy_node_struct

    var __local_key: c_ulonglong = (unsafe *__param_node).index

    var __local_let_ptr: *mut *mut tommy_node_struct

    var __ci_expr_ternary_7: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_7 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_6: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_6 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_5: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_5 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_4: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_4 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_3: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_3 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_2: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_2 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_1: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_1 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_0: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_0 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_0 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_1 = __ci_expr_ternary_0)

                            }

                            (__ci_expr_ternary_2 = __ci_expr_ternary_1)

                        }

                        (__ci_expr_ternary_3 = __ci_expr_ternary_2)

                    }

                    (__ci_expr_ternary_4 = __ci_expr_ternary_3)

                }

                (__ci_expr_ternary_5 = __ci_expr_ternary_4)

            }

            (__ci_expr_ternary_6 = __ci_expr_ternary_5)

        }

        (__ci_expr_ternary_7 = __ci_expr_ternary_6)

    }

    var __ci_expr_ternary_15: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_15 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_14: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_14 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_13: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_13 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_12: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_12 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_11: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_11 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_10: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_10 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_9: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_9 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_8: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_8 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_8 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_9 = __ci_expr_ternary_8)

                            }

                            (__ci_expr_ternary_10 = __ci_expr_ternary_9)

                        }

                        (__ci_expr_ternary_11 = __ci_expr_ternary_10)

                    }

                    (__ci_expr_ternary_12 = __ci_expr_ternary_11)

                }

                (__ci_expr_ternary_13 = __ci_expr_ternary_12)

            }

            (__ci_expr_ternary_14 = __ci_expr_ternary_13)

        }

        (__ci_expr_ternary_15 = __ci_expr_ternary_14)

    }

    if ((((if not ((if ((__local_key as c_ulonglong) >> ((32 - ((32 % __ci_expr_ternary_7) + __ci_expr_ternary_15)) as c_uint)) < 32: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"tommy_trie_remove_existing".ptr, c"tommytrie.c".ptr, (282 as c_int), c"key >> TOMMY_TRIE_BUCKET_SHIFT < TOMMY_TRIE_BUCKET_MAX".ptr)
    } else {
        0
    }


    var __ci_expr_ternary_23: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_23 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_22: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_22 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_21: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_21 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_20: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_20 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_19: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_19 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_18: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_18 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_17: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_17 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_16: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_16 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_16 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_17 = __ci_expr_ternary_16)

                            }

                            (__ci_expr_ternary_18 = __ci_expr_ternary_17)

                        }

                        (__ci_expr_ternary_19 = __ci_expr_ternary_18)

                    }

                    (__ci_expr_ternary_20 = __ci_expr_ternary_19)

                }

                (__ci_expr_ternary_21 = __ci_expr_ternary_20)

            }

            (__ci_expr_ternary_22 = __ci_expr_ternary_21)

        }

        (__ci_expr_ternary_23 = __ci_expr_ternary_22)

    }

    var __ci_expr_ternary_31: c_int = 0

    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 256: 1 else: 0) != 0) {
        (__ci_expr_ternary_31 = ((8 as c_int)))
    } else {
        var __ci_expr_ternary_30: c_int = 0

        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 128: 1 else: 0) != 0) {
            (__ci_expr_ternary_30 = ((7 as c_int)))
        } else {
            var __ci_expr_ternary_29: c_int = 0

            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 64: 1 else: 0) != 0) {
                (__ci_expr_ternary_29 = ((6 as c_int)))
            } else {
                var __ci_expr_ternary_28: c_int = 0

                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 32: 1 else: 0) != 0) {
                    (__ci_expr_ternary_28 = ((5 as c_int)))
                } else {
                    var __ci_expr_ternary_27: c_int = 0

                    if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 16: 1 else: 0) != 0) {
                        (__ci_expr_ternary_27 = ((4 as c_int)))
                    } else {
                        var __ci_expr_ternary_26: c_int = 0

                        if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 8: 1 else: 0) != 0) {
                            (__ci_expr_ternary_26 = ((3 as c_int)))
                        } else {
                            var __ci_expr_ternary_25: c_int = 0

                            if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 4: 1 else: 0) != 0) {
                                (__ci_expr_ternary_25 = ((2 as c_int)))
                            } else {
                                var __ci_expr_ternary_24: c_int = 0

                                if ((if ((64 as c_ulong) / (sizeof[usize]() as c_ulong)) == 2: 1 else: 0) != 0) {
                                    (__ci_expr_ternary_24 = ((1 as c_int)))
                                } else {
                                    (__ci_expr_ternary_24 = ((0 as c_int)))
                                }

                                (__ci_expr_ternary_25 = __ci_expr_ternary_24)

                            }

                            (__ci_expr_ternary_26 = __ci_expr_ternary_25)

                        }

                        (__ci_expr_ternary_27 = __ci_expr_ternary_26)

                    }

                    (__ci_expr_ternary_28 = __ci_expr_ternary_27)

                }

                (__ci_expr_ternary_29 = __ci_expr_ternary_28)

            }

            (__ci_expr_ternary_30 = __ci_expr_ternary_29)

        }

        (__ci_expr_ternary_31 = __ci_expr_ternary_30)

    }

    (__local_let_ptr = (((&raw const (unsafe *__param_trie).bucket[((__local_key as c_ulonglong) >> ((32 - ((32 % __ci_expr_ternary_23) + __ci_expr_ternary_31)) as c_uint))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))


    (__local_ret = trie_bucket_remove_existing(__param_trie, (27 as c_uint), __local_let_ptr, __param_node, __local_key))

    if ((((if not ((if __local_ret == __param_node: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"tommy_trie_remove_existing".ptr, c"tommytrie.c".ptr, (289 as c_int), c"ret == node".ptr)
    } else {
        0
    }

    ((unsafe *__param_trie).count = ((unsafe *__param_trie).count -% 1))

    return (unsafe *__local_ret).data

}

unsafe fn tommy_trie_count(__param_trie: *mut tommy_trie_struct) -> c_ulonglong {
    return (unsafe *__param_trie).count

}

pub unsafe fn tommy_trie_memory_usage(__param_trie: *mut tommy_trie_struct) -> c_ulonglong {
    return ((((tommy_trie_count(__param_trie) as c_ulonglong) *% ((sizeof[tommy_node_struct]() as c_ulonglong) as c_ulonglong)) as c_ulonglong) +% ((((unsafe *__param_trie).node_count as c_ulonglong) *% ((((((64 as c_ulong) / (8 as c_ulong)) as c_ulong) *% (8 as c_ulong)) as c_ulonglong) as c_ulonglong)) as c_ulonglong))

}

unsafe fn tommy_list_init(__param_list: *mut *mut tommy_node_struct) -> Unit {
    ((unsafe *__param_list) = null)

}

unsafe fn tommy_list_head(__param_list: *mut *mut tommy_node_struct) -> *mut tommy_node_struct {
    return (unsafe *__param_list)

}

unsafe fn tommy_list_tail(__param_list: *mut *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    if ((if not (__local_head != null): 1 else: 0) != 0) {
        return ((0 as *mut tommy_node_struct))
    }

    return (unsafe *__local_head).prev

}

unsafe fn tommy_list_insert_first(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> Unit {
    ((unsafe *__param_node).prev = __param_node)

    ((unsafe *__param_node).next = null)

    ((unsafe *__param_list) = __param_node)

}

unsafe fn tommy_list_insert_head_not_empty(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> Unit {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    ((unsafe *__param_node).prev = (unsafe *__local_head).prev)

    ((unsafe *__local_head).prev = __param_node)

    ((unsafe *__param_node).next = __local_head)

    ((unsafe *__param_list) = __param_node)

}

unsafe fn tommy_list_insert_tail_not_empty(__param_head: *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> Unit {
    ((unsafe *__param_node).prev = (unsafe *__param_head).prev)

    ((unsafe *__param_head).prev = __param_node)

    ((unsafe *__param_node).next = null)

    ((unsafe *(unsafe *__param_node).prev).next = __param_node)

}

unsafe fn tommy_list_insert_head(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void) -> Unit {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    if (__local_head != null) {
        tommy_list_insert_head_not_empty(__param_list, __param_node)
    } else {
        tommy_list_insert_first(__param_list, __param_node)
    }

    ((unsafe *__param_node).data = __param_data)

}

unsafe fn tommy_list_insert_tail(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void) -> Unit {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    if (__local_head != null) {
        tommy_list_insert_tail_not_empty(__local_head, __param_node)
    } else {
        tommy_list_insert_first(__param_list, __param_node)
    }

    ((unsafe *__param_node).data = __param_data)

}

unsafe fn tommy_list_remove_existing(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    if ((unsafe *__param_node).next != null) {
        ((unsafe *(unsafe *__param_node).next).prev = (unsafe *__param_node).prev)
    } else {
        ((unsafe *__local_head).prev = (unsafe *__param_node).prev)
    }

    if ((if __local_head == __param_node: 1 else: 0) != 0) {
        ((unsafe *__param_list) = (unsafe *__param_node).next)
    } else {
        ((unsafe *(unsafe *__param_node).prev).next = (unsafe *__param_node).next)
    }

    return (unsafe *__param_node).data

}

unsafe fn tommy_list_concat(__param_first: *mut *mut tommy_node_struct, __param_second: *mut *mut tommy_node_struct) -> Unit {
    var __local_first_head: *mut tommy_node_struct

    var __local_first_tail: *mut tommy_node_struct

    var __local_second_head: *mut tommy_node_struct

    (__local_second_head = tommy_list_head(__param_second))

    if ((if __local_second_head == 0: 1 else: 0) != 0) {
        return
    }

    (__local_first_head = tommy_list_head(__param_first))

    if ((if __local_first_head == 0: 1 else: 0) != 0) {
        ((unsafe *__param_first) = (unsafe *__param_second))

        return

    }

    (__local_first_tail = (unsafe *__local_first_head).prev)

    ((unsafe *__local_first_head).prev = (unsafe *__local_second_head).prev)

    ((unsafe *__local_second_head).prev = __local_first_tail)

    ((unsafe *__local_first_tail).next = __local_second_head)

}

unsafe fn tommy_list_empty(__param_list: *mut *mut tommy_node_struct) -> c_int {
    return (if tommy_list_head(__param_list) == 0: 1 else: 0)

}

unsafe fn tommy_list_count(__param_list: *mut *mut tommy_node_struct) -> c_ulonglong {
    var __local_count: c_ulonglong = ((0 as c_ulonglong))

    var __local_i: *mut tommy_node_struct = tommy_list_head(__param_list)

    while (__local_i != null) {
        (__local_count = (__local_count +% 1))

        (__local_i = (unsafe *__local_i).next)

    }

    return __local_count

}

unsafe fn tommy_list_foreach(__param_list: *mut *mut tommy_node_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) -> Unit {
    var __local_node: *mut tommy_node_struct = tommy_list_head(__param_list)

    while (__local_node != null) {
        var __local_data: *mut c_void = (unsafe *__local_node).data

        (__local_node = (unsafe *__local_node).next)

        __param_func(__local_data)

    }

}

unsafe fn tommy_list_foreach_arg(__param_list: *mut *mut tommy_node_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) -> Unit {
    var __local_node: *mut tommy_node_struct = tommy_list_head(__param_list)

    while (__local_node != null) {
        var __local_data: *mut c_void = (unsafe *__local_node).data

        (__local_node = (unsafe *__local_node).next)

        __param_func(__param_arg, __local_data)

    }

}

unsafe fn trie_bucket_insert(__param_trie: *mut tommy_trie_struct, __param_shift: c_uint, __param_let_ptr: *mut *mut tommy_node_struct, __param_insert: *mut tommy_node_struct, __param_key: c_ulonglong) -> Unit {
    var __local_shift = __param_shift
    var __local_let_ptr = __param_let_ptr
    var __local_tree__goto_92_19: *mut tommy_trie_tree_struct = null

    var __local_node__goto_93_19: *mut tommy_node_struct = null

    var __local_ptr__goto_94_8: *mut c_void = null

    var __local_i__goto_95_15: c_uint = 0

    var __local_j__goto_96_15: c_uint = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__local_ptr__goto_94_8 = (((unsafe *__local_let_ptr) as *mut c_void)))
        if ((if not (__local_ptr__goto_94_8 != null): 1 else: 0) != 0) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_2 {
        tommy_list_insert_first(__local_let_ptr, __param_insert)
        return
    }

    '__ci_bb_3 {
        if ((if (((__local_ptr__goto_94_8 as c_ulong) as c_ulong) & (1 as c_ulong)) == 1: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        (__local_let_ptr = (((&raw const (unsafe *((((__local_ptr__goto_94_8 as c_ulong) as c_ulong) -% (1 as c_ulong)) as *mut tommy_trie_tree_struct)).map[((((__param_key as c_ulonglong) >> (__local_shift as c_uint)) as c_ulonglong) & (7 as c_ulonglong))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))
        (__local_shift = (__local_shift -% 3))
        goto '__ci_bb_1
    }

    '__ci_bb_5 {
        (__local_node__goto_93_19 = ((__local_ptr__goto_94_8 as *mut tommy_node_struct)))
        if ((if (unsafe *__local_node__goto_93_19).index == __param_key: 1 else: 0) != 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_6 {
        tommy_list_insert_tail_not_empty(__local_node__goto_93_19, __param_insert)
        return
    }

    '__ci_bb_7 {
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        (__local_tree__goto_92_19 = ((tommy_allocator_alloc((unsafe *__param_trie).alloc) as *mut tommy_trie_tree_struct)))
        ((unsafe *__param_trie).node_count = ((unsafe *__param_trie).node_count +% 1))
        ((unsafe *__local_let_ptr) = ((((((__local_tree__goto_92_19 as c_ulong) as c_ulong) +% (1 as c_ulong)) as *mut c_void) as *mut tommy_node_struct)))
        (__local_i__goto_95_15 = ((0 as c_uint)))
        goto '__ci_bb_9
    }

    '__ci_bb_9 {
        if ((if __local_i__goto_95_15 < ((64 as c_ulong) / (8 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_10 {
        ((unsafe *__local_tree__goto_92_19).map[__local_i__goto_95_15] = null)
        goto '__ci_bb_11
    }

    '__ci_bb_11 {
        (__local_i__goto_95_15 = (__local_i__goto_95_15 +% 1))
        goto '__ci_bb_9
    }

    '__ci_bb_12 {
        (__local_i__goto_95_15 = (((((((unsafe *__local_node__goto_93_19).index as c_ulonglong) >> (__local_shift as c_uint)) as c_ulonglong) & (7 as c_ulonglong)) as c_uint)))
        (__local_j__goto_96_15 = ((((((__param_key as c_ulonglong) >> (__local_shift as c_uint)) as c_ulonglong) & (7 as c_ulonglong)) as c_uint)))
        if ((if __local_i__goto_95_15 != __local_j__goto_96_15: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_13 {
        ((unsafe *__local_tree__goto_92_19).map[__local_i__goto_95_15] = __local_node__goto_93_19)
        tommy_list_insert_first(((&raw const (unsafe *__local_tree__goto_92_19).map[__local_j__goto_96_15] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_insert)
        return
    }

    '__ci_bb_14 {
        (__local_let_ptr = (((&raw const (unsafe *__local_tree__goto_92_19).map[__local_i__goto_95_15] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))
        (__local_shift = (__local_shift -% 3))
        goto '__ci_bb_8
    }

    __ci_unreachable()

}

unsafe fn trie_bucket_remove_existing(__param_trie: *mut tommy_trie_struct, __param_shift: c_uint, __param_let_ptr: *mut *mut tommy_node_struct, __param_remove: *mut tommy_node_struct, __param_key: c_ulonglong) -> *mut tommy_node_struct {
    var __local_shift = __param_shift
    var __local_let_ptr = __param_let_ptr
    var __local_remove = __param_remove
    var __local_node__goto_172_19: *mut tommy_node_struct = null

    var __local_tree__goto_173_19: *mut tommy_trie_tree_struct = null

    var __local_ptr__goto_174_8: *mut c_void = null

    var __local_let_back__goto_175_20: [10]*mut *mut tommy_node_struct

    var __local_level__goto_176_15: c_uint = 0

    var __local_i__goto_177_15: c_uint = 0

    var __local_count__goto_178_15: c_uint = 0

    var __local_last__goto_179_15: c_uint = 0

    var __ci_expr_old_0: c_uint = 0

    var __ci_expr_logic_1: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_level__goto_176_15 = ((0 as c_uint)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__local_ptr__goto_174_8 = (((unsafe *__local_let_ptr) as *mut c_void)))
        if ((if not (__local_ptr__goto_174_8 != null): 1 else: 0) != 0) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_2 {
        return ((0 as *mut tommy_node_struct))
    }

    '__ci_bb_3 {
        if ((if (((__local_ptr__goto_174_8 as c_ulong) as c_ulong) & (1 as c_ulong)) == 1: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        (__local_tree__goto_173_19 = (((((__local_ptr__goto_174_8 as c_ulong) as c_ulong) -% (1 as c_ulong)) as *mut tommy_trie_tree_struct)))
        (__ci_expr_old_0 = __local_level__goto_176_15)
        (__local_level__goto_176_15 = (__local_level__goto_176_15 +% 1))
        (__local_let_back__goto_175_20[__ci_expr_old_0] = __local_let_ptr)
        (__local_let_ptr = (((&raw const (unsafe *__local_tree__goto_173_19).map[((((__param_key as c_ulonglong) >> (__local_shift as c_uint)) as c_ulonglong) & (7 as c_ulonglong))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))
        (__local_shift = (__local_shift -% 3))
        goto '__ci_bb_1
    }

    '__ci_bb_5 {
        (__local_node__goto_172_19 = ((__local_ptr__goto_174_8 as *mut tommy_node_struct)))
        if ((if not (__local_remove != null): 1 else: 0) != 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_6 {
        (__local_remove = __local_node__goto_172_19)
        if ((if (unsafe *__local_remove).index != __param_key: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_7 {
        tommy_list_remove_existing(__local_let_ptr, __local_remove)
        if ((unsafe *__local_let_ptr) != null) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if not (__local_level__goto_176_15 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_8 {
        return ((0 as *mut tommy_node_struct))
    }

    '__ci_bb_9 {
        goto '__ci_bb_7
    }

    '__ci_bb_10 {
        return __local_remove
    }

    '__ci_bb_11 {
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        (__local_level__goto_176_15 = (__local_level__goto_176_15 -% 1))
        (__local_let_ptr = __local_let_back__goto_175_20[__local_level__goto_176_15])
        (__local_tree__goto_173_19 = ((((((unsafe *__local_let_ptr) as c_ulong) as c_ulong) -% (1 as c_ulong)) as *mut tommy_trie_tree_struct)))
        (__local_count__goto_178_15 = ((0 as c_uint)))
        (__local_last__goto_179_15 = ((0 as c_uint)))
        (__local_i__goto_177_15 = ((0 as c_uint)))
        goto '__ci_bb_13
    }

    '__ci_bb_13 {
        if ((if __local_i__goto_177_15 < ((64 as c_ulong) / (8 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_14 {
        if ((unsafe *__local_tree__goto_173_19).map[__local_i__goto_177_15] != null) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_15 {
        (__local_i__goto_177_15 = (__local_i__goto_177_15 +% 1))
        goto '__ci_bb_13
    }

    '__ci_bb_16 {
        if ((((if not ((if __local_count__goto_178_15 == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"trie_bucket_remove_existing".ptr, c"tommytrie.c".ptr, (241 as c_int), c"count == 1".ptr)
        } else {
            0
        }
        ((unsafe *__local_let_ptr) = (unsafe *__local_tree__goto_173_19).map[__local_last__goto_179_15])
        tommy_allocator_free((unsafe *__param_trie).alloc, (__local_tree__goto_173_19 as *mut c_void))
        ((unsafe *__param_trie).node_count = ((unsafe *__param_trie).node_count -% 1))
        if (__local_level__goto_176_15 != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_17 {
        if ((if ((((unsafe *__local_tree__goto_173_19).map[__local_i__goto_177_15] as c_ulong) as c_ulong) & (1 as c_ulong)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_18 {
        goto '__ci_bb_15
    }

    '__ci_bb_19 {
        return __local_remove
    }

    '__ci_bb_20 {
        (__local_count__goto_178_15 = (__local_count__goto_178_15 +% 1))
        if ((if __local_count__goto_178_15 > 1: 1 else: 0) != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_21 {
        return __local_remove
    }

    '__ci_bb_22 {
        (__local_last__goto_179_15 = __local_i__goto_177_15)
        goto '__ci_bb_18
    }

    '__ci_bb_23 {
        goto '__ci_bb_12
    }

    '__ci_bb_24 {
        return __local_remove
    }

    __ci_unreachable()

}
