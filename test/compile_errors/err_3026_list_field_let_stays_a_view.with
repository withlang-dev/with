//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// #1530 / D144: the field-view rule stays for a field whose value is not a
// str — `let p = x.items` observes the List (a lost `push` is the worst
// outcome, so a List keeps observing), and assigning the viewed field while
// the view is live is refused. A str field takes the value instead (#3026,
// behav_3026_assign_str_field_under_saved_value).
type S { items: List[i32], n: i32 }
fn main:
    var x = S { items: [1, 2], n: 1 }
    let p = x.items
    x.n = 2
    x.items = [3]
    print(p.len())
