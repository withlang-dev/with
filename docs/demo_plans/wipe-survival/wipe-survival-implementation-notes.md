# 🎮 WIPE: SURVIVAL — Implementation Notes (With + C libs)

## 🎯 Goals (translated into engineering decisions)

* **Minimal code in With**
* **Max performance showcase**
* **Steam Deck ready**
* **Few dependencies, easy Conan install**

👉 Strategy:

> Use a *thin game loop + rendering library* in C
> Write **game logic, ECS-ish systems, and upgrades in With**

---

# 🧱 1. Library Stack (Conan-friendly)

## 🥇 Primary Choice (Best Balance)

### **raylib**

* Simple, immediate-mode style
* Built-in:

  * windowing
  * input (gamepad!)
  * rendering
  * audio (optional)
* Very easy `c_import`
* Available on Conan (`raylib/x.x.x`)

👉 This is **by far the best choice** for your goal.

---

## 🧠 Supporting Libraries

### Math (optional but nice)

* **cglm**
* Or just write your own minimal vec2 (probably easier)

### Random

* Use raylib’s `GetRandomValue` OR roll simple PRNG in With

---

## ❌ Avoid

* SDL2 (too low-level → more work)
* bgfx (too complex for demo)
* OpenGL directly (waste of time)

---

# ⚙️ 2. FFI Strategy in With

Your spec makes this very clean:

```with
use c_import("raylib.h", link: "raylib")
```

👉 No `unsafe` for calls — perfect for demo polish 

---

## Minimal bindings you’ll actually use

* `InitWindow`
* `WindowShouldClose`
* `BeginDrawing`, `EndDrawing`
* `ClearBackground`
* `DrawCircle`, `DrawRectangle`
* `GetFrameTime`
* `GetGamepadAxisMovement`
* `IsGamepadAvailable`

---

# 🧠 3. Core Architecture (Keep It Tiny)

## Data Layout (very With-idiomatic)

```with
type Enemy = {
    pos: Vec2,
    vel: Vec2,
    kind: EnemyKind,
}

type Player = {
    pos: Vec2,
    dir: Vec2,
}

type World = {
    enemies: Vec[Enemy],
    bullets: Vec[Bullet],
    player: Player,
}
```

👉 No ECS needed — keep it simple
👉 But still **data-oriented** (fits With philosophy)

---

# 🎮 4. Game Loop

```with
fn main:
    InitWindow(1280, 720, c"Wipe: Survival".ptr)

    var world = init_world()

    while not WindowShouldClose():
        let dt = GetFrameTime()

        update(world, dt)
        render(world)
```

---

# 🕹️ 5. Twin-Stick Input (Steam Deck)

```with
fn read_input() -> (Vec2, Vec2):
    let move = Vec2 {
        x: GetGamepadAxisMovement(0, LEFT_X),
        y: GetGamepadAxisMovement(0, LEFT_Y),
    }

    let aim = Vec2 {
        x: GetGamepadAxisMovement(0, RIGHT_X),
        y: GetGamepadAxisMovement(0, RIGHT_Y),
    }

    (move, aim)
```

👉 Normalize aim vector
👉 If aim is zero → don’t shoot

---

# 🔫 6. Shooting System

```with
fn update_player(world: &mut World, dt: f32):
    let (move, aim) = read_input()

    world.player.pos += move * speed * dt

    if aim.length() > 0.1:
        spawn_bullet(world, world.player.pos, aim)
```

---

# 👾 7. Enemy System

Keep it stupid simple:

```with
fn update_enemies(world: &mut World, dt: f32):
    for e in world.enemies:
        let dir = (world.player.pos - e.pos).normalize()
        e.pos += dir * speed * dt
```

---

# 💥 8. Rendering (raylib = easy win)

```with
fn render(world: &World):
    BeginDrawing()
    ClearBackground(BLACK)

    DrawCircle(world.player.pos.x, world.player.pos.y, 5, WHITE)

    for e in world.enemies:
        DrawCircle(e.pos.x, e.pos.y, 4, RED)

    EndDrawing()
```

👉 That’s literally enough for a working game

---

# 🪙 9. Upgrade System (Minimal)

No UI framework — just overlay text:

```with
type Upgrade =
    | FireRate
    | MultiShot
    | Speed

fn apply_upgrade(player: &mut Player, up: Upgrade):
    match up
        .FireRate => player.fire_rate *= 1.2
        .MultiShot => player.projectiles += 1
        .Speed => player.speed *= 1.1
```

---

# ⚡ 10. Performance Showcase Hooks

## Entity Stress

```with
if world.time > 60:
    spawn 10 enemies per second
```

👉 Aim for:

* 200+ enemies
* 500+ bullets

---

## Debug Overlay

```with
DrawText("Entities: {world.enemies.len32()}", 10, 10, 20, GREEN)
```

👉 This subtly shows:

* performance
* your language handling scale

---

# 🔁 11. Instant Restart (Important)

```with
fn reset(world: &mut World):
    *world = init_world()
```

No scene reload, no allocations beyond Vec reuse.

---

# 🧩 12. Conan Setup

Example `conanfile.txt`:

```
[requires]
raylib/4.5.0

[generators]
CMakeDeps
CMakeToolchain
```

Then:

```bash
conan install . --build=missing
```

---

# 🧠 13. What This Shows About With

Your implementation should highlight:

### ✔ Clean FFI

```with
InitWindow(...)
DrawCircle(...)
```

### ✔ No lifetime pain

* All gameplay code is clean
* No borrow hell

### ✔ Performance

* High entity count
* Smooth frame time

### ✔ Expressiveness

* `with` blocks for setup
* pattern matching for upgrades
* pipelines for processing

---

# 🏁 Final Architecture Summary

```
With code:
- game loop
- gameplay systems
- upgrades
- state

C (raylib):
- window
- input
- rendering
```

👉 Result:

> ~90% of the interesting code is in With
> ~10% is C plumbing (already done for you)