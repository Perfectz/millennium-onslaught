# resources/items/

PSIV consumables as `ItemDef` resources (script: `item_def.gd`). File name = `item_id`.
`GameState` hydrates inventory entries from here (and from `resources/equipment/` for gear).
Heal amounts are ratios of max HP so they stay useful across levels; `auto_use_on_pickup`
items (the mates) are eaten instantly when grabbed on a battlefield.
