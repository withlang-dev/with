// Wave 1 foundations: stable numeric IDs.
//
// Compiler state uses explicit ID domains even when the runtime
// representation is i32 in bootstrap stages.

pub type FileId = i32
pub type ModuleId = i32
pub type DefId = i32
pub type ItemId = i32
pub type TypeId = i32
pub type ValueId = i32
pub type Symbol = i32
pub type ArenaId = i32

pub fn file_id_invalid -> FileId: -1
pub fn module_id_invalid -> ModuleId: -1
pub fn def_id_invalid -> DefId: -1
pub fn item_id_invalid -> ItemId: -1
pub fn type_id_invalid -> TypeId: (-1) as TypeId
pub fn value_id_invalid -> ValueId: -1
pub fn symbol_invalid -> Symbol: -1
pub fn arena_id_invalid -> ArenaId: -1

pub fn file_id_from_raw(raw: i32) -> FileId: raw
pub fn module_id_from_raw(raw: i32) -> ModuleId: raw
pub fn def_id_from_raw(raw: i32) -> DefId: raw
pub fn item_id_from_raw(raw: i32) -> ItemId: raw
pub fn type_id_from_raw(raw: i32) -> TypeId: raw as TypeId
pub fn value_id_from_raw(raw: i32) -> ValueId: raw
pub fn symbol_from_raw(raw: i32) -> Symbol: raw
pub fn arena_id_from_raw(raw: i32) -> ArenaId: raw

pub fn file_id_raw(id: FileId) -> i32: id
pub fn module_id_raw(id: ModuleId) -> i32: id
pub fn def_id_raw(id: DefId) -> i32: id
pub fn item_id_raw(id: ItemId) -> i32: id
pub fn type_id_raw(id: TypeId) -> i32: id as i32
pub fn value_id_raw(id: ValueId) -> i32: id
pub fn symbol_raw(id: Symbol) -> i32: id
pub fn arena_id_raw(id: ArenaId) -> i32: id

pub fn file_id_is_valid(id: FileId) -> bool: id >= 0
pub fn module_id_is_valid(id: ModuleId) -> bool: id >= 0
pub fn def_id_is_valid(id: DefId) -> bool: id >= 0
pub fn item_id_is_valid(id: ItemId) -> bool: id >= 0
pub fn type_id_is_valid(id: TypeId) -> bool: id >= 0
pub fn value_id_is_valid(id: ValueId) -> bool: id >= 0
pub fn symbol_is_valid(id: Symbol) -> bool: id >= 0
pub fn arena_id_is_valid(id: ArenaId) -> bool: id >= 0
