//! expect-stdout: 5050
//! expect-stdout: 3 [2, 3]
//! expect-stdout: 2 [8, 9]

// D115 Amendment 1 (§9.7): an owned List's remainder shares the subject's
// buffer: taking the head advances the header (`ptr`, `start`), so the
// canonical recursion `[h, ..t] => h + sum(t)` is O(n), not O(n²), and
// allocates nothing per step (a hundred elements: four allocations in all
// under `--debug-alloc`, where each step allocated before). A small
// remainder keeps the original buffer alive; `shrink_to_fit()` releases
// the prefix and the spare capacity.
fn sum(xs: List[i32]) -> i32:
    match move xs:
        [h, ..t] => h + sum(t)
        [] => 0

fn head_rest(xs: List[i32]) -> str:
    match move xs:
        [a, ..r] => f"{a + 2} {r:?}"
        [] => "empty"

fn drop_head(xs: List[i32]) -> str:
    match move xs:
        [_, ..r] =>
            var kept = r
            kept.shrink_to_fit()
            f"{kept.len()} {kept:?}"
        [] => "empty"

fn main:
    var xs: List[i32] = List.new()
    for i in 1..101: xs.push(i)
    print(sum(xs))
    print(head_rest([1, 2, 3]))
    print(drop_head([7, 8, 9]))
