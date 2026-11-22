//! expect-check-fail: view `keep` may originate from `s`, which no longer lives here

// D69 (§13.4, §21.1): a yielded view is valid for the run of the consumer's
// body and is not retained past it; keeping an element is spelled `.clone()`.
gen fn labels(count: i32) -> &str:
    var buf = ""
    for i in 0..count:
        buf = f"item-{i}"
        yield &buf

fn main:
    let first = "x"
    var keep = &first
    for s in labels(3):
        keep = s
    print(keep)
