class_name EnemyCombat
extends Control

signal enemy_died
signal damage_dealt(amount: int)

const ENEMY_NAME: String = "Cultist"
const MAX_HP: int = 20
const ATTACK_DAMAGE: int = 10

var attack_damage: int = ATTACK_DAMAGE
var current_hp: int = MAX_HP

@onready var hp_label: Label = $HPContainer/EnemyHPLabel
@onready var hp_bar: ProgressBar = $HPContainer/EnemyHPBar
@onready var intent_label: Label = $IntentPanel/IntentLabel
@onready var name_label: Label = $EnemyNameLabel
@onready var enemy_sprite: TextureRect = $EnemySprite

func _ready() -> void:
	current_hp = MAX_HP
	name_label.text = ENEMY_NAME
	intent_label.text = "Attacks for %d" % ATTACK_DAMAGE
	_update_hp_display()

func take_damage(amount: int) -> void:
	current_hp -= amount
	current_hp = max(0, current_hp)
	_update_hp_display()
	if current_hp <= 0:
		enemy_died.emit()

func perform_attack() -> void:
	damage_dealt.emit(ATTACK_DAMAGE)

func set_drop_highlight(active: bool) -> void:
	if active:
		modulate = Color(1.3, 0.8, 0.8)
	else:
		modulate = Color(1.0, 1.0, 1.0)

func _update_hp_display() -> void:
	hp_label.text = "%d / %d" % [current_hp, MAX_HP]
	hp_bar.value = float(current_hp) / float(MAX_HP) * 100.0
