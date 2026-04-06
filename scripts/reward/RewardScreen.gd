extends Control

const CARD_SCENE = preload("res://scenes/combat/CardNode.tscn")
const REWARD_CHOICES: int = 3

@onready var title_label: Label = $VBox/TitleLabel
@onready var card_container: HBoxContainer = $VBox/CardContainer
@onready var skip_button: Button = $VBox/SkipButton

var offered_cards: Array[String] = []

func _ready() -> void:
	skip_button.pressed.connect(_on_skip)
	_generate_reward_choices()

func _generate_reward_choices() -> void:
	var pool: Array[String] = GameData.get_reward_pool()
	if pool.is_empty():
		_return_to_menu()
		return

	# Shuffle the pool using the COMBAT_REWARDS stream and pick up to 3
	SeededRandom.shuffle_array(SeededRandom.Stream.COMBAT_REWARDS, pool)
	var count: int = mini(REWARD_CHOICES, pool.size())
	offered_cards.clear()
	for i: int in range(count):
		offered_cards.append(pool[i])

	_display_cards()

func _display_cards() -> void:
	for child: Node in card_container.get_children():
		child.queue_free()

	for card_id: String in offered_cards:
		var card_data: Dictionary = GameData.card_definitions.get(card_id, {}) as Dictionary
		var card_node: CardNode = CARD_SCENE.instantiate() as CardNode
		card_container.add_child(card_node)
		card_node.setup(card_id, card_data)
		# Connect click to selection — we use the drag_started signal as a click proxy,
		# but also add a direct gui_input handler for simple clicks.
		card_node.gui_input.connect(_on_card_clicked.bind(card_id))

func _on_card_clicked(event: InputEvent, card_id: String) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_pick_card(card_id)
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_pick_card(card_id)

func _pick_card(card_id: String) -> void:
	GameData.master_deck.append(card_id)
	_return_to_menu()

func _on_skip() -> void:
	_return_to_menu()

func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
