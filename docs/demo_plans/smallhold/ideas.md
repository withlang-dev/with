Yes — and that is probably the correct instinct.

Dwarf Fortress feels like it models “everything as an object with history,” but for **Smallhold**, I think the better architecture is:

> **Small number of normalized data tables + generic rule processors + event ledger.**

Not giant inheritance trees. Not bespoke object classes for every thing. More like a simulation database.

A pig should not be a complex `Pig` object full of special logic. It should be structured data:

```ts
Entity {
  id: "pig_001",
  kind: "animal",
  species: "pig",
  location: tileId,
  components: {
    hunger: { value: 42 },
    health: { value: 87 },
    stress: { value: 15 },
    containment: { requiredFenceStrength: 3 },
    ownership: { householdId: "player" },
    inventory: null
  }
}
```

Then generic systems act on it.

```ts
HungerSystem:
  for entities with hunger:
    hunger.value += species.metabolismRate * deltaTime

StressSystem:
  for entities with stress:
    stress += crowding + filth + hunger + noise + badWeather

EscapeSystem:
  for animals with containment:
    if enclosure.strength < requiredFenceStrength:
      create Event("escape_risk")
```

The pig is interesting not because the pig class is smart, but because it has the right components and participates in shared systems.

That also fits your emergent complexity goal better. The simulation becomes a set of **pressure transforms**.

```plaintext
potatoes -> feed -> pig -> manure -> fertility -> potatoes
```

```plaintext
overwork -> fatigue -> poor task quality -> crop loss -> hunger -> social desperation
```

```plaintext
escaped animal -> property damage -> resentment -> theft risk -> investigation -> feud
```

The ideal architecture might look like this:

## 1. Entities

Anything that exists as an addressable thing.

```ts
Entity:
- id
- type
- subtype
- location
- owner_id
- tags
```

Examples:

* player
* pig
* neighbor
* potato sack
* potato plant
* RV
* fence segment
* manure pile
* tool

## 2. Components

Reusable state chunks.

```ts
HungerComponent
EnergyComponent
HealthComponent
StressComponent
RelationshipComponent
OwnershipComponent
InventoryComponent
GrowthComponent
DecayComponent
ContainmentComponent
FilthComponent
SkillComponent
NeedComponent
```

Components are where complexity lives, but each one stays simple.

## 3. Definitions

Static data for species, crops, buildings, tools, tasks.

```ts
SpeciesDef:
- id: pig
- diet_tags: [vegetable, grain, scraps]
- hunger_rate
- manure_rate
- escape_pressure
- min_comfort
- adult_weight
```

```ts
CropDef:
- id: potato
- growth_days
- water_need
- fertility_need
- edible: true
- seedable: true
- feed_value
- storage_life_days
```

## 4. Systems

Pure processors that transform state.

```plaintext
NeedSystem
GrowthSystem
DecaySystem
TaskSystem
MovementSystem
RelationshipSystem
ReputationSystem
DiseaseSystem
MarketSystem
WeatherSystem
```

Each system should be dumb and general.

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

That is the difference between scripted complexity and emergent complexity.

## 5. Events

This is crucial.

You need an append-only event ledger.

```ts
Event:
- id
- time
- type
- actors
- targets
- location
- causes
- effects
- visibility
```

Example:

```ts
{
  type: "animal_escaped",
  time: "Day 6 04:20",
  actors: ["pig_001"],
  targets: ["fence_003"],
  location: "north_pen",
  causes: [
    { type: "weak_containment", value: 0.72 },
    { type: "hunger", value: 0.41 }
  ],
  effects: [
    { component: "location", entity: "pig_001", from: "pen", to: "neighbor_yard" }
  ],
  visibility: {
    player: "unknown",
    neighbor_bob: "observed"
  }
}
```

That ledger gives you memory, investigation, relationships, rumors, blame, and storytelling without hardcoding questlines.

## 6. Claims / Beliefs

For social systems, the game should distinguish **what happened** from **who knows or believes what happened**.

```ts
Fact:
- pig_001 was stolen by neighbor_bob
```

```ts
Belief:
- player suspects pig escaped
- neighbor_bob knows he stole pig
- neighbor_mary heard squealing at night
- church_group believes player neglects animals
```

This is where investigation becomes systemic.

The actual event ledger says Bob took the pig.

But the player only has evidence:

```ts
Evidence:
- broken latch
- boot tracks
- blood near Bob's shed
- missing potato scraps
- Bob suddenly has pork
```

You can implement that with structured data too:

```ts
Evidence {
  id
  source_event_id
  type
  location
  discoverability
  decay_time
  points_to
  ambiguity
}
```

Now “bother to investigate?” becomes a real task chain, not a dialogue branch.

## 7. Tasks as data, not code

A task should be declarative:

```ts
TaskDef:
  id: feed_animal
  requirements:
    - actor_has_energy > 5
    - target_has_component: hunger
    - inventory_has_tag: feed
  duration:
    base_minutes: 20
    modifiers:
      - actor.skill.livestock: -0.05
      - distance: +0.1
      - actor.energy_low: +0.25
  effects:
    - target.hunger -= feed.nutrition
    - actor.energy -= 3
    - create_event: animal_fed
```

That gives you a path to add a lot of content without adding code each time.

## The core principle

I’d summarize your architecture as:

> **Objects are rows. Behavior is systems. Meaning comes from events.**

Or even sharper:

> **Do not give the pig logic. Give the world rules that make a pig matter.**

For Smallhold, that is perfect.

The data model does not need infinite object orientation. It needs:

* entity IDs
* components
* static definitions
* generic systems
* tasks
* event ledger
* beliefs/evidence
* relationships/reputation

That is enough to model pig theft, neighbor anger, manure, hunger, labor, crop failure, and social consequences from the same primitives.
