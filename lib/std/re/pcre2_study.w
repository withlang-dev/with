// Migrated from PCRE2
use std.re.defs

type BOOL = c_int
type PCRE2_UCHAR8 = u8
type PCRE2_SPTR8 = *const u8
type pcre2_general_context_8 = pcre2_real_general_context_8
type pcre2_compile_context_8 = pcre2_real_compile_context_8
type pcre2_match_context_8 = pcre2_real_match_context_8
type pcre2_convert_context_8 = pcre2_real_convert_context_8
type pcre2_code_8 = pcre2_real_code_8
type pcre2_match_data_8 = pcre2_real_match_data_8
type pcre2_jit_stack_8 = pcre2_real_jit_stack_8
type pcre2_jit_callback_8 = *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8
type pcre2_callout_block_8 { version: c_uint = 0, callout_number: c_uint = 0, capture_top: c_uint = 0, capture_last: c_uint = 0, offset_vector: *mut c_ulong = null, mark: *const u8 = null, subject: *const u8 = null, subject_length: c_ulong = 0, start_match: c_ulong = 0, current_position: c_ulong = 0, pattern_position: c_ulong = 0, next_item_length: c_ulong = 0, callout_string_offset: c_ulong = 0, callout_string_length: c_ulong = 0, callout_string: *const u8 = null, callout_flags: c_uint = 0 }
type struct_pcre2_callout_block_8 = pcre2_callout_block_8
type pcre2_callout_enumerate_block_8 { version: c_uint = 0, pattern_position: c_ulong = 0, next_item_length: c_ulong = 0, callout_number: c_uint = 0, callout_string_offset: c_ulong = 0, callout_string_length: c_ulong = 0, callout_string: *const u8 = null }
type struct_pcre2_callout_enumerate_block_8 = pcre2_callout_enumerate_block_8
type pcre2_substitute_callout_block_8 { version: c_uint = 0, input: *const u8 = null, output: *const u8 = null, output_offsets: [2]c_ulong = [0 as c_ulong; 2], ovector: *mut c_ulong = null, oveccount: c_uint = 0, subscount: c_uint = 0 }
type struct_pcre2_substitute_callout_block_8 = pcre2_substitute_callout_block_8
extern fn pcre2_config_8(p0: c_uint, p1: *mut c_void) -> c_int
extern fn pcre2_general_context_copy_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_general_context_8
extern fn pcre2_general_context_create_8(p0: *const fn(c_ulong, *mut c_void) -> *mut c_void, p1: *const fn(*mut c_void, *mut c_void) -> void, p2: *mut c_void) -> *mut pcre2_real_general_context_8
extern fn pcre2_general_context_free_8(p0: *mut pcre2_real_general_context_8) -> void
extern fn pcre2_compile_context_copy_8(p0: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_compile_context_8
extern fn pcre2_compile_context_create_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_compile_context_8
extern fn pcre2_compile_context_free_8(p0: *mut pcre2_real_compile_context_8) -> void
extern fn pcre2_set_bsr_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_character_tables_8(p0: *mut pcre2_real_compile_context_8, p1: *const u8) -> c_int
extern fn pcre2_set_compile_extra_options_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_max_pattern_length_8(p0: *mut pcre2_real_compile_context_8, p1: c_ulong) -> c_int
extern fn pcre2_set_max_pattern_compiled_length_8(p0: *mut pcre2_real_compile_context_8, p1: c_ulong) -> c_int
extern fn pcre2_set_max_varlookbehind_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_newline_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_parens_nest_limit_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_compile_recursion_guard_8(p0: *mut pcre2_real_compile_context_8, p1: *const fn(c_uint, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_set_optimize_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_convert_context_copy_8(p0: *mut pcre2_real_convert_context_8) -> *mut pcre2_real_convert_context_8
extern fn pcre2_convert_context_create_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_convert_context_8
extern fn pcre2_convert_context_free_8(p0: *mut pcre2_real_convert_context_8) -> void
extern fn pcre2_set_glob_escape_8(p0: *mut pcre2_real_convert_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_glob_separator_8(p0: *mut pcre2_real_convert_context_8, p1: c_uint) -> c_int
extern fn pcre2_pattern_convert_8(p0: *const u8, p1: c_ulong, p2: c_uint, p3: *mut *mut u8, p4: *mut c_ulong, p5: *mut pcre2_real_convert_context_8) -> c_int
extern fn pcre2_converted_pattern_free_8(p0: *mut u8) -> void
extern fn pcre2_match_context_copy_8(p0: *mut pcre2_real_match_context_8) -> *mut pcre2_real_match_context_8
extern fn pcre2_match_context_create_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_context_8
extern fn pcre2_match_context_free_8(p0: *mut pcre2_real_match_context_8) -> void
extern fn pcre2_set_callout_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_set_substitute_callout_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_set_substitute_case_callout_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, p2: *mut c_void) -> c_int
extern fn pcre2_set_depth_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_heap_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_match_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_offset_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_ulong) -> c_int
extern fn pcre2_set_recursion_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_recursion_memory_management_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(c_ulong, *mut c_void) -> *mut c_void, p2: *const fn(*mut c_void, *mut c_void) -> void, p3: *mut c_void) -> c_int
extern fn pcre2_compile_8(p0: *const u8, p1: c_ulong, p2: c_uint, p3: *mut c_int, p4: *mut c_ulong, p5: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_code_8
extern fn pcre2_code_free_8(p0: *mut pcre2_real_code_8) -> void
extern fn pcre2_code_copy_8(p0: *const pcre2_real_code_8) -> *mut pcre2_real_code_8
extern fn pcre2_code_copy_with_tables_8(p0: *const pcre2_real_code_8) -> *mut pcre2_real_code_8
extern fn pcre2_pattern_info_8(p0: *const pcre2_real_code_8, p1: c_uint, p2: *mut c_void) -> c_int
extern fn pcre2_callout_enumerate_8(p0: *const pcre2_real_code_8, p1: *const fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_match_data_create_8(p0: c_uint, p1: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8
extern fn pcre2_match_data_create_from_pattern_8(p0: *const pcre2_real_code_8, p1: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8
extern fn pcre2_match_data_free_8(p0: *mut pcre2_real_match_data_8) -> void
extern fn pcre2_dfa_match_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8, p7: *mut c_int, p8: c_ulong) -> c_int
extern fn pcre2_match_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8) -> c_int
extern fn pcre2_get_mark_8(p0: *mut pcre2_real_match_data_8) -> *const u8
extern fn pcre2_get_match_data_size_8(p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_get_match_data_heapframes_size_8(p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_get_ovector_count_8(p0: *mut pcre2_real_match_data_8) -> c_uint
extern fn pcre2_get_ovector_pointer_8(p0: *mut pcre2_real_match_data_8) -> *mut c_ulong
extern fn pcre2_get_startchar_8(p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_next_match_8(p0: *mut pcre2_real_match_data_8, p1: *mut c_ulong, p2: *mut c_uint) -> c_int
extern fn pcre2_substring_copy_byname_8(p0: *mut pcre2_real_match_data_8, p1: *const u8, p2: *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_copy_bynumber_8(p0: *mut pcre2_real_match_data_8, p1: c_uint, p2: *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_free_8(p0: *mut u8) -> void
extern fn pcre2_substring_get_byname_8(p0: *mut pcre2_real_match_data_8, p1: *const u8, p2: *mut *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_get_bynumber_8(p0: *mut pcre2_real_match_data_8, p1: c_uint, p2: *mut *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_length_byname_8(p0: *mut pcre2_real_match_data_8, p1: *const u8, p2: *mut c_ulong) -> c_int
extern fn pcre2_substring_length_bynumber_8(p0: *mut pcre2_real_match_data_8, p1: c_uint, p2: *mut c_ulong) -> c_int
extern fn pcre2_substring_nametable_scan_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: *mut *const u8, p3: *mut *const u8) -> c_int
extern fn pcre2_substring_number_from_name_8(p0: *const pcre2_real_code_8, p1: *const u8) -> c_int
extern fn pcre2_substring_list_free_8(p0: *mut *mut u8) -> void
extern fn pcre2_substring_list_get_8(p0: *mut pcre2_real_match_data_8, p1: *mut *mut *mut u8, p2: *mut *mut c_ulong) -> c_int
extern fn pcre2_serialize_encode_8(p0: *mut *const pcre2_real_code_8, p1: c_int, p2: *mut *mut u8, p3: *mut c_ulong, p4: *mut pcre2_real_general_context_8) -> c_int
extern fn pcre2_serialize_decode_8(p0: *mut *mut pcre2_real_code_8, p1: c_int, p2: *const u8, p3: *mut pcre2_real_general_context_8) -> c_int
extern fn pcre2_serialize_get_number_of_codes_8(p0: *const u8) -> c_int
extern fn pcre2_serialize_free_8(p0: *mut u8) -> void
extern fn pcre2_substitute_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8, p7: *const u8, p8: c_ulong, p9: *mut u8, p10: *mut c_ulong) -> c_int
extern fn pcre2_jit_compile_8(p0: *mut pcre2_real_code_8, p1: c_uint) -> c_int
extern fn pcre2_jit_match_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8) -> c_int
extern fn pcre2_jit_free_unused_memory_8(p0: *mut pcre2_real_general_context_8) -> void
extern fn pcre2_jit_stack_create_8(p0: c_ulong, p1: c_ulong, p2: *mut pcre2_real_general_context_8) -> *mut pcre2_real_jit_stack_8
extern fn pcre2_jit_stack_assign_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8, p2: *mut c_void) -> void
extern fn pcre2_jit_stack_free_8(p0: *mut pcre2_real_jit_stack_8) -> void
extern fn pcre2_get_error_message_8(p0: c_int, p1: *mut u8, p2: c_ulong) -> c_int
extern fn pcre2_maketables_8(p0: *mut pcre2_real_general_context_8) -> *const u8
extern fn pcre2_maketables_free_8(p0: *mut pcre2_real_general_context_8, p1: *const u8) -> void
let ucp_C: c_uint = 0
let ucp_L: c_uint = 1
let ucp_M: c_uint = 2
let ucp_N: c_uint = 3
let ucp_P: c_uint = 4
let ucp_S: c_uint = 5
let ucp_Z: c_uint = 6
let ucp_Cc: c_uint = 0
let ucp_Cf: c_uint = 1
let ucp_Cn: c_uint = 2
let ucp_Co: c_uint = 3
let ucp_Cs: c_uint = 4
let ucp_Ll: c_uint = 5
let ucp_Lm: c_uint = 6
let ucp_Lo: c_uint = 7
let ucp_Lt: c_uint = 8
let ucp_Lu: c_uint = 9
let ucp_Mc: c_uint = 10
let ucp_Me: c_uint = 11
let ucp_Mn: c_uint = 12
let ucp_Nd: c_uint = 13
let ucp_Nl: c_uint = 14
let ucp_No: c_uint = 15
let ucp_Pc: c_uint = 16
let ucp_Pd: c_uint = 17
let ucp_Pe: c_uint = 18
let ucp_Pf: c_uint = 19
let ucp_Pi: c_uint = 20
let ucp_Po: c_uint = 21
let ucp_Ps: c_uint = 22
let ucp_Sc: c_uint = 23
let ucp_Sk: c_uint = 24
let ucp_Sm: c_uint = 25
let ucp_So: c_uint = 26
let ucp_Zl: c_uint = 27
let ucp_Zp: c_uint = 28
let ucp_Zs: c_uint = 29
let ucp_ASCII: c_uint = 0
let ucp_ASCII_Hex_Digit: c_uint = 1
let ucp_Alphabetic: c_uint = 2
let ucp_Bidi_Control: c_uint = 3
let ucp_Bidi_Mirrored: c_uint = 4
let ucp_Case_Ignorable: c_uint = 5
let ucp_Cased: c_uint = 6
let ucp_Changes_When_Casefolded: c_uint = 7
let ucp_Changes_When_Casemapped: c_uint = 8
let ucp_Changes_When_Lowercased: c_uint = 9
let ucp_Changes_When_Titlecased: c_uint = 10
let ucp_Changes_When_Uppercased: c_uint = 11
let ucp_Dash: c_uint = 12
let ucp_Default_Ignorable_Code_Point: c_uint = 13
let ucp_Deprecated: c_uint = 14
let ucp_Diacritic: c_uint = 15
let ucp_Emoji: c_uint = 16
let ucp_Emoji_Component: c_uint = 17
let ucp_Emoji_Modifier: c_uint = 18
let ucp_Emoji_Modifier_Base: c_uint = 19
let ucp_Emoji_Presentation: c_uint = 20
let ucp_Extended_Pictographic: c_uint = 21
let ucp_Extender: c_uint = 22
let ucp_Grapheme_Base: c_uint = 23
let ucp_Grapheme_Extend: c_uint = 24
let ucp_Grapheme_Link: c_uint = 25
let ucp_Hex_Digit: c_uint = 26
let ucp_IDS_Binary_Operator: c_uint = 27
let ucp_IDS_Trinary_Operator: c_uint = 28
let ucp_IDS_Unary_Operator: c_uint = 29
let ucp_ID_Compat_Math_Continue: c_uint = 30
let ucp_ID_Compat_Math_Start: c_uint = 31
let ucp_ID_Continue: c_uint = 32
let ucp_ID_Start: c_uint = 33
let ucp_Ideographic: c_uint = 34
let ucp_InCB: c_uint = 35
let ucp_Join_Control: c_uint = 36
let ucp_Logical_Order_Exception: c_uint = 37
let ucp_Lowercase: c_uint = 38
let ucp_Math: c_uint = 39
let ucp_Modifier_Combining_Mark: c_uint = 40
let ucp_Noncharacter_Code_Point: c_uint = 41
let ucp_Pattern_Syntax: c_uint = 42
let ucp_Pattern_White_Space: c_uint = 43
let ucp_Prepended_Concatenation_Mark: c_uint = 44
let ucp_Quotation_Mark: c_uint = 45
let ucp_Radical: c_uint = 46
let ucp_Regional_Indicator: c_uint = 47
let ucp_Sentence_Terminal: c_uint = 48
let ucp_Soft_Dotted: c_uint = 49
let ucp_Terminal_Punctuation: c_uint = 50
let ucp_Unified_Ideograph: c_uint = 51
let ucp_Uppercase: c_uint = 52
let ucp_Variation_Selector: c_uint = 53
let ucp_White_Space: c_uint = 54
let ucp_XID_Continue: c_uint = 55
let ucp_XID_Start: c_uint = 56
let ucp_Bprop_Count: c_uint = 57
let ucp_bidiAL: c_uint = 0
let ucp_bidiAN: c_uint = 1
let ucp_bidiB: c_uint = 2
let ucp_bidiBN: c_uint = 3
let ucp_bidiCS: c_uint = 4
let ucp_bidiEN: c_uint = 5
let ucp_bidiES: c_uint = 6
let ucp_bidiET: c_uint = 7
let ucp_bidiFSI: c_uint = 8
let ucp_bidiL: c_uint = 9
let ucp_bidiLRE: c_uint = 10
let ucp_bidiLRI: c_uint = 11
let ucp_bidiLRO: c_uint = 12
let ucp_bidiNSM: c_uint = 13
let ucp_bidiON: c_uint = 14
let ucp_bidiPDF: c_uint = 15
let ucp_bidiPDI: c_uint = 16
let ucp_bidiR: c_uint = 17
let ucp_bidiRLE: c_uint = 18
let ucp_bidiRLI: c_uint = 19
let ucp_bidiRLO: c_uint = 20
let ucp_bidiS: c_uint = 21
let ucp_bidiWS: c_uint = 22
let ucp_gbCR: c_uint = 0
let ucp_gbLF: c_uint = 1
let ucp_gbControl: c_uint = 2
let ucp_gbExtend: c_uint = 3
let ucp_gbPrepend: c_uint = 4
let ucp_gbSpacingMark: c_uint = 5
let ucp_gbL: c_uint = 6
let ucp_gbV: c_uint = 7
let ucp_gbT: c_uint = 8
let ucp_gbLV: c_uint = 9
let ucp_gbLVT: c_uint = 10
let ucp_gbRegional_Indicator: c_uint = 11
let ucp_gbOther: c_uint = 12
let ucp_gbZWJ: c_uint = 13
let ucp_gbExtended_Pictographic: c_uint = 14
let ucp_Latin: c_uint = 0
let ucp_Greek: c_uint = 1
let ucp_Cyrillic: c_uint = 2
let ucp_Armenian: c_uint = 3
let ucp_Hebrew: c_uint = 4
let ucp_Arabic: c_uint = 5
let ucp_Syriac: c_uint = 6
let ucp_Thaana: c_uint = 7
let ucp_Devanagari: c_uint = 8
let ucp_Bengali: c_uint = 9
let ucp_Gurmukhi: c_uint = 10
let ucp_Gujarati: c_uint = 11
let ucp_Oriya: c_uint = 12
let ucp_Tamil: c_uint = 13
let ucp_Telugu: c_uint = 14
let ucp_Kannada: c_uint = 15
let ucp_Malayalam: c_uint = 16
let ucp_Sinhala: c_uint = 17
let ucp_Thai: c_uint = 18
let ucp_Tibetan: c_uint = 19
let ucp_Myanmar: c_uint = 20
let ucp_Georgian: c_uint = 21
let ucp_Hangul: c_uint = 22
let ucp_Ethiopic: c_uint = 23
let ucp_Cherokee: c_uint = 24
let ucp_Runic: c_uint = 25
let ucp_Mongolian: c_uint = 26
let ucp_Hiragana: c_uint = 27
let ucp_Katakana: c_uint = 28
let ucp_Bopomofo: c_uint = 29
let ucp_Han: c_uint = 30
let ucp_Yi: c_uint = 31
let ucp_Gothic: c_uint = 32
let ucp_Tagalog: c_uint = 33
let ucp_Hanunoo: c_uint = 34
let ucp_Buhid: c_uint = 35
let ucp_Tagbanwa: c_uint = 36
let ucp_Limbu: c_uint = 37
let ucp_Tai_Le: c_uint = 38
let ucp_Linear_B: c_uint = 39
let ucp_Shavian: c_uint = 40
let ucp_Cypriot: c_uint = 41
let ucp_Buginese: c_uint = 42
let ucp_Coptic: c_uint = 43
let ucp_Glagolitic: c_uint = 44
let ucp_Tifinagh: c_uint = 45
let ucp_Syloti_Nagri: c_uint = 46
let ucp_Phags_Pa: c_uint = 47
let ucp_Nko: c_uint = 48
let ucp_Kayah_Li: c_uint = 49
let ucp_Lycian: c_uint = 50
let ucp_Carian: c_uint = 51
let ucp_Lydian: c_uint = 52
let ucp_Avestan: c_uint = 53
let ucp_Samaritan: c_uint = 54
let ucp_Lisu: c_uint = 55
let ucp_Javanese: c_uint = 56
let ucp_Old_Turkic: c_uint = 57
let ucp_Kaithi: c_uint = 58
let ucp_Mandaic: c_uint = 59
let ucp_Chakma: c_uint = 60
let ucp_Meroitic_Hieroglyphs: c_uint = 61
let ucp_Sharada: c_uint = 62
let ucp_Takri: c_uint = 63
let ucp_Caucasian_Albanian: c_uint = 64
let ucp_Duployan: c_uint = 65
let ucp_Elbasan: c_uint = 66
let ucp_Grantha: c_uint = 67
let ucp_Khojki: c_uint = 68
let ucp_Linear_A: c_uint = 69
let ucp_Mahajani: c_uint = 70
let ucp_Manichaean: c_uint = 71
let ucp_Modi: c_uint = 72
let ucp_Old_Permic: c_uint = 73
let ucp_Psalter_Pahlavi: c_uint = 74
let ucp_Khudawadi: c_uint = 75
let ucp_Tirhuta: c_uint = 76
let ucp_Multani: c_uint = 77
let ucp_Old_Hungarian: c_uint = 78
let ucp_Adlam: c_uint = 79
let ucp_Newa: c_uint = 80
let ucp_Osage: c_uint = 81
let ucp_Tangut: c_uint = 82
let ucp_Masaram_Gondi: c_uint = 83
let ucp_Dogra: c_uint = 84
let ucp_Gunjala_Gondi: c_uint = 85
let ucp_Hanifi_Rohingya: c_uint = 86
let ucp_Sogdian: c_uint = 87
let ucp_Nandinagari: c_uint = 88
let ucp_Yezidi: c_uint = 89
let ucp_Cypro_Minoan: c_uint = 90
let ucp_Old_Uyghur: c_uint = 91
let ucp_Toto: c_uint = 92
let ucp_Garay: c_uint = 93
let ucp_Gurung_Khema: c_uint = 94
let ucp_Ol_Onal: c_uint = 95
let ucp_Sunuwar: c_uint = 96
let ucp_Todhri: c_uint = 97
let ucp_Tulu_Tigalari: c_uint = 98
let ucp_Unknown: c_uint = 99
let ucp_Common: c_uint = 100
let ucp_Lao: c_uint = 101
let ucp_Canadian_Aboriginal: c_uint = 102
let ucp_Ogham: c_uint = 103
let ucp_Khmer: c_uint = 104
let ucp_Old_Italic: c_uint = 105
let ucp_Deseret: c_uint = 106
let ucp_Inherited: c_uint = 107
let ucp_Ugaritic: c_uint = 108
let ucp_Osmanya: c_uint = 109
let ucp_Braille: c_uint = 110
let ucp_New_Tai_Lue: c_uint = 111
let ucp_Old_Persian: c_uint = 112
let ucp_Kharoshthi: c_uint = 113
let ucp_Balinese: c_uint = 114
let ucp_Cuneiform: c_uint = 115
let ucp_Phoenician: c_uint = 116
let ucp_Sundanese: c_uint = 117
let ucp_Lepcha: c_uint = 118
let ucp_Ol_Chiki: c_uint = 119
let ucp_Vai: c_uint = 120
let ucp_Saurashtra: c_uint = 121
let ucp_Rejang: c_uint = 122
let ucp_Cham: c_uint = 123
let ucp_Tai_Tham: c_uint = 124
let ucp_Tai_Viet: c_uint = 125
let ucp_Egyptian_Hieroglyphs: c_uint = 126
let ucp_Bamum: c_uint = 127
let ucp_Meetei_Mayek: c_uint = 128
let ucp_Imperial_Aramaic: c_uint = 129
let ucp_Old_South_Arabian: c_uint = 130
let ucp_Inscriptional_Parthian: c_uint = 131
let ucp_Inscriptional_Pahlavi: c_uint = 132
let ucp_Batak: c_uint = 133
let ucp_Brahmi: c_uint = 134
let ucp_Meroitic_Cursive: c_uint = 135
let ucp_Miao: c_uint = 136
let ucp_Sora_Sompeng: c_uint = 137
let ucp_Bassa_Vah: c_uint = 138
let ucp_Pahawh_Hmong: c_uint = 139
let ucp_Mende_Kikakui: c_uint = 140
let ucp_Mro: c_uint = 141
let ucp_Old_North_Arabian: c_uint = 142
let ucp_Nabataean: c_uint = 143
let ucp_Palmyrene: c_uint = 144
let ucp_Pau_Cin_Hau: c_uint = 145
let ucp_Siddham: c_uint = 146
let ucp_Warang_Citi: c_uint = 147
let ucp_Ahom: c_uint = 148
let ucp_Anatolian_Hieroglyphs: c_uint = 149
let ucp_Hatran: c_uint = 150
let ucp_SignWriting: c_uint = 151
let ucp_Bhaiksuki: c_uint = 152
let ucp_Marchen: c_uint = 153
let ucp_Nushu: c_uint = 154
let ucp_Soyombo: c_uint = 155
let ucp_Zanabazar_Square: c_uint = 156
let ucp_Makasar: c_uint = 157
let ucp_Medefaidrin: c_uint = 158
let ucp_Old_Sogdian: c_uint = 159
let ucp_Elymaic: c_uint = 160
let ucp_Nyiakeng_Puachue_Hmong: c_uint = 161
let ucp_Wancho: c_uint = 162
let ucp_Chorasmian: c_uint = 163
let ucp_Dives_Akuru: c_uint = 164
let ucp_Khitan_Small_Script: c_uint = 165
let ucp_Tangsa: c_uint = 166
let ucp_Vithkuqi: c_uint = 167
let ucp_Kawi: c_uint = 168
let ucp_Nag_Mundari: c_uint = 169
let ucp_Kirat_Rai: c_uint = 170
let ucp_Sidetic: c_uint = 171
let ucp_Tai_Yo: c_uint = 172
let ucp_Tolong_Siki: c_uint = 173
let ucp_Beria_Erfe: c_uint = 174
let ucp_Script_Count: c_uint = 175
let PCRE2_MATCHEDBY_INTERPRETER: c_uint = 0
let PCRE2_MATCHEDBY_DFA_INTERPRETER: c_uint = 1
let PCRE2_MATCHEDBY_JIT: c_uint = 2
let ESC_A: c_uint = 1
let ESC_G: c_uint = 2
let ESC_K: c_uint = 3
let ESC_B: c_uint = 4
let ESC_b: c_uint = 5
let ESC_D: c_uint = 6
let ESC_d: c_uint = 7
let ESC_S: c_uint = 8
let ESC_s: c_uint = 9
let ESC_W: c_uint = 10
let ESC_w: c_uint = 11
let ESC_N: c_uint = 12
let ESC_dum: c_uint = 13
let ESC_C: c_uint = 14
let ESC_P: c_uint = 15
let ESC_p: c_uint = 16
let ESC_R: c_uint = 17
let ESC_H: c_uint = 18
let ESC_h: c_uint = 19
let ESC_V: c_uint = 20
let ESC_v: c_uint = 21
let ESC_X: c_uint = 22
let ESC_Z: c_uint = 23
let ESC_z: c_uint = 24
let ESC_E: c_uint = 25
let ESC_Q: c_uint = 26
let ESC_g: c_uint = 27
let ESC_k: c_uint = 28
let ESC_ub: c_uint = 29
let OP_END: c_uint = 0
let OP_SOD: c_uint = 1
let OP_SOM: c_uint = 2
let OP_SET_SOM: c_uint = 3
let OP_NOT_WORD_BOUNDARY: c_uint = 4
let OP_WORD_BOUNDARY: c_uint = 5
let OP_NOT_DIGIT: c_uint = 6
let OP_DIGIT: c_uint = 7
let OP_NOT_WHITESPACE: c_uint = 8
let OP_WHITESPACE: c_uint = 9
let OP_NOT_WORDCHAR: c_uint = 10
let OP_WORDCHAR: c_uint = 11
let OP_ANY: c_uint = 12
let OP_ALLANY: c_uint = 13
let OP_ANYBYTE: c_uint = 14
let OP_NOTPROP: c_uint = 15
let OP_PROP: c_uint = 16
let OP_ANYNL: c_uint = 17
let OP_NOT_HSPACE: c_uint = 18
let OP_HSPACE: c_uint = 19
let OP_NOT_VSPACE: c_uint = 20
let OP_VSPACE: c_uint = 21
let OP_EXTUNI: c_uint = 22
let OP_EODN: c_uint = 23
let OP_EOD: c_uint = 24
let OP_DOLL: c_uint = 25
let OP_DOLLM: c_uint = 26
let OP_CIRC: c_uint = 27
let OP_CIRCM: c_uint = 28
let OP_CHAR: c_uint = 29
let OP_CHARI: c_uint = 30
let OP_NOT: c_uint = 31
let OP_NOTI: c_uint = 32
let OP_STAR: c_uint = 33
let OP_MINSTAR: c_uint = 34
let OP_PLUS: c_uint = 35
let OP_MINPLUS: c_uint = 36
let OP_QUERY: c_uint = 37
let OP_MINQUERY: c_uint = 38
let OP_UPTO: c_uint = 39
let OP_MINUPTO: c_uint = 40
let OP_EXACT: c_uint = 41
let OP_POSSTAR: c_uint = 42
let OP_POSPLUS: c_uint = 43
let OP_POSQUERY: c_uint = 44
let OP_POSUPTO: c_uint = 45
let OP_STARI: c_uint = 46
let OP_MINSTARI: c_uint = 47
let OP_PLUSI: c_uint = 48
let OP_MINPLUSI: c_uint = 49
let OP_QUERYI: c_uint = 50
let OP_MINQUERYI: c_uint = 51
let OP_UPTOI: c_uint = 52
let OP_MINUPTOI: c_uint = 53
let OP_EXACTI: c_uint = 54
let OP_POSSTARI: c_uint = 55
let OP_POSPLUSI: c_uint = 56
let OP_POSQUERYI: c_uint = 57
let OP_POSUPTOI: c_uint = 58
let OP_NOTSTAR: c_uint = 59
let OP_NOTMINSTAR: c_uint = 60
let OP_NOTPLUS: c_uint = 61
let OP_NOTMINPLUS: c_uint = 62
let OP_NOTQUERY: c_uint = 63
let OP_NOTMINQUERY: c_uint = 64
let OP_NOTUPTO: c_uint = 65
let OP_NOTMINUPTO: c_uint = 66
let OP_NOTEXACT: c_uint = 67
let OP_NOTPOSSTAR: c_uint = 68
let OP_NOTPOSPLUS: c_uint = 69
let OP_NOTPOSQUERY: c_uint = 70
let OP_NOTPOSUPTO: c_uint = 71
let OP_NOTSTARI: c_uint = 72
let OP_NOTMINSTARI: c_uint = 73
let OP_NOTPLUSI: c_uint = 74
let OP_NOTMINPLUSI: c_uint = 75
let OP_NOTQUERYI: c_uint = 76
let OP_NOTMINQUERYI: c_uint = 77
let OP_NOTUPTOI: c_uint = 78
let OP_NOTMINUPTOI: c_uint = 79
let OP_NOTEXACTI: c_uint = 80
let OP_NOTPOSSTARI: c_uint = 81
let OP_NOTPOSPLUSI: c_uint = 82
let OP_NOTPOSQUERYI: c_uint = 83
let OP_NOTPOSUPTOI: c_uint = 84
let OP_TYPESTAR: c_uint = 85
let OP_TYPEMINSTAR: c_uint = 86
let OP_TYPEPLUS: c_uint = 87
let OP_TYPEMINPLUS: c_uint = 88
let OP_TYPEQUERY: c_uint = 89
let OP_TYPEMINQUERY: c_uint = 90
let OP_TYPEUPTO: c_uint = 91
let OP_TYPEMINUPTO: c_uint = 92
let OP_TYPEEXACT: c_uint = 93
let OP_TYPEPOSSTAR: c_uint = 94
let OP_TYPEPOSPLUS: c_uint = 95
let OP_TYPEPOSQUERY: c_uint = 96
let OP_TYPEPOSUPTO: c_uint = 97
let OP_CRSTAR: c_uint = 98
let OP_CRMINSTAR: c_uint = 99
let OP_CRPLUS: c_uint = 100
let OP_CRMINPLUS: c_uint = 101
let OP_CRQUERY: c_uint = 102
let OP_CRMINQUERY: c_uint = 103
let OP_CRRANGE: c_uint = 104
let OP_CRMINRANGE: c_uint = 105
let OP_CRPOSSTAR: c_uint = 106
let OP_CRPOSPLUS: c_uint = 107
let OP_CRPOSQUERY: c_uint = 108
let OP_CRPOSRANGE: c_uint = 109
let OP_CLASS: c_uint = 110
let OP_NCLASS: c_uint = 111
let OP_XCLASS: c_uint = 112
let OP_ECLASS: c_uint = 113
let OP_REF: c_uint = 114
let OP_REFI: c_uint = 115
let OP_DNREF: c_uint = 116
let OP_DNREFI: c_uint = 117
let OP_RECURSE: c_uint = 118
let OP_CALLOUT: c_uint = 119
let OP_CALLOUT_STR: c_uint = 120
let OP_ALT: c_uint = 121
let OP_KET: c_uint = 122
let OP_KETRMAX: c_uint = 123
let OP_KETRMIN: c_uint = 124
let OP_KETRPOS: c_uint = 125
let OP_REVERSE: c_uint = 126
let OP_VREVERSE: c_uint = 127
let OP_ASSERT: c_uint = 128
let OP_ASSERT_NOT: c_uint = 129
let OP_ASSERTBACK: c_uint = 130
let OP_ASSERTBACK_NOT: c_uint = 131
let OP_ASSERT_NA: c_uint = 132
let OP_ASSERTBACK_NA: c_uint = 133
let OP_ASSERT_SCS: c_uint = 134
let OP_ONCE: c_uint = 135
let OP_SCRIPT_RUN: c_uint = 136
let OP_BRA: c_uint = 137
let OP_BRAPOS: c_uint = 138
let OP_CBRA: c_uint = 139
let OP_CBRAPOS: c_uint = 140
let OP_COND: c_uint = 141
let OP_SBRA: c_uint = 142
let OP_SBRAPOS: c_uint = 143
let OP_SCBRA: c_uint = 144
let OP_SCBRAPOS: c_uint = 145
let OP_SCOND: c_uint = 146
let OP_CREF: c_uint = 147
let OP_DNCREF: c_uint = 148
let OP_RREF: c_uint = 149
let OP_DNRREF: c_uint = 150
let OP_FALSE: c_uint = 151
let OP_TRUE: c_uint = 152
let OP_BRAZERO: c_uint = 153
let OP_BRAMINZERO: c_uint = 154
let OP_BRAPOSZERO: c_uint = 155
let OP_MARK: c_uint = 156
let OP_PRUNE: c_uint = 157
let OP_PRUNE_ARG: c_uint = 158
let OP_SKIP: c_uint = 159
let OP_SKIP_ARG: c_uint = 160
let OP_THEN: c_uint = 161
let OP_THEN_ARG: c_uint = 162
let OP_COMMIT: c_uint = 163
let OP_COMMIT_ARG: c_uint = 164
let OP_FAIL: c_uint = 165
let OP_ACCEPT: c_uint = 166
let OP_ASSERT_ACCEPT: c_uint = 167
let OP_CLOSE: c_uint = 168
let OP_SKIPZERO: c_uint = 169
let OP_DEFINE: c_uint = 170
let OP_NOT_UCP_WORD_BOUNDARY: c_uint = 171
let OP_UCP_WORD_BOUNDARY: c_uint = 172
let OP_TABLE_LENGTH: c_uint = 173
type pcre2_memctl { malloc: *const fn(c_ulong, *mut c_void) -> *mut c_void = null, free: *const fn(*mut c_void, *mut c_void) -> void = null, memory_data: *mut c_void = null }
type struct_pcre2_memctl = pcre2_memctl
type open_capitem { next: *mut open_capitem = null, number: c_ushort = 0, assert_depth: c_ushort = 0 }
type struct_open_capitem = open_capitem
type ucp_type_table { name_offset: c_ushort = 0, type_: c_ushort = 0, value: c_ushort = 0 }
type struct_ucp_type_table = ucp_type_table
type ucd_record { script: u8 = 0, chartype: u8 = 0, gbprop: u8 = 0, caseset: u8 = 0, other_case: c_int = 0, scriptx_bidiclass: c_ushort = 0, bprops: c_ushort = 0 }
type struct_ucd_record = ucd_record
type pcre2_serialized_data { magic: c_uint = 0, version: c_uint = 0, config: c_uint = 0, number_of_codes: c_int = 0 }
type struct_pcre2_serialized_data = pcre2_serialized_data
extern var _pcre2_utf8_table1: *c_int
extern let _pcre2_utf8_table1_size: c_uint
extern var _pcre2_utf8_table2: *c_int
extern var _pcre2_utf8_table3: *c_int
extern var _pcre2_utf8_table4: *u8
extern var _pcre2_OP_lengths_8: *u8
extern var _pcre2_callout_end_delims_8: *c_uint
extern var _pcre2_callout_start_delims_8: *c_uint
extern var _pcre2_default_compile_context_8: pcre2_real_compile_context_8
extern var _pcre2_default_convert_context_8: pcre2_real_convert_context_8
extern var _pcre2_default_match_context_8: pcre2_real_match_context_8
extern var _pcre2_default_tables_8: *u8
extern var _pcre2_hspace_list_8: *c_uint
extern var _pcre2_vspace_list_8: *c_uint
extern var _pcre2_ucd_boolprop_sets_8: *c_uint
extern var _pcre2_ucd_caseless_sets_8: *c_uint
extern let _pcre2_ucd_turkish_dotted_i_caseset_8: c_uint
extern var _pcre2_ucd_nocase_ranges_8: *c_uint
extern let _pcre2_ucd_nocase_ranges_size_8: c_uint
extern var _pcre2_ucd_digit_sets_8: *c_uint
extern var _pcre2_ucd_script_sets_8: *c_uint
extern var _pcre2_ucd_records_8: *ucd_record
extern var _pcre2_ucd_stage1_8: *c_ushort
extern var _pcre2_ucd_stage2_8: *c_ushort
extern var _pcre2_ucp_gbtable_8: *c_uint
extern var _pcre2_ucp_gentype_8: *c_uint
extern var _pcre2_unicode_version_8: *const i8
extern var _pcre2_utt_8: *ucp_type_table
extern var _pcre2_utt_names_8: *c_char
extern let _pcre2_utt_size_8: c_ulong
extern var _pcre2_ebcdic_1047_to_ascii_8: *u8
extern var _pcre2_ascii_to_ebcdic_1047_8: *u8
type pcre2_real_general_context_8 { memctl: pcre2_memctl }
type struct_pcre2_real_general_context_8 = pcre2_real_general_context_8
type pcre2_real_compile_context_8 { memctl: pcre2_memctl, stack_guard: *const fn(c_uint, *mut c_void) -> c_int = null, stack_guard_data: *mut c_void = null, tables: *const u8 = null, max_pattern_length: c_ulong = 0, max_pattern_compiled_length: c_ulong = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, parens_nest_limit: c_uint = 0, extra_options: c_uint = 0, max_varlookbehind: c_uint = 0, optimization_flags: c_uint = 0 }
type struct_pcre2_real_compile_context_8 = pcre2_real_compile_context_8
type pcre2_real_match_context_8 { memctl: pcre2_memctl, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, callout_data: *mut c_void = null, substitute_callout: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int = null, substitute_callout_data: *mut c_void = null, substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong = null, substitute_case_callout_data: *mut c_void = null, offset_limit: c_ulong = 0, heap_limit: c_uint = 0, match_limit: c_uint = 0, depth_limit: c_uint = 0 }
type struct_pcre2_real_match_context_8 = pcre2_real_match_context_8
type pcre2_real_convert_context_8 { memctl: pcre2_memctl, glob_separator: c_uint = 0, glob_escape: c_uint = 0 }
type struct_pcre2_real_convert_context_8 = pcre2_real_convert_context_8
type pcre2_real_code_8 { memctl: pcre2_memctl, tables: *const u8 = null, executable_jit: *mut c_void = null, start_bitmap: [32]u8 = [0 as u8; 32], blocksize: c_ulong = 0, code_start: c_ulong = 0, magic_number: c_uint = 0, compile_options: c_uint = 0, overall_options: c_uint = 0, extra_options: c_uint = 0, flags: c_uint = 0, limit_heap: c_uint = 0, limit_match: c_uint = 0, limit_depth: c_uint = 0, first_codeunit: c_uint = 0, last_codeunit: c_uint = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, max_lookbehind: c_ushort = 0, minlength: c_ushort = 0, top_bracket: c_ushort = 0, top_backref: c_ushort = 0, name_entry_size: c_ushort = 0, name_count: c_ushort = 0, optimization_flags: c_uint = 0 }
type struct_pcre2_real_code_8 = pcre2_real_code_8
type pcre2_real_match_data_8 { memctl: pcre2_memctl, code: *const pcre2_real_code_8 = null, subject: *const u8 = null, mark: *const u8 = null, heapframes: *mut heapframe = null, heapframes_size: c_ulong = 0, subject_length: c_ulong = 0, start_offset: c_ulong = 0, leftchar: c_ulong = 0, rightchar: c_ulong = 0, startchar: c_ulong = 0, matchedby: u8 = 0, flags: u8 = 0, oveccount: c_ushort = 0, options: c_uint = 0, rc: c_int = 0, ovector: [131072]c_ulong = [0 as c_ulong; 131072] }
type struct_pcre2_real_match_data_8 = pcre2_real_match_data_8
type recurse_check { prev: *mut recurse_check = null, group: *const u8 = null }
type struct_recurse_check = recurse_check
type parsed_recurse_check { prev: *mut parsed_recurse_check = null, groupptr: *mut c_uint = null }
type struct_parsed_recurse_check = parsed_recurse_check
type recurse_cache { group: *const u8 = null, groupnumber: c_int = 0 }
type struct_recurse_cache = recurse_cache
type branch_chain_8 { outer: *mut branch_chain_8 = null, current_branch: *mut u8 = null }
type struct_branch_chain_8 = branch_chain_8
type named_group_8 { name: *const u8 = null, number: c_uint = 0, length: c_ushort = 0, hash_dup: c_ushort = 0 }
type struct_named_group_8 = named_group_8
type compile_data { next: *mut compile_data = null }
type struct_compile_data = compile_data
type class_ranges { header: compile_data, char_lists_size: c_ulong = 0, char_lists_start: c_ulong = 0, range_list_size: c_ushort = 0, char_lists_types: c_ushort = 0 }
type struct_class_ranges = class_ranges
type recurse_arguments { header: compile_data, size: c_ulong = 0, skip_size: c_ulong = 0 }
type struct_recurse_arguments = recurse_arguments
// union
type class_bits_storage { classbits: [32]u8 = [0 as u8; 32], classwords: [8]c_uint = [0 as c_uint; 8] }
type struct_class_bits_storage = class_bits_storage
type compile_block_8 { cx: *mut pcre2_real_compile_context_8 = null, lcc: *const u8 = null, fcc: *const u8 = null, cbits: *const u8 = null, ctypes: *const u8 = null, start_workspace: *mut u8 = null, start_code: *mut u8 = null, start_pattern: *const u8 = null, end_pattern: *const u8 = null, name_table: *mut u8 = null, workspace_size: c_ulong = 0, small_ref_offset: [10]c_ulong = [0 as c_ulong; 10], erroroffset: c_ulong = 0, classbits: class_bits_storage, names_found: c_ushort = 0, name_entry_size: c_ushort = 0, parens_depth: c_ushort = 0, assert_depth: c_ushort = 0, named_groups: *mut named_group_8 = null, named_group_list_size: c_uint = 0, external_options: c_uint = 0, external_flags: c_uint = 0, bracount: c_uint = 0, lastcapture: c_uint = 0, parsed_pattern: *mut c_uint = null, parsed_pattern_end: *mut c_uint = null, groupinfo: *mut c_uint = null, top_backref: c_uint = 0, backref_map: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], class_op_used: [15]u8 = [0 as u8; 15], req_varyopt: c_uint = 0, max_varlookbehind: c_uint = 0, max_lookbehind: c_int = 0, had_accept: c_int = 0, had_pruneorskip: c_int = 0, had_recurse: c_int = 0, dupnames: c_int = 0, first_data: *mut compile_data = null, last_data: *mut compile_data = null }
type struct_compile_block_8 = compile_block_8
type pcre2_real_jit_stack_8 { memctl: pcre2_memctl, stack: *mut c_void = null }
type struct_pcre2_real_jit_stack_8 = pcre2_real_jit_stack_8
type dfa_recursion_info { prevrec: *mut dfa_recursion_info = null, subject_position: *const u8 = null, last_used_ptr: *const u8 = null, group_num: c_uint = 0 }
type struct_dfa_recursion_info = dfa_recursion_info
// /Users/eric/with/.reference/pcre2/src/pcre2_intmodedep.h:696:8: demoted to opaque
type heapframe = opaque
type struct_heapframe = heapframe
type static_assertion_heapframe_size = [1]c_int
// /Users/eric/with/.reference/pcre2/src/pcre2_intmodedep.h:1024:16: demoted to opaque
type heapframe_align = opaque
type struct_heapframe_align = heapframe_align
type match_block_8 { memctl: pcre2_memctl, heap_limit: c_uint = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, hitend: c_int = 0, hasthen: c_int = 0, hasbsk: c_int = 0, allowemptypartial: c_int = 0, allowlookaroundbsk: c_int = 0, lcc: *const u8 = null, fcc: *const u8 = null, ctypes: *const u8 = null, start_offset: c_ulong = 0, end_offset_top: c_ulong = 0, partial: c_ushort = 0, bsr_convention: c_ushort = 0, name_count: c_ushort = 0, name_entry_size: c_ushort = 0, name_table: *const u8 = null, start_code: *const u8 = null, start_subject: *const u8 = null, check_subject: *const u8 = null, end_subject: *const u8 = null, true_end_subject: *const u8 = null, end_match_ptr: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, mark: *const u8 = null, nomatch_mark: *const u8 = null, verb_ecode_ptr: *const u8 = null, verb_skip_ptr: *const u8 = null, verb_current_recurse: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, skip_arg_count: c_uint = 0, ignore_skip_arg: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null }
type struct_match_block_8 = match_block_8
type dfa_match_block_8 { memctl: pcre2_memctl, start_code: *const u8 = null, start_subject: *const u8 = null, end_subject: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, tables: *const u8 = null, start_offset: c_ulong = 0, heap_limit: c_uint = 0, heap_used: c_ulong = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, allowemptypartial: c_int = 0, nl: [4]u8 = [0 as u8; 4], bsr_convention: c_ushort = 0, cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, recursive: *mut dfa_recursion_info = null }
type struct_dfa_match_block_8 = dfa_match_block_8
extern fn _pcre2_auto_possessify_8(p0: *mut u8, p1: *const compile_block_8) -> c_int
extern fn _pcre2_check_escape_8(p0: *mut *const u8, p1: *const u8, p2: *mut c_uint, p3: *mut c_int, p4: c_uint, p5: c_uint, p6: c_uint, p7: c_int, p8: *mut compile_block_8) -> c_int
extern fn _pcre2_ckd_smul_8(p0: *mut c_ulong, p1: c_int, p2: c_int) -> c_int
extern fn _pcre2_extuni_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: *const u8, p4: c_int, p5: *mut c_int) -> *const u8
extern fn _pcre2_find_bracket_8(p0: *const u8, p1: c_int, p2: c_int) -> *const u8
extern fn _pcre2_is_newline_8(p0: *const u8, p1: c_uint, p2: *const u8, p3: *mut c_uint, p4: c_int) -> c_int
extern fn _pcre2_jit_free_rodata_8(p0: *mut c_void, p1: *mut c_void) -> void
extern fn _pcre2_jit_free_8(p0: *mut c_void, p1: *mut pcre2_memctl) -> void
extern fn _pcre2_jit_get_size_8(p0: *mut c_void) -> c_ulong
extern fn _pcre2_jit_get_target_8() -> *const i8
extern fn _pcre2_memctl_malloc_8(p0: c_ulong, p1: *mut pcre2_memctl) -> *mut c_void
extern fn _pcre2_ord2utf_8(p0: c_uint, p1: *mut u8) -> c_uint
extern fn _pcre2_script_run_8(p0: *const u8, p1: *const u8, p2: c_int) -> c_int
extern fn _pcre2_strcmp_8(p0: *const u8, p1: *const u8) -> c_int
extern fn _pcre2_strcmp_c8_8(p0: *const u8, p1: *const i8) -> c_int
extern fn _pcre2_strcpy_c8_8(p0: *mut u8, p1: *const i8) -> c_ulong
extern fn _pcre2_strlen_8(p0: *const u8) -> c_ulong
extern fn _pcre2_strncmp_8(p0: *const u8, p1: *const u8, p2: c_ulong) -> c_int
extern fn _pcre2_strncmp_c8_8(p0: *const u8, p1: *const i8, p2: c_ulong) -> c_int
@[c_export("_pcre2_study_8")]
fn _pcre2_study_8(re: *mut pcre2_real_code_8) -> c_int:
    var count: c_int = 0
    var code: *mut u8 = null
    var utf: c_int = 0
    var ucp: c_int = 0
    var depth: c_int = 0
    var rc: c_int = 0
    var i: c_int = 0
    var a: c_int = 0
    var b: c_int = 0
    var p: *mut u8 = null
    var flags: c_uint = 0
    var x: u8 = 0
    var c: c_int = 0
    var y: u8 = 0
    var d: c_int = 0
    var min: c_int = 0
    var backref_cache: [129]c_int = [0 as c_int; 129]
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                count = 0
                if (if ((re.flags & ((16 | 512)))) == 0: 1 else: 0) != 0:
                    depth = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    rc = set_start_bits(re, (code as *const u8), utf, ucp, (&mut depth as *mut c_int))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if rc == SSB_UNKNOWN: 1 else: 0) != 0:
                        return 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if rc == SSB_DONE: 1 else: 0) != 0:
                        a = -1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        b = -1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (i = 0)
                        while (if i < 256: 1 else: 0) != 0:
                            if (if x != 0: 1 else: 0) != 0:
                                if (if y != x: 1 else: 0) != 0:
                                    __pc = 1
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (c = i)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                match x
                                    1 => 0
                                    2 =>
                                        c = c + 1
                                    4 =>
                                        c = c + 2
                                    8 =>
                                        c = c + 3
                                    16 =>
                                        c = c + 4
                                    32 =>
                                        c = c + 5
                                    64 =>
                                        c = c + 6
                                    128 =>
                                        c = c + 7
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if utf != 0 and (if c > 127: 1 else: 0) != 0: 1 else: 0) != 0:
                                    __pc = 1
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if a < 0: 1 else: 0) != 0:
                                    (a = c)
                                else:
                                    if (if b < 0: 1 else: 0) != 0:
                                        d = (((re.tables + (256 as isize as usize)))[(c as c_uint)])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if d != a: 1 else: 0) != 0:
                                            __pc = 1
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (b = c)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        __pc = 1
                                        __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if a >= 0: 1 else: 0) != 0:
                            (re.first_codeunit = a)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            (flags = 16)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            if (if b >= 0: 1 else: 0) != 0:
                                flags = flags | 32
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        re.flags = re.flags | flags
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if ((re.flags & ((8192 | 8388608)))) == 0: 1 else: 0) != 0 and (if re.top_backref <= 128: 1 else: 0) != 0: 1 else: 0) != 0:
                    ((&backref_cache[0] as *mut c_int)[0] = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (min = find_minlength((re as *const pcre2_real_code_8), (code as *const u8), (code as *const u8), utf, (null as *mut recurse_check), (&mut count as *mut c_int), (&backref_cache[0] as *mut c_int)))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    match min
                        -1 => 0
                        -2 =>
                            return 2
                        -3 =>
                            return 3
                        _ =>
                            (re.minlength = (if ((if min > (65535 as c_int): 1 else: 0)) != 0: (65535 as c_int) else: min))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

extern fn _pcre2_valid_utf_8(p0: *const u8, p1: c_ulong, p2: *mut c_ulong) -> c_int
extern fn _pcre2_was_newline_8(p0: *const u8, p1: c_uint, p2: *const u8, p3: *mut c_uint, p4: c_int) -> c_int
extern fn _pcre2_xclass_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: c_int) -> c_int
extern fn _pcre2_eclass_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: *const u8, p4: c_int) -> c_int
let SSB_FAIL: c_uint = 0
let SSB_DONE: c_uint = 1
let SSB_CONTINUE: c_uint = 2
let SSB_UNKNOWN: c_uint = 3
let SSB_TOODEEP: c_uint = 4
fn find_minlength(re: *const pcre2_real_code_8, code: *const u8, startcode: *const u8, utf: c_int, recurses: *mut recurse_check, countptr: *mut c_int, backref_cache: *mut c_int) -> c_int:
    var length: c_int = 0
    var branchlength: c_int = 0
    var prev_cap_recno: c_int = 0
    var prev_cap_d: c_int = 0
    var prev_recurse_recno: c_int = 0
    var prev_recurse_d: c_int = 0
    var once_fudge: c_uint = 0
    var had_recurse: c_int = 0
    var dupcapused: c_int = 0
    var nextbranch: *const u8 = null
    var cc: *const u8 = null
    var this_recurse: recurse_check
    var d: c_int = 0
    var min: c_int = 0
    var recno: c_int = 0
    var op: u8 = 0
    var cs: *const u8 = null
    var ce: *const u8 = null
    var count: c_int = 0
    var slot: *const u8 = null
    var dd: c_int = 0
    var i: c_int = 0
    var r: *mut recurse_check = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                length = -1
                branchlength = 0
                prev_cap_recno = -1
                prev_cap_d = 0
                prev_recurse_recno = -1
                prev_recurse_d = 0
                if (if (if unsafe: *code >= OP_SBRA: 1 else: 0) != 0 and (if unsafe: *code <= OP_SCOND: 1 else: 0) != 0: 1 else: 0) != 0:
                    return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if unsafe: *code == OP_CBRA: 1 else: 0) != 0 or (if unsafe: *code == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
                    cc = cc + 2
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((unsafe: *countptr) = (unsafe: *countptr) + 1) > 1000: 1 else: 0) != 0:
                    return -1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while true:
                    if (if branchlength >= (65535 as c_int): 1 else: 0) != 0:
                        (branchlength = 65535)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (cc = nextbranch)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (op = unsafe: *cc)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    match op
                        OP_COND =>
                            if (if unsafe: *cs != OP_ALT: 1 else: 0) != 0:
                                (cc = ((cs + (1 as isize as usize)) + (2 as isize as usize)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            __pc = 1
                            __goto_pending = 1
                            if (if (if cc[(1 + 2)] == OP_RECURSE: 1 else: 0) != 0 and (if cc[(2 * ((1 + 2)))] == OP_KET: 1 else: 0) != 0: 1 else: 0) != 0:
                                (once_fudge = 3)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cc = cc + (1 + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if d < 0: 1 else: 0) != 0:
                                return d
                            branchlength = branchlength + d
                            cc = cc + (1 + 2)
                        OP_BRA =>
                            if (if (if cc[(1 + 2)] == OP_RECURSE: 1 else: 0) != 0 and (if cc[(2 * ((1 + 2)))] == OP_KET: 1 else: 0) != 0: 1 else: 0) != 0:
                                (once_fudge = 3)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cc = cc + (1 + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if d < 0: 1 else: 0) != 0:
                                return d
                            branchlength = branchlength + d
                            cc = cc + (1 + 2)
                        OP_ONCE =>
                            if (if d < 0: 1 else: 0) != 0:
                                return d
                            branchlength = branchlength + d
                            cc = cc + (1 + 2)
                        OP_CBRA =>
                            if (if dupcapused != 0 or (if recno != prev_cap_recno: 1 else: 0) != 0: 1 else: 0) != 0:
                                (prev_cap_recno = recno)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (prev_cap_d = find_minlength(re, cc, startcode, utf, recurses, countptr, backref_cache))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if prev_cap_d < 0: 1 else: 0) != 0:
                                    return prev_cap_d
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            branchlength = branchlength + prev_cap_d
                            cc = cc + (1 + 2)
                        OP_ACCEPT =>
                            if (if (if op != OP_ALT: 1 else: 0) != 0 or (if length == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                return length
                            cc = cc + (1 + 2)
                            (branchlength = 0)
                            (had_recurse = 0)
                        OP_ALT =>
                            if (if (if op != OP_ALT: 1 else: 0) != 0 or (if length == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                return length
                            cc = cc + (1 + 2)
                            (branchlength = 0)
                            (had_recurse = 0)
                        OP_ASSERT => 0
                        OP_REVERSE => 0
                        OP_CALLOUT_STR => 0
                        OP_BRAZERO =>
                            cc = cc + (1 + 2)
                        OP_CHAR =>
                            cc = cc + 2
                        OP_TYPEPLUS =>
                            cc = cc + (if ((if (if cc[1] == OP_PROP: 1 else: 0) != 0 or (if cc[1] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 4 else: 2)
                        OP_EXACT =>
                            cc = cc + (2 + 2)
                        OP_TYPEEXACT =>
                            cc = cc + ((2 + 2) + ((if ((if (if cc[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if cc[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                        OP_PROP =>
                            (cc = cc + 1)
                        OP_NOT_DIGIT =>
                            (cc = cc + 1)
                        OP_ANYNL =>
                            branchlength = branchlength + 1
                            (cc = cc + 1)
                        OP_ANYBYTE =>
                            (branchlength = branchlength + 1)
                            (cc = cc + 1)
                        OP_TYPESTAR =>
                            cc = cc + _pcre2_OP_lengths_8[op]
                        OP_TYPEUPTO =>
                            cc = cc + _pcre2_OP_lengths_8[op]
                        OP_CLASS =>
                            match unsafe: *cc
                                OP_CRPLUS => 0
                                OP_CRSTAR => 0
                                OP_CRRANGE =>
                                    cc = cc + (1 + (2 * 2))
                                _ =>
                                    (branchlength = branchlength + 1)
                        OP_DNREF =>
                            cc = cc + _pcre2_OP_lengths_8[unsafe: *cc]
                            __pc = 2
                            __goto_pending = 1
                            if (if (if recno <= backref_cache[0]: 1 else: 0) != 0 and (if backref_cache[recno] >= 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (d = backref_cache[recno])
                            else:
                                (d = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((re.overall_options & 512)) == 0: 1 else: 0) != 0:
                                    (cs = _pcre2_find_bracket_8(startcode, utf, recno))
                                    (ce = cs)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if cs == (null as *const u8): 1 else: 0) != 0:
                                        return -2
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if dupcapused != 0: 0 else: 1) != 0 or (if _pcre2_find_bracket_8(ce, utf, recno) == (null as *const u8): 1 else: 0) != 0: 1 else: 0) != 0:
                                        if (if (if cc > cs: 1 else: 0) != 0 and (if cc < ce: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (had_recurse = 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        else:
                                            (r = recurses)
                                            while (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                                if (if r.group == cs: 1 else: 0) != 0:
                                                    break
                                                (r = r.prev)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                                (had_recurse = 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                (this_recurse.prev = recurses)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (this_recurse.group = cs)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (d = find_minlength(re, cs, startcode, utf, (&mut this_recurse as *mut recurse_check), countptr, backref_cache))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if d < 0: 1 else: 0) != 0:
                                                    return d
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (backref_cache[recno] = d)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i = (backref_cache[0] + 1))
                                while (if i < recno: 1 else: 0) != 0:
                                    (backref_cache[i] = -1)
                                    (i = i + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (backref_cache[0] = recno)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cc = cc + _pcre2_OP_lengths_8[unsafe: *cc]
                            match unsafe: *cc
                                OP_CRSTAR =>
                                    (cc = cc + 1)
                                OP_CRPLUS =>
                                    (cc = cc + 1)
                                OP_CRRANGE =>
                                    cc = cc + (1 + (2 * 2))
                                _ =>
                                    (min = 1)
                            if (if ((if (if d > 0: 1 else: 0) != 0 and (if ((2147483647 / d)) < min: 1 else: 0) != 0: 1 else: 0)) != 0 or (if ((65535 as c_int) - branchlength) < (min * d): 1 else: 0) != 0: 1 else: 0) != 0:
                                (branchlength = 65535)
                            else:
                                branchlength = branchlength + (min * d)
                        OP_REF =>
                            if (if (if recno <= backref_cache[0]: 1 else: 0) != 0 and (if backref_cache[recno] >= 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (d = backref_cache[recno])
                            else:
                                (d = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((re.overall_options & 512)) == 0: 1 else: 0) != 0:
                                    (cs = _pcre2_find_bracket_8(startcode, utf, recno))
                                    (ce = cs)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if cs == (null as *const u8): 1 else: 0) != 0:
                                        return -2
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if dupcapused != 0: 0 else: 1) != 0 or (if _pcre2_find_bracket_8(ce, utf, recno) == (null as *const u8): 1 else: 0) != 0: 1 else: 0) != 0:
                                        if (if (if cc > cs: 1 else: 0) != 0 and (if cc < ce: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (had_recurse = 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        else:
                                            (r = recurses)
                                            while (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                                if (if r.group == cs: 1 else: 0) != 0:
                                                    break
                                                (r = r.prev)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                                (had_recurse = 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                (this_recurse.prev = recurses)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (this_recurse.group = cs)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (d = find_minlength(re, cs, startcode, utf, (&mut this_recurse as *mut recurse_check), countptr, backref_cache))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if d < 0: 1 else: 0) != 0:
                                                    return d
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (backref_cache[recno] = d)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i = (backref_cache[0] + 1))
                                while (if i < recno: 1 else: 0) != 0:
                                    (backref_cache[i] = -1)
                                    (i = i + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (backref_cache[0] = recno)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cc = cc + _pcre2_OP_lengths_8[unsafe: *cc]
                            match unsafe: *cc
                                OP_CRSTAR =>
                                    (cc = cc + 1)
                                OP_CRPLUS =>
                                    (cc = cc + 1)
                                OP_CRRANGE =>
                                    cc = cc + (1 + (2 * 2))
                                _ =>
                                    (min = 1)
                            if (if ((if (if d > 0: 1 else: 0) != 0 and (if ((2147483647 / d)) < min: 1 else: 0) != 0: 1 else: 0)) != 0 or (if ((65535 as c_int) - branchlength) < (min * d): 1 else: 0) != 0: 1 else: 0) != 0:
                                (branchlength = 65535)
                            else:
                                branchlength = branchlength + (min * d)
                        OP_RECURSE =>
                            if (if recno == prev_recurse_recno: 1 else: 0) != 0:
                                branchlength = branchlength + prev_recurse_d
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if cc > cs: 1 else: 0) != 0 and (if cc < ce: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (had_recurse = 1)
                                else:
                                    (r = recurses)
                                    while (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                        if (if r.group == cs: 1 else: 0) != 0:
                                            break
                                        (r = r.prev)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if r != (null as *mut recurse_check): 1 else: 0) != 0:
                                        (had_recurse = 1)
                                    else:
                                        (this_recurse.prev = recurses)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (this_recurse.group = cs)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prev_recurse_d = find_minlength(re, cs, startcode, utf, (&mut this_recurse as *mut recurse_check), countptr, backref_cache))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prev_recurse_d < 0: 1 else: 0) != 0:
                                            return prev_recurse_d
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prev_recurse_recno = recno)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        branchlength = branchlength + prev_recurse_d
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cc = cc + (3 +% once_fudge)
                            (once_fudge = 0)
                        OP_UPTO => 0
                        OP_MARK => 0
                        OP_CLOSE => 0
                        _ =>
                            return -3
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return -3
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn set_table_bit(re: *mut pcre2_real_code_8, __param_p: *const u8, caseless: c_int, utf: c_int, ucp: c_int) -> *const u8:
    var p = __param_p
    var c: c_uint
    utf
    ucp
    return p

fn set_type_bits(re: *mut pcre2_real_code_8, cbit_type: c_int, table_limit: c_uint):
    var c: c_uint
    (c = 0)
    while (if c < table_limit: 1 else: 0) != 0:
        (&re.start_bitmap[0] as *mut u8)[c] = (&re.start_bitmap[0] as *mut u8)[c] | re.tables[((c +% 512) +% cbit_type)]
        (c = c + 1)


fn set_nottype_bits(re: *mut pcre2_real_code_8, cbit_type: c_int, table_limit: c_uint):
    var c: c_uint

fn set_start_bits(re: *mut pcre2_real_code_8, __param_code: *const u8, utf: c_int, ucp: c_int, depthptr: *mut c_int) -> c_int:
    var code = __param_code
    var c: c_uint
    var yield_: c_int = SSB_DONE
    var table_limit: c_int = 32
    unsafe: *depthptr = unsafe: *depthptr + 1
    if (if unsafe: *depthptr > 1000: 1 else: 0) != 0:
        return SSB_TOODEEP

    while true:
        var try_next: c_int
        var tcode: *const u8
        if (if (if (if (if unsafe: *code == OP_CBRA: 1 else: 0) != 0 or (if unsafe: *code == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *code == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *code == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
            tcode = tcode + 2
        
        while try_next != 0:
            var rc: c_int
            var ncode: *const u8
            var classmap: *const u8
            match unsafe: *tcode
                OP_ACCEPT =>
                    tcode = tcode + _pcre2_OP_lengths_8[OP_CIRC]
                OP_CIRC =>
                    tcode = tcode + _pcre2_OP_lengths_8[OP_CIRC]
                OP_PROP =>
                    if (if tcode[1] != 9: 1 else: 0) != 0:
                        return SSB_FAIL
                    var p: *const c_uint
                    (try_next = 0)
                OP_WORD_BOUNDARY => 0
                OP_ASSERT =>
                    ncode = ncode + (1 + 2)
                    var done: c_int
                    while (if done != 0: 0 else: 1) != 0:
                        match unsafe: *ncode
                            OP_ASSERT =>
                                ncode = ncode + (1 + 2)
                            OP_WORD_BOUNDARY => 0
                            OP_CALLOUT =>
                                ncode = ncode + _pcre2_OP_lengths_8[OP_CALLOUT]
                            OP_CALLOUT_STR => 0
                            _ =>
                                (done = 1)
                        
                    match unsafe: *ncode
                        OP_PROP =>
                            if (if ncode[1] != 9: 1 else: 0) != 0:
                                break
                            continue
                        OP_ANYNL =>
                            continue
                        _ => 0
                    if (if rc == SSB_DONE: 1 else: 0) != 0:
                        (try_next = 0)
                    else:
                        if (if rc == SSB_CONTINUE: 1 else: 0) != 0:
                            tcode = tcode + (1 + 2)
                        else:
                            return rc
                OP_BRA =>
                    if (if rc == SSB_DONE: 1 else: 0) != 0:
                        (try_next = 0)
                    else:
                        if (if rc == SSB_CONTINUE: 1 else: 0) != 0:
                            tcode = tcode + (1 + 2)
                        else:
                            return rc
                OP_ALT =>
                    (yield_ = SSB_CONTINUE)
                    (try_next = 0)
                OP_KET =>
                    tcode = tcode + _pcre2_OP_lengths_8[OP_CALLOUT]
                OP_CALLOUT =>
                    tcode = tcode + _pcre2_OP_lengths_8[OP_CALLOUT]
                OP_CALLOUT_STR => 0
                OP_ASSERT_NOT =>
                    tcode = tcode + (1 + 2)
                OP_BRAZERO =>
                    if (if (if (if rc == SSB_FAIL: 1 else: 0) != 0 or (if rc == SSB_UNKNOWN: 1 else: 0) != 0: 1 else: 0) != 0 or (if rc == SSB_TOODEEP: 1 else: 0) != 0: 1 else: 0) != 0:
                        return rc
                    tcode = tcode + (1 + 2)
                OP_SKIPZERO =>
                    (tcode = tcode + 1)
                    tcode = tcode + (1 + 2)
                OP_STAR => 0
                OP_STARI => 0
                OP_UPTO => 0
                OP_UPTOI => 0
                OP_EXACT =>
                    tcode = tcode + 2
                    (try_next = 0)
                OP_CHAR =>
                    (try_next = 0)
                OP_EXACTI =>
                    tcode = tcode + 2
                    (try_next = 0)
                OP_CHARI =>
                    (try_next = 0)
                OP_HSPACE =>
                    (try_next = 0)
                OP_ANYNL =>
                    (try_next = 0)
                OP_NOT_DIGIT =>
                    set_nottype_bits(re, 64, table_limit)
                    (try_next = 0)
                OP_DIGIT =>
                    set_type_bits(re, 64, table_limit)
                    (try_next = 0)
                OP_NOT_WHITESPACE =>
                    set_nottype_bits(re, 0, table_limit)
                    (try_next = 0)
                OP_WHITESPACE =>
                    set_type_bits(re, 0, table_limit)
                    (try_next = 0)
                OP_NOT_WORDCHAR =>
                    set_nottype_bits(re, 160, table_limit)
                    (try_next = 0)
                OP_WORDCHAR =>
                    set_type_bits(re, 160, table_limit)
                    (try_next = 0)
                OP_TYPEPLUS => 0
                OP_TYPEEXACT =>
                    tcode = tcode + (1 + 2)
                OP_TYPEUPTO =>
                    tcode = tcode + 2
                OP_TYPESTAR =>
                    tcode = tcode + 2
                OP_NCLASS =>
                    if (if classmap != (null as *const u8): 1 else: 0) != 0:
                        (c = 0)
                        while (if c < 32: 1 else: 0) != 0:
                            (&re.start_bitmap[0] as *mut u8)[c] = (&re.start_bitmap[0] as *mut u8)[c] | classmap[c]
                            (c = c + 1)
                        
                        
                    match unsafe: *tcode
                        OP_CRSTAR => 0
                        OP_CRRANGE => 0
                        _ =>
                            (try_next = 0)
                _ =>
                    return SSB_UNKNOWN
            
        
        if not ((if unsafe: *code == OP_ALT: 1 else: 0) != 0):
            break

    return yield_

let ARG_MAX: c_int = 1048576
let BC_BASE_MAX: c_int = 99
let BC_DIM_MAX: c_int = 2048
let BC_SCALE_MAX: c_int = 99
let BC_STRING_MAX: c_int = 1000
let BUFSIZ: c_int = 1024
let BUS_ADRALN: c_int = 1
let BUS_ADRERR: c_int = 2
let BUS_NOOP: c_int = 0
let BUS_OBJERR: c_int = 3
// untranslatable fn-like macro
fn BYTES2CU() -> Never:
    comptime_error("untranslatable C macro: BYTES2CU")
// untranslatable fn-like macro
fn CAST_USER_ADDR_T() -> Never:
    comptime_error("untranslatable C macro: CAST_USER_ADDR_T")
let CHARCLASS_NAME_MAX: c_int = 14
let CHAR_0: c_int = 48
let CHAR_1: c_int = 49
let CHAR_2: c_int = 50
let CHAR_3: c_int = 51
let CHAR_4: c_int = 52
let CHAR_5: c_int = 53
let CHAR_6: c_int = 54
let CHAR_7: c_int = 55
let CHAR_8: c_int = 56
let CHAR_9: c_int = 57
let CHAR_A: c_int = 65
let CHAR_AMPERSAND: c_int = 38
let CHAR_APOSTROPHE: c_int = 39
let CHAR_ASTERISK: c_int = 42
let CHAR_B: c_int = 66
let CHAR_BACKSLASH: c_int = 92
let CHAR_BEL: c_int = 7
let CHAR_BIT: c_int = 8
let CHAR_BS: c_int = 8
let CHAR_C: c_int = 67
let CHAR_CIRCUMFLEX_ACCENT: c_int = 94
let CHAR_COLON: c_int = 58
let CHAR_COMMA: c_int = 44
let CHAR_COMMERCIAL_AT: c_int = 64
let CHAR_CR: c_int = 13
let CHAR_D: c_int = 68
let CHAR_DOLLAR_SIGN: c_int = 36
let CHAR_DOT: c_int = 46
let CHAR_E: c_int = 69
let CHAR_EQUALS_SIGN: c_int = 61
let CHAR_ESC: c_int = 0
let CHAR_EXCLAMATION_MARK: c_int = 33
let CHAR_F: c_int = 70
let CHAR_FF: c_int = 12
let CHAR_G: c_int = 71
let CHAR_GRAVE_ACCENT: c_int = 96
let CHAR_GREATER_THAN_SIGN: c_int = 62
let CHAR_H: c_int = 72
let CHAR_HT: c_int = 9
let CHAR_I: c_int = 73
let CHAR_J: c_int = 74
let CHAR_K: c_int = 75
let CHAR_L: c_int = 76
let CHAR_LEFT_CURLY_BRACKET: c_int = 123
let CHAR_LEFT_PARENTHESIS: c_int = 40
let CHAR_LEFT_SQUARE_BRACKET: c_int = 91
let CHAR_LESS_THAN_SIGN: c_int = 60
let CHAR_LF: c_int = 10
let CHAR_M: c_int = 77
let CHAR_MAX: c_int = 127
let CHAR_MINUS: c_int = 45
let CHAR_N: c_int = 78
let CHAR_NL: c_int = 10
let CHAR_NUL: c_int = 0
let CHAR_NUMBER_SIGN: c_int = 35
let CHAR_O: c_int = 79
let CHAR_P: c_int = 80
let CHAR_PERCENT_SIGN: c_int = 37
let CHAR_PLUS: c_int = 43
let CHAR_Q: c_int = 81
let CHAR_QUESTION_MARK: c_int = 63
let CHAR_QUOTATION_MARK: c_int = 34
let CHAR_R: c_int = 82
let CHAR_RIGHT_CURLY_BRACKET: c_int = 125
let CHAR_RIGHT_PARENTHESIS: c_int = 41
let CHAR_RIGHT_SQUARE_BRACKET: c_int = 93
let CHAR_S: c_int = 83
let CHAR_SEMICOLON: c_int = 59
let CHAR_SLASH: c_int = 47
let CHAR_SPACE: c_int = 32
let CHAR_T: c_int = 84
let CHAR_TILDE: c_int = 126
let CHAR_U: c_int = 85
let CHAR_UNDERSCORE: c_int = 95
let CHAR_V: c_int = 86
let CHAR_VERTICAL_LINE: c_int = 124
let CHAR_VT: c_int = 11
let CHAR_W: c_int = 87
let CHAR_X: c_int = 88
let CHAR_Y: c_int = 89
let CHAR_Z: c_int = 90
let CHAR_a: c_int = 97
let CHAR_b: c_int = 98
let CHAR_c: c_int = 99
let CHAR_d: c_int = 100
let CHAR_e: c_int = 101
let CHAR_f: c_int = 102
let CHAR_g: c_int = 103
let CHAR_h: c_int = 104
let CHAR_i: c_int = 105
let CHAR_j: c_int = 106
let CHAR_k: c_int = 107
let CHAR_l: c_int = 108
let CHAR_m: c_int = 109
let CHAR_n: c_int = 110
let CHAR_o: c_int = 111
let CHAR_p: c_int = 112
let CHAR_q: c_int = 113
let CHAR_r: c_int = 114
let CHAR_s: c_int = 115
let CHAR_t: c_int = 116
let CHAR_u: c_int = 117
let CHAR_v: c_int = 118
let CHAR_w: c_int = 119
let CHAR_x: c_int = 120
let CHAR_y: c_int = 121
let CHAR_z: c_int = 122
let CHILD_MAX: c_int = 266
// untranslatable fn-like macro
fn CHMAX_255() -> Never:
    comptime_error("untranslatable C macro: CHMAX_255")
let CLD_CONTINUED: c_int = 6
let CLD_DUMPED: c_int = 3
let CLD_EXITED: c_int = 1
let CLD_KILLED: c_int = 2
let CLD_NOOP: c_int = 0
let CLD_STOPPED: c_int = 5
let CLD_TRAPPED: c_int = 4
let COLL_WEIGHTS_MAX: c_int = 2
let COMPILE_ERROR_BASE: c_int = 100
let CONFIGURED_LINK_SIZE: c_int = 2
let CPUMON_MAKE_FATAL: c_int = 0x1000
// untranslatable fn-like macro
fn CU2BYTES() -> Never:
    comptime_error("untranslatable C macro: CU2BYTES")
let DFA_START_RWS_SIZE: c_int = 30720
let ECLASS_NEST_LIMIT: c_int = 15
let ECL_AND: c_int = 1
let ECL_ANY: c_int = 6
let ECL_MAP: c_int = 0x01
let ECL_NONE: c_int = 7
let ECL_NOT: c_int = 4
let ECL_OR: c_int = 2
let ECL_XCLASS: c_int = 5
let ECL_XOR: c_int = 3
let EOF: c_int = -1
let EQUIV_CLASS_MAX: c_int = 2
let EXIT_FAILURE: c_int = 1
let EXIT_SUCCESS: c_int = 0
let EXPR_NEST_MAX: c_int = 32
let FALSE: c_int = 0
let FILENAME_MAX: c_int = 1024
let FIRST_AUTOTAB_OP: c_int = OP_NOT_DIGIT
let FOOTPRINT_INTERVAL_RESET: c_int = 0x1
let FOPEN_MAX: c_int = 20
let FPE_FLTDIV: c_int = 1
let FPE_FLTINV: c_int = 5
let FPE_FLTOVF: c_int = 2
let FPE_FLTRES: c_int = 4
let FPE_FLTSUB: c_int = 6
let FPE_FLTUND: c_int = 3
let FPE_INTDIV: c_int = 7
let FPE_INTOVF: c_int = 8
let FPE_NOOP: c_int = 0
// untranslatable fn-like macro
fn GET() -> Never:
    comptime_error("untranslatable C macro: GET")
// untranslatable fn-like macro
fn GET2() -> Never:
    comptime_error("untranslatable C macro: GET2")
// untranslatable fn-like macro
fn GETCHAR() -> Never:
    comptime_error("untranslatable C macro: GETCHAR")
// untranslatable fn-like macro
fn GETCHARINC() -> Never:
    comptime_error("untranslatable C macro: GETCHARINC")
// untranslatable fn-like macro
fn GETCHARINCTEST() -> Never:
    comptime_error("untranslatable C macro: GETCHARINCTEST")
// untranslatable fn-like macro
fn GETCHARLEN() -> Never:
    comptime_error("untranslatable C macro: GETCHARLEN")
// untranslatable fn-like macro
fn GETCHARTEST() -> Never:
    comptime_error("untranslatable C macro: GETCHARTEST")
// untranslatable fn-like macro
fn GETUTF8() -> Never:
    comptime_error("untranslatable C macro: GETUTF8")
// untranslatable fn-like macro
fn GETUTF8INC() -> Never:
    comptime_error("untranslatable C macro: GETUTF8INC")
// untranslatable fn-like macro
fn GETUTF8LEN() -> Never:
    comptime_error("untranslatable C macro: GETUTF8LEN")
// untranslatable fn-like macro
fn GET_UCD() -> Never:
    comptime_error("untranslatable C macro: GET_UCD")
let GID_MAX: c_uint = 2147483647
fn HASUTF8EXTRALEN[T](c: T) -> T:
    (c >= 0xc0)
let HAVE_CONFIG_H: c_int = 1
let HEAP_LIMIT: c_int = 20000000
// untranslatable fn-like macro
fn HTONL() -> Never:
    comptime_error("untranslatable C macro: HTONL")
// untranslatable fn-like macro
fn HTONLL() -> Never:
    comptime_error("untranslatable C macro: HTONLL")
// untranslatable fn-like macro
fn HTONS() -> Never:
    comptime_error("untranslatable C macro: HTONS")
let ILL_BADSTK: c_int = 8
let ILL_COPROC: c_int = 7
let ILL_ILLADR: c_int = 5
let ILL_ILLOPC: c_int = 1
let ILL_ILLOPN: c_int = 4
let ILL_ILLTRP: c_int = 2
let ILL_NOOP: c_int = 0
let ILL_PRVOPC: c_int = 3
let ILL_PRVREG: c_int = 6
let IMM2_SIZE: c_int = 2
fn INT16_C[T](v: T) -> T:
    v
let INT16_MAX: c_int = 32767
let INT16_MIN: c_int = -32768
fn INT32_C[T](v: T) -> T:
    v
let INT32_MAX: c_int = 2147483647
let INT32_MIN: c_int = -2147483646
fn INT64_C[T](v: T) -> i64:
    (v as i64)
let INT64_MAX: c_longlong = 9223372036854775807
let INT64_MIN: c_int = -9223372036854775806
fn INT8_C[T](v: T) -> T:
    v
let INT8_MAX: c_int = 127
let INT8_MIN: c_int = -128
fn INTMAX_C[T](v: T) -> i64:
    (v as i64)
let INTMAX_MAX: c_int = INTMAX_C(9223372036854775807)
let INTMAX_MIN: c_int = ((0 - INTMAX_MAX) - 1)
let INTPTR_MAX: c_long = 9223372036854775807
let INTPTR_MIN: c_int = -9223372036854775806
let INT_FAST16_MAX: c_int = 32767
let INT_FAST16_MIN: c_int = -32768
let INT_FAST32_MAX: c_int = 2147483647
let INT_FAST32_MIN: c_int = -2147483646
let INT_FAST64_MAX: c_int = 9223372036854775807
let INT_FAST64_MIN: c_int = -9223372036854775806
let INT_FAST8_MAX: c_int = 127
let INT_FAST8_MIN: c_int = -128
let INT_LEAST16_MAX: c_int = 32767
let INT_LEAST16_MIN: c_int = -32768
let INT_LEAST32_MAX: c_int = 2147483647
let INT_LEAST32_MIN: c_int = -2147483646
let INT_LEAST64_MAX: c_int = 9223372036854775807
let INT_LEAST64_MIN: c_int = -9223372036854775806
let INT_LEAST8_MAX: c_int = 127
let INT_LEAST8_MIN: c_int = -128
let INT_MAX: c_int = 2147483647
let INT_MIN: c_int = -2147483646
let IOPOL_ATIME_UPDATES_DEFAULT: c_int = 0
let IOPOL_ATIME_UPDATES_OFF: c_int = 1
let IOPOL_DEFAULT: c_int = 0
let IOPOL_IMPORTANT: c_int = 1
let IOPOL_MATERIALIZE_DATALESS_FILES_BASIC_MASK: c_int = 3
let IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT: c_int = 0
let IOPOL_MATERIALIZE_DATALESS_FILES_OFF: c_int = 1
let IOPOL_MATERIALIZE_DATALESS_FILES_ON: c_int = 2
let IOPOL_MATERIALIZE_DATALESS_FILES_ORIG: c_int = 4
let IOPOL_NORMAL: c_int = 1
let IOPOL_PASSIVE: c_int = 2
let IOPOL_SCOPE_DARWIN_BG: c_int = 2
let IOPOL_SCOPE_PROCESS: c_int = 0
let IOPOL_SCOPE_THREAD: c_int = 1
let IOPOL_STANDARD: c_int = 5
let IOPOL_THROTTLE: c_int = 3
let IOPOL_TYPE_DISK: c_int = 0
let IOPOL_TYPE_VFS_ALLOW_LOW_SPACE_WRITES: c_int = 9
let IOPOL_TYPE_VFS_ATIME_UPDATES: c_int = 2
let IOPOL_TYPE_VFS_DISALLOW_RW_FOR_O_EVTONLY: c_int = 10
let IOPOL_TYPE_VFS_ENTITLED_RESERVE_ACCESS: c_int = 14
let IOPOL_TYPE_VFS_IGNORE_CONTENT_PROTECTION: c_int = 6
let IOPOL_TYPE_VFS_IGNORE_PERMISSIONS: c_int = 7
let IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES: c_int = 3
let IOPOL_TYPE_VFS_SKIP_MTIME_UPDATE: c_int = 8
let IOPOL_TYPE_VFS_STATFS_NO_DATA_VOLUME: c_int = 4
let IOPOL_TYPE_VFS_TRIGGER_RESOLVE: c_int = 5
let IOPOL_UTILITY: c_int = 4
let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_OFF: c_int = 0
let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_ON: c_int = 1
let IOPOL_VFS_CONTENT_PROTECTION_DEFAULT: c_int = 0
let IOPOL_VFS_CONTENT_PROTECTION_IGNORE: c_int = 1
let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_DEFAULT: c_int = 0
let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_ON: c_int = 1
let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_OFF: c_int = 0
let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_ON: c_int = 1
let IOPOL_VFS_IGNORE_PERMISSIONS_OFF: c_int = 0
let IOPOL_VFS_IGNORE_PERMISSIONS_ON: c_int = 1
let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_DEFAULT: c_int = 0
let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_ON: c_int = 1
let IOPOL_VFS_SKIP_MTIME_UPDATE_IGNORE: c_int = 2
let IOPOL_VFS_SKIP_MTIME_UPDATE_OFF: c_int = 0
let IOPOL_VFS_SKIP_MTIME_UPDATE_ON: c_int = 1
let IOPOL_VFS_STATFS_FORCE_NO_DATA_VOLUME: c_int = 1
let IOPOL_VFS_STATFS_NO_DATA_VOLUME_DEFAULT: c_int = 0
let IOPOL_VFS_TRIGGER_RESOLVE_DEFAULT: c_int = 0
let IOPOL_VFS_TRIGGER_RESOLVE_OFF: c_int = 1
let IOV_MAX: c_int = 1024
// untranslatable fn-like macro
fn IS_NEWLINE() -> Never:
    comptime_error("untranslatable C macro: IS_NEWLINE")
let LAST_AUTOTAB_LEFT_OP: c_int = OP_EXTUNI
let LAST_AUTOTAB_RIGHT_OP: c_int = OP_DOLLM
let LINE_MAX: c_int = 2048
let LINK_MAX: c_int = 32767
let LINK_SIZE: c_int = 2
let LLONG_MAX: c_int = 9223372036854775807
let LLONG_MIN: c_int = -9223372036854775806
let LONG_BIT: c_int = 64
let LONG_LONG_MAX: c_int = 9223372036854775807
let LONG_LONG_MIN: c_int = -9223372036854775806
let LONG_MAX: c_int = 9223372036854775807
let LONG_MIN: c_int = -9223372036854775806
let LT_OBJDIR = ".libs/"
let L_ctermid: c_int = 1024
let L_tmpnam: c_int = 1024
let MAGIC_NUMBER: c_ulong = 0x50435245
// untranslatable fn-like macro
fn MAPBIT() -> Never:
    comptime_error("untranslatable C macro: MAPBIT")
// untranslatable fn-like macro
fn MAPSET() -> Never:
    comptime_error("untranslatable C macro: MAPSET")
let MATCH_LIMIT: c_int = 10000000
let MATCH_LIMIT_DEPTH: c_int = 10000000
// untranslatable fn-like macro
fn MAX_255() -> Never:
    comptime_error("untranslatable C macro: MAX_255")
let MAX_CACHE_BACKREF: c_int = 128
let MAX_CANON: c_int = 1024
let MAX_INPUT: c_int = 1024
let MAX_NAME_COUNT: c_int = 10000
let MAX_NAME_SIZE: c_int = 128
let MAX_NON_UTF_CHAR: f64 = 4294967295.0
let MAX_PATTERN_SIZE: c_int = 65536
let MAX_UTF_CODE_POINT: c_int = 0x10ffff
let MAX_VARLOOKBEHIND: c_int = 255
let MB_LEN_MAX: c_int = 6
let MINSIGSTKSZ: c_int = 32768
let NAME_MAX: c_int = 255
let NEWLINE_DEFAULT: c_int = 2
let NGROUPS_MAX: c_int = 16
let NLTYPE_ANY: c_int = 1
let NLTYPE_ANYCRLF: c_int = 2
let NLTYPE_FIXED: c_int = 0
let NL_ARGMAX: c_int = 9
let NL_LANGMAX: c_int = 14
let NL_MSGMAX: c_int = 32767
let NL_NMAX: c_int = 1
let NL_SETMAX: c_int = 255
let NL_TEXTMAX: c_int = 2048
let NOTACHAR: c_int = 0xffffffff
// untranslatable fn-like macro
fn NTOHL() -> Never:
    comptime_error("untranslatable C macro: NTOHL")
// untranslatable fn-like macro
fn NTOHLL() -> Never:
    comptime_error("untranslatable C macro: NTOHLL")
// untranslatable fn-like macro
fn NTOHS() -> Never:
    comptime_error("untranslatable C macro: NTOHS")
let NZERO: c_int = 20
let OFF_MAX: c_int = 9223372036854775807
let OFF_MIN: c_int = -9223372036854775806
let OPEN_MAX: c_int = 10240
let PACKAGE = "pcre2"
let PACKAGE_BUGREPORT = ""
let PACKAGE_NAME = "PCRE2"
let PACKAGE_STRING = "PCRE2 10.48-DEV"
let PACKAGE_TARNAME = "pcre2"
let PACKAGE_URL = ""
let PACKAGE_VERSION = "10.48-DEV"
let PARENS_NEST_LIMIT: c_int = 250
let PASS_MAX: c_int = 128
let PATH_MAX: c_int = 1024
let PCRE2GREP_BUFSIZE: c_int = 20480
let PCRE2GREP_MAX_BUFSIZE: c_int = 1048576
let PCRE2_ALLOW_EMPTY_CLASS: c_uint = 0x00000001
let PCRE2_ALT_BSUX: c_uint = 0x00000002
let PCRE2_ALT_CIRCUMFLEX: c_uint = 0x00200000
let PCRE2_ALT_EXTENDED_CLASS: c_uint = 0x08000000
let PCRE2_ALT_VERBNAMES: c_uint = 0x00400000
let PCRE2_ANCHORED: c_uint = 0x80000000
// untranslatable fn-like macro
fn PCRE2_ASSERT() -> Never:
    comptime_error("untranslatable C macro: PCRE2_ASSERT")
let PCRE2_AUTO_CALLOUT: c_uint = 0x00000004
let PCRE2_AUTO_POSSESS: c_int = 64
let PCRE2_AUTO_POSSESS_OFF: c_int = 65
let PCRE2_BSR_ANYCRLF: c_int = 2
let PCRE2_BSR_SET: c_uint = 0x00004000
let PCRE2_BSR_UNICODE: c_int = 1
let PCRE2_CALLOUT_BACKTRACK: c_uint = 0x00000002
let PCRE2_CALLOUT_STARTMATCH: c_uint = 0x00000001
let PCRE2_CASELESS: c_uint = 0x00000008
let PCRE2_CODE_UNIT_WIDTH: c_int = 8
let PCRE2_CONFIG_BSR: c_int = 0
let PCRE2_CONFIG_COMPILED_WIDTHS: c_int = 14
let PCRE2_CONFIG_DEPTHLIMIT: c_int = 7
let PCRE2_CONFIG_EFFECTIVE_LINKSIZE: c_int = 16
let PCRE2_CONFIG_HEAPLIMIT: c_int = 12
let PCRE2_CONFIG_JIT: c_int = 1
let PCRE2_CONFIG_JITTARGET: c_int = 2
let PCRE2_CONFIG_LINKSIZE: c_int = 3
let PCRE2_CONFIG_MATCHLIMIT: c_int = 4
let PCRE2_CONFIG_NEVER_BACKSLASH_C: c_int = 13
let PCRE2_CONFIG_NEWLINE: c_int = 5
let PCRE2_CONFIG_PARENSLIMIT: c_int = 6
let PCRE2_CONFIG_RECURSIONLIMIT: c_int = 7
let PCRE2_CONFIG_STACKRECURSE: c_int = 8
let PCRE2_CONFIG_TABLES_LENGTH: c_int = 15
let PCRE2_CONFIG_UNICODE: c_int = 9
let PCRE2_CONFIG_UNICODE_VERSION: c_int = 10
let PCRE2_CONFIG_VERSION: c_int = 11
let PCRE2_CONVERT_GLOB: c_uint = 0x00000010
let PCRE2_CONVERT_GLOB_NO_STARSTAR: c_uint = 0x00000050
let PCRE2_CONVERT_GLOB_NO_WILD_SEPARATOR: c_uint = 0x00000030
let PCRE2_CONVERT_NO_UTF_CHECK: c_uint = 0x00000002
let PCRE2_CONVERT_POSIX_BASIC: c_uint = 0x00000004
let PCRE2_CONVERT_POSIX_EXTENDED: c_uint = 0x00000008
let PCRE2_CONVERT_UTF: c_uint = 0x00000001
let PCRE2_COPY_MATCHED_SUBJECT: c_uint = 0x00004000
let PCRE2_DATE: c_int = 1994
// untranslatable fn-like macro
fn PCRE2_DEBUG_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_DEBUG_UNREACHABLE")
let PCRE2_DEREF_TABLES: c_uint = 0x00040000
let PCRE2_DFA_RESTART: c_uint = 0x00000040
let PCRE2_DFA_SHORTEST: c_uint = 0x00000080
let PCRE2_DISABLE_RECURSELOOP_CHECK: c_uint = 0x00040000
let PCRE2_DOLLAR_ENDONLY: c_uint = 0x00000010
let PCRE2_DOTALL: c_uint = 0x00000020
let PCRE2_DOTSTAR_ANCHOR: c_int = 66
let PCRE2_DOTSTAR_ANCHOR_OFF: c_int = 67
let PCRE2_DUPCAPUSED: c_uint = 0x00200000
let PCRE2_DUPNAMES: c_uint = 0x00000040
let PCRE2_ENDANCHORED: c_uint = 0x20000000
let PCRE2_ERROR_ALPHA_ASSERTION_UNKNOWN: c_int = 195
let PCRE2_ERROR_BACKSLASH_C_CALLER_DISABLED: c_int = 183
let PCRE2_ERROR_BACKSLASH_C_LIBRARY_DISABLED: c_int = 185
let PCRE2_ERROR_BACKSLASH_C_SYNTAX: c_int = 168
let PCRE2_ERROR_BACKSLASH_G_SYNTAX: c_int = 157
let PCRE2_ERROR_BACKSLASH_K_IN_LOOKAROUND: c_int = 199
let PCRE2_ERROR_BACKSLASH_K_SYNTAX: c_int = 169
let PCRE2_ERROR_BACKSLASH_N_IN_CLASS: c_int = 171
let PCRE2_ERROR_BACKSLASH_O_MISSING_BRACE: c_int = 155
let PCRE2_ERROR_BACKSLASH_U_CODE_POINT_TOO_BIG: c_int = 177
let PCRE2_ERROR_BADDATA: c_int = -29
let PCRE2_ERROR_BADMAGIC: c_int = -31
let PCRE2_ERROR_BADMODE: c_int = -32
let PCRE2_ERROR_BADOFFSET: c_int = -33
let PCRE2_ERROR_BADOFFSETLIMIT: c_int = -56
let PCRE2_ERROR_BADOPTION: c_int = -34
let PCRE2_ERROR_BADREPESCAPE: c_int = -57
let PCRE2_ERROR_BADREPLACEMENT: c_int = -35
let PCRE2_ERROR_BADSERIALIZEDDATA: c_int = -62
let PCRE2_ERROR_BADSUBSPATTERN: c_int = -60
let PCRE2_ERROR_BADSUBSTITUTION: c_int = -59
let PCRE2_ERROR_BADUTFOFFSET: c_int = -36
let PCRE2_ERROR_BAD_BACKSLASH_K: c_int = -75
let PCRE2_ERROR_BAD_LITERAL_OPTIONS: c_int = 192
let PCRE2_ERROR_BAD_OPTIONS: c_int = 117
let PCRE2_ERROR_BAD_RELATIVE_REFERENCE: c_int = 129
let PCRE2_ERROR_BAD_SUBPATTERN_REFERENCE: c_int = 115
let PCRE2_ERROR_CALLOUT: c_int = -37
let PCRE2_ERROR_CALLOUT_BAD_STRING_DELIMITER: c_int = 182
let PCRE2_ERROR_CALLOUT_CALLER_DISABLED: c_int = 203
let PCRE2_ERROR_CALLOUT_NO_STRING_DELIMITER: c_int = 181
let PCRE2_ERROR_CALLOUT_NUMBER_TOO_BIG: c_int = 138
let PCRE2_ERROR_CALLOUT_STRING_TOO_LONG: c_int = 172
let PCRE2_ERROR_CLASS_INVALID_RANGE: c_int = 150
let PCRE2_ERROR_CLASS_RANGE_ORDER: c_int = 108
let PCRE2_ERROR_CODE_POINT_TOO_BIG: c_int = 134
let PCRE2_ERROR_CONDITION_ASSERTION_EXPECTED: c_int = 128
let PCRE2_ERROR_CONVERT_SYNTAX: c_int = -64
let PCRE2_ERROR_DEFINE_TOO_MANY_BRANCHES: c_int = 154
let PCRE2_ERROR_DEPTHLIMIT: c_int = -53
let PCRE2_ERROR_DFA_BADRESTART: c_int = -38
let PCRE2_ERROR_DFA_RECURSE: c_int = -39
let PCRE2_ERROR_DFA_UCOND: c_int = -40
let PCRE2_ERROR_DFA_UFUNC: c_int = -41
let PCRE2_ERROR_DFA_UINVALID_UTF: c_int = -66
let PCRE2_ERROR_DFA_UITEM: c_int = -42
let PCRE2_ERROR_DFA_WSSIZE: c_int = -43
let PCRE2_ERROR_DIFFSUBSOFFSET: c_int = -73
let PCRE2_ERROR_DIFFSUBSOPTIONS: c_int = -74
let PCRE2_ERROR_DIFFSUBSPATTERN: c_int = -71
let PCRE2_ERROR_DIFFSUBSSUBJECT: c_int = -72
let PCRE2_ERROR_DUPLICATE_SUBPATTERN_NAME: c_int = 143
let PCRE2_ERROR_ECLASS_EXPECTED_OPERAND: c_int = 210
let PCRE2_ERROR_ECLASS_HINT_SQUARE_BRACKET: c_int = 212
let PCRE2_ERROR_ECLASS_INVALID_OPERATOR: c_int = 208
let PCRE2_ERROR_ECLASS_MIXED_OPERATORS: c_int = 211
let PCRE2_ERROR_ECLASS_NEST_TOO_DEEP: c_int = 207
let PCRE2_ERROR_ECLASS_UNEXPECTED_OPERATOR: c_int = 209
let PCRE2_ERROR_END_BACKSLASH: c_int = 101
let PCRE2_ERROR_END_BACKSLASH_C: c_int = 102
let PCRE2_ERROR_ESCAPE_INVALID_IN_CLASS: c_int = 107
let PCRE2_ERROR_ESCAPE_INVALID_IN_VERB: c_int = 140
let PCRE2_ERROR_EXPECTED_CAPTURE_GROUP: c_int = 217
let PCRE2_ERROR_EXTRA_CASING_INCOMPATIBLE: c_int = 206
let PCRE2_ERROR_EXTRA_CASING_REQUIRES_UNICODE: c_int = 204
let PCRE2_ERROR_HEAPLIMIT: c_int = -63
let PCRE2_ERROR_HEAP_FAILED: c_int = 121
let PCRE2_ERROR_INTERNAL: c_int = -44
let PCRE2_ERROR_INTERNAL_BAD_CODE: c_int = 189
let PCRE2_ERROR_INTERNAL_BAD_CODE_AUTO_POSSESS: c_int = 180
let PCRE2_ERROR_INTERNAL_BAD_CODE_IN_SKIP: c_int = 190
let PCRE2_ERROR_INTERNAL_BAD_CODE_LOOKBEHINDS: c_int = 170
let PCRE2_ERROR_INTERNAL_CODE_OVERFLOW: c_int = 123
let PCRE2_ERROR_INTERNAL_DUPMATCH: c_int = -65
let PCRE2_ERROR_INTERNAL_MISSING_SUBPATTERN: c_int = 153
let PCRE2_ERROR_INTERNAL_OVERRAN_WORKSPACE: c_int = 152
let PCRE2_ERROR_INTERNAL_PARSED_OVERFLOW: c_int = 163
let PCRE2_ERROR_INTERNAL_STUDY_ERROR: c_int = 131
let PCRE2_ERROR_INTERNAL_UNEXPECTED_REPEAT: c_int = 110
let PCRE2_ERROR_INTERNAL_UNKNOWN_NEWLINE: c_int = 156
let PCRE2_ERROR_INVALIDOFFSET: c_int = -67
let PCRE2_ERROR_INVALID_AFTER_PARENS_QUERY: c_int = 111
let PCRE2_ERROR_INVALID_HEXADECIMAL: c_int = 167
let PCRE2_ERROR_INVALID_HYPHEN_IN_OPTIONS: c_int = 194
let PCRE2_ERROR_INVALID_OCTAL: c_int = 164
let PCRE2_ERROR_INVALID_SUBPATTERN_NAME: c_int = 144
let PCRE2_ERROR_JIT_BADOPTION: c_int = -45
let PCRE2_ERROR_JIT_STACKLIMIT: c_int = -46
let PCRE2_ERROR_JIT_UNSUPPORTED: c_int = -68
let PCRE2_ERROR_LOOKBEHIND_INVALID_BACKSLASH_C: c_int = 136
let PCRE2_ERROR_LOOKBEHIND_NOT_FIXED_LENGTH: c_int = 125
let PCRE2_ERROR_LOOKBEHIND_TOO_COMPLICATED: c_int = 135
let PCRE2_ERROR_LOOKBEHIND_TOO_LONG: c_int = 187
let PCRE2_ERROR_MALFORMED_UNICODE_PROPERTY: c_int = 146
let PCRE2_ERROR_MARK_MISSING_ARGUMENT: c_int = 166
let PCRE2_ERROR_MATCHLIMIT: c_int = -47
let PCRE2_ERROR_MAX_VAR_LOOKBEHIND_EXCEEDED: c_int = 200
let PCRE2_ERROR_MISSING_CALLOUT_CLOSING: c_int = 139
let PCRE2_ERROR_MISSING_CLOSING_PARENTHESIS: c_int = 114
let PCRE2_ERROR_MISSING_COMMENT_CLOSING: c_int = 118
let PCRE2_ERROR_MISSING_CONDITION_CLOSING: c_int = 124
let PCRE2_ERROR_MISSING_NAME_TERMINATOR: c_int = 142
let PCRE2_ERROR_MISSING_NUMBER_TERMINATOR: c_int = 219
let PCRE2_ERROR_MISSING_OCTAL_DIGIT: c_int = 198
let PCRE2_ERROR_MISSING_OCTAL_OR_HEX_DIGITS: c_int = 178
let PCRE2_ERROR_MISSING_OPENING_PARENTHESIS: c_int = 218
let PCRE2_ERROR_MISSING_SQUARE_BRACKET: c_int = 106
let PCRE2_ERROR_MIXEDTABLES: c_int = -30
let PCRE2_ERROR_NOMATCH: c_int = -1
let PCRE2_ERROR_NOMEMORY: c_int = -48
let PCRE2_ERROR_NOSUBSTRING: c_int = -49
let PCRE2_ERROR_NOUNIQUESUBSTRING: c_int = -50
let PCRE2_ERROR_NO_SURROGATES_IN_UTF16: c_int = 191
let PCRE2_ERROR_NULL: c_int = -51
let PCRE2_ERROR_NULL_ERROROFFSET: c_int = 220
let PCRE2_ERROR_NULL_PATTERN: c_int = 116
let PCRE2_ERROR_OCTAL_BYTE_TOO_BIG: c_int = 151
let PCRE2_ERROR_OVERSIZE_PYTHON_OCTAL: c_int = 202
let PCRE2_ERROR_PARENS_QUERY_R_MISSING_CLOSING: c_int = 158
let PCRE2_ERROR_PARENTHESES_NEST_TOO_DEEP: c_int = 119
let PCRE2_ERROR_PARENTHESES_STACK_CHECK: c_int = 133
let PCRE2_ERROR_PARTIAL: c_int = -2
let PCRE2_ERROR_PARTIALSUBS: c_int = -76
let PCRE2_ERROR_PATTERN_COMPILED_SIZE_TOO_BIG: c_int = 201
let PCRE2_ERROR_PATTERN_STRING_TOO_LONG: c_int = 188
let PCRE2_ERROR_PATTERN_TOO_COMPLICATED: c_int = 186
let PCRE2_ERROR_PATTERN_TOO_LARGE: c_int = 120
let PCRE2_ERROR_PERL_ECLASS_EMPTY_EXPR: c_int = 214
let PCRE2_ERROR_PERL_ECLASS_MISSING_CLOSE: c_int = 215
let PCRE2_ERROR_PERL_ECLASS_UNEXPECTED_CHAR: c_int = 216
let PCRE2_ERROR_PERL_ECLASS_UNEXPECTED_EXPR: c_int = 213
let PCRE2_ERROR_POSIX_CLASS_NOT_IN_CLASS: c_int = 112
let PCRE2_ERROR_POSIX_NO_SUPPORT_COLLATING: c_int = 113
let PCRE2_ERROR_QUANTIFIER_INVALID: c_int = 109
let PCRE2_ERROR_QUANTIFIER_OUT_OF_ORDER: c_int = 104
let PCRE2_ERROR_QUANTIFIER_TOO_BIG: c_int = 105
let PCRE2_ERROR_QUERY_BARJX_NEST_TOO_DEEP: c_int = 184
let PCRE2_ERROR_RECURSELOOP: c_int = -52
let PCRE2_ERROR_RECURSIONLIMIT: c_int = -53
let PCRE2_ERROR_REPLACECASE: c_int = -69
let PCRE2_ERROR_REPMISSINGBRACE: c_int = -58
let PCRE2_ERROR_SCRIPT_RUN_NOT_AVAILABLE: c_int = 196
let PCRE2_ERROR_SUBPATTERN_NAMES_MISMATCH: c_int = 165
let PCRE2_ERROR_SUBPATTERN_NAME_EXPECTED: c_int = 162
let PCRE2_ERROR_SUBPATTERN_NAME_TOO_LONG: c_int = 148
let PCRE2_ERROR_SUBPATTERN_NUMBER_TOO_BIG: c_int = 161
let PCRE2_ERROR_SUPPORTED_ONLY_IN_UNICODE: c_int = 193
let PCRE2_ERROR_TOOLARGEREPLACE: c_int = -70
let PCRE2_ERROR_TOOMANYREPLACE: c_int = -61
let PCRE2_ERROR_TOO_MANY_CAPTURES: c_int = 197
let PCRE2_ERROR_TOO_MANY_CONDITION_BRANCHES: c_int = 127
let PCRE2_ERROR_TOO_MANY_NAMED_SUBPATTERNS: c_int = 149
let PCRE2_ERROR_TURKISH_CASING_REQUIRES_UTF: c_int = 205
let PCRE2_ERROR_UCP_IS_DISABLED: c_int = 175
let PCRE2_ERROR_UNAVAILABLE: c_int = -54
let PCRE2_ERROR_UNICODE_DISALLOWED_CODE_POINT: c_int = 173
let PCRE2_ERROR_UNICODE_NOT_SUPPORTED: c_int = 132
let PCRE2_ERROR_UNICODE_PROPERTIES_UNAVAILABLE: c_int = 145
let PCRE2_ERROR_UNKNOWN_ESCAPE: c_int = 103
let PCRE2_ERROR_UNKNOWN_POSIX_CLASS: c_int = 130
let PCRE2_ERROR_UNKNOWN_UNICODE_PROPERTY: c_int = 147
let PCRE2_ERROR_UNMATCHED_CLOSING_PARENTHESIS: c_int = 122
let PCRE2_ERROR_UNRECOGNIZED_AFTER_QUERY_P: c_int = 141
let PCRE2_ERROR_UNSET: c_int = -55
let PCRE2_ERROR_UNSUPPORTED_ESCAPE_SEQUENCE: c_int = 137
let PCRE2_ERROR_UTF16_ERR1: c_int = -24
let PCRE2_ERROR_UTF16_ERR2: c_int = -25
let PCRE2_ERROR_UTF16_ERR3: c_int = -26
let PCRE2_ERROR_UTF32_ERR1: c_int = -27
let PCRE2_ERROR_UTF32_ERR2: c_int = -28
let PCRE2_ERROR_UTF8_ERR1: c_int = -3
let PCRE2_ERROR_UTF8_ERR10: c_int = -12
let PCRE2_ERROR_UTF8_ERR11: c_int = -13
let PCRE2_ERROR_UTF8_ERR12: c_int = -14
let PCRE2_ERROR_UTF8_ERR13: c_int = -15
let PCRE2_ERROR_UTF8_ERR14: c_int = -16
let PCRE2_ERROR_UTF8_ERR15: c_int = -17
let PCRE2_ERROR_UTF8_ERR16: c_int = -18
let PCRE2_ERROR_UTF8_ERR17: c_int = -19
let PCRE2_ERROR_UTF8_ERR18: c_int = -20
let PCRE2_ERROR_UTF8_ERR19: c_int = -21
let PCRE2_ERROR_UTF8_ERR2: c_int = -4
let PCRE2_ERROR_UTF8_ERR20: c_int = -22
let PCRE2_ERROR_UTF8_ERR21: c_int = -23
let PCRE2_ERROR_UTF8_ERR3: c_int = -5
let PCRE2_ERROR_UTF8_ERR4: c_int = -6
let PCRE2_ERROR_UTF8_ERR5: c_int = -7
let PCRE2_ERROR_UTF8_ERR6: c_int = -8
let PCRE2_ERROR_UTF8_ERR7: c_int = -9
let PCRE2_ERROR_UTF8_ERR8: c_int = -10
let PCRE2_ERROR_UTF8_ERR9: c_int = -11
let PCRE2_ERROR_UTF_IS_DISABLED: c_int = 174
let PCRE2_ERROR_VERB_ARGUMENT_NOT_ALLOWED: c_int = 159
let PCRE2_ERROR_VERB_NAME_TOO_LONG: c_int = 176
let PCRE2_ERROR_VERB_UNKNOWN: c_int = 160
let PCRE2_ERROR_VERSION_CONDITION_SYNTAX: c_int = 179
let PCRE2_ERROR_ZERO_RELATIVE_REFERENCE: c_int = 126
let PCRE2_EXTENDED: c_uint = 0x00000080
let PCRE2_EXTENDED_MORE: c_uint = 0x01000000
let PCRE2_EXTRA_ALLOW_LOOKAROUND_BSK: c_uint = 0x00000040
let PCRE2_EXTRA_ALLOW_SURROGATE_ESCAPES: c_uint = 0x00000001
let PCRE2_EXTRA_ALT_BSUX: c_uint = 0x00000020
let PCRE2_EXTRA_ASCII_BSD: c_uint = 0x00000100
let PCRE2_EXTRA_ASCII_BSS: c_uint = 0x00000200
let PCRE2_EXTRA_ASCII_BSW: c_uint = 0x00000400
let PCRE2_EXTRA_ASCII_DIGIT: c_uint = 0x00001000
let PCRE2_EXTRA_ASCII_POSIX: c_uint = 0x00000800
let PCRE2_EXTRA_BAD_ESCAPE_IS_LITERAL: c_uint = 0x00000002
let PCRE2_EXTRA_CASELESS_RESTRICT: c_uint = 0x00000080
let PCRE2_EXTRA_ESCAPED_CR_IS_LF: c_uint = 0x00000010
let PCRE2_EXTRA_MATCH_LINE: c_uint = 0x00000008
let PCRE2_EXTRA_MATCH_WORD: c_uint = 0x00000004
let PCRE2_EXTRA_NEVER_CALLOUT: c_uint = 0x00008000
let PCRE2_EXTRA_NO_BS0: c_uint = 0x00004000
let PCRE2_EXTRA_PYTHON_OCTAL: c_uint = 0x00002000
let PCRE2_EXTRA_TURKISH_CASING: c_uint = 0x00010000
let PCRE2_FIRSTCASELESS: c_uint = 0x00000020
let PCRE2_FIRSTLINE: c_uint = 0x00000100
let PCRE2_FIRSTMAPSET: c_uint = 0x00000040
let PCRE2_FIRSTSET: c_uint = 0x00000010
// untranslatable fn-like macro
fn PCRE2_GLUE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_GLUE")
let PCRE2_HASACCEPT: c_uint = 0x00800000
let PCRE2_HASBKC: c_uint = 0x00400000
let PCRE2_HASBKPORX: c_uint = 0x00100000
let PCRE2_HASBSK: c_uint = 0x01000000
let PCRE2_HASCRORLF: c_uint = 0x00000800
let PCRE2_HASTHEN: c_uint = 0x00001000
let PCRE2_INFO_ALLOPTIONS: c_int = 0
let PCRE2_INFO_ARGOPTIONS: c_int = 1
let PCRE2_INFO_BACKREFMAX: c_int = 2
let PCRE2_INFO_BSR: c_int = 3
let PCRE2_INFO_CAPTURECOUNT: c_int = 4
let PCRE2_INFO_DEPTHLIMIT: c_int = 21
let PCRE2_INFO_EXTRAOPTIONS: c_int = 26
let PCRE2_INFO_FIRSTBITMAP: c_int = 7
let PCRE2_INFO_FIRSTCODETYPE: c_int = 6
let PCRE2_INFO_FIRSTCODEUNIT: c_int = 5
let PCRE2_INFO_FRAMESIZE: c_int = 24
let PCRE2_INFO_HASBACKSLASHC: c_int = 23
let PCRE2_INFO_HASCRORLF: c_int = 8
let PCRE2_INFO_HEAPLIMIT: c_int = 25
let PCRE2_INFO_JCHANGED: c_int = 9
let PCRE2_INFO_JITSIZE: c_int = 10
let PCRE2_INFO_LASTCODETYPE: c_int = 12
let PCRE2_INFO_LASTCODEUNIT: c_int = 11
let PCRE2_INFO_MATCHEMPTY: c_int = 13
let PCRE2_INFO_MATCHLIMIT: c_int = 14
let PCRE2_INFO_MAXLOOKBEHIND: c_int = 15
let PCRE2_INFO_MINLENGTH: c_int = 16
let PCRE2_INFO_NAMECOUNT: c_int = 17
let PCRE2_INFO_NAMEENTRYSIZE: c_int = 18
let PCRE2_INFO_NAMETABLE: c_int = 19
let PCRE2_INFO_NEWLINE: c_int = 20
let PCRE2_INFO_RECURSIONLIMIT: c_int = 21
let PCRE2_INFO_SIZE: c_int = 22
let PCRE2_JCHANGED: c_uint = 0x00000400
let PCRE2_JIT_COMPLETE: c_uint = 0x00000001
let PCRE2_JIT_INVALID_UTF: c_uint = 0x00000100
let PCRE2_JIT_PARTIAL_HARD: c_uint = 0x00000004
let PCRE2_JIT_PARTIAL_SOFT: c_uint = 0x00000002
let PCRE2_JIT_TEST_ALLOC: c_uint = 0x00000200
// untranslatable fn-like macro
fn PCRE2_JOIN() -> Never:
    comptime_error("untranslatable C macro: PCRE2_JOIN")
let PCRE2_LASTCASELESS: c_uint = 0x00000100
let PCRE2_LASTSET: c_uint = 0x00000080
let PCRE2_LITERAL: c_uint = 0x02000000
let PCRE2_MAJOR: c_int = 10
let PCRE2_MATCH_EMPTY: c_uint = 0x00002000
let PCRE2_MATCH_INVALID_UTF: c_uint = 0x04000000
let PCRE2_MATCH_UNSET_BACKREF: c_uint = 0x00000200
let PCRE2_MD_COPIED_SUBJECT: c_uint = 0x01
let PCRE2_MINOR: c_int = 48
let PCRE2_MODE16: c_uint = 0x00000002
let PCRE2_MODE32: c_uint = 0x00000004
let PCRE2_MODE8: c_uint = 0x00000001
let PCRE2_MODE_MASK: c_int = 7
let PCRE2_MULTILINE: c_uint = 0x00000400
let PCRE2_NEVER_BACKSLASH_C: c_uint = 0x00100000
let PCRE2_NEVER_UCP: c_uint = 0x00000800
let PCRE2_NEVER_UTF: c_uint = 0x00001000
let PCRE2_NEWLINE_ANY: c_int = 4
let PCRE2_NEWLINE_ANYCRLF: c_int = 5
let PCRE2_NEWLINE_CR: c_int = 1
let PCRE2_NEWLINE_CRLF: c_int = 3
let PCRE2_NEWLINE_LF: c_int = 2
let PCRE2_NEWLINE_NUL: c_int = 6
let PCRE2_NE_ATST_SET: c_uint = 0x00020000
let PCRE2_NL_SET: c_uint = 0x00008000
let PCRE2_NOJIT: c_uint = 0x00080000
let PCRE2_NOTBOL: c_uint = 0x00000001
let PCRE2_NOTEMPTY: c_uint = 0x00000004
let PCRE2_NOTEMPTY_ATSTART: c_uint = 0x00000008
let PCRE2_NOTEMPTY_SET: c_uint = 0x00010000
let PCRE2_NOTEOL: c_uint = 0x00000002
let PCRE2_NO_AUTO_CAPTURE: c_uint = 0x00002000
let PCRE2_NO_AUTO_POSSESS: c_uint = 0x00004000
let PCRE2_NO_DOTSTAR_ANCHOR: c_uint = 0x00008000
let PCRE2_NO_JIT: c_uint = 0x00002000
let PCRE2_NO_START_OPTIMIZE: c_uint = 0x00010000
let PCRE2_NO_UTF_CHECK: c_uint = 0x40000000
let PCRE2_OPTIMIZATION_ALL: c_uint = 0x00000007
let PCRE2_OPTIMIZATION_FULL: c_int = 1
let PCRE2_OPTIMIZATION_NONE: c_int = 0
let PCRE2_OPTIM_AUTO_POSSESS: c_uint = 0x00000001
let PCRE2_OPTIM_DOTSTAR_ANCHOR: c_uint = 0x00000002
let PCRE2_OPTIM_START_OPTIMIZE: c_uint = 0x00000004
let PCRE2_PARTIAL_HARD: c_uint = 0x00000020
let PCRE2_PARTIAL_SOFT: c_uint = 0x00000010
let PCRE2_STARTLINE: c_uint = 0x00000200
let PCRE2_START_OPTIMIZE: c_int = 68
let PCRE2_START_OPTIMIZE_OFF: c_int = 69
let PCRE2_SUBSTITUTE_CASE_LOWER: c_int = 1
let PCRE2_SUBSTITUTE_CASE_TITLE_FIRST: c_int = 3
let PCRE2_SUBSTITUTE_CASE_UPPER: c_int = 2
let PCRE2_SUBSTITUTE_EXTENDED: c_uint = 0x00000200
let PCRE2_SUBSTITUTE_GLOBAL: c_uint = 0x00000100
let PCRE2_SUBSTITUTE_LITERAL: c_uint = 0x00008000
let PCRE2_SUBSTITUTE_MATCHED: c_uint = 0x00010000
let PCRE2_SUBSTITUTE_OVERFLOW_LENGTH: c_uint = 0x00001000
let PCRE2_SUBSTITUTE_REPLACEMENT_ONLY: c_uint = 0x00020000
let PCRE2_SUBSTITUTE_UNKNOWN_UNSET: c_uint = 0x00000800
let PCRE2_SUBSTITUTE_UNSET_EMPTY: c_uint = 0x00000400
fn PCRE2_SUFFIX[T](a: T) -> T:
    PCRE2_GLUE(a, PCRE2_CODE_UNIT_WIDTH)
let PCRE2_UCP: c_uint = 0x00020000
let PCRE2_UNGREEDY: c_uint = 0x00040000
// untranslatable fn-like macro
fn PCRE2_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_UNREACHABLE")
let PCRE2_USE_OFFSET_LIMIT: c_uint = 0x00800000
let PCRE2_UTF: c_uint = 0x00080000
let PIPE_BUF: c_int = 512
let POLL_ERR: c_int = 4
let POLL_HUP: c_int = 6
let POLL_IN: c_int = 1
let POLL_MSG: c_int = 3
let POLL_OUT: c_int = 2
let POLL_PRI: c_int = 5
let PRIO_DARWIN_BG: c_int = 0x1000
let PRIO_DARWIN_NONUI: c_int = 0x1001
let PRIO_DARWIN_PROCESS: c_int = 4
let PRIO_DARWIN_THREAD: c_int = 3
let PRIO_MAX: c_int = 20
let PRIO_MIN: c_int = -20
let PRIO_PGRP: c_int = 1
let PRIO_PROCESS: c_int = 0
let PRIO_USER: c_int = 2
// untranslatable fn-like macro
fn PRIV() -> Never:
    comptime_error("untranslatable C macro: PRIV")
let PRIX16 = "hX"
let PRIX32 = "X"
let PRIXFAST16: c_int = PRIX16
let PRIXFAST32: c_int = PRIX32
let PRIXLEAST16: c_int = PRIX16
let PRIXLEAST32: c_int = PRIX32
let PRIXPTR = "lX"
let PRId16 = "hd"
let PRId32 = "d"
let PRIdFAST16: c_int = PRId16
let PRIdFAST32: c_int = PRId32
let PRIdLEAST16: c_int = PRId16
let PRIdLEAST32: c_int = PRId32
let PRIdPTR = "ld"
let PRIi16 = "hi"
let PRIi32 = "i"
let PRIiFAST16: c_int = PRIi16
let PRIiFAST32: c_int = PRIi32
let PRIiLEAST16: c_int = PRIi16
let PRIiLEAST32: c_int = PRIi32
let PRIiPTR = "li"
let PRIo16 = "ho"
let PRIo32 = "o"
let PRIoFAST16: c_int = PRIo16
let PRIoFAST32: c_int = PRIo32
let PRIoLEAST16: c_int = PRIo16
let PRIoLEAST32: c_int = PRIo32
let PRIoPTR = "lo"
let PRIu16 = "hu"
let PRIu32 = "u"
let PRIuFAST16: c_int = PRIu16
let PRIuFAST32: c_int = PRIu32
let PRIuLEAST16: c_int = PRIu16
let PRIuLEAST32: c_int = PRIu32
let PRIuPTR = "lu"
let PRIx16 = "hx"
let PRIx32 = "x"
let PRIxFAST16: c_int = PRIx16
let PRIxFAST32: c_int = PRIx32
let PRIxLEAST16: c_int = PRIx16
let PRIxLEAST32: c_int = PRIx32
let PRIxPTR = "lx"
let PTHREAD_DESTRUCTOR_ITERATIONS: c_int = 4
let PTHREAD_KEYS_MAX: c_int = 512
let PTHREAD_STACK_MIN: c_int = 16384
let PTRDIFF_MAX: c_int = INTMAX_MAX
let PTRDIFF_MIN: c_int = INTMAX_MIN
let PT_ALNUM: c_int = 5
let PT_ANY: c_int = 13
let PT_BIDICL: c_int = 11
let PT_BOOL: c_int = 12
let PT_CLIST: c_int = 9
let PT_GC: c_int = 1
let PT_LAMP: c_int = 0
let PT_NOTSCRIPT: c_int = 255
let PT_PC: c_int = 2
let PT_PXGRAPH: c_int = 14
let PT_PXPRINT: c_int = 15
let PT_PXPUNCT: c_int = 16
let PT_PXSPACE: c_int = 7
let PT_PXXDIGIT: c_int = 17
let PT_SC: c_int = 3
let PT_SCX: c_int = 4
let PT_SPACE: c_int = 6
let PT_TABSIZE: c_int = 13
let PT_UCNC: c_int = 10
let PT_WORD: c_int = 8
// untranslatable fn-like macro
fn PUT() -> Never:
    comptime_error("untranslatable C macro: PUT")
// untranslatable fn-like macro
fn PUT2() -> Never:
    comptime_error("untranslatable C macro: PUT2")
// untranslatable fn-like macro
fn PUT2INC() -> Never:
    comptime_error("untranslatable C macro: PUT2INC")
// untranslatable fn-like macro
fn PUTCHAR() -> Never:
    comptime_error("untranslatable C macro: PUTCHAR")
// untranslatable fn-like macro
fn PUTINC() -> Never:
    comptime_error("untranslatable C macro: PUTINC")
let P_tmpdir = "/var/tmp/"
let QUAD_MAX: c_int = 9223372036854775807
let QUAD_MIN: c_int = -9223372036854775806
let RAND_MAX: c_int = 0x7fffffff
// untranslatable fn-like macro
fn REAL_GET_UCD() -> Never:
    comptime_error("untranslatable C macro: REAL_GET_UCD")
let REFI_FLAG_CASELESS_RESTRICT: c_int = 0x1
let REFI_FLAG_TURKISH_CASING: c_int = 0x2
let RENAME_EXCL: c_int = 0x00000004
let RENAME_NOFOLLOW_ANY: c_int = 0x00000010
let RENAME_RESERVED1: c_int = 0x00000008
let RENAME_RESOLVE_BENEATH: c_int = 0x00000020
let RENAME_SECLUDE: c_int = 0x00000001
let RENAME_SWAP: c_int = 0x00000002
let REQ_CU_MAX: c_int = 5000
let RE_DUP_MAX: c_int = 255
let RLIMIT_AS: c_int = 5
let RLIMIT_CORE: c_int = 4
let RLIMIT_CPU: c_int = 0
let RLIMIT_CPU_USAGE_MONITOR: c_int = 0x2
let RLIMIT_DATA: c_int = 2
let RLIMIT_FOOTPRINT_INTERVAL: c_int = 0x4
let RLIMIT_FSIZE: c_int = 1
let RLIMIT_MEMLOCK: c_int = 6
let RLIMIT_NOFILE: c_int = 8
let RLIMIT_NPROC: c_int = 7
let RLIMIT_RSS: c_int = 5
let RLIMIT_STACK: c_int = 3
let RLIMIT_THREAD_CPULIMITS: c_int = 0x3
let RLIMIT_WAKEUPS_MONITOR: c_int = 0x1
let RLIM_NLIMITS: c_int = 9
let RREF_ANY: c_int = 0xffff
let RUSAGE_CHILDREN: c_int = -1
let RUSAGE_INFO_V0: c_int = 0
let RUSAGE_INFO_V1: c_int = 1
let RUSAGE_INFO_V2: c_int = 2
let RUSAGE_INFO_V3: c_int = 3
let RUSAGE_INFO_V4: c_int = 4
let RUSAGE_INFO_V5: c_int = 5
let RUSAGE_INFO_V6: c_int = 6
let RUSAGE_SELF: c_int = 0
let RU_PROC_RUNS_RESLIDE: c_int = 0x00000001
let SA_64REGSET: c_int = 0x0200
let SA_NOCLDSTOP: c_int = 0x0008
let SA_NOCLDWAIT: c_int = 0x0020
let SA_NODEFER: c_int = 0x0010
let SA_ONSTACK: c_int = 0x0001
let SA_RESETHAND: c_int = 0x0004
let SA_RESTART: c_int = 0x0002
let SA_SIGINFO: c_int = 0x0040
let SA_USERSPACE_MASK: c_int = 127
let SA_USERTRAMP: c_int = 0x0100
let SCHAR_MAX: c_int = 127
let SCHAR_MIN: c_int = -126
let SCNd16 = "hd"
let SCNd32 = "d"
let SCNdFAST16: c_int = SCNd16
let SCNdFAST32: c_int = SCNd32
let SCNdLEAST16: c_int = SCNd16
let SCNdLEAST32: c_int = SCNd32
let SCNdPTR = "ld"
let SCNi16 = "hi"
let SCNi32 = "i"
let SCNiFAST16: c_int = SCNi16
let SCNiFAST32: c_int = SCNi32
let SCNiLEAST16: c_int = SCNi16
let SCNiLEAST32: c_int = SCNi32
let SCNiPTR = "li"
let SCNo16 = "ho"
let SCNo32 = "o"
let SCNoFAST16: c_int = SCNo16
let SCNoFAST32: c_int = SCNo32
let SCNoLEAST16: c_int = SCNo16
let SCNoLEAST32: c_int = SCNo32
let SCNoPTR = "lo"
let SCNu16 = "hu"
let SCNu32 = "u"
let SCNuFAST16: c_int = SCNu16
let SCNuFAST32: c_int = SCNu32
let SCNuLEAST16: c_int = SCNu16
let SCNuLEAST32: c_int = SCNu32
let SCNuPTR = "lu"
let SCNx16 = "hx"
let SCNx32 = "x"
let SCNxFAST16: c_int = SCNx16
let SCNxFAST32: c_int = SCNx32
let SCNxLEAST16: c_int = SCNx16
let SCNxLEAST32: c_int = SCNx32
let SCNxPTR = "lx"
let SEEK_CUR: c_int = 1
let SEEK_DATA: c_int = 4
let SEEK_END: c_int = 2
let SEEK_HOLE: c_int = 3
let SEEK_SET: c_int = 0
let SEGV_ACCERR: c_int = 2
let SEGV_MAPERR: c_int = 1
let SEGV_NOOP: c_int = 0
// untranslatable fn-like macro
fn SET_BIT() -> Never:
    comptime_error("untranslatable C macro: SET_BIT")
let SHRT_MAX: c_int = 32767
let SHRT_MIN: c_int = -32766
let SIGABRT: c_int = 6
let SIGALRM: c_int = 14
let SIGBUS: c_int = 10
let SIGCHLD: c_int = 20
let SIGCONT: c_int = 19
let SIGEMT: c_int = 7
let SIGEV_KEVENT: c_int = 4
let SIGEV_NONE: c_int = 0
let SIGEV_SIGNAL: c_int = 1
let SIGEV_THREAD: c_int = 3
let SIGFPE: c_int = 8
let SIGHUP: c_int = 1
let SIGILL: c_int = 4
let SIGINFO: c_int = 29
let SIGINT: c_int = 2
let SIGIO: c_int = 23
let SIGIOT: c_int = 6
let SIGKILL: c_int = 9
let SIGPIPE: c_int = 13
let SIGPROF: c_int = 27
let SIGQUIT: c_int = 3
let SIGSEGV: c_int = 11
let SIGSTKSZ: c_int = 131072
let SIGSTOP: c_int = 17
let SIGSYS: c_int = 12
let SIGTERM: c_int = 15
let SIGTRAP: c_int = 5
let SIGTSTP: c_int = 18
let SIGTTIN: c_int = 21
let SIGTTOU: c_int = 22
let SIGURG: c_int = 16
let SIGUSR1: c_int = 30
let SIGUSR2: c_int = 31
let SIGVTALRM: c_int = 26
let SIGWINCH: c_int = 28
let SIGXCPU: c_int = 24
let SIGXFSZ: c_int = 25
let SIG_ATOMIC_MAX: c_int = 2147483647
let SIG_ATOMIC_MIN: c_int = -2147483646
let SIG_BLOCK: c_int = 1
let SIG_SETMASK: c_int = 3
let SIG_UNBLOCK: c_int = 2
let SI_ASYNCIO: c_int = 0x10004
let SI_MESGQ: c_int = 0x10005
let SI_QUEUE: c_int = 0x10002
let SI_TIMER: c_int = 0x10003
let SI_USER: c_int = 0x10001
let SSIZE_MAX: c_int = 9223372036854775807
let SS_DISABLE: c_int = 0x0004
let SS_ONSTACK: c_int = 0x0001
let START_FRAMES_SIZE: c_int = 20480
// untranslatable fn-like macro
fn STATIC_ASSERT() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT")
// untranslatable fn-like macro
fn STATIC_ASSERT_JOIN() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT_JOIN")
let STR_0 = "0"
let STR_1 = "1"
let STR_2 = "2"
let STR_3 = "3"
let STR_4 = "4"
let STR_5 = "5"
let STR_6 = "6"
let STR_7 = "7"
let STR_8 = "8"
let STR_9 = "9"
let STR_A = "A"
let STR_AMPERSAND = "&"
let STR_APOSTROPHE = "'"
let STR_ASTERISK = "*"
let STR_B = "B"
let STR_BACKSLASH = "\\"
let STR_BEL = "\a"
let STR_BS = "\b"
let STR_C = "C"
let STR_CIRCUMFLEX_ACCENT = "^"
let STR_COLON = ":"
let STR_COMMA = ","
let STR_COMMERCIAL_AT = "@"
let STR_CR = "\r"
let STR_D = "D"
let STR_DEL = "\177"
let STR_DOLLAR_SIGN = "$"
let STR_DOT = "."
let STR_E = "E"
let STR_EQUALS_SIGN = "="
let STR_ESC = "\033"
let STR_EXCLAMATION_MARK = "!"
let STR_F = "F"
let STR_FF = "\f"
let STR_G = "G"
let STR_GRAVE_ACCENT = "`"
let STR_GREATER_THAN_SIGN = ">"
let STR_H = "H"
let STR_HT = "\t"
let STR_I = "I"
let STR_J = "J"
let STR_K = "K"
let STR_L = "L"
let STR_LEFT_CURLY_BRACKET = "{"
let STR_LEFT_PARENTHESIS = "("
let STR_LEFT_SQUARE_BRACKET = "["
let STR_LESS_THAN_SIGN = "<"
let STR_LF = "\n"
let STR_M = "M"
let STR_MINUS = "-"
let STR_N = "N"
let STR_NEL = "\x85"
let STR_NL: c_int = STR_LF
let STR_NUMBER_SIGN = "#"
let STR_O = "O"
let STR_P = "P"
let STR_PERCENT_SIGN = "%"
let STR_PLUS = "+"
let STR_Q = "Q"
let STR_QUESTION_MARK = "?"
let STR_QUOTATION_MARK = "\""
let STR_R = "R"
let STR_RIGHT_CURLY_BRACKET = "}"
let STR_RIGHT_PARENTHESIS = ")"
let STR_RIGHT_SQUARE_BRACKET = "]"
let STR_S = "S"
let STR_SEMICOLON = ";"
let STR_SLASH = "/"
let STR_SPACE = " "
let STR_T = "T"
let STR_TILDE = "~"
let STR_U = "U"
let STR_UNDERSCORE = "_"
let STR_V = "V"
let STR_VERTICAL_LINE = "|"
let STR_VT = "\v"
let STR_W = "W"
let STR_X = "X"
let STR_Y = "Y"
let STR_Z = "Z"
let STR_a = "a"
let STR_b = "b"
let STR_c = "c"
let STR_d = "d"
let STR_e = "e"
let STR_f = "f"
let STR_g = "g"
let STR_h = "h"
let STR_i = "i"
let STR_j = "j"
let STR_k = "k"
let STR_l = "l"
let STR_m = "m"
let STR_n = "n"
let STR_o = "o"
let STR_p = "p"
let STR_q = "q"
let STR_r = "r"
let STR_s = "s"
let STR_t = "t"
let STR_u = "u"
let STR_v = "v"
let STR_w = "w"
let STR_x = "x"
let STR_y = "y"
let STR_z = "z"
let SUPPORT_PCRE2_8: c_int = 1
let SV_INTERRUPT: c_int = 0x0002
let SV_NOCLDSTOP: c_int = 0x0008
let SV_NODEFER: c_int = 0x0010
let SV_ONSTACK: c_int = 0x0001
let SV_RESETHAND: c_int = 0x0004
let SV_SIGINFO: c_int = 0x0040
// untranslatable fn-like macro
fn TABLE_GET() -> Never:
    comptime_error("untranslatable C macro: TABLE_GET")
let TARGET_IPHONE_SIMULATOR: c_int = 0
let TARGET_OS_ARROW: c_int = 1
let TARGET_OS_BRIDGE: c_int = 0
let TARGET_OS_DRIVERKIT: c_int = 0
let TARGET_OS_EMBEDDED: c_int = 0
let TARGET_OS_IOS: c_int = 0
let TARGET_OS_IOSMAC: c_int = 0
let TARGET_OS_IPHONE: c_int = 0
let TARGET_OS_LINUX: c_int = 0
let TARGET_OS_MAC: c_int = 1
let TARGET_OS_MACCATALYST: c_int = 0
let TARGET_OS_NANO: c_int = 0
let TARGET_OS_OSX: c_int = 1
let TARGET_OS_SIMULATOR: c_int = 0
let TARGET_OS_TV: c_int = 0
let TARGET_OS_UIKITFORMAC: c_int = 0
let TARGET_OS_UNIX: c_int = 0
let TARGET_OS_VISION: c_int = 0
let TARGET_OS_WATCH: c_int = 0
let TARGET_OS_WIN32: c_int = 0
let TARGET_OS_WINDOWS: c_int = 0
let TARGET_OS_XR: c_int = 0
let TMP_MAX: c_int = 308915776
let TRAP_BRKPT: c_int = 1
let TRAP_TRACE: c_int = 2
let TRUE: c_int = 1
// untranslatable fn-like macro
fn UCD_ANY_I() -> Never:
    comptime_error("untranslatable C macro: UCD_ANY_I")
// untranslatable fn-like macro
fn UCD_BIDICLASS() -> Never:
    comptime_error("untranslatable C macro: UCD_BIDICLASS")
// untranslatable fn-like macro
fn UCD_BIDICLASS_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_BIDICLASS_PROP")
let UCD_BIDICLASS_SHIFT: c_int = 11
let UCD_BLOCK_SIZE: c_int = 128
// untranslatable fn-like macro
fn UCD_BPROPS() -> Never:
    comptime_error("untranslatable C macro: UCD_BPROPS")
let UCD_BPROPS_MASK: c_int = 0xfff
// untranslatable fn-like macro
fn UCD_BPROPS_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_BPROPS_PROP")
// untranslatable fn-like macro
fn UCD_CASESET() -> Never:
    comptime_error("untranslatable C macro: UCD_CASESET")
// untranslatable fn-like macro
fn UCD_CATEGORY() -> Never:
    comptime_error("untranslatable C macro: UCD_CATEGORY")
// untranslatable fn-like macro
fn UCD_CHARTYPE() -> Never:
    comptime_error("untranslatable C macro: UCD_CHARTYPE")
fn UCD_DOTTED_I[T](ch: T) -> T:
    (((ch as c_int) == 0x69) or ((ch as c_int) == 0x0130))
fn UCD_FOLD_I_TURKISH[T](ch: T) -> T:
    (if ((ch as c_int) == 0x0130): 0x69 else: (if ((ch as c_int) == 0x49): 0x0131 else: (ch as c_int)))
// untranslatable fn-like macro
fn UCD_GRAPHBREAK() -> Never:
    comptime_error("untranslatable C macro: UCD_GRAPHBREAK")
// untranslatable fn-like macro
fn UCD_OTHERCASE() -> Never:
    comptime_error("untranslatable C macro: UCD_OTHERCASE")
// untranslatable fn-like macro
fn UCD_SCRIPT() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPT")
// untranslatable fn-like macro
fn UCD_SCRIPTX() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPTX")
let UCD_SCRIPTX_MASK: c_int = 0x3ff
// untranslatable fn-like macro
fn UCD_SCRIPTX_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPTX_PROP")
let UCHAR_MAX: c_int = 255
let UID_MAX: c_uint = 2147483647
fn UINT16_C[T](v: T) -> T:
    v
let UINT16_MAX: c_int = 65535
fn UINT32_C[T](v: T) -> u32:
    (v as u32)
let UINT32_MAX: c_uint = 4294967295
fn UINT64_C[T](v: T) -> u64:
    (v as u64)
let UINT64_MAX: c_ulonglong = 18446744073709551615
fn UINT8_C[T](v: T) -> T:
    v
let UINT8_MAX: c_int = 255
fn UINTMAX_C[T](v: T) -> u64:
    (v as u64)
let UINTMAX_MAX: c_int = UINTMAX_C(18446744073709551615)
let UINTPTR_MAX: c_ulong = 18446744073709551615
let UINT_FAST16_MAX: c_int = 65535
let UINT_FAST32_MAX: c_int = 4294967295
let UINT_FAST64_MAX: c_int = 18446744073709551615
let UINT_FAST8_MAX: c_int = 255
let UINT_LEAST16_MAX: c_int = 65535
let UINT_LEAST32_MAX: c_int = 4294967295
let UINT_LEAST64_MAX: c_int = 18446744073709551615
let UINT_LEAST8_MAX: c_int = 255
let UINT_MAX: c_int = 4294967295
let ULLONG_MAX: c_int = -1
let ULONG_LONG_MAX: c_int = -1
let ULONG_MAX: c_int = -1
let UQUAD_MAX: c_int = -1
let USHRT_MAX: c_int = 65535
let VERSION = "10.48-DEV"
let WAIT_ANY: c_int = -1
let WAIT_MYPGRP: c_int = 0
let WAKEMON_DISABLE: c_int = 0x02
let WAKEMON_ENABLE: c_int = 0x01
let WAKEMON_GET_PARAMS: c_int = 0x04
let WAKEMON_MAKE_FATAL: c_int = 0x10
let WAKEMON_SET_DEFAULTS: c_int = 0x08
// untranslatable fn-like macro
fn WAS_NEWLINE() -> Never:
    comptime_error("untranslatable C macro: WAS_NEWLINE")
let WCONTINUED: c_int = 0x00000010
// untranslatable fn-like macro
fn WCOREDUMP() -> Never:
    comptime_error("untranslatable C macro: WCOREDUMP")
let WCOREFLAG: c_int = 0200
let WEXITED: c_int = 0x00000004
// untranslatable fn-like macro
fn WEXITSTATUS() -> Never:
    comptime_error("untranslatable C macro: WEXITSTATUS")
// untranslatable fn-like macro
fn WIFCONTINUED() -> Never:
    comptime_error("untranslatable C macro: WIFCONTINUED")
// untranslatable fn-like macro
fn WIFEXITED() -> Never:
    comptime_error("untranslatable C macro: WIFEXITED")
// untranslatable fn-like macro
fn WIFSIGNALED() -> Never:
    comptime_error("untranslatable C macro: WIFSIGNALED")
// untranslatable fn-like macro
fn WIFSTOPPED() -> Never:
    comptime_error("untranslatable C macro: WIFSTOPPED")
let WINT_MAX: c_int = 2147483647
let WINT_MIN: c_int = -2147483646
let WNOHANG: c_int = 0x00000001
let WNOWAIT: c_int = 0x00000020
let WORD_BIT: c_int = 32
let WSTOPPED: c_int = 0x00000008
// untranslatable fn-like macro
fn WSTOPSIG() -> Never:
    comptime_error("untranslatable C macro: WSTOPSIG")
// untranslatable fn-like macro
fn WTERMSIG() -> Never:
    comptime_error("untranslatable C macro: WTERMSIG")
let WUNTRACED: c_int = 0x00000002
fn W_EXITCODE[T](ret: T, sig: T) -> T:
    ((ret << 8) | sig)
// untranslatable fn-like macro
fn W_STOPCODE() -> Never:
    comptime_error("untranslatable C macro: W_STOPCODE")
let XCL_BEGIN_WITH_RANGE: c_int = 0x4
let XCL_CHAR_END: c_int = 0x1
let XCL_CHAR_LIST_HIGH_16_ADD: c_int = 0x8000
let XCL_CHAR_LIST_HIGH_16_END: c_int = 0xffff
let XCL_CHAR_LIST_HIGH_16_START: c_int = 0x8000
let XCL_CHAR_LIST_HIGH_32_ADD: c_int = 0x80000000
let XCL_CHAR_LIST_HIGH_32_END: c_int = 0xffffffff
let XCL_CHAR_LIST_HIGH_32_START: c_int = 0x80000000
let XCL_CHAR_LIST_LOW_16_ADD: c_int = 0x0
let XCL_CHAR_LIST_LOW_16_END: c_int = 0x7fff
let XCL_CHAR_LIST_LOW_16_START: c_int = 0x100
let XCL_CHAR_LIST_LOW_32_ADD: c_int = 0x0
let XCL_CHAR_LIST_LOW_32_END: c_int = 0x7fffffff
let XCL_CHAR_LIST_LOW_32_START: c_int = 0x10000
let XCL_CHAR_SHIFT: c_int = 1
let XCL_END: c_int = 0
let XCL_HASPROP: c_int = 0x04
let XCL_ITEM_COUNT_MASK: c_int = 0x3
let XCL_LIST: c_int = (if (sizeof[PCRE2_UCHAR]() == 1): 0x10 else: 0x1000)
let XCL_MAP: c_int = 0x02
let XCL_NOT: c_int = 0x01
let XCL_NOTPROP: c_int = 4
let XCL_PROP: c_int = 3
let XCL_RANGE: c_int = 2
let XCL_SINGLE: c_int = 1
let XCL_TYPE_BIT_LEN: c_int = 3
let XCL_TYPE_MASK: c_int = 0xfff
// untranslatable fn-like macro
fn alloca() -> Never:
    comptime_error("untranslatable C macro: alloca")
fn bcopy() -> Never:
    comptime_error("variadic macro — use direct call")
fn bzero() -> Never:
    comptime_error("variadic macro — use direct call")
let cbit_cntrl: c_int = 288
let cbit_digit: c_int = 64
let cbit_graph: c_int = 192
let cbit_length: c_int = 320
let cbit_lower: c_int = 128
let cbit_print: c_int = 224
let cbit_punct: c_int = 256
let cbit_space: c_int = 0
let cbit_upper: c_int = 96
let cbit_word: c_int = 160
let cbit_xdigit: c_int = 32
let cbits_offset: c_int = 512
// untranslatable fn-like macro
fn clearerr_unlocked() -> Never:
    comptime_error("untranslatable C macro: clearerr_unlocked")
let ctype_digit: c_int = 0x08
let ctype_lcletter: c_int = 0x04
let ctype_letter: c_int = 0x02
let ctype_space: c_int = 0x01
let ctype_word: c_int = 0x10
let ctypes_offset: c_int = 832
let fcc_offset: c_int = 256
// untranslatable fn-like macro
fn feof_unlocked() -> Never:
    comptime_error("untranslatable C macro: feof_unlocked")
// untranslatable fn-like macro
fn ferror_unlocked() -> Never:
    comptime_error("untranslatable C macro: ferror_unlocked")
// untranslatable fn-like macro
fn fileno_unlocked() -> Never:
    comptime_error("untranslatable C macro: fileno_unlocked")
// untranslatable fn-like macro
fn fropen() -> Never:
    comptime_error("untranslatable C macro: fropen")
// untranslatable fn-like macro
fn fwopen() -> Never:
    comptime_error("untranslatable C macro: fwopen")
// untranslatable fn-like macro
fn getc_unlocked() -> Never:
    comptime_error("untranslatable C macro: getc_unlocked")
// untranslatable fn-like macro
fn getchar_unlocked() -> Never:
    comptime_error("untranslatable C macro: getchar_unlocked")
// untranslatable fn-like macro
fn htonl() -> Never:
    comptime_error("untranslatable C macro: htonl")
// untranslatable fn-like macro
fn htonll() -> Never:
    comptime_error("untranslatable C macro: htonll")
// untranslatable fn-like macro
fn htons() -> Never:
    comptime_error("untranslatable C macro: htons")
let lcc_offset: c_int = 0
fn memccpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn memcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn memmove() -> Never:
    comptime_error("variadic macro — use direct call")
fn memset() -> Never:
    comptime_error("variadic macro — use direct call")
// untranslatable fn-like macro
fn ntohl() -> Never:
    comptime_error("untranslatable C macro: ntohl")
// untranslatable fn-like macro
fn ntohll() -> Never:
    comptime_error("untranslatable C macro: ntohll")
// untranslatable fn-like macro
fn ntohs() -> Never:
    comptime_error("untranslatable C macro: ntohs")
// untranslatable fn-like macro
fn offsetof() -> Never:
    comptime_error("untranslatable C macro: offsetof")
// untranslatable fn-like macro
fn putc_unlocked() -> Never:
    comptime_error("untranslatable C macro: putc_unlocked")
// untranslatable fn-like macro
fn putchar_unlocked() -> Never:
    comptime_error("untranslatable C macro: putchar_unlocked")
// untranslatable fn-like macro
fn sigmask() -> Never:
    comptime_error("untranslatable C macro: sigmask")
fn snprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn sprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn stpcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn stpncpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn strcat() -> Never:
    comptime_error("variadic macro — use direct call")
fn strcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn strlcat() -> Never:
    comptime_error("variadic macro — use direct call")
fn strlcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn strncat() -> Never:
    comptime_error("variadic macro — use direct call")
fn strncpy() -> Never:
    comptime_error("variadic macro — use direct call")
let ucd_boolprop_sets_item_size: c_int = 2
let ucd_script_sets_item_size: c_int = 4
fn vsnprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn vsprintf() -> Never:
    comptime_error("variadic macro — use direct call")
