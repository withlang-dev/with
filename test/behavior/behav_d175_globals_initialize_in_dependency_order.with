//! expect-stdout: 10 51 -9223372036854775808 5 1 w5
//! expect-stdout: 301 300 8
// D175 (§9.1c): runtime globals initialize in dependency order, each after
// every global it may read, through every function it calls: directly
// (`doubled`), through a call (`through_fn`), through a callable parameter
// (`via_param`) and a callable value (`via_value`), whose candidates are
// every function of that type. In declaration order these read globals
// whose initializers had not run (`1 0` for `301 300`). A global's
// initializer may call a function with an inferred return type (D43).
let doubled = later * 2
let through_fn = read_later() + 1
let quad_min = llong_min
let via_param = apply(scaled)
let getter = scaled
let via_value = getter()
let seven_plus = seven() + 1
let later: i64 = table.len()
let table = [1, 2, 3, 4, 5]
let llong_min: i64 = -9223372036854775807 - 1
let words = names()
let name_count = words.len()
let base: i64 = compute()

fn read_later(): later * 10

fn seven(): 7

fn compute() -> i64: 3

fn scaled() -> i64: base * 100

fn apply(g: fn() -> i64) -> i64: g() + 1

fn names() -> List[str]:
    var xs: List[str] = List.new()
    xs.push(f"w{later}")
    xs

fn main:
    print(f"{doubled} {through_fn} {quad_min} {later} {name_count} {words[0]}")
    print(f"{via_param} {via_value} {seven_plus}")
