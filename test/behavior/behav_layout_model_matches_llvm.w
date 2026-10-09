//! expect-stdout: E0 4/4 4/4 ok
//! expect-stdout: E8 8/4 8/4 ok
//! expect-stdout: E64 16/8 16/8 ok
//! expect-stdout: EP 24/8 24/8 ok
//! expect-stdout: EMix 24/8 24/8 ok
//! expect-stdout: EOpt 32/8 32/8 ok
//! expect-stdout: EBoxDyn 24/8 24/8 ok
//! expect-stdout: EBig 32/16 32/16 ok
//! expect-stdout: RK 1/1 1/1 ok
//! expect-stdout: RP 16/8 16/8 ok
//! expect-stdout: RP8 16/8 16/8 ok
//! expect-stdout: Option[&P] 8/8 8/8 ok
//! expect-stdout: Option[*const P] 8/8 8/8 ok
//! expect-stdout: Option[&str] 24/8 24/8 ok
//! expect-stdout: Option[&dyn] 24/8 24/8 ok
//! expect-stdout: Option[Box[P]] 8/8 8/8 ok
//! expect-stdout: Option[Box[dyn]] 24/8 24/8 ok
//! expect-stdout: Option[extern fn] 8/8 8/8 ok
//! expect-stdout: Option[fn] 24/8 24/8 ok
//! expect-stdout: Option[i32] 8/4 8/4 ok
//! expect-stdout: Option[i8] 8/4 8/4 ok
//! expect-stdout: Option[i64] 16/8 16/8 ok
//! expect-stdout: Option[P] 24/8 24/8 ok
//! expect-stdout: Option[Q] 8/4 8/4 ok
//! expect-stdout: Option[Big] 32/16 32/16 ok
//! expect-stdout: Option[Option[i32]] 12/4 12/4 ok
//! expect-stdout: Option[Option[P]] 32/8 32/8 ok
//! expect-stdout: Option[List] 40/8 40/8 ok
//! expect-stdout: Option[str] 24/8 24/8 ok
//! expect-stdout: Option[HashMap] 16/8 16/8 ok
//! expect-stdout: Option[E64] 24/8 24/8 ok
//! expect-stdout: Box[P] 8/8 8/8 ok
//! expect-stdout: Box[dyn] 16/8 16/8 ok
//! expect-stdout: &dyn 16/8 16/8 ok
//! expect-stdout: Gen[i64] 16/8 16/8 ok
//! expect-stdout: Gen[P] 24/8 24/8 ok
//! expect-stdout: Gen[i8] 8/4 8/4 ok
//! expect-stdout: Result[i64,str] 24/8 24/8 ok
//! expect-stdout: Result[i8,i8] 8/4 8/4 ok
//! expect-stdout: Result[P,i64] 24/8 24/8 ok
//! expect-stdout: Result[Unit,i8] 8/4 8/4 ok
//! expect-stdout: (i8,i64,i8) 24/8 24/8 ok
//! expect-stdout: (i32,i8) 8/4 8/4 ok
//! expect-stdout: (i8,Option[&P]) 16/8 16/8 ok
//! expect-stdout: (i8,E64) 24/8 24/8 ok
//! expect-stdout: [Option[P];3] 72/8 72/8 ok
//! expect-stdout: [E64;2] 32/8 32/8 ok
//! expect-stdout: [&dyn;2] 32/8 32/8 ok
//! expect-stdout: [Box[dyn];2] 32/8 32/8 ok
//! expect-stdout: [(i8,i64);2] 32/8 32/8 ok
//! expect-stdout: [Option[&P];3] 24/8 24/8 ok
//! expect-stdout: [EP;2] 48/8 48/8 ok
//! expect-stdout: [E8;3] 24/4 24/4 ok
//! expect-stdout: List[i32] 32/8 32/8 ok
//! expect-stdout: HashMap 8/8 8/8 ok
//! expect-stdout: str 16/8 16/8 ok
//! expect-stdout: []i32 16/8 16/8 ok
//! expect-stdout: fn 16/8 16/8 ok
//! expect-stdout: extern fn 8/8 8/8 ok
//! expect-stdout: bool 1/1 1/1 ok
//! expect-stdout: Range[i32] 12/4 12/4 ok
//! expect-stdout: P 16/8 16/8 ok
//! expect-stdout: Big 16/16 16/16 ok
//! expect-stdout: Option[Al32] 96/32 96/32 ok
//! expect-stdout: Option[Option[Al32]] 128/32 128/32 ok
//! expect-stdout: Option[V4] 32/16 32/16 ok
//! expect-stdout: Option[Option[V4]] 48/16 48/16 ok
//! expect-stdout: Result[Al32,i8] 96/32 96/32 ok
//! expect-stdout: Gen[Al32] 96/32 96/32 ok
//! expect-stdout: (i8,Al32) 96/32 96/32 ok
//! expect-stdout: (Al32,i8) 96/32 96/32 ok
//! expect-stdout: (i8,(i8,Al32)) 128/32 128/32 ok
//! expect-stdout: [(i8,Al32);2] 192/32 192/32 ok
//! expect-stdout: Option[(i8,Al32)] 128/32 128/32 ok
//! expect-stdout: (i8,V4) 32/16 32/16 ok
//! expect-stdout: (i8,V8) ok
//! expect-stdout: (i8,(i8,V8)) ok

// #1438 (docs/spec/abi/with-abi.md §1–§3): TypeLayout, the hashed ABI source
// that answers `comptime T.size()`/`T.align()` and sizes union members,
// channel slots and map tuples, must measure exactly what codegen emits.
// Each row prints the model's size/align, then LLVM's for the emitted type
// (`size_of[T]()` is the DataLayout size; the alignment is recovered from
// the size of `(i8, T)`, which places T at its own alignment — `align_of`
// on a named type reads the model, so it cannot witness LLVM), then `ok`
// only when they agree. The numbers pin the rules themselves:
//   §2 enums: tag, then the payload area at the largest payload's alignment;
//     aligned to the larger of the two, size rounded to it (`E64` is 16/8,
//     not the 12/4 of a payload packed at offset 4);
//   §3 nullable Option: a single-address payload (`&T`, `*T`, `extern fn`,
//     a std `Box[T]`) is the pointer itself; `&str` is a view, `&dyn` is fat;
//   §1 fat pointers: `&dyn T`, `Box[dyn T]` are two words.
// `Unit` is deliberately absent: §1 gives it zero size in a layout and an
// `i32` carrier as a value, so `size_of[Unit]()` (4) and `Unit.size()` (0)
// answer different questions.

use std.collections.HashMap
use std.box.Box

trait Shape:
    fn area(self: &Self) -> i32

type P { x: i64, y: i32 }
type Q { a: i8, b: i8 }
type Big { v: i128 }
// #1958: a payload the model aligns above its LLVM body (an `@[align(N)]`
// record, §16.4) or below it (a SIMD vector, §4.3d); Option takes §2's
// body like every enum.
type Al32 { a: i8, @[align(32)] b: i64 }
type V4 = Vector[4, f32]
enum E0 { A | B }
enum E8 { A(v: i8) | B }
enum E64 { A(v: i64) | B }
enum EP { A(p: P) | B }
enum EMix { A(v: i8) | B(w: i64, z: i8) | C }
enum EOpt { A(r: Option[P]) | B }
enum EBoxDyn { A(b: Box[dyn Shape]) | B }
enum EBig { A(b: Big) | B }
enum Gen[T] { Of(t: T) | Nothing }
enum RK: u8 { A = 1 | B = 2 }
enum RP: i32 { A(v: i64) = 1 | B = 2 }
enum RP8: u8 { A(v: i64) = 1 | B = 2 }
type TOptRef = Option[&P]
type TOptPtr = Option[*const P]
type TOptStrRef = Option[&str]
type TOptRefDyn = Option[&dyn Shape]
type TOptBox = Option[Box[P]]
type TOptBoxDyn = Option[Box[dyn Shape]]
type TOptExtFn = Option[extern "C" fn(i32) -> i32]
type TOptFn = Option[fn(i32) -> i32]
type TOptI32 = Option[i32]
type TOptI8 = Option[i8]
type TOptI64 = Option[i64]
type TOptP = Option[P]
type TOptQ = Option[Q]
type TOptBig = Option[Big]
type TOptOptI32 = Option[Option[i32]]
type TOptOptP = Option[Option[P]]
type TOptList = Option[List[i32]]
type TOptStr = Option[str]
type TOptHM = Option[HashMap[i32, i32]]
type TOptE64 = Option[E64]
type TOptAl32 = Option[Al32]
type TOptOptAl32 = Option[Option[Al32]]
type TOptV4 = Option[V4]
type TOptOptV4 = Option[Option[V4]]
type TResAl32I8 = Result[Al32, i8]
type TGenAl32 = Gen[Al32]
// #1964: a tuple places each element at the model's alignment for it, not
// LLVM's (an `@[align(N)]` record's packed body is LLVM-aligned 1; a
// `Vector[8, f32]` is LLVM-aligned 32 where §4.3d caps AArch64 at 16).
type V8 = Vector[8, f32]
type TTupAl32 = (i8, Al32)
type TTupAl32Rev = (Al32, i8)
type TTupTupAl32 = (i8, TTupAl32)
type TArrTupAl32 = [TTupAl32; 2]
type TOptTupAl32 = Option[TTupAl32]
type TTupV4 = (i8, V4)
type TTupV8 = (i8, V8)
type TTupTupV8 = (i8, TTupV8)
type TBoxP = Box[P]
type TBoxDyn = Box[dyn Shape]
type TRefDyn = &dyn Shape
type TGenI64 = Gen[i64]
type TGenP = Gen[P]
type TGenI8 = Gen[i8]
type TResI64Str = Result[i64, str]
type TResI8I8 = Result[i8, i8]
type TResPI64 = Result[P, i64]
type TResUnitI8 = Result[Unit, i8]
type TTup1 = (i8, i64, i8)
type TTup2 = (i32, i8)
type TTup3 = (i8, Option[&P])
type TTup4 = (i8, E64)
type TArrOptP = [Option[P]; 3]
type TArrE64 = [E64; 2]
type TArrRefDyn = [&dyn Shape; 2]
type TArrBoxDyn = [Box[dyn Shape]; 2]
type TArrTup = [(i8, i64); 2]
type TArrOptRef = [Option[&P]; 3]
type TArrEP = [EP; 2]
type TArrE8 = [E8; 3]
type TVec = List[i32]
type THM = HashMap[i32, i32]
type TStr = str
type TSlice = []i32
type TFn = fn(i32) -> i32
type TExtFn = extern "C" fn(i32) -> i32
type TBool = bool
type TRange = Range[i32]


type W_E0 = (i8, E0)
type W_E8 = (i8, E8)
type W_E64 = (i8, E64)
type W_EP = (i8, EP)
type W_EMix = (i8, EMix)
type W_EOpt = (i8, EOpt)
type W_EBoxDyn = (i8, EBoxDyn)
type W_EBig = (i8, EBig)
type W_RK = (i8, RK)
type W_RP = (i8, RP)
type W_RP8 = (i8, RP8)
type W_TOptRef = (i8, TOptRef)
type W_TOptPtr = (i8, TOptPtr)
type W_TOptStrRef = (i8, TOptStrRef)
type W_TOptRefDyn = (i8, TOptRefDyn)
type W_TOptBox = (i8, TOptBox)
type W_TOptBoxDyn = (i8, TOptBoxDyn)
type W_TOptExtFn = (i8, TOptExtFn)
type W_TOptFn = (i8, TOptFn)
type W_TOptI32 = (i8, TOptI32)
type W_TOptI8 = (i8, TOptI8)
type W_TOptI64 = (i8, TOptI64)
type W_TOptP = (i8, TOptP)
type W_TOptQ = (i8, TOptQ)
type W_TOptBig = (i8, TOptBig)
type W_TOptOptI32 = (i8, TOptOptI32)
type W_TOptOptP = (i8, TOptOptP)
type W_TOptList = (i8, TOptList)
type W_TOptStr = (i8, TOptStr)
type W_TOptHM = (i8, TOptHM)
type W_TOptE64 = (i8, TOptE64)
type W_TOptAl32 = (i8, TOptAl32)
type W_TOptOptAl32 = (i8, TOptOptAl32)
type W_TOptV4 = (i8, TOptV4)
type W_TOptOptV4 = (i8, TOptOptV4)
type W_TResAl32I8 = (i8, TResAl32I8)
type W_TGenAl32 = (i8, TGenAl32)
type W_TTupAl32 = (i8, TTupAl32)
type W_TTupAl32Rev = (i8, TTupAl32Rev)
type W_TTupTupAl32 = (i8, TTupTupAl32)
type W_TArrTupAl32 = (i8, TArrTupAl32)
type W_TOptTupAl32 = (i8, TOptTupAl32)
type W_TTupV4 = (i8, TTupV4)
type W_TTupV8 = (i8, TTupV8)
type W_TTupTupV8 = (i8, TTupTupV8)
type W_TBoxP = (i8, TBoxP)
type W_TBoxDyn = (i8, TBoxDyn)
type W_TRefDyn = (i8, TRefDyn)
type W_TGenI64 = (i8, TGenI64)
type W_TGenP = (i8, TGenP)
type W_TGenI8 = (i8, TGenI8)
type W_TResI64Str = (i8, TResI64Str)
type W_TResI8I8 = (i8, TResI8I8)
type W_TResPI64 = (i8, TResPI64)
type W_TResUnitI8 = (i8, TResUnitI8)
type W_TTup1 = (i8, TTup1)
type W_TTup2 = (i8, TTup2)
type W_TTup3 = (i8, TTup3)
type W_TTup4 = (i8, TTup4)
type W_TArrOptP = (i8, TArrOptP)
type W_TArrE64 = (i8, TArrE64)
type W_TArrRefDyn = (i8, TArrRefDyn)
type W_TArrBoxDyn = (i8, TArrBoxDyn)
type W_TArrTup = (i8, TArrTup)
type W_TArrOptRef = (i8, TArrOptRef)
type W_TArrEP = (i8, TArrEP)
type W_TArrE8 = (i8, TArrE8)
type W_TVec = (i8, TVec)
type W_THM = (i8, THM)
type W_TStr = (i8, TStr)
type W_TSlice = (i8, TSlice)
type W_TFn = (i8, TFn)
type W_TExtFn = (i8, TExtFn)
type W_TBool = (i8, TBool)
type W_TRange = (i8, TRange)
type W_P = (i8, P)
type W_Big = (i8, Big)

fn llvm_align(size: i64, pair: i64) -> i64:
    for a in [1, 2, 4, 8, 16, 32]:
        let up = if (a + size) % a == 0: a + size else: a + size + (a - (a + size) % a)
        if up == pair: return a
    -1

fn row(name: str, ms: usize, ma: usize, ls: i64, pair: i64):
    let la = llvm_align(ls, pair)
    let mark = if ms as i64 == ls and ma as i64 == la: "ok" else: "MISMATCH"
    print(f"{name} {ms}/{ma} {ls}/{la} {mark}")

// The verdict alone, for a row whose numbers are the target's (§4.3d).
fn verdict(name: str, ms: usize, ma: usize, ls: i64, pair: i64):
    let la = llvm_align(ls, pair)
    let mark = if ms as i64 == ls and ma as i64 == la: "ok" else: f"MISMATCH {ms}/{ma} {ls}/{la}"
    print(f"{name} {mark}")

fn main:
    row("E0", comptime E0.size(), comptime E0.align(), size_of[E0](), size_of[W_E0]())
    row("E8", comptime E8.size(), comptime E8.align(), size_of[E8](), size_of[W_E8]())
    row("E64", comptime E64.size(), comptime E64.align(), size_of[E64](), size_of[W_E64]())
    row("EP", comptime EP.size(), comptime EP.align(), size_of[EP](), size_of[W_EP]())
    row("EMix", comptime EMix.size(), comptime EMix.align(), size_of[EMix](), size_of[W_EMix]())
    row("EOpt", comptime EOpt.size(), comptime EOpt.align(), size_of[EOpt](), size_of[W_EOpt]())
    row("EBoxDyn", comptime EBoxDyn.size(), comptime EBoxDyn.align(), size_of[EBoxDyn](), size_of[W_EBoxDyn]())
    row("EBig", comptime EBig.size(), comptime EBig.align(), size_of[EBig](), size_of[W_EBig]())
    row("RK", comptime RK.size(), comptime RK.align(), size_of[RK](), size_of[W_RK]())
    row("RP", comptime RP.size(), comptime RP.align(), size_of[RP](), size_of[W_RP]())
    row("RP8", comptime RP8.size(), comptime RP8.align(), size_of[RP8](), size_of[W_RP8]())
    row("Option[&P]", comptime TOptRef.size(), comptime TOptRef.align(), size_of[TOptRef](), size_of[W_TOptRef]())
    row("Option[*const P]", comptime TOptPtr.size(), comptime TOptPtr.align(), size_of[TOptPtr](), size_of[W_TOptPtr]())
    row("Option[&str]", comptime TOptStrRef.size(), comptime TOptStrRef.align(), size_of[TOptStrRef](), size_of[W_TOptStrRef]())
    row("Option[&dyn]", comptime TOptRefDyn.size(), comptime TOptRefDyn.align(), size_of[TOptRefDyn](), size_of[W_TOptRefDyn]())
    row("Option[Box[P]]", comptime TOptBox.size(), comptime TOptBox.align(), size_of[TOptBox](), size_of[W_TOptBox]())
    row("Option[Box[dyn]]", comptime TOptBoxDyn.size(), comptime TOptBoxDyn.align(), size_of[TOptBoxDyn](), size_of[W_TOptBoxDyn]())
    row("Option[extern fn]", comptime TOptExtFn.size(), comptime TOptExtFn.align(), size_of[TOptExtFn](), size_of[W_TOptExtFn]())
    row("Option[fn]", comptime TOptFn.size(), comptime TOptFn.align(), size_of[TOptFn](), size_of[W_TOptFn]())
    row("Option[i32]", comptime TOptI32.size(), comptime TOptI32.align(), size_of[TOptI32](), size_of[W_TOptI32]())
    row("Option[i8]", comptime TOptI8.size(), comptime TOptI8.align(), size_of[TOptI8](), size_of[W_TOptI8]())
    row("Option[i64]", comptime TOptI64.size(), comptime TOptI64.align(), size_of[TOptI64](), size_of[W_TOptI64]())
    row("Option[P]", comptime TOptP.size(), comptime TOptP.align(), size_of[TOptP](), size_of[W_TOptP]())
    row("Option[Q]", comptime TOptQ.size(), comptime TOptQ.align(), size_of[TOptQ](), size_of[W_TOptQ]())
    row("Option[Big]", comptime TOptBig.size(), comptime TOptBig.align(), size_of[TOptBig](), size_of[W_TOptBig]())
    row("Option[Option[i32]]", comptime TOptOptI32.size(), comptime TOptOptI32.align(), size_of[TOptOptI32](), size_of[W_TOptOptI32]())
    row("Option[Option[P]]", comptime TOptOptP.size(), comptime TOptOptP.align(), size_of[TOptOptP](), size_of[W_TOptOptP]())
    row("Option[List]", comptime TOptList.size(), comptime TOptList.align(), size_of[TOptList](), size_of[W_TOptList]())
    row("Option[str]", comptime TOptStr.size(), comptime TOptStr.align(), size_of[TOptStr](), size_of[W_TOptStr]())
    row("Option[HashMap]", comptime TOptHM.size(), comptime TOptHM.align(), size_of[TOptHM](), size_of[W_TOptHM]())
    row("Option[E64]", comptime TOptE64.size(), comptime TOptE64.align(), size_of[TOptE64](), size_of[W_TOptE64]())
    row("Box[P]", comptime TBoxP.size(), comptime TBoxP.align(), size_of[TBoxP](), size_of[W_TBoxP]())
    row("Box[dyn]", comptime TBoxDyn.size(), comptime TBoxDyn.align(), size_of[TBoxDyn](), size_of[W_TBoxDyn]())
    row("&dyn", comptime TRefDyn.size(), comptime TRefDyn.align(), size_of[TRefDyn](), size_of[W_TRefDyn]())
    row("Gen[i64]", comptime TGenI64.size(), comptime TGenI64.align(), size_of[TGenI64](), size_of[W_TGenI64]())
    row("Gen[P]", comptime TGenP.size(), comptime TGenP.align(), size_of[TGenP](), size_of[W_TGenP]())
    row("Gen[i8]", comptime TGenI8.size(), comptime TGenI8.align(), size_of[TGenI8](), size_of[W_TGenI8]())
    row("Result[i64,str]", comptime TResI64Str.size(), comptime TResI64Str.align(), size_of[TResI64Str](), size_of[W_TResI64Str]())
    row("Result[i8,i8]", comptime TResI8I8.size(), comptime TResI8I8.align(), size_of[TResI8I8](), size_of[W_TResI8I8]())
    row("Result[P,i64]", comptime TResPI64.size(), comptime TResPI64.align(), size_of[TResPI64](), size_of[W_TResPI64]())
    row("Result[Unit,i8]", comptime TResUnitI8.size(), comptime TResUnitI8.align(), size_of[TResUnitI8](), size_of[W_TResUnitI8]())
    row("(i8,i64,i8)", comptime TTup1.size(), comptime TTup1.align(), size_of[TTup1](), size_of[W_TTup1]())
    row("(i32,i8)", comptime TTup2.size(), comptime TTup2.align(), size_of[TTup2](), size_of[W_TTup2]())
    row("(i8,Option[&P])", comptime TTup3.size(), comptime TTup3.align(), size_of[TTup3](), size_of[W_TTup3]())
    row("(i8,E64)", comptime TTup4.size(), comptime TTup4.align(), size_of[TTup4](), size_of[W_TTup4]())
    row("[Option[P];3]", comptime TArrOptP.size(), comptime TArrOptP.align(), size_of[TArrOptP](), size_of[W_TArrOptP]())
    row("[E64;2]", comptime TArrE64.size(), comptime TArrE64.align(), size_of[TArrE64](), size_of[W_TArrE64]())
    row("[&dyn;2]", comptime TArrRefDyn.size(), comptime TArrRefDyn.align(), size_of[TArrRefDyn](), size_of[W_TArrRefDyn]())
    row("[Box[dyn];2]", comptime TArrBoxDyn.size(), comptime TArrBoxDyn.align(), size_of[TArrBoxDyn](), size_of[W_TArrBoxDyn]())
    row("[(i8,i64);2]", comptime TArrTup.size(), comptime TArrTup.align(), size_of[TArrTup](), size_of[W_TArrTup]())
    row("[Option[&P];3]", comptime TArrOptRef.size(), comptime TArrOptRef.align(), size_of[TArrOptRef](), size_of[W_TArrOptRef]())
    row("[EP;2]", comptime TArrEP.size(), comptime TArrEP.align(), size_of[TArrEP](), size_of[W_TArrEP]())
    row("[E8;3]", comptime TArrE8.size(), comptime TArrE8.align(), size_of[TArrE8](), size_of[W_TArrE8]())
    row("List[i32]", comptime TVec.size(), comptime TVec.align(), size_of[TVec](), size_of[W_TVec]())
    row("HashMap", comptime THM.size(), comptime THM.align(), size_of[THM](), size_of[W_THM]())
    row("str", comptime TStr.size(), comptime TStr.align(), size_of[TStr](), size_of[W_TStr]())
    row("[]i32", comptime TSlice.size(), comptime TSlice.align(), size_of[TSlice](), size_of[W_TSlice]())
    row("fn", comptime TFn.size(), comptime TFn.align(), size_of[TFn](), size_of[W_TFn]())
    row("extern fn", comptime TExtFn.size(), comptime TExtFn.align(), size_of[TExtFn](), size_of[W_TExtFn]())
    row("bool", comptime TBool.size(), comptime TBool.align(), size_of[TBool](), size_of[W_TBool]())
    row("Range[i32]", comptime TRange.size(), comptime TRange.align(), size_of[TRange](), size_of[W_TRange]())
    row("P", comptime P.size(), comptime P.align(), size_of[P](), size_of[W_P]())
    row("Big", comptime Big.size(), comptime Big.align(), size_of[Big](), size_of[W_Big]())
    row("Option[Al32]", comptime TOptAl32.size(), comptime TOptAl32.align(), size_of[TOptAl32](), size_of[W_TOptAl32]())
    row("Option[Option[Al32]]", comptime TOptOptAl32.size(), comptime TOptOptAl32.align(), size_of[TOptOptAl32](), size_of[W_TOptOptAl32]())
    row("Option[V4]", comptime TOptV4.size(), comptime TOptV4.align(), size_of[TOptV4](), size_of[W_TOptV4]())
    row("Option[Option[V4]]", comptime TOptOptV4.size(), comptime TOptOptV4.align(), size_of[TOptOptV4](), size_of[W_TOptOptV4]())
    row("Result[Al32,i8]", comptime TResAl32I8.size(), comptime TResAl32I8.align(), size_of[TResAl32I8](), size_of[W_TResAl32I8]())
    row("Gen[Al32]", comptime TGenAl32.size(), comptime TGenAl32.align(), size_of[TGenAl32](), size_of[W_TGenAl32]())

    row("(i8,Al32)", comptime TTupAl32.size(), comptime TTupAl32.align(), size_of[TTupAl32](), size_of[W_TTupAl32]())
    row("(Al32,i8)", comptime TTupAl32Rev.size(), comptime TTupAl32Rev.align(), size_of[TTupAl32Rev](), size_of[W_TTupAl32Rev]())
    row("(i8,(i8,Al32))", comptime TTupTupAl32.size(), comptime TTupTupAl32.align(), size_of[TTupTupAl32](), size_of[W_TTupTupAl32]())
    row("[(i8,Al32);2]", comptime TArrTupAl32.size(), comptime TArrTupAl32.align(), size_of[TArrTupAl32](), size_of[W_TArrTupAl32]())
    row("Option[(i8,Al32)]", comptime TOptTupAl32.size(), comptime TOptTupAl32.align(), size_of[TOptTupAl32](), size_of[W_TOptTupAl32]())
    row("(i8,V4)", comptime TTupV4.size(), comptime TTupV4.align(), size_of[TTupV4](), size_of[W_TTupV4]())
    verdict("(i8,V8)", comptime TTupV8.size(), comptime TTupV8.align(), size_of[TTupV8](), size_of[W_TTupV8]())
    verdict("(i8,(i8,V8))", comptime TTupTupV8.size(), comptime TTupTupV8.align(), size_of[TTupTupV8](), size_of[W_TTupTupV8]())
