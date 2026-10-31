"""
Module: onset_detector.py
Executes digital signal tracking, frequency isolation, and temporal filtering matrices.
"""
import librosa
import numpy as np
from typing import List, Tuple


class OnsetDetector:
    def __init__(self, sample_rate: int = 22050, hop_length: int = 512):
        self.sample_rate = sample_rate
        self.hop_length = hop_length

    def compute_bpm(self, audio_path: str) -> float:
        """Determines macro tempo boundaries across target stem tracking profiles."""
        y, sr = librosa.load(audio_path, sr=self.sample_rate, mono=True)
        onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=self.hop_length)
        tempo, _ = librosa.beat.beat_track(
            onset_envelope=onset_env, sr=sr, hop_length=self.hop_length
        )

        # Unpack array return types from Librosa tracking matrix
        if isinstance(tempo, np.ndarray):
            tempo = tempo[0] if tempo.size > 0 else 120.0
        return float(tempo)

    def extract_filtered_onsets(self, audio_path: str, min_gap_ms: int) -> List[float]:
        """Calculates transient energy spikes and applies non-maximum suppression windows."""
        y, sr = librosa.load(audio_path, sr=self.sample_rate, mono=True)

        raw_onset_frames = librosa.onset.onset_detect(
            y=y,
            sr=sr,
            hop_length=self.hop_length,
            units="frames",
            backtrack=True,
        )

        raw_timestamps = librosa.frames_to_time(
            raw_onset_frames, sr=sr, hop_length=self.hop_length
        )

        # Suppression parsing setup
        suppressed_timestamps: List[float] = []
        last_allocated_time = -999.0
        minimum_temporal_delta = min_gap_ms / 1000.0

        for current_time in raw_timestamps:
            if current_time - last_allocated_time >= minimum_temporal_delta:
                suppressed_timestamps.append(float(np.round(current_time, 3)))
                last_allocated_time = current_time

        return suppressed_timestamps

    def extract_tonal_onsets(
        self,
        audio_path: str,
        min_gap_ms: int,
        fallback_to_yin: bool = False,
    ) -> List[Tuple[float, float]]:
        """Maps frequency nodes to transient markers using tracking algorithms."""
        y, sr = librosa.load(audio_path, sr=self.sample_rate, mono=True)

        # Primary onset isolation logic
        raw_onset_frames = librosa.onset.onset_detect(
            y=y, sr=sr, hop_length=self.hop_length, units="frames", backtrack=True
        )
        onset_timestamps = librosa.frames_to_time(
            raw_onset_frames, sr=sr, hop_length=self.hop_length
        )

        if fallback_to_yin:
            # High speed route — YIN forces continuity; voiced flags evaluated on power boundary
            frequencies = librosa.yin(
                y=y,
                sr=sr,
                fmin=float(librosa.note_to_hz("C2")),
                fmax=float(librosa.note_to_hz("C7")),
                hop_length=self.hop_length,
            )
            voiced_flags = np.ones_like(frequencies, dtype=bool)
            time_vector = librosa.times_like(frequencies, sr=sr, hop_length=self.hop_length)
        else:
            # Probabilistic pYIN for cleaner tonal contouring
            frequencies, voiced_flags, _ = librosa.pyin(
                y=y,
                sr=sr,
                fmin=float(librosa.note_to_hz("C2")),
                fmax=float(librosa.note_to_hz("C7")),
                hop_length=self.hop_length,
            )
            time_vector = librosa.times_like(frequencies, sr=sr, hop_length=self.hop_length)

        tonal_onset_collection: List[Tuple[float, float]] = []
        last_allocated_time = -999.0
        minimum_temporal_delta = min_gap_ms / 1000.0

        for marker_time in onset_timestamps:
            if marker_time - last_allocated_time < minimum_temporal_delta:
                continue

            closest_frame_index = int(np.argmin(np.abs(time_vector - marker_time)))

            if closest_frame_index < len(voiced_flags) and voiced_flags[closest_frame_index]:
                target_freq = frequencies[closest_frame_index]
                if not np.isnan(target_freq):
                    tonal_onset_collection.append(
                        (float(np.round(marker_time, 3)), float(target_freq))
                    )
                    last_allocated_time = marker_time
            else:
                # Unvoiced transient: null frequency allows default lane routing fallback
                tonal_onset_collection.append((float(np.round(marker_time, 3)), 0.0))
                last_allocated_time = marker_time

        return tonal_onset_collection
