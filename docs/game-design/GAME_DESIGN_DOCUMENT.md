# GAME DESIGN DOCUMENT — PROJECT RHYTHM

Project: PROJECT RHYTHM
Version: 0.1
Status: Draft (Wave 2)
Reference gameplay: Magic Tiles 3 (inspiration only — original identity, no copied IP)

## 1. Game identity

- Working name: PROJECT RHYTHM (final name/branding decided in discovery)
- Genre: 2D rhythm / piano-tile music game
- Platform: Android (offline-first)
- Core loop: Select song → play descending tiles → hit in time → score/combo/accuracy → results → unlock progress

## 2. Core gameplay concept

- Multiple vertical tile lanes (MVP: 4 lanes; foundation supports 6)
- Tiles descend toward a hit (judgment) zone
- Touch input on the correct lane
- Timing-based hit detection
- Immediate visual and audio feedback on hit/miss
- Score calculation, combo tracking, accuracy percentage
- Miss detection
- Song completion and results screen
- Responsive, satisfying feel; every mechanic functional (no faked interactions)

## 3. Note data & chart system

Each song has a structured note chart (JSON):

| Field | Meaning |
|-------|---------|
| note id | Unique identifier |
| lane | Vertical lane index |
| start timestamp | Seconds from song start (authoritative audio clock) |
| end timestamp | For hold notes |
| note type | TAP or HOLD |
| difficulty | Chart difficulty tier |
| timing info | Hit-window classification input |

Chart-driven: tile spawn and hit time derived from music playback position via AudioSync, not frame delta.

## 4. Hit windows (initial design targets, calibrated via QA)

| Rating | Window | Points |
|--------|--------|--------|
| PERFECT | ±50 ms | 300 |
| GOOD | ±100 ms | 100 |
| MISS | outside accepted window | 0, combo reset |

(Existing foundation uses ≤45/≤90/≤150 ms; QA to calibrate to master-prompt targets.)

Anti-cheat / integrity rules:
- No duplicate hits per note
- No accidental multi-touch scoring
- No unregistered touches
- No timing drift
- No negative score
- No incorrect combo updates
- No tiles appearing after intended hit time
- Audio stops correctly on game over

## 5. Difficulty system

| Difficulty | Effect |
|------------|--------|
| Easy | Lower note density, wider timing windows, slower speed |
| Normal | Baseline density, standard windows, standard speed |
| Hard | Higher density, tighter windows, faster speed |
| Expert | Maximum density, tightest windows, fastest speed |

Difficulty changes actual note patterns, density, timing windows, and gameplay speed — not just a label.

## 6. Game modes (build Classic first; others incremental)

1. Classic Mode — song-based, finish the chart
2. Endless Mode — infinite descending tiles, survive as long as possible
3. Rush Mode — time-limited, maximize score
4. Challenge Mode — specific objectives/modifiers
5. Daily Challenge — rotating daily song + goal

## 7. Scoring engine (independent of visual interface)

- Perfect / Good / Miss hit evaluation
- Combo counter, maximum combo
- Accuracy percentage
- Score multiplier
- Final score
- Grade calculation (e.g., S, A, B, C)

## 8. Progression system (persisted locally)

- Player level, experience points
- Song unlocks
- Achievements
- Daily rewards
- High scores, personal bests
- Statistics

## 9. Audio system

- Music playback driven by authoritative audio clock
- Sound effects: hit, miss, menu
- Volume controls (music, SFX)
- Audio latency calibration (user offset persisted to user://)
- Pause/resume synchronization
- Offline playback (local audio files only)

## 10. Audio & copyright (mandatory)

- Original compositions, properly licensed music, or public-domain compositions only
- Never embed copyrighted commercial music without authorization
- Maintain music asset registry: track name, artist, source, license, attribution, file location, chart location
- Chart/audio import system allows new legally authorized tracks without engine changes

## 11. Screens

1. Splash screen
2. Main menu (logo, play, song library, modes, daily challenges, profile, settings, rewards, progress)
3. Song selection (catalogue, title/artist/genre/difficulty/duration, preview, locked/unlocked, search/filter)
4. Song details
5. Gameplay (4 lanes, HUD: score, combo, rating, pause)
6. Pause menu
7. Results (score, combo, accuracy, grade, restart)
8. Game modes
9. Profile
10. Settings (volume, latency calibration, screen)

## 12. Visual direction (original identity)

- Deep dark backgrounds
- Piano-inspired tiles
- Cyan, blue, purple accents
- Smooth gradients, subtle glow
- Responsive animations, clear typography
- Gameplay readability over decoration
- Support multiple screen sizes/aspect ratios

## 13. Performance targets

- 60 FPS on supported devices (evaluate 90/120 Hz)
- Low input latency, stable audio timing
- Efficient rendering, controlled allocation, fast startup
- Object pooling for tiles (no GC pauses during gameplay)

## 14. MVP scope (Wave 3)

1. Main menu
2. Song selection
3. One playable song (original/licensed audio)
4. Four-lane tile gameplay
5. Music synchronization
6. Touch detection
7. Scoring + combo
8. Game-over screen
9. Results screen
10. Restart
11. Android APK (debug)

Must work on a real Android device before Wave 4.
