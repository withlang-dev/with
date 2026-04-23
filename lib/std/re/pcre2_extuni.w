// Migrated from PCRE2
use std.re.defs

fn _pcre2_extuni_8(__param_c: c_uint, __param_eptr: *const u8, start_subject: *const u8, end_subject: *const u8, utf: c_int, xcount: *mut c_int) -> *const u8 {
    var c = __param_c
    var eptr = __param_eptr
    var was_ep_ZWJ: c_int = 0

    var lgb: c_int = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize)).gbprop

    while ((if eptr < end_subject: 1 else: 0) != 0) {
        var rgb: c_int

        var len: c_int = 1

        if ((if not (utf != 0): 1 else: 0) != 0) {
            (c = (unsafe: *eptr))
        } else {
            (c = (unsafe: *eptr))

            if ((if c >= 192: 1 else: 0) != 0) {
                if ((if (c & 32) == 0: 1 else: 0) != 0) {
                    (c = (((c & 31) as c_uint) << 6) | ((unsafe: eptr[1]) & 63))

                    (len = len + 1)

                } else {
                    if ((if (c & 16) == 0: 1 else: 0) != 0) {
                        (c = ((((c & 15) as c_uint) << 12) | ((((unsafe: eptr[1]) & 63) as c_uint) << 6)) | ((unsafe: eptr[2]) & 63))

                        (len = len + 2)

                    } else {
                        if ((if (c & 8) == 0: 1 else: 0) != 0) {
                            (c = (((((c & 7) as c_uint) << 18) | ((((unsafe: eptr[1]) & 63) as c_uint) << 12)) | ((((unsafe: eptr[2]) & 63) as c_uint) << 6)) | ((unsafe: eptr[3]) & 63))

                            (len = len + 3)

                        } else {
                            if ((if (c & 4) == 0: 1 else: 0) != 0) {
                                (c = ((((((c & 3) as c_uint) << 24) | ((((unsafe: eptr[1]) & 63) as c_uint) << 18)) | ((((unsafe: eptr[2]) & 63) as c_uint) << 12)) | ((((unsafe: eptr[3]) & 63) as c_uint) << 6)) | ((unsafe: eptr[4]) & 63))

                                (len = len + 4)

                            } else {
                                (c = (((((((c & 1) as c_uint) << 30) | ((((unsafe: eptr[1]) & 63) as c_uint) << 24)) | ((((unsafe: eptr[2]) & 63) as c_uint) << 18)) | ((((unsafe: eptr[3]) & 63) as c_uint) << 12)) | ((((unsafe: eptr[4]) & 63) as c_uint) << 6)) | ((unsafe: eptr[5]) & 63))

                                (len = len + 5)

                            }
                        }
                    }
                }

            }

        }

        (rgb = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize)).gbprop)

        if ((if (_pcre2_ucp_gbtable_8[lgb] & ((1 as c_uint) << rgb)) == 0: 1 else: 0) != 0) {
            break
        }

        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_logic_0: c_int = 0

        if ((if lgb == ucp_gbZWJ: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if rgb == ucp_gbExtended_Pictographic: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if not (was_ep_ZWJ != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            break
        }


        var __ci_expr_logic_2: c_int = 0

        if ((if lgb == ucp_gbRegional_Indicator: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if (if rgb == ucp_gbRegional_Indicator: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            var ricount: c_int = 0

            var bptr: *const u8 = (eptr - ((1 as isize) as usize))

            if (utf != 0) {
                while ((if ((unsafe: *bptr) & 192) == 128: 1 else: 0) != 0) {
                    (bptr = bptr - 1)
                }
            }

            while ((if bptr > start_subject: 1 else: 0) != 0) {
                (bptr = bptr - 1)

                if (utf != 0) {
                    while ((if ((unsafe: *bptr) & 192) == 128: 1 else: 0) != 0) {
                        (bptr = bptr - 1)
                    }

                    (c = (unsafe: *bptr))

                    if ((if c >= 192: 1 else: 0) != 0) {
                        if ((if (c & 32) == 0: 1 else: 0) != 0) {
                            (c = (((c & 31) as c_uint) << 6) | ((unsafe: bptr[1]) & 63))
                        } else {
                            if ((if (c & 16) == 0: 1 else: 0) != 0) {
                                (c = ((((c & 15) as c_uint) << 12) | ((((unsafe: bptr[1]) & 63) as c_uint) << 6)) | ((unsafe: bptr[2]) & 63))
                            } else {
                                if ((if (c & 8) == 0: 1 else: 0) != 0) {
                                    (c = (((((c & 7) as c_uint) << 18) | ((((unsafe: bptr[1]) & 63) as c_uint) << 12)) | ((((unsafe: bptr[2]) & 63) as c_uint) << 6)) | ((unsafe: bptr[3]) & 63))
                                } else {
                                    if ((if (c & 4) == 0: 1 else: 0) != 0) {
                                        (c = ((((((c & 3) as c_uint) << 24) | ((((unsafe: bptr[1]) & 63) as c_uint) << 18)) | ((((unsafe: bptr[2]) & 63) as c_uint) << 12)) | ((((unsafe: bptr[3]) & 63) as c_uint) << 6)) | ((unsafe: bptr[4]) & 63))
                                    } else {
                                        (c = (((((((c & 1) as c_uint) << 30) | ((((unsafe: bptr[1]) & 63) as c_uint) << 24)) | ((((unsafe: bptr[2]) & 63) as c_uint) << 18)) | ((((unsafe: bptr[3]) & 63) as c_uint) << 12)) | ((((unsafe: bptr[4]) & 63) as c_uint) << 6)) | ((unsafe: bptr[5]) & 63))
                                    }
                                }
                            }
                        }

                    }

                } else {
                    (c = (unsafe: *bptr))
                }

                if ((if ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize)).gbprop != ucp_gbRegional_Indicator: 1 else: 0) != 0) {
                    break
                }

                (ricount = ricount + 1)

            }

            if ((if (ricount & 1) != 0: 1 else: 0) != 0) {
                break
            }

        }


        var __ci_expr_logic_3: c_int = 0

        if ((if lgb == ucp_gbExtended_Pictographic: 1 else: 0) != 0) {
            (__ci_expr_logic_3 = (if (if rgb == ucp_gbZWJ: 1 else: 0) != 0: 1 else: 0))
        }

        (was_ep_ZWJ = __ci_expr_logic_3)


        var __ci_expr_logic_4: c_int

        if ((if rgb != ucp_gbExtend: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_4 = (if (if lgb != ucp_gbExtended_Pictographic: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_4 != 0) {
            (lgb = rgb)
        }


        (eptr = eptr + len)

        if ((if xcount != null: 1 else: 0) != 0) {
            ((unsafe: *xcount) = (unsafe: *xcount) + 1)
        }

    }

    return eptr

}
