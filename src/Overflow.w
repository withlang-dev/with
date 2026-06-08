use Ast

type IntArithmeticResult {
    ok: i32,
    overflow: i32,
    value: i64,
}
impl Copy for IntArithmeticResult

fn OVERFLOW_MODE_PANIC -> i32: 0
fn OVERFLOW_MODE_WRAP -> i32: 1
fn OVERFLOW_MODE_SATURATE -> i32: 2

fn overflow_mode_default -> i32:
    OVERFLOW_MODE_PANIC()

fn overflow_mode_valid(mode: i32) -> bool:
    mode == OVERFLOW_MODE_PANIC() or mode == OVERFLOW_MODE_WRAP() or mode == OVERFLOW_MODE_SATURATE()

fn overflow_mode_name(mode: i32) -> str:
    if mode == OVERFLOW_MODE_WRAP():
        return "wrap"
    if mode == OVERFLOW_MODE_SATURATE():
        return "saturate"
    "panic"

fn overflow_mode_parse(value: str) -> i32:
    if value == "panic":
        return OVERFLOW_MODE_PANIC()
    if value == "wrap":
        return OVERFLOW_MODE_WRAP()
    if value == "saturate":
        return OVERFLOW_MODE_SATURATE()
    -1

fn int_arith_ok(value: i64) -> IntArithmeticResult:
    IntArithmeticResult { ok: 1, overflow: 0, value }

fn int_arith_overflow(value: i64) -> IntArithmeticResult:
    IntArithmeticResult { ok: 1, overflow: 1, value }

fn int_arith_invalid -> IntArithmeticResult:
    IntArithmeticResult { ok: 0, overflow: 1, value: 0 }

fn int_width_clamp(width: i32) -> i32:
    if width <= 0:
        return 64
    if width > 64:
        return 64
    width

fn int_truncate_to_width(value: i64, width_raw: i32, is_unsigned: bool) -> i64:
    let width = int_width_clamp(width_raw)
    if width >= 64:
        return value
    let mask = exact_int_low_mask(width)
    let raw = value & mask
    if is_unsigned:
        return raw
    let sign = exact_int_pow2_word(width - 1)
    if (raw & sign) != 0:
        return raw | (~mask)
    raw

fn int_signed_min(width_raw: i32) -> i64:
    let width = int_width_clamp(width_raw)
    if width >= 64:
        return exact_int_sign_bit()
    0 - ((1 as i64) << ((width - 1) as u32))

fn int_signed_max(width_raw: i32) -> i64:
    let width = int_width_clamp(width_raw)
    if width >= 64:
        return 9223372036854775807
    ((1 as i64) << ((width - 1) as u32)) - 1

fn int_unsigned_max(width_raw: i32) -> i64:
    let width = int_width_clamp(width_raw)
    if width >= 64:
        return -1
    exact_int_low_mask(width)

fn int_exact_mul_u64(lhs: i64, rhs: i64) -> ExactIntValue:
    var result = exact_int_value(0, 0)
    var addend = exact_int_value(lhs, 0)
    var mul = rhs
    var bit = 0
    while bit < 64:
        if (mul & 1) != 0:
            result = exact_int_add_values(result, addend)
            if result.ok == 0 or result.overflow != 0:
                return result
        mul = exact_int_logical_shr_word(mul, 1)
        bit = bit + 1
        if bit < 64:
            addend = exact_int_shl_small(addend, 1)
            if addend.ok == 0 or addend.overflow != 0:
                return addend
    result

fn int_unsigned_wrap_value(value: ExactIntValue, width: i32) -> i64:
    let masked = exact_int_mask_bits(value, int_width_clamp(width))
    if masked.ok == 0 or masked.overflow != 0:
        return 0
    masked.lo

fn int_unsigned_add(lhs: i64, rhs: i64, width_raw: i32, mode: i32) -> IntArithmeticResult:
    let width = int_width_clamp(width_raw)
    let lv = int_truncate_to_width(lhs, width, true)
    let rv = int_truncate_to_width(rhs, width, true)
    let exact = exact_int_add_values(exact_int_value(lv, 0), exact_int_value(rv, 0))
    if exact.ok == 0:
        return int_arith_invalid()
    let wrapped = int_unsigned_wrap_value(exact, width)
    if exact.overflow == 0 and exact_int_fits_unsigned_bits(exact, width):
        return int_arith_ok(wrapped)
    if mode == OVERFLOW_MODE_SATURATE():
        return int_arith_ok(int_unsigned_max(width))
    if mode == OVERFLOW_MODE_WRAP():
        return int_arith_ok(wrapped)
    int_arith_overflow(wrapped)

fn int_unsigned_sub(lhs: i64, rhs: i64, width_raw: i32, mode: i32) -> IntArithmeticResult:
    let width = int_width_clamp(width_raw)
    let lv = int_truncate_to_width(lhs, width, true)
    let rv = int_truncate_to_width(rhs, width, true)
    let wrapped = int_truncate_to_width(lv -% rv, width, true)
    if not exact_int_uword_lt(lv, rv):
        return int_arith_ok(wrapped)
    if mode == OVERFLOW_MODE_SATURATE():
        return int_arith_ok(0)
    if mode == OVERFLOW_MODE_WRAP():
        return int_arith_ok(wrapped)
    int_arith_overflow(wrapped)

fn int_unsigned_mul(lhs: i64, rhs: i64, width_raw: i32, mode: i32) -> IntArithmeticResult:
    let width = int_width_clamp(width_raw)
    let lv = int_truncate_to_width(lhs, width, true)
    let rv = int_truncate_to_width(rhs, width, true)
    let exact = int_exact_mul_u64(lv, rv)
    if exact.ok == 0:
        return int_arith_invalid()
    let wrapped = int_unsigned_wrap_value(exact, width)
    if exact.overflow == 0 and exact_int_fits_unsigned_bits(exact, width):
        return int_arith_ok(wrapped)
    if mode == OVERFLOW_MODE_SATURATE():
        return int_arith_ok(int_unsigned_max(width))
    if mode == OVERFLOW_MODE_WRAP():
        return int_arith_ok(wrapped)
    int_arith_overflow(wrapped)

fn int_signed_add(lhs: i64, rhs: i64, width_raw: i32, mode: i32) -> IntArithmeticResult:
    let width = int_width_clamp(width_raw)
    let lv = int_truncate_to_width(lhs, width, false)
    let rv = int_truncate_to_width(rhs, width, false)
    let min = int_signed_min(width)
    let max = int_signed_max(width)
    let over_hi = rv > 0 and lv > max - rv
    let over_lo = rv < 0 and lv < min - rv
    let wrapped = int_truncate_to_width(lv +% rv, width, false)
    if not over_hi and not over_lo:
        return int_arith_ok(wrapped)
    if mode == OVERFLOW_MODE_SATURATE():
        return int_arith_ok(if over_hi: max else: min)
    if mode == OVERFLOW_MODE_WRAP():
        return int_arith_ok(wrapped)
    int_arith_overflow(wrapped)

fn int_signed_sub(lhs: i64, rhs: i64, width_raw: i32, mode: i32) -> IntArithmeticResult:
    let width = int_width_clamp(width_raw)
    let lv = int_truncate_to_width(lhs, width, false)
    let rv = int_truncate_to_width(rhs, width, false)
    let min = int_signed_min(width)
    let max = int_signed_max(width)
    let over_hi = rv < 0 and lv > max + rv
    let over_lo = rv > 0 and lv < min + rv
    let wrapped = int_truncate_to_width(lv -% rv, width, false)
    if not over_hi and not over_lo:
        return int_arith_ok(wrapped)
    if mode == OVERFLOW_MODE_SATURATE():
        return int_arith_ok(if over_hi: max else: min)
    if mode == OVERFLOW_MODE_WRAP():
        return int_arith_ok(wrapped)
    int_arith_overflow(wrapped)

fn int_signed_mul_overflows(lhs: i64, rhs: i64, min: i64, max: i64) -> bool:
    if lhs == 0 or rhs == 0:
        return false
    if lhs == -1 and rhs == min:
        return true
    if rhs == -1 and lhs == min:
        return true
    if lhs > 0:
        if rhs > 0:
            return lhs > max / rhs
        return rhs < min / lhs
    if rhs > 0:
        return lhs < min / rhs
    rhs < max / lhs

fn int_signed_mul(lhs: i64, rhs: i64, width_raw: i32, mode: i32) -> IntArithmeticResult:
    let width = int_width_clamp(width_raw)
    let lv = int_truncate_to_width(lhs, width, false)
    let rv = int_truncate_to_width(rhs, width, false)
    let min = int_signed_min(width)
    let max = int_signed_max(width)
    let over = int_signed_mul_overflows(lv, rv, min, max)
    let wrapped = int_truncate_to_width(lv *% rv, width, false)
    if not over:
        return int_arith_ok(wrapped)
    if mode == OVERFLOW_MODE_SATURATE():
        return int_arith_ok(if (lv < 0) == (rv < 0): max else: min)
    if mode == OVERFLOW_MODE_WRAP():
        return int_arith_ok(wrapped)
    int_arith_overflow(wrapped)

fn int_effective_overflow_mode(op: i32, mode: i32) -> i32:
    if op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_MUL_WRAP:
        return OVERFLOW_MODE_WRAP()
    if op == BinaryOp.OP_ADD_SAT or op == BinaryOp.OP_SUB_SAT or op == BinaryOp.OP_MUL_SAT:
        return OVERFLOW_MODE_SATURATE()
    if overflow_mode_valid(mode):
        return mode
    OVERFLOW_MODE_PANIC()

fn int_eval_binary_arithmetic(op: i32, lhs: i64, rhs: i64, width: i32, is_unsigned: bool, overflow_mode: i32) -> IntArithmeticResult:
    let mode = int_effective_overflow_mode(op, overflow_mode)
    if is_unsigned:
        if op == BinaryOp.OP_ADD or op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_ADD_SAT:
            return int_unsigned_add(lhs, rhs, width, mode)
        if op == BinaryOp.OP_SUB or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_SUB_SAT:
            return int_unsigned_sub(lhs, rhs, width, mode)
        if op == BinaryOp.OP_MUL or op == BinaryOp.OP_MUL_WRAP or op == BinaryOp.OP_MUL_SAT:
            return int_unsigned_mul(lhs, rhs, width, mode)
    else:
        if op == BinaryOp.OP_ADD or op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_ADD_SAT:
            return int_signed_add(lhs, rhs, width, mode)
        if op == BinaryOp.OP_SUB or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_SUB_SAT:
            return int_signed_sub(lhs, rhs, width, mode)
        if op == BinaryOp.OP_MUL or op == BinaryOp.OP_MUL_WRAP or op == BinaryOp.OP_MUL_SAT:
            return int_signed_mul(lhs, rhs, width, mode)
    int_arith_invalid()

fn int_eval_unary_neg(value: i64, width: i32, overflow_mode: i32) -> IntArithmeticResult:
    let mode = if overflow_mode_valid(overflow_mode): overflow_mode else: OVERFLOW_MODE_PANIC()
    let v = int_truncate_to_width(value, width, false)
    let min = int_signed_min(width)
    let max = int_signed_max(width)
    let wrapped = int_truncate_to_width(0 -% v, width, false)
    if v != min:
        return int_arith_ok(wrapped)
    if mode == OVERFLOW_MODE_SATURATE():
        return int_arith_ok(max)
    if mode == OVERFLOW_MODE_WRAP():
        return int_arith_ok(wrapped)
    int_arith_overflow(wrapped)

fn int_div_overflows(lhs: i64, rhs: i64, width: i32, is_unsigned: bool) -> bool:
    if is_unsigned:
        return false
    rhs == -1 and int_truncate_to_width(lhs, width, false) == int_signed_min(width)
