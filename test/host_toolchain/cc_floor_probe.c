/* #3603: the shape of a build system's function probe (CMake's
   check_function_exists). memset_explicit exists only in glibc 2.43 and
   later; `with cc` builds at the 2.28 floor, so this must not link. */
char memset_explicit(void);
int main(void) { return memset_explicit(); }
