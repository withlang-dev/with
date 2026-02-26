# Falling With Style — Game Design Specification

**Genre:** Physics Survivors / Horde Defense
**Platform:** Steam Deck (primary), PC (secondary)
**Engine:** Custom — built in the With programming language
**Physics:** Box2D v3 (C API via `c_import`)
**Renderer:** SDL3 + SDL3_image + SDL3_gpu (2D sprite-based)
**Audio:** SDL3_mixer
**Input:** Steam Input API (gyro, trackpads, touchscreen, grip buttons), gamepad, keyboard
**Target:** 60fps with 2,000+ active rigid bodies on Steam Deck

---

## 1. Elevator Pitch

You control gravity. They don't.

You're a little maintenance robot in a space station that's been
overrun by malfunctioning drones. Tilt your Steam Deck to change
the direction of gravity across the entire arena. Enemies tumble,
slide, pile up, and ragdoll. Place physics hazards — ramps, walls,
bumpers, pits — to build kill zones, then tilt the world to pour
enemies into them.

It's Vampire Survivors meets a marble maze, in space.

---

## 2. Core Loop

```
Every 0.016s (60fps):
    1. Read gyro → update world gravity vector
    2. Spawn enemy wave (escalating)
    3. Step physics (Box2D)
    4. Check damage (enemy-trap collisions, crush damage, fall damage)
    5. Collect XP cores from kills
    6. Level up → choose upgrade
    7. Render
```

A run lasts 15–30 minutes. Difficulty escalates continuously.
The player survives as long as possible. Death ends the run.
Meta-progression unlocks new trap types and passive abilities
between runs.

---

## 3. Controls

### 3.1 Steam Deck (Primary)

**Movement and gravity:**

| Input | Action |
|-------|--------|
| Gyro (accelerometer) | Control gravity direction and magnitude |
| Left stick | Move player character |
| R2 (analog trigger) | Amplify gravity — light pull = 1.5×, full pull = 2.5×, past click = 3× burst |

**Trap placement:**

| Input | Action |
|-------|--------|
| Touchscreen tap | Place selected trap at tap location |
| Left trackpad (radial) | Select trap type — slide thumb in a direction, each segment = one trap type (up to 8). Haptic click on segment boundaries for eyes-free selection |
| R4 (back grip) | Quick-place last trap type at player position (panic button) |

**Gravity abilities:**

| Input | Action |
|-------|--------|
| L4 (back grip) | Gravity slam — instant max gravity in current tilt direction (10s cooldown) |
| L5 (back grip) | Gravity flip — instant 180° reversal of gravity direction (separate cooldown) |
| R5 (back grip) | Gravity lock — hold to freeze gravity direction while repositioning the Deck |
| X button | Activate special ability (unlocked abilities) |

**Haptic feedback (right trackpad motor):**

The right trackpad is used as a haptic feedback channel, not an
input. It encodes gravity state as vibration:

- Idle: silent
- Light tilt: gentle purr (low frequency, low amplitude)
- Strong tilt: aggressive rumble (high frequency, high amplitude)
- Gravity amplify (R2): motor revs up proportional to trigger pull
- Gravity slam (L4): sharp heavy pulse on activation
- Enemy fall-damage kill: quick directional tick (you feel the
  impact through your thumb)

This gives a tactile sense of gravity force even when the screen
is too chaotic to read the visual indicators.

**Gyro dampening on touch:**

When the touchscreen registers a tap, gyro input is dampened for
~100ms to prevent the physical act of touching the screen from
jerking the gravity direction. Without this, every trap placement
will feel bad and players won't know why.

**Gravity control details:**

The accelerometer provides a 2D gravity vector. The Steam Deck's
physical orientation maps directly to the in-game gravity direction.

- Deck flat → gravity points down (normal)
- Deck tilted left → gravity pulls left
- Deck tilted forward → gravity pulls up-screen
- Full inversion → gravity reverses

The magnitude is proportional to tilt angle. Gentle tilt = gentle
slope. Full tilt = freefall sideways. This gives fine-grained
analog control.

**Sensitivity curve:**

```
tilt_angle = atan2(accel.x, accel.y)
tilt_magnitude = clamp(length(accel.xy) / 9.81, 0.0, 1.0)

// Dead zone: ignore tiny tilts (holding Deck naturally)
if tilt_magnitude < 0.08:
    tilt_magnitude = 0.0

// Exponential curve for precision at low tilt, power at high tilt
effective = tilt_magnitude ^ 1.4

gravity = normalize(tilt_direction) * effective * MAX_GRAVITY
```

`MAX_GRAVITY` default: 30 m/s². Normal earth gravity (9.81) is the
baseline. Fully tilting gives ~3x earth gravity.

**Why back grip buttons work here:** All four grip buttons (L4, L5,
R4, R5) are operated by fingers already resting on the back of the
Deck. They require zero hand repositioning. You can tilt, move with
the left stick, amplify with R2, and hit a grip button simultaneously.
These are the most underused inputs on the Deck because most games
don't know they exist.

### 3.2 PC Fallback

| Input | Action |
|-------|--------|
| Mouse position (relative to player) | Gravity direction + magnitude |
| WASD | Move player |
| Left click | Place trap at cursor position |
| Right click | Cycle trap type |
| Space | Special ability |
| Shift (hold) | Lock gravity |
| Ctrl (hold) | Amplify gravity |
| Q / E | Gravity slam / gravity flip |
| 1–8 keys | Direct trap type selection |

Mouse-controlled gravity: direction from player to cursor sets
gravity direction. Distance from player to cursor sets magnitude
(close = weak, far = strong).

PC players get cursor-based trap placement for free since they
already have a mouse cursor on screen. This makes PC feel natural
even without the touchscreen and trackpad.

### 3.3 Accessibility

- Configurable dead zones and sensitivity curves
- Option to invert gravity axes independently
- Option to use right stick instead of gyro
- Option to lock gravity to 8 cardinal directions (digital mode)
- Colorblind-safe palette for all gameplay-critical elements
- Option to disable touchscreen placement (use cursor/stick instead)
- Haptic intensity slider (including off)

---

## 4. The Arena

### 4.1 Structure

The arena is a sealed section of the space station — a bounded 2D
space with bulkhead walls on all four sides. GV-7 and all drones
exist within this section. The walls are indestructible hull plating.

**Arena size:** ~40x30 meters (Box2D units). Camera shows the
full arena at all times (no scrolling). This keeps the cognitive
load on "manage the whole space" rather than "explore."

### 4.2 Terrain

The arena contains static geometry that interacts with physics:

- **Platforms** — metal grating surfaces enemies can stand/slide on
- **Ramps** — angled hull plating that redirects falling enemies
- **Pits** — gaps with kill zones at the bottom (plasma vents, crushers)
- **Pillars** — structural columns that split enemy flow
- **Funnels** — V-shaped bulkhead geometry that concentrates enemies

The terrain layout varies per run (procedurally selected from
hand-designed chunks). Terrain is destructible at higher
difficulty tiers — certain enemies can break platforms.

### 4.3 Procedural Arena Composition

Each run selects a layout from a pool of hand-authored arena
templates. Templates define:

- Wall and platform geometry (static Box2D bodies)
- Pit locations and kill zone types
- Spawn point locations (edges where enemies enter)
- Player start position

Templates are categorized by difficulty and unlock progressively
through meta-progression. Early templates have simple geometry
(flat floor, one pit). Late templates have complex multi-level
structures with ramps, funnels, and floating platforms.

---

## 5. Player Character

### 5.1 Properties

**GV-7 ("Gee")** — a chunky little maintenance robot. Spherical
body, stubby magnetized legs, single large eye, expressive antenna.
Built for station repair, accidentally became the only thing
standing between the station and total drone malfunction.

| Property | Value |
|----------|-------|
| Shape | Circle, radius 0.5m |
| Mass | 10 kg (heavy — mag-boots resist gravity changes) |
| Movement | Direct velocity control (not force-based) |
| Speed | 8 m/s base |
| Health | 100 base (shield charge) |
| Gravity response | Reduced (0.3x world gravity) |

The player is a physics body but is only partially affected by
gravity changes. This is critical — the player must be able to
navigate while enemies tumble. The 0.3x factor means GV-7 slides
slightly when gravity shifts (which feels good) but isn't
helplessly thrown around. The lore justification: mag-boots and
internal stabilizers.

**Visual expressiveness (no facial animation needed):**

- Antenna points in current gravity direction (doubles as a
  gameplay indicator)
- Eye widens when enemies are close, narrows when safe
- Legs scramble comically when sliding on a surface
- Body tilts opposite to movement direction (leans into the walk)
- Small thruster puffs when changing direction
- Eye blinks occasionally during calm moments

This is important: the character communicates state through body
language alone. Works at 32×32 pixel scale because the silhouette
reads clearly — round body, pointy antenna, two stubby legs.

**Playtest note:** The sweet spot between "heavy but not helpless"
is razor-thin. Test 0.25× and 0.35× aggressively. Additionally,
add a small **inertia dampener** to the player — when the gravity
direction changes, apply a brief counter-force (decaying over
~0.2s) so direction reversals don't feel sticky. The dampener
shouldn't eliminate the slide, just soften the jerk on reversal.

### 5.2 Damage Model

The player takes damage from:

- Enemy contact (per-enemy damage, with brief invincibility frames)
- Crushing (pinned between enemies and a wall at high gravity)
- Environmental hazards (plasma pits, if player falls in)

The player does NOT take fall damage (enemies do). GV-7 is built
to survive impacts. The drones are not.

### 5.3 Health and Recovery

- Shield charge regenerates slowly (1 hp/s base)
- XP cores restore small amounts of charge (2 hp each)
- Upgrade options can increase regen, max charge, or add barriers

---

## 6. Enemies

### 6.1 Core Enemy Properties

All enemies are malfunctioning drones — Box2D rigid bodies with
full physics simulation. They have mass, friction, restitution
(bounciness), and respond to gravity. They want to reach GV-7
and discharge into it. They don't know gravity is about to ruin
their day.

| Property | Meaning |
|----------|---------|
| Mass | How hard they are to move with gravity |
| Friction | How much they grip surfaces |
| Restitution | How much they bounce |
| Shape | Circle or convex polygon |
| HP | How much damage before death |
| Contact damage | Damage dealt to player on touch |
| XP value | Cores dropped on death |

### 6.2 Damage From Physics

Enemies take damage from physics interactions. This is the core
damage model — the player kills enemies by using gravity and
traps, not direct weapons.

| Source | Damage formula |
|--------|---------------|
| Fall damage | `velocity_at_impact² × 0.1` |
| Crush (pinned) | `force_on_body × 0.05` per frame |
| Trap collision | Trap-specific (see §7) |
| Enemy-enemy collision | `relative_velocity² × 0.02` (high speed only) |
| Kill zone (pit) | Instant kill |

Fall damage is the primary kill mechanism. Tilt the world, enemies
fall sideways into a wall at 20 m/s, take 40 damage. Stack enemies
on top of each other with gravity, bottom ones get crushed.

### 6.3 Enemy Types

**Tier 1 — Fodder (minutes 0–5):**

| Type | Mass | HP | Behavior | Visual |
|------|------|----|----------|--------|
| Blobber | 2 kg | 20 | Roll toward player | Spherical gel-drone, high restitution (bouncy), wobbles and deforms on impact |
| Junkbot | 5 kg | 40 | Walk toward player | Cobbled-together scrap drone, low friction (slides easily), limbs flail when tumbling |

**Tier 2 — Sturdy (minutes 3–10):**

| Type | Mass | HP | Behavior | Visual |
|------|------|----|----------|--------|
| Loader | 20 kg | 120 | Slow walk | Heavy industrial drone, cubic, low restitution (thud), dents on impact |
| Hover Drone | 1 kg | 15 | Fly (reduced gravity response) | Small quad-rotor, buzzes, high friction on contact |
| Clinger | 3 kg | 30 | Wall-cling (high friction) | Spider-like repair drone, grips surfaces with mag-legs, resists sliding |

**Tier 3 — Threats (minutes 8–20):**

| Type | Mass | HP | Behavior | Visual |
|------|------|----|----------|--------|
| Breacher | 15 kg | 200 | Charge toward player | Armored security drone, battering ram head, destroys traps on contact |
| Phase Drone | 0.5 kg | 60 | Phase through platforms | Translucent holographic shell, only solid near player, flickers |
| Detonator | 8 kg | 50 | Walk toward player, explode on death | Blinking red warning light, explosion applies radial impulse to nearby enemies |

**Tier 4 — Elites (minutes 15+):**

| Type | Mass | HP | Behavior | Visual |
|------|------|----|----------|--------|
| Colossus | 100 kg | 800 | Slow, creates gravity well on death | Enormous cargo drone, other enemies orbit it, screen shakes when it lands |
| Anchor | 50 kg | 400 | Immune to gravity changes | Walks steadily regardless of tilt. Gyroscopic stabilizer rings on its body that stay level no matter the tilt angle — visible from across the arena so players immediately understand this drone plays by different rules |
| Hive Core | 10 kg | 150 | Spawns Blobbers continuously | Pulsing factory drone, must be killed to stop spawn, glows brighter as it produces |

**Bosses (every 5 minutes):**

Mini-boss waves. Single large enemy with unique physics mechanics:

- **The Wrecking Ball** (min 5): Giant sphere drone, extremely
  heavy, rolls with gravity. Player must trap it in a pit.
  **Hard design rule:** The Wrecking Ball MUST be beatable with
  only starter traps (Spike Strip + Bumper + Wall) and basic tilt.
  No unlocks required. If a new player who understands the core
  mechanic can't kill this boss, the game's retention dies here.
- **The Chain Gang** (min 10): Group of drones connected by
  energy tethers (Box2D distance joints). Must break the chain
  by pulling them apart with alternating gravity.
- **The Pendulum** (min 15): Drone on a revolute joint,
  swings with gravity. Destroys terrain it hits. Wrecking ball
  on a cosmic string.
- **The Inverter** (min 20): Reverses gravity for itself.
  Falls upward. Completely disorienting. Its own gravity field
  is visible as a shimmering bubble.

### 6.4 Spawning

Enemies spawn from the arena edges. Spawn rate escalates:

```
enemies_per_second = base_rate × (1 + minutes_elapsed × 0.15)

// minute 0:  2/sec
// minute 5:  3.5/sec
// minute 10: 5/sec
// minute 15: 6.5/sec
// minute 20: 8/sec
// minute 25: 9.5/sec (screen is chaos)
```

Composition shifts toward higher tiers over time. By minute 20,
most spawns are Tier 3+ with Tier 1 as filler.

### 6.5 Enemy AI

Most enemies have trivial AI: move toward player position. The
interesting behavior comes from physics — they get interrupted by
gravity changes, pile up on surfaces, block each other, and chain-
react when hit.

```
fn update_enemy(enemy: &mut Enemy, player_pos: Vec2, dt: f32) =
    let direction = normalize(player_pos - enemy.position)
    let move_force = direction * enemy.move_strength

    // Apply movement force (fighting against gravity)
    enemy.body.apply_force(move_force)

    // That's it. Physics handles the rest.
```

The emergent behavior from simple AI + full physics is the game.
Enemies pile up at walls, form bridges over pits, push each other
off ledges, and create organic formations. This is what makes
gravity control interesting — you're manipulating emergent
physics behavior, not solving puzzles.

---

## 7. Traps (Player Abilities)

Traps are the player's primary tool for converting gravity into
damage. The player places them in the arena and they persist.

### 7.1 Trap Placement

- Player selects a trap type (radial selector on left trackpad,
  or d-pad cycle)
- Tap touchscreen at desired location to place the trap
- Alternatively: R4 back grip to quick-place at player position
- Trap appears as a static or kinematic Box2D body
- Each trap has a cooldown before another can be placed
- Maximum active traps per type (typically 3–5)
- Oldest trap despawns when limit is exceeded

### 7.2 Trap Types

**Starter traps (always available):**

| Trap | Physics | Damage | Notes |
|------|---------|--------|-------|
| Spike Strip | Static sensor | 30 on contact | Flat, enemies slide over it |
| Bumper | Static body, restitution 2.0 | 10 + launch | Bounces enemies away hard |
| Wall Segment | Static body | 0 (blocking) | Creates surfaces for enemies to smash into |

**Unlockable traps (meta-progression):**

| Trap | Physics | Damage | Notes |
|------|---------|--------|-------|
| Ramp | Static angled body | 0 (redirect) | Redirects falling enemies |
| Funnel | V-shaped static bodies | 0 (concentrate) | Funnels enemies to a point |
| Grinder | Kinematic rotating body | 50/s contact | Spinning hazard, destroys enemies that fall in |
| Magnet | Radial force field | 0 (pull) | Attracts enemies toward center (combine with pit) |
| Explosive Barrel | Dynamic body | 200 in radius | Detonates on heavy impact, applies impulse |
| Conveyor | Kinematic body, surface velocity | 0 (move) | Pushes enemies along its surface |
| Pendulum | Revolute joint + heavy body | Impact-based | Swings with gravity, smashes enemies |
| Black Hole | Radial force + sensor | 5/s | Slowly pulls and compresses enemies into a point |

### 7.3 Trap Synergies

The fun comes from combining traps with gravity:

- Funnel above a Grinder → tilt to pour enemies into it
- Magnet near a pit → hold enemies over the edge, then slam gravity
- Explosive Barrel on a Ramp → tilt to roll barrel into enemy cluster
- Bumper chain → pinball enemy bouncing between bumpers at high gravity
- Wall + Spike Strip → enemies smash into wall, slide down onto spikes
- Conveyor into Black Hole → automated enemy disposal

### 7.4 Trap Physics Details

Traps are Box2D bodies with special collision categories:

```
CATEGORY_PLAYER     = 0x0001
CATEGORY_ENEMY      = 0x0002
CATEGORY_TRAP       = 0x0004
CATEGORY_TERRAIN    = 0x0008
CATEGORY_PICKUP     = 0x0010
CATEGORY_KILL_ZONE  = 0x0020

// Enemies collide with: terrain, traps, other enemies, kill zones
// Player collides with: terrain, enemies (for damage)
// Traps collide with: enemies
// Pickups collide with: player only
```

---

## 8. Progression

### 8.1 In-Run Progression (XP and Levels)

Killed enemies drop XP cores. Cores are small physics bodies that
roll with gravity (this is important — they slide toward the
player when gravity favors it, creating a satisfying cascade of
pickups after a big kill).

```
XP per level: 10 × level (level 1 = 10xp, level 10 = 100xp)
```

On level up, the player chooses one of three random upgrades.

### 8.2 Upgrade Categories

**Gravity upgrades:**

| Upgrade | Effect |
|---------|--------|
| Heavy Gravity | +20% max gravity force |
| Gravity Surge | Amplify (R2) gives 3x instead of 2x |
| Tidal Force | Gravity changes apply a shockwave impulse |
| Orbital | Enemies near player orbit instead of falling |
| Sticky Gravity | Gravity changes smoothly (less chaotic, more control) |
| Volatile Gravity | Gravity changes instantly (more chaotic, more damage) |

**Trap upgrades:**

| Upgrade | Effect |
|---------|--------|
| Extra Traps | +2 max traps of selected type |
| Trap Size | Traps are 50% larger |
| Overcharged | Traps deal 2x damage |
| Chain Reaction | Explosive barrels trigger nearby barrels |
| Magnetic Traps | Traps pull nearby enemies slightly |

**Player upgrades:**

| Upgrade | Effect |
|---------|--------|
| Mag-Boot Override | Player gravity response 0.15x (more stable) |
| Thruster Boost | +20% movement speed |
| Shield Regen | +2 hp/s |
| Deflector | Absorb one hit every 10 seconds |
| Core Magnet | XP cores attracted from further away |
| Ballast Module | Player mass +50% (push through enemies) |

**Special upgrades (rare, game-changing):**

| Upgrade | Effect |
|---------|--------|
| Hull Breach | Gravity changes crack terrain, creating new pits |
| Zero-G Zone | Area around player has zero gravity (enemies float helplessly) |
| Gravity Bomb | On cooldown: slam gravity to max in random direction |
| Ricochet Plating | Enemies that hit walls bounce back at 2x speed |

### 8.3 Meta-Progression (Between Runs)

**Currency: Grav-Shards** — glowing blue-white crystals that tumble
with gravity on the shop screen. Earned continuously during a run,
paid out at death (or run completion).

```
shards_per_minute = 40 + (minutes_elapsed × 12)
  + (peak_enemy_count / 10)           // bonus for surviving swarms
  + (gravity_kills × 0.25)            // fall/crush/pit kills reward
```

A strong 18-minute run earns roughly 1,200–1,800 shards. A quick
4-minute death earns ~300. Even the worst run gives at least 150.
Never punish the player for learning.

**The Bank:** Unspent shards roll over between runs. No wasted
currency, no "I have 47 shards and nothing to buy" frustration.
Players can save up for big-ticket items across multiple runs.

**Post-Death Flow:**

1. Slow-mo replay of the run's best kill (highest velocity impact
   or biggest pile-up)
2. Fade to **Grav-Shard Forge** (the shop)
3. Player buys what they want (or banks shards)
4. One button: **"Drop Again"** → next run starts

The entire death-to-next-run loop must take under 30 seconds if
the player doesn't want to browse.

**Permanent Unlocks (one-time purchases):**

All Tier 1 unlocks cost the same (500 shards) so the player's
first decision is *which* upgrade, not *which can I barely afford.*
Price differentiation starts at Tier 2.

**Tier 1 — First Deaths (500 shards each):**

| Unlock | Effect |
|--------|--------|
| Extra Trap Slot | +1 max trap of every type |
| Heavier Tilt | Base max gravity +15% |
| Iron Soles | Player gravity response reduced to 0.20× (mag-boot upgrade) |
| Core Magnet | XP cores have 30% stronger gravity pull toward player |

**Tier 2 — Getting Comfortable (800–1,200 shards):**

| Unlock | Cost | Effect |
|--------|------|--------|
| Unlock Ramp | 800 | New trap type: Ramp |
| Unlock Funnel | 850 | New trap type: Funnel |
| Unlock Grinder | 1,200 | New trap type: Grinder |
| Starter Trap Bundle | 1,000 | Begin every run with 1 Spike Strip + 1 Bumper pre-placed |

**Tier 3 — Invested (1,500–2,500 shards):**

| Unlock | Cost | Effect | Prereq |
|--------|------|--------|--------|
| Unlock Magnet | 1,800 | New trap type: Magnet | Unlock Funnel |
| Unlock Explosive Barrel | 2,000 | New trap type: Explosive Barrel | — |
| Unlock Conveyor | 1,950 | New trap type: Conveyor | — |
| Arena Pack 1 | 1,600 | +3 new arena templates | Survive 10 min once |
| Colossus Slayer | 2,500 | All elite enemies take +25% physics damage | — |

**Tier 4 — Mastery (2,800–3,500 shards):**

| Unlock | Cost | Effect | Prereq |
|--------|------|--------|--------|
| Unlock Pendulum | 3,200 | New trap type: Pendulum | Unlock Grinder |
| Unlock Black Hole | 3,500 | New trap type: Black Hole | Unlock Magnet |
| Arena Pack 2 | 3,000 | +4 complex multi-level arenas | Survive 15 min once |

**Tier 5 — Endgame (4,800–7,000 shards):**

| Unlock | Cost | Effect | Prereq |
|--------|------|--------|--------|
| Zero-G Mastery | 5,500 | Adds Zero-G Zone to the rare upgrade pool | — |
| Physics God | 6,000 | Global physics damage multiplier +20% | Survive 20 min once |
| The Anchor (character) | 7,000 | Playable character with 0.0× gravity response (completely stable, different playstyle) | — |

**Design principles for the shop:**

- Prioritize unlocks that change what you *do* (new trap types,
  new arenas, new characters) over unlocks that change numbers.
- The first 3–4 purchases should be obvious power spikes so new
  players feel the system working immediately.
- No temporary boosters. Every shard spent is a permanent
  investment. Every death moves you forward. No way to waste a run.

---

## 9. Visual Style

### 9.1 Art Direction

**Chunky pixel art, 32×32 base sprites. Sci-fi space station
aesthetic with a bright, saturated palette.**

Think: abandoned space station meets toy box. Clean metal surfaces,
glowing plasma vents, exposed wiring, warning stripes — but all
rendered in chunky, friendly pixel art. Nothing grimdark. The
station is dangerous but the robots are cute.

**Color language:**

- **Player (GV-7):** Bright cyan body, warm orange eye. Always
  pops against any background. The antenna tip glows white.
- **Tier 1 enemies:** Green spectrum (lime Blobbers, olive Junkbots)
- **Tier 2 enemies:** Yellow-orange spectrum (amber Loaders, yellow
  Hover Drones, orange Clingers)
- **Tier 3 enemies:** Red spectrum (crimson Breachers, magenta Phase
  Drones, scarlet Detonators with blinking warning light)
- **Tier 4 enemies:** Purple/white (Colossus glows purple, Anchor
  has white stabilizer rings, Hive Core pulses violet)
- **Bosses:** Unique palette per boss, larger sprites (64×64 or 96×96)
- **Traps:** Metallic grey with colored accents matching their
  function (red for damage, blue for physics, yellow for area)
- **XP cores:** Bright electric blue, high contrast against
  everything. Small glowing hexagons.
- **Terrain:** Muted steel grey and dark blue. Never competes with
  gameplay elements for attention.

**The visual priority is readability at high entity counts.** When
500 drones are on screen, the player must instantly distinguish:

- Enemies (by type/tier — color coded by temperature)
- Traps (distinct silhouettes, metallic)
- Terrain (muted background)
- XP cores (bright blue, always visible)
- GV-7 (cyan + orange, never lost in the crowd)

**Character animation principles:**

All robots communicate through body language, not faces:

- GV-7's antenna points toward gravity direction
- Enemy drones lean into their movement, flail when tumbling
- Destroyed drones burst into component parts (screws, bolts,
  plating) that are themselves physics bodies for a brief moment
  before fading — this creates satisfying debris cascades
- Blobbers deform on every surface contact (squash and stretch)
- Junkbots lose limb-pieces as they take damage
- Loaders leave dent sprites on walls they impact

### 9.2 Camera

Fixed camera showing the entire arena. No scrolling, no zoom.
The arena is always fully visible. This is essential for the
gravity mechanic — the player needs to see where enemies will
fall when they tilt.

Subtle camera effects:

- Screen shake on heavy impacts (scaled by impact force)
- Camera tilts slightly to match gravity direction (2-3 degrees max)
- Slight zoom pulse on level-up

### 9.3 Visual Feedback for Gravity

Critical: the player must always know the gravity direction.

- **Arrow indicator** — large, semi-transparent holographic arrow
  showing gravity direction and magnitude, always visible at screen
  center
- **Particle dust** — ambient debris particles drift in gravity
  direction
- **Drone lean** — enemies tilt toward gravity (visual only)
- **Background parallax** — subtle starfield/station exterior layer
  shifts opposite to gravity, reinforcing the tilt feeling
- **XP core behavior** — cores sliding and rolling in gravity
  direction provides constant ambient feedback

### 9.4 Juice

| Event | Effect |
|-------|--------|
| Enemy death | Drone pops into component debris, 3–5 sparks, XP cores fly out |
| High-speed impact | Flash white, screen shake (proportional to velocity) |
| Crush kill | Crumple animation, sparks spray from crush point |
| Pit kill | Plasma flare / electrical discharge from pit type |
| Level up | Flash, brief slowdown (100ms), upgrade UI |
| Boss spawn | Screen darkens briefly, klaxon warning, alert text |
| Gravity slam (L4) | Radial pulse wave, everything accelerates, heavy haptic pulse |
| Gravity flip (L5) | Brief inversion flash, all particles reverse, sharp haptic tick |

### 9.5 UI

**HUD (always visible):**

- Shield charge bar (top left)
- XP bar (bottom, full width, thin)
- Current trap + count (bottom right)
- Gravity direction indicator (center, subtle holographic)
- Timer (top right)
- Kill counter (top right, below timer)
- Active trap count (bottom right, per type)

**Upgrade screen (on level up):**

- Three cards, horizontally arranged
- Brief game pause (enemies freeze mid-physics)
- Cards show: icon, name, one-line description
- Player picks one (d-pad or stick + A)
- Game resumes immediately

---

## 10. Audio

### 10.1 Music

Escalating electronic/synthwave soundtrack. Space station ambience
underneath.

- Minutes 0–5: Calm, ambient, low hum of the station, building anticipation
- Minutes 5–10: Driving beat kicks in, synth layers
- Minutes 10–15: Intensity increases, distorted bass, alarm tones woven in
- Minutes 15+: Full chaos mode, aggressive track
- Boss: Klaxon stinger + boss theme

Music tempo can subtly sync with enemy spawn rate.

### 10.2 Sound Effects

| Sound | Trigger |
|-------|---------|
| Metallic thud (pitch varies with mass) | Drone hits surface |
| Crackle/pop | Drone destroyed |
| Crunch | Crush kill |
| Electrical zap | Plasma pit kill |
| Boing | Bumper hit |
| Whoosh | Gravity direction change (proportional to delta) |
| Rumble (low freq) | Gravity amplify (R2 analog pull) |
| Slam (percussive) | Gravity slam (L4) |
| Ping | XP core pickup |
| Fanfare (short) | Level up |
| Klaxon | Boss incoming |

Physics-driven audio: impact sounds pitch-shift based on collision
velocity. Heavy impacts are deep, light bounces are high. This
creates an organic soundscape as hundreds of drones tumble.

### 10.3 Haptics

Steam Deck has two HD haptic motors (one in each trackpad). Use
the **right trackpad motor** as a continuous gravity feedback
channel (see §3.1 for details). The left trackpad motor provides
haptic clicks for the radial trap selector.

**Right trackpad (gravity feedback):**

| State | Haptic |
|-------|--------|
| No tilt | Silent |
| Light tilt | Low-frequency gentle purr |
| Strong tilt | High-frequency aggressive rumble |
| R2 amplify | Motor intensity scales with trigger pull |
| L4 gravity slam | Sharp heavy thud |
| L5 gravity flip | Quick double-tick |
| Enemy fall-kill | Brief directional pulse |
| Damage taken | Sharp triple-pulse |
| Level up | Rising sweep pattern |

**Left trackpad (trap selector):**

| State | Haptic |
|-------|--------|
| Thumb crosses segment boundary | Crisp click |
| Trap placed successfully | Soft confirm tick |
| Trap placement failed (cooldown) | Harsh buzz |

The haptic feedback should be noticeable but never fatiguing.
Players will be holding the Deck for 15–30 minute sessions.
Provide an intensity slider in settings (including fully off).

---

## 11. Technical Architecture

### 11.1 Technology Stack

```
┌─────────────────────────────────┐
│  Game Logic (With)              │
│  └─ Systems: spawn, AI, damage  │
│  └─ Progression: XP, upgrades   │
│  └─ Trap placement and management│
├─────────────────────────────────┤
│  Physics (Box2D v3 via c_import)│
│  └─ Rigid bodies for all entities│
│  └─ Contact callbacks for damage │
│  └─ Spatial queries for AOE      │
├─────────────────────────────────┤
│  Rendering (SDL3 via c_import)  │
│  └─ SDL3_gpu for sprite batching │
│  └─ Texture atlases              │
│  └─ Particle system              │
├─────────────────────────────────┤
│  Audio (SDL3_mixer via c_import)│
│  └─ Positional audio (2D pan)   │
│  └─ Dynamic pitch/volume         │
├─────────────────────────────────┤
│  Platform (SDL3 via c_import)   │
│  └─ Window, input, timing        │
│  └─ Steam Input API for gyro     │
│  └─ Steam SDK for achievements   │
└─────────────────────────────────┘
```

### 11.2 ECS-Lite Architecture

Not a full ECS. Entity is an ID. Components are parallel arrays.
Systems are functions.

```
type EntityId = distinct u32

type World = {
    // Parallel arrays indexed by EntityId
    positions:    Vec[Vec2],
    physics:      Vec[b2BodyId],      // Box2D body handles
    healths:      Vec[f32],
    enemy_types:  Vec[EnemyType],
    sprites:      Vec[SpriteId],
    alive:        Vec[bool],

    // Singleton state
    player:       Player,
    traps:        Vec[Trap],
    cores:         Vec[Core],
    gravity:      Vec2,
    elapsed:      f32,

    // Box2D world
    b2_world:     b2WorldId,
}
```

### 11.3 Frame Budget

Steam Deck target: 60fps = 16.6ms per frame.

| Phase | Budget | Notes |
|-------|--------|-------|
| Input + gravity | 0.1ms | Read accelerometer, compute gravity vector |
| Enemy AI | 0.5ms | Trivial: apply force toward player |
| Physics step | 6.0ms | Box2D step for 2000 bodies |
| Damage resolution | 0.5ms | Contact callback processing |
| Spawn + cleanup | 0.3ms | Create/destroy bodies |
| Rendering | 6.0ms | Sprite batching, particles |
| Audio | 0.2ms | Mix and queue |
| Headroom | 3.0ms | Safety margin |

Box2D v3 is heavily optimized for large body counts. Erin Catto has
benchmarks showing 10,000+ bodies at sub-10ms on modern hardware.
The Steam Deck's Zen 2 APU should handle 2,000 comfortably.

### 11.4 Box2D Integration

```
use c_import("box2d/box2d.h", link: "box2d")

fn create_enemy(world: &mut World, pos: Vec2, enemy_type: EnemyType) -> EntityId =
    let body_def = b2DefaultBodyDef()
    body_def.type = b2_dynamicBody
    body_def.position = b2Vec2 { x: pos.x, y: pos.y }
    body_def.linearDamping = 0.5

    let body_id = b2CreateBody(world.b2_world, &body_def)

    let shape_def = b2DefaultShapeDef()
    shape_def.density = enemy_type.mass / (PI * enemy_type.radius * enemy_type.radius)
    shape_def.friction = enemy_type.friction
    shape_def.restitution = enemy_type.restitution

    let circle = b2Circle { center: b2Vec2_zero, radius: enemy_type.radius }
    b2CreateCircleShape(body_id, &shape_def, &circle)

    // Register entity...
    world.add_entity(pos, body_id, enemy_type)

fn update_gravity(world: &mut World, accel: Vec2) =
    let gravity = compute_gravity_from_accel(accel)
    world.gravity = gravity
    b2World_SetGravity(world.b2_world, b2Vec2 { x: gravity.x, y: gravity.y })

fn step_physics(world: &mut World, dt: f32) =
    b2World_Step(world.b2_world, dt, 4)  // 4 sub-steps
    // Sync positions from Box2D back to our arrays
    for i in 0..world.positions.len():
        if world.alive[i]:
            let pos = b2Body_GetPosition(world.physics[i])
            world.positions[i] = Vec2 { x: pos.x, y: pos.y }
```

### 11.5 Collision Callbacks for Damage

```
fn on_contact(contact: b2ContactEvents, world: &mut World) =
    for hit in contact.begin_events:
        let speed = b2Contact_GetRelativeVelocity(hit).length()

        // Fall damage: velocity² × 0.1
        if speed > 5.0:
            let damage = speed * speed * 0.1
            if let Some(entity) = body_to_entity(hit.body_a):
                world.healths[entity] -= damage
            if let Some(entity) = body_to_entity(hit.body_b):
                world.healths[entity] -= damage

    for hit in contact.sensor_events:
        // Kill zone detection
        if is_kill_zone(hit.sensor):
            if let Some(entity) = body_to_entity(hit.visitor):
                world.healths[entity] = 0.0
```

### 11.6 Rendering Pipeline

Sprite batching is essential for 2000+ entities:

```
fn render(world: &World, renderer: &mut Renderer) =
    renderer.clear(BACKGROUND_COLOR)

    // Layer 0: Background + parallax
    renderer.draw_background(world.gravity)

    // Layer 1: Terrain (static, cached)
    renderer.draw_terrain(world.terrain)

    // Layer 2: Kill zones (pits, plasma vents)
    renderer.draw_kill_zones(world.terrain)

    // Layer 3: Traps
    for trap in &world.traps:
        renderer.queue_sprite(trap.sprite, trap.position, trap.rotation)

    // Layer 4: Enemies (batched by sprite type)
    for i in 0..world.positions.len():
        if world.alive[i]:
            let rot = b2Body_GetRotation(world.physics[i])
            renderer.queue_sprite(
                world.sprites[i],
                world.positions[i],
                b2Rot_GetAngle(rot),
            )

    // Layer 5: XP cores
    for core in &world.cores:
        renderer.queue_sprite(CORE_SPRITE, core.position, 0.0)

    // Layer 6: Player (always on top)
    renderer.queue_sprite(world.player.sprite, world.player.position, 0.0)

    // Layer 7: Particles
    renderer.draw_particles()

    // Layer 8: UI
    renderer.draw_hud(world)

    // Flush all batched sprites in one draw call per texture atlas
    renderer.flush()
```

### 11.7 Steam Deck Specifics

**Power management:**
- Target 60fps at 10W TDP
- Reduce particle count if frame time exceeds 14ms
- Box2D substeps can be reduced from 4 to 2 under pressure

**Resolution:**
- Steam Deck: 1280×800 native
- PC: support 1920×1080, 2560×1440, 3840×2160
- All game logic in world-space (meters), rendering scales

**Steam Input API:**
```
use c_import("steam/steam_api.h", link: "steam_api")

fn read_gyro() -> Vec2 =
    var motion: InputMotionData_t = default()
    SteamInput().GetMotionData(controller_handle, &mut motion)
    // motion.rotAccelX/Y/Z — angular acceleration
    // motion.posAccelX/Y/Z — linear acceleration (what we want)
    Vec2 {
        x: motion.posAccelX,
        y: motion.posAccelY,
    }
```

---

## 12. Content Roadmap

### 12.1 Playable Demo (Minimum Viable Game)

- 1 arena template (simple: flat floor, 2 plasma pits, some platforms)
- 3 enemy types (Blobber, Junkbot, Loader)
- 3 starter traps (Spike Strip, Bumper, Wall)
- Gravity control via gyro
- XP + leveling with 6 basic upgrades
- 15-minute run with escalating difficulty
- No meta-progression, no bosses, no audio

This is the "is it fun?" checkpoint.

### 12.2 Alpha

- 3 arena templates
- 6 enemy types (Tier 1 + Tier 2)
- 6 trap types
- First boss (The Wrecking Ball)
- 15 upgrades
- Placeholder audio
- Grav-Shard Forge with Tier 1 + Tier 2 permanent unlocks
- Post-death flow (slow-mo best kill → shop → drop again)

### 12.3 Beta

- 6 arena templates
- 12 enemy types (all tiers)
- 10 trap types
- 4 bosses
- 30 upgrades
- Full audio + music
- Full Grav-Shard Forge (all tiers, all unlocks)
- Steam achievements
- PC keyboard+mouse support

### 12.4 Launch

- 10+ arena templates
- Polish pass on all visuals
- Tutorial / first-run experience
- Leaderboards (time survived, enemies killed)
- Steam Deck verified badge

---

## 13. What This Showcases About With

When someone opens the repo and reads the source code:

- **`c_import`** — Box2D, SDL3, Steam SDK imported in single lines.
  No bindings, no wrappers, no build.rs. Just `c_import` and go.
- **No GC** — 2000 rigid bodies, 60fps, consistent frame times.
  No GC pauses. No stutters. The frame time graph is flat.
- **Syntax** — Game logic reads like pseudocode. The `update` function
  looks like the design doc. A Lua/Python developer can read it.
- **Comptime** — Enemy type registration, component metadata, sprite
  atlas generation. Zero-cost abstraction over the data model.
- **`with` blocks** — SDL resource management, texture lifetimes,
  audio channel scoping. Clean RAII everywhere.
- **Fibers** — Async asset loading, parallel spatial hash construction,
  background audio decode. Where it makes sense, not everywhere.
- **Safety** — No segfaults, no use-after-free, no data races. Despite
  heavy C interop and thousands of entities.

The story: "This game runs at 60fps on Steam Deck with 2000 physics
bodies, and the source code is 5,000 lines of a language you've
never seen before. A little robot, a broken space station, and a
gravity gun. Read the code. You already understand it."

---

*Falling With Style — Game Design Specification v0.4*