//! expect-stdout: 16 4 12 1102 1103 1
//! expect-stdout: true 43 1102 42
//! expect-stdout: true
//! expect-stdout: 20
//! expect-stdout: 4 2 42 7
//! expect-stdout: 8 4
//! expect-stdout: 42

use c_import("behav_c_import_cxx_flat.h", lang: "c++", no_methods: true)

@[c_export("flat_ready")]
fn ready(iface: *mut FlatInterface, enabled: bool) -> bool: enabled

@[c_export("flat_score")]
fn score(name: *const i8, value: u64) -> u64: value + 1

fn main:
    print(f"{size_of[FlatCallback]()} {FLAT_GAME_OFFSET} {FLAT_RESULT_OFFSET} {FlatCallback_k_iCallback} {FlatEmpty_k_iCallback} {size_of[FlatEmpty]()}")
    unsafe:
        print(f"{flat_ready(null, true)} {flat_score(c\"score\".ptr, 42)} {FLAT_CALLBACK_ID} {FLAT_TYPED_ID}")
    let callback = FlatCallback { tag: 7, game: 0x0102030405060708u64, result: 9 }
    let bytes = (&raw const callback) as *const u8
    let matches = unsafe { bytes[0] == 7 and bytes[FLAT_GAME_OFFSET] == 8 and bytes[FLAT_GAME_OFFSET + 7] == 1 and bytes[FLAT_RESULT_OFFSET] == 9 }
    print(f"{matches}")
    print(size_of[FlatPackedUnion]())
    let outer = FlatOuter { value: FlatOuter_Nested { value: 42 } }
    let other = FlatOther { value: FlatOther_Nested { value: 7 } }
    print(f"{size_of[FlatOuter]()} {size_of[FlatOther]()} {outer.value.value} {other.value.value}")
    print(f"{size_of[FlatCollision_Item]()} {size_of[FlatCollision_Item_2]()}")
    let constructed = FlatConstructor { value: 42 }
    print(constructed.value)
