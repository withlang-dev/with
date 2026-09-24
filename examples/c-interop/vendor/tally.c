#include "tally.h"

int tally_calls = 0;

TallyRange tally_range(const int *values, int count) {
    TallyRange range = { 0, 0 };
    tally_calls++;
    for (int i = 0; i < count; i++) {
        if (i == 0 || values[i] < range.low) range.low = values[i];
        if (i == 0 || values[i] > range.high) range.high = values[i];
    }
    return range;
}

TallyRange tally_widen(TallyRange range, int by) {
    tally_calls++;
    range.low -= by;
    range.high += by;
    return range;
}

void tally_each(const int *values, int count, void (*visit)(void *context, int value), void *context) {
    tally_calls++;
    for (int i = 0; i < count; i++) visit(context, values[i]);
}

int tally_total(const int *values, int count) {
    int total = 0;
    tally_calls++;
    for (int i = 0; i < count; i++) total += c_interop_score(values[i]);
    return total;
}
