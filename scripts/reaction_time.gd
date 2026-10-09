extends Control

signal game_finished

@onready var bg_rect = $ColorRect
@onready var prompt_label = $Label
@onready var wait_timer = $Timer

const TOTAL_ATTEMPTS: int = 3
var attempts: Array[float] = []

var state: String = "IDLE"
var time_turned_green: int = 0

func _ready() -> void:
	wait_timer.one_shot = true
	start_attempt()

func start_attempt() -> void:
	state = "WAITING"
	bg_rect.color = Color.RED
	prompt_label.text = "Attempt %d/%d\nWait for Green..." % [attempts.size() + 1, TOTAL_ATTEMPTS]
	wait_timer.start(randf_range(2.0, 5.0))

func _on_timer_timeout() -> void:
	state = "CLICK"
	bg_rect.color = Color.GREEN
	prompt_label.text = "CLICK NOW!"
	time_turned_green = Time.get_ticks_msec()

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	match state:
		"WAITING":
			# Clicked too early: cancel timer and let them retry the same attempt
			wait_timer.stop()
			bg_rect.color = Color.DARK_RED
			prompt_label.text = "Too early!\nClick to retry this attempt."
			state = "RETRY"

		"CLICK":
			# Successful click
			var reaction_time: float = (Time.get_ticks_msec() - time_turned_green) / 1000.0
			attempts.append(reaction_time)
			
			if attempts.size() < TOTAL_ATTEMPTS:
				bg_rect.color = Color.DARK_SLATE_GRAY
				prompt_label.text = "Time: %.3fs\nClick for next round." % reaction_time
				state = "NEXT_ROUND"
			else:
				finish_game()

		"RETRY":
			start_attempt()

		"NEXT_ROUND":
			start_attempt()

func finish_game() -> void:
	state = "FINISHED"
	
	# Calculate best and average times
	var best_time: float = attempts.min()
	var total_time: float = 0.0
	for t in attempts:
		total_time += t
	var avg_time: float = total_time / attempts.size()

	# Save to Global
	GLOBAL.minigame_scores["reaction_best"] = best_time
	GLOBAL.minigame_scores["reaction_average"] = avg_time

	# Display final screen briefly
	bg_rect.color = Color.STEEL_BLUE
	prompt_label.text = "Done!\nBest: %.3fs | Avg: %.3fs" % [best_time, avg_time]

	# Brief delay so player sees their score before transition begins
	await get_tree().create_timer(1.2).timeout
	game_finished.emit()
