Alright—here’s a **clean, focused, no-BS spec** tailored to your real goal:

> ⚙️ *Show off With*
> 🎮 *Deliver a tight 2–5 minute twin-stick experience*
> 🧠 *Impress devs + feel great on Steam Deck*

---

# 🎮 **WIPE: SURVIVAL — SPEC v2 (Demo-Focused)**

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
4. Survive → gain upgrade choices
5. Difficulty ramps quickly
6. Player dies
7. Instant restart

👉 Total loop downtime: **<2 seconds**

---

# 🧱 4. Arena

* Single screen (no scrolling)
* Player starts center
* Enemies spawn just off-screen edge
* No obstacles (MVP)

---

# 👾 5. Enemies (MVP: 3 Types)

### 1. Chaser

* Moves toward player
* Slow → medium speed
* Core pressure unit

### 2. Dasher

* Charges toward player periodically
* Telegraph before dash

### 3. Shooter

* Keeps distance
* Fires slow projectiles

### Scaling:

* Spawn rate increases over time
* Mix complexity increases

---

# 🔫 6. Player Combat

* Constant fire (no input needed)
* Bullets go exactly where you aim
* No recoil, no delay

### Base stats:

* Moderate fire rate
* Single projectile
* Low spread (0° initially)

---

# ⚡ 7. Upgrades (Run-Based)

### Trigger:

* Every ~20–30 seconds
* Player chooses 1 of 3

---

## Core Upgrade Pool (MVP)

### Damage Path

* +Damage
* +Fire rate
* +Bullet size

### Multi-shot Path

* +Projectiles (spread)
* Slight spread increase

### Utility Path

* Piercing bullets
* Ricochet (bounce once)
* Slow nearby enemies

### Defensive Path

* Orbiting shield
* +Movement speed

👉 Keep total pool: **8–12 upgrades max**

---

# 🪙 8. Meta Progression (Minimal)

Since this is a demo:

* Earn points during run
* Spend after death

### Permanent upgrades (small boosts):

* +5% damage
* +5% fire rate
* +5% movement speed

👉 Cap progression quickly (no grind)

---

# 📈 9. Difficulty Scaling

### Over Time:

* Spawn rate ↑
* Enemy speed ↑ (slightly)
* Enemy mix ↑

### Goal:

* Player overwhelmed in **2–5 minutes**

---

# 💥 10. Juice / Feedback (CRITICAL)

### Visual:

* Bright hit flashes
* Particle explosions
* Bullet trails
* Screen shake on kill bursts

### UX:

* Score ticks up rapidly
* Combo multiplier (optional)

### Death:

* Screen **hard wipe / flash**
* Everything disappears instantly

👉 Reinforce the *“wipe”* identity

---

# ⚙️ 11. Performance Showcase

This is your hidden “feature”:

### Target:

* 150–300 enemies + bullets + particles
* Stable FPS on Steam Deck

### Optional Debug Overlay:

(toggleable)

* FPS
* Entity count
* Frame time

Example:

> 120 FPS | 284 entities | 0.5ms

---

# 🔁 12. Restart Flow (IMPORTANT)

On death:

* Instant screen clear
* Press button → restart immediately
* No loading, no fade delays

👉 Feels like:

> die → blink → back in game

---

# 🖥️ 13. UI (Minimal)

* Score (top center)
* Time survived
* Upgrade choices (large, readable)
* No clutter

---

# 🎯 14. First 60 Seconds (Scripted Feel)

### 0–10s:

* Few enemies, easy kills

### 10–30s:

* Player surrounded lightly
* First upgrade choice

### 30–60s:

* Noticeable chaos
* Player feels stronger

👉 Player should think:

> “this feels really smooth”

---

# 🧠 15. What This Demonstrates About “With”

Without saying it explicitly, the game shows:

* Fast iteration loop
* Clean system design
* High-performance entity handling
* Tight input responsiveness

---

# 🏁 16. Scope Guardrails

### DO NOT ADD:

* Story
* Multiple levels
* Complex UI
* Inventory systems

### ONLY ADD IF CORE IS PERFECT:

* Dash
* Boss
* More enemy types

---

# 🧪 17. Success Criteria

If a dev plays for 3 minutes, they should think:

> “This handles a lot of stuff really cleanly… what is this built in?”

---

If you want next, I can:

* Turn this into a **code architecture (ECS vs simple structs in With)**
* Or design the **exact upgrade math + balance curves**
* Or help you build a **“wow benchmark moment” at 2 minutes**
