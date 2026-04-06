class_name DeckManager
extends RefCounted

signal hand_changed(hand: Array)
signal draw_pile_count_changed(count: int)
signal discard_pile_count_changed(count: int)

const HAND_SIZE: int = 5
const MAX_HAND_SIZE: int = 10

var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

func initialize(deck: Array[String]) -> void:
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()

func draw_cards(count: int = HAND_SIZE) -> void:
	for i: int in range(count):
		if hand.size() >= MAX_HAND_SIZE:
			break
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			_shuffle_discard_into_draw()
		if not draw_pile.is_empty():
			hand.append(draw_pile.pop_back())
	hand_changed.emit(hand)
	draw_pile_count_changed.emit(draw_pile.size())

func play_card(card_id: String) -> void:
	var idx: int = hand.find(card_id)
	if idx == -1:
		return
	hand.remove_at(idx)
	discard_pile.append(card_id)
	hand_changed.emit(hand)
	discard_pile_count_changed.emit(discard_pile.size())

func discard_random_from_hand() -> void:
	if hand.is_empty():
		return
	var idx: int = randi() % hand.size()
	var card_id: String = hand[idx]
	hand.remove_at(idx)
	discard_pile.append(card_id)
	hand_changed.emit(hand)
	discard_pile_count_changed.emit(discard_pile.size())

func discard_hand() -> void:
	for card_id: String in hand:
		discard_pile.append(card_id)
	hand.clear()
	hand_changed.emit(hand)
	discard_pile_count_changed.emit(discard_pile.size())

func _shuffle_discard_into_draw() -> void:
	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()
	draw_pile_count_changed.emit(draw_pile.size())
	discard_pile_count_changed.emit(0)
