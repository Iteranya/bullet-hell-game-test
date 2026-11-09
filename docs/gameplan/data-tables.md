# TOWERCHAIN — Data Tables (Mirror of res://data/*.json)

**Note:** This file is documentation only. Edit the JSON files in
`E:\HERMES\godot-mcp-test\data\` directly — GDScript contains no balance numbers.
`values` below are the live defaults as of Rev. 8 (2026-11-09, after the `area.json` split).

---

## player.json

| Field | Value | Description |
|---|---|---|
| `hp` | 100 | Player hit points |
| `speed` | 260 | Base move px/s |
| `damage` | 6 | Base bullet damage |
| `fire_rate` | 4 | Shots per second |
| `bullet_type` | `player_bolt` | Bullet kind |
| `hit_radius_px` | 8 | Hitbox size |

## towers.json (single template — Homebase is `is_homebase: true` on a field instance)

| Field | Value | Description |
|---|---|---|
| `field.hp` | 300 | Tower HP (Homebase: invulnerable via boolean, `take_damage` returns early) |
| `field.invulnerable` | false | Template flag — ignored; instance boolean governs |
| `field.aura_R` | 250 | Buff radius |
| `field.damage` | 8 | Bullet damage |
| `field.fire_rate` | 2 | Shots per second |
| `field.build_cost` | 20 | Base Alloy cost (see economy scaling) |

## area.json (grid + limits)

| Field | Value | Description |
|---|---|---|
| `grid.cell_size_px` | 100 | Grid block size |
| `grid.cols` | 16 | Grid width (cells) |
| `grid.rows` | 16 | Grid height (cells) |
| `limits.max_towers` | 6 | Total tower cap, Homebase included |
| `limits.max_place_range_px` | 520 | Max distance from Player to place |
| `limits.homebase_safe_radius_px` | 220 | Safe radius around Homebase |
| `areas[homebase]` | col 7, row 7, 2×2 | `placeable: false`, no spawns |
| `areas[field]` | col 0, row 0, 16×16 | `placeable: true`, spawns enemies |

Placement rule: mouse position → `(col,row)` → cell covered by a non-placeable area is rejected.

## buff.json

| Field | Value | Description |
|---|---|---|
| `s_max` | 1.0 | Max buff at tower centre |
| `s_min` | 0.2 | Min buff at aura edge |
| `resonance_bonus` | 0.25 | Bonus per extra overlapping aura |
| `stacking_cap` | 2.5 | Hard cap on total buff |

## enemies.json

| Field | Value | Description |
|---|---|---|
| `chaser.hp` | 20 | Chaser hit points |
| `chaser.speed` | 90 | Chaser move px/s |
| `chaser.damage` | 8 | Contact damage |
| `chaser.drop` | `[1,2]` | Alloy dropped |
| `chaser.bullet_pattern` | `none` | No bullets |
| `spinner.hp` | 40 | Spinner hit points |
| `spinner.speed` | 40 | Spinner move px/s |
| `spinner.damage` | 10 | Spinner damage |
| `spinner.drop` | `[3,3]` | Alloy dropped |
| `spinner.bullet_pattern` | `radial_8` | 8-way burst (not yet fired) |

## bullets.json

| Field | Value | Description |
|---|---|---|
| `player_bolt.speed` | 420 | Bolt speed px/s (code still hardcodes 420) |
| `player_bolt.damage` | 6 | Damage |
| `player_bolt.radius` | 4 | Bolt radius |
| `tower_bolt.speed` | 360 | Bolt speed px/s |
| `tower_bolt.damage` | 8 | Damage |
| `tower_bolt.radius` | 5 | Bolt radius |
| `enemy_bolt.speed` | 160 | Bolt speed px/s |
| `enemy_bolt.damage` | 8 | Damage |
| `enemy_bolt.radius` | 5 | Bolt radius |

## wave_table.json

| Field | Value | Description |
|---|---|---|
| `wave_interval_s` | 20 | Time between waves |
| `hp_scale_per_wave` | 0.15 | Enemy HP growth per wave (not yet applied) |
| `waves[1]` | 3 chaser, 0 spinner | Wave 1 composition |
| `waves[2]` | 5 chaser, 1 spinner | Wave 2 composition |
| `waves[3]` | 7 chaser, 2 spinner | Wave 3 composition |
| `waves[4]` | 9 chaser, 3 spinner | Wave 4 composition |
| `waves[5]` | 12 chaser, 4 spinner | Wave 5 composition, loops endlessly |

## economy.json

| Field | Value | Description |
|---|---|---|
| `base_build_cost` | 20 | First field tower cost |
| `cost_scale_per_tower` | 0.5 | +50% of base per tower built |
| `cost_growth` | 2.0 | Upgrade tier growth |
| `upgrade_costs.guns` | `[20,40,80,160]` | Per tier T1→T4 |
| `upgrade_costs.aura` | `[20,40,80,160]` | Per tier T1→T4 |
| `upgrade_costs.utility` | `[20,40,80,160]` | Per tier T1→T4 |

## resources.json

| Field | Value | Description |
|---|---|---|
| `alloy.magnet_radius_px` | 120 | Alloy magnet range |
| `alloy.magnet_only_in_aura` | true | Magnet only when buffed |

## maps.json

| Field | Value | Description |
|---|---|---|
| `arena_size_px` | 1600 | Playable size (Player clamped) |
| `spawn_radius_px` | 700 | Enemy spawn distance |

## art_manifest.json

| Field | Value | Description |
|---|---|---|
| `player.size_px` | 18 | Blue square size |
| `tower.size_px` | 32 | Gold square size |
| `chaser.size_px` | 14 | Red square size |
| `spinner.size_px` | 20 | Orange diamond size |
| `alloy.size_px` | 8 | Yellow diamond size |

## ally_towers.json / ally_bond.json / story_chapters.json (now tower_types.json — behaviours, not shoot-only)

| File | Field | Value | Description |
|---|---|---|---|
| `ally_towers` | `ally_01.aura_R` | 240 | Ally aura radius |
| `ally_towers` | `bullet_pattern.count` | 2 | Extra bolts per volley |
| `ally_towers` | `bullet_pattern.spread_deg` | 12 | Spread angle |
| `ally_towers` | `bullet_pattern.damage_mul` | 0.8 | Damage multiplier |
| `ally_towers` | `synergy_range_px` | 300 | Adjacency check range |
| `ally_towers` | `synergy_bonus` | 0.25 | Two-tower synergy bonus |
| `ally_bond` | `per_kill_in_aura` | 2 | Bond per kill in aura |
| `ally_bond` | `per_wave_survived_in_aura` | 25 | Bond per wave survived |
| `ally_bond` | `per_alloy_collected_in_aura` | 1 | Bond per Alloy collected |
| `story_chapters` | `chapter_01.bond_cap` | 250 | Current bond ceiling |
| `story_chapters` | `chapter_01.mission_id` | `mission_clear_wave_5` | Mission to raise cap |
| `story_chapters` | `chapter_02.bond_cap` | 500 | Next ceiling |

## cutscenes/triggers.json

| Event | Script file | Start label |
|---|---|---|
| `game_start` | `res://data/cutscenes/towerchain.json` | `start` |
| `bond_threshold` | `res://data/cutscenes/towerchain.json` | `start` |
| `mission_complete` | `res://data/cutscenes/towerchain.json` | `start` |

---

## Pending cleanups (not blockers for MVP)
- `Bullet.gd` hardcodes 420px/s — read `bullets.json` speed instead.
- `strings.json` still says “40 Alloy” — update to dynamic cost.
- Enemy `damage` not applied to Player (enemy bullets have no projectile yet).
- `spinner.radial_8` pattern not fired.
- Ally companion sprite, bond caps/missions, upgrade UI not yet implemented.
