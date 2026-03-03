# Stage Chunks

Modular Node3D scenes that tile along the X axis to form continuous stages.

## Chunk Structure

Each chunk is 24 units wide (configurable via StageDef.chunk_width).
Positioned by StageRunner at `X = chunk_index * chunk_width`.

```
ChunkRoot (Node3D)
├── Floor (StaticBody3D) — BoxShape3D(24, 1, 6) at Y=-0.5, Layer 1
├── Platforms (optional) — StaticBody3D, Layer 128
├── Throwables (optional) — ThrowableObject nodes
└── Hazards (optional) — HazardZone nodes
```

## Current Chunks

| Scene | Purpose |
|-------|---------|
| `chunk_start.tscn` | Player spawn area, no enemies |
| `chunk_street_a.tscn` | Basic walkway |
| `chunk_plaza_a.tscn` | Open area with side platforms (encounter zone) |
| `chunk_street_b.tscn` | Walkway with elevated platform |
| `chunk_plaza_b.tscn` | Open area (encounter zone) |
| `chunk_boss.tscn` | Boss arena with right wall boundary |

## Design Notes

- Floors connect seamlessly when tiled (each floor mesh centered at X=12 within chunk)
- No left/right walls between chunks — room_bounds in GameState handles player clamping
- Boss chunk has a right wall to close off the stage end
