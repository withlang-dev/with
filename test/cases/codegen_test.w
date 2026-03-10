//! expect-stdout: ok

use Types
use Mir
use Codegen

fn test_type_mapping:
    var types = TypeTable.new()
    assert(type_to_llvm(types, TYPE_VOID) == LT_VOID)
    assert(type_to_llvm(types, TYPE_BOOL) == LT_I1)
    assert(type_to_llvm(types, TYPE_I8) == LT_I8)
    assert(type_to_llvm(types, TYPE_I32) == LT_I32)
    assert(type_to_llvm(types, TYPE_I64) == LT_I64)
    assert(type_to_llvm(types, TYPE_F32) == LT_F32)
    assert(type_to_llvm(types, TYPE_F64) == LT_F64)
    assert(type_to_llvm(types, TYPE_STR) == LT_STRUCT)
    let pt = TypeTable.add_ptr(types, TYPE_I32, 0)
    assert(type_to_llvm(types, pt) == LT_PTR)

fn test_cast_instructions:
    var types = TypeTable.new()
    // Int widening: i8 → i32 (signed → sext)
    assert(cast_instruction(types, TYPE_I8, TYPE_I32) == LI_SEXT)
    // Unsigned widening: u8 → u32 (unsigned → zext)
    assert(cast_instruction(types, TYPE_U8, TYPE_U32) == LI_ZEXT)
    // Int narrowing: i64 → i32 (trunc)
    assert(cast_instruction(types, TYPE_I64, TYPE_I32) == LI_TRUNC)
    // Int → Float
    assert(cast_instruction(types, TYPE_I32, TYPE_F64) == LI_SITOFP)
    assert(cast_instruction(types, TYPE_U32, TYPE_F64) == LI_UITOFP)
    // Float → Int
    assert(cast_instruction(types, TYPE_F64, TYPE_I32) == LI_FPTOSI)
    assert(cast_instruction(types, TYPE_F64, TYPE_U32) == LI_FPTOUI)
    // Float widening
    assert(cast_instruction(types, TYPE_F32, TYPE_F64) == LI_FPEXT)
    // Float narrowing
    assert(cast_instruction(types, TYPE_F64, TYPE_F32) == LI_FPTRUNC)
    // Same type → no-op
    assert(cast_instruction(types, TYPE_I32, TYPE_I32) == -1)

fn test_binop_mapping:
    var types = TypeTable.new()
    // Int operations
    assert(binop_to_llvm(types, 0, TYPE_I32) == LI_ADD)
    assert(binop_to_llvm(types, 1, TYPE_I32) == LI_SUB)
    assert(binop_to_llvm(types, 2, TYPE_I32) == LI_MUL)
    assert(binop_to_llvm(types, 3, TYPE_I32) == LI_SDIV)
    assert(binop_to_llvm(types, 4, TYPE_I32) == LI_SREM)
    // Float operations
    assert(binop_to_llvm(types, 0, TYPE_F64) == LI_FADD)
    assert(binop_to_llvm(types, 1, TYPE_F64) == LI_FSUB)
    assert(binop_to_llvm(types, 2, TYPE_F64) == LI_FMUL)
    assert(binop_to_llvm(types, 3, TYPE_F64) == LI_FDIV)
    // Comparison
    assert(binop_to_llvm(types, 5, TYPE_I32) == LI_ICMP_EQ)
    assert(binop_to_llvm(types, 5, TYPE_F64) == LI_FCMP_OEQ)
    assert(binop_to_llvm(types, 7, TYPE_I32) == LI_ICMP_SLT)
    // Bitwise
    assert(binop_to_llvm(types, 13, TYPE_I32) == LI_AND)
    assert(binop_to_llvm(types, 14, TYPE_I32) == LI_OR)
    assert(binop_to_llvm(types, 15, TYPE_I32) == LI_XOR)
    assert(binop_to_llvm(types, 16, TYPE_I32) == LI_SHL)
    assert(binop_to_llvm(types, 17, TYPE_I32) == LI_ASHR)

fn test_codegen_simple:
    var body = MirBody.new()
    let l1 = MirBody.add_local(body, -1, TYPE_I32, 0)
    let bb = MirBody.add_block(body)
    MirBody.add_assign(body, bb, l1, RV_CONSTANT, 42, 0)
    var types = TypeTable.new()
    var cg = CodegenState.new(body, types)
    assert(cg.next_reg == MirBody.local_count(body))
    CodegenState.gen_function(cg)
    // Should have emitted alloca + store instructions
    assert(CodegenState.inst_count(cg) >= 2)
    // First instruction: alloca for return local
    let inst0 = CodegenState.get_inst(cg, 0)
    assert(inst0.opcode == LI_ALLOCA)
    // Second instruction: alloca for l1
    let inst1 = CodegenState.get_inst(cg, 1)
    assert(inst1.opcode == LI_ALLOCA)

fn test_codegen_use:
    var body = MirBody.new()
    let l1 = MirBody.add_local(body, -1, TYPE_I32, 0)
    let l2 = MirBody.add_local(body, -1, TYPE_I32, 0)
    let bb = MirBody.add_block(body)
    // l2 = use l1
    MirBody.add_assign(body, bb, l2, RV_USE, l1, 0)
    var types = TypeTable.new()
    var cg = CodegenState.new(body, types)
    CodegenState.gen_function(cg)
    // Allocas for 3 locals + load + store for the use
    assert(CodegenState.inst_count(cg) >= 5)

fn test_instruction:
    let inst = Instruction.new(LI_ADD, 5, 3, 4)
    assert(inst.opcode == LI_ADD)
    assert(inst.dest == 5)
    assert(inst.op0 == 3)
    assert(inst.op1 == 4)
    assert(inst.extra == 0)

fn main:
    test_type_mapping()
    test_cast_instructions()
    test_binop_mapping()
    test_codegen_simple()
    test_codegen_use()
    test_instruction()
    println("ok")
