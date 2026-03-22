#ifndef AUTO_METHODS_TEST_INLINE_H
#define AUTO_METHODS_TEST_INLINE_H

#include <stdlib.h>

typedef struct AmtVec {
    float x, y, z;
} AmtVec;

AmtVec* amt_vec_new(float x, float y, float z);
float amt_vec_get_x(const AmtVec* v);
float amt_vec_get_y(const AmtVec* v);
float amt_vec_length_sq(const AmtVec* v);
void amt_vec_scale(AmtVec* v, float s);
void amt_vec_free(AmtVec* v);

#endif
