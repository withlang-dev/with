//! expect-stdout: ok

use c_import("#define FILLED 0
typedef int element;
static inline int total(const element *values, unsigned char count) { int sum = 0; for (int i = 0; i < count; ++i) sum += values[i]; return sum; }
static inline int reversed(unsigned char count, const element *values) { return total(values, count); }
static inline int fill(element *dest, int *count) { if (*count < 2) return 1; dest[0] = 11; dest[1] = 13; *count = 2; return FILLED; }
static inline void each(const element *values, int count, void (*visit)(void *, int), void *ctx) { for (int i = 0; i < count; ++i) visit(ctx, values[i]); }
static inline void fill_each(element *dest, int *count, void (*visit)(void *, int), void *ctx) { if (*count > 0) { dest[0] = 17; visit(ctx, dest[0]); *count = 1; } }
typedef struct Pair { int x; int y; } Pair;
static inline int pairs(const Pair *values, int count) { int sum = 0; for (int i = 0; i < count; ++i) sum += values[i].x + values[i].y; return sum; }
")

c facade arrays:
    fn total
        buffer param values len param count elements
    fn reversed
        buffer param values len param count elements
    fn fill
        buffer param dest capacity param count inout elements
        ok FILLED
    fn each
        buffer param values len param count elements
        callback param 2 userdata param 3
    fn fill_each
        buffer param dest capacity param count inout elements
        callback param 2 userdata param 3
    fn pairs
        buffer param values len param count elements

fn collect(sink: &fn(i32) -> Unit, value: i32): sink(value)

fn main:
    let values: [i32; 3] = [3, 5, 7]
    assert(total(values) == 15)
    assert(reversed(values) == 15)
    let empty: [i32; 0] = []
    assert(total(empty) == 0)
    var output: [i32; 4] = [0; 4]
    assert(fill(output).unwrap() == 2)
    assert(output.len() == 4 and output[0] == 11 and output[1] == 13)
    var seen: Vec[i32] = Vec.new()
    each(values, collect, value => seen.push(value))
    assert(seen.len() == 3 and seen[0] == 3 and seen[2] == 7)
    assert(fill_each(output, collect, value => seen.push(value)) == 1)
    assert(output.len() == 4 and output[0] == 17 and seen[3] == 17)
    let points = [Pair { x: 2, y: 3 }, Pair { x: 5, y: 7 }]
    assert(pairs(points) == 17)
    print("ok")
