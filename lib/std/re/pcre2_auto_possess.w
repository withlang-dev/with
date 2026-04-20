// Migrated from PCRE2
use std.re.defs

fn _pcre2_auto_possessify_8(__param_code: *mut u8, cb: *const compile_block_8) -> c_int {
    var code = __param_code
    var c: u8

    var end: *const u8

    var repeat_opcode: *mut u8

    var list: [8]c_uint

    var rec_limit: c_int = 1000

    var utf: c_int = (if (cb.external_options & 524288) != 0: 1 else: 0)

    var ucp: c_int = (if (cb.external_options & 131072) != 0: 1 else: 0)

    while true {
        (c = (unsafe: *code))
        
        if ((if c >= OP_TABLE_LENGTH: 1 else: 0) != 0) {
            while true {
                if (not (0 != 0)) {
                    break
                }
            }
            
            return -1
            
        }
        
        var __ci_expr_logic_0: c_int = 0
        
        if ((if c >= OP_STAR: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if c <= OP_TYPEPOSUPTO: 1 else: 0) != 0: 1 else: 0))
        }
        
        if (__ci_expr_logic_0 != 0) {
            (c = c - (get_repeat_base(c) - OP_STAR))
            
            var __ci_expr_ternary_1: *const u8 = null
            
            if ((if c <= OP_MINUPTO: 1 else: 0) != 0) {
                (__ci_expr_ternary_1 = get_chr_property_list(code, utf, ucp, cb.fcc, (&list[0] as *mut c_uint)))
            } else {
                (__ci_expr_ternary_1 = null)
            }
            
            (end = __ci_expr_ternary_1)
            
            
            var __ci_expr_logic_4: c_int
            
            var __ci_expr_logic_3: c_int
            
            var __ci_expr_logic_2: c_int
            
            if ((if c == OP_STAR: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if c == OP_PLUS: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if c == OP_QUERY: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_3 != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if c == OP_UPTO: 1 else: 0) != 0: 1 else: 0))
            }
            
            (list[1] = __ci_expr_logic_4)
            
            
            var __ci_expr_logic_5: c_int = 0
            
            if ((if end != null: 1 else: 0) != 0) {
                (__ci_expr_logic_5 = (if compare_opcodes(end, utf, ucp, cb, (&list[0] as *mut c_uint), end, (&mut rec_limit as *mut c_int)) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_5 != 0) {
                match c:
                    OP_STAR =>
                        ((unsafe: *code) = (unsafe: *code) + (OP_POSSTAR - OP_STAR))
                    OP_MINSTAR =>
                        ((unsafe: *code) = (unsafe: *code) + (OP_POSSTAR - OP_MINSTAR))
                    OP_PLUS =>
                        ((unsafe: *code) = (unsafe: *code) + (OP_POSPLUS - OP_PLUS))
                    OP_MINPLUS =>
                        ((unsafe: *code) = (unsafe: *code) + (OP_POSPLUS - OP_MINPLUS))
                    OP_QUERY =>
                        ((unsafe: *code) = (unsafe: *code) + (OP_POSQUERY - OP_QUERY))
                    OP_MINQUERY =>
                        ((unsafe: *code) = (unsafe: *code) + (OP_POSQUERY - OP_MINQUERY))
                    OP_UPTO =>
                        ((unsafe: *code) = (unsafe: *code) + (OP_POSUPTO - OP_UPTO))
                    OP_MINUPTO =>
                        ((unsafe: *code) = (unsafe: *code) + (OP_POSUPTO - OP_MINUPTO))
                
            }
            
            
            (c = (unsafe: *code))
            
        } else {
            var __ci_expr_logic_8: c_int
            
            var __ci_expr_logic_7: c_int
            
            var __ci_expr_logic_6: c_int
            
            if ((if c == OP_CLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_6 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_6 = (if (if c == OP_NCLASS: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_6 != 0) {
                (__ci_expr_logic_7 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_7 = (if (if c == OP_XCLASS: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_7 != 0) {
                (__ci_expr_logic_8 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_8 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_8 != 0) {
                var __ci_expr_logic_9: c_int
                
                if ((if c == OP_XCLASS: 1 else: 0) != 0) {
                    (__ci_expr_logic_9 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_9 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_9 != 0) {
                    (repeat_opcode = code + (((code[1] << 8) | code[(1 + 1)]) as c_uint))
                } else {
                    (repeat_opcode = (code + ((1 as isize) as usize)) + (32 / sizeof[u8]()))
                }
                
                
                (c = (unsafe: *repeat_opcode))
                
                var __ci_expr_logic_10: c_int = 0
                
                if ((if c >= OP_CRSTAR: 1 else: 0) != 0) {
                    (__ci_expr_logic_10 = (if (if c <= OP_CRMINRANGE: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_10 != 0) {
                    (end = get_chr_property_list(code, utf, ucp, cb.fcc, (&list[0] as *mut c_uint)))
                    
                    (list[1] = (if (c & 1) == 0: 1 else: 0))
                    
                    var __ci_expr_logic_11: c_int = 0
                    
                    if ((if end != null: 1 else: 0) != 0) {
                        (__ci_expr_logic_11 = (if compare_opcodes(end, utf, ucp, cb, (&list[0] as *mut c_uint), end, (&mut rec_limit as *mut c_int)) != 0: 1 else: 0))
                    }
                    
                    if (__ci_expr_logic_11 != 0) {
                        match c:
                            OP_CRSTAR | OP_CRMINSTAR =>
                                ((unsafe: *repeat_opcode) = 106)
                            OP_CRPLUS | OP_CRMINPLUS =>
                                ((unsafe: *repeat_opcode) = 107)
                            OP_CRQUERY | OP_CRMINQUERY =>
                                ((unsafe: *repeat_opcode) = 108)
                            OP_CRRANGE | OP_CRMINRANGE =>
                                ((unsafe: *repeat_opcode) = 109)
                        
                    }
                    
                    
                }
                
                
                (c = (unsafe: *code))
                
            }
            
        }
        
        
        match c:
            OP_END =>
                return 0
                
                var __ci_expr_logic_12: c_int
                
                if ((if code[1] == OP_PROP: 1 else: 0) != 0) {
                    (__ci_expr_logic_12 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_12 = (if (if code[1] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_12 != 0) {
                    (code = code + 2)
                }
                
                
            OP_TYPESTAR | OP_TYPEMINSTAR | OP_TYPEPLUS | OP_TYPEMINPLUS | OP_TYPEQUERY | OP_TYPEMINQUERY | OP_TYPEPOSSTAR | OP_TYPEPOSPLUS | OP_TYPEPOSQUERY =>
                var __ci_expr_logic_12: c_int
                
                if ((if code[1] == OP_PROP: 1 else: 0) != 0) {
                    (__ci_expr_logic_12 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_12 = (if (if code[1] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_12 != 0) {
                    (code = code + 2)
                }
                
            OP_TYPEUPTO | OP_TYPEMINUPTO | OP_TYPEEXACT | OP_TYPEPOSUPTO =>
                var __ci_expr_logic_13: c_int
                
                if ((if code[(1 + 2)] == OP_PROP: 1 else: 0) != 0) {
                    (__ci_expr_logic_13 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_13 = (if (if code[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_13 != 0) {
                    (code = code + 2)
                }
                
            OP_CALLOUT_STR =>
                (code = code + (((code[(1 + (2 * 2))] << 8) | code[((1 + (2 * 2)) + 1)]) as c_uint))
            OP_XCLASS | OP_ECLASS =>
                (code = code + (((code[1] << 8) | code[(1 + 1)]) as c_uint))
            OP_MARK | OP_COMMIT_ARG | OP_PRUNE_ARG | OP_SKIP_ARG | OP_THEN_ARG =>
                (code = code + code[1])
        
        (code = code + _pcre2_OP_lengths_8[c])
        
        if (utf != 0) {
            match c:
                OP_CHAR | OP_CHARI | OP_NOT | OP_NOTI | OP_STAR | OP_MINSTAR | OP_PLUS | OP_MINPLUS | OP_QUERY | OP_MINQUERY | OP_UPTO | OP_MINUPTO | OP_EXACT | OP_POSSTAR | OP_POSPLUS | OP_POSQUERY | OP_POSUPTO | OP_STARI | OP_MINSTARI | OP_PLUSI | OP_MINPLUSI | OP_QUERYI | OP_MINQUERYI | OP_UPTOI | OP_MINUPTOI | OP_EXACTI | OP_POSSTARI | OP_POSPLUSI | OP_POSQUERYI | OP_POSUPTOI | OP_NOTSTAR | OP_NOTMINSTAR | OP_NOTPLUS | OP_NOTMINPLUS | OP_NOTQUERY | OP_NOTMINQUERY | OP_NOTUPTO | OP_NOTMINUPTO | OP_NOTEXACT | OP_NOTPOSSTAR | OP_NOTPOSPLUS | OP_NOTPOSQUERY | OP_NOTPOSUPTO | OP_NOTSTARI | OP_NOTMINSTARI | OP_NOTPLUSI | OP_NOTMINPLUSI | OP_NOTQUERYI | OP_NOTMINQUERYI | OP_NOTUPTOI | OP_NOTMINUPTOI | OP_NOTEXACTI | OP_NOTPOSSTARI | OP_NOTPOSPLUSI | OP_NOTPOSQUERYI | OP_NOTPOSUPTOI =>
                    if ((if code[-1] >= 192: 1 else: 0) != 0) {
                        (code = code + _pcre2_utf8_table4[(code[-1] & 63)])
                    }
        }
        
    }

}

fn check_char_prop(c: c_uint, ptype: c_uint, pdata: c_uint, negated: c_int) -> c_int {
    var ok: c_int
    
    var rc: c_int
    

    var p: *const c_uint

    var prop: *const ucd_record = ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((c as c_int) / 128)] * 128) + ((c as c_int) % 128))] as isize) as usize))

    match ptype:
        0 =>
            var __ci_expr_logic_1: c_int
            
            var __ci_expr_logic_0: c_int
            
            if ((if prop.chartype == ucp_Lu: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_0 = (if (if prop.chartype == ucp_Ll: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_0 != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_1 = (if (if prop.chartype == ucp_Lt: 1 else: 0) != 0: 1 else: 0))
            }
            
            return (if __ci_expr_logic_1 == negated: 1 else: 0)
            
            
            return (if (if pdata == _pcre2_ucp_gentype_8[prop.chartype]: 1 else: 0) == negated: 1 else: 0)
            
        1 =>
            return (if (if pdata == _pcre2_ucp_gentype_8[prop.chartype]: 1 else: 0) == negated: 1 else: 0)
            
            return (if (if pdata == prop.chartype: 1 else: 0) == negated: 1 else: 0)
            
        2 =>
            return (if (if pdata == prop.chartype: 1 else: 0) == negated: 1 else: 0)
            
            return (if (if pdata == prop.script: 1 else: 0) == negated: 1 else: 0)
            
        3 =>
            return (if (if pdata == prop.script: 1 else: 0) == negated: 1 else: 0)
            
            var __ci_expr_logic_2: c_int
            
            if ((if pdata == prop.script: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if (((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + (((prop.scriptx_bidiclass & 1023) as isize) as usize))[(pdata / 32)] & (1 << (pdata % 32))) != 0: 1 else: 0) != 0: 1 else: 0))
            }
            
            (ok = __ci_expr_logic_2)
            
            
            return (if ok == negated: 1 else: 0)
            
            
        4 =>
            var __ci_expr_logic_2: c_int
            
            if ((if pdata == prop.script: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_2 = (if (if (((&_pcre2_ucd_script_sets_8[0] as *const c_uint) + (((prop.scriptx_bidiclass & 1023) as isize) as usize))[(pdata / 32)] & (1 << (pdata % 32))) != 0: 1 else: 0) != 0: 1 else: 0))
            }
            
            (ok = __ci_expr_logic_2)
            
            
            return (if ok == negated: 1 else: 0)
            
            var __ci_expr_logic_3: c_int
            
            if ((if _pcre2_ucp_gentype_8[prop.chartype] == 1: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 3: 1 else: 0) != 0: 1 else: 0))
            }
            
            return (if __ci_expr_logic_3 == negated: 1 else: 0)
            
            
        5 =>
            var __ci_expr_logic_3: c_int
            
            if ((if _pcre2_ucp_gentype_8[prop.chartype] == 1: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_3 = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 3: 1 else: 0) != 0: 1 else: 0))
            }
            
            return (if __ci_expr_logic_3 == negated: 1 else: 0)
            
            
            match c:
                9 | 32 | 160 | 5760 | 6158 | 8192 | 8193 | 8194 | 8195 | 8196 | 8197 | 8198 | 8199 | 8200 | 8201 | 8202 | 8239 | 8287 | 12288 | 10 | 11 | 12 | 13 | 133 | 8232 | 8233 =>
                    (rc = negated)
                _ =>
                    (rc = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 6: 1 else: 0) == negated: 1 else: 0))
            
            return rc
            
            
        6 | 7 =>
            match c:
                9 | 32 | 160 | 5760 | 6158 | 8192 | 8193 | 8194 | 8195 | 8196 | 8197 | 8198 | 8199 | 8200 | 8201 | 8202 | 8239 | 8287 | 12288 | 10 | 11 | 12 | 13 | 133 | 8232 | 8233 =>
                    (rc = negated)
                _ =>
                    (rc = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 6: 1 else: 0) == negated: 1 else: 0))
            
            return rc
            
            var __ci_expr_logic_5: c_int
            
            var __ci_expr_logic_4: c_int
            
            if ((if _pcre2_ucp_gentype_8[prop.chartype] == 1: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 3: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_4 != 0) {
                (__ci_expr_logic_5 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_5 = (if (if c == 95: 1 else: 0) != 0: 1 else: 0))
            }
            
            return (if __ci_expr_logic_5 == negated: 1 else: 0)
            
            
        8 =>
            var __ci_expr_logic_5: c_int
            
            var __ci_expr_logic_4: c_int
            
            if ((if _pcre2_ucp_gentype_8[prop.chartype] == 1: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_4 = (if (if _pcre2_ucp_gentype_8[prop.chartype] == 3: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_4 != 0) {
                (__ci_expr_logic_5 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_5 = (if (if c == 95: 1 else: 0) != 0: 1 else: 0))
            }
            
            return (if __ci_expr_logic_5 == negated: 1 else: 0)
            
            
            (p = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + ((prop.caseset as isize) as usize))
            
            while true {
                if ((if c < (unsafe: *p): 1 else: 0) != 0) {
                    return (if not (negated != 0): 1 else: 0)
                }
                
                var __ci_expr_old_6: *const c_uint = p
                
                (p = p + 1)
                
                if ((if c == (unsafe: *__ci_expr_old_6): 1 else: 0) != 0) {
                    return negated
                }
                
                
            }
            
            while true {
                if (not (0 != 0)) {
                    break
                }
            }
            
            
        9 =>
            (p = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + ((prop.caseset as isize) as usize))
            
            while true {
                if ((if c < (unsafe: *p): 1 else: 0) != 0) {
                    return (if not (negated != 0): 1 else: 0)
                }
                
                var __ci_expr_old_6: *const c_uint = p
                
                (p = p + 1)
                
                if ((if c == (unsafe: *__ci_expr_old_6): 1 else: 0) != 0) {
                    return negated
                }
                
                
            }
            
            while true {
                if (not (0 != 0)) {
                    break
                }
            }
            
        11 =>
            return 0
            
            return 0
            
        12 =>
            return 0

    return 0

}

fn get_repeat_base(c: u8) -> u8 {
    var __ci_expr_ternary_4: c_int = 0
    
    if ((if c > OP_TYPEPOSUPTO: 1 else: 0) != 0) {
        (__ci_expr_ternary_4 = c)
    } else {
        var __ci_expr_ternary_3: c_int = 0
        
        if ((if c >= OP_TYPESTAR: 1 else: 0) != 0) {
            (__ci_expr_ternary_3 = OP_TYPESTAR)
        } else {
            var __ci_expr_ternary_2: c_int = 0
            
            if ((if c >= OP_NOTSTARI: 1 else: 0) != 0) {
                (__ci_expr_ternary_2 = OP_NOTSTARI)
            } else {
                var __ci_expr_ternary_1: c_int = 0
                
                if ((if c >= OP_NOTSTAR: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = OP_NOTSTAR)
                } else {
                    var __ci_expr_ternary_0: c_int = 0
                    
                    if ((if c >= OP_STARI: 1 else: 0) != 0) {
                        (__ci_expr_ternary_0 = OP_STARI)
                    } else {
                        (__ci_expr_ternary_0 = OP_STAR)
                    }
                    
                    (__ci_expr_ternary_1 = __ci_expr_ternary_0)
                    
                }
                
                (__ci_expr_ternary_2 = __ci_expr_ternary_1)
                
            }
            
            (__ci_expr_ternary_3 = __ci_expr_ternary_2)
            
        }
        
        (__ci_expr_ternary_4 = __ci_expr_ternary_3)
        
    }
    
    return __ci_expr_ternary_4
    

}

fn get_chr_property_list(__param_code: *const u8, utf: c_int, ucp: c_int, fcc: *const u8, list: *mut c_uint) -> *const u8 {
    var code = __param_code
    var c: u8 = (unsafe: *code)

    var base: u8

    var end: *const u8

    var class_end: *const u8

    var chr: c_uint

    var clist_dest: *mut c_uint

    var clist_src: *const c_uint

    (list[0] = c)

    (list[1] = 0)

    (code = code + 1)

    var __ci_expr_logic_0: c_int = 0
    
    if ((if c >= OP_STAR: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if c <= OP_TYPEPOSUPTO: 1 else: 0) != 0: 1 else: 0))
    }
    
    if (__ci_expr_logic_0 != 0) {
        (base = get_repeat_base(c))
        
        (c = c - (base - OP_STAR))
        
        var __ci_expr_logic_3: c_int
        
        var __ci_expr_logic_2: c_int
        
        var __ci_expr_logic_1: c_int
        
        if ((if c == OP_UPTO: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if c == OP_MINUPTO: 1 else: 0) != 0: 1 else: 0))
        }
        
        if (__ci_expr_logic_1 != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if c == OP_EXACT: 1 else: 0) != 0: 1 else: 0))
        }
        
        if (__ci_expr_logic_2 != 0) {
            (__ci_expr_logic_3 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_3 = (if (if c == OP_POSUPTO: 1 else: 0) != 0: 1 else: 0))
        }
        
        if (__ci_expr_logic_3 != 0) {
            (code = code + 2)
        }
        
        
        var __ci_expr_logic_6: c_int = 0
        
        var __ci_expr_logic_5: c_int = 0
        
        var __ci_expr_logic_4: c_int = 0
        
        if ((if c != OP_PLUS: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if (if c != OP_MINPLUS: 1 else: 0) != 0: 1 else: 0))
        }
        
        if (__ci_expr_logic_4 != 0) {
            (__ci_expr_logic_5 = (if (if c != OP_EXACT: 1 else: 0) != 0: 1 else: 0))
        }
        
        if (__ci_expr_logic_5 != 0) {
            (__ci_expr_logic_6 = (if (if c != OP_POSPLUS: 1 else: 0) != 0: 1 else: 0))
        }
        
        (list[1] = __ci_expr_logic_6)
        
        
        match base:
            OP_STAR =>
                (list[0] = 29)
            OP_STARI =>
                (list[0] = 30)
            OP_NOTSTAR =>
                (list[0] = 31)
            OP_NOTSTARI =>
                (list[0] = 32)
            OP_TYPESTAR =>
                (list[0] = (unsafe: *code))
                
                (code = code + 1)
                
        
        (c = list[0])
        
    }
    

    match c:
        OP_NOT_DIGIT | OP_DIGIT | OP_NOT_WHITESPACE | OP_WHITESPACE | OP_NOT_WORDCHAR | OP_WORDCHAR | OP_ANY | OP_ALLANY | OP_ANYNL | OP_NOT_HSPACE | OP_HSPACE | OP_NOT_VSPACE | OP_VSPACE | OP_EXTUNI | OP_EODN | OP_EOD | OP_DOLL | OP_DOLLM =>
            return code
            
            var __ci_expr_old_7: *const u8 = code
            
            (code = code + 1)
            
            (chr = (unsafe: *__ci_expr_old_7))
            
            
            var __ci_expr_logic_8: c_int = 0
            
            if (utf != 0) {
                (__ci_expr_logic_8 = (if (if chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_8 != 0) {
                if ((if (chr & 32) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_9: *const u8 = code
                    
                    (code = code + 1)
                    
                    (chr = ((chr & 31) << 6) | ((unsafe: *__ci_expr_old_9) & 63))
                    
                } else {
                    if ((if (chr & 16) == 0: 1 else: 0) != 0) {
                        (chr = (((chr & 15) << 12) | (((unsafe: *code) & 63) << 6)) | (code[1] & 63))
                        
                        (code = code + 2)
                        
                    } else {
                        if ((if (chr & 8) == 0: 1 else: 0) != 0) {
                            (chr = ((((chr & 7) << 18) | (((unsafe: *code) & 63) << 12)) | ((code[1] & 63) << 6)) | (code[2] & 63))
                            
                            (code = code + 3)
                            
                        } else {
                            if ((if (chr & 4) == 0: 1 else: 0) != 0) {
                                (chr = (((((chr & 3) << 24) | (((unsafe: *code) & 63) << 18)) | ((code[1] & 63) << 12)) | ((code[2] & 63) << 6)) | (code[3] & 63))
                                
                                (code = code + 4)
                                
                            } else {
                                (chr = ((((((chr & 1) << 30) | (((unsafe: *code) & 63) << 24)) | ((code[1] & 63) << 18)) | ((code[2] & 63) << 12)) | ((code[3] & 63) << 6)) | (code[4] & 63))
                                
                                (code = code + 5)
                                
                            }
                        }
                    }
                }
                
            }
            
            
            (list[2] = chr)
            
            (list[3] = 4294967295)
            
            return code
            
            
        OP_CHAR | OP_NOT =>
            var __ci_expr_old_7: *const u8 = code
            
            (code = code + 1)
            
            (chr = (unsafe: *__ci_expr_old_7))
            
            
            var __ci_expr_logic_8: c_int = 0
            
            if (utf != 0) {
                (__ci_expr_logic_8 = (if (if chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_8 != 0) {
                if ((if (chr & 32) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_9: *const u8 = code
                    
                    (code = code + 1)
                    
                    (chr = ((chr & 31) << 6) | ((unsafe: *__ci_expr_old_9) & 63))
                    
                } else {
                    if ((if (chr & 16) == 0: 1 else: 0) != 0) {
                        (chr = (((chr & 15) << 12) | (((unsafe: *code) & 63) << 6)) | (code[1] & 63))
                        
                        (code = code + 2)
                        
                    } else {
                        if ((if (chr & 8) == 0: 1 else: 0) != 0) {
                            (chr = ((((chr & 7) << 18) | (((unsafe: *code) & 63) << 12)) | ((code[1] & 63) << 6)) | (code[2] & 63))
                            
                            (code = code + 3)
                            
                        } else {
                            if ((if (chr & 4) == 0: 1 else: 0) != 0) {
                                (chr = (((((chr & 3) << 24) | (((unsafe: *code) & 63) << 18)) | ((code[1] & 63) << 12)) | ((code[2] & 63) << 6)) | (code[3] & 63))
                                
                                (code = code + 4)
                                
                            } else {
                                (chr = ((((((chr & 1) << 30) | (((unsafe: *code) & 63) << 24)) | ((code[1] & 63) << 18)) | ((code[2] & 63) << 12)) | ((code[3] & 63) << 6)) | (code[4] & 63))
                                
                                (code = code + 5)
                                
                            }
                        }
                    }
                }
                
            }
            
            
            (list[2] = chr)
            
            (list[3] = 4294967295)
            
            return code
            
            var __ci_expr_ternary_10: c_int = 0
            
            if ((if c == OP_CHARI: 1 else: 0) != 0) {
                (__ci_expr_ternary_10 = OP_CHAR)
            } else {
                (__ci_expr_ternary_10 = OP_NOT)
            }
            
            (list[0] = __ci_expr_ternary_10)
            
            
            var __ci_expr_old_11: *const u8 = code
            
            (code = code + 1)
            
            (chr = (unsafe: *__ci_expr_old_11))
            
            
            var __ci_expr_logic_12: c_int = 0
            
            if (utf != 0) {
                (__ci_expr_logic_12 = (if (if chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_12 != 0) {
                if ((if (chr & 32) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_13: *const u8 = code
                    
                    (code = code + 1)
                    
                    (chr = ((chr & 31) << 6) | ((unsafe: *__ci_expr_old_13) & 63))
                    
                } else {
                    if ((if (chr & 16) == 0: 1 else: 0) != 0) {
                        (chr = (((chr & 15) << 12) | (((unsafe: *code) & 63) << 6)) | (code[1] & 63))
                        
                        (code = code + 2)
                        
                    } else {
                        if ((if (chr & 8) == 0: 1 else: 0) != 0) {
                            (chr = ((((chr & 7) << 18) | (((unsafe: *code) & 63) << 12)) | ((code[1] & 63) << 6)) | (code[2] & 63))
                            
                            (code = code + 3)
                            
                        } else {
                            if ((if (chr & 4) == 0: 1 else: 0) != 0) {
                                (chr = (((((chr & 3) << 24) | (((unsafe: *code) & 63) << 18)) | ((code[1] & 63) << 12)) | ((code[2] & 63) << 6)) | (code[3] & 63))
                                
                                (code = code + 4)
                                
                            } else {
                                (chr = ((((((chr & 1) << 30) | (((unsafe: *code) & 63) << 24)) | ((code[1] & 63) << 18)) | ((code[2] & 63) << 12)) | ((code[3] & 63) << 6)) | (code[4] & 63))
                                
                                (code = code + 5)
                                
                            }
                        }
                    }
                }
                
            }
            
            
            (list[2] = chr)
            
            var __ci_expr_logic_16: c_int
            
            if ((if chr < 128: 1 else: 0) != 0) {
                (__ci_expr_logic_16 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_15: c_int = 0
                
                var __ci_expr_logic_14: c_int = 0
                
                if ((if chr < 256: 1 else: 0) != 0) {
                    (__ci_expr_logic_14 = (if (if not (utf != 0): 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_14 != 0) {
                    (__ci_expr_logic_15 = (if (if not (ucp != 0): 1 else: 0) != 0: 1 else: 0))
                }
                
                (__ci_expr_logic_16 = (if __ci_expr_logic_15 != 0: 1 else: 0))
                
            }
            
            if (__ci_expr_logic_16 != 0) {
                (list[3] = fcc[chr])
            } else {
                (list[3] = ((((chr as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((chr as c_int) / 128)] * 128) + ((chr as c_int) % 128))] as isize) as usize)).other_case) as c_uint)))
            }
            
            
            if ((if chr == list[3]: 1 else: 0) != 0) {
                (list[3] = 4294967295)
            } else {
                (list[4] = 4294967295)
            }
            
            return code
            
            
        OP_CHARI | OP_NOTI =>
            var __ci_expr_ternary_10: c_int = 0
            
            if ((if c == OP_CHARI: 1 else: 0) != 0) {
                (__ci_expr_ternary_10 = OP_CHAR)
            } else {
                (__ci_expr_ternary_10 = OP_NOT)
            }
            
            (list[0] = __ci_expr_ternary_10)
            
            
            var __ci_expr_old_11: *const u8 = code
            
            (code = code + 1)
            
            (chr = (unsafe: *__ci_expr_old_11))
            
            
            var __ci_expr_logic_12: c_int = 0
            
            if (utf != 0) {
                (__ci_expr_logic_12 = (if (if chr >= 192: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_12 != 0) {
                if ((if (chr & 32) == 0: 1 else: 0) != 0) {
                    var __ci_expr_old_13: *const u8 = code
                    
                    (code = code + 1)
                    
                    (chr = ((chr & 31) << 6) | ((unsafe: *__ci_expr_old_13) & 63))
                    
                } else {
                    if ((if (chr & 16) == 0: 1 else: 0) != 0) {
                        (chr = (((chr & 15) << 12) | (((unsafe: *code) & 63) << 6)) | (code[1] & 63))
                        
                        (code = code + 2)
                        
                    } else {
                        if ((if (chr & 8) == 0: 1 else: 0) != 0) {
                            (chr = ((((chr & 7) << 18) | (((unsafe: *code) & 63) << 12)) | ((code[1] & 63) << 6)) | (code[2] & 63))
                            
                            (code = code + 3)
                            
                        } else {
                            if ((if (chr & 4) == 0: 1 else: 0) != 0) {
                                (chr = (((((chr & 3) << 24) | (((unsafe: *code) & 63) << 18)) | ((code[1] & 63) << 12)) | ((code[2] & 63) << 6)) | (code[3] & 63))
                                
                                (code = code + 4)
                                
                            } else {
                                (chr = ((((((chr & 1) << 30) | (((unsafe: *code) & 63) << 24)) | ((code[1] & 63) << 18)) | ((code[2] & 63) << 12)) | ((code[3] & 63) << 6)) | (code[4] & 63))
                                
                                (code = code + 5)
                                
                            }
                        }
                    }
                }
                
            }
            
            
            (list[2] = chr)
            
            var __ci_expr_logic_16: c_int
            
            if ((if chr < 128: 1 else: 0) != 0) {
                (__ci_expr_logic_16 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_15: c_int = 0
                
                var __ci_expr_logic_14: c_int = 0
                
                if ((if chr < 256: 1 else: 0) != 0) {
                    (__ci_expr_logic_14 = (if (if not (utf != 0): 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_14 != 0) {
                    (__ci_expr_logic_15 = (if (if not (ucp != 0): 1 else: 0) != 0: 1 else: 0))
                }
                
                (__ci_expr_logic_16 = (if __ci_expr_logic_15 != 0: 1 else: 0))
                
            }
            
            if (__ci_expr_logic_16 != 0) {
                (list[3] = fcc[chr])
            } else {
                (list[3] = ((((chr as c_int) + ((&_pcre2_ucd_records_8[0] as *const ucd_record) + ((_pcre2_ucd_stage2_8[((_pcre2_ucd_stage1_8[((chr as c_int) / 128)] * 128) + ((chr as c_int) % 128))] as isize) as usize)).other_case) as c_uint)))
            }
            
            
            if ((if chr == list[3]: 1 else: 0) != 0) {
                (list[3] = 4294967295)
            } else {
                (list[4] = 4294967295)
            }
            
            return code
            
            if ((if code[0] != 9: 1 else: 0) != 0) {
                (list[2] = code[0])
                
                (list[3] = code[1])
                
                return (code + ((2 as isize) as usize))
                
            }
            
            (clist_src = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + ((code[1] as isize) as usize))
            
            (clist_dest = list + ((2 as isize) as usize))
            
            (code = code + 2)
            
            while true {
                if ((if clist_dest >= (list + ((8 as isize) as usize)): 1 else: 0) != 0) {
                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }
                    
                    (list[2] = code[0])
                    
                    (list[3] = code[1])
                    
                    return code
                    
                }
                
                var __ci_expr_old_18: *mut c_uint = clist_dest
                
                (clist_dest = clist_dest + 1)
                
                ((unsafe: *__ci_expr_old_18) = (unsafe: *clist_src))
                
                var __ci_expr_old_17: *const c_uint = clist_src
                
                (clist_src = clist_src + 1)
                
                if (not ((if (unsafe: *__ci_expr_old_17) != 4294967295: 1 else: 0) != 0)) {
                    break
                }
                
            }
            
            var __ci_expr_ternary_19: c_int = 0
            
            if ((if c == OP_PROP: 1 else: 0) != 0) {
                (__ci_expr_ternary_19 = OP_CHAR)
            } else {
                (__ci_expr_ternary_19 = OP_NOT)
            }
            
            (list[0] = __ci_expr_ternary_19)
            
            
            return code
            
            
        OP_PROP | OP_NOTPROP =>
            if ((if code[0] != 9: 1 else: 0) != 0) {
                (list[2] = code[0])
                
                (list[3] = code[1])
                
                return (code + ((2 as isize) as usize))
                
            }
            
            (clist_src = (&_pcre2_ucd_caseless_sets_8[0] as *const c_uint) + ((code[1] as isize) as usize))
            
            (clist_dest = list + ((2 as isize) as usize))
            
            (code = code + 2)
            
            while true {
                if ((if clist_dest >= (list + ((8 as isize) as usize)): 1 else: 0) != 0) {
                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }
                    
                    (list[2] = code[0])
                    
                    (list[3] = code[1])
                    
                    return code
                    
                }
                
                var __ci_expr_old_18: *mut c_uint = clist_dest
                
                (clist_dest = clist_dest + 1)
                
                ((unsafe: *__ci_expr_old_18) = (unsafe: *clist_src))
                
                var __ci_expr_old_17: *const c_uint = clist_src
                
                (clist_src = clist_src + 1)
                
                if (not ((if (unsafe: *__ci_expr_old_17) != 4294967295: 1 else: 0) != 0)) {
                    break
                }
                
            }
            
            var __ci_expr_ternary_19: c_int = 0
            
            if ((if c == OP_PROP: 1 else: 0) != 0) {
                (__ci_expr_ternary_19 = OP_CHAR)
            } else {
                (__ci_expr_ternary_19 = OP_NOT)
            }
            
            (list[0] = __ci_expr_ternary_19)
            
            
            return code
            
            var __ci_expr_logic_20: c_int
            
            if ((if c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_20 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_20 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_20 != 0) {
                (end = (code + (((code[0] << 8) | code[(0 + 1)]) as c_uint)) - ((1 as isize) as usize))
            } else {
                (end = code + (32 / sizeof[u8]()))
            }
            
            
            (class_end = end)
            
            match (unsafe: *end):
                OP_CRSTAR | OP_CRMINSTAR | OP_CRQUERY | OP_CRMINQUERY | OP_CRPOSSTAR | OP_CRPOSQUERY =>
                    (list[1] = 1)
                    
                    (end = end + 1)
                    
                OP_CRPLUS | OP_CRMINPLUS | OP_CRPOSPLUS =>
                    (end = end + 1)
                OP_CRRANGE | OP_CRMINRANGE | OP_CRPOSRANGE =>
                    (list[1] = (if ((((end[1] << 8) | end[(1 + 1)]) as c_uint)) == 0: 1 else: 0))
                    
                    (end = end + (1 + (2 * 2)))
                    
            
            (list[2] = (((((end as usize) -% (code as usize)) / sizeof[u8]()) as c_uint)))
            
            (list[3] = (((((end as usize) -% (class_end as usize)) / sizeof[u8]()) as c_uint)))
            
            return end
            
            
        OP_NCLASS | OP_CLASS | OP_XCLASS | OP_ECLASS =>
            var __ci_expr_logic_20: c_int
            
            if ((if c == OP_XCLASS: 1 else: 0) != 0) {
                (__ci_expr_logic_20 = (if true: 1 else: 0))
            } else {
                (__ci_expr_logic_20 = (if (if c == OP_ECLASS: 1 else: 0) != 0: 1 else: 0))
            }
            
            if (__ci_expr_logic_20 != 0) {
                (end = (code + (((code[0] << 8) | code[(0 + 1)]) as c_uint)) - ((1 as isize) as usize))
            } else {
                (end = code + (32 / sizeof[u8]()))
            }
            
            
            (class_end = end)
            
            match (unsafe: *end):
                OP_CRSTAR | OP_CRMINSTAR | OP_CRQUERY | OP_CRMINQUERY | OP_CRPOSSTAR | OP_CRPOSQUERY =>
                    (list[1] = 1)
                    
                    (end = end + 1)
                    
                OP_CRPLUS | OP_CRMINPLUS | OP_CRPOSPLUS =>
                    (end = end + 1)
                OP_CRRANGE | OP_CRMINRANGE | OP_CRPOSRANGE =>
                    (list[1] = (if ((((end[1] << 8) | end[(1 + 1)]) as c_uint)) == 0: 1 else: 0))
                    
                    (end = end + (1 + (2 * 2)))
                    
            
            (list[2] = (((((end as usize) -% (code as usize)) / sizeof[u8]()) as c_uint)))
            
            (list[3] = (((((end as usize) -% (class_end as usize)) / sizeof[u8]()) as c_uint)))
            
            return end
            

    return null

}

fn compare_opcodes(__param_code: *const u8, utf: c_int, ucp: c_int, cb: *const compile_block_8, base_list: *const c_uint, base_end: *const u8, rec_limit: *mut c_int) -> c_int {
    var code = __param_code
    var c: u8

    var list: [8]c_uint

    var chr_ptr: *const c_uint

    var ochr_ptr: *const c_uint

    var list_ptr: *const c_uint

    var next_code: *const u8

    var xclass_flags: *const u8

    var class_bitset: *const u8

    var set1: *const u8
    
    var set2: *const u8
    
    var set_end: *const u8
    

    var chr: c_uint

    var accepted: c_int
    
    var invert_bits: c_int
    

    var entered_a_group: c_int = 0

    ((unsafe: *rec_limit) = (unsafe: *rec_limit) - 1)
    
    if ((if (unsafe: *rec_limit) <= 0: 1 else: 0) != 0) {
        return 0
    }
    

    while true {
        var bracode: *const u8
        
        (c = (unsafe: *code))
        
        if ((if c == OP_CALLOUT: 1 else: 0) != 0) {
            (code = code + _pcre2_OP_lengths_8[c])
            
            continue
            
        }
        
        if ((if c == OP_CALLOUT_STR: 1 else: 0) != 0) {
            (code = code + (((code[(1 + (2 * 2))] << 8) | code[((1 + (2 * 2)) + 1)]) as c_uint))
            
            continue
            
        }
        
        if ((if c == OP_ALT: 1 else: 0) != 0) {
            while true {
                (code = code + (((code[1] << 8) | code[(1 + 1)]) as c_uint))
                
                if (not ((if (unsafe: *code) == OP_ALT: 1 else: 0) != 0)) {
                    break
                }
                
            }
            
            (c = (unsafe: *code))
            
        }
        
        match c:
            OP_END =>
                return (if base_list[1] != 0: 1 else: 0)
                
                if ((if base_list[1] == 0: 1 else: 0) != 0) {
                    return 0
                }
                
                (bracode = code - (((code[1] << 8) | code[(1 + 1)]) as c_uint))
                
                match (unsafe: *bracode):
                    OP_CBRA | OP_SCBRA | OP_CBRAPOS | OP_SCBRAPOS =>
                        if (cb.had_recurse != 0) {
                            return 0
                        }
                    OP_SCRIPT_RUN =>
                        var __ci_expr_logic_0: c_int = 0
                        
                        if ((if base_list[0] != 29: 1 else: 0) != 0) {
                            (__ci_expr_logic_0 = (if (if base_list[0] != 30: 1 else: 0) != 0: 1 else: 0))
                        }
                        
                        if (__ci_expr_logic_0 != 0) {
                            return 0
                        }
                        
                    OP_ASSERT | OP_ASSERT_NOT | OP_ONCE =>
                        return (if not (entered_a_group != 0): 1 else: 0)
                        
                        while true {
                            if ((if bracode[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0) {
                                return 0
                            }
                            
                            (bracode = bracode + (((bracode[1] << 8) | bracode[(1 + 1)]) as c_uint))
                            
                            if (not ((if (unsafe: *bracode) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }
                            
                        }
                        
                        return (if not (entered_a_group != 0): 1 else: 0)
                        
                        
                    OP_ASSERTBACK | OP_ASSERTBACK_NOT =>
                        while true {
                            if ((if bracode[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0) {
                                return 0
                            }
                            
                            (bracode = bracode + (((bracode[1] << 8) | bracode[(1 + 1)]) as c_uint))
                            
                            if (not ((if (unsafe: *bracode) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }
                            
                        }
                        
                        return (if not (entered_a_group != 0): 1 else: 0)
                        
                        return 0
                        
                    OP_ASSERT_NA | OP_ASSERTBACK_NA =>
                        return 0
                
                (code = code + _pcre2_OP_lengths_8[c])
                
                continue
                
                
            OP_KET | OP_KETRPOS =>
                if ((if base_list[1] == 0: 1 else: 0) != 0) {
                    return 0
                }
                
                (bracode = code - (((code[1] << 8) | code[(1 + 1)]) as c_uint))
                
                match (unsafe: *bracode):
                    OP_CBRA | OP_SCBRA | OP_CBRAPOS | OP_SCBRAPOS =>
                        if (cb.had_recurse != 0) {
                            return 0
                        }
                    OP_SCRIPT_RUN =>
                        var __ci_expr_logic_0: c_int = 0
                        
                        if ((if base_list[0] != 29: 1 else: 0) != 0) {
                            (__ci_expr_logic_0 = (if (if base_list[0] != 30: 1 else: 0) != 0: 1 else: 0))
                        }
                        
                        if (__ci_expr_logic_0 != 0) {
                            return 0
                        }
                        
                    OP_ASSERT | OP_ASSERT_NOT | OP_ONCE =>
                        return (if not (entered_a_group != 0): 1 else: 0)
                        
                        while true {
                            if ((if bracode[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0) {
                                return 0
                            }
                            
                            (bracode = bracode + (((bracode[1] << 8) | bracode[(1 + 1)]) as c_uint))
                            
                            if (not ((if (unsafe: *bracode) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }
                            
                        }
                        
                        return (if not (entered_a_group != 0): 1 else: 0)
                        
                        
                    OP_ASSERTBACK | OP_ASSERTBACK_NOT =>
                        while true {
                            if ((if bracode[(1 + 2)] == OP_VREVERSE: 1 else: 0) != 0) {
                                return 0
                            }
                            
                            (bracode = bracode + (((bracode[1] << 8) | bracode[(1 + 1)]) as c_uint))
                            
                            if (not ((if (unsafe: *bracode) == OP_ALT: 1 else: 0) != 0)) {
                                break
                            }
                            
                        }
                        
                        return (if not (entered_a_group != 0): 1 else: 0)
                        
                        return 0
                        
                    OP_ASSERT_NA | OP_ASSERTBACK_NA =>
                        return 0
                
                (code = code + _pcre2_OP_lengths_8[c])
                
                continue
                
                (next_code = code + (((code[1] << 8) | code[(1 + 1)]) as c_uint))
                
                (code = code + _pcre2_OP_lengths_8[c])
                
                while ((if (unsafe: *next_code) == OP_ALT: 1 else: 0) != 0) {
                    if ((if not (compare_opcodes(code, utf, ucp, cb, base_list, base_end, rec_limit) != 0): 1 else: 0) != 0) {
                        return 0
                    }
                    
                    (code = (next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))
                    
                    (next_code = next_code + (((next_code[1] << 8) | next_code[(1 + 1)]) as c_uint))
                    
                }
                
                (entered_a_group = 1)
                
                continue
                
                
            OP_ONCE | OP_BRA | OP_CBRA =>
                (next_code = code + (((code[1] << 8) | code[(1 + 1)]) as c_uint))
                
                (code = code + _pcre2_OP_lengths_8[c])
                
                while ((if (unsafe: *next_code) == OP_ALT: 1 else: 0) != 0) {
                    if ((if not (compare_opcodes(code, utf, ucp, cb, base_list, base_end, rec_limit) != 0): 1 else: 0) != 0) {
                        return 0
                    }
                    
                    (code = (next_code + ((1 as isize) as usize)) + ((2 as isize) as usize))
                    
                    (next_code = next_code + (((next_code[1] << 8) | next_code[(1 + 1)]) as c_uint))
                    
                }
                
                (entered_a_group = 1)
                
                continue
                
                (next_code = code + ((1 as isize) as usize))
                
                var __ci_expr_logic_2: c_int = 0
                
                var __ci_expr_logic_1: c_int = 0
                
                if ((if (unsafe: *next_code) != OP_BRA: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if (unsafe: *next_code) != OP_CBRA: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_1 != 0) {
                    (__ci_expr_logic_2 = (if (if (unsafe: *next_code) != OP_ONCE: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_2 != 0) {
                    return 0
                }
                
                
                while true {
                    (next_code = next_code + (((next_code[1] << 8) | next_code[(1 + 1)]) as c_uint))
                    
                    if (not ((if (unsafe: *next_code) == OP_ALT: 1 else: 0) != 0)) {
                        break
                    }
                    
                }
                
                (next_code = next_code + (1 + 2))
                
                if ((if not (compare_opcodes(next_code, utf, ucp, cb, base_list, base_end, rec_limit) != 0): 1 else: 0) != 0) {
                    return 0
                }
                
                (code = code + _pcre2_OP_lengths_8[c])
                
                continue
                
                
            OP_BRAZERO | OP_BRAMINZERO =>
                (next_code = code + ((1 as isize) as usize))
                
                var __ci_expr_logic_2: c_int = 0
                
                var __ci_expr_logic_1: c_int = 0
                
                if ((if (unsafe: *next_code) != OP_BRA: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if (unsafe: *next_code) != OP_CBRA: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_1 != 0) {
                    (__ci_expr_logic_2 = (if (if (unsafe: *next_code) != OP_ONCE: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_2 != 0) {
                    return 0
                }
                
                
                while true {
                    (next_code = next_code + (((next_code[1] << 8) | next_code[(1 + 1)]) as c_uint))
                    
                    if (not ((if (unsafe: *next_code) == OP_ALT: 1 else: 0) != 0)) {
                        break
                    }
                    
                }
                
                (next_code = next_code + (1 + 2))
                
                if ((if not (compare_opcodes(next_code, utf, ucp, cb, base_list, base_end, rec_limit) != 0): 1 else: 0) != 0) {
                    return 0
                }
                
                (code = code + _pcre2_OP_lengths_8[c])
                
                continue
                
        
        (code = get_chr_property_list(code, utf, ucp, cb.fcc, (&list[0] as *mut c_uint)))
        
        if ((if code == null: 1 else: 0) != 0) {
            return 0
        }
        
        if ((if base_list[0] == 29: 1 else: 0) != 0) {
            (chr_ptr = base_list + ((2 as isize) as usize))
            
            (list_ptr = (&list[0] as *const c_uint))
            
        } else {
            if ((if list[0] == 29: 1 else: 0) != 0) {
                (chr_ptr = ((((&list[0] as *mut c_uint) + ((2 as isize) as usize)) as *const c_uint)))
                
                (list_ptr = base_list)
                
            } else {
                var __ci_expr_logic_6: c_int
                
                var __ci_expr_logic_3: c_int
                
                if ((if base_list[0] == 110: 1 else: 0) != 0) {
                    (__ci_expr_logic_3 = (if true: 1 else: 0))
                } else {
                    (__ci_expr_logic_3 = (if (if list[0] == 110: 1 else: 0) != 0: 1 else: 0))
                }
                
                if (__ci_expr_logic_3 != 0) {
                    (__ci_expr_logic_6 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_logic_5: c_int = 0
                    
                    if ((if not (utf != 0): 1 else: 0) != 0) {
                        var __ci_expr_logic_4: c_int
                        
                        if ((if base_list[0] == 111: 1 else: 0) != 0) {
                            (__ci_expr_logic_4 = (if true: 1 else: 0))
                        } else {
                            (__ci_expr_logic_4 = (if (if list[0] == 111: 1 else: 0) != 0: 1 else: 0))
                        }
                        
                        (__ci_expr_logic_5 = (if __ci_expr_logic_4 != 0: 1 else: 0))
                        
                    }
                    
                    (__ci_expr_logic_6 = (if __ci_expr_logic_5 != 0: 1 else: 0))
                    
                }
                
                if (__ci_expr_logic_6 != 0) {
                    var __ci_expr_logic_8: c_int
                    
                    if ((if base_list[0] == 110: 1 else: 0) != 0) {
                        (__ci_expr_logic_8 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_7: c_int = 0
                        
                        if ((if not (utf != 0): 1 else: 0) != 0) {
                            (__ci_expr_logic_7 = (if (if base_list[0] == 111: 1 else: 0) != 0: 1 else: 0))
                        }
                        
                        (__ci_expr_logic_8 = (if __ci_expr_logic_7 != 0: 1 else: 0))
                        
                    }
                    
                    if (__ci_expr_logic_8 != 0) {
                        (set1 = base_end - base_list[2])
                        
                        (list_ptr = (&list[0] as *const c_uint))
                        
                    } else {
                        (set1 = code - list[2])
                        
                        (list_ptr = base_list)
                        
                    }
                    
                    
                    (invert_bits = 0)
                    
                    match list_ptr[0]:
                        110 | 111 =>
                            var __ci_expr_ternary_9: *const u8 = null
                            
                            if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                                (__ci_expr_ternary_9 = code)
                            } else {
                                (__ci_expr_ternary_9 = base_end)
                            }
                            
                            (set2 = __ci_expr_ternary_9 - list_ptr[2])
                            
                        112 =>
                            var __ci_expr_ternary_10: *const u8 = null
                            
                            if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                                (__ci_expr_ternary_10 = code)
                            } else {
                                (__ci_expr_ternary_10 = base_end)
                            }
                            
                            (xclass_flags = (__ci_expr_ternary_10 - list_ptr[2]) + ((2 as isize) as usize))
                            
                            
                            if ((if ((unsafe: *xclass_flags) & 4) != 0: 1 else: 0) != 0) {
                                return 0
                            }
                            
                            if ((if ((unsafe: *xclass_flags) & 2) == 0: 1 else: 0) != 0) {
                                if ((if list[1] == 0: 1 else: 0) != 0) {
                                    return (if ((unsafe: *xclass_flags) & 1) == 0: 1 else: 0)
                                }
                                
                                continue
                                
                            }
                            
                            (set2 = xclass_flags + ((1 as isize) as usize))
                            
                        6 =>
                            (invert_bits = 1)
                            
                            (set2 = cb.cbits + ((64 as isize) as usize))
                            
                        7 =>
                            (set2 = cb.cbits + ((64 as isize) as usize))
                        8 =>
                            (invert_bits = 1)
                            
                            (set2 = cb.cbits + ((0 as isize) as usize))
                            
                        9 =>
                            (set2 = cb.cbits + ((0 as isize) as usize))
                        10 =>
                            (invert_bits = 1)
                            
                            (set2 = cb.cbits + ((160 as isize) as usize))
                            
                        11 =>
                            (set2 = cb.cbits + ((160 as isize) as usize))
                        _ =>
                            return 0
                    
                    (set_end = set1 + ((32 as isize) as usize))
                    
                    if (invert_bits != 0) {
                        while true {
                            var __ci_expr_old_11: *const u8 = set1
                            
                            (set1 = set1 + 1)
                            
                            var __ci_expr_old_12: *const u8 = set2
                            
                            (set2 = set2 + 1)
                            
                            if ((if ((unsafe: *__ci_expr_old_11) & (~(unsafe: *__ci_expr_old_12))) != 0: 1 else: 0) != 0) {
                                return 0
                            }
                            
                            if (not ((if set1 < set_end: 1 else: 0) != 0)) {
                                break
                            }
                            
                        }
                        
                    } else {
                        while true {
                            var __ci_expr_old_13: *const u8 = set1
                            
                            (set1 = set1 + 1)
                            
                            var __ci_expr_old_14: *const u8 = set2
                            
                            (set2 = set2 + 1)
                            
                            if ((if ((unsafe: *__ci_expr_old_13) & (unsafe: *__ci_expr_old_14)) != 0: 1 else: 0) != 0) {
                                return 0
                            }
                            
                            if (not ((if set1 < set_end: 1 else: 0) != 0)) {
                                break
                            }
                            
                        }
                        
                    }
                    
                    if ((if list[1] == 0: 1 else: 0) != 0) {
                        return 1
                    }
                    
                    continue
                    
                } else {
                    var leftop: c_uint
                    
                    var rightop: c_uint
                    
                    
                    (leftop = base_list[0])
                    
                    (rightop = list[0])
                    
                    (accepted = 0)
                    
                    var __ci_expr_logic_15: c_int
                    
                    if ((if leftop == 16: 1 else: 0) != 0) {
                        (__ci_expr_logic_15 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_15 = (if (if leftop == 15: 1 else: 0) != 0: 1 else: 0))
                    }
                    
                    if (__ci_expr_logic_15 != 0) {
                        if ((if rightop == 24: 1 else: 0) != 0) {
                            (accepted = 1)
                        } else {
                            var __ci_expr_logic_16: c_int
                            
                            if ((if rightop == 16: 1 else: 0) != 0) {
                                (__ci_expr_logic_16 = (if true: 1 else: 0))
                            } else {
                                (__ci_expr_logic_16 = (if (if rightop == 15: 1 else: 0) != 0: 1 else: 0))
                            }
                            
                            if (__ci_expr_logic_16 != 0) {
                                var n: c_int
                                
                                var p: *const u8
                                
                                var same: c_int = (if leftop == rightop: 1 else: 0)
                                
                                var lisprop: c_int = (if leftop == 16: 1 else: 0)
                                
                                var risprop: c_int = (if rightop == 16: 1 else: 0)
                                
                                var bothprop: c_int = with 0 as __ci_expr_seq_347 {
                                    var __ci_expr_logic_17: c_int = 0
                                    if (lisprop != 0) {
                                        (__ci_expr_logic_17 = (if risprop != 0: 1 else: 0))
                                    }
                                    __ci_expr_logic_17
                                }
                                
                                (n = propposstab[base_list[2]][list[2]])
                                
                                match n:
                                    0 =>
                                        (accepted = bothprop)
                                    1 =>
                                        (accepted = bothprop)
                                    2 =>
                                        (accepted = (if (if base_list[3] == list[3]: 1 else: 0) != same: 1 else: 0))
                                    3 =>
                                        (accepted = (if not (same != 0): 1 else: 0))
                                    4 =>
                                        var __ci_expr_logic_18: c_int = 0
                                        
                                        if (risprop != 0) {
                                            (__ci_expr_logic_18 = (if (if catposstab[base_list[3]][list[3]] == same: 1 else: 0) != 0: 1 else: 0))
                                        }
                                        
                                        (accepted = __ci_expr_logic_18)
                                        
                                    5 =>
                                        var __ci_expr_logic_19: c_int = 0
                                        
                                        if (lisprop != 0) {
                                            (__ci_expr_logic_19 = (if (if catposstab[list[3]][base_list[3]] == same: 1 else: 0) != 0: 1 else: 0))
                                        }
                                        
                                        (accepted = __ci_expr_logic_19)
                                        
                                    6 | 7 | 8 =>
                                        (p = (&posspropstab[(n - 6)][0] as *const u8))
                                        
                                        var __ci_expr_logic_23: c_int = 0
                                        
                                        if (risprop != 0) {
                                            var __ci_expr_logic_22: c_int = 0
                                            
                                            var __ci_expr_logic_20: c_int = 0
                                            
                                            if ((if list[3] != p[0]: 1 else: 0) != 0) {
                                                (__ci_expr_logic_20 = (if (if list[3] != p[1]: 1 else: 0) != 0: 1 else: 0))
                                            }
                                            
                                            if (__ci_expr_logic_20 != 0) {
                                                var __ci_expr_logic_21: c_int
                                                
                                                if ((if list[3] != p[2]: 1 else: 0) != 0) {
                                                    (__ci_expr_logic_21 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_21 = (if (if not (lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                }
                                                
                                                (__ci_expr_logic_22 = (if __ci_expr_logic_21 != 0: 1 else: 0))
                                                
                                            }
                                            
                                            (__ci_expr_logic_23 = (if (if lisprop == __ci_expr_logic_22: 1 else: 0) != 0: 1 else: 0))
                                            
                                        }
                                        
                                        (accepted = __ci_expr_logic_23)
                                        
                                        
                                    9 | 10 | 11 =>
                                        (p = (&posspropstab[(n - 9)][0] as *const u8))
                                        
                                        var __ci_expr_logic_27: c_int = 0
                                        
                                        if (lisprop != 0) {
                                            var __ci_expr_logic_26: c_int = 0
                                            
                                            var __ci_expr_logic_24: c_int = 0
                                            
                                            if ((if base_list[3] != p[0]: 1 else: 0) != 0) {
                                                (__ci_expr_logic_24 = (if (if base_list[3] != p[1]: 1 else: 0) != 0: 1 else: 0))
                                            }
                                            
                                            if (__ci_expr_logic_24 != 0) {
                                                var __ci_expr_logic_25: c_int
                                                
                                                if ((if base_list[3] != p[2]: 1 else: 0) != 0) {
                                                    (__ci_expr_logic_25 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_25 = (if (if not (risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                }
                                                
                                                (__ci_expr_logic_26 = (if __ci_expr_logic_25 != 0: 1 else: 0))
                                                
                                            }
                                            
                                            (__ci_expr_logic_27 = (if (if risprop == __ci_expr_logic_26: 1 else: 0) != 0: 1 else: 0))
                                            
                                        }
                                        
                                        (accepted = __ci_expr_logic_27)
                                        
                                        
                                    12 | 13 | 14 =>
                                        (p = (&posspropstab[(n - 12)][0] as *const u8))
                                        
                                        var __ci_expr_logic_31: c_int = 0
                                        
                                        if (risprop != 0) {
                                            var __ci_expr_logic_30: c_int = 0
                                            
                                            var __ci_expr_logic_28: c_int = 0
                                            
                                            if (catposstab[p[0]][list[3]] != 0) {
                                                (__ci_expr_logic_28 = (if catposstab[p[1]][list[3]] != 0: 1 else: 0))
                                            }
                                            
                                            if (__ci_expr_logic_28 != 0) {
                                                var __ci_expr_logic_29: c_int
                                                
                                                if ((if list[3] != p[3]: 1 else: 0) != 0) {
                                                    (__ci_expr_logic_29 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_29 = (if (if not (lisprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                }
                                                
                                                (__ci_expr_logic_30 = (if __ci_expr_logic_29 != 0: 1 else: 0))
                                                
                                            }
                                            
                                            (__ci_expr_logic_31 = (if (if lisprop == __ci_expr_logic_30: 1 else: 0) != 0: 1 else: 0))
                                            
                                        }
                                        
                                        (accepted = __ci_expr_logic_31)
                                        
                                        
                                    15 | 16 | 17 =>
                                        (p = (&posspropstab[(n - 15)][0] as *const u8))
                                        
                                        var __ci_expr_logic_35: c_int = 0
                                        
                                        if (lisprop != 0) {
                                            var __ci_expr_logic_34: c_int = 0
                                            
                                            var __ci_expr_logic_32: c_int = 0
                                            
                                            if (catposstab[p[0]][base_list[3]] != 0) {
                                                (__ci_expr_logic_32 = (if catposstab[p[1]][base_list[3]] != 0: 1 else: 0))
                                            }
                                            
                                            if (__ci_expr_logic_32 != 0) {
                                                var __ci_expr_logic_33: c_int
                                                
                                                if ((if base_list[3] != p[3]: 1 else: 0) != 0) {
                                                    (__ci_expr_logic_33 = (if true: 1 else: 0))
                                                } else {
                                                    (__ci_expr_logic_33 = (if (if not (risprop != 0): 1 else: 0) != 0: 1 else: 0))
                                                }
                                                
                                                (__ci_expr_logic_34 = (if __ci_expr_logic_33 != 0: 1 else: 0))
                                                
                                            }
                                            
                                            (__ci_expr_logic_35 = (if (if risprop == __ci_expr_logic_34: 1 else: 0) != 0: 1 else: 0))
                                            
                                        }
                                        
                                        (accepted = __ci_expr_logic_35)
                                        
                                        
                                
                            }
                            
                        }
                        
                    } else {
                        var __ci_expr_logic_39: c_int = 0
                        
                        var __ci_expr_logic_38: c_int = 0
                        
                        var __ci_expr_logic_37: c_int = 0
                        
                        var __ci_expr_logic_36: c_int = 0
                        
                        if ((if leftop >= 6: 1 else: 0) != 0) {
                            (__ci_expr_logic_36 = (if (if leftop <= 22: 1 else: 0) != 0: 1 else: 0))
                        }
                        
                        if (__ci_expr_logic_36 != 0) {
                            (__ci_expr_logic_37 = (if (if rightop >= 6: 1 else: 0) != 0: 1 else: 0))
                        }
                        
                        if (__ci_expr_logic_37 != 0) {
                            (__ci_expr_logic_38 = (if (if rightop <= 26: 1 else: 0) != 0: 1 else: 0))
                        }
                        
                        if (__ci_expr_logic_38 != 0) {
                            (__ci_expr_logic_39 = (if autoposstab[(leftop -% 6)][(rightop -% 6)] != 0: 1 else: 0))
                        }
                        
                        (accepted = __ci_expr_logic_39)
                        
                    }
                    
                    
                    if ((if not (accepted != 0): 1 else: 0) != 0) {
                        return 0
                    }
                    
                    if ((if list[1] == 0: 1 else: 0) != 0) {
                        return 1
                    }
                    
                    continue
                    
                }
                
            }
        }
        
        while true {
            (chr = (unsafe: *chr_ptr))
            
            match list_ptr[0]:
                29 =>
                    (ochr_ptr = list_ptr + ((2 as isize) as usize))
                    
                    while true {
                        if ((if chr == (unsafe: *ochr_ptr): 1 else: 0) != 0) {
                            return 0
                        }
                        
                        (ochr_ptr = ochr_ptr + 1)
                        
                        if (not ((if (unsafe: *ochr_ptr) != 4294967295: 1 else: 0) != 0)) {
                            break
                        }
                        
                    }
                    
                31 =>
                    (ochr_ptr = list_ptr + ((2 as isize) as usize))
                    
                    while true {
                        if ((if chr == (unsafe: *ochr_ptr): 1 else: 0) != 0) {
                            break
                        }
                        
                        (ochr_ptr = ochr_ptr + 1)
                        
                        if (not ((if (unsafe: *ochr_ptr) != 4294967295: 1 else: 0) != 0)) {
                            break
                        }
                        
                    }
                    
                    if ((if (unsafe: *ochr_ptr) == 4294967295: 1 else: 0) != 0) {
                        return 0
                    }
                    
                7 =>
                    var __ci_expr_logic_40: c_int = 0
                    
                    if ((if chr < 256: 1 else: 0) != 0) {
                        (__ci_expr_logic_40 = (if (if (cb.ctypes[chr] & 8) != 0: 1 else: 0) != 0: 1 else: 0))
                    }
                    
                    if (__ci_expr_logic_40 != 0) {
                        return 0
                    }
                    
                6 =>
                    var __ci_expr_logic_41: c_int
                    
                    if ((if chr > 255: 1 else: 0) != 0) {
                        (__ci_expr_logic_41 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_41 = (if (if (cb.ctypes[chr] & 8) == 0: 1 else: 0) != 0: 1 else: 0))
                    }
                    
                    if (__ci_expr_logic_41 != 0) {
                        return 0
                    }
                    
                9 =>
                    var __ci_expr_logic_42: c_int = 0
                    
                    if ((if chr < 256: 1 else: 0) != 0) {
                        (__ci_expr_logic_42 = (if (if (cb.ctypes[chr] & 1) != 0: 1 else: 0) != 0: 1 else: 0))
                    }
                    
                    if (__ci_expr_logic_42 != 0) {
                        return 0
                    }
                    
                8 =>
                    var __ci_expr_logic_43: c_int
                    
                    if ((if chr > 255: 1 else: 0) != 0) {
                        (__ci_expr_logic_43 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_43 = (if (if (cb.ctypes[chr] & 1) == 0: 1 else: 0) != 0: 1 else: 0))
                    }
                    
                    if (__ci_expr_logic_43 != 0) {
                        return 0
                    }
                    
                11 =>
                    var __ci_expr_logic_44: c_int = 0
                    
                    if ((if chr < 255: 1 else: 0) != 0) {
                        (__ci_expr_logic_44 = (if (if (cb.ctypes[chr] & 16) != 0: 1 else: 0) != 0: 1 else: 0))
                    }
                    
                    if (__ci_expr_logic_44 != 0) {
                        return 0
                    }
                    
                10 =>
                    var __ci_expr_logic_45: c_int
                    
                    if ((if chr > 255: 1 else: 0) != 0) {
                        (__ci_expr_logic_45 = (if true: 1 else: 0))
                    } else {
                        (__ci_expr_logic_45 = (if (if (cb.ctypes[chr] & 16) == 0: 1 else: 0) != 0: 1 else: 0))
                    }
                    
                    if (__ci_expr_logic_45 != 0) {
                        return 0
                    }
                    
                19 =>
                    match chr:
                        9 | 32 | 160 | 5760 | 6158 | 8192 | 8193 | 8194 | 8195 | 8196 | 8197 | 8198 | 8199 | 8200 | 8201 | 8202 | 8239 | 8287 | 12288 =>
                            return 0
                18 =>
                    match chr:
                        9 | 32 | 160 | 5760 | 6158 | 8192 | 8193 | 8194 | 8195 | 8196 | 8197 | 8198 | 8199 | 8200 | 8201 | 8202 | 8239 | 8287 | 12288 =>
                            return 0
                        _ =>
                            return 0
                17 | 21 =>
                    match chr:
                        10 | 11 | 12 | 13 | 133 | 8232 | 8233 =>
                            return 0
                20 =>
                    match chr:
                        10 | 11 | 12 | 13 | 133 | 8232 | 8233 =>
                            return 0
                        _ =>
                            return 0
                25 | 23 =>
                    match chr:
                        13 | 10 | 11 | 12 | 133 | 8232 | 8233 =>
                            return 0
                24 =>
                    if ((if not (check_char_prop(chr, list_ptr[2], list_ptr[3], (if list_ptr[0] == 15: 1 else: 0)) != 0): 1 else: 0) != 0) {
                        return 0
                    }
                16 | 15 =>
                    if ((if not (check_char_prop(chr, list_ptr[2], list_ptr[3], (if list_ptr[0] == 15: 1 else: 0)) != 0): 1 else: 0) != 0) {
                        return 0
                    }
                111 =>
                    if ((if chr > 255: 1 else: 0) != 0) {
                        return 0
                    }
                    
                    if ((if chr > 255: 1 else: 0) != 0) {
                        break
                    }
                    
                    var __ci_expr_ternary_46: *const u8 = null
                    
                    if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                        (__ci_expr_ternary_46 = code)
                    } else {
                        (__ci_expr_ternary_46 = base_end)
                    }
                    
                    (class_bitset = __ci_expr_ternary_46 - list_ptr[2])
                    
                    
                    if ((if (class_bitset[(chr >> 3)] & (1 << (chr & 7))) != 0: 1 else: 0) != 0) {
                        return 0
                    }
                    
                    
                110 =>
                    if ((if chr > 255: 1 else: 0) != 0) {
                        break
                    }
                    
                    var __ci_expr_ternary_46: *const u8 = null
                    
                    if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                        (__ci_expr_ternary_46 = code)
                    } else {
                        (__ci_expr_ternary_46 = base_end)
                    }
                    
                    (class_bitset = __ci_expr_ternary_46 - list_ptr[2])
                    
                    
                    if ((if (class_bitset[(chr >> 3)] & (1 << (chr & 7))) != 0: 1 else: 0) != 0) {
                        return 0
                    }
                    
                112 =>
                    var __ci_expr_ternary_47: *const u8 = null
                    
                    if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                        (__ci_expr_ternary_47 = code)
                    } else {
                        (__ci_expr_ternary_47 = base_end)
                    }
                    
                    if (_pcre2_xclass_8(chr, ((__ci_expr_ternary_47 - list_ptr[2]) + ((2 as isize) as usize)), (cb.start_code as *const u8), utf) != 0) {
                        return 0
                    }
                    
                113 =>
                    var __ci_expr_ternary_48: *const u8 = null
                    
                    if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                        (__ci_expr_ternary_48 = code)
                    } else {
                        (__ci_expr_ternary_48 = base_end)
                    }
                    
                    var __ci_expr_ternary_49: *const u8 = null
                    
                    if ((if list_ptr == (&list[0] as *const c_uint): 1 else: 0) != 0) {
                        (__ci_expr_ternary_49 = code)
                    } else {
                        (__ci_expr_ternary_49 = base_end)
                    }
                    
                    if (_pcre2_eclass_8(chr, ((__ci_expr_ternary_48 - list_ptr[2]) + ((2 as isize) as usize)), (__ci_expr_ternary_49 - list_ptr[3]), (cb.start_code as *const u8), utf) != 0) {
                        return 0
                    }
                    
                _ =>
                    return 0
            
            (chr_ptr = chr_ptr + 1)
            
            if (not ((if (unsafe: *chr_ptr) != 4294967295: 1 else: 0) != 0)) {
                break
            }
            
        }
        
        if ((if list[1] == 0: 1 else: 0) != 0) {
            return 1
        }
        
    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    return 0

}

