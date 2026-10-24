// Migrated from C
use std.engines.pcre2.defs
use std.engines.pcre2.pcre2_config
use std.engines.pcre2.pcre2_context
use std.engines.pcre2.pcre2_convert
use std.engines.pcre2.pcre2_compile
use std.engines.pcre2.pcre2_match_data
use std.engines.pcre2.pcre2_dfa_match
use std.engines.pcre2.pcre2_match
use std.engines.pcre2.pcre2_match_next
use std.engines.pcre2.pcre2_substring
use std.engines.pcre2.pcre2_serialize
use std.engines.pcre2.pcre2_substitute
use std.engines.pcre2.pcre2_jit_compile
use std.engines.pcre2.pcre2_error
use std.engines.pcre2.pcre2_maketables
use std.engines.pcre2.pcre2_tables
use std.engines.pcre2.pcre2_chartables
use std.engines.pcre2.pcre2_ucd
use std.engines.pcre2.pcre2_auto_possess
use std.engines.pcre2.pcre2_chkdint
use std.engines.pcre2.pcre2_extuni
use std.engines.pcre2.pcre2_find_bracket
use std.engines.pcre2.pcre2_newline
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass
use std.libc

pub unsafe fn pcre2_pattern_info_8(__param_code: *const pcre2_real_code_8, __param_what: u32, __param_where_: *mut c_void) -> i32 {
    var __local_re: *const pcre2_real_code_8 = __param_code

    if ((if __param_where_ == null: 1 else: 0) != 0) {
        match __param_what {
            0 => {
                return ((4 as i32))
            },
            1 => {
                return ((4 as i32))
            },
            2 => {
                return ((4 as i32))
            },
            3 => {
                return ((4 as i32))
            },
            4 => {
                return ((4 as i32))
            },
            21 => {
                return ((4 as i32))
            },
            26 => {
                return ((4 as i32))
            },
            6 => {
                return ((4 as i32))
            },
            5 => {
                return ((4 as i32))
            },
            23 => {
                return ((4 as i32))
            },
            8 => {
                return ((4 as i32))
            },
            25 => {
                return ((4 as i32))
            },
            9 => {
                return ((4 as i32))
            },
            12 => {
                return ((4 as i32))
            },
            11 => {
                return ((4 as i32))
            },
            13 => {
                return ((4 as i32))
            },
            14 => {
                return ((4 as i32))
            },
            15 => {
                return ((4 as i32))
            },
            16 => {
                return ((4 as i32))
            },
            18 => {
                return ((4 as i32))
            },
            17 => {
                return ((4 as i32))
            },
            20 => {
                return ((4 as i32))
            },
            7 => {
                return ((8 as i32))
            },
            10 => {
                return ((8 as i32))
            },
            22 => {
                return ((8 as i32))
            },
            24 => {
                return ((8 as i32))
            },
            19 => {
                return ((8 as i32))
            },
        }

    }

    if ((if __local_re == null: 1 else: 0) != 0) {
        return -51
    }

    if ((if (*__local_re).magic_number != 1346589253: 1 else: 0) != 0) {
        return -31
    }

    if ((if (((*__local_re).flags as u32) & (1 as u32)) == 0: 1 else: 0) != 0) {
        return -32
    }

    while true {
        match __param_what {
            0 => {
                ((*(__param_where_ as *mut u32)) = (*__local_re).overall_options)
            },
            1 => {
                ((*(__param_where_ as *mut u32)) = (*__local_re).compile_options)
            },
            2 => {
                ((*(__param_where_ as *mut u32)) = (((*__local_re).top_backref as u32)))
            },
            3 => {
                ((*(__param_where_ as *mut u32)) = (((*__local_re).bsr_convention as u32)))
            },
            4 => {
                ((*(__param_where_ as *mut u32)) = (((*__local_re).top_bracket as u32)))
            },
            21 => {
                ((*(__param_where_ as *mut u32)) = (*__local_re).limit_depth)

                if ((if (*__local_re).limit_depth == libc.UINT32_MAX: 1 else: 0) != 0) {
                    return -55
                }

            },
            26 => {
                ((*(__param_where_ as *mut u32)) = (*__local_re).extra_options)
            },
            6 => {
                ((*(__param_where_ as *mut u32)) = (((if (if (((*__local_re).flags as u32) & (16 as u32)) != 0: 1 else: 0) != 0: (1 as i32) else: ((if (if (((*__local_re).flags as u32) & (512 as u32)) != 0: 1 else: 0) != 0: (2 as i32) else: (0 as i32)) as i32)) as u32)))
            },
            5 => {
                ((*(__param_where_ as *mut u32)) = (((if (if (((*__local_re).flags as u32) & (16 as u32)) != 0: 1 else: 0) != 0: (*__local_re).first_codeunit else: (0 as u32)) as u32)))
            },
            7 => {
                ((*(__param_where_ as *mut *const u8)) = (if (if (((*__local_re).flags as u32) & (64 as u32)) != 0: 1 else: 0) != 0: (&raw const (*__local_re).start_bitmap[0] as *const u8) else: (null as *const u8)))
            },
            24 => {
                ((*(__param_where_ as *mut u64)) = (((((offsetof[heapframe](ovector) as usize) as u64) +% ((((((*__local_re).top_bracket as i32) * 2) as u64) *% (sizeof[u64]() as u64)) as u64)) as u64)))
            },
            23 => {
                ((*(__param_where_ as *mut u32)) = (((if (((*__local_re).flags as u32) & (4194304 as u32)) != 0: 1 else: 0) as u32)))
            },
            8 => {
                ((*(__param_where_ as *mut u32)) = (((if (((*__local_re).flags as u32) & (2048 as u32)) != 0: 1 else: 0) as u32)))
            },
            25 => {
                ((*(__param_where_ as *mut u32)) = (*__local_re).limit_heap)

                if ((if (*__local_re).limit_heap == libc.UINT32_MAX: 1 else: 0) != 0) {
                    return -55
                }

            },
            9 => {
                ((*(__param_where_ as *mut u32)) = (((if (((*__local_re).flags as u32) & (1024 as u32)) != 0: 1 else: 0) as u32)))
            },
            10 => {
                ((*(__param_where_ as *mut u64)) = ((0 as u64)))
            },
            12 => {
                ((*(__param_where_ as *mut u32)) = (((if (if (((*__local_re).flags as u32) & (128 as u32)) != 0: 1 else: 0) != 0: (1 as i32) else: (0 as i32)) as u32)))
            },
            11 => {
                ((*(__param_where_ as *mut u32)) = (((if (if (((*__local_re).flags as u32) & (128 as u32)) != 0: 1 else: 0) != 0: (*__local_re).last_codeunit else: (0 as u32)) as u32)))
            },
            13 => {
                ((*(__param_where_ as *mut u32)) = (((if (((*__local_re).flags as u32) & (8192 as u32)) != 0: 1 else: 0) as u32)))
            },
            14 => {
                ((*(__param_where_ as *mut u32)) = (*__local_re).limit_match)

                if ((if (*__local_re).limit_match == libc.UINT32_MAX: 1 else: 0) != 0) {
                    return -55
                }

            },
            15 => {
                ((*(__param_where_ as *mut u32)) = (((*__local_re).max_lookbehind as u32)))
            },
            16 => {
                ((*(__param_where_ as *mut u32)) = (((*__local_re).minlength as u32)))
            },
            18 => {
                ((*(__param_where_ as *mut u32)) = (((*__local_re).name_entry_size as u32)))
            },
            17 => {
                ((*(__param_where_ as *mut u32)) = (((*__local_re).name_count as u32)))
            },
            19 => {
                ((*(__param_where_ as *mut *const u8)) = ((((__local_re as *const c_char) + (sizeof[pcre2_real_code_8]() as usize)) as *const u8)))
            },
            20 => {
                ((*(__param_where_ as *mut u32)) = (((*__local_re).newline_convention as u32)))
            },
            22 => {
                ((*(__param_where_ as *mut u64)) = (*__local_re).blocksize)
            },
            _ => {
                return -34
            },
        }

        break

    }

    return 0

}

pub unsafe fn pcre2_callout_enumerate_8(__param_code: *const pcre2_real_code_8, __param_callback: unsafe extern "C" fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> i32, __param_callout_data: *mut c_void) -> i32 {
    var __local_re: *const pcre2_real_code_8 = __param_code

    var __local_cb: pcre2_callout_enumerate_block_8

    var __local_cc: *const u8

    var __local_utf: i32

    if ((if __local_re == null: 1 else: 0) != 0) {
        return -51
    }

    (__local_utf = (((if (((*__local_re).overall_options as u32) & (524288 as u32)) != 0: 1 else: 0) as i32)))

    if ((if (*__local_re).magic_number != 1346589253: 1 else: 0) != 0) {
        return -31
    }

    if ((if (((*__local_re).flags as u32) & (1 as u32)) == 0: 1 else: 0) != 0) {
        return -32
    }

    (__local_cb.version = ((0 as u32)))

    (__local_cc = ((((__local_re as *mut u8) + ((*__local_re).code_start as usize)) as *const u8)))

    while (1 != 0) {
        var __local_rc: i32

        while true {
            match (*__local_cc) {
                0 => {
                    return 0
                },
                29 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                30 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                31 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                32 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                33 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                34 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                35 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                36 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                37 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                38 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                39 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                40 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                41 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                42 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                43 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                44 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                45 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                46 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                47 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                48 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                49 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                50 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                51 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                52 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                53 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                54 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                55 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                56 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                57 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                58 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                59 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                60 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                61 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                62 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                63 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                64 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                65 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                66 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                67 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                68 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                69 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                70 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                71 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                72 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                73 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                74 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                75 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                76 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                77 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                78 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                79 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                80 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                81 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                82 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                83 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                84 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_0: i32 = 0

                    if (__local_utf != 0) {
                        (__ci_expr_logic_0 = (if (if (__local_cc[-1]) >= 192: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        (__local_cc = __local_cc + (((_pcre2_utf8_table4[((((__local_cc[-1]) as i32) as u32) & (63 as u32))] as u32) as usize) as i32))
                    }


                },
                85 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                86 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                87 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                88 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                89 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                90 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                91 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                92 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                93 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                94 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                95 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                96 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                97 => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                    var __ci_expr_logic_1: i32

                    if ((if (__local_cc[-1]) == OP_PROP: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_1 = (if (if (__local_cc[-1]) == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        (__local_cc = __local_cc + ((2 as isize) as usize))
                    }


                },
                112 => {
                    (__local_cc = __local_cc + (((((((__local_cc[1]) as i32) << (8 as u32)) as i32) | ((__local_cc[(1 + 1)]) as i32)) as u32) as usize))
                },
                113 => {
                    (__local_cc = __local_cc + (((((((__local_cc[1]) as i32) << (8 as u32)) as i32) | ((__local_cc[(1 + 1)]) as i32)) as u32) as usize))
                },
                156 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(*__local_cc)] as i32) + ((__local_cc[1]) as i32)) as isize) as usize))
                },
                164 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(*__local_cc)] as i32) + ((__local_cc[1]) as i32)) as isize) as usize))
                },
                158 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(*__local_cc)] as i32) + ((__local_cc[1]) as i32)) as isize) as usize))
                },
                160 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(*__local_cc)] as i32) + ((__local_cc[1]) as i32)) as isize) as usize))
                },
                162 => {
                    (__local_cc = __local_cc + ((((_pcre2_OP_lengths_8[(*__local_cc)] as i32) + ((__local_cc[1]) as i32)) as isize) as usize))
                },
                119 => {
                    (__local_cb.pattern_position = ((((((((__local_cc[1]) as i32) << (8 as u32)) as i32) | ((__local_cc[(1 + 1)]) as i32)) as u32) as u64)))

                    (__local_cb.next_item_length = ((((((((__local_cc[(1 + 2)]) as i32) << (8 as u32)) as i32) | ((__local_cc[((1 + 2) + 1)]) as i32)) as u32) as u64)))

                    (__local_cb.callout_number = (((__local_cc[(1 + (2 * 2))]) as u32)))

                    (__local_cb.callout_string_offset = ((0 as u64)))

                    (__local_cb.callout_string_length = ((0 as u64)))

                    (__local_cb.callout_string = ((null as *const u8)))

                    (__local_rc = ((__param_callback((&raw mut __local_cb as *mut pcre2_callout_enumerate_block_8), __param_callout_data) as i32)))

                    if ((if __local_rc != 0: 1 else: 0) != 0) {
                        return __local_rc
                    }

                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))

                },
                120 => {
                    (__local_cb.pattern_position = ((((((((__local_cc[1]) as i32) << (8 as u32)) as i32) | ((__local_cc[(1 + 1)]) as i32)) as u32) as u64)))

                    (__local_cb.next_item_length = ((((((((__local_cc[(1 + 2)]) as i32) << (8 as u32)) as i32) | ((__local_cc[((1 + 2) + 1)]) as i32)) as u32) as u64)))

                    (__local_cb.callout_number = ((0 as u32)))

                    (__local_cb.callout_string_offset = ((((((((__local_cc[(1 + (3 * 2))]) as i32) << (8 as u32)) as i32) | ((__local_cc[((1 + (3 * 2)) + 1)]) as i32)) as u32) as u64)))

                    (__local_cb.callout_string_length = (((((((((((__local_cc[(1 + (2 * 2))]) as i32) << (8 as u32)) as i32) | ((__local_cc[((1 + (2 * 2)) + 1)]) as i32)) as u32) -% (9 as u32)) as u32) -% (2 as u32)) as u64)))

                    (__local_cb.callout_string = (__local_cc + (((1 + (4 * 2)) as isize) as usize)) + ((1 as isize) as usize))

                    (__local_rc = ((__param_callback((&raw mut __local_cb as *mut pcre2_callout_enumerate_block_8), __param_callout_data) as i32)))

                    if ((if __local_rc != 0: 1 else: 0) != 0) {
                        return __local_rc
                    }

                    (__local_cc = __local_cc + (((((((__local_cc[(1 + (2 * 2))]) as i32) << (8 as u32)) as i32) | ((__local_cc[((1 + (2 * 2)) + 1)]) as i32)) as u32) as usize))

                },
                _ => {
                    (__local_cc = __local_cc + (((_pcre2_OP_lengths_8[(*__local_cc)] as u32) as usize) as i32))
                },
            }

            break

        }

    }

}
