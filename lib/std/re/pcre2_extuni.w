// Migrated from C
use std.re.defs
use std.re.pcre2_config
use std.re.pcre2_context
use std.re.pcre2_convert
use std.re.pcre2_compile
use std.re.pcre2_pattern_info
use std.re.pcre2_match_data
use std.re.pcre2_dfa_match
use std.re.pcre2_match
use std.re.pcre2_match_next
use std.re.pcre2_substring
use std.re.pcre2_serialize
use std.re.pcre2_substitute
use std.re.pcre2_jit_compile
use std.re.pcre2_error
use std.re.pcre2_maketables
use std.re.pcre2_tables
use std.re.pcre2_chartables
use std.re.pcre2_ucd
use std.re.pcre2_auto_possess
use std.re.pcre2_chkdint
use std.re.pcre2_find_bracket
use std.re.pcre2_newline
use std.re.pcre2_ord2utf
use std.re.pcre2_script_run
use std.re.pcre2_string_utils
use std.re.pcre2_study
use std.re.pcre2_valid_utf
use std.re.pcre2_xclass

pub unsafe fn _pcre2_extuni_8(__param_c: c_uint, __param_eptr: *const u8, __param_start_subject: *const u8, __param_end_subject: *const u8, __param_utf: c_int, __param_xcount: *mut c_int) -> *const u8 {
    var __local_c = __param_c
    var __local_eptr = __param_eptr
    var __local_was_ep_ZWJ: c_int = ((0 as c_int))

    var __local_lgb: c_int = ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as c_int) / 128)] as c_int) * 128) + ((__local_c as c_int) % 128))] as c_uint) as usize)).gbprop as c_int))

    while ((if __local_eptr < __param_end_subject: 1 else: 0) != 0) {
        var __local_rgb: c_int

        var __local_len: c_int = ((1 as c_int))

        if ((if not (__param_utf != 0): 1 else: 0) != 0) {
            (__local_c = (((unsafe *__local_eptr) as c_uint)))
        } else {
            (__local_c = (((unsafe *__local_eptr) as c_uint)))

            if ((if __local_c >= 192: 1 else: 0) != 0) {
                if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__local_c = ((((((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe __local_eptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))

                    (__local_len = __local_len + 1)

                } else {
                    if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_c = ((((((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe __local_eptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_eptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))

                        (__local_len = __local_len + 2)

                    } else {
                        if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_c = ((((((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe __local_eptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_eptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_eptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))

                            (__local_len = __local_len + 3)

                        } else {
                            if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_c = ((((((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe __local_eptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_eptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_eptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_eptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))

                                (__local_len = __local_len + 4)

                            } else {
                                (__local_c = ((((((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe __local_eptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_eptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_eptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_eptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_eptr[5]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))

                                (__local_len = __local_len + 5)

                            }
                        }
                    }
                }

            }

        }

        (__local_rgb = ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as c_int) / 128)] as c_int) * 128) + ((__local_c as c_int) % 128))] as c_uint) as usize)).gbprop as c_int)))

        if ((if ((_pcre2_ucp_gbtable_8[__local_lgb] as c_uint) & (((1 as c_uint) << (__local_rgb as c_uint)) as c_uint)) == 0: 1 else: 0) != 0) {
            break
        }

        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_logic_0: c_int = 0

        if ((if __local_lgb == ucp_gbZWJ: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_rgb == ucp_gbExtended_Pictographic: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if not (__local_was_ep_ZWJ != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            break
        }


        var __ci_expr_logic_2: c_int = 0

        if ((if __local_lgb == ucp_gbRegional_Indicator: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __local_rgb == ucp_gbRegional_Indicator: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            var __local_ricount: c_int = ((0 as c_int))

            var __local_bptr: *const u8 = (__local_eptr - ((1 as isize) as usize))

            if (__param_utf != 0) {
                while ((if ((((unsafe *__local_bptr) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0) {
                    (__local_bptr = __local_bptr - 1)
                }
            }

            while ((if __local_bptr > __param_start_subject: 1 else: 0) != 0) {
                (__local_bptr = __local_bptr - 1)

                if (__param_utf != 0) {
                    while ((if ((((unsafe *__local_bptr) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0) {
                        (__local_bptr = __local_bptr - 1)
                    }

                    (__local_c = (((unsafe *__local_bptr) as c_uint)))

                    if ((if __local_c >= 192: 1 else: 0) != 0) {
                        if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_c = ((((((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe __local_bptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))
                        } else {
                            if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                                (__local_c = ((((((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe __local_bptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_bptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))
                            } else {
                                if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                                    (__local_c = ((((((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe __local_bptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_bptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_bptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))
                                } else {
                                    if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                                        (__local_c = ((((((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe __local_bptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_bptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_bptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_bptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))
                                    } else {
                                        (__local_c = ((((((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe __local_bptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_bptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_bptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_bptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_bptr[5]) as c_int) as c_uint) & (63 as c_uint)) as c_uint)) as c_uint)))
                                    }
                                }
                            }
                        }

                    }

                } else {
                    (__local_c = (((unsafe *__local_bptr) as c_uint)))
                }

                if ((if ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as c_int) / 128)] as c_int) * 128) + ((__local_c as c_int) % 128))] as c_uint) as usize)).gbprop != ucp_gbRegional_Indicator: 1 else: 0) != 0) {
                    break
                }

                (__local_ricount = __local_ricount + 1)

            }

            if ((if ((__local_ricount as c_int) & (1 as c_int)) != 0: 1 else: 0) != 0) {
                break
            }

        }


        var __ci_expr_logic_3: c_int = 0

        if ((if __local_lgb == ucp_gbExtended_Pictographic: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if __local_rgb == ucp_gbZWJ: 1 else: 0) != 0: 1 else: 0))
        }

        (__local_was_ep_ZWJ = __ci_expr_logic_3)


        var __ci_expr_logic_4: c_int

        if ((if __local_rgb != ucp_gbExtend: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_4 = (if (if __local_lgb != ucp_gbExtended_Pictographic: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (__local_lgb = __local_rgb)
        }


        (__local_eptr = __local_eptr + ((__local_len as isize) as usize))

        if ((if __param_xcount != null: 1 else: 0) != 0) {
            ((unsafe *__param_xcount) = (unsafe *__param_xcount) + 1)
        }

    }

    return __local_eptr

}
