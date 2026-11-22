//! expect-stdout: ok

use c_import("typedef struct Color288 { unsigned char r; unsigned char g; unsigned char b; unsigned char a; } Color288;\n    #define CLITERAL(type) (type)\n    #define ADD_ONE288(x) ((x) + 1)\n    #define PI288 3.14159265358979323846f\n    #define DEG2RAD288 (PI288/180.0f)\n    #define RAD2DEG288 (180.0f/PI288)\n#define COLOR_TYPE288 Color288\n#define LIGHTGRAY288 CLITERAL(Color288){ 200, 200, 200, 255 } // Light Gray\n#define GRAY288 CLITERAL(Color288){ 130, 130, 130, 255 } // Gray\n#define RAYWHITE288 CLITERAL(Color288){ 245, 245, 245, 255 } // Ray White\n")

fn main:
    assert(LIGHTGRAY288.r == 200)
    assert(LIGHTGRAY288.g == 200)
    assert(LIGHTGRAY288.b == 200)
    assert(LIGHTGRAY288.a == 255)
    assert(GRAY288.r == 130)
    assert(GRAY288.g == 130)
    assert(GRAY288.b == 130)
    assert(GRAY288.a == 255)
    assert(RAYWHITE288.r == 245)
    assert(RAYWHITE288.g == 245)
    assert(RAYWHITE288.b == 245)
    assert(RAYWHITE288.a == 255)
    assert(ADD_ONE288(4) == 5)
    assert(DEG2RAD288 > 0.017)
    assert(DEG2RAD288 < 0.018)
    assert(RAD2DEG288 > 57.0)
    assert(RAD2DEG288 < 58.0)
    print("ok")
