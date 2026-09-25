// ECS update: structure-of-arrays storage, bitmask queries, 1M entities.
// Timed region: 1000 ticks of movement, damage, and cleanup systems.
package main

import (
	"fmt"
	"time"
)

const (
	entities = 1000000
	ticks    = 1000
	hasPos   = 1
	hasVel   = 2
	hasHP    = 4
	hasDmg   = 8
)

type Position struct{ x, y float32 }
type Velocity struct{ x, y float32 }
type Health struct{ hp float32 }
type Damage struct{ dps float32 }

type World struct {
	mask  []uint8
	pos   []Position
	vel   []Velocity
	hp    []Health
	dmg   []Damage
	count int
}

func newWorld() *World {
	return &World{
		mask: make([]uint8, entities),
		pos:  make([]Position, entities),
		vel:  make([]Velocity, entities),
		hp:   make([]Health, entities),
		dmg:  make([]Damage, entities),
	}
}

func (w *World) create() int {
	id := w.count
	w.count++
	return id
}

// Explicit float32 conversions on the products keep Go from fusing them into
// FMAs on arm64, so every language computes the same rounded f32 values.
func (w *World) systemMovement(dt float32) {
	const need = hasPos | hasVel
	for i := 0; i < w.count; i++ {
		if w.mask[i]&need == need {
			w.pos[i].x += float32(w.vel[i].x * dt)
			w.pos[i].y += float32(w.vel[i].y * dt)
		}
	}
}

func (w *World) systemDamage(dt float32) {
	const need = hasHP | hasDmg
	for i := 0; i < w.count; i++ {
		if w.mask[i]&need == need {
			w.hp[i].hp -= float32(w.dmg[i].dps * dt)
		}
	}
}

func (w *World) systemCleanup() {
	for i := 0; i < w.count; i++ {
		if w.mask[i]&hasHP != 0 && w.hp[i].hp <= 0 {
			w.mask[i] = 0
		}
	}
}

func (w *World) countAlive() int {
	n := 0
	for i := 0; i < w.count; i++ {
		if w.mask[i] != 0 {
			n++
		}
	}
	return n
}

func main() {
	w := newWorld()
	// 70% move, 50% have health, 30% take damage.
	for i := uint32(0); i < entities; i++ {
		id := w.create()
		fi := float32(i)
		if i%10 < 7 {
			w.mask[id] |= hasPos
			w.pos[id] = Position{float32(fi * 0.1), float32(fi * 0.2)}
			w.mask[id] |= hasVel
			w.vel[id] = Velocity{float32(float32(i%100) * 0.01), float32(float32((i+50)%100) * 0.01)}
		}
		if i%10 < 5 {
			w.mask[id] |= hasHP
			w.hp[id] = Health{100}
		}
		if i%10 < 3 {
			w.mask[id] |= hasDmg
			w.dmg[id] = Damage{0.5 + float32(float32(i%10)*0.1)}
		}
	}
	aliveBefore := w.countAlive()

	start := time.Now()
	dt := float32(1.0 / 60.0)
	for t := 0; t < ticks; t++ {
		w.systemMovement(dt)
		w.systemDamage(dt)
		w.systemCleanup()
	}
	elapsedMs := float64(time.Since(start).Nanoseconds()) / 1e6

	sum := 0.0
	for i := 0; i < w.count; i++ {
		if w.mask[i]&hasPos != 0 {
			sum += float64(w.pos[i].x)
		}
	}
	fmt.Printf("entities %d alive_before %d alive_after %d\n", w.count, aliveBefore, w.countAlive())
	fmt.Printf("elapsed_ms %.3f\n", elapsedMs)
	fmt.Printf("checksum %.2f\n", sum)
}
