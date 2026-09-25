# scripts/battlefield/

Dynasty-Warriors-style battlefield mode. See `docs/design/fusion_direction.md` and DECISIONS.md
(2026-09-25, "Battlefield (musou) mode").

| File | Role |
|---|---|
| `battlefield_run.gd` | Scene orchestrator: builds the map, seeds garrisons/officers, reinforcements, capture → commander → victory, rewards |
| `battlefield_def.gd`, `battlefield_base_def.gd` | Resources describing a battlefield and its bases |
| `horde_director.gd` | Drives every grunt in one batched loop (separation, attack tokens, telegraphs, animation) |
| `horde_grunt.gd` | Pooled lightweight enemy: health + hurtbox, no per-node AI |
| `horde_unit_def.gd` | Grunt type data (stats, attack, procedural body style) |
| `horde_mesh_factory.gd` | Procedural low-poly biomonster meshes, cached per type |
| `horde_steering.gd` | Pure steering math (ring slots, separation, seek, strike arc) — unit tested |
| `spatial_hash_grid.gd` | XZ spatial hash + one-pass separation sum — unit tested |
| `attack_token_pool.gd` | Limits simultaneous attackers — unit tested |
| `combination_gauge.gd` | Musou meter (hits, KOs, damage taken) — unit tested |
| `battle_tally.gd` | KOs, officer KOs, rank, rewards — unit tested |
| `battlefield_control.gd` | Bases, garrisons, capture, morale → enemy aggression — unit tested |
| `battlefield_environment.gd`, `battlefield_base_marker.gd` | Procedural desert map + base visuals |
| `battlefield_hud.gd`, `battlefield_minimap.gd`, `battlefield_results.gd`, `battlefield_vfx.gd` | UI and effects |

Rules: gameplay numbers live in `Constants` (Battlefield section); cross-system events go through
`EventBus` (`battlefield_*`, `combat_combination_*`); pure logic gets GdUnit4 tests in `tests/unit/battlefield/`.
