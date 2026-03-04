// Multiple imports from a single root module.
use support.alpha
use support.beta
use diamond.shared

fn main -> i32:
    alpha(1) + beta(2) + shared_base()
