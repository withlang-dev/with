// The facade for the vendored library, vendor/tally.h: what the header cannot
// say about its own declarations, stated as With (spec §16.2b). tally has no
// resource — nothing it hands out has to be given back — so the facade has no
// `resource` item; what it has is one contract per declaration, each quoted
// from the header, and the honest record of which ones today's clause
// vocabulary can state.
use c_import("tally.h")

c facade tally:
    // "TallyRange tally_widen(TallyRange range, int by)": both parameters
    // cross by value, so C borrows nothing past the call and the call is a
    // lend. (A struct by value was already safe under the raw rules; the
    // clause records that the contract was read.)
    fn tally_widen
        lend
    // Not statable yet — each of these is the raw call src/tally.w keeps:
    //
    //   "TallyRange tally_range(const int *values, int count)" and
    //   "int tally_total(const int *values, int count)" take a caller-owned
    //   buffer and the number of ints in it. D64 pairs a buffer with its
    //   length only as bytes (`buffer param P len param L` renders `[]u8`),
    //   and says the `T * + count` form waits until it is decided what the
    //   integer counts; an element-count pairing rendering `[]i32` is the
    //   clause tally needs. Until it lands the compiler refuses a `lend`
    //   here (#1621: "a safe call over a raw pointer with no bounds is the
    //   partial model §16.2b.3 forbids — leave the call raw").
    //
    //   "void tally_each(const int *values, int count,
    //                   void (*visit)(void *context, int value), void *context)"
    //   calls `visit` once per value during the call, handing `context` back
    //   each time: a callback with userdata that C uses during the call only
    //   (§16.2b.9, `callback param 2 userdata param 3`) — but a callback
    //   contract is presented as a method of the resource its first parameter
    //   receives, and tally_each receives a buffer, not a resource. A callback
    //   contract on a free function is the second clause tally needs.
