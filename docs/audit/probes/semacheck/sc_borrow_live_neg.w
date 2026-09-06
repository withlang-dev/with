// T6 negative control: the view is used AFTER the mutation, so the borrow
// is live at the mutation site (check_mutation_against_views). Expect
// check FAIL with a live-view diagnostic.
fn main:
    var p = 1
    let v = &p
    p = 2
    assert(*v == 1)
