extends Control

signal game_finished

@onready var manware: TextureRect = $CenterContainer/VBoxContainer/TextureRect
@onready var beat_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var status_label: Label = $VBoxContainer/status_label
@onready var attempt_label: Label = $VBoxContainer/attempt_label
@onready var mood_label: Label = $VBoxContainer/mood_label
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer

@export_dir var texture_folder_path: String = "res://assets/pat-manware/"
@export var bpm: float = 120.0

const HIT_WINDOW_MS: int = 180
const MAX_ATTEMPTS: int = 3
const WIN_MOOD: int = 6
const LOSE_MOOD: int = -5

const HITS_TO_IMPROVE_MOOD: int = 6
const MISSES_TO_DROP_MOOD: int = 3

# Hooke's Law Spring constants
const SPRING_STIFFNESS: float = 320.0
const SPRING_DAMPING: float = 15.0

var textures: Dictionary = {}
var mood: int = 0
var current_attempt: int = 1
var is_active: bool = false

var hit_counter: int = 0
var miss_counter: int = 0

var beat_interval_sec: float
var beat_interval_ms: int
var song_start_msec: int = 0

var last_pulsed_beat: int = -1
var last_evaluated_beat: int = 0
var beats_hit: Dictionary = {}

var scale_displacement: Vector2 = Vector2.ZERO
var scale_velocity: Vector2 = Vector2.ZERO

var bar_shake_tween: Tween
var bar_base_x: float = 0.0

func _ready() -> void:
	load_mood_textures()
	beat_interval_sec = 60.0 / bpm
	beat_interval_ms = int(beat_interval_sec * 1000.0)

	manware.pivot_offset = manware.custom_minimum_size / 2.0
	manware.gui_input.connect(_on_manware_gui_input)

	bar_base_x = beat_bar.position.x
	beat_bar.pivot_offset = beat_bar.size / 2.0

	start_attempt()

func load_mood_textures() -> void:
	var base_path = texture_folder_path.trim_suffix("/") + "/"

	textures[0] = load(base_path + "0.webp")
	textures[1] = load(base_path + "1.webp")
	textures[2] = load(base_path + "2.webp")
	textures[3] = load(base_path + "3.webp")
	textures[4] = load(base_path + "4.webp")
	textures[5] = load(base_path + "5.jpg")
	textures[6] = load(base_path + "6.jpg")

	for i in range(1, 6):
		textures[-i] = load(base_path + "-" + str(i) + ".webp")

func start_attempt() -> void:
	mood = 0
	hit_counter = 0
	miss_counter = 0
	is_active = true
	last_pulsed_beat = -1
	last_evaluated_beat = 0
	beats_hit.clear()
	manware.modulate = Color.WHITE

	update_display()
	song_start_msec = Time.get_ticks_msec()

	if music_player.stream:
		music_player.stop()
		music_player.play()

# Returns exact audio playback time synchronized with output latency
func get_audio_time_ms() -> float:
	if music_player and music_player.playing:
		var pos = music_player.get_playback_position() + AudioServer.get_time_since_last_mix()
		pos -= AudioServer.get_output_latency()
		return max(0.0, pos * 1000.0)
	return float(Time.get_ticks_msec() - song_start_msec)

func _process(delta: float) -> void:
	var spring_force = -SPRING_STIFFNESS * scale_displacement - SPRING_DAMPING * scale_velocity
	scale_velocity += spring_force * delta
	scale_displacement += scale_velocity * delta
	manware.scale = Vector2.ONE + scale_displacement

	if not is_active:
		return

	var current_time = get_audio_time_ms()

	# Progress bar fills from 0 to 100% targeting each beat
	var cycle_time = fposmod(current_time, float(beat_interval_ms))
	beat_bar.value = (cycle_time / float(beat_interval_ms)) * 100.0

	var current_beat = int(current_time / float(beat_interval_ms))

	# 1. Pulse Manware at 100% as each beat arrives
	if current_beat > last_pulsed_beat:
		if last_pulsed_beat >= 0:
			apply_spring_impulse(0.12)
		last_pulsed_beat = current_beat

	# 2. Check for missed beats after the hit window closes
	var beat_to_check = int((current_time - HIT_WINDOW_MS) / float(beat_interval_ms))
	if beat_to_check > last_evaluated_beat:
		if beat_to_check > 0 and not beats_hit.has(beat_to_check):
			register_mistake("Missed Beat!")
		last_evaluated_beat = beat_to_check

func apply_spring_impulse(intensity: float) -> void:
	scale_velocity += Vector2(intensity * 14.0, -intensity * 14.0)

func _on_manware_gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pet_manware()

func pet_manware() -> void:
	var current_time = get_audio_time_ms()
	# The beat closest to the current click
	var target_beat = int(round(current_time / float(beat_interval_ms)))
	var beat_target_time = float(target_beat * beat_interval_ms)
	var diff = abs(current_time - beat_target_time)

	if diff <= HIT_WINDOW_MS and not beats_hit.has(target_beat) and target_beat > 0:
		beats_hit[target_beat] = true
		hit_counter += 1
		apply_spring_impulse(0.38)

		if hit_counter >= HITS_TO_IMPROVE_MOOD:
			hit_counter = 0
			mood += 1
			status_label.text = "Mood Improved!"
			update_display()

			if mood >= WIN_MOOD:
				win_game()
				return
		else:
			status_label.text = "Purrfect! (%d/%d)" % [hit_counter, HITS_TO_IMPROVE_MOOD]
			update_display()
	else:
		register_mistake("Off Beat!")

func register_mistake(reason: String) -> void:
	miss_counter += 1
	scale_velocity = Vector2(-7.0, 10.0)
	shake_bar()

	if miss_counter >= MISSES_TO_DROP_MOOD:
		miss_counter = 0
		mood -= 1
		status_label.text = "%s Mood Dropped!" % reason
		update_display()

		if mood <= LOSE_MOOD:
			handle_loss()
			return
	else:
		status_label.text = "%s (%d/%d strikes)" % [reason, miss_counter, MISSES_TO_DROP_MOOD]
		update_display()

func shake_bar() -> void:
	if bar_shake_tween and bar_shake_tween.is_valid():
		bar_shake_tween.kill()

	beat_bar.position.x = bar_base_x
	beat_bar.rotation_degrees = 0.0

	bar_shake_tween = create_tween()
	bar_shake_tween.tween_property(beat_bar, "position:x", bar_base_x - 12.0, 0.03)
	bar_shake_tween.parallel().tween_property(beat_bar, "rotation_degrees", -4.0, 0.03)
	bar_shake_tween.tween_property(beat_bar, "position:x", bar_base_x + 12.0, 0.03)
	bar_shake_tween.parallel().tween_property(beat_bar, "rotation_degrees", 4.0, 0.03)
	bar_shake_tween.tween_property(beat_bar, "position:x", bar_base_x - 6.0, 0.03)
	bar_shake_tween.parallel().tween_property(beat_bar, "rotation_degrees", -2.0, 0.03)
	bar_shake_tween.tween_property(beat_bar, "position:x", bar_base_x + 6.0, 0.03)
	bar_shake_tween.parallel().tween_property(beat_bar, "rotation_degrees", 2.0, 0.03)
	bar_shake_tween.tween_property(beat_bar, "position:x", bar_base_x, 0.03)
	bar_shake_tween.parallel().tween_property(beat_bar, "rotation_degrees", 0.0, 0.03)

func update_display() -> void:
	mood = clampi(mood, LOSE_MOOD, WIN_MOOD)

	if textures.has(mood) and textures[mood] != null:
		manware.texture = textures[mood]

	attempt_label.text = "Attempt: %d / %d" % [current_attempt, MAX_ATTEMPTS]
	mood_label.text = "Mood: %d (+: %d/%d | -: %d/%d)" % [
		mood, hit_counter, HITS_TO_IMPROVE_MOOD, miss_counter, MISSES_TO_DROP_MOOD
	]

func handle_loss() -> void:
	is_active = false
	if music_player.playing:
		music_player.stop()

	status_label.text = "MANWARE EXPLODED!"

	var tw = create_tween()
	tw.tween_property(manware, "scale", Vector2(2.4, 2.4), 0.2)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(manware, "modulate", Color(5.0, 0.2, 0.2, 0.0), 0.25)
	await tw.finished

	if current_attempt < MAX_ATTEMPTS:
		current_attempt += 1
		await get_tree().create_timer(1.0).timeout
		start_attempt()
	else:
		GLOBAL.minigame_scores["rhythm_passed"] = false
		GLOBAL.minigame_scores["rhythm_win_attempt"] = 0
		GLOBAL.minigame_scores["rhythm_final_mood"] = mood
		await get_tree().create_timer(1.2).timeout
		game_finished.emit()

func win_game() -> void:
	is_active = false
	status_label.text = "Manware is completely satisfied!"

	GLOBAL.minigame_scores["rhythm_passed"] = true
	GLOBAL.minigame_scores["rhythm_win_attempt"] = current_attempt
	GLOBAL.minigame_scores["rhythm_final_mood"] = mood

	await get_tree().create_timer(1.5).timeout
	game_finished.emit()
