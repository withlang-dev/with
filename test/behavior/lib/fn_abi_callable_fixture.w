@[repr(C)]
pub type Pair { a: i64, b: i64 }
impl Copy for Pair

impl Pair:
    move fn bounce(other: Pair): other

@[repr(C)]
pub type Large { a: i64, b: i64, c: i64, d: i64 }
impl Copy for Large

trait EchoLarge:
    fn echo(self: &Self, value: Large) -> Large: value

impl EchoLarge for Pair

trait ReadFirst:
    fn first(self: &Self) -> i64

impl ReadFirst for Pair:
    fn first: self.a

fn read_first(value: dyn ReadFirst): value.first()
fn with_dyn(cb: fn(dyn ReadFirst) -> i64, value: dyn ReadFirst): cb(value)

@[c_export("pair")]
fn pair(value: Pair): Pair { a: value.b, b: value.a }

@[c_export("large")]
fn large(value: Large): Large { a: value.d, b: value.c, c: value.b, d: value.a }

fn call_pair(cb: extern "C" fn(Pair) -> Pair, value: Pair): cb(value)
fn call_large(cb: extern "C" fn(Large) -> Large, value: Large): cb(value)
fn call_pointer(cb: extern "C" fn(*const Large) -> i64, value: *const Large): cb(value)

fn closure_pair(value: Pair):
    let cb: extern "C" fn(Pair) -> Pair = x => Pair { a: x.b, b: x.a }
    cb(value)

fn closure_large(value: Large):
    let cb: extern "C" fn(Large) -> Large = x => Large { a: x.d, b: x.c, c: x.b, d: x.a }
    cb(value)

fn with_large(cb: fn(Large) -> Large, value: Large): cb(value)
fn with_pair(cb: fn(Pair) -> Pair, value: Pair): cb(value)
fn named_with_large(value: Large): Large { a: value.d, b: value.c, c: value.b, d: value.a }

fn captured_large(value: Large):
    let delta = 11
    let cb: fn(Large) -> Large = x => Large { a: x.a + delta, b: x.b, c: x.c, d: x.d }
    cb(value)
