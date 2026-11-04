# HexaRhythm Visual System and Screenshot Findings

**Updated:** 2026-11-02  
**Implementation owner:** Agent 00 (workspace implementation)  
**State:** Implemented in source; headless runtime checked; GUI visual review blocked by unavailable display server.

## Baseline findings

The supplied capture is available at [gameplay-before-2026-11-02.png](evidence/gameplay-before-2026-11-02.png). The project entry point in `project.godot` is `MainMenu.tscn`; the screenshot itself shows the `GameScene` after the player entered a song.

- The three pink bars are pooled note controls created by `NoteSpawner.gd`. They are real chart notes in lane 0, rendered as plain `ColorRect` nodes with no border, corner treatment, or shared note style.
- `LaneManager.gd` computed lane widths and hit positions but did not draw the lanes, so notes appeared detached from any playfield.
- `JudgmentLine` was a fixed `1920×4` control at `y=918`; when the game viewport differed from the authoring viewport, it no longer tracked the playfield or receptors.
- `ScoreLabel` and `ComboLabel` used a right edge anchor and a tiny fixed offset, which centered values across the screen instead of creating a left HUD group. Accuracy, song progress, and song title were not presented.
- The screenshot was taken during gameplay: the displayed MISS was produced by the live scoring system. The main-menu network catalog controls were visible but had no UI handlers.
- The app scene is configured to open Main Menu first. Its Play action starts the bundled example song; Song Library remains a separate selection route.

## Tokens and components

`godot_project/assets/theme/hexarhythm_theme.tres` is the shared Godot `Theme` for application screens. `godot_project/scripts/ui/VisualTokens.gd` supplies semantic colors and layout constants to gameplay drawing and notes. `ResponsiveLayout.gd` places centered screens inside a viewport-safe rectangle. `AtmosphereBackground.gd` draws a small set of static, original glow rings and redraws only after resize.

| Token | Value | Use |
|---|---|---|
| Background | `#080F1C` | Main application canvas |
| Surface | `#101A2D` | Playfield base |
| Alternate surface | `#17243B` | Alternating lanes |
| Border | `#263B5D` | Playfield frame |
| Cyan | `#38D9FF` | Hold notes, active accents |
| Magenta | `#FF55CB` | Tap notes |
| Perfect | `#5AE0FF` | Judgment feedback |
| Good | `#FFC857` | Judgment feedback |
| Miss | `#FF5D76` | Judgment feedback |
| Text | `#E9F2FF` | Primary labels |
| Secondary text | `#8CA7C7` | Supporting labels |

Typography uses Godot's default UI font, with shared theme sizing and explicit display sizes at the title/HUD level. Panels and buttons use a 12 px corner radius; screens use a 24 px safe margin; the standard button height is 64 px. The main Play action and song Play action use the shared PrimaryButton variation. Hover and pressed states use brighter cyan and magenta borders.

Motion is short and input-safe: judgments fade over 0.4 seconds, milestone combo emphasis is brief, lane receptors flash for 0.14 seconds, and pause changes occur on the same state/audio signals as gameplay. No timing or score calculation was changed for animation.

## Implemented in this pass

- A centered four-lane playfield is drawn from viewport dimensions. It has a bounded frame, alternating lane surfaces, clear dividers, a receptor per lane, and visible top/bottom rails. Lane-count math remains normalized through the existing 4/6-lane configuration.
- Pooled notes now use rounded `Panel` nodes and shared tap/hold styles. Existing chart timestamps, lane positions, pooling, and note lifecycle remain the source of note placement.
- Receptors flash on lane press. Desktop key input uses A/S/D/F for four lanes and A/S/D/J/K/L when configured for six; existing mouse and touch input remain.
- The judgment line now follows the playfield's calculated x, width, and y. The HUD shows score, combo, actual accuracy, chart title, and actual audio-clock progress, with a fully inset pause button.
- Resume now emits the existing `song_resumed` signal so the pause overlay hides and `AudioSync` seeks/resumes the audio clock at the paused position.
- Main Menu now presents the brand icon, title, tagline, Play, Song Library, Calibration, Settings, Profile, and a working Quit action. The visible network catalog mock controls were removed because they had no input wiring.
- Song Library uses a responsive card-like metadata area. Selecting a real catalog item reads its chart metadata, validates the corresponding packaged audio file, and shows BPM, lane count, and a saved best score when present. Unknown artist or difficulty details are not invented.
- Results emphasizes the actual score and grade separately from accuracy and judgment statistics. Retry, song library, and main menu actions remain connected.
- The shared theme and atmospheric background were applied to song selection, calibration, results, settings, and profile screens. These screens use a shared centered layout helper.

## Scope still open

- The catalog still contains one playable song. It has no author, artist, genre, artwork, preview, or difficulty variants in its metadata; those screens cannot truthfully display those fields yet.
- Difficulty choice, search/filter, loading animation, full empty/error states, game-mode navigation, achievements, unlocks, daily rewards, and the broader GDD progression are still unimplemented.
- The settings and profile screens have shared theme and responsive bounds but still need a GUI usability pass at compact portrait/landscape sizes.
- The supplied baseline is preserved. A new after screenshot could not be captured: this environment has no available X11 or Wayland display. The normal Godot launch failed with `X11 Display is not available` / `Can't connect to a Wayland display`; the headless movie writer also crashed because the headless renderer has no texture backend. Headless tests are not represented as visual validation.
- Independent Agent 04/06/07 participation was not verified. The live collaboration roster for this task had only Agent 00, and no replacement agents or sessions were created.

## Verification record

- Godot 4.3 project import/parser: no GDScript parse errors. The sandbox reports socket-listen errors from Godot's editor helper, unrelated to project scripts.
- Godot headless runtime smoke: **27/27 passed**, including chart/audio binding, actual score/result data, pause/resume UI and audio state, and centered panel bounds for 1920×1080, 1600×900, 1366×768, 1280×720, 412×915 portrait, and 915×412 landscape.
- Python regression suite: **141 passed**, with an existing `pytest.ini` warning for an unknown `rootdir` option.
- GUI runtime and visual acceptance: **not completed** because the desktop display server is unavailable in this execution environment.
