# 16.4 Layout Control

```
@[repr(C)]
type Point { x: f64, y: f64 }
```

Types imported via `c_import` automatically have `repr(C)` layout.
Manually defined types intended for C interop must be explicitly
annotated.

**Packed layout:**

```
@[repr(packed)]
type PackedHeader {
    magic: u8,
    version: u16,
    size: u32,
}
```

`repr(packed)` implies `repr(C)` and sets alignment to 1 for all
fields (no padding). The compiler emits unaligned loads/stores.
Creating a reference to a packed field is a compile error (the
reference would be unaligned).

`@[repr(packed(N))]`, with `N` a power of two, caps every field's alignment
at `N`: a field whose natural alignment exceeds `N` is placed at alignment
`N`, and the record's alignment is at most `N`. It is the layout of C's
`#pragma pack(N)`, and `c_import` emits it for a record whose clang layout
it reproduces exactly (e.g. `BITMAPFILEHEADER` under `pack(2)`); a record it
does not reproduce stays opaque. (`__attribute__((packed, aligned(N)))` is a
different layout: it packs every field to 1 and aligns only the record.) A
reference to a field whose natural alignment exceeds `N` is a compile error,
as for `repr(packed)`.

**Union types:**

```
@[repr(C)]
type Value = union {
    i: i32,
    f: f32,
    p: *mut c_void,
}

let v = Value { i: 42 }
let as_float = unsafe { v.f }    // reinterpret bits as f32
```

Unions have the size of their largest field. All fields share offset 0.
Reading a field that wasn't last written requires `unsafe`. Writing any
field is safe. Construction requires exactly one field initializer.
`c_import` translates C union declarations directly.

**Custom alignment:**

Variables, struct fields, and function parameters can specify custom
alignment using the `align` attribute:

```
type CacheLine = {
    @[align(64)]
    data: [64]u8,
}

@[align(16)]
var buffer: [256]u8 = [0; 256]

fn process(@[align(16)] data: *[4]f32):
    // data is guaranteed 16-byte aligned
```

Rules:

1. Alignment must be a power of two.
2. Alignment must be at least the natural alignment of the type.
3. Alignment cannot exceed a platform-defined maximum (65536).
4. Violations are compile-time errors.

When a local variable has custom alignment, the compiler emits an
aligned stack allocation. When a struct has an aligned field, the
struct's own alignment becomes the maximum of all field alignments.

**Bitpacked layout** is described in §4.3b.
