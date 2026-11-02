"""Pure-Python reference implementation of GameController lifecycle and state machine.

Mirrors godot_project/scripts/core/GameController.gd and GameStateManager.gd
(song preparation, start/pause/resume/complete/exit, state transitions).
"""


class GameState:
    MAIN_MENU = "MAIN_MENU"
    SONG_SELECTION = "SONG_SELECTION"
    LOADING = "LOADING"
    PLAYING = "PLAYING"
    PAUSED = "PAUSED"
    RESULTS = "RESULTS"
    GAME_OVER = "GAME_OVER"
    CALIBRATION = "CALIBRATION"


class GameStateManager:
    def __init__(self):
        self.current_state = GameState.MAIN_MENU
        self.previous_state = GameState.MAIN_MENU

    def transition_to(self, next_state: str) -> None:
        if next_state == self.current_state:
            return
        self.previous_state = self.current_state
        self.current_state = next_state

    def is_playing(self) -> bool:
        return self.current_state == GameState.PLAYING

    def is_paused(self) -> bool:
        return self.current_state == GameState.PAUSED

    def reset_to_main_menu(self) -> None:
        self.transition_to(GameState.MAIN_MENU)


class ScoreManager:
    """Minimal reference for GameController integration testing."""

    def __init__(self):
        self.score = 0
        self.combo = 0
        self.max_combo = 0
        self.chart_loaded = False

    def reset_scoring_matrix(self, chart: dict) -> None:
        self.chart_loaded = True


class AudioSync:
    """Minimal reference for GameController integration testing."""

    def __init__(self):
        self.active = False

    def start_audio_pipeline(self) -> None:
        self.active = True

    def stop_audio_pipeline(self) -> None:
        self.active = False


class GameController:
    """Reference implementation of GameController lifecycle management."""

    def __init__(self):
        self.song_loaded_called = False
        self.song_started_called = False
        self.song_paused_called = False
        self.song_completed_called = False
        self.game_over_called = False

        self.current_song_id: str = ""
        self.current_chart_path: str = ""
        self.current_chart: dict = {}
        self.is_game_active: bool = False

        self.state_manager = GameStateManager()
        self.score_manager = ScoreManager()
        self.audio_sync = AudioSync()

    def prepare_song(self, song_id: str, chart_path: str) -> bool:
        self.current_song_id = song_id
        self.current_chart_path = chart_path
        self.state_manager.transition_to(GameState.LOADING)
        self.current_chart = {"noteTimeline": chart_path and []}  # Simplified: empty chart OK for testing
        self.score_manager.reset_scoring_matrix(self.current_chart)
        self.song_loaded_called = True
        return True

    def start_song(self) -> None:
        if not self.current_chart:
            return
        self.is_game_active = True
        self.state_manager.transition_to(GameState.PLAYING)
        self.audio_sync.start_audio_pipeline()
        self.song_started_called = True

    def pause_song(self) -> None:
        if not self.is_game_active:
            return
        self.state_manager.transition_to(GameState.PAUSED)
        self.song_paused_called = True

    def resume_song(self) -> None:
        if self.state_manager.current_state != GameState.PAUSED:
            return
        self.state_manager.transition_to(GameState.PLAYING)

    def complete_song(self) -> None:
        self.is_game_active = False
        self.audio_sync.stop_audio_pipeline()
        self.state_manager.transition_to(GameState.RESULTS)
        self.song_completed_called = True

    def game_over(self, final_score: int = 0, max_combo: int = 0, accuracy: float = 0.0) -> None:
        self.is_game_active = False
        self.audio_sync.stop_audio_pipeline()
        self.state_manager.transition_to(GameState.GAME_OVER)
        self.game_over_called = True

    def exit_to_menu(self) -> None:
        self.is_game_active = False
        self.audio_sync.stop_audio_pipeline()
        self.state_manager.reset_to_main_menu()
        self.current_chart.clear()
        self.current_song_id = ""
        self.current_chart_path = ""