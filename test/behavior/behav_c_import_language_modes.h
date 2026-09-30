#ifndef WITH_C_IMPORT_LANGUAGE_MODES_H
#define WITH_C_IMPORT_LANGUAGE_MODES_H
#ifdef __cplusplus
const int FLAT_CXX_MODE = 2;
extern "C" {
#else
enum { FLAT_C_MODE = 1 };
#endif
struct FlatPlain { int value; };
#ifdef __cplusplus
}
#endif
#endif
