// Spec test: Section 15.3 — C-String Literals (formerly 25.84)

// PASS: c"..." produces &CStr
fn test_c_string_literal_type_and_storage:
    let s: &CStr = c"hello"
    assert(s.len() == 5)
    assert(unsafe s.ptr[0] == 104)
    assert(unsafe s.ptr[4] == 111)
    assert(unsafe s.ptr[5] == 0)
