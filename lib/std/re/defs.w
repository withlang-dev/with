// std.re.defs — shared definitions for migrated PCRE2

pub fn is_alpha(c: i32) -> bool {
    (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
}
pub fn is_digit(c: i32) -> bool {
    c >= 48 and c <= 57
}
pub fn is_space(c: i32) -> bool {
    c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11
}
pub fn is_alnum(c: i32) -> bool {
    is_alpha(c) or is_digit(c)
}
pub fn is_upper(c: i32) -> bool {
    c >= 65 and c <= 90
}
pub fn is_lower(c: i32) -> bool {
    c >= 97 and c <= 122
}
pub fn is_xdigit(c: i32) -> bool {
    (c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)
}
pub fn is_print(c: i32) -> bool {
    c >= 32 and c <= 126
}
pub fn to_lower(c: i32) -> i32 {
    if c >= 65 and c <= 90 { c + 32 } else { c }
}
pub fn to_upper(c: i32) -> i32 {
    if c >= 97 and c <= 122 { c - 32 } else { c }
}
pub extern fn strlen(s: *const i8) -> i64
pub extern fn strcmp(a: *const i8, b: *const i8) -> i32
pub extern fn strncmp(a: *const i8, b: *const i8, n: i64) -> i32
pub extern fn strchr(s: *const i8, c: i32) -> *mut i8
pub extern fn memchr(s: *const c_void, c: i32, n: i64) -> *mut c_void
pub extern fn isalpha(c: i32) -> i32
pub extern fn isdigit(c: i32) -> i32
pub extern fn isalnum(c: i32) -> i32
pub extern fn isspace(c: i32) -> i32
pub extern fn isupper(c: i32) -> i32
pub extern fn islower(c: i32) -> i32
pub extern fn isxdigit(c: i32) -> i32
pub extern fn isprint(c: i32) -> i32
pub extern fn isgraph(c: i32) -> i32
pub extern fn ispunct(c: i32) -> i32
pub extern fn iscntrl(c: i32) -> i32
pub extern fn tolower(c: i32) -> i32
pub extern fn toupper(c: i32) -> i32
pub extern fn sqrt(x: f64) -> f64
pub extern fn pow(base: f64, exp: f64) -> f64
pub extern fn floor(x: f64) -> f64
pub extern fn ceil(x: f64) -> f64
pub extern fn round(x: f64) -> f64
pub extern fn sin(x: f64) -> f64
pub extern fn cos(x: f64) -> f64
pub extern fn tan(x: f64) -> f64
pub extern fn log(x: f64) -> f64
pub extern fn log10(x: f64) -> f64
pub extern fn exp(x: f64) -> f64
pub extern fn fabs(x: f64) -> f64
pub extern fn fmod(x: f64, y: f64) -> f64
pub extern fn asin(x: f64) -> f64
pub extern fn acos(x: f64) -> f64
pub extern fn atan(x: f64) -> f64
pub extern fn atan2(y: f64, x: f64) -> f64

pub type c_void = opaque
pub extern fn abort() -> Never
pub fn __ci_unreachable() -> Never: abort()

pub type c_char = i8
pub type c_short = i16
pub type c_ushort = u16
pub type c_int = i32
pub type c_uint = u32
pub type c_long = i64
pub type c_ulong = u64
pub type c_longlong = i64
pub type c_ulonglong = u64
pub type c_longdouble = f64
pub unsafe fn __with_builtin_add_overflow_i8(a: i8, b: i8, out: *mut i8) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i8(a: i8, b: i8, out: *mut i8) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i8(a: i8, b: i8, out: *mut i8) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if a == 0 or b == 0: false else if a == -1: result == b else if b == -1: result == a else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_u8(a: u8, b: u8, out: *mut u8) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u8(a: u8, b: u8, out: *mut u8) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u8(a: u8, b: u8, out: *mut u8) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if b == 0: false else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_i16(a: i16, b: i16, out: *mut i16) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i16(a: i16, b: i16, out: *mut i16) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i16(a: i16, b: i16, out: *mut i16) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if a == 0 or b == 0: false else if a == -1: result == b else if b == -1: result == a else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_u16(a: u16, b: u16, out: *mut u16) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u16(a: u16, b: u16, out: *mut u16) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u16(a: u16, b: u16, out: *mut u16) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if b == 0: false else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_i32(a: i32, b: i32, out: *mut i32) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i32(a: i32, b: i32, out: *mut i32) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i32(a: i32, b: i32, out: *mut i32) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if a == 0 or b == 0: false else if a == -1: result == b else if b == -1: result == a else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_u32(a: u32, b: u32, out: *mut u32) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u32(a: u32, b: u32, out: *mut u32) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u32(a: u32, b: u32, out: *mut u32) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if b == 0: false else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_i64(a: i64, b: i64, out: *mut i64) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i64(a: i64, b: i64, out: *mut i64) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
pub unsafe fn __with_builtin_mul_overflow_i64(a: i64, b: i64, out: *mut i64) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if a == 0 or b == 0: false else if a == -1: result == b else if b == -1: result == a else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_u64(a: u64, b: u64, out: *mut u64) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u64(a: u64, b: u64, out: *mut u64) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u64(a: u64, b: u64, out: *mut u64) -> bool {
    let result = a *% b
    unsafe { (*out = result) }
    if b == 0: false else: result / b != a
}
pub unsafe fn __with_builtin_add_overflow_i128(a: i128, b: i128, out: *mut i128) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    ((result ^ a) & (result ^ b)) < 0
}
pub unsafe fn __with_builtin_sub_overflow_i128(a: i128, b: i128, out: *mut i128) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    ((a ^ b) & (result ^ a)) < 0
}
// The 128-bit overflow checks stay division-free on purpose: `/` on i128/u128
// lowers to the __divti3/__udivti3 compiler-rt libcalls, and this shim is
// compiled into freestanding runtime objects whose COFF link has no builtins
// library to resolve them from. Limb decomposition keeps the check to multiplies
// and shifts, which lower inline on every target and at every -O level.
fn u128_mul_would_overflow(a: u128, b: u128) -> bool {
    let a_hi = (a >> 64) as u64
    let b_hi = (b >> 64) as u64
    if a_hi != 0 and b_hi != 0: return true
    let a_lo = (a as u64) as u128
    let b_lo = (b as u64) as u128
    let cross = (a_hi as u128) *% b_lo +% (b_hi as u128) *% a_lo
    if (cross >> 64) != 0: return true
    let low = a_lo *% b_lo
    ((low >> 64) +% cross) >> 64 != 0
}
pub unsafe fn __with_builtin_mul_overflow_i128(a: i128, b: i128, out: *mut i128) -> bool {
    unsafe { (*out = a *% b) }
    if a == 0 or b == 0: return false
    let neg = (a < 0) != (b < 0)
    let ua = if a < 0: (0 as u128) -% (a as u128) else: a as u128
    let ub = if b < 0: (0 as u128) -% (b as u128) else: b as u128
    if u128_mul_would_overflow(ua, ub): return true
    let limit = if neg: (1 as u128) << 127 else: ((1 as u128) << 127) -% 1
    ua *% ub > limit
}
pub unsafe fn __with_builtin_add_overflow_u128(a: u128, b: u128, out: *mut u128) -> bool {
    let result = a +% b
    unsafe { (*out = result) }
    result < a
}
pub unsafe fn __with_builtin_sub_overflow_u128(a: u128, b: u128, out: *mut u128) -> bool {
    let result = a -% b
    unsafe { (*out = result) }
    a < b
}
pub unsafe fn __with_builtin_mul_overflow_u128(a: u128, b: u128, out: *mut u128) -> bool {
    unsafe { (*out = a *% b) }
    u128_mul_would_overflow(a, b)
}
pub extern fn with_clz(x: i32) -> i32
pub extern fn with_ctz(x: i32) -> i32
pub extern fn with_popcount(x: i32) -> i32
pub extern fn with_bswap16(x: u16) -> u16
pub extern fn with_bswap32(x: u32) -> u32
pub extern fn with_bswap64(x: u64) -> u64
pub extern fn with_clzl(x: i64) -> i32
pub extern fn with_clzll(x: i64) -> i32
pub extern fn with_ctzl(x: i64) -> i32
pub extern fn with_ctzll(x: i64) -> i32
pub extern fn with_abs(x: i32) -> i32
pub extern fn with_alloc(size: i64) -> *mut u8
pub extern fn with_alloc_zeroed(count: i64, size: i64) -> *mut u8
pub extern fn with_realloc(ptr: *mut u8, old_size: i64, new_size: i64) -> *mut u8
pub extern fn with_free(ptr: *mut u8) -> Unit
pub extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8
pub extern fn with_memmove(dst: *mut u8, src: *const u8, n: i64) -> *mut u8
pub extern fn with_memset(dst: *mut u8, c: i32, n: i64) -> *mut u8
pub extern fn with_memcmp(a: *const u8, b: *const u8, n: i64) -> i32
pub extern fn with_va_start(ap: *mut i8) -> Unit
pub extern fn with_va_end(ap: *mut i8) -> Unit


pub type max_align_t = c_longdouble

pub type BOOL = c_int

pub type PCRE2_UCHAR8 = u8

pub type PCRE2_SPTR8 = *const u8

pub type pcre2_general_context_8 = pcre2_real_general_context_8

pub type pcre2_compile_context_8 = pcre2_real_compile_context_8

pub type pcre2_match_context_8 = pcre2_real_match_context_8

pub type pcre2_convert_context_8 = pcre2_real_convert_context_8

pub type pcre2_code_8 = pcre2_real_code_8

pub type pcre2_match_data_8 = pcre2_real_match_data_8

pub type pcre2_jit_stack_8 = pcre2_real_jit_stack_8

pub type pcre2_jit_callback_8 = unsafe extern "C" fn(*mut c_void) -> *mut pcre2_real_jit_stack_8

pub type pcre2_callout_block_8 { version: c_uint = 0, callout_number: c_uint = 0, capture_top: c_uint = 0, capture_last: c_uint = 0, offset_vector: *mut c_ulong = null, mark: *const u8 = null, subject: *const u8 = null, subject_length: c_ulong = 0, start_match: c_ulong = 0, current_position: c_ulong = 0, pattern_position: c_ulong = 0, next_item_length: c_ulong = 0, callout_string_offset: c_ulong = 0, callout_string_length: c_ulong = 0, callout_string: *const u8 = null, callout_flags: c_uint = 0 }
impl Copy for pcre2_callout_block_8

pub type pcre2_callout_enumerate_block_8 { version: c_uint = 0, pattern_position: c_ulong = 0, next_item_length: c_ulong = 0, callout_number: c_uint = 0, callout_string_offset: c_ulong = 0, callout_string_length: c_ulong = 0, callout_string: *const u8 = null }
impl Copy for pcre2_callout_enumerate_block_8

pub type pcre2_substitute_callout_block_8 { version: c_uint = 0, input: *const u8 = null, output: *const u8 = null, output_offsets: [2]c_ulong = [0 as c_ulong; 2], ovector: *mut c_ulong = null, oveccount: c_uint = 0, subscount: c_uint = 0 }
impl Copy for pcre2_substitute_callout_block_8

pub let ucp_C: c_uint = 0
pub let ucp_L: c_uint = 1
pub let ucp_M: c_uint = 2
pub let ucp_N: c_uint = 3
pub let ucp_P: c_uint = 4
pub let ucp_S: c_uint = 5
pub let ucp_Z: c_uint = 6
pub let ucp_Cc: c_uint = 0
pub let ucp_Cf: c_uint = 1
pub let ucp_Cn: c_uint = 2
pub let ucp_Co: c_uint = 3
pub let ucp_Cs: c_uint = 4
pub let ucp_Ll: c_uint = 5
pub let ucp_Lm: c_uint = 6
pub let ucp_Lo: c_uint = 7
pub let ucp_Lt: c_uint = 8
pub let ucp_Lu: c_uint = 9
pub let ucp_Mc: c_uint = 10
pub let ucp_Me: c_uint = 11
pub let ucp_Mn: c_uint = 12
pub let ucp_Nd: c_uint = 13
pub let ucp_Nl: c_uint = 14
pub let ucp_No: c_uint = 15
pub let ucp_Pc: c_uint = 16
pub let ucp_Pd: c_uint = 17
pub let ucp_Pe: c_uint = 18
pub let ucp_Pf: c_uint = 19
pub let ucp_Pi: c_uint = 20
pub let ucp_Po: c_uint = 21
pub let ucp_Ps: c_uint = 22
pub let ucp_Sc: c_uint = 23
pub let ucp_Sk: c_uint = 24
pub let ucp_Sm: c_uint = 25
pub let ucp_So: c_uint = 26
pub let ucp_Zl: c_uint = 27
pub let ucp_Zp: c_uint = 28
pub let ucp_Zs: c_uint = 29
pub let ucp_ASCII: c_uint = 0
pub let ucp_ASCII_Hex_Digit: c_uint = 1
pub let ucp_Alphabetic: c_uint = 2
pub let ucp_Bidi_Control: c_uint = 3
pub let ucp_Bidi_Mirrored: c_uint = 4
pub let ucp_Case_Ignorable: c_uint = 5
pub let ucp_Cased: c_uint = 6
pub let ucp_Changes_When_Casefolded: c_uint = 7
pub let ucp_Changes_When_Casemapped: c_uint = 8
pub let ucp_Changes_When_Lowercased: c_uint = 9
pub let ucp_Changes_When_Titlecased: c_uint = 10
pub let ucp_Changes_When_Uppercased: c_uint = 11
pub let ucp_Dash: c_uint = 12
pub let ucp_Default_Ignorable_Code_Point: c_uint = 13
pub let ucp_Deprecated: c_uint = 14
pub let ucp_Diacritic: c_uint = 15
pub let ucp_Emoji: c_uint = 16
pub let ucp_Emoji_Component: c_uint = 17
pub let ucp_Emoji_Modifier: c_uint = 18
pub let ucp_Emoji_Modifier_Base: c_uint = 19
pub let ucp_Emoji_Presentation: c_uint = 20
pub let ucp_Extended_Pictographic: c_uint = 21
pub let ucp_Extender: c_uint = 22
pub let ucp_Grapheme_Base: c_uint = 23
pub let ucp_Grapheme_Extend: c_uint = 24
pub let ucp_Grapheme_Link: c_uint = 25
pub let ucp_Hex_Digit: c_uint = 26
pub let ucp_IDS_Binary_Operator: c_uint = 27
pub let ucp_IDS_Trinary_Operator: c_uint = 28
pub let ucp_IDS_Unary_Operator: c_uint = 29
pub let ucp_ID_Compat_Math_Continue: c_uint = 30
pub let ucp_ID_Compat_Math_Start: c_uint = 31
pub let ucp_ID_Continue: c_uint = 32
pub let ucp_ID_Start: c_uint = 33
pub let ucp_Ideographic: c_uint = 34
pub let ucp_InCB: c_uint = 35
pub let ucp_Join_Control: c_uint = 36
pub let ucp_Logical_Order_Exception: c_uint = 37
pub let ucp_Lowercase: c_uint = 38
pub let ucp_Math: c_uint = 39
pub let ucp_Modifier_Combining_Mark: c_uint = 40
pub let ucp_Noncharacter_Code_Point: c_uint = 41
pub let ucp_Pattern_Syntax: c_uint = 42
pub let ucp_Pattern_White_Space: c_uint = 43
pub let ucp_Prepended_Concatenation_Mark: c_uint = 44
pub let ucp_Quotation_Mark: c_uint = 45
pub let ucp_Radical: c_uint = 46
pub let ucp_Regional_Indicator: c_uint = 47
pub let ucp_Sentence_Terminal: c_uint = 48
pub let ucp_Soft_Dotted: c_uint = 49
pub let ucp_Terminal_Punctuation: c_uint = 50
pub let ucp_Unified_Ideograph: c_uint = 51
pub let ucp_Uppercase: c_uint = 52
pub let ucp_Variation_Selector: c_uint = 53
pub let ucp_White_Space: c_uint = 54
pub let ucp_XID_Continue: c_uint = 55
pub let ucp_XID_Start: c_uint = 56
pub let ucp_Bprop_Count: c_uint = 57
pub let ucp_bidiAL: c_uint = 0
pub let ucp_bidiAN: c_uint = 1
pub let ucp_bidiB: c_uint = 2
pub let ucp_bidiBN: c_uint = 3
pub let ucp_bidiCS: c_uint = 4
pub let ucp_bidiEN: c_uint = 5
pub let ucp_bidiES: c_uint = 6
pub let ucp_bidiET: c_uint = 7
pub let ucp_bidiFSI: c_uint = 8
pub let ucp_bidiL: c_uint = 9
pub let ucp_bidiLRE: c_uint = 10
pub let ucp_bidiLRI: c_uint = 11
pub let ucp_bidiLRO: c_uint = 12
pub let ucp_bidiNSM: c_uint = 13
pub let ucp_bidiON: c_uint = 14
pub let ucp_bidiPDF: c_uint = 15
pub let ucp_bidiPDI: c_uint = 16
pub let ucp_bidiR: c_uint = 17
pub let ucp_bidiRLE: c_uint = 18
pub let ucp_bidiRLI: c_uint = 19
pub let ucp_bidiRLO: c_uint = 20
pub let ucp_bidiS: c_uint = 21
pub let ucp_bidiWS: c_uint = 22
pub let ucp_gbCR: c_uint = 0
pub let ucp_gbLF: c_uint = 1
pub let ucp_gbControl: c_uint = 2
pub let ucp_gbExtend: c_uint = 3
pub let ucp_gbPrepend: c_uint = 4
pub let ucp_gbSpacingMark: c_uint = 5
pub let ucp_gbL: c_uint = 6
pub let ucp_gbV: c_uint = 7
pub let ucp_gbT: c_uint = 8
pub let ucp_gbLV: c_uint = 9
pub let ucp_gbLVT: c_uint = 10
pub let ucp_gbRegional_Indicator: c_uint = 11
pub let ucp_gbOther: c_uint = 12
pub let ucp_gbZWJ: c_uint = 13
pub let ucp_gbExtended_Pictographic: c_uint = 14
pub let ucp_Latin: c_uint = 0
pub let ucp_Greek: c_uint = 1
pub let ucp_Cyrillic: c_uint = 2
pub let ucp_Armenian: c_uint = 3
pub let ucp_Hebrew: c_uint = 4
pub let ucp_Arabic: c_uint = 5
pub let ucp_Syriac: c_uint = 6
pub let ucp_Thaana: c_uint = 7
pub let ucp_Devanagari: c_uint = 8
pub let ucp_Bengali: c_uint = 9
pub let ucp_Gurmukhi: c_uint = 10
pub let ucp_Gujarati: c_uint = 11
pub let ucp_Oriya: c_uint = 12
pub let ucp_Tamil: c_uint = 13
pub let ucp_Telugu: c_uint = 14
pub let ucp_Kannada: c_uint = 15
pub let ucp_Malayalam: c_uint = 16
pub let ucp_Sinhala: c_uint = 17
pub let ucp_Thai: c_uint = 18
pub let ucp_Tibetan: c_uint = 19
pub let ucp_Myanmar: c_uint = 20
pub let ucp_Georgian: c_uint = 21
pub let ucp_Hangul: c_uint = 22
pub let ucp_Ethiopic: c_uint = 23
pub let ucp_Cherokee: c_uint = 24
pub let ucp_Runic: c_uint = 25
pub let ucp_Mongolian: c_uint = 26
pub let ucp_Hiragana: c_uint = 27
pub let ucp_Katakana: c_uint = 28
pub let ucp_Bopomofo: c_uint = 29
pub let ucp_Han: c_uint = 30
pub let ucp_Yi: c_uint = 31
pub let ucp_Gothic: c_uint = 32
pub let ucp_Tagalog: c_uint = 33
pub let ucp_Hanunoo: c_uint = 34
pub let ucp_Buhid: c_uint = 35
pub let ucp_Tagbanwa: c_uint = 36
pub let ucp_Limbu: c_uint = 37
pub let ucp_Tai_Le: c_uint = 38
pub let ucp_Linear_B: c_uint = 39
pub let ucp_Shavian: c_uint = 40
pub let ucp_Cypriot: c_uint = 41
pub let ucp_Buginese: c_uint = 42
pub let ucp_Coptic: c_uint = 43
pub let ucp_Glagolitic: c_uint = 44
pub let ucp_Tifinagh: c_uint = 45
pub let ucp_Syloti_Nagri: c_uint = 46
pub let ucp_Phags_Pa: c_uint = 47
pub let ucp_Nko: c_uint = 48
pub let ucp_Kayah_Li: c_uint = 49
pub let ucp_Lycian: c_uint = 50
pub let ucp_Carian: c_uint = 51
pub let ucp_Lydian: c_uint = 52
pub let ucp_Avestan: c_uint = 53
pub let ucp_Samaritan: c_uint = 54
pub let ucp_Lisu: c_uint = 55
pub let ucp_Javanese: c_uint = 56
pub let ucp_Old_Turkic: c_uint = 57
pub let ucp_Kaithi: c_uint = 58
pub let ucp_Mandaic: c_uint = 59
pub let ucp_Chakma: c_uint = 60
pub let ucp_Meroitic_Hieroglyphs: c_uint = 61
pub let ucp_Sharada: c_uint = 62
pub let ucp_Takri: c_uint = 63
pub let ucp_Caucasian_Albanian: c_uint = 64
pub let ucp_Duployan: c_uint = 65
pub let ucp_Elbasan: c_uint = 66
pub let ucp_Grantha: c_uint = 67
pub let ucp_Khojki: c_uint = 68
pub let ucp_Linear_A: c_uint = 69
pub let ucp_Mahajani: c_uint = 70
pub let ucp_Manichaean: c_uint = 71
pub let ucp_Modi: c_uint = 72
pub let ucp_Old_Permic: c_uint = 73
pub let ucp_Psalter_Pahlavi: c_uint = 74
pub let ucp_Khudawadi: c_uint = 75
pub let ucp_Tirhuta: c_uint = 76
pub let ucp_Multani: c_uint = 77
pub let ucp_Old_Hungarian: c_uint = 78
pub let ucp_Adlam: c_uint = 79
pub let ucp_Osage: c_uint = 80
pub let ucp_Tangut: c_uint = 81
pub let ucp_Masaram_Gondi: c_uint = 82
pub let ucp_Dogra: c_uint = 83
pub let ucp_Gunjala_Gondi: c_uint = 84
pub let ucp_Hanifi_Rohingya: c_uint = 85
pub let ucp_Sogdian: c_uint = 86
pub let ucp_Nandinagari: c_uint = 87
pub let ucp_Yezidi: c_uint = 88
pub let ucp_Cypro_Minoan: c_uint = 89
pub let ucp_Old_Uyghur: c_uint = 90
pub let ucp_Toto: c_uint = 91
pub let ucp_Garay: c_uint = 92
pub let ucp_Gurung_Khema: c_uint = 93
pub let ucp_Ol_Onal: c_uint = 94
pub let ucp_Sunuwar: c_uint = 95
pub let ucp_Todhri: c_uint = 96
pub let ucp_Tulu_Tigalari: c_uint = 97
pub let ucp_Unknown: c_uint = 98
pub let ucp_Common: c_uint = 99
pub let ucp_Lao: c_uint = 100
pub let ucp_Canadian_Aboriginal: c_uint = 101
pub let ucp_Ogham: c_uint = 102
pub let ucp_Khmer: c_uint = 103
pub let ucp_Old_Italic: c_uint = 104
pub let ucp_Deseret: c_uint = 105
pub let ucp_Inherited: c_uint = 106
pub let ucp_Ugaritic: c_uint = 107
pub let ucp_Osmanya: c_uint = 108
pub let ucp_Braille: c_uint = 109
pub let ucp_New_Tai_Lue: c_uint = 110
pub let ucp_Old_Persian: c_uint = 111
pub let ucp_Kharoshthi: c_uint = 112
pub let ucp_Balinese: c_uint = 113
pub let ucp_Cuneiform: c_uint = 114
pub let ucp_Phoenician: c_uint = 115
pub let ucp_Sundanese: c_uint = 116
pub let ucp_Lepcha: c_uint = 117
pub let ucp_Ol_Chiki: c_uint = 118
pub let ucp_Vai: c_uint = 119
pub let ucp_Saurashtra: c_uint = 120
pub let ucp_Rejang: c_uint = 121
pub let ucp_Cham: c_uint = 122
pub let ucp_Tai_Tham: c_uint = 123
pub let ucp_Tai_Viet: c_uint = 124
pub let ucp_Egyptian_Hieroglyphs: c_uint = 125
pub let ucp_Bamum: c_uint = 126
pub let ucp_Meetei_Mayek: c_uint = 127
pub let ucp_Imperial_Aramaic: c_uint = 128
pub let ucp_Old_South_Arabian: c_uint = 129
pub let ucp_Inscriptional_Parthian: c_uint = 130
pub let ucp_Inscriptional_Pahlavi: c_uint = 131
pub let ucp_Batak: c_uint = 132
pub let ucp_Brahmi: c_uint = 133
pub let ucp_Meroitic_Cursive: c_uint = 134
pub let ucp_Miao: c_uint = 135
pub let ucp_Sora_Sompeng: c_uint = 136
pub let ucp_Bassa_Vah: c_uint = 137
pub let ucp_Pahawh_Hmong: c_uint = 138
pub let ucp_Mende_Kikakui: c_uint = 139
pub let ucp_Mro: c_uint = 140
pub let ucp_Old_North_Arabian: c_uint = 141
pub let ucp_Nabataean: c_uint = 142
pub let ucp_Palmyrene: c_uint = 143
pub let ucp_Pau_Cin_Hau: c_uint = 144
pub let ucp_Siddham: c_uint = 145
pub let ucp_Warang_Citi: c_uint = 146
pub let ucp_Ahom: c_uint = 147
pub let ucp_Anatolian_Hieroglyphs: c_uint = 148
pub let ucp_Hatran: c_uint = 149
pub let ucp_SignWriting: c_uint = 150
pub let ucp_Bhaiksuki: c_uint = 151
pub let ucp_Marchen: c_uint = 152
pub let ucp_Newa: c_uint = 153
pub let ucp_Nushu: c_uint = 154
pub let ucp_Soyombo: c_uint = 155
pub let ucp_Zanabazar_Square: c_uint = 156
pub let ucp_Makasar: c_uint = 157
pub let ucp_Medefaidrin: c_uint = 158
pub let ucp_Old_Sogdian: c_uint = 159
pub let ucp_Elymaic: c_uint = 160
pub let ucp_Nyiakeng_Puachue_Hmong: c_uint = 161
pub let ucp_Wancho: c_uint = 162
pub let ucp_Chorasmian: c_uint = 163
pub let ucp_Dives_Akuru: c_uint = 164
pub let ucp_Khitan_Small_Script: c_uint = 165
pub let ucp_Tangsa: c_uint = 166
pub let ucp_Vithkuqi: c_uint = 167
pub let ucp_Kawi: c_uint = 168
pub let ucp_Nag_Mundari: c_uint = 169
pub let ucp_Kirat_Rai: c_uint = 170
pub let ucp_Script_Count: c_uint = 171
pub let PCRE2_MATCHEDBY_INTERPRETER: c_uint = 0
pub let PCRE2_MATCHEDBY_DFA_INTERPRETER: c_uint = 1
pub let PCRE2_MATCHEDBY_JIT: c_uint = 2
pub let ESC_A: c_uint = 1
pub let ESC_G: c_uint = 2
pub let ESC_K: c_uint = 3
pub let ESC_B: c_uint = 4
pub let ESC_b: c_uint = 5
pub let ESC_D: c_uint = 6
pub let ESC_d: c_uint = 7
pub let ESC_S: c_uint = 8
pub let ESC_s: c_uint = 9
pub let ESC_W: c_uint = 10
pub let ESC_w: c_uint = 11
pub let ESC_N: c_uint = 12
pub let ESC_dum: c_uint = 13
pub let ESC_C: c_uint = 14
pub let ESC_P: c_uint = 15
pub let ESC_p: c_uint = 16
pub let ESC_R: c_uint = 17
pub let ESC_H: c_uint = 18
pub let ESC_h: c_uint = 19
pub let ESC_V: c_uint = 20
pub let ESC_v: c_uint = 21
pub let ESC_X: c_uint = 22
pub let ESC_Z: c_uint = 23
pub let ESC_z: c_uint = 24
pub let ESC_E: c_uint = 25
pub let ESC_Q: c_uint = 26
pub let ESC_g: c_uint = 27
pub let ESC_k: c_uint = 28
pub let ESC_ub: c_uint = 29
pub let OP_END: c_uint = 0
pub let OP_SOD: c_uint = 1
pub let OP_SOM: c_uint = 2
pub let OP_SET_SOM: c_uint = 3
pub let OP_NOT_WORD_BOUNDARY: c_uint = 4
pub let OP_WORD_BOUNDARY: c_uint = 5
pub let OP_NOT_DIGIT: c_uint = 6
pub let OP_DIGIT: c_uint = 7
pub let OP_NOT_WHITESPACE: c_uint = 8
pub let OP_WHITESPACE: c_uint = 9
pub let OP_NOT_WORDCHAR: c_uint = 10
pub let OP_WORDCHAR: c_uint = 11
pub let OP_ANY: c_uint = 12
pub let OP_ALLANY: c_uint = 13
pub let OP_ANYBYTE: c_uint = 14
pub let OP_NOTPROP: c_uint = 15
pub let OP_PROP: c_uint = 16
pub let OP_ANYNL: c_uint = 17
pub let OP_NOT_HSPACE: c_uint = 18
pub let OP_HSPACE: c_uint = 19
pub let OP_NOT_VSPACE: c_uint = 20
pub let OP_VSPACE: c_uint = 21
pub let OP_EXTUNI: c_uint = 22
pub let OP_EODN: c_uint = 23
pub let OP_EOD: c_uint = 24
pub let OP_DOLL: c_uint = 25
pub let OP_DOLLM: c_uint = 26
pub let OP_CIRC: c_uint = 27
pub let OP_CIRCM: c_uint = 28
pub let OP_CHAR: c_uint = 29
pub let OP_CHARI: c_uint = 30
pub let OP_NOT: c_uint = 31
pub let OP_NOTI: c_uint = 32
pub let OP_STAR: c_uint = 33
pub let OP_MINSTAR: c_uint = 34
pub let OP_PLUS: c_uint = 35
pub let OP_MINPLUS: c_uint = 36
pub let OP_QUERY: c_uint = 37
pub let OP_MINQUERY: c_uint = 38
pub let OP_UPTO: c_uint = 39
pub let OP_MINUPTO: c_uint = 40
pub let OP_EXACT: c_uint = 41
pub let OP_POSSTAR: c_uint = 42
pub let OP_POSPLUS: c_uint = 43
pub let OP_POSQUERY: c_uint = 44
pub let OP_POSUPTO: c_uint = 45
pub let OP_STARI: c_uint = 46
pub let OP_MINSTARI: c_uint = 47
pub let OP_PLUSI: c_uint = 48
pub let OP_MINPLUSI: c_uint = 49
pub let OP_QUERYI: c_uint = 50
pub let OP_MINQUERYI: c_uint = 51
pub let OP_UPTOI: c_uint = 52
pub let OP_MINUPTOI: c_uint = 53
pub let OP_EXACTI: c_uint = 54
pub let OP_POSSTARI: c_uint = 55
pub let OP_POSPLUSI: c_uint = 56
pub let OP_POSQUERYI: c_uint = 57
pub let OP_POSUPTOI: c_uint = 58
pub let OP_NOTSTAR: c_uint = 59
pub let OP_NOTMINSTAR: c_uint = 60
pub let OP_NOTPLUS: c_uint = 61
pub let OP_NOTMINPLUS: c_uint = 62
pub let OP_NOTQUERY: c_uint = 63
pub let OP_NOTMINQUERY: c_uint = 64
pub let OP_NOTUPTO: c_uint = 65
pub let OP_NOTMINUPTO: c_uint = 66
pub let OP_NOTEXACT: c_uint = 67
pub let OP_NOTPOSSTAR: c_uint = 68
pub let OP_NOTPOSPLUS: c_uint = 69
pub let OP_NOTPOSQUERY: c_uint = 70
pub let OP_NOTPOSUPTO: c_uint = 71
pub let OP_NOTSTARI: c_uint = 72
pub let OP_NOTMINSTARI: c_uint = 73
pub let OP_NOTPLUSI: c_uint = 74
pub let OP_NOTMINPLUSI: c_uint = 75
pub let OP_NOTQUERYI: c_uint = 76
pub let OP_NOTMINQUERYI: c_uint = 77
pub let OP_NOTUPTOI: c_uint = 78
pub let OP_NOTMINUPTOI: c_uint = 79
pub let OP_NOTEXACTI: c_uint = 80
pub let OP_NOTPOSSTARI: c_uint = 81
pub let OP_NOTPOSPLUSI: c_uint = 82
pub let OP_NOTPOSQUERYI: c_uint = 83
pub let OP_NOTPOSUPTOI: c_uint = 84
pub let OP_TYPESTAR: c_uint = 85
pub let OP_TYPEMINSTAR: c_uint = 86
pub let OP_TYPEPLUS: c_uint = 87
pub let OP_TYPEMINPLUS: c_uint = 88
pub let OP_TYPEQUERY: c_uint = 89
pub let OP_TYPEMINQUERY: c_uint = 90
pub let OP_TYPEUPTO: c_uint = 91
pub let OP_TYPEMINUPTO: c_uint = 92
pub let OP_TYPEEXACT: c_uint = 93
pub let OP_TYPEPOSSTAR: c_uint = 94
pub let OP_TYPEPOSPLUS: c_uint = 95
pub let OP_TYPEPOSQUERY: c_uint = 96
pub let OP_TYPEPOSUPTO: c_uint = 97
pub let OP_CRSTAR: c_uint = 98
pub let OP_CRMINSTAR: c_uint = 99
pub let OP_CRPLUS: c_uint = 100
pub let OP_CRMINPLUS: c_uint = 101
pub let OP_CRQUERY: c_uint = 102
pub let OP_CRMINQUERY: c_uint = 103
pub let OP_CRRANGE: c_uint = 104
pub let OP_CRMINRANGE: c_uint = 105
pub let OP_CRPOSSTAR: c_uint = 106
pub let OP_CRPOSPLUS: c_uint = 107
pub let OP_CRPOSQUERY: c_uint = 108
pub let OP_CRPOSRANGE: c_uint = 109
pub let OP_CLASS: c_uint = 110
pub let OP_NCLASS: c_uint = 111
pub let OP_XCLASS: c_uint = 112
pub let OP_ECLASS: c_uint = 113
pub let OP_REF: c_uint = 114
pub let OP_REFI: c_uint = 115
pub let OP_DNREF: c_uint = 116
pub let OP_DNREFI: c_uint = 117
pub let OP_RECURSE: c_uint = 118
pub let OP_CALLOUT: c_uint = 119
pub let OP_CALLOUT_STR: c_uint = 120
pub let OP_ALT: c_uint = 121
pub let OP_KET: c_uint = 122
pub let OP_KETRMAX: c_uint = 123
pub let OP_KETRMIN: c_uint = 124
pub let OP_KETRPOS: c_uint = 125
pub let OP_REVERSE: c_uint = 126
pub let OP_VREVERSE: c_uint = 127
pub let OP_ASSERT: c_uint = 128
pub let OP_ASSERT_NOT: c_uint = 129
pub let OP_ASSERTBACK: c_uint = 130
pub let OP_ASSERTBACK_NOT: c_uint = 131
pub let OP_ASSERT_NA: c_uint = 132
pub let OP_ASSERTBACK_NA: c_uint = 133
pub let OP_ASSERT_SCS: c_uint = 134
pub let OP_ONCE: c_uint = 135
pub let OP_SCRIPT_RUN: c_uint = 136
pub let OP_BRA: c_uint = 137
pub let OP_BRAPOS: c_uint = 138
pub let OP_CBRA: c_uint = 139
pub let OP_CBRAPOS: c_uint = 140
pub let OP_COND: c_uint = 141
pub let OP_SBRA: c_uint = 142
pub let OP_SBRAPOS: c_uint = 143
pub let OP_SCBRA: c_uint = 144
pub let OP_SCBRAPOS: c_uint = 145
pub let OP_SCOND: c_uint = 146
pub let OP_CREF: c_uint = 147
pub let OP_DNCREF: c_uint = 148
pub let OP_RREF: c_uint = 149
pub let OP_DNRREF: c_uint = 150
pub let OP_FALSE: c_uint = 151
pub let OP_TRUE: c_uint = 152
pub let OP_BRAZERO: c_uint = 153
pub let OP_BRAMINZERO: c_uint = 154
pub let OP_BRAPOSZERO: c_uint = 155
pub let OP_MARK: c_uint = 156
pub let OP_PRUNE: c_uint = 157
pub let OP_PRUNE_ARG: c_uint = 158
pub let OP_SKIP: c_uint = 159
pub let OP_SKIP_ARG: c_uint = 160
pub let OP_THEN: c_uint = 161
pub let OP_THEN_ARG: c_uint = 162
pub let OP_COMMIT: c_uint = 163
pub let OP_COMMIT_ARG: c_uint = 164
pub let OP_FAIL: c_uint = 165
pub let OP_ACCEPT: c_uint = 166
pub let OP_ASSERT_ACCEPT: c_uint = 167
pub let OP_CLOSE: c_uint = 168
pub let OP_SKIPZERO: c_uint = 169
pub let OP_DEFINE: c_uint = 170
pub let OP_NOT_UCP_WORD_BOUNDARY: c_uint = 171
pub let OP_UCP_WORD_BOUNDARY: c_uint = 172
pub let OP_TABLE_LENGTH: c_uint = 173
pub type pcre2_memctl { malloc: unsafe extern "C" fn(c_ulong, *mut c_void) -> *mut c_void, free: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, memory_data: *mut c_void = null }
impl Copy for pcre2_memctl

pub type open_capitem { next: *mut open_capitem = null, number: c_ushort = 0, assert_depth: c_ushort = 0 }
impl Copy for open_capitem

pub type ucp_type_table { name_offset: c_ushort = 0, type_: c_ushort = 0, value: c_ushort = 0 }
impl Copy for ucp_type_table

pub type ucd_record { script: u8 = 0, chartype: u8 = 0, gbprop: u8 = 0, caseset: u8 = 0, other_case: c_int = 0, scriptx_bidiclass: c_ushort = 0, bprops: c_ushort = 0 }
impl Copy for ucd_record

pub type pcre2_serialized_data { magic: c_uint = 0, version: c_uint = 0, config: c_uint = 0, number_of_codes: c_int = 0 }
impl Copy for pcre2_serialized_data

pub type pcre2_real_general_context_8 { memctl: pcre2_memctl }
impl Copy for pcre2_real_general_context_8

pub type pcre2_real_compile_context_8 { memctl: pcre2_memctl, stack_guard: unsafe extern "C" fn(c_uint, *mut c_void) -> c_int, stack_guard_data: *mut c_void = null, tables: *const u8 = null, max_pattern_length: c_ulong = 0, max_pattern_compiled_length: c_ulong = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, parens_nest_limit: c_uint = 0, extra_options: c_uint = 0, max_varlookbehind: c_uint = 0, optimization_flags: c_uint = 0 }
impl Copy for pcre2_real_compile_context_8

pub type pcre2_real_match_context_8 { memctl: pcre2_memctl, callout: unsafe extern "C" fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int, callout_data: *mut c_void = null, substitute_callout: unsafe extern "C" fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int, substitute_callout_data: *mut c_void = null, substitute_case_callout: unsafe extern "C" fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, substitute_case_callout_data: *mut c_void = null, offset_limit: c_ulong = 0, heap_limit: c_uint = 0, match_limit: c_uint = 0, depth_limit: c_uint = 0 }
impl Copy for pcre2_real_match_context_8

pub type pcre2_real_convert_context_8 { memctl: pcre2_memctl, glob_separator: c_uint = 0, glob_escape: c_uint = 0 }
impl Copy for pcre2_real_convert_context_8

pub type pcre2_real_code_8 { memctl: pcre2_memctl, tables: *const u8 = null, executable_jit: *mut c_void = null, start_bitmap: [32]u8 = [0 as u8; 32], blocksize: c_ulong = 0, code_start: c_ulong = 0, magic_number: c_uint = 0, compile_options: c_uint = 0, overall_options: c_uint = 0, extra_options: c_uint = 0, flags: c_uint = 0, limit_heap: c_uint = 0, limit_match: c_uint = 0, limit_depth: c_uint = 0, first_codeunit: c_uint = 0, last_codeunit: c_uint = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, max_lookbehind: c_ushort = 0, minlength: c_ushort = 0, top_bracket: c_ushort = 0, top_backref: c_ushort = 0, name_entry_size: c_ushort = 0, name_count: c_ushort = 0, optimization_flags: c_uint = 0 }
impl Copy for pcre2_real_code_8

pub type pcre2_real_match_data_8 { memctl: pcre2_memctl, code: *const pcre2_real_code_8 = null, subject: *const u8 = null, mark: *const u8 = null, heapframes: *mut heapframe = null, heapframes_size: c_ulong = 0, subject_length: c_ulong = 0, start_offset: c_ulong = 0, leftchar: c_ulong = 0, rightchar: c_ulong = 0, startchar: c_ulong = 0, matchedby: u8 = 0, flags: u8 = 0, oveccount: c_ushort = 0, options: c_uint = 0, rc: c_int = 0, ovector: [131072]c_ulong = [0 as c_ulong; 131072] }
impl Copy for pcre2_real_match_data_8

pub type recurse_check { prev: *mut recurse_check = null, group: *const u8 = null }
impl Copy for recurse_check

pub type parsed_recurse_check { prev: *mut parsed_recurse_check = null, groupptr: *mut c_uint = null }
impl Copy for parsed_recurse_check

pub type recurse_cache { group: *const u8 = null, groupnumber: c_int = 0 }
impl Copy for recurse_cache

pub type branch_chain_8 { outer: *mut branch_chain_8 = null, current_branch: *mut u8 = null }
impl Copy for branch_chain_8

pub type named_group_8 { name: *const u8 = null, number: c_uint = 0, length: c_ushort = 0, hash_dup: c_ushort = 0 }
impl Copy for named_group_8

pub type compile_data { next: *mut compile_data = null }
impl Copy for compile_data

pub type class_ranges { header: compile_data, char_lists_size: c_ulong = 0, char_lists_start: c_ulong = 0, range_list_size: c_ushort = 0, char_lists_types: c_ushort = 0 }
impl Copy for class_ranges

pub type recurse_arguments { header: compile_data, size: c_ulong = 0, skip_size: c_ulong = 0 }
impl Copy for recurse_arguments

pub type class_bits_storage = union { classbits: [32]u8 = [0 as u8; 32], classwords: [8]c_uint = [0 as c_uint; 8] }
impl Copy for class_bits_storage

pub type compile_block_8 { cx: *mut pcre2_real_compile_context_8 = null, lcc: *const u8 = null, fcc: *const u8 = null, cbits: *const u8 = null, ctypes: *const u8 = null, start_workspace: *mut u8 = null, start_code: *mut u8 = null, start_pattern: *const u8 = null, end_pattern: *const u8 = null, name_table: *mut u8 = null, workspace_size: c_ulong = 0, small_ref_offset: [10]c_ulong = [0 as c_ulong; 10], erroroffset: c_ulong = 0, classbits: class_bits_storage, names_found: c_ushort = 0, name_entry_size: c_ushort = 0, parens_depth: c_ushort = 0, assert_depth: c_ushort = 0, named_groups: *mut named_group_8 = null, named_group_list_size: c_uint = 0, external_options: c_uint = 0, external_flags: c_uint = 0, bracount: c_uint = 0, lastcapture: c_uint = 0, parsed_pattern: *mut c_uint = null, parsed_pattern_end: *mut c_uint = null, groupinfo: *mut c_uint = null, top_backref: c_uint = 0, backref_map: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], class_op_used: [15]u8 = [0 as u8; 15], req_varyopt: c_uint = 0, max_varlookbehind: c_uint = 0, max_lookbehind: c_int = 0, had_accept: c_int = 0, had_pruneorskip: c_int = 0, had_recurse: c_int = 0, dupnames: c_int = 0, first_data: *mut compile_data = null, last_data: *mut compile_data = null, char_lists_size: c_ulong = 0 }
impl Copy for compile_block_8

pub type pcre2_real_jit_stack_8 { memctl: pcre2_memctl, stack: *mut c_void = null }
impl Copy for pcre2_real_jit_stack_8

pub type dfa_recursion_info { prevrec: *mut dfa_recursion_info = null, subject_position: *const u8 = null, last_used_ptr: *const u8 = null, group_num: c_uint = 0 }
impl Copy for dfa_recursion_info

pub type heapframe { ecode: *const u8 = null, temp_sptr: [2]*const u8 = [null as *const u8; 2], length: c_ulong = 0, back_frame: c_ulong = 0, temp_size: c_ulong = 0, rdepth: c_uint = 0, group_frame_type: c_uint = 0, temp_32: [4]c_uint = [0 as c_uint; 4], return_id: u8 = 0, op: u8 = 0, occu: [6]u8 = [0 as u8; 6], eptr: *const u8 = null, start_match: *const u8 = null, mark: *const u8 = null, recurse_last_used: *const u8 = null, current_recurse: c_uint = 0, capture_last: c_uint = 0, last_group_offset: c_ulong = 0, offset_top: c_ulong = 0, ovector: [131072]c_ulong = [0 as c_ulong; 131072] }
impl Copy for heapframe

pub type static_assertion_heapframe_size = [1]c_int

pub type heapframe_align { unalign: c_char = 0, frame: heapframe }
impl Copy for heapframe_align

pub type match_block_8 { memctl: pcre2_memctl, heap_limit: c_uint = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, hitend: c_int = 0, hasthen: c_int = 0, hasbsk: c_int = 0, allowemptypartial: c_int = 0, allowlookaroundbsk: c_int = 0, lcc: *const u8 = null, fcc: *const u8 = null, ctypes: *const u8 = null, start_offset: c_ulong = 0, end_offset_top: c_ulong = 0, partial: c_ushort = 0, bsr_convention: c_ushort = 0, name_count: c_ushort = 0, name_entry_size: c_ushort = 0, name_table: *const u8 = null, start_code: *const u8 = null, start_subject: *const u8 = null, check_subject: *const u8 = null, end_subject: *const u8 = null, true_end_subject: *const u8 = null, end_match_ptr: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, mark: *const u8 = null, nomatch_mark: *const u8 = null, verb_ecode_ptr: *const u8 = null, verb_skip_ptr: *const u8 = null, verb_current_recurse: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, skip_arg_count: c_uint = 0, ignore_skip_arg: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: unsafe extern "C" fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int }
impl Copy for match_block_8

pub type dfa_match_block_8 { memctl: pcre2_memctl, start_code: *const u8 = null, start_subject: *const u8 = null, end_subject: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, tables: *const u8 = null, start_offset: c_ulong = 0, heap_limit: c_uint = 0, heap_used: c_ulong = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, allowemptypartial: c_int = 0, nl: [4]u8 = [0 as u8; 4], bsr_convention: c_ushort = 0, cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: unsafe extern "C" fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int, recursive: *mut dfa_recursion_info = null }
impl Copy for dfa_match_block_8

pub let PCRE2_CODE_UNIT_WIDTH: c_int = 8
pub let HAVE_CONFIG_H: c_int = 1
pub let HAVE_UNISTD_H: c_int = 1
pub let USE_CLANG_TYPES: c_int = 0
pub let USE_CLANG_STDDEF: c_int = 0
pub let USER_ADDR_NULL: c_ulonglong = (0 as c_ulonglong)
pub let USE_CLANG_STDARG: c_int = 0
pub let RENAME_SECLUDE: c_int = 0x00000001
pub let RENAME_SWAP: c_int = 0x00000002
pub let RENAME_EXCL: c_int = 0x00000004
pub let RENAME_RESERVED1: c_int = 0x00000008
pub let RENAME_NOFOLLOW_ANY: c_int = 0x00000010
pub let RENAME_RESOLVE_BENEATH: c_int = 0x00000020
pub let SEEK_SET: c_int = 0
pub let SEEK_CUR: c_int = 1
pub let SEEK_END: c_int = 2
pub let SEEK_HOLE: c_int = 3
pub let SEEK_DATA: c_int = 4
pub let BUFSIZ: c_int = 1024
pub let EOF: c_int = -1
pub let FOPEN_MAX: c_int = 20
pub let FILENAME_MAX: c_int = 1024
pub let P_tmpdir = "/var/tmp/"
pub let L_tmpnam: c_int = 1024
pub let TMP_MAX: c_int = 308915776
pub let L_ctermid: c_int = 1024
pub let WITH_PCRE2_CONFIG_H: c_int = 1
pub let SUPPORT_PCRE2_8: c_int = 1
pub let SUPPORT_UNICODE: c_int = 1
pub let HEAP_LIMIT: c_int = 20000000
pub let LINK_SIZE: c_int = 2
pub let LT_OBJDIR = ".libs/"
pub let MATCH_LIMIT: c_int = 10000000
pub let MATCH_LIMIT_DEPTH: c_int = 10000000
pub let MAX_NAME_COUNT: c_int = 10000
pub let MAX_NAME_SIZE: c_int = 128
pub let MAX_VARLOOKBEHIND: c_int = 255
pub let NEWLINE_DEFAULT: c_int = 2
pub let PACKAGE = "pcre2"
pub let PACKAGE_BUGREPORT = ""
pub let PACKAGE_NAME = "PCRE2"
pub let PACKAGE_STRING = "PCRE2 10.47"
pub let PACKAGE_TARNAME = "pcre2"
pub let PACKAGE_URL = ""
pub let PACKAGE_VERSION = "10.47"
pub let PARENS_NEST_LIMIT: c_int = 250
pub let PCRE2GREP_BUFSIZE: c_int = 20480
pub let PCRE2GREP_MAX_BUFSIZE: c_int = 1048576
pub let VERSION = "10.47"
pub let USE_CLANG_LIMITS: c_int = 0
pub let MB_LEN_MAX: c_int = 6
pub let CHAR_BIT: c_int = 8
pub let SCHAR_MAX: c_int = 127
pub let SCHAR_MIN: c_int = -128
pub let UCHAR_MAX: c_int = 255
pub let CHAR_MAX: c_int = 127
pub let CHAR_MIN: c_int = -128
pub let USHRT_MAX: c_int = 65535
pub let SHRT_MAX: c_int = 32767
pub let SHRT_MIN: c_int = -32768
pub let UINT_MAX: c_uint = 0xffffffff
pub let INT_MAX: c_int = 2147483647
pub let INT_MIN: c_int = (-2147483647 - 1)
pub let ULONG_MAX: c_ulong = 0xffffffffffffffff
pub let LONG_MAX: c_long = 0x7fffffffffffffff
pub let LONG_MIN: c_long = (-0x7fffffffffffffff - 1)
pub let ULLONG_MAX: c_ulonglong = 0xffffffffffffffff
pub let LLONG_MAX: c_longlong = 0x7fffffffffffffff
pub let LLONG_MIN: c_longlong = (-0x7fffffffffffffff - 1)
pub let LONG_BIT: c_int = 64
pub let SSIZE_MAX: c_long = 0x7fffffffffffffff
pub let WORD_BIT: c_int = 32
pub let SIZE_T_MAX: c_ulong = 0xffffffffffffffff
pub let UQUAD_MAX: c_ulonglong = 0xffffffffffffffff
pub let QUAD_MAX: c_longlong = 0x7fffffffffffffff
pub let QUAD_MIN = LLONG_MIN
pub let ARG_MAX: c_int = (1024 * 1024)
pub let CHILD_MAX: c_int = 266
pub let GID_MAX: c_uint = 2147483647
pub let LINK_MAX: c_int = 32767
pub let MAX_CANON: c_int = 1024
pub let MAX_INPUT: c_int = 1024
pub let NAME_MAX: c_int = 255
pub let NGROUPS_MAX: c_int = 16
pub let UID_MAX: c_uint = 2147483647
pub let OPEN_MAX: c_int = 10240
pub let PATH_MAX: c_int = 1024
pub let PIPE_BUF: c_int = 512
pub let BC_BASE_MAX: c_int = 99
pub let BC_DIM_MAX: c_int = 2048
pub let BC_SCALE_MAX: c_int = 99
pub let BC_STRING_MAX: c_int = 1000
pub let CHARCLASS_NAME_MAX: c_int = 14
pub let COLL_WEIGHTS_MAX: c_int = 2
pub let EQUIV_CLASS_MAX: c_int = 2
pub let EXPR_NEST_MAX: c_int = 32
pub let LINE_MAX: c_int = 2048
pub let RE_DUP_MAX: c_int = 255
pub let NZERO: c_int = 20
pub let PTHREAD_DESTRUCTOR_ITERATIONS: c_int = 4
pub let PTHREAD_KEYS_MAX: c_int = 512
pub let PTHREAD_STACK_MIN: c_int = 16384
pub let OFF_MIN = LLONG_MIN
pub let OFF_MAX: c_longlong = 0x7fffffffffffffff
pub let NL_ARGMAX: c_int = 9
pub let NL_LANGMAX: c_int = 14
pub let NL_MSGMAX: c_int = 32767
pub let NL_NMAX: c_int = 1
pub let NL_SETMAX: c_int = 255
pub let NL_TEXTMAX: c_int = 2048
pub let IOV_MAX: c_int = 1024
pub let LONG_LONG_MAX: c_longlong = 9223372036854775807
pub let LONG_LONG_MIN: c_longlong = (0 - 9223372036854775807 - 1)
pub let ULONG_LONG_MAX: c_ulonglong = ((0 as c_ulonglong) -% 1)
pub let NULL: *mut c_void = null
pub let SIGHUP: c_int = 1
pub let SIGINT: c_int = 2
pub let SIGQUIT: c_int = 3
pub let SIGILL: c_int = 4
pub let SIGTRAP: c_int = 5
pub let SIGABRT: c_int = 6
pub let SIGIOT: c_int = 6
pub let SIGEMT: c_int = 7
pub let SIGFPE: c_int = 8
pub let SIGKILL: c_int = 9
pub let SIGBUS: c_int = 10
pub let SIGSEGV: c_int = 11
pub let SIGSYS: c_int = 12
pub let SIGPIPE: c_int = 13
pub let SIGALRM: c_int = 14
pub let SIGTERM: c_int = 15
pub let SIGURG: c_int = 16
pub let SIGSTOP: c_int = 17
pub let SIGTSTP: c_int = 18
pub let SIGCONT: c_int = 19
pub let SIGCHLD: c_int = 20
pub let SIGTTIN: c_int = 21
pub let SIGTTOU: c_int = 22
pub let SIGIO: c_int = 23
pub let SIGXCPU: c_int = 24
pub let SIGXFSZ: c_int = 25
pub let SIGVTALRM: c_int = 26
pub let SIGPROF: c_int = 27
pub let SIGWINCH: c_int = 28
pub let SIGINFO: c_int = 29
pub let SIGUSR1: c_int = 30
pub let SIGUSR2: c_int = 31
pub let SIGEV_NONE: c_int = 0
pub let SIGEV_SIGNAL: c_int = 1
pub let SIGEV_THREAD: c_int = 3
pub let SIGEV_KEVENT: c_int = 4
pub let ILL_NOOP: c_int = 0
pub let ILL_ILLOPC: c_int = 1
pub let ILL_ILLTRP: c_int = 2
pub let ILL_PRVOPC: c_int = 3
pub let ILL_ILLOPN: c_int = 4
pub let ILL_ILLADR: c_int = 5
pub let ILL_PRVREG: c_int = 6
pub let ILL_COPROC: c_int = 7
pub let ILL_BADSTK: c_int = 8
pub let FPE_NOOP: c_int = 0
pub let FPE_FLTDIV: c_int = 1
pub let FPE_FLTOVF: c_int = 2
pub let FPE_FLTUND: c_int = 3
pub let FPE_FLTRES: c_int = 4
pub let FPE_FLTINV: c_int = 5
pub let FPE_FLTSUB: c_int = 6
pub let FPE_INTDIV: c_int = 7
pub let FPE_INTOVF: c_int = 8
pub let SEGV_NOOP: c_int = 0
pub let SEGV_MAPERR: c_int = 1
pub let SEGV_ACCERR: c_int = 2
pub let BUS_NOOP: c_int = 0
pub let BUS_ADRALN: c_int = 1
pub let BUS_ADRERR: c_int = 2
pub let BUS_OBJERR: c_int = 3
pub let TRAP_BRKPT: c_int = 1
pub let TRAP_TRACE: c_int = 2
pub let CLD_NOOP: c_int = 0
pub let CLD_EXITED: c_int = 1
pub let CLD_KILLED: c_int = 2
pub let CLD_DUMPED: c_int = 3
pub let CLD_TRAPPED: c_int = 4
pub let CLD_STOPPED: c_int = 5
pub let CLD_CONTINUED: c_int = 6
pub let POLL_IN: c_int = 1
pub let POLL_OUT: c_int = 2
pub let POLL_MSG: c_int = 3
pub let POLL_ERR: c_int = 4
pub let POLL_PRI: c_int = 5
pub let POLL_HUP: c_int = 6
pub let SA_ONSTACK: c_int = 0x0001
pub let SA_RESTART: c_int = 0x0002
pub let SA_RESETHAND: c_int = 0x0004
pub let SA_NOCLDSTOP: c_int = 0x0008
pub let SA_NODEFER: c_int = 0x0010
pub let SA_NOCLDWAIT: c_int = 0x0020
pub let SA_SIGINFO: c_int = 0x0040
pub let SA_USERTRAMP: c_int = 0x0100
pub let SA_64REGSET: c_int = 0x0200
pub let SA_USERSPACE_MASK: c_int = 127
pub let SIG_BLOCK: c_int = 1
pub let SIG_UNBLOCK: c_int = 2
pub let SIG_SETMASK: c_int = 3
pub let SI_USER: c_int = 0x10001
pub let SI_QUEUE: c_int = 0x10002
pub let SI_TIMER: c_int = 0x10003
pub let SI_ASYNCIO: c_int = 0x10004
pub let SI_MESGQ: c_int = 0x10005
pub let SS_ONSTACK: c_int = 0x0001
pub let SS_DISABLE: c_int = 0x0004
pub let MINSIGSTKSZ: c_int = 32768
pub let SIGSTKSZ: c_int = 131072
pub let SV_ONSTACK: c_int = 0x0001
pub let SV_INTERRUPT: c_int = 0x0002
pub let SV_RESETHAND: c_int = 0x0004
pub let SV_NODEFER: c_int = 0x0010
pub let SV_NOCLDSTOP: c_int = 0x0008
pub let SV_SIGINFO: c_int = 0x0040
pub fn INT8_C[T](v: T) -> T {
    v
}
pub fn INT16_C[T](v: T) -> T {
    v
}
pub fn INT32_C[T](v: T) -> T {
    v
}
pub fn INT64_C[T](v: T) -> i64 {
    (v as i64)
}
pub fn UINT8_C[T](v: T) -> T {
    v
}
pub fn UINT16_C[T](v: T) -> T {
    v
}
pub fn UINT32_C[T](v: T) -> u32 {
    (v as u32)
}
pub fn UINT64_C[T](v: T) -> u64 {
    (v as u64)
}
pub fn INTMAX_C[T](v: T) -> i64 {
    (v as i64)
}
pub fn UINTMAX_C[T](v: T) -> u64 {
    (v as u64)
}
pub let INT8_MAX: c_int = 127
pub let INT16_MAX: c_int = 32767
pub let INT32_MAX: c_int = 2147483647
pub let INT64_MAX: c_longlong = 9223372036854775807
pub let INT8_MIN: c_int = -128
pub let INT16_MIN: c_int = -32768
pub let INT32_MIN: c_int = ((0 - 2147483647) - 1)
pub let INT64_MIN: c_longlong = ((0 - 9223372036854775807) - 1)
pub let UINT8_MAX: c_int = 255
pub let UINT16_MAX: c_int = 65535
pub let UINT32_MAX: c_uint = 4294967295
pub let UINT64_MAX: c_ulonglong = 18446744073709551615
pub let INT_LEAST8_MIN: c_int = -128
pub let INT_LEAST16_MIN: c_int = -32768
pub let INT_LEAST32_MIN = INT32_MIN
pub let INT_LEAST64_MIN = INT64_MIN
pub let INT_LEAST8_MAX: c_int = 127
pub let INT_LEAST16_MAX: c_int = 32767
pub let INT_LEAST32_MAX: c_int = 2147483647
pub let INT_LEAST64_MAX: c_longlong = 9223372036854775807
pub let UINT_LEAST8_MAX: c_int = 255
pub let UINT_LEAST16_MAX: c_int = 65535
pub let UINT_LEAST32_MAX: c_uint = 4294967295
pub let UINT_LEAST64_MAX: c_ulonglong = 18446744073709551615
pub let INT_FAST8_MIN: c_int = -128
pub let INT_FAST16_MIN: c_int = -32768
pub let INT_FAST32_MIN = INT32_MIN
pub let INT_FAST64_MIN = INT64_MIN
pub let INT_FAST8_MAX: c_int = 127
pub let INT_FAST16_MAX: c_int = 32767
pub let INT_FAST32_MAX: c_int = 2147483647
pub let INT_FAST64_MAX: c_longlong = 9223372036854775807
pub let UINT_FAST8_MAX: c_int = 255
pub let UINT_FAST16_MAX: c_int = 65535
pub let UINT_FAST32_MAX: c_uint = 4294967295
pub let UINT_FAST64_MAX: c_ulonglong = 18446744073709551615
pub let INTPTR_MAX: c_long = 9223372036854775807
pub let INTPTR_MIN: c_long = ((0 - 9223372036854775807) - 1)
pub let UINTPTR_MAX: c_ulong = 18446744073709551615
pub let INTMAX_MAX: c_long = INTMAX_C(9223372036854775807)
pub let UINTMAX_MAX: c_ulong = UINTMAX_C(18446744073709551615u64)
pub let INTMAX_MIN: c_long = ((0 - INTMAX_MAX) - 1)
pub let PTRDIFF_MIN = INTMAX_MIN
pub let PTRDIFF_MAX = INTMAX_MAX
pub let SIZE_MAX: c_ulong = 18446744073709551615
pub let RSIZE_MAX: c_ulong = (SIZE_MAX >> 1)
pub let WINT_MIN = INT32_MIN
pub let WINT_MAX: c_int = 2147483647
pub let SIG_ATOMIC_MIN = INT32_MIN
pub let SIG_ATOMIC_MAX: c_int = 2147483647
pub let PRIO_PROCESS: c_int = 0
pub let PRIO_PGRP: c_int = 1
pub let PRIO_USER: c_int = 2
pub let PRIO_DARWIN_THREAD: c_int = 3
pub let PRIO_DARWIN_PROCESS: c_int = 4
pub let PRIO_MIN: c_int = -20
pub let PRIO_MAX: c_int = 20
pub let PRIO_DARWIN_BG: c_int = 0x1000
pub let PRIO_DARWIN_NONUI: c_int = 0x1001
pub let RUSAGE_SELF: c_int = 0
pub let RUSAGE_CHILDREN: c_int = -1
pub let RUSAGE_INFO_V0: c_int = 0
pub let RUSAGE_INFO_V1: c_int = 1
pub let RUSAGE_INFO_V2: c_int = 2
pub let RUSAGE_INFO_V3: c_int = 3
pub let RUSAGE_INFO_V4: c_int = 4
pub let RUSAGE_INFO_V5: c_int = 5
pub let RUSAGE_INFO_V6: c_int = 6
pub let RUSAGE_INFO_CURRENT: c_int = 6
pub let RU_PROC_RUNS_RESLIDE: c_int = 0x00000001
pub let RLIMIT_CPU: c_int = 0
pub let RLIMIT_FSIZE: c_int = 1
pub let RLIMIT_DATA: c_int = 2
pub let RLIMIT_STACK: c_int = 3
pub let RLIMIT_CORE: c_int = 4
pub let RLIMIT_AS: c_int = 5
pub let RLIMIT_RSS: c_int = 5
pub let RLIMIT_MEMLOCK: c_int = 6
pub let RLIMIT_NPROC: c_int = 7
pub let RLIMIT_NOFILE: c_int = 8
pub let RLIM_NLIMITS: c_int = 9
pub let RLIMIT_WAKEUPS_MONITOR: c_int = 0x1
pub let RLIMIT_CPU_USAGE_MONITOR: c_int = 0x2
pub let RLIMIT_THREAD_CPULIMITS: c_int = 0x3
pub let RLIMIT_FOOTPRINT_INTERVAL: c_int = 0x4
pub let WAKEMON_ENABLE: c_int = 0x01
pub let WAKEMON_DISABLE: c_int = 0x02
pub let WAKEMON_GET_PARAMS: c_int = 0x04
pub let WAKEMON_SET_DEFAULTS: c_int = 0x08
pub let WAKEMON_MAKE_FATAL: c_int = 0x10
pub let CPUMON_MAKE_FATAL: c_int = 0x1000
pub let FOOTPRINT_INTERVAL_RESET: c_int = 0x1
pub let IOPOL_TYPE_DISK: c_int = 0
pub let IOPOL_TYPE_VFS_ATIME_UPDATES: c_int = 2
pub let IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES: c_int = 3
pub let IOPOL_TYPE_VFS_STATFS_NO_DATA_VOLUME: c_int = 4
pub let IOPOL_TYPE_VFS_TRIGGER_RESOLVE: c_int = 5
pub let IOPOL_TYPE_VFS_IGNORE_CONTENT_PROTECTION: c_int = 6
pub let IOPOL_TYPE_VFS_IGNORE_PERMISSIONS: c_int = 7
pub let IOPOL_TYPE_VFS_SKIP_MTIME_UPDATE: c_int = 8
pub let IOPOL_TYPE_VFS_ALLOW_LOW_SPACE_WRITES: c_int = 9
pub let IOPOL_TYPE_VFS_DISALLOW_RW_FOR_O_EVTONLY: c_int = 10
pub let IOPOL_TYPE_VFS_ENTITLED_RESERVE_ACCESS: c_int = 14
pub let IOPOL_SCOPE_PROCESS: c_int = 0
pub let IOPOL_SCOPE_THREAD: c_int = 1
pub let IOPOL_SCOPE_DARWIN_BG: c_int = 2
pub let IOPOL_DEFAULT: c_int = 0
pub let IOPOL_IMPORTANT: c_int = 1
pub let IOPOL_PASSIVE: c_int = 2
pub let IOPOL_THROTTLE: c_int = 3
pub let IOPOL_UTILITY: c_int = 4
pub let IOPOL_STANDARD: c_int = 5
pub let IOPOL_APPLICATION: c_int = 5
pub let IOPOL_NORMAL: c_int = 1
pub let IOPOL_ATIME_UPDATES_DEFAULT: c_int = 0
pub let IOPOL_ATIME_UPDATES_OFF: c_int = 1
pub let IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT: c_int = 0
pub let IOPOL_MATERIALIZE_DATALESS_FILES_OFF: c_int = 1
pub let IOPOL_MATERIALIZE_DATALESS_FILES_ON: c_int = 2
pub let IOPOL_MATERIALIZE_DATALESS_FILES_ORIG: c_int = 4
pub let IOPOL_MATERIALIZE_DATALESS_FILES_BASIC_MASK: c_int = 3
pub let IOPOL_VFS_STATFS_NO_DATA_VOLUME_DEFAULT: c_int = 0
pub let IOPOL_VFS_STATFS_FORCE_NO_DATA_VOLUME: c_int = 1
pub let IOPOL_VFS_TRIGGER_RESOLVE_DEFAULT: c_int = 0
pub let IOPOL_VFS_TRIGGER_RESOLVE_OFF: c_int = 1
pub let IOPOL_VFS_CONTENT_PROTECTION_DEFAULT: c_int = 0
pub let IOPOL_VFS_CONTENT_PROTECTION_IGNORE: c_int = 1
pub let IOPOL_VFS_IGNORE_PERMISSIONS_OFF: c_int = 0
pub let IOPOL_VFS_IGNORE_PERMISSIONS_ON: c_int = 1
pub let IOPOL_VFS_SKIP_MTIME_UPDATE_OFF: c_int = 0
pub let IOPOL_VFS_SKIP_MTIME_UPDATE_ON: c_int = 1
pub let IOPOL_VFS_SKIP_MTIME_UPDATE_IGNORE: c_int = 2
pub let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_OFF: c_int = 0
pub let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_ON: c_int = 1
pub let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_DEFAULT: c_int = 0
pub let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_ON: c_int = 1
pub let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_DEFAULT: c_int = 0
pub let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_ON: c_int = 1
pub let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_OFF: c_int = 0
pub let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_ON: c_int = 1
pub let WNOHANG: c_int = 0x00000001
pub let WUNTRACED: c_int = 0x00000002
pub let WCOREFLAG: c_int = 0200
pub fn W_EXITCODE[T](ret: T, sig: T) -> T {
    ((ret << 8) | sig)
}
pub let WEXITED: c_int = 0x00000004
pub let WSTOPPED: c_int = 0x00000008
pub let WCONTINUED: c_int = 0x00000010
pub let WNOWAIT: c_int = 0x00000020
pub let WAIT_ANY: c_int = -1
pub let WAIT_MYPGRP: c_int = 0
pub let EXIT_FAILURE: c_int = 1
pub let EXIT_SUCCESS: c_int = 0
pub let RAND_MAX: c_int = 0x7fffffff
pub let FALSE: c_int = 0
pub let TRUE: c_int = 1
pub let PCRE2_MAJOR: c_int = 10
pub let PCRE2_MINOR: c_int = 47
pub let PCRE2_DATE: c_int = 1994
pub let PRId16 = "hd"
pub let PRIi16 = "hi"
pub let PRIo16 = "ho"
pub let PRIu16 = "hu"
pub let PRIx16 = "hx"
pub let PRIX16 = "hX"
pub let PRId32 = "d"
pub let PRIi32 = "i"
pub let PRIo32 = "o"
pub let PRIu32 = "u"
pub let PRIx32 = "x"
pub let PRIX32 = "X"
pub let PRIdLEAST16 = PRId16
pub let PRIiLEAST16 = PRIi16
pub let PRIoLEAST16 = PRIo16
pub let PRIuLEAST16 = PRIu16
pub let PRIxLEAST16 = PRIx16
pub let PRIXLEAST16 = PRIX16
pub let PRIdLEAST32 = PRId32
pub let PRIiLEAST32 = PRIi32
pub let PRIoLEAST32 = PRIo32
pub let PRIuLEAST32 = PRIu32
pub let PRIxLEAST32 = PRIx32
pub let PRIXLEAST32 = PRIX32
pub let PRIdFAST16 = PRId16
pub let PRIiFAST16 = PRIi16
pub let PRIoFAST16 = PRIo16
pub let PRIuFAST16 = PRIu16
pub let PRIxFAST16 = PRIx16
pub let PRIXFAST16 = PRIX16
pub let PRIdFAST32 = PRId32
pub let PRIiFAST32 = PRIi32
pub let PRIoFAST32 = PRIo32
pub let PRIuFAST32 = PRIu32
pub let PRIxFAST32 = PRIx32
pub let PRIXFAST32 = PRIX32
pub let PRIdPTR = "ld"
pub let PRIiPTR = "li"
pub let PRIoPTR = "lo"
pub let PRIuPTR = "lu"
pub let PRIxPTR = "lx"
pub let PRIXPTR = "lX"
pub let SCNd16 = "hd"
pub let SCNi16 = "hi"
pub let SCNo16 = "ho"
pub let SCNu16 = "hu"
pub let SCNx16 = "hx"
pub let SCNd32 = "d"
pub let SCNi32 = "i"
pub let SCNo32 = "o"
pub let SCNu32 = "u"
pub let SCNx32 = "x"
pub let SCNdLEAST16 = SCNd16
pub let SCNiLEAST16 = SCNi16
pub let SCNoLEAST16 = SCNo16
pub let SCNuLEAST16 = SCNu16
pub let SCNxLEAST16 = SCNx16
pub let SCNdLEAST32 = SCNd32
pub let SCNiLEAST32 = SCNi32
pub let SCNoLEAST32 = SCNo32
pub let SCNuLEAST32 = SCNu32
pub let SCNxLEAST32 = SCNx32
pub let SCNdFAST16 = SCNd16
pub let SCNiFAST16 = SCNi16
pub let SCNoFAST16 = SCNo16
pub let SCNuFAST16 = SCNu16
pub let SCNxFAST16 = SCNx16
pub let SCNdFAST32 = SCNd32
pub let SCNiFAST32 = SCNi32
pub let SCNoFAST32 = SCNo32
pub let SCNuFAST32 = SCNu32
pub let SCNxFAST32 = SCNx32
pub let SCNdPTR = "ld"
pub let SCNiPTR = "li"
pub let SCNoPTR = "lo"
pub let SCNuPTR = "lu"
pub let SCNxPTR = "lx"
pub let PCRE2_ANCHORED: c_uint = 0x80000000
pub let PCRE2_NO_UTF_CHECK: c_uint = 0x40000000
pub let PCRE2_ENDANCHORED: c_uint = 0x20000000
pub let PCRE2_ALLOW_EMPTY_CLASS: c_uint = 0x00000001
pub let PCRE2_ALT_BSUX: c_uint = 0x00000002
pub let PCRE2_AUTO_CALLOUT: c_uint = 0x00000004
pub let PCRE2_CASELESS: c_uint = 0x00000008
pub let PCRE2_DOLLAR_ENDONLY: c_uint = 0x00000010
pub let PCRE2_DOTALL: c_uint = 0x00000020
pub let PCRE2_DUPNAMES: c_uint = 0x00000040
pub let PCRE2_EXTENDED: c_uint = 0x00000080
pub let PCRE2_FIRSTLINE: c_uint = 0x00000100
pub let PCRE2_MATCH_UNSET_BACKREF: c_uint = 0x00000200
pub let PCRE2_MULTILINE: c_uint = 0x00000400
pub let PCRE2_NEVER_UCP: c_uint = 0x00000800
pub let PCRE2_NEVER_UTF: c_uint = 0x00001000
pub let PCRE2_NO_AUTO_CAPTURE: c_uint = 0x00002000
pub let PCRE2_NO_AUTO_POSSESS: c_uint = 0x00004000
pub let PCRE2_NO_DOTSTAR_ANCHOR: c_uint = 0x00008000
pub let PCRE2_NO_START_OPTIMIZE: c_uint = 0x00010000
pub let PCRE2_UCP: c_uint = 0x00020000
pub let PCRE2_UNGREEDY: c_uint = 0x00040000
pub let PCRE2_UTF: c_uint = 0x00080000
pub let PCRE2_NEVER_BACKSLASH_C: c_uint = 0x00100000
pub let PCRE2_ALT_CIRCUMFLEX: c_uint = 0x00200000
pub let PCRE2_ALT_VERBNAMES: c_uint = 0x00400000
pub let PCRE2_USE_OFFSET_LIMIT: c_uint = 0x00800000
pub let PCRE2_EXTENDED_MORE: c_uint = 0x01000000
pub let PCRE2_LITERAL: c_uint = 0x02000000
pub let PCRE2_MATCH_INVALID_UTF: c_uint = 0x04000000
pub let PCRE2_ALT_EXTENDED_CLASS: c_uint = 0x08000000
pub let PCRE2_EXTRA_ALLOW_SURROGATE_ESCAPES: c_uint = 0x00000001
pub let PCRE2_EXTRA_BAD_ESCAPE_IS_LITERAL: c_uint = 0x00000002
pub let PCRE2_EXTRA_MATCH_WORD: c_uint = 0x00000004
pub let PCRE2_EXTRA_MATCH_LINE: c_uint = 0x00000008
pub let PCRE2_EXTRA_ESCAPED_CR_IS_LF: c_uint = 0x00000010
pub let PCRE2_EXTRA_ALT_BSUX: c_uint = 0x00000020
pub let PCRE2_EXTRA_ALLOW_LOOKAROUND_BSK: c_uint = 0x00000040
pub let PCRE2_EXTRA_CASELESS_RESTRICT: c_uint = 0x00000080
pub let PCRE2_EXTRA_ASCII_BSD: c_uint = 0x00000100
pub let PCRE2_EXTRA_ASCII_BSS: c_uint = 0x00000200
pub let PCRE2_EXTRA_ASCII_BSW: c_uint = 0x00000400
pub let PCRE2_EXTRA_ASCII_POSIX: c_uint = 0x00000800
pub let PCRE2_EXTRA_ASCII_DIGIT: c_uint = 0x00001000
pub let PCRE2_EXTRA_PYTHON_OCTAL: c_uint = 0x00002000
pub let PCRE2_EXTRA_NO_BS0: c_uint = 0x00004000
pub let PCRE2_EXTRA_NEVER_CALLOUT: c_uint = 0x00008000
pub let PCRE2_EXTRA_TURKISH_CASING: c_uint = 0x00010000
pub let PCRE2_JIT_COMPLETE: c_uint = 0x00000001
pub let PCRE2_JIT_PARTIAL_SOFT: c_uint = 0x00000002
pub let PCRE2_JIT_PARTIAL_HARD: c_uint = 0x00000004
pub let PCRE2_JIT_INVALID_UTF: c_uint = 0x00000100
pub let PCRE2_JIT_TEST_ALLOC: c_uint = 0x00000200
pub let PCRE2_NOTBOL: c_uint = 0x00000001
pub let PCRE2_NOTEOL: c_uint = 0x00000002
pub let PCRE2_NOTEMPTY: c_uint = 0x00000004
pub let PCRE2_NOTEMPTY_ATSTART: c_uint = 0x00000008
pub let PCRE2_PARTIAL_SOFT: c_uint = 0x00000010
pub let PCRE2_PARTIAL_HARD: c_uint = 0x00000020
pub let PCRE2_DFA_RESTART: c_uint = 0x00000040
pub let PCRE2_DFA_SHORTEST: c_uint = 0x00000080
pub let PCRE2_SUBSTITUTE_GLOBAL: c_uint = 0x00000100
pub let PCRE2_SUBSTITUTE_EXTENDED: c_uint = 0x00000200
pub let PCRE2_SUBSTITUTE_UNSET_EMPTY: c_uint = 0x00000400
pub let PCRE2_SUBSTITUTE_UNKNOWN_UNSET: c_uint = 0x00000800
pub let PCRE2_SUBSTITUTE_OVERFLOW_LENGTH: c_uint = 0x00001000
pub let PCRE2_NO_JIT: c_uint = 0x00002000
pub let PCRE2_COPY_MATCHED_SUBJECT: c_uint = 0x00004000
pub let PCRE2_SUBSTITUTE_LITERAL: c_uint = 0x00008000
pub let PCRE2_SUBSTITUTE_MATCHED: c_uint = 0x00010000
pub let PCRE2_SUBSTITUTE_REPLACEMENT_ONLY: c_uint = 0x00020000
pub let PCRE2_DISABLE_RECURSELOOP_CHECK: c_uint = 0x00040000
pub let PCRE2_CONVERT_UTF: c_uint = 0x00000001
pub let PCRE2_CONVERT_NO_UTF_CHECK: c_uint = 0x00000002
pub let PCRE2_CONVERT_POSIX_BASIC: c_uint = 0x00000004
pub let PCRE2_CONVERT_POSIX_EXTENDED: c_uint = 0x00000008
pub let PCRE2_CONVERT_GLOB: c_uint = 0x00000010
pub let PCRE2_CONVERT_GLOB_NO_WILD_SEPARATOR: c_uint = 0x00000030
pub let PCRE2_CONVERT_GLOB_NO_STARSTAR: c_uint = 0x00000050
pub let PCRE2_NEWLINE_CR: c_int = 1
pub let PCRE2_NEWLINE_LF: c_int = 2
pub let PCRE2_NEWLINE_CRLF: c_int = 3
pub let PCRE2_NEWLINE_ANY: c_int = 4
pub let PCRE2_NEWLINE_ANYCRLF: c_int = 5
pub let PCRE2_NEWLINE_NUL: c_int = 6
pub let PCRE2_BSR_UNICODE: c_int = 1
pub let PCRE2_BSR_ANYCRLF: c_int = 2
pub let PCRE2_ERROR_END_BACKSLASH: c_int = 101
pub let PCRE2_ERROR_END_BACKSLASH_C: c_int = 102
pub let PCRE2_ERROR_UNKNOWN_ESCAPE: c_int = 103
pub let PCRE2_ERROR_QUANTIFIER_OUT_OF_ORDER: c_int = 104
pub let PCRE2_ERROR_QUANTIFIER_TOO_BIG: c_int = 105
pub let PCRE2_ERROR_MISSING_SQUARE_BRACKET: c_int = 106
pub let PCRE2_ERROR_ESCAPE_INVALID_IN_CLASS: c_int = 107
pub let PCRE2_ERROR_CLASS_RANGE_ORDER: c_int = 108
pub let PCRE2_ERROR_QUANTIFIER_INVALID: c_int = 109
pub let PCRE2_ERROR_INTERNAL_UNEXPECTED_REPEAT: c_int = 110
pub let PCRE2_ERROR_INVALID_AFTER_PARENS_QUERY: c_int = 111
pub let PCRE2_ERROR_POSIX_CLASS_NOT_IN_CLASS: c_int = 112
pub let PCRE2_ERROR_POSIX_NO_SUPPORT_COLLATING: c_int = 113
pub let PCRE2_ERROR_MISSING_CLOSING_PARENTHESIS: c_int = 114
pub let PCRE2_ERROR_BAD_SUBPATTERN_REFERENCE: c_int = 115
pub let PCRE2_ERROR_NULL_PATTERN: c_int = 116
pub let PCRE2_ERROR_BAD_OPTIONS: c_int = 117
pub let PCRE2_ERROR_MISSING_COMMENT_CLOSING: c_int = 118
pub let PCRE2_ERROR_PARENTHESES_NEST_TOO_DEEP: c_int = 119
pub let PCRE2_ERROR_PATTERN_TOO_LARGE: c_int = 120
pub let PCRE2_ERROR_HEAP_FAILED: c_int = 121
pub let PCRE2_ERROR_UNMATCHED_CLOSING_PARENTHESIS: c_int = 122
pub let PCRE2_ERROR_INTERNAL_CODE_OVERFLOW: c_int = 123
pub let PCRE2_ERROR_MISSING_CONDITION_CLOSING: c_int = 124
pub let PCRE2_ERROR_LOOKBEHIND_NOT_FIXED_LENGTH: c_int = 125
pub let PCRE2_ERROR_ZERO_RELATIVE_REFERENCE: c_int = 126
pub let PCRE2_ERROR_TOO_MANY_CONDITION_BRANCHES: c_int = 127
pub let PCRE2_ERROR_CONDITION_ASSERTION_EXPECTED: c_int = 128
pub let PCRE2_ERROR_BAD_RELATIVE_REFERENCE: c_int = 129
pub let PCRE2_ERROR_UNKNOWN_POSIX_CLASS: c_int = 130
pub let PCRE2_ERROR_INTERNAL_STUDY_ERROR: c_int = 131
pub let PCRE2_ERROR_UNICODE_NOT_SUPPORTED: c_int = 132
pub let PCRE2_ERROR_PARENTHESES_STACK_CHECK: c_int = 133
pub let PCRE2_ERROR_CODE_POINT_TOO_BIG: c_int = 134
pub let PCRE2_ERROR_LOOKBEHIND_TOO_COMPLICATED: c_int = 135
pub let PCRE2_ERROR_LOOKBEHIND_INVALID_BACKSLASH_C: c_int = 136
pub let PCRE2_ERROR_UNSUPPORTED_ESCAPE_SEQUENCE: c_int = 137
pub let PCRE2_ERROR_CALLOUT_NUMBER_TOO_BIG: c_int = 138
pub let PCRE2_ERROR_MISSING_CALLOUT_CLOSING: c_int = 139
pub let PCRE2_ERROR_ESCAPE_INVALID_IN_VERB: c_int = 140
pub let PCRE2_ERROR_UNRECOGNIZED_AFTER_QUERY_P: c_int = 141
pub let PCRE2_ERROR_MISSING_NAME_TERMINATOR: c_int = 142
pub let PCRE2_ERROR_DUPLICATE_SUBPATTERN_NAME: c_int = 143
pub let PCRE2_ERROR_INVALID_SUBPATTERN_NAME: c_int = 144
pub let PCRE2_ERROR_UNICODE_PROPERTIES_UNAVAILABLE: c_int = 145
pub let PCRE2_ERROR_MALFORMED_UNICODE_PROPERTY: c_int = 146
pub let PCRE2_ERROR_UNKNOWN_UNICODE_PROPERTY: c_int = 147
pub let PCRE2_ERROR_SUBPATTERN_NAME_TOO_LONG: c_int = 148
pub let PCRE2_ERROR_TOO_MANY_NAMED_SUBPATTERNS: c_int = 149
pub let PCRE2_ERROR_CLASS_INVALID_RANGE: c_int = 150
pub let PCRE2_ERROR_OCTAL_BYTE_TOO_BIG: c_int = 151
pub let PCRE2_ERROR_INTERNAL_OVERRAN_WORKSPACE: c_int = 152
pub let PCRE2_ERROR_INTERNAL_MISSING_SUBPATTERN: c_int = 153
pub let PCRE2_ERROR_DEFINE_TOO_MANY_BRANCHES: c_int = 154
pub let PCRE2_ERROR_BACKSLASH_O_MISSING_BRACE: c_int = 155
pub let PCRE2_ERROR_INTERNAL_UNKNOWN_NEWLINE: c_int = 156
pub let PCRE2_ERROR_BACKSLASH_G_SYNTAX: c_int = 157
pub let PCRE2_ERROR_PARENS_QUERY_R_MISSING_CLOSING: c_int = 158
pub let PCRE2_ERROR_VERB_ARGUMENT_NOT_ALLOWED: c_int = 159
pub let PCRE2_ERROR_VERB_UNKNOWN: c_int = 160
pub let PCRE2_ERROR_SUBPATTERN_NUMBER_TOO_BIG: c_int = 161
pub let PCRE2_ERROR_SUBPATTERN_NAME_EXPECTED: c_int = 162
pub let PCRE2_ERROR_INTERNAL_PARSED_OVERFLOW: c_int = 163
pub let PCRE2_ERROR_INVALID_OCTAL: c_int = 164
pub let PCRE2_ERROR_SUBPATTERN_NAMES_MISMATCH: c_int = 165
pub let PCRE2_ERROR_MARK_MISSING_ARGUMENT: c_int = 166
pub let PCRE2_ERROR_INVALID_HEXADECIMAL: c_int = 167
pub let PCRE2_ERROR_BACKSLASH_C_SYNTAX: c_int = 168
pub let PCRE2_ERROR_BACKSLASH_K_SYNTAX: c_int = 169
pub let PCRE2_ERROR_INTERNAL_BAD_CODE_LOOKBEHINDS: c_int = 170
pub let PCRE2_ERROR_BACKSLASH_N_IN_CLASS: c_int = 171
pub let PCRE2_ERROR_CALLOUT_STRING_TOO_LONG: c_int = 172
pub let PCRE2_ERROR_UNICODE_DISALLOWED_CODE_POINT: c_int = 173
pub let PCRE2_ERROR_UTF_IS_DISABLED: c_int = 174
pub let PCRE2_ERROR_UCP_IS_DISABLED: c_int = 175
pub let PCRE2_ERROR_VERB_NAME_TOO_LONG: c_int = 176
pub let PCRE2_ERROR_BACKSLASH_U_CODE_POINT_TOO_BIG: c_int = 177
pub let PCRE2_ERROR_MISSING_OCTAL_OR_HEX_DIGITS: c_int = 178
pub let PCRE2_ERROR_VERSION_CONDITION_SYNTAX: c_int = 179
pub let PCRE2_ERROR_INTERNAL_BAD_CODE_AUTO_POSSESS: c_int = 180
pub let PCRE2_ERROR_CALLOUT_NO_STRING_DELIMITER: c_int = 181
pub let PCRE2_ERROR_CALLOUT_BAD_STRING_DELIMITER: c_int = 182
pub let PCRE2_ERROR_BACKSLASH_C_CALLER_DISABLED: c_int = 183
pub let PCRE2_ERROR_QUERY_BARJX_NEST_TOO_DEEP: c_int = 184
pub let PCRE2_ERROR_BACKSLASH_C_LIBRARY_DISABLED: c_int = 185
pub let PCRE2_ERROR_PATTERN_TOO_COMPLICATED: c_int = 186
pub let PCRE2_ERROR_LOOKBEHIND_TOO_LONG: c_int = 187
pub let PCRE2_ERROR_PATTERN_STRING_TOO_LONG: c_int = 188
pub let PCRE2_ERROR_INTERNAL_BAD_CODE: c_int = 189
pub let PCRE2_ERROR_INTERNAL_BAD_CODE_IN_SKIP: c_int = 190
pub let PCRE2_ERROR_NO_SURROGATES_IN_UTF16: c_int = 191
pub let PCRE2_ERROR_BAD_LITERAL_OPTIONS: c_int = 192
pub let PCRE2_ERROR_SUPPORTED_ONLY_IN_UNICODE: c_int = 193
pub let PCRE2_ERROR_INVALID_HYPHEN_IN_OPTIONS: c_int = 194
pub let PCRE2_ERROR_ALPHA_ASSERTION_UNKNOWN: c_int = 195
pub let PCRE2_ERROR_SCRIPT_RUN_NOT_AVAILABLE: c_int = 196
pub let PCRE2_ERROR_TOO_MANY_CAPTURES: c_int = 197
pub let PCRE2_ERROR_MISSING_OCTAL_DIGIT: c_int = 198
pub let PCRE2_ERROR_BACKSLASH_K_IN_LOOKAROUND: c_int = 199
pub let PCRE2_ERROR_MAX_VAR_LOOKBEHIND_EXCEEDED: c_int = 200
pub let PCRE2_ERROR_PATTERN_COMPILED_SIZE_TOO_BIG: c_int = 201
pub let PCRE2_ERROR_OVERSIZE_PYTHON_OCTAL: c_int = 202
pub let PCRE2_ERROR_CALLOUT_CALLER_DISABLED: c_int = 203
pub let PCRE2_ERROR_EXTRA_CASING_REQUIRES_UNICODE: c_int = 204
pub let PCRE2_ERROR_TURKISH_CASING_REQUIRES_UTF: c_int = 205
pub let PCRE2_ERROR_EXTRA_CASING_INCOMPATIBLE: c_int = 206
pub let PCRE2_ERROR_ECLASS_NEST_TOO_DEEP: c_int = 207
pub let PCRE2_ERROR_ECLASS_INVALID_OPERATOR: c_int = 208
pub let PCRE2_ERROR_ECLASS_UNEXPECTED_OPERATOR: c_int = 209
pub let PCRE2_ERROR_ECLASS_EXPECTED_OPERAND: c_int = 210
pub let PCRE2_ERROR_ECLASS_MIXED_OPERATORS: c_int = 211
pub let PCRE2_ERROR_ECLASS_HINT_SQUARE_BRACKET: c_int = 212
pub let PCRE2_ERROR_PERL_ECLASS_UNEXPECTED_EXPR: c_int = 213
pub let PCRE2_ERROR_PERL_ECLASS_EMPTY_EXPR: c_int = 214
pub let PCRE2_ERROR_PERL_ECLASS_MISSING_CLOSE: c_int = 215
pub let PCRE2_ERROR_PERL_ECLASS_UNEXPECTED_CHAR: c_int = 216
pub let PCRE2_ERROR_EXPECTED_CAPTURE_GROUP: c_int = 217
pub let PCRE2_ERROR_MISSING_OPENING_PARENTHESIS: c_int = 218
pub let PCRE2_ERROR_MISSING_NUMBER_TERMINATOR: c_int = 219
pub let PCRE2_ERROR_NULL_ERROROFFSET: c_int = 220
pub let PCRE2_ERROR_NOMATCH: c_int = -1
pub let PCRE2_ERROR_PARTIAL: c_int = -2
pub let PCRE2_ERROR_UTF8_ERR1: c_int = -3
pub let PCRE2_ERROR_UTF8_ERR2: c_int = -4
pub let PCRE2_ERROR_UTF8_ERR3: c_int = -5
pub let PCRE2_ERROR_UTF8_ERR4: c_int = -6
pub let PCRE2_ERROR_UTF8_ERR5: c_int = -7
pub let PCRE2_ERROR_UTF8_ERR6: c_int = -8
pub let PCRE2_ERROR_UTF8_ERR7: c_int = -9
pub let PCRE2_ERROR_UTF8_ERR8: c_int = -10
pub let PCRE2_ERROR_UTF8_ERR9: c_int = -11
pub let PCRE2_ERROR_UTF8_ERR10: c_int = -12
pub let PCRE2_ERROR_UTF8_ERR11: c_int = -13
pub let PCRE2_ERROR_UTF8_ERR12: c_int = -14
pub let PCRE2_ERROR_UTF8_ERR13: c_int = -15
pub let PCRE2_ERROR_UTF8_ERR14: c_int = -16
pub let PCRE2_ERROR_UTF8_ERR15: c_int = -17
pub let PCRE2_ERROR_UTF8_ERR16: c_int = -18
pub let PCRE2_ERROR_UTF8_ERR17: c_int = -19
pub let PCRE2_ERROR_UTF8_ERR18: c_int = -20
pub let PCRE2_ERROR_UTF8_ERR19: c_int = -21
pub let PCRE2_ERROR_UTF8_ERR20: c_int = -22
pub let PCRE2_ERROR_UTF8_ERR21: c_int = -23
pub let PCRE2_ERROR_UTF16_ERR1: c_int = -24
pub let PCRE2_ERROR_UTF16_ERR2: c_int = -25
pub let PCRE2_ERROR_UTF16_ERR3: c_int = -26
pub let PCRE2_ERROR_UTF32_ERR1: c_int = -27
pub let PCRE2_ERROR_UTF32_ERR2: c_int = -28
pub let PCRE2_ERROR_BADDATA: c_int = -29
pub let PCRE2_ERROR_MIXEDTABLES: c_int = -30
pub let PCRE2_ERROR_BADMAGIC: c_int = -31
pub let PCRE2_ERROR_BADMODE: c_int = -32
pub let PCRE2_ERROR_BADOFFSET: c_int = -33
pub let PCRE2_ERROR_BADOPTION: c_int = -34
pub let PCRE2_ERROR_BADREPLACEMENT: c_int = -35
pub let PCRE2_ERROR_BADUTFOFFSET: c_int = -36
pub let PCRE2_ERROR_CALLOUT: c_int = -37
pub let PCRE2_ERROR_DFA_BADRESTART: c_int = -38
pub let PCRE2_ERROR_DFA_RECURSE: c_int = -39
pub let PCRE2_ERROR_DFA_UCOND: c_int = -40
pub let PCRE2_ERROR_DFA_UFUNC: c_int = -41
pub let PCRE2_ERROR_DFA_UITEM: c_int = -42
pub let PCRE2_ERROR_DFA_WSSIZE: c_int = -43
pub let PCRE2_ERROR_INTERNAL: c_int = -44
pub let PCRE2_ERROR_JIT_BADOPTION: c_int = -45
pub let PCRE2_ERROR_JIT_STACKLIMIT: c_int = -46
pub let PCRE2_ERROR_MATCHLIMIT: c_int = -47
pub let PCRE2_ERROR_NOMEMORY: c_int = -48
pub let PCRE2_ERROR_NOSUBSTRING: c_int = -49
pub let PCRE2_ERROR_NOUNIQUESUBSTRING: c_int = -50
pub let PCRE2_ERROR_NULL: c_int = -51
pub let PCRE2_ERROR_RECURSELOOP: c_int = -52
pub let PCRE2_ERROR_DEPTHLIMIT: c_int = -53
pub let PCRE2_ERROR_RECURSIONLIMIT: c_int = -53
pub let PCRE2_ERROR_UNAVAILABLE: c_int = -54
pub let PCRE2_ERROR_UNSET: c_int = -55
pub let PCRE2_ERROR_BADOFFSETLIMIT: c_int = -56
pub let PCRE2_ERROR_BADREPESCAPE: c_int = -57
pub let PCRE2_ERROR_REPMISSINGBRACE: c_int = -58
pub let PCRE2_ERROR_BADSUBSTITUTION: c_int = -59
pub let PCRE2_ERROR_BADSUBSPATTERN: c_int = -60
pub let PCRE2_ERROR_TOOMANYREPLACE: c_int = -61
pub let PCRE2_ERROR_BADSERIALIZEDDATA: c_int = -62
pub let PCRE2_ERROR_HEAPLIMIT: c_int = -63
pub let PCRE2_ERROR_CONVERT_SYNTAX: c_int = -64
pub let PCRE2_ERROR_INTERNAL_DUPMATCH: c_int = -65
pub let PCRE2_ERROR_DFA_UINVALID_UTF: c_int = -66
pub let PCRE2_ERROR_INVALIDOFFSET: c_int = -67
pub let PCRE2_ERROR_JIT_UNSUPPORTED: c_int = -68
pub let PCRE2_ERROR_REPLACECASE: c_int = -69
pub let PCRE2_ERROR_TOOLARGEREPLACE: c_int = -70
pub let PCRE2_ERROR_DIFFSUBSPATTERN: c_int = -71
pub let PCRE2_ERROR_DIFFSUBSSUBJECT: c_int = -72
pub let PCRE2_ERROR_DIFFSUBSOFFSET: c_int = -73
pub let PCRE2_ERROR_DIFFSUBSOPTIONS: c_int = -74
pub let PCRE2_ERROR_BAD_BACKSLASH_K: c_int = -75
pub let PCRE2_INFO_ALLOPTIONS: c_int = 0
pub let PCRE2_INFO_ARGOPTIONS: c_int = 1
pub let PCRE2_INFO_BACKREFMAX: c_int = 2
pub let PCRE2_INFO_BSR: c_int = 3
pub let PCRE2_INFO_CAPTURECOUNT: c_int = 4
pub let PCRE2_INFO_FIRSTCODEUNIT: c_int = 5
pub let PCRE2_INFO_FIRSTCODETYPE: c_int = 6
pub let PCRE2_INFO_FIRSTBITMAP: c_int = 7
pub let PCRE2_INFO_HASCRORLF: c_int = 8
pub let PCRE2_INFO_JCHANGED: c_int = 9
pub let PCRE2_INFO_JITSIZE: c_int = 10
pub let PCRE2_INFO_LASTCODEUNIT: c_int = 11
pub let PCRE2_INFO_LASTCODETYPE: c_int = 12
pub let PCRE2_INFO_MATCHEMPTY: c_int = 13
pub let PCRE2_INFO_MATCHLIMIT: c_int = 14
pub let PCRE2_INFO_MAXLOOKBEHIND: c_int = 15
pub let PCRE2_INFO_MINLENGTH: c_int = 16
pub let PCRE2_INFO_NAMECOUNT: c_int = 17
pub let PCRE2_INFO_NAMEENTRYSIZE: c_int = 18
pub let PCRE2_INFO_NAMETABLE: c_int = 19
pub let PCRE2_INFO_NEWLINE: c_int = 20
pub let PCRE2_INFO_DEPTHLIMIT: c_int = 21
pub let PCRE2_INFO_RECURSIONLIMIT: c_int = 21
pub let PCRE2_INFO_SIZE: c_int = 22
pub let PCRE2_INFO_HASBACKSLASHC: c_int = 23
pub let PCRE2_INFO_FRAMESIZE: c_int = 24
pub let PCRE2_INFO_HEAPLIMIT: c_int = 25
pub let PCRE2_INFO_EXTRAOPTIONS: c_int = 26
pub let PCRE2_CONFIG_BSR: c_int = 0
pub let PCRE2_CONFIG_JIT: c_int = 1
pub let PCRE2_CONFIG_JITTARGET: c_int = 2
pub let PCRE2_CONFIG_LINKSIZE: c_int = 3
pub let PCRE2_CONFIG_MATCHLIMIT: c_int = 4
pub let PCRE2_CONFIG_NEWLINE: c_int = 5
pub let PCRE2_CONFIG_PARENSLIMIT: c_int = 6
pub let PCRE2_CONFIG_DEPTHLIMIT: c_int = 7
pub let PCRE2_CONFIG_RECURSIONLIMIT: c_int = 7
pub let PCRE2_CONFIG_STACKRECURSE: c_int = 8
pub let PCRE2_CONFIG_UNICODE: c_int = 9
pub let PCRE2_CONFIG_UNICODE_VERSION: c_int = 10
pub let PCRE2_CONFIG_VERSION: c_int = 11
pub let PCRE2_CONFIG_HEAPLIMIT: c_int = 12
pub let PCRE2_CONFIG_NEVER_BACKSLASH_C: c_int = 13
pub let PCRE2_CONFIG_COMPILED_WIDTHS: c_int = 14
pub let PCRE2_CONFIG_TABLES_LENGTH: c_int = 15
pub let PCRE2_CONFIG_EFFECTIVE_LINKSIZE: c_int = 16
pub let PCRE2_OPTIMIZATION_NONE: c_int = 0
pub let PCRE2_OPTIMIZATION_FULL: c_int = 1
pub let PCRE2_AUTO_POSSESS: c_int = 64
pub let PCRE2_AUTO_POSSESS_OFF: c_int = 65
pub let PCRE2_DOTSTAR_ANCHOR: c_int = 66
pub let PCRE2_DOTSTAR_ANCHOR_OFF: c_int = 67
pub let PCRE2_START_OPTIMIZE: c_int = 68
pub let PCRE2_START_OPTIMIZE_OFF: c_int = 69
pub let PCRE2_SUBSTITUTE_CASE_LOWER: c_int = 1
pub let PCRE2_SUBSTITUTE_CASE_UPPER: c_int = 2
pub let PCRE2_SUBSTITUTE_CASE_TITLE_FIRST: c_int = 3
pub let PCRE2_SIZE_MAX: c_ulong = ((0 as c_ulong) -% 1)
pub let PCRE2_ZERO_TERMINATED: c_ulong = ((0 as c_ulong) -% 1)
pub let PCRE2_UNSET: c_ulong = ((0 as c_ulong) -% 1)
pub let PCRE2_CALLOUT_STARTMATCH: c_uint = 0x00000001
pub let PCRE2_CALLOUT_BACKTRACK: c_uint = 0x00000002
pub fn PCRE2_GLUE[T](a: T, b: T) -> T {
    PCRE2_JOIN(a, b)
}
pub fn PCRE2_SUFFIX[T](a: T) -> T {
    PCRE2_GLUE(a, 8)
}
pub let PCRE2_LOCAL_WIDTH: c_int = 8
pub let ucd_boolprop_sets_item_size: c_int = 2
pub let ucd_script_sets_item_size: c_int = 4
pub let NOTACHAR: c_uint = 0xffffffff
pub let MAX_UTF_CODE_POINT: c_int = 0x10ffff
pub let COMPILE_ERROR_BASE: c_int = 100
pub let START_FRAMES_SIZE: c_int = 20480
pub let DFA_START_RWS_SIZE: c_int = 30720
pub let BSR_DEFAULT: c_int = 1
pub fn HASUTF8EXTRALEN[T](c: T) -> T {
    (c >= 0xc0)
}
pub let NLTYPE_FIXED: c_int = 0
pub let NLTYPE_ANY: c_int = 1
pub let NLTYPE_ANYCRLF: c_int = 2
pub let PCRE2_MODE8: c_uint = 0x00000001
pub let PCRE2_MODE16: c_uint = 0x00000002
pub let PCRE2_MODE32: c_uint = 0x00000004
pub let PCRE2_FIRSTSET: c_uint = 0x00000010
pub let PCRE2_FIRSTCASELESS: c_uint = 0x00000020
pub let PCRE2_FIRSTMAPSET: c_uint = 0x00000040
pub let PCRE2_LASTSET: c_uint = 0x00000080
pub let PCRE2_LASTCASELESS: c_uint = 0x00000100
pub let PCRE2_STARTLINE: c_uint = 0x00000200
pub let PCRE2_JCHANGED: c_uint = 0x00000400
pub let PCRE2_HASCRORLF: c_uint = 0x00000800
pub let PCRE2_HASTHEN: c_uint = 0x00001000
pub let PCRE2_MATCH_EMPTY: c_uint = 0x00002000
pub let PCRE2_BSR_SET: c_uint = 0x00004000
pub let PCRE2_NL_SET: c_uint = 0x00008000
pub let PCRE2_NOTEMPTY_SET: c_uint = 0x00010000
pub let PCRE2_NE_ATST_SET: c_uint = 0x00020000
pub let PCRE2_DEREF_TABLES: c_uint = 0x00040000
pub let PCRE2_NOJIT: c_uint = 0x00080000
pub let PCRE2_HASBKPORX: c_uint = 0x00100000
pub let PCRE2_DUPCAPUSED: c_uint = 0x00200000
pub let PCRE2_HASBKC: c_uint = 0x00400000
pub let PCRE2_HASACCEPT: c_uint = 0x00800000
pub let PCRE2_HASBSK: c_uint = 0x01000000
pub let PCRE2_MODE_MASK: c_uint = 7
pub let PCRE2_MD_COPIED_SUBJECT: c_uint = 0x01
pub let MAGIC_NUMBER: c_ulong = 0x50435245
pub let REQ_CU_MAX: c_int = 5000
pub let ECLASS_NEST_LIMIT: c_int = 15
pub let cbit_space: c_int = 0
pub let cbit_xdigit: c_int = 32
pub let cbit_digit: c_int = 64
pub let cbit_upper: c_int = 96
pub let cbit_lower: c_int = 128
pub let cbit_word: c_int = 160
pub let cbit_graph: c_int = 192
pub let cbit_print: c_int = 224
pub let cbit_punct: c_int = 256
pub let cbit_cntrl: c_int = 288
pub let cbit_length: c_int = 320
pub let ctype_space: c_int = 0x01
pub let ctype_letter: c_int = 0x02
pub let ctype_lcletter: c_int = 0x04
pub let ctype_digit: c_int = 0x08
pub let ctype_word: c_int = 0x10
pub let lcc_offset: c_int = 0
pub let fcc_offset: c_int = 256
pub let cbits_offset: c_int = 512
pub let ctypes_offset: c_int = 832
pub let TABLES_LENGTH: c_int = 1088
pub let PCRE2_OPTIM_AUTO_POSSESS: c_uint = 0x00000001
pub let PCRE2_OPTIM_DOTSTAR_ANCHOR: c_uint = 0x00000002
pub let PCRE2_OPTIM_START_OPTIMIZE: c_uint = 0x00000004
pub let PCRE2_OPTIMIZATION_ALL: c_uint = 0x00000007
pub let CHAR_HT: c_int = 9
pub let CHAR_VT: c_int = 11
pub let CHAR_FF: c_int = 12
pub let CHAR_CR: c_int = 13
pub let CHAR_LF: c_int = 10
pub let CHAR_NL: c_int = 10
pub let CHAR_NEL: u8 = 133
pub let CHAR_BS: c_int = 8
pub let CHAR_BEL: c_int = 7
pub let CHAR_ESC: c_int = 27
pub let CHAR_DEL: c_int = 127
pub let CHAR_NUL: c_int = 0
pub let CHAR_SPACE: c_int = 32
pub let CHAR_EXCLAMATION_MARK: c_int = 33
pub let CHAR_QUOTATION_MARK: c_int = 34
pub let CHAR_NUMBER_SIGN: c_int = 35
pub let CHAR_DOLLAR_SIGN: c_int = 36
pub let CHAR_PERCENT_SIGN: c_int = 37
pub let CHAR_AMPERSAND: c_int = 38
pub let CHAR_APOSTROPHE: c_int = 39
pub let CHAR_LEFT_PARENTHESIS: c_int = 40
pub let CHAR_RIGHT_PARENTHESIS: c_int = 41
pub let CHAR_ASTERISK: c_int = 42
pub let CHAR_PLUS: c_int = 43
pub let CHAR_COMMA: c_int = 44
pub let CHAR_MINUS: c_int = 45
pub let CHAR_DOT: c_int = 46
pub let CHAR_SLASH: c_int = 47
pub let CHAR_0: c_int = 48
pub let CHAR_1: c_int = 49
pub let CHAR_2: c_int = 50
pub let CHAR_3: c_int = 51
pub let CHAR_4: c_int = 52
pub let CHAR_5: c_int = 53
pub let CHAR_6: c_int = 54
pub let CHAR_7: c_int = 55
pub let CHAR_8: c_int = 56
pub let CHAR_9: c_int = 57
pub let CHAR_COLON: c_int = 58
pub let CHAR_SEMICOLON: c_int = 59
pub let CHAR_LESS_THAN_SIGN: c_int = 60
pub let CHAR_EQUALS_SIGN: c_int = 61
pub let CHAR_GREATER_THAN_SIGN: c_int = 62
pub let CHAR_QUESTION_MARK: c_int = 63
pub let CHAR_COMMERCIAL_AT: c_int = 64
pub let CHAR_A: c_int = 65
pub let CHAR_B: c_int = 66
pub let CHAR_C: c_int = 67
pub let CHAR_D: c_int = 68
pub let CHAR_E: c_int = 69
pub let CHAR_F: c_int = 70
pub let CHAR_G: c_int = 71
pub let CHAR_H: c_int = 72
pub let CHAR_I: c_int = 73
pub let CHAR_J: c_int = 74
pub let CHAR_K: c_int = 75
pub let CHAR_L: c_int = 76
pub let CHAR_M: c_int = 77
pub let CHAR_N: c_int = 78
pub let CHAR_O: c_int = 79
pub let CHAR_P: c_int = 80
pub let CHAR_Q: c_int = 81
pub let CHAR_R: c_int = 82
pub let CHAR_S: c_int = 83
pub let CHAR_T: c_int = 84
pub let CHAR_U: c_int = 85
pub let CHAR_V: c_int = 86
pub let CHAR_W: c_int = 87
pub let CHAR_X: c_int = 88
pub let CHAR_Y: c_int = 89
pub let CHAR_Z: c_int = 90
pub let CHAR_LEFT_SQUARE_BRACKET: c_int = 91
pub let CHAR_BACKSLASH: c_int = 92
pub let CHAR_RIGHT_SQUARE_BRACKET: c_int = 93
pub let CHAR_CIRCUMFLEX_ACCENT: c_int = 94
pub let CHAR_UNDERSCORE: c_int = 95
pub let CHAR_GRAVE_ACCENT: c_int = 96
pub let CHAR_a: c_int = 97
pub let CHAR_b: c_int = 98
pub let CHAR_c: c_int = 99
pub let CHAR_d: c_int = 100
pub let CHAR_e: c_int = 101
pub let CHAR_f: c_int = 102
pub let CHAR_g: c_int = 103
pub let CHAR_h: c_int = 104
pub let CHAR_i: c_int = 105
pub let CHAR_j: c_int = 106
pub let CHAR_k: c_int = 107
pub let CHAR_l: c_int = 108
pub let CHAR_m: c_int = 109
pub let CHAR_n: c_int = 110
pub let CHAR_o: c_int = 111
pub let CHAR_p: c_int = 112
pub let CHAR_q: c_int = 113
pub let CHAR_r: c_int = 114
pub let CHAR_s: c_int = 115
pub let CHAR_t: c_int = 116
pub let CHAR_u: c_int = 117
pub let CHAR_v: c_int = 118
pub let CHAR_w: c_int = 119
pub let CHAR_x: c_int = 120
pub let CHAR_y: c_int = 121
pub let CHAR_z: c_int = 122
pub let CHAR_LEFT_CURLY_BRACKET: c_int = 123
pub let CHAR_VERTICAL_LINE: c_int = 124
pub let CHAR_RIGHT_CURLY_BRACKET: c_int = 125
pub let CHAR_TILDE: c_int = 126
pub let CHAR_NBSP: u8 = 160
pub let STR_HT = "\x09"
pub let STR_VT = "\x0b"
pub let STR_FF = "\x0c"
pub let STR_CR = "\x0d"
pub let STR_NL = "\x0a"
pub let STR_BS = "\x08"
pub let STR_BEL = "\x07"
pub let STR_ESC = "\x1b"
pub let STR_DEL = "\x7f"
pub let STR_SPACE = "\x20"
pub let STR_EXCLAMATION_MARK = "\x21"
pub let STR_QUOTATION_MARK = "\x22"
pub let STR_NUMBER_SIGN = "\x23"
pub let STR_DOLLAR_SIGN = "\x24"
pub let STR_PERCENT_SIGN = "\x25"
pub let STR_AMPERSAND = "\x26"
pub let STR_APOSTROPHE = "\x27"
pub let STR_LEFT_PARENTHESIS = "\x28"
pub let STR_RIGHT_PARENTHESIS = "\x29"
pub let STR_ASTERISK = "\x2a"
pub let STR_PLUS = "\x2b"
pub let STR_COMMA = "\x2c"
pub let STR_MINUS = "\x2d"
pub let STR_DOT = "\x2e"
pub let STR_SLASH = "\x2f"
pub let STR_0 = "\x30"
pub let STR_1 = "\x31"
pub let STR_2 = "\x32"
pub let STR_3 = "\x33"
pub let STR_4 = "\x34"
pub let STR_5 = "\x35"
pub let STR_6 = "\x36"
pub let STR_7 = "\x37"
pub let STR_8 = "\x38"
pub let STR_9 = "\x39"
pub let STR_COLON = "\x3a"
pub let STR_SEMICOLON = "\x3b"
pub let STR_LESS_THAN_SIGN = "\x3c"
pub let STR_EQUALS_SIGN = "\x3d"
pub let STR_GREATER_THAN_SIGN = "\x3e"
pub let STR_QUESTION_MARK = "\x3f"
pub let STR_COMMERCIAL_AT = "\x40"
pub let STR_A = "\x41"
pub let STR_B = "\x42"
pub let STR_C = "\x43"
pub let STR_D = "\x44"
pub let STR_E = "\x45"
pub let STR_F = "\x46"
pub let STR_G = "\x47"
pub let STR_H = "\x48"
pub let STR_I = "\x49"
pub let STR_J = "\x4a"
pub let STR_K = "\x4b"
pub let STR_L = "\x4c"
pub let STR_M = "\x4d"
pub let STR_N = "\x4e"
pub let STR_O = "\x4f"
pub let STR_P = "\x50"
pub let STR_Q = "\x51"
pub let STR_R = "\x52"
pub let STR_S = "\x53"
pub let STR_T = "\x54"
pub let STR_U = "\x55"
pub let STR_V = "\x56"
pub let STR_W = "\x57"
pub let STR_X = "\x58"
pub let STR_Y = "\x59"
pub let STR_Z = "\x5a"
pub let STR_LEFT_SQUARE_BRACKET = "\x5b"
pub let STR_BACKSLASH = "\x5c"
pub let STR_RIGHT_SQUARE_BRACKET = "\x5d"
pub let STR_CIRCUMFLEX_ACCENT = "\x5e"
pub let STR_UNDERSCORE = "\x5f"
pub let STR_GRAVE_ACCENT = "\x60"
pub let STR_a = "\x61"
pub let STR_b = "\x62"
pub let STR_c = "\x63"
pub let STR_d = "\x64"
pub let STR_e = "\x65"
pub let STR_f = "\x66"
pub let STR_g = "\x67"
pub let STR_h = "\x68"
pub let STR_i = "\x69"
pub let STR_j = "\x6a"
pub let STR_k = "\x6b"
pub let STR_l = "\x6c"
pub let STR_m = "\x6d"
pub let STR_n = "\x6e"
pub let STR_o = "\x6f"
pub let STR_p = "\x70"
pub let STR_q = "\x71"
pub let STR_r = "\x72"
pub let STR_s = "\x73"
pub let STR_t = "\x74"
pub let STR_u = "\x75"
pub let STR_v = "\x76"
pub let STR_w = "\x77"
pub let STR_x = "\x78"
pub let STR_y = "\x79"
pub let STR_z = "\x7a"
pub let STR_LEFT_CURLY_BRACKET = "\x7b"
pub let STR_VERTICAL_LINE = "\x7c"
pub let STR_RIGHT_CURLY_BRACKET = "\x7d"
pub let STR_TILDE = "\x7e"
pub let STRING_ACCEPT0: [8]c_char = [65, 67, 67, 69, 80, 84, 0, 0]
pub let STRING_COMMIT0: [8]c_char = [67, 79, 77, 77, 73, 84, 0, 0]
pub let STRING_F0: [3]c_char = [70, 0, 0]
pub let STRING_FAIL0: [6]c_char = [70, 65, 73, 76, 0, 0]
pub let STRING_MARK0: [6]c_char = [77, 65, 82, 75, 0, 0]
pub let STRING_PRUNE0: [7]c_char = [80, 82, 85, 78, 69, 0, 0]
pub let STRING_SKIP0: [6]c_char = [83, 75, 73, 80, 0, 0]
pub let STRING_THEN: [5]c_char = [84, 72, 69, 78, 0]
pub let STRING_atomic0: [8]c_char = [97, 116, 111, 109, 105, 99, 0, 0]
pub let STRING_pla0: [5]c_char = [112, 108, 97, 0, 0]
pub let STRING_plb0: [5]c_char = [112, 108, 98, 0, 0]
pub let STRING_napla0: [7]c_char = [110, 97, 112, 108, 97, 0, 0]
pub let STRING_naplb0: [7]c_char = [110, 97, 112, 108, 98, 0, 0]
pub let STRING_nla0: [5]c_char = [110, 108, 97, 0, 0]
pub let STRING_nlb0: [5]c_char = [110, 108, 98, 0, 0]
pub let STRING_scs0: [5]c_char = [115, 99, 115, 0, 0]
pub let STRING_sr0: [4]c_char = [115, 114, 0, 0]
pub let STRING_asr0: [5]c_char = [97, 115, 114, 0, 0]
pub let STRING_positive_lookahead0: [20]c_char = [112, 111, 115, 105, 116, 105, 118, 101, 95, 108, 111, 111, 107, 97, 104, 101, 97, 100, 0, 0]
pub let STRING_positive_lookbehind0: [21]c_char = [112, 111, 115, 105, 116, 105, 118, 101, 95, 108, 111, 111, 107, 98, 101, 104, 105, 110, 100, 0, 0]
pub let STRING_non_atomic_positive_lookahead0: [31]c_char = [110, 111, 110, 95, 97, 116, 111, 109, 105, 99, 95, 112, 111, 115, 105, 116, 105, 118, 101, 95, 108, 111, 111, 107, 97, 104, 101, 97, 100, 0, 0]
pub let STRING_non_atomic_positive_lookbehind0: [32]c_char = [110, 111, 110, 95, 97, 116, 111, 109, 105, 99, 95, 112, 111, 115, 105, 116, 105, 118, 101, 95, 108, 111, 111, 107, 98, 101, 104, 105, 110, 100, 0, 0]
pub let STRING_negative_lookahead0: [20]c_char = [110, 101, 103, 97, 116, 105, 118, 101, 95, 108, 111, 111, 107, 97, 104, 101, 97, 100, 0, 0]
pub let STRING_negative_lookbehind0: [21]c_char = [110, 101, 103, 97, 116, 105, 118, 101, 95, 108, 111, 111, 107, 98, 101, 104, 105, 110, 100, 0, 0]
pub let STRING_script_run0: [12]c_char = [115, 99, 114, 105, 112, 116, 95, 114, 117, 110, 0, 0]
pub let STRING_atomic_script_run: [18]c_char = [97, 116, 111, 109, 105, 99, 95, 115, 99, 114, 105, 112, 116, 95, 114, 117, 110, 0]
pub let STRING_scan_substring0: [16]c_char = [115, 99, 97, 110, 95, 115, 117, 98, 115, 116, 114, 105, 110, 103, 0, 0]
pub let STRING_alpha0: [7]c_char = [97, 108, 112, 104, 97, 0, 0]
pub let STRING_lower0: [7]c_char = [108, 111, 119, 101, 114, 0, 0]
pub let STRING_upper0: [7]c_char = [117, 112, 112, 101, 114, 0, 0]
pub let STRING_alnum0: [7]c_char = [97, 108, 110, 117, 109, 0, 0]
pub let STRING_ascii0: [7]c_char = [97, 115, 99, 105, 105, 0, 0]
pub let STRING_blank0: [7]c_char = [98, 108, 97, 110, 107, 0, 0]
pub let STRING_cntrl0: [7]c_char = [99, 110, 116, 114, 108, 0, 0]
pub let STRING_digit0: [7]c_char = [100, 105, 103, 105, 116, 0, 0]
pub let STRING_graph0: [7]c_char = [103, 114, 97, 112, 104, 0, 0]
pub let STRING_print0: [7]c_char = [112, 114, 105, 110, 116, 0, 0]
pub let STRING_punct0: [7]c_char = [112, 117, 110, 99, 116, 0, 0]
pub let STRING_space0: [7]c_char = [115, 112, 97, 99, 101, 0, 0]
pub let STRING_word0: [6]c_char = [119, 111, 114, 100, 0, 0]
pub let STRING_xdigit: [7]c_char = [120, 100, 105, 103, 105, 116, 0]
pub let STRING_DEFINE: [7]c_char = [68, 69, 70, 73, 78, 69, 0]
pub let STRING_VERSION: [8]c_char = [86, 69, 82, 83, 73, 79, 78, 0]
pub let STRING_WEIRD_STARTWORD: [7]c_char = [91, 58, 60, 58, 93, 93, 0]
pub let STRING_WEIRD_ENDWORD: [7]c_char = [91, 58, 62, 58, 93, 93, 0]
pub let STRING_CR_RIGHTPAR: [4]c_char = [67, 82, 41, 0]
pub let STRING_LF_RIGHTPAR: [4]c_char = [76, 70, 41, 0]
pub let STRING_CRLF_RIGHTPAR: [6]c_char = [67, 82, 76, 70, 41, 0]
pub let STRING_ANY_RIGHTPAR: [5]c_char = [65, 78, 89, 41, 0]
pub let STRING_ANYCRLF_RIGHTPAR: [9]c_char = [65, 78, 89, 67, 82, 76, 70, 41, 0]
pub let STRING_NUL_RIGHTPAR: [5]c_char = [78, 85, 76, 41, 0]
pub let STRING_BSR_ANYCRLF_RIGHTPAR: [13]c_char = [66, 83, 82, 95, 65, 78, 89, 67, 82, 76, 70, 41, 0]
pub let STRING_BSR_UNICODE_RIGHTPAR: [13]c_char = [66, 83, 82, 95, 85, 78, 73, 67, 79, 68, 69, 41, 0]
pub let STRING_UTF8_RIGHTPAR: [6]c_char = [85, 84, 70, 56, 41, 0]
pub let STRING_UTF16_RIGHTPAR: [7]c_char = [85, 84, 70, 49, 54, 41, 0]
pub let STRING_UTF32_RIGHTPAR: [7]c_char = [85, 84, 70, 51, 50, 41, 0]
pub let STRING_UTF_RIGHTPAR: [5]c_char = [85, 84, 70, 41, 0]
pub let STRING_UCP_RIGHTPAR: [5]c_char = [85, 67, 80, 41, 0]
pub let STRING_NO_AUTO_POSSESS_RIGHTPAR: [17]c_char = [78, 79, 95, 65, 85, 84, 79, 95, 80, 79, 83, 83, 69, 83, 83, 41, 0]
pub let STRING_NO_DOTSTAR_ANCHOR_RIGHTPAR: [19]c_char = [78, 79, 95, 68, 79, 84, 83, 84, 65, 82, 95, 65, 78, 67, 72, 79, 82, 41, 0]
pub let STRING_NO_JIT_RIGHTPAR: [8]c_char = [78, 79, 95, 74, 73, 84, 41, 0]
pub let STRING_NO_START_OPT_RIGHTPAR: [14]c_char = [78, 79, 95, 83, 84, 65, 82, 84, 95, 79, 80, 84, 41, 0]
pub let STRING_NOTEMPTY_RIGHTPAR: [10]c_char = [78, 79, 84, 69, 77, 80, 84, 89, 41, 0]
pub let STRING_NOTEMPTY_ATSTART_RIGHTPAR: [18]c_char = [78, 79, 84, 69, 77, 80, 84, 89, 95, 65, 84, 83, 84, 65, 82, 84, 41, 0]
pub let STRING_CASELESS_RESTRICT_RIGHTPAR: [19]c_char = [67, 65, 83, 69, 76, 69, 83, 83, 95, 82, 69, 83, 84, 82, 73, 67, 84, 41, 0]
pub let STRING_TURKISH_CASING_RIGHTPAR: [16]c_char = [84, 85, 82, 75, 73, 83, 72, 95, 67, 65, 83, 73, 78, 71, 41, 0]
pub let STRING_LIMIT_HEAP_EQ: [12]c_char = [76, 73, 77, 73, 84, 95, 72, 69, 65, 80, 61, 0]
pub let STRING_LIMIT_MATCH_EQ: [13]c_char = [76, 73, 77, 73, 84, 95, 77, 65, 84, 67, 72, 61, 0]
pub let STRING_LIMIT_DEPTH_EQ: [13]c_char = [76, 73, 77, 73, 84, 95, 68, 69, 80, 84, 72, 61, 0]
pub let STRING_LIMIT_RECURSION_EQ: [17]c_char = [76, 73, 77, 73, 84, 95, 82, 69, 67, 85, 82, 83, 73, 79, 78, 61, 0]
pub let STRING_MARK: [5]c_char = [77, 65, 82, 75, 0]
pub let STRING_bc: [3]c_char = [98, 99, 0]
pub let STRING_bidiclass: [10]c_char = [98, 105, 100, 105, 99, 108, 97, 115, 115, 0]
pub let STRING_sc: [3]c_char = [115, 99, 0]
pub let STRING_script: [7]c_char = [115, 99, 114, 105, 112, 116, 0]
pub let STRING_scriptextensions: [17]c_char = [115, 99, 114, 105, 112, 116, 101, 120, 116, 101, 110, 115, 105, 111, 110, 115, 0]
pub let STRING_scx: [4]c_char = [115, 99, 120, 0]
pub let PT_LAMP: c_int = 0
pub let PT_GC: c_int = 1
pub let PT_PC: c_int = 2
pub let PT_SC: c_int = 3
pub let PT_SCX: c_int = 4
pub let PT_ALNUM: c_int = 5
pub let PT_SPACE: c_int = 6
pub let PT_PXSPACE: c_int = 7
pub let PT_WORD: c_int = 8
pub let PT_CLIST: c_int = 9
pub let PT_UCNC: c_int = 10
pub let PT_BIDICL: c_int = 11
pub let PT_BOOL: c_int = 12
pub let PT_ANY: c_int = 13
pub let PT_TABSIZE: c_int = 13
pub let PT_PXGRAPH: c_int = 14
pub let PT_PXPRINT: c_int = 15
pub let PT_PXPUNCT: c_int = 16
pub let PT_PXXDIGIT: c_int = 17
pub let PT_NOTSCRIPT: c_int = 255
pub let XCL_NOT: c_int = 0x01
pub let XCL_MAP: c_int = 0x02
pub let XCL_HASPROP: c_int = 0x04
pub let XCL_END: c_int = 0
pub let XCL_SINGLE: c_int = 1
pub let XCL_RANGE: c_int = 2
pub let XCL_PROP: c_int = 3
pub let XCL_NOTPROP: c_int = 4
pub let XCL_LIST: c_int = 16
pub let XCL_CHAR_LIST_LOW_16_START: c_int = 0x100
pub let XCL_CHAR_LIST_LOW_16_END: c_int = 0x7fff
pub let XCL_CHAR_LIST_LOW_16_ADD: c_int = 0x0
pub let XCL_CHAR_LIST_HIGH_16_START: c_int = 0x8000
pub let XCL_CHAR_LIST_HIGH_16_END: c_int = 0xffff
pub let XCL_CHAR_LIST_HIGH_16_ADD: c_int = 0x8000
pub let XCL_CHAR_LIST_LOW_32_START: c_int = 0x10000
pub let XCL_CHAR_LIST_LOW_32_END: c_int = 0x7fffffff
pub let XCL_CHAR_LIST_LOW_32_ADD: c_int = 0x0
pub let XCL_CHAR_LIST_HIGH_32_START: c_uint = 0x80000000
pub let XCL_CHAR_LIST_HIGH_32_END: c_uint = 0xffffffff
pub let XCL_CHAR_LIST_HIGH_32_ADD: c_uint = 0x80000000
pub let XCL_TYPE_MASK: c_int = 0xfff
pub let XCL_TYPE_BIT_LEN: c_int = 3
pub let XCL_BEGIN_WITH_RANGE: c_int = 0x4
pub let XCL_ITEM_COUNT_MASK: c_int = 0x3
pub let XCL_CHAR_END: c_int = 0x1
pub let XCL_CHAR_SHIFT: c_int = 1
pub let ECL_MAP: c_int = 0x01
pub let ECL_AND: c_int = 1
pub let ECL_OR: c_int = 2
pub let ECL_XOR: c_int = 3
pub let ECL_NOT: c_int = 4
pub let ECL_XCLASS: c_int = 5
pub let ECL_ANY: c_int = 6
pub let ECL_NONE: c_int = 7
pub let FIRST_AUTOTAB_OP: c_int = 6
pub let LAST_AUTOTAB_LEFT_OP: c_int = 22
pub let LAST_AUTOTAB_RIGHT_OP: c_int = 26
pub let RREF_ANY: c_int = 0xffff
pub let REFI_FLAG_CASELESS_RESTRICT: c_int = 0x1
pub let REFI_FLAG_TURKISH_CASING: c_int = 0x2
pub let UCD_BLOCK_SIZE: c_int = 128
pub fn GET_UCD[T](ch: T) -> T {
    REAL_GET_UCD(ch)
}
pub let UCD_SCRIPTX_MASK: c_int = 0x3ff
pub let UCD_BIDICLASS_SHIFT: c_int = 11
pub let UCD_BPROPS_MASK: c_int = 0xfff
pub fn UCD_SCRIPTX[T](ch: T) -> T {
    UCD_SCRIPTX_PROP(GET_UCD(ch))
}
pub fn UCD_BPROPS[T](ch: T) -> T {
    UCD_BPROPS_PROP(GET_UCD(ch))
}
pub fn UCD_BIDICLASS[T](ch: T) -> T {
    UCD_BIDICLASS_PROP(GET_UCD(ch))
}
pub let MAX_NON_UTF_CHAR: f64 = 4294967295.0
pub let CONFIGURED_LINK_SIZE: c_int = 2
pub let MAX_PATTERN_SIZE: c_int = 65536
pub let IMM2_SIZE: c_int = 2
pub fn MAX_255[T](c: T) -> c_int {
    1
}
pub let MAX_MARK: c_uint = 255
pub fn CHMAX_255[T](c: T) -> T {
    (c <= 255)
}
pub fn UCHAR21[T](eptr: T) -> T {
    (unsafe *eptr)
}
pub fn UCHAR21TEST[T](eptr: T) -> T {
    (unsafe *eptr)
}
pub let MAX_UTF_SINGLE_CU: c_int = 127
pub fn HAS_EXTRALEN[T](c: T) -> T {
    HASUTF8EXTRALEN(c)
}
pub let LOOKBEHIND_MAX: c_int = 65535
pub let HEAPFRAME_ALIGNMENT: c_ulong = 8
pub let _pcre2_default_tables_8: [1088]u8 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 91, 92, 93, 94, 95, 96, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 0x00, 0x3e, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x03, 0x7e, 0x00, 0x00, 0x00, 0x7e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0xff, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0xff, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x03, 0xfe, 0xff, 0xff, 0x87, 0xfe, 0xff, 0xff, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff, 0x00, 0xfc, 0x01, 0x00, 0x00, 0xf8, 0x01, 0x00, 0x00, 0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

pub let _pcre2_OP_lengths_8: [173]u8 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 4, 4, 4, 2, 2, 2, 4, 1, 1, 1, 1, 1, 1, 5, 5, 1, 1, 1, 5, 33, 33, 0, 0, 3, 4, 5, 6, 3, 6, 0, 3, 3, 3, 3, 3, 3, 5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 5, 5, 3, 3, 3, 5, 5, 3, 3, 5, 3, 5, 1, 1, 1, 1, 1, 3, 1, 3, 1, 3, 1, 3, 1, 3, 1, 1, 1, 3, 1, 1, 1, 1]

pub let _pcre2_hspace_list_8: [20]c_uint = [9, 32, 160, 5760, 6158, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288, 4294967295]

pub let _pcre2_vspace_list_8: [8]c_uint = [10, 11, 12, 13, 133, 8232, 8233, 4294967295]

pub let _pcre2_callout_start_delims_8: [9]c_uint = [96, 39, 34, 94, 37, 35, 36, 123, 0]

pub let _pcre2_callout_end_delims_8: [9]c_uint = [96, 39, 34, 94, 37, 35, 36, 125, 0]

pub let _pcre2_utf8_table1: [6]c_int = [127, 2047, 65535, 2097151, 67108863, 2147483647]

pub let _pcre2_utf8_table1_size: c_uint = 6

pub let _pcre2_utf8_table2: [6]c_int = [0, 192, 224, 240, 248, 252]

pub let _pcre2_utf8_table3: [6]c_int = [255, 31, 15, 7, 3, 1]

pub let _pcre2_utf8_table4: [64]u8 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5]

pub let _pcre2_ucp_gentype_8: [30]c_uint = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6]

pub let _pcre2_ucp_gbtable_8: [15]c_uint = [(((1 as c_uint) << (ucp_gbLF as c_uint))), 0, 0, 8232, ((((((((((((((((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbPrepend as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbL as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbLV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbLVT as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbOther as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbRegional_Indicator as c_uint))) as c_uint)), 8232, ((((((((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbL as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbLV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbLVT as c_uint))) as c_uint)), ((((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)), ((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)), ((((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)), ((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)), (((1 as c_uint) << (ucp_gbRegional_Indicator as c_uint))), 8232, ((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbExtended_Pictographic as c_uint))) as c_uint)), 8232]

pub let _pcre2_utt_names_8: [3779]c_char = [97, 100, 108, 97, 109, 0, 97, 100, 108, 109, 0, 97, 103, 104, 98, 0, 97, 104, 101, 120, 0, 97, 104, 111, 109, 0, 97, 108, 112, 104, 97, 0, 97, 108, 112, 104, 97, 98, 101, 116, 105, 99, 0, 97, 110, 97, 116, 111, 108, 105, 97, 110, 104, 105, 101, 114, 111, 103, 108, 121, 112, 104, 115, 0, 97, 110, 121, 0, 97, 114, 97, 98, 0, 97, 114, 97, 98, 105, 99, 0, 97, 114, 109, 101, 110, 105, 97, 110, 0, 97, 114, 109, 105, 0, 97, 114, 109, 110, 0, 97, 115, 99, 105, 105, 0, 97, 115, 99, 105, 105, 104, 101, 120, 100, 105, 103, 105, 116, 0, 97, 118, 101, 115, 116, 97, 110, 0, 97, 118, 115, 116, 0, 98, 97, 108, 105, 0, 98, 97, 108, 105, 110, 101, 115, 101, 0, 98, 97, 109, 117, 0, 98, 97, 109, 117, 109, 0, 98, 97, 115, 115, 0, 98, 97, 115, 115, 97, 118, 97, 104, 0, 98, 97, 116, 97, 107, 0, 98, 97, 116, 107, 0, 98, 101, 110, 103, 0, 98, 101, 110, 103, 97, 108, 105, 0, 98, 104, 97, 105, 107, 115, 117, 107, 105, 0, 98, 104, 107, 115, 0, 98, 105, 100, 105, 97, 108, 0, 98, 105, 100, 105, 97, 110, 0, 98, 105, 100, 105, 98, 0, 98, 105, 100, 105, 98, 110, 0, 98, 105, 100, 105, 99, 0, 98, 105, 100, 105, 99, 111, 110, 116, 114, 111, 108, 0, 98, 105, 100, 105, 99, 115, 0, 98, 105, 100, 105, 101, 110, 0, 98, 105, 100, 105, 101, 115, 0, 98, 105, 100, 105, 101, 116, 0, 98, 105, 100, 105, 102, 115, 105, 0, 98, 105, 100, 105, 108, 0, 98, 105, 100, 105, 108, 114, 101, 0, 98, 105, 100, 105, 108, 114, 105, 0, 98, 105, 100, 105, 108, 114, 111, 0, 98, 105, 100, 105, 109, 0, 98, 105, 100, 105, 109, 105, 114, 114, 111, 114, 101, 100, 0, 98, 105, 100, 105, 110, 115, 109, 0, 98, 105, 100, 105, 111, 110, 0, 98, 105, 100, 105, 112, 100, 102, 0, 98, 105, 100, 105, 112, 100, 105, 0, 98, 105, 100, 105, 114, 0, 98, 105, 100, 105, 114, 108, 101, 0, 98, 105, 100, 105, 114, 108, 105, 0, 98, 105, 100, 105, 114, 108, 111, 0, 98, 105, 100, 105, 115, 0, 98, 105, 100, 105, 119, 115, 0, 98, 111, 112, 111, 0, 98, 111, 112, 111, 109, 111, 102, 111, 0, 98, 114, 97, 104, 0, 98, 114, 97, 104, 109, 105, 0, 98, 114, 97, 105, 0, 98, 114, 97, 105, 108, 108, 101, 0, 98, 117, 103, 105, 0, 98, 117, 103, 105, 110, 101, 115, 101, 0, 98, 117, 104, 100, 0, 98, 117, 104, 105, 100, 0, 99, 0, 99, 97, 107, 109, 0, 99, 97, 110, 97, 100, 105, 97, 110, 97, 98, 111, 114, 105, 103, 105, 110, 97, 108, 0, 99, 97, 110, 115, 0, 99, 97, 114, 105, 0, 99, 97, 114, 105, 97, 110, 0, 99, 97, 115, 101, 100, 0, 99, 97, 115, 101, 105, 103, 110, 111, 114, 97, 98, 108, 101, 0, 99, 97, 117, 99, 97, 115, 105, 97, 110, 97, 108, 98, 97, 110, 105, 97, 110, 0, 99, 99, 0, 99, 102, 0, 99, 104, 97, 107, 109, 97, 0, 99, 104, 97, 109, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 99, 97, 115, 101, 102, 111, 108, 100, 101, 100, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 99, 97, 115, 101, 109, 97, 112, 112, 101, 100, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 108, 111, 119, 101, 114, 99, 97, 115, 101, 100, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 116, 105, 116, 108, 101, 99, 97, 115, 101, 100, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 117, 112, 112, 101, 114, 99, 97, 115, 101, 100, 0, 99, 104, 101, 114, 0, 99, 104, 101, 114, 111, 107, 101, 101, 0, 99, 104, 111, 114, 97, 115, 109, 105, 97, 110, 0, 99, 104, 114, 115, 0, 99, 105, 0, 99, 110, 0, 99, 111, 0, 99, 111, 109, 109, 111, 110, 0, 99, 111, 112, 116, 0, 99, 111, 112, 116, 105, 99, 0, 99, 112, 109, 110, 0, 99, 112, 114, 116, 0, 99, 115, 0, 99, 117, 110, 101, 105, 102, 111, 114, 109, 0, 99, 119, 99, 102, 0, 99, 119, 99, 109, 0, 99, 119, 108, 0, 99, 119, 116, 0, 99, 119, 117, 0, 99, 121, 112, 114, 105, 111, 116, 0, 99, 121, 112, 114, 111, 109, 105, 110, 111, 97, 110, 0, 99, 121, 114, 105, 108, 108, 105, 99, 0, 99, 121, 114, 108, 0, 100, 97, 115, 104, 0, 100, 101, 102, 97, 117, 108, 116, 105, 103, 110, 111, 114, 97, 98, 108, 101, 99, 111, 100, 101, 112, 111, 105, 110, 116, 0, 100, 101, 112, 0, 100, 101, 112, 114, 101, 99, 97, 116, 101, 100, 0, 100, 101, 115, 101, 114, 101, 116, 0, 100, 101, 118, 97, 0, 100, 101, 118, 97, 110, 97, 103, 97, 114, 105, 0, 100, 105, 0, 100, 105, 97, 0, 100, 105, 97, 99, 114, 105, 116, 105, 99, 0, 100, 105, 97, 107, 0, 100, 105, 118, 101, 115, 97, 107, 117, 114, 117, 0, 100, 111, 103, 114, 0, 100, 111, 103, 114, 97, 0, 100, 115, 114, 116, 0, 100, 117, 112, 108, 0, 100, 117, 112, 108, 111, 121, 97, 110, 0, 101, 98, 97, 115, 101, 0, 101, 99, 111, 109, 112, 0, 101, 103, 121, 112, 0, 101, 103, 121, 112, 116, 105, 97, 110, 104, 105, 101, 114, 111, 103, 108, 121, 112, 104, 115, 0, 101, 108, 98, 97, 0, 101, 108, 98, 97, 115, 97, 110, 0, 101, 108, 121, 109, 0, 101, 108, 121, 109, 97, 105, 99, 0, 101, 109, 111, 100, 0, 101, 109, 111, 106, 105, 0, 101, 109, 111, 106, 105, 99, 111, 109, 112, 111, 110, 101, 110, 116, 0, 101, 109, 111, 106, 105, 109, 111, 100, 105, 102, 105, 101, 114, 0, 101, 109, 111, 106, 105, 109, 111, 100, 105, 102, 105, 101, 114, 98, 97, 115, 101, 0, 101, 109, 111, 106, 105, 112, 114, 101, 115, 101, 110, 116, 97, 116, 105, 111, 110, 0, 101, 112, 114, 101, 115, 0, 101, 116, 104, 105, 0, 101, 116, 104, 105, 111, 112, 105, 99, 0, 101, 120, 116, 0, 101, 120, 116, 101, 110, 100, 101, 100, 112, 105, 99, 116, 111, 103, 114, 97, 112, 104, 105, 99, 0, 101, 120, 116, 101, 110, 100, 101, 114, 0, 101, 120, 116, 112, 105, 99, 116, 0, 103, 97, 114, 97, 0, 103, 97, 114, 97, 121, 0, 103, 101, 111, 114, 0, 103, 101, 111, 114, 103, 105, 97, 110, 0, 103, 108, 97, 103, 0, 103, 108, 97, 103, 111, 108, 105, 116, 105, 99, 0, 103, 111, 110, 103, 0, 103, 111, 110, 109, 0, 103, 111, 116, 104, 0, 103, 111, 116, 104, 105, 99, 0, 103, 114, 97, 110, 0, 103, 114, 97, 110, 116, 104, 97, 0, 103, 114, 97, 112, 104, 101, 109, 101, 98, 97, 115, 101, 0, 103, 114, 97, 112, 104, 101, 109, 101, 101, 120, 116, 101, 110, 100, 0, 103, 114, 97, 112, 104, 101, 109, 101, 108, 105, 110, 107, 0, 103, 114, 98, 97, 115, 101, 0, 103, 114, 101, 101, 107, 0, 103, 114, 101, 107, 0, 103, 114, 101, 120, 116, 0, 103, 114, 108, 105, 110, 107, 0, 103, 117, 106, 97, 114, 97, 116, 105, 0, 103, 117, 106, 114, 0, 103, 117, 107, 104, 0, 103, 117, 110, 106, 97, 108, 97, 103, 111, 110, 100, 105, 0, 103, 117, 114, 109, 117, 107, 104, 105, 0, 103, 117, 114, 117, 0, 103, 117, 114, 117, 110, 103, 107, 104, 101, 109, 97, 0, 104, 97, 110, 0, 104, 97, 110, 103, 0, 104, 97, 110, 103, 117, 108, 0, 104, 97, 110, 105, 0, 104, 97, 110, 105, 102, 105, 114, 111, 104, 105, 110, 103, 121, 97, 0, 104, 97, 110, 111, 0, 104, 97, 110, 117, 110, 111, 111, 0, 104, 97, 116, 114, 0, 104, 97, 116, 114, 97, 110, 0, 104, 101, 98, 114, 0, 104, 101, 98, 114, 101, 119, 0, 104, 101, 120, 0, 104, 101, 120, 100, 105, 103, 105, 116, 0, 104, 105, 114, 97, 0, 104, 105, 114, 97, 103, 97, 110, 97, 0, 104, 108, 117, 119, 0, 104, 109, 110, 103, 0, 104, 109, 110, 112, 0, 104, 117, 110, 103, 0, 105, 100, 99, 0, 105, 100, 99, 111, 109, 112, 97, 116, 109, 97, 116, 104, 99, 111, 110, 116, 105, 110, 117, 101, 0, 105, 100, 99, 111, 109, 112, 97, 116, 109, 97, 116, 104, 115, 116, 97, 114, 116, 0, 105, 100, 99, 111, 110, 116, 105, 110, 117, 101, 0, 105, 100, 101, 111, 0, 105, 100, 101, 111, 103, 114, 97, 112, 104, 105, 99, 0, 105, 100, 115, 0, 105, 100, 115, 98, 0, 105, 100, 115, 98, 105, 110, 97, 114, 121, 111, 112, 101, 114, 97, 116, 111, 114, 0, 105, 100, 115, 116, 0, 105, 100, 115, 116, 97, 114, 116, 0, 105, 100, 115, 116, 114, 105, 110, 97, 114, 121, 111, 112, 101, 114, 97, 116, 111, 114, 0, 105, 100, 115, 117, 0, 105, 100, 115, 117, 110, 97, 114, 121, 111, 112, 101, 114, 97, 116, 111, 114, 0, 105, 109, 112, 101, 114, 105, 97, 108, 97, 114, 97, 109, 97, 105, 99, 0, 105, 110, 99, 98, 0, 105, 110, 104, 101, 114, 105, 116, 101, 100, 0, 105, 110, 115, 99, 114, 105, 112, 116, 105, 111, 110, 97, 108, 112, 97, 104, 108, 97, 118, 105, 0, 105, 110, 115, 99, 114, 105, 112, 116, 105, 111, 110, 97, 108, 112, 97, 114, 116, 104, 105, 97, 110, 0, 105, 116, 97, 108, 0, 106, 97, 118, 97, 0, 106, 97, 118, 97, 110, 101, 115, 101, 0, 106, 111, 105, 110, 99, 0, 106, 111, 105, 110, 99, 111, 110, 116, 114, 111, 108, 0, 107, 97, 105, 116, 104, 105, 0, 107, 97, 108, 105, 0, 107, 97, 110, 97, 0, 107, 97, 110, 110, 97, 100, 97, 0, 107, 97, 116, 97, 107, 97, 110, 97, 0, 107, 97, 119, 105, 0, 107, 97, 121, 97, 104, 108, 105, 0, 107, 104, 97, 114, 0, 107, 104, 97, 114, 111, 115, 104, 116, 104, 105, 0, 107, 104, 105, 116, 97, 110, 115, 109, 97, 108, 108, 115, 99, 114, 105, 112, 116, 0, 107, 104, 109, 101, 114, 0, 107, 104, 109, 114, 0, 107, 104, 111, 106, 0, 107, 104, 111, 106, 107, 105, 0, 107, 104, 117, 100, 97, 119, 97, 100, 105, 0, 107, 105, 114, 97, 116, 114, 97, 105, 0, 107, 105, 116, 115, 0, 107, 110, 100, 97, 0, 107, 114, 97, 105, 0, 107, 116, 104, 105, 0, 108, 0, 108, 38, 0, 108, 97, 110, 97, 0, 108, 97, 111, 0, 108, 97, 111, 111, 0, 108, 97, 116, 105, 110, 0, 108, 97, 116, 110, 0, 108, 99, 0, 108, 101, 112, 99, 0, 108, 101, 112, 99, 104, 97, 0, 108, 105, 109, 98, 0, 108, 105, 109, 98, 117, 0, 108, 105, 110, 97, 0, 108, 105, 110, 98, 0, 108, 105, 110, 101, 97, 114, 97, 0, 108, 105, 110, 101, 97, 114, 98, 0, 108, 105, 115, 117, 0, 108, 108, 0, 108, 109, 0, 108, 111, 0, 108, 111, 101, 0, 108, 111, 103, 105, 99, 97, 108, 111, 114, 100, 101, 114, 101, 120, 99, 101, 112, 116, 105, 111, 110, 0, 108, 111, 119, 101, 114, 0, 108, 111, 119, 101, 114, 99, 97, 115, 101, 0, 108, 116, 0, 108, 117, 0, 108, 121, 99, 105, 0, 108, 121, 99, 105, 97, 110, 0, 108, 121, 100, 105, 0, 108, 121, 100, 105, 97, 110, 0, 109, 0, 109, 97, 104, 97, 106, 97, 110, 105, 0, 109, 97, 104, 106, 0, 109, 97, 107, 97, 0, 109, 97, 107, 97, 115, 97, 114, 0, 109, 97, 108, 97, 121, 97, 108, 97, 109, 0, 109, 97, 110, 100, 0, 109, 97, 110, 100, 97, 105, 99, 0, 109, 97, 110, 105, 0, 109, 97, 110, 105, 99, 104, 97, 101, 97, 110, 0, 109, 97, 114, 99, 0, 109, 97, 114, 99, 104, 101, 110, 0, 109, 97, 115, 97, 114, 97, 109, 103, 111, 110, 100, 105, 0, 109, 97, 116, 104, 0, 109, 99, 0, 109, 99, 109, 0, 109, 101, 0, 109, 101, 100, 101, 102, 97, 105, 100, 114, 105, 110, 0, 109, 101, 100, 102, 0, 109, 101, 101, 116, 101, 105, 109, 97, 121, 101, 107, 0, 109, 101, 110, 100, 0, 109, 101, 110, 100, 101, 107, 105, 107, 97, 107, 117, 105, 0, 109, 101, 114, 99, 0, 109, 101, 114, 111, 0, 109, 101, 114, 111, 105, 116, 105, 99, 99, 117, 114, 115, 105, 118, 101, 0, 109, 101, 114, 111, 105, 116, 105, 99, 104, 105, 101, 114, 111, 103, 108, 121, 112, 104, 115, 0, 109, 105, 97, 111, 0, 109, 108, 121, 109, 0, 109, 110, 0, 109, 111, 100, 105, 0, 109, 111, 100, 105, 102, 105, 101, 114, 99, 111, 109, 98, 105, 110, 105, 110, 103, 109, 97, 114, 107, 0, 109, 111, 110, 103, 0, 109, 111, 110, 103, 111, 108, 105, 97, 110, 0, 109, 114, 111, 0, 109, 114, 111, 111, 0, 109, 116, 101, 105, 0, 109, 117, 108, 116, 0, 109, 117, 108, 116, 97, 110, 105, 0, 109, 121, 97, 110, 109, 97, 114, 0, 109, 121, 109, 114, 0, 110, 0, 110, 97, 98, 97, 116, 97, 101, 97, 110, 0, 110, 97, 103, 109, 0, 110, 97, 103, 109, 117, 110, 100, 97, 114, 105, 0, 110, 97, 110, 100, 0, 110, 97, 110, 100, 105, 110, 97, 103, 97, 114, 105, 0, 110, 97, 114, 98, 0, 110, 98, 97, 116, 0, 110, 99, 104, 97, 114, 0, 110, 100, 0, 110, 101, 119, 97, 0, 110, 101, 119, 116, 97, 105, 108, 117, 101, 0, 110, 107, 111, 0, 110, 107, 111, 111, 0, 110, 108, 0, 110, 111, 0, 110, 111, 110, 99, 104, 97, 114, 97, 99, 116, 101, 114, 99, 111, 100, 101, 112, 111, 105, 110, 116, 0, 110, 115, 104, 117, 0, 110, 117, 115, 104, 117, 0, 110, 121, 105, 97, 107, 101, 110, 103, 112, 117, 97, 99, 104, 117, 101, 104, 109, 111, 110, 103, 0, 111, 103, 97, 109, 0, 111, 103, 104, 97, 109, 0, 111, 108, 99, 104, 105, 107, 105, 0, 111, 108, 99, 107, 0, 111, 108, 100, 104, 117, 110, 103, 97, 114, 105, 97, 110, 0, 111, 108, 100, 105, 116, 97, 108, 105, 99, 0, 111, 108, 100, 110, 111, 114, 116, 104, 97, 114, 97, 98, 105, 97, 110, 0, 111, 108, 100, 112, 101, 114, 109, 105, 99, 0, 111, 108, 100, 112, 101, 114, 115, 105, 97, 110, 0, 111, 108, 100, 115, 111, 103, 100, 105, 97, 110, 0, 111, 108, 100, 115, 111, 117, 116, 104, 97, 114, 97, 98, 105, 97, 110, 0, 111, 108, 100, 116, 117, 114, 107, 105, 99, 0, 111, 108, 100, 117, 121, 103, 104, 117, 114, 0, 111, 108, 111, 110, 97, 108, 0, 111, 110, 97, 111, 0, 111, 114, 105, 121, 97, 0, 111, 114, 107, 104, 0, 111, 114, 121, 97, 0, 111, 115, 97, 103, 101, 0, 111, 115, 103, 101, 0, 111, 115, 109, 97, 0, 111, 115, 109, 97, 110, 121, 97, 0, 111, 117, 103, 114, 0, 112, 0, 112, 97, 104, 97, 119, 104, 104, 109, 111, 110, 103, 0, 112, 97, 108, 109, 0, 112, 97, 108, 109, 121, 114, 101, 110, 101, 0, 112, 97, 116, 115, 121, 110, 0, 112, 97, 116, 116, 101, 114, 110, 115, 121, 110, 116, 97, 120, 0, 112, 97, 116, 116, 101, 114, 110, 119, 104, 105, 116, 101, 115, 112, 97, 99, 101, 0, 112, 97, 116, 119, 115, 0, 112, 97, 117, 99, 0, 112, 97, 117, 99, 105, 110, 104, 97, 117, 0, 112, 99, 0, 112, 99, 109, 0, 112, 100, 0, 112, 101, 0, 112, 101, 114, 109, 0, 112, 102, 0, 112, 104, 97, 103, 0, 112, 104, 97, 103, 115, 112, 97, 0, 112, 104, 108, 105, 0, 112, 104, 108, 112, 0, 112, 104, 110, 120, 0, 112, 104, 111, 101, 110, 105, 99, 105, 97, 110, 0, 112, 105, 0, 112, 108, 114, 100, 0, 112, 111, 0, 112, 114, 101, 112, 101, 110, 100, 101, 100, 99, 111, 110, 99, 97, 116, 101, 110, 97, 116, 105, 111, 110, 109, 97, 114, 107, 0, 112, 114, 116, 105, 0, 112, 115, 0, 112, 115, 97, 108, 116, 101, 114, 112, 97, 104, 108, 97, 118, 105, 0, 113, 97, 97, 99, 0, 113, 97, 97, 105, 0, 113, 109, 97, 114, 107, 0, 113, 117, 111, 116, 97, 116, 105, 111, 110, 109, 97, 114, 107, 0, 114, 97, 100, 105, 99, 97, 108, 0, 114, 101, 103, 105, 111, 110, 97, 108, 105, 110, 100, 105, 99, 97, 116, 111, 114, 0, 114, 101, 106, 97, 110, 103, 0, 114, 105, 0, 114, 106, 110, 103, 0, 114, 111, 104, 103, 0, 114, 117, 110, 105, 99, 0, 114, 117, 110, 114, 0, 115, 0, 115, 97, 109, 97, 114, 105, 116, 97, 110, 0, 115, 97, 109, 114, 0, 115, 97, 114, 98, 0, 115, 97, 117, 114, 0, 115, 97, 117, 114, 97, 115, 104, 116, 114, 97, 0, 115, 99, 0, 115, 100, 0, 115, 101, 110, 116, 101, 110, 99, 101, 116, 101, 114, 109, 105, 110, 97, 108, 0, 115, 103, 110, 119, 0, 115, 104, 97, 114, 97, 100, 97, 0, 115, 104, 97, 118, 105, 97, 110, 0, 115, 104, 97, 119, 0, 115, 104, 114, 100, 0, 115, 105, 100, 100, 0, 115, 105, 100, 100, 104, 97, 109, 0, 115, 105, 103, 110, 119, 114, 105, 116, 105, 110, 103, 0, 115, 105, 110, 100, 0, 115, 105, 110, 104, 0, 115, 105, 110, 104, 97, 108, 97, 0, 115, 107, 0, 115, 109, 0, 115, 111, 0, 115, 111, 102, 116, 100, 111, 116, 116, 101, 100, 0, 115, 111, 103, 100, 0, 115, 111, 103, 100, 105, 97, 110, 0, 115, 111, 103, 111, 0, 115, 111, 114, 97, 0, 115, 111, 114, 97, 115, 111, 109, 112, 101, 110, 103, 0, 115, 111, 121, 111, 0, 115, 111, 121, 111, 109, 98, 111, 0, 115, 112, 97, 99, 101, 0, 115, 116, 101, 114, 109, 0, 115, 117, 110, 100, 0, 115, 117, 110, 100, 97, 110, 101, 115, 101, 0, 115, 117, 110, 117, 0, 115, 117, 110, 117, 119, 97, 114, 0, 115, 121, 108, 111, 0, 115, 121, 108, 111, 116, 105, 110, 97, 103, 114, 105, 0, 115, 121, 114, 99, 0, 115, 121, 114, 105, 97, 99, 0, 116, 97, 103, 97, 108, 111, 103, 0, 116, 97, 103, 98, 0, 116, 97, 103, 98, 97, 110, 119, 97, 0, 116, 97, 105, 108, 101, 0, 116, 97, 105, 116, 104, 97, 109, 0, 116, 97, 105, 118, 105, 101, 116, 0, 116, 97, 107, 114, 0, 116, 97, 107, 114, 105, 0, 116, 97, 108, 101, 0, 116, 97, 108, 117, 0, 116, 97, 109, 105, 108, 0, 116, 97, 109, 108, 0, 116, 97, 110, 103, 0, 116, 97, 110, 103, 115, 97, 0, 116, 97, 110, 103, 117, 116, 0, 116, 97, 118, 116, 0, 116, 101, 108, 117, 0, 116, 101, 108, 117, 103, 117, 0, 116, 101, 114, 109, 0, 116, 101, 114, 109, 105, 110, 97, 108, 112, 117, 110, 99, 116, 117, 97, 116, 105, 111, 110, 0, 116, 102, 110, 103, 0, 116, 103, 108, 103, 0, 116, 104, 97, 97, 0, 116, 104, 97, 97, 110, 97, 0, 116, 104, 97, 105, 0, 116, 105, 98, 101, 116, 97, 110, 0, 116, 105, 98, 116, 0, 116, 105, 102, 105, 110, 97, 103, 104, 0, 116, 105, 114, 104, 0, 116, 105, 114, 104, 117, 116, 97, 0, 116, 110, 115, 97, 0, 116, 111, 100, 104, 114, 105, 0, 116, 111, 100, 114, 0, 116, 111, 116, 111, 0, 116, 117, 108, 117, 116, 105, 103, 97, 108, 97, 114, 105, 0, 116, 117, 116, 103, 0, 117, 103, 97, 114, 0, 117, 103, 97, 114, 105, 116, 105, 99, 0, 117, 105, 100, 101, 111, 0, 117, 110, 105, 102, 105, 101, 100, 105, 100, 101, 111, 103, 114, 97, 112, 104, 0, 117, 110, 107, 110, 111, 119, 110, 0, 117, 112, 112, 101, 114, 0, 117, 112, 112, 101, 114, 99, 97, 115, 101, 0, 118, 97, 105, 0, 118, 97, 105, 105, 0, 118, 97, 114, 105, 97, 116, 105, 111, 110, 115, 101, 108, 101, 99, 116, 111, 114, 0, 118, 105, 116, 104, 0, 118, 105, 116, 104, 107, 117, 113, 105, 0, 118, 115, 0, 119, 97, 110, 99, 104, 111, 0, 119, 97, 114, 97, 0, 119, 97, 114, 97, 110, 103, 99, 105, 116, 105, 0, 119, 99, 104, 111, 0, 119, 104, 105, 116, 101, 115, 112, 97, 99, 101, 0, 119, 115, 112, 97, 99, 101, 0, 120, 97, 110, 0, 120, 105, 100, 99, 0, 120, 105, 100, 99, 111, 110, 116, 105, 110, 117, 101, 0, 120, 105, 100, 115, 0, 120, 105, 100, 115, 116, 97, 114, 116, 0, 120, 112, 101, 111, 0, 120, 112, 115, 0, 120, 115, 112, 0, 120, 115, 117, 120, 0, 120, 117, 99, 0, 120, 119, 100, 0, 121, 101, 122, 105, 0, 121, 101, 122, 105, 100, 105, 0, 121, 105, 0, 121, 105, 105, 105, 0, 122, 0, 122, 97, 110, 97, 98, 97, 122, 97, 114, 115, 113, 117, 97, 114, 101, 0, 122, 97, 110, 98, 0, 122, 105, 110, 104, 0, 122, 108, 0, 122, 112, 0, 122, 115, 0, 122, 121, 121, 121, 0, 122, 122, 122, 122, 0, 0]

pub let _pcre2_utt_8: [510]ucp_type_table = [ucp_type_table { name_offset: 0, type_: 4, value: 79 }, ucp_type_table { name_offset: 6, type_: 4, value: 79 }, ucp_type_table { name_offset: 11, type_: 4, value: 64 }, ucp_type_table { name_offset: 16, type_: 12, value: 1 }, ucp_type_table { name_offset: 21, type_: 3, value: 147 }, ucp_type_table { name_offset: 26, type_: 12, value: 2 }, ucp_type_table { name_offset: 32, type_: 12, value: 2 }, ucp_type_table { name_offset: 43, type_: 3, value: 148 }, ucp_type_table { name_offset: 64, type_: 13, value: 0 }, ucp_type_table { name_offset: 68, type_: 4, value: 5 }, ucp_type_table { name_offset: 73, type_: 4, value: 5 }, ucp_type_table { name_offset: 80, type_: 4, value: 3 }, ucp_type_table { name_offset: 89, type_: 3, value: 128 }, ucp_type_table { name_offset: 94, type_: 4, value: 3 }, ucp_type_table { name_offset: 99, type_: 12, value: 0 }, ucp_type_table { name_offset: 105, type_: 12, value: 1 }, ucp_type_table { name_offset: 119, type_: 4, value: 53 }, ucp_type_table { name_offset: 127, type_: 4, value: 53 }, ucp_type_table { name_offset: 132, type_: 3, value: 113 }, ucp_type_table { name_offset: 137, type_: 3, value: 113 }, ucp_type_table { name_offset: 146, type_: 3, value: 126 }, ucp_type_table { name_offset: 151, type_: 3, value: 126 }, ucp_type_table { name_offset: 157, type_: 3, value: 137 }, ucp_type_table { name_offset: 162, type_: 3, value: 137 }, ucp_type_table { name_offset: 171, type_: 3, value: 132 }, ucp_type_table { name_offset: 177, type_: 3, value: 132 }, ucp_type_table { name_offset: 182, type_: 4, value: 9 }, ucp_type_table { name_offset: 187, type_: 4, value: 9 }, ucp_type_table { name_offset: 195, type_: 3, value: 151 }, ucp_type_table { name_offset: 205, type_: 3, value: 151 }, ucp_type_table { name_offset: 210, type_: 11, value: 0 }, ucp_type_table { name_offset: 217, type_: 11, value: 1 }, ucp_type_table { name_offset: 224, type_: 11, value: 2 }, ucp_type_table { name_offset: 230, type_: 11, value: 3 }, ucp_type_table { name_offset: 237, type_: 12, value: 3 }, ucp_type_table { name_offset: 243, type_: 12, value: 3 }, ucp_type_table { name_offset: 255, type_: 11, value: 4 }, ucp_type_table { name_offset: 262, type_: 11, value: 5 }, ucp_type_table { name_offset: 269, type_: 11, value: 6 }, ucp_type_table { name_offset: 276, type_: 11, value: 7 }, ucp_type_table { name_offset: 283, type_: 11, value: 8 }, ucp_type_table { name_offset: 291, type_: 11, value: 9 }, ucp_type_table { name_offset: 297, type_: 11, value: 10 }, ucp_type_table { name_offset: 305, type_: 11, value: 11 }, ucp_type_table { name_offset: 313, type_: 11, value: 12 }, ucp_type_table { name_offset: 321, type_: 12, value: 4 }, ucp_type_table { name_offset: 327, type_: 12, value: 4 }, ucp_type_table { name_offset: 340, type_: 11, value: 13 }, ucp_type_table { name_offset: 348, type_: 11, value: 14 }, ucp_type_table { name_offset: 355, type_: 11, value: 15 }, ucp_type_table { name_offset: 363, type_: 11, value: 16 }, ucp_type_table { name_offset: 371, type_: 11, value: 17 }, ucp_type_table { name_offset: 377, type_: 11, value: 18 }, ucp_type_table { name_offset: 385, type_: 11, value: 19 }, ucp_type_table { name_offset: 393, type_: 11, value: 20 }, ucp_type_table { name_offset: 401, type_: 11, value: 21 }, ucp_type_table { name_offset: 407, type_: 11, value: 22 }, ucp_type_table { name_offset: 414, type_: 4, value: 29 }, ucp_type_table { name_offset: 419, type_: 4, value: 29 }, ucp_type_table { name_offset: 428, type_: 3, value: 133 }, ucp_type_table { name_offset: 433, type_: 3, value: 133 }, ucp_type_table { name_offset: 440, type_: 3, value: 109 }, ucp_type_table { name_offset: 445, type_: 3, value: 109 }, ucp_type_table { name_offset: 453, type_: 4, value: 42 }, ucp_type_table { name_offset: 458, type_: 4, value: 42 }, ucp_type_table { name_offset: 467, type_: 4, value: 35 }, ucp_type_table { name_offset: 472, type_: 4, value: 35 }, ucp_type_table { name_offset: 478, type_: 1, value: 0 }, ucp_type_table { name_offset: 480, type_: 4, value: 60 }, ucp_type_table { name_offset: 485, type_: 3, value: 101 }, ucp_type_table { name_offset: 504, type_: 3, value: 101 }, ucp_type_table { name_offset: 509, type_: 4, value: 51 }, ucp_type_table { name_offset: 514, type_: 4, value: 51 }, ucp_type_table { name_offset: 521, type_: 12, value: 6 }, ucp_type_table { name_offset: 527, type_: 12, value: 5 }, ucp_type_table { name_offset: 541, type_: 4, value: 64 }, ucp_type_table { name_offset: 559, type_: 2, value: 0 }, ucp_type_table { name_offset: 562, type_: 2, value: 1 }, ucp_type_table { name_offset: 565, type_: 4, value: 60 }, ucp_type_table { name_offset: 572, type_: 3, value: 122 }, ucp_type_table { name_offset: 577, type_: 12, value: 7 }, ucp_type_table { name_offset: 599, type_: 12, value: 8 }, ucp_type_table { name_offset: 621, type_: 12, value: 9 }, ucp_type_table { name_offset: 643, type_: 12, value: 10 }, ucp_type_table { name_offset: 665, type_: 12, value: 11 }, ucp_type_table { name_offset: 687, type_: 4, value: 24 }, ucp_type_table { name_offset: 692, type_: 4, value: 24 }, ucp_type_table { name_offset: 701, type_: 3, value: 163 }, ucp_type_table { name_offset: 712, type_: 3, value: 163 }, ucp_type_table { name_offset: 717, type_: 12, value: 5 }, ucp_type_table { name_offset: 720, type_: 2, value: 2 }, ucp_type_table { name_offset: 723, type_: 2, value: 3 }, ucp_type_table { name_offset: 726, type_: 3, value: 99 }, ucp_type_table { name_offset: 733, type_: 4, value: 43 }, ucp_type_table { name_offset: 738, type_: 4, value: 43 }, ucp_type_table { name_offset: 745, type_: 4, value: 89 }, ucp_type_table { name_offset: 750, type_: 4, value: 41 }, ucp_type_table { name_offset: 755, type_: 2, value: 4 }, ucp_type_table { name_offset: 758, type_: 3, value: 114 }, ucp_type_table { name_offset: 768, type_: 12, value: 7 }, ucp_type_table { name_offset: 773, type_: 12, value: 8 }, ucp_type_table { name_offset: 778, type_: 12, value: 9 }, ucp_type_table { name_offset: 782, type_: 12, value: 10 }, ucp_type_table { name_offset: 786, type_: 12, value: 11 }, ucp_type_table { name_offset: 790, type_: 4, value: 41 }, ucp_type_table { name_offset: 798, type_: 4, value: 89 }, ucp_type_table { name_offset: 810, type_: 4, value: 2 }, ucp_type_table { name_offset: 819, type_: 4, value: 2 }, ucp_type_table { name_offset: 824, type_: 12, value: 12 }, ucp_type_table { name_offset: 829, type_: 12, value: 13 }, ucp_type_table { name_offset: 855, type_: 12, value: 14 }, ucp_type_table { name_offset: 859, type_: 12, value: 14 }, ucp_type_table { name_offset: 870, type_: 3, value: 105 }, ucp_type_table { name_offset: 878, type_: 4, value: 8 }, ucp_type_table { name_offset: 883, type_: 4, value: 8 }, ucp_type_table { name_offset: 894, type_: 12, value: 13 }, ucp_type_table { name_offset: 897, type_: 12, value: 15 }, ucp_type_table { name_offset: 901, type_: 12, value: 15 }, ucp_type_table { name_offset: 911, type_: 3, value: 164 }, ucp_type_table { name_offset: 916, type_: 3, value: 164 }, ucp_type_table { name_offset: 927, type_: 4, value: 83 }, ucp_type_table { name_offset: 932, type_: 4, value: 83 }, ucp_type_table { name_offset: 938, type_: 3, value: 105 }, ucp_type_table { name_offset: 943, type_: 4, value: 65 }, ucp_type_table { name_offset: 948, type_: 4, value: 65 }, ucp_type_table { name_offset: 957, type_: 12, value: 19 }, ucp_type_table { name_offset: 963, type_: 12, value: 17 }, ucp_type_table { name_offset: 969, type_: 3, value: 125 }, ucp_type_table { name_offset: 974, type_: 3, value: 125 }, ucp_type_table { name_offset: 994, type_: 4, value: 66 }, ucp_type_table { name_offset: 999, type_: 4, value: 66 }, ucp_type_table { name_offset: 1007, type_: 3, value: 160 }, ucp_type_table { name_offset: 1012, type_: 3, value: 160 }, ucp_type_table { name_offset: 1020, type_: 12, value: 18 }, ucp_type_table { name_offset: 1025, type_: 12, value: 16 }, ucp_type_table { name_offset: 1031, type_: 12, value: 17 }, ucp_type_table { name_offset: 1046, type_: 12, value: 18 }, ucp_type_table { name_offset: 1060, type_: 12, value: 19 }, ucp_type_table { name_offset: 1078, type_: 12, value: 20 }, ucp_type_table { name_offset: 1096, type_: 12, value: 20 }, ucp_type_table { name_offset: 1102, type_: 4, value: 23 }, ucp_type_table { name_offset: 1107, type_: 4, value: 23 }, ucp_type_table { name_offset: 1116, type_: 12, value: 22 }, ucp_type_table { name_offset: 1120, type_: 12, value: 21 }, ucp_type_table { name_offset: 1141, type_: 12, value: 22 }, ucp_type_table { name_offset: 1150, type_: 12, value: 21 }, ucp_type_table { name_offset: 1158, type_: 4, value: 92 }, ucp_type_table { name_offset: 1163, type_: 4, value: 92 }, ucp_type_table { name_offset: 1169, type_: 4, value: 21 }, ucp_type_table { name_offset: 1174, type_: 4, value: 21 }, ucp_type_table { name_offset: 1183, type_: 4, value: 44 }, ucp_type_table { name_offset: 1188, type_: 4, value: 44 }, ucp_type_table { name_offset: 1199, type_: 4, value: 84 }, ucp_type_table { name_offset: 1204, type_: 4, value: 82 }, ucp_type_table { name_offset: 1209, type_: 4, value: 32 }, ucp_type_table { name_offset: 1214, type_: 4, value: 32 }, ucp_type_table { name_offset: 1221, type_: 4, value: 67 }, ucp_type_table { name_offset: 1226, type_: 4, value: 67 }, ucp_type_table { name_offset: 1234, type_: 12, value: 23 }, ucp_type_table { name_offset: 1247, type_: 12, value: 24 }, ucp_type_table { name_offset: 1262, type_: 12, value: 25 }, ucp_type_table { name_offset: 1275, type_: 12, value: 23 }, ucp_type_table { name_offset: 1282, type_: 4, value: 1 }, ucp_type_table { name_offset: 1288, type_: 4, value: 1 }, ucp_type_table { name_offset: 1293, type_: 12, value: 24 }, ucp_type_table { name_offset: 1299, type_: 12, value: 25 }, ucp_type_table { name_offset: 1306, type_: 4, value: 11 }, ucp_type_table { name_offset: 1315, type_: 4, value: 11 }, ucp_type_table { name_offset: 1320, type_: 4, value: 93 }, ucp_type_table { name_offset: 1325, type_: 4, value: 84 }, ucp_type_table { name_offset: 1338, type_: 4, value: 10 }, ucp_type_table { name_offset: 1347, type_: 4, value: 10 }, ucp_type_table { name_offset: 1352, type_: 4, value: 93 }, ucp_type_table { name_offset: 1364, type_: 4, value: 30 }, ucp_type_table { name_offset: 1368, type_: 4, value: 22 }, ucp_type_table { name_offset: 1373, type_: 4, value: 22 }, ucp_type_table { name_offset: 1380, type_: 4, value: 30 }, ucp_type_table { name_offset: 1385, type_: 4, value: 85 }, ucp_type_table { name_offset: 1400, type_: 4, value: 34 }, ucp_type_table { name_offset: 1405, type_: 4, value: 34 }, ucp_type_table { name_offset: 1413, type_: 3, value: 149 }, ucp_type_table { name_offset: 1418, type_: 3, value: 149 }, ucp_type_table { name_offset: 1425, type_: 4, value: 4 }, ucp_type_table { name_offset: 1430, type_: 4, value: 4 }, ucp_type_table { name_offset: 1437, type_: 12, value: 26 }, ucp_type_table { name_offset: 1441, type_: 12, value: 26 }, ucp_type_table { name_offset: 1450, type_: 4, value: 27 }, ucp_type_table { name_offset: 1455, type_: 4, value: 27 }, ucp_type_table { name_offset: 1464, type_: 3, value: 148 }, ucp_type_table { name_offset: 1469, type_: 3, value: 138 }, ucp_type_table { name_offset: 1474, type_: 3, value: 161 }, ucp_type_table { name_offset: 1479, type_: 4, value: 78 }, ucp_type_table { name_offset: 1484, type_: 12, value: 32 }, ucp_type_table { name_offset: 1488, type_: 12, value: 30 }, ucp_type_table { name_offset: 1509, type_: 12, value: 31 }, ucp_type_table { name_offset: 1527, type_: 12, value: 32 }, ucp_type_table { name_offset: 1538, type_: 12, value: 34 }, ucp_type_table { name_offset: 1543, type_: 12, value: 34 }, ucp_type_table { name_offset: 1555, type_: 12, value: 33 }, ucp_type_table { name_offset: 1559, type_: 12, value: 27 }, ucp_type_table { name_offset: 1564, type_: 12, value: 27 }, ucp_type_table { name_offset: 1582, type_: 12, value: 28 }, ucp_type_table { name_offset: 1587, type_: 12, value: 33 }, ucp_type_table { name_offset: 1595, type_: 12, value: 28 }, ucp_type_table { name_offset: 1614, type_: 12, value: 29 }, ucp_type_table { name_offset: 1619, type_: 12, value: 29 }, ucp_type_table { name_offset: 1636, type_: 3, value: 128 }, ucp_type_table { name_offset: 1652, type_: 12, value: 35 }, ucp_type_table { name_offset: 1657, type_: 3, value: 106 }, ucp_type_table { name_offset: 1667, type_: 3, value: 131 }, ucp_type_table { name_offset: 1688, type_: 3, value: 130 }, ucp_type_table { name_offset: 1710, type_: 3, value: 104 }, ucp_type_table { name_offset: 1715, type_: 4, value: 56 }, ucp_type_table { name_offset: 1720, type_: 4, value: 56 }, ucp_type_table { name_offset: 1729, type_: 12, value: 36 }, ucp_type_table { name_offset: 1735, type_: 12, value: 36 }, ucp_type_table { name_offset: 1747, type_: 4, value: 58 }, ucp_type_table { name_offset: 1754, type_: 4, value: 49 }, ucp_type_table { name_offset: 1759, type_: 4, value: 28 }, ucp_type_table { name_offset: 1764, type_: 4, value: 15 }, ucp_type_table { name_offset: 1772, type_: 4, value: 28 }, ucp_type_table { name_offset: 1781, type_: 3, value: 168 }, ucp_type_table { name_offset: 1786, type_: 4, value: 49 }, ucp_type_table { name_offset: 1794, type_: 3, value: 112 }, ucp_type_table { name_offset: 1799, type_: 3, value: 112 }, ucp_type_table { name_offset: 1810, type_: 3, value: 165 }, ucp_type_table { name_offset: 1828, type_: 3, value: 103 }, ucp_type_table { name_offset: 1834, type_: 3, value: 103 }, ucp_type_table { name_offset: 1839, type_: 4, value: 68 }, ucp_type_table { name_offset: 1844, type_: 4, value: 68 }, ucp_type_table { name_offset: 1851, type_: 4, value: 75 }, ucp_type_table { name_offset: 1861, type_: 3, value: 170 }, ucp_type_table { name_offset: 1870, type_: 3, value: 165 }, ucp_type_table { name_offset: 1875, type_: 4, value: 15 }, ucp_type_table { name_offset: 1880, type_: 3, value: 170 }, ucp_type_table { name_offset: 1885, type_: 4, value: 58 }, ucp_type_table { name_offset: 1890, type_: 1, value: 1 }, ucp_type_table { name_offset: 1892, type_: 0, value: 0 }, ucp_type_table { name_offset: 1895, type_: 3, value: 123 }, ucp_type_table { name_offset: 1900, type_: 3, value: 100 }, ucp_type_table { name_offset: 1904, type_: 3, value: 100 }, ucp_type_table { name_offset: 1909, type_: 4, value: 0 }, ucp_type_table { name_offset: 1915, type_: 4, value: 0 }, ucp_type_table { name_offset: 1920, type_: 0, value: 0 }, ucp_type_table { name_offset: 1923, type_: 3, value: 117 }, ucp_type_table { name_offset: 1928, type_: 3, value: 117 }, ucp_type_table { name_offset: 1935, type_: 4, value: 37 }, ucp_type_table { name_offset: 1940, type_: 4, value: 37 }, ucp_type_table { name_offset: 1946, type_: 4, value: 69 }, ucp_type_table { name_offset: 1951, type_: 4, value: 39 }, ucp_type_table { name_offset: 1956, type_: 4, value: 69 }, ucp_type_table { name_offset: 1964, type_: 4, value: 39 }, ucp_type_table { name_offset: 1972, type_: 4, value: 55 }, ucp_type_table { name_offset: 1977, type_: 2, value: 5 }, ucp_type_table { name_offset: 1980, type_: 2, value: 6 }, ucp_type_table { name_offset: 1983, type_: 2, value: 7 }, ucp_type_table { name_offset: 1986, type_: 12, value: 37 }, ucp_type_table { name_offset: 1990, type_: 12, value: 37 }, ucp_type_table { name_offset: 2012, type_: 12, value: 38 }, ucp_type_table { name_offset: 2018, type_: 12, value: 38 }, ucp_type_table { name_offset: 2028, type_: 2, value: 8 }, ucp_type_table { name_offset: 2031, type_: 2, value: 9 }, ucp_type_table { name_offset: 2034, type_: 4, value: 50 }, ucp_type_table { name_offset: 2039, type_: 4, value: 50 }, ucp_type_table { name_offset: 2046, type_: 4, value: 52 }, ucp_type_table { name_offset: 2051, type_: 4, value: 52 }, ucp_type_table { name_offset: 2058, type_: 1, value: 2 }, ucp_type_table { name_offset: 2060, type_: 4, value: 70 }, ucp_type_table { name_offset: 2069, type_: 4, value: 70 }, ucp_type_table { name_offset: 2074, type_: 3, value: 157 }, ucp_type_table { name_offset: 2079, type_: 3, value: 157 }, ucp_type_table { name_offset: 2087, type_: 4, value: 16 }, ucp_type_table { name_offset: 2097, type_: 4, value: 59 }, ucp_type_table { name_offset: 2102, type_: 4, value: 59 }, ucp_type_table { name_offset: 2110, type_: 4, value: 71 }, ucp_type_table { name_offset: 2115, type_: 4, value: 71 }, ucp_type_table { name_offset: 2126, type_: 3, value: 152 }, ucp_type_table { name_offset: 2131, type_: 3, value: 152 }, ucp_type_table { name_offset: 2139, type_: 4, value: 82 }, ucp_type_table { name_offset: 2152, type_: 12, value: 39 }, ucp_type_table { name_offset: 2157, type_: 2, value: 10 }, ucp_type_table { name_offset: 2160, type_: 12, value: 40 }, ucp_type_table { name_offset: 2164, type_: 2, value: 11 }, ucp_type_table { name_offset: 2167, type_: 3, value: 158 }, ucp_type_table { name_offset: 2179, type_: 3, value: 158 }, ucp_type_table { name_offset: 2184, type_: 3, value: 127 }, ucp_type_table { name_offset: 2196, type_: 3, value: 139 }, ucp_type_table { name_offset: 2201, type_: 3, value: 139 }, ucp_type_table { name_offset: 2214, type_: 3, value: 134 }, ucp_type_table { name_offset: 2219, type_: 4, value: 61 }, ucp_type_table { name_offset: 2224, type_: 3, value: 134 }, ucp_type_table { name_offset: 2240, type_: 4, value: 61 }, ucp_type_table { name_offset: 2260, type_: 3, value: 135 }, ucp_type_table { name_offset: 2265, type_: 4, value: 16 }, ucp_type_table { name_offset: 2270, type_: 2, value: 12 }, ucp_type_table { name_offset: 2273, type_: 4, value: 72 }, ucp_type_table { name_offset: 2278, type_: 12, value: 40 }, ucp_type_table { name_offset: 2300, type_: 4, value: 26 }, ucp_type_table { name_offset: 2305, type_: 4, value: 26 }, ucp_type_table { name_offset: 2315, type_: 3, value: 140 }, ucp_type_table { name_offset: 2319, type_: 3, value: 140 }, ucp_type_table { name_offset: 2324, type_: 3, value: 127 }, ucp_type_table { name_offset: 2329, type_: 4, value: 77 }, ucp_type_table { name_offset: 2334, type_: 4, value: 77 }, ucp_type_table { name_offset: 2342, type_: 4, value: 20 }, ucp_type_table { name_offset: 2350, type_: 4, value: 20 }, ucp_type_table { name_offset: 2355, type_: 1, value: 3 }, ucp_type_table { name_offset: 2357, type_: 3, value: 142 }, ucp_type_table { name_offset: 2367, type_: 3, value: 169 }, ucp_type_table { name_offset: 2372, type_: 3, value: 169 }, ucp_type_table { name_offset: 2383, type_: 4, value: 87 }, ucp_type_table { name_offset: 2388, type_: 4, value: 87 }, ucp_type_table { name_offset: 2400, type_: 3, value: 141 }, ucp_type_table { name_offset: 2405, type_: 3, value: 142 }, ucp_type_table { name_offset: 2410, type_: 12, value: 41 }, ucp_type_table { name_offset: 2416, type_: 2, value: 13 }, ucp_type_table { name_offset: 2419, type_: 3, value: 153 }, ucp_type_table { name_offset: 2424, type_: 3, value: 110 }, ucp_type_table { name_offset: 2434, type_: 4, value: 48 }, ucp_type_table { name_offset: 2438, type_: 4, value: 48 }, ucp_type_table { name_offset: 2443, type_: 2, value: 14 }, ucp_type_table { name_offset: 2446, type_: 2, value: 15 }, ucp_type_table { name_offset: 2449, type_: 12, value: 41 }, ucp_type_table { name_offset: 2471, type_: 3, value: 154 }, ucp_type_table { name_offset: 2476, type_: 3, value: 154 }, ucp_type_table { name_offset: 2482, type_: 3, value: 161 }, ucp_type_table { name_offset: 2503, type_: 3, value: 102 }, ucp_type_table { name_offset: 2508, type_: 3, value: 102 }, ucp_type_table { name_offset: 2514, type_: 3, value: 118 }, ucp_type_table { name_offset: 2522, type_: 3, value: 118 }, ucp_type_table { name_offset: 2527, type_: 4, value: 78 }, ucp_type_table { name_offset: 2540, type_: 3, value: 104 }, ucp_type_table { name_offset: 2550, type_: 3, value: 141 }, ucp_type_table { name_offset: 2566, type_: 4, value: 73 }, ucp_type_table { name_offset: 2576, type_: 3, value: 111 }, ucp_type_table { name_offset: 2587, type_: 3, value: 159 }, ucp_type_table { name_offset: 2598, type_: 3, value: 129 }, ucp_type_table { name_offset: 2614, type_: 4, value: 57 }, ucp_type_table { name_offset: 2624, type_: 4, value: 90 }, ucp_type_table { name_offset: 2634, type_: 4, value: 94 }, ucp_type_table { name_offset: 2641, type_: 4, value: 94 }, ucp_type_table { name_offset: 2646, type_: 4, value: 12 }, ucp_type_table { name_offset: 2652, type_: 4, value: 57 }, ucp_type_table { name_offset: 2657, type_: 4, value: 12 }, ucp_type_table { name_offset: 2662, type_: 4, value: 80 }, ucp_type_table { name_offset: 2668, type_: 4, value: 80 }, ucp_type_table { name_offset: 2673, type_: 3, value: 108 }, ucp_type_table { name_offset: 2678, type_: 3, value: 108 }, ucp_type_table { name_offset: 2686, type_: 4, value: 90 }, ucp_type_table { name_offset: 2691, type_: 1, value: 4 }, ucp_type_table { name_offset: 2693, type_: 3, value: 138 }, ucp_type_table { name_offset: 2705, type_: 3, value: 143 }, ucp_type_table { name_offset: 2710, type_: 3, value: 143 }, ucp_type_table { name_offset: 2720, type_: 12, value: 42 }, ucp_type_table { name_offset: 2727, type_: 12, value: 42 }, ucp_type_table { name_offset: 2741, type_: 12, value: 43 }, ucp_type_table { name_offset: 2759, type_: 12, value: 43 }, ucp_type_table { name_offset: 2765, type_: 3, value: 144 }, ucp_type_table { name_offset: 2770, type_: 3, value: 144 }, ucp_type_table { name_offset: 2780, type_: 2, value: 16 }, ucp_type_table { name_offset: 2783, type_: 12, value: 44 }, ucp_type_table { name_offset: 2787, type_: 2, value: 17 }, ucp_type_table { name_offset: 2790, type_: 2, value: 18 }, ucp_type_table { name_offset: 2793, type_: 4, value: 73 }, ucp_type_table { name_offset: 2798, type_: 2, value: 19 }, ucp_type_table { name_offset: 2801, type_: 4, value: 47 }, ucp_type_table { name_offset: 2806, type_: 4, value: 47 }, ucp_type_table { name_offset: 2814, type_: 3, value: 131 }, ucp_type_table { name_offset: 2819, type_: 4, value: 74 }, ucp_type_table { name_offset: 2824, type_: 3, value: 115 }, ucp_type_table { name_offset: 2829, type_: 3, value: 115 }, ucp_type_table { name_offset: 2840, type_: 2, value: 20 }, ucp_type_table { name_offset: 2843, type_: 3, value: 135 }, ucp_type_table { name_offset: 2848, type_: 2, value: 21 }, ucp_type_table { name_offset: 2851, type_: 12, value: 44 }, ucp_type_table { name_offset: 2878, type_: 3, value: 130 }, ucp_type_table { name_offset: 2883, type_: 2, value: 22 }, ucp_type_table { name_offset: 2886, type_: 4, value: 74 }, ucp_type_table { name_offset: 2901, type_: 4, value: 43 }, ucp_type_table { name_offset: 2906, type_: 3, value: 106 }, ucp_type_table { name_offset: 2911, type_: 12, value: 45 }, ucp_type_table { name_offset: 2917, type_: 12, value: 45 }, ucp_type_table { name_offset: 2931, type_: 12, value: 46 }, ucp_type_table { name_offset: 2939, type_: 12, value: 47 }, ucp_type_table { name_offset: 2957, type_: 3, value: 121 }, ucp_type_table { name_offset: 2964, type_: 12, value: 47 }, ucp_type_table { name_offset: 2967, type_: 3, value: 121 }, ucp_type_table { name_offset: 2972, type_: 4, value: 85 }, ucp_type_table { name_offset: 2977, type_: 4, value: 25 }, ucp_type_table { name_offset: 2983, type_: 4, value: 25 }, ucp_type_table { name_offset: 2988, type_: 1, value: 5 }, ucp_type_table { name_offset: 2990, type_: 4, value: 54 }, ucp_type_table { name_offset: 3000, type_: 4, value: 54 }, ucp_type_table { name_offset: 3005, type_: 3, value: 129 }, ucp_type_table { name_offset: 3010, type_: 3, value: 120 }, ucp_type_table { name_offset: 3015, type_: 3, value: 120 }, ucp_type_table { name_offset: 3026, type_: 2, value: 23 }, ucp_type_table { name_offset: 3029, type_: 12, value: 49 }, ucp_type_table { name_offset: 3032, type_: 12, value: 48 }, ucp_type_table { name_offset: 3049, type_: 3, value: 150 }, ucp_type_table { name_offset: 3054, type_: 4, value: 62 }, ucp_type_table { name_offset: 3062, type_: 4, value: 40 }, ucp_type_table { name_offset: 3070, type_: 4, value: 40 }, ucp_type_table { name_offset: 3075, type_: 4, value: 62 }, ucp_type_table { name_offset: 3080, type_: 3, value: 145 }, ucp_type_table { name_offset: 3085, type_: 3, value: 145 }, ucp_type_table { name_offset: 3093, type_: 3, value: 150 }, ucp_type_table { name_offset: 3105, type_: 4, value: 75 }, ucp_type_table { name_offset: 3110, type_: 4, value: 17 }, ucp_type_table { name_offset: 3115, type_: 4, value: 17 }, ucp_type_table { name_offset: 3123, type_: 2, value: 24 }, ucp_type_table { name_offset: 3126, type_: 2, value: 25 }, ucp_type_table { name_offset: 3129, type_: 2, value: 26 }, ucp_type_table { name_offset: 3132, type_: 12, value: 49 }, ucp_type_table { name_offset: 3143, type_: 4, value: 86 }, ucp_type_table { name_offset: 3148, type_: 4, value: 86 }, ucp_type_table { name_offset: 3156, type_: 3, value: 159 }, ucp_type_table { name_offset: 3161, type_: 3, value: 136 }, ucp_type_table { name_offset: 3166, type_: 3, value: 136 }, ucp_type_table { name_offset: 3178, type_: 3, value: 155 }, ucp_type_table { name_offset: 3183, type_: 3, value: 155 }, ucp_type_table { name_offset: 3191, type_: 12, value: 54 }, ucp_type_table { name_offset: 3197, type_: 12, value: 48 }, ucp_type_table { name_offset: 3203, type_: 3, value: 116 }, ucp_type_table { name_offset: 3208, type_: 3, value: 116 }, ucp_type_table { name_offset: 3218, type_: 4, value: 95 }, ucp_type_table { name_offset: 3223, type_: 4, value: 95 }, ucp_type_table { name_offset: 3231, type_: 4, value: 46 }, ucp_type_table { name_offset: 3236, type_: 4, value: 46 }, ucp_type_table { name_offset: 3248, type_: 4, value: 6 }, ucp_type_table { name_offset: 3253, type_: 4, value: 6 }, ucp_type_table { name_offset: 3260, type_: 4, value: 33 }, ucp_type_table { name_offset: 3268, type_: 4, value: 36 }, ucp_type_table { name_offset: 3273, type_: 4, value: 36 }, ucp_type_table { name_offset: 3282, type_: 4, value: 38 }, ucp_type_table { name_offset: 3288, type_: 3, value: 123 }, ucp_type_table { name_offset: 3296, type_: 3, value: 124 }, ucp_type_table { name_offset: 3304, type_: 4, value: 63 }, ucp_type_table { name_offset: 3309, type_: 4, value: 63 }, ucp_type_table { name_offset: 3315, type_: 4, value: 38 }, ucp_type_table { name_offset: 3320, type_: 3, value: 110 }, ucp_type_table { name_offset: 3325, type_: 4, value: 13 }, ucp_type_table { name_offset: 3331, type_: 4, value: 13 }, ucp_type_table { name_offset: 3336, type_: 4, value: 81 }, ucp_type_table { name_offset: 3341, type_: 3, value: 166 }, ucp_type_table { name_offset: 3348, type_: 4, value: 81 }, ucp_type_table { name_offset: 3355, type_: 3, value: 124 }, ucp_type_table { name_offset: 3360, type_: 4, value: 14 }, ucp_type_table { name_offset: 3365, type_: 4, value: 14 }, ucp_type_table { name_offset: 3372, type_: 12, value: 50 }, ucp_type_table { name_offset: 3377, type_: 12, value: 50 }, ucp_type_table { name_offset: 3397, type_: 4, value: 45 }, ucp_type_table { name_offset: 3402, type_: 4, value: 33 }, ucp_type_table { name_offset: 3407, type_: 4, value: 7 }, ucp_type_table { name_offset: 3412, type_: 4, value: 7 }, ucp_type_table { name_offset: 3419, type_: 4, value: 18 }, ucp_type_table { name_offset: 3424, type_: 4, value: 19 }, ucp_type_table { name_offset: 3432, type_: 4, value: 19 }, ucp_type_table { name_offset: 3437, type_: 4, value: 45 }, ucp_type_table { name_offset: 3446, type_: 4, value: 76 }, ucp_type_table { name_offset: 3451, type_: 4, value: 76 }, ucp_type_table { name_offset: 3459, type_: 3, value: 166 }, ucp_type_table { name_offset: 3464, type_: 4, value: 96 }, ucp_type_table { name_offset: 3471, type_: 4, value: 96 }, ucp_type_table { name_offset: 3476, type_: 4, value: 91 }, ucp_type_table { name_offset: 3481, type_: 4, value: 97 }, ucp_type_table { name_offset: 3494, type_: 4, value: 97 }, ucp_type_table { name_offset: 3499, type_: 3, value: 107 }, ucp_type_table { name_offset: 3504, type_: 3, value: 107 }, ucp_type_table { name_offset: 3513, type_: 12, value: 51 }, ucp_type_table { name_offset: 3519, type_: 12, value: 51 }, ucp_type_table { name_offset: 3536, type_: 3, value: 98 }, ucp_type_table { name_offset: 3544, type_: 12, value: 52 }, ucp_type_table { name_offset: 3550, type_: 12, value: 52 }, ucp_type_table { name_offset: 3560, type_: 3, value: 119 }, ucp_type_table { name_offset: 3564, type_: 3, value: 119 }, ucp_type_table { name_offset: 3569, type_: 12, value: 53 }, ucp_type_table { name_offset: 3587, type_: 3, value: 167 }, ucp_type_table { name_offset: 3592, type_: 3, value: 167 }, ucp_type_table { name_offset: 3601, type_: 12, value: 53 }, ucp_type_table { name_offset: 3604, type_: 3, value: 162 }, ucp_type_table { name_offset: 3611, type_: 3, value: 146 }, ucp_type_table { name_offset: 3616, type_: 3, value: 146 }, ucp_type_table { name_offset: 3627, type_: 3, value: 162 }, ucp_type_table { name_offset: 3632, type_: 12, value: 54 }, ucp_type_table { name_offset: 3643, type_: 12, value: 54 }, ucp_type_table { name_offset: 3650, type_: 5, value: 0 }, ucp_type_table { name_offset: 3654, type_: 12, value: 55 }, ucp_type_table { name_offset: 3659, type_: 12, value: 55 }, ucp_type_table { name_offset: 3671, type_: 12, value: 56 }, ucp_type_table { name_offset: 3676, type_: 12, value: 56 }, ucp_type_table { name_offset: 3685, type_: 3, value: 111 }, ucp_type_table { name_offset: 3690, type_: 7, value: 0 }, ucp_type_table { name_offset: 3694, type_: 6, value: 0 }, ucp_type_table { name_offset: 3698, type_: 3, value: 114 }, ucp_type_table { name_offset: 3703, type_: 10, value: 0 }, ucp_type_table { name_offset: 3707, type_: 8, value: 0 }, ucp_type_table { name_offset: 3711, type_: 4, value: 88 }, ucp_type_table { name_offset: 3716, type_: 4, value: 88 }, ucp_type_table { name_offset: 3723, type_: 4, value: 31 }, ucp_type_table { name_offset: 3726, type_: 4, value: 31 }, ucp_type_table { name_offset: 3731, type_: 1, value: 6 }, ucp_type_table { name_offset: 3733, type_: 3, value: 156 }, ucp_type_table { name_offset: 3749, type_: 3, value: 156 }, ucp_type_table { name_offset: 3754, type_: 3, value: 106 }, ucp_type_table { name_offset: 3759, type_: 2, value: 27 }, ucp_type_table { name_offset: 3762, type_: 2, value: 28 }, ucp_type_table { name_offset: 3765, type_: 2, value: 29 }, ucp_type_table { name_offset: 3768, type_: 3, value: 99 }, ucp_type_table { name_offset: 3773, type_: 3, value: 98 }]

pub let _pcre2_utt_size_8: c_ulong = 510

pub fn ARR_SIZE[T](x: T) -> T {
    sizeof[T]()
}
pub let STRING_adlam0: [7]c_char = [97, 100, 108, 97, 109, 0, 0]
pub let STRING_adlm0: [6]c_char = [97, 100, 108, 109, 0, 0]
pub let STRING_aghb0: [6]c_char = [97, 103, 104, 98, 0, 0]
pub let STRING_ahex0: [6]c_char = [97, 104, 101, 120, 0, 0]
pub let STRING_ahom0: [6]c_char = [97, 104, 111, 109, 0, 0]
pub let STRING_alphabetic0: [12]c_char = [97, 108, 112, 104, 97, 98, 101, 116, 105, 99, 0, 0]
pub let STRING_anatolianhieroglyphs0: [22]c_char = [97, 110, 97, 116, 111, 108, 105, 97, 110, 104, 105, 101, 114, 111, 103, 108, 121, 112, 104, 115, 0, 0]
pub let STRING_any0: [5]c_char = [97, 110, 121, 0, 0]
pub let STRING_arab0: [6]c_char = [97, 114, 97, 98, 0, 0]
pub let STRING_arabic0: [8]c_char = [97, 114, 97, 98, 105, 99, 0, 0]
pub let STRING_armenian0: [10]c_char = [97, 114, 109, 101, 110, 105, 97, 110, 0, 0]
pub let STRING_armi0: [6]c_char = [97, 114, 109, 105, 0, 0]
pub let STRING_armn0: [6]c_char = [97, 114, 109, 110, 0, 0]
pub let STRING_asciihexdigit0: [15]c_char = [97, 115, 99, 105, 105, 104, 101, 120, 100, 105, 103, 105, 116, 0, 0]
pub let STRING_avestan0: [9]c_char = [97, 118, 101, 115, 116, 97, 110, 0, 0]
pub let STRING_avst0: [6]c_char = [97, 118, 115, 116, 0, 0]
pub let STRING_bali0: [6]c_char = [98, 97, 108, 105, 0, 0]
pub let STRING_balinese0: [10]c_char = [98, 97, 108, 105, 110, 101, 115, 101, 0, 0]
pub let STRING_bamu0: [6]c_char = [98, 97, 109, 117, 0, 0]
pub let STRING_bamum0: [7]c_char = [98, 97, 109, 117, 109, 0, 0]
pub let STRING_bass0: [6]c_char = [98, 97, 115, 115, 0, 0]
pub let STRING_bassavah0: [10]c_char = [98, 97, 115, 115, 97, 118, 97, 104, 0, 0]
pub let STRING_batak0: [7]c_char = [98, 97, 116, 97, 107, 0, 0]
pub let STRING_batk0: [6]c_char = [98, 97, 116, 107, 0, 0]
pub let STRING_beng0: [6]c_char = [98, 101, 110, 103, 0, 0]
pub let STRING_bengali0: [9]c_char = [98, 101, 110, 103, 97, 108, 105, 0, 0]
pub let STRING_bhaiksuki0: [11]c_char = [98, 104, 97, 105, 107, 115, 117, 107, 105, 0, 0]
pub let STRING_bhks0: [6]c_char = [98, 104, 107, 115, 0, 0]
pub let STRING_bidial0: [8]c_char = [98, 105, 100, 105, 97, 108, 0, 0]
pub let STRING_bidian0: [8]c_char = [98, 105, 100, 105, 97, 110, 0, 0]
pub let STRING_bidib0: [7]c_char = [98, 105, 100, 105, 98, 0, 0]
pub let STRING_bidibn0: [8]c_char = [98, 105, 100, 105, 98, 110, 0, 0]
pub let STRING_bidic0: [7]c_char = [98, 105, 100, 105, 99, 0, 0]
pub let STRING_bidicontrol0: [13]c_char = [98, 105, 100, 105, 99, 111, 110, 116, 114, 111, 108, 0, 0]
pub let STRING_bidics0: [8]c_char = [98, 105, 100, 105, 99, 115, 0, 0]
pub let STRING_bidien0: [8]c_char = [98, 105, 100, 105, 101, 110, 0, 0]
pub let STRING_bidies0: [8]c_char = [98, 105, 100, 105, 101, 115, 0, 0]
pub let STRING_bidiet0: [8]c_char = [98, 105, 100, 105, 101, 116, 0, 0]
pub let STRING_bidifsi0: [9]c_char = [98, 105, 100, 105, 102, 115, 105, 0, 0]
pub let STRING_bidil0: [7]c_char = [98, 105, 100, 105, 108, 0, 0]
pub let STRING_bidilre0: [9]c_char = [98, 105, 100, 105, 108, 114, 101, 0, 0]
pub let STRING_bidilri0: [9]c_char = [98, 105, 100, 105, 108, 114, 105, 0, 0]
pub let STRING_bidilro0: [9]c_char = [98, 105, 100, 105, 108, 114, 111, 0, 0]
pub let STRING_bidim0: [7]c_char = [98, 105, 100, 105, 109, 0, 0]
pub let STRING_bidimirrored0: [14]c_char = [98, 105, 100, 105, 109, 105, 114, 114, 111, 114, 101, 100, 0, 0]
pub let STRING_bidinsm0: [9]c_char = [98, 105, 100, 105, 110, 115, 109, 0, 0]
pub let STRING_bidion0: [8]c_char = [98, 105, 100, 105, 111, 110, 0, 0]
pub let STRING_bidipdf0: [9]c_char = [98, 105, 100, 105, 112, 100, 102, 0, 0]
pub let STRING_bidipdi0: [9]c_char = [98, 105, 100, 105, 112, 100, 105, 0, 0]
pub let STRING_bidir0: [7]c_char = [98, 105, 100, 105, 114, 0, 0]
pub let STRING_bidirle0: [9]c_char = [98, 105, 100, 105, 114, 108, 101, 0, 0]
pub let STRING_bidirli0: [9]c_char = [98, 105, 100, 105, 114, 108, 105, 0, 0]
pub let STRING_bidirlo0: [9]c_char = [98, 105, 100, 105, 114, 108, 111, 0, 0]
pub let STRING_bidis0: [7]c_char = [98, 105, 100, 105, 115, 0, 0]
pub let STRING_bidiws0: [8]c_char = [98, 105, 100, 105, 119, 115, 0, 0]
pub let STRING_bopo0: [6]c_char = [98, 111, 112, 111, 0, 0]
pub let STRING_bopomofo0: [10]c_char = [98, 111, 112, 111, 109, 111, 102, 111, 0, 0]
pub let STRING_brah0: [6]c_char = [98, 114, 97, 104, 0, 0]
pub let STRING_brahmi0: [8]c_char = [98, 114, 97, 104, 109, 105, 0, 0]
pub let STRING_brai0: [6]c_char = [98, 114, 97, 105, 0, 0]
pub let STRING_braille0: [9]c_char = [98, 114, 97, 105, 108, 108, 101, 0, 0]
pub let STRING_bugi0: [6]c_char = [98, 117, 103, 105, 0, 0]
pub let STRING_buginese0: [10]c_char = [98, 117, 103, 105, 110, 101, 115, 101, 0, 0]
pub let STRING_buhd0: [6]c_char = [98, 117, 104, 100, 0, 0]
pub let STRING_buhid0: [7]c_char = [98, 117, 104, 105, 100, 0, 0]
pub let STRING_c0: [3]c_char = [99, 0, 0]
pub let STRING_cakm0: [6]c_char = [99, 97, 107, 109, 0, 0]
pub let STRING_canadianaboriginal0: [20]c_char = [99, 97, 110, 97, 100, 105, 97, 110, 97, 98, 111, 114, 105, 103, 105, 110, 97, 108, 0, 0]
pub let STRING_cans0: [6]c_char = [99, 97, 110, 115, 0, 0]
pub let STRING_cari0: [6]c_char = [99, 97, 114, 105, 0, 0]
pub let STRING_carian0: [8]c_char = [99, 97, 114, 105, 97, 110, 0, 0]
pub let STRING_cased0: [7]c_char = [99, 97, 115, 101, 100, 0, 0]
pub let STRING_caseignorable0: [15]c_char = [99, 97, 115, 101, 105, 103, 110, 111, 114, 97, 98, 108, 101, 0, 0]
pub let STRING_caucasianalbanian0: [19]c_char = [99, 97, 117, 99, 97, 115, 105, 97, 110, 97, 108, 98, 97, 110, 105, 97, 110, 0, 0]
pub let STRING_cc0: [4]c_char = [99, 99, 0, 0]
pub let STRING_cf0: [4]c_char = [99, 102, 0, 0]
pub let STRING_chakma0: [8]c_char = [99, 104, 97, 107, 109, 97, 0, 0]
pub let STRING_cham0: [6]c_char = [99, 104, 97, 109, 0, 0]
pub let STRING_changeswhencasefolded0: [23]c_char = [99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 99, 97, 115, 101, 102, 111, 108, 100, 101, 100, 0, 0]
pub let STRING_changeswhencasemapped0: [23]c_char = [99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 99, 97, 115, 101, 109, 97, 112, 112, 101, 100, 0, 0]
pub let STRING_changeswhenlowercased0: [23]c_char = [99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 108, 111, 119, 101, 114, 99, 97, 115, 101, 100, 0, 0]
pub let STRING_changeswhentitlecased0: [23]c_char = [99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 116, 105, 116, 108, 101, 99, 97, 115, 101, 100, 0, 0]
pub let STRING_changeswhenuppercased0: [23]c_char = [99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 117, 112, 112, 101, 114, 99, 97, 115, 101, 100, 0, 0]
pub let STRING_cher0: [6]c_char = [99, 104, 101, 114, 0, 0]
pub let STRING_cherokee0: [10]c_char = [99, 104, 101, 114, 111, 107, 101, 101, 0, 0]
pub let STRING_chorasmian0: [12]c_char = [99, 104, 111, 114, 97, 115, 109, 105, 97, 110, 0, 0]
pub let STRING_chrs0: [6]c_char = [99, 104, 114, 115, 0, 0]
pub let STRING_ci0: [4]c_char = [99, 105, 0, 0]
pub let STRING_cn0: [4]c_char = [99, 110, 0, 0]
pub let STRING_co0: [4]c_char = [99, 111, 0, 0]
pub let STRING_common0: [8]c_char = [99, 111, 109, 109, 111, 110, 0, 0]
pub let STRING_copt0: [6]c_char = [99, 111, 112, 116, 0, 0]
pub let STRING_coptic0: [8]c_char = [99, 111, 112, 116, 105, 99, 0, 0]
pub let STRING_cpmn0: [6]c_char = [99, 112, 109, 110, 0, 0]
pub let STRING_cprt0: [6]c_char = [99, 112, 114, 116, 0, 0]
pub let STRING_cs0: [4]c_char = [99, 115, 0, 0]
pub let STRING_cuneiform0: [11]c_char = [99, 117, 110, 101, 105, 102, 111, 114, 109, 0, 0]
pub let STRING_cwcf0: [6]c_char = [99, 119, 99, 102, 0, 0]
pub let STRING_cwcm0: [6]c_char = [99, 119, 99, 109, 0, 0]
pub let STRING_cwl0: [5]c_char = [99, 119, 108, 0, 0]
pub let STRING_cwt0: [5]c_char = [99, 119, 116, 0, 0]
pub let STRING_cwu0: [5]c_char = [99, 119, 117, 0, 0]
pub let STRING_cypriot0: [9]c_char = [99, 121, 112, 114, 105, 111, 116, 0, 0]
pub let STRING_cyprominoan0: [13]c_char = [99, 121, 112, 114, 111, 109, 105, 110, 111, 97, 110, 0, 0]
pub let STRING_cyrillic0: [10]c_char = [99, 121, 114, 105, 108, 108, 105, 99, 0, 0]
pub let STRING_cyrl0: [6]c_char = [99, 121, 114, 108, 0, 0]
pub let STRING_dash0: [6]c_char = [100, 97, 115, 104, 0, 0]
pub let STRING_defaultignorablecodepoint0: [27]c_char = [100, 101, 102, 97, 117, 108, 116, 105, 103, 110, 111, 114, 97, 98, 108, 101, 99, 111, 100, 101, 112, 111, 105, 110, 116, 0, 0]
pub let STRING_dep0: [5]c_char = [100, 101, 112, 0, 0]
pub let STRING_deprecated0: [12]c_char = [100, 101, 112, 114, 101, 99, 97, 116, 101, 100, 0, 0]
pub let STRING_deseret0: [9]c_char = [100, 101, 115, 101, 114, 101, 116, 0, 0]
pub let STRING_deva0: [6]c_char = [100, 101, 118, 97, 0, 0]
pub let STRING_devanagari0: [12]c_char = [100, 101, 118, 97, 110, 97, 103, 97, 114, 105, 0, 0]
pub let STRING_di0: [4]c_char = [100, 105, 0, 0]
pub let STRING_dia0: [5]c_char = [100, 105, 97, 0, 0]
pub let STRING_diacritic0: [11]c_char = [100, 105, 97, 99, 114, 105, 116, 105, 99, 0, 0]
pub let STRING_diak0: [6]c_char = [100, 105, 97, 107, 0, 0]
pub let STRING_divesakuru0: [12]c_char = [100, 105, 118, 101, 115, 97, 107, 117, 114, 117, 0, 0]
pub let STRING_dogr0: [6]c_char = [100, 111, 103, 114, 0, 0]
pub let STRING_dogra0: [7]c_char = [100, 111, 103, 114, 97, 0, 0]
pub let STRING_dsrt0: [6]c_char = [100, 115, 114, 116, 0, 0]
pub let STRING_dupl0: [6]c_char = [100, 117, 112, 108, 0, 0]
pub let STRING_duployan0: [10]c_char = [100, 117, 112, 108, 111, 121, 97, 110, 0, 0]
pub let STRING_ebase0: [7]c_char = [101, 98, 97, 115, 101, 0, 0]
pub let STRING_ecomp0: [7]c_char = [101, 99, 111, 109, 112, 0, 0]
pub let STRING_egyp0: [6]c_char = [101, 103, 121, 112, 0, 0]
pub let STRING_egyptianhieroglyphs0: [21]c_char = [101, 103, 121, 112, 116, 105, 97, 110, 104, 105, 101, 114, 111, 103, 108, 121, 112, 104, 115, 0, 0]
pub let STRING_elba0: [6]c_char = [101, 108, 98, 97, 0, 0]
pub let STRING_elbasan0: [9]c_char = [101, 108, 98, 97, 115, 97, 110, 0, 0]
pub let STRING_elym0: [6]c_char = [101, 108, 121, 109, 0, 0]
pub let STRING_elymaic0: [9]c_char = [101, 108, 121, 109, 97, 105, 99, 0, 0]
pub let STRING_emod0: [6]c_char = [101, 109, 111, 100, 0, 0]
pub let STRING_emoji0: [7]c_char = [101, 109, 111, 106, 105, 0, 0]
pub let STRING_emojicomponent0: [16]c_char = [101, 109, 111, 106, 105, 99, 111, 109, 112, 111, 110, 101, 110, 116, 0, 0]
pub let STRING_emojimodifier0: [15]c_char = [101, 109, 111, 106, 105, 109, 111, 100, 105, 102, 105, 101, 114, 0, 0]
pub let STRING_emojimodifierbase0: [19]c_char = [101, 109, 111, 106, 105, 109, 111, 100, 105, 102, 105, 101, 114, 98, 97, 115, 101, 0, 0]
pub let STRING_emojipresentation0: [19]c_char = [101, 109, 111, 106, 105, 112, 114, 101, 115, 101, 110, 116, 97, 116, 105, 111, 110, 0, 0]
pub let STRING_epres0: [7]c_char = [101, 112, 114, 101, 115, 0, 0]
pub let STRING_ethi0: [6]c_char = [101, 116, 104, 105, 0, 0]
pub let STRING_ethiopic0: [10]c_char = [101, 116, 104, 105, 111, 112, 105, 99, 0, 0]
pub let STRING_ext0: [5]c_char = [101, 120, 116, 0, 0]
pub let STRING_extendedpictographic0: [22]c_char = [101, 120, 116, 101, 110, 100, 101, 100, 112, 105, 99, 116, 111, 103, 114, 97, 112, 104, 105, 99, 0, 0]
pub let STRING_extender0: [10]c_char = [101, 120, 116, 101, 110, 100, 101, 114, 0, 0]
pub let STRING_extpict0: [9]c_char = [101, 120, 116, 112, 105, 99, 116, 0, 0]
pub let STRING_gara0: [6]c_char = [103, 97, 114, 97, 0, 0]
pub let STRING_garay0: [7]c_char = [103, 97, 114, 97, 121, 0, 0]
pub let STRING_geor0: [6]c_char = [103, 101, 111, 114, 0, 0]
pub let STRING_georgian0: [10]c_char = [103, 101, 111, 114, 103, 105, 97, 110, 0, 0]
pub let STRING_glag0: [6]c_char = [103, 108, 97, 103, 0, 0]
pub let STRING_glagolitic0: [12]c_char = [103, 108, 97, 103, 111, 108, 105, 116, 105, 99, 0, 0]
pub let STRING_gong0: [6]c_char = [103, 111, 110, 103, 0, 0]
pub let STRING_gonm0: [6]c_char = [103, 111, 110, 109, 0, 0]
pub let STRING_goth0: [6]c_char = [103, 111, 116, 104, 0, 0]
pub let STRING_gothic0: [8]c_char = [103, 111, 116, 104, 105, 99, 0, 0]
pub let STRING_gran0: [6]c_char = [103, 114, 97, 110, 0, 0]
pub let STRING_grantha0: [9]c_char = [103, 114, 97, 110, 116, 104, 97, 0, 0]
pub let STRING_graphemebase0: [14]c_char = [103, 114, 97, 112, 104, 101, 109, 101, 98, 97, 115, 101, 0, 0]
pub let STRING_graphemeextend0: [16]c_char = [103, 114, 97, 112, 104, 101, 109, 101, 101, 120, 116, 101, 110, 100, 0, 0]
pub let STRING_graphemelink0: [14]c_char = [103, 114, 97, 112, 104, 101, 109, 101, 108, 105, 110, 107, 0, 0]
pub let STRING_grbase0: [8]c_char = [103, 114, 98, 97, 115, 101, 0, 0]
pub let STRING_greek0: [7]c_char = [103, 114, 101, 101, 107, 0, 0]
pub let STRING_grek0: [6]c_char = [103, 114, 101, 107, 0, 0]
pub let STRING_grext0: [7]c_char = [103, 114, 101, 120, 116, 0, 0]
pub let STRING_grlink0: [8]c_char = [103, 114, 108, 105, 110, 107, 0, 0]
pub let STRING_gujarati0: [10]c_char = [103, 117, 106, 97, 114, 97, 116, 105, 0, 0]
pub let STRING_gujr0: [6]c_char = [103, 117, 106, 114, 0, 0]
pub let STRING_gukh0: [6]c_char = [103, 117, 107, 104, 0, 0]
pub let STRING_gunjalagondi0: [14]c_char = [103, 117, 110, 106, 97, 108, 97, 103, 111, 110, 100, 105, 0, 0]
pub let STRING_gurmukhi0: [10]c_char = [103, 117, 114, 109, 117, 107, 104, 105, 0, 0]
pub let STRING_guru0: [6]c_char = [103, 117, 114, 117, 0, 0]
pub let STRING_gurungkhema0: [13]c_char = [103, 117, 114, 117, 110, 103, 107, 104, 101, 109, 97, 0, 0]
pub let STRING_han0: [5]c_char = [104, 97, 110, 0, 0]
pub let STRING_hang0: [6]c_char = [104, 97, 110, 103, 0, 0]
pub let STRING_hangul0: [8]c_char = [104, 97, 110, 103, 117, 108, 0, 0]
pub let STRING_hani0: [6]c_char = [104, 97, 110, 105, 0, 0]
pub let STRING_hanifirohingya0: [16]c_char = [104, 97, 110, 105, 102, 105, 114, 111, 104, 105, 110, 103, 121, 97, 0, 0]
pub let STRING_hano0: [6]c_char = [104, 97, 110, 111, 0, 0]
pub let STRING_hanunoo0: [9]c_char = [104, 97, 110, 117, 110, 111, 111, 0, 0]
pub let STRING_hatr0: [6]c_char = [104, 97, 116, 114, 0, 0]
pub let STRING_hatran0: [8]c_char = [104, 97, 116, 114, 97, 110, 0, 0]
pub let STRING_hebr0: [6]c_char = [104, 101, 98, 114, 0, 0]
pub let STRING_hebrew0: [8]c_char = [104, 101, 98, 114, 101, 119, 0, 0]
pub let STRING_hex0: [5]c_char = [104, 101, 120, 0, 0]
pub let STRING_hexdigit0: [10]c_char = [104, 101, 120, 100, 105, 103, 105, 116, 0, 0]
pub let STRING_hira0: [6]c_char = [104, 105, 114, 97, 0, 0]
pub let STRING_hiragana0: [10]c_char = [104, 105, 114, 97, 103, 97, 110, 97, 0, 0]
pub let STRING_hluw0: [6]c_char = [104, 108, 117, 119, 0, 0]
pub let STRING_hmng0: [6]c_char = [104, 109, 110, 103, 0, 0]
pub let STRING_hmnp0: [6]c_char = [104, 109, 110, 112, 0, 0]
pub let STRING_hung0: [6]c_char = [104, 117, 110, 103, 0, 0]
pub let STRING_idc0: [5]c_char = [105, 100, 99, 0, 0]
pub let STRING_idcompatmathcontinue0: [22]c_char = [105, 100, 99, 111, 109, 112, 97, 116, 109, 97, 116, 104, 99, 111, 110, 116, 105, 110, 117, 101, 0, 0]
pub let STRING_idcompatmathstart0: [19]c_char = [105, 100, 99, 111, 109, 112, 97, 116, 109, 97, 116, 104, 115, 116, 97, 114, 116, 0, 0]
pub let STRING_idcontinue0: [12]c_char = [105, 100, 99, 111, 110, 116, 105, 110, 117, 101, 0, 0]
pub let STRING_ideo0: [6]c_char = [105, 100, 101, 111, 0, 0]
pub let STRING_ideographic0: [13]c_char = [105, 100, 101, 111, 103, 114, 97, 112, 104, 105, 99, 0, 0]
pub let STRING_ids0: [5]c_char = [105, 100, 115, 0, 0]
pub let STRING_idsb0: [6]c_char = [105, 100, 115, 98, 0, 0]
pub let STRING_idsbinaryoperator0: [19]c_char = [105, 100, 115, 98, 105, 110, 97, 114, 121, 111, 112, 101, 114, 97, 116, 111, 114, 0, 0]
pub let STRING_idst0: [6]c_char = [105, 100, 115, 116, 0, 0]
pub let STRING_idstart0: [9]c_char = [105, 100, 115, 116, 97, 114, 116, 0, 0]
pub let STRING_idstrinaryoperator0: [20]c_char = [105, 100, 115, 116, 114, 105, 110, 97, 114, 121, 111, 112, 101, 114, 97, 116, 111, 114, 0, 0]
pub let STRING_idsu0: [6]c_char = [105, 100, 115, 117, 0, 0]
pub let STRING_idsunaryoperator0: [18]c_char = [105, 100, 115, 117, 110, 97, 114, 121, 111, 112, 101, 114, 97, 116, 111, 114, 0, 0]
pub let STRING_imperialaramaic0: [17]c_char = [105, 109, 112, 101, 114, 105, 97, 108, 97, 114, 97, 109, 97, 105, 99, 0, 0]
pub let STRING_incb0: [6]c_char = [105, 110, 99, 98, 0, 0]
pub let STRING_inherited0: [11]c_char = [105, 110, 104, 101, 114, 105, 116, 101, 100, 0, 0]
pub let STRING_inscriptionalpahlavi0: [22]c_char = [105, 110, 115, 99, 114, 105, 112, 116, 105, 111, 110, 97, 108, 112, 97, 104, 108, 97, 118, 105, 0, 0]
pub let STRING_inscriptionalparthian0: [23]c_char = [105, 110, 115, 99, 114, 105, 112, 116, 105, 111, 110, 97, 108, 112, 97, 114, 116, 104, 105, 97, 110, 0, 0]
pub let STRING_ital0: [6]c_char = [105, 116, 97, 108, 0, 0]
pub let STRING_java0: [6]c_char = [106, 97, 118, 97, 0, 0]
pub let STRING_javanese0: [10]c_char = [106, 97, 118, 97, 110, 101, 115, 101, 0, 0]
pub let STRING_joinc0: [7]c_char = [106, 111, 105, 110, 99, 0, 0]
pub let STRING_joincontrol0: [13]c_char = [106, 111, 105, 110, 99, 111, 110, 116, 114, 111, 108, 0, 0]
pub let STRING_kaithi0: [8]c_char = [107, 97, 105, 116, 104, 105, 0, 0]
pub let STRING_kali0: [6]c_char = [107, 97, 108, 105, 0, 0]
pub let STRING_kana0: [6]c_char = [107, 97, 110, 97, 0, 0]
pub let STRING_kannada0: [9]c_char = [107, 97, 110, 110, 97, 100, 97, 0, 0]
pub let STRING_katakana0: [10]c_char = [107, 97, 116, 97, 107, 97, 110, 97, 0, 0]
pub let STRING_kawi0: [6]c_char = [107, 97, 119, 105, 0, 0]
pub let STRING_kayahli0: [9]c_char = [107, 97, 121, 97, 104, 108, 105, 0, 0]
pub let STRING_khar0: [6]c_char = [107, 104, 97, 114, 0, 0]
pub let STRING_kharoshthi0: [12]c_char = [107, 104, 97, 114, 111, 115, 104, 116, 104, 105, 0, 0]
pub let STRING_khitansmallscript0: [19]c_char = [107, 104, 105, 116, 97, 110, 115, 109, 97, 108, 108, 115, 99, 114, 105, 112, 116, 0, 0]
pub let STRING_khmer0: [7]c_char = [107, 104, 109, 101, 114, 0, 0]
pub let STRING_khmr0: [6]c_char = [107, 104, 109, 114, 0, 0]
pub let STRING_khoj0: [6]c_char = [107, 104, 111, 106, 0, 0]
pub let STRING_khojki0: [8]c_char = [107, 104, 111, 106, 107, 105, 0, 0]
pub let STRING_khudawadi0: [11]c_char = [107, 104, 117, 100, 97, 119, 97, 100, 105, 0, 0]
pub let STRING_kiratrai0: [10]c_char = [107, 105, 114, 97, 116, 114, 97, 105, 0, 0]
pub let STRING_kits0: [6]c_char = [107, 105, 116, 115, 0, 0]
pub let STRING_knda0: [6]c_char = [107, 110, 100, 97, 0, 0]
pub let STRING_krai0: [6]c_char = [107, 114, 97, 105, 0, 0]
pub let STRING_kthi0: [6]c_char = [107, 116, 104, 105, 0, 0]
pub let STRING_l0: [3]c_char = [108, 0, 0]
pub let STRING_l_AMPERSAND0: [4]c_char = [108, 38, 0, 0]
pub let STRING_lana0: [6]c_char = [108, 97, 110, 97, 0, 0]
pub let STRING_lao0: [5]c_char = [108, 97, 111, 0, 0]
pub let STRING_laoo0: [6]c_char = [108, 97, 111, 111, 0, 0]
pub let STRING_latin0: [7]c_char = [108, 97, 116, 105, 110, 0, 0]
pub let STRING_latn0: [6]c_char = [108, 97, 116, 110, 0, 0]
pub let STRING_lc0: [4]c_char = [108, 99, 0, 0]
pub let STRING_lepc0: [6]c_char = [108, 101, 112, 99, 0, 0]
pub let STRING_lepcha0: [8]c_char = [108, 101, 112, 99, 104, 97, 0, 0]
pub let STRING_limb0: [6]c_char = [108, 105, 109, 98, 0, 0]
pub let STRING_limbu0: [7]c_char = [108, 105, 109, 98, 117, 0, 0]
pub let STRING_lina0: [6]c_char = [108, 105, 110, 97, 0, 0]
pub let STRING_linb0: [6]c_char = [108, 105, 110, 98, 0, 0]
pub let STRING_lineara0: [9]c_char = [108, 105, 110, 101, 97, 114, 97, 0, 0]
pub let STRING_linearb0: [9]c_char = [108, 105, 110, 101, 97, 114, 98, 0, 0]
pub let STRING_lisu0: [6]c_char = [108, 105, 115, 117, 0, 0]
pub let STRING_ll0: [4]c_char = [108, 108, 0, 0]
pub let STRING_lm0: [4]c_char = [108, 109, 0, 0]
pub let STRING_lo0: [4]c_char = [108, 111, 0, 0]
pub let STRING_loe0: [5]c_char = [108, 111, 101, 0, 0]
pub let STRING_logicalorderexception0: [23]c_char = [108, 111, 103, 105, 99, 97, 108, 111, 114, 100, 101, 114, 101, 120, 99, 101, 112, 116, 105, 111, 110, 0, 0]
pub let STRING_lowercase0: [11]c_char = [108, 111, 119, 101, 114, 99, 97, 115, 101, 0, 0]
pub let STRING_lt0: [4]c_char = [108, 116, 0, 0]
pub let STRING_lu0: [4]c_char = [108, 117, 0, 0]
pub let STRING_lyci0: [6]c_char = [108, 121, 99, 105, 0, 0]
pub let STRING_lycian0: [8]c_char = [108, 121, 99, 105, 97, 110, 0, 0]
pub let STRING_lydi0: [6]c_char = [108, 121, 100, 105, 0, 0]
pub let STRING_lydian0: [8]c_char = [108, 121, 100, 105, 97, 110, 0, 0]
pub let STRING_m0: [3]c_char = [109, 0, 0]
pub let STRING_mahajani0: [10]c_char = [109, 97, 104, 97, 106, 97, 110, 105, 0, 0]
pub let STRING_mahj0: [6]c_char = [109, 97, 104, 106, 0, 0]
pub let STRING_maka0: [6]c_char = [109, 97, 107, 97, 0, 0]
pub let STRING_makasar0: [9]c_char = [109, 97, 107, 97, 115, 97, 114, 0, 0]
pub let STRING_malayalam0: [11]c_char = [109, 97, 108, 97, 121, 97, 108, 97, 109, 0, 0]
pub let STRING_mand0: [6]c_char = [109, 97, 110, 100, 0, 0]
pub let STRING_mandaic0: [9]c_char = [109, 97, 110, 100, 97, 105, 99, 0, 0]
pub let STRING_mani0: [6]c_char = [109, 97, 110, 105, 0, 0]
pub let STRING_manichaean0: [12]c_char = [109, 97, 110, 105, 99, 104, 97, 101, 97, 110, 0, 0]
pub let STRING_marc0: [6]c_char = [109, 97, 114, 99, 0, 0]
pub let STRING_marchen0: [9]c_char = [109, 97, 114, 99, 104, 101, 110, 0, 0]
pub let STRING_masaramgondi0: [14]c_char = [109, 97, 115, 97, 114, 97, 109, 103, 111, 110, 100, 105, 0, 0]
pub let STRING_math0: [6]c_char = [109, 97, 116, 104, 0, 0]
pub let STRING_mc0: [4]c_char = [109, 99, 0, 0]
pub let STRING_mcm0: [5]c_char = [109, 99, 109, 0, 0]
pub let STRING_me0: [4]c_char = [109, 101, 0, 0]
pub let STRING_medefaidrin0: [13]c_char = [109, 101, 100, 101, 102, 97, 105, 100, 114, 105, 110, 0, 0]
pub let STRING_medf0: [6]c_char = [109, 101, 100, 102, 0, 0]
pub let STRING_meeteimayek0: [13]c_char = [109, 101, 101, 116, 101, 105, 109, 97, 121, 101, 107, 0, 0]
pub let STRING_mend0: [6]c_char = [109, 101, 110, 100, 0, 0]
pub let STRING_mendekikakui0: [14]c_char = [109, 101, 110, 100, 101, 107, 105, 107, 97, 107, 117, 105, 0, 0]
pub let STRING_merc0: [6]c_char = [109, 101, 114, 99, 0, 0]
pub let STRING_mero0: [6]c_char = [109, 101, 114, 111, 0, 0]
pub let STRING_meroiticcursive0: [17]c_char = [109, 101, 114, 111, 105, 116, 105, 99, 99, 117, 114, 115, 105, 118, 101, 0, 0]
pub let STRING_meroitichieroglyphs0: [21]c_char = [109, 101, 114, 111, 105, 116, 105, 99, 104, 105, 101, 114, 111, 103, 108, 121, 112, 104, 115, 0, 0]
pub let STRING_miao0: [6]c_char = [109, 105, 97, 111, 0, 0]
pub let STRING_mlym0: [6]c_char = [109, 108, 121, 109, 0, 0]
pub let STRING_mn0: [4]c_char = [109, 110, 0, 0]
pub let STRING_modi0: [6]c_char = [109, 111, 100, 105, 0, 0]
pub let STRING_modifiercombiningmark0: [23]c_char = [109, 111, 100, 105, 102, 105, 101, 114, 99, 111, 109, 98, 105, 110, 105, 110, 103, 109, 97, 114, 107, 0, 0]
pub let STRING_mong0: [6]c_char = [109, 111, 110, 103, 0, 0]
pub let STRING_mongolian0: [11]c_char = [109, 111, 110, 103, 111, 108, 105, 97, 110, 0, 0]
pub let STRING_mro0: [5]c_char = [109, 114, 111, 0, 0]
pub let STRING_mroo0: [6]c_char = [109, 114, 111, 111, 0, 0]
pub let STRING_mtei0: [6]c_char = [109, 116, 101, 105, 0, 0]
pub let STRING_mult0: [6]c_char = [109, 117, 108, 116, 0, 0]
pub let STRING_multani0: [9]c_char = [109, 117, 108, 116, 97, 110, 105, 0, 0]
pub let STRING_myanmar0: [9]c_char = [109, 121, 97, 110, 109, 97, 114, 0, 0]
pub let STRING_mymr0: [6]c_char = [109, 121, 109, 114, 0, 0]
pub let STRING_n0: [3]c_char = [110, 0, 0]
pub let STRING_nabataean0: [11]c_char = [110, 97, 98, 97, 116, 97, 101, 97, 110, 0, 0]
pub let STRING_nagm0: [6]c_char = [110, 97, 103, 109, 0, 0]
pub let STRING_nagmundari0: [12]c_char = [110, 97, 103, 109, 117, 110, 100, 97, 114, 105, 0, 0]
pub let STRING_nand0: [6]c_char = [110, 97, 110, 100, 0, 0]
pub let STRING_nandinagari0: [13]c_char = [110, 97, 110, 100, 105, 110, 97, 103, 97, 114, 105, 0, 0]
pub let STRING_narb0: [6]c_char = [110, 97, 114, 98, 0, 0]
pub let STRING_nbat0: [6]c_char = [110, 98, 97, 116, 0, 0]
pub let STRING_nchar0: [7]c_char = [110, 99, 104, 97, 114, 0, 0]
pub let STRING_nd0: [4]c_char = [110, 100, 0, 0]
pub let STRING_newa0: [6]c_char = [110, 101, 119, 97, 0, 0]
pub let STRING_newtailue0: [11]c_char = [110, 101, 119, 116, 97, 105, 108, 117, 101, 0, 0]
pub let STRING_nko0: [5]c_char = [110, 107, 111, 0, 0]
pub let STRING_nkoo0: [6]c_char = [110, 107, 111, 111, 0, 0]
pub let STRING_nl0: [4]c_char = [110, 108, 0, 0]
pub let STRING_no0: [4]c_char = [110, 111, 0, 0]
pub let STRING_noncharactercodepoint0: [23]c_char = [110, 111, 110, 99, 104, 97, 114, 97, 99, 116, 101, 114, 99, 111, 100, 101, 112, 111, 105, 110, 116, 0, 0]
pub let STRING_nshu0: [6]c_char = [110, 115, 104, 117, 0, 0]
pub let STRING_nushu0: [7]c_char = [110, 117, 115, 104, 117, 0, 0]
pub let STRING_nyiakengpuachuehmong0: [22]c_char = [110, 121, 105, 97, 107, 101, 110, 103, 112, 117, 97, 99, 104, 117, 101, 104, 109, 111, 110, 103, 0, 0]
pub let STRING_ogam0: [6]c_char = [111, 103, 97, 109, 0, 0]
pub let STRING_ogham0: [7]c_char = [111, 103, 104, 97, 109, 0, 0]
pub let STRING_olchiki0: [9]c_char = [111, 108, 99, 104, 105, 107, 105, 0, 0]
pub let STRING_olck0: [6]c_char = [111, 108, 99, 107, 0, 0]
pub let STRING_oldhungarian0: [14]c_char = [111, 108, 100, 104, 117, 110, 103, 97, 114, 105, 97, 110, 0, 0]
pub let STRING_olditalic0: [11]c_char = [111, 108, 100, 105, 116, 97, 108, 105, 99, 0, 0]
pub let STRING_oldnortharabian0: [17]c_char = [111, 108, 100, 110, 111, 114, 116, 104, 97, 114, 97, 98, 105, 97, 110, 0, 0]
pub let STRING_oldpermic0: [11]c_char = [111, 108, 100, 112, 101, 114, 109, 105, 99, 0, 0]
pub let STRING_oldpersian0: [12]c_char = [111, 108, 100, 112, 101, 114, 115, 105, 97, 110, 0, 0]
pub let STRING_oldsogdian0: [12]c_char = [111, 108, 100, 115, 111, 103, 100, 105, 97, 110, 0, 0]
pub let STRING_oldsoutharabian0: [17]c_char = [111, 108, 100, 115, 111, 117, 116, 104, 97, 114, 97, 98, 105, 97, 110, 0, 0]
pub let STRING_oldturkic0: [11]c_char = [111, 108, 100, 116, 117, 114, 107, 105, 99, 0, 0]
pub let STRING_olduyghur0: [11]c_char = [111, 108, 100, 117, 121, 103, 104, 117, 114, 0, 0]
pub let STRING_olonal0: [8]c_char = [111, 108, 111, 110, 97, 108, 0, 0]
pub let STRING_onao0: [6]c_char = [111, 110, 97, 111, 0, 0]
pub let STRING_oriya0: [7]c_char = [111, 114, 105, 121, 97, 0, 0]
pub let STRING_orkh0: [6]c_char = [111, 114, 107, 104, 0, 0]
pub let STRING_orya0: [6]c_char = [111, 114, 121, 97, 0, 0]
pub let STRING_osage0: [7]c_char = [111, 115, 97, 103, 101, 0, 0]
pub let STRING_osge0: [6]c_char = [111, 115, 103, 101, 0, 0]
pub let STRING_osma0: [6]c_char = [111, 115, 109, 97, 0, 0]
pub let STRING_osmanya0: [9]c_char = [111, 115, 109, 97, 110, 121, 97, 0, 0]
pub let STRING_ougr0: [6]c_char = [111, 117, 103, 114, 0, 0]
pub let STRING_p0: [3]c_char = [112, 0, 0]
pub let STRING_pahawhhmong0: [13]c_char = [112, 97, 104, 97, 119, 104, 104, 109, 111, 110, 103, 0, 0]
pub let STRING_palm0: [6]c_char = [112, 97, 108, 109, 0, 0]
pub let STRING_palmyrene0: [11]c_char = [112, 97, 108, 109, 121, 114, 101, 110, 101, 0, 0]
pub let STRING_patsyn0: [8]c_char = [112, 97, 116, 115, 121, 110, 0, 0]
pub let STRING_patternsyntax0: [15]c_char = [112, 97, 116, 116, 101, 114, 110, 115, 121, 110, 116, 97, 120, 0, 0]
pub let STRING_patternwhitespace0: [19]c_char = [112, 97, 116, 116, 101, 114, 110, 119, 104, 105, 116, 101, 115, 112, 97, 99, 101, 0, 0]
pub let STRING_patws0: [7]c_char = [112, 97, 116, 119, 115, 0, 0]
pub let STRING_pauc0: [6]c_char = [112, 97, 117, 99, 0, 0]
pub let STRING_paucinhau0: [11]c_char = [112, 97, 117, 99, 105, 110, 104, 97, 117, 0, 0]
pub let STRING_pc0: [4]c_char = [112, 99, 0, 0]
pub let STRING_pcm0: [5]c_char = [112, 99, 109, 0, 0]
pub let STRING_pd0: [4]c_char = [112, 100, 0, 0]
pub let STRING_pe0: [4]c_char = [112, 101, 0, 0]
pub let STRING_perm0: [6]c_char = [112, 101, 114, 109, 0, 0]
pub let STRING_pf0: [4]c_char = [112, 102, 0, 0]
pub let STRING_phag0: [6]c_char = [112, 104, 97, 103, 0, 0]
pub let STRING_phagspa0: [9]c_char = [112, 104, 97, 103, 115, 112, 97, 0, 0]
pub let STRING_phli0: [6]c_char = [112, 104, 108, 105, 0, 0]
pub let STRING_phlp0: [6]c_char = [112, 104, 108, 112, 0, 0]
pub let STRING_phnx0: [6]c_char = [112, 104, 110, 120, 0, 0]
pub let STRING_phoenician0: [12]c_char = [112, 104, 111, 101, 110, 105, 99, 105, 97, 110, 0, 0]
pub let STRING_pi0: [4]c_char = [112, 105, 0, 0]
pub let STRING_plrd0: [6]c_char = [112, 108, 114, 100, 0, 0]
pub let STRING_po0: [4]c_char = [112, 111, 0, 0]
pub let STRING_prependedconcatenationmark0: [28]c_char = [112, 114, 101, 112, 101, 110, 100, 101, 100, 99, 111, 110, 99, 97, 116, 101, 110, 97, 116, 105, 111, 110, 109, 97, 114, 107, 0, 0]
pub let STRING_prti0: [6]c_char = [112, 114, 116, 105, 0, 0]
pub let STRING_ps0: [4]c_char = [112, 115, 0, 0]
pub let STRING_psalterpahlavi0: [16]c_char = [112, 115, 97, 108, 116, 101, 114, 112, 97, 104, 108, 97, 118, 105, 0, 0]
pub let STRING_qaac0: [6]c_char = [113, 97, 97, 99, 0, 0]
pub let STRING_qaai0: [6]c_char = [113, 97, 97, 105, 0, 0]
pub let STRING_qmark0: [7]c_char = [113, 109, 97, 114, 107, 0, 0]
pub let STRING_quotationmark0: [15]c_char = [113, 117, 111, 116, 97, 116, 105, 111, 110, 109, 97, 114, 107, 0, 0]
pub let STRING_radical0: [9]c_char = [114, 97, 100, 105, 99, 97, 108, 0, 0]
pub let STRING_regionalindicator0: [19]c_char = [114, 101, 103, 105, 111, 110, 97, 108, 105, 110, 100, 105, 99, 97, 116, 111, 114, 0, 0]
pub let STRING_rejang0: [8]c_char = [114, 101, 106, 97, 110, 103, 0, 0]
pub let STRING_ri0: [4]c_char = [114, 105, 0, 0]
pub let STRING_rjng0: [6]c_char = [114, 106, 110, 103, 0, 0]
pub let STRING_rohg0: [6]c_char = [114, 111, 104, 103, 0, 0]
pub let STRING_runic0: [7]c_char = [114, 117, 110, 105, 99, 0, 0]
pub let STRING_runr0: [6]c_char = [114, 117, 110, 114, 0, 0]
pub let STRING_s0: [3]c_char = [115, 0, 0]
pub let STRING_samaritan0: [11]c_char = [115, 97, 109, 97, 114, 105, 116, 97, 110, 0, 0]
pub let STRING_samr0: [6]c_char = [115, 97, 109, 114, 0, 0]
pub let STRING_sarb0: [6]c_char = [115, 97, 114, 98, 0, 0]
pub let STRING_saur0: [6]c_char = [115, 97, 117, 114, 0, 0]
pub let STRING_saurashtra0: [12]c_char = [115, 97, 117, 114, 97, 115, 104, 116, 114, 97, 0, 0]
pub let STRING_sc0: [4]c_char = [115, 99, 0, 0]
pub let STRING_sd0: [4]c_char = [115, 100, 0, 0]
pub let STRING_sentenceterminal0: [18]c_char = [115, 101, 110, 116, 101, 110, 99, 101, 116, 101, 114, 109, 105, 110, 97, 108, 0, 0]
pub let STRING_sgnw0: [6]c_char = [115, 103, 110, 119, 0, 0]
pub let STRING_sharada0: [9]c_char = [115, 104, 97, 114, 97, 100, 97, 0, 0]
pub let STRING_shavian0: [9]c_char = [115, 104, 97, 118, 105, 97, 110, 0, 0]
pub let STRING_shaw0: [6]c_char = [115, 104, 97, 119, 0, 0]
pub let STRING_shrd0: [6]c_char = [115, 104, 114, 100, 0, 0]
pub let STRING_sidd0: [6]c_char = [115, 105, 100, 100, 0, 0]
pub let STRING_siddham0: [9]c_char = [115, 105, 100, 100, 104, 97, 109, 0, 0]
pub let STRING_signwriting0: [13]c_char = [115, 105, 103, 110, 119, 114, 105, 116, 105, 110, 103, 0, 0]
pub let STRING_sind0: [6]c_char = [115, 105, 110, 100, 0, 0]
pub let STRING_sinh0: [6]c_char = [115, 105, 110, 104, 0, 0]
pub let STRING_sinhala0: [9]c_char = [115, 105, 110, 104, 97, 108, 97, 0, 0]
pub let STRING_sk0: [4]c_char = [115, 107, 0, 0]
pub let STRING_sm0: [4]c_char = [115, 109, 0, 0]
pub let STRING_so0: [4]c_char = [115, 111, 0, 0]
pub let STRING_softdotted0: [12]c_char = [115, 111, 102, 116, 100, 111, 116, 116, 101, 100, 0, 0]
pub let STRING_sogd0: [6]c_char = [115, 111, 103, 100, 0, 0]
pub let STRING_sogdian0: [9]c_char = [115, 111, 103, 100, 105, 97, 110, 0, 0]
pub let STRING_sogo0: [6]c_char = [115, 111, 103, 111, 0, 0]
pub let STRING_sora0: [6]c_char = [115, 111, 114, 97, 0, 0]
pub let STRING_sorasompeng0: [13]c_char = [115, 111, 114, 97, 115, 111, 109, 112, 101, 110, 103, 0, 0]
pub let STRING_soyo0: [6]c_char = [115, 111, 121, 111, 0, 0]
pub let STRING_soyombo0: [9]c_char = [115, 111, 121, 111, 109, 98, 111, 0, 0]
pub let STRING_sterm0: [7]c_char = [115, 116, 101, 114, 109, 0, 0]
pub let STRING_sund0: [6]c_char = [115, 117, 110, 100, 0, 0]
pub let STRING_sundanese0: [11]c_char = [115, 117, 110, 100, 97, 110, 101, 115, 101, 0, 0]
pub let STRING_sunu0: [6]c_char = [115, 117, 110, 117, 0, 0]
pub let STRING_sunuwar0: [9]c_char = [115, 117, 110, 117, 119, 97, 114, 0, 0]
pub let STRING_sylo0: [6]c_char = [115, 121, 108, 111, 0, 0]
pub let STRING_sylotinagri0: [13]c_char = [115, 121, 108, 111, 116, 105, 110, 97, 103, 114, 105, 0, 0]
pub let STRING_syrc0: [6]c_char = [115, 121, 114, 99, 0, 0]
pub let STRING_syriac0: [8]c_char = [115, 121, 114, 105, 97, 99, 0, 0]
pub let STRING_tagalog0: [9]c_char = [116, 97, 103, 97, 108, 111, 103, 0, 0]
pub let STRING_tagb0: [6]c_char = [116, 97, 103, 98, 0, 0]
pub let STRING_tagbanwa0: [10]c_char = [116, 97, 103, 98, 97, 110, 119, 97, 0, 0]
pub let STRING_taile0: [7]c_char = [116, 97, 105, 108, 101, 0, 0]
pub let STRING_taitham0: [9]c_char = [116, 97, 105, 116, 104, 97, 109, 0, 0]
pub let STRING_taiviet0: [9]c_char = [116, 97, 105, 118, 105, 101, 116, 0, 0]
pub let STRING_takr0: [6]c_char = [116, 97, 107, 114, 0, 0]
pub let STRING_takri0: [7]c_char = [116, 97, 107, 114, 105, 0, 0]
pub let STRING_tale0: [6]c_char = [116, 97, 108, 101, 0, 0]
pub let STRING_talu0: [6]c_char = [116, 97, 108, 117, 0, 0]
pub let STRING_tamil0: [7]c_char = [116, 97, 109, 105, 108, 0, 0]
pub let STRING_taml0: [6]c_char = [116, 97, 109, 108, 0, 0]
pub let STRING_tang0: [6]c_char = [116, 97, 110, 103, 0, 0]
pub let STRING_tangsa0: [8]c_char = [116, 97, 110, 103, 115, 97, 0, 0]
pub let STRING_tangut0: [8]c_char = [116, 97, 110, 103, 117, 116, 0, 0]
pub let STRING_tavt0: [6]c_char = [116, 97, 118, 116, 0, 0]
pub let STRING_telu0: [6]c_char = [116, 101, 108, 117, 0, 0]
pub let STRING_telugu0: [8]c_char = [116, 101, 108, 117, 103, 117, 0, 0]
pub let STRING_term0: [6]c_char = [116, 101, 114, 109, 0, 0]
pub let STRING_terminalpunctuation0: [21]c_char = [116, 101, 114, 109, 105, 110, 97, 108, 112, 117, 110, 99, 116, 117, 97, 116, 105, 111, 110, 0, 0]
pub let STRING_tfng0: [6]c_char = [116, 102, 110, 103, 0, 0]
pub let STRING_tglg0: [6]c_char = [116, 103, 108, 103, 0, 0]
pub let STRING_thaa0: [6]c_char = [116, 104, 97, 97, 0, 0]
pub let STRING_thaana0: [8]c_char = [116, 104, 97, 97, 110, 97, 0, 0]
pub let STRING_thai0: [6]c_char = [116, 104, 97, 105, 0, 0]
pub let STRING_tibetan0: [9]c_char = [116, 105, 98, 101, 116, 97, 110, 0, 0]
pub let STRING_tibt0: [6]c_char = [116, 105, 98, 116, 0, 0]
pub let STRING_tifinagh0: [10]c_char = [116, 105, 102, 105, 110, 97, 103, 104, 0, 0]
pub let STRING_tirh0: [6]c_char = [116, 105, 114, 104, 0, 0]
pub let STRING_tirhuta0: [9]c_char = [116, 105, 114, 104, 117, 116, 97, 0, 0]
pub let STRING_tnsa0: [6]c_char = [116, 110, 115, 97, 0, 0]
pub let STRING_todhri0: [8]c_char = [116, 111, 100, 104, 114, 105, 0, 0]
pub let STRING_todr0: [6]c_char = [116, 111, 100, 114, 0, 0]
pub let STRING_toto0: [6]c_char = [116, 111, 116, 111, 0, 0]
pub let STRING_tulutigalari0: [14]c_char = [116, 117, 108, 117, 116, 105, 103, 97, 108, 97, 114, 105, 0, 0]
pub let STRING_tutg0: [6]c_char = [116, 117, 116, 103, 0, 0]
pub let STRING_ugar0: [6]c_char = [117, 103, 97, 114, 0, 0]
pub let STRING_ugaritic0: [10]c_char = [117, 103, 97, 114, 105, 116, 105, 99, 0, 0]
pub let STRING_uideo0: [7]c_char = [117, 105, 100, 101, 111, 0, 0]
pub let STRING_unifiedideograph0: [18]c_char = [117, 110, 105, 102, 105, 101, 100, 105, 100, 101, 111, 103, 114, 97, 112, 104, 0, 0]
pub let STRING_unknown0: [9]c_char = [117, 110, 107, 110, 111, 119, 110, 0, 0]
pub let STRING_uppercase0: [11]c_char = [117, 112, 112, 101, 114, 99, 97, 115, 101, 0, 0]
pub let STRING_vai0: [5]c_char = [118, 97, 105, 0, 0]
pub let STRING_vaii0: [6]c_char = [118, 97, 105, 105, 0, 0]
pub let STRING_variationselector0: [19]c_char = [118, 97, 114, 105, 97, 116, 105, 111, 110, 115, 101, 108, 101, 99, 116, 111, 114, 0, 0]
pub let STRING_vith0: [6]c_char = [118, 105, 116, 104, 0, 0]
pub let STRING_vithkuqi0: [10]c_char = [118, 105, 116, 104, 107, 117, 113, 105, 0, 0]
pub let STRING_vs0: [4]c_char = [118, 115, 0, 0]
pub let STRING_wancho0: [8]c_char = [119, 97, 110, 99, 104, 111, 0, 0]
pub let STRING_wara0: [6]c_char = [119, 97, 114, 97, 0, 0]
pub let STRING_warangciti0: [12]c_char = [119, 97, 114, 97, 110, 103, 99, 105, 116, 105, 0, 0]
pub let STRING_wcho0: [6]c_char = [119, 99, 104, 111, 0, 0]
pub let STRING_whitespace0: [12]c_char = [119, 104, 105, 116, 101, 115, 112, 97, 99, 101, 0, 0]
pub let STRING_wspace0: [8]c_char = [119, 115, 112, 97, 99, 101, 0, 0]
pub let STRING_xan0: [5]c_char = [120, 97, 110, 0, 0]
pub let STRING_xidc0: [6]c_char = [120, 105, 100, 99, 0, 0]
pub let STRING_xidcontinue0: [13]c_char = [120, 105, 100, 99, 111, 110, 116, 105, 110, 117, 101, 0, 0]
pub let STRING_xids0: [6]c_char = [120, 105, 100, 115, 0, 0]
pub let STRING_xidstart0: [10]c_char = [120, 105, 100, 115, 116, 97, 114, 116, 0, 0]
pub let STRING_xpeo0: [6]c_char = [120, 112, 101, 111, 0, 0]
pub let STRING_xps0: [5]c_char = [120, 112, 115, 0, 0]
pub let STRING_xsp0: [5]c_char = [120, 115, 112, 0, 0]
pub let STRING_xsux0: [6]c_char = [120, 115, 117, 120, 0, 0]
pub let STRING_xuc0: [5]c_char = [120, 117, 99, 0, 0]
pub let STRING_xwd0: [5]c_char = [120, 119, 100, 0, 0]
pub let STRING_yezi0: [6]c_char = [121, 101, 122, 105, 0, 0]
pub let STRING_yezidi0: [8]c_char = [121, 101, 122, 105, 100, 105, 0, 0]
pub let STRING_yi0: [4]c_char = [121, 105, 0, 0]
pub let STRING_yiii0: [6]c_char = [121, 105, 105, 105, 0, 0]
pub let STRING_z0: [3]c_char = [122, 0, 0]
pub let STRING_zanabazarsquare0: [17]c_char = [122, 97, 110, 97, 98, 97, 122, 97, 114, 115, 113, 117, 97, 114, 101, 0, 0]
pub let STRING_zanb0: [6]c_char = [122, 97, 110, 98, 0, 0]
pub let STRING_zinh0: [6]c_char = [122, 105, 110, 104, 0, 0]
pub let STRING_zl0: [4]c_char = [122, 108, 0, 0]
pub let STRING_zp0: [4]c_char = [122, 112, 0, 0]
pub let STRING_zs0: [4]c_char = [122, 115, 0, 0]
pub let STRING_zyyy0: [6]c_char = [122, 121, 121, 121, 0, 0]
pub let STRING_zzzz0: [6]c_char = [122, 122, 122, 122, 0, 0]
pub var _pcre2_unicode_version_8: *const i8 = c"16.0.0".ptr as *const i8

pub let _pcre2_ucd_caseless_sets_8: [118]c_uint = [0xffffffff, 0x0053, 0x0073, 0x017f, 0xffffffff, 0x01c4, 0x01c5, 0x01c6, 0xffffffff, 0x01c7, 0x01c8, 0x01c9, 0xffffffff, 0x01ca, 0x01cb, 0x01cc, 0xffffffff, 0x01f1, 0x01f2, 0x01f3, 0xffffffff, 0x0345, 0x0399, 0x03b9, 0x1fbe, 0xffffffff, 0x00b5, 0x039c, 0x03bc, 0xffffffff, 0x03a3, 0x03c2, 0x03c3, 0xffffffff, 0x0392, 0x03b2, 0x03d0, 0xffffffff, 0x0398, 0x03b8, 0x03d1, 0x03f4, 0xffffffff, 0x03a6, 0x03c6, 0x03d5, 0xffffffff, 0x03a0, 0x03c0, 0x03d6, 0xffffffff, 0x039a, 0x03ba, 0x03f0, 0xffffffff, 0x03a1, 0x03c1, 0x03f1, 0xffffffff, 0x0395, 0x03b5, 0x03f5, 0xffffffff, 0x0412, 0x0432, 0x1c80, 0xffffffff, 0x0414, 0x0434, 0x1c81, 0xffffffff, 0x041e, 0x043e, 0x1c82, 0xffffffff, 0x0421, 0x0441, 0x1c83, 0xffffffff, 0x0422, 0x0442, 0x1c84, 0x1c85, 0xffffffff, 0x042a, 0x044a, 0x1c86, 0xffffffff, 0x0462, 0x0463, 0x1c87, 0xffffffff, 0x1e60, 0x1e61, 0x1e9b, 0xffffffff, 0x03a9, 0x03c9, 0x2126, 0xffffffff, 0x004b, 0x006b, 0x212a, 0xffffffff, 0x00c5, 0x00e5, 0x212b, 0xffffffff, 0x1c88, 0xa64a, 0xa64b, 0xffffffff, 0x0069, 0x0130, 0xffffffff, 0x0049, 0x0131, 0xffffffff]

pub let _pcre2_ucd_turkish_dotted_i_caseset_8: c_uint = 112

pub let _pcre2_ucd_nocase_ranges_8: [82]c_uint = [0, 65, 122, 181, 181, 192, 658, 669, 670, 837, 837, 880, 1153, 1162, 1366, 1377, 1414, 4256, 4351, 5024, 5117, 7296, 7359, 7545, 7549, 7566, 7566, 7680, 8188, 8486, 8498, 8526, 8526, 8544, 8580, 9398, 9449, 11264, 11507, 11520, 11565, 42560, 42605, 42624, 42651, 42786, 42863, 42873, 42972, 42997, 42998, 43859, 43859, 43888, 43967, 64261, 64262, 65313, 65370, 66560, 66639, 66736, 66811, 66928, 67004, 68736, 68786, 68800, 68850, 68944, 68965, 68976, 68997, 71840, 71903, 93760, 93823, 125184, 125251, 1114112, 4294967295, 4294967295]

pub let _pcre2_ucd_nocase_ranges_size_8: c_uint = 80

pub let _pcre2_ucd_digit_sets_8: [77]c_uint = [76, 57, 1641, 1785, 1993, 2415, 2543, 2671, 2799, 2927, 3055, 3183, 3311, 3439, 3567, 3673, 3801, 3881, 4169, 4249, 6121, 6169, 6479, 6617, 6793, 6809, 7001, 7097, 7241, 7257, 42537, 43225, 43273, 43481, 43513, 43609, 44025, 65305, 66729, 68921, 68937, 69743, 69881, 69951, 70105, 70393, 70745, 70873, 71257, 71369, 71385, 71395, 71481, 71913, 72025, 72697, 72793, 73049, 73129, 73561, 90425, 92777, 92873, 93017, 93561, 118009, 120791, 120801, 120811, 120821, 120831, 123209, 123641, 124153, 124410, 125273, 130041]

pub let _pcre2_ucd_script_sets_8: [444]c_uint = [0, 0, 0, 0, 1075838979, 3676417, 1049158, 0, 262917, 8388608, 134217728, 0, 536870913, 0, 0, 0, 1, 8388608, 0, 0, 262145, 0, 0, 0, 16777223, 2112, 2147484160, 0, 16777223, 64, 2147549184, 1, 16777221, 8192, 0, 0, 262209, 4096, 2147483648, 0, 16777287, 10241, 65537, 1, 268435457, 6145, 4, 0, 7, 0, 512, 0, 81, 10304, 514, 1, 95, 65, 514, 0, 1, 8192, 0, 0, 65, 0, 2, 0, 16777221, 0, 65536, 0, 16777217, 64, 0, 0, 1, 0, 2147483648, 0, 8388609, 0, 0, 0, 5, 0, 0, 1, 3, 0, 512, 1, 65, 0, 0, 0, 285212737, 0, 2, 0, 16777281, 0, 2, 0, 65, 0, 2147483648, 0, 16777281, 0, 0, 0, 17039361, 1, 2147483649, 0, 2, 0, 0, 0, 1, 0, 65536, 0, 1, 0, 1, 1, 1, 0, 0, 0, 2, 2048, 0, 0, 4, 0, 512, 0, 4, 4096, 0, 0, 5, 0, 0, 0, 2097160, 4096, 0, 0, 224, 65536, 287309824, 0, 224, 0, 0, 0, 224, 65536, 287342592, 0, 96, 134217728, 73434240, 0, 96, 0, 0, 0, 160, 0, 16777216, 0, 32, 0, 2097152, 0, 130817, 1073741824, 4104, 0, 130817, 0, 4104, 0, 261888, 2147500032, 1083971656, 0, 261888, 2147500064, 1620842568, 0, 256, 67108864, 524352, 0, 512, 268451840, 0, 0, 1024, 0, 8192, 0, 2048, 0, 16, 0, 8192, 0, 8, 0, 32768, 0, 8388608, 2, 1048576, 268435520, 0, 0, 2097153, 4096, 0, 0, 33554432, 0, 0, 0, 0, 30, 0, 0, 67108864, 32768, 0, 0, 33536, 0, 8, 0, 256, 0, 0, 0, 33024, 0, 8, 0, 768, 0, 0, 0, 256, 1073741824, 0, 0, 127232, 0, 0, 0, 256, 0, 8388608, 0, 250624, 0, 8392712, 2, 256, 0, 8, 0, 33024, 0, 8, 2, 512, 0, 0, 0, 0, 0, 8388608, 0, 69, 0, 0, 0, 64, 0, 0, 0, 67108865, 32768, 0, 0, 32, 0, 32768, 0, 2097152, 34344960, 16384, 0, 2, 537395200, 16384, 0, 257, 0, 8, 0, 1, 2048, 0, 0, 0, 35651584, 0, 0, 2097152, 74973184, 16384, 0, 0, 0, 2, 0, 32, 0, 49152, 0, 1073741824, 0, 131072, 0, 4232052736, 0, 0, 0, 4232052736, 32768, 0, 0, 2017460224, 0, 0, 0, 1073741824, 0, 0, 0, 4232577024, 0, 0, 0, 4232577024, 8388608, 0, 0, 4164943872, 0, 0, 0, 1610612736, 0, 0, 0, 402653184, 0, 0, 0, 1476395008, 0, 0, 0, 1073741825, 0, 0, 0, 101632, 3288334336, 8919376, 2, 36096, 3288334336, 8919376, 2, 3328, 2214592512, 530768, 0, 3328, 3288334336, 530768, 0, 768, 0, 0, 2, 8448, 0, 0, 0, 1048577, 131072, 0, 0, 0, 16778240, 0, 0, 32, 65536, 0, 0, 160, 0, 0, 0, 0, 640, 33554432, 0, 0, 640, 0, 0, 0, 640, 32, 0, 32, 2048, 0, 0, 0, 0, 67108992, 0]

pub let _pcre2_ucd_boolprop_sets_8: [384]c_uint = [0, 0, 1, 0, 1, 4196352, 8388609, 4196352, 8388609, 328704, 8388609, 9216, 8585217, 1024, 8388609, 1024, 8388641, 9216, 8388625, 1024, 8388609, 1152, 8388609, 263168, 8392705, 1024, 8388641, 328704, 75694083, 8388609, 8388641, 263168, 8388625, 1152, 75498439, 26214403, 8389573, 26214403, 8421409, 1152, 8388609, 8388609, 8421409, 1024, 75500871, 25165891, 8392005, 25165891, 8392005, 25296963, 0, 4196352, 8388608, 4194304, 8388608, 1024, 8421408, 0, 10551296, 1024, 8388676, 25165891, 8388624, 9216, 8388608, 1152, 8224, 0, 1082130432, 0, 8392132, 25165891, 12615712, 8388609, 8388608, 0, 8389572, 26214403, 8392004, 25165891, 8392004, 25296963, 8408516, 25165891, 8388612, 25165827, 8390596, 26214403, 8391620, 25165827, 8421476, 25165891, 8421476, 25296963, 8421412, 25165827, 12615716, 25165827, 16810016, 8388617, 16813540, 8388681, 16785440, 8388617, 16777248, 8388617, 16777252, 8388617, 8421476, 67, 8388608, 262144, 8388640, 8650753, 8392132, 25166019, 8388676, 26214531, 8388676, 26214403, 8389572, 26214531, 8388608, 128, 16777248, 8, 8388640, 0, 8388608, 327680, 8392704, 0, 16810020, 8388617, 32, 4096, 8232, 0, 12582948, 25165827, 16777252, 8388873, 16810016, 8388873, 8388608, 8388609, 8404996, 25165827, 8388644, 25165827, 16777248, 8388873, 16810020, 8388873, 8388612, 8388609, 8388612, 25165835, 50364448, 8388617, 16777220, 8388617, 20971556, 8388617, 21004320, 8388617, 8388612, 8388611, 50364452, 8388617, 8388612, 25165859, 8388624, 0, 8421376, 8388609, 16793636, 8388617, 8421380, 8388609, 8390980, 25165891, 8388708, 25165891, 8396804, 25165827, 8389444, 26214403, 50364416, 8388617, 12582912, 0, 16785440, 10485769, 16777252, 25165835, 16810016, 8, 21004324, 8388617, 8421376, 0, 8388676, 25296963, 8388708, 25296963, 16785440, 8388625, 139296, 8388633, 8232, 2048, 8392704, 1024, 8388640, 9216, 8388608, 9216, 8388640, 328704, 8388640, 1024, 10551296, 328704, 8388608, 328704, 8388608, 8388737, 8388624, 1024, 8224, 128, 8192, 0, 24608, 0, 1082130432, 128, 1082134528, 128, 1082130448, 128, 16777248, 8388745, 16908320, 8, 8388676, 25166019, 8388608, 25165955, 10551296, 0, 8388608, 25165827, 8388612, 25165955, 10551364, 25165891, 8388676, 25297091, 10551296, 1152, 3229614080, 1152, 8388624, 1152, 8392704, 1152, 11599872, 1024, 8405008, 1024, 10485760, 1024, 0, 1024, 8389572, 1048576, 10552260, 1048576, 8392004, 64, 11599872, 1152, 10485760, 1152, 11075584, 1024, 12124160, 1024, 50331680, 8388617, 8421412, 1024, 8388608, 263168, 8388608, 16384, 142606336, 0, 276824064, 0, 545259520, 0, 8388612, 25165831, 16809984, 8388617, 10555392, 1024, 8421408, 3, 8388612, 25690119, 8421380, 25165827, 8388612, 3, 0, 512, 16916512, 10485769, 8388608, 8192, 8388640, 327680, 8388640, 262144, 8392704, 128, 8388624, 128, 8388640, 8192, 75497472, 8388609, 75498436, 26214403, 8421408, 128, 75500868, 25165891, 8388624, 8192, 16810020, 8388619, 32, 0, 12582916, 25165827, 12615684, 25165827, 20971552, 8388617, 16777248, 8388621, 16809988, 8388617, 16777216, 8388617, 3229614080, 128, 10485760, 0, 11599872, 0, 2097152, 0, 8388676, 1048576, 10551364, 1048576, 9633792, 32768, 12124160, 0, 11075584, 0, 9895968, 8, 11730944, 0, 16916512, 8]

pub let _pcre2_ucd_records_8: [1543]ucd_record = [ucd_record { script: 99, chartype: 0, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 2 }, ucd_record { script: 99, chartype: 0, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 43008, bprops: 4 }, ucd_record { script: 99, chartype: 0, gbprop: 1, caseset: 0, other_case: 0, scriptx_bidiclass: 4096, bprops: 4 }, ucd_record { script: 99, chartype: 0, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 45056, bprops: 4 }, ucd_record { script: 99, chartype: 0, gbprop: 0, caseset: 0, other_case: 0, scriptx_bidiclass: 4096, bprops: 4 }, ucd_record { script: 99, chartype: 0, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 4096, bprops: 2 }, ucd_record { script: 99, chartype: 0, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 43008, bprops: 2 }, ucd_record { script: 99, chartype: 29, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 45056, bprops: 6 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 8 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 10 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 12 }, ucd_record { script: 99, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 14 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 14 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 14 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 16 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 18 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 18 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 12 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 12288, bprops: 20 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 22 }, ucd_record { script: 99, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 12288, bprops: 24 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 26 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 14 }, ucd_record { script: 99, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 10240, bprops: 28 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 30 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 22 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 32 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 20 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 32, scriptx_bidiclass: 18432, bprops: 34 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 32, scriptx_bidiclass: 18432, bprops: 36 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 100, other_case: 32, scriptx_bidiclass: 18432, bprops: 36 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 1, other_case: 32, scriptx_bidiclass: 18432, bprops: 36 }, ucd_record { script: 99, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 38 }, ucd_record { script: 99, chartype: 16, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 40 }, ucd_record { script: 99, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 42 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 18432, bprops: 44 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 18432, bprops: 46 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 18432, bprops: 48 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 100, other_case: -32, scriptx_bidiclass: 18432, bprops: 46 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 1, other_case: -32, scriptx_bidiclass: 18432, bprops: 46 }, ucd_record { script: 99, chartype: 0, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 0 }, ucd_record { script: 99, chartype: 0, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 4096, bprops: 50 }, ucd_record { script: 99, chartype: 29, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 52 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 54 }, ucd_record { script: 99, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 54 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 54 }, ucd_record { script: 99, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 56 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 58 }, ucd_record { script: 0, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 60 }, ucd_record { script: 99, chartype: 20, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 62 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 64 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 66 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 54 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 64 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 10240, bprops: 68 }, ucd_record { script: 99, chartype: 5, gbprop: 12, caseset: 26, other_case: 775, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28676, bprops: 72 }, ucd_record { script: 99, chartype: 19, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 62 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 104, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 7615, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 104, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 121, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 1, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -1, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -1, scriptx_bidiclass: 18432, bprops: 80 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 60 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 82 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -121, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 1, other_case: 0, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 195, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 210, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 206, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 205, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 79, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 202, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 203, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 207, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 97, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 211, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 209, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 163, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42561, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 213, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 130, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 214, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 218, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 217, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 219, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 56, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 5, other_case: 2, scriptx_bidiclass: 18432, bprops: 86 }, ucd_record { script: 0, chartype: 8, gbprop: 12, caseset: 5, other_case: 1, scriptx_bidiclass: 18432, bprops: 88 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 5, other_case: -2, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 9, other_case: 2, scriptx_bidiclass: 18432, bprops: 86 }, ucd_record { script: 0, chartype: 8, gbprop: 12, caseset: 9, other_case: 1, scriptx_bidiclass: 18432, bprops: 88 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 9, other_case: -2, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 13, other_case: 2, scriptx_bidiclass: 18432, bprops: 86 }, ucd_record { script: 0, chartype: 8, gbprop: 12, caseset: 13, other_case: 1, scriptx_bidiclass: 18432, bprops: 88 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 13, other_case: -2, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -79, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 17, other_case: 2, scriptx_bidiclass: 18432, bprops: 86 }, ucd_record { script: 0, chartype: 8, gbprop: 12, caseset: 17, other_case: 1, scriptx_bidiclass: 18432, bprops: 88 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 17, other_case: -2, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -97, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -56, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -130, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 10795, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -163, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 10792, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 10815, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -195, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 69, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 71, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 10783, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 10780, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 10782, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -210, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -206, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -205, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -202, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -203, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42319, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42315, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -207, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42343, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42280, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42308, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -209, scriptx_bidiclass: 18432, bprops: 80 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -211, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 10743, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42305, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 10749, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -213, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -214, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 10727, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -218, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42307, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42282, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -69, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -217, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -71, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -219, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42261, scriptx_bidiclass: 18432, bprops: 80 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 42258, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 90 }, ucd_record { script: 0, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 92 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 94 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 94 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18440, bprops: 94 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 90 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28684, bprops: 94 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28688, bprops: 94 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 96 }, ucd_record { script: 99, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28692, bprops: 56 }, ucd_record { script: 99, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28684, bprops: 56 }, ucd_record { script: 29, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 56 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26648, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26652, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26656, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26660, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26664, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26668, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26672, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26676, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26680, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26684, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26688, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26692, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26696, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26700, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26704, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26708, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26712, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26716, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26720, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26724, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26728, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26732, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26736, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26740, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 21, other_case: 116, scriptx_bidiclass: 26740, bprops: 100 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 102 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26744, bprops: 104 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26748, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26752, bprops: 106 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 1, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -1, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28804, bprops: 94 }, ucd_record { script: 1, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28804, bprops: 56 }, ucd_record { script: 98, chartype: 2, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 0 }, ucd_record { script: 1, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 108 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 130, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 110 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 116, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 56 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 38, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 112 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 37, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 64, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 63, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 7235, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 34, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 59, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 38, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 21, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 51, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 26, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 47, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 55, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 30, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 43, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 96, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -38, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -37, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 7219, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 34, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 59, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 38, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 21, other_case: -116, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 51, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 26, other_case: -775, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 47, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 55, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 30, other_case: 1, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 30, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 43, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 96, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -64, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -63, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 8, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 34, other_case: -30, scriptx_bidiclass: 18432, bprops: 114 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 38, other_case: -25, scriptx_bidiclass: 18432, bprops: 114 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 116 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 118 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 43, other_case: -15, scriptx_bidiclass: 18432, bprops: 114 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 47, other_case: -22, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -8, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 43, chartype: 9, gbprop: 12, caseset: 0, other_case: 1, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 43, chartype: 5, gbprop: 12, caseset: 0, other_case: -1, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 51, other_case: -54, scriptx_bidiclass: 18432, bprops: 114 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 55, other_case: -48, scriptx_bidiclass: 18432, bprops: 114 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 7, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -116, scriptx_bidiclass: 18432, bprops: 80 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 38, other_case: -60, scriptx_bidiclass: 18432, bprops: 120 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 59, other_case: -64, scriptx_bidiclass: 18432, bprops: 114 }, ucd_record { script: 1, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 122 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: -7, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 60 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: -130, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 0, other_case: 80, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 0, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 63, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 67, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 71, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 75, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 79, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 84, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 63, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 67, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 71, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 75, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 79, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 84, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 0, other_case: -80, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 0, other_case: -80, scriptx_bidiclass: 18432, bprops: 80 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 0, other_case: 1, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 0, other_case: -1, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 88, other_case: 1, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 88, other_case: -1, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 2, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26760, bprops: 98 }, ucd_record { script: 2, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26764, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26768, bprops: 98 }, ucd_record { script: 2, chartype: 11, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 124 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 0, other_case: 15, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 0, other_case: -15, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 3, chartype: 9, gbprop: 12, caseset: 0, other_case: 48, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 3, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 94 }, ucd_record { script: 3, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 3, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 126 }, ucd_record { script: 3, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 60 }, ucd_record { script: 3, chartype: 5, gbprop: 12, caseset: 0, other_case: -48, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 3, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 3, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18580, bprops: 128 }, ucd_record { script: 3, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 130 }, ucd_record { script: 3, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 3, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 74 }, ucd_record { script: 98, chartype: 2, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 0 }, ucd_record { script: 4, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 4, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 4, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 132 }, ucd_record { script: 4, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 130 }, ucd_record { script: 4, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 4, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 110 }, ucd_record { script: 4, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 4, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 4, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 126 }, ucd_record { script: 5, chartype: 1, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 2048, bprops: 134 }, ucd_record { script: 99, chartype: 1, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 2048, bprops: 134 }, ucd_record { script: 5, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 122 }, ucd_record { script: 5, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 122 }, ucd_record { script: 5, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 74 }, ucd_record { script: 5, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 74 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8344, bprops: 110 }, ucd_record { script: 5, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 74 }, ucd_record { script: 5, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 5, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 152, bprops: 110 }, ucd_record { script: 5, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 156, bprops: 136 }, ucd_record { script: 5, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 128 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 160, bprops: 128 }, ucd_record { script: 5, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 84 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 164, bprops: 138 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26792, bprops: 132 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26792, bprops: 106 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26792, bprops: 140 }, ucd_record { script: 5, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 132 }, ucd_record { script: 5, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 142 }, ucd_record { script: 5, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 2220, bprops: 144 }, ucd_record { script: 5, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 2048, bprops: 74 }, ucd_record { script: 5, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 146 }, ucd_record { script: 5, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 176, bprops: 128 }, ucd_record { script: 5, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 140 }, ucd_record { script: 5, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 5, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 94 }, ucd_record { script: 5, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 10240, bprops: 144 }, ucd_record { script: 5, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 74 }, ucd_record { script: 6, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 128 }, ucd_record { script: 6, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 110 }, ucd_record { script: 6, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 74 }, ucd_record { script: 98, chartype: 2, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 0 }, ucd_record { script: 6, chartype: 1, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 134 }, ucd_record { script: 6, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 84 }, ucd_record { script: 6, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 6, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 132 }, ucd_record { script: 6, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 7, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 84 }, ucd_record { script: 7, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 132 }, ucd_record { script: 48, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 144 }, ucd_record { script: 48, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 48, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 48, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 94 }, ucd_record { script: 48, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 48, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 48, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 110 }, ucd_record { script: 48, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 128 }, ucd_record { script: 48, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 138 }, ucd_record { script: 48, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 48, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 54, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 54, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 54, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 54, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 148 }, ucd_record { script: 54, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 54, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 110 }, ucd_record { script: 54, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 54, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 128 }, ucd_record { script: 59, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 59, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 59, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 110 }, ucd_record { script: 5, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 126 }, ucd_record { script: 5, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 150 }, ucd_record { script: 5, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 5, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 152 }, ucd_record { script: 8, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 8, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 8, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 8, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 156 }, ucd_record { script: 8, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 8, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26804, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26808, bprops: 98 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18620, bprops: 128 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18624, bprops: 128 }, ucd_record { script: 8, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18628, bprops: 144 }, ucd_record { script: 8, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 8, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 94 }, ucd_record { script: 9, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 9, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 9, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 9, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 156 }, ucd_record { script: 9, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 9, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 9, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 9, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18632, bprops: 144 }, ucd_record { script: 9, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 74 }, ucd_record { script: 9, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 9, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 9, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 9, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 10, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 10, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 10, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 10, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 10, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 10, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18636, bprops: 144 }, ucd_record { script: 10, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 162 }, ucd_record { script: 10, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 11, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 11, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 11, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 11, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 156 }, ucd_record { script: 11, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 11, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 11, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18640, bprops: 144 }, ucd_record { script: 11, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 11, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 74 }, ucd_record { script: 11, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 162 }, ucd_record { script: 12, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 12, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 12, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 12, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 156 }, ucd_record { script: 12, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 12, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 12, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 12, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 164 }, ucd_record { script: 12, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 12, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 12, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 13, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 13, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 13, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 13, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 13, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 13, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18644, bprops: 144 }, ucd_record { script: 13, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18644, bprops: 74 }, ucd_record { script: 13, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28884, bprops: 74 }, ucd_record { script: 13, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 13, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 74 }, ucd_record { script: 14, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 14, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 14, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 14, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 156 }, ucd_record { script: 14, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 14, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 14, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 14, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 14, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 14, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 15, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 15, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 15, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 15, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 15, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 15, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 106 }, ucd_record { script: 15, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 15, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 15, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18648, bprops: 144 }, ucd_record { script: 16, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 16, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 16, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 16, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 156 }, ucd_record { script: 16, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 16, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 16, chartype: 7, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 16, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 16, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 16, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 17, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 17, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 17, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 17, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 17, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 17, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 17, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 18, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 18, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 18, chartype: 7, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 166 }, ucd_record { script: 18, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 168 }, ucd_record { script: 99, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 74 }, ucd_record { script: 18, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 170 }, ucd_record { script: 18, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 18, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 18, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 18, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 18, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 100, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 100, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 100, chartype: 7, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 166 }, ucd_record { script: 100, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 100, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 170 }, ucd_record { script: 100, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 100, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 100, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 100, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 19, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 19, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 19, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 19, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 19, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 19, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 19, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 19, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 172 }, ucd_record { script: 19, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 172 }, ucd_record { script: 19, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 174 }, ucd_record { script: 19, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 19, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 176 }, ucd_record { script: 19, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 19, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 132 }, ucd_record { script: 19, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 20, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 20, chartype: 10, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 20, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 20, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 20, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 20, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 20, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18652, bprops: 144 }, ucd_record { script: 20, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 20, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 20, chartype: 10, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 178 }, ucd_record { script: 20, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 132 }, ucd_record { script: 20, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 20, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 21, chartype: 9, gbprop: 12, caseset: 0, other_case: 7264, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 21, chartype: 5, gbprop: 12, caseset: 0, other_case: 3008, scriptx_bidiclass: 18432, bprops: 180 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18656, bprops: 74 }, ucd_record { script: 21, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 182 }, ucd_record { script: 22, chartype: 7, gbprop: 6, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 22, chartype: 7, gbprop: 6, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 184 }, ucd_record { script: 22, chartype: 7, gbprop: 7, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 184 }, ucd_record { script: 22, chartype: 7, gbprop: 7, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 22, chartype: 7, gbprop: 8, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 23, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 23, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 23, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 23, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 23, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 23, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 23, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 23, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 24, chartype: 9, gbprop: 12, caseset: 0, other_case: 38864, scriptx_bidiclass: 18432, bprops: 186 }, ucd_record { script: 24, chartype: 9, gbprop: 12, caseset: 0, other_case: 8, scriptx_bidiclass: 18432, bprops: 186 }, ucd_record { script: 24, chartype: 5, gbprop: 12, caseset: 0, other_case: -8, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 101, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 130 }, ucd_record { script: 101, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 101, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 101, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 102, chartype: 29, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 45056, bprops: 52 }, ucd_record { script: 102, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 102, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 172 }, ucd_record { script: 102, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 172 }, ucd_record { script: 25, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18660, bprops: 110 }, ucd_record { script: 25, chartype: 14, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 33, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 33, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 33, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 33, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 34, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 34, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 34, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18664, bprops: 128 }, ucd_record { script: 35, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 35, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 36, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 36, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 103, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 103, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 146 }, ucd_record { script: 103, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 102 }, ucd_record { script: 103, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 103, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 103, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 103, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 103, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 103, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 103, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 148 }, ucd_record { script: 103, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 103, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 74 }, ucd_record { script: 103, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 103, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 26, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28908, bprops: 110 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28908, bprops: 128 }, ucd_record { script: 26, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 110 }, ucd_record { script: 26, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 130 }, ucd_record { script: 26, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 128 }, ucd_record { script: 26, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 190 }, ucd_record { script: 26, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 192 }, ucd_record { script: 26, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 66 }, ucd_record { script: 26, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 26, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 26, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 26, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 194 }, ucd_record { script: 26, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 37, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 37, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 37, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 37, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 37, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 37, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 128 }, ucd_record { script: 37, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 38, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 110, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 110, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 170 }, ucd_record { script: 110, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 110, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 110, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 103, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 42, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 42, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 42, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 42, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 123, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 123, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 123, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 123, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 123, chartype: 10, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 123, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 123, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 123, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 123, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 123, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 106, chartype: 11, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 196 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 113, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 113, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 113, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 113, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 113, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 113, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 113, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 113, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 113, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 113, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 113, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 116, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 116, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 116, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 116, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 116, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 116, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 132, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 132, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 132, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 132, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 132, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 132, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 117, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 117, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 117, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 117, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 198 }, ucd_record { script: 117, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 117, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 117, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 117, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 118, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 118, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 118, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 94 }, ucd_record { script: 118, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 96 }, ucd_record { script: 118, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 63, other_case: -6222, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 67, other_case: -6221, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 71, other_case: -6212, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 75, other_case: -6210, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 79, other_case: -6210, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 79, other_case: -6211, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 84, other_case: -6204, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 88, other_case: -6180, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 108, other_case: 35267, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 21, chartype: 9, gbprop: 12, caseset: 0, other_case: -3008, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 116, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26864, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26868, bprops: 98 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18680, bprops: 200 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26876, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26880, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26884, bprops: 98 }, ucd_record { script: 99, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18684, bprops: 174 }, ucd_record { script: 99, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18696, bprops: 84 }, ucd_record { script: 99, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18684, bprops: 84 }, ucd_record { script: 99, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18676, bprops: 84 }, ucd_record { script: 99, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18700, bprops: 84 }, ucd_record { script: 99, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18704, bprops: 84 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26900, bprops: 98 }, ucd_record { script: 99, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18712, bprops: 174 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26896, bprops: 98 }, ucd_record { script: 99, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18716, bprops: 84 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 60 }, ucd_record { script: 1, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 90 }, ucd_record { script: 2, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 182 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 35332, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 3814, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 35384, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 202 }, ucd_record { script: 0, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 182 }, ucd_record { script: 0, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 204 }, ucd_record { script: 1, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 182 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26740, bprops: 104 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26912, bprops: 98 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26916, bprops: 98 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 92, other_case: 1, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 92, other_case: -1, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 92, other_case: -58, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -7615, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 8, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: -8, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 74, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 86, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 100, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 128, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 112, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 126, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 8, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 1, chartype: 8, gbprop: 12, caseset: 0, other_case: -8, scriptx_bidiclass: 18432, bprops: 88 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: 9, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: -74, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 8, gbprop: 12, caseset: 0, other_case: -9, scriptx_bidiclass: 18432, bprops: 88 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 21, other_case: -7173, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: -86, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -7235, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: -100, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 5, gbprop: 12, caseset: 0, other_case: -7219, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: -112, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: -128, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 0, other_case: -126, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 99, chartype: 29, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 45056, bprops: 52 }, ucd_record { script: 106, chartype: 1, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 206 }, ucd_record { script: 106, chartype: 1, gbprop: 13, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 208 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 210 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 210 }, ucd_record { script: 99, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 212 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 64 }, ucd_record { script: 99, chartype: 20, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 214 }, ucd_record { script: 99, chartype: 19, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 214 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 216 }, ucd_record { script: 99, chartype: 20, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 216 }, ucd_record { script: 99, chartype: 19, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 216 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 218 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 220 }, ucd_record { script: 99, chartype: 27, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 45056, bprops: 50 }, ucd_record { script: 99, chartype: 28, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 4096, bprops: 50 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 20480, bprops: 136 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 36864, bprops: 136 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 30720, bprops: 136 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 24576, bprops: 136 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 40960, bprops: 136 }, ucd_record { script: 99, chartype: 29, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8488, bprops: 52 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 54 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 64 }, ucd_record { script: 99, chartype: 21, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 222 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 224 }, ucd_record { script: 99, chartype: 16, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 144 }, ucd_record { script: 99, chartype: 16, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 226 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 64 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 228 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 228 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28972, bprops: 54 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 212 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28976, bprops: 54 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28980, bprops: 54 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 230 }, ucd_record { script: 98, chartype: 2, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 232 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 22528, bprops: 136 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 38912, bprops: 136 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 16384, bprops: 136 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 32768, bprops: 136 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 234 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 12288, bprops: 236 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 12288, bprops: 238 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 236 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 240 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 240 }, ucd_record { script: 98, chartype: 2, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 0 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 242 }, ucd_record { script: 106, chartype: 11, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 124 }, ucd_record { script: 106, chartype: 11, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 244 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26936, bprops: 104 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 99, chartype: 9, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 116 }, ucd_record { script: 99, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 246 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 248 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 250 }, ucd_record { script: 1, chartype: 9, gbprop: 12, caseset: 96, other_case: -7517, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 122 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 100, other_case: 0, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 104, other_case: -8262, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 252 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 28, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 99, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 254 }, ucd_record { script: 99, chartype: 5, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 256 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 122 }, ucd_record { script: 99, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 258 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -28, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 14, gbprop: 12, caseset: 0, other_case: 16, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 14, gbprop: 12, caseset: 0, other_case: -16, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 14, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 99, chartype: 25, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 260 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 260 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 64 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 262 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 264 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 12288, bprops: 266 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 264 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 264 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 268 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 270 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 270 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 54 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 272 }, ucd_record { script: 98, chartype: 2, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 274 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 10240, bprops: 74 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 26, scriptx_bidiclass: 18432, bprops: 276 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 26, scriptx_bidiclass: 18432, bprops: 278 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: -26, scriptx_bidiclass: 18432, bprops: 280 }, ucd_record { script: 99, chartype: 25, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 282 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 284 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 286 }, ucd_record { script: 99, chartype: 25, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 284 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 272 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 288 }, ucd_record { script: 109, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 54 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 228 }, ucd_record { script: 44, chartype: 9, gbprop: 12, caseset: 0, other_case: 48, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 44, chartype: 5, gbprop: 12, caseset: 0, other_case: -48, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -10743, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -3814, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -10727, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -10795, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -10792, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -10780, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -10749, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -10783, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -10782, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -10815, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 43, chartype: 5, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 60 }, ucd_record { script: 43, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 43, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 43, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 128 }, ucd_record { script: 43, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 43, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 21, chartype: 5, gbprop: 12, caseset: 0, other_case: -7264, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 45, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 45, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 148 }, ucd_record { script: 45, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 45, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 290 }, ucd_record { script: 2, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 99, chartype: 20, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 228 }, ucd_record { script: 99, chartype: 19, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 228 }, ucd_record { script: 99, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28988, bprops: 212 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 292 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28992, bprops: 54 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28996, bprops: 54 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29000, bprops: 224 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29004, bprops: 294 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28812, bprops: 54 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 294 }, ucd_record { script: 30, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 296 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29008, bprops: 298 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29008, bprops: 300 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29008, bprops: 302 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29012, bprops: 294 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29016, bprops: 224 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29020, bprops: 54 }, ucd_record { script: 30, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 99, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18784, bprops: 304 }, ucd_record { script: 30, chartype: 14, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 304 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29028, bprops: 228 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29028, bprops: 228 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29032, bprops: 228 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29032, bprops: 228 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29036, bprops: 62 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29036, bprops: 62 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29036, bprops: 228 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29036, bprops: 228 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29020, bprops: 54 }, ucd_record { script: 99, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29020, bprops: 212 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29020, bprops: 216 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29020, bprops: 216 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26992, bprops: 98 }, ucd_record { script: 22, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 306 }, ucd_record { script: 99, chartype: 17, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 29020, bprops: 308 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18804, bprops: 138 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29020, bprops: 74 }, ucd_record { script: 30, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 148 }, ucd_record { script: 99, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18808, bprops: 84 }, ucd_record { script: 99, chartype: 21, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 29048, bprops: 250 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29024, bprops: 74 }, ucd_record { script: 27, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26996, bprops: 98 }, ucd_record { script: 99, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29044, bprops: 310 }, ucd_record { script: 27, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 99, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29044, bprops: 130 }, ucd_record { script: 28, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29036, bprops: 144 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18804, bprops: 96 }, ucd_record { script: 28, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 29, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 22, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 22, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 184 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18784, bprops: 74 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18784, bprops: 74 }, ucd_record { script: 22, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 22, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 18784, bprops: 250 }, ucd_record { script: 28, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 30, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 312 }, ucd_record { script: 31, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 31, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 31, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 55, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 55, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 148 }, ucd_record { script: 55, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 55, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 119, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 119, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 119, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 110 }, ucd_record { script: 119, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 128 }, ucd_record { script: 119, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 2, chartype: 9, gbprop: 12, caseset: 108, other_case: 1, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 2, chartype: 5, gbprop: 12, caseset: 108, other_case: -35267, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 2, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 2, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 2, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 2, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 94 }, ucd_record { script: 2, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 90 }, ucd_record { script: 126, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 126, chartype: 14, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 126, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 126, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 126, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 126, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 99, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29052, bprops: 56 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -35332, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 99, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 56 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42280, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 48, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42308, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42319, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42315, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42305, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42258, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42282, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42261, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 928, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -48, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42307, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -35384, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42343, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: -42561, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 46, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 46, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 46, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 46, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 46, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18816, bprops: 74 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18820, bprops: 74 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18824, bprops: 74 }, ucd_record { script: 99, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14732, bprops: 74 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14728, bprops: 74 }, ucd_record { script: 47, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 47, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 47, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 128 }, ucd_record { script: 120, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 120, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 120, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 120, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 120, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 120, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 8, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 27024, bprops: 98 }, ucd_record { script: 8, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18836, bprops: 84 }, ucd_record { script: 49, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 49, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 49, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 49, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18840, bprops: 200 }, ucd_record { script: 49, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 121, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 121, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 121, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 121, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 121, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 56, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 56, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 56, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 56, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 56, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 56, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 56, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 56, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 99, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18844, bprops: 138 }, ucd_record { script: 56, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 20, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 122, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 122, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 122, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 122, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 122, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 122, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 124, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 124, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 124, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 170 }, ucd_record { script: 124, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 124, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 314 }, ucd_record { script: 124, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 124, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 124, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 127, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 127, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 127, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 127, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 127, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 127, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -928, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 24, chartype: 5, gbprop: 12, caseset: 0, other_case: -38864, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 127, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 174 }, ucd_record { script: 127, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 22, chartype: 7, gbprop: 9, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 22, chartype: 7, gbprop: 10, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 98, chartype: 4, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 0 }, ucd_record { script: 98, chartype: 3, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 0 }, ucd_record { script: 30, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 304 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: 1, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -1, scriptx_bidiclass: 18432, bprops: 70 }, ucd_record { script: 4, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 12288, bprops: 122 }, ucd_record { script: 5, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 316 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29088, bprops: 54 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29088, bprops: 54 }, ucd_record { script: 98, chartype: 2, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 318 }, ucd_record { script: 5, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 420, bprops: 84 }, ucd_record { script: 5, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29092, bprops: 74 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 192 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 320 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 128 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 126 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 99, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 130 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 322 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 322 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 110 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 324 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 326 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 172 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 172 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 74 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 122 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 12288, bprops: 122 }, ucd_record { script: 99, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 12288, bprops: 328 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 330 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 322 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 332 }, ucd_record { script: 99, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 12288, bprops: 130 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 8192, bprops: 74 }, ucd_record { script: 99, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 10240, bprops: 334 }, ucd_record { script: 0, chartype: 9, gbprop: 12, caseset: 0, other_case: 32, scriptx_bidiclass: 18432, bprops: 336 }, ucd_record { script: 99, chartype: 24, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 338 }, ucd_record { script: 0, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 18432, bprops: 340 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29036, bprops: 128 }, ucd_record { script: 99, chartype: 22, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29036, bprops: 342 }, ucd_record { script: 99, chartype: 18, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29036, bprops: 342 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29036, bprops: 110 }, ucd_record { script: 99, chartype: 6, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18804, bprops: 344 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 346 }, ucd_record { script: 39, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18856, bprops: 74 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 29096, bprops: 74 }, ucd_record { script: 99, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18860, bprops: 74 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18864, bprops: 74 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18860, bprops: 74 }, ucd_record { script: 1, chartype: 14, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 84 }, ucd_record { script: 1, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 1, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 1, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 50, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 51, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 27060, bprops: 98 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 10676, bprops: 74 }, ucd_record { script: 104, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 104, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 32, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 32, chartype: 14, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 73, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 73, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 107, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 107, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 111, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 111, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 111, chartype: 14, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 105, chartype: 9, gbprop: 12, caseset: 0, other_case: 40, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 105, chartype: 5, gbprop: 12, caseset: 0, other_case: -40, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 40, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 108, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 108, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 80, chartype: 9, gbprop: 12, caseset: 0, other_case: 40, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 80, chartype: 5, gbprop: 12, caseset: 0, other_case: -40, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 66, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 64, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 64, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 167, chartype: 9, gbprop: 12, caseset: 0, other_case: 39, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 167, chartype: 5, gbprop: 12, caseset: 0, other_case: -39, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 96, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 69, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 0, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 96 }, ucd_record { script: 41, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 128, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 128, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 110 }, ucd_record { script: 128, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 143, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 143, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 143, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 142, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 142, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 149, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 149, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 115, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 115, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 115, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 110 }, ucd_record { script: 52, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 52, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 61, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 134, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 134, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 112, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 112, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 112, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 112, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 112, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 112, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 112, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 128 }, ucd_record { script: 129, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 129, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 129, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 141, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 141, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 71, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 71, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 71, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 71, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 71, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 110 }, ucd_record { script: 71, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 35256, bprops: 110 }, ucd_record { script: 71, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 53, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 53, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 53, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 110 }, ucd_record { script: 130, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 130, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 131, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 131, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 74, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 74, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 110 }, ucd_record { script: 74, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 57, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 78, chartype: 9, gbprop: 12, caseset: 0, other_case: 64, scriptx_bidiclass: 34816, bprops: 76 }, ucd_record { script: 78, chartype: 5, gbprop: 12, caseset: 0, other_case: -64, scriptx_bidiclass: 34816, bprops: 78 }, ucd_record { script: 78, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 85, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 84 }, ucd_record { script: 85, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 314 }, ucd_record { script: 85, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 132 }, ucd_record { script: 85, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 2048, bprops: 144 }, ucd_record { script: 92, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 2048, bprops: 144 }, ucd_record { script: 92, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 92, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 96 }, ucd_record { script: 92, chartype: 9, gbprop: 12, caseset: 0, other_case: 32, scriptx_bidiclass: 34816, bprops: 76 }, ucd_record { script: 92, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 132 }, ucd_record { script: 92, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 164 }, ucd_record { script: 92, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 92, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 130 }, ucd_record { script: 92, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 138 }, ucd_record { script: 92, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 34816, bprops: 78 }, ucd_record { script: 92, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 122 }, ucd_record { script: 5, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 2048, bprops: 74 }, ucd_record { script: 88, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 88, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 88, chartype: 17, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 130 }, ucd_record { script: 159, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 159, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 86, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 84 }, ucd_record { script: 86, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 86, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 74 }, ucd_record { script: 86, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 128 }, ucd_record { script: 90, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 90, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 90, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 128 }, ucd_record { script: 163, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 163, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 160, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 133, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 133, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 133, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 133, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 133, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 133, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 133, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 133, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 133, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 290 }, ucd_record { script: 58, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 58, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 58, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 58, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 58, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 58, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 58, chartype: 1, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 134 }, ucd_record { script: 58, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 136, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 136, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 60, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 60, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 60, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 60, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 60, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 60, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 60, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 70, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 70, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 70, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 62, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 62, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 62, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 62, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 62, chartype: 7, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 62, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 62, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 62, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 62, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 62, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 17, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 68, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 68, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 68, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 68, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 68, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 68, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 162 }, ucd_record { script: 68, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 68, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 68, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 77, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 77, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 75, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 75, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 75, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 75, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 75, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 75, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 67, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 67, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26836, bprops: 106 }, ucd_record { script: 67, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 67, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18644, bprops: 154 }, ucd_record { script: 67, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 106, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26836, bprops: 98 }, ucd_record { script: 67, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26836, bprops: 98 }, ucd_record { script: 67, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 67, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 67, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 348 }, ucd_record { script: 67, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 97, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 97, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 97, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 97, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 97, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 97, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 97, chartype: 7, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 97, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 164 }, ucd_record { script: 97, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 350 }, ucd_record { script: 97, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 97, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 97, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 153, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 153, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 153, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 153, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 153, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 153, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 153, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 153, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 153, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 153, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 76, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 76, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 76, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 76, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 76, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 76, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 76, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 76, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 145, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 145, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 145, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 145, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 145, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 145, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 145, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 145, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 145, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 145, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 190 }, ucd_record { script: 72, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 72, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 72, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 72, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 72, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 72, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 72, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 63, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 63, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 63, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 63, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 63, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 63, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 63, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 147, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 147, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 147, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 147, chartype: 10, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 147, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 147, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 147, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 147, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 147, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 83, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 83, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 83, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 83, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 83, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 83, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 146, chartype: 9, gbprop: 12, caseset: 0, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 146, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 146, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 146, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 146, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 164, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 164, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 160 }, ucd_record { script: 164, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 164, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 164, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 164, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 164, chartype: 7, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 164, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 164, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 164, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 164, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 87, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 87, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 87, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 87, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 87, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 156, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 156, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 156, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 106 }, ucd_record { script: 156, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 156, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 156, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 156, chartype: 7, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 156, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 156, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 155, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 155, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 155, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 155, chartype: 7, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 155, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 352 }, ucd_record { script: 155, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 155, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 155, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 155, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 144, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 95, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 95, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 95, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 151, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 151, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 151, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 151, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 158 }, ucd_record { script: 151, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 151, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 151, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 151, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 151, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 152, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 152, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 152, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 152, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 152, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 82, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 82, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 82, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 82, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 82, chartype: 7, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 82, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 84, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 84, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 84, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 84, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 84, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 157, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 157, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 157, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 157, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 168, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 168, chartype: 7, gbprop: 4, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 168, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 168, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 168, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 188 }, ucd_record { script: 168, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 168, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 168, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 168, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 168, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 13, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 13, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 114, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 114, chartype: 14, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 114, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 89, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 89, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 125, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 125, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 346 }, ucd_record { script: 125, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 125, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 148, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 93, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 93, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 93, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 93, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 158 }, ucd_record { script: 93, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 140, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 140, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 140, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 166, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 166, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 137, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 137, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 137, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 138, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 138, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 138, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 138, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 138, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 138, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 138, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 148 }, ucd_record { script: 138, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 138, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 138, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 170, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 148 }, ucd_record { script: 170, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 170, chartype: 7, gbprop: 7, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 170, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 94 }, ucd_record { script: 170, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 170, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 170, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 158, chartype: 9, gbprop: 12, caseset: 0, other_case: 32, scriptx_bidiclass: 18432, bprops: 76 }, ucd_record { script: 158, chartype: 5, gbprop: 12, caseset: 0, other_case: -32, scriptx_bidiclass: 18432, bprops: 78 }, ucd_record { script: 158, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 158, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 158, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 158, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 135, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 135, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 135, chartype: 10, gbprop: 5, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 154 }, ucd_record { script: 135, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 132 }, ucd_record { script: 135, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 94 }, ucd_record { script: 81, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 154, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 30, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 74 }, ucd_record { script: 165, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 354 }, ucd_record { script: 30, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 356 }, ucd_record { script: 81, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 304 }, ucd_record { script: 165, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 304 }, ucd_record { script: 28, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 94 }, ucd_record { script: 154, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 304 }, ucd_record { script: 65, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 65, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 65, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 65, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 65, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 99, chartype: 1, gbprop: 2, caseset: 0, other_case: 0, scriptx_bidiclass: 6472, bprops: 66 }, ucd_record { script: 99, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 10240, bprops: 144 }, ucd_record { script: 99, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 358 }, ucd_record { script: 99, chartype: 10, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 306 }, ucd_record { script: 1, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 99, chartype: 25, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 360 }, ucd_record { script: 99, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 10240, bprops: 226 }, ucd_record { script: 150, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 150, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 150, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 110 }, ucd_record { script: 150, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 128 }, ucd_record { script: 150, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 44, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 2, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 92 }, ucd_record { script: 161, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 161, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 161, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 148 }, ucd_record { script: 161, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 138 }, ucd_record { script: 161, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 161, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 91, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 91, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 162, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 162, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 162, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 162, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 14336, bprops: 74 }, ucd_record { script: 169, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 169, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 148 }, ucd_record { script: 169, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 104 }, ucd_record { script: 169, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 94, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 84 }, ucd_record { script: 94, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 94, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 164 }, ucd_record { script: 94, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 144 }, ucd_record { script: 94, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 139, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 84 }, ucd_record { script: 139, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 139, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 79, chartype: 9, gbprop: 12, caseset: 0, other_case: 34, scriptx_bidiclass: 34816, bprops: 76 }, ucd_record { script: 79, chartype: 5, gbprop: 12, caseset: 0, other_case: -34, scriptx_bidiclass: 34816, bprops: 78 }, ucd_record { script: 79, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 164 }, ucd_record { script: 79, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 106 }, ucd_record { script: 79, chartype: 12, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 26624, bprops: 98 }, ucd_record { script: 79, chartype: 6, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 148 }, ucd_record { script: 79, chartype: 13, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 144 }, ucd_record { script: 79, chartype: 21, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 34816, bprops: 74 }, ucd_record { script: 99, chartype: 15, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 74 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 74 }, ucd_record { script: 99, chartype: 23, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 74 }, ucd_record { script: 5, chartype: 7, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 0, bprops: 254 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 362 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 364 }, ucd_record { script: 98, chartype: 2, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 366 }, ucd_record { script: 99, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 368 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 370 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 364 }, ucd_record { script: 99, chartype: 26, gbprop: 11, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 372 }, ucd_record { script: 27, chartype: 26, gbprop: 12, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 74 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 18432, bprops: 250 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 18784, bprops: 364 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 374 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 376 }, ucd_record { script: 99, chartype: 24, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 378 }, ucd_record { script: 99, chartype: 26, gbprop: 14, caseset: 0, other_case: 0, scriptx_bidiclass: 28672, bprops: 380 }, ucd_record { script: 99, chartype: 1, gbprop: 3, caseset: 0, other_case: 0, scriptx_bidiclass: 6144, bprops: 382 }]

pub let _pcre2_ucd_stage1_8: [8704]c_ushort = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 41, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 102, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 103, 104, 104, 104, 104, 104, 104, 104, 104, 105, 106, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 122, 123, 124, 125, 119, 120, 121, 126, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 129, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 146, 183, 184, 185, 186, 146, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 146, 199, 200, 201, 202, 202, 202, 202, 202, 202, 202, 203, 204, 202, 205, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 206, 207, 207, 207, 207, 207, 207, 207, 207, 208, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 207, 209, 210, 210, 210, 210, 211, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 212, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 213, 213, 213, 213, 214, 215, 216, 217, 146, 146, 218, 146, 219, 220, 221, 222, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 223, 224, 223, 223, 223, 223, 223, 223, 225, 225, 225, 226, 227, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 228, 229, 230, 231, 232, 232, 233, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 234, 235, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 236, 237, 236, 236, 236, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 146, 248, 249, 250, 251, 252, 253, 254, 255, 256, 256, 256, 256, 257, 258, 146, 146, 146, 146, 146, 146, 146, 146, 259, 146, 260, 261, 262, 146, 146, 263, 146, 146, 146, 264, 146, 265, 146, 146, 146, 266, 267, 268, 269, 270, 270, 270, 270, 270, 271, 272, 273, 270, 274, 275, 270, 270, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 236, 298, 281, 281, 281, 281, 281, 281, 281, 299, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 300, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 301, 101, 302, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 303, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 304, 101, 101, 101, 101, 305, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 129, 129, 129, 129, 306, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 308, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 309, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 310, 311, 312, 313, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 146, 307, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 314, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 314]

pub let _pcre2_ucd_stage2_8: [40320]c_ushort = [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 1, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 25, 26, 27, 26, 8, 13, 28, 28, 28, 28, 28, 28, 29, 29, 29, 29, 30, 29, 29, 29, 29, 29, 29, 29, 31, 29, 29, 29, 29, 29, 29, 29, 15, 13, 16, 32, 33, 34, 35, 35, 35, 35, 35, 35, 36, 36, 37, 37, 38, 36, 36, 36, 36, 36, 36, 36, 39, 36, 36, 36, 36, 36, 36, 36, 15, 27, 16, 27, 0, 40, 40, 40, 40, 40, 41, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 42, 43, 44, 44, 44, 44, 45, 43, 46, 47, 48, 49, 50, 51, 47, 46, 52, 53, 54, 54, 46, 55, 43, 56, 46, 54, 48, 57, 58, 58, 58, 43, 59, 59, 59, 59, 59, 60, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 50, 59, 59, 59, 59, 59, 59, 59, 61, 62, 62, 62, 62, 62, 63, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 50, 62, 62, 62, 62, 62, 62, 62, 64, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 67, 68, 69, 65, 66, 65, 66, 65, 66, 70, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 71, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 72, 65, 66, 65, 66, 65, 66, 73, 74, 75, 65, 66, 65, 66, 76, 65, 66, 77, 77, 65, 66, 70, 78, 79, 80, 65, 66, 77, 81, 82, 83, 84, 65, 66, 85, 86, 83, 87, 88, 89, 65, 66, 65, 66, 65, 66, 90, 65, 66, 90, 70, 70, 65, 66, 90, 65, 66, 91, 91, 65, 66, 65, 66, 92, 65, 66, 70, 93, 65, 66, 70, 94, 93, 93, 93, 93, 95, 96, 97, 98, 99, 100, 101, 102, 103, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 104, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 69, 105, 106, 107, 65, 66, 108, 109, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 110, 70, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 70, 70, 70, 70, 70, 70, 111, 65, 66, 112, 113, 114, 114, 65, 66, 115, 116, 117, 65, 66, 65, 67, 65, 66, 65, 66, 65, 66, 118, 119, 120, 121, 122, 70, 123, 123, 70, 124, 70, 125, 126, 70, 70, 70, 123, 127, 70, 128, 129, 130, 131, 70, 132, 133, 131, 134, 135, 70, 70, 133, 70, 136, 137, 70, 70, 138, 70, 70, 70, 70, 70, 70, 70, 139, 70, 70, 140, 70, 141, 140, 70, 70, 70, 142, 140, 143, 144, 144, 145, 70, 70, 70, 70, 70, 146, 70, 93, 70, 70, 70, 70, 70, 70, 70, 70, 147, 148, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 149, 149, 150, 149, 149, 149, 149, 149, 149, 151, 151, 152, 153, 152, 152, 152, 154, 154, 46, 46, 46, 46, 151, 155, 151, 155, 155, 155, 151, 156, 151, 151, 157, 157, 46, 46, 46, 46, 46, 158, 46, 159, 46, 46, 46, 46, 46, 46, 149, 149, 149, 149, 149, 46, 46, 46, 46, 46, 160, 160, 151, 46, 152, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 174, 177, 176, 178, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 179, 176, 176, 180, 181, 179, 176, 176, 176, 176, 176, 176, 176, 182, 179, 176, 183, 184, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 185, 176, 176, 186, 176, 176, 176, 176, 176, 176, 176, 176, 176, 187, 176, 176, 176, 176, 176, 176, 176, 176, 188, 189, 189, 189, 189, 176, 190, 176, 176, 176, 176, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 191, 192, 193, 192, 193, 194, 195, 192, 193, 196, 196, 197, 198, 198, 198, 199, 200, 196, 196, 196, 196, 201, 46, 202, 203, 204, 204, 204, 196, 205, 196, 206, 206, 207, 208, 209, 208, 208, 210, 208, 208, 211, 212, 213, 208, 214, 208, 208, 208, 215, 216, 196, 217, 208, 208, 218, 208, 208, 219, 208, 208, 220, 221, 221, 221, 222, 223, 224, 223, 223, 225, 223, 223, 226, 227, 228, 223, 229, 223, 223, 223, 230, 231, 232, 233, 223, 223, 234, 223, 223, 235, 223, 223, 236, 237, 237, 238, 239, 240, 241, 242, 242, 243, 244, 245, 192, 193, 192, 193, 192, 193, 192, 193, 192, 193, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 248, 249, 250, 251, 252, 253, 254, 192, 193, 255, 192, 193, 256, 257, 257, 257, 258, 258, 258, 258, 258, 258, 258, 258, 258, 258, 258, 258, 258, 258, 258, 258, 259, 259, 260, 259, 261, 259, 259, 259, 259, 259, 259, 259, 259, 259, 262, 259, 259, 263, 264, 259, 259, 259, 259, 259, 259, 259, 265, 259, 259, 259, 259, 259, 266, 266, 267, 266, 268, 266, 266, 266, 266, 266, 266, 266, 266, 266, 269, 266, 266, 270, 271, 266, 266, 266, 266, 266, 266, 266, 272, 266, 266, 266, 266, 266, 273, 273, 273, 273, 273, 273, 274, 273, 274, 273, 273, 273, 273, 273, 273, 273, 275, 276, 277, 278, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 279, 280, 281, 282, 282, 281, 283, 283, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 284, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 285, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 196, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 286, 196, 196, 287, 288, 288, 288, 288, 288, 289, 290, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 292, 290, 293, 294, 196, 196, 295, 295, 296, 297, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 299, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 298, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 301, 300, 302, 300, 300, 303, 300, 304, 302, 304, 297, 297, 297, 297, 297, 297, 297, 297, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 297, 297, 297, 297, 305, 305, 305, 305, 302, 306, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 307, 307, 307, 307, 307, 308, 309, 309, 310, 311, 311, 312, 313, 314, 315, 315, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 317, 318, 319, 319, 320, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 322, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 323, 323, 323, 323, 323, 323, 323, 323, 324, 325, 325, 316, 326, 327, 316, 316, 316, 316, 316, 316, 316, 328, 328, 328, 328, 328, 328, 328, 328, 328, 328, 311, 329, 329, 314, 321, 321, 324, 321, 321, 330, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 331, 321, 316, 316, 316, 316, 316, 316, 332, 308, 315, 333, 333, 316, 316, 332, 316, 334, 334, 332, 332, 315, 333, 333, 333, 316, 321, 321, 335, 335, 335, 335, 335, 335, 335, 335, 335, 335, 321, 321, 321, 336, 336, 321, 337, 337, 337, 338, 338, 338, 338, 338, 338, 338, 338, 339, 338, 339, 340, 341, 342, 343, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 344, 344, 344, 344, 344, 344, 344, 344, 344, 344, 344, 344, 344, 344, 344, 344, 345, 345, 345, 345, 345, 345, 345, 345, 345, 345, 345, 340, 340, 342, 342, 342, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 346, 347, 347, 347, 347, 347, 347, 347, 347, 347, 347, 347, 346, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 348, 348, 348, 348, 348, 348, 348, 348, 348, 348, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 349, 350, 350, 350, 350, 350, 350, 350, 350, 350, 351, 351, 352, 353, 354, 355, 356, 297, 297, 357, 358, 358, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 359, 360, 360, 361, 361, 362, 360, 360, 360, 360, 360, 360, 360, 360, 360, 362, 360, 360, 360, 362, 360, 360, 360, 360, 363, 297, 297, 364, 364, 364, 364, 364, 364, 365, 366, 364, 366, 364, 364, 364, 366, 366, 297, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 367, 368, 368, 368, 297, 297, 369, 297, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 342, 340, 340, 340, 340, 340, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 370, 321, 321, 321, 321, 321, 321, 340, 307, 307, 340, 340, 340, 340, 340, 316, 333, 333, 333, 333, 333, 333, 333, 333, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 334, 327, 327, 333, 327, 327, 327, 333, 333, 333, 371, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 316, 372, 372, 308, 326, 326, 326, 326, 326, 326, 326, 333, 333, 333, 333, 333, 333, 326, 326, 326, 373, 326, 326, 326, 326, 326, 326, 326, 326, 326, 326, 326, 316, 374, 374, 374, 375, 376, 376, 376, 376, 376, 376, 376, 376, 376, 376, 376, 376, 376, 376, 376, 376, 376, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 377, 374, 375, 378, 376, 375, 375, 375, 374, 374, 374, 374, 374, 374, 374, 374, 375, 375, 375, 375, 379, 375, 375, 376, 380, 381, 176, 176, 374, 374, 374, 377, 377, 377, 377, 377, 377, 377, 377, 376, 376, 374, 374, 382, 383, 384, 384, 384, 384, 384, 384, 384, 384, 384, 384, 385, 386, 376, 376, 376, 376, 376, 376, 377, 377, 377, 377, 377, 377, 377, 377, 387, 388, 389, 389, 196, 387, 387, 387, 387, 387, 387, 387, 387, 196, 196, 387, 387, 196, 196, 387, 387, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 196, 390, 390, 390, 390, 390, 390, 390, 196, 390, 196, 196, 196, 390, 390, 390, 390, 196, 196, 391, 387, 392, 389, 389, 388, 388, 388, 388, 196, 196, 389, 389, 196, 196, 389, 389, 393, 387, 196, 196, 196, 196, 196, 196, 196, 196, 392, 196, 196, 196, 196, 390, 390, 196, 390, 387, 387, 388, 388, 196, 196, 394, 394, 394, 394, 394, 394, 394, 394, 394, 394, 390, 390, 395, 395, 396, 396, 396, 396, 396, 396, 397, 395, 387, 398, 399, 196, 196, 400, 400, 401, 196, 402, 402, 402, 402, 402, 402, 196, 196, 196, 196, 402, 402, 196, 196, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 402, 196, 402, 402, 402, 402, 402, 402, 402, 196, 402, 402, 196, 402, 402, 196, 402, 402, 196, 196, 403, 196, 401, 401, 401, 400, 400, 196, 196, 196, 196, 400, 400, 196, 196, 400, 400, 404, 196, 196, 196, 400, 196, 196, 196, 196, 196, 196, 196, 402, 402, 402, 402, 196, 402, 196, 196, 196, 196, 196, 196, 196, 405, 405, 405, 405, 405, 405, 405, 405, 405, 405, 400, 406, 402, 402, 402, 400, 407, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 408, 408, 409, 196, 410, 410, 410, 410, 410, 410, 410, 410, 410, 196, 410, 410, 410, 196, 410, 410, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 411, 196, 411, 411, 411, 411, 411, 411, 411, 196, 411, 411, 196, 411, 411, 411, 411, 411, 196, 196, 412, 410, 409, 409, 409, 408, 408, 408, 408, 408, 196, 408, 408, 409, 196, 409, 409, 413, 196, 196, 410, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 410, 410, 408, 408, 196, 196, 414, 414, 414, 414, 414, 414, 414, 414, 414, 414, 415, 416, 196, 196, 196, 196, 196, 196, 196, 411, 408, 417, 408, 412, 412, 412, 196, 418, 419, 419, 196, 420, 420, 420, 420, 420, 420, 420, 420, 196, 196, 420, 420, 196, 196, 420, 420, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 421, 196, 421, 421, 421, 421, 421, 421, 421, 196, 421, 421, 196, 421, 421, 421, 421, 421, 196, 196, 422, 420, 423, 418, 419, 418, 418, 418, 418, 196, 196, 419, 419, 196, 196, 419, 419, 424, 196, 196, 196, 196, 196, 196, 196, 425, 418, 423, 196, 196, 196, 196, 421, 421, 196, 421, 420, 420, 418, 418, 196, 196, 426, 426, 426, 426, 426, 426, 426, 426, 426, 426, 427, 421, 428, 428, 428, 428, 428, 428, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 429, 430, 196, 430, 430, 430, 430, 430, 430, 196, 196, 196, 430, 430, 430, 196, 430, 430, 430, 430, 196, 196, 196, 430, 430, 196, 430, 196, 430, 430, 196, 196, 196, 430, 430, 196, 196, 196, 430, 430, 430, 196, 196, 196, 430, 430, 430, 430, 430, 430, 430, 430, 430, 430, 430, 430, 196, 196, 196, 196, 431, 432, 429, 432, 432, 196, 196, 196, 432, 432, 432, 196, 432, 432, 432, 433, 196, 196, 430, 196, 196, 196, 196, 196, 196, 431, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 434, 434, 434, 434, 434, 434, 434, 434, 434, 434, 435, 435, 435, 436, 437, 437, 437, 437, 437, 438, 437, 196, 196, 196, 196, 196, 439, 440, 440, 440, 439, 441, 441, 441, 441, 441, 441, 441, 441, 196, 441, 441, 441, 196, 441, 441, 441, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 196, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 442, 196, 196, 443, 441, 439, 439, 439, 440, 440, 440, 440, 196, 439, 439, 439, 196, 439, 439, 439, 444, 196, 196, 196, 196, 196, 196, 196, 439, 439, 196, 442, 442, 442, 196, 196, 441, 196, 196, 441, 441, 439, 439, 196, 196, 445, 445, 445, 445, 445, 445, 445, 445, 445, 445, 196, 196, 196, 196, 196, 196, 196, 446, 447, 447, 447, 447, 447, 447, 447, 448, 449, 450, 451, 451, 452, 449, 449, 449, 449, 449, 449, 449, 449, 196, 449, 449, 449, 196, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 196, 449, 449, 449, 449, 449, 449, 449, 449, 449, 449, 196, 449, 449, 449, 449, 449, 196, 196, 453, 449, 451, 454, 455, 451, 455, 451, 451, 196, 454, 455, 455, 196, 455, 455, 450, 456, 196, 196, 196, 196, 196, 196, 196, 455, 455, 196, 196, 196, 196, 196, 196, 449, 449, 196, 449, 449, 450, 450, 196, 196, 457, 457, 457, 457, 457, 457, 457, 457, 457, 457, 196, 449, 449, 451, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 458, 458, 459, 459, 460, 460, 460, 460, 460, 460, 460, 460, 460, 196, 460, 460, 460, 196, 460, 460, 460, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 461, 462, 462, 460, 463, 459, 459, 458, 458, 458, 458, 196, 459, 459, 459, 196, 459, 459, 459, 462, 464, 465, 196, 196, 196, 196, 460, 460, 460, 463, 466, 466, 466, 466, 466, 466, 466, 460, 460, 460, 458, 458, 196, 196, 467, 467, 467, 467, 467, 467, 467, 467, 467, 467, 466, 466, 466, 466, 466, 466, 466, 466, 466, 465, 460, 460, 460, 460, 460, 460, 196, 468, 469, 469, 196, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 196, 196, 196, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 470, 196, 470, 470, 470, 470, 470, 470, 470, 470, 470, 196, 470, 196, 196, 470, 470, 470, 470, 470, 470, 470, 196, 196, 196, 471, 196, 196, 196, 196, 472, 469, 469, 468, 468, 468, 196, 468, 196, 469, 469, 469, 469, 469, 469, 469, 472, 196, 196, 196, 196, 196, 196, 473, 473, 473, 473, 473, 473, 473, 473, 473, 473, 196, 196, 469, 469, 474, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 476, 475, 477, 476, 476, 476, 476, 476, 476, 478, 196, 196, 196, 196, 479, 480, 480, 480, 480, 480, 475, 481, 482, 482, 482, 482, 482, 482, 476, 482, 483, 484, 484, 484, 484, 484, 484, 484, 484, 484, 484, 485, 485, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 486, 486, 196, 486, 196, 486, 486, 486, 486, 486, 196, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 196, 486, 196, 486, 486, 486, 486, 486, 486, 486, 486, 486, 486, 487, 486, 488, 487, 487, 487, 487, 487, 487, 489, 487, 487, 486, 196, 196, 490, 490, 490, 490, 490, 196, 491, 196, 492, 492, 492, 492, 492, 487, 493, 196, 494, 494, 494, 494, 494, 494, 494, 494, 494, 494, 196, 196, 486, 486, 486, 486, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 495, 496, 496, 496, 497, 497, 497, 497, 498, 497, 497, 497, 497, 498, 498, 498, 498, 498, 498, 496, 497, 496, 496, 496, 499, 499, 496, 496, 496, 496, 496, 496, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 501, 501, 501, 501, 501, 501, 501, 501, 501, 501, 496, 499, 496, 499, 496, 499, 502, 503, 502, 503, 504, 504, 495, 495, 495, 495, 495, 495, 495, 495, 196, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 495, 196, 196, 196, 196, 505, 505, 505, 505, 505, 505, 506, 505, 506, 505, 505, 505, 505, 505, 507, 505, 505, 508, 508, 509, 497, 499, 499, 495, 495, 495, 495, 495, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 196, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 505, 196, 496, 496, 496, 496, 496, 496, 496, 496, 499, 496, 496, 496, 496, 496, 496, 196, 496, 496, 497, 497, 497, 497, 497, 510, 510, 510, 510, 497, 497, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 512, 512, 513, 513, 513, 513, 514, 513, 513, 513, 513, 513, 515, 512, 516, 516, 514, 514, 513, 513, 511, 517, 517, 517, 517, 517, 517, 517, 517, 517, 517, 518, 518, 519, 519, 519, 519, 511, 511, 511, 511, 511, 511, 514, 514, 513, 513, 511, 511, 511, 511, 513, 513, 513, 511, 512, 520, 520, 511, 511, 512, 512, 520, 520, 520, 520, 520, 511, 511, 511, 513, 513, 513, 513, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 513, 512, 514, 513, 513, 520, 520, 520, 520, 520, 520, 521, 511, 520, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 520, 520, 512, 513, 523, 523, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 524, 196, 524, 196, 196, 196, 196, 196, 524, 196, 196, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 525, 526, 527, 525, 525, 525, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 529, 530, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 196, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 196, 533, 533, 533, 533, 196, 196, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 196, 196, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 196, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 196, 533, 533, 533, 533, 196, 196, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 196, 196, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 196, 196, 534, 534, 534, 535, 536, 537, 536, 536, 536, 536, 537, 537, 538, 538, 538, 538, 538, 538, 538, 538, 538, 539, 539, 539, 539, 539, 539, 539, 539, 539, 539, 539, 196, 196, 196, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 540, 540, 540, 540, 540, 540, 540, 540, 540, 540, 196, 196, 196, 196, 196, 196, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 541, 542, 542, 542, 542, 542, 542, 196, 196, 543, 543, 543, 543, 543, 543, 196, 196, 544, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 546, 547, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 548, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 549, 550, 551, 196, 196, 196, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 552, 553, 553, 553, 554, 554, 554, 552, 552, 552, 552, 552, 552, 552, 552, 196, 196, 196, 196, 196, 196, 196, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 555, 556, 556, 557, 558, 196, 196, 196, 196, 196, 196, 196, 196, 196, 555, 559, 559, 559, 559, 559, 559, 559, 559, 559, 559, 559, 559, 559, 559, 559, 559, 559, 559, 560, 560, 561, 562, 562, 196, 196, 196, 196, 196, 196, 196, 196, 196, 563, 563, 563, 563, 563, 563, 563, 563, 563, 563, 563, 563, 563, 563, 563, 563, 563, 563, 564, 564, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 565, 565, 565, 565, 565, 565, 565, 565, 565, 565, 565, 565, 565, 196, 565, 565, 565, 196, 566, 566, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 568, 568, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 567, 569, 569, 570, 571, 571, 571, 571, 571, 571, 571, 570, 570, 570, 570, 570, 570, 570, 570, 571, 570, 570, 572, 572, 572, 572, 572, 572, 572, 572, 572, 573, 572, 574, 574, 575, 576, 577, 577, 575, 578, 567, 572, 196, 196, 579, 579, 579, 579, 579, 579, 579, 579, 579, 579, 196, 196, 196, 196, 196, 196, 580, 580, 580, 580, 580, 580, 580, 580, 580, 580, 196, 196, 196, 196, 196, 196, 581, 581, 582, 583, 584, 582, 585, 581, 584, 586, 587, 588, 588, 588, 589, 588, 590, 590, 590, 590, 590, 590, 590, 590, 590, 590, 196, 196, 196, 196, 196, 196, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 592, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 196, 196, 196, 196, 196, 196, 196, 591, 591, 591, 591, 591, 593, 593, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 591, 594, 591, 196, 196, 196, 196, 196, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 595, 196, 596, 596, 596, 597, 597, 597, 597, 596, 596, 597, 597, 597, 196, 196, 196, 196, 597, 597, 596, 597, 597, 597, 597, 597, 597, 598, 598, 598, 196, 196, 196, 196, 599, 196, 196, 196, 600, 600, 601, 601, 601, 601, 601, 601, 601, 601, 601, 601, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 602, 196, 196, 602, 602, 602, 602, 602, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 196, 196, 196, 196, 603, 603, 603, 603, 603, 604, 604, 604, 603, 603, 604, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 603, 196, 196, 196, 196, 196, 196, 605, 605, 605, 605, 605, 605, 605, 605, 605, 605, 606, 196, 196, 196, 607, 607, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 608, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 609, 610, 610, 611, 611, 610, 196, 196, 612, 612, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 613, 614, 615, 614, 615, 615, 615, 615, 615, 615, 615, 196, 616, 617, 615, 617, 617, 615, 615, 615, 615, 615, 615, 615, 615, 614, 614, 614, 614, 614, 614, 615, 615, 618, 618, 618, 618, 618, 618, 618, 618, 196, 196, 618, 619, 619, 619, 619, 619, 619, 619, 619, 619, 619, 196, 196, 196, 196, 196, 196, 619, 619, 619, 619, 619, 619, 619, 619, 619, 619, 196, 196, 196, 196, 196, 196, 620, 620, 620, 620, 620, 620, 620, 621, 622, 622, 622, 622, 620, 620, 196, 196, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 623, 624, 624, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 624, 624, 624, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 625, 625, 625, 625, 626, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 627, 628, 629, 625, 625, 625, 625, 625, 629, 625, 629, 626, 626, 626, 626, 625, 629, 630, 627, 627, 627, 627, 627, 627, 627, 627, 196, 631, 631, 632, 632, 632, 632, 632, 632, 632, 632, 632, 632, 631, 631, 633, 634, 631, 631, 633, 635, 635, 635, 635, 635, 635, 635, 635, 635, 635, 628, 628, 628, 628, 628, 628, 628, 628, 628, 635, 635, 635, 635, 635, 635, 635, 635, 635, 631, 631, 631, 636, 636, 637, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 638, 637, 636, 636, 636, 636, 637, 637, 636, 636, 639, 640, 636, 636, 638, 638, 641, 641, 641, 641, 641, 641, 641, 641, 641, 641, 638, 638, 638, 638, 638, 638, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 642, 643, 644, 645, 645, 644, 644, 644, 645, 644, 645, 645, 645, 646, 646, 196, 196, 196, 196, 196, 196, 196, 196, 647, 647, 647, 647, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 648, 649, 649, 649, 649, 649, 649, 649, 649, 650, 650, 650, 650, 650, 650, 650, 650, 649, 649, 651, 652, 196, 196, 196, 653, 653, 654, 654, 654, 655, 655, 655, 655, 655, 655, 655, 655, 655, 655, 196, 196, 196, 648, 648, 648, 656, 656, 656, 656, 656, 656, 656, 656, 656, 656, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 657, 658, 658, 658, 659, 658, 658, 660, 660, 661, 662, 663, 664, 665, 666, 667, 668, 669, 275, 276, 196, 196, 196, 196, 196, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 670, 196, 196, 670, 670, 670, 671, 671, 671, 671, 671, 671, 671, 671, 196, 196, 196, 196, 196, 196, 196, 196, 672, 673, 672, 674, 673, 675, 675, 676, 675, 676, 677, 673, 676, 676, 673, 673, 676, 678, 673, 673, 673, 673, 673, 673, 673, 679, 680, 681, 681, 675, 681, 681, 681, 681, 682, 683, 684, 680, 680, 685, 686, 686, 687, 196, 196, 196, 196, 196, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 256, 256, 256, 256, 256, 688, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 689, 689, 689, 689, 689, 150, 149, 149, 149, 689, 689, 689, 689, 689, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 690, 691, 70, 70, 70, 692, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 693, 70, 70, 70, 70, 70, 70, 70, 694, 70, 70, 70, 70, 695, 695, 695, 695, 695, 695, 695, 695, 695, 696, 695, 695, 695, 696, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 697, 698, 698, 189, 189, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 189, 189, 189, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 624, 176, 176, 176, 699, 176, 700, 176, 176, 176, 176, 176, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 67, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 701, 702, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 69, 69, 69, 69, 703, 704, 70, 70, 705, 70, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 67, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 706, 706, 706, 706, 706, 706, 706, 706, 707, 707, 707, 707, 707, 707, 707, 707, 706, 706, 706, 706, 706, 706, 196, 196, 707, 707, 707, 707, 707, 707, 196, 196, 706, 706, 706, 706, 706, 706, 706, 706, 707, 707, 707, 707, 707, 707, 707, 707, 706, 706, 706, 706, 706, 706, 706, 706, 707, 707, 707, 707, 707, 707, 707, 707, 706, 706, 706, 706, 706, 706, 196, 196, 707, 707, 707, 707, 707, 707, 196, 196, 708, 706, 708, 706, 708, 706, 708, 706, 196, 707, 196, 707, 196, 707, 196, 707, 706, 706, 706, 706, 706, 706, 706, 706, 707, 707, 707, 707, 707, 707, 707, 707, 709, 709, 710, 710, 710, 710, 711, 711, 712, 712, 713, 713, 714, 714, 196, 196, 715, 715, 715, 715, 715, 715, 715, 715, 716, 716, 716, 716, 716, 716, 716, 716, 715, 715, 715, 715, 715, 715, 715, 715, 716, 716, 716, 716, 716, 716, 716, 716, 715, 715, 715, 715, 715, 715, 715, 715, 716, 716, 716, 716, 716, 716, 716, 716, 706, 706, 717, 718, 717, 196, 708, 717, 707, 707, 719, 719, 720, 201, 721, 201, 201, 201, 717, 718, 717, 196, 708, 717, 722, 722, 722, 722, 720, 201, 201, 201, 706, 706, 708, 723, 196, 196, 708, 708, 707, 707, 724, 724, 196, 201, 201, 201, 706, 706, 708, 725, 708, 250, 708, 708, 707, 707, 726, 726, 255, 201, 201, 201, 196, 196, 717, 718, 717, 196, 708, 717, 727, 727, 728, 728, 720, 201, 201, 196, 729, 729, 729, 729, 729, 729, 729, 729, 729, 729, 729, 51, 730, 731, 732, 733, 734, 734, 734, 734, 734, 734, 735, 43, 736, 737, 738, 739, 739, 740, 738, 739, 43, 43, 43, 43, 741, 43, 43, 742, 743, 744, 745, 746, 747, 748, 749, 750, 751, 751, 752, 752, 752, 43, 43, 43, 43, 49, 57, 43, 753, 754, 43, 755, 756, 43, 43, 43, 757, 758, 759, 754, 754, 753, 43, 43, 43, 43, 43, 760, 43, 43, 50, 761, 755, 43, 43, 43, 43, 43, 762, 43, 43, 763, 43, 729, 51, 764, 764, 764, 764, 765, 766, 767, 768, 769, 770, 770, 770, 770, 770, 770, 54, 696, 196, 196, 54, 54, 54, 54, 54, 54, 771, 772, 773, 774, 775, 695, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 771, 772, 773, 774, 775, 196, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 695, 196, 196, 196, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 479, 776, 776, 776, 776, 776, 776, 776, 776, 776, 776, 776, 776, 776, 776, 776, 777, 777, 777, 777, 777, 777, 777, 777, 777, 777, 777, 777, 777, 778, 778, 778, 778, 777, 778, 779, 778, 777, 777, 189, 189, 189, 189, 777, 777, 777, 777, 777, 780, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 781, 781, 782, 781, 781, 781, 781, 782, 781, 781, 783, 782, 782, 782, 783, 783, 782, 782, 782, 783, 781, 782, 781, 781, 784, 782, 782, 782, 782, 782, 781, 781, 781, 781, 785, 781, 782, 781, 786, 781, 782, 787, 788, 789, 782, 782, 790, 783, 782, 782, 791, 782, 783, 792, 792, 792, 792, 793, 781, 781, 783, 783, 782, 782, 794, 794, 794, 794, 794, 782, 783, 783, 795, 795, 781, 794, 781, 781, 796, 510, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 797, 797, 797, 797, 797, 797, 797, 797, 797, 797, 797, 797, 797, 797, 797, 797, 798, 798, 798, 798, 798, 798, 798, 798, 798, 798, 798, 798, 798, 798, 798, 798, 799, 799, 799, 65, 66, 799, 799, 799, 799, 58, 781, 781, 196, 196, 196, 196, 50, 50, 50, 50, 800, 801, 801, 801, 801, 801, 50, 50, 802, 802, 802, 802, 50, 802, 802, 50, 802, 802, 50, 802, 45, 801, 801, 802, 802, 802, 50, 45, 802, 802, 45, 45, 45, 45, 802, 802, 45, 45, 45, 45, 802, 802, 802, 802, 802, 802, 802, 802, 802, 802, 802, 802, 802, 802, 802, 802, 802, 802, 50, 50, 802, 802, 50, 802, 50, 802, 802, 802, 802, 802, 802, 802, 45, 802, 45, 45, 45, 45, 45, 45, 802, 802, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 803, 50, 50, 50, 50, 803, 804, 804, 804, 804, 804, 804, 50, 50, 50, 50, 805, 53, 50, 804, 50, 50, 50, 50, 50, 50, 50, 50, 803, 804, 804, 804, 804, 50, 804, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 50, 50, 50, 50, 50, 804, 50, 804, 50, 50, 50, 50, 50, 50, 804, 50, 50, 50, 50, 50, 804, 804, 804, 804, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 804, 804, 804, 804, 804, 804, 50, 50, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 50, 50, 50, 804, 804, 804, 804, 50, 50, 50, 50, 50, 804, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 50, 50, 804, 50, 804, 804, 50, 804, 50, 50, 50, 50, 804, 804, 804, 804, 804, 804, 804, 804, 804, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 804, 804, 804, 50, 50, 804, 804, 50, 50, 50, 50, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 50, 50, 804, 804, 804, 804, 804, 50, 804, 804, 50, 50, 804, 804, 804, 804, 804, 50, 45, 45, 45, 45, 45, 45, 45, 45, 806, 807, 806, 807, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 808, 808, 45, 45, 45, 45, 50, 50, 45, 45, 45, 45, 45, 45, 47, 809, 810, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 811, 45, 50, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 812, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 811, 45, 45, 45, 45, 45, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 802, 802, 45, 802, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 47, 802, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 50, 50, 50, 50, 50, 50, 802, 45, 45, 45, 45, 45, 45, 808, 808, 808, 808, 47, 47, 47, 808, 47, 47, 808, 45, 45, 45, 45, 47, 47, 47, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 815, 815, 815, 815, 815, 815, 815, 815, 815, 815, 815, 815, 816, 815, 815, 815, 815, 815, 815, 815, 815, 815, 815, 815, 815, 815, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 817, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 802, 802, 45, 45, 45, 45, 45, 45, 45, 45, 47, 47, 45, 45, 802, 802, 802, 802, 802, 802, 802, 802, 801, 50, 45, 45, 45, 45, 802, 802, 802, 802, 801, 50, 45, 45, 45, 45, 802, 802, 45, 45, 802, 802, 45, 45, 45, 802, 802, 802, 802, 802, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 802, 45, 802, 45, 45, 802, 802, 802, 802, 802, 802, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 50, 50, 50, 800, 800, 818, 818, 50, 47, 47, 47, 47, 47, 819, 802, 812, 812, 812, 812, 812, 812, 812, 47, 812, 812, 47, 812, 45, 808, 808, 812, 812, 47, 812, 812, 812, 812, 820, 812, 812, 47, 812, 47, 47, 812, 812, 47, 812, 812, 812, 47, 812, 812, 812, 47, 47, 812, 812, 812, 812, 812, 812, 812, 812, 47, 47, 47, 812, 812, 812, 812, 812, 801, 812, 801, 812, 812, 812, 812, 812, 808, 808, 808, 808, 808, 808, 808, 808, 808, 808, 808, 808, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 47, 801, 819, 819, 801, 812, 47, 47, 812, 47, 812, 812, 812, 812, 819, 819, 821, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 47, 812, 812, 47, 808, 812, 812, 812, 812, 812, 812, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 812, 812, 47, 808, 47, 47, 47, 47, 812, 47, 812, 47, 47, 812, 812, 812, 47, 808, 812, 812, 812, 812, 812, 47, 812, 812, 808, 808, 822, 812, 812, 812, 47, 47, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 808, 808, 812, 812, 812, 812, 812, 808, 808, 812, 812, 47, 812, 812, 812, 812, 812, 808, 47, 812, 47, 812, 47, 808, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 812, 47, 808, 812, 812, 812, 812, 812, 47, 47, 808, 808, 47, 808, 812, 47, 47, 820, 808, 812, 812, 808, 812, 812, 812, 812, 47, 812, 812, 808, 45, 45, 47, 47, 823, 823, 820, 820, 812, 47, 812, 812, 47, 45, 47, 45, 47, 45, 45, 45, 45, 45, 45, 47, 45, 45, 45, 47, 45, 45, 45, 45, 45, 45, 808, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 47, 47, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 47, 45, 45, 47, 45, 45, 45, 45, 808, 45, 808, 45, 45, 45, 45, 808, 808, 808, 45, 808, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 47, 47, 812, 812, 812, 758, 759, 758, 759, 758, 759, 758, 759, 758, 759, 758, 759, 758, 759, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 45, 808, 808, 808, 45, 45, 45, 45, 45, 45, 45, 45, 45, 47, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 808, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 808, 50, 50, 50, 804, 804, 806, 807, 50, 804, 804, 50, 804, 50, 804, 50, 50, 50, 50, 50, 50, 50, 804, 804, 50, 50, 50, 50, 50, 804, 804, 804, 50, 50, 50, 804, 804, 804, 804, 806, 807, 806, 807, 806, 807, 806, 807, 806, 807, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 824, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 800, 800, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 806, 807, 806, 807, 806, 807, 806, 807, 806, 807, 806, 807, 806, 807, 806, 807, 806, 807, 806, 807, 806, 807, 50, 50, 804, 50, 50, 50, 50, 804, 50, 50, 804, 804, 804, 50, 50, 804, 804, 804, 804, 804, 804, 804, 804, 50, 50, 50, 50, 50, 50, 50, 50, 804, 50, 50, 50, 50, 50, 50, 50, 804, 804, 50, 50, 804, 804, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 804, 804, 50, 804, 804, 50, 50, 806, 807, 806, 807, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 50, 50, 804, 804, 50, 50, 806, 807, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 804, 804, 50, 50, 50, 50, 50, 804, 804, 50, 50, 50, 50, 50, 50, 804, 804, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 50, 50, 50, 804, 804, 804, 804, 804, 804, 804, 804, 50, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 804, 50, 50, 50, 50, 50, 50, 50, 804, 50, 50, 50, 50, 804, 804, 804, 50, 50, 50, 50, 50, 50, 804, 804, 804, 50, 50, 50, 50, 50, 50, 50, 50, 804, 804, 804, 804, 50, 50, 50, 50, 50, 45, 45, 45, 45, 45, 47, 47, 47, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 808, 808, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 45, 45, 50, 50, 50, 50, 50, 50, 45, 45, 45, 808, 45, 45, 45, 45, 808, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 813, 813, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 813, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 825, 45, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 826, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 827, 65, 66, 828, 829, 830, 831, 832, 65, 66, 65, 66, 65, 66, 833, 834, 835, 836, 70, 65, 66, 70, 65, 66, 70, 70, 70, 70, 70, 696, 695, 837, 837, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 246, 247, 838, 839, 839, 839, 839, 839, 839, 246, 247, 246, 247, 840, 840, 840, 246, 247, 196, 196, 196, 196, 196, 841, 841, 841, 842, 843, 842, 842, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 844, 196, 844, 196, 196, 196, 196, 196, 844, 196, 196, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 845, 196, 196, 196, 196, 196, 196, 196, 846, 847, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 848, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 196, 196, 196, 196, 196, 196, 196, 196, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 196, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 849, 43, 43, 850, 851, 850, 851, 43, 43, 43, 850, 851, 43, 850, 851, 43, 43, 43, 43, 43, 43, 43, 43, 43, 852, 43, 43, 734, 43, 850, 851, 43, 43, 850, 851, 758, 759, 758, 759, 758, 759, 758, 759, 43, 43, 43, 43, 754, 853, 854, 855, 43, 43, 43, 43, 43, 43, 43, 43, 734, 734, 856, 43, 43, 43, 734, 857, 738, 858, 43, 43, 43, 43, 43, 43, 43, 43, 859, 43, 859, 859, 45, 45, 43, 754, 754, 758, 759, 758, 759, 758, 759, 758, 759, 734, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 813, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 196, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 860, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 861, 861, 862, 862, 861, 861, 861, 861, 861, 861, 861, 861, 861, 861, 863, 863, 729, 864, 865, 866, 781, 867, 868, 869, 870, 871, 872, 873, 874, 875, 874, 875, 876, 877, 45, 878, 876, 877, 876, 877, 876, 877, 876, 877, 879, 880, 881, 881, 45, 869, 869, 869, 869, 869, 869, 869, 869, 869, 882, 882, 882, 882, 883, 883, 884, 885, 885, 885, 885, 885, 781, 886, 869, 869, 869, 887, 888, 889, 890, 890, 196, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 196, 196, 892, 892, 893, 893, 894, 894, 891, 895, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 897, 898, 899, 899, 896, 196, 196, 196, 196, 196, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 196, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 902, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 196, 903, 903, 904, 904, 904, 904, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 890, 196, 196, 196, 196, 196, 196, 196, 196, 196, 861, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 906, 906, 196, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 907, 907, 907, 907, 907, 907, 907, 907, 781, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 905, 906, 906, 906, 510, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 908, 903, 908, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 781, 781, 781, 781, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 903, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 909, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 510, 510, 510, 510, 510, 510, 781, 781, 781, 781, 903, 903, 903, 903, 903, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 781, 781, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 903, 781, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 912, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 911, 196, 196, 196, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 913, 196, 196, 196, 196, 196, 196, 196, 196, 196, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 914, 915, 915, 915, 915, 915, 915, 916, 917, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 919, 920, 921, 921, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 918, 922, 922, 922, 922, 922, 922, 922, 922, 922, 922, 918, 918, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 923, 924, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 925, 281, 283, 283, 283, 926, 849, 849, 849, 849, 849, 849, 849, 849, 927, 927, 926, 928, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 275, 276, 929, 929, 849, 849, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 931, 931, 931, 931, 931, 931, 931, 931, 931, 931, 932, 932, 933, 934, 935, 935, 935, 934, 196, 196, 196, 196, 196, 196, 196, 196, 936, 936, 936, 936, 936, 936, 936, 936, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 151, 151, 151, 151, 151, 151, 151, 151, 151, 46, 46, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 70, 70, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 695, 70, 70, 70, 70, 70, 70, 70, 70, 65, 66, 65, 66, 937, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 151, 938, 938, 65, 66, 939, 70, 93, 65, 66, 65, 66, 940, 70, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 941, 942, 943, 944, 941, 70, 945, 946, 947, 948, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 65, 66, 949, 950, 951, 65, 66, 65, 66, 952, 65, 66, 196, 196, 65, 66, 196, 70, 196, 70, 65, 66, 65, 66, 65, 66, 953, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 695, 695, 695, 65, 66, 93, 149, 149, 70, 93, 93, 93, 93, 93, 954, 954, 955, 954, 954, 954, 956, 954, 954, 954, 954, 955, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 954, 957, 957, 955, 955, 957, 958, 958, 958, 958, 956, 196, 196, 196, 959, 959, 959, 960, 960, 960, 961, 961, 962, 963, 196, 196, 196, 196, 196, 196, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 964, 965, 965, 966, 966, 196, 196, 196, 196, 196, 196, 196, 196, 967, 967, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 968, 967, 967, 967, 967, 967, 967, 967, 967, 967, 967, 967, 967, 967, 967, 967, 967, 969, 970, 196, 196, 196, 196, 196, 196, 196, 196, 971, 971, 972, 972, 972, 972, 972, 972, 972, 972, 972, 972, 196, 196, 196, 196, 196, 196, 378, 378, 378, 378, 378, 378, 378, 378, 378, 378, 378, 378, 378, 378, 378, 378, 378, 973, 376, 974, 376, 376, 376, 376, 385, 385, 385, 376, 385, 376, 376, 374, 975, 975, 975, 975, 975, 975, 975, 975, 975, 975, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 976, 977, 977, 977, 977, 977, 978, 978, 978, 979, 980, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 981, 982, 982, 982, 982, 982, 982, 982, 982, 982, 982, 982, 983, 984, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 985, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 528, 196, 196, 196, 986, 986, 986, 987, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 988, 989, 987, 987, 986, 986, 986, 986, 987, 987, 986, 986, 987, 987, 990, 991, 991, 991, 991, 991, 991, 992, 993, 993, 991, 991, 991, 991, 196, 994, 995, 995, 995, 995, 995, 995, 995, 995, 995, 995, 196, 196, 196, 196, 991, 991, 511, 511, 511, 511, 511, 521, 996, 511, 511, 511, 511, 511, 511, 511, 511, 511, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 511, 511, 511, 511, 511, 196, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 997, 998, 998, 998, 998, 998, 998, 999, 999, 998, 998, 999, 999, 998, 998, 196, 196, 196, 196, 196, 196, 196, 196, 196, 997, 997, 997, 998, 997, 997, 997, 997, 997, 997, 997, 997, 998, 999, 196, 196, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 196, 196, 1001, 1002, 1002, 1002, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 511, 996, 511, 511, 511, 511, 511, 511, 523, 523, 523, 511, 520, 521, 520, 511, 511, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1003, 1004, 1003, 1004, 1004, 1004, 1005, 1005, 1004, 1004, 1005, 1003, 1005, 1005, 1003, 1004, 1006, 1007, 1006, 1007, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1003, 1003, 1008, 1009, 1010, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1012, 1013, 1013, 1012, 1012, 1014, 1014, 1011, 1015, 1015, 1012, 1016, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 533, 533, 533, 533, 533, 533, 196, 196, 533, 533, 533, 533, 533, 533, 196, 196, 533, 533, 533, 533, 533, 533, 196, 196, 196, 196, 196, 196, 196, 196, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 196, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 1017, 70, 70, 70, 70, 70, 70, 70, 938, 149, 149, 149, 149, 70, 70, 70, 70, 70, 256, 70, 70, 70, 149, 46, 46, 196, 196, 196, 196, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1018, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1011, 1012, 1012, 1013, 1012, 1012, 1013, 1012, 1012, 1014, 1019, 1016, 196, 196, 1020, 1020, 1020, 1020, 1020, 1020, 1020, 1020, 1020, 1020, 196, 196, 196, 196, 196, 196, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1021, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 1022, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 531, 196, 196, 196, 196, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 532, 196, 196, 196, 196, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1023, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 910, 910, 1025, 910, 1025, 910, 910, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 910, 1025, 910, 1025, 910, 910, 1025, 1025, 910, 910, 910, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 196, 196, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 703, 703, 703, 703, 703, 1026, 1027, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 292, 292, 292, 292, 292, 196, 196, 196, 196, 196, 305, 300, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 1028, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 297, 305, 305, 305, 305, 305, 297, 305, 297, 305, 305, 297, 305, 305, 297, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 370, 370, 370, 370, 370, 370, 370, 370, 370, 370, 370, 370, 370, 370, 370, 370, 370, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 1029, 1029, 1029, 1029, 1029, 1029, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 1030, 1031, 315, 315, 315, 315, 315, 315, 315, 315, 315, 315, 315, 315, 315, 315, 315, 315, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 340, 340, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 340, 340, 340, 340, 340, 340, 340, 315, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 1032, 321, 321, 1033, 321, 321, 321, 321, 321, 321, 321, 1029, 1029, 312, 1034, 315, 315, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1036, 1037, 1037, 1038, 1039, 1037, 1038, 1038, 1040, 1041, 1037, 196, 196, 196, 196, 196, 196, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 927, 927, 1037, 1042, 1042, 755, 755, 1040, 1041, 1040, 1041, 1040, 1041, 1040, 1041, 1040, 1041, 1040, 1041, 1043, 1044, 1043, 1044, 866, 866, 1040, 1041, 1037, 1037, 1037, 1037, 755, 755, 755, 1045, 199, 1046, 196, 199, 1047, 1038, 1038, 1042, 1048, 1049, 1048, 1049, 1048, 1049, 1050, 1037, 1051, 1052, 1053, 1054, 1054, 794, 196, 1051, 479, 1050, 1037, 196, 196, 196, 196, 1029, 321, 1029, 321, 1029, 340, 1029, 321, 1029, 321, 1029, 321, 1029, 321, 1029, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 321, 340, 340, 51, 196, 1038, 1055, 1050, 479, 1050, 1037, 1056, 1048, 1049, 1037, 1052, 1045, 1057, 1046, 1058, 1059, 1059, 1059, 1059, 1059, 1059, 1059, 1059, 1059, 1059, 1047, 199, 1054, 794, 1054, 1038, 1037, 1060, 1060, 1060, 1060, 1060, 1060, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 1048, 1051, 1049, 1061, 755, 46, 1062, 1062, 1062, 1062, 1062, 1062, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 1048, 794, 1049, 794, 1048, 1049, 1063, 1064, 1065, 1066, 897, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 898, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 896, 1067, 1067, 902, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 901, 196, 196, 196, 901, 901, 901, 901, 901, 901, 196, 196, 901, 901, 901, 901, 901, 901, 196, 196, 901, 901, 901, 901, 901, 901, 196, 196, 901, 901, 901, 196, 196, 196, 479, 479, 794, 46, 781, 479, 479, 196, 781, 794, 794, 794, 794, 781, 781, 196, 765, 765, 765, 765, 765, 765, 765, 765, 765, 1068, 1068, 1068, 781, 781, 1032, 1032, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 196, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 196, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 196, 1069, 1069, 196, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 196, 196, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 1069, 196, 196, 196, 196, 196, 1070, 1071, 1072, 196, 196, 196, 196, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 1073, 196, 196, 196, 1074, 1074, 1074, 1074, 1074, 1074, 1074, 1074, 1074, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1075, 1076, 1076, 1076, 1076, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1076, 1076, 1077, 1078, 1078, 196, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 196, 196, 196, 1077, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 189, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 1079, 196, 196, 196, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 1080, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1081, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 1082, 196, 196, 196, 196, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1083, 1084, 1084, 1084, 1084, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1083, 1083, 1083, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1086, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1085, 1086, 196, 196, 196, 196, 196, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1087, 1088, 1088, 1088, 1088, 1088, 196, 196, 196, 196, 196, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 1089, 196, 1090, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 196, 196, 196, 196, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1091, 1092, 1093, 1093, 1093, 1093, 1093, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1094, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1095, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1096, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 1097, 196, 196, 1098, 1098, 1098, 1098, 1098, 1098, 1098, 1098, 1098, 1098, 196, 196, 196, 196, 196, 196, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 1099, 196, 196, 196, 196, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 196, 196, 196, 196, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 1101, 196, 196, 196, 196, 196, 196, 196, 196, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 1102, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1103, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 196, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 196, 1104, 1104, 1104, 1104, 1104, 1104, 1104, 196, 1104, 1104, 196, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 196, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 196, 1105, 1105, 1105, 1105, 1105, 1105, 1105, 196, 1105, 1105, 196, 196, 196, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 1106, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 1107, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 149, 1108, 1108, 149, 149, 149, 196, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 149, 196, 149, 149, 149, 149, 149, 149, 149, 149, 149, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1109, 1109, 1109, 1109, 1109, 1109, 297, 297, 1109, 297, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 1109, 297, 1109, 1109, 297, 297, 297, 1109, 297, 297, 1109, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 1110, 297, 1111, 1112, 1112, 1112, 1112, 1112, 1112, 1112, 1112, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1113, 1114, 1114, 1115, 1115, 1115, 1115, 1115, 1115, 1115, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 1116, 297, 297, 297, 297, 297, 297, 297, 297, 1117, 1117, 1117, 1117, 1117, 1117, 1117, 1117, 1117, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 1118, 297, 1118, 1118, 297, 297, 297, 297, 297, 1119, 1119, 1119, 1119, 1119, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1120, 1121, 1121, 1121, 1121, 1121, 1121, 297, 297, 297, 1122, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 1123, 297, 297, 297, 297, 297, 1124, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1125, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 1126, 297, 297, 297, 297, 1127, 1127, 1126, 1126, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 297, 297, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1127, 1128, 1129, 1129, 1129, 297, 1129, 1129, 297, 297, 297, 297, 297, 1129, 1129, 1129, 1129, 1128, 1128, 1128, 1128, 297, 1128, 1128, 1128, 297, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 1128, 297, 297, 1130, 1130, 1130, 297, 297, 297, 297, 1131, 1132, 1132, 1132, 1132, 1132, 1132, 1132, 1132, 1132, 297, 297, 297, 297, 297, 297, 297, 1133, 1133, 1133, 1133, 1133, 1133, 1134, 1134, 1133, 297, 297, 297, 297, 297, 297, 297, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1135, 1136, 1136, 1137, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1138, 1139, 1139, 1139, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1141, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1140, 1142, 1142, 297, 297, 297, 297, 1143, 1143, 1143, 1143, 1143, 1144, 1144, 1145, 1144, 1144, 1144, 1146, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 1147, 297, 297, 297, 1148, 1149, 1149, 1149, 1149, 1149, 1149, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 1150, 297, 297, 1151, 1151, 1151, 1151, 1151, 1151, 1151, 1151, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 1152, 297, 297, 297, 297, 297, 1153, 1153, 1153, 1153, 1153, 1153, 1153, 1153, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 1154, 297, 297, 297, 297, 297, 297, 297, 1155, 1155, 1155, 1155, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1156, 1156, 1156, 1156, 1156, 1156, 1156, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 1157, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 1158, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 1159, 297, 297, 297, 297, 297, 297, 297, 1160, 1160, 1160, 1160, 1160, 1160, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1161, 1162, 1162, 1163, 1163, 1163, 1163, 340, 340, 340, 340, 340, 340, 340, 340, 1164, 1164, 1164, 1164, 1164, 1164, 1164, 1164, 1164, 1164, 340, 340, 340, 340, 340, 340, 1165, 1165, 1165, 1165, 1165, 1165, 1165, 1165, 1165, 1165, 1166, 1166, 1166, 1166, 1167, 1166, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 1168, 297, 297, 297, 1169, 1170, 1171, 1171, 1171, 1172, 1173, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 1174, 297, 297, 297, 297, 297, 297, 297, 297, 1175, 1175, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 1176, 297, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 1177, 297, 1178, 1178, 1179, 297, 297, 1177, 1177, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 340, 340, 321, 321, 321, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 316, 333, 333, 333, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1180, 1181, 1181, 1181, 1181, 1181, 1181, 1181, 1181, 1181, 1181, 1180, 297, 297, 297, 297, 297, 297, 297, 297, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1182, 1183, 1183, 1183, 1183, 1183, 1183, 1183, 1183, 1183, 1183, 1183, 1184, 1184, 1184, 1184, 1185, 1185, 1185, 1185, 1185, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1186, 1187, 1187, 1187, 1187, 1188, 1188, 1188, 1188, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1189, 1190, 1190, 1190, 1190, 1190, 1190, 1190, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 1191, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1192, 1193, 1192, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1194, 1193, 1193, 1193, 1193, 1193, 1193, 1193, 1193, 1193, 1193, 1193, 1193, 1193, 1193, 1195, 1196, 1196, 1197, 1197, 1197, 1197, 1197, 196, 196, 196, 196, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1198, 1199, 1199, 1199, 1199, 1199, 1199, 1199, 1199, 1199, 1199, 1195, 1194, 1194, 1193, 1193, 1194, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1200, 1201, 1201, 1202, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1203, 1202, 1202, 1202, 1201, 1201, 1201, 1201, 1202, 1202, 1204, 1205, 1206, 1206, 1207, 1208, 1208, 1208, 1208, 1201, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1207, 196, 196, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 1209, 196, 196, 196, 196, 196, 196, 196, 1210, 1210, 1210, 1210, 1210, 1210, 1210, 1210, 1210, 1210, 196, 196, 196, 196, 196, 196, 1211, 1211, 1211, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1212, 1211, 1211, 1211, 1211, 1211, 1213, 1211, 1211, 1211, 1211, 1211, 1211, 1214, 1214, 196, 1215, 1215, 1215, 1215, 1215, 1215, 1215, 1215, 1215, 1215, 1216, 1217, 1217, 1217, 1212, 1213, 1213, 1212, 196, 196, 196, 196, 196, 196, 196, 196, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1218, 1219, 1220, 1220, 1218, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1221, 1221, 1222, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1223, 1222, 1222, 1222, 1221, 1221, 1221, 1221, 1221, 1221, 1221, 1221, 1221, 1222, 1224, 1223, 1225, 1225, 1223, 1226, 1226, 1227, 1227, 1228, 1229, 1229, 1229, 1226, 1222, 1221, 1230, 1230, 1230, 1230, 1230, 1230, 1230, 1230, 1230, 1230, 1223, 1227, 1223, 1227, 1226, 1226, 196, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 1231, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 196, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1232, 1233, 1233, 1233, 1234, 1234, 1234, 1233, 1233, 1234, 1235, 1236, 1237, 1238, 1238, 1239, 1238, 1238, 1240, 1234, 1232, 1232, 1234, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 196, 1241, 196, 1241, 1241, 1241, 1241, 196, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 196, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1241, 1242, 196, 196, 196, 196, 196, 196, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1243, 1244, 1245, 1245, 1245, 1244, 1244, 1244, 1244, 1244, 1244, 1246, 1247, 196, 196, 196, 196, 196, 1248, 1248, 1248, 1248, 1248, 1248, 1248, 1248, 1248, 1248, 196, 196, 196, 196, 196, 196, 1249, 1250, 1251, 1252, 196, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 196, 196, 1253, 1253, 196, 196, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 196, 1253, 1253, 1253, 1253, 1253, 1253, 1253, 196, 1253, 1253, 196, 1253, 1253, 1253, 1253, 1253, 196, 1254, 1255, 1253, 1256, 1251, 1249, 1251, 1251, 1251, 1251, 196, 196, 1251, 1251, 196, 196, 1251, 1251, 1257, 196, 196, 1253, 196, 196, 196, 196, 196, 196, 1256, 196, 196, 196, 196, 196, 1258, 1253, 1253, 1253, 1253, 1251, 1251, 196, 196, 1259, 1259, 1259, 1259, 1259, 1259, 1259, 196, 196, 196, 1259, 1259, 1259, 1259, 1259, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 196, 1260, 196, 196, 1260, 196, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 1260, 196, 1260, 1261, 1262, 1262, 1263, 1263, 1263, 1263, 1263, 1263, 196, 1261, 196, 196, 1261, 196, 1261, 1261, 1261, 1262, 196, 1262, 1262, 1264, 1265, 1264, 1266, 1267, 1268, 1269, 1269, 196, 1270, 1270, 196, 196, 196, 196, 196, 196, 196, 196, 1271, 1271, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1272, 1273, 1273, 1273, 1274, 1274, 1274, 1274, 1274, 1274, 1274, 1274, 1273, 1273, 1275, 1274, 1274, 1273, 1276, 1272, 1272, 1272, 1272, 1277, 1277, 1278, 1279, 1279, 1280, 1280, 1280, 1280, 1280, 1280, 1280, 1280, 1280, 1280, 1278, 1278, 196, 1279, 1281, 1272, 1272, 1272, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1282, 1283, 1284, 1284, 1285, 1285, 1285, 1285, 1285, 1285, 1284, 1285, 1284, 1284, 1283, 1284, 1285, 1285, 1284, 1286, 1287, 1282, 1282, 1288, 1282, 196, 196, 196, 196, 196, 196, 196, 196, 1289, 1289, 1289, 1289, 1289, 1289, 1289, 1289, 1289, 1289, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1290, 1291, 1292, 1292, 1293, 1293, 1293, 1293, 196, 196, 1292, 1292, 1292, 1292, 1293, 1293, 1292, 1294, 1295, 1296, 1297, 1297, 1298, 1298, 1299, 1299, 1299, 1297, 1297, 1297, 1297, 1297, 1297, 1297, 1297, 1297, 1297, 1297, 1297, 1297, 1297, 1297, 1290, 1290, 1290, 1290, 1293, 1293, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1301, 1301, 1301, 1302, 1302, 1302, 1302, 1302, 1302, 1302, 1302, 1301, 1301, 1302, 1301, 1303, 1302, 1304, 1304, 1305, 1300, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1306, 1306, 1306, 1306, 1306, 1306, 1306, 1306, 1306, 1306, 196, 196, 196, 196, 196, 196, 581, 581, 581, 581, 581, 581, 581, 581, 581, 581, 581, 581, 581, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1307, 1308, 1309, 1308, 1309, 1309, 1308, 1308, 1308, 1308, 1308, 1308, 1310, 1311, 1307, 1312, 196, 196, 196, 196, 196, 196, 1313, 1313, 1313, 1313, 1313, 1313, 1313, 1313, 1313, 1313, 196, 196, 196, 196, 196, 196, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 522, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 196, 196, 1315, 1316, 1315, 1317, 1317, 1315, 1315, 1315, 1315, 1316, 1315, 1315, 1315, 1315, 1318, 196, 196, 196, 196, 1319, 1319, 1319, 1319, 1319, 1319, 1319, 1319, 1319, 1319, 1320, 1320, 1321, 1321, 1321, 1322, 1314, 1314, 1314, 1314, 1314, 1314, 1314, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1323, 1324, 1324, 1324, 1325, 1325, 1325, 1325, 1325, 1325, 1325, 1325, 1325, 1324, 1326, 1327, 1328, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1329, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1330, 1331, 1331, 1331, 1331, 1331, 1331, 1331, 1331, 1331, 1331, 1332, 1332, 1332, 1332, 1332, 1332, 1332, 1332, 1332, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1333, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 196, 196, 1334, 196, 196, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 196, 1334, 1334, 196, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1334, 1335, 1336, 1336, 1336, 1336, 1336, 196, 1336, 1336, 196, 196, 1337, 1337, 1338, 1339, 1340, 1336, 1340, 1336, 1341, 1342, 1343, 1342, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1344, 1344, 1344, 1344, 1344, 1344, 1344, 1344, 1344, 1344, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 196, 196, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1345, 1346, 1346, 1346, 1347, 1347, 1347, 1347, 196, 196, 1347, 1347, 1346, 1346, 1346, 1346, 1348, 1345, 1349, 1345, 1346, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1350, 1351, 1351, 1351, 1351, 1351, 1351, 1352, 1352, 1351, 1351, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1350, 1353, 1354, 1351, 1351, 1351, 1351, 1355, 1356, 1351, 1351, 1351, 1351, 1357, 1357, 1357, 1358, 1358, 1357, 1357, 1357, 1354, 196, 196, 196, 196, 196, 196, 196, 196, 1359, 1360, 1360, 1360, 1360, 1360, 1360, 1361, 1361, 1360, 1360, 1360, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1359, 1362, 1362, 1362, 1362, 1362, 1362, 1360, 1360, 1360, 1360, 1360, 1360, 1360, 1360, 1360, 1360, 1360, 1360, 1360, 1361, 1363, 1364, 1365, 1366, 1366, 1359, 1365, 1365, 1365, 1367, 1367, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 545, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 1368, 196, 196, 196, 196, 196, 196, 196, 385, 385, 385, 385, 385, 385, 385, 385, 385, 385, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1369, 1370, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1371, 1371, 1371, 1371, 1371, 1371, 1371, 1371, 1371, 1371, 196, 196, 196, 196, 196, 196, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 196, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1372, 1373, 1374, 1374, 1374, 1374, 1374, 1374, 1374, 196, 1374, 1374, 1374, 1374, 1374, 1374, 1373, 1375, 1372, 1376, 1376, 1377, 1378, 1378, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1379, 1379, 1379, 1379, 1379, 1379, 1379, 1379, 1379, 1379, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 1380, 196, 196, 196, 1381, 1382, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 1383, 196, 196, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 196, 1385, 1384, 1384, 1384, 1384, 1384, 1384, 1384, 1385, 1384, 1384, 1385, 1384, 1384, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 196, 1386, 1386, 196, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1386, 1387, 1387, 1387, 1387, 1387, 1387, 196, 196, 196, 1387, 196, 1387, 1387, 196, 1387, 1387, 1387, 1388, 1387, 1389, 1389, 1390, 1387, 196, 196, 196, 196, 196, 196, 196, 196, 1391, 1391, 1391, 1391, 1391, 1391, 1391, 1391, 1391, 1391, 196, 196, 196, 196, 196, 196, 1392, 1392, 1392, 1392, 1392, 1392, 196, 1392, 1392, 196, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1392, 1393, 1393, 1393, 1393, 1393, 196, 1394, 1394, 196, 1393, 1393, 1394, 1393, 1395, 1392, 196, 196, 196, 196, 196, 196, 196, 1396, 1396, 1396, 1396, 1396, 1396, 1396, 1396, 1396, 1396, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1397, 1398, 1398, 1399, 1399, 1400, 1400, 196, 196, 196, 196, 196, 196, 196, 1401, 1401, 1402, 1403, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 196, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1404, 1403, 1403, 1401, 1401, 1401, 1401, 1401, 196, 196, 196, 1403, 1403, 1401, 1405, 1406, 1407, 1407, 1408, 1408, 1408, 1408, 1408, 1408, 1408, 1408, 1408, 1408, 1408, 1409, 1409, 1409, 1409, 1409, 1409, 1409, 1409, 1409, 1409, 1410, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 914, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 1411, 435, 435, 1411, 435, 1411, 437, 437, 437, 437, 437, 437, 437, 437, 438, 438, 438, 438, 437, 437, 437, 437, 437, 437, 437, 437, 437, 437, 437, 437, 437, 437, 437, 437, 437, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1412, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 1414, 196, 1415, 1415, 1415, 1415, 1415, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 1413, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1416, 1417, 1417, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1419, 1420, 1418, 1418, 1418, 1418, 1418, 1418, 1421, 1421, 1421, 1421, 1421, 1421, 1421, 1421, 1421, 1421, 1421, 1421, 1421, 1421, 1421, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 1418, 196, 196, 196, 196, 196, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 1422, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1423, 1424, 1424, 1424, 1424, 1424, 1424, 1424, 1424, 1424, 1424, 1424, 1424, 1425, 1425, 1425, 1424, 1424, 1426, 1427, 1427, 1427, 1427, 1427, 1427, 1427, 1427, 1427, 1427, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 930, 196, 196, 196, 196, 196, 196, 196, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 1428, 196, 1429, 1429, 1429, 1429, 1429, 1429, 1429, 1429, 1429, 1429, 196, 196, 196, 196, 1430, 1430, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 1431, 196, 1432, 1432, 1432, 1432, 1432, 1432, 1432, 1432, 1432, 1432, 196, 196, 196, 196, 196, 196, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 1433, 196, 196, 1434, 1434, 1434, 1434, 1434, 1435, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1437, 1437, 1437, 1437, 1437, 1437, 1437, 1438, 1438, 1439, 1440, 1440, 1441, 1441, 1441, 1441, 1442, 1442, 1443, 1443, 1438, 1441, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1444, 1444, 1444, 1444, 1444, 1444, 1444, 1444, 1444, 1444, 196, 1445, 1445, 1445, 1445, 1445, 1445, 1445, 196, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 196, 196, 196, 196, 196, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 1436, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1446, 1446, 1446, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1447, 1448, 1447, 1447, 1447, 1448, 1448, 1448, 1448, 1449, 1449, 1450, 1451, 1451, 1452, 1452, 1452, 1452, 1452, 1452, 1452, 1452, 1452, 1452, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1453, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1454, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1455, 1456, 1457, 1458, 1458, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 1459, 196, 196, 196, 196, 1460, 1459, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 1461, 196, 196, 196, 196, 196, 196, 196, 1462, 1462, 1462, 1462, 1463, 1463, 1463, 1463, 1463, 1463, 1463, 1463, 1463, 1463, 1463, 1463, 1463, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1464, 1465, 1466, 867, 1467, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1468, 1468, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 196, 196, 196, 196, 196, 196, 196, 196, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 1470, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1470, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 1469, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1471, 1471, 1471, 1471, 196, 1471, 1471, 1471, 1471, 1471, 1471, 1471, 196, 1471, 1471, 196, 896, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 891, 896, 896, 896, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 891, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 891, 891, 891, 196, 196, 896, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 896, 896, 896, 896, 196, 196, 196, 196, 196, 196, 196, 196, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 1472, 196, 196, 196, 196, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 196, 196, 196, 196, 196, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 196, 196, 196, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 196, 196, 196, 196, 196, 196, 196, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 1473, 196, 196, 1474, 1475, 1476, 1477, 1478, 1478, 1478, 1478, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 1479, 1479, 1479, 1479, 1479, 1479, 1479, 1479, 1479, 1479, 196, 196, 196, 196, 196, 196, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 196, 196, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 196, 196, 196, 196, 196, 196, 196, 196, 196, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 196, 196, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 1480, 1480, 176, 176, 176, 510, 510, 510, 1481, 1481, 1481, 1481, 1481, 1481, 51, 51, 51, 51, 51, 51, 51, 51, 176, 176, 176, 176, 176, 176, 176, 176, 510, 510, 176, 176, 176, 176, 176, 176, 176, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 176, 176, 176, 176, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 781, 781, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1077, 1482, 1482, 1482, 1077, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 907, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 196, 196, 196, 196, 196, 196, 196, 196, 196, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 904, 907, 907, 907, 907, 907, 907, 907, 196, 196, 196, 196, 196, 196, 196, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 196, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 196, 782, 782, 196, 196, 782, 196, 196, 782, 782, 196, 196, 782, 782, 782, 782, 196, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 196, 783, 196, 783, 795, 795, 783, 783, 783, 783, 196, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 196, 782, 782, 782, 782, 196, 196, 782, 782, 782, 782, 782, 782, 782, 782, 196, 782, 782, 782, 782, 782, 782, 782, 196, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 196, 782, 782, 782, 782, 196, 782, 782, 782, 782, 782, 196, 782, 196, 196, 196, 782, 782, 782, 782, 782, 782, 782, 196, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 783, 783, 783, 783, 783, 783, 783, 783, 795, 795, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 196, 196, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 1483, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 1483, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 1483, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 1483, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 1483, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 1483, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 1483, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 1483, 783, 783, 783, 783, 783, 783, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 782, 1483, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 783, 1483, 783, 783, 783, 783, 783, 783, 782, 783, 196, 196, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1484, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1485, 1485, 1485, 1485, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1486, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1485, 1486, 1485, 1485, 1487, 1488, 1487, 1487, 1489, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1486, 1486, 1486, 1486, 1486, 196, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 1486, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 93, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 694, 70, 70, 70, 70, 196, 196, 196, 196, 196, 196, 70, 70, 70, 70, 70, 70, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 196, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 196, 196, 1490, 1490, 1490, 1490, 1490, 1490, 1490, 196, 1490, 1490, 196, 1490, 1490, 1490, 1490, 1490, 196, 196, 196, 196, 196, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 1491, 1491, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 929, 1491, 929, 929, 929, 929, 929, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 849, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 1492, 196, 196, 196, 1493, 1493, 1493, 1493, 1493, 1493, 1493, 1494, 1494, 1494, 1494, 1494, 1495, 1495, 196, 196, 1496, 1496, 1496, 1496, 1496, 1496, 1496, 1496, 1496, 1496, 196, 196, 196, 196, 1492, 1497, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1498, 1499, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1501, 1501, 1501, 1501, 1502, 1502, 1502, 1502, 1502, 1502, 1502, 1502, 1502, 1502, 196, 196, 196, 196, 196, 1503, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1504, 1505, 1506, 1506, 1506, 1506, 1507, 1507, 1507, 1507, 1507, 1507, 1507, 1507, 1507, 1507, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1508, 1509, 1510, 1508, 1511, 1511, 1511, 1511, 1511, 1511, 1511, 1511, 1511, 1511, 196, 196, 196, 196, 1512, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 533, 533, 533, 533, 533, 533, 533, 196, 533, 533, 533, 533, 196, 533, 533, 196, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 533, 196, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 1513, 297, 297, 1514, 1514, 1514, 1514, 1514, 1514, 1514, 1514, 1514, 1515, 1515, 1515, 1515, 1515, 1515, 1515, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1516, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1517, 1518, 1518, 1518, 1519, 1520, 1520, 1520, 1521, 297, 297, 297, 297, 1522, 1522, 1522, 1522, 1522, 1522, 1522, 1522, 1522, 1522, 297, 297, 297, 297, 1523, 1523, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 340, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1525, 1524, 1524, 1524, 1526, 1524, 1524, 1524, 1524, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 340, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1525, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 1524, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 297, 1527, 1527, 1527, 1527, 340, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 340, 1527, 1527, 340, 1527, 340, 340, 1527, 340, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 340, 1527, 1527, 1527, 1527, 340, 1527, 340, 1527, 340, 340, 340, 340, 340, 340, 1527, 340, 340, 340, 340, 1527, 340, 1527, 340, 1527, 340, 1527, 1527, 1527, 340, 1527, 1527, 340, 1527, 340, 340, 1527, 340, 1527, 340, 1527, 340, 1527, 340, 1527, 340, 1527, 1527, 340, 1527, 340, 340, 1527, 1527, 1527, 1527, 340, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 340, 1527, 1527, 1527, 1527, 340, 1527, 1527, 1527, 1527, 340, 1527, 340, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 340, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 340, 340, 340, 340, 340, 1527, 1527, 1527, 340, 1527, 1527, 1527, 1527, 1527, 340, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 1527, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 309, 309, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 340, 1528, 1528, 1528, 1528, 1529, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1530, 1530, 1530, 1530, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1530, 1530, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1530, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1529, 1530, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 814, 58, 58, 1528, 1528, 1528, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 1528, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 510, 510, 510, 510, 510, 510, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 781, 781, 1528, 1528, 1528, 1528, 1532, 1532, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1532, 1532, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 1531, 510, 510, 510, 510, 1533, 510, 510, 1533, 1533, 1533, 1533, 1533, 1533, 1533, 1533, 1533, 1533, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 1528, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1534, 1535, 1533, 1536, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 1533, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 510, 1533, 510, 510, 1533, 1533, 1533, 1533, 1533, 1536, 1533, 1533, 1533, 510, 1530, 1530, 1530, 1530, 510, 510, 510, 510, 510, 510, 510, 510, 510, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1537, 1537, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1528, 1528, 1528, 1528, 1528, 1528, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 785, 1528, 1528, 785, 785, 785, 785, 785, 785, 785, 785, 785, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 785, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 785, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1528, 1528, 785, 785, 1528, 785, 785, 785, 1528, 1528, 785, 785, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1538, 1538, 1529, 1529, 1538, 1529, 1529, 1538, 1539, 1539, 785, 785, 1529, 1529, 1529, 1529, 1529, 785, 785, 785, 785, 785, 785, 785, 785, 785, 785, 785, 785, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1528, 1528, 785, 1529, 785, 1528, 785, 1529, 1529, 1529, 1540, 1540, 1540, 1540, 1540, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 785, 1529, 785, 1538, 1538, 1529, 1529, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1529, 1529, 1529, 1538, 1529, 1529, 1529, 1529, 1538, 1538, 1538, 1529, 1538, 1538, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1529, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 785, 1528, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 781, 781, 781, 781, 781, 781, 781, 781, 1528, 1528, 1528, 785, 785, 1529, 1529, 1529, 1529, 1528, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 785, 785, 1528, 1528, 785, 1539, 1539, 785, 785, 785, 785, 1538, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 785, 1528, 1528, 785, 785, 785, 785, 1528, 1528, 1539, 1528, 1528, 1528, 1528, 1538, 1538, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1529, 785, 1528, 1528, 785, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 785, 785, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 785, 1528, 1528, 1528, 1528, 1528, 785, 785, 785, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 785, 785, 785, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 785, 785, 785, 1528, 1528, 785, 1528, 785, 1528, 1528, 1528, 1528, 785, 1528, 1528, 1528, 1528, 1528, 1528, 785, 1528, 1528, 1528, 785, 1528, 1528, 1528, 1528, 1528, 1528, 785, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1538, 1538, 1529, 1529, 1529, 1538, 1538, 1538, 1538, 1538, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1538, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1529, 1529, 1529, 1529, 1529, 1528, 1528, 1528, 1528, 1528, 785, 1538, 785, 785, 785, 1529, 1529, 1529, 1528, 1528, 1529, 1529, 1529, 1530, 1530, 1530, 1530, 1529, 1529, 1529, 1529, 785, 785, 785, 785, 785, 785, 1528, 1528, 1528, 785, 1528, 1529, 1529, 1530, 1530, 1530, 785, 1528, 1528, 785, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1530, 1530, 1530, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1528, 1528, 1528, 1530, 1530, 1530, 1530, 1528, 1528, 1528, 1528, 1528, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1528, 1528, 1528, 1528, 1528, 1530, 1530, 1530, 1530, 1530, 1530, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1530, 1530, 1530, 1530, 1529, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1530, 1530, 1530, 1530, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1530, 1530, 1530, 1530, 1530, 1530, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1530, 1530, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1530, 1530, 1530, 1530, 1528, 1528, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1538, 1529, 1529, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1529, 781, 1538, 1538, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 781, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1541, 1541, 1541, 1541, 1529, 1538, 1538, 1529, 1538, 1538, 1529, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1538, 1538, 1529, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1528, 1530, 1530, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1530, 1530, 1530, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1530, 1530, 1530, 1530, 1530, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1538, 1538, 1538, 1529, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1530, 1530, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1529, 1530, 1530, 1530, 1530, 1530, 1530, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1538, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 196, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 781, 1479, 1479, 1479, 1479, 1479, 1479, 1479, 1479, 1479, 1479, 196, 196, 196, 196, 196, 196, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1530, 1032, 1032, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 196, 196, 196, 196, 196, 196, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 196, 196, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 1025, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 1032, 1032, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 196, 196, 196, 196, 196, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 910, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 196, 765, 770, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 1542, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 1035, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 765, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1024, 1032, 1032]

pub fn XSTRING[T](s: T) -> T {
    STRING(s)
}
pub var _pcre2_default_compile_context_8: pcre2_real_compile_context_8 = pcre2_real_compile_context_8 { memctl: pcre2_memctl { malloc: default_malloc, free: default_free, memory_data: (null) }, stack_guard: (null), stack_guard_data: (null), tables: (&raw const _pcre2_default_tables_8[0] as *const u8), max_pattern_length: ((~(0 as c_ulong))), max_pattern_compiled_length: ((~(0 as c_ulong))), bsr_convention: 1, newline_convention: 2, parens_nest_limit: 250, extra_options: 0, max_varlookbehind: 255, optimization_flags: 7 }

pub var _pcre2_default_match_context_8: pcre2_real_match_context_8 = pcre2_real_match_context_8 { memctl: pcre2_memctl { malloc: default_malloc, free: default_free, memory_data: (null) }, callout: (null), callout_data: (null), substitute_callout: (null), substitute_callout_data: (null), substitute_case_callout: (null), substitute_case_callout_data: (null), offset_limit: ((~(0 as c_ulong))), heap_limit: 20000000, match_limit: 10000000, depth_limit: 10000000 }

pub var _pcre2_default_convert_context_8: pcre2_real_convert_context_8 = pcre2_real_convert_context_8 { memctl: pcre2_memctl { malloc: default_malloc, free: default_free, memory_data: null }, glob_separator: 47, glob_escape: 92 }

pub let POSIX_START_REGEX: c_uint = 0
pub let POSIX_ANCHORED: c_uint = 1
pub let POSIX_NOT_BRACKET: c_uint = 2
pub let POSIX_CLASS_NOT_STARTED: c_uint = 3
pub let POSIX_CLASS_STARTING: c_uint = 4
pub let POSIX_CLASS_STARTED: c_uint = 5
pub type pcre2_output_context { output: *mut u8 = null, output_end: *const u8 = null, output_size: c_ulong = 0, out_str: [8]u8 = [0 as u8; 8] }
impl Copy for pcre2_output_context

pub let TYPE_OPTIONS: c_uint = 28
pub let ALL_OPTIONS: c_uint = 127
pub let DUMMY_BUFFER_SIZE: c_int = 100
pub let STR_BACKSLASH_A: [3]c_char = [92, 65, 0]
pub let STR_BACKSLASH_z: [3]c_char = [92, 122, 0]
pub let STR_COLON_RIGHT_SQUARE_BRACKET: [3]c_char = [58, 93, 0]
pub let STR_DOT_STAR_LOOKBEHIND: [7]c_char = [46, 42, 40, 63, 60, 61, 0]
pub let STR_LOOKAHEAD_NOT_DOT: [7]c_char = [40, 63, 33, 92, 46, 41, 0]
pub let STR_QUERY_s: [5]c_char = [40, 63, 115, 41, 0]
pub let STR_STAR_NUL: [7]c_char = [40, 42, 78, 85, 76, 41, 0]
pub fn ISLOWER[T](c: T) -> T {
    ((c >= 97) and (c <= 122))
}
pub let ERR0: c_uint = 100
pub let ERR1: c_uint = 101
pub let ERR2: c_uint = 102
pub let ERR3: c_uint = 103
pub let ERR4: c_uint = 104
pub let ERR5: c_uint = 105
pub let ERR6: c_uint = 106
pub let ERR7: c_uint = 107
pub let ERR8: c_uint = 108
pub let ERR9: c_uint = 109
pub let ERR10: c_uint = 110
pub let ERR11: c_uint = 111
pub let ERR12: c_uint = 112
pub let ERR13: c_uint = 113
pub let ERR14: c_uint = 114
pub let ERR15: c_uint = 115
pub let ERR16: c_uint = 116
pub let ERR17: c_uint = 117
pub let ERR18: c_uint = 118
pub let ERR19: c_uint = 119
pub let ERR20: c_uint = 120
pub let ERR21: c_uint = 121
pub let ERR22: c_uint = 122
pub let ERR23: c_uint = 123
pub let ERR24: c_uint = 124
pub let ERR25: c_uint = 125
pub let ERR26: c_uint = 126
pub let ERR27: c_uint = 127
pub let ERR28: c_uint = 128
pub let ERR29: c_uint = 129
pub let ERR30: c_uint = 130
pub let ERR31: c_uint = 131
pub let ERR32: c_uint = 132
pub let ERR33: c_uint = 133
pub let ERR34: c_uint = 134
pub let ERR35: c_uint = 135
pub let ERR36: c_uint = 136
pub let ERR37: c_uint = 137
pub let ERR38: c_uint = 138
pub let ERR39: c_uint = 139
pub let ERR40: c_uint = 140
pub let ERR41: c_uint = 141
pub let ERR42: c_uint = 142
pub let ERR43: c_uint = 143
pub let ERR44: c_uint = 144
pub let ERR45: c_uint = 145
pub let ERR46: c_uint = 146
pub let ERR47: c_uint = 147
pub let ERR48: c_uint = 148
pub let ERR49: c_uint = 149
pub let ERR50: c_uint = 150
pub let ERR51: c_uint = 151
pub let ERR52: c_uint = 152
pub let ERR53: c_uint = 153
pub let ERR54: c_uint = 154
pub let ERR55: c_uint = 155
pub let ERR56: c_uint = 156
pub let ERR57: c_uint = 157
pub let ERR58: c_uint = 158
pub let ERR59: c_uint = 159
pub let ERR60: c_uint = 160
pub let ERR61: c_uint = 161
pub let ERR62: c_uint = 162
pub let ERR63: c_uint = 163
pub let ERR64: c_uint = 164
pub let ERR65: c_uint = 165
pub let ERR66: c_uint = 166
pub let ERR67: c_uint = 167
pub let ERR68: c_uint = 168
pub let ERR69: c_uint = 169
pub let ERR70: c_uint = 170
pub let ERR71: c_uint = 171
pub let ERR72: c_uint = 172
pub let ERR73: c_uint = 173
pub let ERR74: c_uint = 174
pub let ERR75: c_uint = 175
pub let ERR76: c_uint = 176
pub let ERR77: c_uint = 177
pub let ERR78: c_uint = 178
pub let ERR79: c_uint = 179
pub let ERR80: c_uint = 180
pub let ERR81: c_uint = 181
pub let ERR82: c_uint = 182
pub let ERR83: c_uint = 183
pub let ERR84: c_uint = 184
pub let ERR85: c_uint = 185
pub let ERR86: c_uint = 186
pub let ERR87: c_uint = 187
pub let ERR88: c_uint = 188
pub let ERR89: c_uint = 189
pub let ERR90: c_uint = 190
pub let ERR91: c_uint = 191
pub let ERR92: c_uint = 192
pub let ERR93: c_uint = 193
pub let ERR94: c_uint = 194
pub let ERR95: c_uint = 195
pub let ERR96: c_uint = 196
pub let ERR97: c_uint = 197
pub let ERR98: c_uint = 198
pub let ERR99: c_uint = 199
pub let ERR100: c_uint = 200
pub let ERR101: c_uint = 201
pub let ERR102: c_uint = 202
pub let ERR103: c_uint = 203
pub let ERR104: c_uint = 204
pub let ERR105: c_uint = 205
pub let ERR106: c_uint = 206
pub let ERR107: c_uint = 207
pub let ERR108: c_uint = 208
pub let ERR109: c_uint = 209
pub let ERR110: c_uint = 210
pub let ERR111: c_uint = 211
pub let ERR112: c_uint = 212
pub let ERR113: c_uint = 213
pub let ERR114: c_uint = 214
pub let ERR115: c_uint = 215
pub let ERR116: c_uint = 216
pub let ERR117: c_uint = 217
pub let ERR118: c_uint = 218
pub let ERR119: c_uint = 219
pub let ERR120: c_uint = 220
pub type eclass_op_info { code_start: *mut u8 = null, length: c_ulong = 0, op_single_type: u8 = 0, bits: class_bits_storage }
impl Copy for eclass_op_info

pub let META_END: c_uint = 0x80000000
pub let META_ALT: c_uint = 0x80010000
pub let META_ATOMIC: c_uint = 0x80020000
pub let META_BACKREF: c_uint = 0x80030000
pub let META_BACKREF_BYNAME: c_uint = 0x80040000
pub let META_BIGVALUE: c_uint = 0x80050000
pub let META_CALLOUT_NUMBER: c_uint = 0x80060000
pub let META_CALLOUT_STRING: c_uint = 0x80070000
pub let META_CAPTURE: c_uint = 0x80080000
pub let META_CIRCUMFLEX: c_uint = 0x80090000
pub let META_CLASS: c_uint = 0x800a0000
pub let META_CLASS_EMPTY: c_uint = 0x800b0000
pub let META_CLASS_EMPTY_NOT: c_uint = 0x800c0000
pub let META_CLASS_END: c_uint = 0x800d0000
pub let META_CLASS_NOT: c_uint = 0x800e0000
pub let META_COND_ASSERT: c_uint = 0x800f0000
pub let META_COND_DEFINE: c_uint = 0x80100000
pub let META_COND_NAME: c_uint = 0x80110000
pub let META_COND_NUMBER: c_uint = 0x80120000
pub let META_COND_RNAME: c_uint = 0x80130000
pub let META_COND_RNUMBER: c_uint = 0x80140000
pub let META_COND_VERSION: c_uint = 0x80150000
pub let META_OFFSET: c_uint = 2148925440
pub let META_SCS: c_uint = 0x80170000
pub let META_CAPTURE_NAME: c_uint = 0x80180000
pub let META_CAPTURE_NUMBER: c_uint = 0x80190000
pub let META_DOLLAR: c_uint = 0x801a0000
pub let META_DOT: c_uint = 0x801b0000
pub let META_ESCAPE: c_uint = 0x801c0000
pub let META_KET: c_uint = 0x801d0000
pub let META_NOCAPTURE: c_uint = 0x801e0000
pub let META_OPTIONS: c_uint = 0x801f0000
pub let META_POSIX: c_uint = 0x80200000
pub let META_POSIX_NEG: c_uint = 0x80210000
pub let META_RANGE_ESCAPED: c_uint = 0x80220000
pub let META_RANGE_LITERAL: c_uint = 0x80230000
pub let META_RECURSE: c_uint = 0x80240000
pub let META_RECURSE_BYNAME: c_uint = 0x80250000
pub let META_SCRIPT_RUN: c_uint = 0x80260000
pub let META_LOOKAHEAD: c_uint = 0x80270000
pub let META_LOOKAHEADNOT: c_uint = 0x80280000
pub let META_LOOKBEHIND: c_uint = 0x80290000
pub let META_LOOKBEHINDNOT: c_uint = 0x802a0000
pub let META_LOOKAHEAD_NA: c_uint = 0x802b0000
pub let META_LOOKBEHIND_NA: c_uint = 0x802c0000
pub let META_MARK: c_uint = 0x802d0000
pub let META_ACCEPT: c_uint = 0x802e0000
pub let META_FAIL: c_uint = 0x802f0000
pub let META_COMMIT: c_uint = 0x80300000
pub let META_COMMIT_ARG: c_uint = 0x80310000
pub let META_PRUNE: c_uint = 0x80320000
pub let META_PRUNE_ARG: c_uint = 0x80330000
pub let META_SKIP: c_uint = 0x80340000
pub let META_SKIP_ARG: c_uint = 0x80350000
pub let META_THEN: c_uint = 0x80360000
pub let META_THEN_ARG: c_uint = 0x80370000
pub let META_ASTERISK: c_uint = 0x80380000
pub let META_ASTERISK_PLUS: c_uint = 0x80390000
pub let META_ASTERISK_QUERY: c_uint = 0x803a0000
pub let META_PLUS: c_uint = 0x803b0000
pub let META_PLUS_PLUS: c_uint = 0x803c0000
pub let META_PLUS_QUERY: c_uint = 0x803d0000
pub let META_QUERY: c_uint = 0x803e0000
pub let META_QUERY_PLUS: c_uint = 0x803f0000
pub let META_QUERY_QUERY: c_uint = 0x80400000
pub let META_MINMAX: c_uint = 0x80410000
pub let META_MINMAX_PLUS: c_uint = 0x80420000
pub let META_MINMAX_QUERY: c_uint = 0x80430000
pub let META_ECLASS_AND: c_uint = 0x80440000
pub let META_ECLASS_OR: c_uint = 0x80450000
pub let META_ECLASS_SUB: c_uint = 0x80460000
pub let META_ECLASS_XOR: c_uint = 0x80470000
pub let META_ECLASS_NOT: c_uint = 0x80480000
pub let META_FIRST_QUANTIFIER: c_uint = 2151153664
pub let META_LAST_QUANTIFIER: c_uint = 2151874560
pub let META_ATOMIC_SCRIPT_RUN: c_uint = 0x8fff0000
pub fn META_CODE[T](x: T) -> T {
    (x & 0xffff0000)
}
pub fn META_DATA[T](x: T) -> T {
    (x & 0x0000ffff)
}
pub let SIZEOFFSET: c_int = 2
pub let CLASS_IS_ECLASS: c_int = 0x1
pub let MAX_UCHAR_VALUE: c_uint = 0xff
pub fn SELECT_VALUE8[T](value8: T, value: T) -> T {
    value8
}
pub let PC_DIGIT: c_int = 7
pub let PC_GRAPH: c_int = 8
pub let PC_PRINT: c_int = 9
pub let PC_PUNCT: c_int = 10
pub let PC_XDIGIT: c_int = 13
pub let NAMED_GROUP_HASH_MASK: c_ushort = 32767
pub let NAMED_GROUP_IS_DUPNAME: c_ushort = 32768
pub type eclass_context { options: c_uint = 0, xoptions: c_uint = 0, errorcodeptr: *mut c_int = null, cb: *mut compile_block_8 = null, needs_bitmap: c_int = 0 }
impl Copy for eclass_context

pub let PARSE_CLASS_UTF: c_int = 0x1
pub let PARSE_CLASS_CASELESS_UTF: c_int = 0x2
pub let PARSE_CLASS_RESTRICTED_UTF: c_int = 0x4
pub let PARSE_CLASS_TURKISH_UTF: c_int = 0x8
pub let CHAR_LIST_EXTRA_SIZE: c_int = 3
pub let XCLASS_REQUIRED: c_int = 0x1
pub let XCLASS_HAS_8BIT_CHARS: c_int = 0x2
pub let XCLASS_HAS_PROPS: c_int = 0x4
pub let XCLASS_HAS_CHAR_LISTS: c_int = 0x8
pub let XCLASS_HIGH_ANY: c_int = 0x10
pub let MAX_LIST: c_int = 8
pub let APTROWS: c_int = 17
pub let APTCOLS: c_int = 21
pub let PSKIP_ALT: c_uint = 0
pub let PSKIP_CLASS: c_uint = 1
pub let PSKIP_KET: c_uint = 2
pub type verbitem { len: c_uint = 0, meta: c_uint = 0, has_arg: c_int = 0 }
impl Copy for verbitem

pub type alasitem { len: c_uint = 0, meta: c_uint = 0 }
impl Copy for alasitem

pub let PSO_OPT: c_uint = 0
pub let PSO_XOPT: c_uint = 1
pub let PSO_FLG: c_uint = 2
pub let PSO_NL: c_uint = 3
pub let PSO_BSR: c_uint = 4
pub let PSO_LIMH: c_uint = 5
pub let PSO_LIMM: c_uint = 6
pub let PSO_LIMD: c_uint = 7
pub let PSO_OPTMZ: c_uint = 8
pub type pso { name: *const i8 = null, length: c_ushort = 0, type_: c_ushort = 0, value: c_uint = 0 }
impl Copy for pso

pub type static_assertion_opcode_possessify = [1]c_int

pub type nest_save { nest_depth: c_ushort = 0, reset_group: c_ushort = 0, max_group: c_ushort = 0, flags: c_ushort = 0, options: c_uint = 0, xoptions: c_uint = 0 }
impl Copy for nest_save

pub let RANGE_NO: c_uint = 0
pub let RANGE_STARTED: c_uint = 1
pub let RANGE_FORBID_NO: c_uint = 2
pub let RANGE_FORBID_STARTED: c_uint = 3
pub let RANGE_OK_ESCAPED: c_uint = 4
pub let RANGE_OK_LITERAL: c_uint = 5
pub let CLASS_OP_EMPTY: c_uint = 0
pub let CLASS_OP_OPERAND: c_uint = 1
pub let CLASS_OP_OPERATOR: c_uint = 2
pub let CLASS_MODE_NORMAL: c_uint = 0
pub let CLASS_MODE_ALT_EXT: c_uint = 1
pub let CLASS_MODE_PERL_EXT: c_uint = 2
pub let CLASS_MODE_PERL_EXT_LEAF: c_uint = 3
pub let _pcre2_posix_class_maps8: [42]c_int = [160, 64, -2, 128, -1, 0, 96, -1, 0, 160, -1, 2, 224, 288, 0, 0, -1, 1, 288, -1, 0, 64, -1, 0, 192, -1, 0, 224, -1, 0, 256, -1, 0, 0, -1, 0, 160, -1, 0, 32, -1, 0]

pub fn XDIGIT[T](c: T) -> T {
    xdigitab[c]
}
pub let MAX_GROUP_NUMBER: c_uint = 65535
pub let MAX_REPEAT_COUNT: c_uint = 65535
pub let REPEAT_UNLIMITED: c_uint = 65536
pub let COMPILE_WORK_SIZE: c_int = 6000
pub let C16_WORK_SIZE: c_ulong = 3000
pub let GROUPINFO_DEFAULT_SIZE: c_int = 256
pub let WORK_SIZE_SAFETY_MARGIN: c_int = 100
pub let NAMED_GROUP_LIST_SIZE: c_int = 20
pub let PARSED_PATTERN_DEFAULT_SIZE: c_int = 1024
pub let OFLOW_MAX: c_int = 2147483627
pub let REQ_UNSET: c_uint = 0xffffffff
pub let REQ_NONE: c_uint = 0xfffffffe
pub let REQ_CASELESS: c_uint = 0x00000001
pub let REQ_VARY: c_uint = 0x00000002
pub let GI_SET_FIXED_LENGTH: c_uint = 0x80000000
pub let GI_NOT_FIXED_LENGTH: c_uint = 0x40000000
pub let GI_FIXED_LENGTH_MASK: c_uint = 0x0000ffff
pub fn IS_DIGIT[T](x: T) -> T {
    ((x >= 48) and (x <= 57))
}
pub let ESCAPES_FIRST: c_int = 48
pub let ESCAPES_LAST: c_int = 122
pub fn UPPER_CASE[T](c: T) -> T {
    (c - 32)
}
pub let PUBLIC_LITERAL_COMPILE_OPTIONS: c_uint = 3867738380
pub let PUBLIC_COMPILE_OPTIONS: c_uint = 4026531839
pub let PUBLIC_LITERAL_COMPILE_EXTRA_OPTIONS: c_uint = 65676
pub let PUBLIC_COMPILE_EXTRA_OPTIONS: c_uint = 131071
pub let NSF_RESET: c_uint = 0x0001
pub let NSF_CONDASSERT: c_uint = 0x0002
pub let NSF_ATOMICSR: c_uint = 0x0004
pub let PARSE_TRACKED_OPTIONS: c_uint = 17048808
pub let PARSE_TRACKED_EXTRA_OPTIONS: c_uint = 8064
pub let RSCAN_CACHE_SIZE: c_int = 8
pub fn charfn_to[T](c: T) -> T {
    c
}
pub fn charfn_from[T](c: T) -> T {
    c
}
pub type static_assertion_coptable = [1]c_int

pub type static_assertion_poptable = [1]c_int

pub type stateblock { offset: c_int = 0, count: c_int = 0, data: c_int = 0 }
impl Copy for stateblock

pub type RWS_anchor { next: *mut RWS_anchor = null, size: c_uint = 0, free: c_uint = 0 }
impl Copy for RWS_anchor

pub let PUBLIC_DFA_MATCH_OPTIONS: c_uint = 3758113023
pub let OP_PROP_EXTRA: c_int = 300
pub let OP_EXTUNI_EXTRA: c_int = 320
pub let OP_ANYNL_EXTRA: c_int = 340
pub let OP_HSPACE_EXTRA: c_int = 360
pub let OP_VSPACE_EXTRA: c_int = 380
pub let INTS_PER_STATEBLOCK: c_int = 3
pub let OVEC_UNIT: c_ulong = 2
pub let RWS_BASE_SIZE: c_ulong = 7680
pub let RWS_RSIZE: c_int = 1000
pub let RWS_OVEC_RSIZE: c_ulong = 2000
pub let RWS_OVEC_OSIZE: c_ulong = 4
pub let RWS_ANCHOR_SIZE: c_ulong = 4
pub let FF: c_int = (0x00010000 | 0x00020000)
pub let OO: c_int = (0x00000004 | 0x00000008)
pub let REPTYPE_MIN: c_uint = 0
pub let REPTYPE_MAX: c_uint = 1
pub let REPTYPE_POS: c_uint = 2
pub let RM1: c_uint = 1
pub let RM2: c_uint = 2
pub let RM3: c_uint = 3
pub let RM4: c_uint = 4
pub let RM5: c_uint = 5
pub let RM6: c_uint = 6
pub let RM7: c_uint = 7
pub let RM8: c_uint = 8
pub let RM9: c_uint = 9
pub let RM10: c_uint = 10
pub let RM11: c_uint = 11
pub let RM12: c_uint = 12
pub let RM13: c_uint = 13
pub let RM14: c_uint = 14
pub let RM15: c_uint = 15
pub let RM16: c_uint = 16
pub let RM17: c_uint = 17
pub let RM18: c_uint = 18
pub let RM19: c_uint = 19
pub let RM20: c_uint = 20
pub let RM21: c_uint = 21
pub let RM22: c_uint = 22
pub let RM23: c_uint = 23
pub let RM24: c_uint = 24
pub let RM25: c_uint = 25
pub let RM26: c_uint = 26
pub let RM27: c_uint = 27
pub let RM28: c_uint = 28
pub let RM29: c_uint = 29
pub let RM30: c_uint = 30
pub let RM31: c_uint = 31
pub let RM32: c_uint = 32
pub let RM33: c_uint = 33
pub let RM34: c_uint = 34
pub let RM35: c_uint = 35
pub let RM36: c_uint = 36
pub let RM37: c_uint = 37
pub let RM38: c_uint = 38
pub let RM39: c_uint = 39
pub let RM100: c_uint = 100
pub let RM101: c_uint = 101
pub let RM102: c_uint = 102
pub let RM103: c_uint = 103
pub let RM200: c_uint = 200
pub let RM201: c_uint = 201
pub let RM202: c_uint = 202
pub let RM203: c_uint = 203
pub let RM204: c_uint = 204
pub let RM205: c_uint = 205
pub let RM206: c_uint = 206
pub let RM207: c_uint = 207
pub let RM208: c_uint = 208
pub let RM209: c_uint = 209
pub let RM210: c_uint = 210
pub let RM211: c_uint = 211
pub let RM212: c_uint = 212
pub let RM213: c_uint = 213
pub let RM214: c_uint = 214
pub let RM215: c_uint = 215
pub let RM216: c_uint = 216
pub let RM217: c_uint = 217
pub let RM218: c_uint = 218
pub let RM219: c_uint = 219
pub let RM220: c_uint = 220
pub let RM221: c_uint = 221
pub let RM222: c_uint = 222
pub let RM223: c_uint = 223
pub let RM224: c_uint = 224
pub let RECURSE_UNSET: c_uint = 0xffffffff
pub let PUBLIC_MATCH_OPTIONS: c_uint = 3758383167
pub let PUBLIC_JIT_MATCH_OPTIONS: c_uint = 1073758271
pub let MATCH_MATCH: c_int = 1
pub let MATCH_NOMATCH: c_int = 0
pub let MATCH_ACCEPT: c_int = -999
pub let MATCH_KETRPOS: c_int = -998
pub let MATCH_COMMIT: c_int = -997
pub let MATCH_PRUNE: c_int = -996
pub let MATCH_SKIP: c_int = -995
pub let MATCH_SKIP_ARG: c_int = -994
pub let MATCH_THEN: c_int = -993
pub let MATCH_BACKTRACK_MAX: c_int = -993
pub let MATCH_BACKTRACK_MIN: c_int = -997
pub let GF_CAPTURE: c_uint = 0x00010000
pub let GF_NOCAPTURE: c_uint = 0x00020000
pub let GF_CONDASSERT: c_uint = 0x00030000
pub let GF_RECURSE: c_uint = 0x00040000
pub fn GF_IDMASK[T](a: T) -> T {
    (a & 0xffff0000)
}
pub fn GF_DATAMASK[T](a: T) -> T {
    (a & 0x0000ffff)
}
pub let SERIALIZED_DATA_MAGIC: c_uint = 0x50523253
pub let SERIALIZED_DATA_VERSION: c_int = 3080202
pub let SERIALIZED_DATA_CONFIG: c_ulong = 526337
pub type case_state { to_case: c_int = 0, single_char: c_int = 0 }
impl Copy for case_state

pub let PTR_STACK_SIZE: c_int = 20
pub let SUBSTITUTE_OPTIONS: c_uint = 237312
pub let PCRE2_SUBSTITUTE_CASE_NONE: c_int = 0
pub let PCRE2_SUBSTITUTE_CASE_REVERSE_TITLE_FIRST: c_int = 4
pub let SSB_FAIL: c_uint = 0
pub let SSB_DONE: c_uint = 1
pub let SSB_CONTINUE: c_uint = 2
pub let SSB_UNKNOWN: c_uint = 3
pub let SSB_TOODEEP: c_uint = 4
pub let MAX_CACHE_BACKREF: c_int = 128
pub let SCRIPT_UNSET: c_uint = 0
pub let SCRIPT_MAP: c_uint = 1
pub let SCRIPT_HANPENDING: c_uint = 2
pub let SCRIPT_HANHIRAKATA: c_uint = 3
pub let SCRIPT_HANBOPOMOFO: c_uint = 4
pub let SCRIPT_HANHANGUL: c_uint = 5
pub let UCD_MAPSIZE: c_int = 4
pub let FULL_MAPSIZE: c_int = 6
pub let FOUND_BOPOMOFO: c_int = 1
pub let FOUND_HIRAGANA: c_int = 2
pub let FOUND_KATAKANA: c_int = 4
pub let FOUND_HANGUL: c_int = 8
pub let REG_ASSERT: c_uint = 1
pub let REG_BADBR: c_uint = 2
pub let REG_BADPAT: c_uint = 3
pub let REG_BADRPT: c_uint = 4
pub let REG_EBRACE: c_uint = 5
pub let REG_EBRACK: c_uint = 6
pub let REG_ECOLLATE: c_uint = 7
pub let REG_ECTYPE: c_uint = 8
pub let REG_EESCAPE: c_uint = 9
pub let REG_EMPTY: c_uint = 10
pub let REG_EPAREN: c_uint = 11
pub let REG_ERANGE: c_uint = 12
pub let REG_ESIZE: c_uint = 13
pub let REG_ESPACE: c_uint = 14
pub let REG_ESUBREG: c_uint = 15
pub let REG_INVARG: c_uint = 16
pub let REG_NOMATCH: c_uint = 17
pub type regex_t { re_pcre2_code: *mut c_void = null, re_match_data: *mut c_void = null, re_endp: *const i8 = null, re_nsub: c_ulong = 0, re_erroffset: c_ulong = 0, re_cflags: c_int = 0 }
impl Copy for regex_t

pub type regoff_t = c_int

pub type regmatch_t { rm_so: c_int = 0, rm_eo: c_int = 0 }
impl Copy for regmatch_t

pub let REG_ICASE: c_int = 0x0001
pub let REG_NEWLINE: c_int = 0x0002
pub let REG_NOTBOL: c_int = 0x0004
pub let REG_NOTEOL: c_int = 0x0008
pub let REG_DOTALL: c_int = 0x0010
pub let REG_NOSUB: c_int = 0x0020
pub let REG_UTF: c_int = 0x0040
pub let REG_STARTEND: c_int = 0x0080
pub let REG_NOTEMPTY: c_int = 0x0100
pub let REG_UNGREEDY: c_int = 0x0200
pub let REG_UCP: c_int = 0x0400
pub let REG_PEND: c_int = 0x0800
pub let REG_NOSPEC: c_int = 0x1000
pub let REG_EXTENDED: c_int = 0
pub fn PRIV[T](name: T) -> T {
    name
}
pub let PR_OK: c_uint = 0
pub let PR_SKIP: c_uint = 1
pub let PR_ABEND: c_uint = 2
pub let PR_ENDIF: c_uint = 3
pub type static_assertion_OP_names = [1]c_int

pub type static_assertion_OP_lengths_8 = [1]c_int

pub type cmdstruct { name: *const i8 = null, value: c_int = 0 }
impl Copy for cmdstruct

pub let CMD_ENDIF: c_uint = 0
pub let CMD_FORBID_UTF: c_uint = 1
pub let CMD_IF: c_uint = 2
pub let CMD_LOAD: c_uint = 3
pub let CMD_LOADTABLES: c_uint = 4
pub let CMD_NEWLINE_DEFAULT: c_uint = 5
pub let CMD_PATTERN: c_uint = 6
pub let CMD_PERLTEST: c_uint = 7
pub let CMD_POP: c_uint = 8
pub let CMD_POPCOPY: c_uint = 9
pub let CMD_SAVE: c_uint = 10
pub let CMD_SUBJECT: c_uint = 11
pub let CMD_UNKNOWN: c_uint = 12
pub type convertstruct { name: *const i8 = null, option: c_uint = 0 }
impl Copy for convertstruct

pub let MOD_CTC: c_uint = 0
pub let MOD_CTM: c_uint = 1
pub let MOD_PAT: c_uint = 2
pub let MOD_PATP: c_uint = 3
pub let MOD_DAT: c_uint = 4
pub let MOD_DATP: c_uint = 5
pub let MOD_PD: c_uint = 6
pub let MOD_PDP: c_uint = 7
pub let MOD_PND: c_uint = 8
pub let MOD_PNDP: c_uint = 9
pub let MOD_CHR: c_uint = 10
pub let MOD_CON: c_uint = 11
pub let MOD_CTL: c_uint = 12
pub let MOD_BSR: c_uint = 13
pub let MOD_IN2: c_uint = 14
pub let MOD_INS: c_uint = 15
pub let MOD_INT: c_uint = 16
pub let MOD_IND: c_uint = 17
pub let MOD_NL: c_uint = 18
pub let MOD_NN: c_uint = 19
pub let MOD_OPT: c_uint = 20
pub let MOD_OPTMZ: c_uint = 21
pub let MOD_SIZ: c_uint = 22
pub let MOD_STR: c_uint = 23
pub type patctl { options: c_uint = 0, control: c_uint = 0, control2: c_uint = 0, jitstack: c_uint = 0, replacement: [101]u8 = [0 as u8; 101], substitute_skip: c_uint = 0, substitute_stop: c_uint = 0, jit: c_uint = 0, stackguard_test: c_uint = 0, tables_id: c_uint = 0, convert_type: c_uint = 0, convert_length: c_uint = 0, convert_glob_escape: c_uint = 0, convert_glob_separator: c_uint = 0, regerror_buffsize: c_int = 0, locale: [33]u8 = [0 as u8; 33] }
impl Copy for patctl

pub type datctl { options: c_uint = 0, control: c_uint = 0, control2: c_uint = 0, jitstack: c_uint = 0, replacement: [101]u8 = [0 as u8; 101], substitute_skip: c_uint = 0, substitute_stop: c_uint = 0, substitute_subject: [101]u8 = [0 as u8; 101], startend: [2]c_uint = [0 as c_uint; 2], cerror: [2]c_uint = [0 as c_uint; 2], cfail: [2]c_uint = [0 as c_uint; 2], callout_data: c_int = 0, copy_numbers: [10]c_int = [0 as c_int; 10], get_numbers: [10]c_int = [0 as c_int; 10], oveccount: c_uint = 0, offset: c_ulong = 0, copy_names: [64]u8 = [0 as u8; 64], get_names: [64]u8 = [0 as u8; 64] }
impl Copy for datctl

pub let CTX_PAT: c_uint = 0
pub let CTX_POPPAT: c_uint = 1
pub let CTX_DEFPAT: c_uint = 2
pub let CTX_DAT: c_uint = 3
pub let CTX_DEFDAT: c_uint = 4
pub type static_assertion_options_mismatch = [1]c_int

pub type static_assertion_control_mismatch = [1]c_int

pub type static_assertion_control2_mismatch = [1]c_int

pub type static_assertion_jitstack_mismatch = [1]c_int

pub type static_assertion_replacement_mismatch = [1]c_int

pub type static_assertion_substitute_skip_mismatch = [1]c_int

pub type static_assertion_substitute_stop_mismatch = [1]c_int

pub type modstruct { name: *const i8 = null, which: c_ushort = 0, type_: c_ushort = 0, value: c_uint = 0, offset: c_ulong = 0 }
impl Copy for modstruct

pub type c1modstruct { fullname: *const i8 = null, onechar: c_uint = 0, index: c_int = 0 }
impl Copy for c1modstruct

pub type coptstruct { name: *const i8 = null, type_: c_uint = 0, value: c_uint = 0 }
impl Copy for coptstruct

pub let CONF_BSR: c_uint = 0
pub let CONF_FIX: c_uint = 1
pub let CONF_INT: c_uint = 2
pub let CONF_NL: c_uint = 3
pub let CONF_JU: c_uint = 4
pub type force_encoding = c_uint

pub let FORCE_NONE: c_uint = 0
pub let FORCE_RAW: c_uint = 1
pub let FORCE_UTF: c_uint = 2
pub let COLOUR_NEVER: c_uint = 0
pub let COLOUR_ALWAYS: c_uint = 1
pub let COLOUR_AUTO: c_uint = 2
pub let callout_start_delims: [9]c_uint = [96, 39, 34, 94, 37, 35, 36, 123, 0]

pub let callout_end_delims: [9]c_uint = [96, 39, 34, 94, 37, 35, 36, 125, 0]

pub let utf8_table1: [6]c_int = [127, 2047, 65535, 2097151, 67108863, 2147483647]

pub let utf8_table1_size: c_uint = 6

pub let utf8_table2: [6]c_int = [0, 192, 224, 240, 248, 252]

pub let utf8_table3: [6]c_int = [255, 31, 15, 7, 3, 1]

pub let utf8_table4: [64]u8 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5]

pub let ucp_gentype: [30]c_uint = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6]

pub let ucp_gbtable: [15]c_uint = [(((1 as c_uint) << (ucp_gbLF as c_uint))), 0, 0, 8232, ((((((((((((((((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbPrepend as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbL as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbLV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbLVT as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbOther as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbRegional_Indicator as c_uint))) as c_uint)), 8232, ((((((((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbL as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbLV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbLVT as c_uint))) as c_uint)), ((((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)), ((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)), ((((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbV as c_uint))) as c_uint)) as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)), ((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbT as c_uint))) as c_uint)), (((1 as c_uint) << (ucp_gbRegional_Indicator as c_uint))), 8232, ((8232 as c_uint) | ((((1 as c_uint) << (ucp_gbExtended_Pictographic as c_uint))) as c_uint)), 8232]

pub let utt_names: [3779]c_char = [97, 100, 108, 97, 109, 0, 97, 100, 108, 109, 0, 97, 103, 104, 98, 0, 97, 104, 101, 120, 0, 97, 104, 111, 109, 0, 97, 108, 112, 104, 97, 0, 97, 108, 112, 104, 97, 98, 101, 116, 105, 99, 0, 97, 110, 97, 116, 111, 108, 105, 97, 110, 104, 105, 101, 114, 111, 103, 108, 121, 112, 104, 115, 0, 97, 110, 121, 0, 97, 114, 97, 98, 0, 97, 114, 97, 98, 105, 99, 0, 97, 114, 109, 101, 110, 105, 97, 110, 0, 97, 114, 109, 105, 0, 97, 114, 109, 110, 0, 97, 115, 99, 105, 105, 0, 97, 115, 99, 105, 105, 104, 101, 120, 100, 105, 103, 105, 116, 0, 97, 118, 101, 115, 116, 97, 110, 0, 97, 118, 115, 116, 0, 98, 97, 108, 105, 0, 98, 97, 108, 105, 110, 101, 115, 101, 0, 98, 97, 109, 117, 0, 98, 97, 109, 117, 109, 0, 98, 97, 115, 115, 0, 98, 97, 115, 115, 97, 118, 97, 104, 0, 98, 97, 116, 97, 107, 0, 98, 97, 116, 107, 0, 98, 101, 110, 103, 0, 98, 101, 110, 103, 97, 108, 105, 0, 98, 104, 97, 105, 107, 115, 117, 107, 105, 0, 98, 104, 107, 115, 0, 98, 105, 100, 105, 97, 108, 0, 98, 105, 100, 105, 97, 110, 0, 98, 105, 100, 105, 98, 0, 98, 105, 100, 105, 98, 110, 0, 98, 105, 100, 105, 99, 0, 98, 105, 100, 105, 99, 111, 110, 116, 114, 111, 108, 0, 98, 105, 100, 105, 99, 115, 0, 98, 105, 100, 105, 101, 110, 0, 98, 105, 100, 105, 101, 115, 0, 98, 105, 100, 105, 101, 116, 0, 98, 105, 100, 105, 102, 115, 105, 0, 98, 105, 100, 105, 108, 0, 98, 105, 100, 105, 108, 114, 101, 0, 98, 105, 100, 105, 108, 114, 105, 0, 98, 105, 100, 105, 108, 114, 111, 0, 98, 105, 100, 105, 109, 0, 98, 105, 100, 105, 109, 105, 114, 114, 111, 114, 101, 100, 0, 98, 105, 100, 105, 110, 115, 109, 0, 98, 105, 100, 105, 111, 110, 0, 98, 105, 100, 105, 112, 100, 102, 0, 98, 105, 100, 105, 112, 100, 105, 0, 98, 105, 100, 105, 114, 0, 98, 105, 100, 105, 114, 108, 101, 0, 98, 105, 100, 105, 114, 108, 105, 0, 98, 105, 100, 105, 114, 108, 111, 0, 98, 105, 100, 105, 115, 0, 98, 105, 100, 105, 119, 115, 0, 98, 111, 112, 111, 0, 98, 111, 112, 111, 109, 111, 102, 111, 0, 98, 114, 97, 104, 0, 98, 114, 97, 104, 109, 105, 0, 98, 114, 97, 105, 0, 98, 114, 97, 105, 108, 108, 101, 0, 98, 117, 103, 105, 0, 98, 117, 103, 105, 110, 101, 115, 101, 0, 98, 117, 104, 100, 0, 98, 117, 104, 105, 100, 0, 99, 0, 99, 97, 107, 109, 0, 99, 97, 110, 97, 100, 105, 97, 110, 97, 98, 111, 114, 105, 103, 105, 110, 97, 108, 0, 99, 97, 110, 115, 0, 99, 97, 114, 105, 0, 99, 97, 114, 105, 97, 110, 0, 99, 97, 115, 101, 100, 0, 99, 97, 115, 101, 105, 103, 110, 111, 114, 97, 98, 108, 101, 0, 99, 97, 117, 99, 97, 115, 105, 97, 110, 97, 108, 98, 97, 110, 105, 97, 110, 0, 99, 99, 0, 99, 102, 0, 99, 104, 97, 107, 109, 97, 0, 99, 104, 97, 109, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 99, 97, 115, 101, 102, 111, 108, 100, 101, 100, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 99, 97, 115, 101, 109, 97, 112, 112, 101, 100, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 108, 111, 119, 101, 114, 99, 97, 115, 101, 100, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 116, 105, 116, 108, 101, 99, 97, 115, 101, 100, 0, 99, 104, 97, 110, 103, 101, 115, 119, 104, 101, 110, 117, 112, 112, 101, 114, 99, 97, 115, 101, 100, 0, 99, 104, 101, 114, 0, 99, 104, 101, 114, 111, 107, 101, 101, 0, 99, 104, 111, 114, 97, 115, 109, 105, 97, 110, 0, 99, 104, 114, 115, 0, 99, 105, 0, 99, 110, 0, 99, 111, 0, 99, 111, 109, 109, 111, 110, 0, 99, 111, 112, 116, 0, 99, 111, 112, 116, 105, 99, 0, 99, 112, 109, 110, 0, 99, 112, 114, 116, 0, 99, 115, 0, 99, 117, 110, 101, 105, 102, 111, 114, 109, 0, 99, 119, 99, 102, 0, 99, 119, 99, 109, 0, 99, 119, 108, 0, 99, 119, 116, 0, 99, 119, 117, 0, 99, 121, 112, 114, 105, 111, 116, 0, 99, 121, 112, 114, 111, 109, 105, 110, 111, 97, 110, 0, 99, 121, 114, 105, 108, 108, 105, 99, 0, 99, 121, 114, 108, 0, 100, 97, 115, 104, 0, 100, 101, 102, 97, 117, 108, 116, 105, 103, 110, 111, 114, 97, 98, 108, 101, 99, 111, 100, 101, 112, 111, 105, 110, 116, 0, 100, 101, 112, 0, 100, 101, 112, 114, 101, 99, 97, 116, 101, 100, 0, 100, 101, 115, 101, 114, 101, 116, 0, 100, 101, 118, 97, 0, 100, 101, 118, 97, 110, 97, 103, 97, 114, 105, 0, 100, 105, 0, 100, 105, 97, 0, 100, 105, 97, 99, 114, 105, 116, 105, 99, 0, 100, 105, 97, 107, 0, 100, 105, 118, 101, 115, 97, 107, 117, 114, 117, 0, 100, 111, 103, 114, 0, 100, 111, 103, 114, 97, 0, 100, 115, 114, 116, 0, 100, 117, 112, 108, 0, 100, 117, 112, 108, 111, 121, 97, 110, 0, 101, 98, 97, 115, 101, 0, 101, 99, 111, 109, 112, 0, 101, 103, 121, 112, 0, 101, 103, 121, 112, 116, 105, 97, 110, 104, 105, 101, 114, 111, 103, 108, 121, 112, 104, 115, 0, 101, 108, 98, 97, 0, 101, 108, 98, 97, 115, 97, 110, 0, 101, 108, 121, 109, 0, 101, 108, 121, 109, 97, 105, 99, 0, 101, 109, 111, 100, 0, 101, 109, 111, 106, 105, 0, 101, 109, 111, 106, 105, 99, 111, 109, 112, 111, 110, 101, 110, 116, 0, 101, 109, 111, 106, 105, 109, 111, 100, 105, 102, 105, 101, 114, 0, 101, 109, 111, 106, 105, 109, 111, 100, 105, 102, 105, 101, 114, 98, 97, 115, 101, 0, 101, 109, 111, 106, 105, 112, 114, 101, 115, 101, 110, 116, 97, 116, 105, 111, 110, 0, 101, 112, 114, 101, 115, 0, 101, 116, 104, 105, 0, 101, 116, 104, 105, 111, 112, 105, 99, 0, 101, 120, 116, 0, 101, 120, 116, 101, 110, 100, 101, 100, 112, 105, 99, 116, 111, 103, 114, 97, 112, 104, 105, 99, 0, 101, 120, 116, 101, 110, 100, 101, 114, 0, 101, 120, 116, 112, 105, 99, 116, 0, 103, 97, 114, 97, 0, 103, 97, 114, 97, 121, 0, 103, 101, 111, 114, 0, 103, 101, 111, 114, 103, 105, 97, 110, 0, 103, 108, 97, 103, 0, 103, 108, 97, 103, 111, 108, 105, 116, 105, 99, 0, 103, 111, 110, 103, 0, 103, 111, 110, 109, 0, 103, 111, 116, 104, 0, 103, 111, 116, 104, 105, 99, 0, 103, 114, 97, 110, 0, 103, 114, 97, 110, 116, 104, 97, 0, 103, 114, 97, 112, 104, 101, 109, 101, 98, 97, 115, 101, 0, 103, 114, 97, 112, 104, 101, 109, 101, 101, 120, 116, 101, 110, 100, 0, 103, 114, 97, 112, 104, 101, 109, 101, 108, 105, 110, 107, 0, 103, 114, 98, 97, 115, 101, 0, 103, 114, 101, 101, 107, 0, 103, 114, 101, 107, 0, 103, 114, 101, 120, 116, 0, 103, 114, 108, 105, 110, 107, 0, 103, 117, 106, 97, 114, 97, 116, 105, 0, 103, 117, 106, 114, 0, 103, 117, 107, 104, 0, 103, 117, 110, 106, 97, 108, 97, 103, 111, 110, 100, 105, 0, 103, 117, 114, 109, 117, 107, 104, 105, 0, 103, 117, 114, 117, 0, 103, 117, 114, 117, 110, 103, 107, 104, 101, 109, 97, 0, 104, 97, 110, 0, 104, 97, 110, 103, 0, 104, 97, 110, 103, 117, 108, 0, 104, 97, 110, 105, 0, 104, 97, 110, 105, 102, 105, 114, 111, 104, 105, 110, 103, 121, 97, 0, 104, 97, 110, 111, 0, 104, 97, 110, 117, 110, 111, 111, 0, 104, 97, 116, 114, 0, 104, 97, 116, 114, 97, 110, 0, 104, 101, 98, 114, 0, 104, 101, 98, 114, 101, 119, 0, 104, 101, 120, 0, 104, 101, 120, 100, 105, 103, 105, 116, 0, 104, 105, 114, 97, 0, 104, 105, 114, 97, 103, 97, 110, 97, 0, 104, 108, 117, 119, 0, 104, 109, 110, 103, 0, 104, 109, 110, 112, 0, 104, 117, 110, 103, 0, 105, 100, 99, 0, 105, 100, 99, 111, 109, 112, 97, 116, 109, 97, 116, 104, 99, 111, 110, 116, 105, 110, 117, 101, 0, 105, 100, 99, 111, 109, 112, 97, 116, 109, 97, 116, 104, 115, 116, 97, 114, 116, 0, 105, 100, 99, 111, 110, 116, 105, 110, 117, 101, 0, 105, 100, 101, 111, 0, 105, 100, 101, 111, 103, 114, 97, 112, 104, 105, 99, 0, 105, 100, 115, 0, 105, 100, 115, 98, 0, 105, 100, 115, 98, 105, 110, 97, 114, 121, 111, 112, 101, 114, 97, 116, 111, 114, 0, 105, 100, 115, 116, 0, 105, 100, 115, 116, 97, 114, 116, 0, 105, 100, 115, 116, 114, 105, 110, 97, 114, 121, 111, 112, 101, 114, 97, 116, 111, 114, 0, 105, 100, 115, 117, 0, 105, 100, 115, 117, 110, 97, 114, 121, 111, 112, 101, 114, 97, 116, 111, 114, 0, 105, 109, 112, 101, 114, 105, 97, 108, 97, 114, 97, 109, 97, 105, 99, 0, 105, 110, 99, 98, 0, 105, 110, 104, 101, 114, 105, 116, 101, 100, 0, 105, 110, 115, 99, 114, 105, 112, 116, 105, 111, 110, 97, 108, 112, 97, 104, 108, 97, 118, 105, 0, 105, 110, 115, 99, 114, 105, 112, 116, 105, 111, 110, 97, 108, 112, 97, 114, 116, 104, 105, 97, 110, 0, 105, 116, 97, 108, 0, 106, 97, 118, 97, 0, 106, 97, 118, 97, 110, 101, 115, 101, 0, 106, 111, 105, 110, 99, 0, 106, 111, 105, 110, 99, 111, 110, 116, 114, 111, 108, 0, 107, 97, 105, 116, 104, 105, 0, 107, 97, 108, 105, 0, 107, 97, 110, 97, 0, 107, 97, 110, 110, 97, 100, 97, 0, 107, 97, 116, 97, 107, 97, 110, 97, 0, 107, 97, 119, 105, 0, 107, 97, 121, 97, 104, 108, 105, 0, 107, 104, 97, 114, 0, 107, 104, 97, 114, 111, 115, 104, 116, 104, 105, 0, 107, 104, 105, 116, 97, 110, 115, 109, 97, 108, 108, 115, 99, 114, 105, 112, 116, 0, 107, 104, 109, 101, 114, 0, 107, 104, 109, 114, 0, 107, 104, 111, 106, 0, 107, 104, 111, 106, 107, 105, 0, 107, 104, 117, 100, 97, 119, 97, 100, 105, 0, 107, 105, 114, 97, 116, 114, 97, 105, 0, 107, 105, 116, 115, 0, 107, 110, 100, 97, 0, 107, 114, 97, 105, 0, 107, 116, 104, 105, 0, 108, 0, 108, 38, 0, 108, 97, 110, 97, 0, 108, 97, 111, 0, 108, 97, 111, 111, 0, 108, 97, 116, 105, 110, 0, 108, 97, 116, 110, 0, 108, 99, 0, 108, 101, 112, 99, 0, 108, 101, 112, 99, 104, 97, 0, 108, 105, 109, 98, 0, 108, 105, 109, 98, 117, 0, 108, 105, 110, 97, 0, 108, 105, 110, 98, 0, 108, 105, 110, 101, 97, 114, 97, 0, 108, 105, 110, 101, 97, 114, 98, 0, 108, 105, 115, 117, 0, 108, 108, 0, 108, 109, 0, 108, 111, 0, 108, 111, 101, 0, 108, 111, 103, 105, 99, 97, 108, 111, 114, 100, 101, 114, 101, 120, 99, 101, 112, 116, 105, 111, 110, 0, 108, 111, 119, 101, 114, 0, 108, 111, 119, 101, 114, 99, 97, 115, 101, 0, 108, 116, 0, 108, 117, 0, 108, 121, 99, 105, 0, 108, 121, 99, 105, 97, 110, 0, 108, 121, 100, 105, 0, 108, 121, 100, 105, 97, 110, 0, 109, 0, 109, 97, 104, 97, 106, 97, 110, 105, 0, 109, 97, 104, 106, 0, 109, 97, 107, 97, 0, 109, 97, 107, 97, 115, 97, 114, 0, 109, 97, 108, 97, 121, 97, 108, 97, 109, 0, 109, 97, 110, 100, 0, 109, 97, 110, 100, 97, 105, 99, 0, 109, 97, 110, 105, 0, 109, 97, 110, 105, 99, 104, 97, 101, 97, 110, 0, 109, 97, 114, 99, 0, 109, 97, 114, 99, 104, 101, 110, 0, 109, 97, 115, 97, 114, 97, 109, 103, 111, 110, 100, 105, 0, 109, 97, 116, 104, 0, 109, 99, 0, 109, 99, 109, 0, 109, 101, 0, 109, 101, 100, 101, 102, 97, 105, 100, 114, 105, 110, 0, 109, 101, 100, 102, 0, 109, 101, 101, 116, 101, 105, 109, 97, 121, 101, 107, 0, 109, 101, 110, 100, 0, 109, 101, 110, 100, 101, 107, 105, 107, 97, 107, 117, 105, 0, 109, 101, 114, 99, 0, 109, 101, 114, 111, 0, 109, 101, 114, 111, 105, 116, 105, 99, 99, 117, 114, 115, 105, 118, 101, 0, 109, 101, 114, 111, 105, 116, 105, 99, 104, 105, 101, 114, 111, 103, 108, 121, 112, 104, 115, 0, 109, 105, 97, 111, 0, 109, 108, 121, 109, 0, 109, 110, 0, 109, 111, 100, 105, 0, 109, 111, 100, 105, 102, 105, 101, 114, 99, 111, 109, 98, 105, 110, 105, 110, 103, 109, 97, 114, 107, 0, 109, 111, 110, 103, 0, 109, 111, 110, 103, 111, 108, 105, 97, 110, 0, 109, 114, 111, 0, 109, 114, 111, 111, 0, 109, 116, 101, 105, 0, 109, 117, 108, 116, 0, 109, 117, 108, 116, 97, 110, 105, 0, 109, 121, 97, 110, 109, 97, 114, 0, 109, 121, 109, 114, 0, 110, 0, 110, 97, 98, 97, 116, 97, 101, 97, 110, 0, 110, 97, 103, 109, 0, 110, 97, 103, 109, 117, 110, 100, 97, 114, 105, 0, 110, 97, 110, 100, 0, 110, 97, 110, 100, 105, 110, 97, 103, 97, 114, 105, 0, 110, 97, 114, 98, 0, 110, 98, 97, 116, 0, 110, 99, 104, 97, 114, 0, 110, 100, 0, 110, 101, 119, 97, 0, 110, 101, 119, 116, 97, 105, 108, 117, 101, 0, 110, 107, 111, 0, 110, 107, 111, 111, 0, 110, 108, 0, 110, 111, 0, 110, 111, 110, 99, 104, 97, 114, 97, 99, 116, 101, 114, 99, 111, 100, 101, 112, 111, 105, 110, 116, 0, 110, 115, 104, 117, 0, 110, 117, 115, 104, 117, 0, 110, 121, 105, 97, 107, 101, 110, 103, 112, 117, 97, 99, 104, 117, 101, 104, 109, 111, 110, 103, 0, 111, 103, 97, 109, 0, 111, 103, 104, 97, 109, 0, 111, 108, 99, 104, 105, 107, 105, 0, 111, 108, 99, 107, 0, 111, 108, 100, 104, 117, 110, 103, 97, 114, 105, 97, 110, 0, 111, 108, 100, 105, 116, 97, 108, 105, 99, 0, 111, 108, 100, 110, 111, 114, 116, 104, 97, 114, 97, 98, 105, 97, 110, 0, 111, 108, 100, 112, 101, 114, 109, 105, 99, 0, 111, 108, 100, 112, 101, 114, 115, 105, 97, 110, 0, 111, 108, 100, 115, 111, 103, 100, 105, 97, 110, 0, 111, 108, 100, 115, 111, 117, 116, 104, 97, 114, 97, 98, 105, 97, 110, 0, 111, 108, 100, 116, 117, 114, 107, 105, 99, 0, 111, 108, 100, 117, 121, 103, 104, 117, 114, 0, 111, 108, 111, 110, 97, 108, 0, 111, 110, 97, 111, 0, 111, 114, 105, 121, 97, 0, 111, 114, 107, 104, 0, 111, 114, 121, 97, 0, 111, 115, 97, 103, 101, 0, 111, 115, 103, 101, 0, 111, 115, 109, 97, 0, 111, 115, 109, 97, 110, 121, 97, 0, 111, 117, 103, 114, 0, 112, 0, 112, 97, 104, 97, 119, 104, 104, 109, 111, 110, 103, 0, 112, 97, 108, 109, 0, 112, 97, 108, 109, 121, 114, 101, 110, 101, 0, 112, 97, 116, 115, 121, 110, 0, 112, 97, 116, 116, 101, 114, 110, 115, 121, 110, 116, 97, 120, 0, 112, 97, 116, 116, 101, 114, 110, 119, 104, 105, 116, 101, 115, 112, 97, 99, 101, 0, 112, 97, 116, 119, 115, 0, 112, 97, 117, 99, 0, 112, 97, 117, 99, 105, 110, 104, 97, 117, 0, 112, 99, 0, 112, 99, 109, 0, 112, 100, 0, 112, 101, 0, 112, 101, 114, 109, 0, 112, 102, 0, 112, 104, 97, 103, 0, 112, 104, 97, 103, 115, 112, 97, 0, 112, 104, 108, 105, 0, 112, 104, 108, 112, 0, 112, 104, 110, 120, 0, 112, 104, 111, 101, 110, 105, 99, 105, 97, 110, 0, 112, 105, 0, 112, 108, 114, 100, 0, 112, 111, 0, 112, 114, 101, 112, 101, 110, 100, 101, 100, 99, 111, 110, 99, 97, 116, 101, 110, 97, 116, 105, 111, 110, 109, 97, 114, 107, 0, 112, 114, 116, 105, 0, 112, 115, 0, 112, 115, 97, 108, 116, 101, 114, 112, 97, 104, 108, 97, 118, 105, 0, 113, 97, 97, 99, 0, 113, 97, 97, 105, 0, 113, 109, 97, 114, 107, 0, 113, 117, 111, 116, 97, 116, 105, 111, 110, 109, 97, 114, 107, 0, 114, 97, 100, 105, 99, 97, 108, 0, 114, 101, 103, 105, 111, 110, 97, 108, 105, 110, 100, 105, 99, 97, 116, 111, 114, 0, 114, 101, 106, 97, 110, 103, 0, 114, 105, 0, 114, 106, 110, 103, 0, 114, 111, 104, 103, 0, 114, 117, 110, 105, 99, 0, 114, 117, 110, 114, 0, 115, 0, 115, 97, 109, 97, 114, 105, 116, 97, 110, 0, 115, 97, 109, 114, 0, 115, 97, 114, 98, 0, 115, 97, 117, 114, 0, 115, 97, 117, 114, 97, 115, 104, 116, 114, 97, 0, 115, 99, 0, 115, 100, 0, 115, 101, 110, 116, 101, 110, 99, 101, 116, 101, 114, 109, 105, 110, 97, 108, 0, 115, 103, 110, 119, 0, 115, 104, 97, 114, 97, 100, 97, 0, 115, 104, 97, 118, 105, 97, 110, 0, 115, 104, 97, 119, 0, 115, 104, 114, 100, 0, 115, 105, 100, 100, 0, 115, 105, 100, 100, 104, 97, 109, 0, 115, 105, 103, 110, 119, 114, 105, 116, 105, 110, 103, 0, 115, 105, 110, 100, 0, 115, 105, 110, 104, 0, 115, 105, 110, 104, 97, 108, 97, 0, 115, 107, 0, 115, 109, 0, 115, 111, 0, 115, 111, 102, 116, 100, 111, 116, 116, 101, 100, 0, 115, 111, 103, 100, 0, 115, 111, 103, 100, 105, 97, 110, 0, 115, 111, 103, 111, 0, 115, 111, 114, 97, 0, 115, 111, 114, 97, 115, 111, 109, 112, 101, 110, 103, 0, 115, 111, 121, 111, 0, 115, 111, 121, 111, 109, 98, 111, 0, 115, 112, 97, 99, 101, 0, 115, 116, 101, 114, 109, 0, 115, 117, 110, 100, 0, 115, 117, 110, 100, 97, 110, 101, 115, 101, 0, 115, 117, 110, 117, 0, 115, 117, 110, 117, 119, 97, 114, 0, 115, 121, 108, 111, 0, 115, 121, 108, 111, 116, 105, 110, 97, 103, 114, 105, 0, 115, 121, 114, 99, 0, 115, 121, 114, 105, 97, 99, 0, 116, 97, 103, 97, 108, 111, 103, 0, 116, 97, 103, 98, 0, 116, 97, 103, 98, 97, 110, 119, 97, 0, 116, 97, 105, 108, 101, 0, 116, 97, 105, 116, 104, 97, 109, 0, 116, 97, 105, 118, 105, 101, 116, 0, 116, 97, 107, 114, 0, 116, 97, 107, 114, 105, 0, 116, 97, 108, 101, 0, 116, 97, 108, 117, 0, 116, 97, 109, 105, 108, 0, 116, 97, 109, 108, 0, 116, 97, 110, 103, 0, 116, 97, 110, 103, 115, 97, 0, 116, 97, 110, 103, 117, 116, 0, 116, 97, 118, 116, 0, 116, 101, 108, 117, 0, 116, 101, 108, 117, 103, 117, 0, 116, 101, 114, 109, 0, 116, 101, 114, 109, 105, 110, 97, 108, 112, 117, 110, 99, 116, 117, 97, 116, 105, 111, 110, 0, 116, 102, 110, 103, 0, 116, 103, 108, 103, 0, 116, 104, 97, 97, 0, 116, 104, 97, 97, 110, 97, 0, 116, 104, 97, 105, 0, 116, 105, 98, 101, 116, 97, 110, 0, 116, 105, 98, 116, 0, 116, 105, 102, 105, 110, 97, 103, 104, 0, 116, 105, 114, 104, 0, 116, 105, 114, 104, 117, 116, 97, 0, 116, 110, 115, 97, 0, 116, 111, 100, 104, 114, 105, 0, 116, 111, 100, 114, 0, 116, 111, 116, 111, 0, 116, 117, 108, 117, 116, 105, 103, 97, 108, 97, 114, 105, 0, 116, 117, 116, 103, 0, 117, 103, 97, 114, 0, 117, 103, 97, 114, 105, 116, 105, 99, 0, 117, 105, 100, 101, 111, 0, 117, 110, 105, 102, 105, 101, 100, 105, 100, 101, 111, 103, 114, 97, 112, 104, 0, 117, 110, 107, 110, 111, 119, 110, 0, 117, 112, 112, 101, 114, 0, 117, 112, 112, 101, 114, 99, 97, 115, 101, 0, 118, 97, 105, 0, 118, 97, 105, 105, 0, 118, 97, 114, 105, 97, 116, 105, 111, 110, 115, 101, 108, 101, 99, 116, 111, 114, 0, 118, 105, 116, 104, 0, 118, 105, 116, 104, 107, 117, 113, 105, 0, 118, 115, 0, 119, 97, 110, 99, 104, 111, 0, 119, 97, 114, 97, 0, 119, 97, 114, 97, 110, 103, 99, 105, 116, 105, 0, 119, 99, 104, 111, 0, 119, 104, 105, 116, 101, 115, 112, 97, 99, 101, 0, 119, 115, 112, 97, 99, 101, 0, 120, 97, 110, 0, 120, 105, 100, 99, 0, 120, 105, 100, 99, 111, 110, 116, 105, 110, 117, 101, 0, 120, 105, 100, 115, 0, 120, 105, 100, 115, 116, 97, 114, 116, 0, 120, 112, 101, 111, 0, 120, 112, 115, 0, 120, 115, 112, 0, 120, 115, 117, 120, 0, 120, 117, 99, 0, 120, 119, 100, 0, 121, 101, 122, 105, 0, 121, 101, 122, 105, 100, 105, 0, 121, 105, 0, 121, 105, 105, 105, 0, 122, 0, 122, 97, 110, 97, 98, 97, 122, 97, 114, 115, 113, 117, 97, 114, 101, 0, 122, 97, 110, 98, 0, 122, 105, 110, 104, 0, 122, 108, 0, 122, 112, 0, 122, 115, 0, 122, 121, 121, 121, 0, 122, 122, 122, 122, 0, 0]

pub let utt: [510]ucp_type_table = [ucp_type_table { name_offset: 0, type_: 4, value: 79 }, ucp_type_table { name_offset: 6, type_: 4, value: 79 }, ucp_type_table { name_offset: 11, type_: 4, value: 64 }, ucp_type_table { name_offset: 16, type_: 12, value: 1 }, ucp_type_table { name_offset: 21, type_: 3, value: 147 }, ucp_type_table { name_offset: 26, type_: 12, value: 2 }, ucp_type_table { name_offset: 32, type_: 12, value: 2 }, ucp_type_table { name_offset: 43, type_: 3, value: 148 }, ucp_type_table { name_offset: 64, type_: 13, value: 0 }, ucp_type_table { name_offset: 68, type_: 4, value: 5 }, ucp_type_table { name_offset: 73, type_: 4, value: 5 }, ucp_type_table { name_offset: 80, type_: 4, value: 3 }, ucp_type_table { name_offset: 89, type_: 3, value: 128 }, ucp_type_table { name_offset: 94, type_: 4, value: 3 }, ucp_type_table { name_offset: 99, type_: 12, value: 0 }, ucp_type_table { name_offset: 105, type_: 12, value: 1 }, ucp_type_table { name_offset: 119, type_: 4, value: 53 }, ucp_type_table { name_offset: 127, type_: 4, value: 53 }, ucp_type_table { name_offset: 132, type_: 3, value: 113 }, ucp_type_table { name_offset: 137, type_: 3, value: 113 }, ucp_type_table { name_offset: 146, type_: 3, value: 126 }, ucp_type_table { name_offset: 151, type_: 3, value: 126 }, ucp_type_table { name_offset: 157, type_: 3, value: 137 }, ucp_type_table { name_offset: 162, type_: 3, value: 137 }, ucp_type_table { name_offset: 171, type_: 3, value: 132 }, ucp_type_table { name_offset: 177, type_: 3, value: 132 }, ucp_type_table { name_offset: 182, type_: 4, value: 9 }, ucp_type_table { name_offset: 187, type_: 4, value: 9 }, ucp_type_table { name_offset: 195, type_: 3, value: 151 }, ucp_type_table { name_offset: 205, type_: 3, value: 151 }, ucp_type_table { name_offset: 210, type_: 11, value: 0 }, ucp_type_table { name_offset: 217, type_: 11, value: 1 }, ucp_type_table { name_offset: 224, type_: 11, value: 2 }, ucp_type_table { name_offset: 230, type_: 11, value: 3 }, ucp_type_table { name_offset: 237, type_: 12, value: 3 }, ucp_type_table { name_offset: 243, type_: 12, value: 3 }, ucp_type_table { name_offset: 255, type_: 11, value: 4 }, ucp_type_table { name_offset: 262, type_: 11, value: 5 }, ucp_type_table { name_offset: 269, type_: 11, value: 6 }, ucp_type_table { name_offset: 276, type_: 11, value: 7 }, ucp_type_table { name_offset: 283, type_: 11, value: 8 }, ucp_type_table { name_offset: 291, type_: 11, value: 9 }, ucp_type_table { name_offset: 297, type_: 11, value: 10 }, ucp_type_table { name_offset: 305, type_: 11, value: 11 }, ucp_type_table { name_offset: 313, type_: 11, value: 12 }, ucp_type_table { name_offset: 321, type_: 12, value: 4 }, ucp_type_table { name_offset: 327, type_: 12, value: 4 }, ucp_type_table { name_offset: 340, type_: 11, value: 13 }, ucp_type_table { name_offset: 348, type_: 11, value: 14 }, ucp_type_table { name_offset: 355, type_: 11, value: 15 }, ucp_type_table { name_offset: 363, type_: 11, value: 16 }, ucp_type_table { name_offset: 371, type_: 11, value: 17 }, ucp_type_table { name_offset: 377, type_: 11, value: 18 }, ucp_type_table { name_offset: 385, type_: 11, value: 19 }, ucp_type_table { name_offset: 393, type_: 11, value: 20 }, ucp_type_table { name_offset: 401, type_: 11, value: 21 }, ucp_type_table { name_offset: 407, type_: 11, value: 22 }, ucp_type_table { name_offset: 414, type_: 4, value: 29 }, ucp_type_table { name_offset: 419, type_: 4, value: 29 }, ucp_type_table { name_offset: 428, type_: 3, value: 133 }, ucp_type_table { name_offset: 433, type_: 3, value: 133 }, ucp_type_table { name_offset: 440, type_: 3, value: 109 }, ucp_type_table { name_offset: 445, type_: 3, value: 109 }, ucp_type_table { name_offset: 453, type_: 4, value: 42 }, ucp_type_table { name_offset: 458, type_: 4, value: 42 }, ucp_type_table { name_offset: 467, type_: 4, value: 35 }, ucp_type_table { name_offset: 472, type_: 4, value: 35 }, ucp_type_table { name_offset: 478, type_: 1, value: 0 }, ucp_type_table { name_offset: 480, type_: 4, value: 60 }, ucp_type_table { name_offset: 485, type_: 3, value: 101 }, ucp_type_table { name_offset: 504, type_: 3, value: 101 }, ucp_type_table { name_offset: 509, type_: 4, value: 51 }, ucp_type_table { name_offset: 514, type_: 4, value: 51 }, ucp_type_table { name_offset: 521, type_: 12, value: 6 }, ucp_type_table { name_offset: 527, type_: 12, value: 5 }, ucp_type_table { name_offset: 541, type_: 4, value: 64 }, ucp_type_table { name_offset: 559, type_: 2, value: 0 }, ucp_type_table { name_offset: 562, type_: 2, value: 1 }, ucp_type_table { name_offset: 565, type_: 4, value: 60 }, ucp_type_table { name_offset: 572, type_: 3, value: 122 }, ucp_type_table { name_offset: 577, type_: 12, value: 7 }, ucp_type_table { name_offset: 599, type_: 12, value: 8 }, ucp_type_table { name_offset: 621, type_: 12, value: 9 }, ucp_type_table { name_offset: 643, type_: 12, value: 10 }, ucp_type_table { name_offset: 665, type_: 12, value: 11 }, ucp_type_table { name_offset: 687, type_: 4, value: 24 }, ucp_type_table { name_offset: 692, type_: 4, value: 24 }, ucp_type_table { name_offset: 701, type_: 3, value: 163 }, ucp_type_table { name_offset: 712, type_: 3, value: 163 }, ucp_type_table { name_offset: 717, type_: 12, value: 5 }, ucp_type_table { name_offset: 720, type_: 2, value: 2 }, ucp_type_table { name_offset: 723, type_: 2, value: 3 }, ucp_type_table { name_offset: 726, type_: 3, value: 99 }, ucp_type_table { name_offset: 733, type_: 4, value: 43 }, ucp_type_table { name_offset: 738, type_: 4, value: 43 }, ucp_type_table { name_offset: 745, type_: 4, value: 89 }, ucp_type_table { name_offset: 750, type_: 4, value: 41 }, ucp_type_table { name_offset: 755, type_: 2, value: 4 }, ucp_type_table { name_offset: 758, type_: 3, value: 114 }, ucp_type_table { name_offset: 768, type_: 12, value: 7 }, ucp_type_table { name_offset: 773, type_: 12, value: 8 }, ucp_type_table { name_offset: 778, type_: 12, value: 9 }, ucp_type_table { name_offset: 782, type_: 12, value: 10 }, ucp_type_table { name_offset: 786, type_: 12, value: 11 }, ucp_type_table { name_offset: 790, type_: 4, value: 41 }, ucp_type_table { name_offset: 798, type_: 4, value: 89 }, ucp_type_table { name_offset: 810, type_: 4, value: 2 }, ucp_type_table { name_offset: 819, type_: 4, value: 2 }, ucp_type_table { name_offset: 824, type_: 12, value: 12 }, ucp_type_table { name_offset: 829, type_: 12, value: 13 }, ucp_type_table { name_offset: 855, type_: 12, value: 14 }, ucp_type_table { name_offset: 859, type_: 12, value: 14 }, ucp_type_table { name_offset: 870, type_: 3, value: 105 }, ucp_type_table { name_offset: 878, type_: 4, value: 8 }, ucp_type_table { name_offset: 883, type_: 4, value: 8 }, ucp_type_table { name_offset: 894, type_: 12, value: 13 }, ucp_type_table { name_offset: 897, type_: 12, value: 15 }, ucp_type_table { name_offset: 901, type_: 12, value: 15 }, ucp_type_table { name_offset: 911, type_: 3, value: 164 }, ucp_type_table { name_offset: 916, type_: 3, value: 164 }, ucp_type_table { name_offset: 927, type_: 4, value: 83 }, ucp_type_table { name_offset: 932, type_: 4, value: 83 }, ucp_type_table { name_offset: 938, type_: 3, value: 105 }, ucp_type_table { name_offset: 943, type_: 4, value: 65 }, ucp_type_table { name_offset: 948, type_: 4, value: 65 }, ucp_type_table { name_offset: 957, type_: 12, value: 19 }, ucp_type_table { name_offset: 963, type_: 12, value: 17 }, ucp_type_table { name_offset: 969, type_: 3, value: 125 }, ucp_type_table { name_offset: 974, type_: 3, value: 125 }, ucp_type_table { name_offset: 994, type_: 4, value: 66 }, ucp_type_table { name_offset: 999, type_: 4, value: 66 }, ucp_type_table { name_offset: 1007, type_: 3, value: 160 }, ucp_type_table { name_offset: 1012, type_: 3, value: 160 }, ucp_type_table { name_offset: 1020, type_: 12, value: 18 }, ucp_type_table { name_offset: 1025, type_: 12, value: 16 }, ucp_type_table { name_offset: 1031, type_: 12, value: 17 }, ucp_type_table { name_offset: 1046, type_: 12, value: 18 }, ucp_type_table { name_offset: 1060, type_: 12, value: 19 }, ucp_type_table { name_offset: 1078, type_: 12, value: 20 }, ucp_type_table { name_offset: 1096, type_: 12, value: 20 }, ucp_type_table { name_offset: 1102, type_: 4, value: 23 }, ucp_type_table { name_offset: 1107, type_: 4, value: 23 }, ucp_type_table { name_offset: 1116, type_: 12, value: 22 }, ucp_type_table { name_offset: 1120, type_: 12, value: 21 }, ucp_type_table { name_offset: 1141, type_: 12, value: 22 }, ucp_type_table { name_offset: 1150, type_: 12, value: 21 }, ucp_type_table { name_offset: 1158, type_: 4, value: 92 }, ucp_type_table { name_offset: 1163, type_: 4, value: 92 }, ucp_type_table { name_offset: 1169, type_: 4, value: 21 }, ucp_type_table { name_offset: 1174, type_: 4, value: 21 }, ucp_type_table { name_offset: 1183, type_: 4, value: 44 }, ucp_type_table { name_offset: 1188, type_: 4, value: 44 }, ucp_type_table { name_offset: 1199, type_: 4, value: 84 }, ucp_type_table { name_offset: 1204, type_: 4, value: 82 }, ucp_type_table { name_offset: 1209, type_: 4, value: 32 }, ucp_type_table { name_offset: 1214, type_: 4, value: 32 }, ucp_type_table { name_offset: 1221, type_: 4, value: 67 }, ucp_type_table { name_offset: 1226, type_: 4, value: 67 }, ucp_type_table { name_offset: 1234, type_: 12, value: 23 }, ucp_type_table { name_offset: 1247, type_: 12, value: 24 }, ucp_type_table { name_offset: 1262, type_: 12, value: 25 }, ucp_type_table { name_offset: 1275, type_: 12, value: 23 }, ucp_type_table { name_offset: 1282, type_: 4, value: 1 }, ucp_type_table { name_offset: 1288, type_: 4, value: 1 }, ucp_type_table { name_offset: 1293, type_: 12, value: 24 }, ucp_type_table { name_offset: 1299, type_: 12, value: 25 }, ucp_type_table { name_offset: 1306, type_: 4, value: 11 }, ucp_type_table { name_offset: 1315, type_: 4, value: 11 }, ucp_type_table { name_offset: 1320, type_: 4, value: 93 }, ucp_type_table { name_offset: 1325, type_: 4, value: 84 }, ucp_type_table { name_offset: 1338, type_: 4, value: 10 }, ucp_type_table { name_offset: 1347, type_: 4, value: 10 }, ucp_type_table { name_offset: 1352, type_: 4, value: 93 }, ucp_type_table { name_offset: 1364, type_: 4, value: 30 }, ucp_type_table { name_offset: 1368, type_: 4, value: 22 }, ucp_type_table { name_offset: 1373, type_: 4, value: 22 }, ucp_type_table { name_offset: 1380, type_: 4, value: 30 }, ucp_type_table { name_offset: 1385, type_: 4, value: 85 }, ucp_type_table { name_offset: 1400, type_: 4, value: 34 }, ucp_type_table { name_offset: 1405, type_: 4, value: 34 }, ucp_type_table { name_offset: 1413, type_: 3, value: 149 }, ucp_type_table { name_offset: 1418, type_: 3, value: 149 }, ucp_type_table { name_offset: 1425, type_: 4, value: 4 }, ucp_type_table { name_offset: 1430, type_: 4, value: 4 }, ucp_type_table { name_offset: 1437, type_: 12, value: 26 }, ucp_type_table { name_offset: 1441, type_: 12, value: 26 }, ucp_type_table { name_offset: 1450, type_: 4, value: 27 }, ucp_type_table { name_offset: 1455, type_: 4, value: 27 }, ucp_type_table { name_offset: 1464, type_: 3, value: 148 }, ucp_type_table { name_offset: 1469, type_: 3, value: 138 }, ucp_type_table { name_offset: 1474, type_: 3, value: 161 }, ucp_type_table { name_offset: 1479, type_: 4, value: 78 }, ucp_type_table { name_offset: 1484, type_: 12, value: 32 }, ucp_type_table { name_offset: 1488, type_: 12, value: 30 }, ucp_type_table { name_offset: 1509, type_: 12, value: 31 }, ucp_type_table { name_offset: 1527, type_: 12, value: 32 }, ucp_type_table { name_offset: 1538, type_: 12, value: 34 }, ucp_type_table { name_offset: 1543, type_: 12, value: 34 }, ucp_type_table { name_offset: 1555, type_: 12, value: 33 }, ucp_type_table { name_offset: 1559, type_: 12, value: 27 }, ucp_type_table { name_offset: 1564, type_: 12, value: 27 }, ucp_type_table { name_offset: 1582, type_: 12, value: 28 }, ucp_type_table { name_offset: 1587, type_: 12, value: 33 }, ucp_type_table { name_offset: 1595, type_: 12, value: 28 }, ucp_type_table { name_offset: 1614, type_: 12, value: 29 }, ucp_type_table { name_offset: 1619, type_: 12, value: 29 }, ucp_type_table { name_offset: 1636, type_: 3, value: 128 }, ucp_type_table { name_offset: 1652, type_: 12, value: 35 }, ucp_type_table { name_offset: 1657, type_: 3, value: 106 }, ucp_type_table { name_offset: 1667, type_: 3, value: 131 }, ucp_type_table { name_offset: 1688, type_: 3, value: 130 }, ucp_type_table { name_offset: 1710, type_: 3, value: 104 }, ucp_type_table { name_offset: 1715, type_: 4, value: 56 }, ucp_type_table { name_offset: 1720, type_: 4, value: 56 }, ucp_type_table { name_offset: 1729, type_: 12, value: 36 }, ucp_type_table { name_offset: 1735, type_: 12, value: 36 }, ucp_type_table { name_offset: 1747, type_: 4, value: 58 }, ucp_type_table { name_offset: 1754, type_: 4, value: 49 }, ucp_type_table { name_offset: 1759, type_: 4, value: 28 }, ucp_type_table { name_offset: 1764, type_: 4, value: 15 }, ucp_type_table { name_offset: 1772, type_: 4, value: 28 }, ucp_type_table { name_offset: 1781, type_: 3, value: 168 }, ucp_type_table { name_offset: 1786, type_: 4, value: 49 }, ucp_type_table { name_offset: 1794, type_: 3, value: 112 }, ucp_type_table { name_offset: 1799, type_: 3, value: 112 }, ucp_type_table { name_offset: 1810, type_: 3, value: 165 }, ucp_type_table { name_offset: 1828, type_: 3, value: 103 }, ucp_type_table { name_offset: 1834, type_: 3, value: 103 }, ucp_type_table { name_offset: 1839, type_: 4, value: 68 }, ucp_type_table { name_offset: 1844, type_: 4, value: 68 }, ucp_type_table { name_offset: 1851, type_: 4, value: 75 }, ucp_type_table { name_offset: 1861, type_: 3, value: 170 }, ucp_type_table { name_offset: 1870, type_: 3, value: 165 }, ucp_type_table { name_offset: 1875, type_: 4, value: 15 }, ucp_type_table { name_offset: 1880, type_: 3, value: 170 }, ucp_type_table { name_offset: 1885, type_: 4, value: 58 }, ucp_type_table { name_offset: 1890, type_: 1, value: 1 }, ucp_type_table { name_offset: 1892, type_: 0, value: 0 }, ucp_type_table { name_offset: 1895, type_: 3, value: 123 }, ucp_type_table { name_offset: 1900, type_: 3, value: 100 }, ucp_type_table { name_offset: 1904, type_: 3, value: 100 }, ucp_type_table { name_offset: 1909, type_: 4, value: 0 }, ucp_type_table { name_offset: 1915, type_: 4, value: 0 }, ucp_type_table { name_offset: 1920, type_: 0, value: 0 }, ucp_type_table { name_offset: 1923, type_: 3, value: 117 }, ucp_type_table { name_offset: 1928, type_: 3, value: 117 }, ucp_type_table { name_offset: 1935, type_: 4, value: 37 }, ucp_type_table { name_offset: 1940, type_: 4, value: 37 }, ucp_type_table { name_offset: 1946, type_: 4, value: 69 }, ucp_type_table { name_offset: 1951, type_: 4, value: 39 }, ucp_type_table { name_offset: 1956, type_: 4, value: 69 }, ucp_type_table { name_offset: 1964, type_: 4, value: 39 }, ucp_type_table { name_offset: 1972, type_: 4, value: 55 }, ucp_type_table { name_offset: 1977, type_: 2, value: 5 }, ucp_type_table { name_offset: 1980, type_: 2, value: 6 }, ucp_type_table { name_offset: 1983, type_: 2, value: 7 }, ucp_type_table { name_offset: 1986, type_: 12, value: 37 }, ucp_type_table { name_offset: 1990, type_: 12, value: 37 }, ucp_type_table { name_offset: 2012, type_: 12, value: 38 }, ucp_type_table { name_offset: 2018, type_: 12, value: 38 }, ucp_type_table { name_offset: 2028, type_: 2, value: 8 }, ucp_type_table { name_offset: 2031, type_: 2, value: 9 }, ucp_type_table { name_offset: 2034, type_: 4, value: 50 }, ucp_type_table { name_offset: 2039, type_: 4, value: 50 }, ucp_type_table { name_offset: 2046, type_: 4, value: 52 }, ucp_type_table { name_offset: 2051, type_: 4, value: 52 }, ucp_type_table { name_offset: 2058, type_: 1, value: 2 }, ucp_type_table { name_offset: 2060, type_: 4, value: 70 }, ucp_type_table { name_offset: 2069, type_: 4, value: 70 }, ucp_type_table { name_offset: 2074, type_: 3, value: 157 }, ucp_type_table { name_offset: 2079, type_: 3, value: 157 }, ucp_type_table { name_offset: 2087, type_: 4, value: 16 }, ucp_type_table { name_offset: 2097, type_: 4, value: 59 }, ucp_type_table { name_offset: 2102, type_: 4, value: 59 }, ucp_type_table { name_offset: 2110, type_: 4, value: 71 }, ucp_type_table { name_offset: 2115, type_: 4, value: 71 }, ucp_type_table { name_offset: 2126, type_: 3, value: 152 }, ucp_type_table { name_offset: 2131, type_: 3, value: 152 }, ucp_type_table { name_offset: 2139, type_: 4, value: 82 }, ucp_type_table { name_offset: 2152, type_: 12, value: 39 }, ucp_type_table { name_offset: 2157, type_: 2, value: 10 }, ucp_type_table { name_offset: 2160, type_: 12, value: 40 }, ucp_type_table { name_offset: 2164, type_: 2, value: 11 }, ucp_type_table { name_offset: 2167, type_: 3, value: 158 }, ucp_type_table { name_offset: 2179, type_: 3, value: 158 }, ucp_type_table { name_offset: 2184, type_: 3, value: 127 }, ucp_type_table { name_offset: 2196, type_: 3, value: 139 }, ucp_type_table { name_offset: 2201, type_: 3, value: 139 }, ucp_type_table { name_offset: 2214, type_: 3, value: 134 }, ucp_type_table { name_offset: 2219, type_: 4, value: 61 }, ucp_type_table { name_offset: 2224, type_: 3, value: 134 }, ucp_type_table { name_offset: 2240, type_: 4, value: 61 }, ucp_type_table { name_offset: 2260, type_: 3, value: 135 }, ucp_type_table { name_offset: 2265, type_: 4, value: 16 }, ucp_type_table { name_offset: 2270, type_: 2, value: 12 }, ucp_type_table { name_offset: 2273, type_: 4, value: 72 }, ucp_type_table { name_offset: 2278, type_: 12, value: 40 }, ucp_type_table { name_offset: 2300, type_: 4, value: 26 }, ucp_type_table { name_offset: 2305, type_: 4, value: 26 }, ucp_type_table { name_offset: 2315, type_: 3, value: 140 }, ucp_type_table { name_offset: 2319, type_: 3, value: 140 }, ucp_type_table { name_offset: 2324, type_: 3, value: 127 }, ucp_type_table { name_offset: 2329, type_: 4, value: 77 }, ucp_type_table { name_offset: 2334, type_: 4, value: 77 }, ucp_type_table { name_offset: 2342, type_: 4, value: 20 }, ucp_type_table { name_offset: 2350, type_: 4, value: 20 }, ucp_type_table { name_offset: 2355, type_: 1, value: 3 }, ucp_type_table { name_offset: 2357, type_: 3, value: 142 }, ucp_type_table { name_offset: 2367, type_: 3, value: 169 }, ucp_type_table { name_offset: 2372, type_: 3, value: 169 }, ucp_type_table { name_offset: 2383, type_: 4, value: 87 }, ucp_type_table { name_offset: 2388, type_: 4, value: 87 }, ucp_type_table { name_offset: 2400, type_: 3, value: 141 }, ucp_type_table { name_offset: 2405, type_: 3, value: 142 }, ucp_type_table { name_offset: 2410, type_: 12, value: 41 }, ucp_type_table { name_offset: 2416, type_: 2, value: 13 }, ucp_type_table { name_offset: 2419, type_: 3, value: 153 }, ucp_type_table { name_offset: 2424, type_: 3, value: 110 }, ucp_type_table { name_offset: 2434, type_: 4, value: 48 }, ucp_type_table { name_offset: 2438, type_: 4, value: 48 }, ucp_type_table { name_offset: 2443, type_: 2, value: 14 }, ucp_type_table { name_offset: 2446, type_: 2, value: 15 }, ucp_type_table { name_offset: 2449, type_: 12, value: 41 }, ucp_type_table { name_offset: 2471, type_: 3, value: 154 }, ucp_type_table { name_offset: 2476, type_: 3, value: 154 }, ucp_type_table { name_offset: 2482, type_: 3, value: 161 }, ucp_type_table { name_offset: 2503, type_: 3, value: 102 }, ucp_type_table { name_offset: 2508, type_: 3, value: 102 }, ucp_type_table { name_offset: 2514, type_: 3, value: 118 }, ucp_type_table { name_offset: 2522, type_: 3, value: 118 }, ucp_type_table { name_offset: 2527, type_: 4, value: 78 }, ucp_type_table { name_offset: 2540, type_: 3, value: 104 }, ucp_type_table { name_offset: 2550, type_: 3, value: 141 }, ucp_type_table { name_offset: 2566, type_: 4, value: 73 }, ucp_type_table { name_offset: 2576, type_: 3, value: 111 }, ucp_type_table { name_offset: 2587, type_: 3, value: 159 }, ucp_type_table { name_offset: 2598, type_: 3, value: 129 }, ucp_type_table { name_offset: 2614, type_: 4, value: 57 }, ucp_type_table { name_offset: 2624, type_: 4, value: 90 }, ucp_type_table { name_offset: 2634, type_: 4, value: 94 }, ucp_type_table { name_offset: 2641, type_: 4, value: 94 }, ucp_type_table { name_offset: 2646, type_: 4, value: 12 }, ucp_type_table { name_offset: 2652, type_: 4, value: 57 }, ucp_type_table { name_offset: 2657, type_: 4, value: 12 }, ucp_type_table { name_offset: 2662, type_: 4, value: 80 }, ucp_type_table { name_offset: 2668, type_: 4, value: 80 }, ucp_type_table { name_offset: 2673, type_: 3, value: 108 }, ucp_type_table { name_offset: 2678, type_: 3, value: 108 }, ucp_type_table { name_offset: 2686, type_: 4, value: 90 }, ucp_type_table { name_offset: 2691, type_: 1, value: 4 }, ucp_type_table { name_offset: 2693, type_: 3, value: 138 }, ucp_type_table { name_offset: 2705, type_: 3, value: 143 }, ucp_type_table { name_offset: 2710, type_: 3, value: 143 }, ucp_type_table { name_offset: 2720, type_: 12, value: 42 }, ucp_type_table { name_offset: 2727, type_: 12, value: 42 }, ucp_type_table { name_offset: 2741, type_: 12, value: 43 }, ucp_type_table { name_offset: 2759, type_: 12, value: 43 }, ucp_type_table { name_offset: 2765, type_: 3, value: 144 }, ucp_type_table { name_offset: 2770, type_: 3, value: 144 }, ucp_type_table { name_offset: 2780, type_: 2, value: 16 }, ucp_type_table { name_offset: 2783, type_: 12, value: 44 }, ucp_type_table { name_offset: 2787, type_: 2, value: 17 }, ucp_type_table { name_offset: 2790, type_: 2, value: 18 }, ucp_type_table { name_offset: 2793, type_: 4, value: 73 }, ucp_type_table { name_offset: 2798, type_: 2, value: 19 }, ucp_type_table { name_offset: 2801, type_: 4, value: 47 }, ucp_type_table { name_offset: 2806, type_: 4, value: 47 }, ucp_type_table { name_offset: 2814, type_: 3, value: 131 }, ucp_type_table { name_offset: 2819, type_: 4, value: 74 }, ucp_type_table { name_offset: 2824, type_: 3, value: 115 }, ucp_type_table { name_offset: 2829, type_: 3, value: 115 }, ucp_type_table { name_offset: 2840, type_: 2, value: 20 }, ucp_type_table { name_offset: 2843, type_: 3, value: 135 }, ucp_type_table { name_offset: 2848, type_: 2, value: 21 }, ucp_type_table { name_offset: 2851, type_: 12, value: 44 }, ucp_type_table { name_offset: 2878, type_: 3, value: 130 }, ucp_type_table { name_offset: 2883, type_: 2, value: 22 }, ucp_type_table { name_offset: 2886, type_: 4, value: 74 }, ucp_type_table { name_offset: 2901, type_: 4, value: 43 }, ucp_type_table { name_offset: 2906, type_: 3, value: 106 }, ucp_type_table { name_offset: 2911, type_: 12, value: 45 }, ucp_type_table { name_offset: 2917, type_: 12, value: 45 }, ucp_type_table { name_offset: 2931, type_: 12, value: 46 }, ucp_type_table { name_offset: 2939, type_: 12, value: 47 }, ucp_type_table { name_offset: 2957, type_: 3, value: 121 }, ucp_type_table { name_offset: 2964, type_: 12, value: 47 }, ucp_type_table { name_offset: 2967, type_: 3, value: 121 }, ucp_type_table { name_offset: 2972, type_: 4, value: 85 }, ucp_type_table { name_offset: 2977, type_: 4, value: 25 }, ucp_type_table { name_offset: 2983, type_: 4, value: 25 }, ucp_type_table { name_offset: 2988, type_: 1, value: 5 }, ucp_type_table { name_offset: 2990, type_: 4, value: 54 }, ucp_type_table { name_offset: 3000, type_: 4, value: 54 }, ucp_type_table { name_offset: 3005, type_: 3, value: 129 }, ucp_type_table { name_offset: 3010, type_: 3, value: 120 }, ucp_type_table { name_offset: 3015, type_: 3, value: 120 }, ucp_type_table { name_offset: 3026, type_: 2, value: 23 }, ucp_type_table { name_offset: 3029, type_: 12, value: 49 }, ucp_type_table { name_offset: 3032, type_: 12, value: 48 }, ucp_type_table { name_offset: 3049, type_: 3, value: 150 }, ucp_type_table { name_offset: 3054, type_: 4, value: 62 }, ucp_type_table { name_offset: 3062, type_: 4, value: 40 }, ucp_type_table { name_offset: 3070, type_: 4, value: 40 }, ucp_type_table { name_offset: 3075, type_: 4, value: 62 }, ucp_type_table { name_offset: 3080, type_: 3, value: 145 }, ucp_type_table { name_offset: 3085, type_: 3, value: 145 }, ucp_type_table { name_offset: 3093, type_: 3, value: 150 }, ucp_type_table { name_offset: 3105, type_: 4, value: 75 }, ucp_type_table { name_offset: 3110, type_: 4, value: 17 }, ucp_type_table { name_offset: 3115, type_: 4, value: 17 }, ucp_type_table { name_offset: 3123, type_: 2, value: 24 }, ucp_type_table { name_offset: 3126, type_: 2, value: 25 }, ucp_type_table { name_offset: 3129, type_: 2, value: 26 }, ucp_type_table { name_offset: 3132, type_: 12, value: 49 }, ucp_type_table { name_offset: 3143, type_: 4, value: 86 }, ucp_type_table { name_offset: 3148, type_: 4, value: 86 }, ucp_type_table { name_offset: 3156, type_: 3, value: 159 }, ucp_type_table { name_offset: 3161, type_: 3, value: 136 }, ucp_type_table { name_offset: 3166, type_: 3, value: 136 }, ucp_type_table { name_offset: 3178, type_: 3, value: 155 }, ucp_type_table { name_offset: 3183, type_: 3, value: 155 }, ucp_type_table { name_offset: 3191, type_: 12, value: 54 }, ucp_type_table { name_offset: 3197, type_: 12, value: 48 }, ucp_type_table { name_offset: 3203, type_: 3, value: 116 }, ucp_type_table { name_offset: 3208, type_: 3, value: 116 }, ucp_type_table { name_offset: 3218, type_: 4, value: 95 }, ucp_type_table { name_offset: 3223, type_: 4, value: 95 }, ucp_type_table { name_offset: 3231, type_: 4, value: 46 }, ucp_type_table { name_offset: 3236, type_: 4, value: 46 }, ucp_type_table { name_offset: 3248, type_: 4, value: 6 }, ucp_type_table { name_offset: 3253, type_: 4, value: 6 }, ucp_type_table { name_offset: 3260, type_: 4, value: 33 }, ucp_type_table { name_offset: 3268, type_: 4, value: 36 }, ucp_type_table { name_offset: 3273, type_: 4, value: 36 }, ucp_type_table { name_offset: 3282, type_: 4, value: 38 }, ucp_type_table { name_offset: 3288, type_: 3, value: 123 }, ucp_type_table { name_offset: 3296, type_: 3, value: 124 }, ucp_type_table { name_offset: 3304, type_: 4, value: 63 }, ucp_type_table { name_offset: 3309, type_: 4, value: 63 }, ucp_type_table { name_offset: 3315, type_: 4, value: 38 }, ucp_type_table { name_offset: 3320, type_: 3, value: 110 }, ucp_type_table { name_offset: 3325, type_: 4, value: 13 }, ucp_type_table { name_offset: 3331, type_: 4, value: 13 }, ucp_type_table { name_offset: 3336, type_: 4, value: 81 }, ucp_type_table { name_offset: 3341, type_: 3, value: 166 }, ucp_type_table { name_offset: 3348, type_: 4, value: 81 }, ucp_type_table { name_offset: 3355, type_: 3, value: 124 }, ucp_type_table { name_offset: 3360, type_: 4, value: 14 }, ucp_type_table { name_offset: 3365, type_: 4, value: 14 }, ucp_type_table { name_offset: 3372, type_: 12, value: 50 }, ucp_type_table { name_offset: 3377, type_: 12, value: 50 }, ucp_type_table { name_offset: 3397, type_: 4, value: 45 }, ucp_type_table { name_offset: 3402, type_: 4, value: 33 }, ucp_type_table { name_offset: 3407, type_: 4, value: 7 }, ucp_type_table { name_offset: 3412, type_: 4, value: 7 }, ucp_type_table { name_offset: 3419, type_: 4, value: 18 }, ucp_type_table { name_offset: 3424, type_: 4, value: 19 }, ucp_type_table { name_offset: 3432, type_: 4, value: 19 }, ucp_type_table { name_offset: 3437, type_: 4, value: 45 }, ucp_type_table { name_offset: 3446, type_: 4, value: 76 }, ucp_type_table { name_offset: 3451, type_: 4, value: 76 }, ucp_type_table { name_offset: 3459, type_: 3, value: 166 }, ucp_type_table { name_offset: 3464, type_: 4, value: 96 }, ucp_type_table { name_offset: 3471, type_: 4, value: 96 }, ucp_type_table { name_offset: 3476, type_: 4, value: 91 }, ucp_type_table { name_offset: 3481, type_: 4, value: 97 }, ucp_type_table { name_offset: 3494, type_: 4, value: 97 }, ucp_type_table { name_offset: 3499, type_: 3, value: 107 }, ucp_type_table { name_offset: 3504, type_: 3, value: 107 }, ucp_type_table { name_offset: 3513, type_: 12, value: 51 }, ucp_type_table { name_offset: 3519, type_: 12, value: 51 }, ucp_type_table { name_offset: 3536, type_: 3, value: 98 }, ucp_type_table { name_offset: 3544, type_: 12, value: 52 }, ucp_type_table { name_offset: 3550, type_: 12, value: 52 }, ucp_type_table { name_offset: 3560, type_: 3, value: 119 }, ucp_type_table { name_offset: 3564, type_: 3, value: 119 }, ucp_type_table { name_offset: 3569, type_: 12, value: 53 }, ucp_type_table { name_offset: 3587, type_: 3, value: 167 }, ucp_type_table { name_offset: 3592, type_: 3, value: 167 }, ucp_type_table { name_offset: 3601, type_: 12, value: 53 }, ucp_type_table { name_offset: 3604, type_: 3, value: 162 }, ucp_type_table { name_offset: 3611, type_: 3, value: 146 }, ucp_type_table { name_offset: 3616, type_: 3, value: 146 }, ucp_type_table { name_offset: 3627, type_: 3, value: 162 }, ucp_type_table { name_offset: 3632, type_: 12, value: 54 }, ucp_type_table { name_offset: 3643, type_: 12, value: 54 }, ucp_type_table { name_offset: 3650, type_: 5, value: 0 }, ucp_type_table { name_offset: 3654, type_: 12, value: 55 }, ucp_type_table { name_offset: 3659, type_: 12, value: 55 }, ucp_type_table { name_offset: 3671, type_: 12, value: 56 }, ucp_type_table { name_offset: 3676, type_: 12, value: 56 }, ucp_type_table { name_offset: 3685, type_: 3, value: 111 }, ucp_type_table { name_offset: 3690, type_: 7, value: 0 }, ucp_type_table { name_offset: 3694, type_: 6, value: 0 }, ucp_type_table { name_offset: 3698, type_: 3, value: 114 }, ucp_type_table { name_offset: 3703, type_: 10, value: 0 }, ucp_type_table { name_offset: 3707, type_: 8, value: 0 }, ucp_type_table { name_offset: 3711, type_: 4, value: 88 }, ucp_type_table { name_offset: 3716, type_: 4, value: 88 }, ucp_type_table { name_offset: 3723, type_: 4, value: 31 }, ucp_type_table { name_offset: 3726, type_: 4, value: 31 }, ucp_type_table { name_offset: 3731, type_: 1, value: 6 }, ucp_type_table { name_offset: 3733, type_: 3, value: 156 }, ucp_type_table { name_offset: 3749, type_: 3, value: 156 }, ucp_type_table { name_offset: 3754, type_: 3, value: 106 }, ucp_type_table { name_offset: 3759, type_: 2, value: 27 }, ucp_type_table { name_offset: 3762, type_: 2, value: 28 }, ucp_type_table { name_offset: 3765, type_: 2, value: 29 }, ucp_type_table { name_offset: 3768, type_: 3, value: 99 }, ucp_type_table { name_offset: 3773, type_: 3, value: 98 }]

pub let utt_size: c_ulong = 510

pub var unicode_version: *const i8 = c"16.0.0".ptr as *const i8

pub let ucd_caseless_sets: [118]c_uint = [0xffffffff, 0x0053, 0x0073, 0x017f, 0xffffffff, 0x01c4, 0x01c5, 0x01c6, 0xffffffff, 0x01c7, 0x01c8, 0x01c9, 0xffffffff, 0x01ca, 0x01cb, 0x01cc, 0xffffffff, 0x01f1, 0x01f2, 0x01f3, 0xffffffff, 0x0345, 0x0399, 0x03b9, 0x1fbe, 0xffffffff, 0x00b5, 0x039c, 0x03bc, 0xffffffff, 0x03a3, 0x03c2, 0x03c3, 0xffffffff, 0x0392, 0x03b2, 0x03d0, 0xffffffff, 0x0398, 0x03b8, 0x03d1, 0x03f4, 0xffffffff, 0x03a6, 0x03c6, 0x03d5, 0xffffffff, 0x03a0, 0x03c0, 0x03d6, 0xffffffff, 0x039a, 0x03ba, 0x03f0, 0xffffffff, 0x03a1, 0x03c1, 0x03f1, 0xffffffff, 0x0395, 0x03b5, 0x03f5, 0xffffffff, 0x0412, 0x0432, 0x1c80, 0xffffffff, 0x0414, 0x0434, 0x1c81, 0xffffffff, 0x041e, 0x043e, 0x1c82, 0xffffffff, 0x0421, 0x0441, 0x1c83, 0xffffffff, 0x0422, 0x0442, 0x1c84, 0x1c85, 0xffffffff, 0x042a, 0x044a, 0x1c86, 0xffffffff, 0x0462, 0x0463, 0x1c87, 0xffffffff, 0x1e60, 0x1e61, 0x1e9b, 0xffffffff, 0x03a9, 0x03c9, 0x2126, 0xffffffff, 0x004b, 0x006b, 0x212a, 0xffffffff, 0x00c5, 0x00e5, 0x212b, 0xffffffff, 0x1c88, 0xa64a, 0xa64b, 0xffffffff, 0x0069, 0x0130, 0xffffffff, 0x0049, 0x0131, 0xffffffff]

pub let ucd_turkish_dotted_i_caseset: c_uint = 112

pub let CLOCKS_PER_SEC: c_ulong = (1000000 as c_ulong)
pub let TIME_UTC: c_int = 1
pub let LC_COLLATE_MASK: c_int = (1 << 0)
pub let LC_CTYPE_MASK: c_int = (1 << 1)
pub let LC_MESSAGES_MASK: c_int = (1 << 2)
pub let LC_MONETARY_MASK: c_int = (1 << 3)
pub let LC_NUMERIC_MASK: c_int = (1 << 4)
pub let LC_TIME_MASK: c_int = (1 << 5)
pub let LC_GLOBAL_LOCALE: *mut c_void = (-1 as *mut c_void)
pub let LC_ALL: c_int = 0
pub let LC_COLLATE: c_int = 1
pub let LC_CTYPE: c_int = 2
pub let LC_MONETARY: c_int = 3
pub let LC_NUMERIC: c_int = 4
pub let LC_TIME: c_int = 5
pub let LC_MESSAGES: c_int = 6
pub let EPERM: c_int = 1
pub let ENOENT: c_int = 2
pub let ESRCH: c_int = 3
pub let EINTR: c_int = 4
pub let EIO: c_int = 5
pub let ENXIO: c_int = 6
pub let E2BIG: c_int = 7
pub let ENOEXEC: c_int = 8
pub let EBADF: c_int = 9
pub let ECHILD: c_int = 10
pub let EDEADLK: c_int = 11
pub let ENOMEM: c_int = 12
pub let EACCES: c_int = 13
pub let EFAULT: c_int = 14
pub let ENOTBLK: c_int = 15
pub let EBUSY: c_int = 16
pub let EEXIST: c_int = 17
pub let EXDEV: c_int = 18
pub let ENODEV: c_int = 19
pub let ENOTDIR: c_int = 20
pub let EISDIR: c_int = 21
pub let EINVAL: c_int = 22
pub let ENFILE: c_int = 23
pub let EMFILE: c_int = 24
pub let ENOTTY: c_int = 25
pub let ETXTBSY: c_int = 26
pub let EFBIG: c_int = 27
pub let ENOSPC: c_int = 28
pub let ESPIPE: c_int = 29
pub let EROFS: c_int = 30
pub let EMLINK: c_int = 31
pub let EPIPE: c_int = 32
pub let EDOM: c_int = 33
pub let ERANGE: c_int = 34
pub let EAGAIN: c_int = 35
pub let EWOULDBLOCK: c_int = 35
pub let EINPROGRESS: c_int = 36
pub let EALREADY: c_int = 37
pub let ENOTSOCK: c_int = 38
pub let EDESTADDRREQ: c_int = 39
pub let EMSGSIZE: c_int = 40
pub let EPROTOTYPE: c_int = 41
pub let ENOPROTOOPT: c_int = 42
pub let EPROTONOSUPPORT: c_int = 43
pub let ESOCKTNOSUPPORT: c_int = 44
pub let ENOTSUP: c_int = 45
pub let EPFNOSUPPORT: c_int = 46
pub let EAFNOSUPPORT: c_int = 47
pub let EADDRINUSE: c_int = 48
pub let EADDRNOTAVAIL: c_int = 49
pub let ENETDOWN: c_int = 50
pub let ENETUNREACH: c_int = 51
pub let ENETRESET: c_int = 52
pub let ECONNABORTED: c_int = 53
pub let ECONNRESET: c_int = 54
pub let ENOBUFS: c_int = 55
pub let EISCONN: c_int = 56
pub let ENOTCONN: c_int = 57
pub let ESHUTDOWN: c_int = 58
pub let ETOOMANYREFS: c_int = 59
pub let ETIMEDOUT: c_int = 60
pub let ECONNREFUSED: c_int = 61
pub let ELOOP: c_int = 62
pub let ENAMETOOLONG: c_int = 63
pub let EHOSTDOWN: c_int = 64
pub let EHOSTUNREACH: c_int = 65
pub let ENOTEMPTY: c_int = 66
pub let EPROCLIM: c_int = 67
pub let EUSERS: c_int = 68
pub let EDQUOT: c_int = 69
pub let ESTALE: c_int = 70
pub let EREMOTE: c_int = 71
pub let EBADRPC: c_int = 72
pub let ERPCMISMATCH: c_int = 73
pub let EPROGUNAVAIL: c_int = 74
pub let EPROGMISMATCH: c_int = 75
pub let EPROCUNAVAIL: c_int = 76
pub let ENOLCK: c_int = 77
pub let ENOSYS: c_int = 78
pub let EFTYPE: c_int = 79
pub let EAUTH: c_int = 80
pub let ENEEDAUTH: c_int = 81
pub let EPWROFF: c_int = 82
pub let EDEVERR: c_int = 83
pub let EOVERFLOW: c_int = 84
pub let EBADEXEC: c_int = 85
pub let EBADARCH: c_int = 86
pub let ESHLIBVERS: c_int = 87
pub let EBADMACHO: c_int = 88
pub let ECANCELED: c_int = 89
pub let EIDRM: c_int = 90
pub let ENOMSG: c_int = 91
pub let EILSEQ: c_int = 92
pub let ENOATTR: c_int = 93
pub let EBADMSG: c_int = 94
pub let EMULTIHOP: c_int = 95
pub let ENODATA: c_int = 96
pub let ENOLINK: c_int = 97
pub let ENOSR: c_int = 98
pub let ENOSTR: c_int = 99
pub let EPROTO: c_int = 100
pub let ETIME: c_int = 101
pub let EOPNOTSUPP: c_int = 102
pub let ENOPOLICY: c_int = 103
pub let ENOTRECOVERABLE: c_int = 104
pub let EOWNERDEAD: c_int = 105
pub let EQFULL: c_int = 106
pub let ENOTCAPABLE: c_int = 107
pub let ELAST: c_int = 107
pub let F_OK: c_int = 0
pub let X_OK: c_int = (1 << 0)
pub let W_OK: c_int = (1 << 1)
pub let R_OK: c_int = (1 << 2)
pub let L_SET: c_int = 0
pub let L_INCR: c_int = 1
pub let L_XTND: c_int = 2
pub let ACCESSX_MAX_DESCRIPTORS: c_int = 100
pub let ACCESSX_MAX_TABLESIZE: c_int = (16 * 1024)
pub let STDIN_FILENO: c_int = 0
pub let STDOUT_FILENO: c_int = 1
pub let STDERR_FILENO: c_int = 2
pub let F_ULOCK: c_int = 0
pub let F_LOCK: c_int = 1
pub let F_TLOCK: c_int = 2
pub let F_TEST: c_int = 3
pub let SYNC_VOLUME_FULLSYNC: c_int = 0x01
pub let SYNC_VOLUME_WAIT: c_int = 0x02
pub let ITIMER_REAL: c_int = 0
pub let ITIMER_VIRTUAL: c_int = 1
pub let ITIMER_PROF: c_int = 2
pub let DST_NONE: c_int = 0
pub let DST_USA: c_int = 1
pub let DST_AUST: c_int = 2
pub let DST_WET: c_int = 3
pub let DST_MET: c_int = 4
pub let DST_EET: c_int = 5
pub let DST_CAN: c_int = 6
pub let INPUT_MODE = "rb"
pub let OUTPUT_MODE = "wb"
pub let BINARY_INPUT_MODE = "rb"
pub let BINARY_OUTPUT_MODE = "wb"
pub let PTR_FORM = "td"
pub let SIZ_FORM = "zu"
pub fn G[T](a: T, b: T) -> T {
    glue(a, b)
}
pub fn stringify(x: str) -> str {
    x
}
pub fn STR[T](x: T) -> T {
    stringify(x)
}
pub let CFORE_UNSET: c_uint = 4294967295
pub let CONVERT_UNSET: c_uint = 4294967295
pub let MOD_STR_UNSET: c_int = 255
pub let DFA_WS_DIMENSION: c_int = 1000
pub let DEFAULT_OVECCOUNT: c_int = 15
pub let JUNK_OFFSET: c_uint = 0xdeadbeef
pub let LOCALESIZE: c_int = 32
pub let LOOPREPEAT: c_int = 500000
pub let MALLOCLISTSIZE: c_int = 20
pub let PARENS_NEST_DEFAULT: c_int = 220
pub let PATSTACKSIZE: c_int = 20
pub let REPLACE_MODSIZE: c_int = 100
pub let SUBSTITUTE_SUBJECT_MODSIZE: c_int = 100
pub let VERSION_SIZE: c_int = 64
pub let REPLACE_BUFFSIZE: c_int = 256
pub let JIT_DEFAULT: c_uint = 7
pub let PCRE2TEST_MODE_8: c_int = 8
pub let EBCDIC_IO: c_int = 0
pub fn PRINTABLE[T](c: T) -> T {
    ((c >= 32) and (c < 127))
}
pub fn CHAR_OUTPUT[T](c: T) -> T {
    c
}
pub fn CHAR_OUTPUT_HEX[T](c: T) -> T {
    CHAR_OUTPUT(c)
}
pub fn CHAR_INPUT[T](c: T) -> T {
    c
}
pub fn CHAR_INPUT_HEX[T](c: T) -> T {
    CHAR_INPUT(c)
}
pub fn U32OVERFLOW[T](x: T) -> T {
    (x > 4294967295)
}
pub fn S32OVERFLOW[T](x: T) -> T {
    ((x > 2147483647) or (x < INT32_MIN))
}
pub let DEFAULT_TEST_MODE: c_int = 8
pub let cmdlistcount: c_ulong = 12
pub let convertlistcount: c_ulong = 6
pub let CTL_AFTERTEXT: c_uint = 0x00000001
pub let CTL_ALLAFTERTEXT: c_uint = 0x00000002
pub let CTL_ALLCAPTURES: c_uint = 0x00000004
pub let CTL_ALLUSEDTEXT: c_uint = 0x00000008
pub let CTL_ALTGLOBAL: c_uint = 0x00000010
pub let CTL_BINCODE: c_uint = 0x00000020
pub let CTL_CALLOUT_CAPTURE: c_uint = 0x00000040
pub let CTL_CALLOUT_INFO: c_uint = 0x00000080
pub let CTL_CALLOUT_NONE: c_uint = 0x00000100
pub let CTL_DFA: c_uint = 0x00000200
pub let CTL_EXPAND: c_uint = 0x00000400
pub let CTL_FINDLIMITS: c_uint = 0x00000800
pub let CTL_FINDLIMITS_NOHEAP: c_uint = 0x00001000
pub let CTL_FULLBINCODE: c_uint = 0x00002000
pub let CTL_GETALL: c_uint = 0x00004000
pub let CTL_GLOBAL: c_uint = 0x00008000
pub let CTL_HEXPAT: c_uint = 0x00010000
pub let CTL_INFO: c_uint = 0x00020000
pub let CTL_JITFAST: c_uint = 0x00040000
pub let CTL_JITVERIFY: c_uint = 0x00080000
pub let CTL_MARK: c_uint = 0x00100000
pub let CTL_MEMORY: c_uint = 0x00200000
pub let CTL_NULLCONTEXT: c_uint = 0x00400000
pub let CTL_POSIX: c_uint = 0x00800000
pub let CTL_POSIX_NOSUB: c_uint = 0x01000000
pub let CTL_PUSH: c_uint = 0x02000000
pub let CTL_PUSHCOPY: c_uint = 0x04000000
pub let CTL_PUSHTABLESCOPY: c_uint = 0x08000000
pub let CTL_STARTCHAR: c_uint = 0x10000000
pub let CTL_USE_LENGTH: c_uint = 0x20000000
pub let CTL_UTF8_INPUT: c_uint = 0x40000000
pub let CTL_ZERO_TERMINATE: c_uint = 0x80000000
pub let CTL_DEBUG: c_uint = 139264
pub let CTL_ANYGLOB: c_uint = 32784
pub let CTL2_SUBSTITUTE_CALLOUT: c_uint = 0x00000001
pub let CTL2_SUBSTITUTE_EXTENDED: c_uint = 0x00000002
pub let CTL2_SUBSTITUTE_LITERAL: c_uint = 0x00000004
pub let CTL2_SUBSTITUTE_MATCHED: c_uint = 0x00000008
pub let CTL2_SUBSTITUTE_OVERFLOW_LENGTH: c_uint = 0x00000010
pub let CTL2_SUBSTITUTE_REPLACEMENT_ONLY: c_uint = 0x00000020
pub let CTL2_SUBSTITUTE_UNKNOWN_UNSET: c_uint = 0x00000040
pub let CTL2_SUBSTITUTE_UNSET_EMPTY: c_uint = 0x00000080
pub let CTL2_SUBJECT_LITERAL: c_uint = 0x00000100
pub let CTL2_CALLOUT_NO_WHERE: c_uint = 0x00000200
pub let CTL2_CALLOUT_EXTRA: c_uint = 0x00000400
pub let CTL2_ALLVECTOR: c_uint = 0x00000800
pub let CTL2_NULL_PATTERN: c_uint = 0x00001000
pub let CTL2_NULL_SUBJECT: c_uint = 0x00002000
pub let CTL2_NULL_REPLACEMENT: c_uint = 0x00004000
pub let CTL2_FRAMESIZE: c_uint = 0x00008000
pub let CTL2_SUBSTITUTE_CASE_CALLOUT: c_uint = 0x00010000
pub let CTL2_NULL_SUBSTITUTE_MATCH_DATA: c_uint = 0x00020000
pub let CTL2_HEAPFRAMES_SIZE: c_uint = 0x20000000
pub let CTL2_NL_SET: c_uint = 0x40000000
pub let CTL2_BSR_SET: c_uint = 0x80000000
pub let CTL_ALLPD: c_uint = 1343258655
pub let CTL2_ALLPD: c_uint = 537069823
pub let MAXCPYGET: c_int = 10
pub let LENCPYGET: c_int = 64
pub let PCRE2_EXTRA_ASCII_ALL: c_uint = 3840
pub let MODLISTCOUNT: c_ulong = 156
pub let POSIX_SUPPORTED_COMPILE_OPTIONS: c_uint = 34473000
pub let POSIX_SUPPORTED_COMPILE_EXTRA_OPTIONS: c_int = 0
pub let POSIX_SUPPORTED_COMPILE_CONTROLS: c_uint = 562103299
pub let POSIX_SUPPORTED_COMPILE_CONTROLS2: c_int = 0
pub let POSIX_SUPPORTED_MATCH_OPTIONS: c_uint = 7
pub let POSIX_SUPPORTED_MATCH_CONTROLS: c_uint = 3
pub let POSIX_SUPPORTED_MATCH_CONTROLS2: c_uint = 8192
pub let PUSH_SUPPORTED_COMPILE_CONTROLS: c_uint = 774578336
pub let PUSH_SUPPORTED_COMPILE_CONTROLS2: c_uint = 3758129152
pub let PUSH_COMPILE_ONLY_CONTROLS: c_uint = 524288
pub let PUSH_COMPILE_ONLY_CONTROLS2: c_int = 0
pub let NOTPOP_CONTROLS: c_uint = 796983296
pub let C1MODLISTCOUNT: c_ulong = 10
pub let SUPPORT_8: c_int = 1
pub let SUPPORT_EBCDIC: c_int = 0
pub let SUPPORT_EBCDIC_NL25: c_int = 0
pub let BACKSLASH_C: c_int = 1
pub let COPTLISTCOUNT: c_ulong = 13
pub let BITONE: c_int = 8
pub let MAX_SYNONYMS: c_int = 5
pub let PUBLIC_JIT_COMPILE_OPTIONS: c_uint = 263
