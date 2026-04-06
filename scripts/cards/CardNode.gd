class_name CardNode
extends Control

signal drag_started(card_node: CardNode)

var card_id: String = ""

@onready var name_label: Label = $NameLabel
@onready var desc_label: Label = $DescLabel
@onready var cost_label: Label = $CostOrb/CostLabel
@onready var card_art: TextureRect = $CardArt
@onready var type_label: Label = $TypeLabel

var _mouse_held: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_emitted: bool = false
const DRAG_THRESHOLD: float = 8.0

func setup(p_card_id: String, card_data: Dictionary) -> void:
	card_id = p_card_id
	name_label.text = card_data.get("name", p_card_id) as String
	desc_label.text = card_data.get("description", "") as String
	cost_label.text = str(card_data.get("cost", 1) as int)
	type_label.text = card_data.get("type", "Attack") as String
	var image_path: String = card_data.get("image_path", "") as String
	if image_path != "" and ResourceLoader.exists(image_path):
		card_art.texture = load(image_path) as Texture2D

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_held = true
				_drag_emitted = false
				_drag_start_pos = get_global_mouse_position()
			else:
				_mouse_held = false
				_drag_emitted = false

	elif event is InputEventMouseMotion and _mouse_held and not _drag_emitted:
		var delta: Vector2 = get_global_mouse_position() - _drag_start_pos
		if delta.length() > DRAG_THRESHOLD:
			_drag_emitted = true
			_mouse_held = false
			drag_started.emit(self)

	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_mouse_held = true
			_drag_emitted = false
			_drag_start_pos = st.position
		else:
			_mouse_held = false
			_drag_emitted = false

	elif event is InputEventScreenDrag and _mouse_held and not _drag_emitted:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		var delta: Vector2 = sd.position - _drag_start_pos
		if delta.length() > DRAG_THRESHOLD:
			_drag_emitted = true
			_mouse_held = false
			drag_started.emit(self)
