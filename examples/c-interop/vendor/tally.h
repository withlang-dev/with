/* tally: a small C library, vendored so this example can show the things a
 * system library cannot: C that calls back into With, structs that cross the
 * boundary by value, and a C source file for `with migrate`. */
#ifndef TALLY_H
#define TALLY_H

#define TALLY_VERSION "1.2"
#define TALLY_MAX 64

typedef enum TallyOrder { TALLY_ASCENDING, TALLY_DESCENDING = 5 } TallyOrder;

/* Crosses the boundary by value, in both directions. */
typedef struct TallyRange { int low; int high; } TallyRange;

/* How many times the library has been called. */
extern int tally_calls;

TallyRange tally_range(const int *values, int count);
TallyRange tally_widen(TallyRange range, int by);

/* Calls `visit` once per value, handing `context` back each time. */
void tally_each(const int *values, int count, void (*visit)(void *context, int value), void *context);

/* Sums score(value) over the values: `score` is written in With. */
int tally_total(const int *values, int count);
int c_interop_score(int value);

#endif
