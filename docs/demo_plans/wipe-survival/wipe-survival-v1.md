# WIPE: SURVIVAL — V1 SPEC

## 1. Goal

V1 expands the proven MVP into the first complete public/demo-ready version.

The target experience:

> instant arcade survival, short repeatable runs, meaningful cross-run progression, visible plateau, curiosity-driven prestige, and enough enemy/build variety to sustain repeated play.

V1 assumes the MVP already feels good.

---

## 2. Core Pillars

### Instant Fun

- Playable in under 3 seconds
- No setup friction
- Minimal/no menus

### Extreme Responsiveness

- Twin-stick movement and aiming
- Auto-fire
- Instant restart
- No perceived input latency

### High Entity Performance

- 150–300 enemies, bullets, and particles smoothly
- Stable FPS on Steam Deck
- Entity cap enforced by budget

### Short, Repeatable Runs

- 2–5 minutes per run
- Death/retry loop under 2 seconds

### Addictive Loop

Immediate:

- Combo rhythm
- Upgrade anticipation bar

Per-run:

- Dynamic goal tension
- Near-miss feedback
- Build variance

Cross-run:

- Points
- Unlocks
- Best-wave tracking
- Prestige discovery

---

## 3. Controls

Steam Deck first:

- Left Stick: move
- Right Stick: aim
- Auto-fire: constant shooting
- A / Trigger: dash, if the core loop is already perfect

Requirements:

- No input buffering delay
- Smooth analog aiming
- Tuned deadzone
- Instant restart input

---

## 4. Core Gameplay Loop

1. Spawn instantly in arena.
2. Enemies spawn from edges in waves.
3. Player auto-fires while aiming.
4. Combo builds through kills.
5. Run goal remains visible.
6. Upgrade bar fills.
7. Player chooses 1 of 3 upgrades.
8. Waves ramp in density and enemy mix.
9. Player dies.
10. Death screen shows near-miss/goal result, best wave, next goal, points, and optional prestige.
11. Player retries instantly.

Target downtime:

- Death screen appears immediately
- Retry/prestige input available immediately
- Retry to gameplay under 1 second

---

## 5. Arena

- Single screen
- Player starts center
- Enemies spawn just off-screen
- No obstacles by default

Possible later extension:

- Very light arena variants only after core feel is proven

---

## 6. Enemies

V1 enemy set: 3 types.

### Chaser

Behavior:

- Moves toward player
- Slow to medium speed

Pressure role:

- Creates crowd/body pressure
- Forces constant movement
- Forms walls of danger

### Dasher

Behavior:

- Tracks player briefly
- Telegraphs
- Charges periodically

Pressure role:

- Punishes predictable movement
- Forces quick directional decisions
- Adds burst danger without constant clutter

Requirements:

- Telegraph must be readable
- Dash should feel fair, not random

### Shooter

Behavior:

- Keeps distance
- Fires slow bullets

Pressure role:

- Creates area pressure
- Forces aim/movement split
- Prevents passive circling from solving every wave

### Wave Mix

| Wave Range | Mix |
|-----------|-----|
| 1–5 | Chasers only |
| 6–9 | Chasers + Dashers |
| 10 | Boss wave or milestone wave |
| 11–19 | All three types |
| 20 | Boss/milestone wave |
| 21–30 | Increased Dashers and Shooters |
| 30 | Boss/milestone wave |
| 31+ | Heavy Shooter/Dasher ratio, Chasers as filler |

---

## 7. Bosses — Post-Core V1 Feature

Bosses are optional for v1 and should only be added if the regular loop is already excellent.

Rules:

- Boss spawns every 10 waves: 10, 20, 30...
- Boss wave replaces or dominates normal wave pattern
- Boss is a wave-clear gate, not a separate mode
- Regular enemies may resume in reduced numbers during the fight

Boss requirements:

- Large, high-HP single enemy
- Unique attack pattern per boss type
- Boss HP bar is allowed as the one enemy HP exception

---

## 8. Player Combat

Base combat:

- Constant auto-fire
- Bullets follow aim exactly
- No recoil
- No input delay
- Single projectile at base
- Low spread

Optional post-core:

- Dash
- Additional projectile behavior
- Visual themes per prestige

---

## 9. Upgrades

### Trigger

- Every ~20–30 seconds
- Player chooses 1 of 3
- Upgrade progress bar visible at all times

### Purpose

The upgrade bar creates anticipation:

> “Just survive a few more seconds.”

### Core Upgrade Pool

Damage path:

- +Damage
- +Fire rate
- +Bullet size

Multi-shot path:

- +Projectiles
- Slight spread

Utility path:

- Piercing
- Ricochet
- Slow field

Defensive path:

- Orbiting shield
- Movement speed

Target pool:

- 8–12 upgrades max

---

## 10. Build Variance

Upgrades should stack into emergent builds.

Examples:

- Multi-shot + piercing: chaos build
- Shield + slow: defensive build
- Speed + fire rate: glass cannon
- Ricochet + bullet size: screen-control build

No explicit combo-upgrade interaction is required for v1.

Build variety should come from upgrade stacking, not complex synergy rules.

---

## 11. Run Goals

Each run has one dynamic goal.

Goal types:

- Kill X enemies
- Survive X seconds
- Reach wave X
- Reach X upgrades
- No damage for X seconds, only after the base loop is tuned

Goal scaling:

- Completing a goal advances to the next tier
- Failing retries the same goal
- Goal should feel barely achievable

Target completion rate:

- 40–60% across all runs

Example progression:

```text
Kill 25 → Kill 50 → Kill 75 → Kill 100
Survive 30s → Survive 60s → Survive 90s
Reach wave 5 → Reach wave 10 → Reach wave 15
```

Requirements:

- Visible at all times
- Progress updates live
- Achievable within a run
- Next goal previewed on death screen

Purpose:

> Creates tension: “I was so close.”

---

## 12. Combo System

Combo is core.

Rules:

- Each kill increments combo counter
- Combo resets after ~2 seconds without a kill
- Combo resets on damage/death
- Combo multiplier applies to run points
- Best combo is shown on death screen
- No grade text, no excessive UI

Purpose:

- Creates rhythm
- Rewards aggression
- Makes points feel skill-influenced
- Adds replay motivation to death screen

---

## 13. Meta Progression

### Earn

Points per run, scaled by:

- Wave reached
- Kills
- Combo performance
- Prestige rank

### Spend

Priority:

1. Unlock new upgrades
2. Small permanent stat boosts

Permanent stat boosts:

- +5% damage
- +5% fire rate
- +5% movement speed

Unlocks:

- New upgrade types
- New effects

Principle:

> Unlocks are more exciting than stat boosts.

Interaction with prestige:

- Stat boosts reset on prestige
- Unlocks never reset

---

## 14. Prestige

### Problem It Solves

Difficulty scales exponentially. In-run upgrades and stat boosts scale more linearly. Over several runs, the player notices results plateauing around the same wave range.

Prestige is the natural next step when stat boosts stop producing meaningful progress.

### The Feel

There is no hard cap, no warning, and no explicit recommendation.

The player experience should be:

1. Early runs: large improvements
2. Mid runs: slower progress
3. Plateau: repeated deaths near the same best wave
4. Realization: “I should prestige.”

### How It Works

After dying at wave 15+, death screen shows:

```text
[Prestige?]
```

Accepting prestige:

- Resets permanent stat boosts to zero
- Grants +1 Prestige Rank
- Each rank gives +8% all stats multiplicatively

Does not reset:

- Upgrade unlocks
- Achievements
- Lifetime stats
- Best records, unless later design says otherwise

### Formula

```text
prestige_multiplier = 1.08 ^ prestige_rank
```

Player effective power:

```text
effective_power = base_stats
                × prestige_multiplier
                × (1 + sum(stat_boosts))
                × (1 + sum(upgrade_bonuses))
```

### Soft Ceiling Example

| Prestige | Effective Multiplier | Soft Ceiling Zone |
|----------|---------------------|-------------------|
| 0 | 1.00× | Waves ~28–32 |
| 1 | 1.08× | Waves ~34–37 |
| 2 | 1.17× | Waves ~39–42 |
| 3 | 1.26× | Waves ~44–47 |
| 5 | 1.47× | Waves ~55+ |

Each prestige moves the plateau forward. It does not remove the plateau.

### UI Principle

Do not explain prestige too much.

Show:

- Prestige button after wave 15+
- Best wave comparison
- Repeated near-best deaths

Do not show:

- Recommended prestige popup
- Power curve graph
- Ceiling number
- “You should prestige now” text

---

## 15. Difficulty Scaling

Difficulty is driven by wave number.

Formula:

```text
enemy_hp     = base_hp     × 1.07 ^ wave
enemy_damage = base_damage × 1.05 ^ wave
enemy_speed  = base_speed  × 1.02 ^ wave
spawn_count  = base_count  + floor(wave × 1.4)
```

Enemy scaling is exponential. Player scaling inside a run is mostly additive/linear. Prestige shifts player power upward multiplicatively.

This creates a soft ceiling where the curves cross.

Tuning targets:

- Wave 10: first-run player feels pressure
- Wave 20: experienced player needs good upgrades
- Wave 30: soft ceiling for prestige 0
- Wave 40+: requires prestige to reach consistently

Requirements:

- Spawn count clamped to entity budget
- Enemy stat scaling invisible to player
- No regular enemy HP bars

---

## 16. Juice / Feedback

### Combat Feedback

- Enemy hit flashes
- Particle explosions on kill
- Bullet trails
- Subtle screen shake on kills
- Multi-kill shake scaling
- Rapid score ticks

### Wave Clear Feedback

Every wave clear is a micro-reward.

On wave clear:

- 50–80ms freeze frame
- Large wave number flash
- 30ms white overlay at ~20% opacity
- Punchy impact/chime sound
- Kill/explode remaining enemies
- 0.5s player recovery pulse/invulnerability

Milestone waves every 10:

- 100–150ms stronger freeze
- Gold/yellow flash
- Larger text
- 5% camera zoom pulse

Timing:

- Total wave-clear ceremony under 1 second
- Next wave starts as text fades
- Player can move and shoot during sequence

---

## 17. Boss Juice — If Bosses Ship In V1

### Boss Spawn

- Red screen-edge warning for ~1.5s
- WARNING text at center
- Regular enemies stop spawning during warning
- 120–150ms entrance freeze
- Camera zooms out ~15%
- Music shift or low rumble
- Boss HP bar appears

### During Boss Fight

- Larger hit flashes
- Meatier shake per hit
- Phase threshold feedback at 66% and 33%
- Reduced regular enemy spawning

### Boss Kill

- 200–350ms extended freeze
- Explosion cascade over ~0.5s
- All enemies die
- Strongest screen shake
- Score burst
- Gold flash
- 1–2 seconds of calm

Boss design note:

Bosses are wave-clear gates. Boss death leads into normal wave-clear feedback.

---

## 18. Death Screen

The death screen is the core addiction trigger.

Always show:

- YOU DIED
- Wave reached
- Best wave comparison
- Kill count
- Goal result
- Points earned
- Best combo multiplier
- Next goal
- Prestige button, if eligible
- Retry button

### Goal Complete

```text
YOU DIED

Wave: 31  (best: 31 ★)
Kills: 147
Goal: SURVIVE_90s ✓

+18 points (x12 combo best)

Next goal: KILL_75

        [Prestige?]     [Retry]
```

### Near-Miss

```text
YOU DIED

Wave: 28  (best: 30)
Kills: 47 / 50

Goal: KILL_50
→ ALMOST (94%)

+12 points (x8 combo best)

Next goal: KILL_50 (retry)

        [Prestige?]     [Retry]
```

Rules:

- Near-miss threshold: 85%+
- New best wave gets ★
- Failed goal repeats as retry
- Completed goal previews harder/new goal
- Prestige button appears at wave 15+

---

## 19. Steam Achievements

All progression systems tie into Steamworks SDK.

### Categories

First-time events:

- First kill
- First upgrade
- First run

Run goals:

- Kill 50 enemies: `KILL_50`
- Survive 60s: `SURVIVE_60`
- No damage goal: `PERFECT_RUN`

Progress milestones:

- Total kills: 100, 500, 1000
- Total runs: 5, 10, 25
- Prestige rank: 1, 3, 5

Wave records:

- Reach wave 20: `WAVE_20`
- Reach wave 40: `WAVE_40`
- Reach wave 60: `WAVE_60`

Boss kills, if bosses ship:

- Kill first boss: `BOSS_SLAYER`
- Kill 3 bosses in one run: `TRIPLE_BOSS`

Unlocks:

- Unlock ricochet
- Unlock shield

Requirements:

- Achievements trigger immediately
- No custom achievement UI required
- Steam overlay handles display

Design principle:

> Achievements reinforce the one-more-run loop.

---

## 20. Performance Showcase

Target:

- 150–300 enemies + bullets + particles
- Stable FPS on Steam Deck

Entity budget:

- Spawn count formula is clamped
- Total active entity cap enforced
- Prioritize readability and enemy variety over raw count

Debug overlay required during development:

- FPS
- Entity count
- Bullet count
- Particle count
- Frame time
- Current wave

Principle:

> The engine should support 300+ entities. The game should display only as many as remain readable.

---

## 21. Restart Flow

On death:

- Death screen appears instantly
- Prestige applies immediately if selected
- Retry restarts instantly
- No transition delay
- No menu friction

Target feel:

> die → optional prestige tap → blink → retry

---

## 22. UI

### In-Run HUD

- Score
- Wave number
- Time survived
- Goal progress
- Combo counter
- Upgrade progress bar
- Prestige rank icon/number

### Death Screen

- Wave reached + best wave comparison
- Kill count
- Goal result
- Points earned
- Best combo multiplier
- Next goal preview
- Prestige button, conditional
- Retry button

### Upgrade Screen

- 3 choices
- Pick and resume instantly

No complex menus, inventory, map, or loadout screen.

---

## 23. First 60 Seconds

### 0–10 seconds

- Easy kills
- Chasers only
- Immediate feedback
- Combo begins naturally

### 10–30 seconds

- First goal progress is obvious
- Upgrade bar fills
- First upgrade choice
- Dashers may begin appearing after MVP tuning

### 30–60 seconds

- Enemy variety increases
- Combo becomes harder to maintain
- Chaos increases
- Player either completes or nearly completes the first goal

Desired player thought:

> “I almost completed the goal… and I want to see what wave I can hit.”

---

## 24. What This Demonstrates About With

WIPE: SURVIVAL should visibly demonstrate:

- Clean real-time loop
- High-performance entity handling
- Data-oriented mutation
- Minimal FFI friction
- Stable frame time
- Seamless Steam + raylib integration
- No GC-hitch feeling

Desired reaction:

> “This is built in With??”

---

## 25. Scope Guardrails

Do not add:

- Story
- Multiple levels/arenas
- Complex menus
- Inventory systems
- Prestige skill trees
- Multiple currencies
- Large upgrade trees

Only add after core is perfect:

- Dash
- Boss enemies
- Extra enemy types
- Visual themes per prestige rank
- Run modifiers

Run modifiers, if added later:

- 3–5 modifier types
- One per run
- Examples: faster enemies, more dashers, double chasers
- Requires difficulty rebalance per modifier

---

## 26. V1 Success Criteria

After 3 minutes, a developer should think:

> “This feels smooth… and I almost hit that goal… one more run.”

After 30 minutes:

> “I keep plateauing around wave 30… what does Prestige do?”

After prestiging:

> “Oh. I’m stronger now. I can push past 35. Let me keep going.”

And finally:

> “This is built in With??”

---

## 27. V1 Depends On MVP

Do not begin full v1 implementation until MVP proves:

- Movement feels good
- Aiming feels good
- Shooting feels good
- Chasers create pressure
- Death/retry is instant
- Goals create near-miss tension
- Upgrade bar creates anticipation
- Combo creates aggression rhythm

If any of those fail, fix MVP before adding v1 systems.

