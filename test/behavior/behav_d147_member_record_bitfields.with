//! expect-stdout: ok

// #3014 (D147, §16.9): `c_import` demotes a record whose member record carries
// bitfields to `opaque` (never mis-modeling bitfields as whole-word fields),
// while `with migrate` preserves the member record's storage units, accessors,
// and comptime layout assertions (tested end-to-end in c-migrator-basic-tests).

@[repr(C)]
pub type Outer_inner { pub __bits_0: u16 = 0 }
impl Copy for Outer_inner
impl Outer_inner:
    pub fn a() -> u16: ((self.__bits_0 >> 0) & 31) as u16
    pub mut fn set_a(v: u16): self.__bits_0 = (self.__bits_0 & ~((31 as u16) << 0)) | (((v as u16) & 31) << 0)
    pub fn b() -> u16: ((self.__bits_0 >> 5) & 2047) as u16
    pub mut fn set_b(v: u16): self.__bits_0 = (self.__bits_0 & ~((2047 as u16) << 5)) | (((v as u16) & 2047) << 5)
comptime fn __ci_layout_Outer_inner():
    if sizeof[Outer_inner]() != 2 or offsetof[Outer_inner](__bits_0) != 0:
        comptime_error("Outer_inner layout mismatch")
const __ci_layout_Outer_inner_check: Unit = __ci_layout_Outer_inner()

@[repr(C)]
pub type Outer_anon_0 { pub __bits_0: u16 = 0 }
impl Copy for Outer_anon_0
impl Outer_anon_0:
    pub fn s() -> i16: (((self.__bits_0 << 10) as i16) >> 10) as i16
    pub mut fn set_s(v: i16): self.__bits_0 = (self.__bits_0 & ~((63 as u16) << 0)) | (((v as u16) & 63) << 0)
    pub fn u() -> u16: ((self.__bits_0 >> 6) & 1023) as u16
    pub mut fn set_u(v: u16): self.__bits_0 = (self.__bits_0 & ~((1023 as u16) << 6)) | (((v as u16) & 1023) << 6)

@[repr(C)]
pub type Outer { pub inner: Outer_inner = Outer_inner {}, pub anon_0: Outer_anon_0 = Outer_anon_0 {} }
impl Copy for Outer

fn main:
    var x = Outer {}
    x.inner.set_a(35)
    x.inner.set_b(1000)
    x.anon_0.set_s(-7)
    x.anon_0.set_u(500)
    if sizeof[Outer]() == 4 and x.inner.a() == 3 and x.inner.b() == 1000 and x.anon_0.s() == -7 and x.anon_0.u() == 500:
        print("ok")
