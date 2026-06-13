//! expect-stdout: ok

@[derive(Eq, Hash, Ord, Debug, Clone)]
type Color { r: u8, g: u8, b: u8 }

@[derive(all)]
type Pixel { r: u8, g: u8, b: u8, a: u8 }

@[derive(all)]
type Name { first: str, last: str }

@[derive(Copy)]
type CopyPair { x: i32, y: i32 }

type Leaf { value: i32 }

impl Clone for Leaf:    fn clone(self:
    &Self) -> Leaf:
        Leaf { value: self.value + 1 }

@[derive(Clone)]
type Wrap { leaf: Leaf }

@[derive(Display)]
enum Role { Admin | Member | Guest }

@[derive(Display)]
enum PayloadRole { Admin(i32) | Guest }

const COLOR_HAS_EQ: bool = comptime Color.implements(Eq)
const COLOR_HAS_HASH: bool = comptime Color.implements(Hash)
const COLOR_HAS_ORD: bool = comptime Color.implements(Ord)
const COLOR_HAS_DEBUG: bool = comptime Color.implements(Debug)
const COLOR_HAS_CLONE: bool = comptime Color.implements(Clone)
const PIXEL_HAS_DEFAULT: bool = comptime Pixel.implements(Default)
const PIXEL_HAS_EQ: bool = comptime Pixel.implements(Eq)
const PIXEL_HAS_HASH: bool = comptime Pixel.implements(Hash)
const PIXEL_HAS_ORD: bool = comptime Pixel.implements(Ord)
const PIXEL_HAS_DEBUG: bool = comptime Pixel.implements(Debug)
const PIXEL_HAS_CLONE: bool = comptime Pixel.implements(Clone)
const PIXEL_IS_COPY: bool = comptime Pixel.is_copy()
const NAME_HAS_DEFAULT: bool = comptime Name.implements(Default)
const NAME_HAS_CLONE: bool = comptime Name.implements(Clone)
const NAME_HAS_ORD: bool = comptime Name.implements(Ord)
const ROLE_HAS_DISPLAY: bool = comptime Role.implements(Display)
const COPY_PAIR_IS_COPY: bool = comptime CopyPair.is_copy()

fn main:
    assert(COLOR_HAS_EQ)
    assert(COLOR_HAS_HASH)
    assert(COLOR_HAS_ORD)
    assert(COLOR_HAS_DEBUG)
    assert(COLOR_HAS_CLONE)
    assert(PIXEL_HAS_DEFAULT)
    assert(PIXEL_HAS_EQ)
    assert(PIXEL_HAS_HASH)
    assert(PIXEL_HAS_ORD)
    assert(PIXEL_HAS_DEBUG)
    assert(PIXEL_HAS_CLONE)
    assert(not PIXEL_IS_COPY)
    assert(NAME_HAS_DEFAULT)
    assert(NAME_HAS_CLONE)
    assert(not NAME_HAS_ORD)
    assert(ROLE_HAS_DISPLAY)
    assert(COPY_PAIR_IS_COPY)

    let red = Color { r: 255, g: 0, b: 0 }
    let red2 = Color { r: 255, g: 0, b: 0 }
    let blue = Color { r: 0, g: 0, b: 255 }
    assert(red == red2)
    assert(Color { r: 255, g: 0, b: 0 }.cmp(Color { r: 255, g: 0, b: 0 }) == 0)
    assert(Color { r: 0, g: 0, b: 255 }.cmp(Color { r: 255, g: 0, b: 0 }) < 0)
    assert(Color { r: 255, g: 0, b: 0 }.cmp(Color { r: 0, g: 0, b: 255 }) > 0)
    assert(Color { r: 255, g: 0, b: 0 }.hash_value() == Color { r: 255, g: 0, b: 0 }.hash_value())
    assert(Color { r: 255, g: 0, b: 0 }.hash_value() != blue.hash_value())
    assert(Color { r: 255, g: 0, b: 0 }.debug_str() == "Color { r: 255, g: 0, b: 0 }")

    let original = Color { r: 1, g: 2, b: 3 }
    let cloned = original.clone()
    assert(original.r == 1)
    assert(cloned == Color { r: 1, g: 2, b: 3 })

    let default_pixel = Pixel.default()
    assert(default_pixel.r == 0)
    assert(default_pixel.a == 0)

    let default_name = Name.default()
    assert(default_name.first == "")
    assert(default_name.last == "")
    assert(Name { first: "A", last: "B" }.clone().first == "A")

    let copied = CopyPair { x: 4, y: 5 }
    let copied2 = copied
    assert(copied.x == copied2.x)
    assert(copied.y == copied2.y)

    let wrapped = Wrap { leaf: Leaf { value: 10 } }
    let wrapped2 = wrapped.clone()
    assert(wrapped.leaf.value == 10)
    assert(wrapped2.leaf.value == 11)

    assert(Role.Admin.to_str() == "Admin")
    assert(Role.Member.to_str() == "Member")
    assert(PayloadRole.Admin(7).to_str() == "Admin")

    print("ok")
