extends Control

signal game_finished

@onready var background_rays: ColorRect = $ColorRect
@onready var hero: TextureRect = $CenterContainer/hero
@onready var type_title: Label = $VBoxContainer/reveal_card/MarginContainer/VBoxContainer/type_title
@onready var type_subtitle: Label = $VBoxContainer/reveal_card/MarginContainer/VBoxContainer/type_subtitle
@onready var type_passage: Label = $VBoxContainer/reveal_card/MarginContainer/VBoxContainer/type_passage
@onready var restart_btn: Button = $VBoxContainer/reveal_card/MarginContainer/VBoxContainer/Button

# Archetype database
const ARCHETYPES: Dictionary = {
	"chud_gamer": {
		"title": "CHUD GAMER",
		"subtitle": "// 0% PORE HYGIENE • UNREASONABLY SWEATY • ASCENDED DEGENERATE",
		"passage": "please touch some grass bro",
		"image_path": "res://assets/archetypes/chud.png",
		"core_color": Color("#FFD700"),
		"outer_color": Color("#00F5A0")
	},
	"grass_addict": {
		"title": "GRASS ADDICT",
		"subtitle": "// OVERDOSED ON OXYGEN • TERMINALLY UNPLUGGED • KEYBOARD ALLERGIC",
		"passage": "please stop touching grass so much",
		"image_path": "res://assets/archetypes/grass.webp",
		"core_color": Color("#22C55E"),
		"outer_color": Color("#06B6D4")
	},
	"nerd_gamer": {
		"title": "NERD GAMER",
		"subtitle": "// 400 IQ THEORYCRAFTER • ZERO APM EXECUTION • ACADEMIC MENACE",
		"passage": "my homegirls told me that baddies are into nerds. is that true?",
		"image_path": "res://assets/archetypes/nerd.png",
		"core_color": Color("#00F2FE"),
		"outer_color": Color("#8B5CF6")
	},
	"gooner_gamer": {
		"title": "GOONER GAMER",
		"subtitle": "// GOONER • BIG DREAMS SMALL DIH • WHAT'S GRASS?",
		"passage": "You can't shoot, you can't dodge, and you definitely failed math, but you sure know how to stroke the cat.",
		"image_path": "res://assets/archetypes/goon.png",
		"core_color": Color("#FF2A6D"),
		"outer_color": Color("#F472B6")
	},
	"action_gamer": {
		"title": "ACTION GAMER",
		"subtitle": "// ALL HANDS NO BRAIN • WASD DEMON • THINKING IS FATAL",
		"passage": "Head empty, crosshairs steady, reflexes pumped. Who needs thinking when you have pure adrenaline and WASD muscle memory?",
		"image_path": "res://assets/archetypes/action.png",
		"core_color": Color("#FF5722"),
		"outer_color": Color("#EF4444")
	}
}

var hover_time: float = 0.0
const HOVER_SPEED: float = 2.4
const SCALE_AMPLITUDE: float = 0.08
const BOB_AMPLITUDE: float = 12.0

func _ready() -> void:
	restart_btn.pressed.connect(_on_restart_pressed)
	
	hero.resized.connect(_update_hero_pivot)
	_update_hero_pivot()
	
	evaluate_scores()

func _update_hero_pivot() -> void:
	hero.pivot_offset = hero.size / 2.0

func _process(delta: float) -> void:
	hover_time += delta * HOVER_SPEED
	
	var scale_factor = 1.0 + sin(hover_time) * SCALE_AMPLITUDE
	hero.scale = Vector2.ONE * scale_factor
	hero.position.y = sin(hover_time * 0.8) * BOB_AMPLITUDE

func evaluate_scores() -> void:
	var s = GLOBAL.minigame_scores

	# Mechanical Score (0 - 100)
	var shoot_acc = s.get("shooter_accuracy", 0.0)
	var dodge_time = s.get("dodge_survival_time", 0.0)
	var reaction = s.get("reaction_best", 400.0)
	
	var reaction_norm = clampf((500.0 - reaction) / 280.0, 0.0, 1.0) * 30.0 if reaction > 0.0 else 0.0
	var shoot_norm = (shoot_acc / 100.0) * 35.0
	var dodge_norm = clampf(dodge_time / 18.0, 0.0, 1.0) * 35.0
	var action_total = reaction_norm + shoot_norm + dodge_norm

	# Cognitive Score (0 - 100)
	var jee_acc = s.get("jee_accuracy", 0.0)
	var pred_score = s.get("predict_score", 0.0)
	var snake_pts = s.get("snake_high_score", 0)
	
	var jee_norm = (jee_acc / 100.0) * 45.0
	var pred_norm = clampf(pred_score / 8.0, 0.0, 1.0) * 35.0
	var snake_norm = clampf(float(snake_pts) / 6.0, 0.0, 1.0) * 20.0
	var brain_total = jee_norm + pred_norm + snake_norm

	# Petting Score (0 - 100)
	var mood = s.get("rhythm_final_mood", 0)
	var click_total = clampf(float(mood + 5) / 11.0, 0.0, 1.0) * 100.0
	if s.get("rhythm_passed", false):
		click_total = max(click_total, 85.0)

	# Classification thresholds
	var is_action_good: bool = action_total >= 52.0
	var is_action_bad: bool = action_total < 38.0
	var is_brain_good: bool = brain_total >= 50.0
	var is_brain_bad: bool = brain_total < 38.0
	var is_click_good: bool = click_total >= 65.0
	var is_click_bad: bool = click_total < 40.0

	var key = "grass_addict"

	# Archetype decisions
	if is_action_good and is_brain_good and is_click_good:
		key = "chud_gamer"
	elif is_action_bad and is_brain_bad and is_click_bad:
		key = "grass_addict"
	elif is_click_good and is_action_bad and is_brain_bad:
		key = "gooner_gamer"
	elif is_action_good and is_brain_bad:
		key = "action_gamer"
	elif is_brain_good and is_action_bad:
		key = "nerd_gamer"
	else:
		# Fallback resolution based on best performer
		if click_total > action_total and click_total > brain_total and click_total >= 50.0:
			key = "gooner_gamer"
		elif action_total >= brain_total:
			key = "action_gamer" if action_total >= 40.0 else "grass_addict"
		else:
			key = "nerd_gamer" if brain_total >= 40.0 else "grass_addict"

	apply_archetype(key)

func apply_archetype(key: String) -> void:
	var data = ARCHETYPES[key]

	type_title.text = data["title"]
	type_subtitle.text = data["subtitle"]
	type_passage.text = data["passage"]

	type_title.add_theme_color_override("font_color", data["core_color"])
	type_subtitle.add_theme_color_override("font_color", data["outer_color"])

	if ResourceLoader.exists(data["image_path"]):
		hero.texture = load(data["image_path"])
	
	if background_rays.material is ShaderMaterial:
		var mat = background_rays.material as ShaderMaterial
		mat.set_shader_parameter("ray_color_core", data["core_color"])
		mat.set_shader_parameter("ray_color_outer", data["outer_color"])
	
	hero.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(hero, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(hero, "scale", Vector2.ONE * 1.2, 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(hero, "scale", Vector2.ONE, 0.2)

func _on_restart_pressed() -> void:
	for k in GLOBAL.minigame_scores.keys():
		if typeof(GLOBAL.minigame_scores[k]) == TYPE_BOOL:
			GLOBAL.minigame_scores[k] = false
		elif typeof(GLOBAL.minigame_scores[k]) == TYPE_FLOAT:
			GLOBAL.minigame_scores[k] = 0.0
		elif typeof(GLOBAL.minigame_scores[k]) == TYPE_INT:
			GLOBAL.minigame_scores[k] = 0

	game_finished.emit()
