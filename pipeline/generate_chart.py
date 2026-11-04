"""
Module: generate_chart.py
Main entry orchestrator parsing raw audio streams into chart.json data contracts.

Usage:
    python generate_chart.py <path_to_audio.mp3>
"""
import json
import sys
from pathlib import Path

import librosa
import numpy as np

from stem_splitter import StemSplitter
from onset_detector import OnsetDetector
from lane_allocator import LaneAllocator


def extract_waveform_envelope(audio_path: str, targets: int = 150) -> list:
    """Downsamples audio to a normalised amplitude vector for UI waveform rendering."""
    y, sr = librosa.load(audio_path, sr=11025, mono=True)
    chunk_size = len(y) // targets
    if chunk_size == 0:
        return [1.0] * targets

    envelope = []
    for i in range(targets):
        slice_data = y[i * chunk_size : (i + 1) * chunk_size]
        if len(slice_data) > 0:
            peak = float(np.max(np.abs(slice_data)))
            envelope.append(round(peak, 3))
        else:
            envelope.append(0.0)

    max_val = max(envelope) if max(envelope) > 0 else 1.0
    return [round(x / max_val, 3) for x in envelope]


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python generate_chart.py <path_to_audio.mp3>")
        sys.exit(1)

    input_audio = sys.argv[1]

    # Structural initialisations
    splitter = StemSplitter()
    detector = OnsetDetector()
    allocator = LaneAllocator()

    # ── Phase 1: Stem isolation ────────────────────────────────────────────────
    has_stems = False
    drum_path = input_audio
    vocal_path = None
    other_path = None

    try:
        stem_directory = splitter.execute_separation(input_audio)
        drum_path = str(stem_directory / "drums.wav")
        vocal_path = str(stem_directory / "vocals.wav")
        other_path = str(stem_directory / "other.wav")
        has_stems = True
    except Exception as ex:
        print(f"[Pipeline Notice] Demucs stem separation bypassed/unavailable ({ex}). Falling back to direct audio analysis.")

    # ── Phase 2: DSP extraction ────────────────────────────────────────────────
    print("[Pipeline Phase 2] Running transient DSP operations...")
    macro_tempo = detector.compute_bpm(drum_path)

    compiled_notes = []
    if has_stems and vocal_path and other_path:
        drum_timestamps = detector.extract_filtered_onsets(drum_path, min_gap_ms=150)
        vocal_timestamps = detector.extract_filtered_onsets(vocal_path, min_gap_ms=120)
        melody_tonal_data = detector.extract_tonal_onsets(
            other_path, min_gap_ms=200, fallback_to_yin=False
        )
        compiled_notes.extend(allocator.process_drums(drum_timestamps))
        compiled_notes.extend(allocator.process_vocals(vocal_timestamps))
        compiled_notes.extend(allocator.process_melody(melody_tonal_data))
    else:
        # Direct full-mix onset extraction for 4-lane chart
        mix_timestamps = detector.extract_filtered_onsets(drum_path, min_gap_ms=180)
        compiled_notes.extend(allocator.process_drums(mix_timestamps))

    # Enforce global chronological sort
    compiled_notes.sort(key=lambda x: x["timestamp"])

    # ── Metadata ───────────────────────────────────────────────────────────────
    y, sr = librosa.load(input_audio, sr=22050, mono=True)
    total_duration_seconds = float(np.round(librosa.get_duration(y=y, sr=sr), 2))
    visual_envelope = extract_waveform_envelope(input_audio)

    chart_payload = {
        "metaData": {
            "songName": Path(input_audio).stem,
            "bpm": round(macro_tempo, 2),
            "totalDuration": total_duration_seconds,
            "laneCount": 4 if not has_stems else 6,
            # Preserve the source extension so the packaged Godot audio asset
            # can be resolved by GameScene instead of assuming conversion.
            "audioFile": Path(input_audio).name,
            "waveformEnvelope": visual_envelope,
        },
        "noteTimeline": compiled_notes,
    }

    # ── Output ─────────────────────────────────────────────────────────────────
    output_directory = Path("./charts")
    output_directory.mkdir(exist_ok=True)
    target_output_json = output_directory / f"{Path(input_audio).stem}_chart.json"

    with open(target_output_json, "w") as out_file:
        json.dump(chart_payload, out_file, indent=2)

    print(f"\n[Pipeline Completed Successfully]")
    print(f"  Total Notes Mapped : {len(compiled_notes)}")
    print(f"  BPM Detected       : {round(macro_tempo, 2)}")
    print(f"  Duration           : {total_duration_seconds}s")
    print(f"  Output             : {target_output_json}")


if __name__ == "__main__":
    main()
