#ifndef WITH_CXX_FLAT_FIXTURE_H
#define WITH_CXX_FLAT_FIXTURE_H
typedef unsigned long long FlatId;
const int flat_callback_base = 1100;
class FlatInterface { public: virtual bool ready() = 0; };
template<typename T> class FlatTemplate { T value; };
inline int flat_cpp_only(int x) { return x + 99; }
extern int flat_cpp_variable;
extern const int flat_cpp_external_constant;
struct FlatVirtual { virtual void method(); int value; };
struct FlatBase { int value; };
struct FlatDerived : FlatBase { int extra; };
struct FlatContainsVirtual { FlatVirtual value; };
#pragma pack(push, 4)
struct FlatCallback {
    enum { k_iCallback = flat_callback_base + 2 };
    unsigned char tag;
    FlatId game;
    int result;
};
#pragma pack(pop)
struct FlatEmpty { enum { k_iCallback = flat_callback_base + 3 }; };
struct FlatOuter { struct Nested; struct Nested { int value; }; Nested value; };
struct FlatOther { struct Nested { short value; }; Nested value; };
struct FlatCollision_Item { long long value; };
struct FlatCollision { struct Item { int value; }; Item item; };
struct FlatConstructor { FlatConstructor(); int value; };
#pragma pack(push, 1)
struct FlatPackedUnion { union { unsigned int ipv4; unsigned char ipv6[16]; }; int kind; };
#pragma pack(pop)
enum { FLAT_GAME_OFFSET = __builtin_offsetof(FlatCallback, game), FLAT_RESULT_OFFSET = __builtin_offsetof(FlatCallback, result) };
#define FLAT_CALLBACK_ID (FlatCallback::k_iCallback)
#define FLAT_TYPED_ID ((FlatId)42)
#define FLAT_API extern "C"
FLAT_API bool flat_ready(FlatInterface *self, bool enabled);
FLAT_API FlatId flat_score(const char *name, FlatId score);
#endif
