extends Node

var player_name: String = "The Ascendant"
var player_max_hp: int = 50
var player_current_hp: int = 50

var master_deck: Array[String] = []
var card_definitions: Dictionary = {}

func _ready() -> void:
	_load_all_card_definitions()
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
	for i: int in range(5):
		master_deck.append("strike")
	for i: int in range(4):
		master_deck.append("defend")
	master_deck.append("slash")
	master_deck.append("refocus")
	master_deck.append("brace")
