// compile_fuzz — read-only fuzz probe for the migrated pcre2 compile half.
// Exercises pcre2_compile_8 (+ cgroup/class helpers, find_bracket,
// auto_possess, chkdint, error) with tricky VALID patterns (nested groups,
// backrefs, lookaround, counted repeats, classes, possessives, conditionals,
// named groups) and INVALID patterns (expect loud failure + code).
// Prints one line per case; compare match lines against pcre2test oracle.

use std.re.defs
use std.re.pcre2_tables
use std.re.pcre2_ucd
use std.re.pcre2_chartables
use std.re.pcre2_string_utils
use std.re.pcre2_newline
use std.re.pcre2_valid_utf
use std.re.pcre2_ord2utf
use std.re.pcre2_extuni
use std.re.pcre2_find_bracket
use std.re.pcre2_context
use std.re.pcre2_error
use std.re.pcre2_auto_possess
use std.re.pcre2_study
use std.re.pcre2_xclass
use std.re.pcre2_chkdint
use std.re.pcre2_compile_class
use std.re.pcre2_compile_cgroup
use std.re.pcre2_compile
use std.re.pcre2_config
use std.re.pcre2_match_data
use std.re.pcre2_match_next
use std.re.pcre2_match
use std.re.pcre2_dfa_match
use std.re.pcre2_substitute
use std.re.pcre2_substring
use std.re.pcre2_pattern_info
use std.re.pcre2_serialize
use std.re.pcre2_convert
use std.re.pcre2_script_run
use std.re.pcre2_maketables

unsafe fn run_case(tag: str, pattern: str, subject: str, gcontext: *mut pcre2_real_general_context_8, ccontext: *mut pcre2_real_compile_context_8):
    var error_code: c_int = 0
    var error_offset: c_ulong = 0
    let code = pcre2_compile_8(
        (pattern as *const u8),
        pattern.len() as c_ulong,
        0 as c_uint,
        (&raw mut error_code as *mut c_int),
        (&raw mut error_offset as *mut c_ulong),
        ccontext
    )
    if code as i64 == 0:
        var err_msg: [256]u8
        pcre2_get_error_message_8(error_code, (&raw mut err_msg[0] as *mut u8), 256 as c_ulong)
        print(f"CASE {tag} COMPILE_FAIL code={error_code} off={error_offset} subjlen={subject.len()}\n")
        return
    let mcontext = pcre2_match_context_create_8(gcontext)
    let md = pcre2_match_data_create_from_pattern_8(code, gcontext)
    if (md as i64) == 0:
        print(f"CASE {tag} COMPILE_OK mdnull subjlen={subject.len()}\n")
        pcre2_match_context_free_8(mcontext)
        pcre2_code_free_8(code)
        return
    let rc = pcre2_match_8(
        code,
        (subject as *const u8),
        subject.len() as c_ulong,
        0 as c_ulong,
        0 as c_uint,
        md,
        mcontext
    )
    if rc < 0:
        print(f"CASE {tag} COMPILE_OK MATCH rc={rc} subjlen={subject.len()}\n")
    else:
        let ov = pcre2_get_ovector_pointer_8(md)
        var i: c_uint = 0
        let group_count = rc as c_uint
        while i < group_count:
            let start = unsafe *(ov + ((i * 2) as isize))
            let end_pos = unsafe *(ov + ((i * 2 + 1) as isize))
            if start == (0 -% 1) as c_ulong:
                print(f"CASE {tag} COMPILE_OK MATCH rc={rc} g{i}=unset\n")
            else:
                let matched = subject.slice(start as i64, end_pos as i64)
                print(f"CASE {tag} COMPILE_OK MATCH rc={rc} g{i}=[{start},{end_pos}) s={matched}\n")
            i = i + 1
    pcre2_match_data_free_8(md)
    pcre2_match_context_free_8(mcontext)
    pcre2_code_free_8(code)

fn main:
    unsafe {
        let gcontext = pcre2_general_context_create_8(null, null, null)
        if (gcontext as i64) == 0:
            print("FATAL gcontext null\n")
        let ccontext = pcre2_compile_context_create_8(gcontext)
        if (ccontext as i64) == 0:
            print("FATAL ccontext null\n")
        (ccontext.max_pattern_length = (0 -% 1) as c_ulong)
        (ccontext.max_pattern_compiled_length = (0 -% 1) as c_ulong)
        (ccontext.parens_nest_limit = 250)
        (ccontext.max_varlookbehind = 255)
        (ccontext.newline_convention = 2)
        (ccontext.bsr_convention = 0)
        (ccontext.optimization_flags = 4294967295)
        let tables = pcre2_maketables_8(gcontext)
        (ccontext.tables = tables)
        // Tricky valid patterns
        run_case("nested", "((a)(b(c)))", "abc", gcontext, ccontext)
        run_case("backref-hit", "(a|b)\\1", "aa", gcontext, ccontext)
        run_case("backref-miss", "(a|b)\\1", "ab", gcontext, ccontext)
        run_case("lookahead", "(?=abc)abc", "abc", gcontext, ccontext)
        run_case("neglookahead", "(?!foo)bar", "bar", gcontext, ccontext)
        run_case("lookbehind", "(?<=ab)c", "abc", gcontext, ccontext)
        run_case("count", "a{64}", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", gcontext, ccontext)
        run_case("countrange", "x{1,200}", "xxxx", gcontext, ccontext)
        run_case("class", "[a-z]+", "hello", gcontext, ccontext)
        run_case("negclass", "[^abc]+", "xyz", gcontext, ccontext)
        run_case("posixclass", "[[:alpha:]]+", "hello", gcontext, ccontext)
        run_case("alt", "(a|b)*abb", "aababb", gcontext, ccontext)
        run_case("nongreedy", "a+?b", "aaab", gcontext, ccontext)
        run_case("named", "(?<word>ab)c", "abc", gcontext, ccontext)
        run_case("namedref", "(?<w>a|b)k(?P=w)", "aka", gcontext, ccontext)
        run_case("possessive", "a++b", "aaab", gcontext, ccontext)
        run_case("atomic", "(?>a+)b", "aaab", gcontext, ccontext)
        run_case("cond-hit", "(a)?(?(1)b|c)", "ab", gcontext, ccontext)
        run_case("cond-else", "(a)?(?(1)b|c)", "c", gcontext, ccontext)
        run_case("anchors", "^\\d{3}-\\d{4}$", "123-4567", gcontext, ccontext)
        run_case("deep10", "((((((((((a))))))))))", "a", gcontext, ccontext)
        run_case("empty", "", "", gcontext, ccontext)
        // Invalid patterns: must fail loud with codes
        run_case("bad-unclosed", "(abc", "abc", gcontext, ccontext)
        run_case("bad-class", "[abc", "abc", gcontext, ccontext)
        run_case("bad-quant", "*abc", "abc", gcontext, ccontext)
        run_case("bad-backref", "(a)\\2", "aa", gcontext, ccontext)
        run_case("bad-range", "a{3,2}", "aaa", gcontext, ccontext)
        run_case("bad-trailbs", "abc\\", "abc", gcontext, ccontext)
        run_case("bad-lookbehind", "(?<=a*)b", "ab", gcontext, ccontext)
        run_case("bad-dupname", "(?P<n>a)(?P<n>b)", "ab", gcontext, ccontext)
        pcre2_compile_context_free_8(ccontext)
        pcre2_general_context_free_8(gcontext)
        print("DONE\n")
    }
