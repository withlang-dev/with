//! expect-stdout: 2 3 1
// #3062 (D103, §9.5): under an `Option[E]` demand a bare variant shorthand
// is E's variant and the demand wraps it, in an assignment and in both
// branches of an `if`. The demand names E: a second enum in scope that
// shares the variant names (`Other.Callback`) does not split the arms, and
// E may come from another module. `Some(.Str)` was required where `.Str`
// should do.
use option_shorthand_kinds

enum Other:
    Callback
    Retained

fn classify(c: i32, r: i32) -> i32:
    var kind: Option[OptionShorthandKind] = None
    if c != 0 or r != 0:
        kind = if c != 0: .Callback else: .Retained
    else if r == 0 and c == 0:
        kind = .Str
    let Some(k) = kind else: return 0
    match k:
        .Callback => 1
        .Retained => 2
        .Str => 3
        .Scalar => 4

fn main:
    print(f"{classify(0, 5)} {classify(0, 0)} {classify(4, 0)}")
