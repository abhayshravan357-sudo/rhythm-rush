"""
Module: lane_allocator.py
Translates raw timestamps and frequencies into operational lane layouts.
"""
import numpy as np
from typing import Any, Dict, List, Tuple


class LaneAllocator:
    def __init__(self, lane_count: int = 6):
        self.lane_count = lane_count

    def process_drums(self, timestamps: List[float]) -> List[Dict[str, Any]]:
        """Maps percussive markers to outer perimeter boundaries (Lanes 0 and 5).

        Alternates in a ping-pong pattern so that consecutive drum hits land on
        opposite sides of the playfield, producing balanced visual density.
        """
        mapped_notes: List[Dict[str, Any]] = []
        for index, timestamp in enumerate(timestamps):
            target_lane = 0 if index % 2 == 0 else 5
            mapped_notes.append(
                {
                    "timestamp": timestamp,
                    "lane": target_lane,
                    "type": "TAP",
                    "source": "drums",
                }
            )
        return mapped_notes

    def process_vocals(self, timestamps: List[float]) -> List[Dict[str, Any]]:
        """Cycles vocal transients across inner operational lanes (Lanes 1 to 4)."""
        mapped_notes: List[Dict[str, Any]] = []
        vocal_track_sequence = [1, 2, 3, 4]
        for index, timestamp in enumerate(timestamps):
            target_lane = vocal_track_sequence[index % len(vocal_track_sequence)]
            mapped_notes.append(
                {
                    "timestamp": timestamp,
                    "lane": target_lane,
                    "type": "TAP",
                    "source": "vocals",
                }
            )
        return mapped_notes

    def process_melody(
        self,
        tonal_data: List[Tuple[float, float]],
        min_freq: float = 130.0,
        max_freq: float = 880.0,
    ) -> List[Dict[str, Any]]:
        """Maps frequency contours to inner lanes and appends dynamic hold durations.

        Frequencies are mapped logarithmically so that musically equal intervals
        map to equal visual distances across Lanes 2, 3, and 4.
        """
        mapped_notes: List[Dict[str, Any]] = []

        log_min = np.log(min_freq)
        log_max = np.log(max_freq)
        log_range = log_max - log_min  # Fixed: was erroneously written as log_max - log_log_min

        for index, (timestamp, frequency) in enumerate(tonal_data):
            if frequency <= 0.0:
                target_lane = 2  # Default fallback for unvoiced melody markers
            else:
                bounded_freq = float(np.clip(frequency, min_freq, max_freq))
                normalized_scale = (np.log(bounded_freq) - log_min) / log_range
                target_lane = int(2 + np.round(normalized_scale * 2))
                target_lane = int(np.clip(target_lane, 2, 4))

            # Pseudo-random, structurally uniform hold duration (0.30 – 0.70 s)
            simulated_duration = float(np.round(0.3 + ((index % 5) * 0.1), 2))

            mapped_notes.append(
                {
                    "timestamp": timestamp,
                    "lane": target_lane,
                    "type": "HOLD",
                    "duration": simulated_duration,
                    "source": "other",
                }
            )
        return mapped_notes
