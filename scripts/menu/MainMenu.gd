extends Control

const CHARACTERS: Array[Dictionary] = [
	{
		"id": "the_ascendant",
		"name": "The Ascendant",
		"description": "A warrior who channels inner strength.\nStarter deck: 5 Strike, 4 Defend.",
		"image_path": "res://assets/images/characters/the_ascendant.svg",
	},
]

var selected_index: int = 0

@onready var char_name_label: Label = $CenterPanel/VBox/CharName
@onready var char_desc_label: Label = $CenterPanel/VBox/CharDesc
@onready var char_sprite: TextureRect = $CenterPanel/VBox/CharSprite
@onready var prev_button: Button = $CenterPanel/VBox/NavRow/PrevButton
@onready var next_button: Button = $CenterPanel/VBox/NavRow/NextButton
@onready var start_button: Button = $CenterPanel/VBox/StartButton
@onready var seed_input: LineEdit = $CenterPanel/VBox/SeedRow/SeedInput

func _ready() -> void:
	prev_button.pressed.connect(_on_prev)
	next_button.pressed.connect(_on_next)
	start_button.pressed.connect(_on_start)
	_update_display()

func _on_prev() -> void:
	selected_index = (selected_index - 1 + CHARACTERS.size()) % CHARACTERS.size()
	_update_display()

func _on_next() -> void:
	selected_index = (selected_index + 1) % CHARACTERS.size()
	_update_display()

func _update_display() -> void:
	var data: Dictionary = CHARACTERS[selected_index]
	char_name_label.text = data["name"]
	char_desc_label.text = data["description"]
	var img_path: String = data.get("image_path", "") as String
	if img_path != "" and ResourceLoader.exists(img_path):
		char_sprite.texture = load(img_path) as Texture2D
	prev_button.visible = CHARACTERS.size() > 1
	next_button.visible = CHARACTERS.size() > 1

func _on_start() -> void:
	var character: Dictionary = CHARACTERS[selected_index]

	# Parse seed
	var seed_text: String = seed_input.text.strip_edges()
	if seed_text == "":
		SeededRandom.new_run(-1)
	else:
		SeededRandom.new_run(seed_text.hash())

	GameData.selected_character = character["id"]
	GameData.reset_for_new_run()
	get_tree().change_scene_to_file("res://scenes/combat/CombatScene.tscn")
