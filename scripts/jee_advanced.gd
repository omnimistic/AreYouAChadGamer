extends Control

signal game_finished

const TIME_LIMIT := 300.0

const FONT_BOLD: FontFile = preload("res://assets/fonts/PixelOperator8-Bold.ttf")
const FONT_REGULAR: FontFile = preload("res://assets/fonts/PixelOperator8.ttf")

const OPTION_IDS: Array[String] = ["opt_a", "opt_b", "opt_c", "opt_d"]

const COLOR_TEXT := Color(0.95, 0.96, 1.0, 1.0)
const COLOR_CORRECT := Color(0.3137, 0.9059, 0.6588, 1.0)
const COLOR_INCORRECT := Color(1.0, 0.3647, 0.4471, 1.0)
const COLOR_DIMMED := Color(0.55, 0.6, 0.72, 1.0)
const COLOR_PANEL_BORDER := Color(0.3137, 0.4745, 0.7529, 1.0)

# Original question bank: single-correct, multiple-correct and numerical items.
const BANK: Dictionary = {
	"jee_p1": {
		"subject": "Physics",
		"type": "single",
		"prompt": "A particle moves along the x-axis with position x(t) = t^3 - 6t^2 + 9t + 2 (SI units). The particle is momentarily at rest at t = 1 s and t = 3 s. What is the total distance traveled between t = 0 and t = 4 s?",
		"options": {
			"opt_a": "10 m",
			"opt_b": "12 m",
			"opt_c": "14 m",
			"opt_d": "16 m"
		},
		"answer": "opt_b",
		"solution": "v(t) = 3(t-1)(t-3). At t=0: x=2. At t=1: x=6. At t=3: x=2. At t=4: x=6. Distance = |6-2| + |2-6| + |6-2| = 4 + 4 + 4 = 12 m."
	},
	"jee_p2": {
		"subject": "Physics",
		"type": "multiple",
		"prompt": "A particle is attached to two identical springs of constant k and natural length L0, placed on opposite sides along the same line, and constrained to move on a smooth horizontal table. x is the displacement from equilibrium along that line. Which statements are correct?",
		"options": {
			"opt_a": "For small x the restoring force is approximately -2kx.",
			"opt_b": "The motion is simple harmonic for all x.",
			"opt_c": "The period depends on the amplitude for small oscillations.",
			"opt_d": "If the table is inclined along the line, the equilibrium shifts but small oscillations around it remain SHM."
		},
		"answer": ["opt_a", "opt_d"],
		"solution": "Each spring gives -kx for small x, total -2kx (A correct). For large x a spring can go slack, so not SHM for all x (B wrong). SHM period is independent of amplitude (C wrong). On an incline, gravity shifts equilibrium but the linearized force around the new equilibrium is still -2kx' (D correct)."
	},
	"jee_p3": {
		"subject": "Physics",
		"type": "numerical",
		"prompt": "A 2 kg mass hangs freely and a 3 kg mass rests on a smooth horizontal table; they are connected by a light inextensible string over a smooth pulley. The system is released from rest. Find the acceleration in m/s^2, rounded to two decimals.",
		"options": {
			"opt_a": "2.94",
			"opt_b": "4.90",
			"opt_c": "1.96",
			"opt_d": "3.92"
		},
		"answer": "opt_d",
		"solution": "a = (2g)/(2+3) = 19.6/5 = 3.92 m/s^2. The correct option is 3.92."
	},
	"jee_c1": {
		"subject": "Chemistry",
		"type": "single",
		"prompt": "In the molecule XeF4, the lone pairs on xenon occupy which positions according to VSEPR theory?",
		"options": {
			"opt_a": "Axial positions of a trigonal bipyramid.",
			"opt_b": "Equatorial positions, giving a see-saw shape.",
			"opt_c": "Two axial and two equatorial positions in an octahedron, giving square planar.",
			"opt_d": "Two opposite axial positions of an octahedron, giving square planar."
		},
		"answer": "opt_d",
		"solution": "XeF4: Xe has 8 valence electrons, 4 used in Xe-F bonds, leaving 4 electrons = 2 lone pairs. Steric number 6 (octahedral electron geometry). Lone pairs occupy opposite axial positions to minimize repulsion, leaving the four F atoms in a square plane: square planar (D correct)."
	},
	"jee_c2": {
		"subject": "Chemistry",
		"type": "multiple",
		"prompt": "Consider the Diels-Alder reaction between 1,3-butadiene and ethene to form cyclohexene. Which statements are correct?",
		"options": {
			"opt_a": "The reaction is stereospecific with respect to the dienophile geometry.",
			"opt_b": "The reaction proceeds through a cyclic concerted transition state.",
			"opt_c": "The diene must adopt an s-cis conformation to react.",
			"opt_d": "The reaction is a photochemical [2+2] cycloaddition."
		},
		"answer": ["opt_a", "opt_b", "opt_c"],
		"solution": "Diels-Alder is a concerted [4+2] cycloaddition with a cyclic transition state (B correct). It is stereospecific: the dienophile's stereochemistry is retained in the adduct (A correct). The diene must be s-cis, not s-trans, to react (C correct). It is not a photochemical [2+2] reaction (D wrong)."
	},
	"jee_c3": {
		"subject": "Chemistry",
		"type": "numerical",
		"prompt": "A 0.500 mol sample of an ideal gas is compressed isothermally at 300 K from an initial volume of 12.0 L to a final volume of 6.0 L. Calculate the work done ON the gas in kJ. Use R = 8.314 J/mol-K. Round the final answer to two decimals.",
		"options": {
			"opt_a": "0.86",
			"opt_b": "-0.86",
			"opt_c": "8.64",
			"opt_d": "-8.64"
		},
		"answer": "opt_a",
		"solution": "W_on = -nRT ln(Vf/Vi) = -0.5*8.314*300*ln(6/12) = -1247.1*ln(0.5) = 864.2 J = 0.86 kJ. The correct option is 0.86 kJ."
	},
	"jee_m1": {
		"subject": "Mathematics",
		"type": "single",
		"prompt": "Let f(x) = x^4 - 4x^3 + 6x^2 - 4x + 2. The function has exactly one real local minimum. Find its x-coordinate.",
		"options": {
			"opt_a": "0",
			"opt_b": "1",
			"opt_c": "2",
			"opt_d": "3"
		},
		"answer": "opt_b",
		"solution": "f'(x) = 4(x-1)^3. Critical point at x=1. Sign of f': negative before 1, positive after 1, so x=1 is a local minimum. x-coordinate = 1."
	},
	"jee_m2": {
		"subject": "Mathematics",
		"type": "single",
		"prompt": "Which of the following integrals is equal to pi/2?",
		"options": {
			"opt_a": "Integral from 0 to pi of sin^2(x) dx.",
			"opt_b": "Integral from 0 to pi of sin(x) dx.",
			"opt_c": "Integral from 0 to pi/2 of sin^2(x) dx.",
			"opt_d": "Integral from 0 to pi of sin(x) cos(x) dx."
		},
		"answer": "opt_a",
		"solution": "Integral_0^pi sin^2(x) dx = pi/2 (A correct). Integral_0^pi sin(x) dx = 2 (B wrong). Integral_0^(pi/2) sin^2(x) dx = pi/4 (C wrong). Integral_0^pi sin(x)cos(x) dx = 0 (D wrong). The correct choice is A."
	},
	"jee_m3": {
		"subject": "Mathematics",
		"type": "numerical",
		"prompt": "If the sum of the first n positive integers is 5050, find the value of n.",
		"options": {
			"opt_a": "99",
			"opt_b": "100",
			"opt_c": "101",
			"opt_d": "102"
		},
		"answer": "opt_b",
		"solution": "n(n+1)/2 = 5050 => n(n+1) = 10100 => n^2 + n - 10100 = 0 => discriminant = 1 + 40400 = 40401, sqrt = 201. n = (-1 + 201)/2 = 100. So n = 100."
	},
	"jee_p4": {
		"subject": "Physics",
		"type": "single",
		"prompt": "A uniform rod of length L and mass M is pivoted at one end and held horizontally. It is released from rest. What is the initial angular acceleration of the rod? (Take g as the acceleration due to gravity.)",
		"options": {
			"opt_a": "3g / (2L)",
			"opt_b": "2g / (3L)",
			"opt_c": "g / L",
			"opt_d": "g / (2L)"
		},
		"answer": "opt_a",
		"solution": "Torque about the pivot = Mg * (L/2). Moment of inertia about the end = ML^2/3. Angular acceleration = torque / I = (MgL/2) / (ML^2/3) = 3g/(2L)."
	},
	"jee_c4": {
		"subject": "Chemistry",
		"type": "single",
		"prompt": "In the titration of a strong acid with a strong base, the pH at the equivalence point is 7.0 at 25 C. Which statement best explains this?",
		"options": {
			"opt_a": "The salt formed does not hydrolyze.",
			"opt_b": "The concentration of hydrogen ions equals the concentration of hydroxide ions from water auto-ionization.",
			"opt_c": "Both the acid and base are completely neutralized, and the resulting solution contains only water and a neutral salt.",
			"opt_d": "The base is fully ionized, so the pH is fixed at 7.0."
		},
		"answer": "opt_c",
		"solution": "At the equivalence point of a strong acid/strong base titration, moles of H+ equal moles of OH-. The products are water and a salt with ions that do not hydrolyze, so neither ion is acidic or basic. The pH is determined by water alone, giving pH = 7.0 at 25 C."
	}
}

@onready var background: ColorRect = $background
@onready var container: PanelContainer = $container
@onready var timer_label: Label = $container/main_layout/info_bar/timer_label
@onready var progress_label: Label = $container/main_layout/info_bar/progress_label
@onready var score_label: Label = $container/main_layout/info_bar/score_label
@onready var restart_btn: Button = $container/main_layout/restart_btn
@onready var question_panel: PanelContainer = $container/main_layout/question_scroll/question_panel
@onready var subject_label: Label = $container/main_layout/question_scroll/question_panel/question_content/question_header/question_subject
@onready var type_label: Label = $container/main_layout/question_scroll/question_panel/question_content/question_header/question_type
@onready var prompt_text: Label = $container/main_layout/question_scroll/question_panel/question_content/question_prompt
@onready var options_panel: VBoxContainer = $container/main_layout/question_scroll/question_panel/question_content/options_panel
@onready var question_scroll: ScrollContainer = $container/main_layout/question_scroll
@onready var submit_btn: Button = $container/main_layout/actions_row/submit_btn
@onready var next_btn: Button = $container/main_layout/actions_row/next_btn
@onready var clear_btn: Button = $container/main_layout/actions_row/clear_btn
@onready var feedback_label: Label = $container/main_layout/actions_row/feedback_label
@onready var solution_box: Label = $container/main_layout/question_scroll/question_panel/question_content/solution_box
@onready var finish_panel: PanelContainer = $finish_panel
@onready var finish_score: Label = $finish_panel/finish_layout/stats_row/score_label
@onready var finish_correct: Label = $finish_panel/finish_layout/stats_row/correct_label
@onready var finish_incorrect: Label = $finish_panel/finish_layout/stats_row/incorrect_label
@onready var finish_unanswered: Label = $finish_panel/finish_layout/stats_row/unanswered_label
@onready var finish_time: Label = $finish_panel/finish_layout/stats_row/time_label
@onready var finish_restart_btn: Button = $finish_panel/finish_layout/finish_buttons/restart_btn
@onready var finish_next_btn: Button = $finish_panel/finish_layout/finish_buttons/next_btn

var _keys: Array = []
var _results: Dictionary = {}
var _current_index := 0
var _start_ticks := 0
var _round_active := false
var _button_style: StyleBoxFlat
var _button_style_hover: StyleBoxFlat

func _ready() -> void:
	_button_style = _make_button_style(Color(0.1294, 0.1490, 0.2431, 1.0))
	_button_style_hover = _make_button_style(Color(0.2157, 0.2510, 0.4000, 1.0))
	prompt_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	solution_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sync_text_width()
	resized.connect(_sync_text_width)
	submit_btn.pressed.connect(_on_submit_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	restart_btn.pressed.connect(_start_round)
	finish_restart_btn.pressed.connect(_start_round)
	finish_next_btn.pressed.connect(_on_finish_next_pressed)
	_start_round()

func _process(_delta: float) -> void:
	if not _round_active:
		return
	var elapsed := (Time.get_ticks_msec() - _start_ticks) / 1000.0
	timer_label.text = "TIME %.1fs" % maxf(0.0, TIME_LIMIT - elapsed)
	if elapsed >= TIME_LIMIT:
		_finish_round()

func _start_round() -> void:
	_keys = BANK.keys()
	_results.clear()
	_current_index = 0
	_start_ticks = Time.get_ticks_msec()
	_round_active = true
	finish_panel.visible = false
	container.visible = true
	_show_question()

func _show_question() -> void:
	if _current_index >= _keys.size():
		_finish_round()
		return
	var key := str(_keys[_current_index])
	var q: Dictionary = BANK[key]
	subject_label.text = str(q["subject"]).to_upper()
	type_label.text = _type_text(str(q["type"]))
	prompt_text.text = str(q["prompt"])
	_build_options(q, key)
	submit_btn.disabled = true
	next_btn.disabled = true
	clear_btn.disabled = false
	feedback_label.visible = false
	feedback_label.text = ""
	solution_box.visible = false
	solution_box.text = ""
	progress_label.text = "Q %d / %d" % [_current_index + 1, _keys.size()]
	score_label.text = "CORRECT %d" % _correct_so_far()
	question_scroll.scroll_vertical = 0

# An autowrapping Label has no width until something gives it one, and inside a
# ScrollContainer that means the wrap never happens: the label reports a single
# enormous line, the panel grows to match, and the whole thing runs off screen.
# Tying the wrap width to the real control width keeps it honest at any resolution.
func _sync_text_width() -> void:
	var wrap_width := maxf(420.0, size.x - 200.0)
	prompt_text.custom_minimum_size = Vector2(wrap_width, 0.0)
	solution_box.custom_minimum_size = Vector2(wrap_width, 0.0)

# Worked solutions are longer than the visible strip, so bring them into view
# instead of leaving the reader to discover that the box scrolls.
func _scroll_to_solution() -> void:
	await get_tree().process_frame
	if not is_instance_valid(question_scroll) or solution_box == null:
		return
	question_scroll.scroll_vertical = int(question_scroll.get_v_scroll_bar().max_value)

func _type_text(type_name: String) -> String:
	match type_name:
		"multiple":
			return "MULTIPLE CHOICE"
		"numerical":
			return "NUMERICAL"
		_:
			return "SINGLE CHOICE"

func _build_options(q: Dictionary, key: String) -> void:
	for child in options_panel.get_children():
		options_panel.remove_child(child)
		child.queue_free()
	var opt_map: Dictionary = q["options"]
	for opt_id in OPTION_IDS:
		if not opt_map.has(opt_id):
			continue
		var btn := Button.new()
		btn.text = "%s. %s" % [opt_id.substr(4).to_upper(), str(opt_map[opt_id])]
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		# Option text can be a whole sentence. Without wrapping, the button's minimum
		# width is its single-line text width (up to ~1300px), which propagates up
		# through the containers and makes the panel wider than the window.
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 38.0)
		btn.add_theme_font_override("font", FONT_REGULAR)
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", COLOR_TEXT)
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
		btn.add_theme_stylebox_override("normal", _button_style)
		btn.add_theme_stylebox_override("hover", _button_style_hover)
		btn.add_theme_stylebox_override("pressed", _button_style_hover)
		btn.add_theme_stylebox_override("disabled", _button_style)
		btn.add_theme_color_override("font_disabled_color", COLOR_TEXT)
		btn.set_meta("opt_id", opt_id)
		btn.toggled.connect(_on_option_toggled.bind(opt_id, key))
		options_panel.add_child(btn)

func _on_option_toggled(toggled_on: bool, opt_id: String, key: String) -> void:
	if not _round_active or _results.has(key):
		return
	var q: Dictionary = BANK[key]
	var multi := str(q["type"]) == "multiple"
	if toggled_on and not multi:
		for child in options_panel.get_children():
			if child is Button:
				var other := child as Button
				if other.button_pressed and str(other.get_meta("opt_id", "")) != opt_id:
					other.set_pressed_no_signal(false)
	_refresh_submit()

func _refresh_submit() -> void:
	for child in options_panel.get_children():
		if child is Button and (child as Button).button_pressed:
			submit_btn.disabled = false
			return
	submit_btn.disabled = true

func _selected_options() -> Array[String]:
	var selected: Array[String] = []
	for child in options_panel.get_children():
		if child is Button and (child as Button).button_pressed:
			selected.append(str((child as Button).get_meta("opt_id", "")))
	selected.sort()
	return selected

func _on_submit_pressed() -> void:
	if not _round_active:
		return
	var key := str(_keys[_current_index])
	if _results.has(key):
		return
	var selected := _selected_options()
	if selected.is_empty():
		return
	var correct := _is_correct(key, selected)
	_results[key] = correct

	if correct:
		feedback_label.text = "CORRECT"
		feedback_label.add_theme_color_override("font_color", COLOR_CORRECT)
	else:
		feedback_label.text = "INCORRECT"
		feedback_label.add_theme_color_override("font_color", COLOR_INCORRECT)
	feedback_label.visible = true
	var q: Dictionary = BANK[key]
	solution_box.text = "Solution: %s" % str(q["solution"])
	solution_box.visible = true
	_scroll_to_solution()

	for child in options_panel.get_children():
		if child is Button:
			var btn := child as Button
			btn.disabled = true
			if not btn.button_pressed:
				btn.modulate = COLOR_DIMMED
	submit_btn.disabled = true
	clear_btn.disabled = true
	next_btn.disabled = false
	score_label.text = "CORRECT %d" % _correct_so_far()

func _on_next_pressed() -> void:
	if not _round_active:
		return
	var key := str(_keys[_current_index])
	if not _results.has(key):
		return
	_current_index += 1
	_show_question()

func _on_clear_pressed() -> void:
	if not _round_active:
		return
	var key := str(_keys[_current_index])
	if _results.has(key):
		return
	for child in options_panel.get_children():
		if child is Button:
			(child as Button).set_pressed_no_signal(false)
	submit_btn.disabled = true

func _correct_so_far() -> int:
	var count := 0
	for key in _results:
		if bool(_results[key]):
			count += 1
	return count

func _is_correct(key: String, selected: Array[String]) -> bool:
	var q: Dictionary = BANK[key]
	var answer: Variant = q["answer"]
	if answer is Array:
		var wanted: Array[String] = []
		for item in (answer as Array):
			wanted.append(str(item))
		wanted.sort()
		return wanted == selected
	return selected.size() == 1 and selected[0] == str(answer)

func _finish_round() -> void:
	if not _round_active:
		return
	_round_active = false
	var elapsed := (Time.get_ticks_msec() - _start_ticks) / 1000.0
	var correct := 0
	var incorrect := 0
	var unanswered := 0
	for entry in _keys:
		var key := str(entry)
		if not _results.has(key):
			unanswered += 1
		elif bool(_results[key]):
			correct += 1
		else:
			incorrect += 1
	var total: int = _keys.size()
	var accuracy := 0.0
	if total > 0:
		accuracy = float(correct) / float(total)
	var score := maxf(100.0 * accuracy - 10.0 * float(incorrect), 0.0)

	var scores: Dictionary = GLOBAL.minigame_scores
	scores["jee_correct"] = correct
	scores["jee_incorrect"] = incorrect
	scores["jee_unanswered"] = unanswered
	scores["jee_accuracy"] = accuracy
	scores["jee_completion_time"] = elapsed
	scores["jee_score"] = score

	finish_score.text = "SCORE %.0f" % score
	finish_correct.text = "CORRECT: %d" % correct
	finish_incorrect.text = "INCORRECT: %d" % incorrect
	finish_unanswered.text = "UNANSWERED: %d" % unanswered
	finish_time.text = "TIME %.1fs" % elapsed
	finish_panel.visible = true
	container.visible = false

func _on_finish_next_pressed() -> void:
	if finish_panel.visible:
		game_finished.emit()

func _make_button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = COLOR_PANEL_BORDER
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
