// Migrated from PCRE2
use std.re.defs

fn pcre2_substring_copy_byname_8(match_data: *mut pcre2_real_match_data_8, stringname: *const u8, buffer: *mut u8, sizeptr: *mut c_ulong) -> c_int {
    var first: *const u8

    var last: *const u8

    var entry: *const u8


    var failrc: c_int

    var entrysize: c_int


    if ((if match_data.matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
        return -41
    }

    (entrysize = pcre2_substring_nametable_scan_8(match_data.code, stringname, (&mut first as *mut *const u8), (&mut last as *mut *const u8)))

    if ((if entrysize < 0: 1 else: 0) != 0) {
        return entrysize
    }

    (failrc = -54)

    (entry = first)

    while ((if entry <= last: 1 else: 0) != 0) {
        var n: c_uint = ((((((unsafe: entry[0]) as c_int) << 8) | (unsafe: entry[(0 + 1)])) as c_uint))

        if ((if n < match_data.oveccount: 1 else: 0) != 0) {
            if ((if match_data.ovector[(n *% 2)] != (~(0 as c_ulong)): 1 else: 0) != 0) {
                return pcre2_substring_copy_bynumber_8(match_data, n, buffer, sizeptr)
            }

            (failrc = -55)

        }


        (entry = entry + entrysize)

    }


    return failrc

}

fn pcre2_substring_copy_bynumber_8(match_data: *mut pcre2_real_match_data_8, stringnumber: c_uint, buffer: *mut u8, sizeptr: *mut c_ulong) -> c_int {
    var rc: c_int

    var size: c_ulong

    (rc = pcre2_substring_length_bynumber_8(match_data, stringnumber, (&mut size as *mut c_ulong)))

    if ((if rc < 0: 1 else: 0) != 0) {
        return rc
    }

    if ((if (size +% 1) > (unsafe: *sizeptr): 1 else: 0) != 0) {
        return -48
    }

    if ((if size != 0: 1 else: 0) != 0) {
        with_memcpy((buffer as *i8), ((match_data.subject + match_data.ovector[(stringnumber *% 2)]) as *i8), ((size *% 1) as i64))
    }

    ((unsafe: buffer[size]) = 0)

    ((unsafe: *sizeptr) = size)

    return 0

}

fn pcre2_substring_free_8(string: *mut u8) {
    if ((if string != null: 1 else: 0) != 0) {
        var memctl: *mut pcre2_memctl = ((((string as *mut c_char) - sizeof[pcre2_memctl]()) as *mut pcre2_memctl))

        memctl.free(memctl, memctl.memory_data)

    }

}

fn pcre2_substring_get_byname_8(match_data: *mut pcre2_real_match_data_8, stringname: *const u8, stringptr: *mut *mut u8, sizeptr: *mut c_ulong) -> c_int {
    var first: *const u8

    var last: *const u8

    var entry: *const u8


    var failrc: c_int

    var entrysize: c_int


    if ((if match_data.matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
        return -41
    }

    (entrysize = pcre2_substring_nametable_scan_8(match_data.code, stringname, (&mut first as *mut *const u8), (&mut last as *mut *const u8)))

    if ((if entrysize < 0: 1 else: 0) != 0) {
        return entrysize
    }

    (failrc = -54)

    (entry = first)

    while ((if entry <= last: 1 else: 0) != 0) {
        var n: c_uint = ((((((unsafe: entry[0]) as c_int) << 8) | (unsafe: entry[(0 + 1)])) as c_uint))

        if ((if n < match_data.oveccount: 1 else: 0) != 0) {
            if ((if match_data.ovector[(n *% 2)] != (~(0 as c_ulong)): 1 else: 0) != 0) {
                return pcre2_substring_get_bynumber_8(match_data, n, stringptr, sizeptr)
            }

            (failrc = -55)

        }


        (entry = entry + entrysize)

    }


    return failrc

}

fn pcre2_substring_get_bynumber_8(match_data: *mut pcre2_real_match_data_8, stringnumber: c_uint, stringptr: *mut *mut u8, sizeptr: *mut c_ulong) -> c_int {
    var rc: c_int

    var size: c_ulong

    var yield_: *mut u8

    (rc = pcre2_substring_length_bynumber_8(match_data, stringnumber, (&mut size as *mut c_ulong)))

    if ((if rc < 0: 1 else: 0) != 0) {
        return rc
    }

    (yield_ = ((_pcre2_memctl_malloc_8((sizeof[pcre2_memctl]() +% ((size +% 1) *% 8)), (match_data as *mut pcre2_memctl)) as *mut u8)))

    if ((if yield_ == null: 1 else: 0) != 0) {
        return -48
    }

    (yield_ = ((((yield_ as *mut c_char) + sizeof[pcre2_memctl]()) as *mut u8)))

    if ((if size != 0: 1 else: 0) != 0) {
        with_memcpy((yield_ as *i8), ((match_data.subject + match_data.ovector[(stringnumber *% 2)]) as *i8), ((size *% 1) as i64))
    }

    ((unsafe: yield_[size]) = 0)

    ((unsafe: *stringptr) = yield_)

    ((unsafe: *sizeptr) = size)

    return 0

}

fn pcre2_substring_length_byname_8(match_data: *mut pcre2_real_match_data_8, stringname: *const u8, sizeptr: *mut c_ulong) -> c_int {
    var first: *const u8

    var last: *const u8

    var entry: *const u8


    var failrc: c_int

    var entrysize: c_int


    if ((if match_data.matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
        return -41
    }

    (entrysize = pcre2_substring_nametable_scan_8(match_data.code, stringname, (&mut first as *mut *const u8), (&mut last as *mut *const u8)))

    if ((if entrysize < 0: 1 else: 0) != 0) {
        return entrysize
    }

    (failrc = -54)

    (entry = first)

    while ((if entry <= last: 1 else: 0) != 0) {
        var n: c_uint = ((((((unsafe: entry[0]) as c_int) << 8) | (unsafe: entry[(0 + 1)])) as c_uint))

        if ((if n < match_data.oveccount: 1 else: 0) != 0) {
            if ((if match_data.ovector[(n *% 2)] != (~(0 as c_ulong)): 1 else: 0) != 0) {
                return pcre2_substring_length_bynumber_8(match_data, n, sizeptr)
            }

            (failrc = -55)

        }


        (entry = entry + entrysize)

    }


    return failrc

}

fn pcre2_substring_length_bynumber_8(match_data: *mut pcre2_real_match_data_8, stringnumber: c_uint, sizeptr: *mut c_ulong) -> c_int {
    var left: c_ulong

    var right: c_ulong


    var count: c_int = match_data.rc

    if ((if count == -2: 1 else: 0) != 0) {
        if ((if stringnumber > 0: 1 else: 0) != 0) {
            return -2
        }

        (count = 0)

    } else {
        if ((if count < 0: 1 else: 0) != 0) {
            return count
        }
    }

    if ((if match_data.matchedby != PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
        if ((if stringnumber > match_data.code.top_bracket: 1 else: 0) != 0) {
            return -49
        }

        if ((if stringnumber >= match_data.oveccount: 1 else: 0) != 0) {
            return -54
        }

        if ((if match_data.ovector[(stringnumber *% 2)] == (~(0 as c_ulong)): 1 else: 0) != 0) {
            return -55
        }

    } else {
        if ((if stringnumber >= match_data.oveccount: 1 else: 0) != 0) {
            return -54
        }

        var __ci_expr_logic_0: c_int = 0

        if ((if count != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if stringnumber >= ((count as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            return -55
        }


    }

    (left = match_data.ovector[(stringnumber *% 2)])

    (right = match_data.ovector[((stringnumber *% 2) +% 1)])

    var __ci_expr_logic_1: c_int

    if ((if left > match_data.subject_length: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if right > match_data.subject_length: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        while true {
            if (not (0 != 0)) {
                break
            }
        }

        return -67

    }


    if ((if sizeptr != null: 1 else: 0) != 0) {
        var __ci_expr_ternary_2: c_ulong = 0

        if ((if left > right: 1 else: 0) != 0) {
            (__ci_expr_ternary_2 = 0)
        } else {
            (__ci_expr_ternary_2 = (right -% left))
        }

        ((unsafe: *sizeptr) = __ci_expr_ternary_2)

    }

    return 0

}

fn pcre2_substring_nametable_scan_8(code: *const pcre2_real_code_8, stringname: *const u8, firstptr: *mut *const u8, lastptr: *mut *const u8) -> c_int {
    var bot: c_ushort = 0

    var top: c_ushort = code.name_count

    var entrysize: c_ushort = code.name_entry_size

    var nametable: *const u8 = ((((code as *const c_char) + sizeof[pcre2_real_code_8]()) as *const u8))

    while ((if top > bot: 1 else: 0) != 0) {
        var mid: c_ushort = ((top + bot) / 2)

        var entry: *const u8 = (nametable + (((entrysize * mid) as isize) as usize))

        var c: c_int = _pcre2_strcmp_8(stringname, (entry + ((2 as isize) as usize)))

        if ((if c == 0: 1 else: 0) != 0) {
            var first: *const u8

            var last: *const u8

            var lastentry: *const u8

            (lastentry = nametable + (((entrysize * (code.name_count - 1)) as isize) as usize))

            (last = entry)

            (first = last)


            while ((if first > nametable: 1 else: 0) != 0) {
                if ((if _pcre2_strcmp_8(stringname, ((first - ((entrysize as isize) as usize)) + ((2 as isize) as usize))) != 0: 1 else: 0) != 0) {
                    break
                }

                (first = first - entrysize)

            }

            while ((if last < lastentry: 1 else: 0) != 0) {
                if ((if _pcre2_strcmp_8(stringname, ((last + ((entrysize as isize) as usize)) + ((2 as isize) as usize))) != 0: 1 else: 0) != 0) {
                    break
                }

                (last = last + entrysize)

            }

            if ((if firstptr == null: 1 else: 0) != 0) {
                var __ci_expr_ternary_0: c_int = 0

                if ((if first == last: 1 else: 0) != 0) {
                    (__ci_expr_ternary_0 = (((((((unsafe: entry[0]) as c_int) << 8) | (unsafe: entry[(0 + 1)])) as c_uint) as c_int)))
                } else {
                    (__ci_expr_ternary_0 = -50)
                }

                return __ci_expr_ternary_0

            }

            ((unsafe: *firstptr) = first)

            ((unsafe: *lastptr) = last)

            return entrysize

        }

        if ((if c > 0: 1 else: 0) != 0) {
            (bot = mid + 1)
        } else {
            (top = mid)
        }

    }

    return -49

}

fn pcre2_substring_number_from_name_8(code: *const pcre2_real_code_8, stringname: *const u8) -> c_int {
    return pcre2_substring_nametable_scan_8(code, stringname, null, null)

}

fn pcre2_substring_list_free_8(list: *mut *mut u8) {
    if ((if list != null: 1 else: 0) != 0) {
        var memctl: *mut pcre2_memctl = ((((list as *mut c_char) - sizeof[pcre2_memctl]()) as *mut pcre2_memctl))

        memctl.free(memctl, memctl.memory_data)

    }

}

fn pcre2_substring_list_get_8(match_data: *mut pcre2_real_match_data_8, listptr: *mut *mut *mut u8, lengthsptr: *mut *mut c_ulong) -> c_int {
    var i: c_int

    var count: c_int

    var count2: c_int


    var size: c_ulong

    var lensp: *mut c_ulong

    var memp: *mut pcre2_memctl

    var listp: *mut *mut u8

    var sp: *mut u8

    var ovector: *mut c_ulong

    (count = match_data.rc)

    if ((if count < 0: 1 else: 0) != 0) {
        return count
    }


    if ((if count == 0: 1 else: 0) != 0) {
        (count = match_data.oveccount)
    }

    (count2 = 2 * count)

    (ovector = (&match_data.ovector[0] as *mut c_ulong))

    (size = (sizeof[pcre2_memctl]() +% sizeof[u8]()))

    if ((if lengthsptr != null: 1 else: 0) != 0) {
        (size = size + (sizeof[c_ulong]() *% count))
    }

    (i = 0)

    while ((if i < count2: 1 else: 0) != 0) {
        (size = size + (sizeof[u8]() +% 1))

        if ((if (unsafe: ovector[(i + 1)]) > (unsafe: ovector[i]): 1 else: 0) != 0) {
            (size = size + (((unsafe: ovector[(i + 1)]) -% (unsafe: ovector[i])) *% 1))
        }


        (i = i + 2)

    }


    (memp = ((_pcre2_memctl_malloc_8(size, (match_data as *mut pcre2_memctl)) as *mut pcre2_memctl)))

    if ((if memp == null: 1 else: 0) != 0) {
        return -48
    }

    (listp = ((((memp as *mut c_char) + sizeof[pcre2_memctl]()) as *mut *mut u8)))

    ((unsafe: *listptr) = listp)


    (lensp = ((((listp as *mut c_char) + (sizeof[u8]() *% (count + 1))) as *mut c_ulong)))

    if ((if lengthsptr == null: 1 else: 0) != 0) {
        (sp = ((lensp as *mut u8)))

        (lensp = ((null as *mut c_ulong)))

    } else {
        ((unsafe: *lengthsptr) = lensp)

        (sp = ((((lensp as *mut c_char) + (sizeof[c_ulong]() *% count)) as *mut u8)))

    }

    (i = 0)

    while ((if i < count2: 1 else: 0) != 0) {
        var __ci_expr_ternary_0: c_ulong = 0

        if ((if (unsafe: ovector[(i + 1)]) > (unsafe: ovector[i]): 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = ((unsafe: ovector[(i + 1)]) -% (unsafe: ovector[i])))
        } else {
            (__ci_expr_ternary_0 = 0)
        }

        (size = __ci_expr_ternary_0)


        if ((if size != 0: 1 else: 0) != 0) {
            with_memcpy((sp as *i8), ((match_data.subject + (unsafe: ovector[i])) as *i8), ((size *% 1) as i64))
        }

        var __ci_expr_old_1: *mut *mut u8 = listp

        (listp = listp + 1)

        ((unsafe: *__ci_expr_old_1) = sp)


        if ((if lensp != null: 1 else: 0) != 0) {
            var __ci_expr_old_2: *mut c_ulong = lensp

            (lensp = lensp + 1)

            ((unsafe: *__ci_expr_old_2) = size)

        }

        (sp = sp + size)

        var __ci_expr_old_3: *mut u8 = sp

        (sp = sp + 1)

        ((unsafe: *__ci_expr_old_3) = 0)



        (i = i + 2)

    }


    ((unsafe: *listp) = ((null as *mut u8)))

    return 0

}
