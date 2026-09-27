# 15.2 Conversions

| From | To | How |
|------|----|-----|
| `str` | `&str` | auto-borrow or `.as_view()` |
| `&str` | `str` | `.to_owned()` (allocates) |
| `"literal"` | `str` | direct (default) |
| `"literal"` | `&str` | when type context is `&str`, zero-cost static ref |
| `str` | `CString` | `.to_cstring()` (appends NUL) |
| `CString` | `CStr` | `.as_cstr()` |
