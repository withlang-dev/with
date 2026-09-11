// Type tags shared by semantic analysis and the frozen MIR type tables.
// Keep this vocabulary independent of the semantic-analysis driver.
enum TypeKind: i32:
    TY_ERR = 0
    TY_INT = 1
    TY_FLOAT = 2
    TY_BOOL = 3
    TY_VOID = 4
    TY_STR = 5
    TY_STRUCT = 6
    TY_ENUM = 7
    TY_ARRAY = 8
    TY_SLICE = 9
    TY_TUPLE = 10
    TY_RANGE = 11
    TY_FN = 12
    TY_PTR = 13
    TY_REF = 14
    TY_ALIAS = 15
    TY_GENERIC_FN = 16
    TY_TRAIT_OBJ = 17
    TY_NEVER = 18
    TY_GENERIC_INST = 19
    TY_EXTERN_FN = 20

type TypeId = i32

enum BorrowKind: i32:
    SHARED = 0
    EXCLUSIVE = 1
