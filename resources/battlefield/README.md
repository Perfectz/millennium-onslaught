# resources/battlefield/

Data for battlefield mode. Canon roster from `docs/design/psiv_content_bible.md` (§5 enemies by area).

- `piata_plains.tres` — "Battle of the Motavian Plains" (id kept for save compatibility): nests led by
  Speard / Caterpillar / Fanbite officers, commander Scorpirus.
- `units/` — `HordeUnitDef` grunts named after PSIV enemies (Locusta, Crawler, Mini Worm, Infant Worm,
  Monster Fly, Sand Newt, Xanafalgue, Zoran Bult). HP = PSIV HP x 0.5 (musou grunts fall in 1-3 hits).
- `officers/` — `EnemyDef`s for officers/commanders (PSIV HP x 1.5, commanders x 3.5) using procedural bodies.
- `bodies/` — `HordeUnitDef`s used only as the procedural look of officers.
- `attacks/` — `AttackDef`s used by grunts.
