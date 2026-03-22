#ifndef AUTO_METHODS_TEST_H
#define AUTO_METHODS_TEST_H

#include <stdlib.h>
#include <math.h>

typedef struct MyVec {
    float x, y, z;
} MyVec;

MyVec* my_vec_new(float x, float y, float z);
float my_vec_length(const MyVec* v);
void my_vec_scale(MyVec* v, float s);
float my_vec_dot(const MyVec* a, const MyVec* b);
void my_vec_free(MyVec* v);

#ifdef AUTO_METHODS_TEST_IMPL
MyVec* my_vec_new(float x, float y, float z) {
    MyVec* v = (MyVec*)malloc(sizeof(MyVec));
    v->x = x; v->y = y; v->z = z;
    return v;
}
float my_vec_length(const MyVec* v) {
    return sqrtf(v->x * v->x + v->y * v->y + v->z * v->z);
}
void my_vec_scale(MyVec* v, float s) {
    v->x *= s; v->y *= s; v->z *= s;
}
float my_vec_dot(const MyVec* a, const MyVec* b) {
    return a->x * b->x + a->y * b->y + a->z * b->z;
}
void my_vec_free(MyVec* v) {
    free(v);
}
#endif

#endif
