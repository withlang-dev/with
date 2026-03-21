# 🎮 WIPE: SURVIVAL — Implementation Notes

---

# 🧭 1. Core Philosophy

## Hard constraints

1. **All control flow is written in With**
2. **All game state and logic live in With**
3. **C libraries are used only for platform capabilities**
4. **No platform-specific APIs (e.g., Win32) are used directly**

---

## Architectural statement

> With = the game
> C libraries = the machine

---

# 🧱 2. Dependencies

## 🎮 Graphics / Input / Audio

### **raylib**

Used for:

* window creation
* rendering (2D primitives)
* input (keyboard + controller → Steam Deck)
* audio playback (sound + music)
* frame timing

---

## 🧩 Platform / Distribution

### **Steamworks SDK**

Used for:

* achievements
* stats / progression tracking
* Steam overlay
* Steam Deck integration
* application lifecycle (running under Steam)

---

## ❌ No other dependencies

* no SDL (raylib already uses it internally)
* no Box2D (physics not needed)
* no Win32 / POSIX APIs directly
* no additional audio or rendering libraries

---

# ⚙️ 3. FFI Model (With Design Showcase)

Both libraries are imported via:

```with id="ff4g9e"
use c_import("raylib.h", link: "raylib")
use c_import("steam/steam_api.h", link: "steam_api")
```

---

## Design goal

> C functions should feel like native With functions

This directly demonstrates your language principle:

* no boilerplate FFI layers
* no unsafe noise
* no wrapper explosion

---

# 🧱 4. Responsibility Split

## raylib handles

* window lifecycle
* drawing primitives
* input polling
* audio playback
* frame timing

---

## Steamworks handles

* achievements & stats
* overlay
* Steam Deck runtime environment
* platform integration

---

## With handles

* game loop
* world state
* gameplay systems
* spawning / difficulty scaling
* upgrades
* rendering orchestration

---

# 🎮 5. Game Loop (Owned by With)

```with id="p5x6hz"
fn main:
    InitWindow(1280, 720, c"Wipe: Survival".ptr)
    InitAudioDevice()
    SteamAPI_Init()

    var world = init_world()

    while not WindowShouldClose():
        SteamAPI_RunCallbacks()

        let dt = GetFrameTime()
        let input = read_input()

        update(world, input, dt)

        BeginDrawing()
        ClearBackground(BLACK)
        render(world)
        EndDrawing()
```

---

## Key point

> The game loop is pure With
> No control flow delegated to C

---

# 🕹️ 6. Input System (raylib → With)

## Immediate translation

```with id="uvd6s5"
type Input = {
    move: Vec2,
    aim: Vec2,
}

fn read_input() -> Input:
    Input {
        move: Vec2 {
            x: GetGamepadAxisMovement(0, LEFT_X),
            y: GetGamepadAxisMovement(0, LEFT_Y),
        },
        aim: Vec2 {
            x: GetGamepadAxisMovement(0, RIGHT_X),
            y: GetGamepadAxisMovement(0, RIGHT_Y),
        }
    }
```

---

## Rule

> Input becomes a With value immediately

---

# 🔫 7. Gameplay Systems (Pure With)

## Player

```with id="8xw9wz"
fn update_player(world: &mut World, input: &Input, dt: f32):
    world.player.pos += input.move * SPEED * dt

    if input.aim.length() > 0.1:
        spawn_bullet(world, world.player.pos, input.aim)
```

---

## Enemies

```with id="tq3x3k"
fn update_enemies(world: &mut World, dt: f32):
    for e in world.enemies:
        let dir = (world.player.pos - e.pos).normalize()
        e.pos += dir * e.speed * dt
```

---

## Collision (no physics engine)

```with id="0mrbk2"
fn collide(a: Vec2, b: Vec2, r: f32) -> bool:
    (a - b).length_sq() < r * r
```

---

# 💥 8. Rendering (raylib primitives, With control)

```with id="4kpprh"
fn render(world: &World):
    DrawCircle(world.player.pos.x, world.player.pos.y, 5, WHITE)

    for e in world.enemies:
        DrawCircle(e.pos.x, e.pos.y, 4, RED)
```

---

## Rule

> Rendering decisions are With logic
> Drawing is delegated to raylib

---

# 🔊 9. Audio (raylib)

## Initialization

```with id="q4g3s1"
InitAudioDevice()
```

---

## Usage

```with id="6onrpn"
let shoot = LoadSound(c"shoot.wav".ptr)

fn fire():
    PlaySound(shoot)
```

---

## Music

```with id="j6yyq0"
let music = LoadMusicStream(c"music.ogg".ptr)
PlayMusicStream(music)

fn update_audio():
    UpdateMusicStream(music)
```

---

## Design goal

> Audio logic stays trivial and event-driven

---

# 🏆 10. Steam Integration (Steamworks)

## Initialization

```with id="r3t7m2"
fn init_steam():
    if not SteamAPI_Init():
        println("Steam not running")
```

---

## Per-frame

```with id="q3z0e1"
fn update_steam():
    SteamAPI_RunCallbacks()
```

---

## Achievements

```with id="q23o2i"
fn unlock(name: &str):
    let stats = SteamUserStats()
    stats.SetAchievement(name)
    stats.StoreStats()
```

---

## Usage example

```with id="8q1eow"
if world.kills > 100:
    unlock("KILL_100")
```

---

## Design goal

> Steam integration is minimal, explicit, and unobtrusive

---

# ⚡ 11. What This Demonstrates About With

This architecture intentionally showcases:

---

## ✔ FFI simplicity

```with id="7c7z6k"
DrawCircle(...)
PlaySound(...)
SteamAPI_RunCallbacks()
```

No wrappers required.

---

## ✔ Real-time control

```with id="v7ifwn"
while not WindowShouldClose():
```

No runtime or framework dependency.

---

## ✔ Data-oriented design

```with id="q9c6hf"
for e in world.enemies:
    e.pos += e.vel * dt
```

---

## ✔ Clear boundaries

* With = logic
* C = capabilities

---

# 🚨 12. Failure Signals (Design Bugs)

If you encounter:

---

## ❌ C types in game state

```with id="8v9n55"
Vector2   // from raylib
```

👉 should be:

```with id="slf6bq"
Vec2
```

---

## ❌ Game logic tied to C calls

👉 indicates poor boundary

---

## ❌ Need to move logic into C

👉 critical failure for language design

---

## ❌ Excessive wrappers

👉 FFI is not ergonomic enough

---

# 🏁 13. Final Summary

## Dependencies

* raylib → platform (graphics/input/audio)
* Steamworks → platform (Steam features)

---

## Ownership

* With owns **everything that matters**
* C libraries provide **only capabilities**

---

## Outcome

> A complete, real-time, Steam-ready game
> written almost entirely in With
> with minimal, seamless C interop
