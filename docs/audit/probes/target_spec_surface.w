@[panic_handler]
fn on_panic -> Never:
    loop {}

@[target("x86_64")]
@[c_export]
@[no_main]
fn selected_arch() -> i32: 86

@[target("aarch64")]
@[c_export]
@[no_main]
fn selected_arch() -> i32: 64
