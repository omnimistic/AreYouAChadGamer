extends Area2D

signal enemy_defeated
signal enemy_escaped

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

@export var approach_speed: float = 0.08
@export var min_scale: float = 0.35
@export var max_scale: float = 2.2

enum State { SPAWNING, APPROACHING, DYING }
var current_state: State = State.SPAWNING
var current_scale_factor: float = 0.35

func _ready() -> void:
	current_scale_factor = min_scale
	scale = Vector2.ONE * current_scale_factor
	input_pickable = true
	spawn_sequence()

func spawn_sequence() -> void:
	current_state = State.SPAWNING
	# Play death animation backward to rise from the floor
	sprite.play_backwards("death")
	await sprite.animation_finished
	
	current_state = State.APPROACHING
	sprite.play("walk")

func _process(delta: float) -> void:
	if current_state == State.APPROACHING:
		current_scale_factor += approach_speed * delta
		scale = Vector2.ONE * current_scale_factor

		# Enemy reached the player screen
		if current_scale_factor >= max_scale:
			current_state = State.DYING
			enemy_escaped.emit()
			queue_free()

func hit() -> void:
	if current_state != State.APPROACHING:
		return

	current_state = State.DYING
	collider.set_deferred("disabled", true)
	enemy_defeated.emit()

	# Ensure death animation does not loop
	if sprite.sprite_frames and sprite.sprite_frames.get_animation_loop("death"):
		sprite.sprite_frames.set_animation_loop("death", false)

	sprite.play("death")
	await sprite.animation_finished
	queue_free()
