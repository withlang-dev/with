// Migrated from PCRE2
use std.re.defs

@[c_export("pcre2_get_error_message_8")]
fn pcre2_get_error_message_8(enumber: c_int, buffer: *mut u8, size: c_ulong) -> c_int {
    var message: *const u8

    var i: c_ulong

    var n: c_int

    var rc: c_int = 0


    if ((if size == 0: 1 else: 0) != 0) {
        return -48
    }

    if ((if enumber >= 100: 1 else: 0) != 0) {
        (message = (&compile_error_texts[0] as *const u8))

        (n = enumber - 100)

    } else {
        if ((if enumber < 0: 1 else: 0) != 0) {
            (message = (&match_error_texts[0] as *const u8))

            (n = 0 - enumber)

        } else {
            (message = (("\0" as *const u8)))

            (n = 1)

        }
    }

    while ((if n > 0: 1 else: 0) != 0) {
        while true {
            var __ci_expr_old_0: *const u8 = message

            (message = message + 1)

            if (not ((if (unsafe: *__ci_expr_old_0) != 0: 1 else: 0) != 0)) {
                break
            }

        }

        if ((if (unsafe: *message) == 0: 1 else: 0) != 0) {
            return -29
        }


        (n = n - 1)

    }

    (i = 0)

    while ((if (unsafe: *message) != 0: 1 else: 0) != 0) {
        if ((if i >= (size -% 1): 1 else: 0) != 0) {
            (rc = -48)

            break

        }

        var __ci_expr_old_1: *const u8 = message

        (message = message + 1)

        ((unsafe: buffer[i]) = (unsafe: *__ci_expr_old_1))



        (i = i + 1)

    }


    ((unsafe: buffer[i]) = 0)

    var __ci_expr_ternary_2: c_int = 0

    if (rc != 0) {
        (__ci_expr_ternary_2 = rc)
    } else {
        (__ci_expr_ternary_2 = ((i as c_int)))
    }

    return __ci_expr_ternary_2


}

let compile_error_texts: [5687]u8 = "no error\0\\ at end of pattern\0\\c at end of pattern\0unrecognized character follows \\\0numbers out of order in {} quantifier\0number too big in {} quantifier\0missing terminating ] for character class\0escape sequence is invalid in character class\0range out of order in character class\0quantifier does not follow a repeatable item\0internal error: unexpected repeat\0unrecognized character after (? or (?-\0POSIX named classes are supported only within a class\0POSIX collating elements are not supported\0missing closing parenthesis\0reference to non-existent subpattern\0pattern passed as NULL with non-zero length\0unrecognised compile-time option bit(s)\0missing ) after (?# comment\0parentheses are too deeply nested\0regular expression is too large\0failed to allocate heap memory\0unmatched closing parenthesis\0internal error: code overflow\0missing closing parenthesis for condition\0length of lookbehind assertion is not limited\0a relative value of zero is not allowed\0conditional subpattern contains more than two branches\0atomic assertion expected after (?( or (?(?C)\0digit expected after (?+\0unknown POSIX class name\0internal error in pcre2_study(): should not occur\0this version of PCRE2 does not have Unicode support\0parentheses are too deeply nested (stack check)\0character code point value in \\x{} or \\o{} is too large\0lookbehind is too complicated\0\\C is not allowed in a lookbehind assertion in UTF- mode\0PCRE2 does not support \\F, \\L, \\l, \\N{name}, \\U, or \\u\0number after (?C is greater than 255\0closing parenthesis for (?C expected\0invalid escape sequence in (*VERB) name\0unrecognized character after (?P\0syntax error in subpattern name (missing terminator?)\0two named subpatterns have the same name (PCRE2_DUPNAMES not set)\0subpattern name must start with a non-digit\0this version of PCRE2 does not have support for \\P, \\p, or \\X\0malformed \\P or \\p sequence\0unknown property after \\P or \\p\0subpattern name is too long (maximum  code units)\0too many named subpatterns (maximum )\0invalid range in character class\0octal value is greater than \\377 in 8-bit non-UTF-8 mode\0internal error: overran compiling workspace\0internal error: previously-checked referenced subpattern not found\0DEFINE subpattern contains more than one branch\0missing opening brace after \\o\0internal error: unknown newline setting\0\\g is not followed by a braced, angle-bracketed, or quoted name/number or by a plain number\0(?R (recursive pattern call) must be followed by a closing parenthesis\0obsolete error (should not occur)\0(*VERB) not recognized or malformed\0subpattern number is too big\0subpattern name expected\0internal error: parsed pattern overflow\0non-octal character in \\o{} (closing brace missing?)\0different names for subpatterns of the same number are not allowed\0(*MARK) must have an argument\0non-hex character in \\x{} (closing brace missing?)\0\\c must be followed by a printable ASCII character\0\\c must be followed by a letter or one of @[\\]^_?\0\\k is not followed by a braced, angle-bracketed, or quoted name\0internal error: unknown meta code in check_lookbehinds()\0\\N is not supported in a class\0callout string is too long\0disallowed Unicode code point (>= 0xd800 && <= 0xdfff)\0using UTF is disabled by the application\0using UCP is disabled by the application\0name is too long in (*MARK), (*PRUNE), (*SKIP), or (*THEN)\0character code point value in \\u.... sequence is too large\0digits missing after \\x or in \\x{} or \\o{} or \\N{U+}\0syntax error or number too big in (?(VERSION condition\0internal error: unknown opcode in auto_possessify()\0missing terminating delimiter for callout with string argument\0unrecognized string delimiter follows (?C\0using \\C is disabled by the application\0(?| and/or (?J: or (?x: parentheses are too deeply nested\0using \\C is disabled in this PCRE2 library\0regular expression is too complicated\0lookbehind assertion is too long\0pattern string is longer than the limit set by the application\0internal error: unknown code in parsed pattern\0internal error: bad code value in parsed_skip()\0PCRE2_EXTRA_ALLOW_SURROGATE_ESCAPES is not allowed in UTF-16 mode\0invalid option bits with PCRE2_LITERAL\0\\N{U+dddd} is supported only in Unicode (UTF) mode\0invalid hyphen in option setting\0(*alpha_assertion) not recognized\0script runs require Unicode support, which this version of PCRE2 does not have\0too many capturing groups (maximum 65535)\0octal digit missing after \\0 (PCRE2_EXTRA_NO_BS0 is set)\0\\K is not allowed in lookarounds (but see PCRE2_EXTRA_ALLOW_LOOKAROUND_BSK)\0branch too long in variable-length lookbehind assertion\0compiled pattern would be longer than the limit set by the application\0octal value given by \\ddd is greater than \\377 (forbidden by PCRE2_EXTRA_PYTHON_OCTAL)\0using callouts is disabled by the application\0PCRE2_EXTRA_TURKISH_CASING require Unicode (UTF or UCP) mode\0PCRE2_EXTRA_TURKISH_CASING requires UTF in 8-bit mode\0PCRE2_EXTRA_TURKISH_CASING and PCRE2_EXTRA_CASELESS_RESTRICT are not compatible\0extended character class nesting is too deep\0invalid operator in extended character class\0unexpected operator in extended character class (no preceding operand)\0expected operand after operator in extended character class\0square brackets needed to clarify operator precedence in extended character class\0missing terminating ] for extended character class (note '[' must be escaped under PCRE2_ALT_EXTENDED_CLASS)\0unexpected expression in extended character class (no preceding operator)\0empty expression in extended character class\0terminating ] with no following closing parenthesis in (?[...]\0unexpected character in (?[...]) extended character class\0expected capture group number or name\0missing opening parenthesis\0syntax error in subpattern number (missing terminator?)\0erroroffset passed as NULL\0"
let match_error_texts: [2946]u8 = "no error\0no match\0partial match\0UTF-8 error: 1 byte missing at end\0UTF-8 error: 2 bytes missing at end\0UTF-8 error: 3 bytes missing at end\0UTF-8 error: 4 bytes missing at end\0UTF-8 error: 5 bytes missing at end\0UTF-8 error: byte 2 top bits not 0x80\0UTF-8 error: byte 3 top bits not 0x80\0UTF-8 error: byte 4 top bits not 0x80\0UTF-8 error: byte 5 top bits not 0x80\0UTF-8 error: byte 6 top bits not 0x80\0UTF-8 error: 5-byte character is not allowed (RFC 3629)\0UTF-8 error: 6-byte character is not allowed (RFC 3629)\0UTF-8 error: code points greater than 0x10ffff are not defined\0UTF-8 error: code points 0xd800-0xdfff are not defined\0UTF-8 error: overlong 2-byte sequence\0UTF-8 error: overlong 3-byte sequence\0UTF-8 error: overlong 4-byte sequence\0UTF-8 error: overlong 5-byte sequence\0UTF-8 error: overlong 6-byte sequence\0UTF-8 error: isolated byte with 0x80 bit set\0UTF-8 error: illegal byte (0xfe or 0xff)\0UTF-16 error: missing low surrogate at end\0UTF-16 error: invalid low surrogate\0UTF-16 error: isolated low surrogate\0UTF-32 error: code points 0xd800-0xdfff are not defined\0UTF-32 error: code points greater than 0x10ffff are not defined\0bad data value\0patterns do not all use the same character tables\0magic number missing\0pattern compiled in wrong mode: 8/16/32-bit error\0bad offset value\0bad option value\0invalid replacement string\0bad offset into UTF string\0callout error code\0invalid data in workspace for DFA restart\0too much recursion for DFA matching\0backreference condition or recursion test is not supported for DFA matching\0function is not supported for DFA matching\0pattern contains an item that is not supported for DFA matching\0workspace size exceeded in DFA matching\0internal error - pattern overwritten?\0bad JIT option\0JIT stack limit reached\0match limit exceeded\0no more memory\0unknown substring\0non-unique substring name\0NULL argument passed with non-zero length\0nested recursion at the same subject position\0matching depth limit exceeded\0requested value is not available\0requested value is not set\0offset limit set without PCRE2_USE_OFFSET_LIMIT\0bad escape sequence in replacement string\0expected closing curly bracket in replacement string\0bad substitution in replacement string\0match with end before start or start moved backwards is not supported\0too many replacements (more than INT_MAX)\0bad serialized data\0heap limit exceeded\0invalid syntax\0internal error: duplicate substitution match\0PCRE2_MATCH_INVALID_UTF is not supported for DFA matching\0internal error: invalid substring offset\0feature is not supported by the JIT compiler\0error performing replacement case transformation\0replacement too large (longer than PCRE2_SIZE)\0substitute pattern differs from prior match call\0substitute subject differs from prior match call\0substitute start offset differs from prior match call\0substitute options differ from prior match call\0disallowed use of \\K in lookaround\0replacement $' or $_ not supported with partial match\0"
