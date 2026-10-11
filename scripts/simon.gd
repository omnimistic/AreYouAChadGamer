extends Control

signal game_finished

@onready var status_label: Label = $VBoxContainer/status_label
@onready var score_label: Label = $VBoxContainer/score_label
@onready var pads: Array[Button] = [
	$CenterContainer/GridContainer/Button,
	$CenterContainer/GridContainer/Button2,
	$CenterContainer/GridContainer/Button3,
	$CenterContainer/GridContainer/Button4
]

const PAD_COLORS: Array[Color] = [
	Color(0.15, 0.85, 0.35),
	Color(0.95, 0.25, 0.25),
	Color(0.25, 0.55, 0.95),
	Color(0.95, 0.85, 0.20)
]

const TARGET_SEQUENCE: int = 7

var sequence: Array[int] = []
var player_step: int = 0
var is_player_turn: bool = false

func _ready() -> void:
	for i in range(pads.size()):
		var idx = i
		pads[idx].modulate = PAD_COLORS[idx] * 0.4
		pads[idx].pressed.connect(func(): _on_pad_pressed(idx))

	start_game()

func start_game() -> void:
	sequence.clear()
	score_label.text = "Sequence: 0 / %d" % TARGET_SEQUENCE
	next_round()

func next_round() -> void:
	is_player_turn = false
	player_step = 0
	sequence.append(randi() % 4)
	score_label.text = "Sequence: %d / %d" % [sequence.size(), TARGET_SEQUENCE]
	status_label.text = "Watch the sequence..."

	await get_tree().create_timer(0.6).timeout
	play_sequence()

func play_sequence() -> void:
	for pad_index in sequence:
		await flash_pad(pad_index, 0.32)
		await get_tree().create_timer(0.12).timeout

	status_label.text = "Your turn!"
	is_player_turn = true

func flash_pad(index: int, duration: float) -> void:
	var pad = pads[index]
	var tw = create_tween()
	tw.tween_property(pad, "modulate", PAD_COLORS[index] * 1.8, duration * 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(pad, "modulate", PAD_COLORS[index] * 0.4, duration * 0.6)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

func _on_pad_pressed(index: int) -> void:
	if not is_player_turn:
		return

	flash_pad(index, 0.2)

	if index == sequence[player_step]:
		player_step += 1
		if player_step >= sequence.size():
			is_player_turn = false
			if sequence.size() >= TARGET_SEQUENCE:
				end_game(true)
			else:
				status_label.text = "Correct! Get ready..."
				await get_tree().create_timer(0.8).timeout
				next_round()
	else:
		is_player_turn = false
		end_game(false)

func end_game(passed: bool) -> void:
	var final_score = sequence.size() if passed else max(0, sequence.size() - 1)
	GLOBAL.minigame_scores["simon_max_sequence"] = final_score
	GLOBAL.minigame_scores["simon_passed"] = passed

	status_label.text = "Sequence Cleared!" if passed else "Wrong Pad! Memory Limit Reached."
	await get_tree().create_timer(1.4).timeout
	game_finished.emit()
