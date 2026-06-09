use c_import("void free(void *);\n#define TEST_FREE(ptr) free(ptr)\n")

fn main:
    TEST_FREE(null as *mut c_void)
