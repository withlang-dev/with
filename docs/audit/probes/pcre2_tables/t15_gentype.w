use std.libc
use std.re.defs
use std.re.pcre2_context

// T15b: gentype at true chartype indices (Lu=9, Mn=12, Nd=13, Po=21, Zs=29).
fn main:
    printf(c"gentype_Lu9=%d\n".ptr, (_pcre2_ucp_gentype_8[9] as i32))
    printf(c"gentype_Mn12=%d\n".ptr, (_pcre2_ucp_gentype_8[12] as i32))
    printf(c"gentype_Nd13=%d\n".ptr, (_pcre2_ucp_gentype_8[13] as i32))
    printf(c"gentype_Po21=%d\n".ptr, (_pcre2_ucp_gentype_8[21] as i32))
    printf(c"gentype_Zl27=%d\n".ptr, (_pcre2_ucp_gentype_8[27] as i32))
    printf(c"ucp_Lu=%d ucp_Nd=%d ucp_Zs=%d\n".ptr, (ucp_Lu as i32), (ucp_Nd as i32), (ucp_Zs as i32))
