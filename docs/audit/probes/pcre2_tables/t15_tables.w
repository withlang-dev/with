use std.libc
use std.re.defs
use std.re.pcre2_context

// T15: spot-check default-table + utf8-table fidelity against known facts.
fn main:
    printf(c"fold_A_to_a=%d\n".ptr, (_pcre2_default_tables_8[65] as i32))
    printf(c"fold_a_to_A=%d\n".ptr, (_pcre2_default_tables_8[353] as i32))
    printf(c"fold_B_to_b=%d\n".ptr, (_pcre2_default_tables_8[66] as i32))
    printf(c"id0=%d\n".ptr, (_pcre2_default_tables_8[0] as i32))
    printf(c"digit0_bit=%d\n".ptr, ((_pcre2_default_tables_8[582] & 1) as i32))
    printf(c"space_bit=%d\n".ptr, ((_pcre2_default_tables_8[516] & 1) as i32))
    printf(c"upperA_bit=%d\n".ptr, ((_pcre2_default_tables_8[616] & 2) as i32))
    printf(c"lowera_bit=%d\n".ptr, ((_pcre2_default_tables_8[652] & 2) as i32))
    printf(c"utf8t1_0=%d\n".ptr, _pcre2_utf8_table1[0])
    printf(c"utf8t1_5=%d\n".ptr, _pcre2_utf8_table1[5])
    printf(c"utf8t2_1=%d\n".ptr, _pcre2_utf8_table2[1])
    printf(c"utf8t3_0=%d\n".ptr, _pcre2_utf8_table3[0])
    printf(c"gentype_Lo=%d\n".ptr, (_pcre2_ucp_gentype_8[5] as i32))
    printf(c"gentype_Nd=%d\n".ptr, (_pcre2_ucp_gentype_8[9] as i32))
    printf(c"gentype_Zs=%d\n".ptr, (_pcre2_ucp_gentype_8[23] as i32))
    printf(c"gentype_last=%d\n".ptr, (_pcre2_ucp_gentype_8[29] as i32))
    printf(c"stage1_0=%d\n".ptr, (_pcre2_ucd_stage1_8[0] as i32))
