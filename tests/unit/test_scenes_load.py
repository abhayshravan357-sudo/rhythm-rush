"""Unit tests for scene file validity.

Verifies that all .tscn scene files in the project are valid Godot scene
files (start with [gd_scene], have scene format version, define at least
one node). These are static checks — they do not require the Godot engine
to be running.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SCENES_DIR = ROOT / "godot_project" / "scenes"


def _find_tscn_files() -> list[Path]:
    return sorted(SCENES_DIR.glob("*.tscn"))


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


def test_all_scenes_have_format_version():
    for scn_path in _find_tscn_files():
        content = scn_path.read_text(encoding="utf-8")
        assert "format=" in content, (
            f"{scn_path.name} missing format version"
        )


def test_all_scenes_have_at_least_one_node():
    for scn_path in _find_tscn_files():
        content = scn_path.read_text(encoding="utf-8")
        # Look for node declarations: [node name="..." type="..."]
        assert re.search(r'\[node name=', content), (
            f"{scn_path.name} defines no nodes"
        )


def test_main_menu_scene_exists():
    assert (SCENES_DIR / "MainMenu.tscn").exists(), "MainMenu.tscn is missing"


def test_game_scene_exists():
    assert (SCENES_DIR / "GameScene.tscn").exists(), "GameScene.tscn is missing"


# ── Scene count sanity ──────────────────────────────────────────────────────


def test_scene_count_reasonable():
    """Ensure we have a reasonable number of scenes (not zero, not hundreds)."""
    count = len(_find_tscn_files())
    assert 1 <= count <= 50, f"Unexpected scene count: {count}"
