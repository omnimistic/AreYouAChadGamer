extends Control

signal game_finished

@onready var board: Control = $CenterContainer/board
@onready var status_label: Label = $VBoxContainer/status_label
@onready var message_label: Label = $VBoxContainer/message_label
@onready var move_timer: Timer = $move_timer

const GRID_SIZE: int = 5
const MAX_ATTEMPTS: int = 3
const TARGET_SCORE: int = 7

var current_attempt: int = 1
var best_score: int = 0
var score: int = 0

var snake: Array[Vector2i] = []
var direction: Vector2i = Vector2i.ZERO
var next_direction: Vector2i = Vector2i.ZERO
var food_pos: Vector2i = Vector2i(-1, -1)
var is_playing: bool = false
var game_over: bool = false

func _ready() -> void:
	move_timer.timeout.connect(_on_move_timer_timeout)
	board.draw.connect(_on_board_draw)
	start_attempt()

func start_attempt() -> void:
	is_playing = false
	game_over = false
	direction = Vector2i.ZERO
	next_direction = Vector2i.ZERO
	score = 0
	move_timer.stop()

	snake = [Vector2i(2, 2)]
	spawn_food()

	update_hud()
	message_label.text = "Attempt %d/%d — Press WASD or Arrow Keys to move" % [current_attempt, MAX_ATTEMPTS]
	board.queue_redraw()

func spawn_food() -> void:
	var empty_cells: Array[Vector2i] = []
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var pos = Vector2i(x, y)
			if not snake.has(pos):
				empty_cells.append(pos)

	if empty_cells.is_empty():
		win_game()
		return

	food_pos = empty_cells.pick_random()

func _input(event: InputEvent) -> void:
	if game_over:
		return

	var new_dir = Vector2i.ZERO
	if event.is_action_pressed("ui_up"):
		new_dir = Vector2i.UP
	elif event.is_action_pressed("ui_down"):
		new_dir = Vector2i.DOWN
	elif event.is_action_pressed("ui_left"):
		new_dir = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"):
		new_dir = Vector2i.RIGHT

	if new_dir != Vector2i.ZERO:
		# Prevent reversing directly into yourself
		if snake.size() == 1 or new_dir != -direction:
			next_direction = new_dir
			if not is_playing:
				is_playing = true
				direction = next_direction
				move_timer.start()
				message_label.text = ""

func _on_move_timer_timeout() -> void:
	direction = next_direction
	var head = snake[0]
	var new_head = head + direction

	# Check wall collision (outside 5x5)
	if new_head.x < 0 or new_head.x >= GRID_SIZE or new_head.y < 0 or new_head.y >= GRID_SIZE:
		handle_fail()
		return

	# Check self collision
	if snake.has(new_head):
		handle_fail()
		return

	# Move snake forward
	snake.insert(0, new_head)

	# Check food eaten
	if new_head == food_pos:
		score += 1
		best_score = maxi(best_score, score)
		update_hud()

		if score >= TARGET_SCORE:
			win_game()
			return

		spawn_food()
	else:
		# Remove tail if no food eaten
		snake.pop_back()

	board.queue_redraw()

func handle_fail() -> void:
	move_timer.stop()
	is_playing = false
	best_score = maxi(best_score, score)

	if current_attempt < MAX_ATTEMPTS:
		current_attempt += 1
		message_label.text = "Crashed! Starting Attempt %d/%d..." % [current_attempt, MAX_ATTEMPTS]
		board.queue_redraw()
		await get_tree().create_timer(1.2).timeout
		start_attempt()
	else:
		# Failed all 3 attempts
		game_over = true
		GLOBAL.minigame_scores["snake_high_score"] = best_score
		GLOBAL.minigame_scores["snake_passed"] = false
		GLOBAL.minigame_scores["snake_win_attempt"] = 0

		message_label.text = "Failed all 3 attempts! High Score: %d" % best_score
		board.queue_redraw()
		await get_tree().create_timer(1.5).timeout
		game_finished.emit()

func win_game() -> void:
	move_timer.stop()
	game_over = true
	best_score = maxi(best_score, score)

	GLOBAL.minigame_scores["snake_high_score"] = best_score
	GLOBAL.minigame_scores["snake_passed"] = true
	GLOBAL.minigame_scores["snake_win_attempt"] = current_attempt

	message_label.text = "SUCCESS! Passed on Attempt %d!" % current_attempt
	board.queue_redraw()
	await get_tree().create_timer(1.5).timeout
	game_finished.emit()

func update_hud() -> void:
	status_label.text = "Attempt: %d/%d  |  Apples: %d/%d  |  High Score: %d" % [
		current_attempt, MAX_ATTEMPTS, score, TARGET_SCORE, best_score
	]

func _on_board_draw() -> void:
	var cell_size = board.size / float(GRID_SIZE)

	# Draw grid tiles
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var rect = Rect2(Vector2(x, y) * cell_size, cell_size - Vector2(2, 2))
			board.draw_rect(rect, Color(0.18, 0.20, 0.25, 0.8))

	# Draw food
	if food_pos != Vector2i(-1, -1):
		var food_rect = Rect2(Vector2(food_pos) * cell_size + Vector2(4, 4), cell_size - Vector2(8, 8))
		board.draw_rect(food_rect, Color(0.9, 0.2, 0.2))

	# Draw snake
	for i in range(snake.size()):
		var segment = snake[i]
		var s_rect = Rect2(Vector2(segment) * cell_size + Vector2(2, 2), cell_size - Vector2(4, 4))
		var color = Color(0.2, 0.85, 0.4) if i == 0 else Color(0.1, 0.65, 0.3)
		board.draw_rect(s_rect, color)
