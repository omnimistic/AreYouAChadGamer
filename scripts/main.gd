extends Control

@onready var landing_page = $CenterContainer
@onready var game_container = $game_container
@onready var begin_btn = $CenterContainer/VBoxContainer/VBoxContainer/Button
@onready var follow_btn = $CenterContainer/VBoxContainer/VBoxContainer/Button2
@onready var transition_rect = $CanvasLayer/ColorRect

var transition_mat: ShaderMaterial

func _ready() -> void:
	transition_mat = transition_rect.material as ShaderMaterial
	transition_mat.set_shader_parameter("circle_size", 0.0)

	begin_btn.pressed.connect(_on_begin_pressed)
	follow_btn.pressed.connect(_on_follow_pressed)

func _on_follow_pressed() -> void:
	OS.shell_open("https://github.com/omnimistic/")

func _on_begin_pressed() -> void:
	begin_btn.disabled = true
	transition_to_scene("res://scenes/mini_games/reaction_time.tscn")

func transition_to_scene(scene_path: String) -> void:
	# 1. Expand circle from bottom-left to cover screen
	var tween_in = create_tween()
	tween_in.tween_property(transition_mat, "shader_parameter/circle_size", 2.8, 0.45)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	await tween_in.finished

	# 2. Clear old scene/UI
	landing_page.hide()
	for child in game_container.get_children():
		child.queue_free()

	# 3. Instantiate incoming scene
	var new_scene = load(scene_path).instantiate()
	game_container.add_child(new_scene)


	if new_scene.has_signal("game_finished"):
		if scene_path.ends_with("reaction_time.tscn"):
			new_scene.game_finished.connect(func(): transition_to_scene("res://scenes/mini_games/snake.tscn"))
		elif scene_path.ends_with("snake.tscn"):
			pass
			# Next minigame
			#new_scene.game_finished.connect(func(): transition_to_scene())

	# 4. Shrink circle back to bottom-left to reveal the new game
	var tween_out = create_tween()
	tween_out.tween_property(transition_mat, "shader_parameter/circle_size", 0.0, 0.45)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
