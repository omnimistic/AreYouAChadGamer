extends Control

signal game_finished

## "Predict" = predict the next element of a visual sequence.
##
## A row of shape tiles forms a repeating rule (period 2 or 3, doubled pairs, a
## rotating shape, or a cycling colour) and the last tile is hidden behind a "?".
## Four candidate tiles are offered; exactly one continues the rule.
##
## The shapes are painted in code rather than typed as glyphs on purpose: the pixel
## font has no circle/star characters, and drawing them keeps the board readable at
## any tile size.

const TIME_LIMIT := 120.0
const CORRECT_POINTS := 10.0
const WRONG_PENALTY := 5.0
const ROUND_COUNT := 12
const REVEAL_DELAY := 0.9
const SEQUENCE_SHOWN := 5      # visible tiles before the hidden one

const TILE_SIZE := 88.0
const OPTION_SIZE := 104.0

const FONT_BOLD: FontFile = preload("res://assets/fonts/PixelOperator8-Bold.ttf")

const COLOR_DIM := Color(0.5803922, 0.6392157, 0.72156864, 1.0)
const COLOR_CORRECT := Color(0.3137255, 0.90588236, 0.65882355, 1.0)
const COLOR_WRONG := Color(1.0, 0.3647059, 0.44705883, 1.0)
const COLOR_TILE_BG := Color(0.11764706, 0.12941177, 0.21176471, 1.0)
const COLOR_TILE_BORDER := Color(0.3137255, 0.4745098, 0.7529412, 1.0)

const SHAPE_COLORS := [
	Color(0.3529412, 0.61960787, 0.9529412, 1.0),   # blue
	Color(1.0, 0.72156864, 0.3019608, 1.0),         # amber
	Color(0.8980392, 0.41568628, 1.0, 1.0),         # magenta
	Color(0.3137255, 0.90588236, 0.65882355, 1.0),  # green
	Color(1.0, 0.54901963, 0.47058824, 1.0),        # coral
	Color(0.7058824, 0.75686276, 1.0, 1.0),         # periwinkle
]

## One drawn shape. Doubles as a clickable answer tile when `clickable` is set.
class ShapeTile extends Control:
	signal chosen(index: int)

	const SHAPE_CIRCLE := 0
	const SHAPE_SQUARE := 1
	const SHAPE_TRIANGLE := 2
	const SHAPE_DIAMOND := 3
	const SHAPE_STAR := 4
	const SHAPE_HEXAGON := 5

	const VOCABULARY := [SHAPE_CIRCLE, SHAPE_SQUARE, SHAPE_TRIANGLE, SHAPE_DIAMOND, SHAPE_STAR, SHAPE_HEXAGON]

	const TILE_BG := Color(0.11764706, 0.12941177, 0.21176471, 1.0)
	const TILE_BORDER := Color(0.3137255, 0.4745098, 0.7529412, 1.0)
	const DIM_GLYPH := Color(0.5803922, 0.6392157, 0.72156864, 1.0)

	var shape_id := SHAPE_CIRCLE
	var tint := Color(1, 1, 1, 1)
	var angle := 0.0            # degrees, only meaningful for the pointed shapes
	var unknown := false        # draws the "?" placeholder
	var clickable := false
	var option_index := -1
	var ring := Color(0, 0, 0, 0)
	var _hovered := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE
		if clickable:
			mouse_entered.connect(_on_hover_in)
			mouse_exited.connect(_on_hover_out)

	func _on_hover_in() -> void:
		_hovered = true
		queue_redraw()

	func _on_hover_out() -> void:
		_hovered = false
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if not clickable:
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			chosen.emit(option_index)

	func _draw() -> void:
		var centre := size * 0.5
		var inner := Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0))

		if unknown:
			draw_rect(inner, TILE_BG, true)
			draw_rect(inner, TILE_BORDER, false, 2.0)
			var font_size := int(minf(size.x, size.y) * 0.56)
			var text := "?"
			var width := FONT_BOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(FONT_BOLD, Vector2(centre.x - width * 0.5, centre.y + font_size * 0.36),
				text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, DIM_GLYPH)
			return

		if clickable:
			var bg := TILE_BG.lightened(0.14) if _hovered else TILE_BG
			draw_rect(inner, bg, true)
			draw_rect(inner, TILE_BORDER, false, 2.0)
		else:
			# a faint plate keeps the sequence reading as a row of tiles
			draw_rect(inner, Color(TILE_BG.r, TILE_BG.g, TILE_BG.b, 0.55), true)

		var radius := minf(size.x, size.y) * 0.31
		_draw_shape(centre, radius)

		if ring.a > 0.0:
			draw_rect(inner, ring, false, 3.0)

	func _draw_shape(centre: Vector2, radius: float) -> void:
		match shape_id:
			SHAPE_SQUARE:
				var half := radius * 0.86
				draw_rect(Rect2(centre - Vector2(half, half), Vector2(half, half) * 2.0), tint, true)
			SHAPE_CIRCLE:
				draw_circle(centre, radius, tint)
			SHAPE_TRIANGLE:
				draw_colored_polygon(_polygon(3, centre, radius, -90.0 + angle), tint)
			SHAPE_DIAMOND:
				draw_colored_polygon(_polygon(4, centre, radius, angle), tint)
			SHAPE_STAR:
				draw_colored_polygon(_star(centre, radius, radius * 0.44), tint)
			SHAPE_HEXAGON:
				draw_colored_polygon(_polygon(6, centre, radius, angle), tint)

	func _polygon(sides: int, centre: Vector2, radius: float, start_deg: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in sides:
			var a := deg_to_rad(start_deg + 360.0 * float(i) / float(sides))
			points.append(centre + Vector2(cos(a), sin(a)) * radius)
		return points

	func _star(centre: Vector2, outer: float, inner: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in 10:
			var radius := outer if i % 2 == 0 else inner
			var a := deg_to_rad(-90.0 + 36.0 * float(i) + angle)
			points.append(centre + Vector2(cos(a), sin(a)) * radius)
		return points

@onready var sequence_row: HBoxContainer = $margin/column/sequence_row
@onready var options_row: HBoxContainer = $margin/column/options_row
@onready var timer_label: Label = $margin/column/hud/timer_label
@onready var progress_label: Label = $margin/column/hud/progress_label
@onready var score_label: Label = $margin/column/hud/score_label
@onready var feedback_label: Label = $margin/column/feedback_label
@onready var back_button: Button = $margin/column/footer/back_button
@onready var replay_button: Button = $margin/column/footer/replay_button
@onready var game_over: PanelContainer = $game_over
@onready var score_line: Label = $game_over/game_over_layout/game_over_stats/score_line
@onready var detail_line: Label = $game_over/game_over_layout/game_over_stats/detail_line
@onready var continue_button: Button = $game_over/game_over_layout/game_over_buttons/continue_button
@onready var restart_button: Button = $game_over/game_over_layout/game_over_buttons/restart_button
@onready var close_button: Button = $game_over/game_over_layout/game_over_buttons/close_button

# The harness reads this to answer correctly without re-deriving the rule.
var correct_option_index := -1

var _puzzle: Dictionary = {}
var _round := 0
var _score := 0.0
var _correct := 0
var _incorrect := 0
var _elapsed := 0.0
var _total_answer_time := 0.0
var _active := false
var _awaiting := false
var _puzzle_started := 0

func _ready() -> void:
	back_button.pressed.connect(_on_skip_pressed)
	replay_button.pressed.connect(_start_round)
	continue_button.pressed.connect(_on_finish_pressed)
	close_button.pressed.connect(_on_finish_pressed)
	restart_button.pressed.connect(_start_round)
	_start_round()

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	timer_label.text = "TIME %.1f" % maxf(0.0, TIME_LIMIT - _elapsed)
	if _elapsed >= TIME_LIMIT:
		_end_game()

func _start_round() -> void:
	_round = 0
	_score = 0.0
	_correct = 0
	_incorrect = 0
	_elapsed = 0.0
	_total_answer_time = 0.0
	_active = true
	_awaiting = false
	game_over.visible = false
	timer_label.text = "TIME %.1f" % TIME_LIMIT
	_present_puzzle()

func _present_puzzle() -> void:
	if _round >= ROUND_COUNT:
		_end_game()
		return
	_puzzle = _make_puzzle()
	correct_option_index = int(_puzzle["correct_index"])
	_awaiting = true
	_build_sequence(_puzzle["sequence"])
	_build_options(_puzzle["options"])
	feedback_label.text = ""
	feedback_label.add_theme_color_override("font_color", COLOR_DIM)
	progress_label.text = "ROUND %d / %d" % [_round + 1, ROUND_COUNT]
	score_label.text = "SCORE %d" % int(_score)
	_puzzle_started = Time.get_ticks_msec()

func _on_tile_chosen(index: int) -> void:
	if not _active or not _awaiting:
		return
	_awaiting = false
	var ok := index == correct_option_index
	_total_answer_time += float(Time.get_ticks_msec() - _puzzle_started) / 1000.0
	if ok:
		_correct += 1
		_score += CORRECT_POINTS
		feedback_label.text = "CORRECT"
		feedback_label.add_theme_color_override("font_color", COLOR_CORRECT)
	else:
		_incorrect += 1
		_score -= WRONG_PENALTY
		feedback_label.text = "NOT QUITE"
		feedback_label.add_theme_color_override("font_color", COLOR_WRONG)
	score_label.text = "SCORE %d" % int(_score)
	_reveal(index)
	_round += 1
	await get_tree().create_timer(REVEAL_DELAY).timeout
	if _active:
		_present_puzzle()

func _reveal(chosen_index: int) -> void:
	for child in options_row.get_children():
		var tile := child as ShapeTile
		if tile == null:
			continue
		if tile.option_index == correct_option_index:
			tile.ring = COLOR_CORRECT
		elif tile.option_index == chosen_index:
			tile.ring = COLOR_WRONG
		tile.clickable = false
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.queue_redraw()

func _end_game() -> void:
	if not _active:
		return
	_active = false
	_awaiting = false
	var answered := _correct + _incorrect
	var average := 0.0
	if answered > 0:
		average = _total_answer_time / float(answered)

	var scores: Dictionary = GLOBAL.minigame_scores
	scores["predict_correct"] = _correct
	scores["predict_incorrect"] = _incorrect
	scores["predict_avg_time"] = average
	scores["predict_score"] = _score

	score_line.text = "SCORE %d" % int(_score)
	detail_line.text = "CORRECT %d  |  WRONG %d  |  AVG %.1fs" % [_correct, _incorrect, average]
	game_over.visible = true

func _on_skip_pressed() -> void:
	game_finished.emit()

func _on_finish_pressed() -> void:
	if game_over.visible:
		game_finished.emit()

# ------------------------------------------------------------------ rendering
func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _build_sequence(sequence: Array) -> void:
	_clear(sequence_row)
	for i in SEQUENCE_SHOWN:
		if i >= sequence.size():
			break
		sequence_row.add_child(_make_tile(sequence[i], false, -1, TILE_SIZE))
	# the hidden element the player has to predict
	var unknown_tile := ShapeTile.new()
	unknown_tile.unknown = true
	unknown_tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	sequence_row.add_child(unknown_tile)

func _build_options(options: Array) -> void:
	_clear(options_row)
	for i in options.size():
		options_row.add_child(_make_tile(options[i], true, i, OPTION_SIZE))

func _make_tile(spec: Dictionary, clickable: bool, index: int, tile_size: float) -> ShapeTile:
	var tile := ShapeTile.new()
	tile.shape_id = int(spec["shape"])
	tile.tint = spec["tint"]
	tile.angle = float(spec["angle"])
	tile.clickable = clickable
	tile.option_index = index
	tile.custom_minimum_size = Vector2(tile_size, tile_size)
	# the sequence row absorbs the spare height, and a stretching HBox child would turn
	# every tile into a tall rectangle with a tiny shape floating in the middle
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if clickable:
		tile.chosen.connect(_on_tile_chosen)
	return tile

# ------------------------------------------------------------ puzzle authoring
func _make_puzzle() -> Dictionary:
	var spec: Dictionary
	match randi() % 5:
		0:
			spec = _puzzle_cycle(2)
		1:
			spec = _puzzle_cycle(3)
		2:
			spec = _puzzle_doubled()
		3:
			spec = _puzzle_rotation()
		_:
			spec = _puzzle_palette()
	spec["correct_index"] = _finalise_options(spec)
	return spec

func _base_spec(shape: int, tint: Color, angle: float) -> Dictionary:
	return {"shape": shape, "tint": tint, "angle": angle}

## Shapes laid out on a repeating cycle of `period` distinct shapes.
func _puzzle_cycle(period: int) -> Dictionary:
	var vocabulary := ShapeTile.VOCABULARY.duplicate()
	vocabulary.shuffle()
	var picked := vocabulary.slice(0, period)
	var sequence: Array = []
	for i in SEQUENCE_SHOWN + 1:
		var shape: int = int(picked[i % period])
		sequence.append(_base_spec(shape, SHAPE_COLORS[shape], 0.0))
	var answer: Dictionary = sequence[SEQUENCE_SHOWN]
	var wrong_shapes: Array = []
	for shape in picked:
		if int(shape) != int(answer["shape"]) and not wrong_shapes.has(int(shape)):
			wrong_shapes.append(int(shape))
	for shape in vocabulary:
		if int(shape) != int(answer["shape"]) and not wrong_shapes.has(int(shape)):
			wrong_shapes.append(int(shape))
	var options: Array = [answer]
	for shape in wrong_shapes.slice(0, 3):
		options.append(_base_spec(int(shape), SHAPE_COLORS[int(shape)], 0.0))
	return {"sequence": sequence, "answer": answer, "options": options, "rule": "cycle%d" % period}

## Two of one shape then two of another: A A B B A A ...
func _puzzle_doubled() -> Dictionary:
	var vocabulary := ShapeTile.VOCABULARY.duplicate()
	vocabulary.shuffle()
	var first := int(vocabulary[0])
	var second := int(vocabulary[1])
	var sequence: Array = []
	for i in SEQUENCE_SHOWN + 1:
		var shape := first if i % 4 < 2 else second
		sequence.append(_base_spec(shape, SHAPE_COLORS[shape], 0.0))
	var answer: Dictionary = sequence[SEQUENCE_SHOWN]
	# Collect genuinely distinct wrong shapes: the two shapes used by the rule can be
	# only one apart from the answer, which would leave a three-tile row.
	var options: Array = [answer]
	for shape in vocabulary:
		if options.size() >= 4:
			break
		if int(shape) == int(answer["shape"]):
			continue
		var already := false
		for option in options:
			if int(option["shape"]) == int(shape):
				already = true
		if not already:
			options.append(_base_spec(int(shape), SHAPE_COLORS[int(shape)], 0.0))
	return {"sequence": sequence, "answer": answer, "options": options, "rule": "doubled"}

## One triangle turning a quarter turn each step.
func _puzzle_rotation() -> Dictionary:
	var shape := ShapeTile.SHAPE_TRIANGLE
	var tint: Color = SHAPE_COLORS[2]
	var sequence: Array = []
	for i in SEQUENCE_SHOWN + 1:
		sequence.append(_base_spec(shape, tint, fmod(float(i) * 90.0, 360.0)))
	var answer: Dictionary = sequence[SEQUENCE_SHOWN]
	var options: Array = [answer]
	for angle in [0.0, 180.0, 270.0]:
		if absf(angle - float(answer["angle"])) > 1.0:
			options.append(_base_spec(shape, tint, angle))
	return {"sequence": sequence, "answer": answer, "options": options, "rule": "rotation"}

## Same shape, colour cycling in a repeating period.
func _puzzle_palette() -> Dictionary:
	var period := 2 if randi() % 2 == 0 else 3
	var shape := ShapeTile.SHAPE_SQUARE if randi() % 2 == 0 else ShapeTile.SHAPE_CIRCLE
	var palette_indices: Array = []
	var pool := range(SHAPE_COLORS.size())
	pool.shuffle()
	palette_indices = pool.slice(0, period)
	var sequence: Array = []
	for i in SEQUENCE_SHOWN + 1:
		sequence.append(_base_spec(shape, SHAPE_COLORS[int(palette_indices[i % period])], 0.0))
	var answer: Dictionary = sequence[SEQUENCE_SHOWN]
	var options: Array = [answer]
	for index in pool:
		if options.size() >= 4:
			break
		var tint: Color = SHAPE_COLORS[int(index)]
		if tint != answer["tint"]:
			options.append(_base_spec(shape, tint, 0.0))
	return {"sequence": sequence, "answer": answer, "options": options, "rule": "palette%d" % period}

## Reduces the candidates to four distinct tiles, puts the correct one somewhere in
## the row, and reports which slot it landed in. Every rule offers at least three
## distinct wrong answers (6 shapes, 6 colours, 4 orientations), so a full row of
## four is always reachable.
func _finalise_options(spec: Dictionary) -> int:
	var answer: Dictionary = spec["answer"]
	var answer_key := _option_key(answer)
	var seen := {answer_key: true}
	var others: Array = []
	for option in spec["options"]:
		var key := _option_key(option)
		if seen.has(key):
			continue
		seen[key] = true
		others.append(option)
	var options: Array = others.slice(0, 3)
	options.append(answer)
	options.shuffle()
	spec["options"] = options
	for i in options.size():
		if _option_key(options[i]) == answer_key:
			return i
	return options.size() - 1

func _option_key(option: Dictionary) -> String:
	return "%d|%.0f|%s" % [int(option["shape"]), float(option["angle"]), (option["tint"] as Color).to_html(false)]
