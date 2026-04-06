extends Node

const CARD_SCENE = preload("res://scenes/combat/CardNode.tscn")
const MAX_ENERGY: int = 3

# --- Node references ---
@onready var player_hp_label: Label = $BattlefieldLayer/PlayerArea/PlayerHPLabel
@onready var player_hp_bar: ProgressBar = $BattlefieldLayer/PlayerArea/PlayerHPBar
@onready var player_block_label: Label = $BattlefieldLayer/PlayerArea/PlayerBlockLabel
@onready var player_sprite: TextureRect = $BattlefieldLayer/PlayerArea/PlayerSprite
@onready var energy_value_label: Label = $BattlefieldLayer/EnergyPanel/EnergyValueLabel
@onready var turn_label: Label = $BattlefieldLayer/TurnLabel
@onready var end_turn_button: Button = $BattlefieldLayer/EndTurnButton
@onready var draw_pile_button: Button = $BattlefieldLayer/DrawPileButton
@onready var discard_pile_button: Button = $BattlefieldLayer/DiscardPileButton
@onready var hand_container: HBoxContainer = $HandLayer/HandContainer
@onready var drag_layer: CanvasLayer = $DragLayer
@onready var enemy_node: EnemyCombat = $BattlefieldLayer/EnemyArea

# --- Combat state ---
var current_energy: int = MAX_ENERGY
var player_hp: int = 50
var player_max_hp: int = 50
var player_block: int = 0
var pending_block: int = 0
var is_player_turn: bool = false
var combat_over: bool = false

var deck_manager: DeckManager

# --- Drag state ---
var _dragging: CardNode = null
var _drag_placeholder: Control = null
var _drag_hand_index: int = -1

func _ready() -> void:
	deck_manager = DeckManager.new()
	deck_manager.hand_changed.connect(_on_hand_changed)
	deck_manager.draw_pile_count_changed.connect(_update_draw_label)
	deck_manager.discard_pile_count_changed.connect(_update_discard_label)

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	enemy_node.enemy_died.connect(_on_enemy_died)

	player_hp = GameData.player_current_hp
	player_max_hp = GameData.player_max_hp

	var ascendant_tex: Texture2D = load("res://assets/images/characters/the_ascendant.svg") as Texture2D
	if ascendant_tex:
		player_sprite.texture = ascendant_tex

	deck_manager.initialize(GameData.master_deck)
	_start_player_turn()

func _start_player_turn() -> void:
	if combat_over:
		return
	is_player_turn = true
	current_energy = MAX_ENERGY
	player_block = pending_block
	pending_block = 0
	end_turn_button.disabled = false
	turn_label.text = "Your Turn"
	_update_energy_display()
	_update_player_display()
	deck_manager.draw_cards(DeckManager.HAND_SIZE)

func _on_end_turn_pressed() -> void:
	if not is_player_turn or combat_over:
		return
	is_player_turn = false
	end_turn_button.disabled = true
	turn_label.text = "Enemy Turn"
	deck_manager.discard_hand()
	get_tree().create_timer(0.6).timeout.connect(_execute_enemy_turn)

func _execute_enemy_turn() -> void:
	if combat_over:
		return
	enemy_node.perform_attack()
	var damage: int = enemy_node.attack_damage
	var damage_after_block: int = max(0, damage - player_block)
	player_block = max(0, player_block - damage)
	player_hp -= damage_after_block
	player_hp = max(0, player_hp)
	_update_player_display()
	if player_hp <= 0:
		_on_player_defeated()
		return
	get_tree().create_timer(0.8).timeout.connect(_start_player_turn)

func try_play_card(card_node: CardNode) -> bool:
	var card_def: Dictionary = GameData.card_definitions.get(card_node.card_id, {}) as Dictionary
	var cost: int = card_def.get("cost", 1) as int
	if current_energy < cost:
		return false
	current_energy -= cost
	_update_energy_display()

	deck_manager.play_card(card_node.card_id)

	var damage: int = card_def.get("damage", 0) as int
	var block: int = card_def.get("block", 0) as int
	var block_next: int = card_def.get("block_next_turn", 0) as int
	var discard_count: int = card_def.get("discard_random", 0) as int
	var draw_count: int = card_def.get("draw", 0) as int

	if damage > 0:
		enemy_node.take_damage(damage)
	if block > 0:
		player_block += block
		_update_player_display()
	if block_next > 0:
		pending_block += block_next
	for i: int in range(discard_count):
		deck_manager.discard_random_from_hand()
	if draw_count > 0:
		deck_manager.draw_cards(draw_count)

	return true

# --- Drag and Drop ---

func _on_card_drag_started(card_node: CardNode) -> void:
	if not is_player_turn or combat_over:
		return
	_dragging = card_node
	_drag_hand_index = card_node.get_index()

	_drag_placeholder = Control.new()
	_drag_placeholder.custom_minimum_size = card_node.custom_minimum_size
	hand_container.add_child(_drag_placeholder)
	hand_container.move_child(_drag_placeholder, _drag_hand_index)

	hand_container.remove_child(card_node)
	drag_layer.add_child(card_node)
	card_node.position = get_viewport().get_mouse_position() - Vector2(55, 80)

func _input(event: InputEvent) -> void:
	if _dragging == null:
		return

	var mouse_pos: Vector2 = Vector2.ZERO
	if event is InputEventMouseMotion:
		mouse_pos = (event as InputEventMouseMotion).global_position
		_dragging.position = mouse_pos - Vector2(55, 80)
		enemy_node.set_drop_highlight(enemy_node.get_global_rect().has_point(mouse_pos))

	elif event is InputEventScreenDrag:
		mouse_pos = (event as InputEventScreenDrag).position
		_dragging.position = mouse_pos - Vector2(55, 80)
		enemy_node.set_drop_highlight(enemy_node.get_global_rect().has_point(mouse_pos))

	elif (event is InputEventMouseButton and
			(event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and
			not (event as InputEventMouseButton).pressed):
		_handle_drop(get_viewport().get_mouse_position())

	elif (event is InputEventScreenTouch and
			not (event as InputEventScreenTouch).pressed):
		_handle_drop((event as InputEventScreenTouch).position)

func _handle_drop(drop_pos: Vector2) -> void:
	var card_node: CardNode = _dragging
	_dragging = null
	enemy_node.set_drop_highlight(false)

	var enemy_rect: Rect2 = enemy_node.get_global_rect()
	if enemy_rect.has_point(drop_pos) and try_play_card(card_node):
		if _drag_placeholder:
			_drag_placeholder.queue_free()
			_drag_placeholder = null
		card_node.queue_free()
	else:
		drag_layer.remove_child(card_node)
		if _drag_placeholder:
			var slot_idx: int = _drag_placeholder.get_index()
			_drag_placeholder.queue_free()
			_drag_placeholder = null
			hand_container.add_child(card_node)
			hand_container.move_child(card_node, slot_idx)
		else:
			hand_container.add_child(card_node)

# --- Hand rebuilding ---

func _on_hand_changed(hand: Array) -> void:
	for child: Node in hand_container.get_children():
		if child != _drag_placeholder:
			child.queue_free()
	for card_id: String in hand:
		var card_node: CardNode = CARD_SCENE.instantiate() as CardNode
		hand_container.add_child(card_node)
		card_node.setup(card_id, GameData.card_definitions.get(card_id, {}) as Dictionary)
		card_node.drag_started.connect(_on_card_drag_started)

# --- Display updates ---

func _update_energy_display() -> void:
	energy_value_label.text = "%d / %d" % [current_energy, MAX_ENERGY]

func _update_player_display() -> void:
	player_hp_label.text = "HP: %d / %d" % [player_hp, player_max_hp]
	player_hp_bar.value = float(player_hp) / float(player_max_hp) * 100.0
	player_block_label.text = "Block: %d" % player_block

func _update_draw_label(count: int) -> void:
	draw_pile_button.text = "Draw: %d" % count

func _update_discard_label(count: int) -> void:
	discard_pile_button.text = "Discard: %d" % count

# --- End conditions ---

func _on_enemy_died() -> void:
	combat_over = true
	is_player_turn = false
	end_turn_button.disabled = true
	turn_label.text = "Victory!"

func _on_player_defeated() -> void:
	combat_over = true
	is_player_turn = false
	end_turn_button.disabled = true
	turn_label.text = "Defeated!"
