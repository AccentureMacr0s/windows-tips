# Electromagnetic Aircraft — Design Concept

A conceptual design for an electromagnetic aircraft that uses rotating magnets and charged-particle reflectors to generate lift.  The folder contains a description of the apparatus, its operating principles, and an [LTspice](https://www.analog.com/en/resources/design-tools-and-calculators/ltspice-simulator.html) circuit (`circuit.asc`) that models the key electromagnetic interactions.

---

## Repository Structure

```
electromagnetic-device/
├── README.md      ← this file
└── circuit.asc    ← LTspice netlist for simulation
```

---

## I. Apparatus Construction

### Main Elements

| # | Element | Purpose |
|---|---------|---------|
| 1 | **Two cylindrical magnets** (bottom) | Rotate in opposite directions at high speed to generate a vortex electromagnetic field |
| 2 | **Small driver magnets** | Initiate rotation of the main cylinders |
| 3 | **Parabolic reflector mirror** | Focuses downward the stream of charged particles; coated with heat-resistant metallised ceramic |
| 4 | **Air-ionisation system** | High-frequency generator + electrodes that produce a stable plasma stream |
| 5 | **Cooling system** | Compensates for overheating of the mirror and magnets |
| 6 | **Control coils / superconductors** | Manage currents and field resonance for stabilisation |

---

## II. Operating Principles

### 1 — Charged-Particle Stream
1. The ioniser creates a stream of charged particles in the upper section of the craft.
2. The rotating-cylinder magnetic field captures those particles, accelerates them, and directs them downward.
3. The parabolic mirror (dielectric or conductive) concentrates and collimates the beam.

### 2 — Field Control
- Counter-rotating magnets produce a vortex electromagnetic field that stabilises the craft attitude.
- Electrodes set the initial trajectory of the ionised stream.

### 3 — Thrust Generation
- The reactive force from ejecting particles downward produces upward lift.

---

## III. Circuit Description (for LTspice)

The netlist (`circuit.asc`) models the following subsystems:

| Component | Role |
|-----------|------|
| `V1` (24 V DC) | Power supply for magnet coils |
| `V2` (5 kV DC) | High-voltage supply for ioniser |
| `L1` (100 µH) | First cylindrical-magnet coil (figure-eight double loop) |
| `L2` (100 µH) | Second cylindrical-magnet coil → drives mirror-plate current |
| `R1` (1 Ω) | Series resistance of coil winding |
| `R2` (10 MΩ) | Ioniser load / discharge resistor |
| `C1` (100 µF) | Supply decoupling / voltage stabilisation |
| `C2` (1 nF) | High-frequency noise suppression on ioniser rail |
| `D1` | Flyback protection for the L1/L2 coil pair (magnet drive circuit) |
| `D2` | Reverse-current protection for the ioniser supply circuit |

### Simplified Topology

```
                                    D1
V1 (+24 V) ──┬──── L1 ────┬───────►|──── GND
             │             │
             C1            R1
             │             │
            GND           L2 ──── (conceptual: represents mirror-plate coil output;
                           │       actual driven load not modelled in circuit.asc)
                          D2
                           │
                          GND

V2 (+5 kV) ──── R2 ──── ioniser electrode
             │
             C2
             │
            GND
```

---

## IV. Construction Layers

### Upper Layer
- Magnet coil power supply (`V1`) and the two cylindrical magnets that establish the primary field.
- Ioniser power supply (`V2`) with electrodes that inject the charged-particle stream.

### Lower Layer
- Reflector plate driven by `L2`; concentrates and collimates particles downward.
- Cooling channels and thermal interface between mirror and structural frame.

---

## V. Simulation Steps

1. Open `circuit.asc` in LTspice.
2. Run a **DC Operating Point** (`.op`) analysis to verify quiescent currents through `L1`, `L2`.
3. Run a **Transient** (`.tran 0 10m 0 1u`) simulation to observe the coil current ramp-up and flyback behaviour on `D1` / `D2`.
4. Optionally add a PWM voltage source on `V1` to model pulsed magnet drive and observe resonance.
