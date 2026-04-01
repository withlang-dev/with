
# 🌾 **Smallhold — Game Specification (v0.1)**

**Genre:** Simulation / Management
**Perspective:** 2D top-down (tile-based world, pixel entities)
**Core Idea:**

> A realistic homestead simulator where **time, labor, and relationships** determine success.

---

# 🧠 1. Design Pillars

## 1.1 Time = Money

* Every action consumes **time**
* Time can be:

  * spent on labor
  * invested in higher-value decisions
  * wasted

👉 The player constantly trades:

> **time vs money vs labor vs risk**

---

## 1.2 People Are Not Tools

Workers are:

* unreliable sometimes
* influenced by relationships
* shaped by experience

👉 No “perfect automation”

---

## 1.3 No Artificial Restrictions

* You *can* make bad decisions
* The system responds with consequences

Examples:

* animals in house → disease, stress
* overwork → burnout
* poor hiring → missed tasks

---

## 1.4 Single Homestead Scope

* No city building
* No controlling the town

👉 The world exists, but:

* you only manage **your farm**

---

# 🌍 2. World Model

## 2.1 Tile Grid

* Fixed 2D grid
* Each tile has state

### Tile (MVP)

```plaintext
Tile:
- type (soil, grass, water, building)
- moisture (0–100)
- fertility (0–100)
- occupancy (entity / structure)
```

Later:

* contamination
* temperature
* compaction

---

## 2.2 Spatial Rules

* Entities have **pixel positions**
* Tiles define:

  * movement cost
  * growth behavior

---

# 🧑‍🌾 3. Entities

## 3.1 Humans

### Worker

```plaintext
Worker:
- id
- age
- energy
- skills
- traits
- relationships
- current_task
```

---

### Age System

| Age   | Capability     |
| ----- | -------------- |
| 0–9   | no labor       |
| 10–13 | light labor    |
| 14–17 | moderate labor |
| 18+   | full labor     |

---

### Traits (global)

* work_ethic
* endurance
* learning_rate

---

## 3.2 Animals

```plaintext
Animal:
- type (goat, chicken, etc.)
- age
- health
- stress
- production_rate
```

---

### Animal Types (MVP)

* chickens
* goats

Later:

* rabbits
* ducks
* sheep
* cattle

---

# 📋 4. Task System (CORE)

## 4.1 Task Definition

```plaintext
Task:
- type
- target (tile/entity)
- required_workers
- optimal_workers
- max_workers
- required_stats
- estimated_duration
- status
```

---

## 4.2 Multi-Worker Tasks

* Tasks require:

  * minimum workers
  * combined strength

```plaintext
Example:
Move Hay Bale:
- min_workers: 2
- min_strength: 10
```

---

## 4.3 Assignment

* Default auto-assignment
* Player can override

---

## 4.4 Task Lifecycle

1. Planned
2. Assigned
3. In Progress
4. Completed / Failed / Partial

---

## 4.5 Interruptions

* Tasks can be:

  * paused
  * reassigned
  * delayed

---

# ⏱️ 5. Time System

## 5.1 Time Units

* Day split into hours
* Tasks consume hours

---

## 5.2 Scheduling

* Workers have:

  * daily capacity
  * fatigue

---

## 5.3 Time Pressure

* Some tasks are time-sensitive:

  * feeding animals
  * harvesting

---

# 📊 6. Estimation vs Reality

## 6.1 Estimates

Each task shows:

* estimated duration range
* expected output

---

## 6.2 Actual Outcomes

```plaintext
TaskResult:
- actual_duration
- output_quantity
- output_quality
- waste
- side_effects
```

---

## 6.3 Causes of Variance

* skill
* fatigue
* environment
* randomness

---

# 💰 7. Economy System

## 7.1 Core Loop

* produce goods
* sell goods
* buy inputs

---

## 7.2 Tradeoffs

Example:

| Choice    | Effect       |
| --------- | ------------ |
| grow feed | time + labor |
| buy feed  | money        |

---

## 7.3 Market

* prices fluctuate (later)
* player does NOT control market

---

# 👷 8. Labor System (CORE)

## 8.1 Hiring

Two modes:

### Contract

* short-term
* higher cost
* flexible

---

### Live-in Worker

* lower cost long-term
* requires housing
* more stable

---

## 8.2 Job Market

Player can:

* post job
* respond to workers

---

## 8.3 Worker Stats

* skill
* reliability
* cost

---

## 8.4 Execution Variance

Workers may:

* be late
* do poor work
* skip tasks

---

# 🤝 9. Relationship System

## 9.1 Relationship Score

```plaintext
-100 → hostile
0 → neutral
+100 → loyal
```

---

## 9.2 Effects

Higher relationship:

* better reliability
* better quality
* more forgiveness

---

## 9.3 Community Types

* neighbor
* church member
* stranger

---

## 9.4 Reputation

Farm has:

```plaintext
Reputation:
- affects worker pool
```

---

# 📈 10. Skill System

## 10.1 Structure

### Layers:

* traits (global)
* domain skills (livestock, crops)
* task skills (milk_goat, etc.)

---

## 10.2 Skill Gain

```plaintext
task_skill += X
domain_skill += X * 0.3
trait += X * 0.1
```

---

## 10.3 Transfer

* goat milking → helps cow milking
* livestock skill boosts all animal work

---

# 🧠 11. Consequence System

## 11.1 Hard Constraints

* insufficient strength → cannot perform task
* missing tools → cannot start

---

## 11.2 Soft Constraints

* poor skill → bad outcomes
* fatigue → slower work

---

## 11.3 Examples

* overcrowding animals → stress
* poor hygiene → disease
* missed feeding → production loss

---

# 🖥️ 12. UI Systems

## 12.1 Main Views

* world view
* task list
* worker list

---

## 12.2 Kanban Board

Columns:

* backlog
* assigned
* in progress
* blocked
* done

---

## 12.3 Gantt View

* timeline per worker
* task overlap
* idle time

---

## 12.4 Feedback

Player sees:

* delays
* mistakes
* causes

---

# 🔄 13. Simulation Loop

Each tick:

1. update workers
2. update tasks
3. update tiles
4. update economy

---

# 🎯 14. MVP Scope (IMPORTANT)

## Start with:

* 1 worker (player)
* 1 crop
* 1 animal
* 3 tasks:

  * plant
  * harvest
  * feed

---

## Then add:

* 1 hired worker
* task assignment UI
* simple economy

---

# 🚀 15. Future Systems

* multi-generation family
* education vs labor decision
* breeding systems
* contracts vs permanent workers
* weather

---

# 💡 16. Hidden Goal (your real goal)

This game should teach:

* opportunity cost
* labor allocation
* long-term planning
* human management
