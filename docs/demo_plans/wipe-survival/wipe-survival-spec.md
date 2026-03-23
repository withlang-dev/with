# 🎮 **WIPE: SURVIVAL — SPEC**

---

# 🧭 1. Core Pillars

### 1. Instant Fun

* Playable in **<3 seconds**
* No menus, no setup

### 2. Extreme Responsiveness

* Twin-stick, zero input lag
* Instant restart (<1 second)

### 3. High Entity Performance

* 100–300+ entities smoothly
* No frame drops on Steam Deck

### 4. Short, Repeatable Runs

* 2–5 minutes per run
* Immediate retry loop

### 5. Addictive Loop

* **Immediate**: combo rhythm, upgrade anticipation bar
* **Per-run**: run goal tension, near-miss feedback
* **Cross-run**: next goal tease, best-wave tracking, prestige discovery

---

# 🎮 2. Controls (Steam Deck First)

* **Left Stick** → Move
* **Right Stick** → Aim
* **Auto-fire** (constant shooting)
* **A / Trigger (optional)** → Dash (post-MVP)

### Requirements:

* No input buffering delay
* Smooth analog aiming
* Deadzone tuned for sticks

---

# 🔄 3. Core Gameplay Loop

1. Spawn in arena instantly
2. Enemies spawn from edges in waves
3. Player shoots continuously, combo builds
4. **Run goal visible, upgrade bar filling**
5. Survive → gain upgrade choices
6. Waves ramp in density and mix
7. Player dies
8. **Near-miss / goal result + best wave + next goal shown**
9. **Prestige offered (if wave 15+)**
10. Instant restart

👉 Total loop downtime: **<2 seconds**

---

# 🎯 4. Run Goals (Critical for Addiction)

Each run includes **1 dynamic goal**:

### Types:

* Kill X enemies (e.g. 50)
* Survive X seconds (e.g. 60s)
* No damage for X seconds
* Reach X upgrades

### Goal Scaling:

Goals increase gradually across runs. Completing a goal advances
to the next tier of that goal type. Failing retries the same goal.

Example progression: Kill 25 → Kill 50 → Kill 75 → Kill 100

The curve is tuned so goals are always *just barely achievable* —
the player should complete roughly 40-60% of goals across all runs.
Too easy and there's no tension. Too hard and there's no payoff.

### Requirements:

* Visible at all times during the run
* Progress updates in real-time
* Achievable within a run
* Next goal previewed on death screen (see §14)

### Purpose:

> Creates tension: "I was so close…"

---

# 🧱 5. Arena

* Single screen (no scrolling)
* Player starts center
* Enemies spawn just off-screen edge
* No obstacles (MVP)

---

# 👾 6. Enemies (MVP: 3 Types)

### 1. Chaser

* Moves toward player
* Slow → medium speed

### 2. Dasher

* Charges periodically
* Telegraph before dash

### 3. Shooter

* Keeps distance
* Fires slow bullets

### Wave Scaling:

* Each wave increases spawn count and enemy mix
* Individual enemy stats scale per wave (see §13)
* Mix complexity increases — later waves introduce more Dashers and Shooters

### Boss (Post-Core):

* Spawns every 10 waves (wave 10, 20, 30…)
* Large, high-HP single enemy
* Unique attack pattern per boss type
* See §14 for boss juice spec

---

# 🔫 7. Player Combat

* Constant fire (no input needed)
* Bullets follow aim exactly
* No recoil, no delay

### Base stats:

* Moderate fire rate
* Single projectile
* Low spread

---

# ⚡ 8. Upgrades (Run-Based)

### Trigger:

* Every ~20–30 seconds
* Player chooses 1 of 3

### Anticipation:

Upgrade timing is visible via a small filling bar on the HUD.
When the bar is nearly full, the player thinks "just survive
a few more seconds." This creates short-term survival tension
that layers on top of the run goal.

## Core Upgrade Pool

### Damage Path

* +Damage
* +Fire rate
* +Bullet size

### Multi-shot Path

* +Projectiles
* Slight spread

### Utility Path

* Piercing
* Ricochet
* Slow field

### Defensive Path

* Orbiting shield
* Movement speed

👉 Total: **8–12 upgrades max**

---

# 🧬 9. Build Variance

Upgrades are designed to **stack into emergent builds**

Examples:

* Multi-shot + piercing → chaos build
* Shield + slow → defensive build
* Speed + fire rate → glass cannon

👉 No explicit combo-upgrade interaction needed — emergent builds
come from upgrade stacking, combo rewards come from the points system

---

# 🪙 10. Meta Progression (Minimal + Meaningful)

### Earn:

* Points per run (scaled by wave reached, combo performance, and prestige rank)

### Spend:

* Small stat boosts
* **Unlock new upgrades (priority)**

### Permanent stat boosts:

* +5% damage
* +5% fire rate
* +5% movement speed

### Unlocks:

* New upgrade types
* New effects

👉 Unlocks > stat boosts (more exciting)

### Interaction with Prestige:

* Stat boosts reset on prestige (this is the cost)
* Unlocks are permanent (never reset)

---

# 🔁 11. Prestige (Power Ceiling Expansion)

### The Problem It Solves

Difficulty scales exponentially. In-run upgrades and stat boosts
scale linearly. Over several runs, the player gradually notices
their results plateauing — runs keep ending around the same wave
range. Prestige is the natural next step when grinding stat boosts
stops yielding meaningful progress.

### The Feel (Critical)

There is **no hard cap, no message, no visible wall.** The experience is:

1. Early runs: every run pushes further, big improvement each time
2. Mid runs: progress slows — gaining 1-2 waves per run instead of 5
3. Plateau: runs consistently end in the same wave range, stat boosts feel marginal
4. Realization: "I should prestige"

This mirrors idle game prestige discovery. The game never tells
you to prestige. You *feel* it.

### How It Works

After dying at **wave 15+**, the death screen shows: **"Prestige?"**

Accepting:

* Resets permanent stat boosts (§10) to zero
* Grants **+1 Prestige Rank**
* Each rank gives a **compounding base power bonus** (+8% all stats per rank)

Does NOT reset:

* Upgrade unlocks
* Achievements
* Lifetime stats (total kills, total runs, etc.)

### Why It Breaks the Plateau

Prestige bonus is **multiplicative**, not additive. It multiplies
everything — base stats, stat boosts, and in-run upgrades. This
shifts the soft ceiling forward:

| Prestige | Effective Multiplier | Soft Ceiling Zone |
|----------|---------------------|-------------------|
| 0 | 1.00× | Waves ~28-32 |
| 1 | 1.08× | Waves ~34-37 |
| 2 | 1.17× | Waves ~39-42 |
| 3 | 1.26× | Waves ~44-47 |
| 5 | 1.47× | Waves ~55+ |

Each prestige doesn't remove the plateau — it **moves it**. The
player will plateau again at the new ceiling, and the cycle repeats.

### Why Reset Stat Boosts?

Gives prestige a cost. The first few runs post-prestige feel
slightly weaker (lost the +5% stacks), but the base multiplier
compensates by mid-run. This creates a mini-progression loop
within each prestige cycle:

> Re-earn stat boosts → push to new personal best → feel the plateau → prestige again

Without the reset, prestige is free power with no tradeoff.

### The Prestige Moment

The death screen subtly reinforces the plateau:

```
YOU DIED

Wave: 29  (best: 30)
Kills: 134
Goal: KILL_75 → ALMOST (89%)

+12 points (x8 combo best)

Next goal: KILL_75 (retry)

        [Prestige?]     [Retry]
```

The key detail: `Wave: 29 (best: 30)`. The player sees this
repeatedly across runs. No explanation needed — the stagnation
is visible.

* "Prestige?" only appears at wave 15+
* Best wave is always shown — when the player is stuck at the same
  best for several runs, the number does the nudging
* When a new best is set, a ★ appears — positive reinforcement
* No explanation, no tooltip
* First-time players try prestige out of curiosity
* The next run teaches them what it did — they feel stronger

### What the Player Never Sees

* No "you've hit the maximum wave for your prestige level"
* No "prestige recommended" popup
* No power curve graph
* No explicit ceiling number anywhere

The plateau is emergent from the math. The player discovers
prestige naturally.

### Scope

* One integer (prestige rank)
* One multiplier applied to base stats before all other bonuses
* One conditional button on the death screen
* Zero explanation UI

---

# 🏆 12. Steam Achievements Integration

All progression systems are tied to **Steamworks SDK**.

## Achievement Categories

### 1. First-time Events

* First kill
* First upgrade
* First run

### 2. Run Goals (direct mapping)

* Kill 50 enemies → `KILL_50`
* Survive 60s → `SURVIVE_60`
* No damage → `PERFECT_RUN`

### 3. Progress Milestones

* Total kills (100, 500, 1000)
* Total runs (5, 10, 25)
* Prestige rank (1, 3, 5)

### 4. Wave Records

* Reach wave 20 → `WAVE_20`
* Reach wave 40 → `WAVE_40`
* Reach wave 60 → `WAVE_60`

### 5. Boss Kills (Post-Core)

* Kill first boss → `BOSS_SLAYER`
* Kill 3 bosses in one run → `TRIPLE_BOSS`

### 6. Unlocks

* Unlock ricochet → achievement
* Unlock shield → achievement

## Requirements

* Achievements trigger immediately
* No UI needed (Steam overlay handles display)
* Minimal integration code

## Design Principle

> Achievements reinforce the "one more run" loop

---

# 📈 13. Difficulty Scaling

### Wave-Based Scaling

Difficulty is driven by **wave number**. Each wave increases enemy
stats and spawn counts on an exponential curve.

### The Formula

```
enemy_hp     = base_hp     × 1.07 ^ wave
enemy_damage = base_damage × 1.05 ^ wave
enemy_speed  = base_speed  × 1.02 ^ wave
spawn_count  = base_count  + floor(wave × 1.4)
```

### Player Power (for comparison)

```
effective_power = base_stats
                × prestige_multiplier        (1.08 ^ prestige_rank)
                × (1 + sum(stat_boosts))     (additive, from §10)
                × (1 + sum(upgrade_bonuses)) (additive, from in-run picks)
```

### Why This Creates a Soft Ceiling

Enemy scaling is exponential (compounds every wave). Player scaling
is linear within a run (each upgrade adds a flat bonus). The curves
cross at a predictable point — this is the soft ceiling. The player
doesn't hit a wall; they gradually notice runs stalling in the same
wave range.

Prestige shifts the player curve up by a multiplicative factor,
moving the crossover point to a higher wave.

### Spawn Mix by Wave

| Wave Range | Mix |
|-----------|-----|
| 1–5 | Chasers only |
| 6–9 | Chasers + Dashers |
| **10** | **Boss wave (post-core)** |
| 11–19 | All three types |
| **20** | **Boss wave (post-core)** |
| 21–30 | Increased Dashers and Shooters |
| **30** | **Boss wave (post-core)** |
| 31+ | Heavy Shooter/Dasher ratio, Chasers as filler |

Boss waves (every 10) replace the normal spawn pattern with a boss
encounter. If bosses aren't implemented, these are regular waves
with a milestone-wave juice celebration (§14).

### Tuning Targets

* Wave 10: first-run player feels pressure
* Wave 20: experienced player needs good upgrades
* Wave 30: soft ceiling for prestige 0
* Wave 40+: requires prestige to reach consistently

### Requirements

* Scaling must never produce frame drops — spawn count capped at
  entity budget (§15) regardless of formula output
* Enemy stat scaling is invisible — no HP bars, no numbers shown

---

# 💥 14. Juice / Feedback (CRITICAL)

### Combat Feedback (Continuous):

* Hit flashes (enemy blinks white on damage)
* Particle explosions on kill (scale with enemy type)
* Bullet trails
* Screen shake on kills (subtle, scales with multi-kills)

### UX:

* Score ticks rapidly
* Combo multiplier (core system — see below)

## Combo System

Combo is **core**, not optional. It creates rhythm, rewards
aggression, and ties directly into meta progression.

### Rules:

* Each kill increments the combo counter
* Combo resets to zero on a timer (~2s without a kill) or on taking damage
* Combo multiplier applies to **points earned** for the run
* Best combo reached is shown on the death screen
* No combo UI beyond the counter itself — no "GREAT!" text, no grades

### Why It's Core:

* Creates micro-tension: "keep killing, don't let the combo drop"
* Rewards skilled play with faster meta progression (more points)
* Gives the death screen an extra data point for replay motivation
* Zero complexity — one counter, one timer, one multiplier

## Wave Clear Feedback

Every wave clear is a **micro-reward moment**. The player should
feel each wave boundary even without looking at the wave counter.

### On Wave Clear:

* **Brief freeze frame** — 50-80ms pause. Action stops for a
  heartbeat. Player feels the punctuation.
* **Wave number flash** — large "WAVE 12" text scales up from center,
  fades quickly (~0.8s total). No animation complexity — just scale + alpha.
* **Screen flash** — ~30ms white overlay at ~20% opacity
* **SFX** — punchy impact/chime sound. Tone rises slightly with
  wave number to subconsciously signal progression.
* **Kill all remaining** — any surviving enemies from the current wave
  explode simultaneously on wave clear. Visual payoff + clean slate.
* **Recovery pulse** — player gets ~0.5s invulnerability on wave clear.
  Brief white glow on the player sprite. No HP system needed — this
  is just breathing room. Creates "I survived → I'm rewarded → I
  can reposition for the next wave."

### On Milestone Waves (every 10):

All of the above, plus:

* **Stronger freeze** — 100-150ms
* **Color flash** — gold/yellow tint instead of white
* **Larger text** — "WAVE 20" renders bigger, stays slightly longer
* **Camera zoom pulse** — brief 5% zoom in and back out over ~0.3s

### Timing:

* Total wave-clear ceremony: **<1 second**
* Must never feel like an interruption — it's a breath between waves
* Next wave spawning begins immediately after the text starts fading
* Player can move and shoot during the entire sequence

## Boss Feedback (Post-Core — Ready to Implement)

> Bosses are in the §20 scope guardrails. This section exists so
> the juice is specced when bosses are added.

### Boss Spawn (every 10 waves):

* **Warning** — screen edges pulse red for ~1.5s before boss appears.
  "WARNING" text throbs at screen center. All regular enemies stop
  spawning during the warning.
* **Entrance freeze** — 120-150ms pause as the boss enters the arena.
  Longer than wave clear — this is a big deal.
* **Camera zoom out** — arena view pulls back ~15% to accommodate
  boss size. Smooth ease over ~0.5s. Zooms back on boss death.
* **Music shift** — if music exists, crossfade to boss track.
  If no music, low rumble/drone audio starts.
* **Boss HP bar** — the one exception to "no HP bars." Appears at
  top of screen. This is the only enemy that gets one.

### During Boss Fight:

* **Hit feedback scaled up** — bigger flashes, meatier screen shake
  per hit. Player should feel every bullet connecting.
* **Phase thresholds** — at 66% and 33% HP, ~80ms freeze +
  boss flashes red + burst of particles. Signals progress.
* **Arena pressure** — regular enemies resume spawning in reduced
  numbers during the boss fight. Keeps tension without overwhelming.

### Boss Kill:

* **Extended freeze** — 200-350ms. The longest
  pause in the game. This is the biggest moment in a run.
* **Explosion cascade** — boss doesn't just die, it detonates in
  a sequence of 3-4 expanding particle bursts over ~0.5s.
* **All enemies die** — everything on screen explodes simultaneously.
  Maximum visual payoff.
* **Screen shake** — strongest in the game, ~0.3s duration.
* **Score burst** — large bonus number flies up from boss corpse.
* **Gold flash** — full screen gold tint, fades over ~0.5s.
* **Brief calm** — 1-2 seconds with no spawns after boss death.
  Let the player breathe. Then next wave starts.

### Boss Design Note:

Bosses are a **wave-clear gate**, not a separate mode. Wave 10, 20,
30 etc. are boss waves. Clearing the boss clears the wave. All
standard wave-clear juice plays after the boss-kill juice, creating
a layered celebration: boss explodes → enemies explode → wave clear
flash → "WAVE 21" → next wave begins.

## Death Feedback

### Goal Complete:

```
YOU DIED

Wave: 31  (best: 31 ★)
Kills: 147
Goal: SURVIVE_90s ✓

+18 points (x12 combo best)

Next goal: KILL_75

        [Prestige?]     [Retry]
```

### Goal Near-Miss (≥85% complete):

```
YOU DIED

Wave: 28  (best: 30)
Kills: 47 / 50

Goal: KILL_50
→ ALMOST (94%)

+12 points (x8 combo best)

Next goal: KILL_50 (retry)

        [Prestige?]     [Retry]
```

### Rules:

* **Near-miss threshold**: if goal progress ≥ 85%, show "ALMOST (N%)"
  instead of a plain failure. This turns "I failed" into "I basically
  had it." One of the strongest replay triggers in games.
* **Best wave**: always shown. When the player sets a new record,
  show a ★. When they're stuck at the same best for several runs,
  the number silently reinforces the plateau (prestige nudge).
* **Points earned**: shown with best combo multiplier from the run.
  Makes combo feel consequential even after death.
* **Next goal**: always shown. If the current goal was failed, the
  same goal appears as "retry." If completed, a harder variant
  appears. Gives immediate direction for the next run.
* "Prestige?" appears conditionally (wave 15+)

👉 The death screen is the **core addiction trigger** — near-miss,
best-wave comparison, and next-goal tease all compress into one
moment of "I need to go again."

---

# ⚡ 15. Performance Showcase

### Target:

* 150–300 enemies + bullets + particles
* Stable FPS on Steam Deck

### Entity Budget:

* Spawn count formula (§13) is clamped to max entity count
* If wave formula requests 200 spawns but budget is 300 total,
  spawner respects the cap
* Prioritize enemy variety over raw count at cap

### Optional Debug Overlay:

* FPS
* Entity count
* Frame time
* Current wave

---

# 🔁 16. Restart Flow

On death:

* Death screen shows instantly (stats + optional prestige)
* If prestige: apply immediately, then restart
* If retry: screen wipes instantly
* Restart input available immediately
* No delay, no menus

👉 Feels like:

> die → (optional prestige tap) → blink → retry

---

# 🖥️ 17. UI (Minimal)

### In-Run HUD:

* Score
* Wave number
* Time survived
* Goal progress
* Combo counter
* Upgrade progress bar (fills toward next upgrade choice)
* Prestige rank (small icon/number, top corner)

### Death Screen:

* Wave reached + best wave comparison (★ on new record)
* Kill count
* Goal result (with "ALMOST N%" on near-miss)
* Points earned (with combo multiplier)
* Next goal preview
* Prestige button (conditional, wave 15+)
* Retry button

### Upgrade Screen:

* 3 choices
* Pick and resume instantly

👉 No menus, no settings screen, no inventory

---

# 🎯 18. First 60 Seconds

### 0–10s:

* Easy kills (wave 1-2 chasers only)
* Immediate feedback — hits feel good
* Combo counter starts climbing naturally

### 10–30s:

* First goal appears
* Upgrade bar visibly filling — creates anticipation
* First upgrade choice
* Dashers start appearing

### 30–60s:

* All enemy types present
* Player builds power from upgrades
* Combo becomes harder to maintain — creates rhythm tension
* Chaos increases noticeably

👉 Player feels:

> "I almost completed the goal… and I want to see what wave I can hit"

---

# 🧠 19. What This Demonstrates About With

* Clean real-time loop
* High-performance entity handling
* Data-oriented mutation
* Minimal FFI friction
* Seamless platform integration (Steam + raylib)

---

# 🏁 20. Scope Guardrails

### DO NOT ADD:

* Story
* Multiple levels / arenas
* Complex UI / menus
* Inventory systems
* Prestige skill trees or currencies

### ONLY ADD IF CORE IS PERFECT:

* Dash
* Boss enemies (juice fully specced in §14)
* Extra enemy types
* Visual themes per prestige rank
* Run modifiers (e.g. "Faster Enemies", "More Dashers" — one per
  run, 3-5 types. Prevents "same run again" feeling but requires
  difficulty rebalancing per modifier)

---

# 🧪 21. Success Criteria

After ~3 minutes, a developer should think:

> "This feels smooth… and I almost hit that goal… one more run."

After ~30 minutes:

> "I keep plateauing around wave 30… what does Prestige do?"

After prestiging:

> "Oh. I'm stronger now. I can push past 35. Let me keep going."

AND:

> "This is built in With??"