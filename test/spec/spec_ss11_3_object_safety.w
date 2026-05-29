// Spec test: Section 11.3 - Object Safety.

var DRAW_TOTAL: i32 = 0

trait Drawable:
    fn draw(self: &Self)
    fn label(self: &Self) -> str

type Circle { id: i32 }

impl Drawable for Circle:
    fn draw(self: &Self):
        DRAW_TOTAL = DRAW_TOTAL + self.id

    fn label(self: &Self) -> str:
        "circle"

fn render(d: &dyn Drawable) -> str:
    d.draw()
    d.label()

fn test_ref_self_methods_are_object_safe:
    DRAW_TOTAL = 0
    let c = Circle { id: 7 }
    assert(render(&c) == "circle")
    assert(DRAW_TOTAL == 7)

trait Mutator:
    fn bump(mut self: Self)

type Counter { value: i32 }

impl Mutator for Counter:
    fn bump(mut self: Self):
        self.value = self.value + 1

fn accepts_mutator(_m: &dyn Mutator) -> i32:
    1

fn test_mut_self_methods_are_object_safe:
    var c = Counter { value: 1 }
    assert(accepts_mutator(&c) == 1)

// Consuming `move self: Self` through Box[dyn Trait] is tracked separately by
// #202 because the standard Box[T] type and Box[dyn Trait] shims do not exist yet.
