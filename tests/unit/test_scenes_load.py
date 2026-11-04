"""Unit tests for scene loading validation.

Verifies that all .tscn scene files in the project are valid Godot scene
files (start with [gd_scene], have valid structure) and that referenced
script paths exist. These are static checks — they do not require the
Godot engine to be running.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SCENES_DIR = ROOT / "godot_project" / "scenes"
SCRIPTS_DIR = ROOT / "godot_project" / "scripts"


def _find_tscn_files() -> list[Path]:
    return sorted(SCENES_DIR.glob("*.tscn"))


def _parse_tscn(path: Path) -> dict[str, str]:
    """Minimal parser for .tscn files — extracts resource paths and node types."""
    result: dict[str, str] = {}
    current_section: str | None = None
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("[") and line.endswith("]"):
                current_section = line[1:-1]
                continue
            if "=" in line and current_section:
                key, _, value = line.partition("=")
                key = key.strip()
                value = value.strip().strip('"')
                if key == "script":
                    result["script"] = value
                elif key == "type":
                    result["type"] = value
    return result


# ── Scene file validity ─────────────────────────────────────────────────────


def test_scenes_directory_exists():
    assert SCENES_DIR.is_dir(), f"Scenes directory not found: {SCENES_DIR}"


def test_at_least_one_scene_exists():
    scenes = _find_tscn_files()
    assert len(scenes) > 0, "No .tscn scene files found"


def test_all_scenes_have_gd_scene_header():
    for scn_path in _find_tscn_files():
        content = scn_path.read_text(encoding="utf-8")
        assert content.startswith("[gd_scene"), (
            f"{scn_path.name} does not start with [gd_scene]"
        )


def test_all_scenes_have_valid_script_references():
    """Every script referenced in a .tscn file must exist on disk."""
    missing: list[str] = []
    for scn_path in _find_tscn_files():
        parsed = _parse_tscn(scn_path)
        script_path = parsed.get("script")
        if script_path:
            # Resolve res:// to godot_project/
            resolved = (ROOT / "godot_project" / script_path.replace("res://", ""))
            if not resolved.exists():
                missing.append(f"{scn_path.name}: {script_path}")
    assert len(missing) == 0, f"Missing script files: {missing}"


def test_main_menu_scene_exists():
    assert (SCENES_DIR / "MainMenu.tscn").exists(), "MainMenu.tscn is missing"


def test_game_scene_exists():
    assert (SCENES_DIR / "GameScene.tscn").exists(), "GameScene.tscn is missing"


# ── Scene node type consistency ─────────────────────────────────────────────


def test_game_scene_has_node2d_root():
    scn_path = SCENES_DIR / "GameScene.tscn"
    content = scn_path.read_text(encoding="utf-8")
    assert '[node name="GameScene" type="Node2D"]' in content


def test_main_menu_has_node2d_root():
    scn_path = SCENES_DIR / "MainMenu.tscn"
    content = scn_path.read_text(encoding="utf-8")
    assert '[node name="MainMenu" type="Node2D"]' in content or '[node name="MainMenu" type="Control"]' in content


# ── Scene count sanity ──────────────────────────────────────────────────────


def test_scene_count_reasonable():
    """Ensure we have a reasonable number of scenes (not zero, not hundreds)."""
    count = len(_find_tscn_files())
    assert 1 <= count <= 50, f"Unexpected scene count: {count}"
