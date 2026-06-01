// Regression for #319: void-returning generic functions monomorphize as void.

fn sink[T](x: T):
    let _ = x

fn two_steps[T](x: T):
    sink(x)
    sink("done")

fn test_generic_void_function:
    sink(5)
    sink("hello")
    two_steps(9)
