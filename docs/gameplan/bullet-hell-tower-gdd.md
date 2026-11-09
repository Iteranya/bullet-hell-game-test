# TOWERCHAIN — Bullet-Hell Tower Buff Game
**Pitch and Plan — Artes draft, Nexus write-up — REVISED**
**Status:** Design only. No Godot implementation yet. No code written in this revision.
**Date:** 2026-11-09 (Rev. 8 — MVP design complete; genre/style/story agnostic confirmed)
**Supersedes:** Rev. 7 — completeness confirmed; backlog listed below; build still deferred.

---

## 1. Pitch in One Paragraph

Towerchain is a top-down bullet-hell where you are deliberately weak on your own. You gather resource shards from defeated enemies and spend them to build more Towers or upgrade existing ones. Each Tower shoots for you and projects a buff aura; the further you are from all Towers the weaker you get. Stand where two or more auras overlap and you gain a Resonance bonus on top of the stacked buffs. You do not level up — the Towers do. Push a chain of Towers as far as you can, or build one fortress — both are valid builds from the same data-driven systems.

## 2. Core Fantasy

- You are the field technician. Towers are power plant, artillery, and medic in one.
- Proximity = power. Overlap = bonus. The map is a risk-reward gradient.
- No player XP. Every resource earned goes into Tower construction.
- Visual Novel briefings between waves explain what the Towers see — the hell has a story.

## 3. Core Loop — Revised

1. **Fight.** You and your Tower(s) shoot enemies. Player alone is weak by design.
2. **Gather.** Defeated enemies drop Resource Shards (data-defined per enemy). Shards are attracted to you *only* when you are inside at least one aura — outside you must walk over them. This forces you back into buff range.
3. **Build or upgrade.** Spend resources to:
   - **Build a new Tower** — first build cheap, each additional Tower costs more (scales with tower count).
   - **Upgrade an existing Tower** — Guns / Aura / Utility tracks.
   - You choose expansion vs. depth every purchase.
4. **Seek overlap.** Place the next Tower so its aura overlaps the previous one. The intersection zone grants stacked buff + Resonance bonus.
5. **Survive escalating waves.** Lose at Player HP 0. Next wave begins. VN cutscene may trigger (see §4.7).

## 4. Key Mechanics — Mechanical Definitions

### 4.1 Player
- **Movement:** WASD / arrows. Dodge-focused, small hitbox (classic bullet-hell: 4px core).
- **Aim:** Mouse aim, hold LMB to fire. Player bullets weak without buff.
- **Health:** 100 HP. Contact + bullet damage.
- **No levelling:** Base stats fixed in `data/player.json`. All growth via Tower buff + Tower guns only.

### 4.2 Tower
- **Placement:** Click in placement mode. Cannot place on wall/water/spawn pad. Placement distance from Player capped (config value in `data/towers.json`: `max_place_range_px`).
- **Shooting:** Independent turret, nearest target in range, fires data-defined bullet type.
- **Buff Aura:** Radius `R_buff`. Strength at distance `d`:
  ```
  S(d) = S_max * clamp(1 - d / R_buff, S_min, 1)
  ```
  Example starting values (all in `data/buff.json`): `S_max = 1.0`, `S_min = 0.2`.
- **Build cost:** Scales with current tower count: `cost = base_build_cost * (1 + cost_scale_per_tower * tower_count)` — all numbers from `data/economy.json`, never hardcoded in GDScript.

### 4.2.1 Multi-Tower Stacking and Resonance — NEW
If you are in range of multiple Towers, buffs do not replace — they add, with a bonus:

```
raw_sum   = S_1 + S_2 + ... + S_N        (each computed by falloff above)
N         = number of auras covering player
total_S   = raw_sum * (1 + resonance_bonus * (N - 1))
total_S   = min(total_S, stacking_cap)
Player dmg = base_dmg * (0.5 + total_S)
```

Starting values in `data/buff.json`:
- `resonance_bonus = 0.25` — 2 towers: total is 125% of the raw sum; 3 towers: 150%.
- `stacking_cap = 2.5` — prevents infinite stacking from degenerate tower spam.
- Worked example: two Tower centres, each S = 0.8 → raw 1.6 → with bonus 2.0 → damage multiplier 2.5x base. Single tower centre would be 1.5x.
- Visual feedback: overlapping aura zones render brighter; HUD shows `x2 RESONANCE` when N ≥ 2.
- Tactical implication: Chain players place towers close enough to overlap for the bonus; Fortress players have N=1 always and must compensate with tier-4 Aura upgrades.

### 4.3 Tower Upgrades (all data-driven in `data/tower_upgrades.json`)
| Track | Examples (T1→T4) | Effect |
|---|---|---|
| **Guns** | Twin Barrel → Split Shot → Missile Pods | +damage, +projectiles, +fire rate |
| **Aura** | Extended Coil, Overdrive | +R_buff, +S_max, slower falloff |
| **Utility** | Repair Swarm, Magnet, Slow Field | Heal Tower, attract resources, slow enemies |

Each tier cost defined in data, not computed from a hard-coded formula in scripts (formula parameter `cost_growth = 2.0` lives in `economy.json`).

### 4.4 Enemies — Bullet-Hell Patterns (defined in `data/enemies.json`)
- **Chaser:** No bullets. Slow.
- **Spinner:** Stationary, radial burst (8-way, 12-way).
- **Sniper:** Single aimed fast bullet, long cooldown.
- **Tank:** Slow, high HP, large resource drop.
- **Splitter:** Splits into 3 Chasers.
Spawn in waves from `data/wave_table.json`. Bullets pooled, never instantiated in hot loop.

### 4.5 Resources — REVISED
- **Resource name:** `Supply Alloy` (single resource for MVP). Display name, icon path, magnet radius all defined in `data/resources.json` — not hardcoded.
- **Source:** Defeated enemies only. Drop amounts per enemy defined in `data/enemies.json` (e.g., Chaser 1–2, Spinner 3, Tank 10). No other income.
- **Use:** Build new Tower OR upgrade existing Tower. Nothing else. This enforces "player does not progress, Towers do."
- **Collection rule:** Shards within aura = vacuum toward player. Outside aura = manual pickup on contact. Designed so you must return to aura to profit.
- **Future extension (data-only):** A second resource (e.g., Power Cores for Aura upgrades) can be added later by adding an entry to `resources.json` and drop tables — no code change required.

### 4.6 Two Play Agendas (explicit)
- **Agenda A — Chain Push:** Start west. Map scrolls east. Goal: chain Towers eastward. Overlapping auras give Resonance, so optimal chain steps are ~0.7×R_buff apart. Risk: old towers isolated are wasted spend.
- **Agenda B — Fortress Build:** One Tower at centre. Player kites into the aura. No Resonance; instead T4 Aura + Gun upgrades compensate. Risk: bullet density in a small area, single-point failure.
Both agendas are intent, not code branches — same Towers, same data.

### 4.7 VN-like Cutscenes — REV.3: USE HIKARIN-STUDIO (supersedes Rev.2 draft below)
Visual-Novel cutscenes interrupt the bullet-hell to give context and choices. Gameplay pauses (waves halted, player invulnerable) while a cutscene plays.

**Rev.3 decision (Artes, 2026-11-09): do not design characters now; use the existing `E:\HERMES\hikarin-studio` as the VN authoring pipeline.**
- Hikarin Studio is the visual editor for Hikarin scripts (content pipeline for TLM: Visual Novel Framework). Author stories as stacks of blocks across `.story` tabs in a new project folder under `E:\HERMES\hikarin-studio\projects\towerchain\` (`project.json` + `main.story` + additional `.story` files). Labels are global across files; the file containing `startLabel` compiles first.
- Loop: palette (19 blocks / 5 families) → inspector → Validate (Ctrl+Enter) → Save (Ctrl+S) → Play preview at `http://127.0.0.1:8411` via `uv run serve.py` (`play.html?project=towerchain`, same compiler as export) → Export.
- Export for Godot: `GET /api/projects/{slug}/export?format=json` gives the compiled flat JSON (per `FORMAT.md` ground truth: sequential ids, `dialogue`/`choice`/`conditional`/`transition`/`show_sprite`/`modify_background`/`next`/`finish_dialogue`). Godot `CutsceneUI.tscn` / `CutscenePlayer.gd` render only that shipped JSON vocabulary; no dialogue text is handwritten into Godot JSON.
- Conditional semantics are the engine rule: continue when the test passes, jump to `end` when it fails. `choice` labels are jump targets, `dialogue.label` is the speaker. `next` is a persistent resume point. Day/night are condition types, not variables. Sprite paths must be lowercase `characters/<character>/<outfit>/<emotion>.png` — compiler rejects capitals/spaces.
- Map Towerchain triggers to Hikarin state: wave milestones, first double-aura, tower lost → WORLD/SCENE variables (e.g. `@world.waves_cleared`, `@scene.resonance_seen`) and labels (`start`, `wave_05`, ...). `play_level` (PvZ Fusion extension) maps to "return to bullet-hell level, then resume".
- Reference template only: `projects/cupa/` (`character: cupa`, `startLabel: start`, `files: [main.story]`) shows the minimal shape. Cast, portraits and backgrounds are deferred per instruction.

**Rev.5 — Hikarin runtime spec (Artes, 2026-11-09): "Make a simple runtime that lets the game run compiled hikarin json scripts."**

Runtime scope is intentionally minimal (MVP):

- **Input:** Compiled hikarin JSON only — the flat array from `GET /api/projects/{slug}/export?format=json` per `FORMAT.md` (`id` sequential from 0, `type`/`action` per vocabulary). No `.story` parsing in Godot; no Minecraft TLM runtime involved.
- **Loader:** `CutscenePlayer` (GDScript) loads the JSON via `DataLoader`, builds an `id -> action` map plus `label -> id` map (for `transition`/`conditional.end`/`choice.label` jumps). Validates at boot: ids sequential/unique, every jump target exists, sprite names lowercase-only, required fields present — fail-fast with error report to the log.
- **Executor:** Single `current_id` pointer. Tick loop applies one action per advance input (click/Space): `dialogue` → typewriter text + speaker name; `show_sprite`/`remove_sprite` → portrait slot set (slot replaces by `sprite` name); `modify_background`/`clear_background` → background texture swap; `conditional`/`conditional_global` → evaluate `condition` (`equal`, `not_equal`, `less_than`, `greater_than`, `less_or_equal`, `greater_or_equal`, `exists`, `not_exists`, `day`, `night`) against state, advance or jump to `end` id; `choice`/`night_choice` → present options, jump to selected label id; `transition jump` → jump to label id; `modify_variable`/`modify_global` → mutate state; `next` → persist `checkpoint = label` in state; `finish_dialogue` → close UI, resume combat. Unsupported-for-MVP actions (`command`, `give_item`, `take_item`, `play_level`, `unlock_dialogues`, `idle_chat`) are recognised and logged as no-ops with `pause` placeholder if needed — not silent failures.
- **State:** Four scopes from FORMAT.md mapped to `GameState` autoload dictionaries: `SCENE` (bare names, per-scene), `MAID`, `WORLD`, `PLAYER` (read-only injected facts: `waves_cleared`, `towers_built`, `resonance_seen`, `isDay`/`isNight`, `player_health`, `time_of_day` etc. supplied by the game). Bare names resolve to `SCENE`. `next` checkpoint survives scene close (save to user://).
- **UI:** `CutsceneUI.tscn` minimal: background `TextureRect`, two portrait `TextureRect` slots, speaker `Label`, body `RichTextLabel` with typewriter, choice `VBoxContainer` of buttons, log/skip controls. Gameplay tree paused (`get_tree().paused = true`) while UI is open; player invulnerable; input only to UI.
- **Trigger bridge:** `WaveDirector`/`BuffManager` emit game signals; a `CutsceneTrigger` table (data-driven in `data/cutscenes/triggers.json`) maps signal → `start` label in the compiled JSON. Godot never hardcodes dialogue; it calls `CutscenePlayer.start_at(label)`.
- **Pipeline:** Author in hikarin-studio → validate → preview at `127.0.0.1:8411` → export JSON → copy to `E:\HERMES\godot-mcp-test\data\cutscenes\<character>.json` → Godot runtime consumes. TXT/MD exports are review artefacts only.

**Rev.2 draft below is historical reference only:**

**Content:**
- Backdrop image, 1–2 character portraits, name tag, typewriter text box, advance on click / Space.
- Choice nodes (1–3 options) — e.g., Engineer asks: "Chain forward or fortify here?" Choice sets a hint flag and displays different follow-up lines. Choice does not change game code path, only stored flag read by later dialogue.
- Progression: **log** (review past lines), **skip** (hold to fast-forward), **auto** (optional).

**Triggers (defined in `data/cutscenes.json` triggers, not code):**
- Game start (intro: why Towers exist)
- Wave 5 / 10 milestones
- First time player enters double-aura (explains Resonance)
- First Tower destroyed
- Boss / final wave warning

**Data format (example, not code):**
```json
{
  "id": "intro_01",
  "bg": "res://art/bg_ruin.png",
  "beats": [
    {"speaker": "engineer", "text": "You are weak out there. Stay close to the Tower.", "portrait": "res://art/engineer.png"},
    {"speaker": "operator", "text": "If I fall, build another?"},
    {"choice": ["Chain forward", "Fortify here"], "sets_flag": "agenda"}
  ]
}
```
Characters defined in `data/characters.json` (name, portrait path, colour). Cutscene beats, triggers and flags are in JSON only.

**Scenes:**
- `scenes/CutsceneUI.tscn` (full-screen panel, portrait nodes, text box)
- `scripts/CutscenePlayer.gd` (reads JSON beats, advances, emits flag — no dialogue text hardcoded)

### 4.8 Builder Stance — DECIDED GDSCRIPT ONLY (Rev.5, Artes 2026-11-09)

**Decision: Option A — GDScript only.** Standard Godot build at `E:/HERMES/godot/Godot_v4.7.2-stable_win64.exe` is the sole build. No C# / .NET, no mono templates, no .NET SDK requirement. Data carry-over argument stands: all balance/VN data in JSON, so language choice does not lock content.

### 4.9 Visual Direction — REV.4 DECISION

- **Gameplay (bullet-hell): pixel art, for performance.** Low-resolution sprites (16×16 / 32×32 base, scaled up), texture atlas, few colours, particle effects over detailed art. Keeps VRAM low on a ~8 GB card, keeps bullet readability high, matches pooling plan.
- **VN (hikarin-studio cutscenes): non-pixel.** Higher-resolution illustrated portraits/backgrounds (`hikarin-studio` sprite/background paths accept PNG). VN images are static, full-screen, not per-frame — no performance penalty. Different pipeline is intentional: pixel sprites ≠ VN art.
- **Separation:** `res://art/` for pixel game sprites; hikarin-studio `images/` for VN assets. Names/layouts data-driven via `resources.json`, `characters.json`, hikarin project files — no art paths hardcoded in scripts.

**MVP art — colourful boxes / placeholders (Rev.8, Artes 2026-11-09):**
- Gameplay: `Polygon2D`/`ColorRect` shapes only — coloured squares for Player/Towers, distinct colour per enemy type, small rect/circle bullets (pooled), diamond shapes for Alloy shards, aura as translucent circle, flat background + grid. Colours/sizes/positions defined in `data/art_manifest.json`; `sprite_path = null` triggers shape fallback.
- VN: flat colour background + text box; portrait slots = coloured boxes with slot label (hikarin `show_sprite` still fires, texture is a 1×1/rect placeholder). No pixel art, no character illustration in MVP.
- Purpose: validate aura/resonance, bonding, cutscene runtime and pooling at near-zero VRAM. Final art replaces placeholders by filling `sprite_path` — no script changes.

### 4.10 Homebase & Ally Story Progression — REV.6 (Artes, 2026-11-09)

**Homebase Tower (hub, invulnerable):**
- One permanent Tower at map origin. `invulnerable = true` in `data/towers.json`; enemies spawn outside `homebase_safe_radius_px` and despawn/retreat if they path inside it (data value, not code).
- Function: story hub, upgrade board, tower-construction catalogue, hikarin cutscene stage. Return here between fields to play VN, spend Alloy, unlock towers.
- Attack reduction is prohibited by rule, not by HP tuning — no "homebase HP" stat exists in data.
- Fail state unchanged: Player HP 0. Losing a *field* Tower is a retreat to Homebase, not a game over.

**Chapter loop (data-driven, no hardcoded order):**
```
Homebase VN (hikarin) → Field waves (gather Alloy) → Build/upgrade at Homebase
→ Meet Ally (hikarin intro) → Unlock Ally Tower → Field waves under new aura
→ Bond rises → Bond cutscene → Next chapter / next Ally gate
```
All transitions gated by `data/story_chapters.json`: `{id, required_bond_histogram, waves_cleared_min, unlocks: tower_id}`. Godot reads the table; hikarin `start` router branches on `@world` variables (`waves_cleared`, `ally_bond.<id>`).

**Allies = cosmetic buff companions (no independent entity):**
- Each ally is a `tower_type` entry in `data/ally_towers.json`, e.g. `ally_01` (placeholder — cast deferred). Fields: `bullet_pattern` (count, spread_deg, speed, damage_mul, pierce, homing_factor), `aura_R`, `bond_thresholds`, `sprite_path`.
- When Player is inside an ally tower aura, an ally sprite orbits the Player (animation/offset from data, no `Area2D` hitbox, no separate AI, no HP). The player acquires additional bullets per the ally pattern only — "looks like controlling multiple characters, mechanically only bullet kind/count".
- Two ally auras overlapping: patterns sum (same stacking rule as §4.2.1, `buff.json` resonance) — your volley visually and numerically grows. No extra damage types invented in code; all in JSON.

**Bond — capped, mission-gated (Rev.7, Artes 2026-11-09):**
- Bond per ally is capped per chapter: `bond_cap` in `data/story_chapters.json` (e.g., Ch.1 cap 250, Ch.2 cap 500). Bond cannot exceed the current cap no matter how much fighting occurs.
- The cap raises only when the chapter mission is completed: mission = `mission_id` in the chapter table (e.g., `mission_clear_wave_10`, `mission_build_2_towers`, `mission_first_synergy`) — all data values, checked by `WaveDirector`/`GameState`, not hardcoded.
- Gains (data values as before): `per_kill_in_aura` (+2), `per_wave_survived_in_aura` (+25), `per_alloy_collected_in_aura` (+1). Idle standing does not bond. Excess past cap is discarded.
- On mission completion: cap increases, `bond` resumes rising, and tip-off dialogue fires.
- **Per-scene hikarin scripts (confirmed):** Each bond threshold / chapter scene triggers a **dedicated compiled hikarin JSON script** — e.g. `data/cutscenes/bond_ally01_t1.json`, `chapter_02.json` — authored as its own `.story` project/label set in hikarin-studio, exported via `format=json`, and executed as a full script by the §4.7 runtime (loader → executor → `finish_dialogue`). No inline Godot dialogue strings; every scene is a self-contained hikarin script run start-to-`finish_dialogue`. Trigger table `data/cutscenes/triggers.json` maps `{mission_complete, bond_threshold, first_synergy}` → `{script_file, start_label}`.
- Two ally towers placed adjacent (within `synergy_range_px` in `ally_towers.json`): synergy flag grants `synergy_bonus` (e.g. +25% on both patterns) and its own dedicated hikarin script on first adjacency (`first_synergy.json`).

**Data files added (Rev.6):**
- `data/story_chapters.json`, `data/ally_towers.json`, `data/ally_bond.json` (gain rates, thresholds). Cast names/portraits deferred; hikarin-studio placeholders only.

## 5. Win / Lose

- **MVP Win:** Survive 15 waves. Score = waves cleared + towers built + resources gathered.
- **MVP Lose:** Player HP 0. Tower loss is a setback with rebuild cost, not instant loss.
- **Future Win:** Reach Far Gate east edge and hold 60s.

## 6. Controls (MVP)

- WASD/Arrows — move | Mouse — aim, LMB — fire
- Q — placement mode, LMB — confirm | 1/2/3 — upgrade Guns/Aura/Utility
- E — Overdrive (unlocked later) | Esc — pause
- During cutscene: LMB/Space — advance, 1/2/3 — choose, L — log, hold Esc — skip

## 7. Fully Data-Driven Architecture — REVISED

**Rule: GDScript contains no magic numbers and no hardcoded enemy/tower/dialogue definitions.**
If a value changes game balance, story, cost or spawn pattern, it lives in JSON.

```
res://
├── project.godot
├── main.tscn
├── scenes/
│   ├── Player.tscn
│   ├── Tower.tscn
│   ├── Enemy_Chaser.tscn / Enemy_Spinner.tscn / ...
│   ├── Bullet.tscn
│   ├── Pickup_Resource.tscn
│   └── CutsceneUI.tscn
├── scripts/
│   ├── DataLoader.gd         (autoload: load+validate all JSON at boot)
│   ├── GameState.gd          (autoload: resource count, score, flags)
│   ├── BuffManager.gd        (compute total_S + resonance per §4.2.1)
│   ├── ResourceManager.gd    (drop/collect/spend — reads economy.json)
│   ├── WaveDirector.gd       (reads wave_table.json)
│   ├── CutscenePlayer.gd     (reads cutscenes/*.json, chars)
│   ├── Player.gd / Tower.gd / Enemy_Base.gd / Bullet.gd  (logic only, no stats)
└── data/
    ├── player.json
    ├── towers.json
    ├── tower_upgrades.json
    ├── enemies.json
    ├── bullets.json
    ├── resources.json
    ├── economy.json          (build/upgrade costs, scaling)
    ├── buff.json             (falloff, resonance_bonus, stacking_cap)
    ├── wave_table.json
    ├── characters.json
    ├── cutscenes/            (intro.json, milestone_05.json, ...)
    ├── maps.json             (valid placement zones, spawn pads)
    └── strings.json          (all UI text / localisation keys)
```

**DataLoader responsibilities:**
- Load all files in `data/` on boot, validate against `schema_version`, report missing keys as errors (fail-fast, never silent defaults).
- Expose queries: `DataLoader.get_tower("standard")`, `DataLoader.get_enemy("spinner")`, `DataLoader.get_cutscene("intro_01")` return dictionaries; scripts never construct stats inline.
- Pooling, collision layers (1=World, 2=Player, 3=Tower, 4=Enemy, 5=PlayerBullet, 6=EnemyBullet, 7=Pickup) are config values in `data/maps.json` where feasible.

**What counts as "hardcoded" and is therefore banned in scripts:**
- Damage, HP, speed, fire rate, radius, costs, drop counts, wave counts, bullet counts/speeds, buff formulas' constants, dialogue text, trigger wave numbers, display names/paths.
- GDScript may contain only logic: move, collide, target nearest, iterate data lists, apply multipliers from data.

## 8. Balancing Starting Points (all to live in JSON)

- Player: speed 200, dmg 5, fire rate 3/s, HP 100 (`player.json`)
- Tower T1: dmg 8, rate 2/s, R_buff 250, S_max 1.0, HP 300, build 40 (`towers.json` + `economy.json`)
- Resonance: bonus 0.25 per extra tower, cap total_S 2.5 (`buff.json`)
- Enemy drops: Chaser 1–2, Spinner 3, Tank 10 (`enemies.json`)
- Enemy HP scaling: per-wave multiplier 0.15 (`wave_table.json`)
- Bullet speeds: enemy 120–200, player 400 (`bullets.json`)

## 9. Milestones — Revised

1. **Milestone 0 — Data Layer (0.5 day):** DataLoader + `player.json`/`towers.json`/`economy.json`/`buff.json` load and validate. No gameplay yet. Test: change a number in JSON and see it change in-game without touching scripts.
2. **Milestone 1 — Vertical Slice (1 day):** Player move+shoot, one Tower, aura falloff, one Chaser, one Spinner, resource drop/collect. Test: is staying near Tower fun?
3. **Milestone 2 — Build & Stack (1–2 days):** New-Tower build via resources, overlapping aura with Resonance, WaveDirector 5 waves.
4. **Milestone 3 — VN Cutscenes via hikarin-studio (1 day):** New `projects/towerchain/` in hikarin-studio + intro `.story` blocks + first-overlap trigger. Test: validate in studio, preview at `127.0.0.1:8411`, export JSON, load in Godot CutsceneUI.
5. **Milestone 4 — Polish & Agendas (2 days):** 4 enemy types, bullet pooling, Chain map vs Fortress map test.

## 10. Open Questions for Artes — REV.4 RESOLUTIONS

1. Resource — **DECIDED (MVP): single Alloy.** Dual (Alloy + Cores) is **not** a rewrite: `ResourceManager` reads `resources.json` by id, costs reference resource ids, HUD loops over resource list — adding a second entry later is data + UI row only. Dual deferred post-MVP.
2. Resonance numbers — **DECIDED: data-driven.** `resonance_bonus`, `stacking_cap`, `S_min`, `S_max`, `R_buff` all in `data/buff.json`; scripts contain no constants. Tuning via JSON only.
3. Max Towers simultaneous — **DECIDED: data-driven.** `max_towers` in `data/towers.json` + `economy.json` scaling; scripts enforce the value, do not hardcode 1 or 3.
4. VN cast — deferred per Artes 2026-11-09: use hikarin-studio structure only, no character design yet.
5. Builder stance — **DECIDED (Artes 2026-11-09): GDScript only.** Standard build sole; see §4.8. No C#.
6. Visual direction — **DECIDED:** gameplay = pixel (performance); VN = non-pixel (static illustration). See §4.9.

---
## 11. Completeness & Modularity — REV.8 (Artes, 2026-11-09)

**MVP design is complete for the pillars decided:** resource gathering (single Alloy), multi-tower stacking/resonance, homebase hub (invulnerable), bond capped + mission-gated, per-scene hikarin scripts, fully data-driven, GDScript only, pixel gameplay / non-pixel VN.

**Yes — this structure is genre, style and story agnostic by construction:**
- **Genre:** swap `data/enemies.json`, `data/bullets.json`, `data/wave_table.json` and `Player`/`Enemy` scenes and the same Tower + aura + resource loop yields a tower-defense, survival, or arena game. No genre logic is hardcoded; the loop is "gain resource X from activity Y in aura Z, spend on entity E".
- **Style:** pixel vs non-pixel is a data swap — sprite paths, atlas settings, palette files in JSON. VN art is static PNGs referenced by hikarin projects; gameplay art is low-res atlas. One build can be re-skinned by replacing data/images alone.
- **Story:** any story is buildable in hikarin-studio `.story` blocks (labels, conditionals, choices, `next` resume). `@world` variables are the only bridge to gameplay; adding a new chapter is adding a `.story` label set + a trigger row, not changing Godot code.

**Residual backlog — not blockers for MVP plan, data entries to fill later:**
- Concrete chapter/mission list (3–5 chapters, named missions) — content, not system.
- Placeholder art: pixel sprite set list + VN background/portrait list (paths in `resources.json`/`characters.json`).
- Audio: music/sfx lists in `data/audio.json` (hikarin `play_music`/`play_sound` already cover VN; gameplay buses need data entries).
- Save schema: `user://` save for `WORLD` + `next` checkpoint + bond progress (already implied by FORMAT.md scopes).
- Tutorial/tooltip strings in `data/strings.json`; performance budget (max concurrent pooled bullets); export targets.
None of these require a rewrite — each is a new JSON / `.story` entry.

---
*Rev. 8 — No Godot files modified, no code written; MVP design complete, backlog data-only. Plan only.*
*Location: `E:\\HERMES\\gameplan\\bullet-hell-tower-gdd.md`*
