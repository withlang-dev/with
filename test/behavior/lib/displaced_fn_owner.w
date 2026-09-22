// #1350 fixture module: every top-level name here is also declared by the
// root program (behav_1350_module_fn_same_name.w); this module's own
// references must keep binding its own declarations.
pub fn is_digit(c: i32) -> bool: c >= 48 and c <= 57
pub fn pick[T](a: T, b: T) -> T: b
fn twice(c: i32) -> i32: c * 2
fn label() -> str: "owner"
pub fn via_value(c: i32) -> bool:
    let f = is_digit
    f(c)
pub fn via_pipe(c: i32) -> bool: c |> is_digit
pub fn local_named(c: i32) -> i32:
    let twice = c + 100
    twice
pub fn generic_own(c: i32) -> i32: pick(c, twice(c))
pub fn owner_label() -> str: label()
pub fn count_digits(xs: &Vec[i32]) -> i32:
    var n = 0
    for x in xs:
        if is_digit(x): n = n + 1
    n
