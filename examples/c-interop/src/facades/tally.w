// The facade for the vendored library, vendor/tally.h: what the header cannot
// say about its own declarations, stated as With (spec §16.2b). tally has no
// resource — nothing it hands out has to be given back — so the facade has no
// `resource` item; what it has is one contract per declaration, each quoted
// from the header. D64's explicit `elements` counts ints, not bytes.
use c_import("tally.h")

c facade tally:
    // "TallyRange tally_widen(TallyRange range, int by)": both parameters
    // cross by value, so C borrows nothing past the call and the call is a
    // lend. (A struct by value was already safe under the raw rules; the
    // clause records that the contract was read.)
    fn tally_widen
        lend
    // "TallyRange tally_range(const int *values, int count)" and
    // "int tally_total(const int *values, int count)": a caller-owned
    // buffer with the number of ints in it, presented as one []i32.
    fn tally_range
        buffer param values len param count elements
    fn tally_total
        buffer param values len param count elements
    // "Calls `visit` once per value, handing `context` back each time."
    // The callback and typed userdata are borrowed for this call only.
    fn tally_each
        buffer param values len param count elements
        callback param visit userdata param context
