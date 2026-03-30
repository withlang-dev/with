# Add Doc Comments for LSP Hover Support

The LSP hover handler extracts `///` doc comments from above declarations
and displays them in the hover popup.

## Priority 1: Standard Library (lib/std/) — DONE

### builtins.w
- [x] `print` / `eprint` / `write` / `ewrite`
- [x] `assert` / `require` / `check`
- [x] `print_i32` / `print_i64` / `print_bool`

### collections.w
- [x] `Vec[T]`, `HashMap[K, V]`, `HashSet[T]`, `VecIter[T]`

### option.w
- [x] `Option[T]` — Some/None semantics, methods

### result.w
- [x] `Result[T, E]` — Ok/Err semantics, `?` operator
- [x] `ContextError[E]`

### string.w
- [x] `string_len`, `string_eq`, `string_cmp`
- [x] `is_alpha`, `is_digit`, `is_space`
- [x] `string_to_int`, `parse`, `lines`
- [x] `view_len`, `view_is_empty`, `view_eq`

### traits.w
- [x] `Eq`, `Ord`, `Hash`, `Debug`, `Display`, `Default`, `Clone`, `Drop`
- [x] `Scoped`, `ScopedMut`, `Iter`, `IntoIter`

### math.w
- [x] `abs`, `min`, `max`, `clamp`
- [x] `sqrt_f64`, `pow_f64`, `floor_f64`, `ceil_f64`, `round_f64`
- [x] `sin_f64`, `cos_f64`, `tan_f64`, `asin_f64`, `acos_f64`, `atan_f64`, `atan2_f64`
- [x] `log_f64`, `log10_f64`, `exp_f64`, `fabs_f64`, `fmod_f64`
- [x] `PI`, `E`, `TAU`

### io.w
- [x] `print_str`, `print_line`, `print_int`, `print_float`
- [x] `file_open`, `file_close`, `file_read`, `file_write`
- [x] `read_line`, `read_bytes`, `write_raw`, `flush`

### mem.w
- [x] `alloc`, `alloc_zeroed`, `realloc_mem`, `free_mem`
- [x] `mem_copy`, `mem_move`, `mem_set`, `mem_cmp`

### fmt.w
- [x] `fmt_int`, `fmt_float`, `fmt_hex`

### json.w
- [x] `JsonToken`, `JsonParser`
- [x] `json_parse`, `json_find`, `json_str`, `json_int`
- [x] Token type and error constants

### time.w
- [x] `Duration`, `now`, `sleep_secs`, `sleep`, `now_ns`, `clock_ticks`

### iter.w
- [x] `sum`, `map`, `filter`, `count`, `contains`, `iter_sum`

## Priority 2: Less-used stdlib modules — DONE

### fs.w
- [x] `file_exists`, `remove_file`, `rename_file`, `create_dir`, `remove_dir`
- [x] `write_file`, `read_file`

### net.w
- [x] `tcp_listen`, `tcp_accept`, `tcp_connect`, `send`, `recv`, `socket_close`, `udp_bind`

### process.w
- [x] `exit_code`, `system_cmd`, `pid`, `args`, `env`, `set_env`
- [x] `Command`, `command`

### thread.w
- [x] `JoinHandle`, `spawn_os`, `join`

### sync.w
- [x] `Mutex`, `MutexGuard`, `MutexGuardMut`, `RwLock`, `AtomicI64`
- [x] All create/enter/exit/get/set functions

### random.w
- [x] `seed`, `seed_now`, `next_i32`, `range_i32`, `chance`

### signal.w
- [x] `sigint`, `sigterm`, `sigkill`, `raise_signal`

### async.w
- [x] Already had `///` doc comments (await_all, await_first, await_any, await_settled)

## Doc Comment Format

Use `///` (triple-slash) comments directly above the declaration:

```with
/// Adds two numbers and returns their sum.
fn add(a: i32, b: i32) -> i32:
    a + b
```

The LSP hover handler extracts all consecutive `///` lines above a declaration
and displays them as markdown in the popup.
