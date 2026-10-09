extends Control

signal game_finished

# the stage art is never stretched, only scaled uniformly to fit the window
const FLOOR_RATIO := 0.89          # feet line as a fraction of the art height
const EDGE_MARGIN := 36.0

const PLAYER_FEET_OFFSET := 19.0   # feet sit this far below the cell centre in the sheet
const HIT_HALF_W := 18.0
const HIT_HALF_H := 24.0

const MOVE_SPEED := 340.0

const BLOCK_TEXTURE_SIZE := 64.0   # source tile with its thick rim
const BLOCK_SIZE := 40.0           # drawn size
const COLUMN_COUNT := 10

# every block rolls its own speed, and the band widens as the round goes on
const FALL_SPEED_MIN := 105.0
const FALL_SPEED_MAX := 250.0
const FALL_SPEED_CAP := 520.0
const FALL_RAMP := 6.0
const FALL_JITTER := 60.0

const TIME_LIMIT := 40.0           # survive this long to win

const SPAWN_FIRST := 0.6
const SPAWN_START := 0.42
const SPAWN_MIN := 0.17
const SPAWN_RAMP := 0.010
const SPAWN_JITTER := 0.12
const SPAWN_CLEARANCE := 2.5       # keep a column clear under a block that just appeared

const TEX_RED: Texture2D = preload("res://assets/block_dodge/block_red.png")
const TEX_GREEN: Texture2D = preload("res://assets/block_dodge/block_green.png")
const TEX_YELLOW: Texture2D = preload("res://assets/block_dodge/block_yellow.png")

enum State { PLAYING, OVER, DONE }

@onready var stage: Control = $stage
@onready var bg: TextureRect = $stage/bg
@onready var entities: Node2D = $stage/entities
@onready var player: AnimatedSprite2D = $stage/entities/player
@onready var hud: Control = $stage/hud
@onready var score_label: Label = $stage/hud/score_label
@onready var best_label: Label = $stage/hud/best_label
@onready var hint_label: Label = $stage/hud/hint_label
@onready var overlay: Control = $stage/game_over
@onready var title_label: Label = $stage/game_over/panel/title_label
@onready var result_label: Label = $stage/game_over/panel/result_label
@onready var retry_btn: Button = $stage/game_over/panel/buttons/retry_btn
@onready var next_btn: Button = $stage/game_over/panel/buttons/next_btn

var stage_size := Vector2(680.0, 340.0)
var column_pitch := 68.0
var floor_y := 302.6
var state: int = State.PLAYING
var score: int = 0
var best_score: int = 0
var survival_time: float = 0.0
var dodged: int = 0
var velocity_x: float = 0.0
var spawn_timer: float = SPAWN_FIRST
var last_column: int = -1
var hint_faded: bool = false
var blocks: Array[Sprite2D] = []

func _ready() -> void:
	best_score = int(GLOBAL.minigame_scores.get("dodge_best_score", 0))
	_apply_stage_art()
	resized.connect(_layout_stage)
	_layout_stage()
	retry_btn.pressed.connect(_start_round)
	next_btn.pressed.connect(_next_game)
	_start_round()

func _next_game() -> void:
	state = State.DONE
	overlay.hide()
	game_finished.emit()

func _apply_stage_art() -> void:
	if bg.texture != null:
		stage_size = Vector2(bg.texture.get_width(), bg.texture.get_height())
	bg.size = stage_size
	stage.size = stage_size
	hud.size = stage_size
	overlay.size = stage_size
	column_pitch = stage_size.x / float(COLUMN_COUNT)
	floor_y = stage_size.y * FLOOR_RATIO

func _layout_stage() -> void:
	var view: Vector2 = size
	if view.x <= 0.0 or view.y <= 0.0:
		return
	var factor: float = minf(view.x / stage_size.x, view.y / stage_size.y)
	stage.scale = Vector2(factor, factor)
	stage.position = (view - stage_size * factor) * 0.5

func _start_round() -> void:
	for block in blocks:
		if is_instance_valid(block):
			block.queue_free()
	blocks.clear()

	state = State.PLAYING
	score = 0
	survival_time = 0.0
	dodged = 0
	velocity_x = 0.0
	spawn_timer = SPAWN_FIRST
	last_column = -1
	hint_faded = false

	player.position = Vector2(stage_size.x * 0.5, floor_y - PLAYER_FEET_OFFSET)
	player.play("idle")
	hint_label.show()
	hint_label.modulate.a = 1.0
	overlay.hide()
	_update_hud()

func _process(delta: float) -> void:
	if state != State.PLAYING:
		return

	_update_input(delta)

	survival_time += delta
	if survival_time >= TIME_LIMIT:
		survival_time = TIME_LIMIT
		_update_hud()
		_end_round(true)
		return
	score = dodged + int(survival_time)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_block()
		spawn_timer = _next_interval()

	_update_blocks(delta)

	if survival_time > 6.0 and not hint_faded:
		hint_faded = true
		_fade_hint()

	_update_hud()

func _update_input(delta: float) -> void:
	# arrows or A/D; the raw key check keeps working if the input map changes
	var direction: float = Input.get_axis("ui_left", "ui_right")
	if is_zero_approx(direction):
		var go_left: bool = (Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
			or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		var go_right: bool = (Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
			or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
		if go_left:
			direction = -1.0
		elif go_right:
			direction = 1.0

	# no glide: releasing the key stops Blocky immediately
	velocity_x = direction * MOVE_SPEED
	player.position.x = clampf(player.position.x + velocity_x * delta,
		EDGE_MARGIN, stage_size.x - EDGE_MARGIN)

	# idle is one static frame, so it only animates while walking
	var wanted: StringName = &"idle"
	if direction < -0.01:
		wanted = &"walk_left"
	elif direction > 0.01:
		wanted = &"walk_right"
	if player.animation != wanted:
		player.play(wanted)

func _next_interval() -> float:
	var base: float = maxf(SPAWN_MIN, SPAWN_START - SPAWN_RAMP * survival_time)
	return maxf(0.22, base + randf_range(-SPAWN_JITTER, SPAWN_JITTER))

func _column_centre(column: int) -> float:
	return column_pitch * (float(column) + 0.5)

func _column_blocked(column: int) -> bool:
	var centre_x: float = _column_centre(column)
	for block in blocks:
		if not is_instance_valid(block):
			continue
		if absf(block.position.x - centre_x) < 1.0 and block.position.y < BLOCK_SIZE * SPAWN_CLEARANCE:
			return true
	return false

func _spawn_block() -> void:
	# random column and random speed, never a tidy row
	var column: int = randi() % COLUMN_COUNT
	if column == last_column:
		column = (column + 1 + randi() % (COLUMN_COUNT - 1)) % COLUMN_COUNT
	for _try in 6:
		if not _column_blocked(column):
			break
		column = randi() % COLUMN_COUNT
	last_column = column

	var speed: float = randf_range(FALL_SPEED_MIN, FALL_SPEED_MAX)
	speed += FALL_RAMP * survival_time + randf_range(-FALL_JITTER, FALL_JITTER)
	speed = clampf(speed, FALL_SPEED_MIN, FALL_SPEED_CAP)
	_make_block(column, speed)

func _make_block(column: int, fall_speed: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _pick_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * (BLOCK_SIZE / BLOCK_TEXTURE_SIZE)
	sprite.position = Vector2(_column_centre(column), -BLOCK_SIZE * 0.5)
	sprite.set_meta("fall_speed", fall_speed)
	sprite.set_meta("passed", false)
	entities.add_child(sprite)
	blocks.append(sprite)

func _pick_texture() -> Texture2D:
	match randi() % 3:
		0:
			return TEX_RED
		1:
			return TEX_GREEN
		_:
			return TEX_YELLOW

func _update_blocks(delta: float) -> void:
	var hit_box := Rect2(
		player.position.x - HIT_HALF_W,
		player.position.y - HIT_HALF_H,
		HIT_HALF_W * 2.0,
		HIT_HALF_H * 2.0)
	var alive: Array[Sprite2D] = []

	for block in blocks:
		if not is_instance_valid(block):
			continue
		block.position.y += float(block.get_meta("fall_speed")) * delta

		var block_box := Rect2(
			block.position.x - BLOCK_SIZE * 0.5,
			block.position.y - BLOCK_SIZE * 0.5,
			BLOCK_SIZE,
			BLOCK_SIZE)
		if block_box.intersects(hit_box):
			_end_round()
			return

		# scored once past the feet, but it keeps falling until it is out of sight
		if block_box.position.y > hit_box.end.y and not bool(block.get_meta("passed")):
			block.set_meta("passed", true)
			dodged += 1

		if block_box.position.y > stage_size.y:
			block.queue_free()
			continue
		alive.append(block)

	blocks = alive

func _end_round(won: bool = false) -> void:
	state = State.OVER
	player.pause()
	score = dodged + int(survival_time)
	best_score = maxi(best_score, score)

	GLOBAL.minigame_scores["dodge_score"] = score
	GLOBAL.minigame_scores["dodge_best_score"] = best_score
	GLOBAL.minigame_scores["dodge_survival_time"] = survival_time
	GLOBAL.minigame_scores["dodge_blocks_dodged"] = dodged
	GLOBAL.minigame_scores["dodge_passed"] = won

	title_label.text = "YOU MADE IT!" if won else "GAME OVER"
	result_label.text = "SCORE %d      BEST %d\nSURVIVED %.1fs  ·  %d BLOCKS DODGED" % [
		score, best_score, survival_time, dodged]
	overlay.show()
	_update_hud()

func _fade_hint() -> void:
	if not hint_label.visible:
		return
	var tween := create_tween()
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(hint_label.hide)

func _update_hud() -> void:
	score_label.text = "SCORE %d      TIME %.1fs" % [score, maxf(0.0, TIME_LIMIT - survival_time)]
	best_label.text = "BEST %d" % best_score

func _input(event: InputEvent) -> void:
	if state != State.OVER:
		return

	var retry: bool = false
	var advance: bool = false

	# mouse clicks belong to the two buttons, only the keys are handled here
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		retry = key.keycode == KEY_SPACE or key.physical_keycode == KEY_SPACE
		advance = key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER

	if retry:
		_start_round()
	elif advance:
		_next_game()
