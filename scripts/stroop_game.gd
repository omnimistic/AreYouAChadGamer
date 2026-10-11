extends Control

signal game_finished

@onready var round_label: Label = $VBoxContainer/round_label
@onready var color_word_label: Label = $VBoxContainer/color_word_label
@onready var match_btn: Button = $VBoxContainer/HBoxContainer/match
@onready var no_match_btn: Button = $VBoxContainer/HBoxContainer/no_match

const TOTAL_ROUNDS: int = 15

const COLOR_MAP: Dictionary = {
	"VIOLET": Color(0.72, 0.3, 0.95),
	"BLUE": Color(0.2, 0.65, 1.0),
	"GREEN": Color(0.2, 0.85, 0.35),
	"YELLOW": Color(0.98, 0.88, 0.2),
	"ORANGE": Color(1.0, 0.55, 0.1),
	"RED": Color(0.95, 0.25, 0.25),
	"PINK": Color(1.0, 0.4, 0.7)
}

var current_round: int = 0
var correct_answers: int = 0
var round_start_time: int = 0
var reaction_times: Array[float] = []

var is_current_match: bool = false
var input_locked: bool = false

var last_text_key: String = ""
var last_color_key: String = ""

func _ready() -> void:
	match_btn.pressed.connect(func(): handle_player_choice(true))
	no_match_btn.pressed.connect(func(): handle_player_choice(false))
	next_round()

func next_round() -> void:
	if current_round >= TOTAL_ROUNDS:
		finish_game()
		return

	current_round += 1
	round_label.text = "Round %d / %d" % [current_round, TOTAL_ROUNDS]
	input_locked = false

	var color_names = COLOR_MAP.keys()
	var text_key: String = ""
	var font_color_key: String = ""

	while true:
		is_current_match = randf() < 0.5
		text_key = color_names.pick_random()

		if is_current_match:
			font_color_key = text_key
		else:
			var mismatched = color_names.duplicate()
			mismatched.erase(text_key)
			font_color_key = mismatched.pick_random()

		if text_key != last_text_key or font_color_key != last_color_key:
			break

	last_text_key = text_key
	last_color_key = font_color_key

	color_word_label.text = text_key
	color_word_label.add_theme_color_override("font_color", COLOR_MAP[font_color_key])

	round_start_time = Time.get_ticks_msec()

func handle_player_choice(chose_match: bool) -> void:
	if input_locked:
		return

	input_locked = true
	var reaction_ms = float(Time.get_ticks_msec() - round_start_time)
	reaction_times.append(reaction_ms)

	var is_correct = (chose_match == is_current_match)
	if is_correct:
		correct_answers += 1

	color_word_label.pivot_offset = color_word_label.size / 2.0

	var tw = create_tween()
	tw.tween_property(color_word_label, "scale", Vector2(1.2, 1.2), 0.08)
	tw.tween_property(color_word_label, "scale", Vector2.ONE, 0.08)
	await tw.finished

	next_round()

func finish_game() -> void:
	input_locked = true
	match_btn.disabled = true
	no_match_btn.disabled = true

	var total_ms: float = 0.0
	for t in reaction_times:
		total_ms += t
	var avg_reaction = total_ms / float(reaction_times.size()) if reaction_times.size() > 0 else 0.0
	var accuracy = (float(correct_answers) / float(TOTAL_ROUNDS)) * 100.0

	GLOBAL.minigame_scores["stroop_correct"] = correct_answers
	GLOBAL.minigame_scores["stroop_accuracy"] = accuracy
	GLOBAL.minigame_scores["stroop_avg_reaction_ms"] = avg_reaction

	color_word_label.text = "Test Completed!"
	color_word_label.add_theme_color_override("font_color", Color.WHITE)

	await get_tree().create_timer(1.2).timeout
	game_finished.emit()
