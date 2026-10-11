extends Node

var minigame_scores = {
	"reaction_best": 0.0,
	"reaction_average": 0.0,
	"snake_high_score": 0,
	"snake_passed": false,
	"snake_win_attempt": 0, # 1, 2, 3, or 0 if failed all attempts
	"dodge_score": 0,
	"dodge_best_score": 0,
	"dodge_survival_time": 0.0,
	"dodge_blocks_dodged": 0,
	"shooter_hits": 0,
	"shooter_shots": 0,
	"shooter_accuracy": 0.0,
	"rhythm_passed": false,
	"rhythm_win_attempt": 0,
	"rhythm_final_mood": 0,
	"jee_correct": 0,
	"jee_incorrect": 0,
	"jee_unanswered": 0,
	"jee_accuracy": 0.0,
	"jee_completion_time": 0.0,
	"jee_score": 0.0,
	"predict_correct": 0,
	"predict_incorrect": 0,
	"predict_avg_time": 0.0,
	"predict_score": 0.0,
	"simon_max_sequence": 0,
	"simon_passed": false,
	"stroop_correct": 0,
	"stroop_accuracy": 0.0,
	"stroop_avg_reaction_ms": 0.0
}

var bgm_stream: AudioStream = preload("res://assets/The most beautiful 120 BPM.wav")
var bgm_player: AudioStreamPlayer

func _ready() -> void:
	setup_bgm_player()

func setup_bgm_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	bgm_player.volume_db = -6.0

	if bgm_stream is AudioStreamWAV:
		var wav = bgm_stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if wav.loop_end <= wav.loop_begin:
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)

	bgm_player.stream = bgm_stream

	bgm_player.finished.connect(func():
		if not bgm_player.stream_paused:
			bgm_player.play()
	)

	add_child(bgm_player)

func play_bgm() -> void:
	if not bgm_player.playing:
		bgm_player.play()

func pause_bgm() -> void:
	bgm_player.stream_paused = true

func resume_bgm() -> void:
	bgm_player.stream_paused = false

func stop_bgm() -> void:
	bgm_player.stop()
