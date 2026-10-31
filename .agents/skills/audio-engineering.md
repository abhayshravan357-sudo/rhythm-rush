# Skill: Audio Engineering — Music Synchronization & Latency Calibration

Purpose: Keep gameplay timing locked to an authoritative audio clock and calibrate device audio latency for PROJECT RHYTHM.

## Scope

- Authoritative audio clock (AudioServer hardware time, not accumulated delta)
- Music playback start/stop/pause/resume
- Hit-window evaluation against playback position
- Audio latency calibration (metronome + user tap offset)
- Persistence of user offset to user://settings.cfg

## Procedure: Use the authoritative audio clock (AudioSync.gd)

1. AudioSync.initialize_playback_channel(target_player) binds an AudioStreamPlayer.
2. AudioSync.start_audio_pipeline() calls audio_player_node.play() and sets active_playback_flag.
3. Each _process frame while active:
   - During startup guard (3 frames): estimate time via frame delta.
   - After guard: current_audio_time = get_playback_position() + AudioServer.get_time_since_last_mix().
   - adjusted_system_time = current_audio_time - local_hardware_offset.
4. Never accumulate delta for note timing; always read adjusted_system_time.
5. On playback end (audio_player_node.playing false, guard expired): active_playback_flag = false, emit song_completed.

## Procedure: Calibrate audio latency (OffsetCalibration.gd)

1. Start calibration: reset taps, set _running = true, fire calibration_tick every INTERVAL_SECONDS (0.5 s).
2. User taps TapButton in time with each beat; register_tap() computes signed_delta from _accumulator, wraps to [-0.25, +0.25] s, discards outliers > OUTLIER_THRESHOLD (0.250 s).
3. After REQUIRED_TAPS (12) valid taps: compute mean, persist to user://settings.cfg [audio] user_offset.
4. AudioSync.load_calibration_data() reads user_offset on ready and applies it to every adjusted_system_time calculation.
5. Calibration can be re-run without restart (AudioSync.local_hardware_offset updated live).

## Procedure: Evaluate a hit (ScoreManager.gd)

1. On touch in lane L: playback_time = AudioSync.adjusted_system_time.
2. Scan unresolved notes in lane L; find note with minimum |playback_time - timestamp|.
3. If best_delta <= 0.180 s: evaluate precision (PERFECT ≤45 ms / GOOD ≤90 ms / OK ≤150 ms); else MISS.
4. Mark note resolved (resolved_flags[i] = true) to prevent duplicate hits.
5. Auto-miss any unresolved note when playback_time > timestamp + 0.150 s.
6. Emit alignment_processed(rating, combo); on song end emit sequence_tracking_concluded(final_score, max_combo).

## Example: Hit-window table (initial design targets)

| Rating | Window | Points |
|--------|--------|--------|
| PERFECT | ±50 ms | 300 |
| GOOD | ±100 ms | 100 |
| MISS | outside window | 0 (combo reset) |

## Acceptance criteria

- [ ] Timing uses AudioServer clock, not accumulated frame delta
- [ ] Offset persists across restarts (user://settings.cfg)
- [ ] No duplicate hits per note (resolved_flags)
- [ ] Auto-miss fires for notes drifting past window
- [ ] Audio stops on game over / song end
- [ ] QA verifies hit windows within tolerance on real device

## Files owned

- godot_project/scripts/AudioSync.gd
- godot_project/scripts/OffsetCalibration.gd
- godot_project/scripts/ScoreManager.gd
- music/ (audio assets + registry)
