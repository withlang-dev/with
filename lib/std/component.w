// std.component — ECS component identity helpers.

/// Stable component identity. `@[derive(ComponentId)]` generates a
/// `component_id() -> i64` method from the component type name.
pub trait ComponentId =
    fn component_id() -> i64
