# Add Doc Comments for LSP Hover Support

The LSP hover handler now extracts `///` doc comments from above declarations
and displays them in the hover popup. This document lists everything that
needs doc comments to make the LSP useful.

## Priority 1: Standard Library (lib/std/)

These are the functions and types users interact with most. Every public
function and type should have a `///` doc comment.

### builtins.w
- [ ] `print` / `println` — what they accept, newline behavior
- [ ] `assert` — behavior on failure (panic)
- [ ] `int_to_string` — conversion semantics
- [ ] `str_from_byte` — byte to single-char string

### collections.w
- [ ] `Vec[T]` — what it is, how to create (`Vec.new()`)
- [ ] `Vec.push`, `Vec.pop`, `Vec.get`, `Vec.len`, `Vec.is_empty`, `Vec.contains`, `Vec.clear`
- [ ] `HashMap[K, V]` — creation, lookup, collision behavior
- [ ] `HashMap.get`, `HashMap.insert`, `HashMap.contains`, `HashMap.remove`, `HashMap.len`
- [ ] `HashSet[T]`
- [ ] `VecIter[T]`

### option.w
- [ ] `Option[T]` — Some/None semantics
- [ ] `Option.unwrap`, `Option.unwrap_or`, `Option.is_some`, `Option.is_none`
- [ ] `Option.map`, `Option.and_then`

### result.w
- [ ] `Result[T, E]` — Ok/Err semantics, `?` operator
- [ ] `Result.unwrap`, `Result.unwrap_or`, `Result.is_ok`, `Result.is_err`
- [ ] `Result.map`, `Result.map_err`

### string.w
- [ ] Built-in methods: `len`, `slice`, `contains`, `starts_with`, `ends_with`,
      `find`, `replace`, `to_upper`, `to_lower`, `trim`, `split`, `byte_at`, `repeat`
- [ ] `string_eq`, `string_cmp`, `string_len`
- [ ] `is_alpha`, `is_digit`, `is_space`
- [ ] `string_to_int`, `parse`, `lines`

### traits.w
- [ ] `Eq` — equality trait, `eq` method
- [ ] `Ord` — ordering, `cmp` method
- [ ] `Hash` — hashing
- [ ] `Debug` — debug formatting
- [ ] `Display` — display formatting
- [ ] `Default` — default values
- [ ] `Clone` — cloning
- [ ] `Drop` — destructor
- [ ] `Iter`, `IntoIter` — iteration protocol

### math.w
- [ ] `abs`, `min`, `max`, `clamp`
- [ ] `sqrt`, `pow`, `log`, `exp`
- [ ] Trig: `sin`, `cos`, `tan`, `asin`, `acos`, `atan2`
- [ ] Constants: `PI`, `E`, `TAU`

### io.w
- [ ] `print_str`, `print_line`, `print_int`, `print_float`
- [ ] `file_open`, `file_close`, `file_read`, `file_write`
- [ ] `read_line`, `read_bytes`, `write_raw`, `flush`

### mem.w
- [ ] `alloc`, `alloc_zeroed`, `realloc_mem`, `free_mem`
- [ ] `mem_copy`, `mem_move`, `mem_set`, `mem_cmp`

### fmt.w
- [ ] `fmt_int`, `fmt_float`, `fmt_hex`

### json.w
- [ ] `JsonToken`, `JsonParser` — types
- [ ] `json_parse` — how to use, return value, error codes
- [ ] `json_find` — key lookup semantics
- [ ] `json_str`, `json_int` — extraction helpers
- [ ] Token type constants: `JSON_OBJECT`, `JSON_ARRAY`, `JSON_STRING`, `JSON_PRIMITIVE`
- [ ] Error constants: `JSON_ERROR_NOMEM`, `JSON_ERROR_INVAL`, `JSON_ERROR_PART`

### time.w
- [ ] `Duration` type, `sleep`, `now`, `clock`

### iter.w
- [ ] `sum`, `map`, `filter`, `count`, `contains`

## Priority 2: Less-used stdlib modules

### fs.w, net.w, process.w, thread.w, sync.w, async.w
- [ ] All public functions

### random.w, signal.w, sysinfo.w
- [ ] All public functions

### crypto/*
- [ ] Public API functions only (sha256, hmac, etc.)

## Priority 3: Examples

### examples/
- [ ] Each example file should have a top-level `///` comment explaining what it demonstrates

## Doc Comment Format

Use `///` (triple-slash) comments directly above the declaration:

```with
/// Adds two numbers and returns their sum.
///
/// Returns the arithmetic sum of `a` and `b`.
fn add(a: i32, b: i32) -> i32:
    a + b

/// A point in 2D space.
type Point {
    x: i32,
    y: i32,
}

/// The equality trait. Types implementing this can be compared with `==`.
trait Eq =
    /// Returns true if self equals other.
    fn eq(self, other: Self) -> bool
```

The LSP hover handler extracts all consecutive `///` lines above a declaration
and displays them as markdown in the popup.
