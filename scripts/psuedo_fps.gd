extends Control

signal game_finished

@onready var enemies_container: Node2D = $enemies
@onready var gun_pivot: Node2D = $gun_pivot
@onready var gun_sprite: AnimatedSprite2D = $gun_pivot/gun
@onready var crosshair: TextureRect = $crosshair
@onready var hud_timer: Label = $VBoxContainer/timer_label
@onready var hud_score: Label = $VBoxContainer/score_label
@onready var game_timer: Timer = $game_timer
@onready var spawn_timer: Timer = $enemy_spawn_timer

@export var enemy_scene: PackedScene = preload("res://scenes/mini_games/sub_scenes/fps_enemy.tscn")

const MAX_SIMULTANEOUS_ENEMIES: int = 3
const HORIZON_Y: float = 380.0
const MIN_SPAWN_X: float = 180.0
const MAX_SPAWN_X: float = 1020.0

const MAX_ROTATION_DEG: float = 12.0
const ROTATION_THRESHOLD: float = 0.35
const MAX_SHIFT_OFFSET: float = 50.0

var shots_fired: int = 0
var targets_hit: int = 0

var default_gun_pos: Vector2
var current_sway_pos: Vector2
var recoil_offset_y: float = 0.0
var can_shoot: bool = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	var viewport_size = get_viewport_rect().size
	default_gun_pos = Vector2(viewport_size.x, viewport_size.y)
	gun_pivot.position = default_gun_pos
	current_sway_pos = default_gun_pos

	game_timer.timeout.connect(_on_game_timer_timeout)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	game_timer.start(20.0)
	spawn_timer.start(1.2)
	spawn_enemy()

func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size
	crosshair.position = mouse_pos - (crosshair.size / 2.0)

	var aim_norm = clamp((mouse_pos.x - (viewport_size.x * 0.5)) / (viewport_size.x * 0.5), -1.0, 1.0)

	var target_tilt = deg_to_rad(aim_norm * MAX_ROTATION_DEG)
	gun_pivot.rotation = lerp_angle(gun_pivot.rotation, target_tilt, delta * 7.0)

	var shift_x = 0.0
	var abs_aim = abs(aim_norm)
	if abs_aim > ROTATION_THRESHOLD:
		var excess_ratio = (abs_aim - ROTATION_THRESHOLD) / (1.0 - ROTATION_THRESHOLD)
		shift_x = sign(aim_norm) * excess_ratio * MAX_SHIFT_OFFSET

	var target_pos = default_gun_pos + Vector2(shift_x, 0.0)
	current_sway_pos = current_sway_pos.lerp(target_pos, delta * 6.0)

	gun_pivot.position = current_sway_pos + Vector2(0.0, recoil_offset_y)

	hud_timer.text = "Time: %.1fs" % game_timer.time_left
	hud_score.text = "Hits: %d | Shots: %d" % [targets_hit, shots_fired]

func _input(event: InputEvent) -> void:
	if not can_shoot:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot(event.position)

func shoot(click_pos: Vector2) -> void:
	can_shoot = false
	shots_fired += 1
	gun_sprite.play("shoot")

	recoil_offset_y = 20.0
	var recoil_tween = create_tween()
	recoil_tween.tween_property(self, "recoil_offset_y", 0.0, 0.16) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = click_pos
	query.collide_with_areas = true
	var results = space_state.intersect_point(query)

	var hit_enemy = null
	var largest_scale = -1.0

	for r in results:
		var area = r.collider
		if area.has_method("hit") and area.scale.x > largest_scale:
			largest_scale = area.scale.x
			hit_enemy = area

	if hit_enemy:
		targets_hit += 1
		hit_enemy.hit()

	await gun_sprite.animation_finished
	if gun_sprite.sprite_frames.has_animation("idle"):
		gun_sprite.play("idle")
	can_shoot = true

func _on_spawn_timer_timeout() -> void:
	if enemies_container.get_child_count() < MAX_SIMULTANEOUS_ENEMIES:
		spawn_enemy()

func spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate()
	var spawn_x = randf_range(MIN_SPAWN_X, MAX_SPAWN_X)
	enemy.position = Vector2(spawn_x, HORIZON_Y)

	enemy.enemy_defeated.connect(func(): pass )
	enemy.enemy_escaped.connect(func(): pass )
	enemies_container.add_child(enemy)

func _on_game_timer_timeout() -> void:
	spawn_timer.stop()
	can_shoot = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var accuracy = 0.0
	if shots_fired > 0:
		accuracy = (float(targets_hit) / float(shots_fired)) * 100.0

	GLOBAL.minigame_scores["shooter_hits"] = targets_hit
	GLOBAL.minigame_scores["shooter_shots"] = shots_fired
	GLOBAL.minigame_scores["shooter_accuracy"] = accuracy

	await get_tree().create_timer(1.2).timeout
	game_finished.emit()
