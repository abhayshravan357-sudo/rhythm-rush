# STEP 4 — Reference Game Research & Core Gameplay Mechanics

**Date:** 2026-10-31  
**Research source:** Magic Tiles 3 (Google Play listing) - https://play.google.com/store/apps/details?id=com.youmusic.magictiles

## Core gameplay mechanics (observed)
| Mechanic | Description | Implementation requirement |
|----------|-------------|----------------------------|
| Four-lane tiles | Descending piano tiles in vertical lanes | MVP: 4 lanes (configurable; foundation supports 6) |
| Rhythm synchronization | Tiles align with musical beats | Authoritative audio clock (AudioServer hardware time), not frame delta |
| Touch input | Tap corresponding lane when tile reaches hit zone | Lane-resolved multi-touch input, no duplicate hits |
| Timing-based hits | Perfect/Good/Miss based on timing accuracy | Hit windows: PERFECT ±50ms, GOOD ±100ms (calibrated) |
| Scoring & combos | Score accumulates, combo builds on consecutive hits, resets on miss | Combo counter, max combo, accuracy %, grade calculation |
| Difficulty progression | Multiple difficulty levels affect note patterns/speed | Easy/Normal/Hard/Expert affect density, windows, speed |
| Song selection | Browse and select songs to play | Song library with locked/unlocked states |
| Progression/rewards | Unlocks, rewards, personal bests | Local persistence (offline-first) |
| Offline support | Playable without internet | Offline-first architecture |

## Design constraints (IP safety)
- **Do NOT copy:** copyrighted music, artwork, branding, UI assets, proprietary implementations
- **Do:** create original identity, use original/public-domain/licensed audio only
- **Maintain:** music asset registry with license/attribution/source

## Gameplay feel requirements
- Responsive touch with minimal latency
- Immediate visual/audio feedback
- Tiles spawn ahead of hit time (APPROACH_TIME window)
- No tiles after intended hit time
- Audio stops correctly on game over
- Smooth 60 FPS animations

## Documented in
- `docs/game-design/GAME_DESIGN_DOCUMENT.md` (full design)
- `charts/example_chart.json` (chart format reference)
- `godot_project/scripts/` (existing implementation foundation)
