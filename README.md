# Towerchain — Bullet-Hell MVP

Data-driven bullet-hell in Godot 4.7 (GDScript only). You are weak alone — power comes from Towers. Defeat enemies, gather Supply Alloy, place more Towers, overlap auras to stack buffs (resonance). Homebase is invulnerable; allies unlock behaviour types (shoot / generate / heal / buff / decorative). VN cutscenes run compiled hikarin JSON via a minimal runtime.

Live numbers: see `docs/gameplan/data-tables.md` (mirror of `data/*.json`). Design: `docs/gameplan/bullet-hell-tower-gdd.md`.

## Run
Godot 4.7+ → open this folder → Play (F5).

- WASD/Arrows move, mouse aim, hold LMB fire
- Q toggle place, LMB/RMB confirm, Esc cancel
- C play intro cutscene (click / Space to advance)

## Layout

```
project.godot         autoloads: DataLoader, GameState, BuffManager
main.tscn             Main + WaveDirector + Camera2D
scripts/              GDScript — no hardcoded balance numbers
data/                 14 JSON files — all tuning lives here
addons/godot_mcp/     Godlink MCP plugin (MIT, tomyud)
docs/gameplan/        GDD + data tables
```

## Data rule
All numbers in `data/*.json`. `towers.json` = field template; `area.json` = grid, limits, build cost scale; `tower_types.json` = base class per Tower instance (`field`, `ally_01`, `alloy_gen`, `healer`, …) with `behaviors` (shoot / generate_alloy / heal / buff / decorative). A Homebase is a `field` instance with `is_homebase: true` — invulnerable by flag, not a separate type.
