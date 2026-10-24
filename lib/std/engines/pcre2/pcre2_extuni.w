// Migrated from C
use std.engines.pcre2.defs
use std.engines.pcre2.pcre2_config
use std.engines.pcre2.pcre2_context
use std.engines.pcre2.pcre2_convert
use std.engines.pcre2.pcre2_compile
use std.engines.pcre2.pcre2_pattern_info
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
use std.engines.pcre2.pcre2_find_bracket
use std.engines.pcre2.pcre2_newline
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass

pub unsafe fn _pcre2_extuni_8(__param_c: u32, __param_eptr: *const u8, __param_start_subject: *const u8, __param_end_subject: *const u8, __param_utf: i32, __param_xcount: *mut i32) -> *const u8 {
    var __local_c = __param_c
    var __local_eptr = __param_eptr
    var __local_was_ep_ZWJ: i32 = ((0 as i32))

    var __local_lgb: i32 = ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as i32) / 128)] as i32) * 128) + ((__local_c as i32) % 128))] as u32) as usize)).gbprop as i32))

    while ((if __local_eptr < __param_end_subject: 1 else: 0) != 0) {
        var __local_rgb: i32

        var __local_len: i32 = ((1 as i32))

        if ((if not (__param_utf != 0): 1 else: 0) != 0) {
            (__local_c = (((*__local_eptr) as u32)))
        } else {
            (__local_c = (((*__local_eptr) as u32)))

            if ((if __local_c >= 192: 1 else: 0) != 0) {
                if ((if ((__local_c as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
                    (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((__local_eptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                    (__local_len = __local_len + 1)

                } else {
                    if ((if ((__local_c as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
                        (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((__local_eptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_eptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                        (__local_len = __local_len + 2)

                    } else {
                        if ((if ((__local_c as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
                            (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((__local_eptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_eptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_eptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                            (__local_len = __local_len + 3)

                        } else {
                            if ((if ((__local_c as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
                                (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((__local_eptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_eptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_eptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_eptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_len = __local_len + 4)

                            } else {
                                (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((__local_eptr[1]) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_eptr[2]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_eptr[3]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_eptr[4]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_eptr[5]) as i32) as u32) & (63 as u32)) as u32)) as u32)))

                                (__local_len = __local_len + 5)

                            }
                        }
                    }
                }

            }



        }

        (__local_rgb = ((((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as i32) / 128)] as i32) * 128) + ((__local_c as i32) % 128))] as u32) as usize)).gbprop as i32)))

        if ((if ((_pcre2_ucp_gbtable_8[__local_lgb] as u32) & (((1 as u32) << (__local_rgb as u32)) as u32)) == 0: 1 else: 0) != 0) {
            break
        }

        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_logic_0: i32 = 0

        if ((if __local_lgb == ucp_gbZWJ: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_rgb == ucp_gbExtended_Pictographic: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if not (__local_was_ep_ZWJ != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            break
        }


        var __ci_expr_logic_2: i32 = 0

        if ((if __local_lgb == ucp_gbRegional_Indicator: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if __local_rgb == ucp_gbRegional_Indicator: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            var __local_ricount: i32 = ((0 as i32))

            var __local_bptr: *const u8 = (__local_eptr - ((1 as isize) as usize))

            if (__param_utf != 0) {
                while ((if ((((*__local_bptr) as i32) as u32) & (192 as u32)) == 128: 1 else: 0) != 0) {
                    (__local_bptr = __local_bptr - 1)
                }
            }

            while ((if __local_bptr > __param_start_subject: 1 else: 0) != 0) {
                (__local_bptr = __local_bptr - 1)

                if (__param_utf != 0) {
                    while ((if ((((*__local_bptr) as i32) as u32) & (192 as u32)) == 128: 1 else: 0) != 0) {
                        (__local_bptr = __local_bptr - 1)
                    }

                    (__local_c = (((*__local_bptr) as u32)))

                    if ((if __local_c >= 192: 1 else: 0) != 0) {
                        if ((if ((__local_c as u32) & (32 as u32)) == 0: 1 else: 0) != 0) {
                            (__local_c = ((((((((__local_c as u32) & (31 as u32)) as u32) << (6 as u32)) as u32) | (((((__local_bptr[1]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                        } else {
                            if ((if ((__local_c as u32) & (16 as u32)) == 0: 1 else: 0) != 0) {
                                (__local_c = ((((((((((__local_c as u32) & (15 as u32)) as u32) << (12 as u32)) as u32) | (((((((__local_bptr[1]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_bptr[2]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                            } else {
                                if ((if ((__local_c as u32) & (8 as u32)) == 0: 1 else: 0) != 0) {
                                    (__local_c = ((((((((((((__local_c as u32) & (7 as u32)) as u32) << (18 as u32)) as u32) | (((((((__local_bptr[1]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_bptr[2]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_bptr[3]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                                } else {
                                    if ((if ((__local_c as u32) & (4 as u32)) == 0: 1 else: 0) != 0) {
                                        (__local_c = ((((((((((((((__local_c as u32) & (3 as u32)) as u32) << (24 as u32)) as u32) | (((((((__local_bptr[1]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_bptr[2]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_bptr[3]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_bptr[4]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                                    } else {
                                        (__local_c = ((((((((((((((((__local_c as u32) & (1 as u32)) as u32) << (30 as u32)) as u32) | (((((((__local_bptr[1]) as i32) as u32) & (63 as u32)) as u32) << (24 as u32)) as u32)) as u32) | (((((((__local_bptr[2]) as i32) as u32) & (63 as u32)) as u32) << (18 as u32)) as u32)) as u32) | (((((((__local_bptr[3]) as i32) as u32) & (63 as u32)) as u32) << (12 as u32)) as u32)) as u32) | (((((((__local_bptr[4]) as i32) as u32) & (63 as u32)) as u32) << (6 as u32)) as u32)) as u32) | (((((__local_bptr[5]) as i32) as u32) & (63 as u32)) as u32)) as u32)))
                                    }
                                }
                            }
                        }

                    }



                } else {
                    (__local_c = (((*__local_bptr) as u32)))
                }

                if ((if ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[(((_pcre2_ucd_stage1_8[((__local_c as i32) / 128)] as i32) * 128) + ((__local_c as i32) % 128))] as u32) as usize)).gbprop != ucp_gbRegional_Indicator: 1 else: 0) != 0) {
                    break
                }

                (__local_ricount = __local_ricount + 1)

            }

            if ((if ((__local_ricount as i32) & (1 as i32)) != 0: 1 else: 0) != 0) {
                break
            }

        }


        var __ci_expr_logic_3: i32 = 0

        if ((if __local_lgb == ucp_gbExtended_Pictographic: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if __local_rgb == ucp_gbZWJ: 1 else: 0) != 0: 1 else: 0))
        }

        (__local_was_ep_ZWJ = __ci_expr_logic_3)


        var __ci_expr_logic_4: i32

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
            ((*__param_xcount) = (*__param_xcount) + 1)
        }

    }

    return __local_eptr

}
