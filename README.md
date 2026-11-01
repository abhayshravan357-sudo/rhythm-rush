# HexaRhythm

HexaRhythm is an original Android-first rhythm game prototype built in Godot 4. The project currently contains a partial gameplay foundation, but it still needs modular game-state wiring, consistent lane configuration, scoring fixes, and a verified Android build environment.

## Status

- Core Godot scenes and scripts exist.
- Main menu, gameplay, scoring, calibration, and chart systems are present but not yet fully integrated.
- The project is still blocked from Android build verification until Godot 4, Java, and Android SDK tooling are installed.

## Python dependency setup

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

## Current blockers

- Godot 4 is not installed in this environment.
- Android SDK / `adb` is not installed.
- Java / JDK tooling is not installed.
- No actual published demo song or game icon is present in the project assets.

## Architecture note

The current project is being migrated toward a modular architecture centered on a game state manager, a central game controller, configurable lanes, and isolated chart/audio/gameplay systems. See [docs/ARCHITECTURE_AUDIT.md](docs/ARCHITECTURE_AUDIT.md) for the current engineering audit and migration plan.
