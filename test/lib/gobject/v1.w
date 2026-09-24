// A convention profile (D51 stage 11, ruling §7, §59; spec §16.2b.12), the
// test suite's GObject-shaped one: the package `gobject.v1` that a facade
// adopts with `use convention gobject.v1`. Adoption is the explicit act
// that makes these rules trusted evidence, so a rule may state from a name
// what core With never infers (`*_unref` destroys). Every match is
// unique-or-nothing, and an explicit clause on the adopting facade shadows
// the rule's fact.
//
// Resolved through ordinary package rules: from any fixture under test/,
// the module walk finds test/lib/gobject/v1.w.

c convention gobject.v1:
    new: from *_new
    open: from *_open(out param 1)
    unref: drop *_unref
    free: destroys *_free
    get: fn *_get* lend
    dispose: fn *_dispose destroys
