// Migrated from PCRE2
use std.re.defs

fn pcre2_serialize_encode_8(codes: *mut *const pcre2_real_code_8, number_of_codes: c_int, serialized_bytes: *mut *mut u8, serialized_size: *mut c_ulong, gcontext: *mut pcre2_real_general_context_8) -> c_int {
    var bytes: *mut u8

    var dst_bytes: *mut u8

    var i: c_int

    var total_size: c_ulong

    var re: *const pcre2_real_code_8

    var tables: *const u8

    var data: *mut pcre2_serialized_data

    var memctl: *const pcre2_memctl = with 0 as __ci_expr_seq_16 {
        var __ci_expr_ternary_0: *mut pcre2_memctl = null
        if ((if gcontext != null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (((&gcontext.memctl as *const pcre2_memctl) as *mut pcre2_memctl)))
        } else {
            (__ci_expr_ternary_0 = (((&_pcre2_default_compile_context_8.memctl as *const pcre2_memctl) as *mut pcre2_memctl)))
        }
        (__ci_expr_ternary_0 as *const pcre2_memctl)
    }

    var __ci_expr_logic_2: c_int

    var __ci_expr_logic_1: c_int

    if ((if codes == null: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if serialized_bytes == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if serialized_size == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return -51
    }


    if ((if number_of_codes <= 0: 1 else: 0) != 0) {
        return -29
    }

    (total_size = (sizeof[pcre2_serialized_data]() +% 1088))

    (tables = ((null as *const u8)))

    (i = 0)

    while ((if i < number_of_codes: 1 else: 0) != 0) {
        if ((if (unsafe: codes[i]) == null: 1 else: 0) != 0) {
            return -51
        }

        (re = (unsafe: codes[i]))

        if ((if re.magic_number != 1346589253: 1 else: 0) != 0) {
            return -31
        }

        if ((if tables == null: 1 else: 0) != 0) {
            (tables = re.tables)
        } else {
            if ((if tables != re.tables: 1 else: 0) != 0) {
                return -30
            }
        }

        (total_size = total_size + re.blocksize)


        (i = i + 1)

    }


    (bytes = ((memctl.malloc((total_size +% sizeof[pcre2_memctl]()), memctl.memory_data) as *mut u8)))

    if ((if bytes == null: 1 else: 0) != 0) {
        return -48
    }

    with_memcpy((bytes as *i8), (memctl as *i8), (sizeof[pcre2_memctl]() as i64))

    (bytes = bytes + sizeof[pcre2_memctl]())

    (data = ((bytes as *mut pcre2_serialized_data)))

    (data.magic = 1347564115)

    (data.version = 3145738)

    (data.config = 526337)

    (data.number_of_codes = number_of_codes)

    (dst_bytes = bytes + sizeof[pcre2_serialized_data]())

    with_memcpy((dst_bytes as *i8), (tables as *i8), (1088 as i64))

    (dst_bytes = dst_bytes + ((512 + 320) + 256))

    (i = 0)

    while ((if i < number_of_codes: 1 else: 0) != 0) {
        (re = (unsafe: codes[i]))

        with_memcpy((dst_bytes as *i8), ((re as *const c_char) as *i8), (re.blocksize as i64))

        with_memset(((dst_bytes + 0) as *i8), 0, (sizeof[pcre2_memctl]() as i64))

        with_memset(((dst_bytes + 24) as *i8), 0, (8 as i64))

        with_memset(((dst_bytes + 32) as *i8), 0, (8 as i64))

        (dst_bytes = dst_bytes + re.blocksize)


        (i = i + 1)

    }


    ((unsafe: *serialized_bytes) = bytes)

    ((unsafe: *serialized_size) = total_size)

    return number_of_codes

}

fn pcre2_serialize_decode_8(codes: *mut *mut pcre2_real_code_8, __param_number_of_codes: c_int, bytes: *const u8, gcontext: *mut pcre2_real_general_context_8) -> c_int {
    var number_of_codes = __param_number_of_codes
    var data__goto_164_30: *const pcre2_serialized_data = null
    var memctl__goto_165_21: *const pcre2_memctl = null
    var src_bytes__goto_168_16: *const u8 = null
    var dst_re__goto_169_18: *mut pcre2_real_code_8 = null
    var tables__goto_170_10: *mut u8 = null
    var i__goto_171_9: c_int = 0
    var j__goto_171_12: c_int = 0
    var error___goto_172_9: c_int = 0
    var blocksize__goto_206_23: c_ulong = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                (data__goto_164_30 = ((bytes as *const pcre2_serialized_data)))
                var __ci_expr_ternary_0: *mut pcre2_memctl = null
                if ((if gcontext != null: 1 else: 0) != 0) {
                    (__ci_expr_ternary_0 = (((&gcontext.memctl as *const pcre2_memctl) as *mut pcre2_memctl)))
                } else {
                    (__ci_expr_ternary_0 = (((&_pcre2_default_compile_context_8.memctl as *const pcre2_memctl) as *mut pcre2_memctl)))
                }
                (memctl__goto_165_21 = ((__ci_expr_ternary_0 as *const pcre2_memctl)))
                (dst_re__goto_169_18 = ((null as *mut pcre2_real_code_8)))
                var __ci_expr_logic_1: c_int
                if ((if data__goto_164_30 == null: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_1 = (if (if codes == null: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_1 != 0) {
                    return -51
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if number_of_codes <= 0: 1 else: 0) != 0) {
                    return -29
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if data__goto_164_30.number_of_codes <= 0: 1 else: 0) != 0) {
                    return -62
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if data__goto_164_30.magic != 1347564115: 1 else: 0) != 0) {
                    return -31
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if data__goto_164_30.version != 3145738: 1 else: 0) != 0) {
                    return -32
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if data__goto_164_30.config != (2049 | 524288): 1 else: 0) != 0) {
                    return -32
                }
                if (__goto_pending != 0) {
                    continue
                }
                if ((if number_of_codes > data__goto_164_30.number_of_codes: 1 else: 0) != 0) {
                    (number_of_codes = data__goto_164_30.number_of_codes)
                }
                if (__goto_pending != 0) {
                    continue
                }
                (src_bytes__goto_168_16 = bytes + sizeof[pcre2_serialized_data]())
                if (__goto_pending != 0) {
                    continue
                }
                (tables__goto_170_10 = ((memctl__goto_165_21.malloc((1088 +% sizeof[c_ulong]()), memctl__goto_165_21.memory_data) as *mut u8)))
                if (__goto_pending != 0) {
                    continue
                }
                if ((if tables__goto_170_10 == null: 1 else: 0) != 0) {
                    return -48
                }
                if (__goto_pending != 0) {
                    continue
                }
                with_memcpy((tables__goto_170_10 as *i8), (src_bytes__goto_168_16 as *i8), (1088 as i64))
                if (__goto_pending != 0) {
                    continue
                }
                ((unsafe: *((tables__goto_170_10 + ((((512 + 320) + 256) as isize) as usize)) as *mut c_ulong)) = number_of_codes)
                if (__goto_pending != 0) {
                    continue
                }
                (src_bytes__goto_168_16 = src_bytes__goto_168_16 + ((512 + 320) + 256))
                if (__goto_pending != 0) {
                    continue
                }
                (i__goto_171_9 = 0)
                while ((if i__goto_171_9 < number_of_codes: 1 else: 0) != 0) {
                    with_memcpy(((&mut blocksize__goto_206_23 as *mut c_ulong) as *i8), ((src_bytes__goto_168_16 + 72) as *i8), (sizeof[c_ulong]() as i64))
                    if (__goto_pending != 0) {
                        break
                    }
                    if ((if blocksize__goto_206_23 <= sizeof[pcre2_real_code_8](): 1 else: 0) != 0) {
                        (error___goto_172_9 = -62)
                        if (__goto_pending != 0) {
                            break
                        }
                        __pc = 1
                        __goto_pending = 1
                        if (__goto_pending != 0) {
                            break
                        }
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (dst_re__goto_169_18 = ((_pcre2_memctl_malloc_8(blocksize__goto_206_23, (gcontext as *mut pcre2_memctl)) as *mut pcre2_real_code_8)))
                    if (__goto_pending != 0) {
                        break
                    }
                    if ((if dst_re__goto_169_18 == null: 1 else: 0) != 0) {
                        (error___goto_172_9 = -48)
                        if (__goto_pending != 0) {
                            break
                        }
                        __pc = 1
                        __goto_pending = 1
                        if (__goto_pending != 0) {
                            break
                        }
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    with_memcpy((((dst_re__goto_169_18 as *mut u8) + sizeof[pcre2_memctl]()) as *i8), ((src_bytes__goto_168_16 + sizeof[pcre2_memctl]()) as *i8), ((blocksize__goto_206_23 -% sizeof[pcre2_memctl]()) as i64))
                    if (__goto_pending != 0) {
                        break
                    }
                    var __ci_expr_logic_3: c_int
                    var __ci_expr_logic_2: c_int
                    if ((if dst_re__goto_169_18.magic_number != 1346589253: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_2 = (if (if dst_re__goto_169_18.name_entry_size > ((128 + 2) + 1): 1 else: 0) != 0: 1 else: 0))
                    }
                    if (__ci_expr_logic_2 != 0) {
                        (__ci_expr_logic_3 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_3 = (if (if dst_re__goto_169_18.name_count > 10000: 1 else: 0) != 0: 1 else: 0))
                    }
                    if (__ci_expr_logic_3 != 0) {
                        (error___goto_172_9 = -62)
                        if (__goto_pending != 0) {
                            break
                        }
                        __pc = 1
                        __goto_pending = 1
                        if (__goto_pending != 0) {
                            break
                        }
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (dst_re__goto_169_18.tables = ((tables__goto_170_10 as *const u8)))
                    if (__goto_pending != 0) {
                        break
                    }
                    (dst_re__goto_169_18.executable_jit = null)
                    if (__goto_pending != 0) {
                        break
                    }
                    (dst_re__goto_169_18.flags = dst_re__goto_169_18.flags | 262144)
                    if (__goto_pending != 0) {
                        break
                    }
                    ((unsafe: codes[i__goto_171_9]) = dst_re__goto_169_18)
                    if (__goto_pending != 0) {
                        break
                    }
                    (dst_re__goto_169_18 = ((null as *mut pcre2_real_code_8)))
                    if (__goto_pending != 0) {
                        break
                    }
                    (src_bytes__goto_168_16 = src_bytes__goto_168_16 + blocksize__goto_206_23)
                    if (__goto_pending != 0) {
                        break
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (i__goto_171_9 = i__goto_171_9 + 1)
                }
                if (__goto_pending != 0) {
                    continue
                }
                return number_of_codes
                if (__goto_pending != 0) {
                    continue
                }
                __pc = 1
                __goto_pending = 1
                continue
            1 =>  // cleanup
                (__goto_pending = 0)
                if ((if dst_re__goto_169_18 != null: 1 else: 0) != 0) {
                    memctl__goto_165_21.free(dst_re__goto_169_18, memctl__goto_165_21.memory_data)
                }
                if (__goto_pending != 0) {
                    continue
                }
                memctl__goto_165_21.free(tables__goto_170_10, memctl__goto_165_21.memory_data)
                if (__goto_pending != 0) {
                    continue
                }
                (j__goto_171_12 = 0)
                while ((if j__goto_171_12 < i__goto_171_9: 1 else: 0) != 0) {
                    memctl__goto_165_21.free((unsafe: codes[j__goto_171_12]), memctl__goto_165_21.memory_data)
                    if (__goto_pending != 0) {
                        break
                    }
                    ((unsafe: codes[j__goto_171_12]) = ((null as *mut pcre2_real_code_8)))
                    if (__goto_pending != 0) {
                        break
                    }
                    if (__goto_pending != 0) {
                        break
                    }
                    (j__goto_171_12 = j__goto_171_12 + 1)
                }
                if (__goto_pending != 0) {
                    continue
                }
                return error___goto_172_9
                if (__goto_pending != 0) {
                    continue
                }
            _ => break
    }
}

fn pcre2_serialize_get_number_of_codes_8(bytes: *const u8) -> c_int {
    var data: *const pcre2_serialized_data = ((bytes as *const pcre2_serialized_data))

    if ((if data == null: 1 else: 0) != 0) {
        return -51
    }

    if ((if data.magic != 1347564115: 1 else: 0) != 0) {
        return -31
    }

    if ((if data.version != 3145738: 1 else: 0) != 0) {
        return -32
    }

    if ((if data.config != (2049 | 524288): 1 else: 0) != 0) {
        return -32
    }

    return data.number_of_codes

}

fn pcre2_serialize_free_8(bytes: *mut u8) {
    if ((if bytes != null: 1 else: 0) != 0) {
        var memctl: *mut pcre2_memctl = (((bytes - sizeof[pcre2_memctl]()) as *mut pcre2_memctl))

        memctl.free(memctl, memctl.memory_data)

    }

}
