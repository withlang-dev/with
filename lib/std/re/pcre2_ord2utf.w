// Migrated from PCRE2
use std.re.defs

fn _pcre2_ord2utf_8(__param_cvalue: c_uint, __param_buffer: *mut u8) -> c_uint {
    var cvalue = __param_cvalue
    var buffer = __param_buffer
    var i: c_uint

    (i = 0)
    
    while ((if i < _pcre2_utf8_table1_size: 1 else: 0) != 0) {
        if ((if ((cvalue as c_int)) <= _pcre2_utf8_table1[i]: 1 else: 0) != 0) {
            break
        }
        
        (i = i + 1)
        
    }
    

    (buffer = buffer + i)

    var j: c_uint = i
    
    while ((if j != 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *mut u8 = buffer
        
        (buffer = buffer - 1)
        
        ((unsafe: *__ci_expr_old_0) = 128 | (cvalue & 63))
        
        
        (cvalue = cvalue >> 6)
        
        
        (j = j - 1)
        
    }
    

    ((unsafe: *buffer) = (((_pcre2_utf8_table2[i] | (cvalue as c_int)) as u8)))

    return (i +% 1)

}

