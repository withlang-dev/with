trait Friendly:
    fn greet(self: &Self) -> str:
        "hello"

type Robot { id: i32 }

impl Friendly for Robot

type Loud { id: i32 }

impl Friendly for Loud:
    fn greet(self: &Self) -> str:
        "LOUD"

trait Named:
    fn name(self: &Self) -> str
    fn label(self: &Self) -> str:
        self.name() ++ "!"

type Person { name_text: str }

impl Named for Person:
    fn name(self: &Self) -> str:
        self.name_text

trait Echo[T]:
    fn echo(self: &Self, value: T) -> T:
        value

type EchoI32 { marker: i32 }

impl Echo[i32] for EchoI32

fn test_default_trait_method_on_omitted_impl:
    let r = Robot { id: 7 }
    assert(r.greet() == "hello")

fn test_explicit_trait_method_override_wins:
    let loud = Loud { id: 1 }
    assert(loud.greet() == "LOUD")

fn test_default_trait_method_can_call_required_method:
    let p = Person { name_text: "Ada" }
    assert(p.label() == "Ada!")

fn test_generic_trait_default_method_uses_trait_args:
    let e = EchoI32 { marker: 1 }
    assert(e.echo(42) == 42)
