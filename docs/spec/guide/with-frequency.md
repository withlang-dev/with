# 7.8 `with` Frequency

In a typical codebase, `with` appears pervasively:

```
// Initializing a game entity (Form 2: builder)
let enemy = with Enemy.new(enemy_type) as mut e:
    e.position = spawn_point
    e.health = with difficulty.health_multiplier() as mult:  // Form 3: binding
        base_health * mult
    e.ai_state = AiState.Idle

// Updating game state (Form 1: guarded + Form 4: record update)
with world.entities[enemy.id] as mut entity:
    let new_pos = { entity.position with             // Form 4: record update
        x: entity.position.x + velocity.x * dt
    }
    entity.position = new_pos

// Building an HTTP response (Form 2: builder)
let response = with HttpResponse.new(200) as mut r:
    r.header("Content-Type", "application/json")
    r.body(json_encode(data))

// Processing a batch (Form 1: guarded + Form 3: binding)
with db.transaction() as tx:
    let results = users.traverse(u =>
        with calculate_discount(u.tier, u.years) as discount:  // Form 3
            tx.update_price(u.id, u.base_price * (1.0 - discount))
    )
    results?
```
