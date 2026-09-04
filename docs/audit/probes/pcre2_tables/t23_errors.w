use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_config
use std.re.pcre2_pattern_info
use std.re.pcre2_serialize

// T23: null-arg / bad-option error paths (no heap, no valid pointers needed).
unsafe fn main:
    printf(c"config_bad_what=%d\n".ptr, pcre2_config_8((9999 as c_uint), null))
    printf(c"config_sizeq0=%d\n".ptr, pcre2_config_8((0 as c_uint), null))
    printf(c"patinfo_null_null=%d\n".ptr, pcre2_pattern_info_8(null, (0 as c_uint), null))
    printf(c"patinfo_bad_what=%d\n".ptr, pcre2_pattern_info_8(null, (9999 as c_uint), null))
    printf(c"ser_null=%d\n".ptr, pcre2_serialize_get_number_of_codes_8(null))
