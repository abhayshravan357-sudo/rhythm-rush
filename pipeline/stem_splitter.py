"""
Module: stem_splitter.py
Handles neural network audio separation into structural stems using Meta Demucs.
"""
import os
import subprocess
import sys
from pathlib import Path


class StemSplitter:
    def __init__(self, output_root: str = "./stems", model_name: str = "htdemucs"):
        self.output_root = Path(output_root)
        self.model_name = model_name
        self.output_root.mkdir(parents=True, exist_ok=True)

    def sanitize_filename(self, input_path: str) -> Path:
        """Enforces whitespace compliance to prevent command-line execution errors."""
        original_path = Path(input_path)
        if not original_path.exists():
            raise FileNotFoundError(f"Source file missing: {input_path}")

        sanitized_name = original_path.name.replace(" ", "_")
        sanitized_path = original_path.with_name(sanitized_name)

        if original_path != sanitized_path:
            os.rename(original_path, sanitized_path)
            print(f"[Sanitizer] Renamed source file to: {sanitized_path.name}")
        return sanitized_path

    def execute_separation(self, input_file_path: str) -> Path:
        """Invokes Demucs subprocess execution pattern to guarantee memory collection on completion."""
        valid_path = self.sanitize_filename(input_file_path)
        song_slug = valid_path.stem

        print(f"[Demucs] Starting separation pass via model: {self.model_name}...")
        command = [
            sys.executable, "-m", "demucs",
            "-n", self.model_name,
            "-o", str(self.output_root),
            str(valid_path),
        ]

        try:
            subprocess.run(command, check=True, capture_output=True, text=True)
            print("[Demucs] Subprocess closed with code 0")
        except subprocess.CalledProcessError as err:
            print(f"[Demucs Base Error] Standard Output:\n{err.stdout}")
            print(f"[Demucs Base Error] Standard Error:\n{err.stderr}")
            raise RuntimeError(f"Demucs processing failure: {err}")

        # Path tracking mapped directly to internal architecture definition
        expected_stem_directory = self.output_root / self.model_name / song_slug
        if not expected_stem_directory.exists():
            raise FileNotFoundError(
                f"Demucs output directory not resolved: {expected_stem_directory}"
            )

        print(f"[Demucs] Generated component waveforms located: {expected_stem_directory}")
        return expected_stem_directory
