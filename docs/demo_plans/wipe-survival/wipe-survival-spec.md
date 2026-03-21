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

### 5. Addictive Loop (NEW)

* Clear short-term goals
* “Almost succeeded” tension
* Immediate retry motivation

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
2. Enemies spawn from edges
3. Player shoots continuously
4. **Run goal appears (NEW)**
5. Survive → gain upgrade choices
6. Difficulty ramps quickly
7. Player dies
8. **Goal + achievement progress shown (NEW)**
9. Instant restart

👉 Total loop downtime: **<2 seconds**

---

# 🎯 4. Run Goals (NEW — Critical for Addiction)

Each run includes **1 dynamic goal**:

### Types:

* Kill X enemies (e.g. 50)
* Survive X seconds (e.g. 60s)
* No damage for X seconds
* Reach X upgrades

---

### Requirements:

* Visible at all times
* Progress updates in real-time
* Achievable within a run

---

### Purpose:

> Creates tension: “I was so close…”

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

### Scaling:

* Spawn rate increases over time
* Mix complexity increases

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

---

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

# 🧬 9. Build Variance (NEW)

Upgrades are designed to **stack into emergent builds**

Examples:

* Multi-shot + piercing → chaos build
* Shield + slow → defensive build
* Speed + fire rate → glass cannon

👉 No explicit combo system needed

---

# 🪙 10. Meta Progression (Minimal + Meaningful)

### Earn:

* Points per run

### Spend:

* Small stat boosts
* **Unlock new upgrades (NEW priority)**

---

### Permanent upgrades:

* +5% damage
* +5% fire rate
* +5% movement speed

---

### Unlocks:

* New upgrade types
* New effects

👉 Unlocks > stat boosts (more exciting)

---

# 🏆 11. Steam Achievements Integration (NEW)

All progression systems are tied to **Steamworks SDK**.

---

## Achievement Categories

### 1. First-time Events

* First kill
* First upgrade
* First run

---

### 2. Run Goals (direct mapping)

* Kill 50 enemies → `KILL_50`
* Survive 60s → `SURVIVE_60`
* No damage → `PERFECT_RUN`

---

### 3. Progress Milestones

* Total kills (100, 500, 1000)
* Total runs (5, 10, 25)

---

### 4. Unlocks

* Unlock ricochet → achievement
* Unlock shield → achievement

---

## Requirements

* Achievements trigger immediately
* No UI needed (Steam overlay handles display)
* Minimal integration code

---

## Design Principle

> Achievements reinforce the “one more run” loop

---

# 📈 12. Difficulty Scaling

### Over Time:

* Spawn rate ↑
* Enemy speed ↑ (slightly)
* Enemy mix ↑

### Goal:

* Player overwhelmed in **2–5 minutes**

---

# 💥 13. Juice / Feedback (CRITICAL)

### Visual:

* Hit flashes
* Particle explosions
* Bullet trails
* Screen shake

### UX:

* Score ticks rapidly
* Combo counter (optional but recommended)

---

## Death Feedback (UPDATED)

```text
YOU DIED

Time: 1:42
Kills: 47 / 50
Goal: KILL_50

→ Almost unlocked!
```

---

👉 This is the **core addiction trigger**

---

# ⚡ 14. Performance Showcase

### Target:

* 150–300 enemies + bullets + particles
* Stable FPS on Steam Deck

---

### Optional Debug Overlay:

* FPS
* Entity count
* Frame time

---

# 🔁 15. Restart Flow

On death:

* Screen wipes instantly
* Restart input available immediately
* No delay, no menus

👉 Feels like:

> die → blink → retry

---

# 🖥️ 16. UI (Minimal)

* Score
* Time survived
* Goal progress
* Upgrade choices

---

# 🎯 17. First 60 Seconds (Updated)

### 0–10s:

* Easy kills
* Immediate feedback

### 10–30s:

* First goal appears
* First upgrade

### 30–60s:

* Chaos increases
* Player builds power

👉 Player feels:

> “I almost completed the goal”

---

# 🧠 18. What This Demonstrates About With

* Clean real-time loop
* High-performance entity handling
* Data-oriented mutation
* Minimal FFI friction
* Seamless platform integration (Steam + raylib)

---

# 🏁 19. Scope Guardrails

### DO NOT ADD:

* Story
* Multiple levels
* Complex UI
* Inventory systems

---

### ONLY ADD IF CORE IS PERFECT:

* Dash
* Boss
* Extra enemy types

---

# 🧪 20. Success Criteria

After ~3 minutes, a developer should think:

> “This feels smooth… and I almost hit that goal… one more run.”

AND:

> “This is built in With??”
