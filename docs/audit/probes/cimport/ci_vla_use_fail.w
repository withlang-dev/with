use c_import("void vla_fn(int n, int arr[n]);")
fn main:
    vla_fn(3, null)
