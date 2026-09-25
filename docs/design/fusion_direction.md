# Fusion Direction — Dynasty Warriors × Phantasy Star IV

**Status:** living document. Chapter-by-chapter content mapping lands in `docs/design/psiv_content_bible.md`.

## The pitch
Play the story of *Phantasy Star IV: The End of the Millennium* — Chaz, Alys, Rune, Rika and the rest,
from the Piata Academy basement to the Profound Darkness — but fight it like Dynasty Warriors:
open battlefields with 100+ Bio-monsters, capturable bases, named officers, and screen-clearing
**Combination** attacks. Between battles it stays a JRPG: towns, shops, party, levels, techniques, equipment.

## Pillars
1. **Faithful to PSIV** — plot beats, party join/leave order, towns, dungeons, bosses, enemy roster,
   techniques/skills per character and learn levels, items and key items all follow the original.
   Where we invent (battle framing, officer names), it must fit the canon.
2. **Musou combat** — one hero cutting through crowds; officers and bosses are the "real" fights.
   Grunts are PSIV's regular enemies; officers/bosses are PSIV bosses and elite monsters.
3. **JRPG depth** — XP from every KO feeds the same level/tech-learning curve; party switching mid-battle;
   TP-costed techniques (Foi, Zan, Gra, Res, Megid...) usable in both battlefield and dungeon modes.
4. **Dungeons stay** — PSIV's dungeons are rebuilt as continuous stages whose layouts follow the
   original maps (floors, branches, key rooms, boss chamber placement), populated at musou density.

## Mode map
| PSIV content | Fusion treatment |
|---|---|
| Overworld travel between towns | Overworld hub (existing) — nodes follow PSIV's route and unlock by story flags |
| Towns (Piata, Mile, Zema, Molcum, Tonoe, Aiedo, Kadary...) | Town hubs: shop (PSIV items/equipment), inn, story scenes |
| Dungeons (Academy basement, Birth Valley, Zio's Fort...) | Stage dungeons with layouts adapted from the original maps |
| Random field encounters | **Battlefields** — open maps where the region's enemies attack in force |
| Bosses | Officers/commanders at the climax of a battlefield or dungeon |
| Macros / Combinations | **Combination gauge** attack, flavored by the active character's techniques |
| Monomate/Dimate/Trimate drops | Pickups dropped by KO'd enemies (musou "meat bun" equivalent) |

## Using the original ROM
The user supplied a PSIV (US, Bugfix v1.5) ROM as a **reference**. We read it for data
(name tables for enemies, items, equipment, techniques and skills; later stat tables and map
topology) to keep the fusion faithful. **Nothing from the ROM is committed**: no ROM file, no ripped
graphics, music, text dumps or maps. Assets are original (procedural/Blender/CC0) and names and design
follow the canon.

Decoded so far (text is ASCII−64, 0xFF-terminated):
- `0x280D0C` classes, then the full enemy name table (~150 entries: HELEX … XANAFALGUE, IGGLANOVA,
  LOCUSTA, CRAWLER, ZOL SLUG, RAPPY … ZIO, JUZA, DARK FORCE forms), followed by enemy attack names.
- `0x2AA1xx–0x2AB7xx` equipment → consumables (MONOMATE, DIMATE, TRIMATE, ANTIDOTE, STAR DEW,
  TELEPIPE, ESCAPIPE…) → key items (ALSHLINE, ECLPSTORCH, AERO PRISM, LAND ROVER, rings, ELSYDEON)
  → techniques (FOI/GIFOI/NAFOI, WAT, TSU, ZAN, GRA, MEGID, BROSE, VOL, SAVOL, GELUN, DORAN, SEALS,
  RIMIT, RES/GIRES/NARES, SAR, SHIFT, SANER, DEBAN, FEEVE, ANTI, RIMPA, REVER, REGEN, AROWS, RYUKA,
  HINAS) → skills (CROSSCUT, RAYBLADE, DBLSLASH, FLAELI, FLARE, VORTEX, ASTRAL, AIRSLASH, DISRUPT,
  HEWN, TANDLE, EFESS, LEGEON, BURSTROC, POSIBOLT, SWEEPING, PHONON, ST. FIRE, …, HOLYWORD…).

## Chapter 1 status (2026-09-25)
| Canon beat | Fusion content | State |
|---|---|---|
| Academy Basement (Igglanova) | `dungeon_1`: Xanafalgue/Zoran Bult swarms, Igglanova + Fission | playable end-to-end (headless walkthrough) |
| Motavian field encounters | Battle of the Motavian Plains (Locusta, Crawler, Mini/Infant Worm, Monster Fly, Sand Newt; Speard/Caterpillar/Fanbite officers; Scorpirus) | playable |
| Techniques/skills | 43 canon TechniqueDefs, per-character learnsets | done |
| Items | Monomate/Dimate/Trimate/Antidote/Dews/pipes, battlefield pickups | done |

## Next content milestones
1. Re-theme the Piata Plains slice to canon: grunt types = the region's PSIV enemies; officers and
   commander = the region's PSIV bosses; consumable pickups.
2. Character technique/skill lists and learn levels from the canon; techniques usable as spells in both modes.
3. Chapter 1 end-to-end: Piata → Academy basement → Mile/Zema → Birth Valley, with layouts adapted from the originals.
