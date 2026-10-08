extends Control

signal game_finished

@onready var board: Control = $CenterContainer/board
@onready var status_label: Label = $VBoxContainer/status_label
@onready var message_label: Label = $VBoxContainer/message_label
@onready var move_timer: Timer = $move_timer

@onready var food_sprite: TextureRect = $CenterContainer/board/entity_container/food_sprite
@onready var snake_container: Control = $CenterContainer/board/entity_container/snake

@export var head_texture: Texture2D
@export var body_texture: Texture2D
@export var tail_texture: Texture2D

const GRID_SIZE: int = 5
const MAX_ATTEMPTS: int = 5
const TARGET_SCORE: int = 23

var current_attempt: int = 1
var best_score: int = 0
var score: int = 0

var snake: Array[Vector2i] = []
var direction: Vector2i = Vector2i.ZERO
var next_direction: Vector2i = Vector2i.ZERO
var food_pos: Vector2i = Vector2i(-1, -1)
var is_playing: bool = false
var game_over: bool = false

var snake_nodes: Array[TextureRect] = []

func _ready() -> void:
	move_timer.timeout.connect(_on_move_timer_timeout)
	start_attempt()

func get_cell_size() -> Vector2:
	return board.size / float(GRID_SIZE)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos) * get_cell_size()

func get_rotation_for_dir(dir: Vector2i) -> float:
	match dir:
		Vector2i.UP:
			return 0.0
		Vector2i.RIGHT:
			return deg_to_rad(90.0)
		Vector2i.DOWN:
			return deg_to_rad(180.0)
		Vector2i.LEFT:
			return deg_to_rad(270.0)
		_:
			return 0.0

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
	update_snake_visuals()
	message_label.text = "Attempt %d/%d — Press WASD or Arrow Keys" % [current_attempt, MAX_ATTEMPTS]

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
	
	var cell_size = get_cell_size()
	food_sprite.size = cell_size
	food_sprite.position = grid_to_world(food_pos)
	food_sprite.show()

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

	if new_head.x < 0 or new_head.x >= GRID_SIZE or new_head.y < 0 or new_head.y >= GRID_SIZE:
		handle_fail()
		return

	if snake.has(new_head):
		handle_fail()
		return

	snake.insert(0, new_head)

	if new_head == food_pos:
		score += 1
		best_score = maxi(best_score, score)
		update_hud()

		if score >= TARGET_SCORE:
			win_game()
			return
		spawn_food()
	else:
		snake.pop_back()

	update_snake_visuals()

func update_snake_visuals() -> void:
	var cell_size = get_cell_size()

	while snake_nodes.size() < snake.size():
		var rect = TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		snake_container.add_child(rect)
		snake_nodes.append(rect)

	while snake_nodes.size() > snake.size():
		var extra = snake_nodes.pop_back()
		extra.queue_free()

	for i in range(snake.size()):
		var node = snake_nodes[i]
		node.size = cell_size
		node.position = grid_to_world(snake[i])
		node.pivot_offset = cell_size / 2.0

		var seg_dir: Vector2i = Vector2i.UP

		if i == 0:
			node.texture = head_texture if head_texture else body_texture
			seg_dir = direction if direction != Vector2i.ZERO else Vector2i.UP
		elif i == snake.size() - 1 and tail_texture != null:
			node.texture = tail_texture
			seg_dir = snake[i - 1] - snake[i]
		else:
			node.texture = body_texture
			seg_dir = snake[i - 1] - snake[i]

		node.rotation = get_rotation_for_dir(seg_dir)

func handle_fail() -> void:
	move_timer.stop()
	is_playing = false
	best_score = maxi(best_score, score)

	if current_attempt < MAX_ATTEMPTS:
		current_attempt += 1
		message_label.text = "Crashed! Attempt %d/%d starting..." % [current_attempt, MAX_ATTEMPTS]
		await get_tree().create_timer(1.2).timeout
		start_attempt()
	else:
		game_over = true
		GLOBAL.minigame_scores["snake_high_score"] = best_score
		GLOBAL.minigame_scores["snake_passed"] = false
		GLOBAL.minigame_scores["snake_win_attempt"] = 0

		message_label.text = "Failed all attempts! High Score: %d" % best_score
		await get_tree().create_timer(1.5).timeout
		game_finished.emit()

func win_game() -> void:
	move_timer.stop()
	game_over = true
	best_score = maxi(best_score, score)

	GLOBAL.minigame_scores["snake_high_score"] = best_score
	GLOBAL.minigame_scores["snake_passed"] = true
	GLOBAL.minigame_scores["snake_win_attempt"] = current_attempt

	message_label.text = "Passed on Attempt %d!" % current_attempt
	await get_tree().create_timer(1.5).timeout
	game_finished.emit()

func update_hud() -> void:
	status_label.text = "Attempt: %d/%d  |  Apples: %d/%d  |  High Score: %d" % [
		current_attempt, MAX_ATTEMPTS, score, TARGET_SCORE, best_score
	]
