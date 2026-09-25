// N-body: five-body gravitational integration in f64, 50M steps.
// Timed region: the integration loop. Checksum: final system energy.
package main

import (
	"fmt"
	"math"
	"time"
)

const (
	steps       = 50000000
	solarMass   = 4 * math.Pi * math.Pi
	daysPerYear = 365.24
)

type Body struct{ x, y, z, vx, vy, vz, mass float64 }

func solarSystem() []Body {
	return []Body{
		{0, 0, 0, 0, 0, 0, solarMass},
		{4.84143144246472090e+00, -1.16032004402742839e+00, -1.03622044471123109e-01,
			1.66007664274403694e-03 * daysPerYear, 7.69901118419740425e-03 * daysPerYear,
			-6.90460016972063023e-05 * daysPerYear, 9.54791938424326609e-04 * solarMass},
		{8.34336671824457987e+00, 4.12479856412430479e+00, -4.03523417114321381e-01,
			-2.76742510726862411e-03 * daysPerYear, 4.99852801234917238e-03 * daysPerYear,
			2.30417297573763929e-05 * daysPerYear, 2.85885980666130812e-04 * solarMass},
		{1.28943695621391310e+01, -1.51111514016986312e+01, -2.23307578892655734e-01,
			2.96460137564761618e-03 * daysPerYear, 2.37847173959480950e-03 * daysPerYear,
			-2.96589568540237556e-05 * daysPerYear, 4.36624404335156298e-05 * solarMass},
		{1.53796971148509165e+01, -2.59193146099879641e+01, 1.79258772950371181e-01,
			2.68067772490389322e-03 * daysPerYear, 1.62824170038242295e-03 * daysPerYear,
			-9.51592254519715870e-05 * daysPerYear, 5.15138902046611451e-05 * solarMass},
	}
}

func offsetMomentum(bodies []Body) {
	var px, py, pz float64
	for _, b := range bodies {
		px += float64(b.vx * b.mass)
		py += float64(b.vy * b.mass)
		pz += float64(b.vz * b.mass)
	}
	bodies[0].vx = -px / solarMass
	bodies[0].vy = -py / solarMass
	bodies[0].vz = -pz / solarMass
}

// Explicit float64 conversions around products stop Go from fusing them into
// FMAs on arm64, keeping results bit-identical with the other languages.
func energy(bodies []Body) float64 {
	e := 0.0
	for i, b := range bodies {
		e += float64(0.5 * b.mass * (float64(b.vx*b.vx) + float64(b.vy*b.vy) + float64(b.vz*b.vz)))
		for _, o := range bodies[i+1:] {
			dx := b.x - o.x
			dy := b.y - o.y
			dz := b.z - o.z
			e -= float64(b.mass*o.mass) / math.Sqrt(float64(dx*dx)+float64(dy*dy)+float64(dz*dz))
		}
	}
	return e
}

func advance(bodies []Body, dt float64) {
	n := len(bodies)
	for i := 0; i < n; i++ {
		for j := i + 1; j < n; j++ {
			dx := bodies[i].x - bodies[j].x
			dy := bodies[i].y - bodies[j].y
			dz := bodies[i].z - bodies[j].z
			distance2 := float64(dx*dx) + float64(dy*dy) + float64(dz*dz)
			mag := dt / float64(distance2*math.Sqrt(distance2))
			mi := float64(bodies[i].mass * mag)
			mj := float64(bodies[j].mass * mag)
			bodies[i].vx -= float64(dx * mj)
			bodies[i].vy -= float64(dy * mj)
			bodies[i].vz -= float64(dz * mj)
			bodies[j].vx += float64(dx * mi)
			bodies[j].vy += float64(dy * mi)
			bodies[j].vz += float64(dz * mi)
		}
	}
	for i := range bodies {
		bodies[i].x += float64(dt * bodies[i].vx)
		bodies[i].y += float64(dt * bodies[i].vy)
		bodies[i].z += float64(dt * bodies[i].vz)
	}
}

func main() {
	bodies := solarSystem()
	offsetMomentum(bodies)
	before := energy(bodies)
	start := time.Now()
	for i := 0; i < steps; i++ {
		advance(bodies, 0.01)
	}
	elapsedMs := float64(time.Since(start).Nanoseconds()) / 1e6
	fmt.Printf("energy_before %.9f\n", before)
	fmt.Printf("elapsed_ms %.3f\n", elapsedMs)
	fmt.Printf("checksum %.9f\n", energy(bodies))
}
