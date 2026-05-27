// Migrated from PCRE2
use std.re.defs
use std.re.pcre2_script_run
use std.re.pcre2_xclass
use std.re.pcre2_chkdint
use std.re.pcre2_convert
use std.re.pcre2_substring
use std.re.pcre2_match
use std.re.pcre2_chartables
use std.re.pcre2_extuni
use std.re.pcre2_string_utils
use std.re.pcre2_pattern_info
use std.re.pcre2_match_next
use std.re.pcre2_dfa_match
use std.re.pcre2_maketables
use std.re.pcre2_tables
use std.re.pcre2_compile
use std.re.pcre2_jit_compile
use std.re.pcre2_ord2utf
use std.re.pcre2_compile_cgroup
use std.re.pcre2_compile_class
use std.re.pcre2_substitute
use std.re.pcre2_find_bracket
use std.re.pcre2_ucd
use std.re.pcre2_valid_utf
use std.re.pcre2_study
use std.re.pcre2_context
use std.re.pcre2_newline
use std.re.pcre2posix
use std.re.pcre2_config
use std.re.pcre2_error
use std.re.pcre2_match_data
use std.re.pcre2_serialize
use std.re.pcre2_auto_possess
use std.libc

fn print_char_8(__param_f: *mut c_void, __param_ptr: *const u8, __param_utf: c_int) -> c_uint {
    var __local_c: c_uint = (unsafe: *__param_ptr)

    var __local_one_code_unit: c_int = (if not (__param_utf != 0): 1 else: 0)

    if (__param_utf != 0) {
        (__local_one_code_unit = (if __local_c < 128: 1 else: 0))

    }

    if (__local_one_code_unit != 0) {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_c >= 32: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_c < 127: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            fprintf(__param_f, "%c", __local_c)
        } else {
            (__local_c = __local_c)

            if ((if __local_c < 128: 1 else: 0) != 0) {
                fprintf(__param_f, "\\x%02x", __local_c)
            } else {
                fprintf(__param_f, "\\x{%02x}", __local_c)
            }

        }


        return 0

    }

    if ((if ((__local_c as c_uint) & (192 as c_uint)) != 192: 1 else: 0) != 0) {
        fprintf(__param_f, "\\X{%x}", __local_c)

        return 0

    } else {
        var __local_i: c_int

        var __local_a: c_int = utf8_table4[((__local_c as c_uint) & (63 as c_uint))]

        var __local_s: c_int = (6 * __local_a)

        (__local_c = (((__local_c as c_uint) & (utf8_table3[__local_a] as c_uint)) as c_uint) << (__local_s as c_uint))

        (__local_i = 1)

        while ((if __local_i <= __local_a: 1 else: 0) != 0) {
            if ((if (((unsafe: __param_ptr[__local_i]) as c_int) & 192) != 128: 1 else: 0) != 0) {
                fprintf(__param_f, "\\X{%x}", __local_c)

                return (__local_i - 1)

            }

            (__local_s = __local_s - 6)

            (__local_c = __local_c | (((((unsafe: __param_ptr[__local_i]) as c_int) & 63) as c_int) << (__local_s as c_uint)))


            (__local_i = __local_i + 1)

        }


        fprintf(__param_f, "\\x{%x}", __local_c)

        return __local_a

    }

}

fn print_custring_8(__param_f: *mut c_void, __param_ptr: *const u8) {
    var __local_ptr = __param_ptr
    while ((if (unsafe: *__local_ptr) != 0: 1 else: 0) != 0) {
        var __local_c: c_uint = with 0 as __ci_expr_seq_7 {
            var __ci_expr_old_0: *const u8 = __local_ptr
            (__local_ptr = __local_ptr + 1)
            (unsafe: *__ci_expr_old_0)
        }

        var __ci_expr_logic_1: c_int = 0

        if ((if __local_c >= 32: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if __local_c < 127: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            fprintf(__param_f, "%c", __local_c)
        } else {
            fprintf(__param_f, "\\x{%x}", __local_c)
        }


    }

}

fn print_custring_bylen_8(__param_f: *mut c_void, __param_ptr: *const u8, __param_len: u8) {
    var __local_ptr = __param_ptr
    var __local_len = __param_len
    while ((if __local_len > 0: 1 else: 0) != 0) {
        var __local_c: c_uint = with 0 as __ci_expr_seq_18 {
            var __ci_expr_old_0: *const u8 = __local_ptr
            (__local_ptr = __local_ptr + 1)
            (unsafe: *__ci_expr_old_0)
        }

        var __ci_expr_logic_1: c_int = 0

        if ((if __local_c >= 32: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if __local_c < 127: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            fprintf(__param_f, "%c", __local_c)
        } else {
            fprintf(__param_f, "\\x{%x}", __local_c)
        }



        (__local_len = __local_len - 1)

    }

}

fn get_ucpname_8(__param_ptype: c_uint, __param_pvalue: c_uint) -> *const i8 {
    var __local_count: c_int = 0

    var __local_yield_: *const c_char = (("??" as *const c_char))

    var __local_len: c_ulong = 0

    var __local_ptypex: c_uint = with 0 as __ci_expr_seq_12 {
        var __ci_expr_ternary_0: c_uint = 0
        if ((if __param_ptype == 3: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = 4)
        } else {
            (__ci_expr_ternary_0 = __param_ptype)
        }
        __ci_expr_ternary_0
    }

    var __local_i: c_long = 509

    while ((if __local_i >= 0: 1 else: 0) != 0) {
        var __local_u: *const ucp_type_table = ((&(unsafe: utt[0]) as *const ucp_type_table) + ((__local_i as isize) as usize))

        var __ci_expr_logic_2: c_int = 0

        var __ci_expr_logic_1: c_int

        if ((if __param_ptype == __local_u.type_: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if __local_ptypex == __local_u.type_: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if (if __param_pvalue == __local_u.value: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            var __local_s: *const c_char = ((((&(unsafe: utt_names[0]) as *const c_char) + ((__local_u.name_offset as c_uint) as usize)) as *const c_char))

            var __local_sl: c_ulong = string_len(__local_s)

            var __ci_expr_logic_4: c_int = 0

            if ((if __local_sl == 3: 1 else: 0) != 0) {
                var __ci_expr_logic_3: c_int

                if ((if __local_u.type_ == 3: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_3 = (if (if __local_u.type_ == 4: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_4 != 0) {
                (__local_yield_ = ((__local_s as *const c_char)))

                break

            }


            if ((if __local_sl > __local_len: 1 else: 0) != 0) {
                (__local_yield_ = ((__local_s as *const c_char)))

                (__local_len = __local_sl)

            }

            (__local_count = __local_count + 1)

            if ((if __local_count >= 2: 1 else: 0) != 0) {
                break
            }


        }



        (__local_i = __local_i - 1)

    }


    return __local_yield_

}

fn print_prop_8(__param_f: *mut c_void, __param_code: *const u8, __param_before: *const i8, __param_after: *const i8) {
    if ((if (unsafe: __param_code[1]) != 9: 1 else: 0) != 0) {
        var __local_sc: *const c_char = with 0 as __ci_expr_seq_9 {
            var __ci_expr_ternary_0: *mut c_char = null
            if ((if (unsafe: __param_code[1]) == 3: 1 else: 0) != 0) {
                (__ci_expr_ternary_0 = (("script:" as *mut c_char)))
            } else {
                (__ci_expr_ternary_0 = (("" as *mut c_char)))
            }
            (__ci_expr_ternary_0 as *const c_char)
        }

        var __local_s: *const c_char = ((get_ucpname_8((unsafe: __param_code[1]), (unsafe: __param_code[2])) as *const c_char))

        fprintf(__param_f, "%s%s %s%c%s%s", __param_before, OP_names[(unsafe: *__param_code)], __local_sc, toupper((unsafe: __local_s[0])), (__local_s + ((1 as isize) as usize)), __param_after)

    } else {
        var __local_p: *const c_uint = ((&(unsafe: ucd_caseless_sets[0]) as *const c_uint) + (((unsafe: __param_code[2]) as c_uint) as usize))

        var __ci_expr_ternary_1: *mut c_char = null

        if ((if (unsafe: *__param_code) == OP_PROP: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = (("" as *mut c_char)))
        } else {
            (__ci_expr_ternary_1 = (("not " as *mut c_char)))
        }

        fprintf(__param_f, "%s%sclist", __param_before, __ci_expr_ternary_1)


        while ((if (unsafe: *__local_p) < 4294967295: 1 else: 0) != 0) {
            var __ci_expr_old_2: *const c_uint = __local_p

            (__local_p = __local_p + 1)

            fprintf(__param_f, " %04x", (unsafe: *__ci_expr_old_2))

        }

        fprintf(__param_f, "%s", __param_after)

    }

}

fn print_char_list_8(__param_f: *mut c_void, __param_code: *const u8, __param_char_lists_end: *const u8) -> *const u8 {
    var __local_code = __param_code
    var __local_type_: c_uint

    var __local_list_ind: c_uint


    var __local_char_list_add: c_uint = 0

    var __local_range_start: c_uint = (~(0 as c_uint))

    var __local_range_end: c_uint = 0


    var __local_next_char: *const u8

    (__local_type_ = (((((unsafe: __local_code[0]) as c_int) << (8 as c_uint)) as c_uint) as c_uint) | (((unsafe: __local_code[1]) as c_int) as c_uint))

    (__local_code = __local_code + ((2 as isize) as usize))

    (__local_next_char = __param_char_lists_end - ((((((((unsafe: __local_code[0]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code[(0 + 1)]) as c_int)) as c_uint) as c_uint) << (1 as c_uint)) as usize))

    (__local_type_ = __local_type_ & 4095)

    (__local_list_ind = 0)

    if ((if ((__local_type_ as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
        (__local_range_start = 256)
    }

    while ((if __local_type_ > 0: 1 else: 0) != 0) {
        var __local_item_count: c_uint = ((__local_type_ as c_uint) & (3 as c_uint))

        if ((if __local_item_count == 3: 1 else: 0) != 0) {
            if ((if __local_list_ind <= 1: 1 else: 0) != 0) {
                (__local_item_count = (unsafe: *(__local_next_char as *const c_ushort)))

                (__local_next_char = __local_next_char + ((2 as isize) as usize))

            } else {
                (__local_item_count = (unsafe: *(__local_next_char as *const c_uint)))

                (__local_next_char = __local_next_char + ((4 as isize) as usize))

            }

        }

        while ((if __local_item_count > 0: 1 else: 0) != 0) {
            if ((if __local_list_ind <= 1: 1 else: 0) != 0) {
                (__local_range_end = (unsafe: *(__local_next_char as *const c_ushort)))

                (__local_next_char = __local_next_char + ((2 as isize) as usize))

            } else {
                (__local_range_end = (unsafe: *(__local_next_char as *const c_uint)))

                (__local_next_char = __local_next_char + ((4 as isize) as usize))

            }

            if ((if ((__local_range_end as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
                (__local_range_end = ((__local_char_list_add as c_uint) +% (((__local_range_end as c_uint) >> (1 as c_uint)) as c_uint)))

                if ((if __local_range_start < __local_range_end: 1 else: 0) != 0) {
                    fprintf(__param_f, "\\x{%x}-", __local_range_start)
                }

                fprintf(__param_f, "\\x{%x}", __local_range_end)

                (__local_range_start = (~(0 as c_uint)))

            } else {
                (__local_range_start = ((__local_char_list_add as c_uint) +% (((__local_range_end as c_uint) >> (1 as c_uint)) as c_uint)))
            }

            (__local_item_count = __local_item_count - 1)

        }

        (__local_list_ind = __local_list_ind + 1)

        (__local_type_ = __local_type_ >> (3 as c_uint))

        if ((if __local_range_start == (~(0 as c_uint)): 1 else: 0) != 0) {
            if ((if ((__local_type_ as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
                if ((if __local_list_ind == 1: 1 else: 0) != 0) {
                    (__local_range_start = 32768)
                } else {
                    if ((if __local_list_ind == 2: 1 else: 0) != 0) {
                        (__local_range_start = 65536)
                    } else {
                        (__local_range_start = 2147483648)
                    }
                }

            }

        } else {
            if ((if ((__local_type_ as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                fprintf(__param_f, "\\x{%x}-", __local_range_start)

                if ((if __local_list_ind == 1: 1 else: 0) != 0) {
                    (__local_range_end = 32767)
                } else {
                    if ((if __local_list_ind == 2: 1 else: 0) != 0) {
                        (__local_range_end = 65535)
                    } else {
                        if ((if __local_list_ind == 3: 1 else: 0) != 0) {
                            (__local_range_end = 2147483647)
                        } else {
                            (__local_range_end = 4294967295)
                        }
                    }
                }

                fprintf(__param_f, "\\x{%x}", __local_range_end)

                (__local_range_start = (~(0 as c_uint)))

            }
        }

        if ((if __local_list_ind == 1: 1 else: 0) != 0) {
            (__local_char_list_add = 32768)
        } else {
            if ((if __local_list_ind == 2: 1 else: 0) != 0) {
                (__local_char_list_add = 0)
            } else {
                (__local_char_list_add = 2147483648)
            }
        }

    }

    return (__local_code + ((2 as isize) as usize))

}

fn print_map_8(__param_f: *mut c_void, __param_map: *const u8, __param_negated: c_int) {
    var __local_map = __param_map
    var __local_first: c_int = 1

    var __local_inverted_map: [32]u8

    var __local_i: c_int

    var __local_input: c_int


    if (__param_negated != 0) {
        (__local_i = 0)

        while ((if __local_i < 32: 1 else: 0) != 0) {
            (__local_inverted_map[__local_i] = 255 ^ ((unsafe: __local_map[__local_i]) as c_int))

            (__local_i = __local_i + 1)

        }


        (__local_map = (&(unsafe: __local_inverted_map[0]) as *const u8))

    }

    (__local_input = 0)

    while ((if __local_input < 256: 1 else: 0) != 0) {
        (__local_i = __local_input)

        if ((if ((((unsafe: __local_map[(__local_i / 8)]) as c_int) as c_uint) & (((1 as c_uint) << ((__local_i & 7) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            var __local_j: c_int

            var __local_jinput: c_int


            (__local_jinput = __local_input)

            while ((if (__local_jinput + 1) < 256: 1 else: 0) != 0) {
                (__local_j = __local_jinput + 1)

                if ((if ((((unsafe: __local_map[(__local_j / 8)]) as c_int) as c_uint) & (((1 as c_uint) << ((__local_j & 7) as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
                    break
                }


                (__local_jinput = __local_jinput + 1)

            }


            (__local_j = __local_jinput)

            var __ci_expr_logic_3: c_int

            var __ci_expr_logic_1: c_int

            var __ci_expr_logic_0: c_int

            if ((if __local_i == 45: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if (if __local_i == 92: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_0 != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if __local_i == 93: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_2: c_int = 0

                if (__local_first != 0) {
                    (__ci_expr_logic_2 = (if (if __local_i == 94: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_3 != 0) {
                fprintf(__param_f, "\\")
            }


            var __ci_expr_logic_4: c_int = 0

            if ((if __local_i >= 32: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if (if __local_i < 127: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                fprintf(__param_f, "%c", __local_i)
            } else {
                fprintf(__param_f, "\\x%02x", __local_i)
            }


            (__local_first = 0)

            if ((if __local_jinput > __local_input: 1 else: 0) != 0) {
                if ((if __local_jinput != (__local_input + 1): 1 else: 0) != 0) {
                    fprintf(__param_f, "-")
                }

                var __ci_expr_logic_6: c_int

                var __ci_expr_logic_5: c_int

                if ((if __local_j == 45: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_5 = (if (if __local_j == 92: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_5 != 0) {
                    (__ci_expr_logic_6 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_6 = (if (if __local_j == 93: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_6 != 0) {
                    fprintf(__param_f, "\\")
                }


                var __ci_expr_logic_7: c_int = 0

                if ((if __local_j >= 32: 1 else: 0) != 0) {
                    (__ci_expr_logic_7 = (if (if __local_j < 127: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_7 != 0) {
                    fprintf(__param_f, "%c", __local_j)
                } else {
                    fprintf(__param_f, "\\x%02x", __local_j)
                }


            }

            (__local_input = __local_jinput)

        }


        (__local_input = __local_input + 1)

    }


}

fn print_class_8(__param_f: *mut c_void, __param_type_: c_int, __param_code: *const u8, __param_char_lists_end: *const u8, __param_utf: c_int, __param_before: *const i8, __param_after: *const i8) {
    var __local_printmap: c_int

    var __local_negated: c_int


    var __local_ccode: *const u8

    if ((if __param_type_ == OP_XCLASS: 1 else: 0) != 0) {
        (__local_ccode = __param_code + ((2 as isize) as usize))

        (__local_printmap = (if (((unsafe: *__local_ccode) as c_int) & 2) != 0: 1 else: 0))

        (__local_negated = (if (((unsafe: *__local_ccode) as c_int) & 1) != 0: 1 else: 0))

        (__local_ccode = __local_ccode + 1)

    } else {
        (__local_printmap = 1)

        (__local_negated = (if __param_type_ == OP_NCLASS: 1 else: 0))

        (__local_ccode = __param_code)

    }

    var __ci_expr_ternary_0: *mut c_char = null

    if (__local_negated != 0) {
        (__ci_expr_ternary_0 = (("^" as *mut c_char)))
    } else {
        (__ci_expr_ternary_0 = (("" as *mut c_char)))
    }

    fprintf(__param_f, "%s[%s", __param_before, __ci_expr_ternary_0)


    if (__local_printmap != 0) {
        print_map_8(__param_f, __local_ccode, __local_negated)

        (__local_ccode = __local_ccode + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))

    }

    if ((if __param_type_ == OP_XCLASS: 1 else: 0) != 0) {
        var __local_ch: u8

        while true {
            var __ci_expr_old_1: *const u8 = __local_ccode

            (__local_ccode = __local_ccode + 1)

            (__local_ch = (unsafe: *__ci_expr_old_1))

            if (not ((if __local_ch != 0: 1 else: 0) != 0)) {
                break
            }

            var __local_notch: *const c_char = (("" as *const c_char))

            var __ci_expr_ternary_2: c_int = 0

            if (1 != 0) {
                (__ci_expr_ternary_2 = 16)
            } else {
                (__ci_expr_ternary_2 = 4096)
            }

            if ((if __local_ch >= __ci_expr_ternary_2: 1 else: 0) != 0) {
                (__local_ccode = print_char_list_8(__param_f, (__local_ccode - ((1 as isize) as usize)), __param_char_lists_end))

                break

            }

            while true {
                match __local_ch {
                    4 => {
                        (__local_notch = (("^" as *const c_char)))

                        var __local_ptype: c_uint = with 0 as __ci_expr_seq_50 {
                            var __ci_expr_old_3: *const u8 = __local_ccode
                            (__local_ccode = __local_ccode + 1)
                            (unsafe: *__ci_expr_old_3)
                        }

                        var __local_pvalue: c_uint = with 0 as __ci_expr_seq_57 {
                            var __ci_expr_old_4: *const u8 = __local_ccode
                            (__local_ccode = __local_ccode + 1)
                            (unsafe: *__ci_expr_old_4)
                        }

                        var __local_s: *const c_char

                        while true {
                            match __local_ptype {
                                14 => {
                                    fprintf(__param_f, "[:%sgraph:]", __local_notch)
                                },
                                15 => {
                                    fprintf(__param_f, "[:%sprint:]", __local_notch)
                                },
                                16 => {
                                    fprintf(__param_f, "[:%spunct:]", __local_notch)
                                },
                                17 => {
                                    fprintf(__param_f, "[:%sxdigit:]", __local_notch)
                                },
                                _ => {
                                    (__local_s = ((get_ucpname_8(__local_ptype, __local_pvalue) as *const c_char)))

                                    var __ci_expr_ternary_5: c_int = 0

                                    if ((if (unsafe: __local_notch[0]) == 94: 1 else: 0) != 0) {
                                        (__ci_expr_ternary_5 = 80)
                                    } else {
                                        (__ci_expr_ternary_5 = 112)
                                    }

                                    fprintf(__param_f, "\\%c{%c%s}", __ci_expr_ternary_5, toupper((unsafe: __local_s[0])), (__local_s + ((1 as isize) as usize)))


                                },
                            }

                            break

                        }


                    },
                    3 => {
                        var __local_ptype_1: c_uint = with 0 as __ci_expr_seq_85 {
                            var __ci_expr_old_3: *const u8 = __local_ccode
                            (__local_ccode = __local_ccode + 1)
                            (unsafe: *__ci_expr_old_3)
                        }

                        var __local_pvalue_1: c_uint = with 0 as __ci_expr_seq_92 {
                            var __ci_expr_old_4: *const u8 = __local_ccode
                            (__local_ccode = __local_ccode + 1)
                            (unsafe: *__ci_expr_old_4)
                        }

                        var __local_s_1: *const c_char

                        while true {
                            match __local_ptype_1 {
                                14 => {
                                    fprintf(__param_f, "[:%sgraph:]", __local_notch)
                                },
                                15 => {
                                    fprintf(__param_f, "[:%sprint:]", __local_notch)
                                },
                                16 => {
                                    fprintf(__param_f, "[:%spunct:]", __local_notch)
                                },
                                17 => {
                                    fprintf(__param_f, "[:%sxdigit:]", __local_notch)
                                },
                                _ => {
                                    (__local_s_1 = ((get_ucpname_8(__local_ptype_1, __local_pvalue_1) as *const c_char)))

                                    var __ci_expr_ternary_5: c_int = 0

                                    if ((if (unsafe: __local_notch[0]) == 94: 1 else: 0) != 0) {
                                        (__ci_expr_ternary_5 = 80)
                                    } else {
                                        (__ci_expr_ternary_5 = 112)
                                    }

                                    fprintf(__param_f, "\\%c{%c%s}", __ci_expr_ternary_5, toupper((unsafe: __local_s_1[0])), (__local_s_1 + ((1 as isize) as usize)))


                                },
                            }

                            break

                        }

                    },
                    _ => {
                        (__local_ccode = __local_ccode + (((1 as c_uint) +% (print_char_8(__param_f, __local_ccode, __param_utf) as c_uint)) as usize))

                        if ((if __local_ch == 2: 1 else: 0) != 0) {
                            fprintf(__param_f, "-")

                            (__local_ccode = __local_ccode + (((1 as c_uint) +% (print_char_8(__param_f, __local_ccode, __param_utf) as c_uint)) as usize))

                        }

                    },
                }

                break

            }

        }

        do {
            0
        } while (0 != 0)

    }

    fprintf(__param_f, "]%s", __param_after)

}

fn pcre2_printint_8(__param_re: *mut pcre2_real_code_8, __param_f: *mut c_void, __param_print_lengths: c_int) {
    var __local_codestart__goto_654_12: *const u8 = null

    var __local_nametable__goto_654_23: *const u8 = null

    var __local_code__goto_654_34: *const u8 = null

    var __local_nesize__goto_655_10: c_uint = 0

    var __local_utf__goto_656_6: c_int = 0

    var __local_ccode__goto_663_14: *const u8 = null

    var __local_c__goto_664_12: c_uint = 0

    var __local_i__goto_665_7: c_int = 0

    var __local_flag__goto_666_15: *const i8 = null

    var __local_extra__goto_667_16: c_uint = 0

    var __local_entry__goto_751_18: *const u8 = null

    var __local_entry__goto_924_18: *const u8 = null

    var __local_map__goto_967_22: *const u8 = null

    var __local_print_negated__goto_970_12: c_int = 0

    var __local_min__goto_1036_20: c_uint = 0

    var __local_max__goto_1036_25: c_uint = 0

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_ternary_8: c_int = 0

    var __ci_expr_ternary_9: c_int = 0

    var __ci_expr_ternary_10: *mut c_char = null

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_nesize__goto_655_10 = __param_re.name_entry_size)
        (__local_utf__goto_656_6 = (if ((__param_re.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))
        (__local_nametable__goto_654_23 = ((((__param_re as *mut u8) + (sizeof[pcre2_real_code_8]() as usize)) as *const u8)))
        (__local_codestart__goto_654_12 = ((((__param_re as *mut u8) + (__param_re.code_start as usize)) as *const u8)))
        (__local_code__goto_654_34 = __local_codestart__goto_654_12)
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        goto '__ci_bb_2
    }

    '__ci_bb_2 {
        (__local_flag__goto_666_15 = (("  " as *const c_char)))
        (__local_extra__goto_667_16 = 0)
        if (__param_print_lengths != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_3 {
        goto '__ci_bb_1
    }

    '__ci_bb_5 {
        fprintf(__param_f, "%3d ", ((((__local_code__goto_654_34 as usize) -% (__local_codestart__goto_654_12 as usize)) / sizeof[u8]()) as c_int))
        goto '__ci_bb_7
    }

    '__ci_bb_6 {
        fprintf(__param_f, "    ")
        goto '__ci_bb_7
    }

    '__ci_bb_7 {
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        if ((unsafe: *__local_code__goto_654_34) == 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_9 {
        (__local_code__goto_654_34 = __local_code__goto_654_34 + ((((OP_lengths_8[(unsafe: *__local_code__goto_654_34)] as c_int) as c_uint) +% (__local_extra__goto_667_16 as c_uint)) as usize))
        putc(10, __param_f)
        goto '__ci_bb_3
    }

    '__ci_bb_10 {
        fprintf(__param_f, "    %s\n", OP_names[(unsafe: *__local_code__goto_654_34)])
        fprintf(__param_f, "------------------------------------------------------------------\n")
        return
    }

    '__ci_bb_11 {
        fprintf(__param_f, "    ")
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        (__local_code__goto_654_34 = __local_code__goto_654_34 + 1)
        (__local_code__goto_654_34 = __local_code__goto_654_34 + (((1 as c_uint) +% (print_char_8(__param_f, __local_code__goto_654_34, __local_utf__goto_656_6) as c_uint)) as usize))
        goto '__ci_bb_13
    }

    '__ci_bb_13 {
        if ((if (unsafe: *__local_code__goto_654_34) == OP_CHAR: 1 else: 0) != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_14 {
        fprintf(__param_f, "\n")
        goto '__ci_bb_3
    }

    '__ci_bb_15 {
        fprintf(__param_f, " /i ")
        goto '__ci_bb_16
    }

    '__ci_bb_16 {
        (__local_code__goto_654_34 = __local_code__goto_654_34 + 1)
        (__local_code__goto_654_34 = __local_code__goto_654_34 + (((1 as c_uint) +% (print_char_8(__param_f, __local_code__goto_654_34, __local_utf__goto_656_6) as c_uint)) as usize))
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        if ((if (unsafe: *__local_code__goto_654_34) == OP_CHARI: 1 else: 0) != 0) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_18 {
        fprintf(__param_f, "\n")
        goto '__ci_bb_3
    }

    '__ci_bb_19 {
        if (__param_print_lengths != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_20 {
        fprintf(__param_f, "%3d ", (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint))
        goto '__ci_bb_22
    }

    '__ci_bb_21 {
        fprintf(__param_f, "    ")
        goto '__ci_bb_22
    }

    '__ci_bb_22 {
        fprintf(__param_f, "%s %d", OP_names[(unsafe: *__local_code__goto_654_34)], (((((unsafe: __local_code__goto_654_34[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[((1 + 2) + 1)]) as c_int)) as c_uint))
        goto '__ci_bb_9
    }

    '__ci_bb_23 {
        if (__param_print_lengths != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_24 {
        fprintf(__param_f, "%3d ", (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint))
        goto '__ci_bb_26
    }

    '__ci_bb_25 {
        fprintf(__param_f, "    ")
        goto '__ci_bb_26
    }

    '__ci_bb_26 {
        fprintf(__param_f, "%s", OP_names[(unsafe: *__local_code__goto_654_34)])
        goto '__ci_bb_9
    }

    '__ci_bb_27 {
        fprintf(__param_f, "    %s %d", OP_names[(unsafe: *__local_code__goto_654_34)], (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint))
        goto '__ci_bb_9
    }

    '__ci_bb_28 {
        fprintf(__param_f, "%3d %s", (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint), OP_names[(unsafe: *__local_code__goto_654_34)])
        if ((if (unsafe: *__local_code__goto_654_34) == OP_VREVERSE: 1 else: 0) != 0) {
            goto '__ci_bb_29
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_29 {
        fprintf(__param_f, " %d", (((((unsafe: __local_code__goto_654_34[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[((1 + 2) + 1)]) as c_int)) as c_uint))
        goto '__ci_bb_30
    }

    '__ci_bb_30 {
        goto '__ci_bb_9
    }

    '__ci_bb_31 {
        (__local_entry__goto_751_18 = (__local_nametable__goto_654_23 + ((((((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint) as c_uint) *% (__local_nesize__goto_655_10 as c_uint)) as usize)) + ((2 as isize) as usize))
        fprintf(__param_f, " %s %s<", __local_flag__goto_666_15, OP_names[(unsafe: *__local_code__goto_654_34)])
        print_custring_8(__param_f, __local_entry__goto_751_18)
        fprintf(__param_f, ">%d", (((((unsafe: __local_code__goto_654_34[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[((1 + 2) + 1)]) as c_int)) as c_uint))
        goto '__ci_bb_9
    }

    '__ci_bb_32 {
        (__local_c__goto_664_12 = ((((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint)))
        if ((if __local_c__goto_664_12 == 65535: 1 else: 0) != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_33 {
        fprintf(__param_f, "    %s any", OP_names[(unsafe: *__local_code__goto_654_34)])
        goto '__ci_bb_35
    }

    '__ci_bb_34 {
        fprintf(__param_f, "    %s %d", OP_names[(unsafe: *__local_code__goto_654_34)], __local_c__goto_664_12)
        goto '__ci_bb_35
    }

    '__ci_bb_35 {
        goto '__ci_bb_9
    }

    '__ci_bb_36 {
        (__local_flag__goto_666_15 = (("/i" as *const c_char)))
        goto '__ci_bb_37
    }

    '__ci_bb_37 {
        fprintf(__param_f, " %s ", __local_flag__goto_666_15)
        if ((if (unsafe: *__local_code__goto_654_34) >= OP_TYPESTAR: 1 else: 0) != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_38 {
        if ((if (unsafe: __local_code__goto_654_34[1]) == OP_PROP: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe: __local_code__goto_654_34[1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_39 {
        (__local_extra__goto_667_16 = print_char_8(__param_f, (__local_code__goto_654_34 + ((1 as isize) as usize)), __local_utf__goto_656_6))
        goto '__ci_bb_40
    }

    '__ci_bb_40 {
        fprintf(__param_f, "%s", OP_names[(unsafe: *__local_code__goto_654_34)])
        goto '__ci_bb_9
    }

    '__ci_bb_41 {
        print_prop_8(__param_f, (__local_code__goto_654_34 + ((1 as isize) as usize)), "", " ")
        (__local_extra__goto_667_16 = 2)
        goto '__ci_bb_43
    }

    '__ci_bb_42 {
        fprintf(__param_f, "%s", OP_names[(unsafe: __local_code__goto_654_34[1])])
        goto '__ci_bb_43
    }

    '__ci_bb_43 {
        goto '__ci_bb_40
    }

    '__ci_bb_44 {
        (__local_flag__goto_666_15 = (("/i" as *const c_char)))
        goto '__ci_bb_45
    }

    '__ci_bb_45 {
        fprintf(__param_f, " %s ", __local_flag__goto_666_15)
        (__local_extra__goto_667_16 = print_char_8(__param_f, ((__local_code__goto_654_34 + ((1 as isize) as usize)) + ((2 as isize) as usize)), __local_utf__goto_656_6))
        fprintf(__param_f, "{")
        (__ci_expr_logic_1 = 0)
        if ((if (unsafe: *__local_code__goto_654_34) != OP_EXACT: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe: *__local_code__goto_654_34) != OP_EXACTI: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_46 {
        fprintf(__param_f, "0,")
        goto '__ci_bb_47
    }

    '__ci_bb_47 {
        fprintf(__param_f, "%d}", (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint))
        if ((if (unsafe: *__local_code__goto_654_34) == OP_MINUPTO: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if (unsafe: *__local_code__goto_654_34) == OP_MINUPTOI: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_48
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_48 {
        fprintf(__param_f, "?")
        goto '__ci_bb_50
    }

    '__ci_bb_49 {
        if ((if (unsafe: *__local_code__goto_654_34) == OP_POSUPTO: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if (unsafe: *__local_code__goto_654_34) == OP_POSUPTOI: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_50 {
        goto '__ci_bb_9
    }

    '__ci_bb_51 {
        fprintf(__param_f, "+")
        goto '__ci_bb_52
    }

    '__ci_bb_52 {
        goto '__ci_bb_50
    }

    '__ci_bb_53 {
        if ((if (unsafe: __local_code__goto_654_34[(1 + 2)]) == OP_PROP: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_4 = (if (if (unsafe: __local_code__goto_654_34[(1 + 2)]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_54
        } else {
            goto '__ci_bb_55
        }
    }

    '__ci_bb_54 {
        print_prop_8(__param_f, ((__local_code__goto_654_34 + ((2 as isize) as usize)) + ((1 as isize) as usize)), "    ", " ")
        (__local_extra__goto_667_16 = 2)
        goto '__ci_bb_56
    }

    '__ci_bb_55 {
        fprintf(__param_f, "    %s", OP_names[(unsafe: __local_code__goto_654_34[(1 + 2)])])
        goto '__ci_bb_56
    }

    '__ci_bb_56 {
        fprintf(__param_f, "{")
        if ((if (unsafe: *__local_code__goto_654_34) != OP_TYPEEXACT: 1 else: 0) != 0) {
            goto '__ci_bb_57
        } else {
            goto '__ci_bb_58
        }
    }

    '__ci_bb_57 {
        fprintf(__param_f, "0,")
        goto '__ci_bb_58
    }

    '__ci_bb_58 {
        fprintf(__param_f, "%d}", (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint))
        if ((if (unsafe: *__local_code__goto_654_34) == OP_TYPEMINUPTO: 1 else: 0) != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_59 {
        fprintf(__param_f, "?")
        goto '__ci_bb_61
    }

    '__ci_bb_60 {
        if ((if (unsafe: *__local_code__goto_654_34) == OP_TYPEPOSUPTO: 1 else: 0) != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_63
        }
    }

    '__ci_bb_61 {
        goto '__ci_bb_9
    }

    '__ci_bb_62 {
        fprintf(__param_f, "+")
        goto '__ci_bb_63
    }

    '__ci_bb_63 {
        goto '__ci_bb_61
    }

    '__ci_bb_64 {
        (__local_flag__goto_666_15 = (("/i" as *const c_char)))
        goto '__ci_bb_65
    }

    '__ci_bb_65 {
        fprintf(__param_f, " %s [^", __local_flag__goto_666_15)
        (__local_extra__goto_667_16 = print_char_8(__param_f, (__local_code__goto_654_34 + ((1 as isize) as usize)), __local_utf__goto_656_6))
        fprintf(__param_f, "] (not)")
        goto '__ci_bb_9
    }

    '__ci_bb_66 {
        (__local_flag__goto_666_15 = (("/i" as *const c_char)))
        goto '__ci_bb_67
    }

    '__ci_bb_67 {
        fprintf(__param_f, " %s [^", __local_flag__goto_666_15)
        (__local_extra__goto_667_16 = print_char_8(__param_f, (__local_code__goto_654_34 + ((1 as isize) as usize)), __local_utf__goto_656_6))
        fprintf(__param_f, "]%s (not)", OP_names[(unsafe: *__local_code__goto_654_34)])
        goto '__ci_bb_9
    }

    '__ci_bb_68 {
        (__local_flag__goto_666_15 = (("/i" as *const c_char)))
        goto '__ci_bb_69
    }

    '__ci_bb_69 {
        fprintf(__param_f, " %s [^", __local_flag__goto_666_15)
        (__local_extra__goto_667_16 = print_char_8(__param_f, ((__local_code__goto_654_34 + ((1 as isize) as usize)) + ((2 as isize) as usize)), __local_utf__goto_656_6))
        fprintf(__param_f, "]{")
        (__ci_expr_logic_5 = 0)
        if ((if (unsafe: *__local_code__goto_654_34) != OP_NOTEXACT: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if (unsafe: *__local_code__goto_654_34) != OP_NOTEXACTI: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_70
        } else {
            goto '__ci_bb_71
        }
    }

    '__ci_bb_70 {
        fprintf(__param_f, "0,")
        goto '__ci_bb_71
    }

    '__ci_bb_71 {
        fprintf(__param_f, "%d}", (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint))
        if ((if (unsafe: *__local_code__goto_654_34) == OP_NOTMINUPTO: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if (unsafe: *__local_code__goto_654_34) == OP_NOTMINUPTOI: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_73
        }
    }

    '__ci_bb_72 {
        fprintf(__param_f, "?")
        goto '__ci_bb_74
    }

    '__ci_bb_73 {
        if ((if (unsafe: *__local_code__goto_654_34) == OP_NOTPOSUPTO: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_7 = (if (if (unsafe: *__local_code__goto_654_34) == OP_NOTPOSUPTOI: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_76
        }
    }

    '__ci_bb_74 {
        fprintf(__param_f, " (not)")
        goto '__ci_bb_9
    }

    '__ci_bb_75 {
        fprintf(__param_f, "+")
        goto '__ci_bb_76
    }

    '__ci_bb_76 {
        goto '__ci_bb_74
    }

    '__ci_bb_77 {
        if (__param_print_lengths != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_78 {
        fprintf(__param_f, "%3d ", (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint))
        goto '__ci_bb_80
    }

    '__ci_bb_79 {
        fprintf(__param_f, "    ")
        goto '__ci_bb_80
    }

    '__ci_bb_80 {
        fprintf(__param_f, "%s", OP_names[(unsafe: *__local_code__goto_654_34)])
        goto '__ci_bb_9
    }

    '__ci_bb_81 {
        (__local_flag__goto_666_15 = (("/i" as *const c_char)))
        goto '__ci_bb_82
    }

    '__ci_bb_82 {
        fprintf(__param_f, " %s \\g{%d}", __local_flag__goto_666_15, (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint))
        (__ci_expr_ternary_8 = 0)
        if ((if (unsafe: *__local_code__goto_654_34) == OP_REFI: 1 else: 0) != 0) {
            (__ci_expr_ternary_8 = (unsafe: __local_code__goto_654_34[(1 + 2)]))
        } else {
            (__ci_expr_ternary_8 = 0)
        }
        (__local_i__goto_665_7 = __ci_expr_ternary_8)
        if ((if __local_i__goto_665_7 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_84
        }
    }

    '__ci_bb_83 {
        fprintf(__param_f, " 0x%02x", __local_i__goto_665_7)
        goto '__ci_bb_84
    }

    '__ci_bb_84 {
        (__local_ccode__goto_663_14 = __local_code__goto_654_34 + ((OP_lengths_8[(unsafe: *__local_code__goto_654_34)] as c_uint) as usize))
        goto '__ci_bb_85
    }

    '__ci_bb_85 {
        goto '__ci_bb_124
    }

    '__ci_bb_86 {
        (__local_flag__goto_666_15 = (("/i" as *const c_char)))
        goto '__ci_bb_87
    }

    '__ci_bb_87 {
        (__local_entry__goto_924_18 = (__local_nametable__goto_654_23 + ((((((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint) as c_uint) *% (__local_nesize__goto_655_10 as c_uint)) as usize)) + ((2 as isize) as usize))
        fprintf(__param_f, " %s \\k<", __local_flag__goto_666_15)
        print_custring_8(__param_f, __local_entry__goto_924_18)
        fprintf(__param_f, ">%d", (((((unsafe: __local_code__goto_654_34[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[((1 + 2) + 1)]) as c_int)) as c_uint))
        (__ci_expr_ternary_9 = 0)
        if ((if (unsafe: *__local_code__goto_654_34) == OP_DNREFI: 1 else: 0) != 0) {
            (__ci_expr_ternary_9 = (unsafe: __local_code__goto_654_34[(1 + (2 * 2))]))
        } else {
            (__ci_expr_ternary_9 = 0)
        }
        (__local_i__goto_665_7 = __ci_expr_ternary_9)
        if ((if __local_i__goto_665_7 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_88 {
        fprintf(__param_f, " 0x%02x", __local_i__goto_665_7)
        goto '__ci_bb_89
    }

    '__ci_bb_89 {
        (__local_ccode__goto_663_14 = __local_code__goto_654_34 + ((OP_lengths_8[(unsafe: *__local_code__goto_654_34)] as c_uint) as usize))
        goto '__ci_bb_85
    }

    '__ci_bb_90 {
        fprintf(__param_f, "    %s %d %d %d", OP_names[(unsafe: *__local_code__goto_654_34)], (unsafe: __local_code__goto_654_34[(1 + (2 * 2))]), (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint), (((((unsafe: __local_code__goto_654_34[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[((1 + 2) + 1)]) as c_int)) as c_uint))
        goto '__ci_bb_9
    }

    '__ci_bb_91 {
        (__local_c__goto_664_12 = (unsafe: __local_code__goto_654_34[(1 + (4 * 2))]))
        fprintf(__param_f, "    %s %c", OP_names[(unsafe: *__local_code__goto_654_34)], __local_c__goto_664_12)
        (__local_extra__goto_667_16 = ((((((unsafe: __local_code__goto_654_34[(1 + (2 * 2))]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[((1 + (2 * 2)) + 1)]) as c_int)) as c_uint)))
        print_custring_bylen_8(__param_f, ((__local_code__goto_654_34 + ((2 as isize) as usize)) + (((4 * 2) as isize) as usize)), ((((__local_extra__goto_667_16 as c_uint) -% (3 as c_uint)) as c_uint) -% (8 as c_uint)))
        (__local_i__goto_665_7 = 0)
        goto '__ci_bb_92
    }

    '__ci_bb_92 {
        if ((if callout_start_delims[__local_i__goto_665_7] != 0: 1 else: 0) != 0) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_93 {
        if ((if __local_c__goto_664_12 == callout_start_delims[__local_i__goto_665_7]: 1 else: 0) != 0) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_97
        }
    }

    '__ci_bb_94 {
        (__local_i__goto_665_7 = __local_i__goto_665_7 + 1)
        goto '__ci_bb_92
    }

    '__ci_bb_95 {
        fprintf(__param_f, "%c %d %d %d", __local_c__goto_664_12, (((((unsafe: __local_code__goto_654_34[(1 + (3 * 2))]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[((1 + (3 * 2)) + 1)]) as c_int)) as c_uint), (((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint), (((((unsafe: __local_code__goto_654_34[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[((1 + 2) + 1)]) as c_int)) as c_uint))
        goto '__ci_bb_9
    }

    '__ci_bb_96 {
        (__local_c__goto_664_12 = callout_end_delims[__local_i__goto_665_7])
        goto '__ci_bb_95
    }

    '__ci_bb_97 {
        goto '__ci_bb_94
    }

    '__ci_bb_98 {
        print_prop_8(__param_f, __local_code__goto_654_34, "    ", "")
        goto '__ci_bb_9
    }

    '__ci_bb_99 {
        (__local_extra__goto_667_16 = ((((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint)))
        fprintf(__param_f, "    eclass[\n")
        (__local_ccode__goto_663_14 = ((__local_code__goto_654_34 + ((1 as isize) as usize)) + ((2 as isize) as usize)) + ((1 as isize) as usize))
        if ((if (((unsafe: __local_ccode__goto_663_14[-1]) as c_int) & 1) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_101
        }
    }

    '__ci_bb_100 {
        (__local_map__goto_967_22 = __local_ccode__goto_663_14)
        (__local_print_negated__goto_970_12 = (if (((unsafe: __local_map__goto_967_22[0]) as c_int) & 126) == 126: 1 else: 0))
        (__ci_expr_ternary_10 = null)
        if (__local_print_negated__goto_970_12 != 0) {
            (__ci_expr_ternary_10 = (("^" as *mut c_char)))
        } else {
            (__ci_expr_ternary_10 = (("" as *mut c_char)))
        }
        fprintf(__param_f, "          bitmap: [%s", __ci_expr_ternary_10)
        print_map_8(__param_f, __local_map__goto_967_22, __local_print_negated__goto_970_12)
        fprintf(__param_f, "]\n")
        (__local_ccode__goto_663_14 = __local_ccode__goto_663_14 + (((32 as c_ulong) / (sizeof[u8]() as c_ulong)) as usize))
        goto '__ci_bb_102
    }

    '__ci_bb_101 {
        fprintf(__param_f, "          no bitmap\n")
        goto '__ci_bb_102
    }

    '__ci_bb_102 {
        goto '__ci_bb_103
    }

    '__ci_bb_103 {
        if ((if __local_ccode__goto_663_14 < (__local_code__goto_654_34 + (__local_extra__goto_667_16 as usize)): 1 else: 0) != 0) {
            goto '__ci_bb_104
        } else {
            goto '__ci_bb_105
        }
    }

    '__ci_bb_104 {
        if (__param_print_lengths != 0) {
            goto '__ci_bb_106
        } else {
            goto '__ci_bb_107
        }
    }

    '__ci_bb_105 {
        fprintf(__param_f, "        ]")
        goto '__ci_bb_85
    }

    '__ci_bb_106 {
        fprintf(__param_f, "%3d ", ((((__local_ccode__goto_663_14 as usize) -% (__local_codestart__goto_654_12 as usize)) / sizeof[u8]()) as c_int))
        goto '__ci_bb_108
    }

    '__ci_bb_107 {
        fprintf(__param_f, "    ")
        goto '__ci_bb_108
    }

    '__ci_bb_108 {
        goto '__ci_bb_109
    }

    '__ci_bb_109 {
        if ((unsafe: *__local_ccode__goto_663_14) == 1) {
            goto '__ci_bb_111
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_110 {
        goto '__ci_bb_103
    }

    '__ci_bb_111 {
        fprintf(__param_f, "      AND\n")
        (__local_ccode__goto_663_14 = __local_ccode__goto_663_14 + ((1 as isize) as usize))
        goto '__ci_bb_110
    }

    '__ci_bb_112 {
        fprintf(__param_f, "      OR\n")
        (__local_ccode__goto_663_14 = __local_ccode__goto_663_14 + ((1 as isize) as usize))
        goto '__ci_bb_110
    }

    '__ci_bb_113 {
        fprintf(__param_f, "      XOR\n")
        (__local_ccode__goto_663_14 = __local_ccode__goto_663_14 + ((1 as isize) as usize))
        goto '__ci_bb_110
    }

    '__ci_bb_114 {
        fprintf(__param_f, "      NOT\n")
        (__local_ccode__goto_663_14 = __local_ccode__goto_663_14 + ((1 as isize) as usize))
        goto '__ci_bb_110
    }

    '__ci_bb_115 {
        print_class_8(__param_f, OP_XCLASS, (__local_ccode__goto_663_14 + ((1 as isize) as usize)), (__local_codestart__goto_654_12 as *mut u8), __local_utf__goto_656_6, "      xclass: ", "\n")
        (__local_ccode__goto_663_14 = __local_ccode__goto_663_14 + ((((((unsafe: __local_ccode__goto_663_14[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_ccode__goto_663_14[(1 + 1)]) as c_int)) as c_uint) as usize))
        goto '__ci_bb_110
    }

    '__ci_bb_116 {
        fprintf(__param_f, "      UNEXPECTED\n")
        (__local_ccode__goto_663_14 = __local_ccode__goto_663_14 + ((1 as isize) as usize))
        goto '__ci_bb_110
    }

    '__ci_bb_117 {
        if ((unsafe: *__local_ccode__goto_663_14) == 2) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_118
        }
    }

    '__ci_bb_118 {
        if ((unsafe: *__local_ccode__goto_663_14) == 3) {
            goto '__ci_bb_113
        } else {
            goto '__ci_bb_119
        }
    }

    '__ci_bb_119 {
        if ((unsafe: *__local_ccode__goto_663_14) == 4) {
            goto '__ci_bb_114
        } else {
            goto '__ci_bb_120
        }
    }

    '__ci_bb_120 {
        if ((unsafe: *__local_ccode__goto_663_14) == 5) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_116
        }
    }

    '__ci_bb_121 {
        if ((if (unsafe: *__local_code__goto_654_34) == OP_XCLASS: 1 else: 0) != 0) {
            goto '__ci_bb_122
        } else {
            goto '__ci_bb_123
        }
    }

    '__ci_bb_122 {
        (__local_extra__goto_667_16 = ((((((unsafe: __local_code__goto_654_34[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_code__goto_654_34[(1 + 1)]) as c_int)) as c_uint)))
        goto '__ci_bb_123
    }

    '__ci_bb_123 {
        print_class_8(__param_f, (unsafe: *__local_code__goto_654_34), (__local_code__goto_654_34 + ((1 as isize) as usize)), (__local_codestart__goto_654_12 as *mut u8), __local_utf__goto_656_6, "    ", "")
        (__local_ccode__goto_663_14 = (__local_code__goto_654_34 + ((OP_lengths_8[(unsafe: *__local_code__goto_654_34)] as c_uint) as usize)) + (__local_extra__goto_667_16 as usize))
        goto '__ci_bb_85
    }

    '__ci_bb_124 {
        if ((unsafe: *__local_ccode__goto_663_14) == 98) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_125 {
        goto '__ci_bb_9
    }

    '__ci_bb_126 {
        fprintf(__param_f, "%s", OP_names[(unsafe: *__local_ccode__goto_663_14)])
        (__local_extra__goto_667_16 = __local_extra__goto_667_16 + OP_lengths_8[(unsafe: *__local_ccode__goto_663_14)])
        goto '__ci_bb_125
    }

    '__ci_bb_127 {
        (__local_min__goto_1036_20 = ((((((unsafe: __local_ccode__goto_663_14[1]) as c_int) << (8 as c_uint)) | ((unsafe: __local_ccode__goto_663_14[(1 + 1)]) as c_int)) as c_uint)))
        (__local_max__goto_1036_25 = ((((((unsafe: __local_ccode__goto_663_14[(1 + 2)]) as c_int) << (8 as c_uint)) | ((unsafe: __local_ccode__goto_663_14[((1 + 2) + 1)]) as c_int)) as c_uint)))
        if ((if __local_max__goto_1036_25 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_128
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_128 {
        fprintf(__param_f, "{%u,}", __local_min__goto_1036_20)
        goto '__ci_bb_130
    }

    '__ci_bb_129 {
        fprintf(__param_f, "{%u,%u}", __local_min__goto_1036_20, __local_max__goto_1036_25)
        goto '__ci_bb_130
    }

    '__ci_bb_130 {
        if ((if (unsafe: *__local_ccode__goto_663_14) == OP_CRMINRANGE: 1 else: 0) != 0) {
            goto '__ci_bb_131
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_131 {
        fprintf(__param_f, "?")
        goto '__ci_bb_133
    }

    '__ci_bb_132 {
        if ((if (unsafe: *__local_ccode__goto_663_14) == OP_CRPOSRANGE: 1 else: 0) != 0) {
            goto '__ci_bb_134
        } else {
            goto '__ci_bb_135
        }
    }

    '__ci_bb_133 {
        (__local_extra__goto_667_16 = __local_extra__goto_667_16 + OP_lengths_8[(unsafe: *__local_ccode__goto_663_14)])
        goto '__ci_bb_125
    }

    '__ci_bb_134 {
        fprintf(__param_f, "+")
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        goto '__ci_bb_133
    }

    '__ci_bb_136 {
        goto '__ci_bb_125
    }

    '__ci_bb_137 {
        if ((unsafe: *__local_ccode__goto_663_14) == 99) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_138 {
        if ((unsafe: *__local_ccode__goto_663_14) == 100) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_139 {
        if ((unsafe: *__local_ccode__goto_663_14) == 101) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_140 {
        if ((unsafe: *__local_ccode__goto_663_14) == 102) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_141 {
        if ((unsafe: *__local_ccode__goto_663_14) == 103) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_142
        }
    }

    '__ci_bb_142 {
        if ((unsafe: *__local_ccode__goto_663_14) == 106) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_143 {
        if ((unsafe: *__local_ccode__goto_663_14) == 107) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_144
        }
    }

    '__ci_bb_144 {
        if ((unsafe: *__local_ccode__goto_663_14) == 108) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_145 {
        if ((unsafe: *__local_ccode__goto_663_14) == 104) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_146 {
        if ((unsafe: *__local_ccode__goto_663_14) == 105) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_147 {
        if ((unsafe: *__local_ccode__goto_663_14) == 109) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_148 {
        fprintf(__param_f, "    %s ", OP_names[(unsafe: *__local_code__goto_654_34)])
        print_custring_bylen_8(__param_f, (__local_code__goto_654_34 + ((2 as isize) as usize)), (unsafe: __local_code__goto_654_34[1]))
        (__local_extra__goto_667_16 = __local_extra__goto_667_16 + (unsafe: __local_code__goto_654_34[1]))
        goto '__ci_bb_9
    }

    '__ci_bb_149 {
        (__local_flag__goto_666_15 = (("/m" as *const c_char)))
        goto '__ci_bb_150
    }

    '__ci_bb_150 {
        fprintf(__param_f, " %s %s", __local_flag__goto_666_15, OP_names[(unsafe: *__local_code__goto_654_34)])
        goto '__ci_bb_9
    }

    '__ci_bb_151 {
        if ((unsafe: *__local_code__goto_654_34) == 29) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_152
        }
    }

    '__ci_bb_152 {
        if ((unsafe: *__local_code__goto_654_34) == 30) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_153 {
        if ((unsafe: *__local_code__goto_654_34) == 139) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_154 {
        if ((unsafe: *__local_code__goto_654_34) == 140) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_155
        }
    }

    '__ci_bb_155 {
        if ((unsafe: *__local_code__goto_654_34) == 144) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_156 {
        if ((unsafe: *__local_code__goto_654_34) == 145) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_157
        }
    }

    '__ci_bb_157 {
        if ((unsafe: *__local_code__goto_654_34) == 137) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_158 {
        if ((unsafe: *__local_code__goto_654_34) == 138) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_159 {
        if ((unsafe: *__local_code__goto_654_34) == 142) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_160 {
        if ((unsafe: *__local_code__goto_654_34) == 143) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_161
        }
    }

    '__ci_bb_161 {
        if ((unsafe: *__local_code__goto_654_34) == 123) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_162
        }
    }

    '__ci_bb_162 {
        if ((unsafe: *__local_code__goto_654_34) == 124) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_163 {
        if ((unsafe: *__local_code__goto_654_34) == 125) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_164
        }
    }

    '__ci_bb_164 {
        if ((unsafe: *__local_code__goto_654_34) == 121) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_165 {
        if ((unsafe: *__local_code__goto_654_34) == 122) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_166
        }
    }

    '__ci_bb_166 {
        if ((unsafe: *__local_code__goto_654_34) == 128) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_167
        }
    }

    '__ci_bb_167 {
        if ((unsafe: *__local_code__goto_654_34) == 129) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_168 {
        if ((unsafe: *__local_code__goto_654_34) == 130) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_169
        }
    }

    '__ci_bb_169 {
        if ((unsafe: *__local_code__goto_654_34) == 131) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_170 {
        if ((unsafe: *__local_code__goto_654_34) == 132) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_171
        }
    }

    '__ci_bb_171 {
        if ((unsafe: *__local_code__goto_654_34) == 133) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_172
        }
    }

    '__ci_bb_172 {
        if ((unsafe: *__local_code__goto_654_34) == 134) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_173 {
        if ((unsafe: *__local_code__goto_654_34) == 135) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_174
        }
    }

    '__ci_bb_174 {
        if ((unsafe: *__local_code__goto_654_34) == 136) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_175 {
        if ((unsafe: *__local_code__goto_654_34) == 141) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_176
        }
    }

    '__ci_bb_176 {
        if ((unsafe: *__local_code__goto_654_34) == 146) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_177 {
        if ((unsafe: *__local_code__goto_654_34) == 168) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_178
        }
    }

    '__ci_bb_178 {
        if ((unsafe: *__local_code__goto_654_34) == 147) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_179 {
        if ((unsafe: *__local_code__goto_654_34) == 126) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_180
        }
    }

    '__ci_bb_180 {
        if ((unsafe: *__local_code__goto_654_34) == 127) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_181 {
        if ((unsafe: *__local_code__goto_654_34) == 148) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_182
        }
    }

    '__ci_bb_182 {
        if ((unsafe: *__local_code__goto_654_34) == 150) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_183 {
        if ((unsafe: *__local_code__goto_654_34) == 149) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_184 {
        if ((unsafe: *__local_code__goto_654_34) == 46) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_185
        }
    }

    '__ci_bb_185 {
        if ((unsafe: *__local_code__goto_654_34) == 47) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_186
        }
    }

    '__ci_bb_186 {
        if ((unsafe: *__local_code__goto_654_34) == 55) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_187
        }
    }

    '__ci_bb_187 {
        if ((unsafe: *__local_code__goto_654_34) == 48) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_188 {
        if ((unsafe: *__local_code__goto_654_34) == 49) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_189
        }
    }

    '__ci_bb_189 {
        if ((unsafe: *__local_code__goto_654_34) == 56) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_190 {
        if ((unsafe: *__local_code__goto_654_34) == 50) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_191
        }
    }

    '__ci_bb_191 {
        if ((unsafe: *__local_code__goto_654_34) == 51) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_192 {
        if ((unsafe: *__local_code__goto_654_34) == 57) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_193
        }
    }

    '__ci_bb_193 {
        if ((unsafe: *__local_code__goto_654_34) == 33) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_194
        }
    }

    '__ci_bb_194 {
        if ((unsafe: *__local_code__goto_654_34) == 34) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_195
        }
    }

    '__ci_bb_195 {
        if ((unsafe: *__local_code__goto_654_34) == 42) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_196
        }
    }

    '__ci_bb_196 {
        if ((unsafe: *__local_code__goto_654_34) == 35) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_197
        }
    }

    '__ci_bb_197 {
        if ((unsafe: *__local_code__goto_654_34) == 36) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_198
        }
    }

    '__ci_bb_198 {
        if ((unsafe: *__local_code__goto_654_34) == 43) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_199
        }
    }

    '__ci_bb_199 {
        if ((unsafe: *__local_code__goto_654_34) == 37) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_200
        }
    }

    '__ci_bb_200 {
        if ((unsafe: *__local_code__goto_654_34) == 38) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_201
        }
    }

    '__ci_bb_201 {
        if ((unsafe: *__local_code__goto_654_34) == 44) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_202
        }
    }

    '__ci_bb_202 {
        if ((unsafe: *__local_code__goto_654_34) == 85) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_203
        }
    }

    '__ci_bb_203 {
        if ((unsafe: *__local_code__goto_654_34) == 86) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_204
        }
    }

    '__ci_bb_204 {
        if ((unsafe: *__local_code__goto_654_34) == 94) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_205
        }
    }

    '__ci_bb_205 {
        if ((unsafe: *__local_code__goto_654_34) == 87) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_206
        }
    }

    '__ci_bb_206 {
        if ((unsafe: *__local_code__goto_654_34) == 88) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_207
        }
    }

    '__ci_bb_207 {
        if ((unsafe: *__local_code__goto_654_34) == 95) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_208
        }
    }

    '__ci_bb_208 {
        if ((unsafe: *__local_code__goto_654_34) == 89) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_209
        }
    }

    '__ci_bb_209 {
        if ((unsafe: *__local_code__goto_654_34) == 90) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_210
        }
    }

    '__ci_bb_210 {
        if ((unsafe: *__local_code__goto_654_34) == 96) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_211
        }
    }

    '__ci_bb_211 {
        if ((unsafe: *__local_code__goto_654_34) == 54) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_212
        }
    }

    '__ci_bb_212 {
        if ((unsafe: *__local_code__goto_654_34) == 52) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_213
        }
    }

    '__ci_bb_213 {
        if ((unsafe: *__local_code__goto_654_34) == 53) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_214
        }
    }

    '__ci_bb_214 {
        if ((unsafe: *__local_code__goto_654_34) == 58) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_215
        }
    }

    '__ci_bb_215 {
        if ((unsafe: *__local_code__goto_654_34) == 41) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_216
        }
    }

    '__ci_bb_216 {
        if ((unsafe: *__local_code__goto_654_34) == 39) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_217
        }
    }

    '__ci_bb_217 {
        if ((unsafe: *__local_code__goto_654_34) == 40) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_218
        }
    }

    '__ci_bb_218 {
        if ((unsafe: *__local_code__goto_654_34) == 45) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_219
        }
    }

    '__ci_bb_219 {
        if ((unsafe: *__local_code__goto_654_34) == 93) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_220
        }
    }

    '__ci_bb_220 {
        if ((unsafe: *__local_code__goto_654_34) == 91) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_221
        }
    }

    '__ci_bb_221 {
        if ((unsafe: *__local_code__goto_654_34) == 92) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_222
        }
    }

    '__ci_bb_222 {
        if ((unsafe: *__local_code__goto_654_34) == 97) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_223
        }
    }

    '__ci_bb_223 {
        if ((unsafe: *__local_code__goto_654_34) == 32) {
            goto '__ci_bb_64
        } else {
            goto '__ci_bb_224
        }
    }

    '__ci_bb_224 {
        if ((unsafe: *__local_code__goto_654_34) == 31) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_225
        }
    }

    '__ci_bb_225 {
        if ((unsafe: *__local_code__goto_654_34) == 72) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_226
        }
    }

    '__ci_bb_226 {
        if ((unsafe: *__local_code__goto_654_34) == 73) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_227
        }
    }

    '__ci_bb_227 {
        if ((unsafe: *__local_code__goto_654_34) == 81) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_228
        }
    }

    '__ci_bb_228 {
        if ((unsafe: *__local_code__goto_654_34) == 74) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_229
        }
    }

    '__ci_bb_229 {
        if ((unsafe: *__local_code__goto_654_34) == 75) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_230
        }
    }

    '__ci_bb_230 {
        if ((unsafe: *__local_code__goto_654_34) == 82) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_231
        }
    }

    '__ci_bb_231 {
        if ((unsafe: *__local_code__goto_654_34) == 76) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_232
        }
    }

    '__ci_bb_232 {
        if ((unsafe: *__local_code__goto_654_34) == 77) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_233
        }
    }

    '__ci_bb_233 {
        if ((unsafe: *__local_code__goto_654_34) == 83) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_234
        }
    }

    '__ci_bb_234 {
        if ((unsafe: *__local_code__goto_654_34) == 59) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_235
        }
    }

    '__ci_bb_235 {
        if ((unsafe: *__local_code__goto_654_34) == 60) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_236
        }
    }

    '__ci_bb_236 {
        if ((unsafe: *__local_code__goto_654_34) == 68) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_237
        }
    }

    '__ci_bb_237 {
        if ((unsafe: *__local_code__goto_654_34) == 61) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_238
        }
    }

    '__ci_bb_238 {
        if ((unsafe: *__local_code__goto_654_34) == 62) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_239
        }
    }

    '__ci_bb_239 {
        if ((unsafe: *__local_code__goto_654_34) == 69) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_240
        }
    }

    '__ci_bb_240 {
        if ((unsafe: *__local_code__goto_654_34) == 63) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_241
        }
    }

    '__ci_bb_241 {
        if ((unsafe: *__local_code__goto_654_34) == 64) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_242
        }
    }

    '__ci_bb_242 {
        if ((unsafe: *__local_code__goto_654_34) == 70) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_243
        }
    }

    '__ci_bb_243 {
        if ((unsafe: *__local_code__goto_654_34) == 80) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_244
        }
    }

    '__ci_bb_244 {
        if ((unsafe: *__local_code__goto_654_34) == 78) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_245
        }
    }

    '__ci_bb_245 {
        if ((unsafe: *__local_code__goto_654_34) == 79) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_246
        }
    }

    '__ci_bb_246 {
        if ((unsafe: *__local_code__goto_654_34) == 84) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_247
        }
    }

    '__ci_bb_247 {
        if ((unsafe: *__local_code__goto_654_34) == 67) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_248
        }
    }

    '__ci_bb_248 {
        if ((unsafe: *__local_code__goto_654_34) == 65) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_249
        }
    }

    '__ci_bb_249 {
        if ((unsafe: *__local_code__goto_654_34) == 66) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_250
        }
    }

    '__ci_bb_250 {
        if ((unsafe: *__local_code__goto_654_34) == 71) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_251
        }
    }

    '__ci_bb_251 {
        if ((unsafe: *__local_code__goto_654_34) == 118) {
            goto '__ci_bb_77
        } else {
            goto '__ci_bb_252
        }
    }

    '__ci_bb_252 {
        if ((unsafe: *__local_code__goto_654_34) == 115) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_253
        }
    }

    '__ci_bb_253 {
        if ((unsafe: *__local_code__goto_654_34) == 114) {
            goto '__ci_bb_82
        } else {
            goto '__ci_bb_254
        }
    }

    '__ci_bb_254 {
        if ((unsafe: *__local_code__goto_654_34) == 117) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_255
        }
    }

    '__ci_bb_255 {
        if ((unsafe: *__local_code__goto_654_34) == 116) {
            goto '__ci_bb_87
        } else {
            goto '__ci_bb_256
        }
    }

    '__ci_bb_256 {
        if ((unsafe: *__local_code__goto_654_34) == 119) {
            goto '__ci_bb_90
        } else {
            goto '__ci_bb_257
        }
    }

    '__ci_bb_257 {
        if ((unsafe: *__local_code__goto_654_34) == 120) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_258
        }
    }

    '__ci_bb_258 {
        if ((unsafe: *__local_code__goto_654_34) == 16) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_259
        }
    }

    '__ci_bb_259 {
        if ((unsafe: *__local_code__goto_654_34) == 15) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_260
        }
    }

    '__ci_bb_260 {
        if ((unsafe: *__local_code__goto_654_34) == 113) {
            goto '__ci_bb_99
        } else {
            goto '__ci_bb_261
        }
    }

    '__ci_bb_261 {
        if ((unsafe: *__local_code__goto_654_34) == 110) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_262
        }
    }

    '__ci_bb_262 {
        if ((unsafe: *__local_code__goto_654_34) == 111) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_263
        }
    }

    '__ci_bb_263 {
        if ((unsafe: *__local_code__goto_654_34) == 112) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_264
        }
    }

    '__ci_bb_264 {
        if ((unsafe: *__local_code__goto_654_34) == 156) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_265
        }
    }

    '__ci_bb_265 {
        if ((unsafe: *__local_code__goto_654_34) == 164) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_266
        }
    }

    '__ci_bb_266 {
        if ((unsafe: *__local_code__goto_654_34) == 158) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_267
        }
    }

    '__ci_bb_267 {
        if ((unsafe: *__local_code__goto_654_34) == 160) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_268
        }
    }

    '__ci_bb_268 {
        if ((unsafe: *__local_code__goto_654_34) == 162) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_269
        }
    }

    '__ci_bb_269 {
        if ((unsafe: *__local_code__goto_654_34) == 28) {
            goto '__ci_bb_149
        } else {
            goto '__ci_bb_270
        }
    }

    '__ci_bb_270 {
        if ((unsafe: *__local_code__goto_654_34) == 26) {
            goto '__ci_bb_149
        } else {
            goto '__ci_bb_150
        }
    }

}

fn valid_utf(__param_string: *const u8, __param_length: c_ulong, __param_erroroffset: *mut c_ulong) -> c_int {
    var __local_length = __param_length
    var __local_p: *const u8

    var __local_c: c_uint

    (__local_p = __param_string)

    while ((if __local_length > 0: 1 else: 0) != 0) {
        var __local_ab: c_uint

        var __local_d: c_uint


        (__local_c = (unsafe: *__local_p))

        (__local_length = __local_length - 1)

        if ((if __local_c < 128: 1 else: 0) != 0) {
            (__local_p = __local_p + 1)

            continue

        }

        if ((if __local_c < 192: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = (((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong)))

            return -22

        }

        if ((if __local_c >= 254: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = (((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong)))

            return -23

        }

        (__local_ab = utf8_table4[((__local_c as c_uint) & (63 as c_uint))])

        if ((if __local_length < __local_ab: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = (((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong)))

            match ((__local_ab as c_ulong) -% (__local_length as c_ulong)) {
                1 => {
                    return -3
                },
                2 => {
                    return -4
                },
                3 => {
                    return -5
                },
                4 => {
                    return -6
                },
                5 => {
                    return -7
                },
            }

        }

        (__local_length = __local_length - __local_ab)

        (__local_p = __local_p + 1)

        (__local_d = (unsafe: *__local_p))

        if ((if ((__local_d as c_uint) & (192 as c_uint)) != 128: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (1 as c_ulong)))

            return -8

        }


        while true {
            match __local_ab {
                1 => {
                    if ((if ((__local_c as c_uint) & (62 as c_uint)) == 0: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (1 as c_ulong)))

                        return -17

                    }
                },
                2 => {
                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -9

                    }


                    var __ci_expr_logic_0: c_int = 0

                    if ((if __local_c == 224: 1 else: 0) != 0) {
                        (__ci_expr_logic_0 = (if (if ((__local_d as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -18

                    }


                    var __ci_expr_logic_1: c_int = 0

                    if ((if __local_c == 237: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if (if __local_d >= 160: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -16

                    }


                },
                3 => {
                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -9

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -10

                    }


                    var __ci_expr_logic_2: c_int = 0

                    if ((if __local_c == 240: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if (if ((__local_d as c_uint) & (48 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_2 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -19

                    }


                    var __ci_expr_logic_4: c_int

                    if ((if __local_c > 244: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_3: c_int = 0

                        if ((if __local_c == 244: 1 else: 0) != 0) {
                            (__ci_expr_logic_3 = (if (if __local_d > 143: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_4 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -15

                    }


                },
                4 => {
                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -9

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -10

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (4 as c_ulong)))

                        return -11

                    }


                    var __ci_expr_logic_5: c_int = 0

                    if ((if __local_c == 248: 1 else: 0) != 0) {
                        (__ci_expr_logic_5 = (if (if ((__local_d as c_uint) & (56 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_5 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (4 as c_ulong)))

                        return -20

                    }


                },
                5 => {
                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -9

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -10

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (4 as c_ulong)))

                        return -11

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (5 as c_ulong)))

                        return -12

                    }


                    var __ci_expr_logic_6: c_int = 0

                    if ((if __local_c == 252: 1 else: 0) != 0) {
                        (__ci_expr_logic_6 = (if (if ((__local_d as c_uint) & (60 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_6 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (5 as c_ulong)))

                        return -21

                    }


                },
            }

            break

        }

        if ((if __local_ab > 3: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (__local_ab as c_ulong)))

            var __ci_expr_ternary_8: c_int = 0

            if ((if __local_ab == 4: 1 else: 0) != 0) {
                (__ci_expr_ternary_8 = -13)
            } else {
                (__ci_expr_ternary_8 = -14)
            }

            return __ci_expr_ternary_8


        }


        (__local_p = __local_p + 1)

    }


    return 0

}

fn patctl_zero(__param_p: *mut patctl) {
    with_memset((__param_p as *i8), 0, (sizeof[patctl]() as i64))

    ((unsafe: *__param_p).replacement[0] = 255)

    ((unsafe: *__param_p).convert_type = 4294967295)

    ((unsafe: *__param_p).convert_length = 4294967295)

    ((unsafe: *__param_p).regerror_buffsize = -1)

    ((unsafe: *__param_p).locale[0] = 255)

}

fn datctl_zero(__param_d: *mut datctl) {
    with_memset((__param_d as *i8), 0, (sizeof[datctl]() as i64))

    ((unsafe: *__param_d).replacement[0] = 255)

    ((unsafe: *__param_d).substitute_subject[0] = 255)

    ((unsafe: *__param_d).oveccount = 15)

    ((unsafe: *__param_d).copy_numbers[0] = -1)

    ((unsafe: *__param_d).get_numbers[0] = -1)

    ((unsafe: *__param_d).startend[1] = 4294967295)

    ((unsafe: *__param_d).startend[0] = __param_d.startend[1])


    ((unsafe: *__param_d).cerror[1] = 4294967295)

    ((unsafe: *__param_d).cerror[0] = __param_d.cerror[1])


    ((unsafe: *__param_d).cfail[1] = 4294967295)

    ((unsafe: *__param_d).cfail[0] = __param_d.cfail[1])


}

fn should_print_colour(__param_clr: c_int, __param_f: *mut c_void) -> c_int {
    if ((if __param_f == null: 1 else: 0) != 0) {
        return 0
    }

    if ((if __param_clr == -1: 1 else: 0) != 0) {
        return 0
    }

    if ((if colour_setting == COLOUR_NEVER: 1 else: 0) != 0) {
        return 0
    }

    if ((if colour_setting == COLOUR_AUTO: 1 else: 0) != 0) {
        if ((if fileno(__param_f) != colour_last_fd: 1 else: 0) != 0) {
            (colour_last_fd = fileno(__param_f))

            (colour_fd_interactive = isatty(fileno(__param_f)))

        }

        if ((if not (colour_fd_interactive != 0): 1 else: 0) != 0) {
            return 0
        }

    }

    return 1

}

fn colour_begin(__param_clr: c_int, __param_f: *mut c_void) {
    if (should_print_colour(__param_clr, __param_f) != 0) {
        fprintf(__param_f, "\x1b[%dm", __param_clr)
    }

}

fn colour_end(__param_f: *mut c_void) {
    colour_begin(0, __param_f)

}

// Variadic C helper cfprintf is inlined at statement call sites.

fn reset_callout_state() {
    (mallocs_called = 0)

    (first_callout = 1)

    (last_callout_mark = ((null as *const c_void)))

    (callout_count = 0)

}

fn my_malloc(__param_size: c_ulong, __param_data: *mut c_void) -> *mut c_void {
    var __local_block: *mut c_void

    __param_data

    (mallocs_called = mallocs_called + 1)

    var __ci_expr_logic_1: c_int = 0

    if ((if mallocs_until_failure != 2147483647: 1 else: 0) != 0) {
        var __ci_expr_old_0: c_int = mallocs_until_failure

        (mallocs_until_failure = mallocs_until_failure - 1)

        (__ci_expr_logic_1 = (if (if __ci_expr_old_0 <= 0: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_1 != 0) {
        return null
    }


    (__local_block = ((with_alloc((__param_size as i64)) as *mut c_void)))

    var __ci_expr_logic_2: c_int = 0

    if (show_memory != 0) {
        (__ci_expr_logic_2 = (if (if outfile != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        if ((if __local_block == null: 1 else: 0) != 0) {
            colour_begin(31, outfile)

            fprintf(outfile, "** malloc() failed for %zu\n", __param_size)

            colour_end(outfile)


        } else {
            colour_begin(36, outfile)

            fprintf(outfile, "malloc  %5zu", __param_size)

            colour_end(outfile)


            if ((if malloclistptr < 20: 1 else: 0) != 0) {
                (malloclist[malloclistptr] = __local_block)

                var __ci_expr_old_3: c_uint = malloclistptr

                (malloclistptr = malloclistptr + 1)

                (malloclistlength[__ci_expr_old_3] = __param_size)


            } else {
                colour_begin(36, outfile)

                fprintf(outfile, " (not remembered)")

                colour_end(outfile)

            }

            fprintf(outfile, "\n")

        }

    }


    return __local_block

}

fn my_free(__param_block: *mut c_void, __param_data: *mut c_void) {
    __param_data

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if (show_memory != 0) {
        (__ci_expr_logic_0 = (if (if outfile != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if __param_block != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        var __local_i: c_uint

        var __local_j: c_uint


        var __local_found: c_int = 0

        colour_begin(36, outfile)

        fprintf(outfile, "free")

        colour_end(outfile)


        (__local_i = 0)

        while ((if __local_i < malloclistptr: 1 else: 0) != 0) {
            if ((if __param_block == malloclist[__local_i]: 1 else: 0) != 0) {
                colour_begin(36, outfile)

                fprintf(outfile, "    %5zu", malloclistlength[__local_i])

                colour_end(outfile)


                (malloclistptr = malloclistptr - 1)

                (__local_j = __local_i)

                while ((if __local_j < malloclistptr: 1 else: 0) != 0) {
                    (malloclist[__local_j] = malloclist[((__local_j as c_uint) +% (1 as c_uint))])

                    (malloclistlength[__local_j] = malloclistlength[((__local_j as c_uint) +% (1 as c_uint))])


                    (__local_j = __local_j + 1)

                }


                (__local_found = 1)

                break

            }


            (__local_i = __local_i + 1)

        }


        if ((if not (__local_found != 0): 1 else: 0) != 0) {
            colour_begin(36, outfile)

            fprintf(outfile, " unremembered block")

            colour_end(outfile)

        }

        fprintf(outfile, "\n")

    }


    with_free((__param_block as *mut i8))

}

fn stack_guard(__param_depth: c_uint, __param_user_data: *mut c_void) -> c_int {
    __param_user_data

    return (if __param_depth > (&raw const pat_patctl as *const patctl).stackguard_test: 1 else: 0)

}

fn utf8_to_ord(__param_utf8bytes: *const u8, __param_end: *const u8, __param_vptr: *mut c_uint) -> c_int {
    var __local_utf8bytes = __param_utf8bytes
    var __local_c: c_uint = with 0 as __ci_expr_seq_7 {
        var __ci_expr_old_0: *const u8 = __local_utf8bytes
        (__local_utf8bytes = __local_utf8bytes + 1)
        (unsafe: *__ci_expr_old_0)
    }

    var __local_d: c_uint = __local_c

    var __local_i: c_int

    var __local_j: c_int

    var __local_s: c_int


    (__local_i = -1)

    while ((if __local_i < 6: 1 else: 0) != 0) {
        if ((if ((__local_d as c_uint) & (128 as c_uint)) == 0: 1 else: 0) != 0) {
            break
        }

        (__local_d = __local_d << (1 as c_uint))


        (__local_i = __local_i + 1)

    }


    if ((if __local_i == -1: 1 else: 0) != 0) {
        ((unsafe: *__param_vptr) = __local_c)

        return 1

    }

    var __ci_expr_logic_1: c_int

    if ((if __local_i == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __local_i == 6: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return 0
    }


    (__local_s = 6 * __local_i)

    (__local_d = (((__local_c as c_uint) & (utf8_table3[__local_i] as c_uint)) as c_uint) << (__local_s as c_uint))

    (__local_j = 0)

    while ((if __local_j < __local_i: 1 else: 0) != 0) {
        if ((if __local_utf8bytes >= __param_end: 1 else: 0) != 0) {
            return 0
        }

        var __ci_expr_old_2: *const u8 = __local_utf8bytes

        (__local_utf8bytes = __local_utf8bytes + 1)

        (__local_c = (unsafe: *__ci_expr_old_2))


        if ((if ((__local_c as c_uint) & (192 as c_uint)) != 128: 1 else: 0) != 0) {
            return (0 - (__local_j + 1))
        }

        (__local_s = __local_s - 6)

        (__local_d = __local_d | ((((__local_c as c_uint) & (63 as c_uint)) as c_uint) << (__local_s as c_uint)))


        (__local_j = __local_j + 1)

    }


    (__local_j = 0)

    while ((if __local_j < ((6 as c_int)): 1 else: 0) != 0) {
        if ((if __local_d <= ((utf8_table1[__local_j] as c_uint)): 1 else: 0) != 0) {
            break
        }

        (__local_j = __local_j + 1)

    }


    if ((if __local_j != __local_i: 1 else: 0) != 0) {
        return (0 - (__local_i + 1))
    }

    ((unsafe: *__param_vptr) = __local_d)

    return (__local_i + 1)

}

fn ord_to_utf8(__param_cvalue: c_uint, __param_utf8bytes: *mut u8) -> c_int {
    var __local_cvalue = __param_cvalue
    var __local_utf8bytes = __param_utf8bytes
    var __local_i: c_int

    var __local_j: c_int


    if ((if __local_cvalue > 2147483647: 1 else: 0) != 0) {
        return -1
    }

    (__local_i = 0)

    while ((if __local_i < ((6 as c_int)): 1 else: 0) != 0) {
        if ((if __local_cvalue <= ((utf8_table1[__local_i] as c_uint)): 1 else: 0) != 0) {
            break
        }

        (__local_i = __local_i + 1)

    }


    (__local_utf8bytes = __local_utf8bytes + ((__local_i as isize) as usize))

    (__local_j = __local_i)

    while ((if __local_j > 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *mut u8 = __local_utf8bytes

        (__local_utf8bytes = __local_utf8bytes - 1)

        ((unsafe: *__ci_expr_old_0) = (128 as c_uint) | (((__local_cvalue as c_uint) & (63 as c_uint)) as c_uint))


        (__local_cvalue = __local_cvalue >> (6 as c_uint))


        (__local_j = __local_j - 1)

    }


    ((unsafe: *__local_utf8bytes) = (utf8_table2[__local_i] as c_uint) | (__local_cvalue as c_uint))

    return (__local_i + 1)

}

fn pchar(__param_c: c_uint, __param_utf: c_int, __param_f: *mut c_void) -> c_int {
    var __local_c = __param_c
    var __local_n: c_int = 0

    var __local_tempbuffer: [16]c_char

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_c >= 32: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_c < 127: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_c = __local_c)

        if ((if __param_f != null: 1 else: 0) != 0) {
            fprintf(__param_f, "%c", __local_c)
        }

        return 1

    }


    (__local_c = __local_c)

    if ((if __local_c < 256: 1 else: 0) != 0) {
        if (__param_utf != 0) {
            if ((if __param_f != null: 1 else: 0) != 0) {
                fprintf(__param_f, "\\x{%02x}", __local_c)
            }

            return 6

        } else {
            if ((if __param_f != null: 1 else: 0) != 0) {
                fprintf(__param_f, "\\x%02x", __local_c)
            }

            return 4

        }

    }

    if ((if __param_f != null: 1 else: 0) != 0) {
        (__local_n = fprintf(__param_f, "\\x{%02x}", __local_c))
    } else {
        (__local_n = snprintf((&(unsafe: __local_tempbuffer[0]) as *mut c_char), (16 * sizeof[c_char]()), "\\x{%02x}", __local_c))
    }

    var __ci_expr_ternary_1: c_int = 0

    if ((if __local_n >= 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_1 = __local_n)
    } else {
        (__ci_expr_ternary_1 = 0)
    }

    return __ci_expr_ternary_1


}

fn expand_input_buffers() {
    var __local_new_pbuffer8_size: c_ulong = ((2 as c_ulong) *% (pbuffer8_size as c_ulong))

    var __local_new_buffer: *mut u8 = (((with_alloc((__local_new_pbuffer8_size as i64)) as *mut c_void) as *mut u8))

    var __local_new_pbuffer8: *mut u8 = (((with_alloc((__local_new_pbuffer8_size as i64)) as *mut c_void) as *mut u8))

    var __ci_expr_logic_0: c_int

    if ((if __local_new_buffer == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_new_pbuffer8 == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        colour_begin(31, libc_stderr())

        fprintf(libc_stderr(), "pcre2test: malloc(%zu) failed\n", __local_new_pbuffer8_size)

        colour_end(libc_stderr())


        exit(1)

    }


    with_memcpy((__local_new_buffer as *i8), (buffer as *i8), (pbuffer8_size as i64))

    with_memcpy((__local_new_pbuffer8 as *i8), (pbuffer8 as *i8), (pbuffer8_size as i64))

    (pbuffer8_size = __local_new_pbuffer8_size)

    with_free((buffer as *mut i8))

    with_free((pbuffer8 as *mut i8))

    (buffer = __local_new_buffer)

    (pbuffer8 = __local_new_pbuffer8)

}

fn extend_inputline(__param_f: *mut c_void, __param_start: *mut u8, __param_prompt: *const i8) -> *mut u8 {
    var __local_start = __param_start
    var __local_here: *mut u8 = __local_start

    while true {
        var __local_dlen: c_ulong

        var __local_rlen: c_ulong = ((pbuffer8_size as c_ulong) -% ((((__local_here as usize) -% (buffer as usize)) / sizeof[u8]()) as c_ulong))

        if ((if __local_rlen > 1000: 1 else: 0) != 0) {
            var __local_rlen_trunc: c_int = with 0 as __ci_expr_seq_12 {
                var __ci_expr_ternary_0: c_int = 0
                if ((if __local_rlen > 2147483647: 1 else: 0) != 0) {
                    (__ci_expr_ternary_0 = 2147483647)
                } else {
                    (__ci_expr_ternary_0 = ((__local_rlen as c_int)))
                }
                __ci_expr_ternary_0
            }

            if (isatty(fileno(__param_f)) != 0) {
                colour_begin(34, libc_stdout())

                fprintf(libc_stdout(), "%s", __param_prompt)

                colour_end(libc_stdout())

            }

            if ((if fgets((__local_here as *mut c_char), __local_rlen_trunc, __param_f) == null: 1 else: 0) != 0) {
                var __ci_expr_ternary_1: *mut u8 = null

                if ((if __local_here == __local_start: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = ((null as *mut u8)))
                } else {
                    (__ci_expr_ternary_1 = __local_start)
                }

                return __ci_expr_ternary_1

            }

            (__local_dlen = string_len((__local_here as *mut c_char)))

            (__local_here = __local_here + (__local_dlen as usize))

            var __ci_expr_logic_2: c_int = 0

            if ((if __local_here > __local_start: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if (unsafe: __local_here[-1]) == 10: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                return __local_start
            }


            var __ci_expr_logic_3: c_int = 0

            if ((if __local_dlen < (((__local_rlen_trunc as c_uint) as c_uint) -% (1 as c_uint)): 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if not (feof(__param_f) != 0): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                colour_begin(31, outfile)

                fprintf(outfile, "** Binary zero encountered in input\n")

                colour_end(outfile)


                colour_begin(31, outfile)

                fprintf(outfile, "** pcre2test run abandoned\n")

                colour_end(outfile)


                exit(1)

            }


        } else {
            var __local_start_offset: c_ulong = (((__local_start as usize) -% (buffer as usize)) / sizeof[u8]())

            var __local_here_offset: c_ulong = (((__local_here as usize) -% (buffer as usize)) / sizeof[u8]())

            expand_input_buffers()

            (__local_start = buffer + (__local_start_offset as usize))

            (__local_here = buffer + (__local_here_offset as usize))

        }

    }

    do {
        0
    } while (0 != 0)

}

fn strncmpic(__param_s: *const u8, __param_t: *const u8, __param_n: c_ulong) -> c_int {
    var __local_s = __param_s
    var __local_t = __param_t
    var __local_n = __param_n
    if ((if __local_n > 0: 1 else: 0) != 0) {
        do {
            var __local_c: c_int = with 0 as __ci_expr_seq_12 {
                var __ci_expr_old_0: *const u8 = __local_s
                (__local_s = __local_s + 1)
                var __ci_expr_old_1: *const u8 = __local_t
                (__local_t = __local_t + 1)
                (tolower((unsafe: *__ci_expr_old_0)) - tolower((unsafe: *__ci_expr_old_1)))
            }

            if ((if __local_c != 0: 1 else: 0) != 0) {
                return __local_c
            }

        } while { (__local_n = __local_n - 1); ((if __local_n > 0: 1 else: 0) != 0) }
    }

    return 0

}

fn scan_modifiers(__param_p: *const u8, __param_len: c_ulong) -> c_int {
    var __local_bot: c_int = 0

    var __local_top: c_int = 156

    while ((if __local_top > __local_bot: 1 else: 0) != 0) {
        var __local_mid: c_int = ((__local_bot + __local_top) / 2)

        var __local_mlen: c_ulong = string_len(modlist[__local_mid].name)

        var __local_c: c_int = with 0 as __ci_expr_seq_13 {
            var __ci_expr_ternary_0: c_ulong = 0
            if ((if __param_len < __local_mlen: 1 else: 0) != 0) {
                (__ci_expr_ternary_0 = __param_len)
            } else {
                (__ci_expr_ternary_0 = __local_mlen)
            }
            strncmp((__param_p as *const c_char), modlist[__local_mid].name, __ci_expr_ternary_0)
        }

        if ((if __local_c == 0: 1 else: 0) != 0) {
            if ((if __param_len == __local_mlen: 1 else: 0) != 0) {
                return __local_mid
            }

            var __ci_expr_ternary_1: c_int = 0

            if ((if __param_len > __local_mlen: 1 else: 0) != 0) {
                (__ci_expr_ternary_1 = 1)
            } else {
                (__ci_expr_ternary_1 = -1)
            }

            (__local_c = __ci_expr_ternary_1)


        }

        if ((if __local_c > 0: 1 else: 0) != 0) {
            (__local_bot = __local_mid + 1)
        } else {
            (__local_top = __local_mid)
        }

    }

    return -1

}

fn error_direction(__param_rc: c_int, __param_erroroffset: c_ulong) -> c_int {
    match __param_rc {
        116 => {
            return 0
        },
        117 => {
            return 0
        },
        120 => {
            return 0
        },
        121 => {
            return 0
        },
        132 => {
            return 0
        },
        133 => {
            return 0
        },
        186 => {
            return 0
        },
        188 => {
            return 0
        },
        191 => {
            return 0
        },
        192 => {
            return 0
        },
        201 => {
            return 0
        },
        204 => {
            return 0
        },
        205 => {
            return 0
        },
        206 => {
            return 0
        },
        119 => {
            return 2
        },
        125 => {
            return 2
        },
        127 => {
            return 2
        },
        135 => {
            return 2
        },
        136 => {
            return 2
        },
        181 => {
            return 2
        },
        184 => {
            return 2
        },
        187 => {
            return 2
        },
        200 => {
            return 2
        },
        207 => {
            return 2
        },
        101 => {
            return 1
        },
        102 => {
            return 1
        },
        103 => {
            return 1
        },
        104 => {
            return 1
        },
        105 => {
            return 1
        },
        106 => {
            return 1
        },
        107 => {
            return 1
        },
        108 => {
            return 1
        },
        109 => {
            return 1
        },
        111 => {
            return 1
        },
        112 => {
            return 1
        },
        113 => {
            return 1
        },
        114 => {
            return 1
        },
        115 => {
            return 3
        },
        118 => {
            return 1
        },
        122 => {
            return 1
        },
        124 => {
            return 1
        },
        126 => {
            return 1
        },
        128 => {
            return 1
        },
        129 => {
            return 1
        },
        130 => {
            return 1
        },
        134 => {
            return 1
        },
        137 => {
            return 1
        },
        138 => {
            return 1
        },
        139 => {
            return 1
        },
        140 => {
            return 1
        },
        141 => {
            return 1
        },
        142 => {
            return 1
        },
        143 => {
            return 1
        },
        144 => {
            return 1
        },
        145 => {
            return 1
        },
        146 => {
            return 1
        },
        147 => {
            return 1
        },
        148 => {
            return 1
        },
        149 => {
            return 1
        },
        150 => {
            return 1
        },
        151 => {
            return 1
        },
        154 => {
            return 2
        },
        155 => {
            return 1
        },
        157 => {
            return 1
        },
        158 => {
            return 1
        },
        160 => {
            return 1
        },
        161 => {
            return 1
        },
        162 => {
            return 1
        },
        164 => {
            return 1
        },
        165 => {
            return 1
        },
        166 => {
            return 1
        },
        167 => {
            return 1
        },
        168 => {
            return 1
        },
        169 => {
            return 1
        },
        171 => {
            return 1
        },
        172 => {
            return 1
        },
        173 => {
            return 1
        },
        176 => {
            return 1
        },
        177 => {
            return 1
        },
        178 => {
            return 1
        },
        179 => {
            return 1
        },
        182 => {
            return 1
        },
        183 => {
            return 1
        },
        185 => {
            return 1
        },
        193 => {
            return 1
        },
        194 => {
            return 1
        },
        195 => {
            return 1
        },
        196 => {
            return 1
        },
        197 => {
            return 1
        },
        198 => {
            return 1
        },
        199 => {
            return 3
        },
        202 => {
            return 1
        },
        203 => {
            return 1
        },
        208 => {
            return 1
        },
        209 => {
            return 1
        },
        210 => {
            return 1
        },
        211 => {
            return 1
        },
        212 => {
            return 1
        },
        213 => {
            return 1
        },
        214 => {
            return 1
        },
        215 => {
            return 1
        },
        216 => {
            return 1
        },
        217 => {
            return 1
        },
        218 => {
            return 1
        },
        219 => {
            return 1
        },
        174 => {
            var __ci_expr_ternary_0: c_int = 0

            if ((if __param_erroroffset > 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_0 = 1)
            } else {
                (__ci_expr_ternary_0 = 0)
            }

            return __ci_expr_ternary_0

        },
        175 => {
            var __ci_expr_ternary_0: c_int = 0

            if ((if __param_erroroffset > 0: 1 else: 0) != 0) {
                (__ci_expr_ternary_0 = 1)
            } else {
                (__ci_expr_ternary_0 = 0)
            }

            return __ci_expr_ternary_0

        },
        -3 => {
            return 2
        },
        -4 => {
            return 2
        },
        -5 => {
            return 2
        },
        -6 => {
            return 2
        },
        -7 => {
            return 2
        },
        -8 => {
            return 2
        },
        -9 => {
            return 2
        },
        -10 => {
            return 2
        },
        -11 => {
            return 2
        },
        -12 => {
            return 2
        },
        -13 => {
            return 2
        },
        -14 => {
            return 2
        },
        -15 => {
            return 2
        },
        -16 => {
            return 2
        },
        -17 => {
            return 2
        },
        -18 => {
            return 2
        },
        -19 => {
            return 2
        },
        -20 => {
            return 2
        },
        -21 => {
            return 2
        },
        -22 => {
            return 2
        },
        -23 => {
            return 2
        },
        -24 => {
            return 2
        },
        -25 => {
            return 2
        },
        -26 => {
            return 2
        },
        -27 => {
            return 2
        },
        -28 => {
            return 2
        },
    }

    return -1

}

fn prmsg(__param_msg: *mut *const i8, __param_s: *const i8) {
    colour_begin(31, outfile)

    fprintf(outfile, "%s %s", (unsafe: *__param_msg), __param_s)

    colour_end(outfile)


    ((unsafe: *__param_msg) = (("" as *const c_char)))

}

fn show_controls(__param_clr: c_int, __param_controls: c_uint, __param_controls2: c_uint, __param_before: *const i8) {
    var __ci_expr_ternary_0: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((" aftertext" as *mut c_char)))
    } else {
        (__ci_expr_ternary_0 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_1: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_1 = ((" allaftertext" as *mut c_char)))
    } else {
        (__ci_expr_ternary_1 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_2: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_2 = ((" allcaptures" as *mut c_char)))
    } else {
        (__ci_expr_ternary_2 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_3: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_3 = ((" allusedtext" as *mut c_char)))
    } else {
        (__ci_expr_ternary_3 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_4: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_4 = ((" allvector" as *mut c_char)))
    } else {
        (__ci_expr_ternary_4 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_5: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_5 = ((" altglobal" as *mut c_char)))
    } else {
        (__ci_expr_ternary_5 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_6: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_6 = ((" bincode" as *mut c_char)))
    } else {
        (__ci_expr_ternary_6 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_7: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_7 = ((" bsr" as *mut c_char)))
    } else {
        (__ci_expr_ternary_7 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_8: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_8 = ((" callout_capture" as *mut c_char)))
    } else {
        (__ci_expr_ternary_8 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_9: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_9 = ((" callout_extra" as *mut c_char)))
    } else {
        (__ci_expr_ternary_9 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_10: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_10 = ((" callout_info" as *mut c_char)))
    } else {
        (__ci_expr_ternary_10 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_11: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (256 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_11 = ((" callout_none" as *mut c_char)))
    } else {
        (__ci_expr_ternary_11 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_12: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_12 = ((" callout_no_where" as *mut c_char)))
    } else {
        (__ci_expr_ternary_12 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_13: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_13 = ((" dfa" as *mut c_char)))
    } else {
        (__ci_expr_ternary_13 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_14: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_14 = ((" expand" as *mut c_char)))
    } else {
        (__ci_expr_ternary_14 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_15: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_15 = ((" find_limits" as *mut c_char)))
    } else {
        (__ci_expr_ternary_15 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_16: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (4096 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_16 = ((" find_limits_noheap" as *mut c_char)))
    } else {
        (__ci_expr_ternary_16 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_17: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (32768 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_17 = ((" framesize" as *mut c_char)))
    } else {
        (__ci_expr_ternary_17 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_18: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_18 = ((" fullbincode" as *mut c_char)))
    } else {
        (__ci_expr_ternary_18 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_19: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (16384 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_19 = ((" getall" as *mut c_char)))
    } else {
        (__ci_expr_ternary_19 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_20: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (32768 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_20 = ((" global" as *mut c_char)))
    } else {
        (__ci_expr_ternary_20 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_21: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (536870912 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_21 = ((" heapframes_size" as *mut c_char)))
    } else {
        (__ci_expr_ternary_21 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_22: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (65536 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_22 = ((" hex" as *mut c_char)))
    } else {
        (__ci_expr_ternary_22 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_23: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_23 = ((" info" as *mut c_char)))
    } else {
        (__ci_expr_ternary_23 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_24: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (262144 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_24 = ((" jitfast" as *mut c_char)))
    } else {
        (__ci_expr_ternary_24 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_25: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_25 = ((" jitverify" as *mut c_char)))
    } else {
        (__ci_expr_ternary_25 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_26: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (1048576 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_26 = ((" mark" as *mut c_char)))
    } else {
        (__ci_expr_ternary_26 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_27: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (2097152 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_27 = ((" memory" as *mut c_char)))
    } else {
        (__ci_expr_ternary_27 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_28: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (1073741824 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_28 = ((" newline" as *mut c_char)))
    } else {
        (__ci_expr_ternary_28 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_29: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (4194304 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_29 = ((" null_context" as *mut c_char)))
    } else {
        (__ci_expr_ternary_29 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_30: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (16384 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_30 = ((" null_replacement" as *mut c_char)))
    } else {
        (__ci_expr_ternary_30 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_31: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_31 = ((" null_subject" as *mut c_char)))
    } else {
        (__ci_expr_ternary_31 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_32: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_32 = ((" null_substitute_match_data" as *mut c_char)))
    } else {
        (__ci_expr_ternary_32 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_33: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (8388608 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_33 = ((" posix" as *mut c_char)))
    } else {
        (__ci_expr_ternary_33 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_34: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (16777216 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_34 = ((" posix_nosub" as *mut c_char)))
    } else {
        (__ci_expr_ternary_34 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_35: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (33554432 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_35 = ((" push" as *mut c_char)))
    } else {
        (__ci_expr_ternary_35 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_36: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (67108864 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_36 = ((" pushcopy" as *mut c_char)))
    } else {
        (__ci_expr_ternary_36 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_37: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (134217728 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_37 = ((" pushtablescopy" as *mut c_char)))
    } else {
        (__ci_expr_ternary_37 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_38: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (268435456 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_38 = ((" startchar" as *mut c_char)))
    } else {
        (__ci_expr_ternary_38 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_39: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_39 = ((" substitute_callout" as *mut c_char)))
    } else {
        (__ci_expr_ternary_39 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_40: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (65536 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_40 = ((" substitute_case_callout" as *mut c_char)))
    } else {
        (__ci_expr_ternary_40 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_41: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_41 = ((" substitute_extended" as *mut c_char)))
    } else {
        (__ci_expr_ternary_41 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_42: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_42 = ((" substitute_literal" as *mut c_char)))
    } else {
        (__ci_expr_ternary_42 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_43: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_43 = ((" substitute_matched" as *mut c_char)))
    } else {
        (__ci_expr_ternary_43 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_44: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_44 = ((" substitute_overflow_length" as *mut c_char)))
    } else {
        (__ci_expr_ternary_44 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_45: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_45 = ((" substitute_replacement_only" as *mut c_char)))
    } else {
        (__ci_expr_ternary_45 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_46: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_46 = ((" substitute_unknown_unset" as *mut c_char)))
    } else {
        (__ci_expr_ternary_46 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_47: *mut c_char = null

    if ((if ((__param_controls2 as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_47 = ((" substitute_unset_empty" as *mut c_char)))
    } else {
        (__ci_expr_ternary_47 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_48: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (536870912 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_48 = ((" use_length" as *mut c_char)))
    } else {
        (__ci_expr_ternary_48 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_49: *mut c_char = null

    if ((if ((__param_controls as c_uint) & (1073741824 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_49 = ((" utf8_input" as *mut c_char)))
    } else {
        (__ci_expr_ternary_49 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_50: *mut c_char = null

    if ((if ((__param_controls as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_50 = ((" zero_terminate" as *mut c_char)))
    } else {
        (__ci_expr_ternary_50 = (("" as *mut c_char)))
    }

    colour_begin(__param_clr, outfile)

    fprintf(outfile, "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", __param_before, __ci_expr_ternary_0, __ci_expr_ternary_1, __ci_expr_ternary_2, __ci_expr_ternary_3, __ci_expr_ternary_4, __ci_expr_ternary_5, __ci_expr_ternary_6, __ci_expr_ternary_7, __ci_expr_ternary_8, __ci_expr_ternary_9, __ci_expr_ternary_10, __ci_expr_ternary_11, __ci_expr_ternary_12, __ci_expr_ternary_13, __ci_expr_ternary_14, __ci_expr_ternary_15, __ci_expr_ternary_16, __ci_expr_ternary_17, __ci_expr_ternary_18, __ci_expr_ternary_19, __ci_expr_ternary_20, __ci_expr_ternary_21, __ci_expr_ternary_22, __ci_expr_ternary_23, __ci_expr_ternary_24, __ci_expr_ternary_25, __ci_expr_ternary_26, __ci_expr_ternary_27, __ci_expr_ternary_28, __ci_expr_ternary_29, __ci_expr_ternary_30, __ci_expr_ternary_31, __ci_expr_ternary_32, __ci_expr_ternary_33, __ci_expr_ternary_34, __ci_expr_ternary_35, __ci_expr_ternary_36, __ci_expr_ternary_37, __ci_expr_ternary_38, __ci_expr_ternary_39, __ci_expr_ternary_40, __ci_expr_ternary_41, __ci_expr_ternary_42, __ci_expr_ternary_43, __ci_expr_ternary_44, __ci_expr_ternary_45, __ci_expr_ternary_46, __ci_expr_ternary_47, __ci_expr_ternary_48, __ci_expr_ternary_49, __ci_expr_ternary_50)

    colour_end(outfile)


}

fn show_compile_options(__param_clr: c_int, __param_options: c_uint, __param_before: *const i8, __param_after: *const i8) {
    if ((if __param_options == 0: 1 else: 0) != 0) {
        colour_begin(__param_clr, outfile)

        fprintf(outfile, "%s <none>%s", __param_before, __param_after)

        colour_end(outfile)

    } else {
        var __ci_expr_ternary_0: *mut c_char = null

        if ((if ((__param_options as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = ((" alt_bsux" as *mut c_char)))
        } else {
            (__ci_expr_ternary_0 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_1: *mut c_char = null

        if ((if ((__param_options as c_uint) & (2097152 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = ((" alt_circumflex" as *mut c_char)))
        } else {
            (__ci_expr_ternary_1 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_2: *mut c_char = null

        if ((if ((__param_options as c_uint) & (134217728 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_2 = ((" alt_extended_class" as *mut c_char)))
        } else {
            (__ci_expr_ternary_2 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_3: *mut c_char = null

        if ((if ((__param_options as c_uint) & (4194304 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_3 = ((" alt_verbnames" as *mut c_char)))
        } else {
            (__ci_expr_ternary_3 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_4: *mut c_char = null

        if ((if ((__param_options as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_4 = ((" allow_empty_class" as *mut c_char)))
        } else {
            (__ci_expr_ternary_4 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_5: *mut c_char = null

        if ((if ((__param_options as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_5 = ((" anchored" as *mut c_char)))
        } else {
            (__ci_expr_ternary_5 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_6: *mut c_char = null

        if ((if ((__param_options as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_6 = ((" auto_callout" as *mut c_char)))
        } else {
            (__ci_expr_ternary_6 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_7: *mut c_char = null

        if ((if ((__param_options as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_7 = ((" caseless" as *mut c_char)))
        } else {
            (__ci_expr_ternary_7 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_8: *mut c_char = null

        if ((if ((__param_options as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_8 = ((" dollar_endonly" as *mut c_char)))
        } else {
            (__ci_expr_ternary_8 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_9: *mut c_char = null

        if ((if ((__param_options as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_9 = ((" dotall" as *mut c_char)))
        } else {
            (__ci_expr_ternary_9 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_10: *mut c_char = null

        if ((if ((__param_options as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_10 = ((" dupnames" as *mut c_char)))
        } else {
            (__ci_expr_ternary_10 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_11: *mut c_char = null

        if ((if ((__param_options as c_uint) & (536870912 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_11 = ((" endanchored" as *mut c_char)))
        } else {
            (__ci_expr_ternary_11 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_12: *mut c_char = null

        if ((if ((__param_options as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_12 = ((" extended" as *mut c_char)))
        } else {
            (__ci_expr_ternary_12 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_13: *mut c_char = null

        if ((if ((__param_options as c_uint) & (16777216 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_13 = ((" extended_more" as *mut c_char)))
        } else {
            (__ci_expr_ternary_13 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_14: *mut c_char = null

        if ((if ((__param_options as c_uint) & (256 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_14 = ((" firstline" as *mut c_char)))
        } else {
            (__ci_expr_ternary_14 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_15: *mut c_char = null

        if ((if ((__param_options as c_uint) & (33554432 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_15 = ((" literal" as *mut c_char)))
        } else {
            (__ci_expr_ternary_15 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_16: *mut c_char = null

        if ((if ((__param_options as c_uint) & (67108864 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_16 = ((" match_invalid_utf" as *mut c_char)))
        } else {
            (__ci_expr_ternary_16 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_17: *mut c_char = null

        if ((if ((__param_options as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_17 = ((" match_unset_backref" as *mut c_char)))
        } else {
            (__ci_expr_ternary_17 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_18: *mut c_char = null

        if ((if ((__param_options as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_18 = ((" multiline" as *mut c_char)))
        } else {
            (__ci_expr_ternary_18 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_19: *mut c_char = null

        if ((if ((__param_options as c_uint) & (1048576 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_19 = ((" never_backslash_c" as *mut c_char)))
        } else {
            (__ci_expr_ternary_19 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_20: *mut c_char = null

        if ((if ((__param_options as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_20 = ((" never_ucp" as *mut c_char)))
        } else {
            (__ci_expr_ternary_20 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_21: *mut c_char = null

        if ((if ((__param_options as c_uint) & (4096 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_21 = ((" never_utf" as *mut c_char)))
        } else {
            (__ci_expr_ternary_21 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_22: *mut c_char = null

        if ((if ((__param_options as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_22 = ((" no_auto_capture" as *mut c_char)))
        } else {
            (__ci_expr_ternary_22 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_23: *mut c_char = null

        if ((if ((__param_options as c_uint) & (16384 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_23 = ((" no_auto_possess" as *mut c_char)))
        } else {
            (__ci_expr_ternary_23 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_24: *mut c_char = null

        if ((if ((__param_options as c_uint) & (32768 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_24 = ((" no_dotstar_anchor" as *mut c_char)))
        } else {
            (__ci_expr_ternary_24 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_25: *mut c_char = null

        if ((if ((__param_options as c_uint) & (1073741824 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_25 = ((" no_utf_check" as *mut c_char)))
        } else {
            (__ci_expr_ternary_25 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_26: *mut c_char = null

        if ((if ((__param_options as c_uint) & (65536 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_26 = ((" no_start_optimize" as *mut c_char)))
        } else {
            (__ci_expr_ternary_26 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_27: *mut c_char = null

        if ((if ((__param_options as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_27 = ((" ucp" as *mut c_char)))
        } else {
            (__ci_expr_ternary_27 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_28: *mut c_char = null

        if ((if ((__param_options as c_uint) & (262144 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_28 = ((" ungreedy" as *mut c_char)))
        } else {
            (__ci_expr_ternary_28 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_29: *mut c_char = null

        if ((if ((__param_options as c_uint) & (8388608 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_29 = ((" use_offset_limit" as *mut c_char)))
        } else {
            (__ci_expr_ternary_29 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_30: *mut c_char = null

        if ((if ((__param_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_30 = ((" utf" as *mut c_char)))
        } else {
            (__ci_expr_ternary_30 = (("" as *mut c_char)))
        }

        colour_begin(__param_clr, outfile)

        fprintf(outfile, "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", __param_before, __ci_expr_ternary_0, __ci_expr_ternary_1, __ci_expr_ternary_2, __ci_expr_ternary_3, __ci_expr_ternary_4, __ci_expr_ternary_5, __ci_expr_ternary_6, __ci_expr_ternary_7, __ci_expr_ternary_8, __ci_expr_ternary_9, __ci_expr_ternary_10, __ci_expr_ternary_11, __ci_expr_ternary_12, __ci_expr_ternary_13, __ci_expr_ternary_14, __ci_expr_ternary_15, __ci_expr_ternary_16, __ci_expr_ternary_17, __ci_expr_ternary_18, __ci_expr_ternary_19, __ci_expr_ternary_20, __ci_expr_ternary_21, __ci_expr_ternary_22, __ci_expr_ternary_23, __ci_expr_ternary_24, __ci_expr_ternary_25, __ci_expr_ternary_26, __ci_expr_ternary_27, __ci_expr_ternary_28, __ci_expr_ternary_29, __ci_expr_ternary_30, __param_after)

        colour_end(outfile)

    }

}

fn show_compile_extra_options(__param_clr: c_int, __param_options: c_uint, __param_before: *const i8, __param_after: *const i8) {
    if ((if __param_options == 0: 1 else: 0) != 0) {
        colour_begin(__param_clr, outfile)

        fprintf(outfile, "%s <none>%s", __param_before, __param_after)

        colour_end(outfile)

    } else {
        var __ci_expr_ternary_0: *mut c_char = null

        if ((if ((__param_options as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = ((" allow_lookaround_bsk" as *mut c_char)))
        } else {
            (__ci_expr_ternary_0 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_1: *mut c_char = null

        if ((if ((__param_options as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = ((" allow_surrogate_escapes" as *mut c_char)))
        } else {
            (__ci_expr_ternary_1 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_2: *mut c_char = null

        if ((if ((__param_options as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_2 = ((" alt_bsux" as *mut c_char)))
        } else {
            (__ci_expr_ternary_2 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_3: *mut c_char = null

        if ((if ((__param_options as c_uint) & (256 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_3 = ((" ascii_bsd" as *mut c_char)))
        } else {
            (__ci_expr_ternary_3 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_4: *mut c_char = null

        if ((if ((__param_options as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_4 = ((" ascii_bss" as *mut c_char)))
        } else {
            (__ci_expr_ternary_4 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_5: *mut c_char = null

        if ((if ((__param_options as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_5 = ((" ascii_bsw" as *mut c_char)))
        } else {
            (__ci_expr_ternary_5 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_6: *mut c_char = null

        if ((if ((__param_options as c_uint) & (4096 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_6 = ((" ascii_digit" as *mut c_char)))
        } else {
            (__ci_expr_ternary_6 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_7: *mut c_char = null

        if ((if ((__param_options as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_7 = ((" ascii_posix" as *mut c_char)))
        } else {
            (__ci_expr_ternary_7 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_8: *mut c_char = null

        if ((if ((__param_options as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_8 = ((" bad_escape_is_literal" as *mut c_char)))
        } else {
            (__ci_expr_ternary_8 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_9: *mut c_char = null

        if ((if ((__param_options as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_9 = ((" caseless_restrict" as *mut c_char)))
        } else {
            (__ci_expr_ternary_9 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_10: *mut c_char = null

        if ((if ((__param_options as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_10 = ((" escaped_cr_is_lf" as *mut c_char)))
        } else {
            (__ci_expr_ternary_10 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_11: *mut c_char = null

        if ((if ((__param_options as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_11 = ((" match_word" as *mut c_char)))
        } else {
            (__ci_expr_ternary_11 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_12: *mut c_char = null

        if ((if ((__param_options as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_12 = ((" match_line" as *mut c_char)))
        } else {
            (__ci_expr_ternary_12 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_13: *mut c_char = null

        if ((if ((__param_options as c_uint) & (32768 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_13 = ((" never_callout" as *mut c_char)))
        } else {
            (__ci_expr_ternary_13 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_14: *mut c_char = null

        if ((if ((__param_options as c_uint) & (16384 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_14 = ((" no_bs0" as *mut c_char)))
        } else {
            (__ci_expr_ternary_14 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_15: *mut c_char = null

        if ((if ((__param_options as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_15 = ((" python_octal" as *mut c_char)))
        } else {
            (__ci_expr_ternary_15 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_16: *mut c_char = null

        if ((if ((__param_options as c_uint) & (65536 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_16 = ((" turkish_casing" as *mut c_char)))
        } else {
            (__ci_expr_ternary_16 = (("" as *mut c_char)))
        }

        colour_begin(__param_clr, outfile)

        fprintf(outfile, "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", __param_before, __ci_expr_ternary_0, __ci_expr_ternary_1, __ci_expr_ternary_2, __ci_expr_ternary_3, __ci_expr_ternary_4, __ci_expr_ternary_5, __ci_expr_ternary_6, __ci_expr_ternary_7, __ci_expr_ternary_8, __ci_expr_ternary_9, __ci_expr_ternary_10, __ci_expr_ternary_11, __ci_expr_ternary_12, __ci_expr_ternary_13, __ci_expr_ternary_14, __ci_expr_ternary_15, __ci_expr_ternary_16, __param_after)

        colour_end(outfile)

    }

}

fn show_optimize_flags(__param_clr: c_int, __param_flags: c_uint, __param_before: *const i8, __param_after: *const i8) {
    if ((if __param_flags == 0: 1 else: 0) != 0) {
        colour_begin(__param_clr, outfile)

        fprintf(outfile, "%s<none>%s", __param_before, __param_after)

        colour_end(outfile)

    } else {
        var __ci_expr_ternary_0: *mut c_char = null

        if ((if ((__param_flags as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (("auto_possess" as *mut c_char)))
        } else {
            (__ci_expr_ternary_0 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_2: *mut c_char = null

        var __ci_expr_logic_1: c_int = 0

        if ((if ((__param_flags as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if ((__param_flags as c_uint) >> (1 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_ternary_2 = (("," as *mut c_char)))
        } else {
            (__ci_expr_ternary_2 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_3: *mut c_char = null

        if ((if ((__param_flags as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_3 = (("dotstar_anchor" as *mut c_char)))
        } else {
            (__ci_expr_ternary_3 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_5: *mut c_char = null

        var __ci_expr_logic_4: c_int = 0

        if ((if ((__param_flags as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if ((__param_flags as c_uint) >> (2 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_ternary_5 = (("," as *mut c_char)))
        } else {
            (__ci_expr_ternary_5 = (("" as *mut c_char)))
        }

        var __ci_expr_ternary_6: *mut c_char = null

        if ((if ((__param_flags as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_6 = (("start_optimize" as *mut c_char)))
        } else {
            (__ci_expr_ternary_6 = (("" as *mut c_char)))
        }

        colour_begin(__param_clr, outfile)

        fprintf(outfile, "%s%s%s%s%s%s%s", __param_before, __ci_expr_ternary_0, __ci_expr_ternary_2, __ci_expr_ternary_3, __ci_expr_ternary_5, __ci_expr_ternary_6, __param_after)

        colour_end(outfile)

    }

}

fn show_match_options(__param_clr: c_int, __param_options: c_uint) {
    var __ci_expr_ternary_0: *mut c_char = null

    if ((if ((__param_options as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = ((" anchored" as *mut c_char)))
    } else {
        (__ci_expr_ternary_0 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_1: *mut c_char = null

    if ((if ((__param_options as c_uint) & (16384 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_1 = ((" copy_matched_subject" as *mut c_char)))
    } else {
        (__ci_expr_ternary_1 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_2: *mut c_char = null

    if ((if ((__param_options as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_2 = ((" dfa_restart" as *mut c_char)))
    } else {
        (__ci_expr_ternary_2 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_3: *mut c_char = null

    if ((if ((__param_options as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_3 = ((" dfa_shortest" as *mut c_char)))
    } else {
        (__ci_expr_ternary_3 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_4: *mut c_char = null

    if ((if ((__param_options as c_uint) & (262144 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_4 = ((" disable_recurseloop_check" as *mut c_char)))
    } else {
        (__ci_expr_ternary_4 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_5: *mut c_char = null

    if ((if ((__param_options as c_uint) & (536870912 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_5 = ((" endanchored" as *mut c_char)))
    } else {
        (__ci_expr_ternary_5 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_6: *mut c_char = null

    if ((if ((__param_options as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_6 = ((" no_jit" as *mut c_char)))
    } else {
        (__ci_expr_ternary_6 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_7: *mut c_char = null

    if ((if ((__param_options as c_uint) & (1073741824 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_7 = ((" no_utf_check" as *mut c_char)))
    } else {
        (__ci_expr_ternary_7 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_8: *mut c_char = null

    if ((if ((__param_options as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_8 = ((" notbol" as *mut c_char)))
    } else {
        (__ci_expr_ternary_8 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_9: *mut c_char = null

    if ((if ((__param_options as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_9 = ((" notempty" as *mut c_char)))
    } else {
        (__ci_expr_ternary_9 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_10: *mut c_char = null

    if ((if ((__param_options as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_10 = ((" notempty_atstart" as *mut c_char)))
    } else {
        (__ci_expr_ternary_10 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_11: *mut c_char = null

    if ((if ((__param_options as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_11 = ((" noteol" as *mut c_char)))
    } else {
        (__ci_expr_ternary_11 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_12: *mut c_char = null

    if ((if ((__param_options as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_12 = ((" partial_hard" as *mut c_char)))
    } else {
        (__ci_expr_ternary_12 = (("" as *mut c_char)))
    }

    var __ci_expr_ternary_13: *mut c_char = null

    if ((if ((__param_options as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_13 = ((" partial_soft" as *mut c_char)))
    } else {
        (__ci_expr_ternary_13 = (("" as *mut c_char)))
    }

    colour_begin(__param_clr, outfile)

    fprintf(outfile, "%s%s%s%s%s%s%s%s%s%s%s%s%s%s", __ci_expr_ternary_0, __ci_expr_ternary_1, __ci_expr_ternary_2, __ci_expr_ternary_3, __ci_expr_ternary_4, __ci_expr_ternary_5, __ci_expr_ternary_6, __ci_expr_ternary_7, __ci_expr_ternary_8, __ci_expr_ternary_9, __ci_expr_ternary_10, __ci_expr_ternary_11, __ci_expr_ternary_12, __ci_expr_ternary_13)

    colour_end(outfile)


}

fn open_file(__param_buffptr: *mut u8, __param_mode: *const i8, __param_fptr: *mut *mut c_void, __param_name: *const i8) -> c_int {
    var __local_endf: *mut c_char

    var __local_filename: *mut c_char = ((__param_buffptr as *mut c_char))

    while (isspace(((unsafe: *__local_filename) as u8)) != 0) {
        (__local_filename = __local_filename + 1)
    }

    (__local_endf = (((__local_filename + (string_len(__local_filename) as usize)) as *mut c_char)))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_endf > __local_filename: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if isspace(((unsafe: __local_endf[-1]) as u8)) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_endf = __local_endf - 1)

    }

    if ((if __local_endf == __local_filename: 1 else: 0) != 0) {
        colour_begin(31, outfile)

        fprintf(outfile, "** File name expected after %s\n", __param_name)

        colour_end(outfile)


        return PR_ABEND

    }

    ((unsafe: *__local_endf) = 0)

    ((unsafe: *__param_fptr) = fopen((__local_filename as *const c_char), __param_mode))

    if ((if (unsafe: *__param_fptr) == null: 1 else: 0) != 0) {
        colour_begin(31, outfile)

        fprintf(outfile, "** Failed to open \"%s\": %s\n", __local_filename, strerror((unsafe: *__error())))

        colour_end(outfile)


        return PR_ABEND

    }

    return PR_OK

}

fn case_transform(__param_to_case: c_int, __param_num_in: c_int, __param_num_read: *mut c_int, __param_num_write: *mut c_int, __param_c1: *mut c_uint, __param_c2: *mut c_uint) -> c_int {
    if ((if (unsafe: *__param_c1) == 33: 1 else: 0) != 0) {
        return 0
    }

    ((unsafe: *__param_num_write) = 1)

    ((unsafe: *__param_num_read) = (unsafe: *__param_num_write))


    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe: *__param_c1) == 97: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((unsafe: *__param_c1) = 66)
    } else {
        var __ci_expr_logic_1: c_int = 0

        if ((if (unsafe: *__param_c1) == 66: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if __param_to_case == 1: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            ((unsafe: *__param_c1) = 97)
        } else {
            var __ci_expr_logic_2: c_int = 0

            if ((if (unsafe: *__param_c1) == 100: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                var __ci_expr_ternary_3: c_int = 0

                if ((if __param_to_case == 3: 1 else: 0) != 0) {
                    (__ci_expr_ternary_3 = 68)
                } else {
                    (__ci_expr_ternary_3 = 90)
                }

                ((unsafe: *__param_c1) = __ci_expr_ternary_3)

            } else {
                var __ci_expr_logic_4: c_int = 0

                if ((if (unsafe: *__param_c1) == 68: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if (if __param_to_case != 3: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_4 != 0) {
                    var __ci_expr_ternary_5: c_int = 0

                    if ((if __param_to_case == 1: 1 else: 0) != 0) {
                        (__ci_expr_ternary_5 = 100)
                    } else {
                        (__ci_expr_ternary_5 = 90)
                    }

                    ((unsafe: *__param_c1) = __ci_expr_ternary_5)

                } else {
                    var __ci_expr_logic_6: c_int = 0

                    if ((if (unsafe: *__param_c1) == 90: 1 else: 0) != 0) {
                        (__ci_expr_logic_6 = (if (if __param_to_case != 2: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_6 != 0) {
                        var __ci_expr_ternary_7: c_int = 0

                        if ((if __param_to_case == 1: 1 else: 0) != 0) {
                            (__ci_expr_ternary_7 = 100)
                        } else {
                            (__ci_expr_ternary_7 = 68)
                        }

                        ((unsafe: *__param_c1) = __ci_expr_ternary_7)

                    } else {
                        var __ci_expr_logic_8: c_int = 0

                        if ((if (unsafe: *__param_c1) == 102: 1 else: 0) != 0) {
                            (__ci_expr_logic_8 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_8 != 0) {
                            ((unsafe: *__param_c1) = 83)

                            ((unsafe: *__param_c2) = 83)

                            ((unsafe: *__param_num_write) = 2)

                        } else {
                            var __ci_expr_logic_9: c_int = 0

                            if ((if (unsafe: *__param_c1) == 115: 1 else: 0) != 0) {
                                (__ci_expr_logic_9 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_9 != 0) {
                                ((unsafe: *__param_c1) = 83)
                            } else {
                                var __ci_expr_logic_10: c_int = 0

                                if ((if (unsafe: *__param_c1) == 83: 1 else: 0) != 0) {
                                    (__ci_expr_logic_10 = (if (if __param_to_case == 1: 1 else: 0) != 0: 1 else: 0))
                                }

                                if (__ci_expr_logic_10 != 0) {
                                    ((unsafe: *__param_c1) = 115)
                                } else {
                                    var __ci_expr_logic_13: c_int = 0

                                    var __ci_expr_logic_12: c_int = 0

                                    var __ci_expr_logic_11: c_int = 0

                                    if ((if __param_num_in == 2: 1 else: 0) != 0) {
                                        (__ci_expr_logic_11 = (if (if (unsafe: *__param_c1) == 79: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_11 != 0) {
                                        (__ci_expr_logic_12 = (if (if (unsafe: *__param_c2) == 79: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_12 != 0) {
                                        (__ci_expr_logic_13 = (if (if __param_to_case == 1: 1 else: 0) != 0: 1 else: 0))
                                    }

                                    if (__ci_expr_logic_13 != 0) {
                                        ((unsafe: *__param_c1) = 111)

                                        ((unsafe: *__param_num_read) = 2)

                                    } else {
                                        var __ci_expr_logic_14: c_int = 0

                                        if ((if (unsafe: *__param_c1) == 111: 1 else: 0) != 0) {
                                            (__ci_expr_logic_14 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                                        }

                                        if (__ci_expr_logic_14 != 0) {
                                            ((unsafe: *__param_c1) = 79)

                                            ((unsafe: *__param_c2) = 79)

                                            ((unsafe: *__param_num_write) = 2)

                                        } else {
                                            var __ci_expr_logic_17: c_int = 0

                                            var __ci_expr_logic_16: c_int = 0

                                            var __ci_expr_logic_15: c_int = 0

                                            if ((if __param_num_in == 2: 1 else: 0) != 0) {
                                                (__ci_expr_logic_15 = (if (if (unsafe: *__param_c1) == 112: 1 else: 0) != 0: 1 else: 0))
                                            }

                                            if (__ci_expr_logic_15 != 0) {
                                                (__ci_expr_logic_16 = (if (if (unsafe: *__param_c2) == 112: 1 else: 0) != 0: 1 else: 0))
                                            }

                                            if (__ci_expr_logic_16 != 0) {
                                                (__ci_expr_logic_17 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                                            }

                                            if (__ci_expr_logic_17 != 0) {
                                                ((unsafe: *__param_c1) = 80)

                                                ((unsafe: *__param_num_read) = 2)

                                            } else {
                                                var __ci_expr_logic_18: c_int = 0

                                                if ((if (unsafe: *__param_c1) == 80: 1 else: 0) != 0) {
                                                    (__ci_expr_logic_18 = (if (if __param_to_case == 1: 1 else: 0) != 0: 1 else: 0))
                                                }

                                                if (__ci_expr_logic_18 != 0) {
                                                    ((unsafe: *__param_c1) = 112)

                                                    ((unsafe: *__param_c2) = 112)

                                                    ((unsafe: *__param_num_write) = 2)

                                                } else {
                                                    var __ci_expr_logic_19: c_int = 0

                                                    if ((if (unsafe: *__param_c1) == 108: 1 else: 0) != 0) {
                                                        (__ci_expr_logic_19 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                                                    }

                                                    if (__ci_expr_logic_19 != 0) {
                                                        ((unsafe: *__param_c1) = 77)

                                                        var __ci_expr_ternary_20: c_int = 0

                                                        if ((if __param_to_case == 3: 1 else: 0) != 0) {
                                                            (__ci_expr_ternary_20 = 110)
                                                        } else {
                                                            (__ci_expr_ternary_20 = 78)
                                                        }

                                                        ((unsafe: *__param_c2) = __ci_expr_ternary_20)


                                                        ((unsafe: *__param_num_write) = 2)

                                                    } else {
                                                        var __ci_expr_logic_21: c_int = 0

                                                        if ((if (unsafe: *__param_c1) == 77: 1 else: 0) != 0) {
                                                            (__ci_expr_logic_21 = (if (if __param_to_case == 1: 1 else: 0) != 0: 1 else: 0))
                                                        }

                                                        if (__ci_expr_logic_21 != 0) {
                                                            ((unsafe: *__param_c1) = 109)
                                                        } else {
                                                            var __ci_expr_logic_22: c_int = 0

                                                            if ((if (unsafe: *__param_c1) == 109: 1 else: 0) != 0) {
                                                                (__ci_expr_logic_22 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                                                            }

                                                            if (__ci_expr_logic_22 != 0) {
                                                                ((unsafe: *__param_c1) = 77)
                                                            } else {
                                                                var __ci_expr_logic_23: c_int = 0

                                                                if ((if (unsafe: *__param_c1) == 78: 1 else: 0) != 0) {
                                                                    (__ci_expr_logic_23 = (if (if __param_to_case == 1: 1 else: 0) != 0: 1 else: 0))
                                                                }

                                                                if (__ci_expr_logic_23 != 0) {
                                                                    ((unsafe: *__param_c1) = 110)
                                                                } else {
                                                                    var __ci_expr_logic_24: c_int = 0

                                                                    if ((if (unsafe: *__param_c1) == 110: 1 else: 0) != 0) {
                                                                        (__ci_expr_logic_24 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                                                                    }

                                                                    if (__ci_expr_logic_24 != 0) {
                                                                        ((unsafe: *__param_c1) = 78)
                                                                    } else {
                                                                        var __ci_expr_logic_26: c_int = 0

                                                                        var __ci_expr_logic_25: c_int

                                                                        if ((if (unsafe: *__param_c1) == 99: 1 else: 0) != 0) {
                                                                            (__ci_expr_logic_25 = (if true: 1 else: 0))
                                                                        } else {
                                                                            (__ci_expr_logic_25 = (if (if (unsafe: *__param_c1) == 107: 1 else: 0) != 0: 1 else: 0))
                                                                        }

                                                                        if (__ci_expr_logic_25 != 0) {
                                                                            (__ci_expr_logic_26 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                                                                        }

                                                                        if (__ci_expr_logic_26 != 0) {
                                                                            ((unsafe: *__param_c1) = 75)
                                                                        } else {
                                                                            var __ci_expr_logic_27: c_int = 0

                                                                            if ((if (unsafe: *__param_c1) == 75: 1 else: 0) != 0) {
                                                                                (__ci_expr_logic_27 = (if (if __param_to_case == 1: 1 else: 0) != 0: 1 else: 0))
                                                                            }

                                                                            if (__ci_expr_logic_27 != 0) {
                                                                                var __ci_expr_ternary_29: c_int = 0

                                                                                var __ci_expr_logic_28: c_int

                                                                                if ((if __param_num_in == 1: 1 else: 0) != 0) {
                                                                                    (__ci_expr_logic_28 = (if true: 1 else: 0))
                                                                                } else {
                                                                                    (__ci_expr_logic_28 = (if (if (unsafe: *__param_c2) == 32: 1 else: 0) != 0: 1 else: 0))
                                                                                }

                                                                                if (__ci_expr_logic_28 != 0) {
                                                                                    (__ci_expr_ternary_29 = 99)
                                                                                } else {
                                                                                    (__ci_expr_ternary_29 = 107)
                                                                                }

                                                                                ((unsafe: *__param_c1) = __ci_expr_ternary_29)

                                                                            } else {
                                                                                var __ci_expr_logic_34: c_int = 0

                                                                                var __ci_expr_logic_33: c_int = 0

                                                                                var __ci_expr_logic_31: c_int = 0

                                                                                if ((if __param_num_in == 2: 1 else: 0) != 0) {
                                                                                    var __ci_expr_logic_30: c_int

                                                                                    if ((if (unsafe: *__param_c1) == 105: 1 else: 0) != 0) {
                                                                                        (__ci_expr_logic_30 = (if true: 1 else: 0))
                                                                                    } else {
                                                                                        (__ci_expr_logic_30 = (if (if (unsafe: *__param_c1) == 73: 1 else: 0) != 0: 1 else: 0))
                                                                                    }

                                                                                    (__ci_expr_logic_31 = (if __ci_expr_logic_30 != 0: 1 else: 0))

                                                                                }

                                                                                if (__ci_expr_logic_31 != 0) {
                                                                                    var __ci_expr_logic_32: c_int

                                                                                    if ((if (unsafe: *__param_c2) == 106: 1 else: 0) != 0) {
                                                                                        (__ci_expr_logic_32 = (if true: 1 else: 0))
                                                                                    } else {
                                                                                        (__ci_expr_logic_32 = (if (if (unsafe: *__param_c2) == 74: 1 else: 0) != 0: 1 else: 0))
                                                                                    }

                                                                                    (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

                                                                                }

                                                                                if (__ci_expr_logic_33 != 0) {
                                                                                    (__ci_expr_logic_34 = (if (if __param_to_case == 3: 1 else: 0) != 0: 1 else: 0))
                                                                                }

                                                                                if (__ci_expr_logic_34 != 0) {
                                                                                    ((unsafe: *__param_c1) = 73)

                                                                                    ((unsafe: *__param_c2) = 74)

                                                                                    ((unsafe: *__param_num_read) = 2)

                                                                                    ((unsafe: *__param_num_write) = 2)

                                                                                } else {
                                                                                    var __ci_expr_logic_35: c_int = 0

                                                                                    if ((if (unsafe: *__param_c1) == 105: 1 else: 0) != 0) {
                                                                                        (__ci_expr_logic_35 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                                                                                    }

                                                                                    if (__ci_expr_logic_35 != 0) {
                                                                                        ((unsafe: *__param_c1) = 73)
                                                                                    } else {
                                                                                        var __ci_expr_logic_36: c_int = 0

                                                                                        if ((if (unsafe: *__param_c1) == 73: 1 else: 0) != 0) {
                                                                                            (__ci_expr_logic_36 = (if (if __param_to_case == 1: 1 else: 0) != 0: 1 else: 0))
                                                                                        }

                                                                                        if (__ci_expr_logic_36 != 0) {
                                                                                            ((unsafe: *__param_c1) = 105)
                                                                                        } else {
                                                                                            var __ci_expr_logic_37: c_int = 0

                                                                                            if ((if (unsafe: *__param_c1) == 106: 1 else: 0) != 0) {
                                                                                                (__ci_expr_logic_37 = (if (if __param_to_case != 1: 1 else: 0) != 0: 1 else: 0))
                                                                                            }

                                                                                            if (__ci_expr_logic_37 != 0) {
                                                                                                ((unsafe: *__param_c1) = 74)
                                                                                            } else {
                                                                                                var __ci_expr_logic_38: c_int = 0

                                                                                                if ((if (unsafe: *__param_c1) == 74: 1 else: 0) != 0) {
                                                                                                    (__ci_expr_logic_38 = (if (if __param_to_case == 1: 1 else: 0) != 0: 1 else: 0))
                                                                                                }

                                                                                                if (__ci_expr_logic_38 != 0) {
                                                                                                    ((unsafe: *__param_c1) = 106)
                                                                                                }

                                                                                            }

                                                                                        }

                                                                                    }

                                                                                }

                                                                            }

                                                                        }

                                                                    }

                                                                }

                                                            }

                                                        }

                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                            }

                        }

                    }

                }

            }

        }

    }


    return 1

}

fn show_ovector(__param_ovector: *mut c_ulong, __param_oveccount: c_uint) {
    var __local_i: c_uint

    (__local_i = 0)

    while ((if __local_i < ((2 as c_uint) *% (__param_oveccount as c_uint)): 1 else: 0) != 0) {
        var __local_start: c_ulong = (unsafe: __param_ovector[__local_i])

        var __local_end: c_ulong = (unsafe: __param_ovector[((__local_i as c_uint) +% (1 as c_uint))])

        fprintf(outfile, "%2d: ", ((__local_i as c_uint) / (2 as c_uint)))

        var __ci_expr_logic_0: c_int = 0

        if ((if __local_start == (~(0 as c_ulong)): 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_end == (~(0 as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            fprintf(outfile, "<unset>\n")
        } else {
            var __ci_expr_logic_1: c_int = 0

            if ((if __local_start == 3735928559: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if __local_end == 3735928559: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                fprintf(outfile, "<unchanged>\n")
            } else {
                fprintf(outfile, "%ld %ld\n", __local_start, __local_end)
            }

        }



        (__local_i = __local_i + 2)

    }


}

fn jit_callback_8(__param_arg: *mut c_void) -> *mut pcre2_real_jit_stack_8 {
    (jit_was_used = 1)

    return ((__param_arg as *mut pcre2_real_jit_stack_8))

}

fn pcre2_strcmp_c8_8(__param_str1: *const u8, __param_str2: *const i8) -> c_int {
    var __local_str1 = __param_str1
    var __local_str2 = __param_str2
    var __local_c1: u8

    var __local_c2: u8


    while true {
        var __ci_expr_logic_0: c_int

        if ((if (unsafe: *__local_str1) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe: *__local_str2) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_str1

        (__local_str1 = __local_str1 + 1)

        (__local_c1 = (unsafe: *__ci_expr_old_1))

        var __ci_expr_old_2: *const c_char = __local_str2

        (__local_str2 = __local_str2 + 1)

        (__local_c2 = (unsafe: *__ci_expr_old_2))

        if ((if __local_c1 != __local_c2: 1 else: 0) != 0) {
            return ((((if __local_c1 > __local_c2: 1 else: 0) as c_int) << (1 as c_uint)) - 1)
        }

    }

    return 0

}

fn pcre2_strlen_8(__param_str: *const u8) -> c_ulong {
    var __local_str = __param_str
    var __local_c: c_ulong = 0

    while true {
        var __ci_expr_old_0: *const u8 = __local_str

        (__local_str = __local_str + 1)

        if (not ((if (unsafe: *__ci_expr_old_0) != 0: 1 else: 0) != 0)) {
            break
        }

        (__local_c = __local_c + 1)

    }

    return __local_c

}

fn pchars_8(__param_clr: c_int, __param_p: *const u8, __param_length: c_long, __param_utf: c_int, __param_f: *mut c_void) -> c_int {
    var __local_p = __param_p
    var __local_length = __param_length
    var __local_end: *const u8

    var __local_c: c_uint = 0

    var __local_yield_: c_int = 0

    colour_begin(__param_clr, __param_f)

    if ((if __local_length < 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const u8 = __local_p

        (__local_p = __local_p + 1)

        (__local_length = (unsafe: *__ci_expr_old_0))

    }

    (__local_end = __local_p + ((__local_length as isize) as usize))

    while true {
        var __ci_expr_old_1: c_long = __local_length

        (__local_length = __local_length - 1)

        if (not ((if __ci_expr_old_1 > 0: 1 else: 0) != 0)) {
            break
        }

        if (__param_utf != 0) {
            var __local_rc: c_int = utf8_to_ord(__local_p, __local_end, (&raw mut __local_c as *mut c_uint))

            var __ci_expr_logic_2: c_int = 0

            if ((if __local_rc > 0: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if __local_rc <= (__local_length + 1): 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                (__local_length = __local_length - (__local_rc - 1))

                (__local_p = __local_p + ((__local_rc as isize) as usize))

                (__local_yield_ = __local_yield_ + pchar(__local_c, __param_utf, __param_f))

                continue

            }


        }

        var __ci_expr_old_3: *const u8 = __local_p

        (__local_p = __local_p + 1)

        (__local_c = (unsafe: *__ci_expr_old_3))

        (__local_yield_ = __local_yield_ + pchar(__local_c, __param_utf, __param_f))

    }

    colour_end(__param_f)

    return __local_yield_

}

fn ptrunc_8(__param_clr: c_int, __param_p: *const u8, __param_p_len: c_ulong, __param_offset: c_ulong, __param_left: c_int, __param_utf: c_int, __param_f: *mut c_void) {
    var __local_start: *const u8 = (__param_p + (__param_offset as usize))

    var __local_end: *const u8 = (__param_p + (__param_offset as usize))

    var __local_printed: c_ulong = 0

    colour_begin(__param_clr, __param_f)

    if (__param_left != 0) {
        while true {
            var __ci_expr_logic_0: c_int = 0

            if ((if __local_start > __param_p: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if __local_printed < 10: 1 else: 0) != 0: 1 else: 0))
            }

            if (not (__ci_expr_logic_0 != 0)) {
                break
            }

            (__local_printed = __local_printed + 1)

            (__local_start = __local_start - 1)

            if (__param_utf != 0) {
                while true {
                    var __ci_expr_logic_1: c_int = 0

                    if ((if __local_start > __param_p: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if (if ((((unsafe: *__local_start) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (not (__ci_expr_logic_1 != 0)) {
                        break
                    }

                    (__local_start = __local_start - 1)

                }

            }

        }

    } else {
        while true {
            var __ci_expr_logic_2: c_int = 0

            if ((if __local_end < (__param_p + (__param_p_len as usize)): 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if __local_printed < 10: 1 else: 0) != 0: 1 else: 0))
            }

            if (not (__ci_expr_logic_2 != 0)) {
                break
            }

            (__local_printed = __local_printed + 1)

            (__local_end = __local_end + 1)

            if (__param_utf != 0) {
                while true {
                    var __ci_expr_logic_3: c_int = 0

                    if ((if __local_end < (__param_p + (__param_p_len as usize)): 1 else: 0) != 0) {
                        (__ci_expr_logic_3 = (if (if ((((unsafe: *__local_end) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (not (__ci_expr_logic_3 != 0)) {
                        break
                    }

                    (__local_end = __local_end + 1)

                }

            }

        }

    }

    var __ci_expr_logic_4: c_int = 0

    if (__param_left != 0) {
        (__ci_expr_logic_4 = (if (if __local_start > __param_p: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        fprintf(__param_f, "...")
    }


    while ((if __local_start < __local_end: 1 else: 0) != 0) {
        fprintf(__param_f, "%c", (unsafe: *__local_start))

        (__local_start = __local_start + 1)

    }

    var __ci_expr_logic_5: c_int = 0

    if ((if not (__param_left != 0): 1 else: 0) != 0) {
        (__ci_expr_logic_5 = (if (if __local_end < (__param_p + (__param_p_len as usize)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        fprintf(__param_f, "...")
    }


    colour_end(__param_f)

}

fn config_str_8(__param_what: c_uint, __param_where_: *mut i8) {
    var __local_r1: c_int

    var __local_r2: c_int


    var __local_buf: [64]u8

    (__local_r1 = pcre2_config_8(__param_what, null))

    (__local_r2 = pcre2_config_8(__param_what, (&(unsafe: __local_buf[0]) as *mut u8)))

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if __local_r1 < 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __local_r1 != __local_r2: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __local_r1 >= 64: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        colour_begin(31, libc_stderr())

        fprintf(libc_stderr(), "pcre2test: Error in pcre2_config(%d)\n", __param_what)

        colour_end(libc_stderr())


        exit(1)

    }


    while true {
        var __ci_expr_old_2: c_int = __local_r1

        (__local_r1 = __local_r1 - 1)

        if (not ((if __ci_expr_old_2 > 0: 1 else: 0) != 0)) {
            break
        }

        ((unsafe: __param_where_[__local_r1]) = ((__local_buf[__local_r1] as c_char)))

    }

}

fn check_modifier_8(__param_m: *mut modstruct, __param_ctx: c_int, __param_pctl: *mut patctl, __param_dctl: *mut datctl, __param_c: c_uint) -> *mut c_void {
    var __local_field: *mut c_void = null

    var __local_offset: c_ulong = __param_m.offset

    if (restrict_for_perl_test != 0) {
        while true {
            match __param_m.which {
                9 => {
                    0
                },
                3 => {
                    0
                },
                5 => {
                    0
                },
                7 => {
                    0
                },
                _ => {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** \"%s\" is not allowed in a Perl-compatible test\n", __param_m.name)

                    colour_end(outfile)


                    return null

                },
            }

            break

        }
    }

    while true {
        match __param_m.which {
            0 => {
                if ((if __param_ctx == CTX_DEFPAT: 1 else: 0) != 0) {
                    (__local_field = ((default_pat_context_8 as *mut c_void)))
                } else {
                    if ((if __param_ctx == CTX_PAT: 1 else: 0) != 0) {
                        (__local_field = ((pat_context_8 as *mut c_void)))
                    }
                }
            },
            1 => {
                if ((if __param_ctx == CTX_DEFDAT: 1 else: 0) != 0) {
                    (__local_field = ((default_dat_context_8 as *mut c_void)))
                } else {
                    if ((if __param_ctx == CTX_DAT: 1 else: 0) != 0) {
                        (__local_field = ((dat_context_8 as *mut c_void)))
                    }
                }
            },
            4 => {
                if ((if __param_dctl != null: 1 else: 0) != 0) {
                    (__local_field = ((__param_dctl as *mut c_void)))
                }
            },
            5 => {
                if ((if __param_dctl != null: 1 else: 0) != 0) {
                    (__local_field = ((__param_dctl as *mut c_void)))
                }
            },
            2 => {
                if ((if __param_pctl != null: 1 else: 0) != 0) {
                    (__local_field = ((__param_pctl as *mut c_void)))
                }
            },
            3 => {
                if ((if __param_pctl != null: 1 else: 0) != 0) {
                    (__local_field = ((__param_pctl as *mut c_void)))
                }
            },
            6 => {
                if ((if __param_dctl != null: 1 else: 0) != 0) {
                    (__local_field = ((__param_dctl as *mut c_void)))
                } else {
                    var __ci_expr_logic_3: c_int = 0

                    if ((if __param_pctl != null: 1 else: 0) != 0) {
                        var __ci_expr_logic_2: c_int

                        var __ci_expr_logic_1: c_int

                        if ((if __param_m.which == MOD_PD: 1 else: 0) != 0) {
                            (__ci_expr_logic_1 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_1 = (if (if __param_m.which == MOD_PDP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_1 != 0) {
                            (__ci_expr_logic_2 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_2 = (if (if __param_ctx != CTX_DEFPAT: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_3 != 0) {
                        (__local_field = ((__param_pctl as *mut c_void)))
                    }

                }
            },
            7 => {
                if ((if __param_dctl != null: 1 else: 0) != 0) {
                    (__local_field = ((__param_dctl as *mut c_void)))
                } else {
                    var __ci_expr_logic_3: c_int = 0

                    if ((if __param_pctl != null: 1 else: 0) != 0) {
                        var __ci_expr_logic_2: c_int

                        var __ci_expr_logic_1: c_int

                        if ((if __param_m.which == MOD_PD: 1 else: 0) != 0) {
                            (__ci_expr_logic_1 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_1 = (if (if __param_m.which == MOD_PDP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_1 != 0) {
                            (__ci_expr_logic_2 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_2 = (if (if __param_ctx != CTX_DEFPAT: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_3 != 0) {
                        (__local_field = ((__param_pctl as *mut c_void)))
                    }

                }
            },
            8 => {
                if ((if __param_dctl != null: 1 else: 0) != 0) {
                    (__local_field = ((__param_dctl as *mut c_void)))
                } else {
                    var __ci_expr_logic_3: c_int = 0

                    if ((if __param_pctl != null: 1 else: 0) != 0) {
                        var __ci_expr_logic_2: c_int

                        var __ci_expr_logic_1: c_int

                        if ((if __param_m.which == MOD_PD: 1 else: 0) != 0) {
                            (__ci_expr_logic_1 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_1 = (if (if __param_m.which == MOD_PDP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_1 != 0) {
                            (__ci_expr_logic_2 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_2 = (if (if __param_ctx != CTX_DEFPAT: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_3 != 0) {
                        (__local_field = ((__param_pctl as *mut c_void)))
                    }

                }
            },
            9 => {
                if ((if __param_dctl != null: 1 else: 0) != 0) {
                    (__local_field = ((__param_dctl as *mut c_void)))
                } else {
                    var __ci_expr_logic_3: c_int = 0

                    if ((if __param_pctl != null: 1 else: 0) != 0) {
                        var __ci_expr_logic_2: c_int

                        var __ci_expr_logic_1: c_int

                        if ((if __param_m.which == MOD_PD: 1 else: 0) != 0) {
                            (__ci_expr_logic_1 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_1 = (if (if __param_m.which == MOD_PDP: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_1 != 0) {
                            (__ci_expr_logic_2 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_2 = (if (if __param_ctx != CTX_DEFPAT: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_3 != 0) {
                        (__local_field = ((__param_pctl as *mut c_void)))
                    }

                }
            },
        }

        break

    }

    if ((if __local_field == null: 1 else: 0) != 0) {
        if ((if __param_c == 0: 1 else: 0) != 0) {
            colour_begin(31, outfile)

            fprintf(outfile, "** \"%s\" is not valid here\n", __param_m.name)

            colour_end(outfile)

        } else {
            colour_begin(31, outfile)

            fprintf(outfile, "** /%c is not valid here\n", __param_c)

            colour_end(outfile)

        }

        return null

    }

    return ((__local_field as *mut c_char) + (__local_offset as usize))

}

fn decode_modifiers_8(__param_p: *mut u8, __param_ctx: c_int, __param_pctl: *mut patctl, __param_dctl: *mut datctl) -> c_int {
    var __local_p = __param_p
    var __local_ep__goto_696_10: *mut u8 = null

    var __local_pp__goto_696_15: *mut u8 = null

    var __local_li__goto_697_6: c_long = 0

    var __local_uli__goto_698_15: c_ulong = 0

    var __local_first__goto_699_6: c_int = 0

    var __local_field__goto_703_9: *mut c_void = null

    var __local_m__goto_704_14: *mut modstruct = null

    var __local_off__goto_705_8: c_int = 0

    var __local_i__goto_706_16: c_uint = 0

    var __local_len__goto_707_10: c_ulong = 0

    var __local_index__goto_708_7: c_int = 0

    var __local_endptr__goto_709_9: *mut i8 = null

    var __local_cc__goto_745_14: c_uint = 0

    var __local_mp__goto_746_14: *mut u8 = null

    var __local_colon__goto_886_16: *mut u8 = null

    var __local_ct__goto_982_11: c_int = 0

    var __local_value__goto_983_15: c_int = 0

    var __local_nn__goto_1007_13: *mut i8 = null

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_logic_8: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_old_11: *mut u8 = null

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_logic_13: c_int = 0

    var __ci_expr_logic_12: c_int = 0

    var __ci_expr_logic_15: c_int = 0

    var __ci_expr_logic_16: c_int = 0

    var __ci_expr_logic_17: c_int = 0

    var __ci_expr_logic_18: c_int = 0

    var __ci_expr_logic_19: c_int = 0

    var __ci_expr_old_20: *mut u8 = null

    var __ci_expr_ternary_22: *mut u8 = null

    var __ci_expr_logic_21: c_int = 0

    var __ci_expr_logic_23: c_int = 0

    var __ci_expr_logic_24: c_int = 0

    var __ci_expr_logic_25: c_int = 0

    var __ci_expr_logic_26: c_int = 0

    var __ci_expr_logic_27: c_int = 0

    var __ci_expr_logic_28: c_int = 0

    var __ci_expr_logic_29: c_int = 0

    var __ci_expr_logic_31: c_int = 0

    var __ci_expr_logic_34: c_int = 0

    var __ci_expr_logic_33: c_int = 0

    var __ci_expr_logic_32: c_int = 0

    var __ci_expr_logic_38: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_first__goto_699_6 = 1)
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        goto '__ci_bb_2
    }

    '__ci_bb_2 {
        (__local_off__goto_705_8 = 0)
        goto '__ci_bb_5
    }

    '__ci_bb_3 {
        goto '__ci_bb_1
    }

    '__ci_bb_4 {
        return 1
    }

    '__ci_bb_5 {
        if (isspace((unsafe: *__local_p)) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe: *__local_p) == 44: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_6 {
        (__local_p = __local_p + 1)
        goto '__ci_bb_5
    }

    '__ci_bb_7 {
        if ((if (unsafe: *__local_p) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_8 {
        goto '__ci_bb_4
    }

    '__ci_bb_9 {
        (__local_ep__goto_696_10 = __local_p)
        goto '__ci_bb_10
    }

    '__ci_bb_10 {
        (__ci_expr_logic_1 = 0)
        if ((if (unsafe: *__local_ep__goto_696_10) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe: *__local_ep__goto_696_10) != 44: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_11 {
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        (__local_ep__goto_696_10 = __local_ep__goto_696_10 + 1)
        goto '__ci_bb_10
    }

    '__ci_bb_13 {
        if ((if (unsafe: *__local_ep__goto_696_10) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_14 {
        goto '__ci_bb_16
    }

    '__ci_bb_15 {
        if ((if (unsafe: *__local_p) == 45: 1 else: 0) != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_16 {
        (__ci_expr_logic_2 = 0)
        if ((if __local_ep__goto_696_10 > __local_p: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if isspace((unsafe: __local_ep__goto_696_10[-1])) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_17 {
        (__local_ep__goto_696_10 = __local_ep__goto_696_10 - 1)
        goto '__ci_bb_16
    }

    '__ci_bb_18 {
        ((unsafe: *__local_ep__goto_696_10) = 0)
        goto '__ci_bb_15
    }

    '__ci_bb_19 {
        (__local_off__goto_705_8 = 1)
        (__local_p = __local_p + 1)
        goto '__ci_bb_20
    }

    '__ci_bb_20 {
        (__local_pp__goto_696_15 = __local_p)
        goto '__ci_bb_21
    }

    '__ci_bb_21 {
        (__ci_expr_logic_3 = 0)
        if ((if __local_pp__goto_696_15 < __local_ep__goto_696_10: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if (unsafe: *__local_pp__goto_696_15) != 61: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_22 {
        (__local_pp__goto_696_15 = __local_pp__goto_696_15 + 1)
        goto '__ci_bb_21
    }

    '__ci_bb_23 {
        (__local_index__goto_708_7 = scan_modifiers(__local_p, (((__local_pp__goto_696_15 as usize) -% (__local_p as usize)) / sizeof[u8]())))
        if ((if __local_index__goto_708_7 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_24 {
        (__local_mp__goto_746_14 = __local_p)
        if ((if not (__local_first__goto_699_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_25 {
        (__local_m__goto_704_14 = (&(unsafe: modlist[0]) as *mut modstruct) + ((__local_index__goto_708_7 as isize) as usize))
        (__ci_expr_logic_10 = 0)
        (__ci_expr_logic_8 = 0)
        (__ci_expr_logic_7 = 0)
        if ((if __local_m__goto_704_14.type_ != MOD_CTL: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if (if __local_m__goto_704_14.type_ != MOD_OPT: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            (__ci_expr_logic_8 = (if (if __local_m__goto_704_14.type_ != MOD_OPTMZ: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_8 != 0) {
            var __ci_expr_logic_9: c_int

            if ((if __local_m__goto_704_14.type_ != MOD_IND: 1 else: 0) != 0) {
                (__ci_expr_logic_9 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_9 = (if (if (unsafe: *__local_pp__goto_696_15) == 61: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_10 = (if __ci_expr_logic_9 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_10 != 0) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_26 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unrecognized modifier \"%.*s\"\n", ((((__local_ep__goto_696_10 as usize) -% (__local_p as usize)) / sizeof[u8]()) as c_int), __local_p)
        colour_end(outfile)
        if ((if (((__local_ep__goto_696_10 as usize) -% (__local_p as usize)) / sizeof[u8]()) == 1: 1 else: 0) != 0) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_27 {
        (__local_first__goto_699_6 = 0)
        (__local_cc__goto_745_14 = (unsafe: *__local_p))
        goto '__ci_bb_30
    }

    '__ci_bb_28 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Single-character modifiers must come first\n")
        colour_end(outfile)
        goto '__ci_bb_29
    }

    '__ci_bb_29 {
        return 0
    }

    '__ci_bb_30 {
        (__ci_expr_logic_5 = 0)
        (__ci_expr_logic_4 = 0)
        if ((if __local_cc__goto_745_14 != 44: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if __local_cc__goto_745_14 != 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_logic_5 = (if (if __local_cc__goto_745_14 != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_31 {
        (__local_i__goto_706_16 = 0)
        goto '__ci_bb_34
    }

    '__ci_bb_32 {
        (__local_p = __local_p + 1)
        (__local_cc__goto_745_14 = (unsafe: *__local_p))
        goto '__ci_bb_30
    }

    '__ci_bb_33 {
        goto '__ci_bb_3
    }

    '__ci_bb_34 {
        if ((if __local_i__goto_706_16 < 10: 1 else: 0) != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_37
        }
    }

    '__ci_bb_35 {
        if ((if __local_cc__goto_745_14 == c1modlist[__local_i__goto_706_16].onechar: 1 else: 0) != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_36 {
        (__local_i__goto_706_16 = __local_i__goto_706_16 + 1)
        goto '__ci_bb_34
    }

    '__ci_bb_37 {
        if ((if __local_i__goto_706_16 >= 10: 1 else: 0) != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_38 {
        goto '__ci_bb_37
    }

    '__ci_bb_39 {
        goto '__ci_bb_36
    }

    '__ci_bb_40 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unrecognized modifier '%c' in modifier string \"%.*s\"\n", (unsafe: *__local_p), ((((__local_ep__goto_696_10 as usize) -% (__local_mp__goto_746_14 as usize)) / sizeof[u8]()) as c_int), __local_mp__goto_746_14)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_41 {
        if ((if c1modlist[__local_i__goto_706_16].index >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_42 {
        (__local_index__goto_708_7 = c1modlist[__local_i__goto_706_16].index)
        goto '__ci_bb_44
    }

    '__ci_bb_43 {
        (__local_index__goto_708_7 = scan_modifiers((c1modlist[__local_i__goto_706_16].fullname as *const u8), string_len(c1modlist[__local_i__goto_706_16].fullname)))
        if ((if __local_index__goto_708_7 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_44 {
        (__local_field__goto_703_9 = check_modifier_8(((&(unsafe: modlist[0]) as *mut modstruct) + ((__local_index__goto_708_7 as isize) as usize)), __param_ctx, __param_pctl, __param_dctl, (unsafe: *__local_p)))
        if ((if __local_field__goto_703_9 == null: 1 else: 0) != 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_45 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Internal error: single-character equivalent modifier \"%s\" not found\n", c1modlist[__local_i__goto_706_16].fullname)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_46 {
        (c1modlist[__local_i__goto_706_16].index = __local_index__goto_708_7)
        goto '__ci_bb_44
    }

    '__ci_bb_47 {
        return 0
    }

    '__ci_bb_48 {
        (__ci_expr_logic_6 = 0)
        if ((if __local_cc__goto_745_14 == 120: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if (((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            goto '__ci_bb_49
        } else {
            goto '__ci_bb_50
        }
    }

    '__ci_bb_49 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = (unsafe: *(__local_field__goto_703_9 as *mut c_uint)) & (~128))
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = (unsafe: *(__local_field__goto_703_9 as *mut c_uint)) | 16777216)
        goto '__ci_bb_51
    }

    '__ci_bb_50 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = (unsafe: *(__local_field__goto_703_9 as *mut c_uint)) | modlist[__local_index__goto_708_7].value)
        goto '__ci_bb_51
    }

    '__ci_bb_51 {
        goto '__ci_bb_32
    }

    '__ci_bb_52 {
        (__ci_expr_old_11 = __local_pp__goto_696_15)
        (__local_pp__goto_696_15 = __local_pp__goto_696_15 + 1)
        if ((if (unsafe: *__ci_expr_old_11) != 61: 1 else: 0) != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_53 {
        (__ci_expr_logic_14 = 0)
        (__ci_expr_logic_13 = 0)
        (__ci_expr_logic_12 = 0)
        if ((if (unsafe: *__local_pp__goto_696_15) != 44: 1 else: 0) != 0) {
            (__ci_expr_logic_12 = (if (if (unsafe: *__local_pp__goto_696_15) != 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_12 != 0) {
            (__ci_expr_logic_13 = (if (if (unsafe: *__local_pp__goto_696_15) != 32: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            (__ci_expr_logic_14 = (if (if (unsafe: *__local_pp__goto_696_15) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_54 {
        (__local_len__goto_707_10 = ((__local_ep__goto_696_10 as usize) -% (__local_pp__goto_696_15 as usize)) / sizeof[u8]())
        (__local_field__goto_703_9 = check_modifier_8(__local_m__goto_704_14, __param_ctx, __param_pctl, __param_dctl, 0))
        if ((if __local_field__goto_703_9 == null: 1 else: 0) != 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_55 {
        colour_begin(31, outfile)
        fprintf(outfile, "** '=' expected after \"%s\"\n", __local_m__goto_704_14.name)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_56 {
        if (__local_off__goto_705_8 != 0) {
            goto '__ci_bb_57
        } else {
            goto '__ci_bb_58
        }
    }

    '__ci_bb_57 {
        colour_begin(31, outfile)
        fprintf(outfile, "** '-' is not valid for \"%s\"\n", __local_m__goto_704_14.name)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_58 {
        goto '__ci_bb_54
    }

    '__ci_bb_59 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unrecognized modifier '%.*s'\n", ((((__local_ep__goto_696_10 as usize) -% (__local_p as usize)) / sizeof[u8]()) as c_int), __local_p)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_60 {
        goto '__ci_bb_54
    }

    '__ci_bb_61 {
        return 0
    }

    '__ci_bb_62 {
        goto '__ci_bb_63
    }

    '__ci_bb_63 {
        if (__local_m__goto_704_14.type_ == 12) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_64 {
        (__ci_expr_logic_34 = 0)
        (__ci_expr_logic_33 = 0)
        (__ci_expr_logic_32 = 0)
        if ((if (unsafe: *__local_pp__goto_696_15) != 44: 1 else: 0) != 0) {
            (__ci_expr_logic_32 = (if (if (unsafe: *__local_pp__goto_696_15) != 10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_32 != 0) {
            (__ci_expr_logic_33 = (if (if (unsafe: *__local_pp__goto_696_15) != 32: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_33 != 0) {
            (__ci_expr_logic_34 = (if (if (unsafe: *__local_pp__goto_696_15) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_34 != 0) {
            goto '__ci_bb_192
        } else {
            goto '__ci_bb_193
        }
    }

    '__ci_bb_65 {
        if (__local_off__goto_705_8 != 0) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_67
        }
    }

    '__ci_bb_66 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = (unsafe: *(__local_field__goto_703_9 as *mut c_uint)) & (~__local_m__goto_704_14.value))
        goto '__ci_bb_68
    }

    '__ci_bb_67 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = (unsafe: *(__local_field__goto_703_9 as *mut c_uint)) | __local_m__goto_704_14.value)
        goto '__ci_bb_68
    }

    '__ci_bb_68 {
        goto '__ci_bb_64
    }

    '__ci_bb_69 {
        pcre2_set_optimize_8(__local_field__goto_703_9, __local_m__goto_704_14.value)
        goto '__ci_bb_64
    }

    '__ci_bb_70 {
        (__ci_expr_logic_15 = 0)
        if ((if __local_len__goto_707_10 == 7: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if (if strncmpic(__local_pp__goto_696_15, ("default" as *const u8), 7) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_15 != 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_72
        }
    }

    '__ci_bb_71 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_ushort)) = 1)
        if ((if __param_ctx == CTX_PAT: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_16 = (if (if __param_ctx == CTX_DEFPAT: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_74
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_72 {
        (__ci_expr_logic_17 = 0)
        if ((if __local_len__goto_707_10 == 7: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if strncmpic(__local_pp__goto_696_15, ("anycrlf" as *const u8), 7) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            goto '__ci_bb_77
        } else {
            goto '__ci_bb_78
        }
    }

    '__ci_bb_73 {
        (__local_pp__goto_696_15 = __local_ep__goto_696_10)
        goto '__ci_bb_64
    }

    '__ci_bb_74 {
        ((unsafe: *__param_pctl).control2 = __param_pctl.control2 & (~2147483648))
        goto '__ci_bb_76
    }

    '__ci_bb_75 {
        ((unsafe: *__param_dctl).control2 = __param_dctl.control2 & (~2147483648))
        goto '__ci_bb_76
    }

    '__ci_bb_76 {
        goto '__ci_bb_73
    }

    '__ci_bb_77 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_ushort)) = 2)
        goto '__ci_bb_79
    }

    '__ci_bb_78 {
        (__ci_expr_logic_18 = 0)
        if ((if __local_len__goto_707_10 == 7: 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if (if strncmpic(__local_pp__goto_696_15, ("unicode" as *const u8), 7) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_18 != 0) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_79 {
        if ((if __param_ctx == CTX_PAT: 1 else: 0) != 0) {
            (__ci_expr_logic_19 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_19 = (if (if __param_ctx == CTX_DEFPAT: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_19 != 0) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_85
        }
    }

    '__ci_bb_80 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_ushort)) = 1)
        goto '__ci_bb_82
    }

    '__ci_bb_81 {
        goto '__ci_bb_83
    }

    '__ci_bb_82 {
        goto '__ci_bb_79
    }

    '__ci_bb_83 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Invalid value in \"%.*s\"\n", ((((__local_ep__goto_696_10 as usize) -% (__local_p as usize)) / sizeof[u8]()) as c_int), __local_p)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_84 {
        ((unsafe: *__param_pctl).control2 = __param_pctl.control2 | 2147483648)
        goto '__ci_bb_86
    }

    '__ci_bb_85 {
        ((unsafe: *__param_dctl).control2 = __param_dctl.control2 | 2147483648)
        goto '__ci_bb_86
    }

    '__ci_bb_86 {
        goto '__ci_bb_73
    }

    '__ci_bb_87 {
        (__ci_expr_old_20 = __local_pp__goto_696_15)
        (__local_pp__goto_696_15 = __local_pp__goto_696_15 + 1)
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = (unsafe: *__ci_expr_old_20))
        goto '__ci_bb_64
    }

    '__ci_bb_88 {
        goto '__ci_bb_89
    }

    '__ci_bb_89 {
        goto '__ci_bb_90
    }

    '__ci_bb_90 {
        (__local_colon__goto_886_16 = ((string_find_char((__local_pp__goto_696_15 as *const c_char), 58) as *mut u8)))
        (__ci_expr_ternary_22 = null)
        (__ci_expr_logic_21 = 0)
        if ((if __local_colon__goto_886_16 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_21 = (if (if __local_colon__goto_886_16 < __local_ep__goto_696_10: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_21 != 0) {
            (__ci_expr_ternary_22 = __local_colon__goto_886_16)
        } else {
            (__ci_expr_ternary_22 = __local_ep__goto_696_10)
        }
        (__local_len__goto_707_10 = ((__ci_expr_ternary_22 as usize) -% (__local_pp__goto_696_15 as usize)) / sizeof[u8]())
        (__local_i__goto_706_16 = 0)
        goto '__ci_bb_93
    }

    '__ci_bb_91 {
        (__local_pp__goto_696_15 = __local_pp__goto_696_15 + 1)
        goto '__ci_bb_89
    }

    '__ci_bb_92 {
        goto '__ci_bb_64
    }

    '__ci_bb_93 {
        if ((if __local_i__goto_706_16 < 6: 1 else: 0) != 0) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_96
        }
    }

    '__ci_bb_94 {
        if ((if strncmpic(__local_pp__goto_696_15, (convertlist[__local_i__goto_706_16].name as *const u8), __local_len__goto_707_10) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_95 {
        (__local_i__goto_706_16 = __local_i__goto_706_16 + 1)
        goto '__ci_bb_93
    }

    '__ci_bb_96 {
        if ((if __local_i__goto_706_16 >= 6: 1 else: 0) != 0) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_103
        }
    }

    '__ci_bb_97 {
        if ((if (unsafe: *(__local_field__goto_703_9 as *mut c_uint)) == 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_99
        } else {
            goto '__ci_bb_100
        }
    }

    '__ci_bb_98 {
        goto '__ci_bb_95
    }

    '__ci_bb_99 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = convertlist[__local_i__goto_706_16].option)
        goto '__ci_bb_101
    }

    '__ci_bb_100 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = (unsafe: *(__local_field__goto_703_9 as *mut c_uint)) | convertlist[__local_i__goto_706_16].option)
        goto '__ci_bb_101
    }

    '__ci_bb_101 {
        goto '__ci_bb_96
    }

    '__ci_bb_102 {
        goto '__ci_bb_83
    }

    '__ci_bb_103 {
        (__local_pp__goto_696_15 = __local_pp__goto_696_15 + (__local_len__goto_707_10 as usize))
        if ((if (unsafe: *__local_pp__goto_696_15) != 58: 1 else: 0) != 0) {
            goto '__ci_bb_104
        } else {
            goto '__ci_bb_105
        }
    }

    '__ci_bb_104 {
        goto '__ci_bb_92
    }

    '__ci_bb_105 {
        goto '__ci_bb_91
    }

    '__ci_bb_106 {
        if ((if not (isdigit((unsafe: *__local_pp__goto_696_15)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_107
        } else {
            goto '__ci_bb_108
        }
    }

    '__ci_bb_107 {
        goto '__ci_bb_83
    }

    '__ci_bb_108 {
        (__local_uli__goto_698_15 = strtoul((__local_pp__goto_696_15 as *const c_char), (&raw mut __local_endptr__goto_709_9 as *mut *mut c_char), 10))
        if ((if __local_uli__goto_698_15 > 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_109
        } else {
            goto '__ci_bb_110
        }
    }

    '__ci_bb_109 {
        goto '__ci_bb_83
    }

    '__ci_bb_110 {
        ((unsafe: (__local_field__goto_703_9 as *mut c_uint)[0]) = ((__local_uli__goto_698_15 as c_uint)))
        if ((if (unsafe: *__local_endptr__goto_709_9) == 58: 1 else: 0) != 0) {
            goto '__ci_bb_111
        } else {
            goto '__ci_bb_112
        }
    }

    '__ci_bb_111 {
        (__local_uli__goto_698_15 = strtoul(((__local_endptr__goto_709_9 as *const c_char) + ((1 as isize) as usize)), (&raw mut __local_endptr__goto_709_9 as *mut *mut c_char), 10))
        if ((if __local_uli__goto_698_15 > 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_114
        } else {
            goto '__ci_bb_115
        }
    }

    '__ci_bb_112 {
        ((unsafe: (__local_field__goto_703_9 as *mut c_uint)[1]) = 0)
        goto '__ci_bb_113
    }

    '__ci_bb_113 {
        (__local_pp__goto_696_15 = ((__local_endptr__goto_709_9 as *mut u8)))
        goto '__ci_bb_64
    }

    '__ci_bb_114 {
        goto '__ci_bb_83
    }

    '__ci_bb_115 {
        ((unsafe: (__local_field__goto_703_9 as *mut c_uint)[1]) = ((__local_uli__goto_698_15 as c_uint)))
        goto '__ci_bb_113
    }

    '__ci_bb_116 {
        if ((if not (isdigit((unsafe: *__local_pp__goto_696_15)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_117
        } else {
            goto '__ci_bb_118
        }
    }

    '__ci_bb_117 {
        goto '__ci_bb_83
    }

    '__ci_bb_118 {
        (__local_uli__goto_698_15 = strtoul((__local_pp__goto_696_15 as *const c_char), (&raw mut __local_endptr__goto_709_9 as *mut *mut c_char), 10))
        if ((if __local_uli__goto_698_15 == (((((9223372036854775807 as c_ulong) as c_ulong) *% (2 as c_ulong)) as c_ulong) +% (1 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_119
        } else {
            goto '__ci_bb_120
        }
    }

    '__ci_bb_119 {
        goto '__ci_bb_83
    }

    '__ci_bb_120 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_ulong)) = __local_uli__goto_698_15)
        (__local_pp__goto_696_15 = ((__local_endptr__goto_709_9 as *mut u8)))
        goto '__ci_bb_64
    }

    '__ci_bb_121 {
        if ((if __local_len__goto_707_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_122
        } else {
            goto '__ci_bb_123
        }
    }

    '__ci_bb_122 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = __local_m__goto_704_14.value)
        goto '__ci_bb_64
    }

    '__ci_bb_123 {
        goto '__ci_bb_124
    }

    '__ci_bb_124 {
        if ((if not (isdigit((unsafe: *__local_pp__goto_696_15)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_125
        } else {
            goto '__ci_bb_126
        }
    }

    '__ci_bb_125 {
        goto '__ci_bb_83
    }

    '__ci_bb_126 {
        (__local_uli__goto_698_15 = strtoul((__local_pp__goto_696_15 as *const c_char), (&raw mut __local_endptr__goto_709_9 as *mut *mut c_char), 10))
        if ((if __local_uli__goto_698_15 > 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_128
        }
    }

    '__ci_bb_127 {
        goto '__ci_bb_83
    }

    '__ci_bb_128 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_uint)) = ((__local_uli__goto_698_15 as c_uint)))
        (__local_pp__goto_696_15 = ((__local_endptr__goto_709_9 as *mut u8)))
        goto '__ci_bb_64
    }

    '__ci_bb_129 {
        (__ci_expr_logic_23 = 0)
        if ((if not (isdigit((unsafe: *__local_pp__goto_696_15)) != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_23 = (if (if (unsafe: *__local_pp__goto_696_15) != 45: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_23 != 0) {
            goto '__ci_bb_130
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_130 {
        goto '__ci_bb_83
    }

    '__ci_bb_131 {
        (__local_li__goto_697_6 = strtol((__local_pp__goto_696_15 as *const c_char), (&raw mut __local_endptr__goto_709_9 as *mut *mut c_char), 10))
        if ((if __local_li__goto_697_6 > 2147483647: 1 else: 0) != 0) {
            (__ci_expr_logic_24 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_24 = (if (if __local_li__goto_697_6 < -2147483648: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_24 != 0) {
            goto '__ci_bb_132
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_132 {
        goto '__ci_bb_83
    }

    '__ci_bb_133 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_int)) = ((__local_li__goto_697_6 as c_int)))
        (__local_pp__goto_696_15 = ((__local_endptr__goto_709_9 as *mut u8)))
        goto '__ci_bb_64
    }

    '__ci_bb_134 {
        (__local_i__goto_706_16 = 0)
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        if ((if __local_i__goto_706_16 < (((7 * sizeof[usize]()) as c_ulong) / (sizeof[usize]() as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_136 {
        (__ci_expr_logic_25 = 0)
        if ((if __local_len__goto_707_10 == string_len(newlines[__local_i__goto_706_16]): 1 else: 0) != 0) {
            (__ci_expr_logic_25 = (if (if strncmpic(__local_pp__goto_696_15, (newlines[__local_i__goto_706_16] as *const u8), __local_len__goto_707_10) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_25 != 0) {
            goto '__ci_bb_139
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_137 {
        (__local_i__goto_706_16 = __local_i__goto_706_16 + 1)
        goto '__ci_bb_135
    }

    '__ci_bb_138 {
        if ((if __local_i__goto_706_16 >= (((7 * sizeof[usize]()) as c_ulong) / (sizeof[usize]() as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_142
        }
    }

    '__ci_bb_139 {
        goto '__ci_bb_138
    }

    '__ci_bb_140 {
        goto '__ci_bb_137
    }

    '__ci_bb_141 {
        goto '__ci_bb_83
    }

    '__ci_bb_142 {
        if ((if __local_i__goto_706_16 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_143
        } else {
            goto '__ci_bb_144
        }
    }

    '__ci_bb_143 {
        pcre2_set_newline_8(__local_field__goto_703_9, 2)
        if ((if __param_ctx == CTX_PAT: 1 else: 0) != 0) {
            (__ci_expr_logic_26 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_26 = (if (if __param_ctx == CTX_DEFPAT: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_26 != 0) {
            goto '__ci_bb_146
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_144 {
        pcre2_set_newline_8(__local_field__goto_703_9, __local_i__goto_706_16)
        if ((if __param_ctx == CTX_PAT: 1 else: 0) != 0) {
            (__ci_expr_logic_27 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_27 = (if (if __param_ctx == CTX_DEFPAT: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_27 != 0) {
            goto '__ci_bb_149
        } else {
            goto '__ci_bb_150
        }
    }

    '__ci_bb_145 {
        (__local_pp__goto_696_15 = __local_ep__goto_696_10)
        goto '__ci_bb_64
    }

    '__ci_bb_146 {
        ((unsafe: *__param_pctl).control2 = __param_pctl.control2 & (~1073741824))
        goto '__ci_bb_148
    }

    '__ci_bb_147 {
        ((unsafe: *__param_dctl).control2 = __param_dctl.control2 & (~1073741824))
        goto '__ci_bb_148
    }

    '__ci_bb_148 {
        goto '__ci_bb_145
    }

    '__ci_bb_149 {
        ((unsafe: *__param_pctl).control2 = __param_pctl.control2 | 1073741824)
        goto '__ci_bb_151
    }

    '__ci_bb_150 {
        ((unsafe: *__param_dctl).control2 = __param_dctl.control2 | 1073741824)
        goto '__ci_bb_151
    }

    '__ci_bb_151 {
        goto '__ci_bb_145
    }

    '__ci_bb_152 {
        if (isdigit((unsafe: *__local_pp__goto_696_15)) != 0) {
            (__ci_expr_logic_28 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_28 = (if (if (unsafe: *__local_pp__goto_696_15) == 45: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_28 != 0) {
            goto '__ci_bb_153
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_153 {
        (__local_ct__goto_982_11 = 10 - 1)
        (__local_li__goto_697_6 = strtol((__local_pp__goto_696_15 as *const c_char), (&raw mut __local_endptr__goto_709_9 as *mut *mut c_char), 10))
        if ((if __local_li__goto_697_6 > 2147483647: 1 else: 0) != 0) {
            (__ci_expr_logic_29 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_29 = (if (if __local_li__goto_697_6 < -2147483648: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_29 != 0) {
            goto '__ci_bb_156
        } else {
            goto '__ci_bb_157
        }
    }

    '__ci_bb_154 {
        (__local_nn__goto_1007_13 = ((__local_field__goto_703_9 as *mut c_char)))
        if ((if __local_len__goto_707_10 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_167
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_155 {
        goto '__ci_bb_64
    }

    '__ci_bb_156 {
        goto '__ci_bb_83
    }

    '__ci_bb_157 {
        (__local_value__goto_983_15 = ((__local_li__goto_697_6 as c_int)))
        (__local_field__goto_703_9 = (((((__local_field__goto_703_9 as *mut c_char) - (__local_m__goto_704_14.offset as usize)) + (__local_m__goto_704_14.value as usize)) as *mut c_void)))
        if ((if __local_value__goto_983_15 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_158
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_158 {
        goto '__ci_bb_160
    }

    '__ci_bb_159 {
        ((unsafe: *(__local_field__goto_703_9 as *mut c_int)) = __local_value__goto_983_15)
        if ((if __local_ct__goto_982_11 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_165
        } else {
            goto '__ci_bb_166
        }
    }

    '__ci_bb_160 {
        (__ci_expr_logic_31 = 0)
        if ((if (unsafe: *(__local_field__goto_703_9 as *mut c_int)) >= 0: 1 else: 0) != 0) {
            var __ci_expr_old_30: c_int = __local_ct__goto_982_11

            (__local_ct__goto_982_11 = __local_ct__goto_982_11 - 1)

            (__ci_expr_logic_31 = (if (if __ci_expr_old_30 > 0: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_31 != 0) {
            goto '__ci_bb_161
        } else {
            goto '__ci_bb_162
        }
    }

    '__ci_bb_161 {
        (__local_field__goto_703_9 = ((((__local_field__goto_703_9 as *mut c_char) + (sizeof[i32]() as usize)) as *mut c_void)))
        goto '__ci_bb_160
    }

    '__ci_bb_162 {
        if ((if __local_ct__goto_982_11 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_163
        } else {
            goto '__ci_bb_164
        }
    }

    '__ci_bb_163 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Too many numeric \"%s\" modifiers\n", __local_m__goto_704_14.name)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_164 {
        goto '__ci_bb_159
    }

    '__ci_bb_165 {
        ((unsafe: (__local_field__goto_703_9 as *mut c_int)[1]) = -1)
        goto '__ci_bb_166
    }

    '__ci_bb_166 {
        (__local_pp__goto_696_15 = ((__local_endptr__goto_709_9 as *mut u8)))
        goto '__ci_bb_155
    }

    '__ci_bb_167 {
        if ((if __local_len__goto_707_10 > 128: 1 else: 0) != 0) {
            goto '__ci_bb_169
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_168 {
        ((unsafe: __local_nn__goto_1007_13[__local_len__goto_707_10]) = 0)
        ((unsafe: __local_nn__goto_1007_13[((__local_len__goto_707_10 as c_ulong) +% (1 as c_ulong))]) = 0)
        (__local_pp__goto_696_15 = __local_ep__goto_696_10)
        goto '__ci_bb_155
    }

    '__ci_bb_169 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Group name in \"%s\" is too long\n", __local_m__goto_704_14.name)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_170 {
        goto '__ci_bb_171
    }

    '__ci_bb_171 {
        if ((if (unsafe: *__local_nn__goto_1007_13) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_172
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_172 {
        (__local_nn__goto_1007_13 = __local_nn__goto_1007_13 + (((string_len(__local_nn__goto_1007_13) as c_ulong) +% (1 as c_ulong)) as usize))
        goto '__ci_bb_171
    }

    '__ci_bb_173 {
        if ((if (((((__local_nn__goto_1007_13 + (__local_len__goto_707_10 as usize)) + ((2 as isize) as usize)) as usize) -% ((__local_field__goto_703_9 as *mut c_char) as usize)) / sizeof[c_char]()) > 64: 1 else: 0) != 0) {
            goto '__ci_bb_174
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_174 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Too many characters in named \"%s\" modifiers\n", __local_m__goto_704_14.name)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_175 {
        with_memcpy((__local_nn__goto_1007_13 as *i8), (__local_pp__goto_696_15 as *i8), (__local_len__goto_707_10 as i64))
        goto '__ci_bb_168
    }

    '__ci_bb_176 {
        if ((if ((__local_len__goto_707_10 as c_ulong) +% (1 as c_ulong)) > __local_m__goto_704_14.value: 1 else: 0) != 0) {
            goto '__ci_bb_177
        } else {
            goto '__ci_bb_178
        }
    }

    '__ci_bb_177 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Overlong value for \"%s\" (max %d code units)\n", __local_m__goto_704_14.name, ((__local_m__goto_704_14.value as c_uint) -% (1 as c_uint)))
        colour_end(outfile)
        return 0
    }

    '__ci_bb_178 {
        ((unsafe: (__local_field__goto_703_9 as *mut u8)[0]) = __local_len__goto_707_10)
        with_memcpy((((__local_field__goto_703_9 as *mut u8) + ((1 as isize) as usize)) as *i8), (__local_pp__goto_696_15 as *i8), (__local_len__goto_707_10 as i64))
        ((unsafe: (__local_field__goto_703_9 as *mut u8)[((__local_len__goto_707_10 as c_ulong) +% (1 as c_ulong))]) = 0)
        (__local_pp__goto_696_15 = __local_ep__goto_696_10)
        goto '__ci_bb_64
    }

    '__ci_bb_179 {
        if (__local_m__goto_704_14.type_ == 20) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_180
        }
    }

    '__ci_bb_180 {
        if (__local_m__goto_704_14.type_ == 21) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_181 {
        if (__local_m__goto_704_14.type_ == 13) {
            goto '__ci_bb_70
        } else {
            goto '__ci_bb_182
        }
    }

    '__ci_bb_182 {
        if (__local_m__goto_704_14.type_ == 10) {
            goto '__ci_bb_87
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_183 {
        if (__local_m__goto_704_14.type_ == 11) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_184 {
        if (__local_m__goto_704_14.type_ == 14) {
            goto '__ci_bb_106
        } else {
            goto '__ci_bb_185
        }
    }

    '__ci_bb_185 {
        if (__local_m__goto_704_14.type_ == 22) {
            goto '__ci_bb_116
        } else {
            goto '__ci_bb_186
        }
    }

    '__ci_bb_186 {
        if (__local_m__goto_704_14.type_ == 17) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_187
        }
    }

    '__ci_bb_187 {
        if (__local_m__goto_704_14.type_ == 16) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_188 {
        if (__local_m__goto_704_14.type_ == 15) {
            goto '__ci_bb_129
        } else {
            goto '__ci_bb_189
        }
    }

    '__ci_bb_189 {
        if (__local_m__goto_704_14.type_ == 18) {
            goto '__ci_bb_134
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_190 {
        if (__local_m__goto_704_14.type_ == 19) {
            goto '__ci_bb_152
        } else {
            goto '__ci_bb_191
        }
    }

    '__ci_bb_191 {
        if (__local_m__goto_704_14.type_ == 23) {
            goto '__ci_bb_176
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_192 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Comma expected after modifier item \"%s\"\n", __local_m__goto_704_14.name)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_193 {
        (__local_p = __local_pp__goto_696_15)
        (__ci_expr_logic_38 = 0)
        if ((if __param_ctx == CTX_POPPAT: 1 else: 0) != 0) {
            var __ci_expr_logic_37: c_int

            var __ci_expr_logic_36: c_int

            var __ci_expr_logic_35: c_int

            if ((if __param_pctl.options != 0: 1 else: 0) != 0) {
                (__ci_expr_logic_35 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_35 = (if (if __param_pctl.tables_id != 0: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_35 != 0) {
                (__ci_expr_logic_36 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_36 = (if (if __param_pctl.locale[0] != 255: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_36 != 0) {
                (__ci_expr_logic_37 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_37 = (if (if ((__param_pctl.control as c_uint) & (((((((((((((65536 as c_uint) | (8388608 as c_uint)) as c_uint) | (16777216 as c_uint)) as c_uint) | (33554432 as c_uint)) as c_uint) | (67108864 as c_uint)) as c_uint) | (134217728 as c_uint)) as c_uint) | (536870912 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_38 = (if __ci_expr_logic_37 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_38 != 0) {
            goto '__ci_bb_194
        } else {
            goto '__ci_bb_195
        }
    }

    '__ci_bb_194 {
        colour_begin(31, outfile)
        fprintf(outfile, "** \"%s\" is not valid here\n", __local_m__goto_704_14.name)
        colour_end(outfile)
        return 0
    }

    '__ci_bb_195 {
        goto '__ci_bb_3
    }

}

fn pattern_info_8(__param_what: c_int, __param_where_: *mut c_void, __param_unsetok: c_int) -> c_int {
    var __local_rc: c_int

    pcre2_pattern_info_8(compiled_code_8, __param_what, null)

    (__local_rc = pcre2_pattern_info_8(compiled_code_8, __param_what, __param_where_))

    if ((if __local_rc >= 0: 1 else: 0) != 0) {
        return 0
    }

    var __ci_expr_logic_0: c_int

    if ((if __local_rc != -55: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if not (__param_unsetok != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        colour_begin(35, outfile)

        fprintf(outfile, "Error %d from pcre2_pattern_info_(%d)\n", __local_rc, __param_what)

        colour_end(outfile)


    }


    return __local_rc

}

fn show_memory_info_8() {
    var __local_name_count: c_uint

    var __local_name_entry_size: c_uint


    var __local_size: c_ulong

    var __local_cblock_size: c_ulong

    var __local_data_size: c_ulong


    (__local_cblock_size = sizeof[pcre2_real_code_8]())

    pattern_info_8(22, (&raw mut __local_size as *mut c_ulong), 0)

    pattern_info_8(17, (&raw mut __local_name_count as *mut c_uint), 0)

    pattern_info_8(18, (&raw mut __local_name_entry_size as *mut c_uint), 0)

    (__local_data_size = (((((__local_name_count as c_ulong) as c_ulong) *% ((__local_name_entry_size as c_ulong) as c_ulong)) as c_ulong) *% (1 as c_ulong)))

    colour_begin(36, outfile)

    fprintf(outfile, "Memory allocation - code size : %zu\n", ((((__local_size as c_ulong) -% (__local_cblock_size as c_ulong)) as c_ulong) -% (__local_data_size as c_ulong)))

    colour_end(outfile)


    if ((if __local_data_size != 0: 1 else: 0) != 0) {
        colour_begin(36, outfile)

        fprintf(outfile, "Memory allocation - data size : %zu\n", __local_data_size)

        colour_end(outfile)

    }

    if ((if (&raw const pat_patctl as *const patctl).jit != 0: 1 else: 0) != 0) {
        pattern_info_8(10, (&raw mut __local_size as *mut c_ulong), 0)

        colour_begin(36, outfile)

        fprintf(outfile, "Memory allocation - JIT code  : %zu\n", __local_size)

        colour_end(outfile)


    }

}

fn show_framesize_8() {
    var __local_frame_size: c_ulong

    pattern_info_8(24, (&raw mut __local_frame_size as *mut c_ulong), 0)

    colour_begin(36, outfile)

    fprintf(outfile, "Frame size for pcre2_match(): %zu\n", __local_frame_size)

    colour_end(outfile)


}

fn show_heapframes_size_8() {
    var __local_heapframes_size: c_ulong

    (__local_heapframes_size = pcre2_get_match_data_heapframes_size_8(match_data_8))

    colour_begin(36, outfile)

    fprintf(outfile, "Heapframes size in match_data: %zu\n", __local_heapframes_size)

    colour_end(outfile)


}

fn print_error_message_file_8(__param_file: *mut c_void, __param_errorcode: c_int, __param_before: *const i8, __param_after: *const i8, __param_badcode_ok: c_int) -> c_int {
    var __local_len: c_int

    var __local_buf: [128]u8

    (__local_len = pcre2_get_error_message_8(__param_errorcode, (&(unsafe: __local_buf[0]) as *mut u8), (((128 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong))))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_len == -29: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if __param_badcode_ok != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        colour_begin(35, __param_file)

        fprintf(__param_file, "%sPCRE2_ERROR_BADDATA (unknown error number)%s", __param_before, __param_after)

        colour_end(__param_file)


    } else {
        if ((if __local_len < 0: 1 else: 0) != 0) {
            colour_begin(31, __param_file)

            fprintf(__param_file, "\n** pcre2test internal error: cannot interpret error number\n** Unexpected return (%d) from pcre2_get_error_message()\n", __local_len)

            colour_end(__param_file)


        } else {
            if ((if ((__local_len as c_uint)) != pcre2_strlen_8((&(unsafe: __local_buf[0]) as *mut u8)): 1 else: 0) != 0) {
                colour_begin(31, __param_file)

                fprintf(__param_file, "\n** pcre2test: unexpected length %d from pcre2_get_error_message()\n", __local_len)

                colour_end(__param_file)


                return 0

            } else {
                colour_begin(35, __param_file)

                fprintf(__param_file, "%s", __param_before)

                colour_end(__param_file)


                pchars_8(35, (&(unsafe: __local_buf[0]) as *mut u8), __local_len, 0, __param_file)

                colour_begin(35, __param_file)

                fprintf(__param_file, "%s", __param_after)

                colour_end(__param_file)


            }
        }
    }


    return (if __local_len >= 0: 1 else: 0)

}

fn print_error_message_8(__param_errorcode: c_int, __param_before: *const i8, __param_after: *const i8) -> c_int {
    return print_error_message_file_8(outfile, __param_errorcode, __param_before, __param_after, 0)

}

fn callout_enumerate_function_8(__param_cb: *mut pcre2_callout_enumerate_block_8, __param_callout_data: *mut c_void) -> c_int {
    var __local_i: c_uint

    var __local_pattern_string: *const u8 = pbuffer8

    var __local_utf: c_int = (if ((compiled_code_8.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0)

    var __local_next_item_length: c_ulong = __param_cb.next_item_length

    __param_callout_data

    fprintf(outfile, "Callout ")

    if ((if __param_cb.callout_string != null: 1 else: 0) != 0) {
        var __local_delimiter: c_uint = (unsafe: __param_cb.callout_string[-1])

        fprintf(outfile, "%c", __local_delimiter)

        pchars_8(-1, __param_cb.callout_string, __param_cb.callout_string_length, __local_utf, outfile)

        (__local_i = 0)

        while ((if callout_start_delims[__local_i] != 0: 1 else: 0) != 0) {
            if ((if __local_delimiter == callout_start_delims[__local_i]: 1 else: 0) != 0) {
                (__local_delimiter = callout_end_delims[__local_i])

                break

            }

            (__local_i = __local_i + 1)

        }


        fprintf(outfile, "%c  ", __local_delimiter)

    } else {
        fprintf(outfile, "%d  ", __param_cb.callout_number)
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_next_item_length == 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe: __local_pattern_string[__param_cb.pattern_position]) != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_next_item_length = 1)
    }


    pchars_8(-1, (__local_pattern_string + (__param_cb.pattern_position as usize)), __local_next_item_length, __local_utf, outfile)

    fprintf(outfile, "\n")

    return 0

}

fn callout_enumerate_function_void_8(__param_cb: *mut pcre2_callout_enumerate_block_8, __param_callout_data: *mut c_void) -> c_int {
    __param_cb

    __param_callout_data

    return 0

}

fn callout_enumerate_function_fail_8(__param_cb: *mut pcre2_callout_enumerate_block_8, __param_callout_data: *mut c_void) -> c_int {
    __param_cb

    return (unsafe: *(__param_callout_data as *mut c_int))

}

fn show_pattern_info_8() -> c_int {
    var __local_rc: c_int

    var __local_compile_options: c_uint

    var __local_overall_options: c_uint

    var __local_extra_options: c_uint


    var __local_utf: c_int = (if ((compiled_code_8.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0)

    if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (2097152 as c_uint)) != 0: 1 else: 0) != 0) {
        show_memory_info_8()
    }

    if ((if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (32768 as c_uint)) != 0: 1 else: 0) != 0) {
        show_framesize_8()
    }

    if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (((32 as c_uint) | (8192 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
        fprintf(outfile, "------------------------------------------------------------------\n")

        pcre2_printint_8(compiled_code_8, outfile, (if (((&raw const pat_patctl as *const patctl).control as c_uint) & (8192 as c_uint)) != 0: 1 else: 0))

    }

    if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0) {
        var __local_nametable: *const u8

        var __local_start_bits: *mut u8

        var __local_heap_limit_set: c_int

        var __local_match_limit_set: c_int

        var __local_depth_limit_set: c_int


        var __local_backrefmax: c_uint

        var __local_bsr_convention: c_uint

        var __local_capture_count: c_uint

        var __local_first_ctype: c_uint

        var __local_first_cunit: c_uint

        var __local_hasbackslashc: c_uint

        var __local_hascrorlf: c_uint

        var __local_jchanged: c_uint

        var __local_last_ctype: c_uint

        var __local_last_cunit: c_uint

        var __local_match_empty: c_uint

        var __local_depth_limit: c_uint

        var __local_heap_limit: c_uint

        var __local_match_limit: c_uint

        var __local_minlength: c_uint

        var __local_nameentrysize: c_uint

        var __local_namecount: c_uint

        var __local_newline_convention: c_uint


        while true {
            match pattern_info_8(25, (&raw mut __local_heap_limit as *mut c_uint), 1) {
                0 => {
                    (__local_heap_limit_set = 1)
                },
                -55 => {
                    (__local_heap_limit_set = 0)
                },
                _ => {
                    return PR_ABEND
                },
            }

            break

        }

        while true {
            match pattern_info_8(14, (&raw mut __local_match_limit as *mut c_uint), 1) {
                0 => {
                    (__local_match_limit_set = 1)
                },
                -55 => {
                    (__local_match_limit_set = 0)
                },
                _ => {
                    return PR_ABEND
                },
            }

            break

        }

        while true {
            match pattern_info_8(21, (&raw mut __local_depth_limit as *mut c_uint), 1) {
                0 => {
                    (__local_depth_limit_set = 1)
                },
                -55 => {
                    (__local_depth_limit_set = 0)
                },
                _ => {
                    return PR_ABEND
                },
            }

            break

        }

        if ((if ((((((((((((((((pattern_info_8(2, (&raw mut __local_backrefmax as *mut c_uint), 0) + pattern_info_8(3, (&raw mut __local_bsr_convention as *mut c_uint), 0)) + pattern_info_8(4, (&raw mut __local_capture_count as *mut c_uint), 0)) + pattern_info_8(7, (&raw mut __local_start_bits as *mut *mut u8), 0)) + pattern_info_8(5, (&raw mut __local_first_cunit as *mut c_uint), 0)) + pattern_info_8(6, (&raw mut __local_first_ctype as *mut c_uint), 0)) + pattern_info_8(23, (&raw mut __local_hasbackslashc as *mut c_uint), 0)) + pattern_info_8(8, (&raw mut __local_hascrorlf as *mut c_uint), 0)) + pattern_info_8(9, (&raw mut __local_jchanged as *mut c_uint), 0)) + pattern_info_8(11, (&raw mut __local_last_cunit as *mut c_uint), 0)) + pattern_info_8(12, (&raw mut __local_last_ctype as *mut c_uint), 0)) + pattern_info_8(13, (&raw mut __local_match_empty as *mut c_uint), 0)) + pattern_info_8(16, (&raw mut __local_minlength as *mut c_uint), 0)) + pattern_info_8(17, (&raw mut __local_namecount as *mut c_uint), 0)) + pattern_info_8(18, (&raw mut __local_nameentrysize as *mut c_uint), 0)) + pattern_info_8(19, (&raw mut __local_nametable as *mut *const u8), 0)) + pattern_info_8(20, (&raw mut __local_newline_convention as *mut c_uint), 0)) != 0: 1 else: 0) != 0) {
            return PR_ABEND
        }

        fprintf(outfile, "Capture group count = %d\n", __local_capture_count)

        if ((if __local_backrefmax > 0: 1 else: 0) != 0) {
            fprintf(outfile, "Max back reference = %d\n", __local_backrefmax)
        }

        if ((if maxlookbehind > 0: 1 else: 0) != 0) {
            fprintf(outfile, "Max lookbehind = %d\n", maxlookbehind)
        }

        if (__local_heap_limit_set != 0) {
            fprintf(outfile, "Heap limit = %u\n", __local_heap_limit)
        }

        if (__local_match_limit_set != 0) {
            fprintf(outfile, "Match limit = %u\n", __local_match_limit)
        }

        if (__local_depth_limit_set != 0) {
            fprintf(outfile, "Depth limit = %u\n", __local_depth_limit)
        }

        if ((if __local_namecount > 0: 1 else: 0) != 0) {
            fprintf(outfile, "Named capture groups:\n")

            while ((if __local_namecount > 0: 1 else: 0) != 0) {
                var __local_length: c_ulong = pcre2_strlen_8((__local_nametable + ((2 as isize) as usize)))

                fprintf(outfile, "  ")

                if (__local_utf != 0) {
                    fprintf(outfile, "%s", (__local_nametable + ((2 as isize) as usize)))

                } else {
                    pchars_8(-1, (__local_nametable + ((2 as isize) as usize)), __local_length, 0, outfile)

                }

                while true {
                    var __ci_expr_old_3: c_ulong = __local_length

                    (__local_length = __local_length + 1)

                    if (not ((if __ci_expr_old_3 < ((__local_nameentrysize as c_uint) -% (2 as c_uint)): 1 else: 0) != 0)) {
                        break
                    }

                    putc(32, outfile)

                }

                fprintf(outfile, "%3d\n", (((((unsafe: __local_nametable[0]) as c_int) << (8 as c_uint)) | ((unsafe: __local_nametable[(0 + 1)]) as c_int)) as c_uint))

                (__local_nametable = __local_nametable + (__local_nameentrysize as usize))


                (__local_namecount = __local_namecount - 1)

            }

        }

        if (__local_hascrorlf != 0) {
            fprintf(outfile, "Contains explicit CR or LF match\n")
        }

        if (__local_hasbackslashc != 0) {
            fprintf(outfile, "Contains \\C\n")
        }

        if (__local_match_empty != 0) {
            fprintf(outfile, "May match empty string\n")
        }

        pattern_info_8(1, (&raw mut __local_compile_options as *mut c_uint), 0)

        pattern_info_8(0, (&raw mut __local_overall_options as *mut c_uint), 0)

        pattern_info_8(26, (&raw mut __local_extra_options as *mut c_uint), 0)

        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            (__local_compile_options = __local_compile_options & (~4096))

            (__local_overall_options = __local_overall_options & (~4096))

        }

        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (2048 as c_uint)) == 0: 1 else: 0) != 0) {
            (__local_compile_options = __local_compile_options & (~2048))

            (__local_overall_options = __local_overall_options & (~2048))

        }

        if ((if ((__local_compile_options as c_uint) | (__local_overall_options as c_uint)) != 0: 1 else: 0) != 0) {
            if ((if __local_compile_options == __local_overall_options: 1 else: 0) != 0) {
                show_compile_options(-1, __local_compile_options, "Options:", "\n")
            } else {
                show_compile_options(-1, __local_compile_options, "Compile options:", "\n")

                show_compile_options(-1, __local_overall_options, "Overall options:", "\n")

            }

        }

        if ((if __local_extra_options != 0: 1 else: 0) != 0) {
            show_compile_extra_options(-1, __local_extra_options, "Extra options:", "\n")
        }

        if ((if compiled_code_8.optimization_flags != 7: 1 else: 0) != 0) {
            show_optimize_flags(-1, compiled_code_8.optimization_flags, "Optimizations: ", "\n")
        }

        if (__local_jchanged != 0) {
            fprintf(outfile, "Duplicate name status changes\n")
        }

        var __ci_expr_logic_4: c_int

        if ((if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_4 = (if (if ((compiled_code_8.flags as c_uint) & (16384 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            var __ci_expr_ternary_5: *mut c_char = null

            if ((if __local_bsr_convention == 1: 1 else: 0) != 0) {
                (__ci_expr_ternary_5 = (("any Unicode newline" as *mut c_char)))
            } else {
                (__ci_expr_ternary_5 = (("CR, LF, or CRLF" as *mut c_char)))
            }

            fprintf(outfile, "\\R matches %s\n", __ci_expr_ternary_5)

        }


        if ((if ((compiled_code_8.flags as c_uint) & (32768 as c_uint)) != 0: 1 else: 0) != 0) {
            while true {
                match __local_newline_convention {
                    1 => {
                        fprintf(outfile, "Forced newline is CR\n")
                    },
                    2 => {
                        fprintf(outfile, "Forced newline is LF\n")
                    },
                    3 => {
                        fprintf(outfile, "Forced newline is CRLF\n")
                    },
                    5 => {
                        fprintf(outfile, "Forced newline is CR, LF, or CRLF\n")
                    },
                    4 => {
                        fprintf(outfile, "Forced newline is any Unicode newline\n")
                    },
                    6 => {
                        fprintf(outfile, "Forced newline is NUL\n")
                    },
                    _ => {
                        0
                    },
                }

                break

            }

        }

        if ((if __local_first_ctype == 2: 1 else: 0) != 0) {
            fprintf(outfile, "First code unit at start or follows newline\n")

        } else {
            if ((if __local_first_ctype == 1: 1 else: 0) != 0) {
                var __local_caseless: *const c_char = with 0 as __ci_expr_seq_173 {
                    var __ci_expr_ternary_7: *mut c_char = null
                    if ((if ((compiled_code_8.flags as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__ci_expr_ternary_7 = (("" as *mut c_char)))
                    } else {
                        (__ci_expr_ternary_7 = ((" (caseless)" as *mut c_char)))
                    }
                    (__ci_expr_ternary_7 as *const c_char)
                }

                var __ci_expr_logic_9: c_int = 0

                if ((if __local_first_cunit != 255: 1 else: 0) != 0) {
                    var __ci_expr_logic_8: c_int = 0

                    if ((if __local_first_cunit >= 32: 1 else: 0) != 0) {
                        (__ci_expr_logic_8 = (if (if __local_first_cunit < 127: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_9 = (if __ci_expr_logic_8 != 0: 1 else: 0))

                }

                if (__ci_expr_logic_9 != 0) {
                    fprintf(outfile, "First code unit = \'%c\'%s\n", __local_first_cunit, __local_caseless)
                } else {
                    fprintf(outfile, "First code unit = ")

                    if ((if __local_first_cunit == 255: 1 else: 0) != 0) {
                        fprintf(outfile, "\\xff")
                    } else {
                        pchar(__local_first_cunit, 0, outfile)
                    }

                    fprintf(outfile, "%s\n", __local_caseless)

                }


            } else {
                if ((if __local_start_bits != null: 1 else: 0) != 0) {
                    var __local_input: c_int

                    var __local_c: c_int = 24

                    fprintf(outfile, "Starting code units:")

                    (__local_input = 0)

                    while ((if __local_input < 256: 1 else: 0) != 0) {
                        var __local_i: c_int = __local_input

                        if ((if ((((unsafe: __local_start_bits[(__local_i / 8)]) as c_int) as c_uint) & (((1 as c_uint) << ((__local_i & 7) as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
                            if ((if __local_c > 75: 1 else: 0) != 0) {
                                fprintf(outfile, "\n ")

                                (__local_c = 2)

                            }

                            var __ci_expr_logic_11: c_int = 0

                            var __ci_expr_logic_10: c_int = 0

                            if ((if __local_i >= 32: 1 else: 0) != 0) {
                                (__ci_expr_logic_10 = (if (if __local_i < 127: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_10 != 0) {
                                (__ci_expr_logic_11 = (if (if __local_i != 32: 1 else: 0) != 0: 1 else: 0))
                            }

                            if (__ci_expr_logic_11 != 0) {
                                fprintf(outfile, " %c", __local_i)

                                (__local_c = __local_c + 2)

                            } else {
                                fprintf(outfile, " \\x%02x", __local_i)

                                (__local_c = __local_c + 5)

                            }


                        }


                        (__local_input = __local_input + 1)

                    }


                    fprintf(outfile, "\n")

                }
            }
        }

        if ((if __local_last_ctype != 0: 1 else: 0) != 0) {
            var __local_caseless_1: *const c_char = with 0 as __ci_expr_seq_250 {
                var __ci_expr_ternary_12: *mut c_char = null
                if ((if ((compiled_code_8.flags as c_uint) & (256 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_12 = (("" as *mut c_char)))
                } else {
                    (__ci_expr_ternary_12 = ((" (caseless)" as *mut c_char)))
                }
                (__ci_expr_ternary_12 as *const c_char)
            }

            var __ci_expr_logic_13: c_int = 0

            if ((if __local_last_cunit >= 32: 1 else: 0) != 0) {
                (__ci_expr_logic_13 = (if (if __local_last_cunit < 127: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_13 != 0) {
                fprintf(outfile, "Last code unit = \'%c\'%s\n", __local_last_cunit, __local_caseless_1)
            } else {
                fprintf(outfile, "Last code unit = ")

                pchar(__local_last_cunit, 0, outfile)

                fprintf(outfile, "%s\n", __local_caseless_1)

            }


        }

        if ((if ((compiled_code_8.optimization_flags as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
            fprintf(outfile, "Subject length lower bound = %d\n", __local_minlength)
        }

        var __ci_expr_logic_14: c_int = 0

        if ((if (&raw const pat_patctl as *const patctl).jit != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if (if (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_14 != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "JIT support is not available in this version of PCRE2\n")

            colour_end(outfile)


        }


    }

    var __ci_expr_ternary_15: *mut fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int = null

    if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (128 as c_uint)) != 0: 1 else: 0) != 0) {
        (__ci_expr_ternary_15 = ((callout_enumerate_function_8 as *mut fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int)))
    } else {
        (__ci_expr_ternary_15 = ((callout_enumerate_function_void_8 as *mut fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int)))
    }

    (__local_rc = pcre2_callout_enumerate_8(compiled_code_8, __ci_expr_ternary_15, null))


    if ((if __local_rc != 0: 1 else: 0) != 0) {
        colour_begin(35, outfile)

        fprintf(outfile, "Callout enumerate failed: error %d: ", __local_rc)

        colour_end(outfile)


        var __ci_expr_logic_16: c_int = 0

        if ((if __local_rc < 0: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if (if not (print_error_message_8(__local_rc, "", "\n") != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_16 != 0) {
            return PR_ABEND
        }


        return PR_SKIP

    }

    return PR_OK

}

fn serial_error_8(__param_rc: c_int, __param_msg: *const i8) -> c_int {
    colour_begin(35, outfile)

    fprintf(outfile, "%s failed: error %d: ", __param_msg, __param_rc)

    colour_end(outfile)


    return print_error_message_8(__param_rc, "", "\n")

}

fn process_command_8() -> c_int {
    var __local_f: *mut c_void

    var __local_serial_size: c_ulong

    var __local_i: c_ulong

    var __local_rc: c_int

    var __local_cmd: c_int

    var __local_yield_: c_int


    var __local_first_listed_newline: c_ushort

    var __local_cmdname: *const c_char

    var __local_cmdlen: c_ulong

    var __local_argptr: *mut u8

    var __local_serial: *mut u8


    var __local_if_inverted: c_int

    (__local_yield_ = PR_OK)

    (__local_cmd = CMD_UNKNOWN)

    (__local_cmdlen = 0)

    (__local_i = 0)

    while ((if __local_i < 12: 1 else: 0) != 0) {
        (__local_cmdname = ((cmdlist[__local_i].name as *const c_char)))

        (__local_cmdlen = string_len(__local_cmdname))

        var __ci_expr_logic_1: c_int = 0

        if ((if strncmp(((buffer + ((1 as isize) as usize)) as *mut c_char), __local_cmdname, __local_cmdlen) == 0: 1 else: 0) != 0) {
            var __ci_expr_logic_0: c_int

            if ((if (unsafe: buffer[((__local_cmdlen as c_ulong) +% (1 as c_ulong))]) == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if isspace((unsafe: buffer[((__local_cmdlen as c_ulong) +% (1 as c_ulong))])) != 0: 1 else: 0))
            }

            (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_1 != 0) {
            (__local_cmd = cmdlist[__local_i].value)

            break

        }



        (__local_i = __local_i + 1)

    }


    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    if (preprocess_only != 0) {
        (__ci_expr_logic_2 = (if (if __local_cmd != CMD_IF: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        (__ci_expr_logic_3 = (if (if __local_cmd != CMD_ENDIF: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_3 != 0) {
        return PR_OK
    }


    (__local_argptr = (buffer + (__local_cmdlen as usize)) + ((1 as isize) as usize))

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    if (restrict_for_perl_test != 0) {
        (__ci_expr_logic_4 = (if (if __local_cmd != CMD_PATTERN: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_4 != 0) {
        (__ci_expr_logic_5 = (if (if __local_cmd != CMD_SUBJECT: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_5 != 0) {
        (__ci_expr_logic_6 = (if (if __local_cmd != CMD_IF: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_6 != 0) {
        (__ci_expr_logic_7 = (if (if __local_cmd != CMD_ENDIF: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_7 != 0) {
        colour_begin(31, outfile)

        fprintf(outfile, "** #%s is not allowed after #perltest\n", __local_cmdname)

        colour_end(outfile)


        return PR_ABEND

    }


    while true {
        match __local_cmd {
            12 => {
                colour_begin(31, outfile)

                fprintf(outfile, "** Unknown command: %s", buffer)

                colour_end(outfile)

            },
            1 => {
                (forbid_utf = (4096 as c_uint) | (2048 as c_uint))
            },
            7 => {
                (restrict_for_perl_test = 1)
            },
            6 => {
                decode_modifiers_8(__local_argptr, CTX_DEFPAT, (&raw mut def_patctl as *mut patctl), null)

                var __ci_expr_logic_8: c_int = 0

                if ((if (&raw const def_patctl as *const patctl).jit == 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_8 = (if (if (((&raw const def_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_8 != 0) {
                    (def_patctl.jit = (((1 as c_uint) | (2 as c_uint)) as c_uint) | (4 as c_uint))
                }


            },
            11 => {
                decode_modifiers_8(__local_argptr, CTX_DEFDAT, null, (&raw mut def_datctl as *mut datctl))
            },
            5 => {
                (local_newline_default = 0)

                (__local_first_listed_newline = 0)

                while true {
                    while (isspace((unsafe: *__local_argptr)) != 0) {
                        (__local_argptr = __local_argptr + 1)
                    }

                    if ((if (unsafe: *__local_argptr) == 0: 1 else: 0) != 0) {
                        break
                    }

                    var __local_j: c_ushort = 1

                    while ((if __local_j < (((7 * sizeof[usize]()) as c_ulong) / (sizeof[usize]() as c_ulong)): 1 else: 0) != 0) {
                        var __local_nlen: c_ulong = string_len(newlines[__local_j])

                        var __ci_expr_logic_9: c_int = 0

                        if ((if strncmpic(__local_argptr, (newlines[__local_j] as *const u8), __local_nlen) == 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_9 = (if isspace((unsafe: __local_argptr[__local_nlen])) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_9 != 0) {
                            if ((if __local_j == 2: 1 else: 0) != 0) {
                                return PR_OK
                            }

                            if ((if __local_first_listed_newline == 0: 1 else: 0) != 0) {
                                (__local_first_listed_newline = __local_j)
                            }

                        }



                        (__local_j = __local_j + 1)

                    }


                    while true {
                        var __ci_expr_logic_10: c_int = 0

                        if ((if (unsafe: *__local_argptr) != 0: 1 else: 0) != 0) {
                            (__ci_expr_logic_10 = (if (if not (isspace((unsafe: *__local_argptr)) != 0): 1 else: 0) != 0: 1 else: 0))
                        }

                        if (not (__ci_expr_logic_10 != 0)) {
                            break
                        }

                        (__local_argptr = __local_argptr + 1)

                    }

                }

                (local_newline_default = __local_first_listed_newline)

            },
            8 => {
                if ((if patstacknext_8 <= 0: 1 else: 0) != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** Can't pop off an empty stack\n")

                    colour_end(outfile)


                    return PR_SKIP

                }

                patctl_zero((&raw mut pat_patctl as *mut patctl))

                if ((if not (decode_modifiers_8(__local_argptr, CTX_POPPAT, (&raw mut pat_patctl as *mut patctl), null) != 0): 1 else: 0) != 0) {
                    return PR_SKIP
                }

                if ((if __local_cmd == CMD_POP: 1 else: 0) != 0) {
                    (patstacknext_8 = patstacknext_8 - 1)

                    (compiled_code_8 = patstack_8[patstacknext_8])


                } else {
                    (compiled_code_8 = pcre2_code_copy_8(patstack_8[(patstacknext_8 - 1)]))

                }

                if ((if (&raw const pat_patctl as *const patctl).jit != 0: 1 else: 0) != 0) {
                    (jitrc = pcre2_jit_compile_8(compiled_code_8, (&raw const pat_patctl as *const patctl).jit))

                }

                (__local_rc = show_pattern_info_8())

                if ((if __local_rc != PR_OK: 1 else: 0) != 0) {
                    return __local_rc
                }

            },
            9 => {
                if ((if patstacknext_8 <= 0: 1 else: 0) != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** Can't pop off an empty stack\n")

                    colour_end(outfile)


                    return PR_SKIP

                }

                patctl_zero((&raw mut pat_patctl as *mut patctl))

                if ((if not (decode_modifiers_8(__local_argptr, CTX_POPPAT, (&raw mut pat_patctl as *mut patctl), null) != 0): 1 else: 0) != 0) {
                    return PR_SKIP
                }

                if ((if __local_cmd == CMD_POP: 1 else: 0) != 0) {
                    (patstacknext_8 = patstacknext_8 - 1)

                    (compiled_code_8 = patstack_8[patstacknext_8])


                } else {
                    (compiled_code_8 = pcre2_code_copy_8(patstack_8[(patstacknext_8 - 1)]))

                }

                if ((if (&raw const pat_patctl as *const patctl).jit != 0: 1 else: 0) != 0) {
                    (jitrc = pcre2_jit_compile_8(compiled_code_8, (&raw const pat_patctl as *const patctl).jit))

                }

                (__local_rc = show_pattern_info_8())

                if ((if __local_rc != PR_OK: 1 else: 0) != 0) {
                    return __local_rc
                }

            },
            10 => {
                if ((if patstacknext_8 <= 0: 1 else: 0) != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** No stacked patterns to save\n")

                    colour_end(outfile)


                    return PR_OK

                }

                (__local_rc = open_file((__local_argptr + ((1 as isize) as usize)), "wb", (&raw mut __local_f as *mut *mut c_void), "#save"))

                if ((if __local_rc != PR_OK: 1 else: 0) != 0) {
                    return __local_rc
                }

                (__local_rc = pcre2_serialize_encode_8((&(unsafe: patstack_8[0]) as *mut *const pcre2_real_code_8), patstacknext_8, (&raw mut __local_serial as *mut *mut u8), (&raw mut __local_serial_size as *mut c_ulong), general_context_8))

                if ((if __local_rc < 0: 1 else: 0) != 0) {
                    fclose(__local_f)

                    if ((if not (serial_error_8(__local_rc, "Serialization") != 0): 1 else: 0) != 0) {
                        return PR_ABEND
                    }

                    break

                }

                (__local_i = 0)

                while ((if __local_i < 4: 1 else: 0) != 0) {
                    fputc(((((__local_serial_size as c_ulong) >> (((__local_i as c_ulong) *% (8 as c_ulong)) as c_uint)) as c_ulong) & (255 as c_ulong)), __local_f)

                    (__local_i = __local_i + 1)

                }


                if ((if fwrite(__local_serial, 1, __local_serial_size, __local_f) != __local_serial_size: 1 else: 0) != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** Wrong return from fwrite()\n")

                    colour_end(outfile)


                    fclose(__local_f)

                    return PR_ABEND

                }

                fclose(__local_f)

                pcre2_serialize_free_8(__local_serial)

                while ((if patstacknext_8 > 0: 1 else: 0) != 0) {
                    (patstacknext_8 = patstacknext_8 - 1)

                    (compiled_code_8 = patstack_8[patstacknext_8])


                    pcre2_code_free_8(compiled_code_8)

                }

                (compiled_code_8 = ((null as *mut pcre2_real_code_8)))

            },
            3 => {
                (__local_rc = open_file((__local_argptr + ((1 as isize) as usize)), "rb", (&raw mut __local_f as *mut *mut c_void), "#load"))

                if ((if __local_rc != PR_OK: 1 else: 0) != 0) {
                    return __local_rc
                }

                (__local_serial_size = 0)

                (__local_i = 0)

                while ((if __local_i < 4: 1 else: 0) != 0) {
                    (__local_serial_size = __local_serial_size | ((fgetc(__local_f) as c_int) << (((__local_i as c_ulong) *% (8 as c_ulong)) as c_uint)))

                    (__local_i = __local_i + 1)

                }


                (__local_serial = ((with_alloc((__local_serial_size as i64)) as *mut c_void)))

                if ((if __local_serial == null: 1 else: 0) != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** Failed to get memory (size %zu) for #load\n", __local_serial_size)

                    colour_end(outfile)


                    fclose(__local_f)

                    return PR_ABEND

                }

                (__local_i = fread(__local_serial, 1, __local_serial_size, __local_f))

                fclose(__local_f)

                if ((if __local_i != __local_serial_size: 1 else: 0) != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** Wrong return from fread()\n")

                    colour_end(outfile)


                    (__local_yield_ = PR_ABEND)

                } else {
                    (__local_rc = pcre2_serialize_get_number_of_codes_8(__local_serial))

                    if ((if __local_rc < 0: 1 else: 0) != 0) {
                        if ((if not (serial_error_8(__local_rc, "Get number of codes") != 0): 1 else: 0) != 0) {
                            (__local_yield_ = PR_ABEND)
                        }

                    } else {
                        if ((if (__local_rc + patstacknext_8) > 20: 1 else: 0) != 0) {
                            var __ci_expr_ternary_11: *mut c_char = null

                            if ((if __local_rc == 1: 1 else: 0) != 0) {
                                (__ci_expr_ternary_11 = (("" as *mut c_char)))
                            } else {
                                (__ci_expr_ternary_11 = (("s" as *mut c_char)))
                            }

                            colour_begin(31, outfile)

                            fprintf(outfile, "** Not enough space on pattern stack for %d pattern%s\n", __local_rc, __ci_expr_ternary_11)

                            colour_end(outfile)


                            (__local_rc = 20 - patstacknext_8)

                            var __ci_expr_ternary_12: *mut c_char = null

                            if ((if __local_rc == 1: 1 else: 0) != 0) {
                                (__ci_expr_ternary_12 = (("" as *mut c_char)))
                            } else {
                                (__ci_expr_ternary_12 = (("s" as *mut c_char)))
                            }

                            colour_begin(31, outfile)

                            fprintf(outfile, "** Decoding %d pattern%s\n", __local_rc, __ci_expr_ternary_12)

                            colour_end(outfile)


                        }

                        (__local_rc = pcre2_serialize_decode_8(((&(unsafe: patstack_8[0]) as *mut *mut pcre2_real_code_8) + ((patstacknext_8 as isize) as usize)), __local_rc, __local_serial, general_context_8))

                        if ((if __local_rc < 0: 1 else: 0) != 0) {
                            if ((if not (serial_error_8(__local_rc, "Deserialization") != 0): 1 else: 0) != 0) {
                                (__local_yield_ = PR_ABEND)
                            }

                        } else {
                            (patstacknext_8 = patstacknext_8 + __local_rc)
                        }

                    }

                }

                with_free((__local_serial as *mut i8))

            },
            4 => {
                (__local_rc = open_file((__local_argptr + ((1 as isize) as usize)), "rb", (&raw mut __local_f as *mut *mut c_void), "#loadtables"))

                if ((if __local_rc != PR_OK: 1 else: 0) != 0) {
                    return __local_rc
                }

                if ((if tables3 == null: 1 else: 0) != 0) {
                    var __local_r: c_int

                    (__local_r = pcre2_config_8(15, (&raw mut loadtables_length as *mut c_uint)))

                    if ((if __local_r >= 0: 1 else: 0) != 0) {
                        (tables3 = ((with_alloc((loadtables_length as i64)) as *mut c_void)))
                    }

                }

                if ((if tables3 == null: 1 else: 0) != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** Failed: malloc/config for #loadtables\n")

                    colour_end(outfile)


                    (__local_yield_ = PR_ABEND)

                } else {
                    if ((if fread(tables3, 1, loadtables_length, __local_f) != loadtables_length: 1 else: 0) != 0) {
                        colour_begin(31, outfile)

                        fprintf(outfile, "** Wrong return from fread()\n")

                        colour_end(outfile)


                        (__local_yield_ = PR_ABEND)

                    }
                }

                fclose(__local_f)

            },
            2 => {
                if (inside_if != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** Nested #if not supported\n")

                    colour_end(outfile)


                    return PR_ABEND

                }

                while (isspace((unsafe: *__local_argptr)) != 0) {
                    (__local_argptr = __local_argptr + 1)
                }

                (__local_if_inverted = 0)

                if ((if (unsafe: *__local_argptr) == 33: 1 else: 0) != 0) {
                    (__local_argptr = __local_argptr + 1)

                    (__local_if_inverted = 1)

                }

                while (isspace((unsafe: *__local_argptr)) != 0) {
                    (__local_argptr = __local_argptr + 1)
                }

                (__local_i = 0)

                while ((if __local_i < 13: 1 else: 0) != 0) {
                    var __local_optlen: c_ulong = string_len(coptlist[__local_i].name)

                    var __local_argptr_trail: *const u8

                    if ((if coptlist[__local_i].type_ != 1: 1 else: 0) != 0) {
                        (__local_i = __local_i + 1)

                        continue

                    }

                    if ((if strncmp((__local_argptr as *const c_char), coptlist[__local_i].name, __local_optlen) != 0: 1 else: 0) != 0) {
                        (__local_i = __local_i + 1)

                        continue

                    }

                    (__local_argptr_trail = (((__local_argptr + (__local_optlen as usize)) as *const u8)))

                    while (isspace((unsafe: *__local_argptr_trail)) != 0) {
                        (__local_argptr_trail = __local_argptr_trail + 1)
                    }

                    var __ci_expr_logic_13: c_int

                    if ((if (unsafe: *__local_argptr_trail) == 0: 1 else: 0) != 0) {
                        (__ci_expr_logic_13 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_13 = (if (if (unsafe: *__local_argptr_trail) == 10: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_13 != 0) {
                        break
                    }



                    (__local_i = __local_i + 1)

                }


                if ((if __local_i == 13: 1 else: 0) != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** Unknown condition: %s\n", buffer)

                    colour_end(outfile)


                    return PR_ABEND

                }

                if ((if (if coptlist[__local_i].value != 0: 1 else: 0) == __local_if_inverted: 1 else: 0) != 0) {
                    (__local_yield_ = PR_ENDIF)
                }

                (inside_if = 1)

            },
            0 => {
                if ((if not (inside_if != 0): 1 else: 0) != 0) {
                    colour_begin(31, outfile)

                    fprintf(outfile, "** Unexpected #endif\n")

                    colour_end(outfile)


                    return PR_ABEND

                }

                (inside_if = 0)

            },
        }

        break

    }

    return __local_yield_

}

fn process_pattern_8() -> c_int {
    var __local_utf__goto_2011_6: c_int = 0

    var __local_k__goto_2012_10: c_uint = 0

    var __local_p__goto_2013_10: *mut u8 = null

    var __local_delimiter__goto_2014_14: c_uint = 0

    var __local_rc__goto_2015_5: c_int = 0

    var __local_errorcode__goto_2015_9: c_int = 0

    var __local_use_pat_context__goto_2016_24: *mut pcre2_real_compile_context_8 = null

    var __local_use_pbuffer__goto_2017_12: *const u8 = null

    var __local_use_forbid_utf__goto_2018_10: c_uint = 0

    var __local_patlen__goto_2019_12: c_ulong = 0

    var __local_full_patlen__goto_2019_20: c_ulong = 0

    var __local_valgrind_access_length__goto_2020_12: c_ulong = 0

    var __local_erroroffset__goto_2021_12: c_ulong = 0

    var __local_c__goto_2107_12: c_uint = 0

    var __local_pp__goto_2130_12: *mut u8 = null

    var __local_pt__goto_2130_17: *mut u8 = null

    var __local_c__goto_2131_12: c_uint = 0

    var __local_d__goto_2131_15: c_uint = 0

    var __local_pq__goto_2143_16: *mut u8 = null

    var __local_pp__goto_2195_12: *mut u8 = null

    var __local_pt__goto_2195_17: *mut u8 = null

    var __local_pc__goto_2200_14: *mut u8 = null

    var __local_count__goto_2201_14: c_uint = 0

    var __local_length__goto_2202_12: c_ulong = 0

    var __local_pe__goto_2209_16: *mut u8 = null

    var __local_clen__goto_2214_18: c_ulong = 0

    var __local_i__goto_2215_20: c_uint = 0

    var __local_uli__goto_2216_25: c_ulong = 0

    var __local_endptr__goto_2217_17: *mut i8 = null

    var __local_pc_offset__goto_2252_14: c_ulong = 0

    var __local_pp_offset__goto_2253_14: c_ulong = 0

    var __local_pt_offset__goto_2254_14: c_ulong = 0

    var __local_cflags__goto_2350_7: c_int = 0

    var __local_msg__goto_2351_15: *const i8 = null

    var __local_regbuffer__goto_2436_11: *mut i8 = null

    var __local_bsize__goto_2437_12: c_ulong = 0

    var __local_usize__goto_2437_19: c_ulong = 0

    var __local_strsize__goto_2437_26: c_ulong = 0

    var __local_convert_return__goto_2563_7: c_int = 0

    var __local_convert_options__goto_2564_12: c_uint = 0

    var __local_converted_pattern__goto_2565_16: *mut u8 = null

    var __local_converted_length__goto_2566_14: c_ulong = 0

    var __local_zero_terminate__goto_2567_8: c_int = 0

    var __local_escape__goto_2589_14: c_uint = 0

    var __local_separator__goto_2603_14: c_uint = 0

    var __local_i__goto_2723_7: c_int = 0

    var __local_time_taken__goto_2724_11: c_ulong = 0

    var __local_start_time__goto_2727_13: c_ulong = 0

    var __local_i__goto_2750_12: c_int = 0

    var __local_target_mallocs__goto_2750_19: c_int = 0

    var __local_i__goto_2789_9: c_int = 0

    var __local_time_taken__goto_2790_13: c_ulong = 0

    var __local_start_time__goto_2794_15: c_ulong = 0

    var __local_i__goto_2828_14: c_int = 0

    var __local_target_mallocs__goto_2828_21: c_int = 0

    var __local_direction__goto_2868_7: c_int = 0

    var __local_cc__goto_2883_14: c_uint = 0

    var __local_n__goto_2884_9: c_int = 0

    var __local_q__goto_2885_23: *mut u8 = null

    var __local_q_end__goto_2885_37: *mut u8 = null

    var __ci_expr_old_0: *mut u8 = null

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_old_3: *mut u8 = null

    var __ci_expr_old_4: *mut u8 = null

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_old_8: *mut u8 = null

    var __ci_expr_logic_9: c_int = 0

    var __ci_expr_old_10: *mut u8 = null

    var __ci_expr_ternary_11: c_uint = 0

    var __ci_expr_ternary_12: c_uint = 0

    var __ci_expr_old_13: *mut u8 = null

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_logic_15: c_int = 0

    var __ci_expr_logic_16: c_int = 0

    var __ci_expr_ternary_18: c_ulong = 0

    var __ci_expr_logic_17: c_int = 0

    var __ci_expr_ternary_19: c_ulong = 0

    var __ci_expr_logic_20: c_int = 0

    var __ci_expr_logic_24: c_int = 0

    var __ci_expr_logic_23: c_int = 0

    var __ci_expr_logic_22: c_int = 0

    var __ci_expr_logic_21: c_int = 0

    var __ci_expr_logic_25: c_int = 0

    var __ci_expr_logic_26: c_int = 0

    var __ci_expr_ternary_27: c_ulong = 0

    var __ci_expr_ternary_28: c_uint = 0

    var __ci_expr_ternary_29: *mut u8 = null

    var __ci_expr_ternary_30: c_int = 0

    var __ci_expr_logic_31: c_int = 0

    var __ci_expr_ternary_32: *mut pcre2_real_compile_context_8 = null

    var __ci_expr_ternary_33: *mut u8 = null

    var __ci_expr_logic_35: c_int = 0

    var __ci_expr_logic_36: c_int = 0

    var __ci_expr_logic_37: c_int = 0

    var __ci_expr_logic_38: c_int = 0

    var __ci_expr_logic_39: c_int = 0

    var __ci_expr_ternary_41: *mut c_char = null

    var __ci_expr_old_42: c_int = 0

    var __ci_expr_old_43: c_int = 0

    var __ci_expr_old_44: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_p__goto_2013_10 = buffer)
        (__ci_expr_old_0 = __local_p__goto_2013_10)
        (__local_p__goto_2013_10 = __local_p__goto_2013_10 + 1)
        (__local_delimiter__goto_2014_14 = (unsafe: *__ci_expr_old_0))
        (__local_use_forbid_utf__goto_2018_10 = forbid_utf)
        (__ci_expr_logic_1 = 0)
        if (restrict_for_perl_test != 0) {
            (__ci_expr_logic_1 = (if (if __local_delimiter__goto_2014_14 != 47: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        colour_begin(31, outfile)
        fprintf(outfile, "** The only allowed delimiter after #perltest is '/'\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_2 {
        with_memcpy((pat_context_8 as *i8), (default_pat_context_8 as *i8), (sizeof[pcre2_real_compile_context_8]() as i64))
        with_memcpy(((&raw mut pat_patctl as *mut patctl) as *i8), ((&raw mut def_patctl as *mut patctl) as *i8), (sizeof[patctl]() as i64))
        goto '__ci_bb_3
    }

    '__ci_bb_3 {
        goto '__ci_bb_4
    }

    '__ci_bb_4 {
        goto '__ci_bb_7
    }

    '__ci_bb_5 {
        goto '__ci_bb_3
    }

    '__ci_bb_6 {
        if ((if (unsafe: __local_p__goto_2013_10[1]) == 92: 1 else: 0) != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_7 {
        if ((if (unsafe: *__local_p__goto_2013_10) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_8 {
        (__ci_expr_logic_2 = 0)
        if ((if (unsafe: *__local_p__goto_2013_10) == 92: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if (unsafe: __local_p__goto_2013_10[1]) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_9 {
        if ((if (unsafe: *__local_p__goto_2013_10) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_10 {
        (__local_p__goto_2013_10 = __local_p__goto_2013_10 + 1)
        goto '__ci_bb_12
    }

    '__ci_bb_11 {
        if ((if (unsafe: *__local_p__goto_2013_10) == __local_delimiter__goto_2014_14: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_12 {
        (__local_p__goto_2013_10 = __local_p__goto_2013_10 + 1)
        goto '__ci_bb_7
    }

    '__ci_bb_13 {
        goto '__ci_bb_9
    }

    '__ci_bb_14 {
        goto '__ci_bb_12
    }

    '__ci_bb_15 {
        goto '__ci_bb_6
    }

    '__ci_bb_16 {
        (__local_p__goto_2013_10 = extend_inputline(infile, __local_p__goto_2013_10, "    > "))
        if ((if __local_p__goto_2013_10 == null: 1 else: 0) != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_17 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unexpected EOF\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_18 {
        if ((if not (isatty(fileno(infile)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_19 {
        colour_begin(32, outfile)
        fprintf(outfile, "%s", (__local_p__goto_2013_10 as *mut c_char))
        colour_end(outfile)
        goto '__ci_bb_20
    }

    '__ci_bb_20 {
        goto '__ci_bb_5
    }

    '__ci_bb_21 {
        (__ci_expr_old_3 = __local_p__goto_2013_10)
        (__local_p__goto_2013_10 = __local_p__goto_2013_10 + 1)
        ((unsafe: *__ci_expr_old_3) = 92)
        goto '__ci_bb_22
    }

    '__ci_bb_22 {
        (__ci_expr_old_4 = __local_p__goto_2013_10)
        (__local_p__goto_2013_10 = __local_p__goto_2013_10 + 1)
        ((unsafe: *__ci_expr_old_4) = 0)
        (__local_patlen__goto_2019_12 = (((__local_p__goto_2013_10 as usize) -% (buffer as usize)) / sizeof[u8]()) - 2)
        if ((if not (decode_modifiers_8(__local_p__goto_2013_10, CTX_PAT, (&raw mut pat_patctl as *mut patctl), null) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_23 {
        return PR_SKIP
    }

    '__ci_bb_24 {
        (__local_utf__goto_2011_6 = (if (((&raw const pat_patctl as *const patctl).options as c_uint) & (((524288 as c_uint) | (67108864 as c_uint)) as c_uint)) != 0: 1 else: 0))
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (1073741824 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_25 {
        colour_begin(31, outfile)
        fprintf(outfile, "** The utf8_input modifier is not allowed in 8-bit mode\n")
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_26 {
        (__ci_expr_logic_5 = 0)
        if ((if (&raw const pat_patctl as *const patctl).convert_type != 4294967295: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if (((&raw const pat_patctl as *const patctl).control as c_uint) & (8388608 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_28
        }
    }

    '__ci_bb_27 {
        colour_begin(31, outfile)
        fprintf(outfile, "** The convert and posix modifiers are mutually exclusive\n")
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_28 {
        (__local_k__goto_2012_10 = 0)
        goto '__ci_bb_29
    }

    '__ci_bb_29 {
        if ((if __local_k__goto_2012_10 < (((7 * sizeof[c_uint]()) as c_ulong) / (sizeof[u32]() as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_30 {
        (__local_c__goto_2107_12 = ((&raw const pat_patctl as *const patctl).control as c_uint) & (exclusive_pat_controls[__local_k__goto_2012_10] as c_uint))
        (__ci_expr_logic_6 = 0)
        if ((if __local_c__goto_2107_12 != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if __local_c__goto_2107_12 != ((__local_c__goto_2107_12 as c_uint) & ((((~__local_c__goto_2107_12) as c_uint) +% (1 as c_uint)) as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_31 {
        (__local_k__goto_2012_10 = __local_k__goto_2012_10 + 1)
        goto '__ci_bb_29
    }

    '__ci_bb_32 {
        (__ci_expr_logic_7 = 0)
        if ((if (&raw const pat_patctl as *const patctl).jit == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if (if (((&raw const pat_patctl as *const patctl).control as c_uint) & (((524288 as c_uint) | (262144 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_33 {
        show_controls(31, __local_c__goto_2107_12, 0, "** Not allowed together:")
        fprintf(outfile, "\n")
        return PR_SKIP
    }

    '__ci_bb_34 {
        goto '__ci_bb_31
    }

    '__ci_bb_35 {
        (pat_patctl.jit = (((1 as c_uint) | (2 as c_uint)) as c_uint) | (4 as c_uint))
        goto '__ci_bb_36
    }

    '__ci_bb_36 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (65536 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_37 {
        (__local_pt__goto_2130_17 = pbuffer8)
        (__local_pp__goto_2130_12 = buffer + ((1 as isize) as usize))
        goto '__ci_bb_40
    }

    '__ci_bb_38 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_63
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_39 {
        if ((if (&raw const pat_patctl as *const patctl).locale[0] != 255: 1 else: 0) != 0) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_94
        }
    }

    '__ci_bb_40 {
        if ((if (unsafe: *__local_pp__goto_2130_12) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_41
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_41 {
        if (isspace((unsafe: *__local_pp__goto_2130_12)) != 0) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_42 {
        (__local_pp__goto_2130_12 = __local_pp__goto_2130_12 + 1)
        goto '__ci_bb_40
    }

    '__ci_bb_43 {
        ((unsafe: *__local_pt__goto_2130_17) = 0)
        (__local_patlen__goto_2019_12 = ((__local_pt__goto_2130_17 as usize) -% (pbuffer8 as usize)) / sizeof[u8]())
        goto '__ci_bb_39
    }

    '__ci_bb_44 {
        goto '__ci_bb_42
    }

    '__ci_bb_45 {
        (__ci_expr_old_8 = __local_pp__goto_2130_12)
        (__local_pp__goto_2130_12 = __local_pp__goto_2130_12 + 1)
        (__local_c__goto_2131_12 = (unsafe: *__ci_expr_old_8))
        if ((if __local_c__goto_2131_12 == 39: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_9 = (if (if __local_c__goto_2131_12 == 34: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_46 {
        (__local_pq__goto_2143_16 = __local_pp__goto_2130_12)
        goto '__ci_bb_49
    }

    '__ci_bb_47 {
        if ((if not (isxdigit(__local_c__goto_2131_12) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_57
        } else {
            goto '__ci_bb_58
        }
    }

    '__ci_bb_48 {
        goto '__ci_bb_42
    }

    '__ci_bb_49 {
        goto '__ci_bb_50
    }

    '__ci_bb_50 {
        (__local_d__goto_2131_15 = (unsafe: *__local_pp__goto_2130_12))
        if ((if __local_d__goto_2131_15 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_51 {
        (__local_pp__goto_2130_12 = __local_pp__goto_2130_12 + 1)
        goto '__ci_bb_49
    }

    '__ci_bb_52 {
        goto '__ci_bb_48
    }

    '__ci_bb_53 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Missing closing quote in hex pattern: opening quote is at offset %.\n", ((((__local_pq__goto_2143_16 as usize) -% (buffer as usize)) / sizeof[u8]()) - 2))
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_54 {
        if ((if __local_d__goto_2131_15 == __local_c__goto_2131_12: 1 else: 0) != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_55 {
        goto '__ci_bb_52
    }

    '__ci_bb_56 {
        (__ci_expr_old_10 = __local_pt__goto_2130_17)
        (__local_pt__goto_2130_17 = __local_pt__goto_2130_17 + 1)
        ((unsafe: *__ci_expr_old_10) = __local_d__goto_2131_15)
        goto '__ci_bb_51
    }

    '__ci_bb_57 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unexpected non-hex-digit '%c' at offset %td in hex pattern: quote missing?\n", __local_c__goto_2131_12, ((((__local_pp__goto_2130_12 as usize) -% (buffer as usize)) / sizeof[u8]()) - 2))
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_58 {
        if ((if (unsafe: *__local_pp__goto_2130_12) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_59 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Odd number of digits in hex pattern\n")
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_60 {
        (__local_d__goto_2131_15 = (unsafe: *__local_pp__goto_2130_12))
        if ((if not (isxdigit(__local_d__goto_2131_15) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_61 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unexpected non-hex-digit '%c' at offset %td in hex pattern: quote missing?\n", __local_d__goto_2131_15, ((((__local_pp__goto_2130_12 as usize) -% (buffer as usize)) / sizeof[u8]()) - 1))
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_62 {
        (__local_c__goto_2131_12 = toupper(__local_c__goto_2131_12))
        (__local_d__goto_2131_15 = toupper(__local_d__goto_2131_15))
        (__ci_expr_ternary_11 = 0)
        if (isdigit(__local_c__goto_2131_12) != 0) {
            (__ci_expr_ternary_11 = ((__local_c__goto_2131_12 as c_uint) -% (48 as c_uint)))
        } else {
            (__ci_expr_ternary_11 = ((((__local_c__goto_2131_12 as c_uint) -% (65 as c_uint)) as c_uint) +% (10 as c_uint)))
        }
        (__local_c__goto_2131_12 = __ci_expr_ternary_11)
        (__ci_expr_ternary_12 = 0)
        if (isdigit(__local_d__goto_2131_15) != 0) {
            (__ci_expr_ternary_12 = ((__local_d__goto_2131_15 as c_uint) -% (48 as c_uint)))
        } else {
            (__ci_expr_ternary_12 = ((((__local_d__goto_2131_15 as c_uint) -% (65 as c_uint)) as c_uint) +% (10 as c_uint)))
        }
        (__local_d__goto_2131_15 = __ci_expr_ternary_12)
        (__ci_expr_old_13 = __local_pt__goto_2130_17)
        (__local_pt__goto_2130_17 = __local_pt__goto_2130_17 + 1)
        ((unsafe: *__ci_expr_old_13) = ((((__local_c__goto_2131_12 as c_uint) << (4 as c_uint)) as c_uint) +% (__local_d__goto_2131_15 as c_uint)))
        goto '__ci_bb_48
    }

    '__ci_bb_63 {
        (__local_pt__goto_2195_17 = pbuffer8)
        (__local_pp__goto_2195_12 = buffer + ((1 as isize) as usize))
        goto '__ci_bb_66
    }

    '__ci_bb_64 {
        strncpy((pbuffer8 as *mut c_char), ((buffer + ((1 as isize) as usize)) as *mut c_char), ((__local_patlen__goto_2019_12 as c_ulong) +% (1 as c_ulong)))
        goto '__ci_bb_65
    }

    '__ci_bb_65 {
        goto '__ci_bb_39
    }

    '__ci_bb_66 {
        if ((if (unsafe: *__local_pp__goto_2195_12) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_69
        }
    }

    '__ci_bb_67 {
        (__local_pc__goto_2200_14 = __local_pp__goto_2195_12)
        (__local_count__goto_2201_14 = 1)
        (__local_length__goto_2202_12 = 1)
        (__ci_expr_logic_14 = 0)
        if ((if (unsafe: __local_pp__goto_2195_12[0]) == 92: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if (if (unsafe: __local_pp__goto_2195_12[1]) == 91: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_70
        } else {
            goto '__ci_bb_71
        }
    }

    '__ci_bb_68 {
        (__local_pp__goto_2195_12 = __local_pp__goto_2195_12 + 1)
        goto '__ci_bb_66
    }

    '__ci_bb_69 {
        ((unsafe: *__local_pt__goto_2195_17) = 0)
        (__local_patlen__goto_2019_12 = ((__local_pt__goto_2195_17 as usize) -% (pbuffer8 as usize)) / sizeof[u8]())
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_92
        }
    }

    '__ci_bb_70 {
        (__local_pe__goto_2209_16 = __local_pp__goto_2195_12 + ((2 as isize) as usize))
        goto '__ci_bb_72
    }

    '__ci_bb_71 {
        goto '__ci_bb_84
    }

    '__ci_bb_72 {
        if ((if (unsafe: *__local_pe__goto_2209_16) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_73 {
        (__ci_expr_logic_15 = 0)
        if ((if (unsafe: __local_pe__goto_2209_16[0]) == 93: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if (if (unsafe: __local_pe__goto_2209_16[1]) == 123: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_15 != 0) {
            goto '__ci_bb_76
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_74 {
        (__local_pe__goto_2209_16 = __local_pe__goto_2209_16 + 1)
        goto '__ci_bb_72
    }

    '__ci_bb_75 {
        goto '__ci_bb_71
    }

    '__ci_bb_76 {
        (__local_clen__goto_2214_18 = (((__local_pe__goto_2209_16 as usize) -% (__local_pc__goto_2200_14 as usize)) / sizeof[u8]()) - 2)
        (__local_i__goto_2215_20 = 0)
        (__local_pe__goto_2209_16 = __local_pe__goto_2209_16 + ((2 as isize) as usize))
        (__local_uli__goto_2216_25 = strtoul((__local_pe__goto_2209_16 as *const c_char), (&raw mut __local_endptr__goto_2217_17 as *mut *mut c_char), 10))
        if ((if __local_uli__goto_2216_25 > 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_77 {
        goto '__ci_bb_74
    }

    '__ci_bb_78 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Pattern repeat count too large\n")
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_79 {
        (__local_i__goto_2215_20 = ((__local_uli__goto_2216_25 as c_uint)))
        (__local_pe__goto_2209_16 = ((__local_endptr__goto_2217_17 as *mut u8)))
        if ((if (unsafe: *__local_pe__goto_2209_16) == 125: 1 else: 0) != 0) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_80 {
        if ((if __local_i__goto_2215_20 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_82
        } else {
            goto '__ci_bb_83
        }
    }

    '__ci_bb_81 {
        goto '__ci_bb_77
    }

    '__ci_bb_82 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Zero repeat not allowed\n")
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_83 {
        (__local_pc__goto_2200_14 = __local_pc__goto_2200_14 + ((2 as isize) as usize))
        (__local_count__goto_2201_14 = __local_i__goto_2215_20)
        (__local_length__goto_2202_12 = __local_clen__goto_2214_18)
        (__local_pp__goto_2195_12 = __local_pe__goto_2209_16)
        goto '__ci_bb_75
    }

    '__ci_bb_84 {
        if ((if (__local_pt__goto_2195_17 + (((__local_count__goto_2201_14 as c_ulong) *% (__local_length__goto_2202_12 as c_ulong)) as usize)) > (pbuffer8 + (pbuffer8_size as usize)): 1 else: 0) != 0) {
            goto '__ci_bb_85
        } else {
            goto '__ci_bb_86
        }
    }

    '__ci_bb_85 {
        (__local_pc_offset__goto_2252_14 = ((__local_pc__goto_2200_14 as usize) -% (buffer as usize)) / sizeof[u8]())
        (__local_pp_offset__goto_2253_14 = ((__local_pp__goto_2195_12 as usize) -% (buffer as usize)) / sizeof[u8]())
        (__local_pt_offset__goto_2254_14 = ((__local_pt__goto_2195_17 as usize) -% (pbuffer8 as usize)) / sizeof[u8]())
        expand_input_buffers()
        (__local_pc__goto_2200_14 = buffer + (__local_pc_offset__goto_2252_14 as usize))
        (__local_pp__goto_2195_12 = buffer + (__local_pp_offset__goto_2253_14 as usize))
        (__local_pt__goto_2195_17 = pbuffer8 + (__local_pt_offset__goto_2254_14 as usize))
        goto '__ci_bb_84
    }

    '__ci_bb_86 {
        goto '__ci_bb_87
    }

    '__ci_bb_87 {
        if ((if __local_count__goto_2201_14 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_90
        }
    }

    '__ci_bb_88 {
        with_memcpy((__local_pt__goto_2195_17 as *i8), (__local_pc__goto_2200_14 as *i8), (__local_length__goto_2202_12 as i64))
        (__local_pt__goto_2195_17 = __local_pt__goto_2195_17 + (__local_length__goto_2202_12 as usize))
        goto '__ci_bb_89
    }

    '__ci_bb_89 {
        (__local_count__goto_2201_14 = __local_count__goto_2201_14 - 1)
        goto '__ci_bb_87
    }

    '__ci_bb_90 {
        goto '__ci_bb_68
    }

    '__ci_bb_91 {
        fprintf(outfile, "Expanded: %s\n", pbuffer8)
        goto '__ci_bb_92
    }

    '__ci_bb_92 {
        goto '__ci_bb_65
    }

    '__ci_bb_93 {
        if ((if (&raw const pat_patctl as *const patctl).tables_id != 0: 1 else: 0) != 0) {
            goto '__ci_bb_96
        } else {
            goto '__ci_bb_97
        }
    }

    '__ci_bb_94 {
        goto '__ci_bb_104
    }

    '__ci_bb_95 {
        pcre2_set_character_tables_8(pat_context_8, use_tables)
        if ((if (&raw const pat_patctl as *const patctl).stackguard_test != 0: 1 else: 0) != 0) {
            goto '__ci_bb_116
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_96 {
        colour_begin(31, outfile)
        fprintf(outfile, "** 'Locale' and 'tables' must not both be set\n")
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_97 {
        if ((if setlocale(2, ((&(unsafe: (&raw const pat_patctl as *const patctl).locale[0]) as *const c_char) + ((1 as isize) as usize))) == null: 1 else: 0) != 0) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_98 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Failed to set locale \"%s\"\n", ((&(unsafe: (&raw const pat_patctl as *const patctl).locale[0]) as *mut u8) + ((1 as isize) as usize)))
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_99 {
        if ((if string_cmp(((&(unsafe: (&raw const pat_patctl as *const patctl).locale[0]) as *const c_char) + ((1 as isize) as usize)), (&(unsafe: locale_name[0]) as *const c_char)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_101
        }
    }

    '__ci_bb_100 {
        strncpy((&(unsafe: locale_name[0]) as *mut c_char), ((&(unsafe: (&raw const pat_patctl as *const patctl).locale[0]) as *mut c_char) + ((1 as isize) as usize)), (32 * sizeof[u8]()))
        (locale_name[(((32 * sizeof[u8]()) as c_ulong) -% (1 as c_ulong))] = 0)
        if ((if locale_tables != null: 1 else: 0) != 0) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_103
        }
    }

    '__ci_bb_101 {
        (use_tables = locale_tables)
        goto '__ci_bb_95
    }

    '__ci_bb_102 {
        pcre2_maketables_free_8(general_context_8, locale_tables)
        goto '__ci_bb_103
    }

    '__ci_bb_103 {
        (locale_tables = pcre2_maketables_8(general_context_8))
        goto '__ci_bb_101
    }

    '__ci_bb_104 {
        if ((&raw const pat_patctl as *const patctl).tables_id == 0) {
            goto '__ci_bb_106
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_105 {
        goto '__ci_bb_95
    }

    '__ci_bb_106 {
        (use_tables = ((null as *const u8)))
        goto '__ci_bb_105
    }

    '__ci_bb_107 {
        (use_tables = (&(unsafe: tables1[0]) as *const u8))
        goto '__ci_bb_105
    }

    '__ci_bb_108 {
        (use_tables = (&(unsafe: tables2[0]) as *const u8))
        goto '__ci_bb_105
    }

    '__ci_bb_109 {
        if ((if tables3 == null: 1 else: 0) != 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_110 {
        colour_begin(31, outfile)
        fprintf(outfile, "** 'Tables = 3' is invalid: binary tables have not been loaded\n")
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_111 {
        (use_tables = ((tables3 as *const u8)))
        goto '__ci_bb_105
    }

    '__ci_bb_112 {
        colour_begin(31, outfile)
        fprintf(outfile, "** 'Tables' must specify 0, 1, 2, or 3.\n")
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_113 {
        if ((&raw const pat_patctl as *const patctl).tables_id == 1) {
            goto '__ci_bb_107
        } else {
            goto '__ci_bb_114
        }
    }

    '__ci_bb_114 {
        if ((&raw const pat_patctl as *const patctl).tables_id == 2) {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_115
        }
    }

    '__ci_bb_115 {
        if ((&raw const pat_patctl as *const patctl).tables_id == 3) {
            goto '__ci_bb_109
        } else {
            goto '__ci_bb_112
        }
    }

    '__ci_bb_116 {
        pcre2_set_compile_recursion_guard_8(pat_context_8, stack_guard, null)
        goto '__ci_bb_117
    }

    '__ci_bb_117 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (8388608 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_119
        }
    }

    '__ci_bb_118 {
        (__local_cflags__goto_2350_7 = 0)
        (__local_msg__goto_2351_15 = (("** Ignored with POSIX interface:" as *const c_char)))
        if ((if (&raw const pat_patctl as *const patctl).locale[0] != 255: 1 else: 0) != 0) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_121
        }
    }

    '__ci_bb_119 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (((((33554432 as c_uint) | (67108864 as c_uint)) as c_uint) | (134217728 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_176
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_120 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "locale")
        goto '__ci_bb_121
    }

    '__ci_bb_121 {
        if ((if (&raw const pat_patctl as *const patctl).replacement[0] != 255: 1 else: 0) != 0) {
            goto '__ci_bb_122
        } else {
            goto '__ci_bb_123
        }
    }

    '__ci_bb_122 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "replace")
        goto '__ci_bb_123
    }

    '__ci_bb_123 {
        if ((if (&raw const pat_patctl as *const patctl).tables_id != 0: 1 else: 0) != 0) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_124 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "tables")
        goto '__ci_bb_125
    }

    '__ci_bb_125 {
        if ((if (&raw const pat_patctl as *const patctl).stackguard_test != 0: 1 else: 0) != 0) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_127
        }
    }

    '__ci_bb_126 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "stackguard")
        goto '__ci_bb_127
    }

    '__ci_bb_127 {
        if ((if timeit > 0: 1 else: 0) != 0) {
            goto '__ci_bb_128
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_128 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "timing")
        goto '__ci_bb_129
    }

    '__ci_bb_129 {
        if ((if (&raw const pat_patctl as *const patctl).jit != 0: 1 else: 0) != 0) {
            goto '__ci_bb_130
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_130 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "JIT")
        goto '__ci_bb_131
    }

    '__ci_bb_131 {
        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & ((~((((((((((((8 as c_uint) | (32 as c_uint)) as c_uint) | (33554432 as c_uint)) as c_uint) | (1024 as c_uint)) as c_uint) | (131072 as c_uint)) as c_uint) | (524288 as c_uint)) as c_uint) | (262144 as c_uint))) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_132
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_132 {
        show_compile_options(31, (((&raw const pat_patctl as *const patctl).options as c_uint) & ((~((((((((((((8 as c_uint) | (32 as c_uint)) as c_uint) | (33554432 as c_uint)) as c_uint) | (1024 as c_uint)) as c_uint) | (131072 as c_uint)) as c_uint) | (524288 as c_uint)) as c_uint) | (262144 as c_uint))) as c_uint)), __local_msg__goto_2351_15, "")
        (__local_msg__goto_2351_15 = (("" as *const c_char)))
        goto '__ci_bb_133
    }

    '__ci_bb_133 {
        if ((if ((pat_context_8.extra_options as c_uint) & (((~0) as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_134
        } else {
            goto '__ci_bb_135
        }
    }

    '__ci_bb_134 {
        show_compile_extra_options(31, ((pat_context_8.extra_options as c_uint) & (((~0) as c_uint) as c_uint)), __local_msg__goto_2351_15, "")
        (__local_msg__goto_2351_15 = (("" as *const c_char)))
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & ((~((((((((((((1 as c_uint) | (2 as c_uint)) as c_uint) | (1024 as c_uint)) as c_uint) | (65536 as c_uint)) as c_uint) | (8388608 as c_uint)) as c_uint) | (16777216 as c_uint)) as c_uint) | (536870912 as c_uint))) as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_16 = (if (if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (((~0) as c_uint) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_136 {
        show_controls(31, (((&raw const pat_patctl as *const patctl).control as c_uint) & ((~((((((((((((1 as c_uint) | (2 as c_uint)) as c_uint) | (1024 as c_uint)) as c_uint) | (65536 as c_uint)) as c_uint) | (8388608 as c_uint)) as c_uint) | (16777216 as c_uint)) as c_uint) | (536870912 as c_uint))) as c_uint)), (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (((~0) as c_uint) as c_uint)), __local_msg__goto_2351_15)
        (__local_msg__goto_2351_15 = (("" as *const c_char)))
        (pat_patctl.control = (&raw const pat_patctl as *const patctl).control & ((((((((((((1 as c_uint) | (2 as c_uint)) as c_uint) | (1024 as c_uint)) as c_uint) | (65536 as c_uint)) as c_uint) | (8388608 as c_uint)) as c_uint) | (16777216 as c_uint)) as c_uint) | (536870912 as c_uint)))
        (pat_patctl.control2 = (&raw const pat_patctl as *const patctl).control2 & (0 as c_uint))
        goto '__ci_bb_137
    }

    '__ci_bb_137 {
        if ((if local_newline_default != 0: 1 else: 0) != 0) {
            goto '__ci_bb_138
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_138 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "#newline_default")
        goto '__ci_bb_139
    }

    '__ci_bb_139 {
        if ((if pat_context_8.max_pattern_length != (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_140
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_140 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "max_pattern_length")
        goto '__ci_bb_141
    }

    '__ci_bb_141 {
        if ((if pat_context_8.max_pattern_compiled_length != (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_142
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_142 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "max_pattern_compiled_length")
        goto '__ci_bb_143
    }

    '__ci_bb_143 {
        if ((if pat_context_8.parens_nest_limit != 220: 1 else: 0) != 0) {
            goto '__ci_bb_144
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_144 {
        prmsg((&raw mut __local_msg__goto_2351_15 as *mut *const c_char), "parens_nest_limit")
        goto '__ci_bb_145
    }

    '__ci_bb_145 {
        if ((if (unsafe: __local_msg__goto_2351_15[0]) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_146
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_146 {
        fprintf(outfile, "\n")
        goto '__ci_bb_147
    }

    '__ci_bb_147 {
        if (__local_utf__goto_2011_6 != 0) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_148 {
        (__local_cflags__goto_2350_7 = __local_cflags__goto_2350_7 | 64)
        goto '__ci_bb_149
    }

    '__ci_bb_149 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (16777216 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_150 {
        (__local_cflags__goto_2350_7 = __local_cflags__goto_2350_7 | 32)
        goto '__ci_bb_151
    }

    '__ci_bb_151 {
        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (131072 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_152
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_152 {
        (__local_cflags__goto_2350_7 = __local_cflags__goto_2350_7 | 1024)
        goto '__ci_bb_153
    }

    '__ci_bb_153 {
        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_154
        } else {
            goto '__ci_bb_155
        }
    }

    '__ci_bb_154 {
        (__local_cflags__goto_2350_7 = __local_cflags__goto_2350_7 | 1)
        goto '__ci_bb_155
    }

    '__ci_bb_155 {
        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (33554432 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_156
        } else {
            goto '__ci_bb_157
        }
    }

    '__ci_bb_156 {
        (__local_cflags__goto_2350_7 = __local_cflags__goto_2350_7 | 4096)
        goto '__ci_bb_157
    }

    '__ci_bb_157 {
        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_158
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_158 {
        (__local_cflags__goto_2350_7 = __local_cflags__goto_2350_7 | 2)
        goto '__ci_bb_159
    }

    '__ci_bb_159 {
        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (32 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_160
        } else {
            goto '__ci_bb_161
        }
    }

    '__ci_bb_160 {
        (__local_cflags__goto_2350_7 = __local_cflags__goto_2350_7 | 16)
        goto '__ci_bb_161
    }

    '__ci_bb_161 {
        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (262144 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_162
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_162 {
        (__local_cflags__goto_2350_7 = __local_cflags__goto_2350_7 | 512)
        goto '__ci_bb_163
    }

    '__ci_bb_163 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (((65536 as c_uint) | (536870912 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_164 {
        (preg.re_endp = ((((pbuffer8 as *mut c_char) + (__local_patlen__goto_2019_12 as usize)) as *const c_char)))
        (__local_cflags__goto_2350_7 = __local_cflags__goto_2350_7 | 2048)
        goto '__ci_bb_165
    }

    '__ci_bb_165 {
        (__local_rc__goto_2015_5 = pcre2_regcomp((&raw mut preg as *mut regex_t), (pbuffer8 as *mut c_char), __local_cflags__goto_2350_7))
        if ((if __local_rc__goto_2015_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_166
        } else {
            goto '__ci_bb_167
        }
    }

    '__ci_bb_166 {
        (preg.re_pcre2_code = null)
        (preg.re_match_data = null)
        (__ci_expr_ternary_18 = 0)
        (__ci_expr_logic_17 = 0)
        if ((if (&raw const pat_patctl as *const patctl).regerror_buffsize >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if (((&raw const pat_patctl as *const patctl).regerror_buffsize as c_uint)) <= pbuffer8_size: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            (__ci_expr_ternary_18 = (((&raw const pat_patctl as *const patctl).regerror_buffsize as c_uint)))
        } else {
            (__ci_expr_ternary_18 = pbuffer8_size)
        }
        (__local_bsize__goto_2437_12 = __ci_expr_ternary_18)
        (__local_regbuffer__goto_2436_11 = ((((pbuffer8 as *mut c_char) + (((pbuffer8_size as c_ulong) -% (__local_bsize__goto_2437_12 as c_ulong)) as usize)) as *mut c_char)))
        (__local_usize__goto_2437_19 = pcre2_regerror(__local_rc__goto_2015_5, (&raw mut preg as *mut regex_t), __local_regbuffer__goto_2436_11, __local_bsize__goto_2437_12))
        (__ci_expr_ternary_19 = 0)
        if ((if __local_usize__goto_2437_19 > __local_bsize__goto_2437_12: 1 else: 0) != 0) {
            (__ci_expr_ternary_19 = __local_bsize__goto_2437_12)
        } else {
            (__ci_expr_ternary_19 = __local_usize__goto_2437_19)
        }
        (__local_strsize__goto_2437_26 = ((__ci_expr_ternary_19 as c_ulong) -% (1 as c_ulong)))
        colour_begin(35, outfile)
        fprintf(outfile, "Failed: POSIX code %d: ", __local_rc__goto_2015_5)
        colour_end(outfile)
        if ((if __local_bsize__goto_2437_12 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_168
        } else {
            goto '__ci_bb_169
        }
    }

    '__ci_bb_167 {
        if ((if (&raw const preg as *const regex_t).re_pcre2_code == null: 1 else: 0) != 0) {
            (__ci_expr_logic_21 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_21 = (if (if ((&raw const preg as *const regex_t).re_pcre2_code as *mut pcre2_real_code_8).magic_number != 1346589253: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_21 != 0) {
            (__ci_expr_logic_22 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_22 = (if (if ((&raw const preg as *const regex_t).re_pcre2_code as *mut pcre2_real_code_8).top_bracket != (&raw const preg as *const regex_t).re_nsub: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_22 != 0) {
            (__ci_expr_logic_23 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_23 = (if (if (&raw const preg as *const regex_t).re_match_data == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_23 != 0) {
            (__ci_expr_logic_24 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_24 = (if (if (&raw const preg as *const regex_t).re_cflags != __local_cflags__goto_2350_7: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_24 != 0) {
            goto '__ci_bb_174
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_168 {
        pchars_8(35, (__local_regbuffer__goto_2436_11 as *const u8), __local_strsize__goto_2437_26, __local_utf__goto_2011_6, outfile)
        goto '__ci_bb_169
    }

    '__ci_bb_169 {
        fputs("\n", outfile)
        if ((if __local_usize__goto_2437_19 > __local_bsize__goto_2437_12: 1 else: 0) != 0) {
            goto '__ci_bb_170
        } else {
            goto '__ci_bb_171
        }
    }

    '__ci_bb_170 {
        colour_begin(31, outfile)
        fprintf(outfile, "** regerror() message truncated\n")
        colour_end(outfile)
        goto '__ci_bb_171
    }

    '__ci_bb_171 {
        (__ci_expr_logic_20 = 0)
        if ((if __local_bsize__goto_2437_12 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if (if string_len(__local_regbuffer__goto_2436_11) != __local_strsize__goto_2437_26: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_20 != 0) {
            goto '__ci_bb_172
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_172 {
        colour_begin(31, outfile)
        fprintf(outfile, "** regerror() strlen incorrect\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_173 {
        return PR_SKIP
    }

    '__ci_bb_174 {
        colour_begin(31, outfile)
        fprintf(outfile, "** The regcomp() function returned zero (success), but the values set\n** in the preg block are not valid for PCRE2. Check that pcre2test is\n** linked with PCRE2's pcre2posix module (-lpcre2-posix) and not with\n** some other POSIX regex library.\n**\n")
        colour_end(outfile)
        (preg.re_pcre2_code = null)
        return PR_ABEND
    }

    '__ci_bb_175 {
        return PR_OK
    }

    '__ci_bb_176 {
        if ((if (&raw const pat_patctl as *const patctl).replacement[0] != 255: 1 else: 0) != 0) {
            goto '__ci_bb_178
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_177 {
        (__local_errorcode__goto_2015_9 = 0)
        if ((if (&raw const pat_patctl as *const patctl).convert_type != 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_184
        } else {
            goto '__ci_bb_185
        }
    }

    '__ci_bb_178 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Replacement text is not supported with 'push'.\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_179 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & ((~((((((((((((((((((((32 as c_uint) | (128 as c_uint)) as c_uint) | (8192 as c_uint)) as c_uint) | (65536 as c_uint)) as c_uint) | (131072 as c_uint)) as c_uint) | (524288 as c_uint)) as c_uint) | (2097152 as c_uint)) as c_uint) | (33554432 as c_uint)) as c_uint) | (67108864 as c_uint)) as c_uint) | (134217728 as c_uint)) as c_uint) | (536870912 as c_uint))) as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_25 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_25 = (if (if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & ((~(((((((2147483648 as c_uint) as c_uint) | (536870912 as c_uint)) as c_uint) | (32768 as c_uint)) as c_uint) | (1073741824 as c_uint))) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_25 != 0) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_180 {
        show_controls(31, (((&raw const pat_patctl as *const patctl).control as c_uint) & ((~((((((((((((((((((((32 as c_uint) | (128 as c_uint)) as c_uint) | (8192 as c_uint)) as c_uint) | (65536 as c_uint)) as c_uint) | (131072 as c_uint)) as c_uint) | (524288 as c_uint)) as c_uint) | (2097152 as c_uint)) as c_uint) | (33554432 as c_uint)) as c_uint) | (67108864 as c_uint)) as c_uint) | (134217728 as c_uint)) as c_uint) | (536870912 as c_uint))) as c_uint)), (((&raw const pat_patctl as *const patctl).control2 as c_uint) & ((~(((((((2147483648 as c_uint) as c_uint) | (536870912 as c_uint)) as c_uint) | (32768 as c_uint)) as c_uint) | (1073741824 as c_uint))) as c_uint)), "** Ignored when compiled pattern is stacked with 'push':")
        fprintf(outfile, "\n")
        goto '__ci_bb_181
    }

    '__ci_bb_181 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_26 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_26 = (if (if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (0 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_26 != 0) {
            goto '__ci_bb_182
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_182 {
        show_controls(31, (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)), (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (0 as c_uint)), "** Applies only to compile when pattern is stacked with 'push':")
        fprintf(outfile, "\n")
        goto '__ci_bb_183
    }

    '__ci_bb_183 {
        goto '__ci_bb_177
    }

    '__ci_bb_184 {
        (__local_convert_return__goto_2563_7 = PR_OK)
        (__local_convert_options__goto_2564_12 = (&raw const pat_patctl as *const patctl).convert_type)
        (__local_converted_length__goto_2566_14 = 3735928559)
        if ((if (&raw const pat_patctl as *const patctl).convert_length != 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_186
        } else {
            goto '__ci_bb_187
        }
    }

    '__ci_bb_185 {
        (__local_full_patlen__goto_2019_20 = __local_patlen__goto_2019_12)
        (__local_valgrind_access_length__goto_2020_12 = __local_patlen__goto_2019_12)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (((65536 as c_uint) | (536870912 as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_217
        } else {
            goto '__ci_bb_218
        }
    }

    '__ci_bb_186 {
        (__local_converted_length__goto_2566_14 = (&raw const pat_patctl as *const patctl).convert_length)
        (__ci_expr_ternary_27 = 0)
        if (__local_converted_length__goto_2566_14 != 0) {
            (__ci_expr_ternary_27 = ((__local_converted_length__goto_2566_14 as c_ulong) *% (1 as c_ulong)))
        } else {
            (__ci_expr_ternary_27 = 1)
        }
        (__local_converted_pattern__goto_2565_16 = ((with_alloc((__ci_expr_ternary_27 as i64)) as *mut c_void)))
        if ((if __local_converted_pattern__goto_2565_16 == null: 1 else: 0) != 0) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_187 {
        (__local_converted_pattern__goto_2565_16 = ((null as *mut u8)))
        goto '__ci_bb_188
    }

    '__ci_bb_188 {
        if (__local_utf__goto_2011_6 != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_189 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Failed: malloc failed for converted pattern\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_190 {
        goto '__ci_bb_188
    }

    '__ci_bb_191 {
        (__local_convert_options__goto_2564_12 = __local_convert_options__goto_2564_12 | 1)
        goto '__ci_bb_192
    }

    '__ci_bb_192 {
        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (1073741824 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_193
        } else {
            goto '__ci_bb_194
        }
    }

    '__ci_bb_193 {
        (__local_convert_options__goto_2564_12 = __local_convert_options__goto_2564_12 | 2)
        goto '__ci_bb_194
    }

    '__ci_bb_194 {
        with_memcpy((con_context_8 as *i8), (default_con_context_8 as *i8), (sizeof[pcre2_real_convert_context_8]() as i64))
        if ((if (&raw const pat_patctl as *const patctl).convert_glob_escape != 0: 1 else: 0) != 0) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_196
        }
    }

    '__ci_bb_195 {
        (__ci_expr_ternary_28 = 0)
        if ((if (&raw const pat_patctl as *const patctl).convert_glob_escape == 48: 1 else: 0) != 0) {
            (__ci_expr_ternary_28 = 0)
        } else {
            (__ci_expr_ternary_28 = (&raw const pat_patctl as *const patctl).convert_glob_escape)
        }
        (__local_escape__goto_2589_14 = __ci_expr_ternary_28)
        (__local_rc__goto_2015_5 = pcre2_set_glob_escape_8(con_context_8, __local_escape__goto_2589_14))
        if ((if __local_rc__goto_2015_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_197
        } else {
            goto '__ci_bb_198
        }
    }

    '__ci_bb_196 {
        if ((if (&raw const pat_patctl as *const patctl).convert_glob_separator != 0: 1 else: 0) != 0) {
            goto '__ci_bb_200
        } else {
            goto '__ci_bb_201
        }
    }

    '__ci_bb_197 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Invalid glob escape '%c'\n", (&raw const pat_patctl as *const patctl).convert_glob_escape)
        colour_end(outfile)
        (__local_convert_return__goto_2563_7 = PR_SKIP)
        goto '__ci_bb_199
    }

    '__ci_bb_198 {
        goto '__ci_bb_196
    }

    '__ci_bb_199 {
        if ((if (&raw const pat_patctl as *const patctl).convert_length != 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_212
        } else {
            goto '__ci_bb_213
        }
    }

    '__ci_bb_200 {
        (__local_separator__goto_2603_14 = (&raw const pat_patctl as *const patctl).convert_glob_separator)
        (__local_rc__goto_2015_5 = pcre2_set_glob_separator_8(con_context_8, __local_separator__goto_2603_14))
        if ((if __local_rc__goto_2015_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_202
        } else {
            goto '__ci_bb_203
        }
    }

    '__ci_bb_201 {
        (__local_zero_terminate__goto_2567_8 = (if (((&raw const pat_patctl as *const patctl).control as c_uint) & (((65536 as c_uint) | (536870912 as c_uint)) as c_uint)) == 0: 1 else: 0))
        if (__local_zero_terminate__goto_2567_8 != 0) {
            goto '__ci_bb_204
        } else {
            goto '__ci_bb_205
        }
    }

    '__ci_bb_202 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Invalid glob separator '%c'\n", (&raw const pat_patctl as *const patctl).convert_glob_separator)
        colour_end(outfile)
        (__local_convert_return__goto_2563_7 = PR_SKIP)
        goto '__ci_bb_199
    }

    '__ci_bb_203 {
        goto '__ci_bb_201
    }

    '__ci_bb_204 {
        (__local_patlen__goto_2019_12 = (~(0 as c_ulong)))
        goto '__ci_bb_205
    }

    '__ci_bb_205 {
        (__ci_expr_ternary_29 = null)
        if ((if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_29 = pbuffer8)
        } else {
            (__ci_expr_ternary_29 = ((null as *mut u8)))
        }
        (__local_use_pbuffer__goto_2017_12 = __ci_expr_ternary_29)
        (__local_rc__goto_2015_5 = pcre2_pattern_convert_8(__local_use_pbuffer__goto_2017_12, __local_patlen__goto_2019_12, __local_convert_options__goto_2564_12, (&raw mut __local_converted_pattern__goto_2565_16 as *mut *mut u8), (&raw mut __local_converted_length__goto_2566_14 as *mut c_ulong), con_context_8))
        if ((if __local_rc__goto_2015_5 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_206
        } else {
            goto '__ci_bb_207
        }
    }

    '__ci_bb_206 {
        colour_begin(35, outfile)
        fprintf(outfile, "** Pattern conversion error at offset %zu: ", __local_converted_length__goto_2566_14)
        colour_end(outfile)
        (__ci_expr_ternary_30 = 0)
        if (print_error_message_8(__local_rc__goto_2015_5, "", "\n") != 0) {
            (__ci_expr_ternary_30 = PR_SKIP)
        } else {
            (__ci_expr_ternary_30 = PR_ABEND)
        }
        (__local_convert_return__goto_2563_7 = __ci_expr_ternary_30)
        goto '__ci_bb_208
    }

    '__ci_bb_207 {
        pchars_8(-1, __local_converted_pattern__goto_2565_16, __local_converted_length__goto_2566_14, __local_utf__goto_2011_6, outfile)
        fprintf(outfile, "\n")
        if ((if ((((__local_converted_length__goto_2566_14 as c_ulong) +% (1 as c_ulong)) as c_ulong) *% (1 as c_ulong)) > pbuffer8_size: 1 else: 0) != 0) {
            goto '__ci_bb_209
        } else {
            goto '__ci_bb_210
        }
    }

    '__ci_bb_208 {
        goto '__ci_bb_199
    }

    '__ci_bb_209 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Pattern conversion is too long for the buffer\n")
        colour_end(outfile)
        (__local_convert_return__goto_2563_7 = PR_SKIP)
        goto '__ci_bb_211
    }

    '__ci_bb_210 {
        with_memcpy((pbuffer8 as *i8), (__local_converted_pattern__goto_2565_16 as *i8), (((((__local_converted_length__goto_2566_14 as c_ulong) +% (1 as c_ulong)) as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_patlen__goto_2019_12 = __local_converted_length__goto_2566_14)
        goto '__ci_bb_211
    }

    '__ci_bb_211 {
        goto '__ci_bb_208
    }

    '__ci_bb_212 {
        with_free((__local_converted_pattern__goto_2565_16 as *mut i8))
        goto '__ci_bb_214
    }

    '__ci_bb_213 {
        pcre2_converted_pattern_free_8(__local_converted_pattern__goto_2565_16)
        goto '__ci_bb_214
    }

    '__ci_bb_214 {
        if ((if __local_convert_return__goto_2563_7 != PR_OK: 1 else: 0) != 0) {
            goto '__ci_bb_215
        } else {
            goto '__ci_bb_216
        }
    }

    '__ci_bb_215 {
        return __local_convert_return__goto_2563_7
    }

    '__ci_bb_216 {
        goto '__ci_bb_185
    }

    '__ci_bb_217 {
        (__local_patlen__goto_2019_12 = (~(0 as c_ulong)))
        (__local_valgrind_access_length__goto_2020_12 = __local_valgrind_access_length__goto_2020_12 + 1)
        goto '__ci_bb_218
    }

    '__ci_bb_218 {
        __local_valgrind_access_length__goto_2020_12
        (__ci_expr_logic_31 = 0)
        if ((if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (1073741824 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_31 = (if (if local_newline_default != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_31 != 0) {
            goto '__ci_bb_219
        } else {
            goto '__ci_bb_220
        }
    }

    '__ci_bb_219 {
        pcre2_set_newline_8(pat_context_8, local_newline_default)
        goto '__ci_bb_220
    }

    '__ci_bb_220 {
        (__ci_expr_ternary_32 = null)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (4194304 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_32 = ((null as *mut pcre2_real_compile_context_8)))
        } else {
            (__ci_expr_ternary_32 = pat_context_8)
        }
        (__local_use_pat_context__goto_2016_24 = __ci_expr_ternary_32)
        if ((if (((&raw const pat_patctl as *const patctl).options as c_uint) & (33554432 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_221
        } else {
            goto '__ci_bb_222
        }
    }

    '__ci_bb_221 {
        (__local_use_forbid_utf__goto_2018_10 = 0)
        goto '__ci_bb_222
    }

    '__ci_bb_222 {
        (__ci_expr_ternary_33 = null)
        if ((if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_33 = pbuffer8)
        } else {
            (__ci_expr_ternary_33 = ((null as *mut u8)))
        }
        (__local_use_pbuffer__goto_2017_12 = __ci_expr_ternary_33)
        if ((if timeit > 0: 1 else: 0) != 0) {
            goto '__ci_bb_223
        } else {
            goto '__ci_bb_224
        }
    }

    '__ci_bb_223 {
        (__local_time_taken__goto_2724_11 = 0)
        (__local_i__goto_2723_7 = 0)
        goto '__ci_bb_225
    }

    '__ci_bb_224 {
        (mallocs_called = 0)
        (compiled_code_8 = pcre2_compile_8(__local_use_pbuffer__goto_2017_12, __local_patlen__goto_2019_12, (((&raw const pat_patctl as *const patctl).options as c_uint) | (__local_use_forbid_utf__goto_2018_10 as c_uint)), (&raw mut __local_errorcode__goto_2015_9 as *mut c_int), (&raw mut __local_erroroffset__goto_2021_12 as *mut c_ulong), __local_use_pat_context__goto_2016_24))
        if (malloc_testing != 0) {
            goto '__ci_bb_231
        } else {
            goto '__ci_bb_232
        }
    }

    '__ci_bb_225 {
        if ((if __local_i__goto_2723_7 < timeit: 1 else: 0) != 0) {
            goto '__ci_bb_226
        } else {
            goto '__ci_bb_228
        }
    }

    '__ci_bb_226 {
        (__local_start_time__goto_2727_13 = clock())
        (compiled_code_8 = pcre2_compile_8(__local_use_pbuffer__goto_2017_12, __local_patlen__goto_2019_12, (((&raw const pat_patctl as *const patctl).options as c_uint) | (__local_use_forbid_utf__goto_2018_10 as c_uint)), (&raw mut __local_errorcode__goto_2015_9 as *mut c_int), (&raw mut __local_erroroffset__goto_2021_12 as *mut c_ulong), __local_use_pat_context__goto_2016_24))
        (__local_time_taken__goto_2724_11 = __local_time_taken__goto_2724_11 + ((clock() as c_ulong) -% (__local_start_time__goto_2727_13 as c_ulong)))
        if ((if compiled_code_8 != null: 1 else: 0) != 0) {
            goto '__ci_bb_229
        } else {
            goto '__ci_bb_230
        }
    }

    '__ci_bb_227 {
        (__local_i__goto_2723_7 = __local_i__goto_2723_7 + 1)
        goto '__ci_bb_225
    }

    '__ci_bb_228 {
        (total_compile_time = total_compile_time + __local_time_taken__goto_2724_11)
        colour_begin(36, outfile)
        fprintf(outfile, "Compile time %8.4f microseconds\n", ((((1000000 as c_ulong) / ((1000000 as c_ulong) as c_ulong)) * (__local_time_taken__goto_2724_11 as f64)) / timeit))
        colour_end(outfile)
        goto '__ci_bb_224
    }

    '__ci_bb_229 {
        pcre2_code_free_8(compiled_code_8)
        goto '__ci_bb_230
    }

    '__ci_bb_230 {
        goto '__ci_bb_227
    }

    '__ci_bb_231 {
        (__local_i__goto_2750_12 = 0)
        (__local_target_mallocs__goto_2750_19 = mallocs_called)
        goto '__ci_bb_233
    }

    '__ci_bb_232 {
        (__ci_expr_logic_36 = 0)
        if ((if compiled_code_8 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_36 = (if (if (&raw const pat_patctl as *const patctl).jit != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_36 != 0) {
            goto '__ci_bb_241
        } else {
            goto '__ci_bb_242
        }
    }

    '__ci_bb_233 {
        if ((if __local_i__goto_2750_12 <= __local_target_mallocs__goto_2750_19: 1 else: 0) != 0) {
            goto '__ci_bb_234
        } else {
            goto '__ci_bb_236
        }
    }

    '__ci_bb_234 {
        if ((if compiled_code_8 != null: 1 else: 0) != 0) {
            goto '__ci_bb_237
        } else {
            goto '__ci_bb_238
        }
    }

    '__ci_bb_235 {
        (__local_i__goto_2750_12 = __local_i__goto_2750_12 + 1)
        goto '__ci_bb_233
    }

    '__ci_bb_236 {
        goto '__ci_bb_232
    }

    '__ci_bb_237 {
        pcre2_code_free_8(compiled_code_8)
        goto '__ci_bb_238
    }

    '__ci_bb_238 {
        (__local_errorcode__goto_2015_9 = 0)
        (__local_erroroffset__goto_2021_12 = 0)
        (mallocs_until_failure = __local_i__goto_2750_12)
        (compiled_code_8 = pcre2_compile_8(__local_use_pbuffer__goto_2017_12, __local_patlen__goto_2019_12, (((&raw const pat_patctl as *const patctl).options as c_uint) | (__local_use_forbid_utf__goto_2018_10 as c_uint)), (&raw mut __local_errorcode__goto_2015_9 as *mut c_int), (&raw mut __local_erroroffset__goto_2021_12 as *mut c_ulong), __local_use_pat_context__goto_2016_24))
        (mallocs_until_failure = 2147483647)
        (__ci_expr_logic_35 = 0)
        if ((if __local_i__goto_2750_12 < __local_target_mallocs__goto_2750_19: 1 else: 0) != 0) {
            var __ci_expr_logic_34: c_int = 0

            if ((if compiled_code_8 == null: 1 else: 0) != 0) {
                (__ci_expr_logic_34 = (if (if __local_errorcode__goto_2015_9 == 121: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_35 = (if (if not (__ci_expr_logic_34 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_35 != 0) {
            goto '__ci_bb_239
        } else {
            goto '__ci_bb_240
        }
    }

    '__ci_bb_239 {
        colour_begin(31, outfile)
        fprintf(outfile, "** malloc() compile test did not fail as expected (%d)\n", __local_errorcode__goto_2015_9)
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_240 {
        goto '__ci_bb_235
    }

    '__ci_bb_241 {
        if ((if timeit > 0: 1 else: 0) != 0) {
            goto '__ci_bb_243
        } else {
            goto '__ci_bb_244
        }
    }

    '__ci_bb_242 {
        if ((if compiled_code_8 == null: 1 else: 0) != 0) {
            goto '__ci_bb_271
        } else {
            goto '__ci_bb_272
        }
    }

    '__ci_bb_243 {
        (__local_time_taken__goto_2790_13 = 0)
        (__local_i__goto_2789_9 = 0)
        goto '__ci_bb_245
    }

    '__ci_bb_244 {
        (mallocs_called = 0)
        (jitrc = pcre2_jit_compile_8(compiled_code_8, (&raw const pat_patctl as *const patctl).jit))
        if (malloc_testing != 0) {
            goto '__ci_bb_257
        } else {
            goto '__ci_bb_258
        }
    }

    '__ci_bb_245 {
        if ((if __local_i__goto_2789_9 < timeit: 1 else: 0) != 0) {
            goto '__ci_bb_246
        } else {
            goto '__ci_bb_248
        }
    }

    '__ci_bb_246 {
        (__local_start_time__goto_2794_15 = clock())
        (jitrc = pcre2_jit_compile_8(compiled_code_8, (&raw const pat_patctl as *const patctl).jit))
        (__local_time_taken__goto_2790_13 = __local_time_taken__goto_2790_13 + ((clock() as c_ulong) -% (__local_start_time__goto_2794_15 as c_ulong)))
        pcre2_code_free_8(compiled_code_8)
        (compiled_code_8 = pcre2_compile_8(__local_use_pbuffer__goto_2017_12, __local_patlen__goto_2019_12, (((&raw const pat_patctl as *const patctl).options as c_uint) | (__local_use_forbid_utf__goto_2018_10 as c_uint)), (&raw mut __local_errorcode__goto_2015_9 as *mut c_int), (&raw mut __local_erroroffset__goto_2021_12 as *mut c_ulong), __local_use_pat_context__goto_2016_24))
        if ((if compiled_code_8 == null: 1 else: 0) != 0) {
            goto '__ci_bb_249
        } else {
            goto '__ci_bb_250
        }
    }

    '__ci_bb_247 {
        (__local_i__goto_2789_9 = __local_i__goto_2789_9 + 1)
        goto '__ci_bb_245
    }

    '__ci_bb_248 {
        (total_jit_compile_time = total_jit_compile_time + __local_time_taken__goto_2790_13)
        if ((if jitrc == 0: 1 else: 0) != 0) {
            goto '__ci_bb_255
        } else {
            goto '__ci_bb_256
        }
    }

    '__ci_bb_249 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unexpected - pattern compilation not successful\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_250 {
        if ((if jitrc != 0: 1 else: 0) != 0) {
            goto '__ci_bb_251
        } else {
            goto '__ci_bb_252
        }
    }

    '__ci_bb_251 {
        colour_begin(35, outfile)
        fprintf(outfile, "JIT compilation was not successful")
        colour_end(outfile)
        if ((if not (print_error_message_8(jitrc, " (", ")\n") != 0): 1 else: 0) != 0) {
            goto '__ci_bb_253
        } else {
            goto '__ci_bb_254
        }
    }

    '__ci_bb_252 {
        goto '__ci_bb_247
    }

    '__ci_bb_253 {
        return PR_ABEND
    }

    '__ci_bb_254 {
        goto '__ci_bb_248
    }

    '__ci_bb_255 {
        colour_begin(36, outfile)
        fprintf(outfile, "JIT compile  %8.4f microseconds\n", ((((1000000 as c_ulong) / ((1000000 as c_ulong) as c_ulong)) * (__local_time_taken__goto_2790_13 as f64)) / timeit))
        colour_end(outfile)
        goto '__ci_bb_256
    }

    '__ci_bb_256 {
        goto '__ci_bb_244
    }

    '__ci_bb_257 {
        (__local_i__goto_2828_14 = 0)
        (__local_target_mallocs__goto_2828_21 = mallocs_called)
        goto '__ci_bb_259
    }

    '__ci_bb_258 {
        (__ci_expr_logic_38 = 0)
        if ((if jitrc != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_38 = (if (if (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_38 != 0) {
            goto '__ci_bb_267
        } else {
            goto '__ci_bb_268
        }
    }

    '__ci_bb_259 {
        if ((if __local_i__goto_2828_14 <= __local_target_mallocs__goto_2828_21: 1 else: 0) != 0) {
            goto '__ci_bb_260
        } else {
            goto '__ci_bb_262
        }
    }

    '__ci_bb_260 {
        pcre2_code_free_8(compiled_code_8)
        (compiled_code_8 = pcre2_compile_8(__local_use_pbuffer__goto_2017_12, __local_patlen__goto_2019_12, (((&raw const pat_patctl as *const patctl).options as c_uint) | (__local_use_forbid_utf__goto_2018_10 as c_uint)), (&raw mut __local_errorcode__goto_2015_9 as *mut c_int), (&raw mut __local_erroroffset__goto_2021_12 as *mut c_ulong), __local_use_pat_context__goto_2016_24))
        if ((if compiled_code_8 == null: 1 else: 0) != 0) {
            goto '__ci_bb_263
        } else {
            goto '__ci_bb_264
        }
    }

    '__ci_bb_261 {
        (__local_i__goto_2828_14 = __local_i__goto_2828_14 + 1)
        goto '__ci_bb_259
    }

    '__ci_bb_262 {
        goto '__ci_bb_258
    }

    '__ci_bb_263 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unexpected - pattern compilation not successful\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_264 {
        (mallocs_until_failure = __local_i__goto_2828_14)
        (jitrc = pcre2_jit_compile_8(compiled_code_8, (&raw const pat_patctl as *const patctl).jit))
        (mallocs_until_failure = 2147483647)
        (__ci_expr_logic_37 = 0)
        if ((if __local_i__goto_2828_14 < __local_target_mallocs__goto_2828_21: 1 else: 0) != 0) {
            (__ci_expr_logic_37 = (if (if jitrc != -48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_37 != 0) {
            goto '__ci_bb_265
        } else {
            goto '__ci_bb_266
        }
    }

    '__ci_bb_265 {
        colour_begin(31, outfile)
        fprintf(outfile, "** malloc() JIT compile test did not fail as expected (%d)\n", jitrc)
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_266 {
        goto '__ci_bb_261
    }

    '__ci_bb_267 {
        colour_begin(35, outfile)
        fprintf(outfile, "JIT compilation was not successful")
        colour_end(outfile)
        if ((if not (print_error_message_8(jitrc, " (", ")\n") != 0): 1 else: 0) != 0) {
            goto '__ci_bb_269
        } else {
            goto '__ci_bb_270
        }
    }

    '__ci_bb_268 {
        goto '__ci_bb_242
    }

    '__ci_bb_269 {
        return PR_ABEND
    }

    '__ci_bb_270 {
        goto '__ci_bb_268
    }

    '__ci_bb_271 {
        (__local_direction__goto_2868_7 = error_direction(__local_errorcode__goto_2015_9, __local_erroroffset__goto_2021_12))
        colour_begin(35, outfile)
        fprintf(outfile, "Failed: error %d at offset %d: ", __local_errorcode__goto_2015_9, (__local_erroroffset__goto_2021_12 as c_int))
        colour_end(outfile)
        if ((if not (print_error_message_8(__local_errorcode__goto_2015_9, "", "\n") != 0): 1 else: 0) != 0) {
            goto '__ci_bb_273
        } else {
            goto '__ci_bb_274
        }
    }

    '__ci_bb_272 {
        if ((if forbid_utf != 0: 1 else: 0) != 0) {
            goto '__ci_bb_295
        } else {
            goto '__ci_bb_296
        }
    }

    '__ci_bb_273 {
        return PR_ABEND
    }

    '__ci_bb_274 {
        if (__local_utf__goto_2011_6 != 0) {
            goto '__ci_bb_275
        } else {
            goto '__ci_bb_276
        }
    }

    '__ci_bb_275 {
        (__local_n__goto_2884_9 = 1)
        (__local_q__goto_2885_23 = pbuffer8)
        (__local_q_end__goto_2885_37 = __local_q__goto_2885_23 + (__local_erroroffset__goto_2021_12 as usize))
        goto '__ci_bb_277
    }

    '__ci_bb_276 {
        if ((if __local_direction__goto_2868_7 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_283
        } else {
            goto '__ci_bb_284
        }
    }

    '__ci_bb_277 {
        (__ci_expr_logic_39 = 0)
        if ((if __local_q__goto_2885_23 < __local_q_end__goto_2885_37: 1 else: 0) != 0) {
            (__ci_expr_logic_39 = (if (if __local_n__goto_2884_9 > 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_39 != 0) {
            goto '__ci_bb_278
        } else {
            goto '__ci_bb_280
        }
    }

    '__ci_bb_278 {
        (__local_n__goto_2884_9 = utf8_to_ord(__local_q__goto_2885_23, __local_q_end__goto_2885_37, (&raw mut __local_cc__goto_2883_14 as *mut c_uint)))
        goto '__ci_bb_279
    }

    '__ci_bb_279 {
        (__local_q__goto_2885_23 = __local_q__goto_2885_23 + ((__local_n__goto_2884_9 as isize) as usize))
        goto '__ci_bb_277
    }

    '__ci_bb_280 {
        if ((if __local_n__goto_2884_9 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_282
        }
    }

    '__ci_bb_281 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Erroroffset %d splits a UTF character\n", (__local_erroroffset__goto_2021_12 as c_int))
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_282 {
        goto '__ci_bb_276
    }

    '__ci_bb_283 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Error code %d not implemented in error_direction().\n", __local_errorcode__goto_2015_9)
        colour_end(outfile)
        colour_begin(31, outfile)
        fprintf(outfile, "   error_direction() should usually return '1' for newly-added errors,\n")
        colour_end(outfile)
        colour_begin(31, outfile)
        fprintf(outfile, "   and the offset should be just to the right of the bad character.\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_284 {
        if ((if __local_direction__goto_2868_7 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_286
        } else {
            goto '__ci_bb_287
        }
    }

    '__ci_bb_285 {
        return PR_SKIP
    }

    '__ci_bb_286 {
        colour_begin(35, outfile)
        fprintf(outfile, "        here: ")
        colour_end(outfile)
        if ((if __local_erroroffset__goto_2021_12 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_289
        } else {
            goto '__ci_bb_290
        }
    }

    '__ci_bb_287 {
        if ((if __local_erroroffset__goto_2021_12 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_293
        } else {
            goto '__ci_bb_294
        }
    }

    '__ci_bb_288 {
        goto '__ci_bb_285
    }

    '__ci_bb_289 {
        ptrunc_8(32, pbuffer8, __local_full_patlen__goto_2019_20, __local_erroroffset__goto_2021_12, 1, __local_utf__goto_2011_6, outfile)
        fprintf(outfile, " ")
        goto '__ci_bb_290
    }

    '__ci_bb_290 {
        (__ci_expr_ternary_41 = null)
        if ((if __local_direction__goto_2868_7 == 1: 1 else: 0) != 0) {
            (__ci_expr_ternary_41 = (("|<--|" as *mut c_char)))
        } else {
            var __ci_expr_ternary_40: *mut c_char = null

            if ((if __local_direction__goto_2868_7 == 2: 1 else: 0) != 0) {
                (__ci_expr_ternary_40 = (("|-->|" as *mut c_char)))
            } else {
                (__ci_expr_ternary_40 = (("|<-->|" as *mut c_char)))
            }

            (__ci_expr_ternary_41 = ((__ci_expr_ternary_40 as *mut c_char)))

        }
        colour_begin(35, outfile)
        fprintf(outfile, __ci_expr_ternary_41)
        colour_end(outfile)
        if ((if __local_erroroffset__goto_2021_12 < __local_full_patlen__goto_2019_20: 1 else: 0) != 0) {
            goto '__ci_bb_291
        } else {
            goto '__ci_bb_292
        }
    }

    '__ci_bb_291 {
        fprintf(outfile, " ")
        ptrunc_8(32, pbuffer8, __local_full_patlen__goto_2019_20, __local_erroroffset__goto_2021_12, 0, __local_utf__goto_2011_6, outfile)
        goto '__ci_bb_292
    }

    '__ci_bb_292 {
        fprintf(outfile, "\n")
        goto '__ci_bb_288
    }

    '__ci_bb_293 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unexpected non-zero erroroffset %d for error code %d\n", (__local_erroroffset__goto_2021_12 as c_int), __local_errorcode__goto_2015_9)
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_294 {
        goto '__ci_bb_288
    }

    '__ci_bb_295 {
        if ((if ((compiled_code_8.flags as c_uint) & (1048576 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_297
        } else {
            goto '__ci_bb_298
        }
    }

    '__ci_bb_296 {
        if ((if pattern_info_8(15, (&raw mut maxlookbehind as *mut c_uint), 0) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_299
        } else {
            goto '__ci_bb_300
        }
    }

    '__ci_bb_297 {
        colour_begin(31, outfile)
        fprintf(outfile, "** \\P, \\p, and \\X are not allowed after the #forbid_utf command\n")
        colour_end(outfile)
        return PR_SKIP
    }

    '__ci_bb_298 {
        goto '__ci_bb_296
    }

    '__ci_bb_299 {
        return PR_ABEND
    }

    '__ci_bb_300 {
        if ((if pattern_info_8(4, (&raw mut maxcapcount as *mut c_uint), 0) < 0: 1 else: 0) != 0) {
            goto '__ci_bb_301
        } else {
            goto '__ci_bb_302
        }
    }

    '__ci_bb_301 {
        return PR_ABEND
    }

    '__ci_bb_302 {
        if ((if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (1073741824 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_303
        } else {
            goto '__ci_bb_304
        }
    }

    '__ci_bb_303 {
        ((unsafe: *compiled_code_8).flags = compiled_code_8.flags | 32768)
        goto '__ci_bb_304
    }

    '__ci_bb_304 {
        (__local_rc__goto_2015_5 = show_pattern_info_8())
        if ((if __local_rc__goto_2015_5 != PR_OK: 1 else: 0) != 0) {
            goto '__ci_bb_305
        } else {
            goto '__ci_bb_306
        }
    }

    '__ci_bb_305 {
        return __local_rc__goto_2015_5
    }

    '__ci_bb_306 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (33554432 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_307
        } else {
            goto '__ci_bb_308
        }
    }

    '__ci_bb_307 {
        if ((if patstacknext_8 >= 20: 1 else: 0) != 0) {
            goto '__ci_bb_309
        } else {
            goto '__ci_bb_310
        }
    }

    '__ci_bb_308 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (((67108864 as c_uint) | (134217728 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_312
        }
    }

    '__ci_bb_309 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Too many pushed patterns (max %d)\n", 20)
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_310 {
        (__ci_expr_old_42 = patstacknext_8)
        (patstacknext_8 = patstacknext_8 + 1)
        (patstack_8[__ci_expr_old_42] = compiled_code_8)
        (compiled_code_8 = ((null as *mut pcre2_real_code_8)))
        goto '__ci_bb_308
    }

    '__ci_bb_311 {
        if ((if patstacknext_8 >= 20: 1 else: 0) != 0) {
            goto '__ci_bb_313
        } else {
            goto '__ci_bb_314
        }
    }

    '__ci_bb_312 {
        return PR_OK
    }

    '__ci_bb_313 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Too many pushed patterns (max %d)\n", 20)
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_314 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (67108864 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_315
        } else {
            goto '__ci_bb_316
        }
    }

    '__ci_bb_315 {
        (__ci_expr_old_43 = patstacknext_8)
        (patstacknext_8 = patstacknext_8 + 1)
        (patstack_8[__ci_expr_old_43] = pcre2_code_copy_8(compiled_code_8))
        goto '__ci_bb_317
    }

    '__ci_bb_316 {
        (__ci_expr_old_44 = patstacknext_8)
        (patstacknext_8 = patstacknext_8 + 1)
        (patstack_8[__ci_expr_old_44] = pcre2_code_copy_with_tables_8(compiled_code_8))
        goto '__ci_bb_317
    }

    '__ci_bb_317 {
        goto '__ci_bb_312
    }

}

fn have_active_pattern_8() -> c_int {
    return (if compiled_code_8 != null: 1 else: 0)

}

fn free_active_pattern_8() {
    pcre2_code_free_8(compiled_code_8)

    (compiled_code_8 = ((null as *mut pcre2_real_code_8)))

}

fn check_match_limit_8(__param_pp: *const u8, __param_ulen: c_ulong, __param_errnumber: c_int, __param_msg: *const i8) -> c_int {
    var __local_capcount: c_int

    var __local_min: c_uint = 0

    var __local_mid: c_uint = 64

    var __local_max: c_uint = 4294967295

    var __local_saved_outfile: *mut c_void = outfile

    pcre2_set_match_limit_8(dat_context_8, __local_max)

    pcre2_set_depth_limit_8(dat_context_8, __local_max)

    pcre2_set_heap_limit_8(dat_context_8, __local_max)

    while true {
        var __local_stack_start: c_uint = 0

        if ((if __param_errnumber == -63: 1 else: 0) != 0) {
            pcre2_set_heap_limit_8(dat_context_8, __local_mid)

            (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).free(match_data_8.heapframes, (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).memory_data)

            ((unsafe: *match_data_8).heapframes = ((null as *mut heapframe)))

            ((unsafe: *match_data_8).heapframes_size = 0)

        } else {
            if ((if __param_errnumber == -47: 1 else: 0) != 0) {
                pcre2_set_match_limit_8(dat_context_8, __local_mid)

            } else {
                pcre2_set_depth_limit_8(dat_context_8, __local_mid)

            }
        }

        reset_callout_state()

        (outfile = null)

        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            (__local_stack_start = 30)

            if ((if dfa_workspace == null: 1 else: 0) != 0) {
                (dfa_workspace = (((with_alloc((((1000 as c_ulong) *% (sizeof[c_int]() as c_ulong)) as i64)) as *mut c_void) as *mut c_int)))
            }

            var __ci_expr_old_0: c_uint = dfa_matched

            (dfa_matched = dfa_matched + 1)

            if ((if __ci_expr_old_0 == 0: 1 else: 0) != 0) {
                ((unsafe: dfa_workspace[0]) = -1)
            }


            (__local_capcount = pcre2_dfa_match_8(compiled_code_8, __param_pp, __param_ulen, (&raw const dat_datctl as *const datctl).offset, (&raw const dat_datctl as *const datctl).options, match_data_8, dat_context_8, dfa_workspace, 1000))

        } else {
            if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (262144 as c_uint)) != 0: 1 else: 0) != 0) {
                (__local_capcount = pcre2_jit_match_8(compiled_code_8, __param_pp, __param_ulen, (&raw const dat_datctl as *const datctl).offset, (&raw const dat_datctl as *const datctl).options, match_data_8, dat_context_8))
            } else {
                (__local_capcount = pcre2_match_8(compiled_code_8, __param_pp, __param_ulen, (&raw const dat_datctl as *const datctl).offset, (&raw const dat_datctl as *const datctl).options, match_data_8, dat_context_8))

            }
        }

        (outfile = __local_saved_outfile)

        if ((if __local_capcount == __param_errnumber: 1 else: 0) != 0) {
            if ((if ((__local_mid as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
                colour_begin(31, outfile)

                fprintf(outfile, "** Can't find minimum %s limit: check pattern for restriction\n", __param_msg)

                colour_end(outfile)


                break

            }

            (__local_min = __local_mid)

            var __ci_expr_ternary_2: c_uint = 0

            if ((if __local_mid == ((__local_max as c_uint) -% (1 as c_uint)): 1 else: 0) != 0) {
                (__ci_expr_ternary_2 = __local_max)
            } else {
                var __ci_expr_ternary_1: c_uint = 0

                if ((if __local_max != 4294967295: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = (((__local_min as c_uint) +% (__local_max as c_uint)) as c_uint) / (2 as c_uint))
                } else {
                    (__ci_expr_ternary_1 = ((__local_mid as c_uint) *% (2 as c_uint)))
                }

                (__ci_expr_ternary_2 = __ci_expr_ternary_1)

            }

            (__local_mid = __ci_expr_ternary_2)


        } else {
            var __ci_expr_logic_4: c_int

            var __ci_expr_logic_3: c_int

            if ((if __local_capcount >= 0: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if __local_capcount == -1: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if __local_capcount == -2: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_4 != 0) {
                var __ci_expr_logic_5: c_int = 0

                if ((if __param_errnumber == -63: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if (if __local_mid < __local_stack_start: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_5 != 0) {
                    fprintf(outfile, "Minimum %s limit = 0\n", __param_msg)

                    break

                }


                if ((if __local_mid == ((__local_min as c_uint) +% (1 as c_uint)): 1 else: 0) != 0) {
                    fprintf(outfile, "Minimum %s limit = %d\n", __param_msg, __local_mid)

                    break

                }

                (__local_max = __local_mid)

                (__local_mid = (((__local_min as c_uint) +% (__local_max as c_uint)) as c_uint) / (2 as c_uint))

            } else {
                break
            }

        }

    }

    return __local_capcount

}

fn substitute_callout_function_8(__param_scb: *mut pcre2_substitute_callout_block_8, __param_data_ptr: *mut c_void) -> c_int {
    var __local_yield___goto_3177_5: c_int = 0

    var __local_utf__goto_3178_6: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_yield___goto_3177_5 = 0)
        (__local_utf__goto_3178_6 = (if ((compiled_code_8.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))
        __param_data_ptr
        if ((if outfile == null: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        goto '__ci_bb_3
    }

    '__ci_bb_2 {
        fprintf(outfile, "%2d(%d) Old %zu %zu \"", __param_scb.subscount, __param_scb.oveccount, (unsafe: __param_scb.ovector[0]), (unsafe: __param_scb.ovector[1]))
        pchars_8(-1, (__param_scb.input + ((unsafe: __param_scb.ovector[0]) as usize)), (((unsafe: __param_scb.ovector[1]) as c_ulong) -% ((unsafe: __param_scb.ovector[0]) as c_ulong)), __local_utf__goto_3178_6, outfile)
        fprintf(outfile, "\" New %zu %zu \"", __param_scb.output_offsets[0], __param_scb.output_offsets[1])
        pchars_8(-1, (__param_scb.output + (__param_scb.output_offsets[0] as usize)), ((__param_scb.output_offsets[1] as c_ulong) -% (__param_scb.output_offsets[0] as c_ulong)), __local_utf__goto_3178_6, outfile)
        goto '__ci_bb_3
    }

    '__ci_bb_3 {
        if ((if __param_scb.subscount == (&raw const dat_datctl as *const datctl).substitute_stop: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        (__local_yield___goto_3177_5 = -1)
        if ((if outfile != null: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_5 {
        if ((if __param_scb.subscount == (&raw const dat_datctl as *const datctl).substitute_skip: 1 else: 0) != 0) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_6 {
        if ((if outfile != null: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_7 {
        fprintf(outfile, " STOPPED")
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        goto '__ci_bb_6
    }

    '__ci_bb_9 {
        (__local_yield___goto_3177_5 = 1)
        if ((if outfile != null: 1 else: 0) != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_10 {
        goto '__ci_bb_6
    }

    '__ci_bb_11 {
        fprintf(outfile, " SKIPPED")
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        goto '__ci_bb_10
    }

    '__ci_bb_13 {
        fprintf(outfile, "\"\n")
        goto '__ci_bb_14
    }

    '__ci_bb_14 {
        return __local_yield___goto_3177_5
    }

}

fn substitute_case_callout_function_8(__param_input: *const u8, __param_input_len: c_ulong, __param_output: *mut u8, __param_output_cap: c_ulong, __param_to_case: c_int, __param_data_ptr: *mut c_void) -> c_ulong {
    var __local_to_case = __param_to_case
    var __local_buf__goto_3240_13: [16]u8

    var __local_input_copy__goto_3241_12: *const u8 = null

    var __local_written__goto_3242_12: c_ulong = 0

    var __local_input_buf__goto_3248_16: *mut u8 = null

    var __local_i__goto_3259_17: c_ulong = 0

    var __local_num_in__goto_3261_7: c_int = 0

    var __local_c1__goto_3262_12: c_uint = 0

    var __local_c2__goto_3263_12: c_uint = 0

    var __local_num_read__goto_3264_7: c_int = 0

    var __local_num_write__goto_3265_7: c_int = 0

    var __ci_expr_ternary_0: c_int = 0

    var __ci_expr_ternary_1: c_int = 0

    var __ci_expr_old_2: c_ulong = 0

    var __ci_expr_old_3: c_ulong = 0

    var __ci_expr_ternary_4: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_written__goto_3242_12 = 0)
        __param_data_ptr
        if ((if __param_input_len > (((16 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        (__local_input_buf__goto_3248_16 = (((with_alloc((((__param_input_len as c_ulong) *% (1 as c_ulong)) as i64)) as *mut c_void) as *mut u8)))
        if ((if __local_input_buf__goto_3248_16 == null: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_2 {
        with_memcpy(((&(unsafe: __local_buf__goto_3240_13[0]) as *mut u8) as *i8), (__param_input as *i8), (((__param_input_len as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_input_copy__goto_3241_12 = (&(unsafe: __local_buf__goto_3240_13[0]) as *mut u8))
        goto '__ci_bb_3
    }

    '__ci_bb_3 {
        (__local_i__goto_3259_17 = 0)
        goto '__ci_bb_6
    }

    '__ci_bb_4 {
        return (~(0 as c_ulong))
    }

    '__ci_bb_5 {
        with_memcpy((__local_input_buf__goto_3248_16 as *i8), (__param_input as *i8), (((__param_input_len as c_ulong) *% (1 as c_ulong)) as i64))
        (__local_input_copy__goto_3241_12 = __local_input_buf__goto_3248_16)
        goto '__ci_bb_3
    }

    '__ci_bb_6 {
        if ((if __local_i__goto_3259_17 < __param_input_len: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_7 {
        (__ci_expr_ternary_0 = 0)
        if ((if ((__local_i__goto_3259_17 as c_ulong) +% (1 as c_ulong)) < __param_input_len: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = 2)
        } else {
            (__ci_expr_ternary_0 = 1)
        }
        (__local_num_in__goto_3261_7 = __ci_expr_ternary_0)
        (__local_c1__goto_3262_12 = (unsafe: __local_input_copy__goto_3241_12[__local_i__goto_3259_17]))
        (__ci_expr_ternary_1 = 0)
        if ((if ((__local_i__goto_3259_17 as c_ulong) +% (1 as c_ulong)) < __param_input_len: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = (unsafe: __local_input_copy__goto_3241_12[((__local_i__goto_3259_17 as c_ulong) +% (1 as c_ulong))]))
        } else {
            (__ci_expr_ternary_1 = 0)
        }
        (__local_c2__goto_3263_12 = __ci_expr_ternary_1)
        if ((if not (case_transform(__local_to_case, __local_num_in__goto_3261_7, (&raw mut __local_num_read__goto_3264_7 as *mut c_int), (&raw mut __local_num_write__goto_3265_7 as *mut c_int), (&raw mut __local_c1__goto_3262_12 as *mut c_uint), (&raw mut __local_c2__goto_3263_12 as *mut c_uint)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_8 {
        goto '__ci_bb_6
    }

    '__ci_bb_9 {
        goto '__ci_bb_12
    }

    '__ci_bb_10 {
        (__local_written__goto_3242_12 = (~(0 as c_ulong)))
        goto '__ci_bb_12
    }

    '__ci_bb_11 {
        (__local_i__goto_3259_17 = __local_i__goto_3259_17 + __local_num_read__goto_3264_7)
        if ((if __local_to_case == 3: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_12 {
        if ((if __local_input_copy__goto_3241_12 != (&(unsafe: __local_buf__goto_3240_13[0]) as *mut u8): 1 else: 0) != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_13 {
        (__local_to_case = 1)
        goto '__ci_bb_14
    }

    '__ci_bb_14 {
        if ((if ((__local_written__goto_3242_12 as c_ulong) +% (__local_num_write__goto_3265_7 as c_ulong)) > __param_output_cap: 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_15 {
        (__local_written__goto_3242_12 = __local_written__goto_3242_12 + __local_num_write__goto_3265_7)
        goto '__ci_bb_17
    }

    '__ci_bb_16 {
        if ((if __local_num_write__goto_3265_7 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_17 {
        goto '__ci_bb_8
    }

    '__ci_bb_18 {
        (__ci_expr_old_2 = __local_written__goto_3242_12)
        (__local_written__goto_3242_12 = __local_written__goto_3242_12 + 1)
        ((unsafe: __param_output[__ci_expr_old_2]) = __local_c1__goto_3262_12)
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        if ((if __local_num_write__goto_3265_7 > 1: 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_20 {
        (__ci_expr_old_3 = __local_written__goto_3242_12)
        (__local_written__goto_3242_12 = __local_written__goto_3242_12 + 1)
        ((unsafe: __param_output[__ci_expr_old_3]) = __local_c2__goto_3263_12)
        goto '__ci_bb_21
    }

    '__ci_bb_21 {
        goto '__ci_bb_17
    }

    '__ci_bb_22 {
        with_free(((__local_input_copy__goto_3241_12 as *mut u8) as *mut i8))
        goto '__ci_bb_23
    }

    '__ci_bb_23 {
        if ((if __local_written__goto_3242_12 > __param_output_cap: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_24 {
        (__ci_expr_ternary_4 = 0)
        if ((time(null) & 1) != 0) {
            (__ci_expr_ternary_4 = 205)
        } else {
            (__ci_expr_ternary_4 = 220)
        }
        with_memset((__param_output as *i8), __ci_expr_ternary_4, (((__param_output_cap as c_ulong) *% (1 as c_ulong)) as i64))
        goto '__ci_bb_25
    }

    '__ci_bb_25 {
        return __local_written__goto_3242_12
    }

}

fn callout_function_8(__param_cb: *mut pcre2_callout_block_8, __param_callout_data_ptr: *mut c_void) -> c_int {
    var __local_f__goto_3323_7: *mut c_void = null

    var __local_fdefault__goto_3323_11: *mut c_void = null

    var __local_i__goto_3324_10: c_uint = 0

    var __local_pre_start__goto_3324_13: c_uint = 0

    var __local_post_start__goto_3324_24: c_uint = 0

    var __local_subject_length__goto_3324_36: c_uint = 0

    var __local_current_position__goto_3325_12: c_ulong = 0

    var __local_utf__goto_3326_6: c_int = 0

    var __local_callout_capture__goto_3327_6: c_int = 0

    var __local_callout_where__goto_3328_6: c_int = 0

    var __local_delimiter__goto_3368_12: c_uint = 0

    var __local_callout_data__goto_3504_7: c_int = 0

    var __ci_expr_ternary_2: *mut c_void = null

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_ternary_3: c_ulong = 0

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_utf__goto_3326_6 = (if ((compiled_code_8.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))
        (__local_callout_capture__goto_3327_6 = (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (64 as c_uint)) != 0: 1 else: 0))
        (__local_callout_where__goto_3328_6 = (if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (512 as c_uint)) == 0: 1 else: 0))
        if ((if outfile == null: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        goto '__ci_bb_3
    }

    '__ci_bb_2 {
        (__ci_expr_ternary_2 = null)
        (__ci_expr_logic_1 = 0)
        (__ci_expr_logic_0 = 0)
        if ((if not (first_callout != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if not (__local_callout_capture__goto_3327_6 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if __param_cb.callout_string == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_ternary_2 = null)
        } else {
            (__ci_expr_ternary_2 = outfile)
        }
        (__local_fdefault__goto_3323_11 = __ci_expr_ternary_2)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (1024 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_3 {
        (first_callout = 0)
        (last_callout_mark = ((__param_cb.mark as *const c_void)))
        (callout_count = callout_count + 1)
        if ((if __param_callout_data_ptr != null: 1 else: 0) != 0) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_73
        }
    }

    '__ci_bb_4 {
        (__local_f__goto_3323_7 = outfile)
        goto '__ci_bb_7
    }

    '__ci_bb_5 {
        (__local_f__goto_3323_7 = __local_fdefault__goto_3323_11)
        goto '__ci_bb_6
    }

    '__ci_bb_6 {
        if ((if __param_cb.callout_string != null: 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_7 {
        if (__param_cb.callout_flags == 2) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_8 {
        goto '__ci_bb_6
    }

    '__ci_bb_9 {
        fprintf(__local_f__goto_3323_7, "Backtrack\n")
        goto '__ci_bb_8
    }

    '__ci_bb_10 {
        fprintf(__local_f__goto_3323_7, "Backtrack\nNo other matching paths\n")
        goto '__ci_bb_11
    }

    '__ci_bb_11 {
        fprintf(__local_f__goto_3323_7, "New match attempt\n")
        goto '__ci_bb_8
    }

    '__ci_bb_12 {
        (__local_f__goto_3323_7 = __local_fdefault__goto_3323_11)
        goto '__ci_bb_8
    }

    '__ci_bb_13 {
        if (__param_cb.callout_flags == 3) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_14 {
        if (__param_cb.callout_flags == 1) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_15 {
        (__local_delimiter__goto_3368_12 = (unsafe: __param_cb.callout_string[-1]))
        fprintf(outfile, "Callout (%zu): %c", __param_cb.callout_string_offset, __local_delimiter__goto_3368_12)
        pchars_8(-1, __param_cb.callout_string, __param_cb.callout_string_length, __local_utf__goto_3326_6, outfile)
        (__local_i__goto_3324_10 = 0)
        goto '__ci_bb_17
    }

    '__ci_bb_16 {
        if (__local_callout_capture__goto_3327_6 != 0) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_17 {
        if ((if callout_start_delims[__local_i__goto_3324_10] != 0: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_18 {
        if ((if __local_delimiter__goto_3368_12 == callout_start_delims[__local_i__goto_3324_10]: 1 else: 0) != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_19 {
        (__local_i__goto_3324_10 = __local_i__goto_3324_10 + 1)
        goto '__ci_bb_17
    }

    '__ci_bb_20 {
        fprintf(outfile, "%c", __local_delimiter__goto_3368_12)
        if ((if not (__local_callout_capture__goto_3327_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_21 {
        (__local_delimiter__goto_3368_12 = callout_end_delims[__local_i__goto_3324_10])
        goto '__ci_bb_20
    }

    '__ci_bb_22 {
        goto '__ci_bb_19
    }

    '__ci_bb_23 {
        fprintf(outfile, "\n")
        goto '__ci_bb_24
    }

    '__ci_bb_24 {
        goto '__ci_bb_16
    }

    '__ci_bb_25 {
        if ((if __param_cb.callout_string == null: 1 else: 0) != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_28
        }
    }

    '__ci_bb_26 {
        if (__local_callout_where__goto_3328_6 != 0) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_37
        }
    }

    '__ci_bb_27 {
        fprintf(outfile, "Callout %d:", __param_cb.callout_number)
        goto '__ci_bb_28
    }

    '__ci_bb_28 {
        fprintf(outfile, " last capture = %d\n", __param_cb.capture_last)
        (__local_i__goto_3324_10 = 2)
        goto '__ci_bb_29
    }

    '__ci_bb_29 {
        if ((if __local_i__goto_3324_10 < ((__param_cb.capture_top as c_uint) *% (2 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_30 {
        fprintf(outfile, "%2d: ", ((__local_i__goto_3324_10 as c_uint) / (2 as c_uint)))
        if ((if (unsafe: __param_cb.offset_vector[__local_i__goto_3324_10]) == (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_31 {
        (__local_i__goto_3324_10 = __local_i__goto_3324_10 + 2)
        goto '__ci_bb_29
    }

    '__ci_bb_32 {
        goto '__ci_bb_26
    }

    '__ci_bb_33 {
        fprintf(outfile, "<unset>")
        goto '__ci_bb_35
    }

    '__ci_bb_34 {
        pchars_8(-1, (__param_cb.subject + ((unsafe: __param_cb.offset_vector[__local_i__goto_3324_10]) as usize)), (((unsafe: __param_cb.offset_vector[((__local_i__goto_3324_10 as c_uint) +% (1 as c_uint))]) as c_ulong) -% ((unsafe: __param_cb.offset_vector[__local_i__goto_3324_10]) as c_ulong)), __local_utf__goto_3326_6, __local_f__goto_3323_7)
        goto '__ci_bb_35
    }

    '__ci_bb_35 {
        fprintf(outfile, "\n")
        goto '__ci_bb_31
    }

    '__ci_bb_36 {
        if ((if __local_f__goto_3323_7 != null: 1 else: 0) != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_37 {
        if ((if __param_cb.mark != last_callout_mark: 1 else: 0) != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_38 {
        fprintf(__local_f__goto_3323_7, "--->")
        goto '__ci_bb_39
    }

    '__ci_bb_39 {
        (__local_pre_start__goto_3324_13 = pchars_8(-1, __param_cb.subject, __param_cb.start_match, __local_utf__goto_3326_6, __local_f__goto_3323_7))
        (__ci_expr_ternary_3 = 0)
        if ((if __param_cb.current_position >= __param_cb.start_match: 1 else: 0) != 0) {
            (__ci_expr_ternary_3 = __param_cb.current_position)
        } else {
            (__ci_expr_ternary_3 = __param_cb.start_match)
        }
        (__local_current_position__goto_3325_12 = __ci_expr_ternary_3)
        (__local_post_start__goto_3324_24 = pchars_8(-1, (__param_cb.subject + (__param_cb.start_match as usize)), ((__local_current_position__goto_3325_12 as c_ulong) -% (__param_cb.start_match as c_ulong)), __local_utf__goto_3326_6, __local_f__goto_3323_7))
        pchars_8(-1, (__param_cb.subject + (__local_current_position__goto_3325_12 as usize)), ((__param_cb.subject_length as c_ulong) -% (__local_current_position__goto_3325_12 as c_ulong)), __local_utf__goto_3326_6, __local_f__goto_3323_7)
        (__local_subject_length__goto_3324_36 = pchars_8(-1, __param_cb.subject, __param_cb.subject_length, __local_utf__goto_3326_6, null))
        if ((if __local_f__goto_3323_7 != null: 1 else: 0) != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_40 {
        fprintf(__local_f__goto_3323_7, "\n")
        goto '__ci_bb_41
    }

    '__ci_bb_41 {
        if ((if __param_cb.callout_number == 255: 1 else: 0) != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_42 {
        fprintf(outfile, "%+3d ", (__param_cb.pattern_position as c_int))
        if ((if __param_cb.pattern_position > 99: 1 else: 0) != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_43 {
        if (__local_callout_capture__goto_3327_6 != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_4 = (if (if __param_cb.callout_string != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_44 {
        (__local_i__goto_3324_10 = 0)
        goto '__ci_bb_50
    }

    '__ci_bb_45 {
        fprintf(outfile, "\n    ")
        goto '__ci_bb_46
    }

    '__ci_bb_46 {
        goto '__ci_bb_44
    }

    '__ci_bb_47 {
        fprintf(outfile, "    ")
        goto '__ci_bb_49
    }

    '__ci_bb_48 {
        fprintf(outfile, "%3d ", __param_cb.callout_number)
        goto '__ci_bb_49
    }

    '__ci_bb_49 {
        goto '__ci_bb_44
    }

    '__ci_bb_50 {
        if ((if __local_i__goto_3324_10 < __local_pre_start__goto_3324_13: 1 else: 0) != 0) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_53
        }
    }

    '__ci_bb_51 {
        fprintf(outfile, " ")
        goto '__ci_bb_52
    }

    '__ci_bb_52 {
        (__local_i__goto_3324_10 = __local_i__goto_3324_10 + 1)
        goto '__ci_bb_50
    }

    '__ci_bb_53 {
        fprintf(outfile, "^")
        if ((if __local_post_start__goto_3324_24 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_54
        } else {
            goto '__ci_bb_55
        }
    }

    '__ci_bb_54 {
        (__local_i__goto_3324_10 = 0)
        goto '__ci_bb_56
    }

    '__ci_bb_55 {
        (__local_i__goto_3324_10 = 0)
        goto '__ci_bb_60
    }

    '__ci_bb_56 {
        if ((if __local_i__goto_3324_10 < ((__local_post_start__goto_3324_24 as c_uint) -% (1 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_57
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_57 {
        fprintf(outfile, " ")
        goto '__ci_bb_58
    }

    '__ci_bb_58 {
        (__local_i__goto_3324_10 = __local_i__goto_3324_10 + 1)
        goto '__ci_bb_56
    }

    '__ci_bb_59 {
        fprintf(outfile, "^")
        goto '__ci_bb_55
    }

    '__ci_bb_60 {
        if ((if __local_i__goto_3324_10 < ((((((__local_subject_length__goto_3324_36 as c_uint) -% (__local_pre_start__goto_3324_13 as c_uint)) as c_uint) -% (__local_post_start__goto_3324_24 as c_uint)) as c_uint) +% (4 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_63
        }
    }

    '__ci_bb_61 {
        fprintf(outfile, " ")
        goto '__ci_bb_62
    }

    '__ci_bb_62 {
        (__local_i__goto_3324_10 = __local_i__goto_3324_10 + 1)
        goto '__ci_bb_60
    }

    '__ci_bb_63 {
        if ((if __param_cb.next_item_length != 0: 1 else: 0) != 0) {
            goto '__ci_bb_64
        } else {
            goto '__ci_bb_65
        }
    }

    '__ci_bb_64 {
        pchars_8(-1, (pbuffer8 + (__param_cb.pattern_position as usize)), __param_cb.next_item_length, __local_utf__goto_3326_6, outfile)
        goto '__ci_bb_66
    }

    '__ci_bb_65 {
        fprintf(outfile, "End of pattern")
        goto '__ci_bb_66
    }

    '__ci_bb_66 {
        fprintf(outfile, "\n")
        goto '__ci_bb_37
    }

    '__ci_bb_67 {
        if ((if __param_cb.mark == null: 1 else: 0) != 0) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_68 {
        goto '__ci_bb_3
    }

    '__ci_bb_69 {
        fprintf(outfile, "Latest Mark: <unset>\n")
        goto '__ci_bb_71
    }

    '__ci_bb_70 {
        fprintf(outfile, "Latest Mark: ")
        pchars_8(-1, (__param_cb.mark - ((1 as isize) as usize)), -1, __local_utf__goto_3326_6, outfile)
        putc(10, outfile)
        goto '__ci_bb_71
    }

    '__ci_bb_71 {
        goto '__ci_bb_68
    }

    '__ci_bb_72 {
        (__local_callout_data__goto_3504_7 = (unsafe: *(__param_callout_data_ptr as *mut c_int)))
        if ((if __local_callout_data__goto_3504_7 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_74
        } else {
            goto '__ci_bb_75
        }
    }

    '__ci_bb_73 {
        (__ci_expr_logic_5 = 0)
        if ((if __param_cb.callout_number == (&raw const dat_datctl as *const datctl).cerror[0]: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if callout_count >= (&raw const dat_datctl as *const datctl).cerror[1]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_74 {
        if ((if outfile != null: 1 else: 0) != 0) {
            goto '__ci_bb_76
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_75 {
        goto '__ci_bb_73
    }

    '__ci_bb_76 {
        fprintf(outfile, "Callout data = %d\n", __local_callout_data__goto_3504_7)
        goto '__ci_bb_77
    }

    '__ci_bb_77 {
        return __local_callout_data__goto_3504_7
    }

    '__ci_bb_78 {
        return -37
    }

    '__ci_bb_79 {
        (__ci_expr_logic_6 = 0)
        if ((if __param_cb.callout_number == (&raw const dat_datctl as *const datctl).cfail[0]: 1 else: 0) != 0) {
            (__ci_expr_logic_6 = (if (if callout_count >= (&raw const dat_datctl as *const datctl).cfail[1]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_80 {
        return 1
    }

    '__ci_bb_81 {
        return 0
    }

}

fn copy_and_get_8(__param_utf: c_int, __param_capcount: c_int) -> c_int {
    var __local_i: c_int

    var __local_nptr: *mut u8

    (__local_i = 0)

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_i < 10: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (&raw const dat_datctl as *const datctl).copy_numbers[__local_i] >= 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var __local_rc: c_int

        var __local_rc2: c_int

        var __local_length: c_ulong

        var __local_length2: c_ulong

        var __local_copybuffer: [256]u8

        var __local_n: c_uint = (((&raw const dat_datctl as *const datctl).copy_numbers[__local_i] as c_uint))

        (__local_length = ((256 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong))

        (__local_rc = pcre2_substring_copy_bynumber_8(match_data_8, __local_n, (&(unsafe: __local_copybuffer[0]) as *mut u8), (&raw mut __local_length as *mut c_ulong)))

        if ((if __local_rc < 0: 1 else: 0) != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "Copy substring %d failed (%d): ", __local_n, __local_rc)

            colour_end(outfile)


            if ((if not (print_error_message_8(__local_rc, "", "\n") != 0): 1 else: 0) != 0) {
                return 0
            }

        } else {
            fprintf(outfile, "%2dC ", __local_n)

            pchars_8(-1, (&(unsafe: __local_copybuffer[0]) as *mut u8), __local_length, __param_utf, outfile)

            fprintf(outfile, " (%zu)\n", __local_length)

        }

        (__local_rc2 = pcre2_substring_length_bynumber_8(match_data_8, __local_n, (&raw mut __local_length2 as *mut c_ulong)))

        if ((if __local_rc2 < 0: 1 else: 0) != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "Get substring %d length failed (%d): ", __local_n, __local_rc2)

            colour_end(outfile)


            if ((if not (print_error_message_8(__local_rc2, "", "\n") != 0): 1 else: 0) != 0) {
                return 0
            }

        } else {
            var __ci_expr_logic_1: c_int = 0

            if ((if __local_rc >= 0: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if __local_length2 != __local_length: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                colour_begin(31, outfile)

                fprintf(outfile, "** Mismatched substring lengths: %zu %zu\n", __local_length, __local_length2)

                colour_end(outfile)


            }

        }

        (__local_i = __local_i + 1)

    }


    (__local_nptr = (&(unsafe: (&raw const dat_datctl as *const datctl).copy_names[0]) as *mut u8))

    while true {
        var __local_rc_1: c_int

        var __local_rc2_1: c_int


        var __local_groupnumber: c_int

        var __local_length_1: c_ulong

        var __local_length2_1: c_ulong


        var __local_copybuffer_1: [256]u8

        var __local_namelen: c_ulong = string_len((__local_nptr as *const c_char))

        if ((if __local_namelen == 0: 1 else: 0) != 0) {
            break
        }

        strcpy((pbuffer8 as *mut c_char), (__local_nptr as *mut c_char))

        (__local_groupnumber = pcre2_substring_number_from_name_8(compiled_code_8, pbuffer8))

        var __ci_expr_logic_2: c_int = 0

        if ((if __local_groupnumber < 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __local_groupnumber != -50: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "Number not found for group \"%s\"\n", __local_nptr)

            colour_end(outfile)

        }


        (__local_length_1 = ((256 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong))

        (__local_rc_1 = pcre2_substring_copy_byname_8(match_data_8, pbuffer8, (&(unsafe: __local_copybuffer_1[0]) as *mut u8), (&raw mut __local_length_1 as *mut c_ulong)))

        if ((if __local_rc_1 < 0: 1 else: 0) != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "Copy substring \"%s\" failed (%d): ", __local_nptr, __local_rc_1)

            colour_end(outfile)


            if ((if not (print_error_message_8(__local_rc_1, "", "\n") != 0): 1 else: 0) != 0) {
                return 0
            }

        } else {
            fprintf(outfile, "  C ")

            pchars_8(-1, (&(unsafe: __local_copybuffer_1[0]) as *mut u8), __local_length_1, __param_utf, outfile)

            fprintf(outfile, " (%zu) %s", __local_length_1, __local_nptr)

            if ((if __local_groupnumber >= 0: 1 else: 0) != 0) {
                fprintf(outfile, " (group %d)\n", __local_groupnumber)
            } else {
                fprintf(outfile, " (non-unique)\n")
            }

        }

        (__local_rc2_1 = pcre2_substring_length_byname_8(match_data_8, pbuffer8, (&raw mut __local_length2_1 as *mut c_ulong)))

        if ((if __local_rc2_1 < 0: 1 else: 0) != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "Get substring \"%s\" length failed (%d): ", __local_nptr, __local_rc2_1)

            colour_end(outfile)


            if ((if not (print_error_message_8(__local_rc2_1, "", "\n") != 0): 1 else: 0) != 0) {
                return 0
            }

        } else {
            var __ci_expr_logic_3: c_int = 0

            if ((if __local_rc_1 >= 0: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if __local_length2_1 != __local_length_1: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_3 != 0) {
                colour_begin(31, outfile)

                fprintf(outfile, "** Mismatched substring lengths: %zu %zu\n", __local_length_1, __local_length2_1)

                colour_end(outfile)


            }

        }

        (__local_nptr = __local_nptr + (((__local_namelen as c_ulong) +% (1 as c_ulong)) as usize))

    }

    (__local_i = 0)

    while true {
        var __ci_expr_logic_4: c_int = 0

        if ((if __local_i < 10: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if (&raw const dat_datctl as *const datctl).get_numbers[__local_i] >= 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_4 != 0)) {
            break
        }

        var __local_rc_2: c_int

        var __local_length_2: c_ulong

        var __local_gotbuffer: *mut u8

        var __local_n_1: c_uint = (((&raw const dat_datctl as *const datctl).get_numbers[__local_i] as c_uint))

        (__local_rc_2 = pcre2_substring_get_bynumber_8(match_data_8, __local_n_1, (&raw mut __local_gotbuffer as *mut *mut u8), (&raw mut __local_length_2 as *mut c_ulong)))

        if ((if __local_rc_2 < 0: 1 else: 0) != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "Get substring %d failed (%d): ", __local_n_1, __local_rc_2)

            colour_end(outfile)


            if ((if not (print_error_message_8(__local_rc_2, "", "\n") != 0): 1 else: 0) != 0) {
                return 0
            }

        } else {
            fprintf(outfile, "%2dG ", __local_n_1)

            pchars_8(-1, __local_gotbuffer, __local_length_2, __param_utf, outfile)

            fprintf(outfile, " (%zu)\n", __local_length_2)

            pcre2_substring_free_8(__local_gotbuffer)

        }

        (__local_i = __local_i + 1)

    }


    (__local_nptr = (&(unsafe: (&raw const dat_datctl as *const datctl).get_names[0]) as *mut u8))

    while true {
        var __local_length_3: c_ulong

        var __local_gotbuffer_1: *mut u8

        var __local_rc_3: c_int

        var __local_groupnumber_1: c_int

        var __local_namelen_1: c_ulong = string_len((__local_nptr as *const c_char))

        if ((if __local_namelen_1 == 0: 1 else: 0) != 0) {
            break
        }

        strcpy((pbuffer8 as *mut c_char), (__local_nptr as *mut c_char))

        (__local_groupnumber_1 = pcre2_substring_number_from_name_8(compiled_code_8, pbuffer8))

        var __ci_expr_logic_5: c_int = 0

        if ((if __local_groupnumber_1 < 0: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if __local_groupnumber_1 != -50: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_5 != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "Number not found for group \"%s\"\n", __local_nptr)

            colour_end(outfile)

        }


        (__local_rc_3 = pcre2_substring_get_byname_8(match_data_8, pbuffer8, (&raw mut __local_gotbuffer_1 as *mut *mut u8), (&raw mut __local_length_3 as *mut c_ulong)))

        if ((if __local_rc_3 < 0: 1 else: 0) != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "Get substring \"%s\" failed (%d): ", __local_nptr, __local_rc_3)

            colour_end(outfile)


            if ((if not (print_error_message_8(__local_rc_3, "", "\n") != 0): 1 else: 0) != 0) {
                return 0
            }

        } else {
            fprintf(outfile, "  G ")

            pchars_8(-1, __local_gotbuffer_1, __local_length_3, __param_utf, outfile)

            fprintf(outfile, " (%zu) %s", __local_length_3, __local_nptr)

            if ((if __local_groupnumber_1 >= 0: 1 else: 0) != 0) {
                fprintf(outfile, " (group %d)\n", __local_groupnumber_1)
            } else {
                fprintf(outfile, " (non-unique)\n")
            }

            pcre2_substring_free_8(__local_gotbuffer_1)

        }

        (__local_nptr = __local_nptr + (((__local_namelen_1 as c_ulong) +% (1 as c_ulong)) as usize))

    }

    if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (16384 as c_uint)) != 0: 1 else: 0) != 0) {
        var __local_rc_4: c_int

        var __local_stringlist: *mut *mut u8

        var __local_lengths: *mut c_ulong

        (__local_rc_4 = pcre2_substring_list_get_8(match_data_8, (&raw mut __local_stringlist as *mut *mut *mut u8), (&raw mut __local_lengths as *mut *mut c_ulong)))

        if ((if __local_rc_4 < 0: 1 else: 0) != 0) {
            colour_begin(35, outfile)

            fprintf(outfile, "get substring list failed (%d): ", __local_rc_4)

            colour_end(outfile)


            if ((if not (print_error_message_8(__local_rc_4, "", "\n") != 0): 1 else: 0) != 0) {
                return 0
            }

        } else {
            (__local_i = 0)

            while ((if __local_i < __param_capcount: 1 else: 0) != 0) {
                fprintf(outfile, "%2dL ", __local_i)

                pchars_8(-1, (unsafe: __local_stringlist[__local_i]), (unsafe: __local_lengths[__local_i]), __param_utf, outfile)

                putc(10, outfile)


                (__local_i = __local_i + 1)

            }


            if ((if (unsafe: __local_stringlist[__local_i]) != null: 1 else: 0) != 0) {
                colour_begin(31, outfile)

                fprintf(outfile, "** string list not terminated by NULL\n")

                colour_end(outfile)

            }

            pcre2_substring_list_free_8(__local_stringlist)

        }

    }

    return 1

}

fn copy_substitute_string_8(__param_utf: c_int, __param_input: *mut u8, __param_inlen: c_ulong, __param_output: *mut u8, __param_outlen: *mut c_ulong) {
    var __local_input = __param_input
    var __local_output = __param_output
    var __local_c: c_uint

    var __local_input_end: *mut u8 = (__local_input + (__param_inlen as usize))

    var __local_output_start: *mut u8 = __local_output

    var __local_erroroffset: c_ulong

    var __local_badutf: c_int = 0

    if (__param_utf != 0) {
        (__local_badutf = valid_utf(__local_input, __param_inlen, (&raw mut __local_erroroffset as *mut c_ulong)))
    }

    var __ci_expr_logic_0: c_int

    if ((if not (__param_utf != 0): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __local_badutf != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        while ((if __local_input < __local_input_end: 1 else: 0) != 0) {
            var __ci_expr_old_1: *mut u8 = __local_input

            (__local_input = __local_input + 1)

            (__local_c = (unsafe: *__ci_expr_old_1))


            var __ci_expr_old_2: *mut u8 = __local_output

            (__local_output = __local_output + 1)

            ((unsafe: *__ci_expr_old_2) = __local_c)


        }

    } else {
        while ((if __local_input < __local_input_end: 1 else: 0) != 0) {
            var __ci_expr_old_3: *mut u8 = __local_input

            (__local_input = __local_input + 1)

            (__local_c = (unsafe: *__ci_expr_old_3))


            if ((if __local_c >= 192: 1 else: 0) != 0) {
                if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_4: *mut u8 = __local_input

                    (__local_input = __local_input + 1)

                    (__local_c = (((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe: *__ci_expr_old_4) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                } else {
                    if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_c = (((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe: *__local_input) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_input[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                        (__local_input = __local_input + ((2 as isize) as usize))

                    } else {
                        if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_c = (((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe: *__local_input) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_input[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                            (__local_input = __local_input + ((3 as isize) as usize))

                        } else {
                            if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_c = (((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe: *__local_input) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_input[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_input = __local_input + ((4 as isize) as usize))

                            } else {
                                (__local_c = (((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe: *__local_input) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_input[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_input[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))

                                (__local_input = __local_input + ((5 as isize) as usize))

                            }
                        }
                    }
                }


            }

            (__local_output = __local_output + ((ord_to_utf8(__local_c, __local_output) as isize) as usize))

        }
    }


    ((unsafe: *__local_output) = 0)

    ((unsafe: *__param_outlen) = ((__local_output as usize) -% (__local_output_start as usize)) / sizeof[u8]())

}

fn process_data_8() -> c_int {
    var __local_ulen__goto_3836_12: c_ulong = 0

    var __local_arg_ulen__goto_3836_18: c_ulong = 0

    var __local_gmatched__goto_3837_10: c_uint = 0

    var __local_c__goto_3838_10: c_uint = 0

    var __local_k__goto_3838_13: c_uint = 0

    var __local_g_notempty__goto_3839_10: c_uint = 0

    var __local_p__goto_3840_10: *mut u8 = null

    var __local_len__goto_3841_8: c_ulong = 0

    var __local_needlen__goto_3842_8: c_ulong = 0

    var __local_use_dat_context__goto_3843_22: *mut pcre2_real_match_context_8 = null

    var __local_utf__goto_3844_6: c_int = 0

    var __local_subject_literal__goto_3845_6: c_int = 0

    var __local_ovector__goto_3847_13: *mut c_ulong = null

    var __local_ovecsave__goto_3848_12: [2]*const u8

    var __local_oveccount__goto_3849_10: c_uint = 0

    var __local_q__goto_3851_14: *mut u8 = null

    var __local_start_rep__goto_3852_14: *mut u8 = null

    var __local_pp__goto_3853_14: *mut u8 = null

    var __local_ptmp__goto_3904_12: *mut u8 = null

    var __local_cc__goto_3905_12: c_uint = 0

    var __local_n__goto_3906_7: c_int = 0

    var __local_ptmp_end__goto_3907_12: *mut u8 = null

    var __local_i__goto_3955_7: c_int = 0

    var __local_replen__goto_3956_10: c_ulong = 0

    var __local_encoding__goto_3957_23: i32 = 0

    var __local_li__goto_3963_10: c_long = 0

    var __local_endptr__goto_3964_11: *mut i8 = null

    var __local_qoffset__goto_4003_14: c_ulong = 0

    var __local_rep_offset__goto_4004_14: c_ulong = 0

    var __local_topbit__goto_4036_14: c_uint = 0

    var __local_pt__goto_4087_16: *mut u8 = null

    var __local_pt__goto_4112_16: *mut u8 = null

    var __local_endptr__goto_4161_13: *mut i8 = null

    var __local_uli__goto_4162_21: c_ulong = 0

    var __local_rc__goto_4392_7: c_int = 0

    var __local_eflags__goto_4393_7: c_int = 0

    var __local_pmatch__goto_4394_15: *mut regmatch_t = null

    var __local_startend_buf__goto_4395_14: regmatch_t

    var __local_msg__goto_4396_15: *const i8 = null

    var __local_usize__goto_4453_12: c_ulong = 0

    var __local_i__goto_4464_12: c_ulong = 0

    var __local_j__goto_4464_15: c_ulong = 0

    var __local_last_printed__goto_4465_12: c_ulong = 0

    var __local_start__goto_4470_20: c_ulong = 0

    var __local_end__goto_4471_20: c_ulong = 0

    var __local_rc__goto_4646_7: c_int = 0

    var __local_pr__goto_4647_12: *mut u8 = null

    var __local_prend__goto_4647_17: *mut u8 = null

    var __local_sbuffer__goto_4648_15: [100]u8

    var __local_rbptr__goto_4649_16: *mut u8 = null

    var __local_sbptr__goto_4650_16: *mut u8 = null

    var __local_xoptions__goto_4651_12: c_uint = 0

    var __local_emoption__goto_4652_12: c_uint = 0

    var __local_j__goto_4653_14: c_ulong = 0

    var __local_rlen__goto_4653_17: c_ulong = 0

    var __local_full_rlen__goto_4653_23: c_ulong = 0

    var __local_nsize__goto_4653_34: c_ulong = 0

    var __local_nsize_input__goto_4653_41: c_ulong = 0

    var __local_slen__goto_4653_54: c_ulong = 0

    var __local_smatch_data__goto_4654_21: *mut pcre2_real_match_data_8 = null

    var __local_n__goto_4723_16: c_ulong = 0

    var __local_heapframes__goto_4831_23: *mut c_void = null

    var __local_memory_data__goto_4831_23: *mut c_void = null

    var __local_i__goto_4842_14: c_int = 0

    var __local_target_mallocs__goto_4842_21: c_int = 0

    var __local_saved_outfile__goto_4844_13: *mut c_void = null

    var __local_heapframes__goto_4845_7: *mut c_void = null

    var __local_memory_data__goto_4845_7: *mut c_void = null

    var __local_j__goto_4918_14: c_ulong = 0

    var __local_capcount__goto_4919_7: c_int = 0

    var __local_i__goto_4935_9: c_int = 0

    var __local_start_time__goto_4936_13: c_ulong = 0

    var __local_time_taken__goto_4936_25: c_ulong = 0

    var __local_saved_outfile__goto_4937_11: *mut c_void = null

    var __local_heapframes__goto_5025_25: *mut c_void = null

    var __local_memory_data__goto_5025_25: *mut c_void = null

    var __local_i__goto_5061_16: c_int = 0

    var __local_target_mallocs__goto_5061_23: c_int = 0

    var __local_saved_outfile__goto_5063_15: *mut c_void = null

    var __local_heapframes__goto_5065_9: *mut c_void = null

    var __local_memory_data__goto_5065_9: *mut c_void = null

    var __local_rc_nextmatch__goto_5109_12: c_int = 0

    var __local_tmp_offset__goto_5110_18: c_ulong = 0

    var __local_tmp_options__goto_5111_16: c_uint = 0

    var __local_i__goto_5229_14: c_int = 0

    var __local_lleft__goto_5231_18: c_ulong = 0

    var __local_lmiddle__goto_5231_25: c_ulong = 0

    var __local_lright__goto_5231_34: c_ulong = 0

    var __local_start__goto_5232_18: c_ulong = 0

    var __local_end__goto_5233_18: c_ulong = 0

    var __local_showallused__goto_5280_14: c_int = 0

    var __local_leftchar__goto_5281_20: c_ulong = 0

    var __local_rightchar__goto_5281_30: c_ulong = 0

    var __local_startchar__goto_5310_22: c_ulong = 0

    var __local_leftchar__goto_5377_16: c_ulong = 0

    var __local_backlength__goto_5378_9: c_int = 0

    var __local_rubriclength__goto_5379_9: c_int = 0

    var __local_i__goto_5407_16: c_int = 0

    var __local_i__goto_5408_16: c_int = 0

    var __local_startchar__goto_5467_20: c_ulong = 0

    var __local_new_start_offset__goto_5488_16: c_ulong = 0

    var __local_rc_nextmatch__goto_5489_10: c_int = 0

    var __ci_expr_ternary_0: c_uint = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_old_4: *mut u8 = null

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_old_6: *mut u8 = null

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_old_8: *mut u8 = null

    var __ci_expr_old_9: c_int = 0

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_old_11: c_int = 0

    var __ci_expr_logic_12: c_int = 0

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_logic_13: c_int = 0

    var __ci_expr_old_15: *mut u8 = null

    var __ci_expr_old_16: *mut u8 = null

    var __ci_expr_switch_17: c_uint = 0

    var __ci_expr_logic_20: c_int = 0

    var __ci_expr_logic_19: c_int = 0

    var __ci_expr_old_18: c_int = 0

    var __ci_expr_old_21: *mut u8 = null

    var __ci_expr_ternary_23: c_int = 0

    var __ci_expr_logic_22: c_int = 0

    var __ci_expr_logic_24: c_int = 0

    var __ci_expr_logic_25: c_int = 0

    var __ci_expr_ternary_26: c_int = 0

    var __ci_expr_logic_27: c_int = 0

    var __ci_expr_logic_29: c_int = 0

    var __ci_expr_old_28: c_int = 0

    var __ci_expr_ternary_30: c_int = 0

    var __ci_expr_logic_31: c_int = 0

    var __ci_expr_logic_33: c_int = 0

    var __ci_expr_logic_32: c_int = 0

    var __ci_expr_logic_35: c_int = 0

    var __ci_expr_old_36: *mut u8 = null

    var __ci_expr_logic_37: c_int = 0

    var __ci_expr_logic_38: c_int = 0

    var __ci_expr_logic_39: c_int = 0

    var __ci_expr_logic_40: c_int = 0

    var __ci_expr_logic_41: c_int = 0

    var __ci_expr_logic_42: c_int = 0

    var __ci_expr_logic_43: c_int = 0

    var __ci_expr_ternary_45: c_int = 0

    var __ci_expr_logic_44: c_int = 0

    var __ci_expr_logic_46: c_int = 0

    var __ci_expr_logic_47: c_int = 0

    var __ci_expr_logic_48: c_int = 0

    var __ci_expr_logic_49: c_int = 0

    var __ci_expr_logic_50: c_int = 0

    var __ci_expr_ternary_51: c_int = 0

    var __ci_expr_logic_53: c_int = 0

    var __ci_expr_logic_52: c_int = 0

    var __ci_expr_logic_54: c_int = 0

    var __ci_expr_ternary_55: *mut pcre2_real_match_context_8 = null

    var __ci_expr_logic_56: c_int = 0

    var __ci_expr_logic_57: c_int = 0

    var __ci_expr_logic_59: c_int = 0

    var __ci_expr_logic_58: c_int = 0

    var __ci_expr_ternary_60: c_uint = 0

    var __ci_expr_ternary_61: c_uint = 0

    var __ci_expr_ternary_62: c_uint = 0

    var __ci_expr_ternary_63: c_uint = 0

    var __ci_expr_ternary_64: c_uint = 0

    var __ci_expr_ternary_65: c_uint = 0

    var __ci_expr_ternary_66: c_uint = 0

    var __ci_expr_ternary_67: c_uint = 0

    var __ci_expr_logic_68: c_int = 0

    var __ci_expr_logic_70: c_int = 0

    var __ci_expr_logic_69: c_int = 0

    var __ci_expr_logic_71: c_int = 0

    var __ci_expr_ternary_72: *mut u8 = null

    var __ci_expr_ternary_73: *mut pcre2_real_match_data_8 = null

    var __ci_expr_logic_74: c_int = 0

    var __ci_expr_logic_75: c_int = 0

    var __ci_expr_logic_76: c_int = 0

    var __ci_expr_logic_77: c_int = 0

    var __ci_expr_logic_78: c_int = 0

    var __ci_expr_logic_79: c_int = 0

    var __ci_expr_logic_81: c_int = 0

    var __ci_expr_logic_83: c_int = 0

    var __ci_expr_logic_82: c_int = 0

    var __ci_expr_old_84: c_uint = 0

    var __ci_expr_logic_85: c_int = 0

    var __ci_expr_old_86: c_uint = 0

    var __ci_expr_logic_87: c_int = 0

    var __ci_expr_logic_88: c_int = 0

    var __ci_expr_logic_90: c_int = 0

    var __ci_expr_logic_89: c_int = 0

    var __ci_expr_logic_91: c_int = 0

    var __ci_expr_logic_95: c_int = 0

    var __ci_expr_logic_94: c_int = 0

    var __ci_expr_logic_93: c_int = 0

    var __ci_expr_logic_101: c_int = 0

    var __ci_expr_logic_97: c_int = 0

    var __ci_expr_logic_102: c_int = 0

    var __ci_expr_logic_103: c_int = 0

    var __ci_expr_logic_106: c_int = 0

    var __ci_expr_logic_105: c_int = 0

    var __ci_expr_logic_104: c_int = 0

    var __ci_expr_logic_108: c_int = 0

    var __ci_expr_logic_109: c_int = 0

    var __ci_expr_logic_110: c_int = 0

    var __ci_expr_logic_111: c_int = 0

    var __ci_expr_logic_113: c_int = 0

    var __ci_expr_logic_114: c_int = 0

    var __ci_expr_logic_115: c_int = 0

    var __ci_expr_logic_116: c_int = 0

    var __ci_expr_logic_117: c_int = 0

    var __ci_expr_logic_118: c_int = 0

    var __ci_expr_logic_119: c_int = 0

    var __ci_expr_logic_120: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_g_notempty__goto_3839_10 = 0)
        (__local_ovecsave__goto_3848_12 = [((null) as *const u8), ((null) as *const u8)])
        (__local_q__goto_3851_14 = ((null as *mut u8)))
        (__local_subject_literal__goto_3845_6 = (if (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (256 as c_uint)) != 0: 1 else: 0))
        with_memcpy((dat_context_8 as *i8), (default_dat_context_8 as *i8), (sizeof[pcre2_real_match_context_8]() as i64))
        with_memcpy(((&raw mut dat_datctl as *mut datctl) as *i8), ((&raw mut def_datctl as *mut datctl) as *i8), (sizeof[datctl]() as i64))
        (dat_datctl.control = (&raw const dat_datctl as *const datctl).control | (((&raw const pat_patctl as *const patctl).control as c_uint) & (((((((((((((((((1 as c_uint) | (2 as c_uint)) as c_uint) | (4 as c_uint)) as c_uint) | (8 as c_uint)) as c_uint) | (16 as c_uint)) as c_uint) | (32768 as c_uint)) as c_uint) | (1048576 as c_uint)) as c_uint) | (268435456 as c_uint)) as c_uint) | (1073741824 as c_uint)) as c_uint)))
        (dat_datctl.control2 = (&raw const dat_datctl as *const datctl).control2 | (((&raw const pat_patctl as *const patctl).control2 as c_uint) & (((((((((((((((((((((((1 as c_uint) | (2 as c_uint)) as c_uint) | (4 as c_uint)) as c_uint) | (8 as c_uint)) as c_uint) | (16 as c_uint)) as c_uint) | (32 as c_uint)) as c_uint) | (64 as c_uint)) as c_uint) | (128 as c_uint)) as c_uint) | (2048 as c_uint)) as c_uint) | (65536 as c_uint)) as c_uint) | (131072 as c_uint)) as c_uint) | (536870912 as c_uint)) as c_uint)))
        (dat_datctl.replacement[0] = (&raw const pat_patctl as *const patctl).replacement[0])
        if ((if (&raw const pat_patctl as *const patctl).replacement[0] != 255: 1 else: 0) != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        with_memcpy((((&(unsafe: (&raw const dat_datctl as *const datctl).replacement[0]) as *mut u8) + ((1 as isize) as usize)) as *i8), (((&(unsafe: (&raw const pat_patctl as *const patctl).replacement[0]) as *mut u8) + ((1 as isize) as usize)) as *i8), ((((&raw const pat_patctl as *const patctl).replacement[0] as c_int) + 1) as i64))
        goto '__ci_bb_2
    }

    '__ci_bb_2 {
        if ((if (&raw const dat_datctl as *const datctl).jitstack == 0: 1 else: 0) != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_3 {
        (dat_datctl.jitstack = (&raw const pat_patctl as *const patctl).jitstack)
        goto '__ci_bb_4
    }

    '__ci_bb_4 {
        if ((if (&raw const dat_datctl as *const datctl).substitute_skip == 0: 1 else: 0) != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_5 {
        (dat_datctl.substitute_skip = (&raw const pat_patctl as *const patctl).substitute_skip)
        goto '__ci_bb_6
    }

    '__ci_bb_6 {
        if ((if (&raw const dat_datctl as *const datctl).substitute_stop == 0: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_7 {
        (dat_datctl.substitute_stop = (&raw const pat_patctl as *const patctl).substitute_stop)
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        (__ci_expr_ternary_0 = 0)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (8388608 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = ((&raw const preg as *const regex_t).re_pcre2_code as *mut pcre2_real_code_8).overall_options)
        } else {
            (__ci_expr_ternary_0 = compiled_code_8.overall_options)
        }
        (__local_utf__goto_3844_6 = (if ((__ci_expr_ternary_0 as c_uint) & (524288 as c_uint)) != 0: 1 else: 0))
        (__local_start_rep__goto_3852_14 = ((null as *mut u8)))
        (__local_len__goto_3841_8 = string_len((buffer as *const c_char)))
        goto '__ci_bb_9
    }

    '__ci_bb_9 {
        (__ci_expr_logic_1 = 0)
        if ((if __local_len__goto_3841_8 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if isspace((unsafe: buffer[((__local_len__goto_3841_8 as c_ulong) -% (1 as c_ulong))])) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_10 {
        (__local_len__goto_3841_8 = __local_len__goto_3841_8 - 1)
        goto '__ci_bb_9
    }

    '__ci_bb_11 {
        ((unsafe: buffer[__local_len__goto_3841_8]) = 0)
        (__local_p__goto_3840_10 = buffer)
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        if (isspace((unsafe: *__local_p__goto_3840_10)) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_13 {
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + 1)
        (__local_len__goto_3841_8 = __local_len__goto_3841_8 - 1)
        goto '__ci_bb_12
    }

    '__ci_bb_14 {
        if (__local_utf__goto_3844_6 != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_15 {
        (__local_n__goto_3906_7 = 1)
        (__local_ptmp_end__goto_3907_12 = __local_p__goto_3840_10 + (__local_len__goto_3841_8 as usize))
        (__local_ptmp__goto_3904_12 = __local_p__goto_3840_10)
        goto '__ci_bb_17
    }

    '__ci_bb_16 {
        (__local_needlen__goto_3842_8 = ((((__local_len__goto_3841_8 as c_ulong) +% (1 as c_ulong)) as c_ulong) *% (1 as c_ulong)))
        if ((if dbuffer == null: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if __local_needlen__goto_3842_8 >= dbuffer_size: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_17 {
        (__ci_expr_logic_2 = 0)
        if ((if __local_n__goto_3906_7 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (unsafe: *__local_ptmp__goto_3904_12) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_18 {
        (__local_n__goto_3906_7 = utf8_to_ord(__local_ptmp__goto_3904_12, __local_ptmp_end__goto_3907_12, (&raw mut __local_cc__goto_3905_12 as *mut c_uint)))
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        (__local_ptmp__goto_3904_12 = __local_ptmp__goto_3904_12 + ((__local_n__goto_3906_7 as isize) as usize))
        goto '__ci_bb_17
    }

    '__ci_bb_20 {
        if ((if __local_n__goto_3906_7 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_21 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Failed: invalid UTF-8 string cannot be used as input in UTF mode\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_22 {
        goto '__ci_bb_16
    }

    '__ci_bb_23 {
        goto '__ci_bb_25
    }

    '__ci_bb_24 {
        (__local_q__goto_3851_14 = dbuffer)
        goto '__ci_bb_33
    }

    '__ci_bb_25 {
        if ((if __local_needlen__goto_3842_8 >= dbuffer_size: 1 else: 0) != 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_26 {
        if ((if dbuffer_size < ((((0 as c_ulong) -% 1) as c_ulong) / (2 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_27 {
        (dbuffer = (((with_realloc((dbuffer as *mut i8), (0 as i64), (dbuffer_size as i64)) as *mut c_void) as *mut u8)))
        if ((if dbuffer == null: 1 else: 0) != 0) {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_32
        }
    }

    '__ci_bb_28 {
        (dbuffer_size = dbuffer_size * 2)
        goto '__ci_bb_30
    }

    '__ci_bb_29 {
        (dbuffer_size = ((__local_needlen__goto_3842_8 as c_ulong) +% (1 as c_ulong)))
        goto '__ci_bb_30
    }

    '__ci_bb_30 {
        goto '__ci_bb_25
    }

    '__ci_bb_31 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: realloc(%zu) failed\n", dbuffer_size)
        colour_end(libc_stderr())
        exit(1)
        goto '__ci_bb_32
    }

    '__ci_bb_32 {
        goto '__ci_bb_24
    }

    '__ci_bb_33 {
        (__ci_expr_old_4 = __local_p__goto_3840_10)
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + 1)
        (__local_c__goto_3838_10 = (unsafe: *__ci_expr_old_4))
        if ((if __local_c__goto_3838_10 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_34 {
        (__local_i__goto_3955_7 = 0)
        (__local_encoding__goto_3957_23 = 0)
        (__ci_expr_logic_5 = 0)
        if ((if __local_c__goto_3838_10 == 93: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if __local_start_rep__goto_3852_14 != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            goto '__ci_bb_36
        } else {
            goto '__ci_bb_37
        }
    }

    '__ci_bb_35 {
        goto '__ci_bb_135
    }

    '__ci_bb_36 {
        (__ci_expr_old_6 = __local_p__goto_3840_10)
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + 1)
        if ((if (unsafe: *__ci_expr_old_6) != 123: 1 else: 0) != 0) {
            goto '__ci_bb_38
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_37 {
        if ((if __local_c__goto_3838_10 != 92: 1 else: 0) != 0) {
            (__ci_expr_logic_12 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_12 = (if __local_subject_literal__goto_3845_6 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_12 != 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_38 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Expected '{' after \\[....]\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_39 {
        (__local_li__goto_3963_10 = strtol((__local_p__goto_3840_10 as *const c_char), (&raw mut __local_endptr__goto_3964_11 as *mut *mut c_char), 10))
        if ((if __local_li__goto_3963_10 > 2147483647: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_7 = (if (if __local_li__goto_3963_10 < -2147483648: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_40 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Repeat count too large\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_41 {
        (__local_i__goto_3955_7 = ((__local_li__goto_3963_10 as c_int)))
        (__local_p__goto_3840_10 = ((__local_endptr__goto_3964_11 as *mut u8)))
        (__ci_expr_old_8 = __local_p__goto_3840_10)
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + 1)
        if ((if (unsafe: *__ci_expr_old_8) != 125: 1 else: 0) != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_43
        }
    }

    '__ci_bb_42 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Expected '}' after \\[...]{...\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_43 {
        (__ci_expr_old_9 = __local_i__goto_3955_7)
        (__local_i__goto_3955_7 = __local_i__goto_3955_7 - 1)
        if ((if __ci_expr_old_9 <= 0: 1 else: 0) != 0) {
            goto '__ci_bb_44
        } else {
            goto '__ci_bb_45
        }
    }

    '__ci_bb_44 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Zero or negative repeat not allowed\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_45 {
        (__local_replen__goto_3956_10 = ((__local_q__goto_3851_14 as usize) -% (__local_start_rep__goto_3852_14 as usize)) / sizeof[u8]())
        (__ci_expr_logic_10 = 0)
        if ((if __local_i__goto_3955_7 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if (if __local_replen__goto_3956_10 > ((((((0 as c_ulong) -% 1) as c_ulong) -% (__local_needlen__goto_3842_8 as c_ulong)) as c_ulong) / (__local_i__goto_3955_7 as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_10 != 0) {
            goto '__ci_bb_46
        } else {
            goto '__ci_bb_47
        }
    }

    '__ci_bb_46 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Expanded content too large\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_47 {
        (__local_needlen__goto_3842_8 = __local_needlen__goto_3842_8 + ((__local_replen__goto_3956_10 as c_ulong) *% (__local_i__goto_3955_7 as c_ulong)))
        if ((if __local_needlen__goto_3842_8 >= dbuffer_size: 1 else: 0) != 0) {
            goto '__ci_bb_48
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_48 {
        (__local_qoffset__goto_4003_14 = ((__local_q__goto_3851_14 as usize) -% (dbuffer as usize)) / sizeof[u8]())
        (__local_rep_offset__goto_4004_14 = ((__local_start_rep__goto_3852_14 as usize) -% (dbuffer as usize)) / sizeof[u8]())
        goto '__ci_bb_50
    }

    '__ci_bb_49 {
        goto '__ci_bb_58
    }

    '__ci_bb_50 {
        if ((if __local_needlen__goto_3842_8 >= dbuffer_size: 1 else: 0) != 0) {
            goto '__ci_bb_51
        } else {
            goto '__ci_bb_52
        }
    }

    '__ci_bb_51 {
        if ((if dbuffer_size < ((((0 as c_ulong) -% 1) as c_ulong) / (2 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_52 {
        (dbuffer = (((with_realloc((dbuffer as *mut i8), (0 as i64), (dbuffer_size as i64)) as *mut c_void) as *mut u8)))
        if ((if dbuffer == null: 1 else: 0) != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_53 {
        (dbuffer_size = dbuffer_size * 2)
        goto '__ci_bb_55
    }

    '__ci_bb_54 {
        (dbuffer_size = ((__local_needlen__goto_3842_8 as c_ulong) +% (1 as c_ulong)))
        goto '__ci_bb_55
    }

    '__ci_bb_55 {
        goto '__ci_bb_50
    }

    '__ci_bb_56 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: realloc(%zu) failed\n", dbuffer_size)
        colour_end(libc_stderr())
        exit(1)
        goto '__ci_bb_57
    }

    '__ci_bb_57 {
        (__local_q__goto_3851_14 = dbuffer + (__local_qoffset__goto_4003_14 as usize))
        (__local_start_rep__goto_3852_14 = dbuffer + (__local_rep_offset__goto_4004_14 as usize))
        goto '__ci_bb_49
    }

    '__ci_bb_58 {
        (__ci_expr_old_11 = __local_i__goto_3955_7)
        (__local_i__goto_3955_7 = __local_i__goto_3955_7 - 1)
        if ((if __ci_expr_old_11 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_59 {
        with_memcpy((__local_q__goto_3851_14 as *i8), (__local_start_rep__goto_3852_14 as *i8), (__local_replen__goto_3956_10 as i64))
        (__local_q__goto_3851_14 = __local_q__goto_3851_14 + (((__local_replen__goto_3956_10 as c_ulong) / (1 as c_ulong)) as usize))
        goto '__ci_bb_58
    }

    '__ci_bb_60 {
        (__local_start_rep__goto_3852_14 = ((null as *mut u8)))
        goto '__ci_bb_33
    }

    '__ci_bb_61 {
        (__local_topbit__goto_4036_14 = 0)
        (__ci_expr_logic_14 = 0)
        if (__local_utf__goto_3844_6 != 0) {
            (__ci_expr_logic_13 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_13 = (if (if (((&raw const pat_patctl as *const patctl).control as c_uint) & (1073741824 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            (__ci_expr_logic_14 = (if (if __local_c__goto_3838_10 >= 192: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_64
        } else {
            goto '__ci_bb_65
        }
    }

    '__ci_bb_62 {
        (__ci_expr_old_16 = __local_p__goto_3840_10)
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + 1)
        (__local_c__goto_3838_10 = (unsafe: *__ci_expr_old_16))
        (__ci_expr_switch_17 = __local_c__goto_3838_10)
        goto '__ci_bb_78
    }

    '__ci_bb_63 {
        if ((if __local_encoding__goto_3957_23 == 1: 1 else: 0) != 0) {
            (__ci_expr_logic_35 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_34: c_int

            if (__local_utf__goto_3844_6 != 0) {
                (__ci_expr_logic_34 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_34 = (if (if __local_encoding__goto_3957_23 == 2: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_35 = (if (if not (__ci_expr_logic_34 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_35 != 0) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_64 {
        if ((if ((__local_c__goto_3838_10 as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_66
        } else {
            goto '__ci_bb_67
        }
    }

    '__ci_bb_65 {
        (__local_c__goto_3838_10 = __local_c__goto_3838_10 | __local_topbit__goto_4036_14)
        goto '__ci_bb_63
    }

    '__ci_bb_66 {
        (__ci_expr_old_15 = __local_p__goto_3840_10)
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + 1)
        (__local_c__goto_3838_10 = (((((__local_c__goto_3838_10 as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe: *__ci_expr_old_15) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        goto '__ci_bb_68
    }

    '__ci_bb_67 {
        if ((if ((__local_c__goto_3838_10 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_68 {
        goto '__ci_bb_65
    }

    '__ci_bb_69 {
        (__local_c__goto_3838_10 = (((((((__local_c__goto_3838_10 as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe: *__local_p__goto_3840_10) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_p__goto_3840_10[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + ((2 as isize) as usize))
        goto '__ci_bb_71
    }

    '__ci_bb_70 {
        if ((if ((__local_c__goto_3838_10 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_73
        }
    }

    '__ci_bb_71 {
        goto '__ci_bb_68
    }

    '__ci_bb_72 {
        (__local_c__goto_3838_10 = (((((((((__local_c__goto_3838_10 as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe: *__local_p__goto_3840_10) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_p__goto_3840_10[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_p__goto_3840_10[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + ((3 as isize) as usize))
        goto '__ci_bb_74
    }

    '__ci_bb_73 {
        if ((if ((__local_c__goto_3838_10 as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_76
        }
    }

    '__ci_bb_74 {
        goto '__ci_bb_71
    }

    '__ci_bb_75 {
        (__local_c__goto_3838_10 = (((((((((((__local_c__goto_3838_10 as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe: *__local_p__goto_3840_10) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_p__goto_3840_10[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_p__goto_3840_10[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_p__goto_3840_10[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + ((4 as isize) as usize))
        goto '__ci_bb_77
    }

    '__ci_bb_76 {
        (__local_c__goto_3838_10 = (((((((((((((__local_c__goto_3838_10 as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe: *__local_p__goto_3840_10) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_p__goto_3840_10[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_p__goto_3840_10[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe: __local_p__goto_3840_10[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe: __local_p__goto_3840_10[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + ((5 as isize) as usize))
        goto '__ci_bb_77
    }

    '__ci_bb_77 {
        goto '__ci_bb_74
    }

    '__ci_bb_78 {
        if (__ci_expr_switch_17 == 92) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_142
        }
    }

    '__ci_bb_79 {
        goto '__ci_bb_63
    }

    '__ci_bb_80 {
        goto '__ci_bb_79
    }

    '__ci_bb_81 {
        (__local_c__goto_3838_10 = 7)
        goto '__ci_bb_79
    }

    '__ci_bb_82 {
        (__local_c__goto_3838_10 = 8)
        goto '__ci_bb_79
    }

    '__ci_bb_83 {
        (__local_c__goto_3838_10 = 27)
        goto '__ci_bb_79
    }

    '__ci_bb_84 {
        (__local_c__goto_3838_10 = 12)
        goto '__ci_bb_79
    }

    '__ci_bb_85 {
        (__local_c__goto_3838_10 = 10)
        goto '__ci_bb_79
    }

    '__ci_bb_86 {
        (__local_c__goto_3838_10 = 13)
        goto '__ci_bb_79
    }

    '__ci_bb_87 {
        (__local_c__goto_3838_10 = 9)
        goto '__ci_bb_79
    }

    '__ci_bb_88 {
        (__local_c__goto_3838_10 = 11)
        goto '__ci_bb_79
    }

    '__ci_bb_89 {
        (__local_c__goto_3838_10 = __local_c__goto_3838_10 - 48)
        goto '__ci_bb_90
    }

    '__ci_bb_90 {
        (__ci_expr_logic_20 = 0)
        (__ci_expr_logic_19 = 0)
        (__ci_expr_old_18 = __local_i__goto_3955_7)
        (__local_i__goto_3955_7 = __local_i__goto_3955_7 + 1)
        if ((if __ci_expr_old_18 < 2: 1 else: 0) != 0) {
            (__ci_expr_logic_19 = (if (if (unsafe: *__local_p__goto_3840_10) >= 48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_19 != 0) {
            (__ci_expr_logic_20 = (if (if (unsafe: *__local_p__goto_3840_10) < 56: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_20 != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_92
        }
    }

    '__ci_bb_91 {
        (__ci_expr_old_21 = __local_p__goto_3840_10)
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + 1)
        (__local_c__goto_3838_10 = ((((__local_c__goto_3838_10 as c_uint) *% (8 as c_uint)) as c_uint) +% ((((unsafe: *__ci_expr_old_21) as c_int) - 48) as c_uint)))
        goto '__ci_bb_90
    }

    '__ci_bb_92 {
        (__local_c__goto_3838_10 = __local_c__goto_3838_10)
        (__ci_expr_ternary_23 = 0)
        (__ci_expr_logic_22 = 0)
        if (__local_utf__goto_3844_6 != 0) {
            (__ci_expr_logic_22 = (if (if __local_c__goto_3838_10 > 255: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_22 != 0) {
            (__ci_expr_ternary_23 = FORCE_UTF)
        } else {
            (__ci_expr_ternary_23 = FORCE_RAW)
        }
        (__local_encoding__goto_3957_23 = __ci_expr_ternary_23)
        goto '__ci_bb_79
    }

    '__ci_bb_93 {
        if ((if (unsafe: *__local_p__goto_3840_10) == 123: 1 else: 0) != 0) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_94 {
        (__local_pt__goto_4087_16 = __local_p__goto_3840_10)
        (__local_c__goto_3838_10 = 0)
        (__local_pt__goto_4087_16 = __local_pt__goto_4087_16 + 1)
        goto '__ci_bb_96
    }

    '__ci_bb_95 {
        goto '__ci_bb_79
    }

    '__ci_bb_96 {
        (__ci_expr_logic_24 = 0)
        if (isdigit((unsafe: *__local_pt__goto_4087_16)) != 0) {
            (__ci_expr_logic_24 = (if (if (unsafe: *__local_pt__goto_4087_16) < 56: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_24 != 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_97 {
        if ((if __local_c__goto_3838_10 >= 536870912: 1 else: 0) != 0) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_101
        }
    }

    '__ci_bb_98 {
        (__local_i__goto_3955_7 = __local_i__goto_3955_7 + 1)
        (__local_pt__goto_4087_16 = __local_pt__goto_4087_16 + 1)
        goto '__ci_bb_96
    }

    '__ci_bb_99 {
        (__local_c__goto_3838_10 = __local_c__goto_3838_10)
        if ((if __local_i__goto_3955_7 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_25 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_25 = (if (if (unsafe: *__local_pt__goto_4087_16) != 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_25 != 0) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_104
        }
    }

    '__ci_bb_100 {
        colour_begin(31, outfile)
        fprintf(outfile, "** \\o{ escape too large\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_101 {
        (__local_c__goto_3838_10 = ((((__local_c__goto_3838_10 as c_uint) *% (8 as c_uint)) as c_uint) +% ((((unsafe: *__local_pt__goto_4087_16) as c_int) - 48) as c_uint)))
        goto '__ci_bb_102
    }

    '__ci_bb_102 {
        goto '__ci_bb_98
    }

    '__ci_bb_103 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Malformed \\o{ escape\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_104 {
        (__local_p__goto_3840_10 = __local_pt__goto_4087_16 + ((1 as isize) as usize))
        goto '__ci_bb_105
    }

    '__ci_bb_105 {
        goto '__ci_bb_95
    }

    '__ci_bb_106 {
        (__local_c__goto_3838_10 = 0)
        if ((if (unsafe: *__local_p__goto_3840_10) == 123: 1 else: 0) != 0) {
            goto '__ci_bb_107
        } else {
            goto '__ci_bb_108
        }
    }

    '__ci_bb_107 {
        (__local_pt__goto_4112_16 = __local_p__goto_3840_10)
        (__local_pt__goto_4112_16 = __local_pt__goto_4112_16 + 1)
        goto '__ci_bb_110
    }

    '__ci_bb_108 {
        goto '__ci_bb_123
    }

    '__ci_bb_109 {
        goto '__ci_bb_79
    }

    '__ci_bb_110 {
        if (isxdigit((unsafe: *__local_pt__goto_4112_16)) != 0) {
            goto '__ci_bb_111
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_111 {
        (__local_i__goto_3955_7 = __local_i__goto_3955_7 + 1)
        if ((if __local_i__goto_3955_7 == 9: 1 else: 0) != 0) {
            goto '__ci_bb_114
        } else {
            goto '__ci_bb_115
        }
    }

    '__ci_bb_112 {
        (__local_pt__goto_4112_16 = __local_pt__goto_4112_16 + 1)
        goto '__ci_bb_110
    }

    '__ci_bb_113 {
        (__local_c__goto_3838_10 = __local_c__goto_3838_10)
        if ((if __local_i__goto_3955_7 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_27 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_27 = (if (if (unsafe: *__local_pt__goto_4112_16) != 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_27 != 0) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_121
        }
    }

    '__ci_bb_114 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Too many hex digits in \\x{...} item; using only the first eight.\n")
        colour_end(outfile)
        goto '__ci_bb_117
    }

    '__ci_bb_115 {
        (__ci_expr_ternary_26 = 0)
        if (isdigit((unsafe: *__local_pt__goto_4112_16)) != 0) {
            (__ci_expr_ternary_26 = 48)
        } else {
            (__ci_expr_ternary_26 = 97 - 10)
        }
        (__local_c__goto_3838_10 = ((((__local_c__goto_3838_10 as c_uint) *% (16 as c_uint)) as c_uint) +% ((tolower((unsafe: *__local_pt__goto_4112_16)) - __ci_expr_ternary_26) as c_uint)))
        goto '__ci_bb_116
    }

    '__ci_bb_116 {
        goto '__ci_bb_112
    }

    '__ci_bb_117 {
        if (isxdigit((unsafe: *__local_pt__goto_4112_16)) != 0) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_119
        }
    }

    '__ci_bb_118 {
        (__local_pt__goto_4112_16 = __local_pt__goto_4112_16 + 1)
        goto '__ci_bb_117
    }

    '__ci_bb_119 {
        goto '__ci_bb_113
    }

    '__ci_bb_120 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Malformed \\x{ escape\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_121 {
        (__local_p__goto_3840_10 = __local_pt__goto_4112_16 + ((1 as isize) as usize))
        goto '__ci_bb_122
    }

    '__ci_bb_122 {
        goto '__ci_bb_109
    }

    '__ci_bb_123 {
        (__ci_expr_logic_29 = 0)
        (__ci_expr_old_28 = __local_i__goto_3955_7)
        (__local_i__goto_3955_7 = __local_i__goto_3955_7 + 1)
        if ((if __ci_expr_old_28 < 2: 1 else: 0) != 0) {
            (__ci_expr_logic_29 = (if isxdigit((unsafe: *__local_p__goto_3840_10)) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_29 != 0) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_124 {
        (__ci_expr_ternary_30 = 0)
        if (isdigit((unsafe: *__local_p__goto_3840_10)) != 0) {
            (__ci_expr_ternary_30 = 48)
        } else {
            (__ci_expr_ternary_30 = 97 - 10)
        }
        (__local_c__goto_3838_10 = ((((__local_c__goto_3838_10 as c_uint) *% (16 as c_uint)) as c_uint) +% ((tolower((unsafe: *__local_p__goto_3840_10)) - __ci_expr_ternary_30) as c_uint)))
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + 1)
        goto '__ci_bb_123
    }

    '__ci_bb_125 {
        (__local_c__goto_3838_10 = __local_c__goto_3838_10)
        if (__local_utf__goto_3844_6 != 0) {
            goto '__ci_bb_126
        } else {
            goto '__ci_bb_127
        }
    }

    '__ci_bb_126 {
        (__local_encoding__goto_3957_23 = 1)
        goto '__ci_bb_127
    }

    '__ci_bb_127 {
        goto '__ci_bb_109
    }

    '__ci_bb_128 {
        (__ci_expr_logic_31 = 0)
        if ((if with_memcmp((__local_p__goto_3840_10 as *i8), ("{U+" as *i8), (3 as i64)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_31 = (if isxdigit((unsafe: __local_p__goto_3840_10[3])) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_31 != 0) {
            goto '__ci_bb_129
        } else {
            goto '__ci_bb_130
        }
    }

    '__ci_bb_129 {
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 + ((3 as isize) as usize))
        ((unsafe: *__error()) = 0)
        (__local_uli__goto_4162_21 = strtoul((__local_p__goto_3840_10 as *const c_char), (&raw mut __local_endptr__goto_4161_13 as *mut *mut c_char), 16))
        (__ci_expr_logic_33 = 0)
        (__ci_expr_logic_32 = 0)
        if ((if (unsafe: *__error()) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_32 = (if (if (unsafe: *__local_endptr__goto_4161_13) == 125: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_32 != 0) {
            (__ci_expr_logic_33 = (if (if __local_uli__goto_4162_21 <= 4294967295: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_33 != 0) {
            goto '__ci_bb_131
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_130 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Malformed \\N{U+ escape\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_131 {
        (__local_c__goto_3838_10 = ((__local_uli__goto_4162_21 as c_uint)))
        (__local_p__goto_3840_10 = (__local_endptr__goto_4161_13 as *mut u8) + ((1 as isize) as usize))
        (__local_encoding__goto_3957_23 = 2)
        goto '__ci_bb_79
    }

    '__ci_bb_132 {
        goto '__ci_bb_130
    }

    '__ci_bb_133 {
        (__local_p__goto_3840_10 = __local_p__goto_3840_10 - 1)
        goto '__ci_bb_33
    }

    '__ci_bb_134 {
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        ((unsafe: *__local_q__goto_3851_14) = 0)
        (__local_len__goto_3841_8 = ((__local_q__goto_3851_14 as usize) -% (dbuffer as usize)) / sizeof[u8]())
        (__local_ulen__goto_3836_12 = (__local_len__goto_3841_8 as c_ulong) / (1 as c_ulong))
        (__local_arg_ulen__goto_3836_18 = __local_ulen__goto_3836_12)
        (__ci_expr_logic_38 = 0)
        if ((if (unsafe: __local_p__goto_3840_10[-1]) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_38 = (if (if not (decode_modifiers_8(__local_p__goto_3840_10, CTX_DAT, null, (&raw mut dat_datctl as *mut datctl)) != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_38 != 0) {
            goto '__ci_bb_174
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_136 {
        if ((if __local_start_rep__goto_3852_14 != null: 1 else: 0) != 0) {
            goto '__ci_bb_137
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_137 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Nested replication is not supported\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_138 {
        (__local_start_rep__goto_3852_14 = __local_q__goto_3851_14)
        goto '__ci_bb_33
    }

    '__ci_bb_139 {
        if (isalnum(__local_c__goto_3838_10) != 0) {
            goto '__ci_bb_140
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_140 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Unrecognized escape sequence \"\\%c\"\n", __local_c__goto_3838_10)
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_141 {
        goto '__ci_bb_79
    }

    '__ci_bb_142 {
        if (__ci_expr_switch_17 == 97) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_143 {
        if (__ci_expr_switch_17 == 98) {
            goto '__ci_bb_82
        } else {
            goto '__ci_bb_144
        }
    }

    '__ci_bb_144 {
        if (__ci_expr_switch_17 == 101) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_145 {
        if (__ci_expr_switch_17 == 102) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_146 {
        if (__ci_expr_switch_17 == 110) {
            goto '__ci_bb_85
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_147 {
        if (__ci_expr_switch_17 == 114) {
            goto '__ci_bb_86
        } else {
            goto '__ci_bb_148
        }
    }

    '__ci_bb_148 {
        if (__ci_expr_switch_17 == 116) {
            goto '__ci_bb_87
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_149 {
        if (__ci_expr_switch_17 == 118) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_150
        }
    }

    '__ci_bb_150 {
        if (__ci_expr_switch_17 == 48) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_151 {
        if (__ci_expr_switch_17 == 49) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_152
        }
    }

    '__ci_bb_152 {
        if (__ci_expr_switch_17 == 50) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_153
        }
    }

    '__ci_bb_153 {
        if (__ci_expr_switch_17 == 51) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_154 {
        if (__ci_expr_switch_17 == 52) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_155
        }
    }

    '__ci_bb_155 {
        if (__ci_expr_switch_17 == 53) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_156 {
        if (__ci_expr_switch_17 == 54) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_157
        }
    }

    '__ci_bb_157 {
        if (__ci_expr_switch_17 == 55) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_158 {
        if (__ci_expr_switch_17 == 111) {
            goto '__ci_bb_93
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_159 {
        if (__ci_expr_switch_17 == 120) {
            goto '__ci_bb_106
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_160 {
        if (__ci_expr_switch_17 == 78) {
            goto '__ci_bb_128
        } else {
            goto '__ci_bb_161
        }
    }

    '__ci_bb_161 {
        if (__ci_expr_switch_17 == 0) {
            goto '__ci_bb_133
        } else {
            goto '__ci_bb_162
        }
    }

    '__ci_bb_162 {
        if (__ci_expr_switch_17 == 61) {
            goto '__ci_bb_134
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_163 {
        if (__ci_expr_switch_17 == 91) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_164 {
        if ((if __local_c__goto_3838_10 > 255: 1 else: 0) != 0) {
            goto '__ci_bb_167
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_165 {
        if ((if __local_c__goto_3838_10 > 2147483647: 1 else: 0) != 0) {
            goto '__ci_bb_169
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_166 {
        goto '__ci_bb_33
    }

    '__ci_bb_167 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Character \\x{%x} is greater than 255 and UTF-8 mode is not enabled.\n", __local_c__goto_3838_10)
        colour_end(outfile)
        colour_begin(31, outfile)
        fprintf(outfile, "** Truncation will probably give the wrong result.\n")
        colour_end(outfile)
        goto '__ci_bb_168
    }

    '__ci_bb_168 {
        (__ci_expr_old_36 = __local_q__goto_3851_14)
        (__local_q__goto_3851_14 = __local_q__goto_3851_14 + 1)
        ((unsafe: *__ci_expr_old_36) = ((__local_c__goto_3838_10 as u8)))
        goto '__ci_bb_166
    }

    '__ci_bb_169 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Character \\N{U+%x} is greater than 0x7fffffff and therefore cannot be encoded as UTF-8\n", __local_c__goto_3838_10)
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_170 {
        (__ci_expr_logic_37 = 0)
        if ((if __local_encoding__goto_3957_23 == 2: 1 else: 0) != 0) {
            (__ci_expr_logic_37 = (if (if __local_c__goto_3838_10 > 1114111: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_37 != 0) {
            goto '__ci_bb_172
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_171 {
        (__local_q__goto_3851_14 = __local_q__goto_3851_14 + ((ord_to_utf8(__local_c__goto_3838_10, __local_q__goto_3851_14) as isize) as usize))
        goto '__ci_bb_166
    }

    '__ci_bb_172 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Warning: character \\N{U+%x} is greater than 0x%x and should not be encoded as UTF-8\n", __local_c__goto_3838_10, 1114111)
        colour_end(outfile)
        goto '__ci_bb_173
    }

    '__ci_bb_173 {
        goto '__ci_bb_171
    }

    '__ci_bb_174 {
        return PR_OK
    }

    '__ci_bb_175 {
        if ((if (&raw const dat_datctl as *const datctl).substitute_skip != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_39 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_39 = (if (if (&raw const dat_datctl as *const datctl).substitute_stop != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_39 != 0) {
            goto '__ci_bb_176
        } else {
            goto '__ci_bb_177
        }
    }

    '__ci_bb_176 {
        (dat_datctl.control2 = (&raw const dat_datctl as *const datctl).control2 | 1)
        goto '__ci_bb_177
    }

    '__ci_bb_177 {
        (__local_k__goto_3838_13 = 0)
        goto '__ci_bb_178
    }

    '__ci_bb_178 {
        if ((if __local_k__goto_3838_13 < (((3 * sizeof[c_uint]()) as c_ulong) / (sizeof[u32]() as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_179
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_179 {
        (__local_c__goto_3838_10 = ((&raw const dat_datctl as *const datctl).control as c_uint) & (exclusive_dat_controls[__local_k__goto_3838_13] as c_uint))
        (__ci_expr_logic_40 = 0)
        if ((if __local_c__goto_3838_10 != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_40 = (if (if __local_c__goto_3838_10 != ((__local_c__goto_3838_10 as c_uint) & ((((~__local_c__goto_3838_10) as c_uint) +% (1 as c_uint)) as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_40 != 0) {
            goto '__ci_bb_182
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_180 {
        (__local_k__goto_3838_13 = __local_k__goto_3838_13 + 1)
        goto '__ci_bb_178
    }

    '__ci_bb_181 {
        if ((if (&raw const dat_datctl as *const datctl).replacement[0] != 255: 1 else: 0) != 0) {
            goto '__ci_bb_184
        } else {
            goto '__ci_bb_185
        }
    }

    '__ci_bb_182 {
        show_controls(31, __local_c__goto_3838_10, 0, "** Not allowed together:")
        fprintf(outfile, "\n")
        return PR_OK
    }

    '__ci_bb_183 {
        goto '__ci_bb_180
    }

    '__ci_bb_184 {
        (__ci_expr_logic_41 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_41 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (4194304 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_41 != 0) {
            goto '__ci_bb_187
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_185 {
        if ((if (&raw const dat_datctl as *const datctl).substitute_subject[0] != 255: 1 else: 0) != 0) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_196
        }
    }

    '__ci_bb_186 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_197
        } else {
            goto '__ci_bb_198
        }
    }

    '__ci_bb_187 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Replacement callouts are not supported with null_context.\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_188 {
        (__ci_expr_logic_42 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (65536 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_42 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (4194304 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_42 != 0) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_189 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Replacement case callouts are not supported with null_context.\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_190 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_191 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Ignored with replacement text: allcaptures\n")
        colour_end(outfile)
        goto '__ci_bb_192
    }

    '__ci_bb_192 {
        (__ci_expr_logic_43 = 0)
        if ((if (&raw const dat_datctl as *const datctl).substitute_subject[0] != 255: 1 else: 0) != 0) {
            (__ci_expr_logic_43 = (if (if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_43 != 0) {
            goto '__ci_bb_193
        } else {
            goto '__ci_bb_194
        }
    }

    '__ci_bb_193 {
        colour_begin(31, outfile)
        fprintf(outfile, "** substitute_subject requires substitute_matched.\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_194 {
        goto '__ci_bb_186
    }

    '__ci_bb_195 {
        colour_begin(31, outfile)
        fprintf(outfile, "** substitute_subject requires replacement text.\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_196 {
        goto '__ci_bb_186
    }

    '__ci_bb_197 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_199
        } else {
            goto '__ci_bb_200
        }
    }

    '__ci_bb_198 {
        (__ci_expr_ternary_45 = 0)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (8388608 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_44 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_44 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_44 != 0) {
            (__ci_expr_ternary_45 = 1 * (8 / 8))
        } else {
            (__ci_expr_ternary_45 = 0)
        }
        (__local_c__goto_3838_10 = __ci_expr_ternary_45)
        (__local_pp__goto_3853_14 = ((with_memmove((((dbuffer + (dbuffer_size as usize)) - (((__local_len__goto_3841_8 as c_ulong) +% (__local_c__goto_3838_10 as c_ulong)) as usize)) as *i8), (dbuffer as *i8), (((__local_len__goto_3841_8 as c_ulong) +% (__local_c__goto_3838_10 as c_ulong)) as i64)) as *mut u8)))
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_203
        } else {
            goto '__ci_bb_204
        }
    }

    '__ci_bb_199 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Ignored for DFA matching: allcaptures\n")
        colour_end(outfile)
        goto '__ci_bb_200
    }

    '__ci_bb_200 {
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (536870912 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_201
        } else {
            goto '__ci_bb_202
        }
    }

    '__ci_bb_201 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Ignored for DFA matching: heapframes_size\n")
        colour_end(outfile)
        goto '__ci_bb_202
    }

    '__ci_bb_202 {
        goto '__ci_bb_198
    }

    '__ci_bb_203 {
        (__local_pp__goto_3853_14 = ((null as *mut u8)))
        goto '__ci_bb_204
    }

    '__ci_bb_204 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (8388608 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_206
        }
    }

    '__ci_bb_205 {
        (__local_eflags__goto_4393_7 = 0)
        (__local_pmatch__goto_4394_15 = ((null as *mut regmatch_t)))
        (__local_msg__goto_4396_15 = (("** Ignored with POSIX interface:" as *const c_char)))
        if ((if (&raw const dat_datctl as *const datctl).cerror[0] != 4294967295: 1 else: 0) != 0) {
            (__ci_expr_logic_46 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_46 = (if (if (&raw const dat_datctl as *const datctl).cerror[1] != 4294967295: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_46 != 0) {
            goto '__ci_bb_207
        } else {
            goto '__ci_bb_208
        }
    }

    '__ci_bb_206 {
        if ((if (&raw const dat_datctl as *const datctl).startend[0] != 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_264
        } else {
            goto '__ci_bb_265
        }
    }

    '__ci_bb_207 {
        prmsg((&raw mut __local_msg__goto_4396_15 as *mut *const c_char), "callout_error")
        goto '__ci_bb_208
    }

    '__ci_bb_208 {
        if ((if (&raw const dat_datctl as *const datctl).cfail[0] != 4294967295: 1 else: 0) != 0) {
            (__ci_expr_logic_47 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_47 = (if (if (&raw const dat_datctl as *const datctl).cfail[1] != 4294967295: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_47 != 0) {
            goto '__ci_bb_209
        } else {
            goto '__ci_bb_210
        }
    }

    '__ci_bb_209 {
        prmsg((&raw mut __local_msg__goto_4396_15 as *mut *const c_char), "callout_fail")
        goto '__ci_bb_210
    }

    '__ci_bb_210 {
        if ((if (&raw const dat_datctl as *const datctl).copy_numbers[0] >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_48 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_48 = (if (if (&raw const dat_datctl as *const datctl).copy_names[0] != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_48 != 0) {
            goto '__ci_bb_211
        } else {
            goto '__ci_bb_212
        }
    }

    '__ci_bb_211 {
        prmsg((&raw mut __local_msg__goto_4396_15 as *mut *const c_char), "copy")
        goto '__ci_bb_212
    }

    '__ci_bb_212 {
        if ((if (&raw const dat_datctl as *const datctl).get_numbers[0] >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_49 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_49 = (if (if (&raw const dat_datctl as *const datctl).get_names[0] != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_49 != 0) {
            goto '__ci_bb_213
        } else {
            goto '__ci_bb_214
        }
    }

    '__ci_bb_213 {
        prmsg((&raw mut __local_msg__goto_4396_15 as *mut *const c_char), "get")
        goto '__ci_bb_214
    }

    '__ci_bb_214 {
        if ((if (&raw const dat_datctl as *const datctl).jitstack != 0: 1 else: 0) != 0) {
            goto '__ci_bb_215
        } else {
            goto '__ci_bb_216
        }
    }

    '__ci_bb_215 {
        prmsg((&raw mut __local_msg__goto_4396_15 as *mut *const c_char), "jitstack")
        goto '__ci_bb_216
    }

    '__ci_bb_216 {
        if ((if (&raw const dat_datctl as *const datctl).offset != 0: 1 else: 0) != 0) {
            goto '__ci_bb_217
        } else {
            goto '__ci_bb_218
        }
    }

    '__ci_bb_217 {
        prmsg((&raw mut __local_msg__goto_4396_15 as *mut *const c_char), "offset")
        goto '__ci_bb_218
    }

    '__ci_bb_218 {
        if ((if (((&raw const dat_datctl as *const datctl).options as c_uint) & ((~((((1 as c_uint) | (4 as c_uint)) as c_uint) | (2 as c_uint))) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_219
        } else {
            goto '__ci_bb_220
        }
    }

    '__ci_bb_219 {
        colour_begin(31, outfile)
        fprintf(outfile, "%s", __local_msg__goto_4396_15)
        colour_end(outfile)
        show_match_options(31, (((&raw const dat_datctl as *const datctl).options as c_uint) & ((~((((1 as c_uint) | (4 as c_uint)) as c_uint) | (2 as c_uint))) as c_uint)))
        (__local_msg__goto_4396_15 = (("" as *const c_char)))
        goto '__ci_bb_220
    }

    '__ci_bb_220 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & ((~((1 as c_uint) | (2 as c_uint))) as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_50 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_50 = (if (if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & ((~8192) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_50 != 0) {
            goto '__ci_bb_221
        } else {
            goto '__ci_bb_222
        }
    }

    '__ci_bb_221 {
        show_controls(31, (((&raw const dat_datctl as *const datctl).control as c_uint) & ((~((1 as c_uint) | (2 as c_uint))) as c_uint)), (((&raw const dat_datctl as *const datctl).control2 as c_uint) & ((~8192) as c_uint)), __local_msg__goto_4396_15)
        (__local_msg__goto_4396_15 = (("" as *const c_char)))
        goto '__ci_bb_222
    }

    '__ci_bb_222 {
        if ((if (unsafe: __local_msg__goto_4396_15[0]) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_223
        } else {
            goto '__ci_bb_224
        }
    }

    '__ci_bb_223 {
        fprintf(outfile, "\n")
        goto '__ci_bb_224
    }

    '__ci_bb_224 {
        if ((if (&raw const dat_datctl as *const datctl).oveccount > 0: 1 else: 0) != 0) {
            goto '__ci_bb_225
        } else {
            goto '__ci_bb_226
        }
    }

    '__ci_bb_225 {
        (__local_pmatch__goto_4394_15 = (((with_alloc((((sizeof[regmatch_t]() as c_ulong) *% ((&raw const dat_datctl as *const datctl).oveccount as c_ulong)) as i64)) as *mut c_void) as *mut regmatch_t)))
        if ((if __local_pmatch__goto_4394_15 == null: 1 else: 0) != 0) {
            goto '__ci_bb_227
        } else {
            goto '__ci_bb_228
        }
    }

    '__ci_bb_226 {
        if ((if (&raw const dat_datctl as *const datctl).startend[0] != 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_229
        } else {
            goto '__ci_bb_230
        }
    }

    '__ci_bb_227 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Failed to get memory for recording matching information (size set = %du)\n", (&raw const dat_datctl as *const datctl).oveccount)
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_228 {
        goto '__ci_bb_226
    }

    '__ci_bb_229 {
        if ((if __local_pmatch__goto_4394_15 == null: 1 else: 0) != 0) {
            goto '__ci_bb_231
        } else {
            goto '__ci_bb_232
        }
    }

    '__ci_bb_230 {
        if ((if (((&raw const dat_datctl as *const datctl).options as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_233
        } else {
            goto '__ci_bb_234
        }
    }

    '__ci_bb_231 {
        (__local_pmatch__goto_4394_15 = ((&raw mut __local_startend_buf__goto_4395_14 as *mut regmatch_t)))
        goto '__ci_bb_232
    }

    '__ci_bb_232 {
        ((unsafe: __local_pmatch__goto_4394_15[0]).rm_so = (((&raw const dat_datctl as *const datctl).startend[0] as c_int)))
        (__ci_expr_ternary_51 = 0)
        if ((if (&raw const dat_datctl as *const datctl).startend[1] != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_51 = (((&raw const dat_datctl as *const datctl).startend[1] as c_int)))
        } else {
            (__ci_expr_ternary_51 = ((__local_len__goto_3841_8 as c_int)))
        }
        ((unsafe: __local_pmatch__goto_4394_15[0]).rm_eo = __ci_expr_ternary_51)
        (__local_eflags__goto_4393_7 = __local_eflags__goto_4393_7 | 128)
        goto '__ci_bb_230
    }

    '__ci_bb_233 {
        (__local_eflags__goto_4393_7 = __local_eflags__goto_4393_7 | 4)
        goto '__ci_bb_234
    }

    '__ci_bb_234 {
        if ((if (((&raw const dat_datctl as *const datctl).options as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_235
        } else {
            goto '__ci_bb_236
        }
    }

    '__ci_bb_235 {
        (__local_eflags__goto_4393_7 = __local_eflags__goto_4393_7 | 8)
        goto '__ci_bb_236
    }

    '__ci_bb_236 {
        if ((if (((&raw const dat_datctl as *const datctl).options as c_uint) & (4 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_237
        } else {
            goto '__ci_bb_238
        }
    }

    '__ci_bb_237 {
        (__local_eflags__goto_4393_7 = __local_eflags__goto_4393_7 | 256)
        goto '__ci_bb_238
    }

    '__ci_bb_238 {
        (__local_rc__goto_4392_7 = pcre2_regexec((&raw mut preg as *mut regex_t), (__local_pp__goto_3853_14 as *const c_char), (&raw const dat_datctl as *const datctl).oveccount, __local_pmatch__goto_4394_15, __local_eflags__goto_4393_7))
        if ((if __local_rc__goto_4392_7 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_239
        } else {
            goto '__ci_bb_240
        }
    }

    '__ci_bb_239 {
        (__local_usize__goto_4453_12 = pcre2_regerror(__local_rc__goto_4392_7, (&raw mut preg as *mut regex_t), (pbuffer8 as *mut c_char), pbuffer8_size))
        colour_begin(35, outfile)
        fprintf(outfile, "No match: POSIX code %d: ", __local_rc__goto_4392_7)
        colour_end(outfile)
        pchars_8(35, (pbuffer8 as *const u8), ((__local_usize__goto_4453_12 as c_ulong) -% (1 as c_ulong)), __local_utf__goto_3844_6, outfile)
        fputs("\n", outfile)
        goto '__ci_bb_241
    }

    '__ci_bb_240 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (16777216 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_242
        } else {
            goto '__ci_bb_243
        }
    }

    '__ci_bb_241 {
        if ((if __local_pmatch__goto_4394_15 != ((&raw mut __local_startend_buf__goto_4395_14 as *mut regmatch_t)): 1 else: 0) != 0) {
            goto '__ci_bb_262
        } else {
            goto '__ci_bb_263
        }
    }

    '__ci_bb_242 {
        fprintf(outfile, "Matched with REG_NOSUB\n")
        goto '__ci_bb_244
    }

    '__ci_bb_243 {
        if ((if (&raw const dat_datctl as *const datctl).oveccount == 0: 1 else: 0) != 0) {
            goto '__ci_bb_245
        } else {
            goto '__ci_bb_246
        }
    }

    '__ci_bb_244 {
        goto '__ci_bb_241
    }

    '__ci_bb_245 {
        fprintf(outfile, "Matched without capture\n")
        goto '__ci_bb_247
    }

    '__ci_bb_246 {
        (__local_last_printed__goto_4465_12 = (((&raw const dat_datctl as *const datctl).oveccount as c_ulong)))
        (__local_i__goto_4464_12 = 0)
        goto '__ci_bb_248
    }

    '__ci_bb_247 {
        goto '__ci_bb_244
    }

    '__ci_bb_248 {
        if ((if __local_i__goto_4464_12 < (((&raw const dat_datctl as *const datctl).oveccount as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_249
        } else {
            goto '__ci_bb_251
        }
    }

    '__ci_bb_249 {
        if ((if (unsafe: __local_pmatch__goto_4394_15[__local_i__goto_4464_12]).rm_so >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_252
        } else {
            goto '__ci_bb_253
        }
    }

    '__ci_bb_250 {
        (__local_i__goto_4464_12 = __local_i__goto_4464_12 + 1)
        goto '__ci_bb_248
    }

    '__ci_bb_251 {
        goto '__ci_bb_247
    }

    '__ci_bb_252 {
        (__local_start__goto_4470_20 = (unsafe: __local_pmatch__goto_4394_15[__local_i__goto_4464_12]).rm_so)
        (__local_end__goto_4471_20 = (unsafe: __local_pmatch__goto_4394_15[__local_i__goto_4464_12]).rm_eo)
        (__local_j__goto_4464_15 = ((__local_last_printed__goto_4465_12 as c_ulong) +% (1 as c_ulong)))
        goto '__ci_bb_254
    }

    '__ci_bb_253 {
        goto '__ci_bb_250
    }

    '__ci_bb_254 {
        if ((if __local_j__goto_4464_15 < __local_i__goto_4464_12: 1 else: 0) != 0) {
            goto '__ci_bb_255
        } else {
            goto '__ci_bb_257
        }
    }

    '__ci_bb_255 {
        fprintf(outfile, "%2d: <unset>\n", (__local_j__goto_4464_15 as c_int))
        goto '__ci_bb_256
    }

    '__ci_bb_256 {
        (__local_j__goto_4464_15 = __local_j__goto_4464_15 + 1)
        goto '__ci_bb_254
    }

    '__ci_bb_257 {
        (__local_last_printed__goto_4465_12 = __local_i__goto_4464_12)
        if ((if __local_start__goto_4470_20 > __local_end__goto_4471_20: 1 else: 0) != 0) {
            goto '__ci_bb_258
        } else {
            goto '__ci_bb_259
        }
    }

    '__ci_bb_258 {
        (__local_start__goto_4470_20 = (unsafe: __local_pmatch__goto_4394_15[__local_i__goto_4464_12]).rm_eo)
        (__local_end__goto_4471_20 = (unsafe: __local_pmatch__goto_4394_15[__local_i__goto_4464_12]).rm_so)
        colour_begin(35, outfile)
        fprintf(outfile, "Start of matched string is beyond its end - displaying from end to start.\n")
        colour_end(outfile)
        goto '__ci_bb_259
    }

    '__ci_bb_259 {
        fprintf(outfile, "%2d: ", (__local_i__goto_4464_12 as c_int))
        pchars_8(-1, (__local_pp__goto_3853_14 + (__local_start__goto_4470_20 as usize)), ((__local_end__goto_4471_20 as c_ulong) -% (__local_start__goto_4470_20 as c_ulong)), __local_utf__goto_3844_6, outfile)
        fprintf(outfile, "\n")
        (__ci_expr_logic_52 = 0)
        if ((if __local_i__goto_4464_12 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_52 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_52 != 0) {
            (__ci_expr_logic_53 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_53 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_53 != 0) {
            goto '__ci_bb_260
        } else {
            goto '__ci_bb_261
        }
    }

    '__ci_bb_260 {
        fprintf(outfile, "%2d+ ", (__local_i__goto_4464_12 as c_int))
        pchars_8(-1, (__local_pp__goto_3853_14 + (((unsafe: __local_pmatch__goto_4394_15[__local_i__goto_4464_12]).rm_eo as isize) as usize)), ((__local_len__goto_3841_8 as c_ulong) -% ((unsafe: __local_pmatch__goto_4394_15[__local_i__goto_4464_12]).rm_eo as c_ulong)), __local_utf__goto_3844_6, outfile)
        fprintf(outfile, "\n")
        goto '__ci_bb_261
    }

    '__ci_bb_261 {
        goto '__ci_bb_253
    }

    '__ci_bb_262 {
        with_free((__local_pmatch__goto_4394_15 as *mut i8))
        goto '__ci_bb_263
    }

    '__ci_bb_263 {
        return PR_OK
    }

    '__ci_bb_264 {
        colour_begin(31, outfile)
        fprintf(outfile, "** \\=posix_startend ignored for non-POSIX matching\n")
        colour_end(outfile)
        goto '__ci_bb_265
    }

    '__ci_bb_265 {
        (__ci_expr_logic_54 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (((8 as c_uint) | (512 as c_uint)) as c_uint)) == 8: 1 else: 0) != 0) {
            (__ci_expr_logic_54 = (if (if compiled_code_8.executable_jit != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_54 != 0) {
            goto '__ci_bb_266
        } else {
            goto '__ci_bb_267
        }
    }

    '__ci_bb_266 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Showing all consulted text is not supported by JIT: ignored\n")
        colour_end(outfile)
        (dat_datctl.control = (&raw const dat_datctl as *const datctl).control & (~8))
        goto '__ci_bb_267
    }

    '__ci_bb_267 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_268
        } else {
            goto '__ci_bb_269
        }
    }

    '__ci_bb_268 {
        (__local_arg_ulen__goto_3836_18 = (~(0 as c_ulong)))
        goto '__ci_bb_269
    }

    '__ci_bb_269 {
        (__ci_expr_ternary_55 = null)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (4194304 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_55 = ((null as *mut pcre2_real_match_context_8)))
        } else {
            (__ci_expr_ternary_55 = dat_context_8)
        }
        (__local_use_dat_context__goto_3843_22 = __ci_expr_ternary_55)
        (show_memory = (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (2097152 as c_uint)) != 0: 1 else: 0))
        (__ci_expr_logic_56 = 0)
        if (show_memory != 0) {
            (__ci_expr_logic_56 = (if (if (((((&raw const pat_patctl as *const patctl).control as c_uint) & ((&raw const dat_datctl as *const datctl).control as c_uint)) as c_uint) & (4194304 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_56 != 0) {
            goto '__ci_bb_270
        } else {
            goto '__ci_bb_271
        }
    }

    '__ci_bb_270 {
        colour_begin(31, outfile)
        fprintf(outfile, "** \\=memory requires either a pattern or a subject context: ignored\n")
        colour_end(outfile)
        goto '__ci_bb_271
    }

    '__ci_bb_271 {
        if ((if (&raw const dat_datctl as *const datctl).jitstack != 0: 1 else: 0) != 0) {
            goto '__ci_bb_272
        } else {
            goto '__ci_bb_273
        }
    }

    '__ci_bb_272 {
        if ((if (&raw const dat_datctl as *const datctl).jitstack != jit_stack_size_8: 1 else: 0) != 0) {
            goto '__ci_bb_275
        } else {
            goto '__ci_bb_276
        }
    }

    '__ci_bb_273 {
        if ((if jit_stack_8 != null: 1 else: 0) != 0) {
            goto '__ci_bb_277
        } else {
            goto '__ci_bb_278
        }
    }

    '__ci_bb_274 {
        (__ci_expr_logic_57 = 0)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_57 = (if (if jit_stack_8 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_57 != 0) {
            goto '__ci_bb_279
        } else {
            goto '__ci_bb_280
        }
    }

    '__ci_bb_275 {
        pcre2_jit_stack_free_8(jit_stack_8)
        (jit_stack_8 = pcre2_jit_stack_create_8(1, (((&raw const dat_datctl as *const datctl).jitstack as c_uint) *% (1024 as c_uint)), null))
        (jit_stack_size_8 = (&raw const dat_datctl as *const datctl).jitstack)
        goto '__ci_bb_276
    }

    '__ci_bb_276 {
        pcre2_jit_stack_assign_8(dat_context_8, jit_callback_8, jit_stack_8)
        goto '__ci_bb_274
    }

    '__ci_bb_277 {
        pcre2_jit_stack_assign_8(dat_context_8, null, null)
        pcre2_jit_stack_free_8(jit_stack_8)
        (jit_stack_8 = ((null as *mut pcre2_real_jit_stack_8)))
        (jit_stack_size_8 = 0)
        goto '__ci_bb_278
    }

    '__ci_bb_278 {
        goto '__ci_bb_274
    }

    '__ci_bb_279 {
        pcre2_jit_stack_assign_8(dat_context_8, jit_callback_8, null)
        goto '__ci_bb_280
    }

    '__ci_bb_280 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (256 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_281
        } else {
            goto '__ci_bb_282
        }
    }

    '__ci_bb_281 {
        pcre2_set_callout_8(dat_context_8, callout_function_8, (((&raw const (unsafe: *(&raw const dat_datctl as *const datctl)).callout_data as *const c_int) as *mut c_int) as *mut c_void))
        goto '__ci_bb_283
    }

    '__ci_bb_282 {
        pcre2_set_callout_8(dat_context_8, null, null)
        goto '__ci_bb_283
    }

    '__ci_bb_283 {
        if ((if (&raw const dat_datctl as *const datctl).oveccount == 0: 1 else: 0) != 0) {
            goto '__ci_bb_284
        } else {
            goto '__ci_bb_285
        }
    }

    '__ci_bb_284 {
        pcre2_match_data_free_8(match_data_8)
        (match_data_8 = pcre2_match_data_create_from_pattern_8(compiled_code_8, general_context_8))
        (max_oveccount = pcre2_get_ovector_count_8(match_data_8))
        goto '__ci_bb_286
    }

    '__ci_bb_285 {
        if ((if (&raw const dat_datctl as *const datctl).oveccount <= max_oveccount: 1 else: 0) != 0) {
            goto '__ci_bb_287
        } else {
            goto '__ci_bb_288
        }
    }

    '__ci_bb_286 {
        if ((if match_data_8 == null: 1 else: 0) != 0) {
            goto '__ci_bb_290
        } else {
            goto '__ci_bb_291
        }
    }

    '__ci_bb_287 {
        ((unsafe: *match_data_8).oveccount = (&raw const dat_datctl as *const datctl).oveccount)
        goto '__ci_bb_289
    }

    '__ci_bb_288 {
        (max_oveccount = (&raw const dat_datctl as *const datctl).oveccount)
        pcre2_match_data_free_8(match_data_8)
        (match_data_8 = pcre2_match_data_create_8(max_oveccount, general_context_8))
        goto '__ci_bb_289
    }

    '__ci_bb_289 {
        goto '__ci_bb_286
    }

    '__ci_bb_290 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Failed to get memory for recording matching information (size requested: %d)\n", (&raw const dat_datctl as *const datctl).oveccount)
        colour_end(outfile)
        (max_oveccount = 0)
        return PR_ABEND
    }

    '__ci_bb_291 {
        (__local_ovector__goto_3847_13 = (&(unsafe: match_data_8.ovector[0]) as *mut c_ulong))
        (__local_oveccount__goto_3849_10 = pcre2_get_ovector_count_8(match_data_8))
        (__ci_expr_logic_59 = 0)
        (__ci_expr_logic_58 = 0)
        if ((if (&raw const dat_datctl as *const datctl).replacement[0] != 255: 1 else: 0) != 0) {
            (__ci_expr_logic_58 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_58 != 0) {
            (__ci_expr_logic_59 = (if (if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_59 != 0) {
            goto '__ci_bb_292
        } else {
            goto '__ci_bb_293
        }
    }

    '__ci_bb_292 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Ignored for DFA matching: replace\n")
        colour_end(outfile)
        (dat_datctl.replacement[0] = 255)
        goto '__ci_bb_293
    }

    '__ci_bb_293 {
        if ((if (&raw const dat_datctl as *const datctl).replacement[0] != 255: 1 else: 0) != 0) {
            goto '__ci_bb_294
        } else {
            goto '__ci_bb_295
        }
    }

    '__ci_bb_294 {
        (__local_j__goto_4653_14 = 0)
        goto '__ci_bb_296
    }

    '__ci_bb_295 {
        (__local_gmatched__goto_3837_10 = 0)
        goto '__ci_bb_377
    }

    '__ci_bb_296 {
        if ((if __local_j__goto_4653_14 < ((2 as c_uint) *% (__local_oveccount__goto_3849_10 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_297
        } else {
            goto '__ci_bb_299
        }
    }

    '__ci_bb_297 {
        ((unsafe: __local_ovector__goto_3847_13[__local_j__goto_4653_14]) = 3735928559)
        goto '__ci_bb_298
    }

    '__ci_bb_298 {
        (__local_j__goto_4653_14 = __local_j__goto_4653_14 + 1)
        goto '__ci_bb_296
    }

    '__ci_bb_299 {
        if (timeitm != 0) {
            goto '__ci_bb_300
        } else {
            goto '__ci_bb_301
        }
    }

    '__ci_bb_300 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Timing is not supported with replace: ignored\n")
        colour_end(outfile)
        goto '__ci_bb_301
    }

    '__ci_bb_301 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (16 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_302
        } else {
            goto '__ci_bb_303
        }
    }

    '__ci_bb_302 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Altglobal is not supported with replace: ignored\n")
        colour_end(outfile)
        goto '__ci_bb_303
    }

    '__ci_bb_303 {
        (__ci_expr_ternary_60 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_60 = 0)
        } else {
            (__ci_expr_ternary_60 = 65536)
        }
        (__local_emoption__goto_4652_12 = __ci_expr_ternary_60)
        if ((if __local_emoption__goto_4652_12 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_304
        } else {
            goto '__ci_bb_305
        }
    }

    '__ci_bb_304 {
        reset_callout_state()
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_306
        } else {
            goto '__ci_bb_307
        }
    }

    '__ci_bb_305 {
        (__ci_expr_ternary_61 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (32768 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_61 = 0)
        } else {
            (__ci_expr_ternary_61 = 256)
        }
        (__ci_expr_ternary_62 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (2 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_62 = 0)
        } else {
            (__ci_expr_ternary_62 = 512)
        }
        (__ci_expr_ternary_63 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_63 = 0)
        } else {
            (__ci_expr_ternary_63 = 32768)
        }
        (__ci_expr_ternary_64 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_64 = 0)
        } else {
            (__ci_expr_ternary_64 = 4096)
        }
        (__ci_expr_ternary_65 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_65 = 0)
        } else {
            (__ci_expr_ternary_65 = 131072)
        }
        (__ci_expr_ternary_66 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (64 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_66 = 0)
        } else {
            (__ci_expr_ternary_66 = 2048)
        }
        (__ci_expr_ternary_67 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (128 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_67 = 0)
        } else {
            (__ci_expr_ternary_67 = 1024)
        }
        (__local_xoptions__goto_4651_12 = (((((((((((((__local_emoption__goto_4652_12 as c_uint) | (__ci_expr_ternary_61 as c_uint)) as c_uint) | (__ci_expr_ternary_62 as c_uint)) as c_uint) | (__ci_expr_ternary_63 as c_uint)) as c_uint) | (__ci_expr_ternary_64 as c_uint)) as c_uint) | (__ci_expr_ternary_65 as c_uint)) as c_uint) | (__ci_expr_ternary_66 as c_uint)) as c_uint) | (__ci_expr_ternary_67 as c_uint))
        (__local_pr__goto_4647_12 = (&(unsafe: (&raw const dat_datctl as *const datctl).replacement[0]) as *mut u8) + ((1 as isize) as usize))
        (__local_prend__goto_4647_17 = __local_pr__goto_4647_12 + (((&raw const dat_datctl as *const datctl).replacement[0] as c_uint) as usize))
        (__local_nsize__goto_4653_34 = rep_out_buffer_size_8)
        (__ci_expr_logic_68 = 0)
        if ((if __local_pr__goto_4647_12 < __local_prend__goto_4647_17: 1 else: 0) != 0) {
            (__ci_expr_logic_68 = (if (if (unsafe: *__local_pr__goto_4647_12) == 91: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_68 != 0) {
            goto '__ci_bb_314
        } else {
            goto '__ci_bb_315
        }
    }

    '__ci_bb_306 {
        if ((if dfa_workspace == null: 1 else: 0) != 0) {
            goto '__ci_bb_309
        } else {
            goto '__ci_bb_310
        }
    }

    '__ci_bb_307 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (262144 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_311
        } else {
            goto '__ci_bb_312
        }
    }

    '__ci_bb_308 {
        goto '__ci_bb_305
    }

    '__ci_bb_309 {
        (dfa_workspace = (((with_alloc((((1000 as c_ulong) *% (sizeof[c_int]() as c_ulong)) as i64)) as *mut c_void) as *mut c_int)))
        goto '__ci_bb_310
    }

    '__ci_bb_310 {
        ((unsafe: dfa_workspace[0]) = -1)
        pcre2_dfa_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (&raw const dat_datctl as *const datctl).options, match_data_8, __local_use_dat_context__goto_3843_22, dfa_workspace, 1000)
        goto '__ci_bb_308
    }

    '__ci_bb_311 {
        pcre2_jit_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (&raw const dat_datctl as *const datctl).options, match_data_8, __local_use_dat_context__goto_3843_22)
        goto '__ci_bb_313
    }

    '__ci_bb_312 {
        pcre2_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (&raw const dat_datctl as *const datctl).options, match_data_8, __local_use_dat_context__goto_3843_22)
        goto '__ci_bb_313
    }

    '__ci_bb_313 {
        goto '__ci_bb_308
    }

    '__ci_bb_314 {
        (__local_n__goto_4723_16 = 0)
        (__local_pr__goto_4647_12 = __local_pr__goto_4647_12 + 1)
        goto '__ci_bb_316
    }

    '__ci_bb_315 {
        copy_substitute_string_8(__local_utf__goto_3844_6, __local_pr__goto_4647_12, (((__local_prend__goto_4647_17 as usize) -% (__local_pr__goto_4647_12 as usize)) / sizeof[u8]()), rep_in_buffer_8, (&raw mut __local_rlen__goto_4653_17 as *mut c_ulong))
        (__local_full_rlen__goto_4653_23 = __local_rlen__goto_4653_17)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_324
        } else {
            goto '__ci_bb_325
        }
    }

    '__ci_bb_316 {
        (__ci_expr_logic_70 = 0)
        (__ci_expr_logic_69 = 0)
        if ((if __local_pr__goto_4647_12 < __local_prend__goto_4647_17: 1 else: 0) != 0) {
            (__local_c__goto_3838_10 = (unsafe: *__local_pr__goto_4647_12))

            (__ci_expr_logic_69 = (if (if __local_c__goto_3838_10 >= 48: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_69 != 0) {
            (__ci_expr_logic_70 = (if (if __local_c__goto_3838_10 <= 57: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_70 != 0) {
            goto '__ci_bb_317
        } else {
            goto '__ci_bb_319
        }
    }

    '__ci_bb_317 {
        (__local_n__goto_4723_16 = ((((__local_n__goto_4723_16 as c_ulong) *% (10 as c_ulong)) as c_ulong) +% (((__local_c__goto_3838_10 as c_uint) -% (48 as c_uint)) as c_ulong)))
        goto '__ci_bb_318
    }

    '__ci_bb_318 {
        (__local_pr__goto_4647_12 = __local_pr__goto_4647_12 + 1)
        goto '__ci_bb_316
    }

    '__ci_bb_319 {
        if ((if __local_pr__goto_4647_12 >= __local_prend__goto_4647_17: 1 else: 0) != 0) {
            (__ci_expr_logic_71 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_71 = (if (if (unsafe: *__local_pr__goto_4647_12) != 93: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_71 != 0) {
            goto '__ci_bb_320
        } else {
            goto '__ci_bb_321
        }
    }

    '__ci_bb_320 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Bad buffer size in replacement string\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_321 {
        (__local_pr__goto_4647_12 = __local_pr__goto_4647_12 + 1)
        if ((if __local_n__goto_4723_16 > __local_nsize__goto_4653_34: 1 else: 0) != 0) {
            goto '__ci_bb_322
        } else {
            goto '__ci_bb_323
        }
    }

    '__ci_bb_322 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Replacement buffer setting (%zu) is too large (max %zu)\n", __local_n__goto_4723_16, __local_nsize__goto_4653_34)
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_323 {
        (__local_nsize__goto_4653_34 = __local_n__goto_4723_16)
        goto '__ci_bb_315
    }

    '__ci_bb_324 {
        (__local_rlen__goto_4653_17 = (~(0 as c_ulong)))
        goto '__ci_bb_325
    }

    '__ci_bb_325 {
        (__ci_expr_ternary_72 = null)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (16384 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_72 = rep_in_buffer_8)
        } else {
            (__ci_expr_ternary_72 = ((null as *mut u8)))
        }
        (__local_rbptr__goto_4649_16 = __ci_expr_ternary_72)
        (__local_sbptr__goto_4650_16 = __local_pp__goto_3853_14)
        (__local_slen__goto_4653_54 = __local_arg_ulen__goto_3836_18)
        if ((if (&raw const dat_datctl as *const datctl).substitute_subject[0] != 255: 1 else: 0) != 0) {
            goto '__ci_bb_326
        } else {
            goto '__ci_bb_327
        }
    }

    '__ci_bb_326 {
        copy_substitute_string_8(__local_utf__goto_3844_6, ((&(unsafe: (&raw const dat_datctl as *const datctl).substitute_subject[0]) as *mut u8) + ((1 as isize) as usize)), (&raw const dat_datctl as *const datctl).substitute_subject[0], (&(unsafe: __local_sbuffer__goto_4648_15[0]) as *mut u8), (&raw mut __local_slen__goto_4653_54 as *mut c_ulong))
        if ((if __local_slen__goto_4653_54 > __local_ulen__goto_3836_12: 1 else: 0) != 0) {
            goto '__ci_bb_328
        } else {
            goto '__ci_bb_329
        }
    }

    '__ci_bb_327 {
        (__ci_expr_ternary_73 = null)
        if ((if ((131072 as c_uint) & ((&raw const dat_datctl as *const datctl).control2 as c_uint)) == 0: 1 else: 0) != 0) {
            (__ci_expr_ternary_73 = match_data_8)
        } else {
            (__ci_expr_ternary_73 = ((null as *mut pcre2_real_match_data_8)))
        }
        (__local_smatch_data__goto_4654_21 = __ci_expr_ternary_73)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_336
        } else {
            goto '__ci_bb_337
        }
    }

    '__ci_bb_328 {
        colour_begin(31, outfile)
        fprintf(outfile, "** substitute_subject is longer than match subject buffer\n")
        colour_end(outfile)
        return PR_OK
    }

    '__ci_bb_329 {
        if ((if __local_pp__goto_3853_14 != null: 1 else: 0) != 0) {
            goto '__ci_bb_330
        } else {
            goto '__ci_bb_331
        }
    }

    '__ci_bb_330 {
        with_memcpy((__local_pp__goto_3853_14 as *i8), ((&(unsafe: __local_sbuffer__goto_4648_15[0]) as *mut u8) as *i8), (((__local_slen__goto_4653_54 as c_ulong) *% (1 as c_ulong)) as i64))
        if ((if __local_slen__goto_4653_54 < __local_ulen__goto_3836_12: 1 else: 0) != 0) {
            goto '__ci_bb_332
        } else {
            goto '__ci_bb_333
        }
    }

    '__ci_bb_331 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & ((2147483648 as c_uint) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_334
        } else {
            goto '__ci_bb_335
        }
    }

    '__ci_bb_332 {
        ((unsafe: __local_pp__goto_3853_14[__local_slen__goto_4653_54]) = 0)
        goto '__ci_bb_333
    }

    '__ci_bb_333 {
        goto '__ci_bb_331
    }

    '__ci_bb_334 {
        (__local_slen__goto_4653_54 = (~(0 as c_ulong)))
        goto '__ci_bb_335
    }

    '__ci_bb_335 {
        goto '__ci_bb_327
    }

    '__ci_bb_336 {
        pcre2_set_substitute_callout_8(dat_context_8, substitute_callout_function_8, null)
        goto '__ci_bb_338
    }

    '__ci_bb_337 {
        pcre2_set_substitute_callout_8(dat_context_8, null, null)
        goto '__ci_bb_338
    }

    '__ci_bb_338 {
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (65536 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_339
        } else {
            goto '__ci_bb_340
        }
    }

    '__ci_bb_339 {
        pcre2_set_substitute_case_callout_8(dat_context_8, substitute_case_callout_function_8, null)
        goto '__ci_bb_341
    }

    '__ci_bb_340 {
        pcre2_set_substitute_case_callout_8(dat_context_8, null, null)
        goto '__ci_bb_341
    }

    '__ci_bb_341 {
        if (malloc_testing != 0) {
            goto '__ci_bb_342
        } else {
            goto '__ci_bb_343
        }
    }

    '__ci_bb_342 {
        goto '__ci_bb_344
    }

    '__ci_bb_343 {
        reset_callout_state()
        (__local_nsize_input__goto_4653_41 = __local_nsize__goto_4653_34)
        (__local_rc__goto_4646_7 = pcre2_substitute_8(compiled_code_8, __local_sbptr__goto_4650_16, __local_slen__goto_4653_54, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_xoptions__goto_4651_12 as c_uint)), __local_smatch_data__goto_4654_21, __local_use_dat_context__goto_3843_22, __local_rbptr__goto_4649_16, __local_rlen__goto_4653_17, rep_out_buffer_8, (&raw mut __local_nsize__goto_4653_34 as *mut c_ulong)))
        (__ci_expr_logic_74 = 0)
        if (malloc_testing != 0) {
            (__ci_expr_logic_74 = (if (if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_74 != 0) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_348
        }
    }

    '__ci_bb_344 {
        (__local_heapframes__goto_4831_23 = ((match_data_8.heapframes as *mut c_void)))
        (__local_memory_data__goto_4831_23 = (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).memory_data)
        (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).free(__local_heapframes__goto_4831_23, __local_memory_data__goto_4831_23)
        ((unsafe: *match_data_8).heapframes = ((null as *mut heapframe)))
        ((unsafe: *match_data_8).heapframes_size = 0)
        goto '__ci_bb_345
    }

    '__ci_bb_345 {
        if (0 != 0) {
            goto '__ci_bb_344
        } else {
            goto '__ci_bb_346
        }
    }

    '__ci_bb_346 {
        goto '__ci_bb_343
    }

    '__ci_bb_347 {
        (__local_i__goto_4842_14 = 0)
        (__local_target_mallocs__goto_4842_21 = mallocs_called)
        goto '__ci_bb_349
    }

    '__ci_bb_348 {
        if ((if __local_rc__goto_4646_7 < 0: 1 else: 0) != 0) {
            goto '__ci_bb_358
        } else {
            goto '__ci_bb_359
        }
    }

    '__ci_bb_349 {
        if ((if __local_i__goto_4842_14 <= __local_target_mallocs__goto_4842_21: 1 else: 0) != 0) {
            goto '__ci_bb_350
        } else {
            goto '__ci_bb_352
        }
    }

    '__ci_bb_350 {
        (__local_saved_outfile__goto_4844_13 = outfile)
        goto '__ci_bb_353
    }

    '__ci_bb_351 {
        (__local_i__goto_4842_14 = __local_i__goto_4842_14 + 1)
        goto '__ci_bb_349
    }

    '__ci_bb_352 {
        goto '__ci_bb_348
    }

    '__ci_bb_353 {
        (__local_heapframes__goto_4845_7 = ((match_data_8.heapframes as *mut c_void)))
        (__local_memory_data__goto_4845_7 = (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).memory_data)
        (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).free(__local_heapframes__goto_4845_7, __local_memory_data__goto_4845_7)
        ((unsafe: *match_data_8).heapframes = ((null as *mut heapframe)))
        ((unsafe: *match_data_8).heapframes_size = 0)
        goto '__ci_bb_354
    }

    '__ci_bb_354 {
        if (0 != 0) {
            goto '__ci_bb_353
        } else {
            goto '__ci_bb_355
        }
    }

    '__ci_bb_355 {
        reset_callout_state()
        (mallocs_until_failure = __local_i__goto_4842_14)
        (outfile = null)
        (__local_nsize__goto_4653_34 = __local_nsize_input__goto_4653_41)
        (__local_rc__goto_4646_7 = pcre2_substitute_8(compiled_code_8, __local_sbptr__goto_4650_16, __local_slen__goto_4653_54, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_xoptions__goto_4651_12 as c_uint)), __local_smatch_data__goto_4654_21, __local_use_dat_context__goto_3843_22, __local_rbptr__goto_4649_16, __local_rlen__goto_4653_17, rep_out_buffer_8, (&raw mut __local_nsize__goto_4653_34 as *mut c_ulong)))
        (mallocs_until_failure = 2147483647)
        (outfile = __local_saved_outfile__goto_4844_13)
        (__ci_expr_logic_75 = 0)
        if ((if __local_i__goto_4842_14 < __local_target_mallocs__goto_4842_21: 1 else: 0) != 0) {
            (__ci_expr_logic_75 = (if (if __local_rc__goto_4646_7 != -48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_75 != 0) {
            goto '__ci_bb_356
        } else {
            goto '__ci_bb_357
        }
    }

    '__ci_bb_356 {
        colour_begin(31, outfile)
        fprintf(outfile, "** malloc() Substitution test did not fail as expected (%d)\n", __local_rc__goto_4646_7)
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_357 {
        goto '__ci_bb_351
    }

    '__ci_bb_358 {
        colour_begin(35, outfile)
        fprintf(outfile, "Failed: error %d", __local_rc__goto_4646_7)
        colour_end(outfile)
        (__ci_expr_logic_76 = 0)
        if ((if __local_rc__goto_4646_7 != -48: 1 else: 0) != 0) {
            (__ci_expr_logic_76 = (if (if __local_nsize__goto_4653_34 != (~(0 as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_76 != 0) {
            goto '__ci_bb_361
        } else {
            goto '__ci_bb_362
        }
    }

    '__ci_bb_359 {
        colour_begin(35, outfile)
        fprintf(outfile, "%2d: ", __local_rc__goto_4646_7)
        colour_end(outfile)
        pchars_8(35, rep_out_buffer_8, __local_nsize__goto_4653_34, __local_utf__goto_3844_6, outfile)
        goto '__ci_bb_360
    }

    '__ci_bb_360 {
        fprintf(outfile, "\n")
        (show_memory = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_373
        } else {
            goto '__ci_bb_374
        }
    }

    '__ci_bb_361 {
        colour_begin(35, outfile)
        fprintf(outfile, " at offset %ld in replacement", (__local_nsize__goto_4653_34 as c_long))
        colour_end(outfile)
        goto '__ci_bb_362
    }

    '__ci_bb_362 {
        colour_begin(35, outfile)
        fprintf(outfile, ": ")
        colour_end(outfile)
        if ((if not (print_error_message_8(__local_rc__goto_4646_7, "", "") != 0): 1 else: 0) != 0) {
            goto '__ci_bb_363
        } else {
            goto '__ci_bb_364
        }
    }

    '__ci_bb_363 {
        return PR_ABEND
    }

    '__ci_bb_364 {
        (__ci_expr_logic_77 = 0)
        if ((if __local_rc__goto_4646_7 == -48: 1 else: 0) != 0) {
            (__ci_expr_logic_77 = (if (if ((__local_xoptions__goto_4651_12 as c_uint) & (4096 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_77 != 0) {
            goto '__ci_bb_365
        } else {
            goto '__ci_bb_366
        }
    }

    '__ci_bb_365 {
        colour_begin(35, outfile)
        fprintf(outfile, ": %ld code units are needed", (__local_nsize__goto_4653_34 as c_long))
        colour_end(outfile)
        goto '__ci_bb_366
    }

    '__ci_bb_366 {
        (__ci_expr_logic_78 = 0)
        if ((if __local_rc__goto_4646_7 != -48: 1 else: 0) != 0) {
            (__ci_expr_logic_78 = (if (if __local_nsize__goto_4653_34 != (~(0 as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_78 != 0) {
            goto '__ci_bb_367
        } else {
            goto '__ci_bb_368
        }
    }

    '__ci_bb_367 {
        colour_begin(35, outfile)
        fprintf(outfile, "\n        here: ")
        colour_end(outfile)
        if ((if __local_nsize__goto_4653_34 > 0: 1 else: 0) != 0) {
            goto '__ci_bb_369
        } else {
            goto '__ci_bb_370
        }
    }

    '__ci_bb_368 {
        goto '__ci_bb_360
    }

    '__ci_bb_369 {
        ptrunc_8(32, __local_rbptr__goto_4649_16, __local_full_rlen__goto_4653_23, __local_nsize__goto_4653_34, 1, __local_utf__goto_3844_6, outfile)
        fprintf(outfile, " ")
        goto '__ci_bb_370
    }

    '__ci_bb_370 {
        colour_begin(35, outfile)
        fprintf(outfile, "|<--|")
        colour_end(outfile)
        if ((if __local_nsize__goto_4653_34 < __local_full_rlen__goto_4653_23: 1 else: 0) != 0) {
            goto '__ci_bb_371
        } else {
            goto '__ci_bb_372
        }
    }

    '__ci_bb_371 {
        fprintf(outfile, " ")
        ptrunc_8(32, __local_rbptr__goto_4649_16, __local_full_rlen__goto_4653_23, __local_nsize__goto_4653_34, 0, __local_utf__goto_3844_6, outfile)
        goto '__ci_bb_372
    }

    '__ci_bb_372 {
        goto '__ci_bb_368
    }

    '__ci_bb_373 {
        show_ovector(__local_ovector__goto_3847_13, __local_oveccount__goto_3849_10)
        goto '__ci_bb_374
    }

    '__ci_bb_374 {
        (__ci_expr_logic_79 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (536870912 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_79 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_79 != 0) {
            goto '__ci_bb_375
        } else {
            goto '__ci_bb_376
        }
    }

    '__ci_bb_375 {
        show_heapframes_size_8()
        goto '__ci_bb_376
    }

    '__ci_bb_376 {
        return PR_OK
    }

    '__ci_bb_377 {
        goto '__ci_bb_378
    }

    '__ci_bb_378 {
        (__local_j__goto_4918_14 = 0)
        goto '__ci_bb_381
    }

    '__ci_bb_379 {
        (__local_gmatched__goto_3837_10 = __local_gmatched__goto_3837_10 + 1)
        goto '__ci_bb_377
    }

    '__ci_bb_380 {
        (__ci_expr_logic_120 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (536870912 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_120 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_120 != 0) {
            goto '__ci_bb_597
        } else {
            goto '__ci_bb_598
        }
    }

    '__ci_bb_381 {
        if ((if __local_j__goto_4918_14 < ((2 as c_uint) *% (__local_oveccount__goto_3849_10 as c_uint)): 1 else: 0) != 0) {
            goto '__ci_bb_382
        } else {
            goto '__ci_bb_384
        }
    }

    '__ci_bb_382 {
        ((unsafe: __local_ovector__goto_3847_13[__local_j__goto_4918_14]) = 3735928559)
        goto '__ci_bb_383
    }

    '__ci_bb_383 {
        (__local_j__goto_4918_14 = __local_j__goto_4918_14 + 1)
        goto '__ci_bb_381
    }

    '__ci_bb_384 {
        (jit_was_used = (if (((&raw const pat_patctl as *const patctl).control as c_uint) & (262144 as c_uint)) != 0: 1 else: 0))
        if ((if timeitm > 0: 1 else: 0) != 0) {
            goto '__ci_bb_385
        } else {
            goto '__ci_bb_386
        }
    }

    '__ci_bb_385 {
        (__local_saved_outfile__goto_4937_11 = outfile)
        (outfile = null)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_387
        } else {
            goto '__ci_bb_388
        }
    }

    '__ci_bb_386 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (((2048 as c_uint) | (4096 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_409
        } else {
            goto '__ci_bb_410
        }
    }

    '__ci_bb_387 {
        if ((if (((&raw const dat_datctl as *const datctl).options as c_uint) & (64 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_390
        } else {
            goto '__ci_bb_391
        }
    }

    '__ci_bb_388 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (262144 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_398
        } else {
            goto '__ci_bb_399
        }
    }

    '__ci_bb_389 {
        (__local_time_taken__goto_4936_25 = ((clock() as c_ulong) -% (__local_start_time__goto_4936_13 as c_ulong)))
        (total_match_time = total_match_time + __local_time_taken__goto_4936_25)
        (outfile = __local_saved_outfile__goto_4937_11)
        colour_begin(36, outfile)
        fprintf(outfile, "Match time %7.4f microseconds\n", ((((1000000 as c_ulong) / ((1000000 as c_ulong) as c_ulong)) * (__local_time_taken__goto_4936_25 as f64)) / timeitm))
        colour_end(outfile)
        goto '__ci_bb_386
    }

    '__ci_bb_390 {
        (outfile = __local_saved_outfile__goto_4937_11)
        colour_begin(31, outfile)
        fprintf(outfile, "** Timing DFA restarts is not supported\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_391 {
        if ((if dfa_workspace == null: 1 else: 0) != 0) {
            goto '__ci_bb_392
        } else {
            goto '__ci_bb_393
        }
    }

    '__ci_bb_392 {
        (dfa_workspace = (((with_alloc((((1000 as c_ulong) *% (sizeof[c_int]() as c_ulong)) as i64)) as *mut c_void) as *mut c_int)))
        goto '__ci_bb_393
    }

    '__ci_bb_393 {
        (__local_start_time__goto_4936_13 = clock())
        (__local_i__goto_4935_9 = 0)
        goto '__ci_bb_394
    }

    '__ci_bb_394 {
        if ((if __local_i__goto_4935_9 < timeitm: 1 else: 0) != 0) {
            goto '__ci_bb_395
        } else {
            goto '__ci_bb_397
        }
    }

    '__ci_bb_395 {
        pcre2_dfa_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_g_notempty__goto_3839_10 as c_uint)), match_data_8, __local_use_dat_context__goto_3843_22, dfa_workspace, 1000)
        goto '__ci_bb_396
    }

    '__ci_bb_396 {
        (__local_i__goto_4935_9 = __local_i__goto_4935_9 + 1)
        goto '__ci_bb_394
    }

    '__ci_bb_397 {
        goto '__ci_bb_389
    }

    '__ci_bb_398 {
        (__local_start_time__goto_4936_13 = clock())
        (__local_i__goto_4935_9 = 0)
        goto '__ci_bb_401
    }

    '__ci_bb_399 {
        (__local_start_time__goto_4936_13 = clock())
        (__local_i__goto_4935_9 = 0)
        goto '__ci_bb_405
    }

    '__ci_bb_400 {
        goto '__ci_bb_389
    }

    '__ci_bb_401 {
        if ((if __local_i__goto_4935_9 < timeitm: 1 else: 0) != 0) {
            goto '__ci_bb_402
        } else {
            goto '__ci_bb_404
        }
    }

    '__ci_bb_402 {
        pcre2_jit_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_g_notempty__goto_3839_10 as c_uint)), match_data_8, __local_use_dat_context__goto_3843_22)
        goto '__ci_bb_403
    }

    '__ci_bb_403 {
        (__local_i__goto_4935_9 = __local_i__goto_4935_9 + 1)
        goto '__ci_bb_401
    }

    '__ci_bb_404 {
        goto '__ci_bb_400
    }

    '__ci_bb_405 {
        if ((if __local_i__goto_4935_9 < timeitm: 1 else: 0) != 0) {
            goto '__ci_bb_406
        } else {
            goto '__ci_bb_408
        }
    }

    '__ci_bb_406 {
        pcre2_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_g_notempty__goto_3839_10 as c_uint)), match_data_8, __local_use_dat_context__goto_3843_22)
        goto '__ci_bb_407
    }

    '__ci_bb_407 {
        (__local_i__goto_4935_9 = __local_i__goto_4935_9 + 1)
        goto '__ci_bb_405
    }

    '__ci_bb_408 {
        goto '__ci_bb_400
    }

    '__ci_bb_409 {
        (__ci_expr_logic_81 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (4096 as c_uint)) == 0: 1 else: 0) != 0) {
            var __ci_expr_logic_80: c_int

            if ((if compiled_code_8.executable_jit == null: 1 else: 0) != 0) {
                (__ci_expr_logic_80 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_80 = (if (if (((&raw const dat_datctl as *const datctl).options as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_81 = (if __ci_expr_logic_80 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_81 != 0) {
            goto '__ci_bb_412
        } else {
            goto '__ci_bb_413
        }
    }

    '__ci_bb_410 {
        if (malloc_testing != 0) {
            goto '__ci_bb_418
        } else {
            goto '__ci_bb_419
        }
    }

    '__ci_bb_411 {
        (__ci_expr_logic_88 = 0)
        if ((if __local_capcount__goto_4919_7 < 0: 1 else: 0) != 0) {
            (__ci_expr_logic_88 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (((16 as c_uint) | (32768 as c_uint)) as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_88 != 0) {
            goto '__ci_bb_458
        } else {
            goto '__ci_bb_459
        }
    }

    '__ci_bb_412 {
        check_match_limit_8(__local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, -63, "heap")
        goto '__ci_bb_413
    }

    '__ci_bb_413 {
        (__local_capcount__goto_4919_7 = check_match_limit_8(__local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, -47, "match"))
        if ((if compiled_code_8.executable_jit == null: 1 else: 0) != 0) {
            (__ci_expr_logic_82 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_82 = (if (if (((&raw const dat_datctl as *const datctl).options as c_uint) & (8192 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_82 != 0) {
            (__ci_expr_logic_83 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_83 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_83 != 0) {
            goto '__ci_bb_414
        } else {
            goto '__ci_bb_415
        }
    }

    '__ci_bb_414 {
        (__local_capcount__goto_4919_7 = check_match_limit_8(__local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, -53, "depth"))
        goto '__ci_bb_415
    }

    '__ci_bb_415 {
        if ((if __local_capcount__goto_4919_7 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_416
        } else {
            goto '__ci_bb_417
        }
    }

    '__ci_bb_416 {
        colour_begin(35, outfile)
        fprintf(outfile, "Matched, but offsets vector is too small to show all matches\n")
        colour_end(outfile)
        (__local_capcount__goto_4919_7 = (&raw const dat_datctl as *const datctl).oveccount)
        goto '__ci_bb_417
    }

    '__ci_bb_417 {
        goto '__ci_bb_411
    }

    '__ci_bb_418 {
        goto '__ci_bb_420
    }

    '__ci_bb_419 {
        reset_callout_state()
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_423
        } else {
            goto '__ci_bb_424
        }
    }

    '__ci_bb_420 {
        (__local_heapframes__goto_5025_25 = ((match_data_8.heapframes as *mut c_void)))
        (__local_memory_data__goto_5025_25 = (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).memory_data)
        (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).free(__local_heapframes__goto_5025_25, __local_memory_data__goto_5025_25)
        ((unsafe: *match_data_8).heapframes = ((null as *mut heapframe)))
        ((unsafe: *match_data_8).heapframes_size = 0)
        goto '__ci_bb_421
    }

    '__ci_bb_421 {
        if (0 != 0) {
            goto '__ci_bb_420
        } else {
            goto '__ci_bb_422
        }
    }

    '__ci_bb_422 {
        goto '__ci_bb_419
    }

    '__ci_bb_423 {
        if ((if dfa_workspace == null: 1 else: 0) != 0) {
            goto '__ci_bb_426
        } else {
            goto '__ci_bb_427
        }
    }

    '__ci_bb_424 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (262144 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_432
        } else {
            goto '__ci_bb_433
        }
    }

    '__ci_bb_425 {
        (__ci_expr_logic_85 = 0)
        if (malloc_testing != 0) {
            (__ci_expr_logic_85 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (256 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_85 != 0) {
            goto '__ci_bb_437
        } else {
            goto '__ci_bb_438
        }
    }

    '__ci_bb_426 {
        (dfa_workspace = (((with_alloc((((1000 as c_ulong) *% (sizeof[c_int]() as c_ulong)) as i64)) as *mut c_void) as *mut c_int)))
        goto '__ci_bb_427
    }

    '__ci_bb_427 {
        (__ci_expr_old_84 = dfa_matched)
        (dfa_matched = dfa_matched + 1)
        if ((if __ci_expr_old_84 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_428
        } else {
            goto '__ci_bb_429
        }
    }

    '__ci_bb_428 {
        ((unsafe: dfa_workspace[0]) = -1)
        goto '__ci_bb_429
    }

    '__ci_bb_429 {
        (__local_capcount__goto_4919_7 = pcre2_dfa_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_g_notempty__goto_3839_10 as c_uint)), match_data_8, __local_use_dat_context__goto_3843_22, dfa_workspace, 1000))
        if ((if __local_capcount__goto_4919_7 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_430
        } else {
            goto '__ci_bb_431
        }
    }

    '__ci_bb_430 {
        colour_begin(35, outfile)
        fprintf(outfile, "Matched, but offsets vector is too small to show all matches\n")
        colour_end(outfile)
        (__local_capcount__goto_4919_7 = (&raw const dat_datctl as *const datctl).oveccount)
        goto '__ci_bb_431
    }

    '__ci_bb_431 {
        goto '__ci_bb_425
    }

    '__ci_bb_432 {
        (__local_capcount__goto_4919_7 = pcre2_jit_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_g_notempty__goto_3839_10 as c_uint)), match_data_8, __local_use_dat_context__goto_3843_22))
        goto '__ci_bb_434
    }

    '__ci_bb_433 {
        (__local_capcount__goto_4919_7 = pcre2_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_g_notempty__goto_3839_10 as c_uint)), match_data_8, __local_use_dat_context__goto_3843_22))
        goto '__ci_bb_434
    }

    '__ci_bb_434 {
        if ((if __local_capcount__goto_4919_7 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_435
        } else {
            goto '__ci_bb_436
        }
    }

    '__ci_bb_435 {
        colour_begin(35, outfile)
        fprintf(outfile, "Matched, but too many substrings\n")
        colour_end(outfile)
        (__local_capcount__goto_4919_7 = (&raw const dat_datctl as *const datctl).oveccount)
        goto '__ci_bb_436
    }

    '__ci_bb_436 {
        goto '__ci_bb_425
    }

    '__ci_bb_437 {
        (__local_i__goto_5061_16 = 0)
        (__local_target_mallocs__goto_5061_23 = mallocs_called)
        goto '__ci_bb_439
    }

    '__ci_bb_438 {
        goto '__ci_bb_411
    }

    '__ci_bb_439 {
        if ((if __local_i__goto_5061_16 <= __local_target_mallocs__goto_5061_23: 1 else: 0) != 0) {
            goto '__ci_bb_440
        } else {
            goto '__ci_bb_442
        }
    }

    '__ci_bb_440 {
        (__local_saved_outfile__goto_5063_15 = outfile)
        goto '__ci_bb_443
    }

    '__ci_bb_441 {
        (__local_i__goto_5061_16 = __local_i__goto_5061_16 + 1)
        goto '__ci_bb_439
    }

    '__ci_bb_442 {
        goto '__ci_bb_438
    }

    '__ci_bb_443 {
        (__local_heapframes__goto_5065_9 = ((match_data_8.heapframes as *mut c_void)))
        (__local_memory_data__goto_5065_9 = (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).memory_data)
        (&raw const (unsafe: *match_data_8).memctl as *const pcre2_memctl).free(__local_heapframes__goto_5065_9, __local_memory_data__goto_5065_9)
        ((unsafe: *match_data_8).heapframes = ((null as *mut heapframe)))
        ((unsafe: *match_data_8).heapframes_size = 0)
        goto '__ci_bb_444
    }

    '__ci_bb_444 {
        if (0 != 0) {
            goto '__ci_bb_443
        } else {
            goto '__ci_bb_445
        }
    }

    '__ci_bb_445 {
        reset_callout_state()
        (mallocs_until_failure = __local_i__goto_5061_16)
        (outfile = null)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_446
        } else {
            goto '__ci_bb_447
        }
    }

    '__ci_bb_446 {
        (__ci_expr_old_86 = dfa_matched)
        (dfa_matched = dfa_matched + 1)
        if ((if __ci_expr_old_86 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_449
        } else {
            goto '__ci_bb_450
        }
    }

    '__ci_bb_447 {
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (262144 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_451
        } else {
            goto '__ci_bb_452
        }
    }

    '__ci_bb_448 {
        (mallocs_until_failure = 2147483647)
        (outfile = __local_saved_outfile__goto_5063_15)
        if ((if __local_capcount__goto_4919_7 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_454
        } else {
            goto '__ci_bb_455
        }
    }

    '__ci_bb_449 {
        ((unsafe: dfa_workspace[0]) = -1)
        goto '__ci_bb_450
    }

    '__ci_bb_450 {
        (__local_capcount__goto_4919_7 = pcre2_dfa_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_g_notempty__goto_3839_10 as c_uint)), match_data_8, __local_use_dat_context__goto_3843_22, dfa_workspace, 1000))
        goto '__ci_bb_448
    }

    '__ci_bb_451 {
        (__local_capcount__goto_4919_7 = pcre2_jit_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_g_notempty__goto_3839_10 as c_uint)), match_data_8, __local_use_dat_context__goto_3843_22))
        goto '__ci_bb_453
    }

    '__ci_bb_452 {
        (__local_capcount__goto_4919_7 = pcre2_match_8(compiled_code_8, __local_pp__goto_3853_14, __local_arg_ulen__goto_3836_18, (&raw const dat_datctl as *const datctl).offset, (((&raw const dat_datctl as *const datctl).options as c_uint) | (__local_g_notempty__goto_3839_10 as c_uint)), match_data_8, __local_use_dat_context__goto_3843_22))
        goto '__ci_bb_453
    }

    '__ci_bb_453 {
        goto '__ci_bb_448
    }

    '__ci_bb_454 {
        (__local_capcount__goto_4919_7 = (&raw const dat_datctl as *const datctl).oveccount)
        goto '__ci_bb_455
    }

    '__ci_bb_455 {
        (__ci_expr_logic_87 = 0)
        if ((if __local_i__goto_5061_16 < __local_target_mallocs__goto_5061_23: 1 else: 0) != 0) {
            (__ci_expr_logic_87 = (if (if __local_capcount__goto_4919_7 != -48: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_87 != 0) {
            goto '__ci_bb_456
        } else {
            goto '__ci_bb_457
        }
    }

    '__ci_bb_456 {
        colour_begin(31, outfile)
        fprintf(outfile, "** malloc() match test did not fail as expected (%d)\n", __local_capcount__goto_4919_7)
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_457 {
        goto '__ci_bb_441
    }

    '__ci_bb_458 {
        (__local_tmp_offset__goto_5110_18 = 205)
        (__local_tmp_options__goto_5111_16 = 205)
        (__local_rc_nextmatch__goto_5109_12 = pcre2_next_match_8(match_data_8, (&raw mut __local_tmp_offset__goto_5110_18 as *mut c_ulong), (&raw mut __local_tmp_options__goto_5111_16 as *mut c_uint)))
        if (__local_rc_nextmatch__goto_5109_12 != 0) {
            (__ci_expr_logic_89 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_89 = (if (if __local_tmp_offset__goto_5110_18 != 205: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_89 != 0) {
            (__ci_expr_logic_90 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_90 = (if (if __local_tmp_options__goto_5111_16 != 205: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_90 != 0) {
            goto '__ci_bb_460
        } else {
            goto '__ci_bb_461
        }
    }

    '__ci_bb_459 {
        if ((if __local_capcount__goto_4919_7 >= 0: 1 else: 0) != 0) {
            goto '__ci_bb_462
        } else {
            goto '__ci_bb_463
        }
    }

    '__ci_bb_460 {
        colour_begin(31, outfile)
        fprintf(outfile, "** unexpected pcre2_next_match() for rc < 0\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_461 {
        goto '__ci_bb_459
    }

    '__ci_bb_462 {
        if ((if __local_pp__goto_3853_14 == null: 1 else: 0) != 0) {
            goto '__ci_bb_465
        } else {
            goto '__ci_bb_466
        }
    }

    '__ci_bb_463 {
        if ((if __local_capcount__goto_4919_7 == -2: 1 else: 0) != 0) {
            goto '__ci_bb_543
        } else {
            goto '__ci_bb_544
        }
    }

    '__ci_bb_464 {
        goto '__ci_bb_479
    }

    '__ci_bb_465 {
        (__local_pp__goto_3853_14 = dbuffer)
        ((unsafe: *__local_pp__goto_3853_14) = 0)
        goto '__ci_bb_466
    }

    '__ci_bb_466 {
        if ((if ((__local_capcount__goto_4919_7 as c_uint)) > __local_oveccount__goto_3849_10: 1 else: 0) != 0) {
            goto '__ci_bb_467
        } else {
            goto '__ci_bb_468
        }
    }

    '__ci_bb_467 {
        colour_begin(31, outfile)
        fprintf(outfile, "** PCRE2 error: returned count %d is too big for ovector count %d\n", __local_capcount__goto_4919_7, __local_oveccount__goto_3849_10)
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_468 {
        (__ci_expr_logic_91 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).options as c_uint) & (16384 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_91 = (if (if (((&raw const pat_patctl as *const patctl).control as c_uint) & (262144 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_91 != 0) {
            goto '__ci_bb_469
        } else {
            goto '__ci_bb_470
        }
    }

    '__ci_bb_469 {
        if ((if (((match_data_8.flags as c_int) as c_uint) & (1 as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_471
        } else {
            goto '__ci_bb_472
        }
    }

    '__ci_bb_470 {
        (__ci_expr_logic_95 = 0)
        (__ci_expr_logic_94 = 0)
        (__ci_expr_logic_93 = 0)
        if ((if __local_gmatched__goto_3837_10 > 0: 1 else: 0) != 0) {
            var __ci_expr_logic_92: c_int = 0

            if ((if (&raw const dat_datctl as *const datctl).offset <= (unsafe: __local_ovector__goto_3847_13[0]): 1 else: 0) != 0) {
                (__ci_expr_logic_92 = (if (if (unsafe: __local_ovector__goto_3847_13[0]) <= (unsafe: __local_ovector__goto_3847_13[1]): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_93 = (if (if not (__ci_expr_logic_92 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_93 != 0) {
            (__ci_expr_logic_94 = (if (if (__local_pp__goto_3853_14 + ((unsafe: __local_ovector__goto_3847_13[0]) as usize)) == __local_ovecsave__goto_3848_12[0]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_94 != 0) {
            (__ci_expr_logic_95 = (if (if (__local_pp__goto_3853_14 + ((unsafe: __local_ovector__goto_3847_13[1]) as usize)) == __local_ovecsave__goto_3848_12[1]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_95 != 0) {
            goto '__ci_bb_477
        } else {
            goto '__ci_bb_478
        }
    }

    '__ci_bb_471 {
        colour_begin(31, outfile)
        fprintf(outfile, "** PCRE2 error: flag not set after copy_matched_subject\n")
        colour_end(outfile)
        goto '__ci_bb_472
    }

    '__ci_bb_472 {
        if ((if match_data_8.subject == __local_pp__goto_3853_14: 1 else: 0) != 0) {
            goto '__ci_bb_473
        } else {
            goto '__ci_bb_474
        }
    }

    '__ci_bb_473 {
        colour_begin(31, outfile)
        fprintf(outfile, "** PCRE2 error: copy_matched_subject has not copied\n")
        colour_end(outfile)
        goto '__ci_bb_474
    }

    '__ci_bb_474 {
        if ((if with_memcmp((match_data_8.subject as *i8), (__local_pp__goto_3853_14 as *i8), (__local_ulen__goto_3836_12 as i64)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_475
        } else {
            goto '__ci_bb_476
        }
    }

    '__ci_bb_475 {
        colour_begin(31, outfile)
        fprintf(outfile, "** PCRE2 error: copy_matched_subject mismatch\n")
        colour_end(outfile)
        goto '__ci_bb_476
    }

    '__ci_bb_476 {
        goto '__ci_bb_470
    }

    '__ci_bb_477 {
        colour_begin(35, outfile)
        fprintf(outfile, "global repeat returned the same match as previous\n")
        colour_end(outfile)
        goto '__ci_bb_479
    }

    '__ci_bb_478 {
        (__ci_expr_logic_101 = 0)
        (__ci_expr_logic_97 = 0)
        if ((if __local_gmatched__goto_3837_10 > 0: 1 else: 0) != 0) {
            var __ci_expr_logic_96: c_int = 0

            if ((if (&raw const dat_datctl as *const datctl).offset <= (unsafe: __local_ovector__goto_3847_13[0]): 1 else: 0) != 0) {
                (__ci_expr_logic_96 = (if (if (unsafe: __local_ovector__goto_3847_13[0]) <= (unsafe: __local_ovector__goto_3847_13[1]): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_97 = (if __ci_expr_logic_96 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_97 != 0) {
            var __ci_expr_logic_100: c_int

            if ((if (__local_pp__goto_3853_14 + ((unsafe: __local_ovector__goto_3847_13[1]) as usize)) > __local_ovecsave__goto_3848_12[1]: 1 else: 0) != 0) {
                (__ci_expr_logic_100 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_99: c_int = 0

                var __ci_expr_logic_98: c_int = 0

                if ((if (unsafe: __local_ovector__goto_3847_13[1]) == (unsafe: __local_ovector__goto_3847_13[0]): 1 else: 0) != 0) {
                    (__ci_expr_logic_98 = (if (if __local_ovecsave__goto_3848_12[1] != __local_ovecsave__goto_3848_12[0]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_98 != 0) {
                    (__ci_expr_logic_99 = (if (if (__local_pp__goto_3853_14 + ((unsafe: __local_ovector__goto_3847_13[1]) as usize)) == __local_ovecsave__goto_3848_12[1]: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_100 = (if __ci_expr_logic_99 != 0: 1 else: 0))

            }

            (__ci_expr_logic_101 = (if (if not (__ci_expr_logic_100 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_101 != 0) {
            goto '__ci_bb_480
        } else {
            goto '__ci_bb_481
        }
    }

    '__ci_bb_479 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (((16 as c_uint) | (32768 as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_587
        } else {
            goto '__ci_bb_588
        }
    }

    '__ci_bb_480 {
        colour_begin(31, outfile)
        fprintf(outfile, "** PCRE2 error: global repeat did not make progress\n")
        colour_end(outfile)
        return PR_ABEND
    }

    '__ci_bb_481 {
        (__local_ovecsave__goto_3848_12[0] = __local_pp__goto_3853_14 + ((unsafe: __local_ovector__goto_3847_13[0]) as usize))
        (__local_ovecsave__goto_3848_12[1] = __local_pp__goto_3853_14 + ((unsafe: __local_ovector__goto_3847_13[1]) as usize))
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (((4 as c_uint) | (512 as c_uint)) as c_uint)) == 4: 1 else: 0) != 0) {
            goto '__ci_bb_482
        } else {
            goto '__ci_bb_483
        }
    }

    '__ci_bb_482 {
        (__local_capcount__goto_4919_7 = ((maxcapcount as c_uint) +% (1 as c_uint)))
        if ((if ((__local_capcount__goto_4919_7 as c_uint)) > __local_oveccount__goto_3849_10: 1 else: 0) != 0) {
            goto '__ci_bb_484
        } else {
            goto '__ci_bb_485
        }
    }

    '__ci_bb_483 {
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_486
        } else {
            goto '__ci_bb_487
        }
    }

    '__ci_bb_484 {
        (__local_capcount__goto_4919_7 = __local_oveccount__goto_3849_10)
        goto '__ci_bb_485
    }

    '__ci_bb_485 {
        goto '__ci_bb_483
    }

    '__ci_bb_486 {
        (__local_capcount__goto_4919_7 = __local_oveccount__goto_3849_10)
        goto '__ci_bb_487
    }

    '__ci_bb_487 {
        (__local_i__goto_5229_14 = 0)
        goto '__ci_bb_488
    }

    '__ci_bb_488 {
        if ((if __local_i__goto_5229_14 < (2 * __local_capcount__goto_4919_7): 1 else: 0) != 0) {
            goto '__ci_bb_489
        } else {
            goto '__ci_bb_491
        }
    }

    '__ci_bb_489 {
        (__local_start__goto_5232_18 = (unsafe: __local_ovector__goto_3847_13[__local_i__goto_5229_14]))
        (__local_end__goto_5233_18 = (unsafe: __local_ovector__goto_3847_13[(__local_i__goto_5229_14 + 1)]))
        if ((if __local_start__goto_5232_18 > __local_end__goto_5233_18: 1 else: 0) != 0) {
            goto '__ci_bb_492
        } else {
            goto '__ci_bb_493
        }
    }

    '__ci_bb_490 {
        (__local_i__goto_5229_14 = __local_i__goto_5229_14 + 2)
        goto '__ci_bb_488
    }

    '__ci_bb_491 {
        (__ci_expr_logic_114 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (1048576 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_114 = (if (if match_data_8.mark != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_114 != 0) {
            goto '__ci_bb_539
        } else {
            goto '__ci_bb_540
        }
    }

    '__ci_bb_492 {
        (__local_start__goto_5232_18 = (unsafe: __local_ovector__goto_3847_13[(__local_i__goto_5229_14 + 1)]))
        (__local_end__goto_5233_18 = (unsafe: __local_ovector__goto_3847_13[__local_i__goto_5229_14]))
        colour_begin(35, outfile)
        fprintf(outfile, "Start of matched string is beyond its end - displaying from end to start.\n")
        colour_end(outfile)
        goto '__ci_bb_493
    }

    '__ci_bb_493 {
        fprintf(outfile, "%2d: ", (__local_i__goto_5229_14 / 2))
        (__ci_expr_logic_102 = 0)
        if ((if __local_start__goto_5232_18 == (~(0 as c_ulong)): 1 else: 0) != 0) {
            (__ci_expr_logic_102 = (if (if __local_end__goto_5233_18 == (~(0 as c_ulong)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_102 != 0) {
            goto '__ci_bb_494
        } else {
            goto '__ci_bb_495
        }
    }

    '__ci_bb_494 {
        fprintf(outfile, "<unset>\n")
        goto '__ci_bb_490
    }

    '__ci_bb_495 {
        if ((if __local_start__goto_5232_18 > __local_ulen__goto_3836_12: 1 else: 0) != 0) {
            (__ci_expr_logic_103 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_103 = (if (if __local_end__goto_5233_18 > __local_ulen__goto_3836_12: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_103 != 0) {
            goto '__ci_bb_496
        } else {
            goto '__ci_bb_497
        }
    }

    '__ci_bb_496 {
        (__ci_expr_logic_106 = 0)
        (__ci_expr_logic_105 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (512 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_104 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_104 = (if (if __local_i__goto_5229_14 >= ((((((2 as c_uint) *% (maxcapcount as c_uint)) as c_uint) +% (2 as c_uint)) as c_int)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_104 != 0) {
            (__ci_expr_logic_105 = (if (if __local_start__goto_5232_18 == 3735928559: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_105 != 0) {
            (__ci_expr_logic_106 = (if (if __local_end__goto_5233_18 == 3735928559: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_106 != 0) {
            goto '__ci_bb_498
        } else {
            goto '__ci_bb_499
        }
    }

    '__ci_bb_497 {
        if ((if __local_i__goto_5229_14 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_501
        } else {
            goto '__ci_bb_502
        }
    }

    '__ci_bb_498 {
        fprintf(outfile, "<unchanged>\n")
        goto '__ci_bb_500
    }

    '__ci_bb_499 {
        colour_begin(31, outfile)
        fprintf(outfile, "** ERROR: bad value(s) for offset(s): 0x%lx 0x%lx\n", __local_start__goto_5232_18, __local_end__goto_5233_18)
        colour_end(outfile)
        goto '__ci_bb_500
    }

    '__ci_bb_500 {
        goto '__ci_bb_490
    }

    '__ci_bb_501 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_504
        } else {
            goto '__ci_bb_505
        }
    }

    '__ci_bb_502 {
        pchars_8(-1, (__local_pp__goto_3853_14 + (__local_start__goto_5232_18 as usize)), ((__local_end__goto_5233_18 as c_ulong) -% (__local_start__goto_5232_18 as c_ulong)), __local_utf__goto_3844_6, outfile)
        goto '__ci_bb_503
    }

    '__ci_bb_503 {
        fprintf(outfile, "\n")
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (2 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_113 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_112: c_int = 0

            if ((if __local_i__goto_5229_14 == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_112 = (if (if (((&raw const dat_datctl as *const datctl).control as c_uint) & (1 as c_uint)) != 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_113 = (if __ci_expr_logic_112 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_113 != 0) {
            goto '__ci_bb_537
        } else {
            goto '__ci_bb_538
        }
    }

    '__ci_bb_504 {
        (__local_leftchar__goto_5281_20 = match_data_8.leftchar)
        (__local_rightchar__goto_5281_30 = match_data_8.rightchar)
        (__ci_expr_logic_108 = 0)
        if ((if __local_i__goto_5229_14 == 0: 1 else: 0) != 0) {
            var __ci_expr_logic_107: c_int

            if ((if __local_leftchar__goto_5281_20 < __local_start__goto_5232_18: 1 else: 0) != 0) {
                (__ci_expr_logic_107 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_107 = (if (if __local_rightchar__goto_5281_30 > __local_end__goto_5233_18: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_108 = (if __ci_expr_logic_107 != 0: 1 else: 0))

        }
        (__local_showallused__goto_5280_14 = __ci_expr_logic_108)
        goto '__ci_bb_506
    }

    '__ci_bb_505 {
        (__local_showallused__goto_5280_14 = 0)
        goto '__ci_bb_506
    }

    '__ci_bb_506 {
        if (__local_showallused__goto_5280_14 != 0) {
            goto '__ci_bb_507
        } else {
            goto '__ci_bb_508
        }
    }

    '__ci_bb_507 {
        (__local_lleft__goto_5231_18 = pchars_8(-1, (__local_pp__goto_3853_14 + (__local_leftchar__goto_5281_20 as usize)), ((__local_start__goto_5232_18 as c_ulong) -% (__local_leftchar__goto_5281_20 as c_ulong)), __local_utf__goto_3844_6, outfile))
        (__local_lmiddle__goto_5231_25 = pchars_8(-1, (__local_pp__goto_3853_14 + (__local_start__goto_5232_18 as usize)), ((__local_end__goto_5233_18 as c_ulong) -% (__local_start__goto_5232_18 as c_ulong)), __local_utf__goto_3844_6, outfile))
        (__local_lright__goto_5231_34 = pchars_8(-1, (__local_pp__goto_3853_14 + (__local_end__goto_5233_18 as usize)), ((__local_rightchar__goto_5281_30 as c_ulong) -% (__local_end__goto_5233_18 as c_ulong)), __local_utf__goto_3844_6, outfile))
        (__ci_expr_logic_109 = 0)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_109 = (if jit_was_used != 0: 1 else: 0))
        }
        if (__ci_expr_logic_109 != 0) {
            goto '__ci_bb_510
        } else {
            goto '__ci_bb_511
        }
    }

    '__ci_bb_508 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (268435456 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_524
        } else {
            goto '__ci_bb_525
        }
    }

    '__ci_bb_509 {
        goto '__ci_bb_503
    }

    '__ci_bb_510 {
        fprintf(outfile, " (JIT)")
        goto '__ci_bb_511
    }

    '__ci_bb_511 {
        fprintf(outfile, "\n    ")
        (__local_j__goto_4918_14 = 0)
        goto '__ci_bb_512
    }

    '__ci_bb_512 {
        if ((if __local_j__goto_4918_14 < __local_lleft__goto_5231_18: 1 else: 0) != 0) {
            goto '__ci_bb_513
        } else {
            goto '__ci_bb_515
        }
    }

    '__ci_bb_513 {
        fprintf(outfile, "<")
        goto '__ci_bb_514
    }

    '__ci_bb_514 {
        (__local_j__goto_4918_14 = __local_j__goto_4918_14 + 1)
        goto '__ci_bb_512
    }

    '__ci_bb_515 {
        (__local_j__goto_4918_14 = 0)
        goto '__ci_bb_516
    }

    '__ci_bb_516 {
        if ((if __local_j__goto_4918_14 < __local_lmiddle__goto_5231_25: 1 else: 0) != 0) {
            goto '__ci_bb_517
        } else {
            goto '__ci_bb_519
        }
    }

    '__ci_bb_517 {
        fprintf(outfile, " ")
        goto '__ci_bb_518
    }

    '__ci_bb_518 {
        (__local_j__goto_4918_14 = __local_j__goto_4918_14 + 1)
        goto '__ci_bb_516
    }

    '__ci_bb_519 {
        (__local_j__goto_4918_14 = 0)
        goto '__ci_bb_520
    }

    '__ci_bb_520 {
        if ((if __local_j__goto_4918_14 < __local_lright__goto_5231_34: 1 else: 0) != 0) {
            goto '__ci_bb_521
        } else {
            goto '__ci_bb_523
        }
    }

    '__ci_bb_521 {
        fprintf(outfile, ">")
        goto '__ci_bb_522
    }

    '__ci_bb_522 {
        (__local_j__goto_4918_14 = __local_j__goto_4918_14 + 1)
        goto '__ci_bb_520
    }

    '__ci_bb_523 {
        goto '__ci_bb_509
    }

    '__ci_bb_524 {
        (__local_startchar__goto_5310_22 = pcre2_get_startchar_8(match_data_8))
        (__local_lleft__goto_5231_18 = pchars_8(-1, (__local_pp__goto_3853_14 + (__local_startchar__goto_5310_22 as usize)), ((__local_start__goto_5232_18 as c_ulong) -% (__local_startchar__goto_5310_22 as c_ulong)), __local_utf__goto_3844_6, outfile))
        pchars_8(-1, (__local_pp__goto_3853_14 + (__local_start__goto_5232_18 as usize)), ((__local_end__goto_5233_18 as c_ulong) -% (__local_start__goto_5232_18 as c_ulong)), __local_utf__goto_3844_6, outfile)
        (__ci_expr_logic_110 = 0)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_110 = (if jit_was_used != 0: 1 else: 0))
        }
        if (__ci_expr_logic_110 != 0) {
            goto '__ci_bb_527
        } else {
            goto '__ci_bb_528
        }
    }

    '__ci_bb_525 {
        pchars_8(-1, (__local_pp__goto_3853_14 + (__local_start__goto_5232_18 as usize)), ((__local_end__goto_5233_18 as c_ulong) -% (__local_start__goto_5232_18 as c_ulong)), __local_utf__goto_3844_6, outfile)
        (__ci_expr_logic_111 = 0)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_111 = (if jit_was_used != 0: 1 else: 0))
        }
        if (__ci_expr_logic_111 != 0) {
            goto '__ci_bb_535
        } else {
            goto '__ci_bb_536
        }
    }

    '__ci_bb_526 {
        goto '__ci_bb_509
    }

    '__ci_bb_527 {
        fprintf(outfile, " (JIT)")
        goto '__ci_bb_528
    }

    '__ci_bb_528 {
        if ((if __local_startchar__goto_5310_22 != __local_start__goto_5232_18: 1 else: 0) != 0) {
            goto '__ci_bb_529
        } else {
            goto '__ci_bb_530
        }
    }

    '__ci_bb_529 {
        fprintf(outfile, "\n    ")
        (__local_j__goto_4918_14 = 0)
        goto '__ci_bb_531
    }

    '__ci_bb_530 {
        goto '__ci_bb_526
    }

    '__ci_bb_531 {
        if ((if __local_j__goto_4918_14 < __local_lleft__goto_5231_18: 1 else: 0) != 0) {
            goto '__ci_bb_532
        } else {
            goto '__ci_bb_534
        }
    }

    '__ci_bb_532 {
        fprintf(outfile, "^")
        goto '__ci_bb_533
    }

    '__ci_bb_533 {
        (__local_j__goto_4918_14 = __local_j__goto_4918_14 + 1)
        goto '__ci_bb_531
    }

    '__ci_bb_534 {
        goto '__ci_bb_530
    }

    '__ci_bb_535 {
        fprintf(outfile, " (JIT)")
        goto '__ci_bb_536
    }

    '__ci_bb_536 {
        goto '__ci_bb_526
    }

    '__ci_bb_537 {
        fprintf(outfile, "%2d+ ", (__local_i__goto_5229_14 / 2))
        pchars_8(-1, (__local_pp__goto_3853_14 + ((unsafe: __local_ovector__goto_3847_13[(__local_i__goto_5229_14 + 1)]) as usize)), ((__local_ulen__goto_3836_12 as c_ulong) -% ((unsafe: __local_ovector__goto_3847_13[(__local_i__goto_5229_14 + 1)]) as c_ulong)), __local_utf__goto_3844_6, outfile)
        fprintf(outfile, "\n")
        goto '__ci_bb_538
    }

    '__ci_bb_538 {
        goto '__ci_bb_490
    }

    '__ci_bb_539 {
        fprintf(outfile, "MK: ")
        pchars_8(-1, (match_data_8.mark - ((1 as isize) as usize)), -1, __local_utf__goto_3844_6, outfile)
        fprintf(outfile, "\n")
        goto '__ci_bb_540
    }

    '__ci_bb_540 {
        if ((if not (copy_and_get_8(__local_utf__goto_3844_6, __local_capcount__goto_4919_7) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_541
        } else {
            goto '__ci_bb_542
        }
    }

    '__ci_bb_541 {
        return PR_ABEND
    }

    '__ci_bb_542 {
        goto '__ci_bb_464
    }

    '__ci_bb_543 {
        (__local_rubriclength__goto_5379_9 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (8 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_546
        } else {
            goto '__ci_bb_547
        }
    }

    '__ci_bb_544 {
        goto '__ci_bb_569
    }

    '__ci_bb_546 {
        (__local_leftchar__goto_5377_16 = match_data_8.leftchar)
        goto '__ci_bb_548
    }

    '__ci_bb_547 {
        (__local_leftchar__goto_5377_16 = (unsafe: __local_ovector__goto_3847_13[0]))
        goto '__ci_bb_548
    }

    '__ci_bb_548 {
        colour_begin(35, outfile)
        fprintf(outfile, "Partial match")
        colour_end(outfile)
        (__ci_expr_logic_115 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (1048576 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_115 = (if (if match_data_8.mark != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_115 != 0) {
            goto '__ci_bb_549
        } else {
            goto '__ci_bb_550
        }
    }

    '__ci_bb_549 {
        fprintf(outfile, ", mark=")
        (__local_rubriclength__goto_5379_9 = pchars_8(-1, (match_data_8.mark - ((1 as isize) as usize)), -1, __local_utf__goto_3844_6, outfile))
        (__local_rubriclength__goto_5379_9 = __local_rubriclength__goto_5379_9 + 7)
        goto '__ci_bb_550
    }

    '__ci_bb_550 {
        fprintf(outfile, ": ")
        (__local_rubriclength__goto_5379_9 = __local_rubriclength__goto_5379_9 + 15)
        (__local_backlength__goto_5378_9 = pchars_8(32, (__local_pp__goto_3853_14 + (__local_leftchar__goto_5377_16 as usize)), (((unsafe: __local_ovector__goto_3847_13[0]) as c_ulong) -% (__local_leftchar__goto_5377_16 as c_ulong)), __local_utf__goto_3844_6, outfile))
        pchars_8(32, (__local_pp__goto_3853_14 + ((unsafe: __local_ovector__goto_3847_13[0]) as usize)), (((unsafe: __local_ovector__goto_3847_13[1]) as c_ulong) -% ((unsafe: __local_ovector__goto_3847_13[0]) as c_ulong)), __local_utf__goto_3844_6, outfile)
        (__ci_expr_logic_116 = 0)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_116 = (if jit_was_used != 0: 1 else: 0))
        }
        if (__ci_expr_logic_116 != 0) {
            goto '__ci_bb_551
        } else {
            goto '__ci_bb_552
        }
    }

    '__ci_bb_551 {
        fprintf(outfile, " (JIT)")
        goto '__ci_bb_552
    }

    '__ci_bb_552 {
        fprintf(outfile, "\n")
        if ((if __local_backlength__goto_5378_9 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_553
        } else {
            goto '__ci_bb_554
        }
    }

    '__ci_bb_553 {
        (__local_i__goto_5407_16 = 0)
        goto '__ci_bb_555
    }

    '__ci_bb_554 {
        if ((if __local_ulen__goto_3836_12 != (unsafe: __local_ovector__goto_3847_13[1]): 1 else: 0) != 0) {
            goto '__ci_bb_563
        } else {
            goto '__ci_bb_564
        }
    }

    '__ci_bb_555 {
        if ((if __local_i__goto_5407_16 < __local_rubriclength__goto_5379_9: 1 else: 0) != 0) {
            goto '__ci_bb_556
        } else {
            goto '__ci_bb_558
        }
    }

    '__ci_bb_556 {
        fprintf(outfile, " ")
        goto '__ci_bb_557
    }

    '__ci_bb_557 {
        (__local_i__goto_5407_16 = __local_i__goto_5407_16 + 1)
        goto '__ci_bb_555
    }

    '__ci_bb_558 {
        (__local_i__goto_5408_16 = 0)
        goto '__ci_bb_559
    }

    '__ci_bb_559 {
        if ((if __local_i__goto_5408_16 < __local_backlength__goto_5378_9: 1 else: 0) != 0) {
            goto '__ci_bb_560
        } else {
            goto '__ci_bb_562
        }
    }

    '__ci_bb_560 {
        fprintf(outfile, "<")
        goto '__ci_bb_561
    }

    '__ci_bb_561 {
        (__local_i__goto_5408_16 = __local_i__goto_5408_16 + 1)
        goto '__ci_bb_559
    }

    '__ci_bb_562 {
        fprintf(outfile, "\n")
        goto '__ci_bb_554
    }

    '__ci_bb_563 {
        colour_begin(31, outfile)
        fprintf(outfile, "** ovector[1] is not equal to the subject length: %ld != %ld\n", (unsafe: __local_ovector__goto_3847_13[1]), __local_ulen__goto_3836_12)
        colour_end(outfile)
        goto '__ci_bb_564
    }

    '__ci_bb_564 {
        if ((if not (copy_and_get_8(__local_utf__goto_3844_6, 1) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_565
        } else {
            goto '__ci_bb_566
        }
    }

    '__ci_bb_565 {
        return PR_ABEND
    }

    '__ci_bb_566 {
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_567
        } else {
            goto '__ci_bb_568
        }
    }

    '__ci_bb_567 {
        show_ovector(__local_ovector__goto_3847_13, __local_oveccount__goto_3849_10)
        goto '__ci_bb_568
    }

    '__ci_bb_568 {
        goto '__ci_bb_380
    }

    '__ci_bb_569 {
        if (__local_capcount__goto_4919_7 == -1) {
            goto '__ci_bb_571
        } else {
            goto '__ci_bb_586
        }
    }

    '__ci_bb_570 {
        goto '__ci_bb_380
    }

    '__ci_bb_571 {
        if ((if __local_gmatched__goto_3837_10 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_572
        } else {
            goto '__ci_bb_573
        }
    }

    '__ci_bb_572 {
        colour_begin(35, outfile)
        fprintf(outfile, "No match")
        colour_end(outfile)
        (__ci_expr_logic_117 = 0)
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (1048576 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_117 = (if (if match_data_8.mark != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_117 != 0) {
            goto '__ci_bb_574
        } else {
            goto '__ci_bb_575
        }
    }

    '__ci_bb_573 {
        goto '__ci_bb_570
    }

    '__ci_bb_574 {
        fprintf(outfile, ", mark = ")
        pchars_8(-1, (match_data_8.mark - ((1 as isize) as usize)), -1, __local_utf__goto_3844_6, outfile)
        goto '__ci_bb_575
    }

    '__ci_bb_575 {
        (__ci_expr_logic_118 = 0)
        if ((if (((&raw const pat_patctl as *const patctl).control as c_uint) & (524288 as c_uint)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_118 = (if jit_was_used != 0: 1 else: 0))
        }
        if (__ci_expr_logic_118 != 0) {
            goto '__ci_bb_576
        } else {
            goto '__ci_bb_577
        }
    }

    '__ci_bb_576 {
        fprintf(outfile, " (JIT)")
        goto '__ci_bb_577
    }

    '__ci_bb_577 {
        fprintf(outfile, "\n")
        if ((if (((&raw const dat_datctl as *const datctl).control2 as c_uint) & (2048 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_578
        } else {
            goto '__ci_bb_579
        }
    }

    '__ci_bb_578 {
        show_ovector(__local_ovector__goto_3847_13, __local_oveccount__goto_3849_10)
        goto '__ci_bb_579
    }

    '__ci_bb_579 {
        goto '__ci_bb_573
    }

    '__ci_bb_580 {
        colour_begin(35, outfile)
        fprintf(outfile, "Error %d (bad UTF-8 offset)\n", __local_capcount__goto_4919_7)
        colour_end(outfile)
        goto '__ci_bb_570
    }

    '__ci_bb_581 {
        colour_begin(35, outfile)
        fprintf(outfile, "Failed: error %d: ", __local_capcount__goto_4919_7)
        colour_end(outfile)
        if ((if not (print_error_message_8(__local_capcount__goto_4919_7, "", "") != 0): 1 else: 0) != 0) {
            goto '__ci_bb_582
        } else {
            goto '__ci_bb_583
        }
    }

    '__ci_bb_582 {
        return PR_ABEND
    }

    '__ci_bb_583 {
        (__ci_expr_logic_119 = 0)
        if ((if __local_capcount__goto_4919_7 <= -3: 1 else: 0) != 0) {
            (__ci_expr_logic_119 = (if (if __local_capcount__goto_4919_7 >= -28: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_119 != 0) {
            goto '__ci_bb_584
        } else {
            goto '__ci_bb_585
        }
    }

    '__ci_bb_584 {
        (__local_startchar__goto_5467_20 = pcre2_get_startchar_8(match_data_8))
        colour_begin(35, outfile)
        fprintf(outfile, " at offset %zu", __local_startchar__goto_5467_20)
        colour_end(outfile)
        goto '__ci_bb_585
    }

    '__ci_bb_585 {
        fprintf(outfile, "\n")
        goto '__ci_bb_570
    }

    '__ci_bb_586 {
        if (__local_capcount__goto_4919_7 == -36) {
            goto '__ci_bb_580
        } else {
            goto '__ci_bb_581
        }
    }

    '__ci_bb_587 {
        goto '__ci_bb_380
    }

    '__ci_bb_588 {
        (__local_new_start_offset__goto_5488_16 = ((-1 as c_ulong)))
        (__local_rc_nextmatch__goto_5489_10 = pcre2_next_match_8(match_data_8, (&raw mut __local_new_start_offset__goto_5488_16 as *mut c_ulong), (&raw mut __local_g_notempty__goto_3839_10 as *mut c_uint)))
        if ((if not (__local_rc_nextmatch__goto_5489_10 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_590
        } else {
            goto '__ci_bb_591
        }
    }

    '__ci_bb_589 {
        goto '__ci_bb_379
    }

    '__ci_bb_590 {
        goto '__ci_bb_380
    }

    '__ci_bb_591 {
        if ((if (((&raw const dat_datctl as *const datctl).control as c_uint) & (32768 as c_uint)) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_592
        } else {
            goto '__ci_bb_593
        }
    }

    '__ci_bb_592 {
        (dat_datctl.offset = __local_new_start_offset__goto_5488_16)
        goto '__ci_bb_594
    }

    '__ci_bb_593 {
        (__local_pp__goto_3853_14 = __local_pp__goto_3853_14 + (__local_new_start_offset__goto_5488_16 as usize))
        (__local_len__goto_3841_8 = __local_len__goto_3841_8 - ((__local_new_start_offset__goto_5488_16 as c_ulong) *% (1 as c_ulong)))
        (__local_ulen__goto_3836_12 = __local_ulen__goto_3836_12 - __local_new_start_offset__goto_5488_16)
        if ((if __local_arg_ulen__goto_3836_18 != (~(0 as c_ulong)): 1 else: 0) != 0) {
            goto '__ci_bb_595
        } else {
            goto '__ci_bb_596
        }
    }

    '__ci_bb_594 {
        goto '__ci_bb_589
    }

    '__ci_bb_595 {
        (__local_arg_ulen__goto_3836_18 = __local_arg_ulen__goto_3836_18 - __local_new_start_offset__goto_5488_16)
        goto '__ci_bb_596
    }

    '__ci_bb_596 {
        goto '__ci_bb_594
    }

    '__ci_bb_597 {
        show_heapframes_size_8()
        goto '__ci_bb_598
    }

    '__ci_bb_598 {
        (show_memory = 0)
        return PR_OK
    }

}

fn init_globals_8() {
    (general_context_8 = pcre2_general_context_create_8(my_malloc, my_free, null))

    (general_context_copy_8 = pcre2_general_context_copy_8(general_context_8))

    (default_pat_context_8 = pcre2_compile_context_create_8(general_context_8))

    (pat_context_8 = pcre2_compile_context_copy_8(default_pat_context_8))

    (default_dat_context_8 = pcre2_match_context_create_8(general_context_8))

    (dat_context_8 = pcre2_match_context_copy_8(default_dat_context_8))

    (default_con_context_8 = pcre2_convert_context_create_8(general_context_8))

    (con_context_8 = pcre2_convert_context_copy_8(default_con_context_8))

    (match_data_8 = pcre2_match_data_create_8(max_oveccount, general_context_8))

    (rep_in_buffer_8 = ((with_alloc((((sizeof[u8]() as c_ulong) *% (rep_in_buffer_size_8 as c_ulong)) as i64)) as *mut c_void)))

    (rep_out_buffer_8 = ((with_alloc((((sizeof[u8]() as c_ulong) *% (rep_out_buffer_size_8 as c_ulong)) as i64)) as *mut c_void)))

    pcre2_set_parens_nest_limit_8(default_pat_context_8, 220)

}

fn free_globals_8() {
    pcre2_maketables_free_8(general_context_8, locale_tables)

    pcre2_match_data_free_8(match_data_8)

    pcre2_code_free_8(compiled_code_8)

    while true {
        var __ci_expr_old_0: c_int = patstacknext_8

        (patstacknext_8 = patstacknext_8 - 1)

        if (not ((if __ci_expr_old_0 > 0: 1 else: 0) != 0)) {
            break
        }

        (compiled_code_8 = patstack_8[patstacknext_8])

        pcre2_code_free_8(compiled_code_8)

    }

    pcre2_jit_free_unused_memory_8(general_context_8)

    if ((if jit_stack_8 != null: 1 else: 0) != 0) {
        pcre2_jit_stack_free_8(jit_stack_8)

    }

    pcre2_general_context_free_8(general_context_8)

    pcre2_general_context_free_8(general_context_copy_8)

    pcre2_compile_context_free_8(pat_context_8)

    pcre2_compile_context_free_8(default_pat_context_8)

    pcre2_match_context_free_8(dat_context_8)

    pcre2_match_context_free_8(default_dat_context_8)

    pcre2_convert_context_free_8(default_con_context_8)

    pcre2_convert_context_free_8(con_context_8)

    with_free((rep_in_buffer_8 as *mut i8))

    with_free((rep_out_buffer_8 as *mut i8))

}

fn unittest_8() {
    var __local_rc__goto_5628_5: c_int = 0

    var __local_uval__goto_5629_10: c_uint = 0

    var __local_sizeval__goto_5630_12: c_ulong = 0

    var __local_sptrval__goto_5631_14: *mut u8 = null

    var __local_failure__goto_5632_13: *const i8 = null

    var __local_test_gen_context__goto_5633_24: *mut pcre2_real_general_context_8 = null

    var __local_test_gen_context_copy__goto_5633_50: *mut pcre2_real_general_context_8 = null

    var __local_test_pat_context__goto_5634_24: *mut pcre2_real_compile_context_8 = null

    var __local_test_pat_context_copy__goto_5634_50: *mut pcre2_real_compile_context_8 = null

    var __local_test_dat_context__goto_5635_22: *mut pcre2_real_match_context_8 = null

    var __local_test_dat_context_copy__goto_5635_48: *mut pcre2_real_match_context_8 = null

    var __local_test_con_context__goto_5636_24: *mut pcre2_real_convert_context_8 = null

    var __local_test_con_context_copy__goto_5636_50: *mut pcre2_real_convert_context_8 = null

    var __local_test_match_data__goto_5637_19: *mut pcre2_real_match_data_8 = null

    var __local_test_compiled_code__goto_5638_13: *mut pcre2_real_code_8 = null

    var __local_pattern__goto_5639_13: [4]u8

    var __local_callout_int_pattern__goto_5640_13: [5]u8

    var __local_callout_str_pattern__goto_5642_13: [8]u8

    var __local_capture_pattern__goto_5645_13: [11]u8

    var __local_subject_abcz__goto_5649_13: [5]u8

    var __local_substitute_subject__goto_5651_13: [6]u8

    var __local_name_n__goto_5652_13: [2]u8

    var __local_errorcode__goto_5657_5: c_int = 0

    var __local_erroroffset__goto_5658_12: c_ulong = 0

    var __local_errorbuffer__goto_5659_13: [256]u8

    var __local_errorbuffer8__goto_5661_6: [256]c_char

    var __local_test_preg__goto_5662_9: regex_t

    var __local_invalid_code__goto_5664_7: *mut c_void = null

    var __local_test_tables__goto_5665_16: *const u8 = null

    var __local_copy_buf__goto_5666_13: [64]u8

    var __local_stringlist__goto_5667_15: *mut *mut u8 = null

    var __local_lengthslist__goto_5668_13: *mut c_ulong = null

    var __local_replace_buf__goto_5669_13: [64]u8

    var __local_subs_other_code__goto_5670_13: *mut pcre2_real_code_8 = null

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_logic_8: c_int = 0

    var __ci_expr_logic_9: c_int = 0

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_logic_11: c_int = 0

    var __ci_expr_logic_12: c_int = 0

    var __ci_expr_logic_13: c_int = 0

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_logic_15: c_int = 0

    var __ci_expr_logic_16: c_int = 0

    var __ci_expr_logic_17: c_int = 0

    var __ci_expr_logic_18: c_int = 0

    var __ci_expr_logic_19: c_int = 0

    var __ci_expr_logic_20: c_int = 0

    var __ci_expr_logic_22: c_int = 0

    var __ci_expr_logic_21: c_int = 0

    var __ci_expr_logic_23: c_int = 0

    var __ci_expr_logic_24: c_int = 0

    var __ci_expr_logic_25: c_int = 0

    var __ci_expr_logic_26: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_failure__goto_5632_13 = ((null as *const c_char)))
        (__local_test_gen_context__goto_5633_24 = ((null as *mut pcre2_real_general_context_8)))
        (__local_test_gen_context_copy__goto_5633_50 = ((null as *mut pcre2_real_general_context_8)))
        (__local_test_pat_context__goto_5634_24 = ((null as *mut pcre2_real_compile_context_8)))
        (__local_test_pat_context_copy__goto_5634_50 = ((null as *mut pcre2_real_compile_context_8)))
        (__local_test_dat_context__goto_5635_22 = ((null as *mut pcre2_real_match_context_8)))
        (__local_test_dat_context_copy__goto_5635_48 = ((null as *mut pcre2_real_match_context_8)))
        (__local_test_con_context__goto_5636_24 = ((null as *mut pcre2_real_convert_context_8)))
        (__local_test_con_context_copy__goto_5636_50 = ((null as *mut pcre2_real_convert_context_8)))
        (__local_test_match_data__goto_5637_19 = ((null as *mut pcre2_real_match_data_8)))
        (__local_test_compiled_code__goto_5638_13 = ((null as *mut pcre2_real_code_8)))
        (__local_pattern__goto_5639_13 = [65, 66, 67, 0])
        (__local_callout_int_pattern__goto_5640_13 = [40, 63, 67, 41, 0])
        (__local_callout_str_pattern__goto_5642_13 = [40, 63, 67, 34, 90, 34, 41, 0])
        (__local_capture_pattern__goto_5645_13 = [65, 40, 63, 60, 78, 62, 46, 42, 41, 90, 0])
        (__local_subject_abcz__goto_5649_13 = [65, 66, 67, 90, 0])
        (__local_name_n__goto_5652_13 = [78, 0])
        (__local_invalid_code__goto_5664_7 = null)
        (__local_test_tables__goto_5665_16 = ((null as *const u8)))
        (__local_subs_other_code__goto_5670_13 = ((null as *mut pcre2_real_code_8)))
        with_memset(((&raw mut __local_test_preg__goto_5662_9 as *mut regex_t) as *i8), 0, (sizeof[regex_t]() as i64))
        (__local_rc__goto_5628_5 = pcre2_config_8(0, null))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_2 {
        if (0 != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        (__local_rc__goto_5628_5 = pcre2_config_8(14, null))
        goto '__ci_bb_7
    }

    '__ci_bb_4 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_5 {
        goto '__ci_bb_2
    }

    '__ci_bb_6 {
        (mallocs_until_failure = 2147483647)
        pcre2_regfree((&raw mut __local_test_preg__goto_5662_9 as *mut regex_t))
        if ((if __local_test_compiled_code__goto_5638_13 != null: 1 else: 0) != 0) {
            goto '__ci_bb_652
        } else {
            goto '__ci_bb_653
        }
    }

    '__ci_bb_7 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_8 {
        if (0 != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_9 {
        (__local_rc__goto_5628_5 = pcre2_config_8(7, null))
        goto '__ci_bb_12
    }

    '__ci_bb_10 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_11 {
        goto '__ci_bb_8
    }

    '__ci_bb_12 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_13 {
        if (0 != 0) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_14 {
        (__local_rc__goto_5628_5 = pcre2_config_8(16, null))
        goto '__ci_bb_17
    }

    '__ci_bb_15 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_16 {
        goto '__ci_bb_13
    }

    '__ci_bb_17 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_18 {
        if (0 != 0) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_19 {
        (__local_rc__goto_5628_5 = pcre2_config_8(12, null))
        goto '__ci_bb_22
    }

    '__ci_bb_20 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_21 {
        goto '__ci_bb_18
    }

    '__ci_bb_22 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_25
        } else {
            goto '__ci_bb_26
        }
    }

    '__ci_bb_23 {
        if (0 != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_24 {
        (__local_rc__goto_5628_5 = pcre2_config_8(1, null))
        goto '__ci_bb_27
    }

    '__ci_bb_25 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_26 {
        goto '__ci_bb_23
    }

    '__ci_bb_27 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_28 {
        if (0 != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_29
        }
    }

    '__ci_bb_29 {
        (__local_rc__goto_5628_5 = pcre2_config_8(3, null))
        goto '__ci_bb_32
    }

    '__ci_bb_30 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_31 {
        goto '__ci_bb_28
    }

    '__ci_bb_32 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_33 {
        if (0 != 0) {
            goto '__ci_bb_32
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_34 {
        (__local_rc__goto_5628_5 = pcre2_config_8(4, null))
        goto '__ci_bb_37
    }

    '__ci_bb_35 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_36 {
        goto '__ci_bb_33
    }

    '__ci_bb_37 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_38 {
        if (0 != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_39
        }
    }

    '__ci_bb_39 {
        (__local_rc__goto_5628_5 = pcre2_config_8(13, null))
        goto '__ci_bb_42
    }

    '__ci_bb_40 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_41 {
        goto '__ci_bb_38
    }

    '__ci_bb_42 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_43 {
        if (0 != 0) {
            goto '__ci_bb_42
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_44 {
        (__local_rc__goto_5628_5 = pcre2_config_8(5, null))
        goto '__ci_bb_47
    }

    '__ci_bb_45 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_46 {
        goto '__ci_bb_43
    }

    '__ci_bb_47 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_48 {
        if (0 != 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_49
        }
    }

    '__ci_bb_49 {
        (__local_rc__goto_5628_5 = pcre2_config_8(6, null))
        goto '__ci_bb_52
    }

    '__ci_bb_50 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_51 {
        goto '__ci_bb_48
    }

    '__ci_bb_52 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_56
        }
    }

    '__ci_bb_53 {
        if (0 != 0) {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_54 {
        (__local_rc__goto_5628_5 = pcre2_config_8(8, null))
        goto '__ci_bb_57
    }

    '__ci_bb_55 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_56 {
        goto '__ci_bb_53
    }

    '__ci_bb_57 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_60
        } else {
            goto '__ci_bb_61
        }
    }

    '__ci_bb_58 {
        if (0 != 0) {
            goto '__ci_bb_57
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_59 {
        (__local_rc__goto_5628_5 = pcre2_config_8(15, null))
        goto '__ci_bb_62
    }

    '__ci_bb_60 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_61 {
        goto '__ci_bb_58
    }

    '__ci_bb_62 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_63 {
        if (0 != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_64
        }
    }

    '__ci_bb_64 {
        (__local_rc__goto_5628_5 = pcre2_config_8(9, null))
        goto '__ci_bb_67
    }

    '__ci_bb_65 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_66 {
        goto '__ci_bb_63
    }

    '__ci_bb_67 {
        if ((if not ((if __local_rc__goto_5628_5 == ((sizeof[u32]() as c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_70
        } else {
            goto '__ci_bb_71
        }
    }

    '__ci_bb_68 {
        if (0 != 0) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_69
        }
    }

    '__ci_bb_69 {
        (__local_rc__goto_5628_5 = pcre2_config_8(10, null))
        goto '__ci_bb_72
    }

    '__ci_bb_70 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_71 {
        goto '__ci_bb_68
    }

    '__ci_bb_72 {
        if ((if not ((if __local_rc__goto_5628_5 > 4: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_76
        }
    }

    '__ci_bb_73 {
        if (0 != 0) {
            goto '__ci_bb_72
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_74 {
        (__local_rc__goto_5628_5 = pcre2_config_8(11, null))
        goto '__ci_bb_77
    }

    '__ci_bb_75 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_76 {
        goto '__ci_bb_73
    }

    '__ci_bb_77 {
        if ((if not ((if __local_rc__goto_5628_5 > 4: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_80
        } else {
            goto '__ci_bb_81
        }
    }

    '__ci_bb_78 {
        if (0 != 0) {
            goto '__ci_bb_77
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_79 {
        (__local_rc__goto_5628_5 = pcre2_config_8(4, (&raw mut __local_uval__goto_5629_10 as *mut c_uint)))
        goto '__ci_bb_82
    }

    '__ci_bb_80 {
        (__local_failure__goto_5632_13 = (("pcre2_config(NULL)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_81 {
        goto '__ci_bb_78
    }

    '__ci_bb_82 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_85
        } else {
            goto '__ci_bb_86
        }
    }

    '__ci_bb_83 {
        if (0 != 0) {
            goto '__ci_bb_82
        } else {
            goto '__ci_bb_84
        }
    }

    '__ci_bb_84 {
        (__local_rc__goto_5628_5 = pcre2_config_8(999, null))
        goto '__ci_bb_87
    }

    '__ci_bb_85 {
        (__local_failure__goto_5632_13 = (("pcre2_config(PCRE2_CONFIG_MATCHLIMIT)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_86 {
        goto '__ci_bb_83
    }

    '__ci_bb_87 {
        if ((if not ((if __local_rc__goto_5628_5 == -34: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_90
        } else {
            goto '__ci_bb_91
        }
    }

    '__ci_bb_88 {
        if (0 != 0) {
            goto '__ci_bb_87
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_89 {
        (__local_rc__goto_5628_5 = pcre2_config_8(999, (&raw mut __local_uval__goto_5629_10 as *mut c_uint)))
        goto '__ci_bb_92
    }

    '__ci_bb_90 {
        (__local_failure__goto_5632_13 = (("pcre2_config(bad option)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_91 {
        goto '__ci_bb_88
    }

    '__ci_bb_92 {
        if ((if not ((if __local_rc__goto_5628_5 == -34: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_95
        } else {
            goto '__ci_bb_96
        }
    }

    '__ci_bb_93 {
        if (0 != 0) {
            goto '__ci_bb_92
        } else {
            goto '__ci_bb_94
        }
    }

    '__ci_bb_94 {
        (__local_rc__goto_5628_5 = pcre2_config_8(8, (&raw mut __local_uval__goto_5629_10 as *mut c_uint)))
        goto '__ci_bb_97
    }

    '__ci_bb_95 {
        (__local_failure__goto_5632_13 = (("pcre2_config(bad option)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_96 {
        goto '__ci_bb_93
    }

    '__ci_bb_97 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_101
        }
    }

    '__ci_bb_98 {
        if (0 != 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_99 {
        (__local_rc__goto_5628_5 = pcre2_config_8(3, (&raw mut __local_uval__goto_5629_10 as *mut c_uint)))
        goto '__ci_bb_102
    }

    '__ci_bb_100 {
        (__local_failure__goto_5632_13 = (("pcre2_config(PCRE2_CONFIG_STACKRECURSE)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_101 {
        goto '__ci_bb_98
    }

    '__ci_bb_102 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_103 {
        if (0 != 0) {
            goto '__ci_bb_102
        } else {
            goto '__ci_bb_104
        }
    }

    '__ci_bb_104 {
        (__local_test_gen_context__goto_5633_24 = pcre2_general_context_create_8(null, null, null))
        goto '__ci_bb_107
    }

    '__ci_bb_105 {
        (__local_failure__goto_5632_13 = (("pcre2_config(PCRE2_CONFIG_LINKSIZE)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_106 {
        goto '__ci_bb_103
    }

    '__ci_bb_107 {
        if ((if not ((if __local_test_gen_context__goto_5633_24 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_108 {
        if (0 != 0) {
            goto '__ci_bb_107
        } else {
            goto '__ci_bb_109
        }
    }

    '__ci_bb_109 {
        pcre2_general_context_free_8(__local_test_gen_context__goto_5633_24)
        (mallocs_until_failure = 0)
        (__local_test_gen_context__goto_5633_24 = pcre2_general_context_create_8(my_malloc, my_free, null))
        goto '__ci_bb_112
    }

    '__ci_bb_110 {
        (__local_failure__goto_5632_13 = (("pcre2_general_context_create(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_111 {
        goto '__ci_bb_108
    }

    '__ci_bb_112 {
        if ((if not ((if __local_test_gen_context__goto_5633_24 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_116
        }
    }

    '__ci_bb_113 {
        if (0 != 0) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_114
        }
    }

    '__ci_bb_114 {
        (mallocs_until_failure = 1)
        (__local_test_gen_context__goto_5633_24 = pcre2_general_context_create_8(my_malloc, my_free, null))
        goto '__ci_bb_117
    }

    '__ci_bb_115 {
        (__local_failure__goto_5632_13 = (("pcre2_general_context_create(malloc)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_116 {
        goto '__ci_bb_113
    }

    '__ci_bb_117 {
        if ((if not ((if __local_test_gen_context__goto_5633_24 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_120
        } else {
            goto '__ci_bb_121
        }
    }

    '__ci_bb_118 {
        if (0 != 0) {
            goto '__ci_bb_117
        } else {
            goto '__ci_bb_119
        }
    }

    '__ci_bb_119 {
        (__local_test_pat_context__goto_5634_24 = pcre2_compile_context_create_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_122
    }

    '__ci_bb_120 {
        (__local_failure__goto_5632_13 = (("pcre2_general_context_create(malloc)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_121 {
        goto '__ci_bb_118
    }

    '__ci_bb_122 {
        if ((if not ((if __local_test_pat_context__goto_5634_24 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_125
        } else {
            goto '__ci_bb_126
        }
    }

    '__ci_bb_123 {
        if (0 != 0) {
            goto '__ci_bb_122
        } else {
            goto '__ci_bb_124
        }
    }

    '__ci_bb_124 {
        (__local_test_dat_context__goto_5635_22 = pcre2_match_context_create_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_127
    }

    '__ci_bb_125 {
        (__local_failure__goto_5632_13 = (("pcre2_compile_context_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_126 {
        goto '__ci_bb_123
    }

    '__ci_bb_127 {
        if ((if not ((if __local_test_dat_context__goto_5635_22 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_130
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_128 {
        if (0 != 0) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_129 {
        (__local_test_con_context__goto_5636_24 = pcre2_convert_context_create_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_132
    }

    '__ci_bb_130 {
        (__local_failure__goto_5632_13 = (("pcre2_match_context_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_131 {
        goto '__ci_bb_128
    }

    '__ci_bb_132 {
        if ((if not ((if __local_test_con_context__goto_5636_24 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_135
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_133 {
        if (0 != 0) {
            goto '__ci_bb_132
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_134 {
        (__local_test_pat_context__goto_5634_24 = pcre2_compile_context_create_8(null))
        goto '__ci_bb_137
    }

    '__ci_bb_135 {
        (__local_failure__goto_5632_13 = (("pcre2_convert_context_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_136 {
        goto '__ci_bb_133
    }

    '__ci_bb_137 {
        if ((if not ((if __local_test_pat_context__goto_5634_24 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_140
        } else {
            goto '__ci_bb_141
        }
    }

    '__ci_bb_138 {
        if (0 != 0) {
            goto '__ci_bb_137
        } else {
            goto '__ci_bb_139
        }
    }

    '__ci_bb_139 {
        pcre2_compile_context_free_8(__local_test_pat_context__goto_5634_24)
        (__local_test_dat_context__goto_5635_22 = pcre2_match_context_create_8(null))
        goto '__ci_bb_142
    }

    '__ci_bb_140 {
        (__local_failure__goto_5632_13 = (("pcre2_compile_context_create(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_141 {
        goto '__ci_bb_138
    }

    '__ci_bb_142 {
        if ((if not ((if __local_test_dat_context__goto_5635_22 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_145
        } else {
            goto '__ci_bb_146
        }
    }

    '__ci_bb_143 {
        if (0 != 0) {
            goto '__ci_bb_142
        } else {
            goto '__ci_bb_144
        }
    }

    '__ci_bb_144 {
        pcre2_match_context_free_8(__local_test_dat_context__goto_5635_22)
        (__local_test_con_context__goto_5636_24 = pcre2_convert_context_create_8(null))
        goto '__ci_bb_147
    }

    '__ci_bb_145 {
        (__local_failure__goto_5632_13 = (("pcre2_match_context_create(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_146 {
        goto '__ci_bb_143
    }

    '__ci_bb_147 {
        if ((if not ((if __local_test_con_context__goto_5636_24 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_148 {
        if (0 != 0) {
            goto '__ci_bb_147
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_149 {
        pcre2_convert_context_free_8(__local_test_con_context__goto_5636_24)
        (mallocs_until_failure = 2147483647)
        (__local_test_pat_context__goto_5634_24 = pcre2_compile_context_create_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_152
    }

    '__ci_bb_150 {
        (__local_failure__goto_5632_13 = (("pcre2_convert_context_create(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_151 {
        goto '__ci_bb_148
    }

    '__ci_bb_152 {
        if ((if not ((if __local_test_pat_context__goto_5634_24 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_153 {
        if (0 != 0) {
            goto '__ci_bb_152
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_154 {
        (__local_test_dat_context__goto_5635_22 = pcre2_match_context_create_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_157
    }

    '__ci_bb_155 {
        (__local_failure__goto_5632_13 = (("pcre2_compile_context_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_156 {
        goto '__ci_bb_153
    }

    '__ci_bb_157 {
        if ((if not ((if __local_test_dat_context__goto_5635_22 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_160
        } else {
            goto '__ci_bb_161
        }
    }

    '__ci_bb_158 {
        if (0 != 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_159
        }
    }

    '__ci_bb_159 {
        (__local_test_con_context__goto_5636_24 = pcre2_convert_context_create_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_162
    }

    '__ci_bb_160 {
        (__local_failure__goto_5632_13 = (("pcre2_match_context_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_161 {
        goto '__ci_bb_158
    }

    '__ci_bb_162 {
        if ((if not ((if __local_test_con_context__goto_5636_24 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_165
        } else {
            goto '__ci_bb_166
        }
    }

    '__ci_bb_163 {
        if (0 != 0) {
            goto '__ci_bb_162
        } else {
            goto '__ci_bb_164
        }
    }

    '__ci_bb_164 {
        (mallocs_until_failure = 0)
        (__local_test_gen_context_copy__goto_5633_50 = pcre2_general_context_copy_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_167
    }

    '__ci_bb_165 {
        (__local_failure__goto_5632_13 = (("pcre2_convert_context_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_166 {
        goto '__ci_bb_163
    }

    '__ci_bb_167 {
        if ((if not ((if __local_test_gen_context_copy__goto_5633_50 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_170
        } else {
            goto '__ci_bb_171
        }
    }

    '__ci_bb_168 {
        if (0 != 0) {
            goto '__ci_bb_167
        } else {
            goto '__ci_bb_169
        }
    }

    '__ci_bb_169 {
        (__local_test_pat_context_copy__goto_5634_50 = pcre2_compile_context_copy_8(__local_test_pat_context__goto_5634_24))
        goto '__ci_bb_172
    }

    '__ci_bb_170 {
        (__local_failure__goto_5632_13 = (("pcre2_general_context_copy()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_171 {
        goto '__ci_bb_168
    }

    '__ci_bb_172 {
        if ((if not ((if __local_test_pat_context_copy__goto_5634_50 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_175
        } else {
            goto '__ci_bb_176
        }
    }

    '__ci_bb_173 {
        if (0 != 0) {
            goto '__ci_bb_172
        } else {
            goto '__ci_bb_174
        }
    }

    '__ci_bb_174 {
        (__local_test_dat_context_copy__goto_5635_48 = pcre2_match_context_copy_8(__local_test_dat_context__goto_5635_22))
        goto '__ci_bb_177
    }

    '__ci_bb_175 {
        (__local_failure__goto_5632_13 = (("pcre2_compile_context_copy()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_176 {
        goto '__ci_bb_173
    }

    '__ci_bb_177 {
        if ((if not ((if __local_test_dat_context_copy__goto_5635_48 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
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
        (__local_test_con_context_copy__goto_5636_50 = pcre2_convert_context_copy_8(__local_test_con_context__goto_5636_24))
        goto '__ci_bb_182
    }

    '__ci_bb_180 {
        (__local_failure__goto_5632_13 = (("pcre2_match_context_copy()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_181 {
        goto '__ci_bb_178
    }

    '__ci_bb_182 {
        if ((if not ((if __local_test_con_context_copy__goto_5636_50 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_185
        } else {
            goto '__ci_bb_186
        }
    }

    '__ci_bb_183 {
        if (0 != 0) {
            goto '__ci_bb_182
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_184 {
        (mallocs_until_failure = 2147483647)
        (__local_test_gen_context_copy__goto_5633_50 = pcre2_general_context_copy_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_187
    }

    '__ci_bb_185 {
        (__local_failure__goto_5632_13 = (("pcre2_convert_context_copy()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_186 {
        goto '__ci_bb_183
    }

    '__ci_bb_187 {
        if ((if not ((if __local_test_gen_context_copy__goto_5633_50 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_190
        } else {
            goto '__ci_bb_191
        }
    }

    '__ci_bb_188 {
        if (0 != 0) {
            goto '__ci_bb_187
        } else {
            goto '__ci_bb_189
        }
    }

    '__ci_bb_189 {
        (__local_test_pat_context_copy__goto_5634_50 = pcre2_compile_context_copy_8(__local_test_pat_context__goto_5634_24))
        goto '__ci_bb_192
    }

    '__ci_bb_190 {
        (__local_failure__goto_5632_13 = (("pcre2_general_context_copy()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_191 {
        goto '__ci_bb_188
    }

    '__ci_bb_192 {
        if ((if not ((if __local_test_pat_context_copy__goto_5634_50 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_196
        }
    }

    '__ci_bb_193 {
        if (0 != 0) {
            goto '__ci_bb_192
        } else {
            goto '__ci_bb_194
        }
    }

    '__ci_bb_194 {
        (__local_test_dat_context_copy__goto_5635_48 = pcre2_match_context_copy_8(__local_test_dat_context__goto_5635_22))
        goto '__ci_bb_197
    }

    '__ci_bb_195 {
        (__local_failure__goto_5632_13 = (("pcre2_compile_context_copy()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_196 {
        goto '__ci_bb_193
    }

    '__ci_bb_197 {
        if ((if not ((if __local_test_dat_context_copy__goto_5635_48 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_200
        } else {
            goto '__ci_bb_201
        }
    }

    '__ci_bb_198 {
        if (0 != 0) {
            goto '__ci_bb_197
        } else {
            goto '__ci_bb_199
        }
    }

    '__ci_bb_199 {
        (__local_test_con_context_copy__goto_5636_50 = pcre2_convert_context_copy_8(__local_test_con_context__goto_5636_24))
        goto '__ci_bb_202
    }

    '__ci_bb_200 {
        (__local_failure__goto_5632_13 = (("pcre2_match_context_copy()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_201 {
        goto '__ci_bb_198
    }

    '__ci_bb_202 {
        if ((if not ((if __local_test_con_context_copy__goto_5636_50 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_205
        } else {
            goto '__ci_bb_206
        }
    }

    '__ci_bb_203 {
        if (0 != 0) {
            goto '__ci_bb_202
        } else {
            goto '__ci_bb_204
        }
    }

    '__ci_bb_204 {
        (__local_rc__goto_5628_5 = pcre2_set_compile_extra_options_8(__local_test_pat_context__goto_5634_24, 0))
        goto '__ci_bb_207
    }

    '__ci_bb_205 {
        (__local_failure__goto_5632_13 = (("pcre2_convert_context_copy()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_206 {
        goto '__ci_bb_203
    }

    '__ci_bb_207 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_210
        } else {
            goto '__ci_bb_211
        }
    }

    '__ci_bb_208 {
        if (0 != 0) {
            goto '__ci_bb_207
        } else {
            goto '__ci_bb_209
        }
    }

    '__ci_bb_209 {
        (__local_rc__goto_5628_5 = pcre2_set_max_pattern_length_8(__local_test_pat_context__goto_5634_24, 10))
        goto '__ci_bb_212
    }

    '__ci_bb_210 {
        (__local_failure__goto_5632_13 = (("pcre2_set_compile_extra_options()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_211 {
        goto '__ci_bb_208
    }

    '__ci_bb_212 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_215
        } else {
            goto '__ci_bb_216
        }
    }

    '__ci_bb_213 {
        if (0 != 0) {
            goto '__ci_bb_212
        } else {
            goto '__ci_bb_214
        }
    }

    '__ci_bb_214 {
        (__local_rc__goto_5628_5 = pcre2_set_max_pattern_compiled_length_8(__local_test_pat_context__goto_5634_24, 256))
        goto '__ci_bb_217
    }

    '__ci_bb_215 {
        (__local_failure__goto_5632_13 = (("pcre2_set_max_pattern_length()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_216 {
        goto '__ci_bb_213
    }

    '__ci_bb_217 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_220
        } else {
            goto '__ci_bb_221
        }
    }

    '__ci_bb_218 {
        if (0 != 0) {
            goto '__ci_bb_217
        } else {
            goto '__ci_bb_219
        }
    }

    '__ci_bb_219 {
        (__local_rc__goto_5628_5 = pcre2_set_max_varlookbehind_8(__local_test_pat_context__goto_5634_24, 0))
        goto '__ci_bb_222
    }

    '__ci_bb_220 {
        (__local_failure__goto_5632_13 = (("pcre2_set_max_pattern_compiled_length()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_221 {
        goto '__ci_bb_218
    }

    '__ci_bb_222 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_225
        } else {
            goto '__ci_bb_226
        }
    }

    '__ci_bb_223 {
        if (0 != 0) {
            goto '__ci_bb_222
        } else {
            goto '__ci_bb_224
        }
    }

    '__ci_bb_224 {
        (__local_rc__goto_5628_5 = pcre2_set_offset_limit_8(__local_test_dat_context__goto_5635_22, 0))
        goto '__ci_bb_227
    }

    '__ci_bb_225 {
        (__local_failure__goto_5632_13 = (("pcre2_set_max_varlookbehind()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_226 {
        goto '__ci_bb_223
    }

    '__ci_bb_227 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_230
        } else {
            goto '__ci_bb_231
        }
    }

    '__ci_bb_228 {
        if (0 != 0) {
            goto '__ci_bb_227
        } else {
            goto '__ci_bb_229
        }
    }

    '__ci_bb_229 {
        (__local_rc__goto_5628_5 = pcre2_set_bsr_8(__local_test_pat_context__goto_5634_24, 999))
        goto '__ci_bb_232
    }

    '__ci_bb_230 {
        (__local_failure__goto_5632_13 = (("pcre2_set_offset_limit()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_231 {
        goto '__ci_bb_228
    }

    '__ci_bb_232 {
        if ((if not ((if __local_rc__goto_5628_5 == -29: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_235
        } else {
            goto '__ci_bb_236
        }
    }

    '__ci_bb_233 {
        if (0 != 0) {
            goto '__ci_bb_232
        } else {
            goto '__ci_bb_234
        }
    }

    '__ci_bb_234 {
        (__local_rc__goto_5628_5 = pcre2_set_newline_8(__local_test_pat_context__goto_5634_24, 999))
        goto '__ci_bb_237
    }

    '__ci_bb_235 {
        (__local_failure__goto_5632_13 = (("pcre2_set_bsr()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_236 {
        goto '__ci_bb_233
    }

    '__ci_bb_237 {
        if ((if not ((if __local_rc__goto_5628_5 == -29: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_240
        } else {
            goto '__ci_bb_241
        }
    }

    '__ci_bb_238 {
        if (0 != 0) {
            goto '__ci_bb_237
        } else {
            goto '__ci_bb_239
        }
    }

    '__ci_bb_239 {
        (__local_rc__goto_5628_5 = pcre2_set_recursion_limit_8(__local_test_dat_context__goto_5635_22, 10))
        goto '__ci_bb_242
    }

    '__ci_bb_240 {
        (__local_failure__goto_5632_13 = (("pcre2_set_newline()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_241 {
        goto '__ci_bb_238
    }

    '__ci_bb_242 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_245
        } else {
            goto '__ci_bb_246
        }
    }

    '__ci_bb_243 {
        if (0 != 0) {
            goto '__ci_bb_242
        } else {
            goto '__ci_bb_244
        }
    }

    '__ci_bb_244 {
        (__local_rc__goto_5628_5 = pcre2_set_recursion_memory_management_8(__local_test_dat_context__goto_5635_22, null, null, null))
        goto '__ci_bb_247
    }

    '__ci_bb_245 {
        (__local_failure__goto_5632_13 = (("pcre2_set_recursion_limit()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_246 {
        goto '__ci_bb_243
    }

    '__ci_bb_247 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_250
        } else {
            goto '__ci_bb_251
        }
    }

    '__ci_bb_248 {
        if (0 != 0) {
            goto '__ci_bb_247
        } else {
            goto '__ci_bb_249
        }
    }

    '__ci_bb_249 {
        (__local_rc__goto_5628_5 = pcre2_set_optimize_8(null, 0))
        goto '__ci_bb_252
    }

    '__ci_bb_250 {
        (__local_failure__goto_5632_13 = (("pcre2_set_recursion_memory_management()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_251 {
        goto '__ci_bb_248
    }

    '__ci_bb_252 {
        if ((if not ((if __local_rc__goto_5628_5 == -51: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_255
        } else {
            goto '__ci_bb_256
        }
    }

    '__ci_bb_253 {
        if (0 != 0) {
            goto '__ci_bb_252
        } else {
            goto '__ci_bb_254
        }
    }

    '__ci_bb_254 {
        (__local_rc__goto_5628_5 = pcre2_set_optimize_8(__local_test_pat_context__goto_5634_24, 63))
        goto '__ci_bb_257
    }

    '__ci_bb_255 {
        (__local_failure__goto_5632_13 = (("pcre2_set_optimize(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_256 {
        goto '__ci_bb_253
    }

    '__ci_bb_257 {
        if ((if not ((if __local_rc__goto_5628_5 == -34: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_260
        } else {
            goto '__ci_bb_261
        }
    }

    '__ci_bb_258 {
        if (0 != 0) {
            goto '__ci_bb_257
        } else {
            goto '__ci_bb_259
        }
    }

    '__ci_bb_259 {
        (__local_rc__goto_5628_5 = pcre2_set_optimize_8(__local_test_pat_context__goto_5634_24, 70))
        goto '__ci_bb_262
    }

    '__ci_bb_260 {
        (__local_failure__goto_5632_13 = (("pcre2_set_optimize(bad option)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_261 {
        goto '__ci_bb_258
    }

    '__ci_bb_262 {
        if ((if not ((if __local_rc__goto_5628_5 == -34: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_265
        } else {
            goto '__ci_bb_266
        }
    }

    '__ci_bb_263 {
        if (0 != 0) {
            goto '__ci_bb_262
        } else {
            goto '__ci_bb_264
        }
    }

    '__ci_bb_264 {
        (__local_rc__goto_5628_5 = pcre2_set_glob_escape_8(__local_test_con_context__goto_5636_24, 0))
        goto '__ci_bb_267
    }

    '__ci_bb_265 {
        (__local_failure__goto_5632_13 = (("pcre2_set_optimize(bad option)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_266 {
        goto '__ci_bb_263
    }

    '__ci_bb_267 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_270
        } else {
            goto '__ci_bb_271
        }
    }

    '__ci_bb_268 {
        if (0 != 0) {
            goto '__ci_bb_267
        } else {
            goto '__ci_bb_269
        }
    }

    '__ci_bb_269 {
        (__local_rc__goto_5628_5 = pcre2_set_glob_escape_8(__local_test_con_context__goto_5636_24, 1))
        goto '__ci_bb_272
    }

    '__ci_bb_270 {
        (__local_failure__goto_5632_13 = (("pcre2_set_glob_escape(0)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_271 {
        goto '__ci_bb_268
    }

    '__ci_bb_272 {
        if ((if not ((if __local_rc__goto_5628_5 == -29: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_275
        } else {
            goto '__ci_bb_276
        }
    }

    '__ci_bb_273 {
        if (0 != 0) {
            goto '__ci_bb_272
        } else {
            goto '__ci_bb_274
        }
    }

    '__ci_bb_274 {
        (__local_rc__goto_5628_5 = pcre2_set_glob_escape_8(__local_test_con_context__goto_5636_24, 256))
        goto '__ci_bb_277
    }

    '__ci_bb_275 {
        (__local_failure__goto_5632_13 = (("pcre2_set_glob_escape(1)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_276 {
        goto '__ci_bb_273
    }

    '__ci_bb_277 {
        if ((if not ((if __local_rc__goto_5628_5 == -29: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_280
        } else {
            goto '__ci_bb_281
        }
    }

    '__ci_bb_278 {
        if (0 != 0) {
            goto '__ci_bb_277
        } else {
            goto '__ci_bb_279
        }
    }

    '__ci_bb_279 {
        (__local_test_compiled_code__goto_5638_13 = pcre2_compile_8((&(unsafe: __local_pattern__goto_5639_13[0]) as *mut u8), (~(0 as c_ulong)), 0, null, (&raw mut __local_erroroffset__goto_5658_12 as *mut c_ulong), __local_test_pat_context__goto_5634_24))
        goto '__ci_bb_282
    }

    '__ci_bb_280 {
        (__local_failure__goto_5632_13 = (("pcre2_set_glob_escape(256)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_281 {
        goto '__ci_bb_278
    }

    '__ci_bb_282 {
        if ((if not ((if __local_test_compiled_code__goto_5638_13 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_285
        } else {
            goto '__ci_bb_286
        }
    }

    '__ci_bb_283 {
        if (0 != 0) {
            goto '__ci_bb_282
        } else {
            goto '__ci_bb_284
        }
    }

    '__ci_bb_284 {
        (__local_test_compiled_code__goto_5638_13 = pcre2_compile_8((&(unsafe: __local_pattern__goto_5639_13[0]) as *mut u8), (~(0 as c_ulong)), 0, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int), null, __local_test_pat_context__goto_5634_24))
        goto '__ci_bb_287
    }

    '__ci_bb_285 {
        (__local_failure__goto_5632_13 = (("test pattern compilation" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_286 {
        goto '__ci_bb_283
    }

    '__ci_bb_287 {
        (__ci_expr_logic_0 = 0)
        if ((if __local_test_compiled_code__goto_5638_13 == null: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_errorcode__goto_5657_5 == 220: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_0 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_290
        } else {
            goto '__ci_bb_291
        }
    }

    '__ci_bb_288 {
        if (0 != 0) {
            goto '__ci_bb_287
        } else {
            goto '__ci_bb_289
        }
    }

    '__ci_bb_289 {
        (__local_test_compiled_code__goto_5638_13 = pcre2_compile_8((&(unsafe: __local_pattern__goto_5639_13[0]) as *mut u8), (~(0 as c_ulong)), 0, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int), (&raw mut __local_erroroffset__goto_5658_12 as *mut c_ulong), __local_test_pat_context__goto_5634_24))
        goto '__ci_bb_292
    }

    '__ci_bb_290 {
        (__local_failure__goto_5632_13 = (("test pattern compilation" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_291 {
        goto '__ci_bb_288
    }

    '__ci_bb_292 {
        (__ci_expr_logic_2 = 0)
        (__ci_expr_logic_1 = 0)
        if ((if __local_test_compiled_code__goto_5638_13 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if __local_errorcode__goto_5657_5 == 100: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if (if __local_erroroffset__goto_5658_12 == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_2 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_295
        } else {
            goto '__ci_bb_296
        }
    }

    '__ci_bb_293 {
        if (0 != 0) {
            goto '__ci_bb_292
        } else {
            goto '__ci_bb_294
        }
    }

    '__ci_bb_294 {
        (mallocs_until_failure = 0)
        (__local_test_match_data__goto_5637_19 = pcre2_match_data_create_8(10, __local_test_gen_context__goto_5633_24))
        goto '__ci_bb_297
    }

    '__ci_bb_295 {
        (__local_failure__goto_5632_13 = (("test pattern compilation" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_296 {
        goto '__ci_bb_293
    }

    '__ci_bb_297 {
        if ((if not ((if __local_test_match_data__goto_5637_19 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_300
        } else {
            goto '__ci_bb_301
        }
    }

    '__ci_bb_298 {
        if (0 != 0) {
            goto '__ci_bb_297
        } else {
            goto '__ci_bb_299
        }
    }

    '__ci_bb_299 {
        (__local_test_match_data__goto_5637_19 = pcre2_match_data_create_8(10, null))
        goto '__ci_bb_302
    }

    '__ci_bb_300 {
        (__local_failure__goto_5632_13 = (("pcre2_match_data_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_301 {
        goto '__ci_bb_298
    }

    '__ci_bb_302 {
        if ((if not ((if __local_test_match_data__goto_5637_19 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_305
        } else {
            goto '__ci_bb_306
        }
    }

    '__ci_bb_303 {
        if (0 != 0) {
            goto '__ci_bb_302
        } else {
            goto '__ci_bb_304
        }
    }

    '__ci_bb_304 {
        goto '__ci_bb_307
    }

    '__ci_bb_305 {
        (__local_failure__goto_5632_13 = (("pcre2_match_data_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_306 {
        goto '__ci_bb_303
    }

    '__ci_bb_307 {
        if ((if not ((if pcre2_get_ovector_count_8(__local_test_match_data__goto_5637_19) == 10: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_310
        } else {
            goto '__ci_bb_311
        }
    }

    '__ci_bb_308 {
        if (0 != 0) {
            goto '__ci_bb_307
        } else {
            goto '__ci_bb_309
        }
    }

    '__ci_bb_309 {
        (__local_sizeval__goto_5630_12 = pcre2_get_match_data_size_8(__local_test_match_data__goto_5637_19))
        goto '__ci_bb_312
    }

    '__ci_bb_310 {
        (__local_failure__goto_5632_13 = (("pcre2_get_ovector_count()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_311 {
        goto '__ci_bb_308
    }

    '__ci_bb_312 {
        if ((if not ((if __local_sizeval__goto_5630_12 >= 2: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_315
        } else {
            goto '__ci_bb_316
        }
    }

    '__ci_bb_313 {
        if (0 != 0) {
            goto '__ci_bb_312
        } else {
            goto '__ci_bb_314
        }
    }

    '__ci_bb_314 {
        (mallocs_until_failure = 2147483647)
        pcre2_match_data_free_8(__local_test_match_data__goto_5637_19)
        (__local_test_match_data__goto_5637_19 = pcre2_match_data_create_8(0, __local_test_gen_context__goto_5633_24))
        goto '__ci_bb_317
    }

    '__ci_bb_315 {
        (__local_failure__goto_5632_13 = (("pcre2_get_match_data_size()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_316 {
        goto '__ci_bb_313
    }

    '__ci_bb_317 {
        if ((if not ((if __local_test_match_data__goto_5637_19 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_320
        } else {
            goto '__ci_bb_321
        }
    }

    '__ci_bb_318 {
        if (0 != 0) {
            goto '__ci_bb_317
        } else {
            goto '__ci_bb_319
        }
    }

    '__ci_bb_319 {
        goto '__ci_bb_322
    }

    '__ci_bb_320 {
        (__local_failure__goto_5632_13 = (("pcre2_match_data_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_321 {
        goto '__ci_bb_318
    }

    '__ci_bb_322 {
        if ((if not ((if pcre2_get_ovector_count_8(__local_test_match_data__goto_5637_19) == 1: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_325
        } else {
            goto '__ci_bb_326
        }
    }

    '__ci_bb_323 {
        if (0 != 0) {
            goto '__ci_bb_322
        } else {
            goto '__ci_bb_324
        }
    }

    '__ci_bb_324 {
        pcre2_match_data_free_8(__local_test_match_data__goto_5637_19)
        (__local_test_match_data__goto_5637_19 = pcre2_match_data_create_from_pattern_8(null, null))
        goto '__ci_bb_327
    }

    '__ci_bb_325 {
        (__local_failure__goto_5632_13 = (("pcre2_get_ovector_count()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_326 {
        goto '__ci_bb_323
    }

    '__ci_bb_327 {
        if ((if not ((if __local_test_match_data__goto_5637_19 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_330
        } else {
            goto '__ci_bb_331
        }
    }

    '__ci_bb_328 {
        if (0 != 0) {
            goto '__ci_bb_327
        } else {
            goto '__ci_bb_329
        }
    }

    '__ci_bb_329 {
        (__local_test_match_data__goto_5637_19 = pcre2_match_data_create_from_pattern_8(__local_test_compiled_code__goto_5638_13, null))
        goto '__ci_bb_332
    }

    '__ci_bb_330 {
        (__local_failure__goto_5632_13 = (("pcre2_match_data_create_from_pattern(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_331 {
        goto '__ci_bb_328
    }

    '__ci_bb_332 {
        if ((if not ((if __local_test_match_data__goto_5637_19 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_335
        } else {
            goto '__ci_bb_336
        }
    }

    '__ci_bb_333 {
        if (0 != 0) {
            goto '__ci_bb_332
        } else {
            goto '__ci_bb_334
        }
    }

    '__ci_bb_334 {
        goto '__ci_bb_337
    }

    '__ci_bb_335 {
        (__local_failure__goto_5632_13 = (("pcre2_match_data_create_from_pattern()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_336 {
        goto '__ci_bb_333
    }

    '__ci_bb_337 {
        if ((if not ((if pcre2_get_ovector_count_8(__local_test_match_data__goto_5637_19) == 1: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_340
        } else {
            goto '__ci_bb_341
        }
    }

    '__ci_bb_338 {
        if (0 != 0) {
            goto '__ci_bb_337
        } else {
            goto '__ci_bb_339
        }
    }

    '__ci_bb_339 {
        (mallocs_until_failure = 0)
        pcre2_match_data_free_8(__local_test_match_data__goto_5637_19)
        (__local_test_match_data__goto_5637_19 = pcre2_match_data_create_from_pattern_8(__local_test_compiled_code__goto_5638_13, __local_test_gen_context__goto_5633_24))
        goto '__ci_bb_342
    }

    '__ci_bb_340 {
        (__local_failure__goto_5632_13 = (("pcre2_get_ovector_count()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_341 {
        goto '__ci_bb_338
    }

    '__ci_bb_342 {
        if ((if not ((if __local_test_match_data__goto_5637_19 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_345
        } else {
            goto '__ci_bb_346
        }
    }

    '__ci_bb_343 {
        if (0 != 0) {
            goto '__ci_bb_342
        } else {
            goto '__ci_bb_344
        }
    }

    '__ci_bb_344 {
        (mallocs_until_failure = 2147483647)
        pcre2_match_data_free_8(__local_test_match_data__goto_5637_19)
        (__local_test_match_data__goto_5637_19 = pcre2_match_data_create_from_pattern_8(__local_test_compiled_code__goto_5638_13, __local_test_gen_context__goto_5633_24))
        goto '__ci_bb_347
    }

    '__ci_bb_345 {
        (__local_failure__goto_5632_13 = (("pcre2_match_data_create_from_pattern()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_346 {
        goto '__ci_bb_343
    }

    '__ci_bb_347 {
        if ((if not ((if __local_test_match_data__goto_5637_19 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_350
        } else {
            goto '__ci_bb_351
        }
    }

    '__ci_bb_348 {
        if (0 != 0) {
            goto '__ci_bb_347
        } else {
            goto '__ci_bb_349
        }
    }

    '__ci_bb_349 {
        (__local_rc__goto_5628_5 = pcre2_match_8(__local_test_compiled_code__goto_5638_13, (&(unsafe: __local_pattern__goto_5639_13[0]) as *mut u8), (~(0 as c_ulong)), 0, 16384, __local_test_match_data__goto_5637_19, null))
        goto '__ci_bb_352
    }

    '__ci_bb_350 {
        (__local_failure__goto_5632_13 = (("pcre2_match_data_create_from_pattern()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_351 {
        goto '__ci_bb_348
    }

    '__ci_bb_352 {
        if ((if not ((if __local_rc__goto_5628_5 == 1: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_355
        } else {
            goto '__ci_bb_356
        }
    }

    '__ci_bb_353 {
        if (0 != 0) {
            goto '__ci_bb_352
        } else {
            goto '__ci_bb_354
        }
    }

    '__ci_bb_354 {
        pcre2_match_data_free_8(__local_test_match_data__goto_5637_19)
        (__local_test_match_data__goto_5637_19 = ((null as *mut pcre2_real_match_data_8)))
        (__local_rc__goto_5628_5 = pcre2_pattern_info_8(null, 20, (&raw mut __local_uval__goto_5629_10 as *mut c_uint)))
        goto '__ci_bb_357
    }

    '__ci_bb_355 {
        (__local_failure__goto_5632_13 = (("pcre2_match()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_356 {
        goto '__ci_bb_353
    }

    '__ci_bb_357 {
        if ((if not ((if __local_rc__goto_5628_5 == -51: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_360
        } else {
            goto '__ci_bb_361
        }
    }

    '__ci_bb_358 {
        if (0 != 0) {
            goto '__ci_bb_357
        } else {
            goto '__ci_bb_359
        }
    }

    '__ci_bb_359 {
        (__local_rc__goto_5628_5 = pcre2_pattern_info_8(__local_test_compiled_code__goto_5638_13, 999, null))
        goto '__ci_bb_362
    }

    '__ci_bb_360 {
        (__local_failure__goto_5632_13 = (("pcre2_pattern_info(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_361 {
        goto '__ci_bb_358
    }

    '__ci_bb_362 {
        if ((if not ((if __local_rc__goto_5628_5 == -34: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_365
        } else {
            goto '__ci_bb_366
        }
    }

    '__ci_bb_363 {
        if (0 != 0) {
            goto '__ci_bb_362
        } else {
            goto '__ci_bb_364
        }
    }

    '__ci_bb_364 {
        (__local_rc__goto_5628_5 = pcre2_pattern_info_8(__local_test_compiled_code__goto_5638_13, 999, (&raw mut __local_uval__goto_5629_10 as *mut c_uint)))
        goto '__ci_bb_367
    }

    '__ci_bb_365 {
        (__local_failure__goto_5632_13 = (("pcre2_pattern_info(bad option)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_366 {
        goto '__ci_bb_363
    }

    '__ci_bb_367 {
        if ((if not ((if __local_rc__goto_5628_5 == -34: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_370
        } else {
            goto '__ci_bb_371
        }
    }

    '__ci_bb_368 {
        if (0 != 0) {
            goto '__ci_bb_367
        } else {
            goto '__ci_bb_369
        }
    }

    '__ci_bb_369 {
        (__local_invalid_code__goto_5664_7 = ((with_alloc((1024 as i64)) as *mut c_void)))
        goto '__ci_bb_372
    }

    '__ci_bb_370 {
        (__local_failure__goto_5632_13 = (("pcre2_pattern_info(bad option)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_371 {
        goto '__ci_bb_368
    }

    '__ci_bb_372 {
        if ((if not ((if __local_invalid_code__goto_5664_7 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_375
        } else {
            goto '__ci_bb_376
        }
    }

    '__ci_bb_373 {
        if (0 != 0) {
            goto '__ci_bb_372
        } else {
            goto '__ci_bb_374
        }
    }

    '__ci_bb_374 {
        with_memset((__local_invalid_code__goto_5664_7 as *i8), 0, (1024 as i64))
        (__local_rc__goto_5628_5 = pcre2_pattern_info_8(__local_invalid_code__goto_5664_7, 20, (&raw mut __local_uval__goto_5629_10 as *mut c_uint)))
        goto '__ci_bb_377
    }

    '__ci_bb_375 {
        (__local_failure__goto_5632_13 = (("malloc()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_376 {
        goto '__ci_bb_373
    }

    '__ci_bb_377 {
        if ((if not ((if __local_rc__goto_5628_5 == -31: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_380
        } else {
            goto '__ci_bb_381
        }
    }

    '__ci_bb_378 {
        if (0 != 0) {
            goto '__ci_bb_377
        } else {
            goto '__ci_bb_379
        }
    }

    '__ci_bb_379 {
        (__local_rc__goto_5628_5 = pcre2_regcomp((&raw mut __local_test_preg__goto_5662_9 as *mut regex_t), "abc", 0))
        goto '__ci_bb_382
    }

    '__ci_bb_380 {
        (__local_failure__goto_5632_13 = (("pcre2_pattern_info(bad magic)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_381 {
        goto '__ci_bb_378
    }

    '__ci_bb_382 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_385
        } else {
            goto '__ci_bb_386
        }
    }

    '__ci_bb_383 {
        if (0 != 0) {
            goto '__ci_bb_382
        } else {
            goto '__ci_bb_384
        }
    }

    '__ci_bb_384 {
        (__local_rc__goto_5628_5 = pcre2_regexec((&raw mut __local_test_preg__goto_5662_9 as *mut regex_t), "zabcz", 0, null, 0))
        goto '__ci_bb_387
    }

    '__ci_bb_385 {
        (__local_failure__goto_5632_13 = (("pcre2_regcomp()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_386 {
        goto '__ci_bb_383
    }

    '__ci_bb_387 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_390
        } else {
            goto '__ci_bb_391
        }
    }

    '__ci_bb_388 {
        if (0 != 0) {
            goto '__ci_bb_387
        } else {
            goto '__ci_bb_389
        }
    }

    '__ci_bb_389 {
        (__local_rc__goto_5628_5 = pcre2_regexec((&raw mut __local_test_preg__goto_5662_9 as *mut regex_t), "zabcz", 0, null, 128))
        goto '__ci_bb_392
    }

    '__ci_bb_390 {
        (__local_failure__goto_5632_13 = (("pcre2_regexec(0)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_391 {
        goto '__ci_bb_388
    }

    '__ci_bb_392 {
        if ((if not ((if __local_rc__goto_5628_5 == REG_INVARG: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_395
        } else {
            goto '__ci_bb_396
        }
    }

    '__ci_bb_393 {
        if (0 != 0) {
            goto '__ci_bb_392
        } else {
            goto '__ci_bb_394
        }
    }

    '__ci_bb_394 {
        with_memset(((&(unsafe: __local_errorbuffer8__goto_5661_6[0]) as *mut c_char) as *i8), 0, ((256 * sizeof[c_char]()) as i64))
        (__local_rc__goto_5628_5 = pcre2_regerror(REG_ASSERT, null, (&(unsafe: __local_errorbuffer8__goto_5661_6[0]) as *mut c_char), (256 * sizeof[c_char]())))
        goto '__ci_bb_397
    }

    '__ci_bb_395 {
        (__local_failure__goto_5632_13 = (("pcre2_regexec(REG_STARTEND)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_396 {
        goto '__ci_bb_393
    }

    '__ci_bb_397 {
        (__ci_expr_logic_4 = 0)
        (__ci_expr_logic_3 = 0)
        if ((if __local_rc__goto_5628_5 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if __local_rc__goto_5628_5 <= (((256 * sizeof[c_char]()) as c_int)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_3 != 0) {
            (__ci_expr_logic_4 = (if (if __local_rc__goto_5628_5 == ((string_len((&(unsafe: __local_errorbuffer8__goto_5661_6[0]) as *mut c_char)) as c_int) + 1): 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_4 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_400
        } else {
            goto '__ci_bb_401
        }
    }

    '__ci_bb_398 {
        if (0 != 0) {
            goto '__ci_bb_397
        } else {
            goto '__ci_bb_399
        }
    }

    '__ci_bb_399 {
        (__local_rc__goto_5628_5 = pcre2_regerror(REG_NOMATCH, null, (&(unsafe: __local_errorbuffer8__goto_5661_6[0]) as *mut c_char), (256 * sizeof[c_char]())))
        goto '__ci_bb_402
    }

    '__ci_bb_400 {
        (__local_failure__goto_5632_13 = (("regerror()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_401 {
        goto '__ci_bb_398
    }

    '__ci_bb_402 {
        (__ci_expr_logic_6 = 0)
        (__ci_expr_logic_5 = 0)
        if ((if __local_rc__goto_5628_5 > 0: 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if __local_rc__goto_5628_5 <= (((256 * sizeof[c_char]()) as c_int)): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_logic_6 = (if (if __local_rc__goto_5628_5 == ((string_len((&(unsafe: __local_errorbuffer8__goto_5661_6[0]) as *mut c_char)) as c_int) + 1): 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_405
        } else {
            goto '__ci_bb_406
        }
    }

    '__ci_bb_403 {
        if (0 != 0) {
            goto '__ci_bb_402
        } else {
            goto '__ci_bb_404
        }
    }

    '__ci_bb_404 {
        (__local_rc__goto_5628_5 = pcre2_regerror((REG_ASSERT - 1), null, (&(unsafe: __local_errorbuffer8__goto_5661_6[0]) as *mut c_char), (256 * sizeof[c_char]())))
        goto '__ci_bb_407
    }

    '__ci_bb_405 {
        (__local_failure__goto_5632_13 = (("regerror()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_406 {
        goto '__ci_bb_403
    }

    '__ci_bb_407 {
        (__ci_expr_logic_7 = 0)
        if ((if __local_rc__goto_5628_5 == ((string_len("unknown error code") as c_int) + 1): 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if (if string_cmp((&(unsafe: __local_errorbuffer8__goto_5661_6[0]) as *mut c_char), "unknown error code") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_7 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_410
        } else {
            goto '__ci_bb_411
        }
    }

    '__ci_bb_408 {
        if (0 != 0) {
            goto '__ci_bb_407
        } else {
            goto '__ci_bb_409
        }
    }

    '__ci_bb_409 {
        (__local_rc__goto_5628_5 = pcre2_regerror((REG_NOMATCH + 1), null, (&(unsafe: __local_errorbuffer8__goto_5661_6[0]) as *mut c_char), (256 * sizeof[c_char]())))
        goto '__ci_bb_412
    }

    '__ci_bb_410 {
        (__local_failure__goto_5632_13 = (("regerror(bad error code)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_411 {
        goto '__ci_bb_408
    }

    '__ci_bb_412 {
        (__ci_expr_logic_8 = 0)
        if ((if __local_rc__goto_5628_5 == ((string_len("unknown error code") as c_int) + 1): 1 else: 0) != 0) {
            (__ci_expr_logic_8 = (if (if string_cmp((&(unsafe: __local_errorbuffer8__goto_5661_6[0]) as *mut c_char), "unknown error code") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_8 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_415
        } else {
            goto '__ci_bb_416
        }
    }

    '__ci_bb_413 {
        if (0 != 0) {
            goto '__ci_bb_412
        } else {
            goto '__ci_bb_414
        }
    }

    '__ci_bb_414 {
        (__local_rc__goto_5628_5 = pcre2_get_error_message_8(-29, null, 0))
        goto '__ci_bb_417
    }

    '__ci_bb_415 {
        (__local_failure__goto_5632_13 = (("regerror(bad error code)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_416 {
        goto '__ci_bb_413
    }

    '__ci_bb_417 {
        if ((if not ((if __local_rc__goto_5628_5 == -48: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_420
        } else {
            goto '__ci_bb_421
        }
    }

    '__ci_bb_418 {
        if (0 != 0) {
            goto '__ci_bb_417
        } else {
            goto '__ci_bb_419
        }
    }

    '__ci_bb_419 {
        with_memset(((&(unsafe: __local_errorbuffer__goto_5659_13[0]) as *mut u8) as *i8), 0, ((256 * sizeof[u8]()) as i64))
        (__local_rc__goto_5628_5 = pcre2_get_error_message_8(-29, (&(unsafe: __local_errorbuffer__goto_5659_13[0]) as *mut u8), 0))
        goto '__ci_bb_422
    }

    '__ci_bb_420 {
        (__local_failure__goto_5632_13 = (("pcre2_get_error_message(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_421 {
        goto '__ci_bb_418
    }

    '__ci_bb_422 {
        if ((if not ((if __local_rc__goto_5628_5 == -48: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_425
        } else {
            goto '__ci_bb_426
        }
    }

    '__ci_bb_423 {
        if (0 != 0) {
            goto '__ci_bb_422
        } else {
            goto '__ci_bb_424
        }
    }

    '__ci_bb_424 {
        (__local_rc__goto_5628_5 = pcre2_get_error_message_8(-29, (&(unsafe: __local_errorbuffer__goto_5659_13[0]) as *mut u8), 4))
        goto '__ci_bb_427
    }

    '__ci_bb_425 {
        (__local_failure__goto_5632_13 = (("pcre2_get_error_message(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_426 {
        goto '__ci_bb_423
    }

    '__ci_bb_427 {
        (__ci_expr_logic_9 = 0)
        if ((if __local_rc__goto_5628_5 == -48: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if (if pcre2_strcmp_c8_8((&(unsafe: __local_errorbuffer__goto_5659_13[0]) as *mut u8), "bad") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_9 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_430
        } else {
            goto '__ci_bb_431
        }
    }

    '__ci_bb_428 {
        if (0 != 0) {
            goto '__ci_bb_427
        } else {
            goto '__ci_bb_429
        }
    }

    '__ci_bb_429 {
        (__local_rc__goto_5628_5 = pcre2_get_error_message_8(-29, (&(unsafe: __local_errorbuffer__goto_5659_13[0]) as *mut u8), 14))
        goto '__ci_bb_432
    }

    '__ci_bb_430 {
        (__local_failure__goto_5632_13 = (("pcre2_get_error_message(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_431 {
        goto '__ci_bb_428
    }

    '__ci_bb_432 {
        (__ci_expr_logic_10 = 0)
        if ((if __local_rc__goto_5628_5 == -48: 1 else: 0) != 0) {
            (__ci_expr_logic_10 = (if (if pcre2_strcmp_c8_8((&(unsafe: __local_errorbuffer__goto_5659_13[0]) as *mut u8), "bad data valu") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_10 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_435
        } else {
            goto '__ci_bb_436
        }
    }

    '__ci_bb_433 {
        if (0 != 0) {
            goto '__ci_bb_432
        } else {
            goto '__ci_bb_434
        }
    }

    '__ci_bb_434 {
        (__local_rc__goto_5628_5 = pcre2_get_error_message_8(-29, (&(unsafe: __local_errorbuffer__goto_5659_13[0]) as *mut u8), 15))
        goto '__ci_bb_437
    }

    '__ci_bb_435 {
        (__local_failure__goto_5632_13 = (("pcre2_get_error_message(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_436 {
        goto '__ci_bb_433
    }

    '__ci_bb_437 {
        (__ci_expr_logic_11 = 0)
        if ((if __local_rc__goto_5628_5 == 14: 1 else: 0) != 0) {
            (__ci_expr_logic_11 = (if (if pcre2_strcmp_c8_8((&(unsafe: __local_errorbuffer__goto_5659_13[0]) as *mut u8), "bad data value") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_11 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_440
        } else {
            goto '__ci_bb_441
        }
    }

    '__ci_bb_438 {
        if (0 != 0) {
            goto '__ci_bb_437
        } else {
            goto '__ci_bb_439
        }
    }

    '__ci_bb_439 {
        (__local_test_tables__goto_5665_16 = pcre2_maketables_8(null))
        goto '__ci_bb_442
    }

    '__ci_bb_440 {
        (__local_failure__goto_5632_13 = (("pcre2_get_error_message(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_441 {
        goto '__ci_bb_438
    }

    '__ci_bb_442 {
        if ((if not ((if __local_test_tables__goto_5665_16 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_445
        } else {
            goto '__ci_bb_446
        }
    }

    '__ci_bb_443 {
        if (0 != 0) {
            goto '__ci_bb_442
        } else {
            goto '__ci_bb_444
        }
    }

    '__ci_bb_444 {
        pcre2_maketables_free_8(null, __local_test_tables__goto_5665_16)
        (__local_test_tables__goto_5665_16 = pcre2_maketables_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_447
    }

    '__ci_bb_445 {
        (__local_failure__goto_5632_13 = (("pcre2_maketables(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_446 {
        goto '__ci_bb_443
    }

    '__ci_bb_447 {
        if ((if not ((if __local_test_tables__goto_5665_16 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_450
        } else {
            goto '__ci_bb_451
        }
    }

    '__ci_bb_448 {
        if (0 != 0) {
            goto '__ci_bb_447
        } else {
            goto '__ci_bb_449
        }
    }

    '__ci_bb_449 {
        pcre2_maketables_free_8(__local_test_gen_context__goto_5633_24, __local_test_tables__goto_5665_16)
        (mallocs_until_failure = 0)
        (__local_test_tables__goto_5665_16 = pcre2_maketables_8(__local_test_gen_context__goto_5633_24))
        goto '__ci_bb_452
    }

    '__ci_bb_450 {
        (__local_failure__goto_5632_13 = (("pcre2_maketables()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_451 {
        goto '__ci_bb_448
    }

    '__ci_bb_452 {
        if ((if not ((if __local_test_tables__goto_5665_16 == null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_455
        } else {
            goto '__ci_bb_456
        }
    }

    '__ci_bb_453 {
        if (0 != 0) {
            goto '__ci_bb_452
        } else {
            goto '__ci_bb_454
        }
    }

    '__ci_bb_454 {
        (mallocs_until_failure = 2147483647)
        (__local_rc__goto_5628_5 = pcre2_callout_enumerate_8(null, callout_enumerate_function_void_8, null))
        goto '__ci_bb_457
    }

    '__ci_bb_455 {
        (__local_failure__goto_5632_13 = (("pcre2_maketables()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_456 {
        goto '__ci_bb_453
    }

    '__ci_bb_457 {
        if ((if not ((if __local_rc__goto_5628_5 == -51: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_460
        } else {
            goto '__ci_bb_461
        }
    }

    '__ci_bb_458 {
        if (0 != 0) {
            goto '__ci_bb_457
        } else {
            goto '__ci_bb_459
        }
    }

    '__ci_bb_459 {
        (__local_rc__goto_5628_5 = pcre2_callout_enumerate_8(__local_invalid_code__goto_5664_7, callout_enumerate_function_void_8, null))
        goto '__ci_bb_462
    }

    '__ci_bb_460 {
        (__local_failure__goto_5632_13 = (("pcre2_callout_enumerate(null)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_461 {
        goto '__ci_bb_458
    }

    '__ci_bb_462 {
        if ((if not ((if __local_rc__goto_5628_5 == -31: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_465
        } else {
            goto '__ci_bb_466
        }
    }

    '__ci_bb_463 {
        if (0 != 0) {
            goto '__ci_bb_462
        } else {
            goto '__ci_bb_464
        }
    }

    '__ci_bb_464 {
        pcre2_code_free_8(__local_test_compiled_code__goto_5638_13)
        (__local_test_compiled_code__goto_5638_13 = pcre2_compile_8((&(unsafe: __local_callout_int_pattern__goto_5640_13[0]) as *mut u8), (~(0 as c_ulong)), 0, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int), (&raw mut __local_erroroffset__goto_5658_12 as *mut c_ulong), null))
        goto '__ci_bb_467
    }

    '__ci_bb_465 {
        (__local_failure__goto_5632_13 = (("pcre2_callout_enumerate(invalid)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_466 {
        goto '__ci_bb_463
    }

    '__ci_bb_467 {
        if ((if not ((if __local_test_compiled_code__goto_5638_13 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_470
        } else {
            goto '__ci_bb_471
        }
    }

    '__ci_bb_468 {
        if (0 != 0) {
            goto '__ci_bb_467
        } else {
            goto '__ci_bb_469
        }
    }

    '__ci_bb_469 {
        (__local_rc__goto_5628_5 = pcre2_callout_enumerate_8(__local_test_compiled_code__goto_5638_13, callout_enumerate_function_void_8, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int)))
        goto '__ci_bb_472
    }

    '__ci_bb_470 {
        (__local_failure__goto_5632_13 = (("test pattern compilation" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_471 {
        goto '__ci_bb_468
    }

    '__ci_bb_472 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_475
        } else {
            goto '__ci_bb_476
        }
    }

    '__ci_bb_473 {
        if (0 != 0) {
            goto '__ci_bb_472
        } else {
            goto '__ci_bb_474
        }
    }

    '__ci_bb_474 {
        (__local_errorcode__goto_5657_5 = -12)
        (__local_rc__goto_5628_5 = pcre2_callout_enumerate_8(__local_test_compiled_code__goto_5638_13, callout_enumerate_function_fail_8, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int)))
        goto '__ci_bb_477
    }

    '__ci_bb_475 {
        (__local_failure__goto_5632_13 = (("pcre2_callout_enumerate(void)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_476 {
        goto '__ci_bb_473
    }

    '__ci_bb_477 {
        if ((if not ((if __local_rc__goto_5628_5 == -12: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_480
        } else {
            goto '__ci_bb_481
        }
    }

    '__ci_bb_478 {
        if (0 != 0) {
            goto '__ci_bb_477
        } else {
            goto '__ci_bb_479
        }
    }

    '__ci_bb_479 {
        pcre2_code_free_8(__local_test_compiled_code__goto_5638_13)
        (__local_test_compiled_code__goto_5638_13 = pcre2_compile_8((&(unsafe: __local_callout_str_pattern__goto_5642_13[0]) as *mut u8), (~(0 as c_ulong)), 0, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int), (&raw mut __local_erroroffset__goto_5658_12 as *mut c_ulong), null))
        goto '__ci_bb_482
    }

    '__ci_bb_480 {
        (__local_failure__goto_5632_13 = (("pcre2_callout_enumerate(fail)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_481 {
        goto '__ci_bb_478
    }

    '__ci_bb_482 {
        if ((if not ((if __local_test_compiled_code__goto_5638_13 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_485
        } else {
            goto '__ci_bb_486
        }
    }

    '__ci_bb_483 {
        if (0 != 0) {
            goto '__ci_bb_482
        } else {
            goto '__ci_bb_484
        }
    }

    '__ci_bb_484 {
        (__local_errorcode__goto_5657_5 = -123)
        (__local_rc__goto_5628_5 = pcre2_callout_enumerate_8(__local_test_compiled_code__goto_5638_13, callout_enumerate_function_fail_8, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int)))
        goto '__ci_bb_487
    }

    '__ci_bb_485 {
        (__local_failure__goto_5632_13 = (("test pattern compilation" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_486 {
        goto '__ci_bb_483
    }

    '__ci_bb_487 {
        if ((if not ((if __local_rc__goto_5628_5 == -123: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_490
        } else {
            goto '__ci_bb_491
        }
    }

    '__ci_bb_488 {
        if (0 != 0) {
            goto '__ci_bb_487
        } else {
            goto '__ci_bb_489
        }
    }

    '__ci_bb_489 {
        pcre2_substring_free_8(null)
        pcre2_substring_list_free_8(null)
        pcre2_code_free_8(__local_test_compiled_code__goto_5638_13)
        (__local_test_compiled_code__goto_5638_13 = pcre2_compile_8((&(unsafe: __local_capture_pattern__goto_5645_13[0]) as *mut u8), (~(0 as c_ulong)), 0, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int), (&raw mut __local_erroroffset__goto_5658_12 as *mut c_ulong), null))
        goto '__ci_bb_492
    }

    '__ci_bb_490 {
        (__local_failure__goto_5632_13 = (("pcre2_callout_enumerate(fail)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_491 {
        goto '__ci_bb_488
    }

    '__ci_bb_492 {
        if ((if not ((if __local_test_compiled_code__goto_5638_13 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_495
        } else {
            goto '__ci_bb_496
        }
    }

    '__ci_bb_493 {
        if (0 != 0) {
            goto '__ci_bb_492
        } else {
            goto '__ci_bb_494
        }
    }

    '__ci_bb_494 {
        pcre2_match_data_free_8(__local_test_match_data__goto_5637_19)
        (__local_test_match_data__goto_5637_19 = pcre2_match_data_create_from_pattern_8(__local_test_compiled_code__goto_5638_13, __local_test_gen_context__goto_5633_24))
        goto '__ci_bb_497
    }

    '__ci_bb_495 {
        (__local_failure__goto_5632_13 = (("test pattern compilation" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_496 {
        goto '__ci_bb_493
    }

    '__ci_bb_497 {
        if ((if not ((if __local_test_match_data__goto_5637_19 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_500
        } else {
            goto '__ci_bb_501
        }
    }

    '__ci_bb_498 {
        if (0 != 0) {
            goto '__ci_bb_497
        } else {
            goto '__ci_bb_499
        }
    }

    '__ci_bb_499 {
        (__local_rc__goto_5628_5 = pcre2_match_8(__local_test_compiled_code__goto_5638_13, (&(unsafe: __local_subject_abcz__goto_5649_13[0]) as *mut u8), (~(0 as c_ulong)), 0, 0, __local_test_match_data__goto_5637_19, null))
        goto '__ci_bb_502
    }

    '__ci_bb_500 {
        (__local_failure__goto_5632_13 = (("pcre2_match_data_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_501 {
        goto '__ci_bb_498
    }

    '__ci_bb_502 {
        if ((if not ((if __local_rc__goto_5628_5 == 2: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_505
        } else {
            goto '__ci_bb_506
        }
    }

    '__ci_bb_503 {
        if (0 != 0) {
            goto '__ci_bb_502
        } else {
            goto '__ci_bb_504
        }
    }

    '__ci_bb_504 {
        (__local_sizeval__goto_5630_12 = 2)
        (__local_rc__goto_5628_5 = pcre2_substring_copy_byname_8(__local_test_match_data__goto_5637_19, (&(unsafe: __local_name_n__goto_5652_13[0]) as *mut u8), (&(unsafe: __local_copy_buf__goto_5666_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_507
    }

    '__ci_bb_505 {
        (__local_failure__goto_5632_13 = (("pcre2_match()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_506 {
        goto '__ci_bb_503
    }

    '__ci_bb_507 {
        (__ci_expr_logic_12 = 0)
        if ((if __local_rc__goto_5628_5 == -48: 1 else: 0) != 0) {
            (__ci_expr_logic_12 = (if (if __local_sizeval__goto_5630_12 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_12 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_510
        } else {
            goto '__ci_bb_511
        }
    }

    '__ci_bb_508 {
        if (0 != 0) {
            goto '__ci_bb_507
        } else {
            goto '__ci_bb_509
        }
    }

    '__ci_bb_509 {
        (__local_sizeval__goto_5630_12 = 3)
        (__local_rc__goto_5628_5 = pcre2_substring_copy_byname_8(__local_test_match_data__goto_5637_19, (&(unsafe: __local_name_n__goto_5652_13[0]) as *mut u8), (&(unsafe: __local_copy_buf__goto_5666_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_512
    }

    '__ci_bb_510 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_copy_byname(small buffer)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_511 {
        goto '__ci_bb_508
    }

    '__ci_bb_512 {
        (__ci_expr_logic_13 = 0)
        if ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_13 = (if (if __local_sizeval__goto_5630_12 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_13 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_515
        } else {
            goto '__ci_bb_516
        }
    }

    '__ci_bb_513 {
        if (0 != 0) {
            goto '__ci_bb_512
        } else {
            goto '__ci_bb_514
        }
    }

    '__ci_bb_514 {
        (__local_sizeval__goto_5630_12 = 4)
        (__local_rc__goto_5628_5 = pcre2_substring_copy_byname_8(__local_test_match_data__goto_5637_19, (&(unsafe: __local_name_n__goto_5652_13[0]) as *mut u8), (&(unsafe: __local_copy_buf__goto_5666_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_517
    }

    '__ci_bb_515 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_copy_byname(small buffer)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_516 {
        goto '__ci_bb_513
    }

    '__ci_bb_517 {
        (__ci_expr_logic_14 = 0)
        if ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if (if __local_sizeval__goto_5630_12 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_14 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_520
        } else {
            goto '__ci_bb_521
        }
    }

    '__ci_bb_518 {
        if (0 != 0) {
            goto '__ci_bb_517
        } else {
            goto '__ci_bb_519
        }
    }

    '__ci_bb_519 {
        (__local_sizeval__goto_5630_12 = 2)
        (__local_rc__goto_5628_5 = pcre2_substring_copy_bynumber_8(__local_test_match_data__goto_5637_19, 1, (&(unsafe: __local_copy_buf__goto_5666_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_522
    }

    '__ci_bb_520 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_copy_byname(small buffer)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_521 {
        goto '__ci_bb_518
    }

    '__ci_bb_522 {
        (__ci_expr_logic_15 = 0)
        if ((if __local_rc__goto_5628_5 == -48: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if (if __local_sizeval__goto_5630_12 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_15 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_525
        } else {
            goto '__ci_bb_526
        }
    }

    '__ci_bb_523 {
        if (0 != 0) {
            goto '__ci_bb_522
        } else {
            goto '__ci_bb_524
        }
    }

    '__ci_bb_524 {
        (__local_sizeval__goto_5630_12 = 3)
        (__local_rc__goto_5628_5 = pcre2_substring_copy_bynumber_8(__local_test_match_data__goto_5637_19, 1, (&(unsafe: __local_copy_buf__goto_5666_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_527
    }

    '__ci_bb_525 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_copy_bynumber(small buffer)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_526 {
        goto '__ci_bb_523
    }

    '__ci_bb_527 {
        (__ci_expr_logic_16 = 0)
        if ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if (if __local_sizeval__goto_5630_12 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_16 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_530
        } else {
            goto '__ci_bb_531
        }
    }

    '__ci_bb_528 {
        if (0 != 0) {
            goto '__ci_bb_527
        } else {
            goto '__ci_bb_529
        }
    }

    '__ci_bb_529 {
        (mallocs_until_failure = 0)
        (__local_sizeval__goto_5630_12 = 0)
        (__local_sptrval__goto_5631_14 = ((null as *mut u8)))
        (__local_rc__goto_5628_5 = pcre2_substring_get_byname_8(__local_test_match_data__goto_5637_19, (&(unsafe: __local_name_n__goto_5652_13[0]) as *mut u8), (&raw mut __local_sptrval__goto_5631_14 as *mut *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_532
    }

    '__ci_bb_530 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_copy_bynumber(small buffer)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_531 {
        goto '__ci_bb_528
    }

    '__ci_bb_532 {
        (__ci_expr_logic_17 = 0)
        if ((if __local_rc__goto_5628_5 == -48: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if (if __local_sptrval__goto_5631_14 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_17 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_535
        } else {
            goto '__ci_bb_536
        }
    }

    '__ci_bb_533 {
        if (0 != 0) {
            goto '__ci_bb_532
        } else {
            goto '__ci_bb_534
        }
    }

    '__ci_bb_534 {
        (__local_sizeval__goto_5630_12 = 0)
        (__local_rc__goto_5628_5 = pcre2_substring_get_bynumber_8(__local_test_match_data__goto_5637_19, 1, (&raw mut __local_sptrval__goto_5631_14 as *mut *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_537
    }

    '__ci_bb_535 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_get_byname(small buffer)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_536 {
        goto '__ci_bb_533
    }

    '__ci_bb_537 {
        (__ci_expr_logic_18 = 0)
        if ((if __local_rc__goto_5628_5 == -48: 1 else: 0) != 0) {
            (__ci_expr_logic_18 = (if (if __local_sptrval__goto_5631_14 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_18 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_540
        } else {
            goto '__ci_bb_541
        }
    }

    '__ci_bb_538 {
        if (0 != 0) {
            goto '__ci_bb_537
        } else {
            goto '__ci_bb_539
        }
    }

    '__ci_bb_539 {
        (mallocs_until_failure = 2147483647)
        (__local_sizeval__goto_5630_12 = 0)
        (__local_rc__goto_5628_5 = pcre2_substring_length_bynumber_8(__local_test_match_data__goto_5637_19, 1, (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_542
    }

    '__ci_bb_540 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_get_bynumber(small buffer)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_541 {
        goto '__ci_bb_538
    }

    '__ci_bb_542 {
        (__ci_expr_logic_19 = 0)
        if ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_19 = (if (if __local_sizeval__goto_5630_12 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_19 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_545
        } else {
            goto '__ci_bb_546
        }
    }

    '__ci_bb_543 {
        if (0 != 0) {
            goto '__ci_bb_542
        } else {
            goto '__ci_bb_544
        }
    }

    '__ci_bb_544 {
        (__local_rc__goto_5628_5 = pcre2_substring_length_bynumber_8(__local_test_match_data__goto_5637_19, 1, null))
        goto '__ci_bb_547
    }

    '__ci_bb_545 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_length_bynumber()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_546 {
        goto '__ci_bb_543
    }

    '__ci_bb_547 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_550
        } else {
            goto '__ci_bb_551
        }
    }

    '__ci_bb_548 {
        if (0 != 0) {
            goto '__ci_bb_547
        } else {
            goto '__ci_bb_549
        }
    }

    '__ci_bb_549 {
        (__local_sizeval__goto_5630_12 = 0)
        (__local_rc__goto_5628_5 = pcre2_substring_length_byname_8(__local_test_match_data__goto_5637_19, (&(unsafe: __local_name_n__goto_5652_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_552
    }

    '__ci_bb_550 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_length_bynumber()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_551 {
        goto '__ci_bb_548
    }

    '__ci_bb_552 {
        (__ci_expr_logic_20 = 0)
        if ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if (if __local_sizeval__goto_5630_12 == 2: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_20 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_555
        } else {
            goto '__ci_bb_556
        }
    }

    '__ci_bb_553 {
        if (0 != 0) {
            goto '__ci_bb_552
        } else {
            goto '__ci_bb_554
        }
    }

    '__ci_bb_554 {
        (__local_rc__goto_5628_5 = pcre2_substring_length_byname_8(__local_test_match_data__goto_5637_19, (&(unsafe: __local_name_n__goto_5652_13[0]) as *mut u8), null))
        goto '__ci_bb_557
    }

    '__ci_bb_555 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_length_byname()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_556 {
        goto '__ci_bb_553
    }

    '__ci_bb_557 {
        if ((if not ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_560
        } else {
            goto '__ci_bb_561
        }
    }

    '__ci_bb_558 {
        if (0 != 0) {
            goto '__ci_bb_557
        } else {
            goto '__ci_bb_559
        }
    }

    '__ci_bb_559 {
        (__local_rc__goto_5628_5 = pcre2_substring_list_get_8(__local_test_match_data__goto_5637_19, (&raw mut __local_stringlist__goto_5667_15 as *mut *mut *mut u8), (&raw mut __local_lengthslist__goto_5668_13 as *mut *mut c_ulong)))
        goto '__ci_bb_562
    }

    '__ci_bb_560 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_length_byname()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_561 {
        goto '__ci_bb_558
    }

    '__ci_bb_562 {
        (__ci_expr_logic_22 = 0)
        (__ci_expr_logic_21 = 0)
        if ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_21 = (if (if __local_stringlist__goto_5667_15 != null: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_21 != 0) {
            (__ci_expr_logic_22 = (if (if __local_lengthslist__goto_5668_13 != null: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_22 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_565
        } else {
            goto '__ci_bb_566
        }
    }

    '__ci_bb_563 {
        if (0 != 0) {
            goto '__ci_bb_562
        } else {
            goto '__ci_bb_564
        }
    }

    '__ci_bb_564 {
        pcre2_substring_list_free_8(__local_stringlist__goto_5667_15)
        (__local_stringlist__goto_5667_15 = ((null as *mut *mut u8)))
        (__local_rc__goto_5628_5 = pcre2_substring_list_get_8(__local_test_match_data__goto_5637_19, (&raw mut __local_stringlist__goto_5667_15 as *mut *mut *mut u8), null))
        goto '__ci_bb_567
    }

    '__ci_bb_565 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_list_get()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_566 {
        goto '__ci_bb_563
    }

    '__ci_bb_567 {
        (__ci_expr_logic_23 = 0)
        if ((if __local_rc__goto_5628_5 == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_23 = (if (if __local_stringlist__goto_5667_15 != null: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_23 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_570
        } else {
            goto '__ci_bb_571
        }
    }

    '__ci_bb_568 {
        if (0 != 0) {
            goto '__ci_bb_567
        } else {
            goto '__ci_bb_569
        }
    }

    '__ci_bb_569 {
        pcre2_substring_list_free_8(__local_stringlist__goto_5667_15)
        (mallocs_until_failure = 0)
        (__local_stringlist__goto_5667_15 = ((null as *mut *mut u8)))
        (__local_rc__goto_5628_5 = pcre2_substring_list_get_8(__local_test_match_data__goto_5637_19, (&raw mut __local_stringlist__goto_5667_15 as *mut *mut *mut u8), (&raw mut __local_lengthslist__goto_5668_13 as *mut *mut c_ulong)))
        goto '__ci_bb_572
    }

    '__ci_bb_570 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_list_get()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_571 {
        goto '__ci_bb_568
    }

    '__ci_bb_572 {
        (__ci_expr_logic_24 = 0)
        if ((if __local_rc__goto_5628_5 == -48: 1 else: 0) != 0) {
            (__ci_expr_logic_24 = (if (if __local_stringlist__goto_5667_15 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_24 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_575
        } else {
            goto '__ci_bb_576
        }
    }

    '__ci_bb_573 {
        if (0 != 0) {
            goto '__ci_bb_572
        } else {
            goto '__ci_bb_574
        }
    }

    '__ci_bb_574 {
        (mallocs_until_failure = 2147483647)
        (__local_rc__goto_5628_5 = pcre2_match_8(__local_test_compiled_code__goto_5638_13, (&(unsafe: __local_subject_abcz__goto_5649_13[0]) as *mut u8), (~(0 as c_ulong)), 2, 0, __local_test_match_data__goto_5637_19, null))
        goto '__ci_bb_577
    }

    '__ci_bb_575 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_list_get()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_576 {
        goto '__ci_bb_573
    }

    '__ci_bb_577 {
        if ((if not ((if __local_rc__goto_5628_5 == -1: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_580
        } else {
            goto '__ci_bb_581
        }
    }

    '__ci_bb_578 {
        if (0 != 0) {
            goto '__ci_bb_577
        } else {
            goto '__ci_bb_579
        }
    }

    '__ci_bb_579 {
        (__local_sizeval__goto_5630_12 = 4)
        (__local_rc__goto_5628_5 = pcre2_substring_copy_byname_8(__local_test_match_data__goto_5637_19, (&(unsafe: __local_name_n__goto_5652_13[0]) as *mut u8), (&(unsafe: __local_copy_buf__goto_5666_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_582
    }

    '__ci_bb_580 {
        (__local_failure__goto_5632_13 = (("pcre2_match()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_581 {
        goto '__ci_bb_578
    }

    '__ci_bb_582 {
        if ((if not ((if __local_rc__goto_5628_5 == -1: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_585
        } else {
            goto '__ci_bb_586
        }
    }

    '__ci_bb_583 {
        if (0 != 0) {
            goto '__ci_bb_582
        } else {
            goto '__ci_bb_584
        }
    }

    '__ci_bb_584 {
        (__local_rc__goto_5628_5 = pcre2_substring_copy_bynumber_8(__local_test_match_data__goto_5637_19, 1, (&(unsafe: __local_copy_buf__goto_5666_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_587
    }

    '__ci_bb_585 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_copy_byname(no match)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_586 {
        goto '__ci_bb_583
    }

    '__ci_bb_587 {
        if ((if not ((if __local_rc__goto_5628_5 == -1: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_590
        } else {
            goto '__ci_bb_591
        }
    }

    '__ci_bb_588 {
        if (0 != 0) {
            goto '__ci_bb_587
        } else {
            goto '__ci_bb_589
        }
    }

    '__ci_bb_589 {
        (__local_rc__goto_5628_5 = pcre2_substring_get_byname_8(__local_test_match_data__goto_5637_19, (&(unsafe: __local_name_n__goto_5652_13[0]) as *mut u8), (&raw mut __local_sptrval__goto_5631_14 as *mut *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_592
    }

    '__ci_bb_590 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_copy_bynumber(no match)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_591 {
        goto '__ci_bb_588
    }

    '__ci_bb_592 {
        (__ci_expr_logic_25 = 0)
        if ((if __local_rc__goto_5628_5 == -1: 1 else: 0) != 0) {
            (__ci_expr_logic_25 = (if (if __local_sptrval__goto_5631_14 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_25 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_595
        } else {
            goto '__ci_bb_596
        }
    }

    '__ci_bb_593 {
        if (0 != 0) {
            goto '__ci_bb_592
        } else {
            goto '__ci_bb_594
        }
    }

    '__ci_bb_594 {
        (__local_rc__goto_5628_5 = pcre2_substring_get_bynumber_8(__local_test_match_data__goto_5637_19, 1, (&raw mut __local_sptrval__goto_5631_14 as *mut *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_597
    }

    '__ci_bb_595 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_get_byname(no match)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_596 {
        goto '__ci_bb_593
    }

    '__ci_bb_597 {
        (__ci_expr_logic_26 = 0)
        if ((if __local_rc__goto_5628_5 == -1: 1 else: 0) != 0) {
            (__ci_expr_logic_26 = (if (if __local_sptrval__goto_5631_14 == null: 1 else: 0) != 0: 1 else: 0))
        }
        if ((if not (__ci_expr_logic_26 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_600
        } else {
            goto '__ci_bb_601
        }
    }

    '__ci_bb_598 {
        if (0 != 0) {
            goto '__ci_bb_597
        } else {
            goto '__ci_bb_599
        }
    }

    '__ci_bb_599 {
        pcre2_code_free_8(__local_test_compiled_code__goto_5638_13)
        (__local_test_compiled_code__goto_5638_13 = pcre2_compile_8((&(unsafe: __local_pattern__goto_5639_13[0]) as *mut u8), (~(0 as c_ulong)), 0, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int), (&raw mut __local_erroroffset__goto_5658_12 as *mut c_ulong), null))
        goto '__ci_bb_602
    }

    '__ci_bb_600 {
        (__local_failure__goto_5632_13 = (("pcre2_substring_get_bynumber(no match)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_601 {
        goto '__ci_bb_598
    }

    '__ci_bb_602 {
        if ((if not ((if __local_test_compiled_code__goto_5638_13 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_605
        } else {
            goto '__ci_bb_606
        }
    }

    '__ci_bb_603 {
        if (0 != 0) {
            goto '__ci_bb_602
        } else {
            goto '__ci_bb_604
        }
    }

    '__ci_bb_604 {
        (__local_subs_other_code__goto_5670_13 = pcre2_compile_8((&(unsafe: __local_pattern__goto_5639_13[0]) as *mut u8), (~(0 as c_ulong)), 0, (&raw mut __local_errorcode__goto_5657_5 as *mut c_int), (&raw mut __local_erroroffset__goto_5658_12 as *mut c_ulong), null))
        goto '__ci_bb_607
    }

    '__ci_bb_605 {
        (__local_failure__goto_5632_13 = (("test pattern compilation" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_606 {
        goto '__ci_bb_603
    }

    '__ci_bb_607 {
        if ((if not ((if __local_subs_other_code__goto_5670_13 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_610
        } else {
            goto '__ci_bb_611
        }
    }

    '__ci_bb_608 {
        if (0 != 0) {
            goto '__ci_bb_607
        } else {
            goto '__ci_bb_609
        }
    }

    '__ci_bb_609 {
        pcre2_match_data_free_8(__local_test_match_data__goto_5637_19)
        (__local_test_match_data__goto_5637_19 = pcre2_match_data_create_from_pattern_8(__local_test_compiled_code__goto_5638_13, null))
        goto '__ci_bb_612
    }

    '__ci_bb_610 {
        (__local_failure__goto_5632_13 = (("test pattern compilation" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_611 {
        goto '__ci_bb_608
    }

    '__ci_bb_612 {
        if ((if not ((if __local_test_match_data__goto_5637_19 != null: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_615
        } else {
            goto '__ci_bb_616
        }
    }

    '__ci_bb_613 {
        if (0 != 0) {
            goto '__ci_bb_612
        } else {
            goto '__ci_bb_614
        }
    }

    '__ci_bb_614 {
        with_memcpy(((&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8) as *i8), ((&(unsafe: __local_subject_abcz__goto_5649_13[0]) as *mut u8) as *i8), ((5 * sizeof[u8]()) as i64))
        (__local_rc__goto_5628_5 = pcre2_match_8(__local_test_compiled_code__goto_5638_13, (&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8), (~(0 as c_ulong)), 0, 0, __local_test_match_data__goto_5637_19, null))
        goto '__ci_bb_617
    }

    '__ci_bb_615 {
        (__local_failure__goto_5632_13 = (("pcre2_match_data_create()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_616 {
        goto '__ci_bb_613
    }

    '__ci_bb_617 {
        if ((if not ((if __local_rc__goto_5628_5 == 1: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_620
        } else {
            goto '__ci_bb_621
        }
    }

    '__ci_bb_618 {
        if (0 != 0) {
            goto '__ci_bb_617
        } else {
            goto '__ci_bb_619
        }
    }

    '__ci_bb_619 {
        with_memcpy(((&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8) as *i8), ((&(unsafe: __local_subject_abcz__goto_5649_13[0]) as *mut u8) as *i8), ((5 * sizeof[u8]()) as i64))
        (__local_sizeval__goto_5630_12 = ((64 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong))
        (__local_rc__goto_5628_5 = pcre2_substitute_8(__local_test_compiled_code__goto_5638_13, (&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8), (~(0 as c_ulong)), 0, 65536, __local_test_match_data__goto_5637_19, null, null, 0, (&(unsafe: __local_replace_buf__goto_5669_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_622
    }

    '__ci_bb_620 {
        (__local_failure__goto_5632_13 = (("pcre2_match()" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_621 {
        goto '__ci_bb_618
    }

    '__ci_bb_622 {
        if ((if not ((if __local_rc__goto_5628_5 == 1: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_625
        } else {
            goto '__ci_bb_626
        }
    }

    '__ci_bb_623 {
        if (0 != 0) {
            goto '__ci_bb_622
        } else {
            goto '__ci_bb_624
        }
    }

    '__ci_bb_624 {
        with_memcpy((((&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8) + ((1 as isize) as usize)) as *i8), ((&(unsafe: __local_subject_abcz__goto_5649_13[0]) as *mut u8) as *i8), ((5 * sizeof[u8]()) as i64))
        (__local_sizeval__goto_5630_12 = ((64 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong))
        (__local_rc__goto_5628_5 = pcre2_substitute_8(__local_test_compiled_code__goto_5638_13, ((&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8) + ((1 as isize) as usize)), (~(0 as c_ulong)), 0, 65536, __local_test_match_data__goto_5637_19, null, null, 0, (&(unsafe: __local_replace_buf__goto_5669_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_627
    }

    '__ci_bb_625 {
        (__local_failure__goto_5632_13 = (("pcre2_substitute(baseline)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_626 {
        goto '__ci_bb_623
    }

    '__ci_bb_627 {
        if ((if not ((if __local_rc__goto_5628_5 == -72: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_630
        } else {
            goto '__ci_bb_631
        }
    }

    '__ci_bb_628 {
        if (0 != 0) {
            goto '__ci_bb_627
        } else {
            goto '__ci_bb_629
        }
    }

    '__ci_bb_629 {
        with_memcpy(((&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8) as *i8), ((&(unsafe: __local_subject_abcz__goto_5649_13[0]) as *mut u8) as *i8), ((5 * sizeof[u8]()) as i64))
        (__local_substitute_subject__goto_5651_13[4] = 89)
        (__local_substitute_subject__goto_5651_13[5] = 0)
        (__local_sizeval__goto_5630_12 = ((64 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong))
        (__local_rc__goto_5628_5 = pcre2_substitute_8(__local_test_compiled_code__goto_5638_13, (&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8), (~(0 as c_ulong)), 0, 65536, __local_test_match_data__goto_5637_19, null, null, 0, (&(unsafe: __local_replace_buf__goto_5669_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_632
    }

    '__ci_bb_630 {
        (__local_failure__goto_5632_13 = (("pcre2_substitute(moved)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_631 {
        goto '__ci_bb_628
    }

    '__ci_bb_632 {
        if ((if not ((if __local_rc__goto_5628_5 == -72: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_635
        } else {
            goto '__ci_bb_636
        }
    }

    '__ci_bb_633 {
        if (0 != 0) {
            goto '__ci_bb_632
        } else {
            goto '__ci_bb_634
        }
    }

    '__ci_bb_634 {
        with_memcpy(((&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8) as *i8), ((&(unsafe: __local_subject_abcz__goto_5649_13[0]) as *mut u8) as *i8), ((5 * sizeof[u8]()) as i64))
        (__local_sizeval__goto_5630_12 = ((64 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong))
        (__local_rc__goto_5628_5 = pcre2_substitute_8(__local_test_compiled_code__goto_5638_13, (&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8), (~(0 as c_ulong)), 1, 65536, __local_test_match_data__goto_5637_19, null, null, 0, (&(unsafe: __local_replace_buf__goto_5669_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_637
    }

    '__ci_bb_635 {
        (__local_failure__goto_5632_13 = (("pcre2_substitute(extended)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_636 {
        goto '__ci_bb_633
    }

    '__ci_bb_637 {
        if ((if not ((if __local_rc__goto_5628_5 == -73: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_640
        } else {
            goto '__ci_bb_641
        }
    }

    '__ci_bb_638 {
        if (0 != 0) {
            goto '__ci_bb_637
        } else {
            goto '__ci_bb_639
        }
    }

    '__ci_bb_639 {
        with_memcpy(((&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8) as *i8), ((&(unsafe: __local_subject_abcz__goto_5649_13[0]) as *mut u8) as *i8), ((5 * sizeof[u8]()) as i64))
        (__local_sizeval__goto_5630_12 = ((64 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong))
        (__local_rc__goto_5628_5 = pcre2_substitute_8(__local_test_compiled_code__goto_5638_13, (&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8), (~(0 as c_ulong)), 0, ((65536 as c_uint) | (4 as c_uint)), __local_test_match_data__goto_5637_19, null, null, 0, (&(unsafe: __local_replace_buf__goto_5669_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_642
    }

    '__ci_bb_640 {
        (__local_failure__goto_5632_13 = (("pcre2_substitute(offset)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_641 {
        goto '__ci_bb_638
    }

    '__ci_bb_642 {
        if ((if not ((if __local_rc__goto_5628_5 == -74: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_645
        } else {
            goto '__ci_bb_646
        }
    }

    '__ci_bb_643 {
        if (0 != 0) {
            goto '__ci_bb_642
        } else {
            goto '__ci_bb_644
        }
    }

    '__ci_bb_644 {
        with_memcpy(((&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8) as *i8), ((&(unsafe: __local_subject_abcz__goto_5649_13[0]) as *mut u8) as *i8), ((5 * sizeof[u8]()) as i64))
        (__local_sizeval__goto_5630_12 = ((64 * sizeof[u8]()) as c_ulong) / (sizeof[u8]() as c_ulong))
        (__local_rc__goto_5628_5 = pcre2_substitute_8(__local_subs_other_code__goto_5670_13, (&(unsafe: __local_substitute_subject__goto_5651_13[0]) as *mut u8), (~(0 as c_ulong)), 0, 65536, __local_test_match_data__goto_5637_19, null, null, 0, (&(unsafe: __local_replace_buf__goto_5669_13[0]) as *mut u8), (&raw mut __local_sizeval__goto_5630_12 as *mut c_ulong)))
        goto '__ci_bb_647
    }

    '__ci_bb_645 {
        (__local_failure__goto_5632_13 = (("pcre2_substitute(options)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_646 {
        goto '__ci_bb_643
    }

    '__ci_bb_647 {
        if ((if not ((if __local_rc__goto_5628_5 == -71: 1 else: 0) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_650
        } else {
            goto '__ci_bb_651
        }
    }

    '__ci_bb_648 {
        if (0 != 0) {
            goto '__ci_bb_647
        } else {
            goto '__ci_bb_649
        }
    }

    '__ci_bb_649 {
        goto '__ci_bb_6
    }

    '__ci_bb_650 {
        (__local_failure__goto_5632_13 = (("pcre2_substitute(pattern)" as *const c_char)))
        goto '__ci_bb_6
    }

    '__ci_bb_651 {
        goto '__ci_bb_648
    }

    '__ci_bb_652 {
        pcre2_code_free_8(__local_test_compiled_code__goto_5638_13)
        goto '__ci_bb_653
    }

    '__ci_bb_653 {
        if ((if __local_subs_other_code__goto_5670_13 != null: 1 else: 0) != 0) {
            goto '__ci_bb_654
        } else {
            goto '__ci_bb_655
        }
    }

    '__ci_bb_654 {
        pcre2_code_free_8(__local_subs_other_code__goto_5670_13)
        goto '__ci_bb_655
    }

    '__ci_bb_655 {
        if ((if __local_test_match_data__goto_5637_19 != null: 1 else: 0) != 0) {
            goto '__ci_bb_656
        } else {
            goto '__ci_bb_657
        }
    }

    '__ci_bb_656 {
        pcre2_match_data_free_8(__local_test_match_data__goto_5637_19)
        goto '__ci_bb_657
    }

    '__ci_bb_657 {
        if ((if __local_test_con_context_copy__goto_5636_50 != null: 1 else: 0) != 0) {
            goto '__ci_bb_658
        } else {
            goto '__ci_bb_659
        }
    }

    '__ci_bb_658 {
        pcre2_convert_context_free_8(__local_test_con_context_copy__goto_5636_50)
        goto '__ci_bb_659
    }

    '__ci_bb_659 {
        if ((if __local_test_dat_context_copy__goto_5635_48 != null: 1 else: 0) != 0) {
            goto '__ci_bb_660
        } else {
            goto '__ci_bb_661
        }
    }

    '__ci_bb_660 {
        pcre2_match_context_free_8(__local_test_dat_context_copy__goto_5635_48)
        goto '__ci_bb_661
    }

    '__ci_bb_661 {
        if ((if __local_test_pat_context_copy__goto_5634_50 != null: 1 else: 0) != 0) {
            goto '__ci_bb_662
        } else {
            goto '__ci_bb_663
        }
    }

    '__ci_bb_662 {
        pcre2_compile_context_free_8(__local_test_pat_context_copy__goto_5634_50)
        goto '__ci_bb_663
    }

    '__ci_bb_663 {
        if ((if __local_test_gen_context_copy__goto_5633_50 != null: 1 else: 0) != 0) {
            goto '__ci_bb_664
        } else {
            goto '__ci_bb_665
        }
    }

    '__ci_bb_664 {
        pcre2_general_context_free_8(__local_test_gen_context_copy__goto_5633_50)
        goto '__ci_bb_665
    }

    '__ci_bb_665 {
        if ((if __local_test_con_context__goto_5636_24 != null: 1 else: 0) != 0) {
            goto '__ci_bb_666
        } else {
            goto '__ci_bb_667
        }
    }

    '__ci_bb_666 {
        pcre2_convert_context_free_8(__local_test_con_context__goto_5636_24)
        goto '__ci_bb_667
    }

    '__ci_bb_667 {
        if ((if __local_test_dat_context__goto_5635_22 != null: 1 else: 0) != 0) {
            goto '__ci_bb_668
        } else {
            goto '__ci_bb_669
        }
    }

    '__ci_bb_668 {
        pcre2_match_context_free_8(__local_test_dat_context__goto_5635_22)
        goto '__ci_bb_669
    }

    '__ci_bb_669 {
        if ((if __local_test_pat_context__goto_5634_24 != null: 1 else: 0) != 0) {
            goto '__ci_bb_670
        } else {
            goto '__ci_bb_671
        }
    }

    '__ci_bb_670 {
        pcre2_compile_context_free_8(__local_test_pat_context__goto_5634_24)
        goto '__ci_bb_671
    }

    '__ci_bb_671 {
        if ((if __local_test_gen_context__goto_5633_24 != null: 1 else: 0) != 0) {
            goto '__ci_bb_672
        } else {
            goto '__ci_bb_673
        }
    }

    '__ci_bb_672 {
        pcre2_general_context_free_8(__local_test_gen_context__goto_5633_24)
        goto '__ci_bb_673
    }

    '__ci_bb_673 {
        with_free((__local_invalid_code__goto_5664_7 as *mut i8))
        if ((if __local_failure__goto_5632_13 != null: 1 else: 0) != 0) {
            goto '__ci_bb_674
        } else {
            goto '__ci_bb_675
        }
    }

    '__ci_bb_674 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Unit test error in %s\n", __local_failure__goto_5632_13)
        colour_end(libc_stderr())
        exit(1)
        goto '__ci_bb_675
    }

    '__ci_bb_675 {
        return
    }

}

fn jit_compile_test() -> c_int {
    return pcre2_jit_compile_8(null, 512)

}

fn pcre2_config_(__param_what: c_uint, __param_where_: *mut c_void) -> c_int {
    return pcre2_config_8(__param_what, __param_where_)

}

fn config_str(__param_what: c_uint, __param_where_: *mut i8) {
    config_str_8(__param_what, __param_where_)

}

fn decode_modifiers(__param_p: *mut u8, __param_ctx: c_int, __param_pctl: *mut patctl, __param_dctl: *mut datctl) -> c_int {
    return decode_modifiers_8(__param_p, __param_ctx, __param_pctl, __param_dctl)

}

fn print_error_message_file(__param_file: *mut c_void, __param_errorcode: c_int, __param_before: *const i8, __param_after: *const i8, __param_badcode_ok: c_int) -> c_int {
    return print_error_message_file_8(__param_file, __param_errorcode, __param_before, __param_after, __param_badcode_ok)

}

fn process_command() -> c_int {
    return process_command_8()

}

fn process_pattern() -> c_int {
    return process_pattern_8()

}

fn have_active_pattern() -> c_int {
    return have_active_pattern_8()

}

fn free_active_pattern() {
    free_active_pattern_8()

}

fn process_data() -> c_int {
    return process_data_8()

}

fn init_globals() {
    init_globals_8()

}

fn free_globals() {
    free_globals_8()

}

fn unittest() {
    unittest_8()

}

fn print_version(__param_f: *mut c_void, __param_include_mode: c_int) {
    var __local_buf: [64]c_char

    config_str(11, (&(unsafe: __local_buf[0]) as *mut c_char))

    fprintf(__param_f, "PCRE2 version %s", (&(unsafe: __local_buf[0]) as *mut c_char))

    if (__param_include_mode != 0) {
        fprintf(__param_f, " (%d-bit)", test_mode)

    }

    fprintf(__param_f, "\n")

}

fn print_unicode_version(__param_f: *mut c_void) {
    var __local_buf: [64]c_char

    config_str(10, (&(unsafe: __local_buf[0]) as *mut c_char))

    fprintf(__param_f, "Unicode version %s", (&(unsafe: __local_buf[0]) as *mut c_char))

}

fn print_jit_target(__param_f: *mut c_void) {
    var __local_buf: [64]c_char

    config_str(2, (&(unsafe: __local_buf[0]) as *mut c_char))

    fputs((&(unsafe: __local_buf[0]) as *mut c_char), __param_f)

}

fn print_newline_config(__param_optval: c_uint, __param_isc: c_int) {
    if ((if not (__param_isc != 0): 1 else: 0) != 0) {
        printf("  Default newline sequence is ")
    }

    if ((if __param_optval < (((7 * sizeof[usize]()) as c_ulong) / (sizeof[usize]() as c_ulong)): 1 else: 0) != 0) {
        printf("%s\n", newlines[__param_optval])
    } else {
        printf("a non-standard value: %d\n", __param_optval)
    }

}

fn usage() {
    printf("Usage:     pcre2test [options] [<input file> [<output file>]]\n\n")

    printf("Input and output default to stdin and stdout.\n")

    printf("This version of pcre2test is not linked with readline().\n")

    printf("\nOptions:\n")

    printf("  -8            use the 8-bit library\n")

    printf("  -ac           set default pattern modifier PCRE2_AUTO_CALLOUT\n")

    printf("  -AC           as -ac, but also set subject 'callout_extra' modifier\n")

    printf("  -b            set default pattern modifier 'fullbincode'\n")

    printf("  -C            show PCRE2 compile-time options and exit\n")

    printf("  -C arg        show a specific compile-time option and exit with its\n")

    printf("                  value if numeric (else 0). The arg can be:\n")

    printf("     backslash-C    use of \\C is enabled [0, 1]\n")

    printf("     bsr            \\R type [ANYCRLF, ANY]\n")

    printf("     ebcdic         compiled for EBCDIC character code [0, 1]\n")

    printf("     ebcdic-io      if compiled for EBCDIC, whether pcre2test's input\n")

    printf("                      and output is EBCDIC or ASCII [0, 1]\n")

    printf("     ebcdic-nl25    if compiled for EBCDIC, whether NL is 0x25 [0, 1]\n")

    printf("     jit            just-in-time compiler supported [0, 1]\n")

    printf("     jitusable      test JIT usability [0, 1, 2, 3]\n")

    printf("     linksize       internal link size [2, 3, 4]\n")

    printf("     newline        newline type [CR, LF, CRLF, ANYCRLF, ANY, NUL]\n")

    printf("     pcre2-8        8 bit library support enabled [0, 1]\n")

    printf("     pcre2-16       16 bit library support enabled [0, 1]\n")

    printf("     pcre2-32       32 bit library support enabled [0, 1]\n")

    printf("     unicode        Unicode and UTF support enabled [0, 1]\n")

    printf("  --colo[u]r[=<always,auto,never>]\n")

    printf("                show output in colour\n")

    printf("  -d            set default pattern modifier 'debug'\n")

    printf("  -dfa          set default subject modifier 'dfa'\n")

    printf("  -E            preprocess input only (#if ... #endif)\n")

    printf("  -error <n,m,..>  show messages for error numbers, then exit\n")

    printf("  -help         show usage information\n")

    printf("  -i            set default pattern modifier 'info'\n")

    printf("  -jit          set default pattern modifier 'jit'\n")

    printf("  -jitfast      set default pattern modifier 'jitfast'\n")

    printf("  -jitverify    set default pattern modifier 'jitverify'\n")

    printf("  -LM           list pattern and subject modifiers, then exit\n")

    printf("  -LP           list non-script properties, then exit\n")

    printf("  -LS           list supported scripts, then exit\n")

    printf("  -malloc       exercise malloc() failures\n")

    printf("  -q            quiet: do not output PCRE2 version number at start\n")

    printf("  -pattern <s>  set default pattern modifier fields\n")

    printf("  -subject <s>  set default subject modifier fields\n")

    printf("  -S <n>        set stack size to <n> mebibytes\n")

    printf("  -t [<n>]      time compilation and execution, repeating <n> times\n")

    printf("  -tm [<n>]     time execution (matching) only, repeating <n> times\n")

    printf("  -T            same as -t, but show total times at the end\n")

    printf("  -TM           same as -tm, but show total time at the end\n")

    printf("  -unittest     run unit tests, then exit\n")

    printf("  -v|--version  show PCRE2 version and exit\n")

}

fn c_option(__param_arg: *const i8) -> c_int {
    var __local_optval: c_uint

    var __local_i: c_uint = 13

    var __local_rc: c_int

    var __local_yield_: c_int = 0


    var __ci_expr_logic_0: c_int = 0

    if ((if __param_arg != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe: __param_arg[0]) != 45: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__local_i = 0)

        while ((if __local_i < 13: 1 else: 0) != 0) {
            if ((if string_cmp(__param_arg, coptlist[__local_i].name) == 0: 1 else: 0) != 0) {
                break
            }

            (__local_i = __local_i + 1)

        }


        if ((if __local_i >= 13: 1 else: 0) != 0) {
            colour_begin(31, libc_stderr())

            fprintf(libc_stderr(), "pcre2test: Unknown -C option \"%s\"\n", __param_arg)

            colour_end(libc_stderr())


            return 0

        }

        while true {
            match coptlist[__local_i].type_ {
                0 => {
                    pcre2_config_(coptlist[__local_i].value, (&raw mut __local_optval as *mut c_uint))

                    var __ci_expr_ternary_1: *mut c_char = null

                    if ((if __local_optval == 2: 1 else: 0) != 0) {
                        (__ci_expr_ternary_1 = (("ANYCRLF" as *mut c_char)))
                    } else {
                        (__ci_expr_ternary_1 = (("ANY" as *mut c_char)))
                    }

                    printf("%s\n", __ci_expr_ternary_1)


                },
                1 => {
                    (__local_yield_ = coptlist[__local_i].value)

                    printf("%d\n", __local_yield_)

                },
                2 => {
                    pcre2_config_(coptlist[__local_i].value, (&raw mut __local_yield_ as *mut c_int))

                    printf("%d\n", __local_yield_)

                },
                3 => {
                    pcre2_config_(coptlist[__local_i].value, (&raw mut __local_optval as *mut c_uint))

                    print_newline_config(__local_optval, 1)

                },
                4 => {
                    (__local_rc = jit_compile_test())

                    while true {
                        match __local_rc {
                            0 => {
                                (__local_yield_ = 0)
                            },
                            -48 => {
                                (__local_yield_ = 1)
                            },
                            -68 => {
                                (__local_yield_ = 2)
                            },
                            _ => {
                                (__local_yield_ = 3)
                            },
                        }

                        break

                    }

                    printf("%d\n", __local_yield_)

                },
            }

            break

        }

        return __local_yield_

    }


    print_version(libc_stdout(), 0)

    printf("Compiled with\n")

    pcre2_config_(14, (&raw mut __local_optval as *mut c_uint))

    if (((__local_optval as c_uint) & (1 as c_uint)) != 0) {
        printf("  8-bit support\n")
    }

    if (((__local_optval as c_uint) & (2 as c_uint)) != 0) {
        printf("  16-bit support\n")
    }

    if (((__local_optval as c_uint) & (4 as c_uint)) != 0) {
        printf("  32-bit support\n")
    }

    pcre2_config_(9, (&raw mut __local_optval as *mut c_uint))

    if ((if __local_optval != 0: 1 else: 0) != 0) {
        printf("  UTF and UCP support (")

        print_unicode_version(libc_stdout())

        printf(")\n")

    } else {
        printf("  No Unicode support\n")
    }

    pcre2_config_(1, (&raw mut __local_optval as *mut c_uint))

    if ((if __local_optval != 0: 1 else: 0) != 0) {
        printf("  Just-in-time compiler support\n")

        printf("    Architecture: ")

        print_jit_target(libc_stdout())

        printf("\n")

        printf("    Can allocate executable memory: ")

        (__local_rc = jit_compile_test())

        while true {
            match __local_rc {
                0 => {
                    printf("Yes\n")
                },
                -48 => {
                    printf("No (so cannot work)\n")
                },
                _ => {
                    colour_begin(31, libc_stdout())

                    fprintf(libc_stdout(), "\n** Unexpected return %d from pcre2_jit_compile(NULL, PCRE2_JIT_TEST_ALLOC)\n", __local_rc)

                    colour_end(libc_stdout())


                    colour_begin(31, libc_stdout())

                    fprintf(libc_stdout(), "** Should not occur\n")

                    colour_end(libc_stdout())


                    (__local_yield_ = 1)

                },
            }

            break

        }

    } else {
        printf("  No just-in-time compiler support\n")

    }

    pcre2_config_(5, (&raw mut __local_optval as *mut c_uint))

    print_newline_config(__local_optval, 0)

    pcre2_config_(0, (&raw mut __local_optval as *mut c_uint))

    var __ci_expr_ternary_5: *mut c_char = null

    if ((if __local_optval == 2: 1 else: 0) != 0) {
        (__ci_expr_ternary_5 = (("CR, LF, or CRLF only" as *mut c_char)))
    } else {
        (__ci_expr_ternary_5 = (("all Unicode newlines" as *mut c_char)))
    }

    printf("  \\R matches %s\n", __ci_expr_ternary_5)


    pcre2_config_(13, (&raw mut __local_optval as *mut c_uint))

    var __ci_expr_ternary_6: *mut c_char = null

    if (__local_optval != 0) {
        (__ci_expr_ternary_6 = (("not " as *mut c_char)))
    } else {
        (__ci_expr_ternary_6 = (("" as *mut c_char)))
    }

    printf("  \\C is %ssupported\n", __ci_expr_ternary_6)


    printf("  Internal link size\n")

    pcre2_config_(3, (&raw mut __local_optval as *mut c_uint))

    printf("    Requested = %d\n", __local_optval)

    pcre2_config_(16, (&raw mut __local_optval as *mut c_uint))

    printf("    Effective = %d\n", __local_optval)

    pcre2_config_(6, (&raw mut __local_optval as *mut c_uint))

    printf("  Parentheses nest limit = %d\n", __local_optval)

    pcre2_config_(12, (&raw mut __local_optval as *mut c_uint))

    printf("  Default heap limit = %d kibibytes\n", __local_optval)

    pcre2_config_(4, (&raw mut __local_optval as *mut c_uint))

    printf("  Default match limit = %d\n", __local_optval)

    pcre2_config_(7, (&raw mut __local_optval as *mut c_uint))

    printf("  Default depth limit = %d\n", __local_optval)

    printf("  pcre2test has neither libreadline nor libedit support\n")

    return __local_yield_

}

fn format_list_item(__param_ff: *mut c_short, __param_buff: *mut i8, __param_isscript: c_int) {
    var __local_buff = __param_buff
    var __local_count: c_int

    var __local_maxi: c_int = 0

    var __local_maxs: *const c_char = (("" as *const c_char))

    var __local_max: c_ulong = 0

    (__local_count = 0)

    while ((if (unsafe: __param_ff[__local_count]) >= 0: 1 else: 0) != 0) {

        (__local_count = __local_count + 1)

    }


    var __local_i: c_int = 0

    while ((if (unsafe: __param_ff[__local_i]) >= 0: 1 else: 0) != 0) {
        var __local_s: *const c_char = ((((&(unsafe: utt_names[0]) as *const c_char) + (((unsafe: __param_ff[__local_i]) as isize) as usize)) as *const c_char))

        var __local_len: c_ulong = string_len(__local_s)

        var __ci_expr_logic_0: c_int = 0

        if (__param_isscript != 0) {
            (__ci_expr_logic_0 = (if (if __local_len == 3: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_maxi = __local_i)

            (__local_max = __local_len)

            (__local_maxs = ((__local_s as *const c_char)))

            break

        } else {
            if ((if __local_len > __local_max: 1 else: 0) != 0) {
                (__local_max = __local_len)

                (__local_maxi = __local_i)

                (__local_maxs = ((__local_s as *const c_char)))

            }
        }



        (__local_i = __local_i + 1)

    }


    strcpy(__local_buff, __local_maxs)

    (__local_buff = __local_buff + (__local_max as usize))

    if ((if __local_count > 1: 1 else: 0) != 0) {
        var __local_sep: *const c_char = ((" (" as *const c_char))

        var __local_i_1: c_int = 0

        while ((if __local_i_1 < __local_count: 1 else: 0) != 0) {
            if ((if __local_i_1 == __local_maxi: 1 else: 0) != 0) {
                (__local_i_1 = __local_i_1 + 1)

                continue

            }

            (__local_buff = __local_buff + ((sprintf(__local_buff, "%s%s", __local_sep, ((&(unsafe: utt_names[0]) as *const c_char) + (((unsafe: __param_ff[__local_i_1]) as isize) as usize))) as isize) as usize))

            (__local_sep = ((", " as *const c_char)))


            (__local_i_1 = __local_i_1 + 1)

        }


        sprintf(__local_buff, ")")

    }

}

fn display_properties(__param_wantscripts: c_int) {
    var __local_seentypes: [1024]c_ushort

    var __local_seenvalues: [1024]c_ushort

    var __local_seencount: c_int = 0

    var __local_found: [256][6]c_short

    var __local_fc: c_int = 0

    var __local_colwidth: c_int = 40

    var __local_n: c_int = with 0 as __ci_expr_seq_15 {
        var __ci_expr_ternary_0: c_int = 0
        if (__param_wantscripts != 0) {
            (__ci_expr_ternary_0 = ucp_Script_Count)
        } else {
            (__ci_expr_ternary_0 = ucp_Bprop_Count)
        }
        __ci_expr_ternary_0
    }

    var __local_i: c_ulong = 0

    while ((if __local_i < 510: 1 else: 0) != 0) {
        var __local_k: c_int

        var __local_m: c_int = 0

        var __local_fv: *mut c_short

        var __local_t: *const ucp_type_table = ((&(unsafe: utt[0]) as *const ucp_type_table) + (__local_i as usize))

        var __local_value: c_uint = __local_t.value

        if (__param_wantscripts != 0) {
            var __ci_expr_logic_1: c_int = 0

            if ((if __local_t.type_ != 3: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if __local_t.type_ != 4: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                (__local_i = __local_i + 1)

                continue

            }


        } else {
            if ((if __local_t.type_ != 12: 1 else: 0) != 0) {
                (__local_i = __local_i + 1)

                continue

            }

        }

        (__local_k = 0)

        while ((if __local_k < __local_seencount: 1 else: 0) != 0) {
            var __ci_expr_logic_2: c_int = 0

            if ((if __local_t.type_ == __local_seentypes[__local_k]: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if __local_t.value == __local_seenvalues[__local_k]: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_2 != 0) {
                break
            }



            (__local_k = __local_k + 1)

        }


        if ((if __local_k < __local_seencount: 1 else: 0) != 0) {
            (__local_i = __local_i + 1)

            continue

        }

        (__local_seentypes[__local_seencount] = __local_t.type_)

        var __ci_expr_old_3: c_int = __local_seencount

        (__local_seencount = __local_seencount + 1)

        (__local_seenvalues[__ci_expr_old_3] = __local_t.value)


        var __ci_expr_old_4: c_int = __local_fc

        (__local_fc = __local_fc + 1)

        (__local_fv = (&(unsafe: __local_found[__ci_expr_old_4][0]) as *mut c_short))


        var __ci_expr_old_5: c_int = __local_m

        (__local_m = __local_m + 1)

        ((unsafe: __local_fv[__ci_expr_old_5]) = __local_t.name_offset)


        var __local_j: c_ulong = ((__local_i as c_ulong) +% (1 as c_ulong))

        while ((if __local_j < 510: 1 else: 0) != 0) {
            var __local_tt: *const ucp_type_table = ((&(unsafe: utt[0]) as *const ucp_type_table) + (__local_j as usize))

            var __ci_expr_logic_6: c_int

            if ((if __local_tt.type_ != __local_t.type_: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_6 = (if (if __local_tt.value != __local_value: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_6 != 0) {
                (__local_j = __local_j + 1)

                continue

            }


            if ((if __local_m >= 5: 1 else: 0) != 0) {
                colour_begin(31, libc_stdout())

                fprintf(libc_stdout(), "** Too many synonyms: %s ignored\n", ((&(unsafe: utt_names[0]) as *const c_char) + ((__local_tt.name_offset as c_uint) as usize)))

                colour_end(libc_stdout())

            } else {
                var __ci_expr_old_7: c_int = __local_m

                (__local_m = __local_m + 1)

                ((unsafe: __local_fv[__ci_expr_old_7]) = __local_tt.name_offset)

            }


            (__local_j = __local_j + 1)

        }


        ((unsafe: __local_fv[__local_m]) = -1)


        (__local_i = __local_i + 1)

    }


    var __ci_expr_ternary_8: *mut c_char = null

    if (__param_wantscripts != 0) {
        (__ci_expr_ternary_8 = (("SCRIPTS" as *mut c_char)))
    } else {
        (__ci_expr_ternary_8 = (("PROPERTIES" as *mut c_char)))
    }

    printf("-------------------------- SUPPORTED %s --------------------------\n\n", __ci_expr_ternary_8)


    if ((if not (__param_wantscripts != 0): 1 else: 0) != 0) {
        printf("This release of PCRE2 supports Unicode's general category properties such\nas Lu (upper case letter), bi-directional properties such as Bidi_Class,\nand the following binary (yes/no) properties:\n\n")
    }

    var __local_k_1: c_int = 0

    while ((if __local_k_1 < ((__local_n + 1) / 2): 1 else: 0) != 0) {
        var __local_x: c_int

        var __local_buff1: [128]c_char

        var __local_buff2: [128]c_char

        format_list_item((&(unsafe: __local_found[__local_k_1][0]) as *mut c_short), (&(unsafe: __local_buff1[0]) as *mut c_char), __param_wantscripts)

        (__local_x = __local_k_1 + ((__local_n + 1) / 2))

        if ((if __local_x < __local_n: 1 else: 0) != 0) {
            format_list_item((&(unsafe: __local_found[__local_x][0]) as *mut c_short), (&(unsafe: __local_buff2[0]) as *mut c_char), __param_wantscripts)
        } else {
            (__local_buff2[0] = 0)
        }

        (__local_x = printf("%s", (&(unsafe: __local_buff1[0]) as *mut c_char)))

        while true {
            var __ci_expr_old_9: c_int = __local_x

            (__local_x = __local_x + 1)

            if (not ((if __ci_expr_old_9 < __local_colwidth: 1 else: 0) != 0)) {
                break
            }

            printf(" ")

        }

        printf("%s\n", (&(unsafe: __local_buff2[0]) as *mut c_char))


        (__local_k_1 = __local_k_1 + 1)

    }


}

fn display_one_modifier(__param_m: *mut modstruct, __param_for_pattern: c_int) {
    var __local_c: c_uint = with 0 as __ci_expr_seq_20 {
        var __ci_expr_ternary_2: c_int = 0
        var __ci_expr_logic_1: c_int = 0
        if ((if not (__param_for_pattern != 0): 1 else: 0) != 0) {
            var __ci_expr_logic_0: c_int
            if ((if __param_m.which == MOD_PND: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if (if __param_m.which == MOD_PNDP: 1 else: 0) != 0: 1 else: 0))
            }
            (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_ternary_2 = 42)
        } else {
            (__ci_expr_ternary_2 = 32)
        }
        __ci_expr_ternary_2
    }

    printf("%c%s", __local_c, __param_m.name)

    var __local_i: c_ulong = 0

    while ((if __local_i < 10: 1 else: 0) != 0) {
        if ((if string_cmp(__param_m.name, c1modlist[__local_i].fullname) == 0: 1 else: 0) != 0) {
            printf(" (%c)", c1modlist[__local_i].onechar)
        }


        (__local_i = __local_i + 1)

    }


}

fn display_selected_modifiers(__param_for_pattern: c_int, __param_title: *const i8) {
    var __local_i: c_uint

    var __local_j: c_uint


    var __local_n: c_uint = 0

    var __local_list: [156]c_uint

    var __local_extra: [156]c_uint

    (__local_i = 0)

    while ((if __local_i < 156: 1 else: 0) != 0) {
        var __local_is_pattern: c_int = 1

        var __local_m: *mut modstruct = ((&(unsafe: modlist[0]) as *mut modstruct) + (__local_i as usize))

        while true {
            match __local_m.which {
                0 => {
                    0
                },
                2 => {
                    0
                },
                3 => {
                    0
                },
                1 => {
                    (__local_is_pattern = 0)
                },
                4 => {
                    (__local_is_pattern = 0)
                },
                5 => {
                    (__local_is_pattern = 0)
                },
                8 => {
                    (__local_is_pattern = 0)
                },
                9 => {
                    (__local_is_pattern = 0)
                },
                6 => {
                    (__local_is_pattern = __param_for_pattern)
                },
                7 => {
                    (__local_is_pattern = __param_for_pattern)
                },
                _ => {
                    printf("** Unknown type for modifier \"%s\"\n", __local_m.name)

                    do {
                        0
                    } while (0 != 0)

                    exit(1)

                },
            }

            break

        }

        if ((if __param_for_pattern == __local_is_pattern: 1 else: 0) != 0) {
            (__local_extra[__local_n] = 0)

            var __local_k: c_ulong = 0

            while ((if __local_k < 10: 1 else: 0) != 0) {
                if ((if string_cmp(__local_m.name, c1modlist[__local_k].fullname) == 0: 1 else: 0) != 0) {
                    (__local_extra[__local_n] = __local_extra[__local_n] + 4)

                    break

                }


                (__local_k = __local_k + 1)

            }


            var __ci_expr_old_1: c_uint = __local_n

            (__local_n = __local_n + 1)

            (__local_list[__ci_expr_old_1] = __local_i)


        }


        (__local_i = __local_i + 1)

    }


    printf("-------------- %s MODIFIERS --------------\n", __param_title)

    (__local_i = 0)

    (__local_j = (((__local_n as c_uint) +% (1 as c_uint)) as c_uint) / (2 as c_uint))


    while ((if __local_i < ((((__local_n as c_uint) +% (1 as c_uint)) as c_uint) / (2 as c_uint)): 1 else: 0) != 0) {
        var __local_m_1: *mut modstruct = ((&(unsafe: modlist[0]) as *mut modstruct) + (__local_list[__local_i] as usize))

        display_one_modifier(__local_m_1, __param_for_pattern)

        if ((if __local_j < __local_n: 1 else: 0) != 0) {
            var __local_k_1: c_ulong = ((((27 as c_ulong) -% (string_len(__local_m_1.name) as c_ulong)) as c_ulong) -% (__local_extra[__local_i] as c_ulong))

            while true {
                var __ci_expr_old_2: c_ulong = __local_k_1

                (__local_k_1 = __local_k_1 - 1)

                if (not ((if __ci_expr_old_2 > 0: 1 else: 0) != 0)) {
                    break
                }

                printf(" ")

            }

            display_one_modifier(((&(unsafe: modlist[0]) as *mut modstruct) + (__local_list[__local_j] as usize)), __param_for_pattern)

        }

        printf("\n")


        (__local_i = __local_i + 1)

        (__local_j = __local_j + 1)


    }


}

fn display_modifiers() {
    printf("An asterisk on a subject modifier means that it may be given on a pattern\nline, in order to apply to all subjects matched by that pattern. Modifiers\nthat are listed for both patterns and subjects have different effects in\neach case.\n\n")

    display_selected_modifiers(1, "PATTERN")

    printf("\n")

    display_selected_modifiers(0, "SUBJECT")

}

fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    var __local_argc = __param_argc
    var __local_yield___goto_3644_10: c_uint = 0

    var __local_op__goto_3645_10: c_uint = 0

    var __local_notdone__goto_3646_6: c_int = 0

    var __local_quiet__goto_3647_6: c_int = 0

    var __local_showtotaltimes__goto_3648_6: c_int = 0

    var __local_skipping__goto_3649_6: c_int = 0

    var __local_skipping_endif__goto_3650_6: c_int = 0

    var __local_arg_subject__goto_3651_7: *mut i8 = null

    var __local_arg_pattern__goto_3652_7: *mut i8 = null

    var __local_arg_error__goto_3653_7: *mut i8 = null

    var __local_endptr__goto_3682_9: *mut i8 = null

    var __local_arg__goto_3683_9: *mut i8 = null

    var __local_uli__goto_3684_17: c_ulong = 0

    var __local_rc__goto_3780_9: c_int = 0

    var __local_stack_size__goto_3781_14: c_uint = 0

    var __local_rlim__goto_3782_19: rlimit

    var __local_rlim_old__goto_3782_25: rlimit

    var __local_both__goto_3848_9: c_int = 0

    var __local_val__goto_3931_11: *mut i8 = null

    var __local_errcode__goto_3962_7: c_int = 0

    var __local_endptr__goto_3963_9: *mut i8 = null

    var __local_li__goto_3964_8: c_long = 0

    var __local_p__goto_4052_18: *const u8 = null

    var __local_p_notsp__goto_4053_18: *const u8 = null

    var __local_rc__goto_4054_7: c_int = 0

    var __local_expectdata__goto_4055_8: c_int = 0

    var __local_is_pattern_comment__goto_4056_8: c_int = 0

    var __local_is_data_comment__goto_4057_8: c_int = 0

    var __local_pad__goto_4173_15: *const i8 = null

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    var __ci_expr_logic_3: c_int = 0

    var __ci_expr_logic_2: c_int = 0

    var __ci_expr_logic_4: c_int = 0

    var __ci_expr_logic_6: c_int = 0

    var __ci_expr_logic_5: c_int = 0

    var __ci_expr_logic_8: c_int = 0

    var __ci_expr_logic_7: c_int = 0

    var __ci_expr_logic_11: c_int = 0

    var __ci_expr_logic_10: c_int = 0

    var __ci_expr_logic_9: c_int = 0

    var __ci_expr_logic_12: c_int = 0

    var __ci_expr_logic_13: c_int = 0

    var __ci_expr_logic_14: c_int = 0

    var __ci_expr_logic_15: c_int = 0

    var __ci_expr_logic_16: c_int = 0

    var __ci_expr_logic_19: c_int = 0

    var __ci_expr_logic_17: c_int = 0

    var __ci_expr_logic_22: c_int = 0

    var __ci_expr_logic_20: c_int = 0

    var __ci_expr_logic_23: c_int = 0

    var __ci_expr_ternary_24: *mut c_char = null

    var __ci_expr_logic_26: c_int = 0

    var __ci_expr_logic_29: c_int = 0

    var __ci_expr_logic_33: c_int = 0

    var __ci_expr_logic_31: c_int = 0

    var __ci_expr_logic_30: c_int = 0

    var __ci_expr_ternary_35: c_int = 0

    var __ci_expr_logic_34: c_int = 0

    var __ci_expr_logic_36: c_int = 0

    var __ci_expr_logic_37: c_int = 0

    var __ci_expr_logic_38: c_int = 0

    var __ci_expr_logic_39: c_int = 0

    var __ci_expr_logic_40: c_int = 0

    var __ci_expr_logic_41: c_int = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_yield___goto_3644_10 = 0)
        (__local_op__goto_3645_10 = 1)
        (__local_notdone__goto_3646_6 = 1)
        (__local_quiet__goto_3647_6 = 0)
        (__local_showtotaltimes__goto_3648_6 = 0)
        (__local_skipping__goto_3649_6 = 0)
        (__local_skipping_endif__goto_3650_6 = 0)
        (__local_arg_subject__goto_3651_7 = ((null as *mut c_char)))
        (__local_arg_pattern__goto_3652_7 = ((null as *mut c_char)))
        (__local_arg_error__goto_3653_7 = ((null as *mut c_char)))
        (buffer = (((with_alloc((pbuffer8_size as i64)) as *mut c_void) as *mut u8)))
        (pbuffer8 = (((with_alloc((pbuffer8_size as i64)) as *mut c_void) as *mut u8)))
        (locale_name[0] = 0)
        patctl_zero((&raw mut def_patctl as *mut patctl))
        datctl_zero((&raw mut def_datctl as *mut datctl))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__ci_expr_logic_1 = 0)
        (__ci_expr_logic_0 = 0)
        if ((if __local_argc > 1: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe: (unsafe: __param_argv[__local_op__goto_3645_10])[0]) == 45: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe: (unsafe: __param_argv[__local_op__goto_3645_10])[1]) != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_1 != 0) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_2 {
        (__local_arg__goto_3683_9 = (((unsafe: __param_argv[__local_op__goto_3645_10]) as *mut c_char)))
        if ((if string_cmp(__local_arg__goto_3683_9, "-LM") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_3 {
        if ((if __local_arg_error__goto_3653_7 != null: 1 else: 0) != 0) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_4 {
        display_modifiers()
        goto '__ci_bb_6
    }

    '__ci_bb_5 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-LP") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_6 {
        (__ci_expr_logic_40 = 0)
        if ((if infile != null: 1 else: 0) != 0) {
            (__ci_expr_logic_40 = (if (if infile != libc_stdin(): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_40 != 0) {
            goto '__ci_bb_197
        } else {
            goto '__ci_bb_198
        }
    }

    '__ci_bb_7 {
        display_properties(0)
        goto '__ci_bb_6
    }

    '__ci_bb_8 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-LS") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_9 {
        display_properties(1)
        goto '__ci_bb_6
    }

    '__ci_bb_10 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-unittest") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_11 {
        unittest()
        goto '__ci_bb_6
    }

    '__ci_bb_12 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-C") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_13 {
        (__local_yield___goto_3644_10 = c_option((unsafe: __param_argv[((__local_op__goto_3645_10 as c_uint) +% (1 as c_uint))])))
        goto '__ci_bb_6
    }

    '__ci_bb_14 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-8") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_15 {
        (test_mode = 8)
        goto '__ci_bb_17
    }

    '__ci_bb_16 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-16") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_17 {
        (__local_op__goto_3645_10 = __local_op__goto_3645_10 + 1)
        (__local_argc = __local_argc - 1)
        goto '__ci_bb_1
    }

    '__ci_bb_18 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: This version of PCRE2 was built without 16-bit support\n")
        colour_end(libc_stderr())
        exit(1)
        goto '__ci_bb_20
    }

    '__ci_bb_19 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-32") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_20 {
        goto '__ci_bb_17
    }

    '__ci_bb_21 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: This version of PCRE2 was built without 32-bit support\n")
        colour_end(libc_stderr())
        exit(1)
        goto '__ci_bb_23
    }

    '__ci_bb_22 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-E") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_24
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_23 {
        goto '__ci_bb_20
    }

    '__ci_bb_24 {
        (preprocess_only = 1)
        goto '__ci_bb_26
    }

    '__ci_bb_25 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-q") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_27
        } else {
            goto '__ci_bb_28
        }
    }

    '__ci_bb_26 {
        goto '__ci_bb_23
    }

    '__ci_bb_27 {
        (__local_quiet__goto_3647_6 = 1)
        goto '__ci_bb_29
    }

    '__ci_bb_28 {
        (__ci_expr_logic_3 = 0)
        (__ci_expr_logic_2 = 0)
        if ((if string_cmp(__local_arg__goto_3683_9, "-S") == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __local_argc > 2: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_2 != 0) {
            (__local_uli__goto_3684_17 = strtoul((unsafe: __param_argv[((__local_op__goto_3645_10 as c_uint) +% (1 as c_uint))]), (&raw mut __local_endptr__goto_3682_9 as *mut *mut c_char), 10))

            (__ci_expr_logic_3 = (if (if (unsafe: *__local_endptr__goto_3682_9) == 0: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_3 != 0) {
            goto '__ci_bb_30
        } else {
            goto '__ci_bb_31
        }
    }

    '__ci_bb_29 {
        goto '__ci_bb_26
    }

    '__ci_bb_30 {
        (__local_rc__goto_3780_9 = 0)
        if ((if __local_uli__goto_3684_17 > 2047: 1 else: 0) != 0) {
            goto '__ci_bb_33
        } else {
            goto '__ci_bb_34
        }
    }

    '__ci_bb_31 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-AC") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_32 {
        goto '__ci_bb_29
    }

    '__ci_bb_33 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Argument for -S is too big\n")
        colour_end(libc_stderr())
        exit(1)
        goto '__ci_bb_34
    }

    '__ci_bb_34 {
        (__local_stack_size__goto_3781_14 = ((__local_uli__goto_3684_17 as c_uint)))
        getrlimit(3, (&raw mut __local_rlim_old__goto_3782_25 as *mut rlimit))
        with_memcpy((&raw mut __local_rlim__goto_3782_19 as *i8), (&raw const __local_rlim_old__goto_3782_25 as *i8), sizeof[rlimit]())
        (__local_rlim__goto_3782_19.rlim_cur = ((((__local_stack_size__goto_3781_14 as c_uint) *% (1024 as c_uint)) as c_uint) *% (1024 as c_uint)))
        (__ci_expr_logic_4 = 0)
        if ((if (&raw const __local_rlim__goto_3782_19 as *const rlimit).rlim_max != (((((1 as c_ulonglong) as c_ulonglong) << (63 as c_uint)) as c_ulonglong) -% (1 as c_ulonglong)): 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if (&raw const __local_rlim__goto_3782_19 as *const rlimit).rlim_cur > (&raw const __local_rlim__goto_3782_19 as *const rlimit).rlim_max: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_4 != 0) {
            goto '__ci_bb_35
        } else {
            goto '__ci_bb_36
        }
    }

    '__ci_bb_35 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: requested stack size %luMiB is greater than hard limit ", (__local_stack_size__goto_3781_14 as c_ulong))
        colour_end(libc_stderr())
        if ((if (((&raw const __local_rlim__goto_3782_19 as *const rlimit).rlim_max as c_ulonglong) % (1048576 as c_ulonglong)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_36 {
        (__ci_expr_logic_6 = 0)
        (__ci_expr_logic_5 = 0)
        if ((if (&raw const __local_rlim_old__goto_3782_25 as *const rlimit).rlim_cur != (((((1 as c_ulonglong) as c_ulonglong) << (63 as c_uint)) as c_ulonglong) -% (1 as c_ulonglong)): 1 else: 0) != 0) {
            (__ci_expr_logic_5 = (if (if (&raw const __local_rlim_old__goto_3782_25 as *const rlimit).rlim_cur <= 2147483647: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_logic_6 = (if (if (&raw const __local_rlim__goto_3782_19 as *const rlimit).rlim_cur > (&raw const __local_rlim_old__goto_3782_25 as *const rlimit).rlim_cur: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_6 != 0) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_37 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "%luMiB\n", ((((&raw const __local_rlim__goto_3782_19 as *const rlimit).rlim_max as c_ulonglong) / (1048576 as c_ulonglong)) as c_ulong))
        colour_end(libc_stderr())
        goto '__ci_bb_39
    }

    '__ci_bb_38 {
        if ((if (((&raw const __local_rlim__goto_3782_19 as *const rlimit).rlim_max as c_ulonglong) % (1024 as c_ulonglong)) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_41
        }
    }

    '__ci_bb_39 {
        exit(1)
        goto '__ci_bb_36
    }

    '__ci_bb_40 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "%luKiB\n", ((((&raw const __local_rlim__goto_3782_19 as *const rlimit).rlim_max as c_ulonglong) / (1024 as c_ulonglong)) as c_ulong))
        colour_end(libc_stderr())
        goto '__ci_bb_42
    }

    '__ci_bb_41 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "%lu bytes\n", ((&raw const __local_rlim__goto_3782_19 as *const rlimit).rlim_max as c_ulong))
        colour_end(libc_stderr())
        goto '__ci_bb_42
    }

    '__ci_bb_42 {
        goto '__ci_bb_39
    }

    '__ci_bb_43 {
        (__local_rc__goto_3780_9 = setrlimit(3, (&raw mut __local_rlim__goto_3782_19 as *mut rlimit)))
        goto '__ci_bb_44
    }

    '__ci_bb_44 {
        if ((if __local_rc__goto_3780_9 != 0: 1 else: 0) != 0) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_45 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: setting stack size %luMiB failed: %s\n", (__local_stack_size__goto_3781_14 as c_ulong), strerror((unsafe: *__error())))
        colour_end(libc_stderr())
        exit(1)
        goto '__ci_bb_46
    }

    '__ci_bb_46 {
        (__local_op__goto_3645_10 = __local_op__goto_3645_10 + 1)
        (__local_argc = __local_argc - 1)
        goto '__ci_bb_32
    }

    '__ci_bb_47 {
        (def_patctl.options = (&raw const def_patctl as *const patctl).options | 4)
        (def_datctl.control2 = (&raw const def_datctl as *const datctl).control2 | 1024)
        goto '__ci_bb_49
    }

    '__ci_bb_48 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-ac") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_49 {
        goto '__ci_bb_32
    }

    '__ci_bb_50 {
        (def_patctl.options = (&raw const def_patctl as *const patctl).options | 4)
        goto '__ci_bb_52
    }

    '__ci_bb_51 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-b") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_53
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_52 {
        goto '__ci_bb_49
    }

    '__ci_bb_53 {
        (def_patctl.control = (&raw const def_patctl as *const patctl).control | 8192)
        goto '__ci_bb_55
    }

    '__ci_bb_54 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-d") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_56
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_55 {
        goto '__ci_bb_52
    }

    '__ci_bb_56 {
        (def_patctl.control = (&raw const def_patctl as *const patctl).control | ((8192 as c_uint) | (131072 as c_uint)))
        goto '__ci_bb_58
    }

    '__ci_bb_57 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-dfa") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_59
        } else {
            goto '__ci_bb_60
        }
    }

    '__ci_bb_58 {
        goto '__ci_bb_55
    }

    '__ci_bb_59 {
        (def_datctl.control = (&raw const def_datctl as *const datctl).control | 512)
        goto '__ci_bb_61
    }

    '__ci_bb_60 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-i") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_62
        } else {
            goto '__ci_bb_63
        }
    }

    '__ci_bb_61 {
        goto '__ci_bb_58
    }

    '__ci_bb_62 {
        (def_patctl.control = (&raw const def_patctl as *const patctl).control | 131072)
        goto '__ci_bb_64
    }

    '__ci_bb_63 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-jit") == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_7 = (if (if string_cmp(__local_arg__goto_3683_9, "-jitverify") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_7 != 0) {
            (__ci_expr_logic_8 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_8 = (if (if string_cmp(__local_arg__goto_3683_9, "-jitfast") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_8 != 0) {
            goto '__ci_bb_65
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_64 {
        goto '__ci_bb_61
    }

    '__ci_bb_65 {
        if ((if (unsafe: __local_arg__goto_3683_9[4]) == 118: 1 else: 0) != 0) {
            goto '__ci_bb_68
        } else {
            goto '__ci_bb_69
        }
    }

    '__ci_bb_66 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-t") == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_9 = (if (if string_cmp(__local_arg__goto_3683_9, "-tm") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_9 != 0) {
            (__ci_expr_logic_10 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_10 = (if (if string_cmp(__local_arg__goto_3683_9, "-T") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_10 != 0) {
            (__ci_expr_logic_11 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_11 = (if (if string_cmp(__local_arg__goto_3683_9, "-TM") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_11 != 0) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_67 {
        goto '__ci_bb_64
    }

    '__ci_bb_68 {
        (def_patctl.control = (&raw const def_patctl as *const patctl).control | 524288)
        goto '__ci_bb_70
    }

    '__ci_bb_69 {
        if ((if (unsafe: __local_arg__goto_3683_9[4]) == 102: 1 else: 0) != 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_72
        }
    }

    '__ci_bb_70 {
        (def_patctl.jit = (((1 as c_uint) | (2 as c_uint)) as c_uint) | (4 as c_uint))
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Warning: JIT support is not available: -jit[fast|verify] calls functions that do nothing.\n")
        colour_end(libc_stderr())
        goto '__ci_bb_67
    }

    '__ci_bb_71 {
        (def_patctl.control = (&raw const def_patctl as *const patctl).control | 262144)
        goto '__ci_bb_72
    }

    '__ci_bb_72 {
        goto '__ci_bb_70
    }

    '__ci_bb_73 {
        (__local_both__goto_3848_9 = (if (unsafe: __local_arg__goto_3683_9[2]) == 0: 1 else: 0))
        (__local_showtotaltimes__goto_3648_6 = (if (unsafe: __local_arg__goto_3683_9[1]) == 84: 1 else: 0))
        (__ci_expr_logic_12 = 0)
        if ((if __local_argc > 2: 1 else: 0) != 0) {
            (__local_uli__goto_3684_17 = strtoul((unsafe: __param_argv[((__local_op__goto_3645_10 as c_uint) +% (1 as c_uint))]), (&raw mut __local_endptr__goto_3682_9 as *mut *mut c_char), 10))

            (__ci_expr_logic_12 = (if (if (unsafe: *__local_endptr__goto_3682_9) == 0: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_12 != 0) {
            goto '__ci_bb_76
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_74 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-malloc") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_85
        } else {
            goto '__ci_bb_86
        }
    }

    '__ci_bb_75 {
        goto '__ci_bb_67
    }

    '__ci_bb_76 {
        if ((if __local_uli__goto_3684_17 == 0: 1 else: 0) != 0) {
            goto '__ci_bb_79
        } else {
            goto '__ci_bb_80
        }
    }

    '__ci_bb_77 {
        (timeitm = 500000)
        goto '__ci_bb_78
    }

    '__ci_bb_78 {
        if (__local_both__goto_3848_9 != 0) {
            goto '__ci_bb_83
        } else {
            goto '__ci_bb_84
        }
    }

    '__ci_bb_79 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Argument for %s must not be zero\n", __local_arg__goto_3683_9)
        colour_end(libc_stderr())
        exit(1)
        goto '__ci_bb_80
    }

    '__ci_bb_80 {
        if ((if __local_uli__goto_3684_17 > 4294967295: 1 else: 0) != 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_81 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Argument for %s is too big\n", __local_arg__goto_3683_9)
        colour_end(libc_stderr())
        exit(1)
        goto '__ci_bb_82
    }

    '__ci_bb_82 {
        (timeitm = ((__local_uli__goto_3684_17 as c_int)))
        (__local_op__goto_3645_10 = __local_op__goto_3645_10 + 1)
        (__local_argc = __local_argc - 1)
        goto '__ci_bb_78
    }

    '__ci_bb_83 {
        (timeit = timeitm)
        goto '__ci_bb_84
    }

    '__ci_bb_84 {
        goto '__ci_bb_75
    }

    '__ci_bb_85 {
        (malloc_testing = 1)
        goto '__ci_bb_87
    }

    '__ci_bb_86 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-help") == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_13 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_13 = (if (if string_cmp(__local_arg__goto_3683_9, "--help") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_13 != 0) {
            goto '__ci_bb_88
        } else {
            goto '__ci_bb_89
        }
    }

    '__ci_bb_87 {
        goto '__ci_bb_75
    }

    '__ci_bb_88 {
        usage()
        goto '__ci_bb_6
    }

    '__ci_bb_89 {
        if ((if with_memcmp((__local_arg__goto_3683_9 as *i8), ("-v" as *i8), (2 as i64)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_14 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_14 = (if (if string_cmp(__local_arg__goto_3683_9, "--version") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_14 != 0) {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_92
        }
    }

    '__ci_bb_90 {
        goto '__ci_bb_87
    }

    '__ci_bb_91 {
        print_version(libc_stdout(), 0)
        goto '__ci_bb_6
    }

    '__ci_bb_92 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-error") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_93 {
        goto '__ci_bb_90
    }

    '__ci_bb_94 {
        (__local_arg_error__goto_3653_7 = (((unsafe: __param_argv[((__local_op__goto_3645_10 as c_uint) +% (1 as c_uint))]) as *mut c_char)))
        goto '__ci_bb_97
    }

    '__ci_bb_95 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-subject") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_98
        } else {
            goto '__ci_bb_99
        }
    }

    '__ci_bb_96 {
        goto '__ci_bb_93
    }

    '__ci_bb_97 {
        if ((if __local_argc <= 2: 1 else: 0) != 0) {
            goto '__ci_bb_104
        } else {
            goto '__ci_bb_105
        }
    }

    '__ci_bb_98 {
        (__local_arg_subject__goto_3651_7 = (((unsafe: __param_argv[((__local_op__goto_3645_10 as c_uint) +% (1 as c_uint))]) as *mut c_char)))
        goto '__ci_bb_97
    }

    '__ci_bb_99 {
        if ((if string_cmp(__local_arg__goto_3683_9, "-pattern") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_101
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_100 {
        goto '__ci_bb_96
    }

    '__ci_bb_101 {
        (__local_arg_pattern__goto_3652_7 = (((unsafe: __param_argv[((__local_op__goto_3645_10 as c_uint) +% (1 as c_uint))]) as *mut c_char)))
        goto '__ci_bb_97
    }

    '__ci_bb_102 {
        if ((if string_cmp(__local_arg__goto_3683_9, "--color") == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_15 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_15 = (if (if string_cmp(__local_arg__goto_3683_9, "--colour") == 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_15 != 0) {
            goto '__ci_bb_106
        } else {
            goto '__ci_bb_107
        }
    }

    '__ci_bb_103 {
        goto '__ci_bb_100
    }

    '__ci_bb_104 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Missing value for %s\n", __local_arg__goto_3683_9)
        colour_end(libc_stderr())
        (__local_yield___goto_3644_10 = 1)
        goto '__ci_bb_6
    }

    '__ci_bb_105 {
        (__local_op__goto_3645_10 = __local_op__goto_3645_10 + 1)
        (__local_argc = __local_argc - 1)
        goto '__ci_bb_103
    }

    '__ci_bb_106 {
        (colour_setting = COLOUR_ALWAYS)
        goto '__ci_bb_108
    }

    '__ci_bb_107 {
        if ((if strstr(__local_arg__goto_3683_9, "--color=") == __local_arg__goto_3683_9: 1 else: 0) != 0) {
            (__ci_expr_logic_16 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_16 = (if (if strstr(__local_arg__goto_3683_9, "--colour=") == __local_arg__goto_3683_9: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_16 != 0) {
            goto '__ci_bb_109
        } else {
            goto '__ci_bb_110
        }
    }

    '__ci_bb_108 {
        goto '__ci_bb_103
    }

    '__ci_bb_109 {
        (__local_val__goto_3931_11 = (((string_find_char(__local_arg__goto_3683_9, 61) + ((1 as isize) as usize)) as *mut c_char)))
        if ((if string_cmp(__local_val__goto_3931_11, "always") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_110 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Unknown or malformed option \"%s\"\n", __local_arg__goto_3683_9)
        colour_end(libc_stderr())
        usage()
        (__local_yield___goto_3644_10 = 1)
        goto '__ci_bb_6
    }

    '__ci_bb_111 {
        goto '__ci_bb_108
    }

    '__ci_bb_112 {
        (colour_setting = COLOUR_ALWAYS)
        goto '__ci_bb_114
    }

    '__ci_bb_113 {
        if ((if string_cmp(__local_val__goto_3931_11, "never") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_116
        }
    }

    '__ci_bb_114 {
        goto '__ci_bb_111
    }

    '__ci_bb_115 {
        (colour_setting = COLOUR_NEVER)
        goto '__ci_bb_117
    }

    '__ci_bb_116 {
        if ((if string_cmp(__local_val__goto_3931_11, "auto") == 0: 1 else: 0) != 0) {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_119
        }
    }

    '__ci_bb_117 {
        goto '__ci_bb_114
    }

    '__ci_bb_118 {
        (colour_setting = COLOUR_AUTO)
        goto '__ci_bb_120
    }

    '__ci_bb_119 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Invalid value for \"%.*s\"\n", (((((__local_val__goto_3931_11 - ((1 as isize) as usize)) as usize) -% (__local_arg__goto_3683_9 as usize)) / sizeof[c_char]()) as c_int), __local_arg__goto_3683_9)
        colour_end(libc_stderr())
        (__local_yield___goto_3644_10 = 1)
        goto '__ci_bb_6
    }

    '__ci_bb_120 {
        goto '__ci_bb_117
    }

    '__ci_bb_121 {
        goto '__ci_bb_123
    }

    '__ci_bb_122 {
        (max_oveccount = 15)
        init_globals()
        (outfile = libc_stderr())
        (__ci_expr_logic_20 = 0)
        if ((if __local_arg_pattern__goto_3652_7 != null: 1 else: 0) != 0) {
            (__ci_expr_logic_20 = (if (if not (decode_modifiers((__local_arg_pattern__goto_3652_7 as *mut u8), CTX_DEFPAT, (&raw mut def_patctl as *mut patctl), null) != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_20 != 0) {
            (__ci_expr_logic_22 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_21: c_int = 0

            if ((if __local_arg_subject__goto_3651_7 != null: 1 else: 0) != 0) {
                (__ci_expr_logic_21 = (if (if not (decode_modifiers((__local_arg_subject__goto_3651_7 as *mut u8), CTX_DEFDAT, null, (&raw mut def_datctl as *mut datctl)) != 0): 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_22 = (if __ci_expr_logic_21 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_22 != 0) {
            goto '__ci_bb_131
        } else {
            goto '__ci_bb_132
        }
    }

    '__ci_bb_123 {
        goto '__ci_bb_124
    }

    '__ci_bb_124 {
        (__local_li__goto_3964_8 = strtol(__local_arg_error__goto_3653_7, (&raw mut __local_endptr__goto_3963_9 as *mut *mut c_char), 10))
        if ((if __local_li__goto_3964_8 > 2147483647: 1 else: 0) != 0) {
            (__ci_expr_logic_17 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_17 = (if (if __local_li__goto_3964_8 < -2147483648: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_17 != 0) {
            (__ci_expr_logic_19 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_18: c_int = 0

            if ((if (unsafe: *__local_endptr__goto_3963_9) != 0: 1 else: 0) != 0) {
                (__ci_expr_logic_18 = (if (if (unsafe: *__local_endptr__goto_3963_9) != 44: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_19 = (if __ci_expr_logic_18 != 0: 1 else: 0))

        }
        if (__ci_expr_logic_19 != 0) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_128
        }
    }

    '__ci_bb_125 {
        goto '__ci_bb_123
    }

    '__ci_bb_127 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: \"%s\" is not a valid error number list\n", __local_arg_error__goto_3653_7)
        colour_end(libc_stderr())
        (__local_yield___goto_3644_10 = 1)
        goto '__ci_bb_6
    }

    '__ci_bb_128 {
        (__local_errcode__goto_3962_7 = ((__local_li__goto_3964_8 as c_int)))
        printf("Error %d: ", __local_errcode__goto_3962_7)
        print_error_message_file(libc_stdout(), __local_errcode__goto_3962_7, "", "\n", 1)
        if ((if (unsafe: *__local_endptr__goto_3963_9) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_129
        } else {
            goto '__ci_bb_130
        }
    }

    '__ci_bb_129 {
        goto '__ci_bb_6
    }

    '__ci_bb_130 {
        (__local_arg_error__goto_3653_7 = (((__local_endptr__goto_3963_9 + ((1 as isize) as usize)) as *mut c_char)))
        goto '__ci_bb_125
    }

    '__ci_bb_131 {
        (__local_yield___goto_3644_10 = 1)
        goto '__ci_bb_6
    }

    '__ci_bb_132 {
        (infile = libc_stdin())
        (outfile = libc_stdout())
        (__ci_expr_logic_23 = 0)
        if ((if __local_argc > 1: 1 else: 0) != 0) {
            (__ci_expr_logic_23 = (if (if string_cmp((unsafe: __param_argv[__local_op__goto_3645_10]), "-") != 0: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_23 != 0) {
            goto '__ci_bb_133
        } else {
            goto '__ci_bb_134
        }
    }

    '__ci_bb_133 {
        (infile = fopen((unsafe: __param_argv[__local_op__goto_3645_10]), "rb"))
        if ((if infile == null: 1 else: 0) != 0) {
            goto '__ci_bb_135
        } else {
            goto '__ci_bb_136
        }
    }

    '__ci_bb_134 {
        if ((if __local_argc > 2: 1 else: 0) != 0) {
            goto '__ci_bb_137
        } else {
            goto '__ci_bb_138
        }
    }

    '__ci_bb_135 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Failed to open \"%s\": %s\n", (unsafe: __param_argv[__local_op__goto_3645_10]), strerror((unsafe: *__error())))
        colour_end(libc_stderr())
        (__local_yield___goto_3644_10 = 1)
        goto '__ci_bb_6
    }

    '__ci_bb_136 {
        goto '__ci_bb_134
    }

    '__ci_bb_137 {
        (outfile = fopen((unsafe: __param_argv[((__local_op__goto_3645_10 as c_uint) +% (1 as c_uint))]), "wb"))
        if ((if outfile == null: 1 else: 0) != 0) {
            goto '__ci_bb_139
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_138 {
        if ((if not (__local_quiet__goto_3647_6 != 0): 1 else: 0) != 0) {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_142
        }
    }

    '__ci_bb_139 {
        colour_begin(31, libc_stderr())
        fprintf(libc_stderr(), "pcre2test: Failed to open \"%s\": %s\n", (unsafe: __param_argv[((__local_op__goto_3645_10 as c_uint) +% (1 as c_uint))]), strerror((unsafe: *__error())))
        colour_end(libc_stderr())
        (__local_yield___goto_3644_10 = 1)
        goto '__ci_bb_6
    }

    '__ci_bb_140 {
        goto '__ci_bb_138
    }

    '__ci_bb_141 {
        print_version(outfile, 1)
        goto '__ci_bb_142
    }

    '__ci_bb_142 {
        (preg.re_pcre2_code = null)
        (preg.re_match_data = null)
        goto '__ci_bb_143
    }

    '__ci_bb_143 {
        if (__local_notdone__goto_3646_6 != 0) {
            goto '__ci_bb_144
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_144 {
        (__local_rc__goto_4054_7 = PR_OK)
        (__local_expectdata__goto_4055_8 = have_active_pattern())
        (__local_expectdata__goto_4055_8 = __local_expectdata__goto_4055_8 | (if (&raw const preg as *const regex_t).re_pcre2_code != null: 1 else: 0))
        (__ci_expr_ternary_24 = null)
        if (__local_expectdata__goto_4055_8 != 0) {
            (__ci_expr_ternary_24 = (("data> " as *mut c_char)))
        } else {
            (__ci_expr_ternary_24 = (("  re> " as *mut c_char)))
        }
        if ((if extend_inputline(infile, buffer, __ci_expr_ternary_24) == null: 1 else: 0) != 0) {
            goto '__ci_bb_146
        } else {
            goto '__ci_bb_147
        }
    }

    '__ci_bb_145 {
        if (__local_skipping_endif__goto_3650_6 != 0) {
            goto '__ci_bb_187
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_146 {
        goto '__ci_bb_145
    }

    '__ci_bb_147 {
        if (__local_skipping_endif__goto_3650_6 != 0) {
            goto '__ci_bb_148
        } else {
            goto '__ci_bb_149
        }
    }

    '__ci_bb_148 {
        if ((if strncmp((buffer as *mut c_char), "#endif", 6) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_26 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_25: c_int

            if ((if (unsafe: buffer[6]) == 0: 1 else: 0) != 0) {
                (__ci_expr_logic_25 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_25 = (if isspace((unsafe: buffer[6])) != 0: 1 else: 0))
            }

            (__ci_expr_logic_26 = (if (if not (__ci_expr_logic_25 != 0): 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_26 != 0) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_151
        }
    }

    '__ci_bb_149 {
        (__local_p_notsp__goto_4053_18 = ((buffer as *const u8)))
        (__local_p__goto_4052_18 = __local_p_notsp__goto_4053_18)
        goto '__ci_bb_152
    }

    '__ci_bb_150 {
        goto '__ci_bb_143
    }

    '__ci_bb_151 {
        (__local_skipping_endif__goto_3650_6 = 0)
        goto '__ci_bb_149
    }

    '__ci_bb_152 {
        if (isspace((unsafe: *__local_p_notsp__goto_4053_18)) != 0) {
            goto '__ci_bb_153
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_153 {
        (__local_p_notsp__goto_4053_18 = __local_p_notsp__goto_4053_18 + 1)
        goto '__ci_bb_152
    }

    '__ci_bb_154 {
        (__ci_expr_logic_29 = 0)
        if ((if (unsafe: __local_p__goto_4052_18[0]) == 35: 1 else: 0) != 0) {
            var __ci_expr_logic_28: c_int

            var __ci_expr_logic_27: c_int

            if (isspace((unsafe: __local_p__goto_4052_18[1])) != 0) {
                (__ci_expr_logic_27 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_27 = (if (if (unsafe: __local_p__goto_4052_18[1]) == 33: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_27 != 0) {
                (__ci_expr_logic_28 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_28 = (if (if (unsafe: __local_p__goto_4052_18[1]) == 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_29 = (if __ci_expr_logic_28 != 0: 1 else: 0))

        }
        (__local_is_pattern_comment__goto_4056_8 = __ci_expr_logic_29)
        (__ci_expr_logic_33 = 0)
        (__ci_expr_logic_31 = 0)
        (__ci_expr_logic_30 = 0)
        if (__local_expectdata__goto_4055_8 != 0) {
            (__ci_expr_logic_30 = (if (if (unsafe: __local_p_notsp__goto_4053_18[0]) == 92: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_30 != 0) {
            (__ci_expr_logic_31 = (if (if (unsafe: __local_p_notsp__goto_4053_18[1]) == 61: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_31 != 0) {
            var __ci_expr_logic_32: c_int

            if (isspace((unsafe: __local_p_notsp__goto_4053_18[2])) != 0) {
                (__ci_expr_logic_32 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_32 = (if (if (unsafe: __local_p_notsp__goto_4053_18[2]) == 0: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_33 = (if __ci_expr_logic_32 != 0: 1 else: 0))

        }
        (__local_is_data_comment__goto_4057_8 = __ci_expr_logic_33)
        if ((if not (isatty(fileno(infile)) != 0): 1 else: 0) != 0) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_155 {
        (__ci_expr_ternary_35 = 0)
        if (__local_is_pattern_comment__goto_4056_8 != 0) {
            (__ci_expr_logic_34 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_34 = (if __local_is_data_comment__goto_4057_8 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_34 != 0) {
            (__ci_expr_ternary_35 = 37)
        } else {
            (__ci_expr_ternary_35 = 32)
        }
        colour_begin(__ci_expr_ternary_35, outfile)
        fprintf(outfile, "%s", (buffer as *mut c_char))
        colour_end(outfile)
        goto '__ci_bb_156
    }

    '__ci_bb_156 {
        fflush(outfile)
        (__ci_expr_logic_36 = 0)
        if (preprocess_only != 0) {
            (__ci_expr_logic_36 = (if (if (unsafe: *__local_p__goto_4052_18) != 35: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_36 != 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_157 {
        goto '__ci_bb_143
    }

    '__ci_bb_158 {
        if (__local_expectdata__goto_4055_8 != 0) {
            (__ci_expr_logic_37 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_37 = (if __local_skipping__goto_3649_6 != 0: 1 else: 0))
        }
        if (__ci_expr_logic_37 != 0) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_159 {
        if ((if (unsafe: *__local_p_notsp__goto_4053_18) == 0: 1 else: 0) != 0) {
            goto '__ci_bb_162
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_160 {
        if ((if (unsafe: *__local_p__goto_4052_18) == 35: 1 else: 0) != 0) {
            goto '__ci_bb_169
        } else {
            goto '__ci_bb_170
        }
    }

    '__ci_bb_161 {
        (__ci_expr_logic_39 = 0)
        if ((if __local_rc__goto_4054_7 == PR_SKIP: 1 else: 0) != 0) {
            (__ci_expr_logic_39 = (if (if not (isatty(fileno(infile)) != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_39 != 0) {
            goto '__ci_bb_179
        } else {
            goto '__ci_bb_180
        }
    }

    '__ci_bb_162 {
        if ((if (&raw const preg as *const regex_t).re_pcre2_code != null: 1 else: 0) != 0) {
            goto '__ci_bb_165
        } else {
            goto '__ci_bb_166
        }
    }

    '__ci_bb_163 {
        (__ci_expr_logic_38 = 0)
        if ((if not (__local_skipping__goto_3649_6 != 0): 1 else: 0) != 0) {
            (__ci_expr_logic_38 = (if (if not (__local_is_data_comment__goto_4057_8 != 0): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_38 != 0) {
            goto '__ci_bb_167
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_164 {
        goto '__ci_bb_161
    }

    '__ci_bb_165 {
        pcre2_regfree((&raw mut preg as *mut regex_t))
        (preg.re_pcre2_code = null)
        (preg.re_match_data = null)
        goto '__ci_bb_166
    }

    '__ci_bb_166 {
        free_active_pattern()
        (__local_skipping__goto_3649_6 = 0)
        setlocale(2, "C")
        goto '__ci_bb_164
    }

    '__ci_bb_167 {
        (__local_rc__goto_4054_7 = process_data())
        goto '__ci_bb_168
    }

    '__ci_bb_168 {
        goto '__ci_bb_164
    }

    '__ci_bb_169 {
        if (__local_is_pattern_comment__goto_4056_8 != 0) {
            goto '__ci_bb_172
        } else {
            goto '__ci_bb_173
        }
    }

    '__ci_bb_170 {
        if ((if string_find_char("/!\"'`%&-=_:;,@~", (unsafe: *__local_p__goto_4052_18)) != null: 1 else: 0) != 0) {
            goto '__ci_bb_174
        } else {
            goto '__ci_bb_175
        }
    }

    '__ci_bb_171 {
        goto '__ci_bb_161
    }

    '__ci_bb_172 {
        goto '__ci_bb_143
    }

    '__ci_bb_173 {
        (__local_rc__goto_4054_7 = process_command())
        goto '__ci_bb_171
    }

    '__ci_bb_174 {
        (__local_rc__goto_4054_7 = process_pattern())
        (dfa_matched = 0)
        goto '__ci_bb_176
    }

    '__ci_bb_175 {
        if ((if (unsafe: *__local_p_notsp__goto_4053_18) != 0: 1 else: 0) != 0) {
            goto '__ci_bb_177
        } else {
            goto '__ci_bb_178
        }
    }

    '__ci_bb_176 {
        goto '__ci_bb_171
    }

    '__ci_bb_177 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Invalid pattern delimiter '%c' (x%x).\n", (unsafe: *buffer), (unsafe: *buffer))
        colour_end(outfile)
        (__local_rc__goto_4054_7 = PR_SKIP)
        goto '__ci_bb_178
    }

    '__ci_bb_178 {
        goto '__ci_bb_176
    }

    '__ci_bb_179 {
        (__local_skipping__goto_3649_6 = 1)
        goto '__ci_bb_181
    }

    '__ci_bb_180 {
        if ((if __local_rc__goto_4054_7 == PR_ENDIF: 1 else: 0) != 0) {
            goto '__ci_bb_182
        } else {
            goto '__ci_bb_183
        }
    }

    '__ci_bb_181 {
        goto '__ci_bb_143
    }

    '__ci_bb_182 {
        (__local_skipping_endif__goto_3650_6 = 1)
        goto '__ci_bb_184
    }

    '__ci_bb_183 {
        if ((if __local_rc__goto_4054_7 == PR_ABEND: 1 else: 0) != 0) {
            goto '__ci_bb_185
        } else {
            goto '__ci_bb_186
        }
    }

    '__ci_bb_184 {
        goto '__ci_bb_181
    }

    '__ci_bb_185 {
        colour_begin(31, outfile)
        fprintf(outfile, "** pcre2test run abandoned\n")
        colour_end(outfile)
        (__local_yield___goto_3644_10 = 1)
        goto '__ci_bb_6
    }

    '__ci_bb_186 {
        goto '__ci_bb_184
    }

    '__ci_bb_187 {
        colour_begin(31, outfile)
        fprintf(outfile, "** Expected #endif\n")
        colour_end(outfile)
        (__local_yield___goto_3644_10 = 1)
        goto '__ci_bb_6
    }

    '__ci_bb_188 {
        if (isatty(fileno(infile)) != 0) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_189 {
        fprintf(outfile, "\n")
        goto '__ci_bb_190
    }

    '__ci_bb_190 {
        if (__local_showtotaltimes__goto_3648_6 != 0) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_191 {
        (__local_pad__goto_4173_15 = (("" as *const c_char)))
        colour_begin(36, outfile)
        fprintf(outfile, "--------------------------------------\n")
        colour_end(outfile)
        if ((if timeit > 0: 1 else: 0) != 0) {
            goto '__ci_bb_193
        } else {
            goto '__ci_bb_194
        }
    }

    '__ci_bb_192 {
        goto '__ci_bb_6
    }

    '__ci_bb_193 {
        colour_begin(36, outfile)
        fprintf(outfile, "Total compile time %8.2f microseconds\n", ((((1000000 as c_ulong) / ((1000000 as c_ulong) as c_ulong)) * (total_compile_time as f64)) / timeit))
        colour_end(outfile)
        if ((if total_jit_compile_time > 0: 1 else: 0) != 0) {
            goto '__ci_bb_195
        } else {
            goto '__ci_bb_196
        }
    }

    '__ci_bb_194 {
        colour_begin(36, outfile)
        fprintf(outfile, "Total match time %s%8.2f microseconds\n", __local_pad__goto_4173_15, ((((1000000 as c_ulong) / ((1000000 as c_ulong) as c_ulong)) * (total_match_time as f64)) / timeitm))
        colour_end(outfile)
        goto '__ci_bb_192
    }

    '__ci_bb_195 {
        colour_begin(36, outfile)
        fprintf(outfile, "Total JIT compile  %8.2f microseconds\n", ((((1000000 as c_ulong) / ((1000000 as c_ulong) as c_ulong)) * (total_jit_compile_time as f64)) / timeit))
        colour_end(outfile)
        goto '__ci_bb_196
    }

    '__ci_bb_196 {
        (__local_pad__goto_4173_15 = (("  " as *const c_char)))
        goto '__ci_bb_194
    }

    '__ci_bb_197 {
        fclose(infile)
        goto '__ci_bb_198
    }

    '__ci_bb_198 {
        (__ci_expr_logic_41 = 0)
        if ((if outfile != null: 1 else: 0) != 0) {
            (__ci_expr_logic_41 = (if (if outfile != libc_stdout(): 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_41 != 0) {
            goto '__ci_bb_199
        } else {
            goto '__ci_bb_200
        }
    }

    '__ci_bb_199 {
        fclose(outfile)
        goto '__ci_bb_200
    }

    '__ci_bb_200 {
        if ((if (&raw const preg as *const regex_t).re_pcre2_code != null: 1 else: 0) != 0) {
            goto '__ci_bb_201
        } else {
            goto '__ci_bb_202
        }
    }

    '__ci_bb_201 {
        pcre2_regfree((&raw mut preg as *mut regex_t))
        goto '__ci_bb_202
    }

    '__ci_bb_202 {
        with_free((buffer as *mut i8))
        with_free((dbuffer as *mut i8))
        with_free((pbuffer8 as *mut i8))
        with_free((dfa_workspace as *mut i8))
        with_free((tables3 as *mut i8))
        free_globals()
        return __local_yield___goto_3644_10
    }

}

var OP_names: [173]*const i8 = ["End", "\\A", "\\G", "\\K", "\\B", "\\b", "\\D", "\\d", "\\S", "\\s", "\\W", "\\w", "Any", "AllAny", "Anybyte", "notprop", "prop", "\\R", "\\H", "\\h", "\\V", "\\v", "extuni", "\\Z", "\\z", "$", "$", "^", "^", "char", "chari", "not", "noti", "*", "*?", "+", "+?", "?", "??", "{", "{", "{", "*+", "++", "?+", "{", "*", "*?", "+", "+?", "?", "??", "{", "{", "{", "*+", "++", "?+", "{", "*", "*?", "+", "+?", "?", "??", "{", "{", "{", "*+", "++", "?+", "{", "*", "*?", "+", "+?", "?", "??", "{", "{", "{", "*+", "++", "?+", "{", "*", "*?", "+", "+?", "?", "??", "{", "{", "{", "*+", "++", "?+", "{", "*", "*?", "+", "+?", "?", "??", "{", "{", "*+", "++", "?+", "{", "class", "nclass", "xclass", "eclass", "Ref", "Refi", "DnRef", "DnRefi", "Recurse", "Callout", "CalloutStr", "Alt", "Ket", "KetRmax", "KetRmin", "KetRpos", "Reverse", "VReverse", "Assert", "Assert not", "Assert back", "Assert back not", "Non-atomic assert", "Non-atomic assert back", "Scan substring", "Once", "Script run", "Bra", "BraPos", "CBra", "CBraPos", "Cond", "SBra", "SBraPos", "SCBra", "SCBraPos", "SCond", "Capture ref", "Capture dnref", "Cond rec", "Cond dnrec", "Cond false", "Cond true", "Brazero", "Braminzero", "Braposzero", "*MARK", "*PRUNE", "*PRUNE", "*SKIP", "*SKIP", "*THEN", "*THEN", "*COMMIT", "*COMMIT", "*FAIL", "*ACCEPT", "*ASSERT_ACCEPT", "Close", "Skip zero", "Define", "\\B (ucp)", "\\b (ucp)"]
let OP_lengths_8: [173]u8 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 1, 1, 1, 1, 1, 1, 5, 5, 1, 1, 1, 5, 33, 33, 0, 0, 3, 4, 5, 6, 3, 6, 0, 3, 3, 3, 3, 3, 3, 5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 5, 5, 3, 3, 3, 5, 5, 3, 3, 5, 3, 5, 1, 1, 1, 1, 1, 3, 1, 3, 1, 3, 1, 3, 1, 3, 1, 1, 1, 3, 1, 1, 1, 1]
var cmdlist: [12]cmdstruct = [cmdstruct { name: (("endif" as *mut c_char) as *const c_char), value: CMD_ENDIF }, cmdstruct { name: (("forbid_utf" as *mut c_char) as *const c_char), value: CMD_FORBID_UTF }, cmdstruct { name: (("if" as *mut c_char) as *const c_char), value: CMD_IF }, cmdstruct { name: (("load" as *mut c_char) as *const c_char), value: CMD_LOAD }, cmdstruct { name: (("loadtables" as *mut c_char) as *const c_char), value: CMD_LOADTABLES }, cmdstruct { name: (("newline_default" as *mut c_char) as *const c_char), value: CMD_NEWLINE_DEFAULT }, cmdstruct { name: (("pattern" as *mut c_char) as *const c_char), value: CMD_PATTERN }, cmdstruct { name: (("perltest" as *mut c_char) as *const c_char), value: CMD_PERLTEST }, cmdstruct { name: (("pop" as *mut c_char) as *const c_char), value: CMD_POP }, cmdstruct { name: (("popcopy" as *mut c_char) as *const c_char), value: CMD_POPCOPY }, cmdstruct { name: (("save" as *mut c_char) as *const c_char), value: CMD_SAVE }, cmdstruct { name: (("subject" as *mut c_char) as *const c_char), value: CMD_SUBJECT }]
var newlines: [7]*const i8 = [(("DEFAULT" as *mut c_char) as *const c_char), (("CR" as *mut c_char) as *const c_char), (("LF" as *mut c_char) as *const c_char), (("CRLF" as *mut c_char) as *const c_char), (("ANY" as *mut c_char) as *const c_char), (("ANYCRLF" as *mut c_char) as *const c_char), (("NUL" as *mut c_char) as *const c_char)]
var convertlist: [6]convertstruct = [convertstruct { name: "glob", option: 0x00000010 }, convertstruct { name: "glob_no_starstar", option: 0x00000050 }, convertstruct { name: "glob_no_wild_separator", option: 0x00000030 }, convertstruct { name: "posix_basic", option: 0x00000004 }, convertstruct { name: "posix_extended", option: 0x00000008 }, convertstruct { name: "unset", option: 4294967295 }]
var modlist: [156]modstruct = [modstruct { name: (("aftertext" as *mut c_char) as *const c_char), which: 9, type_: 12, value: 1, offset: 4 }, modstruct { name: (("allaftertext" as *mut c_char) as *const c_char), which: 9, type_: 12, value: 2, offset: 4 }, modstruct { name: (("allcaptures" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 4, offset: 4 }, modstruct { name: (("allow_empty_class" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 1, offset: 0 }, modstruct { name: (("allow_lookaround_bsk" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 64, offset: 72 }, modstruct { name: (("allow_surrogate_escapes" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 1, offset: 72 }, modstruct { name: (("allusedtext" as *mut c_char) as *const c_char), which: 9, type_: 12, value: 8, offset: 4 }, modstruct { name: (("allvector" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 2048, offset: 8 }, modstruct { name: (("alt_bsux" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 2, offset: 0 }, modstruct { name: (("alt_circumflex" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 2097152, offset: 0 }, modstruct { name: (("alt_extended_class" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 134217728, offset: 0 }, modstruct { name: (("alt_verbnames" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 4194304, offset: 0 }, modstruct { name: (("altglobal" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 16, offset: 4 }, modstruct { name: (("anchored" as *mut c_char) as *const c_char), which: 6, type_: 20, value: 2147483648, offset: 0 }, modstruct { name: (("ascii_all" as *mut c_char) as *const c_char), which: 0, type_: 20, value: (((((((256 as c_uint) | (512 as c_uint)) as c_uint) | (1024 as c_uint)) as c_uint) | (2048 as c_uint))), offset: 72 }, modstruct { name: (("ascii_bsd" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 256, offset: 72 }, modstruct { name: (("ascii_bss" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 512, offset: 72 }, modstruct { name: (("ascii_bsw" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 1024, offset: 72 }, modstruct { name: (("ascii_digit" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 4096, offset: 72 }, modstruct { name: (("ascii_posix" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 2048, offset: 72 }, modstruct { name: (("auto_callout" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 4, offset: 0 }, modstruct { name: (("auto_possess" as *mut c_char) as *const c_char), which: 0, type_: 21, value: 64, offset: 0 }, modstruct { name: (("auto_possess_off" as *mut c_char) as *const c_char), which: 0, type_: 21, value: 65, offset: 0 }, modstruct { name: (("bad_escape_is_literal" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 2, offset: 72 }, modstruct { name: (("bincode" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 32, offset: 4 }, modstruct { name: (("bsr" as *mut c_char) as *const c_char), which: 0, type_: 13, value: 0, offset: 64 }, modstruct { name: (("callout_capture" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 64, offset: 4 }, modstruct { name: (("callout_data" as *mut c_char) as *const c_char), which: 4, type_: 15, value: 0, offset: 256 }, modstruct { name: (("callout_error" as *mut c_char) as *const c_char), which: 4, type_: 14, value: 0, offset: 240 }, modstruct { name: (("callout_extra" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 1024, offset: 8 }, modstruct { name: (("callout_fail" as *mut c_char) as *const c_char), which: 4, type_: 14, value: 0, offset: 248 }, modstruct { name: (("callout_info" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 128, offset: 4 }, modstruct { name: (("callout_no_where" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 512, offset: 8 }, modstruct { name: (("callout_none" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 256, offset: 4 }, modstruct { name: (("caseless" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 8, offset: 0 }, modstruct { name: (("caseless_restrict" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 128, offset: 72 }, modstruct { name: (("convert" as *mut c_char) as *const c_char), which: 2, type_: 11, value: 0, offset: 140 }, modstruct { name: (("convert_glob_escape" as *mut c_char) as *const c_char), which: 2, type_: 10, value: 0, offset: 148 }, modstruct { name: (("convert_glob_separator" as *mut c_char) as *const c_char), which: 2, type_: 10, value: 0, offset: 152 }, modstruct { name: (("convert_length" as *mut c_char) as *const c_char), which: 2, type_: 16, value: 0, offset: 144 }, modstruct { name: (("copy" as *mut c_char) as *const c_char), which: 4, type_: 19, value: 260, offset: 352 }, modstruct { name: (("copy_matched_subject" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 16384, offset: 0 }, modstruct { name: (("debug" as *mut c_char) as *const c_char), which: 2, type_: 12, value: (((8192 as c_uint) | (131072 as c_uint))), offset: 4 }, modstruct { name: (("depth_limit" as *mut c_char) as *const c_char), which: 1, type_: 16, value: 0, offset: 88 }, modstruct { name: (("dfa" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 512, offset: 4 }, modstruct { name: (("dfa_restart" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 64, offset: 0 }, modstruct { name: (("dfa_shortest" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 128, offset: 0 }, modstruct { name: (("disable_recurseloop_check" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 262144, offset: 0 }, modstruct { name: (("dollar_endonly" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 16, offset: 0 }, modstruct { name: (("dotall" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 32, offset: 0 }, modstruct { name: (("dotstar_anchor" as *mut c_char) as *const c_char), which: 0, type_: 21, value: 66, offset: 0 }, modstruct { name: (("dotstar_anchor_off" as *mut c_char) as *const c_char), which: 0, type_: 21, value: 67, offset: 0 }, modstruct { name: (("dupnames" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 64, offset: 0 }, modstruct { name: (("endanchored" as *mut c_char) as *const c_char), which: 6, type_: 20, value: 536870912, offset: 0 }, modstruct { name: (("escaped_cr_is_lf" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 16, offset: 72 }, modstruct { name: (("expand" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 1024, offset: 4 }, modstruct { name: (("extended" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 128, offset: 0 }, modstruct { name: (("extended_more" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 16777216, offset: 0 }, modstruct { name: (("extra_alt_bsux" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 32, offset: 72 }, modstruct { name: (("find_limits" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 2048, offset: 4 }, modstruct { name: (("find_limits_noheap" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 4096, offset: 4 }, modstruct { name: (("firstline" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 256, offset: 0 }, modstruct { name: (("framesize" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 32768, offset: 8 }, modstruct { name: (("fullbincode" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 8192, offset: 4 }, modstruct { name: (("get" as *mut c_char) as *const c_char), which: 4, type_: 19, value: 300, offset: 416 }, modstruct { name: (("getall" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 16384, offset: 4 }, modstruct { name: (("global" as *mut c_char) as *const c_char), which: 9, type_: 12, value: 32768, offset: 4 }, modstruct { name: (("heap_limit" as *mut c_char) as *const c_char), which: 1, type_: 16, value: 0, offset: 80 }, modstruct { name: (("heapframes_size" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 536870912, offset: 8 }, modstruct { name: (("hex" as *mut c_char) as *const c_char), which: 3, type_: 12, value: 65536, offset: 4 }, modstruct { name: (("info" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 131072, offset: 4 }, modstruct { name: (("jit" as *mut c_char) as *const c_char), which: 2, type_: 17, value: 7, offset: 128 }, modstruct { name: (("jitfast" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 262144, offset: 4 }, modstruct { name: (("jitstack" as *mut c_char) as *const c_char), which: 9, type_: 16, value: 0, offset: 12 }, modstruct { name: (("jitverify" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 524288, offset: 4 }, modstruct { name: (("literal" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 33554432, offset: 0 }, modstruct { name: (("locale" as *mut c_char) as *const c_char), which: 3, type_: 23, value: 32, offset: 160 }, modstruct { name: (("mark" as *mut c_char) as *const c_char), which: 9, type_: 12, value: 1048576, offset: 4 }, modstruct { name: (("match_invalid_utf" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 67108864, offset: 0 }, modstruct { name: (("match_limit" as *mut c_char) as *const c_char), which: 1, type_: 16, value: 0, offset: 84 }, modstruct { name: (("match_line" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 8, offset: 72 }, modstruct { name: (("match_unset_backref" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 512, offset: 0 }, modstruct { name: (("match_word" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 4, offset: 72 }, modstruct { name: (("max_pattern_compiled_length" as *mut c_char) as *const c_char), which: 0, type_: 22, value: 0, offset: 56 }, modstruct { name: (("max_pattern_length" as *mut c_char) as *const c_char), which: 0, type_: 22, value: 0, offset: 48 }, modstruct { name: (("max_varlookbehind" as *mut c_char) as *const c_char), which: 0, type_: 16, value: 0, offset: 76 }, modstruct { name: (("memory" as *mut c_char) as *const c_char), which: 6, type_: 12, value: 2097152, offset: 4 }, modstruct { name: (("multiline" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 1024, offset: 0 }, modstruct { name: (("never_backslash_c" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 1048576, offset: 0 }, modstruct { name: (("never_callout" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 32768, offset: 72 }, modstruct { name: (("never_ucp" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 2048, offset: 0 }, modstruct { name: (("never_utf" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 4096, offset: 0 }, modstruct { name: (("newline" as *mut c_char) as *const c_char), which: 0, type_: 18, value: 0, offset: 0 }, modstruct { name: (("no_auto_capture" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 8192, offset: 0 }, modstruct { name: (("no_auto_possess" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 16384, offset: 0 }, modstruct { name: (("no_bs0" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 16384, offset: 72 }, modstruct { name: (("no_dotstar_anchor" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 32768, offset: 0 }, modstruct { name: (("no_jit" as *mut c_char) as *const c_char), which: 5, type_: 20, value: 8192, offset: 0 }, modstruct { name: (("no_start_optimize" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 65536, offset: 0 }, modstruct { name: (("no_utf_check" as *mut c_char) as *const c_char), which: 6, type_: 20, value: 1073741824, offset: 0 }, modstruct { name: (("notbol" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 1, offset: 0 }, modstruct { name: (("notempty" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 4, offset: 0 }, modstruct { name: (("notempty_atstart" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 8, offset: 0 }, modstruct { name: (("noteol" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 2, offset: 0 }, modstruct { name: (("null_context" as *mut c_char) as *const c_char), which: 6, type_: 12, value: 4194304, offset: 4 }, modstruct { name: (("null_pattern" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 4096, offset: 8 }, modstruct { name: (("null_replacement" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 16384, offset: 8 }, modstruct { name: (("null_subject" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 8192, offset: 8 }, modstruct { name: (("null_substitute_match_data" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 131072, offset: 8 }, modstruct { name: (("offset" as *mut c_char) as *const c_char), which: 4, type_: 22, value: 0, offset: 344 }, modstruct { name: (("offset_limit" as *mut c_char) as *const c_char), which: 1, type_: 22, value: 0, offset: 72 }, modstruct { name: (("optimization_full" as *mut c_char) as *const c_char), which: 0, type_: 21, value: 1, offset: 0 }, modstruct { name: (("optimization_none" as *mut c_char) as *const c_char), which: 0, type_: 21, value: 0, offset: 0 }, modstruct { name: (("ovector" as *mut c_char) as *const c_char), which: 4, type_: 16, value: 0, offset: 340 }, modstruct { name: (("parens_nest_limit" as *mut c_char) as *const c_char), which: 0, type_: 16, value: 0, offset: 68 }, modstruct { name: (("partial_hard" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 32, offset: 0 }, modstruct { name: (("partial_soft" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 16, offset: 0 }, modstruct { name: (("ph" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 32, offset: 0 }, modstruct { name: (("posix" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 8388608, offset: 4 }, modstruct { name: (("posix_nosub" as *mut c_char) as *const c_char), which: 2, type_: 12, value: ((8388608 as c_uint) | (16777216 as c_uint)), offset: 4 }, modstruct { name: (("posix_startend" as *mut c_char) as *const c_char), which: 4, type_: 14, value: 0, offset: 232 }, modstruct { name: (("ps" as *mut c_char) as *const c_char), which: 4, type_: 20, value: 16, offset: 0 }, modstruct { name: (("push" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 33554432, offset: 4 }, modstruct { name: (("pushcopy" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 67108864, offset: 4 }, modstruct { name: (("pushtablescopy" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 134217728, offset: 4 }, modstruct { name: (("python_octal" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 8192, offset: 72 }, modstruct { name: (("recursion_limit" as *mut c_char) as *const c_char), which: 1, type_: 16, value: 0, offset: 88 }, modstruct { name: (("regerror_buffsize" as *mut c_char) as *const c_char), which: 2, type_: 15, value: 0, offset: 156 }, modstruct { name: (("replace" as *mut c_char) as *const c_char), which: 8, type_: 23, value: 100, offset: 16 }, modstruct { name: (("stackguard" as *mut c_char) as *const c_char), which: 2, type_: 16, value: 0, offset: 132 }, modstruct { name: (("start_optimize" as *mut c_char) as *const c_char), which: 0, type_: 21, value: 68, offset: 0 }, modstruct { name: (("start_optimize_off" as *mut c_char) as *const c_char), which: 0, type_: 21, value: 69, offset: 0 }, modstruct { name: (("startchar" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 268435456, offset: 4 }, modstruct { name: (("startoffset" as *mut c_char) as *const c_char), which: 4, type_: 22, value: 0, offset: 344 }, modstruct { name: (("subject_literal" as *mut c_char) as *const c_char), which: 3, type_: 12, value: 256, offset: 8 }, modstruct { name: (("substitute_callout" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 1, offset: 8 }, modstruct { name: (("substitute_case_callout" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 65536, offset: 8 }, modstruct { name: (("substitute_extended" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 2, offset: 8 }, modstruct { name: (("substitute_literal" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 4, offset: 8 }, modstruct { name: (("substitute_matched" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 8, offset: 8 }, modstruct { name: (("substitute_overflow_length" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 16, offset: 8 }, modstruct { name: (("substitute_replacement_only" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 32, offset: 8 }, modstruct { name: (("substitute_skip" as *mut c_char) as *const c_char), which: 8, type_: 16, value: 0, offset: 120 }, modstruct { name: (("substitute_stop" as *mut c_char) as *const c_char), which: 8, type_: 16, value: 0, offset: 124 }, modstruct { name: (("substitute_subject" as *mut c_char) as *const c_char), which: 4, type_: 23, value: 100, offset: 128 }, modstruct { name: (("substitute_unknown_unset" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 64, offset: 8 }, modstruct { name: (("substitute_unset_empty" as *mut c_char) as *const c_char), which: 8, type_: 12, value: 128, offset: 8 }, modstruct { name: (("tables" as *mut c_char) as *const c_char), which: 2, type_: 16, value: 0, offset: 136 }, modstruct { name: (("turkish_casing" as *mut c_char) as *const c_char), which: 0, type_: 20, value: 65536, offset: 72 }, modstruct { name: (("ucp" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 131072, offset: 0 }, modstruct { name: (("ungreedy" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 262144, offset: 0 }, modstruct { name: (("use_length" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 536870912, offset: 4 }, modstruct { name: (("use_offset_limit" as *mut c_char) as *const c_char), which: 2, type_: 20, value: 8388608, offset: 0 }, modstruct { name: (("utf" as *mut c_char) as *const c_char), which: 3, type_: 20, value: 524288, offset: 0 }, modstruct { name: (("utf8_input" as *mut c_char) as *const c_char), which: 2, type_: 12, value: 1073741824, offset: 4 }, modstruct { name: (("zero_terminate" as *mut c_char) as *const c_char), which: 4, type_: 12, value: 2147483648, offset: 4 }]
var exclusive_pat_controls: [7]c_uint = [(0x00800000 | 0x02000000), (0x00800000 | 0x04000000), (0x00800000 | 0x08000000), (0x02000000 | 0x04000000), (0x02000000 | 0x08000000), (0x04000000 | 0x08000000), (0x00000400 | 0x00010000)]
var exclusive_dat_controls: [3]c_uint = [(0x00000008 | 0x10000000), (0x00000800 | 0x00400000), (0x00001000 | 0x00400000)]
var c1modlist: [10]c1modstruct = [c1modstruct { fullname: (("bincode" as *mut c_char) as *const c_char), onechar: 66, index: -1 }, c1modstruct { fullname: (("info" as *mut c_char) as *const c_char), onechar: 73, index: -1 }, c1modstruct { fullname: (("ascii_all" as *mut c_char) as *const c_char), onechar: 97, index: -1 }, c1modstruct { fullname: (("global" as *mut c_char) as *const c_char), onechar: 103, index: -1 }, c1modstruct { fullname: (("caseless" as *mut c_char) as *const c_char), onechar: 105, index: -1 }, c1modstruct { fullname: (("multiline" as *mut c_char) as *const c_char), onechar: 109, index: -1 }, c1modstruct { fullname: (("no_auto_capture" as *mut c_char) as *const c_char), onechar: 110, index: -1 }, c1modstruct { fullname: (("caseless_restrict" as *mut c_char) as *const c_char), onechar: 114, index: -1 }, c1modstruct { fullname: (("dotall" as *mut c_char) as *const c_char), onechar: 115, index: -1 }, c1modstruct { fullname: (("extended" as *mut c_char) as *const c_char), onechar: 120, index: -1 }]
var coptlist: [13]coptstruct = [coptstruct { name: "backslash-C", type_: CONF_FIX, value: 1 }, coptstruct { name: "bsr", type_: CONF_BSR, value: 0 }, coptstruct { name: "ebcdic", type_: CONF_FIX, value: 0 }, coptstruct { name: "ebcdic-io", type_: CONF_FIX, value: 0 }, coptstruct { name: "ebcdic-nl25", type_: CONF_FIX, value: 0 }, coptstruct { name: "jit", type_: CONF_INT, value: 1 }, coptstruct { name: "jitusable", type_: CONF_JU, value: 0 }, coptstruct { name: "linksize", type_: CONF_INT, value: 16 }, coptstruct { name: "newline", type_: CONF_NL, value: 5 }, coptstruct { name: "pcre2-16", type_: CONF_FIX, value: 0 }, coptstruct { name: "pcre2-32", type_: CONF_FIX, value: 0 }, coptstruct { name: "pcre2-8", type_: CONF_FIX, value: 1 }, coptstruct { name: "unicode", type_: CONF_INT, value: 9 }]
var infile: *mut c_void = null
var outfile: *mut c_void = null
var last_callout_mark: *const c_void = null
var first_callout: c_int = 0
var jit_was_used: c_int = 0
var restrict_for_perl_test: c_int = 0
var show_memory: c_int = 0
var preprocess_only: c_int = 0
var inside_if: c_int = 0
var malloc_testing: c_int = 0
var jitrc: c_int = 0
var timeit: c_int = 0
var timeitm: c_int = 0
var mallocs_until_failure: c_int = 2147483647
var mallocs_called: c_int = 0
var total_compile_time: c_ulong = 0
var total_jit_compile_time: c_ulong = 0
var total_match_time: c_ulong = 0
var dfa_matched: c_uint = 0
var forbid_utf: c_uint = 0
var maxlookbehind: c_uint = 0
var max_oveccount: c_uint = 0
var callout_count: c_uint = 0
var maxcapcount: c_uint = 0
var local_newline_default: c_ushort = 0
var def_patctl: patctl
var pat_patctl: patctl
var def_datctl: datctl
var dat_datctl: datctl
var malloclist: [20]*mut c_void = [null as *mut c_void; 20]
var malloclistlength: [20]c_ulong = [0 as c_ulong; 20]
var malloclistptr: c_uint = 0
var preg: regex_t = regex_t { re_pcre2_code: null, re_match_data: null, re_endp: null, re_nsub: 0, re_erroffset: 0, re_cflags: 0 }
var dfa_workspace: *mut c_int = (null as *mut c_int)
var locale_tables: *const u8 = (null as *const u8)
var use_tables: *const u8 = (null as *const u8)
var locale_name: [32]u8 = [0 as u8; 32]
var tables3: *mut u8 = (null as *mut u8)
var loadtables_length: c_uint = 0
var pbuffer8_size: c_ulong = 50000
var pbuffer8: *mut u8 = (null as *mut u8)
var buffer: *mut u8 = (null as *mut u8)
var dbuffer_size: c_ulong = 16384
var dbuffer: *mut u8 = (null as *mut u8)
let clr_comment: c_int = 37
let clr_input: c_int = 32
let clr_prompt: c_int = 34
let clr_api_error: c_int = 35
let clr_test_error: c_int = 31
let clr_profiling: c_int = 36
let clr_none: c_int = -1
var colour_setting: c_int = 2
var colour_last_fd: c_int = -1
var colour_fd_interactive: c_int = 0
let tables1: [1088]u8 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 91, 92, 93, 94, 95, 96, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 0x00, 0x3e, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x03, 0x7e, 0x00, 0x00, 0x00, 0x7e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0xff, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0xff, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x03, 0xfe, 0xff, 0xff, 0x87, 0xfe, 0xff, 0xff, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0x00, 0xfc, 0x01, 0x00, 0x00, 0xf8, 0x01, 0x00, 0x00, 0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x80, 0x00, 0x1c, 0x1c, 0x1c, 0x1c, 0x1c, 0x1c, 0x1c, 0x1c, 0x1c, 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x1a, 0x1a, 0x1a, 0x1a, 0x1a, 0x1a, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x80, 0x80, 0x00, 0x80, 0x10, 0x00, 0x1a, 0x1a, 0x1a, 0x1a, 0x1a, 0x1a, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
let tables2: [1088]u8 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 215, 248, 249, 250, 251, 252, 253, 254, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 91, 92, 93, 94, 95, 96, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 215, 248, 249, 250, 251, 252, 253, 254, 223, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 247, 216, 217, 218, 219, 220, 221, 222, 255, 0, 62, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 3, 126, 0, 0, 0, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 127, 127, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 7, 0, 0, 0, 0, 0, 4, 32, 4, 0, 0, 0, 128, 255, 255, 127, 255, 0, 0, 0, 0, 0, 0, 255, 3, 254, 255, 255, 135, 254, 255, 255, 7, 0, 0, 0, 0, 0, 4, 44, 6, 255, 255, 127, 255, 255, 255, 127, 255, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 127, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 2, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 127, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 254, 255, 0, 252, 1, 0, 0, 248, 1, 0, 0, 120, 0, 0, 0, 0, 254, 255, 255, 255, 0, 0, 128, 0, 0, 0, 128, 0, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 128, 0, 0, 0, 128, 128, 128, 128, 0, 0, 128, 0, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 0, 0, 0, 0, 0, 128, 0, 26, 26, 26, 26, 26, 26, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 128, 128, 0, 128, 16, 0, 26, 26, 26, 26, 26, 26, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 128, 128, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18, 0, 0, 0, 0, 0, 0, 0, 20, 20, 0, 18, 0, 0, 0, 20, 18, 0, 0, 0, 0, 0, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 0, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 0, 18, 18, 18, 18, 18, 18, 18, 18]
var compiled_code_8: *mut pcre2_real_code_8 = (null as *mut pcre2_real_code_8)
var general_context_8: *mut pcre2_real_general_context_8 = (null as *mut pcre2_real_general_context_8)
var general_context_copy_8: *mut pcre2_real_general_context_8 = (null as *mut pcre2_real_general_context_8)
var pat_context_8: *mut pcre2_real_compile_context_8 = (null as *mut pcre2_real_compile_context_8)
var default_pat_context_8: *mut pcre2_real_compile_context_8 = (null as *mut pcre2_real_compile_context_8)
var con_context_8: *mut pcre2_real_convert_context_8 = (null as *mut pcre2_real_convert_context_8)
var default_con_context_8: *mut pcre2_real_convert_context_8 = (null as *mut pcre2_real_convert_context_8)
var dat_context_8: *mut pcre2_real_match_context_8 = (null as *mut pcre2_real_match_context_8)
var default_dat_context_8: *mut pcre2_real_match_context_8 = (null as *mut pcre2_real_match_context_8)
var match_data_8: *mut pcre2_real_match_data_8 = (null as *mut pcre2_real_match_data_8)
var jit_stack_8: *mut pcre2_real_jit_stack_8 = (null as *mut pcre2_real_jit_stack_8)
var jit_stack_size_8: c_ulong = 0
var patstack_8: [20]*mut pcre2_real_code_8 = [null as *mut pcre2_real_code_8; 20]
var patstacknext_8: c_int = 0
var rep_in_buffer_8: *mut u8 = (null as *mut u8)
var rep_in_buffer_size_8: c_ulong = 100
var rep_out_buffer_8: *mut u8 = (null as *mut u8)
var rep_out_buffer_size_8: c_ulong = 256
var test_mode: c_int = 8
