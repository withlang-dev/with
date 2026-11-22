// Spec test: Section 4.10 — Implicit Default Return.

fn default_return_side_effect:
    let _x = 1

fn default_i32 -> i32:
    default_return_side_effect()

fn default_bool -> bool:
    default_return_side_effect()

fn default_f64 -> f64:
    default_return_side_effect()

fn default_option -> Option[i32]:
    default_return_side_effect()

@[derive(Default)]
type DefaultReturnConfig { port: i32, debug: bool }

fn default_config -> DefaultReturnConfig:
    default_return_side_effect()

fn default_result -> Result[i32, str]:
    default_return_side_effect()

fn explicit_return_value -> i32:
    default_return_side_effect()
    42

fn explicit_return_in_nonfallthrough_loop -> i32:
    while true:
        return 7

fn test_implicit_default_return_for_builtin_and_option:
    assert(default_i32() == 0)
    assert(default_bool() == false)
    assert(default_f64() == 0.0)
    assert(default_option().is_none())

fn test_implicit_default_return_for_derived_default:
    let cfg = default_config()
    assert(cfg.port == 0)
    assert(cfg.debug == false)

fn test_implicit_default_return_composes_with_result:
    match default_result():
        Ok(value) => assert(value == 0)
        Err(_) => assert(false)

fn test_explicit_return_is_not_overridden:
    assert(explicit_return_value() == 42)

fn test_explicit_return_in_nonfallthrough_loop:
    assert(explicit_return_in_nonfallthrough_loop() == 7)
