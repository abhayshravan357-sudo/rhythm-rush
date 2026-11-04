"""Pure-Python reference implementation of AudioSync (godot_project/scripts/AudioSync.gd).

Models the MVP-03 audio-clock synchronisation behaviour so it can be verified
without the Godot engine:

  - adjusted_system_time = current_audio_time - local_hardware_offset
  - pause_audio_pipeline() freezes adjusted_system_time; resume continues from
    the paused position (no backward jump = no timing corruption).
  - Song completion detection when playback position reaches song_duration.
  - Timing drift analysis: drift_ms() reports mean (audio_clock - adjusted).
"""

from __future__ import annotations


class AudioSync:
    """Reference model of the AudioSync autoload singleton."""

    APPROACH_TIME: float = 1.5

    def __init__(self) -> None:
        self.current_audio_time: float = 0.0
        self.adjusted_system_time: float = 0.0
        self.local_hardware_offset: float = 0.0
        self.active_playback_flag: bool = False
        self.is_paused: bool = False
        self._paused_adjusted_time: float = 0.0
        self.song_duration: float = 0.0
        self._drift_samples: list[float] = []
        self.song_completed: bool = False
        self.playback_paused: bool = False
        self.playback_resumed: bool = False

    # ── Queries ──────────────────────────────────────────────────────────────

    def get_playback_position_seconds(self) -> float:
        return self.adjusted_system_time

    def get_raw_audio_time(self) -> float:
        return self.current_audio_time

    def is_playing(self) -> bool:
        return self.active_playback_flag

    def is_paused_state(self) -> bool:
        return self.is_paused

    def get_offset(self) -> float:
        return self.local_hardware_offset

    def get_approach_time(self) -> float:
        return self.APPROACH_TIME

    def drift_ms(self) -> float:
        if not self._drift_samples:
            return 0.0
        return (sum(self._drift_samples) / len(self._drift_samples)) * 1000.0

    def drift_sample_count(self) -> int:
        return len(self._drift_samples)

    # ── Lifecycle ────────────────────────────────────────────────────────────

    def initialize_playback_channel(self, target_player: object) -> None:
        self.active_playback_flag = False
        self.is_paused = False
        self.current_audio_time = 0.0
        self.adjusted_system_time = 0.0
        self._paused_adjusted_time = 0.0
        self.song_duration = 0.0
        self._drift_samples.clear()
        self.song_completed = False
        self.playback_paused = False
        self.playback_resumed = False

    def set_offset(self, seconds: float) -> None:
        self.local_hardware_offset = float(seconds)

    def set_song_duration(self, seconds: float) -> None:
        self.song_duration = max(0.0, float(seconds))

    def start_audio_pipeline(self) -> None:
        if self.is_paused:
            self._resume_from_pause()
            return
        self.active_playback_flag = True
        self.is_paused = False
        self.current_audio_time = 0.0
        self.adjusted_system_time = 0.0

    def _resume_from_pause(self) -> None:
        seek_position = self._paused_adjusted_time + self.local_hardware_offset
        seek_position = max(0.0, seek_position)
        self.current_audio_time = seek_position
        self.adjusted_system_time = self.current_audio_time - self.local_hardware_offset
        self.active_playback_flag = True
        self.is_paused = False
        self.playback_resumed = True

    def pause_audio_pipeline(self) -> None:
        if not self.active_playback_flag or self.is_paused:
            return
        self.is_paused = True
        self.active_playback_flag = False
        self._paused_adjusted_time = self.adjusted_system_time
        self.playback_paused = True

    def stop_audio_pipeline(self) -> None:
        self.active_playback_flag = False
        self.is_paused = False
        self.current_audio_time = 0.0
        self.adjusted_system_time = 0.0
        self._paused_adjusted_time = 0.0

    def process_tick(self, raw_audio_time: float) -> None:
        """Simulate one _process tick with the given raw audio clock position."""
        if not self.active_playback_flag or self.is_paused:
            return
        self.current_audio_time = float(raw_audio_time)
        self.adjusted_system_time = self.current_audio_time - self.local_hardware_offset
        if self.song_duration > 0.0 and self.current_audio_time >= self.song_duration:
            self.active_playback_flag = False
            self.is_paused = False
            self.song_completed = True
            return
        self._drift_samples.append(self.current_audio_time - self.adjusted_system_time)
