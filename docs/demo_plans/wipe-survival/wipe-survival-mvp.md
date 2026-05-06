# WIPE: SURVIVAL — MVP SPEC

## 1. Goal

Build the smallest playable version that proves the core feel:

> spawn instantly → move/aim/shoot → survive waves → almost hit a goal → die → retry immediately

The MVP exists to answer one question:

> Is the game fun in the first 60 seconds?

Everything that does not directly support that question is deferred to v1.

---

## 2. MVP Pillars

### Instant Fun

- Playable in under 3 seconds
- No menus
- No setup
- Spawn directly into the arena

### Extreme Responsiveness

- Twin-stick movement and aiming
- Auto-fire
- No input buffering delay
- Instant restart after death

### Short Retry Loop

- Runs last roughly 2–5 minutes
- Death screen downtime under 2 seconds
- Retry available immediately

### Clear Addiction Hook

- One visible run goal
- Combo counter
- Upgrade anticipation bar
- Near-miss death screen
- Best-wave comparison

---

## 3. Controls

Steam Deck first:

- Left Stick: move
- Right Stick: aim
- Auto-fire: always on

Deferred:

- Dash
- Alternate weapons
- Manual fire modes

Requirements:

- Smooth analog aiming
- Deadzone tuned for sticks
- No input lag

---

## 4. Core Gameplay Loop

1. Player spawns at arena center.
2. Enemies spawn from off-screen edges.
3. Player shoots continuously toward aim direction.
4. Combo builds from kills.
5. Run goal progress updates in real time.
6. Upgrade bar fills over time.
7. Player chooses 1 of 3 upgrades when the bar fills.
8. Waves ramp in density.
9. Player dies.
10. Death screen shows goal result, best wave, points, and retry.
11. Player restarts instantly.

Target downtime:

- Death to retry input: immediate
- Retry to gameplay: under 1 second
- Total loop downtime: under 2 seconds

---

## 5. Arena

- Single screen
- No scrolling
- Player starts center
- Enemies spawn just outside screen bounds
- No obstacles in MVP

Purpose:

- Keep implementation simple
- Keep enemy pressure readable
- Avoid camera/level-design complexity

---

## 6. Player Combat

- Constant auto-fire
- Bullets follow right-stick aim exactly
- No recoil
- No firing delay
- Single projectile at base
- Moderate fire rate
- Low/no spread at base

Base player stats:

- Medium movement speed
- Moderate fire rate
- Low damage
- Single projectile

---

## 7. Enemies — MVP

### Chaser

The only required MVP enemy.

Behavior:

- Moves directly toward player
- Slow to medium speed
- Dies in a small number of hits
- Creates body/crowd pressure

Pressure role:

- Forces the player to keep moving
- Creates walls of enemies
- Makes aim and positioning matter immediately

Deferred to v1:

- Dasher
- Shooter
- Bosses

---

## 8. Waves

Difficulty is wave-based.

MVP wave behavior:

- Each wave increases spawn count
- Chasers get slightly more HP over time
- Chasers get slightly faster over time
- Spawn count is capped by entity budget

Suggested MVP formula:

```text
enemy_hp    = base_hp    × 1.06 ^ wave
enemy_speed = base_speed × 1.015 ^ wave
spawn_count = base_count + floor(wave × 1.25)
```

Tuning targets:

- Wave 1: instant easy kills
- Wave 5: player feels pressure
- Wave 10: first real survival test
- Wave 20: strong run for MVP
- Wave 30: soft ceiling target for later v1/prestige tuning

---

## 9. Run Goals — MVP

Each run has one visible dynamic goal.

MVP goal types:

- Kill X enemies
- Survive X seconds
- Reach wave X

Defer until later:

- No-damage goals
- Reach X upgrades
- Modifier-specific goals

Goal rules:

- Goal is visible at all times
- Progress updates in real time
- Completing a goal advances to a harder version
- Failing retries the same goal
- Goal should be barely achievable

Target completion rate:

- Roughly 40–60% across runs after tuning

Example progression:

```text
Kill 25 → Kill 50 → Kill 75 → Kill 100
Survive 30s → Survive 60s → Survive 90s
Reach wave 5 → Reach wave 10 → Reach wave 15
```

Purpose:

> Create the feeling: “I was so close.”

---

## 10. Combo System — MVP

Combo is core, not optional.

Rules:

- Each kill increments combo counter
- Combo resets after about 2 seconds without a kill
- Combo resets on taking damage/death
- Best combo is shown on death screen
- Combo multiplier affects points earned

UI:

- Show a simple combo counter
- No grades
- No extra text spam

Purpose:

- Rewards aggression
- Creates short-term rhythm tension
- Makes the death screen more replayable

---

## 11. Upgrades — MVP

### Trigger

- Upgrade bar fills over time
- Every ~20–30 seconds, player chooses 1 of 3 upgrades
- Game pauses or slows during choice
- Choice resumes gameplay immediately

### MVP Upgrade Pool

Keep this small.

Damage path:

- +Damage
- +Fire rate
- +Bullet size

Multi-shot path:

- +Projectile
- Slight spread

Utility/defense path:

- Movement speed
- Piercing
- Orbiting shield

Total MVP upgrade count:

- 6–8 upgrades max

Purpose:

- Let the player feel power growth within a run
- Create anticipation from the upgrade bar
- Support a few emergent builds without combo-specific upgrade logic

---

## 12. Points — MVP

Points are earned per run.

MVP formula can be simple:

```text
points = wave_reached + floor(kills / 10) + best_combo_bonus
```

Combo should matter, but not dominate.

Death screen shows:

- Points earned
- Best combo multiplier

Deferred:

- Spending points
- Meta upgrades
- Unlocks
- Prestige interaction

---

## 13. Death Screen — MVP

The death screen is the core replay trigger.

Always show:

- YOU DIED
- Wave reached
- Best wave comparison
- Kill count
- Goal result
- Points earned
- Best combo
- Next goal preview
- Retry button

### Goal Complete Example

```text
YOU DIED

Wave: 12  (best: 12 ★)
Kills: 64
Goal: KILL_50 ✓

+8 points (x7 combo best)

Next goal: SURVIVE_60s

        [Retry]
```

### Near-Miss Example

```text
YOU DIED

Wave: 9  (best: 10)
Kills: 47 / 50

Goal: KILL_50
→ ALMOST (94%)

+6 points (x5 combo best)

Next goal: KILL_50 (retry)

        [Retry]
```

Rules:

- Near-miss threshold: 85%+
- Show `ALMOST (N%)` instead of plain failure
- Show ★ when setting a new best wave
- Retry input is available immediately

---

## 14. Juice / Feedback — MVP

Combat feedback:

- Enemy hit flash
- Particle burst on kill
- Bullet trails
- Subtle screen shake on kills
- Score ticks rapidly

Wave-clear feedback:

- Brief freeze frame: 50–80ms
- Large wave text flash
- Light screen flash
- Punchy sound
- Kill/clear remaining enemies if appropriate
- Player gets brief recovery pulse/invulnerability

Requirements:

- Total wave-clear ceremony under 1 second
- Player can move and shoot during the sequence
- Feedback must never interrupt the retry loop

---

## 15. Performance Target — MVP

The engine should support:

- 100+ enemies/bullets/particles smoothly
- Stable frame time on Steam Deck
- No visible hitches on restart

Gameplay readability matters more than raw count.

Development debug overlay is required:

- FPS
- Frame time
- Enemy count
- Bullet count
- Particle count
- Current wave

---

## 16. UI — MVP

In-run HUD:

- Score
- Wave number
- Time survived
- Goal progress
- Combo counter
- Upgrade progress bar

Death screen:

- Wave reached + best wave
- Kill count
- Goal result
- Points earned
- Best combo
- Next goal
- Retry

Upgrade screen:

- 3 choices
- Minimal text
- Pick and resume instantly

No menus, settings, inventory, map, or extra screens.

---

## 17. First 60 Seconds Target

### 0–10 seconds

- Easy chaser kills
- Immediate hit/kill feedback
- Combo starts naturally

### 10–30 seconds

- First goal progress becomes meaningful
- Upgrade bar visibly filling
- First upgrade choice appears

### 30–60 seconds

- Enemy density increases
- Combo becomes harder to maintain
- Player either completes or nearly completes first goal

Desired player thought:

> “I almost completed the goal. Let me retry.”

---

## 18. MVP Success Criteria

After 3 minutes, a developer should think:

> “This feels smooth… and I almost hit that goal… one more run.”

Technical success:

- Instant startup into gameplay
- Stable frame time
- Fast restart
- 100+ active entities without hitching
- No control latency

Design success:

- Player understands the loop without explanation
- Death screen motivates retry
- Upgrade bar creates anticipation
- Combo creates aggression rhythm

---

## 19. Explicitly Not MVP

Do not add these until the MVP loop feels good:

- Prestige
- Steam achievements
- Meta stat boosts
- Unlock economy
- Dash
- Dasher enemy
- Shooter enemy
- Bosses
- Multiple arenas
- Obstacles
- Menus/settings
- Inventory
- Story
- Run modifiers
- Visual themes
- JIT/advanced platform integrations

