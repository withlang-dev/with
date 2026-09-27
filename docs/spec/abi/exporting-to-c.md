# 16.5 Exporting to C

```
@[c_export("my_lib_init")]
fn init(config: *const Config) -> i32: ...
```

The toolchain generates C header files for all `@[c_export]` symbols.
This enables With libraries to be consumed by C, C++, or any
language with a C FFI.
