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

trait Builder:
    fn preview(self: &Self) -> str
    fn build(move self: Self) -> i32

type MealBuilder { seed: i32 }

impl Builder for MealBuilder:
    fn preview(self: &Self) -> str:
        if self.seed == 40:
            return "meal"
        "wrong"

    fn build(move self: Self) -> i32:
        self.seed + 2

fn preview_builder(b: &dyn Builder) -> str:
    b.preview()

fn test_ref_dyn_trait_allows_traits_with_consuming_methods:
    let builder = MealBuilder { seed: 40 }
    assert(preview_builder(&builder) == "meal")

fn test_box_dyn_trait_consuming_method_shim:
    let builder: Box[dyn Builder] = Box.new(MealBuilder { seed: 40 })
    assert(builder.build() == 42)
