// Migrated from C
use std.engines.stc_testing.defs
use std.libc

unsafe fn c_safe_memcpy(__param_dst: *mut c_void, __param_src: *const c_void, __param_size: i64) -> *mut c_void {
    return (((if __param_dst != null: with_memcpy((__param_dst as *mut u8), (__param_src as *const u8), ((__param_size as u64) as i64)) else: (null as *mut c_void)) as *mut c_void))

}

unsafe fn c_basehash_n(__param_key: *const c_void, __param_len: i64) -> u64 {
    var __local_len = __param_len
    var __local_msg: *const u8 = ((__param_key as *const u8))

    var __local_h: u64 = ((((0 as u64) -% 3750763034362895579) as u64))

    var __local_block: u64 = ((0 as u64))


    while ((if __local_len >= ((sizeof[u64]() as i64)): 1 else: 0) != 0) {
        with_memcpy((((&raw mut __local_block as *mut u64) as *mut c_void) as *mut u8), ((__local_msg as *const c_void) as *const u8), ((sizeof[u64]() as u64) as i64))

        (__local_h = (__local_h as u64) ^ (__local_block as u64))

        (__local_h = (__local_h *% 1099511628211))

        (__local_msg = __local_msg + ((sizeof[u64]() as i64) as usize))

        (__local_len = __local_len - (sizeof[u64]() as i64))

    }

    while true {
        var __ci_expr_old_0: i64 = __local_len

        (__local_len = __local_len - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as u64) ^ ((*__ci_expr_old_1) as u64))

        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_n(__param_key: *const c_void, __param_len: i64) -> u64 {
    var __local_b8: u64

    var __local_b4: u32

    match __param_len {
        8 => {
            with_memcpy((((&raw mut __local_b8 as *mut u64) as *mut c_void) as *mut u8), (__param_key as *const u8), ((8 as u64) as i64))

            return ((__local_b8 as u64) *% (((0 as u64) -% 4132994306676758115) as u64))

        },
        4 => {
            with_memcpy((((&raw mut __local_b4 as *mut u32) as *mut c_void) as *mut u8), (__param_key as *const u8), ((4 as u64) as i64))

            return ((__local_b4 as u64) *% (((0 as u64) -% 3750763034362895579) as u64))

        },
        _ => {
            return c_basehash_n(__param_key, __param_len)
        },
    }

}

unsafe fn c_hash_str(__param_str: *const c_char) -> u64 {
    var __local_msg: *const u8 = ((__param_str as *const u8))

    var __local_h: u64 = ((((0 as u64) -% 3750763034362895579) as u64))

    while ((*__local_msg) != 0) {
        var __ci_expr_old_0: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as u64) ^ ((*__ci_expr_old_0) as u64))


        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_mix_n(__param_h: *mut u64, __param_n: i64) -> u64 {
    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        ((__param_h[0]) = ((__param_h[0]) +% (((__param_h[0]) as u64) ^ ((__param_h[__local_i]) as u64))))

        (__local_i = __local_i + 1)

    }


    return (__param_h[0])

}

fn c_next_pow2(__param_n: i64) -> i64 {
    var __local_n = __param_n
    (__local_n = __local_n - 1)

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (1 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (2 as u32)) as i64))


    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (4 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (8 as u32)) as i64))


    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (16 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (32 as u32)) as i64))

    return (__local_n + 1)

}

unsafe fn c_strnstrn(__param_str: *const c_char, __param_slen: i64, __param_needle: *const c_char, __param_nlen: i64) -> *mut c_char {
    var __local_str = __param_str
    var __local_slen = __param_slen
    if ((if __param_nlen == 0: 1 else: 0) != 0) {
        return ((__local_str as *mut c_char))
    }

    if ((if __param_nlen > __local_slen: 1 else: 0) != 0) {
        return ((null as *mut c_char))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: i32 = 0

        if ((if (*__local_str) == (*__param_needle): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if not (with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if 1 != 0: __param_nlen else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return ((__local_str as *mut c_char))
        }


        (__local_str = __local_str + 1)

        var __ci_expr_old_0: i64 = __local_slen

        (__local_slen = __local_slen - 1)

        if not ((__ci_expr_old_0 != 0)) {
            break
        }
    }

    return ((null as *mut c_char))

}

pub unsafe fn cco_execute(__param_fib: *mut cco_task_fiber) -> i32 {
    var __local_err__goto_730_29: i32 = 0

    var __local__st__goto_744_9: *mut cco_task_state = null

    var __ci_expr_logic_0: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        ((*__param_fib).cur_awaiter = (*(&raw const (*(*__param_fib).task).base as *const cco_task_base)).awaiter)
        ((*__param_fib).cur_awaitbits = (*(&raw const (*(*__param_fib).task).base as *const cco_task_base)).awaitbits)
        ((*__param_fib).status = ((_cco_resume_task((*__param_fib).task) as i32)))
        if ((*(&raw const (*__param_fib).error_ as *const cco_err_t)).code != 0) {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_2
        }
    }

    '__ci_bb_1 {
        if ((if (*__param_fib).status == cco_DONE: 1 else: 0) != 0) {
            goto '__ci_bb_3
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_2 {
        if ((((*__param_fib).status as i32) & ((~(*__param_fib).cur_awaitbits) as i32)) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            ((*__param_fib).task = (*__param_fib).cur_awaiter)

            (__ci_expr_logic_0 = (if (if (*__param_fib).task != null: 1 else: 0) != 0: 1 else: 0))

        }
        if (__ci_expr_logic_0 != 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_3 {
        ((*__param_fib).task = (*__param_fib).cur_awaiter)
        if ((if (*__param_fib).task == null: 1 else: 0) != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_4 {
        goto '__ci_bb_15
    }

    '__ci_bb_5 {
        if ((*__param_fib).failed_grp != null) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_6 {
        with_memcpy((&raw mut (*__param_fib).recover_state as *mut u8), (&raw const (*(*__param_fib).task).base.state as *const u8), sizeof[cco_task_state]())
        goto '__ci_bb_4
    }

    '__ci_bb_7 {
        (__local_err__goto_730_29 = ((536870913 as i32)))
        goto '__ci_bb_9
    }

    '__ci_bb_8 {
        goto '__ci_bb_14
    }

    '__ci_bb_9 {
        if (((*(*__param_fib).failed_grp).on_error() as i32) == 0) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_10 {
        goto '__ci_bb_8
    }

    '__ci_bb_11 {
        _cco_cancel(__param_fib, (*__param_fib).failed_grp, (*(&raw const (*__param_fib).error_ as *const cco_err_t)).file, (*(&raw const (*__param_fib).error_ as *const cco_err_t)).line)
        (__local_err__goto_730_29 = ((536870912 as i32)))
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        with_memcpy((&raw mut (*(*__param_fib).parent).error_ as *mut u8), (&raw const (*__param_fib).error_ as *const u8), sizeof[cco_err_t]())
        ((*(*__param_fib).parent).error_.code = __local_err__goto_730_29)
        goto '__ci_bb_10
    }

    '__ci_bb_13 {
        if (((*(*__param_fib).failed_grp).on_error() as i32) == 1) {
            goto '__ci_bb_12
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_14 {
        if ((((*(&raw const (*__param_fib).error_ as *const cco_err_t)).code as u32) & ((~((((1 as u32) << (30 as u32)) as u32) | (((1 as u32) << (29 as u32)) as u32))) as u32)) != 0) {
            goto '__ci_bb_22
        } else {
            goto '__ci_bb_23
        }
    }

    '__ci_bb_15 {
        (__local__st__goto_744_9 = (((&raw const (*(&raw const (*(*__param_fib).task).base as *const cco_task_base)).state as *const cco_task_state) as *mut cco_task_state)))
        if ((if not (*__local__st__goto_744_9).finalizing: 1 else: 0) != 0) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_16 {
        if (0 != 0) {
            goto '__ci_bb_15
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_17 {
        return 1
    }

    '__ci_bb_18 {
        ((*__local__st__goto_744_9).pos = cco_POS_FINAL)
        ((*__local__st__goto_744_9).finalizing = true)
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        goto '__ci_bb_16
    }

    '__ci_bb_20 {
        return 1
    }

    '__ci_bb_21 {
        goto '__ci_bb_14
    }

    '__ci_bb_22 {
        fprintf(libc_stderr(), c"../include/stc/coroutine.h: error: unhandled coroutine error '%d'\n%s:%d: cco_throw(%d ...);\n".ptr, (*(&raw const (*__param_fib).error_ as *const cco_err_t)).code, (*(&raw const (*__param_fib).error_ as *const cco_err_t)).file, (*(&raw const (*__param_fib).error_ as *const cco_err_t)).line, (*(&raw const (*__param_fib).error_ as *const cco_err_t)).code)
        exit((-128 as i32))
    }

    '__ci_bb_23 {
        return 0
    }

    __ci_unreachable()

}

pub unsafe fn cco_execute_next(__param_fib: *mut cco_task_fiber) -> *mut cco_task_fiber {
    var __local__next: *mut cco_task_fiber = (*__param_fib).next

    var __local_more: i32 = ((cco_execute(__local__next) as i32))

    if ((if not (__local_more != 0): 1 else: 0) != 0) {
        var __local_unlinked: *mut cco_task_fiber = __local__next

        if ((if __param_fib == __local_unlinked: 1 else: 0) != 0) {
            (__local__next = ((null as *mut cco_task_fiber)))
        } else {
            (__local__next = (*__local__next).next)

            ((*__local__next).status = ((0 as i32)))

        }

        ((*__param_fib).next = __local__next)

        with_free(((__local_unlinked as *mut c_void) as *mut u8))

    }

    return __local__next

}

pub unsafe fn _cco_new_fiber(__param_task: *mut cco_task, __param_data: *mut c_void) -> *mut cco_task_fiber {
    var __local_new_fb: *mut cco_task_fiber = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [cco_task_fiber; 1] = [cco_task_fiber { task: __param_task, data: __param_data, recover_state: cco_task_state.zeroed(), error_: cco_err_t.zeroed() }]
        (c_safe_memcpy((with_alloc((((if 1 != 0: (sizeof[cco_task_fiber]() as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void), (&__ci_expr_lit_0[0] as *mut cco_task_fiber), (sizeof[cco_task_fiber]() as i64)) as *mut cco_task_fiber)
    }

    ((*__local_new_fb).next = __local_new_fb)

    ((*__param_task).base.state.fib = (*__local_new_fb).next)


    return __local_new_fb

}

pub unsafe fn _cco_spawn(__param_task: *mut cco_task, __param_grp: *mut cco_group, __param_data: *mut c_void, __param_fib: *mut cco_task_fiber) -> *mut cco_task_fiber {
    var __local_new_fb: *mut cco_task_fiber = with 0 as __ci_expr_seq_11 {
        var __ci_expr_ternary_1: *mut cco_task_fiber = null
        if ((*__param_fib).next != null) {
            var __ci_expr_lit_0: [cco_task_fiber; 1] = [cco_task_fiber { next: (*__param_fib).next, parent: __param_fib, recover_state: cco_task_state.zeroed(), error_: cco_err_t.zeroed() }]
            (__ci_expr_ternary_1 = ((c_safe_memcpy((with_alloc((((if 1 != 0: (sizeof[cco_task_fiber]() as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void), (&__ci_expr_lit_0[0] as *mut cco_task_fiber), (sizeof[cco_task_fiber]() as i64)) as *mut cco_task_fiber)))
        } else {
            (__ci_expr_ternary_1 = __param_fib)
        }
        __ci_expr_ternary_1
    }

    ((*__local_new_fb).task = __param_task)

    ((*__local_new_fb).data = (if __param_data != null: __param_data else: (*__param_fib).data))

    ((*__param_fib).next = __local_new_fb)

    ((*__param_task).base.state.fib = (*__param_fib).next)


    ((*__param_task).base.state.parent_grp = __param_grp)

    if (__param_grp != null) {
        (*__param_grp).set_spawn_count((*__param_grp).spawn_count() + 1)
    }

    return __local_new_fb

}

pub unsafe fn _cco_cancel(__param_fib: *mut cco_task_fiber, __param_grp: *mut cco_group, __param_file: *const c_char, __param_line: i32) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if (__param_grp != null) {
        (__ci_expr_logic_0 = (if (if (*__param_grp).spawn_count() == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((false as bool))
    }


    var __local_fit: *mut cco_task_fiber = (*__param_fib).next

    while ((if __local_fit != __param_fib: 1 else: 0) != 0) {
        var __local_tsk: *mut cco_task = (*__local_fit).task

        loop {
            var __ci_expr_logic_1: i32

            if ((if not (__param_grp != null): 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if (*(&raw const (*__local_tsk).base.state as *const cco_task_state)).parent_grp == __param_grp: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_1 != 0) {
                let __ci_copy_90: cco_err_t = (cco_err_t { code: 1073741824, line: __param_line, file: __param_file, info: (*(&raw const (*__param_fib).error_ as *const cco_err_t)).info } as cco_err_t)
                with_memcpy((&raw mut (*__local_fit).error_ as *mut u8), (&raw const __ci_copy_90 as *const u8), sizeof[cco_err_t]())

                loop {
                    var __local__st: *mut cco_task_state = (((&raw const (*(&raw const (*(*__local_fit).task).base as *const cco_task_base)).state as *const cco_task_state) as *mut cco_task_state))

                    if ((if not (*__local__st).finalizing: 1 else: 0) != 0) {
                        ((*__local__st).pos = cco_POS_FINAL)

                        ((*__local__st).finalizing = true)

                    }

                    if not ((0 != 0)) {
                        break
                    }
                }

                break

            }


            (__local_tsk = (*(&raw const (*__local_tsk).base as *const cco_task_base)).awaiter)

            if not ((__local_tsk != null)) {
                break
            }
        }


        (__local_fit = (*__local_fit).next)

    }


    return ((true as bool))

}

pub unsafe fn _cco_throw(__param_caller: *mut cco_task, __param_err: cco_err_t) {
    var __local_caller = __param_caller
    var __local_fib: *mut cco_task_fiber = (*(&raw const (*__local_caller).base.state as *const cco_task_state)).fib

    with_memcpy((&raw mut (*__local_fib).error_ as *mut u8), (&raw const __param_err as *const u8), sizeof[cco_err_t]())

    with_memcpy((&raw mut (*__local_fib).recover_state as *mut u8), (&raw const (*__local_caller).base.state as *const u8), sizeof[cco_task_state]())

    if ((*__local_fib).parent != null) {
        with_memcpy((&raw mut (*(*__local_fib).parent).recover_state as *mut u8), (&raw const (*(*(*__local_fib).parent).task).base.state as *const u8), sizeof[cco_task_state]())

        while ((*(&raw const (*__local_caller).base as *const cco_task_base)).awaiter != null) {
            (__local_caller = (*(&raw const (*__local_caller).base as *const cco_task_base)).awaiter)
        }

        ((*__local_fib).failed_grp = (*(&raw const (*__local_caller).base.state as *const cco_task_state)).parent_grp)

    }

}

pub unsafe fn _cco_resume_task(__param_task: *mut cco_task) -> i32 {
    return (*(&raw const (*__param_task).base as *const cco_task_base)).func.unwrap()(__param_task)

}

pub unsafe fn _cco_cancel_fiber(__param_fib: *mut cco_task_fiber, __param_err: cco_err_t) -> *mut cco_task_fiber {
    with_memcpy((&raw mut (*__param_fib).error_ as *mut u8), (&raw const __param_err as *const u8), sizeof[cco_err_t]())

    loop {
        var __local__st: *mut cco_task_state = (((&raw const (*(&raw const (*(*__param_fib).task).base as *const cco_task_base)).state as *const cco_task_state) as *mut cco_task_state))

        if ((if not (*__local__st).finalizing: 1 else: 0) != 0) {
            ((*__local__st).pos = cco_POS_FINAL)

            ((*__local__st).finalizing = true)

        }

        if not ((0 != 0)) {
            break
        }
    }

    return __param_fib

}

pub unsafe fn _cco_cancel_task(__param_tsk: *mut cco_task, __param_err: cco_err_t) -> *mut cco_task {
    _cco_cancel_fiber((*(&raw const (*__param_tsk).base.state as *const cco_task_state)).fib, __param_err)

    return __param_tsk

}

pub fn cco_timer_ticks() -> i64 {
    var __local_tv: timeval

    unsafe { gettimeofday((&raw mut __local_tv as *mut timeval), null) }

    return (((unsafe *(&raw const __local_tv as *const timeval)).tv_sec * 1000000) + (unsafe *(&raw const __local_tv as *const timeval)).tv_usec)

}

pub fn cco_make_timer(__param_sec: f64) -> cco_timer {
    var __local_tm: cco_timer = cco_timer { duration: __param_sec, start_time: cco_timer_ticks() }

    return __local_tm

}

pub unsafe fn cco_start_timer(__param_tm: *mut cco_timer, __param_sec: f64) {
    ((*__param_tm).duration = __param_sec)

    ((*__param_tm).start_time = ((cco_timer_ticks() as i64)))

}

pub unsafe fn cco_restart_timer(__param_tm: *mut cco_timer) {
    ((*__param_tm).start_time = ((cco_timer_ticks() as i64)))

}

pub unsafe fn cco_timer_elapsed(__param_tm: *mut cco_timer) -> f64 {
    return (((cco_timer_ticks() - (*__param_tm).start_time) as f64) * (1.0 / (1000000 as f64)))

}

pub unsafe fn cco_timer_expired(__param_tm: *mut cco_timer) -> bool {
    return ((((cco_timer_elapsed(__param_tm) >= (*__param_tm).duration)) as bool))

}

pub unsafe fn cco_timer_remaining(__param_tm: *mut cco_timer) -> f64 {
    return ((*__param_tm).duration - cco_timer_elapsed(__param_tm))

}
