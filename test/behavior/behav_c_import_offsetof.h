#ifndef BEHAV_C_IMPORT_OFFSETOF_H
#define BEHAV_C_IMPORT_OFFSETOF_H

#include <stddef.h>
#include <stdint.h>

typedef struct {
    int32_t x;
    int32_t y;
} with_offset_point_t;

typedef struct {
    with_offset_point_t origin;
    with_offset_point_t size;
} with_offset_rect_t;

typedef struct __attribute__((packed)) {
    uint8_t a;
    uint32_t b;
    uint8_t c;
} with_offset_packed_t;

typedef struct {
    uint32_t count;
    char data[1];
} with_offset_old_flex_t;

#define WITH_OFFSETOF_POINT_X offsetof(with_offset_point_t, x)
#define WITH_OFFSETOF_POINT_Y offsetof(with_offset_point_t, y)
#define WITH_OFFSETOF_RECT_SIZE offsetof(with_offset_rect_t, size)
#define WITH_OFFSETOF_PACKED_B offsetof(with_offset_packed_t, b)
#define WITH_OFFSETOF_OLD_FLEX_DATA offsetof(with_offset_old_flex_t, data)

#endif
