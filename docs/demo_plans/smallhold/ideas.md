# 🌾 Smallhold — Brainstorm Session Insights

**Revision 4 — April 2026**

---

## Core Identity

**Trojan Horse Design:** A cozy farming sim with Harvest Moon / Link to the Past aesthetics that gradually reveals deep economic, interpersonal, and ecological simulation underneath. Marketed as cozy, played as strategic.

**The Arc:**

- **Act 1 — It's Just You:** Manual labor, named chickens, intimate scale. The player falls in love with the homestead as a *place*.
- **Act 2 — You Can't Do It Alone:** Hiring workers, delegating tasks, managing relationships. The player becomes an operations manager.
- **Act 3 — The Machine Humming:** Semi-automated systems run by skilled workers. The player handles exceptions, expansion, and people. Resilience over perfect efficiency.

---

## Design Philosophy

### Problems Are Material, Not Abstract
Issues aren't status effects with generic solutions. They are specific physical conditions with specific physical remedies:
- Rabbit overheating → frozen water bottle in cage
- Goat stress → overcrowded milking stall
- Worker unreliability → denied time off

### Preventive Over Reactive
Good management is boring. Rituals prevent emergencies:
- Frozen bottles placed *before* the heat hits
- Auto doors close *before* predators arrive
- Workload balanced *before* burnout

The game teaches that crisis is a planning failure, not a random event.

### Failure Is Real, Recovery Is Possible
Consequences cost but don't end the game. A goat can die. A worker can quit. But new goats are bought, new workers hired. The farm continues, marked by its history.

### No Violence, No Combat
The world is difficult, not cruel. Conflict is interpersonal and neighborly — disputes about fence lines, water rights, labor poaching, reputation. Resolved through conversation, compromise, time, or acceptance. No weapons. No killing. No eminent domain. The constraints are the message: *solve it like a person.*

### Time Is Permission
The game's default pace is slow enough that the player can afford to waste time. Walking the pond path, watching geese, sitting on the bench — these aren't inefficiencies. They're the point. A clock that's too fast forces optimization. A clock that's generous gives permission to *notice* things.

---

## Time System

### In-Game Day Duration

| Act | Real-Time per Day | Rationale |
|-----|-------------------|-----------|
| Act 1 | ~90-120 minutes | Manual everything. Player needs time to learn, observe, care. Every animal is an individual. |
| Act 2 | ~60-90 minutes | Workers handle routine. Player manages rather than does. Pace quickens naturally. |
| Act 3 | ~45-60 minutes | Systems automated. Player handles exceptions. Days move faster because the machine hums. |

Default target: **90-120 minutes per in-game day for the early game.** The clock communicates the game's values. A slow default says: *there is no rush. Notice the goose on the pond.*

### Time Controls
- **Pause:** Full stop. Walk around. Look at things. Take screenshots. The pond reflection doesn't care about your schedule.
- **Play (1x):** Normal time. The intended pace.
- **Fast-Forward (3x):** For waiting on crops, tasks, or passing slow winter months.
- **Sleep:** Skip to next morning when the day's work is done. Standard in the genre.

### Design Principle
The player who wants to min-max can fast-forward. The player who wants to walk the garden path at sunset can linger. The design honors both, but knows which one leads to the guest book full of kind messages.

---

## Simulation Architecture

### Core Principle

> **Objects are rows. Behavior is systems. Meaning comes from events.**

> **Do not give the pig logic. Give the world rules that make a pig matter.**

Complexity is combinatorial, not hierarchical. A pig isn't a special class with unique code. It's an entity with `hunger`, `stress`, `containment`, and `ownership` components. Those same components describe a goat, a chicken, or a restless neighbor's dog. The systems don't care what species they process — they just transform component values.

### Architecture Layers

**1. Entities**
Anything that exists as an addressable thing: player, pig, neighbor, potato sack, potato plant, fence segment, manure pile, tool, pond.

```ts
Entity {
  id: string,
  kind: string,       // animal, plant, structure, item, human
  species: string,    // pig, potato, border_collie
  location: tileId,
  owner_id: string,
  tags: string[]
}
```

**2. Components**
Reusable state chunks. Each stays simple. Complexity emerges from combination.

```
HungerComponent        EnergyComponent
HealthComponent        StressComponent
RelationshipComponent  OwnershipComponent
InventoryComponent     GrowthComponent
DecayComponent         ContainmentComponent
FilthComponent         SkillComponent
NeedComponent          TemperatureComponent
TrainingComponent      BondComponent
CoolingAccessComponent HabitatQualityComponent
```

A frozen water bottle in a rabbit cage:
```ts
Rabbit {
  components: {
    temperature_exposure: { value: 34 },
    cooling_access: { source: "cage_003", effectiveness: 0.8 }
  }
}
```

No rabbit-specific code. The `HeatStressSystem` processes any entity with `temperature_exposure`, respects `cooling_access`, and applies stress if thresholds are exceeded. The frozen bottle works because the component exists and the system acknowledges it.

**3. Definitions**
Static data for species, crops, buildings, tools, tasks.

```ts
SpeciesDef {
  id: "pig",
  diet_tags: ["vegetable", "grain", "scraps"],
  hunger_rate: 0.8,
  manure_rate: 1.2,
  escape_pressure: 0.4,
  min_comfort: 30,
  temp_tolerance: { min: -5, max: 28 },
  adult_weight: 200
}

CropDef {
  id: "potato",
  growth_days: 60,
  water_need: 0.5,
  fertility_need: 0.6,
  edible: true,
  seedable: true,
  feed_value: 0.3,
  storage_life_days: 90
}
```

Adding a duck later is trivial: rows in `Entity` and `SpeciesDef`, no new code.

**4. Systems**
Pure processors that transform state. Each system is dumb and general.

```
NeedSystem            GrowthSystem
DecaySystem           TaskSystem
MovementSystem        RelationshipSystem
ReputationSystem      DiseaseSystem
MarketSystem          WeatherSystem
HungerSystem          StressSystem
EscapeSystem          OpportunitySystem
TrainingSystem        BondSystem
HeatStressSystem      WildlifeSystem
CompanionSystem       InvestigationSystem
```

Systems don't know about each other:

```ts
StressSystem:
  for entities with stress component:
    stress += crowding + filth + hunger + noise + badWeather

EscapeSystem:
  for entities with containment:
    if enclosure.strength < requiredFenceStrength:
      if hunger > threshold OR stress > threshold:
        create Event("escape_risk")
```

Not:
```ts
if pig escaped and neighbor angry then steal pig
```

But:
```ts
OpportunitySystem:
  if actor has grievance
  and target asset is accessible
  and actor need is high
  and social risk is acceptable
  then create possible action: theft
```

Scripted complexity vs. emergent complexity.

**5. Event Ledger**
Append-only history. The storytelling engine — not cutscenes, not dialogue trees.

```ts
Event {
  id: string,
  time: timestamp,
  type: string,
  actors: string[],
  targets: string[],
  location: tileId,
  causes: Cause[],
  effects: Effect[],
  visibility: VisibilityMap
}
```

Example — the pig theft scenario:
```ts
Event {
  id: "evt_042",
  time: "Day 12 03:15",
  type: "theft",
  actors: ["neighbor_bob"],
  targets: ["pig_001"],
  location: "north_pen",
  causes: [
    { type: "grievance", source: "evt_038" },   // pig escaped earlier, damaged Bob's garden
    { type: "opportunity", fence_strength: 1.2 }
  ],
  visibility: {
    player: "unknown",
    neighbor_bob: "actor",
    neighbor_mary: "heard_noise"                 // partial witness
  }
}
```

**6. Beliefs & Evidence**
Distinguish **what happened** from **who knows or believes what happened**.

```ts
Belief {
  holder: "neighbor_mary",
  event: "evt_042",
  certainty: 0.4,
  details_known: ["noise_at_night", "pig_missing"],
  details_unknown: ["actor_identity"]
}

Evidence {
  id: "boot_tracks_001",
  source_event: "evt_042",
  type: "physical",
  location: "north_pen",
  discoverability: 0.7,
  decay_time: "3_days",
  points_to: "neighbor_bob",
  ambiguity: 0.3
}
```

If the player talks to Mary, her belief surfaces: "I heard something strange Tuesday night. Your pig's gone, isn't it?" The player now has a clue. They might investigate Bob's shed. Find boot tracks. Confront him. Or let it go. All from data. No quest script.

**7. Tasks as Data**
Declarative, not hardcoded.

```ts
TaskDef {
  id: "feed_animal",
  requirements: [
    { actor_has_energy: 5 },
    { target_has_component: "hunger" },
    { inventory_has_tag: "feed" }
  ],
  duration: {
    base_minutes: 20,
    modifiers: [
      { actor.skill.livestock: -0.05 },
      { distance: +0.1 },
      { actor.energy_low: +0.25 }
    ]
  },
  effects: [
    { target.hunger: "-feed.nutrition" },
    { actor.energy: -3 },
    { create_event: "animal_fed" }
  ]
}
```

Content expands without code growing.

### Architecture-Design Alignment

| Design Principle | Architectural Expression |
|------------------|--------------------------|
| Problems are material, not abstract | Components are physical states (temperature, hunger, filth), not abstract status effects |
| Preventive over reactive | Systems run continuously; crisis is when a component crosses a threshold |
| No violence, only neighborly friction | OpportunitySystem generates *social* actions (theft, gossip, poaching), never combat |
| Relationships shape reliability | RelationshipComponent feeds into TaskSystem performance modifiers |
| Ecological response to stewardship | HabitatQualityComponent checked by WildlifeSystem when determining arrivals |
| Time is permission, not pressure | Default clock is generous; fast-forward available but not required |
| Emergent moments, not scripted ones | Event ledger + belief system = stories the game doesn't write, but makes possible |

### Performance Consideration
Event ledger growth managed by:
- Archiving events older than one in-game year into `HistoricalSummary` records
- Beliefs decay over time if not reinforced
- Evidence degrades or disappears based on `decay_time`

---

## Automation Progression

Arrives only after the player has *mastered* manual systems — as graduation, not pain relief.

| Tier | Automation | Type | What It Teaches |
|------|------------|------|-----------------|
| 1 | Egg collection cages | Labor-saving | Simple, mechanical, no maintenance. First taste. |
| 2 | Herding dogs | Living automation | Requires training, care, has limits. Automation with a heartbeat. |
| 3 | Auto feeders | Logistics | Changes failure mode from gradual to catastrophic. Tests backup systems. |
| 4 | Auto henhouse doors | Protection | Loss prevention. What you built stays safe. |
| 5 | Milking machines | Role transformation | Shifts worker from *doing* to *monitoring*. The final exam. |

Automation doesn't remove the relationship layer. Workers who hauled water now maintain irrigation pipes. Same people, different tasks. The machines handle logistics, not judgment.

### Automation Categories

| Type | Examples | What It Feels Like |
|------|----------|-------------------|
| Labor-saving | Egg cages, milking machines | "I do less of this" |
| Logistics | Auto feeders, water systems | "This flows without me" |
| Protection | Auto doors, fencing, dogs | "What I built stays safe" |
| Living | Herding dogs | Automation with a heartbeat — has needs, limits, loyalty |

---

## The Dog System

Not a tool. A **relationship** that unfolds over time. Built on components, not special code.

### Component-Driven Lifecycle

**Puppy:**
```ts
Entity {
  id: "dog_001",
  species: "border_collie",
  components: {
    hunger: { value: 30 },
    energy: { value: 85 },
    bond: { target: "player", value: 0.6 },
    training: { herding: 0.1, obedience: 0.2 }
  }
}
```

**Six Months Later:**
```ts
training: { herding: 0.85, obedience: 0.9 },
bond: { target: "player", value: 0.95 }
```

The `TrainingSystem` processes any entity with a `training` component. The `BondSystem` increments bond when entities spend time near their target. When `bond.value > 0.8`, `CompanionSystem` triggers `FollowBehavior`. The dog walks beside the player not because "dog code" says so, but because component thresholds were crossed.

### Lifecycle Stages
- **Puppy:** Follows clumsily. Useless for work. Generates attachment. Player learns patience.
- **Obedience Training:** Commands start working. Player develops timing, consistency. A *player skill*, not a stat bar.
- **Herding:** The young dog sees the flock. Player gives command. Dog moves. Animals respond. A working partner emerges.
- **Maturity:** Dog anticipates needs. Reads hand gestures. Cuts left without being told. Walks the pond path at sunset because that's what you do together.

### Design Notes
- Requires rest days after heavy herding
- Semi-autonomous — takes initiative but can't handle true emergencies
- Has own relationship/state/needs
- Automation with a heartbeat — alive, not mechanical
- Predator protection: patrols pond edges, henhouse perimeter
- Companion role: walks beside the player, no command needed
- The bond grows through *time spent*, not resource investment

---

## Animal-Specific Care

Each species has distinct biological needs, creating unique ritual sets per animal. Implemented as component thresholds, not special-case logic.

### Chickens
- Dust baths (or mites develop)
- Auto door protection from raccoons
- Egg collection

### Goats
- Hoof trimming (or lameness)
- Milking routine
- Shade requirement in summer

### Rabbits
- Frozen water bottles in heat
- Sensitive to high temperatures
- Die if overheated (preventive husbandry essential)
- Implemented via `TemperatureExposure` + `CoolingAccess` components

### Dogs
- Rest days after heavy herding
- Training investment (puppy → obedience → herding)
- Relationship and state tracking
- Semi-autonomous
- Becomes a companion, not just a worker

### Future Animals
- Ducks (pond integration)
- Geese (self-invited)
- Sheep
- Cattle

---

## Aquaculture System

### Pond Dynamics
- **Water quality:** Oxygen levels, temperature stratification, ammonia buildup
- **Food webs:** Duckweed, insects, algae blooms as feed sources
- **Harvesting:** Feast-or-famine — drain or net for bulk harvest, creates processing bottleneck

### Species Difficulty Curve
1. **Tilapia** — Hardy, forgiving, ideal starter fish
2. **Shrimp** — More sensitive, requires better water management

### Cross-System Integration
- **Crop fertility:** Nutrient-rich pond water irrigates fields
- **Ducks:** Manure fertilizes pond food web; ducks eat duckweed and small aquatic life. Arrive via `WildlifeSystem` checking `HabitatQualityComponent`.
- **Geese:** Arrive uninvited. Territorial, excellent watchdogs, chase predators. Menace to workers with low relationship scores. Player chooses: tolerate, domesticate, or discourage.
- **Frozen storage:** Shared resource — bottles for rabbits vs. fish preservation
- **Predators:** Raccoons, herons — pond needs its own defenses (netting, decoys, dog patrols, geese)

### The Japanese Garden
Beyond production, the pond can become **beauty**. An optional aesthetic development:
- Gravel path raked in patterns
- Stone lanterns
- A wooden bench under a tree
- Koi mixing with the tilapia

Serves no production function. Its yield is stillness. Workers sit on the bench during breaks, stress dropping. The player walks the path with their dog, no UI open, just *being* on the farm they built. The game makes room for this — it doesn't require it, but honors the player who pursues it.

---

## Ecological Design

### The Pond as Ecological Interface
The farm is not separate from nature. It's a conversation with it. Dig a pond for tilapia, and the world responds:
- Algae grows
- Insects breed
- Ducks arrive
- Geese arrive
- Herons hunt the edges

The player didn't buy these creatures. They *showed up* because the habitat was right.

Implementation:
```ts
WildlifeSystem runs periodically:
  for each wild_species_def:
    if season == migration_season:
      check nearby habitats
      if habitat_quality.meets_threshold(species_def.habitat_needs):
        if random < attraction_chance:
          create Entity for wild duck pair
          create Event("wildlife_arrived", species: "mallard", location: pond)
```

### Three Tiers of Animal Acquisition
1. **Purchased livestock:** Chickens, goats, rabbits — bought from market, known quantities
2. **Attracted wildlife:** Ducks on the pond, bees in a hollow log — arrive because conditions are right
3. **Earned companions:** A goose imprinted on the fish-feeding worker, a stray dog become herder, pond-born ducks who return each spring — creatures with *history*

---

## Neighbor & Conflict System

### The Line
**Yes:** Neighborly tension. Disagreements. Personality clashes. Friction with consequences.
**No:** Violence. Weapons. Forced seizure. Death by human hand.

### Conflict Types
- **Property boundaries:** Fences shift. Animals wander. A tree drops fruit on the wrong side.
- **Labor poaching:** Your best worker gets offered more money next door. Match it? Let them go? Wish them well?
- **Resource sharing:** Creek water in a dry August. Who gets how much?
- **Reputation:** A neighbor tells others you're difficult. Worker pool shrinks. Market prices shift slightly. Nothing overt — just friction.
- **Theft:** Driven by `OpportunitySystem` — grievance + accessible target + acceptable social risk → possible action. Player investigates via evidence and beliefs, or lets it go.

### Resolution Paths
Talk it out. Offer something. Wait it out. Let the relationship cool and rebuild later. Or don't. All mediated through `RelationshipSystem` and `ReputationSystem`.

### Design Principle
Neighbors aren't enemies. They're people you share a fence line with for thirty years. You'll need each other. You'll annoy each other. The game is about navigating interdependence with friction.

---

## Farm Visiting & Sharing

### No Competition, No Leaderboards
Farms are shared, not judged. Visibility without extraction. Community without comparison.

### Passive Sharing
- Every farm has a unique code or name
- Browseable directory — not ranked, not scored, just *available*
- Search by farm name, biome, years active
- No leaderboards, no ratings

### Active Invitation
- Player generates a one-time invite link or code
- Friend enters it, arrives at farm boundary — a gate, a path entrance
- Host can be present or not

### The Visit
- Visitor walks the farm freely, full movement, real-time
- Sees pond with ducks, garden path, dog on porch, worker on bench
- Sees rabbits with frozen bottles in summer, auto door on henhouse
- Sees geese being territorial
- No interaction with objects, animals, or workers
- No griefing — just *witnessing*

### Visitor Permissions
**Can do:**
- Walk freely
- See animal names, worker names, building labels
- View simple farm summary (years active, animals, workers, achievements)
- Leave a single emoji or short note (host can disable)
- Take screenshots

**Cannot do:**
- Touch anything
- Open doors or gates
- Interact with animals or workers
- See financial data or private worker information
- Stay forever (visit duration optionally limited by host)

### The Guest Book
Optional object — wooden post with notebook, stone with carved surface. Visitors leave a single message: *"Beautiful pond." "Your dog is wonderful." "The garden path at sunset."* Visible to future visitors and host. Not a chat system. A collection of small gifts.

### Why Sharing Matters
The walk around the pond is beautiful alone. It becomes meaningful when someone else sees it. A player thinks: *I want the garden path finished before Mari visits on Saturday.* Social motivation no internal system can generate. Visitors leave not with envy but with ideas: *I didn't know you could do that. Now I will.*

---

## Achievement Design

### "Nesting Ducks"
A certificate of ecological trust. Wild ducks choosing to nest means:
- Water quality is good
- Edges have cover
- Predator pressure is low
- The pond is *safe*

**Loseable:** Remove reeds, allow harassment, crash water quality → ducks abandon nest. Achievement icon changes. The systems tell the story — no explanation needed.

### Stewardship Achievement Category
Achievements not about extraction, but *presence*:

- **Nesting Ducks** — Wild waterfowl breed on the farm
- **The Hive Found You** — Wild swarm takes an empty hive box
- **Hedgerow Harvest** — Forageable berries and nuts in uncut margins
- **Night Chorus** — Frogs establish in the pond (and eat pests)
- **The Old Tree** — A left-standing tree becomes a raptor perch, reducing rodent pressure
- **The Path at Sunset** — Build a garden path and walk it with your dog
- **The Guest Book** — Receive messages from visitors on three different days

These reward *restraint*, not extraction. The player who leaves margins, tolerates mess, values habitat — their farm looks different. Not richer. Wilder. More alive.

---

## Seasonal Rituals

Each season has preventive care rhythms:

### Summer
- Freeze water bottles for rabbits
- Check henhouse ventilation
- Provide shade for goats
- Monitor pond oxygen levels
- Evening walks with the dog when heat breaks

### Winter
- Break ice on water troughs
- Deep bedding in shelters
- Check stored feed for damp
- Secure structures
- Training sessions with dog by the fire

### Spring
- Clean out winter bedding
- Check fences after storms
- Prepare planting beds
- Pond maintenance
- New lambs, chicks, ducklings

### Autumn
- Secure structures before weather turns
- Stockpile feed
- Bring animals under cover or cull
- Final harvest push
- Rake the garden path

---

## Content Expansion Model

The architecture is a force multiplier. Every new species, crop, tool, or building is mostly definition data. Systems don't grow. Content does.

**Adding sheep:**
- `SpeciesDef` row
- `wool_growth` reuses `GrowthComponent` with `produces: "wool"` tag
- `TaskDef` entries for shearing, reusing existing skill checks
- No new code

**Adding honey:**
- `StructureDef` for hive box
- `SpeciesDef` for bees (wild, attractable via `WildlifeSystem`)
- `TaskDef` for honey harvest
- Honey is an `ItemDef` with tags: `[sweet, sellable, preservable]`
- No new code

The 50th animal species costs as much design work as the 5th. The systems already handle it.

---

## Emergent Moments

The game's deepest experiences can't be scripted. They arise from systems intersecting:

- **The Walk Around the Pond:** Dog entity with `bond > 0.8` + path exists + pond exists + evening light. Player walks. `CompanionSystem` triggers `FollowBehavior`. The generous clock gives permission for this — it's not wasted time, it's the point.
- **The Worker Who Stayed:** `RelationshipComponent` modified by player actions over time. No quest. Systems responding to history.
- **The Goose Returns:** `WildlifeSystem` checks `HabitatQualityComponent`. Pond still good. Goose returns with mate. Event created.
- **The Empty Nest:** Achievement gated on habitat thresholds. Thresholds drop. Achievement icon changes. Player knows why. Game doesn't explain.
- **The Theft Investigated:** Event recorded. Beliefs distributed. Evidence placed. Player finds boot tracks, talks to neighbor who heard noise, confronts Bob. Or doesn't. All data-driven.
- **The Visitor at Sunset:** Friend walks the garden path. Leaves note in guest book. Host reads it next morning.
- **The Bench at Noon:** Worker sits. Stress drops. Player notices. Nothing happens — and that's the moment.

---

## Emotional Arc Summary

1. Manual rituals build love for animals as individuals
2. The slow clock gives permission to care, not just optimize
3. Delegation teaches trust and the cost of human systems
4. Automation rewards mastery but introduces new failure modes
5. Relationships deepen — with workers, with the dog, with neighbors, with the land itself
6. Ecological response validates stewardship
7. Beauty becomes a yield worth pursuing
8. Sharing transforms private accomplishment into communal experience
9. Resilience becomes the truest measure of success

The player who reaches endgame isn't a factory manager. They're the owner of a thriving, mostly-self-running homestead, sitting on the porch with a ledger, dog at their feet, watching sunset over the pond — and knowing exactly what to do when something breaks. And sometimes, a friend walks through the gate to see what they've built.

---

## Technical & Aesthetic Notes

- **Engine:** raylib with tile system
- **Aesthetic:** Link to the Past / Harvest Moon pixel art
- **Architecture:** Entity-component-system with append-only event ledger, belief/evidence model, declarative task definitions
- **Data Philosophy:** Objects are rows. Behavior is systems. Meaning comes from events. Complexity is combinatorial, not hierarchical.
- **UI Philosophy:** Radically legible. Color-coded emotional states. Problems visible in-world (chickens huddle when stressed, workers slouch when tired, rabbits pant in heat). No opaque spreadsheets.
- **Key Views:** World view, kanban board, Gantt timeline, worker list
- **Time System:** Default ~90-120 min/day (Act 1), adjustable with pause/play/fast-forward/sleep controls
- **Multiplayer:** Asynchronous only. Farm visiting, guest books. No real-time co-op. No competitive modes.

---

*Generated from design discussion, April 2026*