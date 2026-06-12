type c_void = opaque
type pcre2_real_code_8 = opaque
type pcre2_real_match_data_8 = opaque
type pcre2_real_compile_context_8 = opaque
type pcre2_real_match_context_8 = opaque
type pcre2_real_general_context_8 = opaque

extern fn pcre2_compile_8(pattern: *const u8, patlen: u64, options: u32, errorptr: *mut i32, erroroffset: *mut u64, ccontext: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_code_8
extern fn pcre2_match_8(code: *const pcre2_real_code_8, subject: *const u8, length: u64, start_offset: u64, options: u32, match_data: *mut pcre2_real_match_data_8, mcontext: *mut pcre2_real_match_context_8) -> i32
extern fn pcre2_match_data_create_from_pattern_8(code: *const pcre2_real_code_8, gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8
extern fn pcre2_get_ovector_pointer_8(match_data: *mut pcre2_real_match_data_8) -> *mut u64
extern fn pcre2_code_free_8(code: *mut pcre2_real_code_8) -> Unit
extern fn pcre2_match_data_free_8(match_data: *mut pcre2_real_match_data_8) -> Unit

fn main():
    let pattern = "hello, (\\w+)!"
    let subject = "hello, world!"
    var errcode: i32 = 0
    var erroffset: u64 = 0
    let code = unsafe { pcre2_compile_8(pattern as *const u8, pattern.len() as u64, 0, &mut errcode, &mut erroffset, null) }
    if code == null:
        print(f"FAIL: compile returned null, error {errcode}")
        return
    let md = unsafe { pcre2_match_data_create_from_pattern_8(code, null) }
    if md == null:
        print("FAIL: match_data_create returned null")
        unsafe { pcre2_code_free_8(code) }
        return
    let rc = unsafe { pcre2_match_8(code, subject as *const u8, subject.len() as u64, 0, 0, md, null) }
    if rc < 0:
        print(f"FAIL: match returned {rc}")
        unsafe { pcre2_match_data_free_8(md) }
        unsafe { pcre2_code_free_8(code) }
        return
    let ovec = unsafe { pcre2_get_ovector_pointer_8(md) }
    let g1s = (unsafe *((ovec as i64 + 16) as *const u64))
    let g1e = (unsafe *((ovec as i64 + 24) as *const u64))
    if g1s != 7 or g1e != 12:
        print(f"FAIL: group 1 is [{g1s},{g1e}), expected [7,12)")
        unsafe { pcre2_match_data_free_8(md) }
        unsafe { pcre2_code_free_8(code) }
        return
    print("ok")
    unsafe { pcre2_match_data_free_8(md) }
    unsafe { pcre2_code_free_8(code) }
