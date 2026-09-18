// re_compile options/error differential probe (read-only audit, rev 450733e5).
// Compiles a matrix of (pattern, options) via pcre2_compile_8, prints one
// line per case: accept/reject + error code/offset/message. For accepted
// patterns also runs one match and prints rc + group-0 span, so option
// effects (caseless/multiline/dotall/extended/ungreedy/anchored/...) are
// observable. Oracle: system pcre2test 10.47 (same version as the port's
// PACKAGE_STRING) driven by gen_oracle.py; see oracle_expected.txt.
// Optics note: pcre2test modifiers are sticky across patterns in one file,
// so the oracle runs ONE pattern per pcre2test invocation.

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
use std.re.pcre2_jit_compile

unsafe fn run_case(tag: str, pattern: str, options: c_uint, subject: str, gcontext: *mut pcre2_real_general_context_8, ccontext: *mut pcre2_real_compile_context_8):
    var error_code: c_int = 0
    var error_offset: c_ulong = 0
    let code = pcre2_compile_8(
        (pattern as *const u8),
        pattern.len() as c_ulong,
        options,
        (&raw mut error_code as *mut c_int),
        (&raw mut error_offset as *mut c_ulong),
        ccontext
    )
    if code as i64 == 0:
        var err_msg: [256]u8
        pcre2_get_error_message_8(error_code, (&raw mut err_msg[0] as *mut u8), 256 as c_ulong)
        print(f"CASE {tag} opts={options} COMPILE_FAIL code={error_code} off={error_offset}\n")
        return
    let mcontext = pcre2_match_context_create_8(gcontext)
    let md = pcre2_match_data_create_from_pattern_8(code, gcontext)
    if (md as i64) == 0:
        print(f"CASE {tag} opts={options} COMPILE_OK mdnull\n")
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
        print(f"CASE {tag} opts={options} COMPILE_OK MATCH rc={rc}\n")
    else:
        let ov = pcre2_get_ovector_pointer_8(md)
        let s0 = unsafe *(ov + (0 as isize))
        let e0 = unsafe *(ov + (1 as isize))
        let s1 = if rc > 1: unsafe *(ov + (2 as isize)) else: (0 -% 1) as c_ulong
        let e1 = if rc > 1: unsafe *(ov + (3 as isize)) else: (0 -% 1) as c_ulong
        print(f"CASE {tag} opts={options} COMPILE_OK MATCH rc={rc} g0=[{s0},{e0}) g1=[{s1},{e1})\n")
    pcre2_match_data_free_8(md)
    pcre2_match_context_free_8(mcontext)
    pcre2_code_free_8(code)

unsafe fn run_jit_case(tag: str, pattern: str, gcontext: *mut pcre2_real_general_context_8, ccontext: *mut pcre2_real_compile_context_8):
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
        print(f"CASE {tag} COMPILE_FAIL code={error_code} off={error_offset}\n")
        return
    let jrc = pcre2_jit_compile_8(code, PCRE2_JIT_COMPLETE)
    let target = _pcre2_jit_get_target_8()
    print(f"CASE {tag} COMPILE_OK JITRC={jrc}\n")
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
        // Valid patterns: option effects observable via MATCH line
        run_case("plain", "hello", 0 as c_uint, "hello world", gcontext, ccontext)
        run_case("ci", "abc", PCRE2_CASELESS, "ABC", gcontext, ccontext)
        run_case("ci-off", "abc", 0 as c_uint, "ABC", gcontext, ccontext)
        run_case("ci-class", "[a-z]+", PCRE2_CASELESS, "HELLO", gcontext, ccontext)
        run_case("ml", "^b", PCRE2_MULTILINE, "a\nb", gcontext, ccontext)
        run_case("noml", "^b", 0 as c_uint, "a\nb", gcontext, ccontext)
        run_case("ds", "a.*b", PCRE2_DOTALL, "a\nb", gcontext, ccontext)
        run_case("nods", "a.*b", 0 as c_uint, "a\nb", gcontext, ccontext)
        run_case("ext", "a b c", PCRE2_EXTENDED, "abc", gcontext, ccontext)
        run_case("noext", "a b c", 0 as c_uint, "abc", gcontext, ccontext)
        run_case("ungreedy", "(a+)(b)", PCRE2_UNGREEDY, "aaab", gcontext, ccontext)
        run_case("greedy", "(a+)(b)", 0 as c_uint, "aaab", gcontext, ccontext)
        run_case("utf", "é", PCRE2_UTF, "é", gcontext, ccontext)
        run_case("utf-ascii", "a", PCRE2_UTF, "a", gcontext, ccontext)
        run_case("dupnames-ok", "(?P<n>a)(?P<n>b)", PCRE2_DUPNAMES, "ab", gcontext, ccontext)
        run_case("anchored", "b", PCRE2_ANCHORED, "ab", gcontext, ccontext)
        run_case("noanch", "b", 0 as c_uint, "ab", gcontext, ccontext)
        run_case("endonly", "a$", PCRE2_DOLLAR_ENDONLY, "a\n", gcontext, ccontext)
        run_case("noendonly", "a$", 0 as c_uint, "a\n", gcontext, ccontext)
        run_case("literal", "a+b", PCRE2_LITERAL, "a+b", gcontext, ccontext)
        run_case("noliteral", "a+b", 0 as c_uint, "a+b", gcontext, ccontext)
        run_case("ucp", "\\w+", PCRE2_UCP, "é", gcontext, ccontext)
        run_case("noucp", "\\w+", 0 as c_uint, "é", gcontext, ccontext)
        run_case("no-auto-possess", "a+b", PCRE2_NO_AUTO_POSSESS, "aaab", gcontext, ccontext)
        run_case("possessive", "a++b", 0 as c_uint, "aaab", gcontext, ccontext)
        run_case("allow-empty-class", "[]b", PCRE2_ALLOW_EMPTY_CLASS, "b", gcontext, ccontext)
        run_case("noallow-empty-class", "[]b", 0 as c_uint, "b", gcontext, ccontext)
        // JIT: upstream without JIT support returns -45; port must agree
        run_jit_case("jit", "a+b", gcontext, ccontext)
        // Invalid patterns: must fail loud; codes/offsets vs pcre2test
        run_case("bad-unclosed", "(abc", 0 as c_uint, "abc", gcontext, ccontext)
        run_case("bad-class", "[abc", 0 as c_uint, "abc", gcontext, ccontext)
        run_case("bad-quant", "*abc", 0 as c_uint, "abc", gcontext, ccontext)
        run_case("bad-backref", "(a)\\2", 0 as c_uint, "aa", gcontext, ccontext)
        run_case("bad-range", "a{3,2}", 0 as c_uint, "aaa", gcontext, ccontext)
        run_case("bad-trailbs", "abc\\", 0 as c_uint, "abc", gcontext, ccontext)
        run_case("bad-lonebs", "\\", 0 as c_uint, "", gcontext, ccontext)
        run_case("bad-lookbehind", "(?<=a*)b", 0 as c_uint, "ab", gcontext, ccontext)
        run_case("bad-dupname", "(?P<n>a)(?P<n>b)", 0 as c_uint, "ab", gcontext, ccontext)
        run_case("bad-conflict", "a", PCRE2_UTF | PCRE2_NEVER_UTF, "a", gcontext, ccontext)
        run_case("bad-optbit", "a", 268435456 as c_uint, "a", gcontext, ccontext)
        run_case("bad-bigrange", "[z-a]", 0 as c_uint, "a", gcontext, ccontext)
        run_case("bad-varlook", "(?<=a|bb)c", 0 as c_uint, "abc", gcontext, ccontext)
        run_case("bad-bigcount", "a{1,100000}", 0 as c_uint, "a", gcontext, ccontext)
        run_case("bad-toolarge-utf", "\\x{110000}", PCRE2_UTF, "a", gcontext, ccontext)
        run_case("toolarge-noutf", "\\x{110000}", 0 as c_uint, "a", gcontext, ccontext)
        run_case("bad-optset", "(?i", 0 as c_uint, "a", gcontext, ccontext)
        run_case("bad-rparen", "(a))", 0 as c_uint, "aa", gcontext, ccontext)
        pcre2_compile_context_free_8(ccontext)
        pcre2_general_context_free_8(gcontext)
        print("DONE\n")
    }
