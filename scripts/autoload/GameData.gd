extends Node

var player_name: String = "The Ascendant"
var player_max_hp: int = 50
var player_current_hp: int = 50

var selected_character: String = "the_ascendant"
var master_deck: Array[String] = []
var card_definitions: Dictionary = {}

func _ready() -> void:
	_load_all_card_definitions()
	_initialize_starter_deck()

func reset_for_new_run() -> void:
	match selected_character:
		"the_ascendant":
			player_name = "The Ascendant"
			player_max_hp = 50
			player_current_hp = 50
	_initialize_starter_deck()

func _load_all_card_definitions() -> void:
	var card_dir: String = "res://cards/the_ascendant/"
	var dir: DirAccess = DirAccess.open(card_dir)
	if dir == null:
		push_error("Cannot open card directory: " + card_dir)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var card_id: String = file_name.get_basename()
			var full_path: String = card_dir + file_name
			var file: FileAccess = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var json_text: String = file.get_as_text()
				file.close()
				var parsed: Variant = JSON.parse_string(json_text)
				if parsed != null:
					card_definitions[card_id] = parsed
		file_name = dir.get_next()
	dir.list_dir_end()

func _initialize_starter_deck() -> void:
	master_deck.clear()
	match selected_character:
		"the_ascendant":
			for i: int in range(5):
				master_deck.append("strike")
			for i: int in range(4):
				master_deck.append("defend")

## Returns all non-basic cards for the selected character (for reward pools).
func get_reward_pool() -> Array[String]:
	var pool: Array[String] = []
	for card_id: String in card_definitions:
		var data: Dictionary = card_definitions[card_id] as Dictionary
		if data.get("rarity", "Basic") != "Basic":
			pool.append(card_id)
	return pool
