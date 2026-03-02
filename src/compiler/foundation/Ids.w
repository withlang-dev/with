// Wave 1 foundations: stable numeric IDs.
//
// Compiler state uses explicit ID domains even when the runtime
// representation is i32 in bootstrap stages.

type FileId = i32
type ModuleId = i32
type DefId = i32
type ItemId = i32
type TypeId = i32
type ValueId = i32
type Symbol = i32
type ArenaId = i32

fn file_id_invalid -> FileId: -1
fn module_id_invalid -> ModuleId: -1
fn def_id_invalid -> DefId: -1
fn item_id_invalid -> ItemId: -1
fn type_id_invalid -> TypeId: -1
fn value_id_invalid -> ValueId: -1
fn symbol_invalid -> Symbol: -1
fn arena_id_invalid -> ArenaId: -1

fn file_id_from_raw(raw: i32) -> FileId: raw
fn module_id_from_raw(raw: i32) -> ModuleId: raw
fn def_id_from_raw(raw: i32) -> DefId: raw
fn item_id_from_raw(raw: i32) -> ItemId: raw
fn type_id_from_raw(raw: i32) -> TypeId: raw
fn value_id_from_raw(raw: i32) -> ValueId: raw
fn symbol_from_raw(raw: i32) -> Symbol: raw
fn arena_id_from_raw(raw: i32) -> ArenaId: raw

fn file_id_raw(id: FileId) -> i32: id
fn module_id_raw(id: ModuleId) -> i32: id
fn def_id_raw(id: DefId) -> i32: id
fn item_id_raw(id: ItemId) -> i32: id
fn type_id_raw(id: TypeId) -> i32: id
fn value_id_raw(id: ValueId) -> i32: id
fn symbol_raw(id: Symbol) -> i32: id
fn arena_id_raw(id: ArenaId) -> i32: id

fn file_id_is_valid(id: FileId) -> bool: id >= 0
fn module_id_is_valid(id: ModuleId) -> bool: id >= 0
fn def_id_is_valid(id: DefId) -> bool: id >= 0
fn item_id_is_valid(id: ItemId) -> bool: id >= 0
fn type_id_is_valid(id: TypeId) -> bool: id >= 0
fn value_id_is_valid(id: ValueId) -> bool: id >= 0
fn symbol_is_valid(id: Symbol) -> bool: id >= 0
fn arena_id_is_valid(id: ArenaId) -> bool: id >= 0
