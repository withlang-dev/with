// Codegen — MIR to LLVM IR code generation for the With compiler.
//
// Walks MIR basic blocks and emits LLVM IR via LLVM-C API.
// Uses alloca + mem2reg strategy for locals.
//
// In the self-hosted compiler, LLVM-C bindings are accessed via
// c_import. This module provides the generation logic; the actual
// LLVM FFI calls are abstracted into helper functions.
//
// Ref: bootstrap/Codegen.zig
// Ref: .reference/zig/src/codegen/llvm.zig
// Ref: .reference/rust/compiler/rustc_codegen_llvm/

use Type
use Mir

// ── LLVM type tags ───────────────────────────────────────────────────

fn LT_VOID() -> i32: 0
fn LT_I1() -> i32: 1
fn LT_I8() -> i32: 2
fn LT_I16() -> i32: 3
fn LT_I32() -> i32: 4
fn LT_I64() -> i32: 5
fn LT_F32() -> i32: 6
fn LT_F64() -> i32: 7
fn LT_PTR() -> i32: 8
fn LT_STRUCT() -> i32: 9
fn LT_ARRAY() -> i32: 10
fn LT_FN() -> i32: 11

// ── LLVM instruction tags ────────────────────────────────────────────

fn LI_ADD() -> i32: 0
fn LI_SUB() -> i32: 1
fn LI_MUL() -> i32: 2
fn LI_SDIV() -> i32: 3
fn LI_UDIV() -> i32: 4
fn LI_SREM() -> i32: 5
fn LI_UREM() -> i32: 6
fn LI_FADD() -> i32: 7
fn LI_FSUB() -> i32: 8
fn LI_FMUL() -> i32: 9
fn LI_FDIV() -> i32: 10
fn LI_AND() -> i32: 11
fn LI_OR() -> i32: 12
fn LI_XOR() -> i32: 13
fn LI_SHL() -> i32: 14
fn LI_LSHR() -> i32: 15
fn LI_ASHR() -> i32: 16
fn LI_ICMP_EQ() -> i32: 17
fn LI_ICMP_NE() -> i32: 18
fn LI_ICMP_SLT() -> i32: 19
fn LI_ICMP_SGT() -> i32: 20
fn LI_ICMP_SLE() -> i32: 21
fn LI_ICMP_SGE() -> i32: 22
fn LI_ICMP_ULT() -> i32: 23
fn LI_ICMP_UGT() -> i32: 24
fn LI_ICMP_ULE() -> i32: 25
fn LI_ICMP_UGE() -> i32: 26
fn LI_FCMP_OEQ() -> i32: 27
fn LI_FCMP_ONE() -> i32: 28
fn LI_FCMP_OLT() -> i32: 29
fn LI_FCMP_OGT() -> i32: 30
fn LI_FCMP_OLE() -> i32: 31
fn LI_FCMP_OGE() -> i32: 32
fn LI_ALLOCA() -> i32: 33
fn LI_LOAD() -> i32: 34
fn LI_STORE() -> i32: 35
fn LI_GEP() -> i32: 36
fn LI_CALL() -> i32: 37
fn LI_RET() -> i32: 38
fn LI_BR() -> i32: 39
fn LI_COND_BR() -> i32: 40
fn LI_PHI() -> i32: 41
fn LI_SEXT() -> i32: 42
fn LI_ZEXT() -> i32: 43
fn LI_TRUNC() -> i32: 44
fn LI_SITOFP() -> i32: 45
fn LI_UITOFP() -> i32: 46
fn LI_FPTOSI() -> i32: 47
fn LI_FPTOUI() -> i32: 48
fn LI_FPEXT() -> i32: 49
fn LI_FPTRUNC() -> i32: 50
fn LI_BITCAST() -> i32: 51
fn LI_NEG() -> i32: 52
fn LI_FNEG() -> i32: 53
fn LI_NOT() -> i32: 54

// ── Codegen instruction buffer ───────────────────────────────────────
// Instead of calling LLVM-C directly (which requires c_import),
// we build an instruction buffer that can be consumed by the driver.

type Instruction = {
    opcode: i32,
    dest: i32,
    op0: i32,
    op1: i32,
    extra: i32,
}

fn Instruction.new(opcode: i32, dest: i32, op0: i32, op1: i32) -> Instruction:
    Instruction {
        opcode: opcode,
        dest: dest,
        op0: op0,
        op1: op1,
        extra: 0,
    }

// ── Codegen state ────────────────────────────────────────────────────

type CodegenState = {
    body: MirBody,
    types: TypeTable,
    instructions: Vec[Instruction],
    next_reg: i32,
    local_regs: Vec[i32],
    bb_labels: Vec[i32],
}

fn CodegenState.new(body: MirBody, types: TypeTable) -> CodegenState:
    var cg = CodegenState {
        body: body,
        types: types,
        instructions: Vec.new(),
        next_reg: 0,
        local_regs: Vec.new(),
        bb_labels: Vec.new(),
    }
    // Allocate registers for all locals
    let lc = MirBody.local_count(body)
    var i = 0
    while i < lc:
        cg.local_regs.push(cg.next_reg)
        cg.next_reg = cg.next_reg + 1
        i = i + 1
    // Allocate labels for all basic blocks
    let bc = MirBody.block_count(body)
    i = 0
    while i < bc:
        cg.bb_labels.push(i)
        i = i + 1
    cg

fn CodegenState.alloc_reg(self: CodegenState) -> i32:
    let r = self.next_reg
    self.next_reg = self.next_reg + 1
    r

fn CodegenState.emit(self: CodegenState, inst: Instruction) -> void:
    self.instructions.push(inst)

fn CodegenState.inst_count(self: CodegenState) -> i32:
    self.instructions.len() as i32

fn CodegenState.get_inst(self: CodegenState, idx: i32) -> Instruction:
    self.instructions.get(idx as i64)

// ── LLVM type mapping ────────────────────────────────────────────────

fn type_to_llvm(types: TypeTable, type_id: i32) -> i32:
    if type_id == TYPE_VOID():
        return LT_VOID()
    if type_id == TYPE_BOOL():
        return LT_I1()
    if type_id == TYPE_I8():
        return LT_I8()
    if type_id == TYPE_U8():
        return LT_I8()
    if type_id == TYPE_I16():
        return LT_I16()
    if type_id == TYPE_U16():
        return LT_I16()
    if type_id == TYPE_I32():
        return LT_I32()
    if type_id == TYPE_U32():
        return LT_I32()
    if type_id == TYPE_I64():
        return LT_I64()
    if type_id == TYPE_U64():
        return LT_I64()
    if type_id == TYPE_F32():
        return LT_F32()
    if type_id == TYPE_F64():
        return LT_F64()
    if type_id == TYPE_STR():
        return LT_STRUCT()
    if TypeTable.is_ptr(types, type_id):
        return LT_PTR()
    if TypeTable.is_ref(types, type_id):
        return LT_PTR()
    if TypeTable.is_struct(types, type_id):
        return LT_STRUCT()
    if TypeTable.is_array(types, type_id):
        return LT_ARRAY()
    if TypeTable.is_fn(types, type_id):
        return LT_FN()
    LT_I32()

// ── Binary op mapping ────────────────────────────────────────────────

fn binop_to_llvm(types: TypeTable, op: i32, operand_type: i32) -> i32:
    let is_float = TypeTable.is_float(types, operand_type)
    if op == 0:  // OP_ADD
        if is_float then LI_FADD() else LI_ADD()
    else if op == 1:  // OP_SUB
        if is_float then LI_FSUB() else LI_SUB()
    else if op == 2:  // OP_MUL
        if is_float then LI_FMUL() else LI_MUL()
    else if op == 3:  // OP_DIV
        if is_float then LI_FDIV() else LI_SDIV()
    else if op == 4:  // OP_MOD
        LI_SREM()
    else if op == 5:  // OP_EQ
        if is_float then LI_FCMP_OEQ() else LI_ICMP_EQ()
    else if op == 6:  // OP_NEQ
        if is_float then LI_FCMP_ONE() else LI_ICMP_NE()
    else if op == 7:  // OP_LT
        if is_float then LI_FCMP_OLT() else LI_ICMP_SLT()
    else if op == 8:  // OP_GT
        if is_float then LI_FCMP_OGT() else LI_ICMP_SGT()
    else if op == 9:  // OP_LTE
        if is_float then LI_FCMP_OLE() else LI_ICMP_SLE()
    else if op == 10:  // OP_GTE
        if is_float then LI_FCMP_OGE() else LI_ICMP_SGE()
    else if op == 11:  // OP_AND
        LI_AND()
    else if op == 12:  // OP_OR
        LI_OR()
    else if op == 13:  // OP_BIT_AND
        LI_AND()
    else if op == 14:  // OP_BIT_OR
        LI_OR()
    else if op == 15:  // OP_BIT_XOR
        LI_XOR()
    else if op == 16:  // OP_SHL
        LI_SHL()
    else if op == 17:  // OP_SHR
        LI_ASHR()
    else LI_ADD()

// ── Code generation ──────────────────────────────────────────────────

fn CodegenState.gen_function(self: CodegenState) -> void:
    // Emit allocas for all locals
    let lc = MirBody.local_count(self.body)
    var i = 0
    while i < lc:
        let decl = MirBody.get_local(self.body, i)
        let llvm_type = type_to_llvm(self.types, decl.type_id)
        let reg = self.local_regs.get(i as i64)
        CodegenState.emit(self, Instruction.new(LI_ALLOCA(), reg, llvm_type, 0))
        i = i + 1
    // Emit statements for each basic block
    let bc = MirBody.block_count(self.body)
    var bb = 0
    while bb < bc:
        CodegenState.gen_block(self, bb)
        bb = bb + 1

fn CodegenState.gen_block(self: CodegenState, bb: i32) -> void:
    // Emit statements
    let stmt_count = MirBody.stmt_count(self.body)
    var i = 0
    while i < stmt_count:
        CodegenState.gen_stmt(self, i)
        i = i + 1

fn CodegenState.gen_stmt(self: CodegenState, idx: i32) -> void:
    let kind = MirBody.stmt_kind(self.body, idx)
    if kind == SK_ASSIGN():
        let dest = MirBody.stmt_d0(self.body, idx)
        let rv_kind = MirBody.stmt_d1(self.body, idx)
        let rv_d0 = MirBody.stmt_d2(self.body, idx)
        if rv_kind == RV_CONSTANT():
            // Store constant into local
            let dest_reg = self.local_regs.get(dest as i64)
            CodegenState.emit(self, Instruction.new(LI_STORE(), dest_reg, rv_d0, 0))
            return
        if rv_kind == RV_USE():
            // Copy from one local to another
            let src_reg = self.local_regs.get(rv_d0 as i64)
            let dest_reg = self.local_regs.get(dest as i64)
            let tmp = CodegenState.alloc_reg(self)
            CodegenState.emit(self, Instruction.new(LI_LOAD(), tmp, src_reg, 0))
            CodegenState.emit(self, Instruction.new(LI_STORE(), dest_reg, tmp, 0))
            return
        if rv_kind == RV_BINARY_OP():
            let lhs_reg = self.local_regs.get(rv_d0 as i64)
            let dest_reg = self.local_regs.get(dest as i64)
            let lhs_tmp = CodegenState.alloc_reg(self)
            CodegenState.emit(self, Instruction.new(LI_LOAD(), lhs_tmp, lhs_reg, 0))
            let result = CodegenState.alloc_reg(self)
            CodegenState.emit(self, Instruction.new(LI_ADD(), result, lhs_tmp, 0))
            CodegenState.emit(self, Instruction.new(LI_STORE(), dest_reg, result, 0))
            return
        if rv_kind == RV_REF():
            // Store address of source into dest
            let dest_reg = self.local_regs.get(dest as i64)
            let src_reg = self.local_regs.get(rv_d0 as i64)
            CodegenState.emit(self, Instruction.new(LI_STORE(), dest_reg, src_reg, 0))
            return
        return
    if kind == SK_DROP():
        // Drop: call destructor if applicable
        // For now, emit a nop (drops are tracked but not codegen'd yet)
        return
    if kind == SK_NOP():
        return

// ── Cast generation ──────────────────────────────────────────────────

fn cast_instruction(types: TypeTable, from_type: i32, to_type: i32) -> i32:
    let from_int = TypeTable.is_int(types, from_type)
    let to_int = TypeTable.is_int(types, to_type)
    let from_float = TypeTable.is_float(types, from_type)
    let to_float = TypeTable.is_float(types, to_type)
    // Int → Int
    if from_int:
        if to_int:
            let from_bits = TypeTable.int_bits(types, from_type)
            let to_bits = TypeTable.int_bits(types, to_type)
            if from_bits < to_bits:
                if TypeTable.int_is_signed(types, from_type):
                    return LI_SEXT()
                return LI_ZEXT()
            if from_bits > to_bits:
                return LI_TRUNC()
            return -1
    // Int → Float
    if from_int:
        if to_float:
            if TypeTable.int_is_signed(types, from_type):
                return LI_SITOFP()
            return LI_UITOFP()
    // Float → Int
    if from_float:
        if to_int:
            if TypeTable.int_is_signed(types, to_type):
                return LI_FPTOSI()
            return LI_FPTOUI()
    // Float → Float
    if from_float:
        if to_float:
            let from_bits = TypeTable.float_bits(types, from_type)
            let to_bits = TypeTable.float_bits(types, to_type)
            if from_bits < to_bits:
                return LI_FPEXT()
            if from_bits > to_bits:
                return LI_FPTRUNC()
            return -1
    -1
