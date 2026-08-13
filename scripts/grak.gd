extends Node3D

## Grak, chef gobelin du camp : premier boss simple.

@export var npc_name := "Grak"
@export var max_hp := 6

@onready var anim: AnimationPlayer = $Model/Barbarian/AnimationPlayer
@onready var interact_area: Area3D = $InteractArea

var hp := 6
var _player_near := false
var _in_fight := false
var _dead := false
var _story_ui: CanvasLayer
var _attack_cooldown := 0.0
var _player: Node3D


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("grak")
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_play_anim("Idle")
	call_deferred("_find_refs")


func _find_refs() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")
	_player = get_tree().get_first_node_in_group("player")


func _unhandled_input(event: InputEvent) -> void:
	if _dead or not _player_near or not Story.can_control_player():
		return
	if event.is_action_pressed("interact") and not _in_fight:
		_talk()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _dead or not _in_fight or not Story.can_control_player():
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _player == null:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist < 2.2 and _attack_cooldown <= 0.0:
		if _player.has_method("take_damage"):
			_player.take_damage(1)
		_attack_cooldown = 1.4
		_play_anim("1H_Melee_Attack_Chop")


func take_damage(amount: int) -> void:
	if _dead:
		return
	if not _in_fight:
		_in_fight = true
	hp -= amount
	if hp <= 0:
		_die()


func _talk() -> void:
	if _story_ui == null:
		return
	if _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)
	_story_ui.start_dialogue(
		npc_name,
		PackedStringArray([
			"Grak écrase les petits humains !",
			"La clé… est à MOI ! Vous ne l'aurez pas !",
			"(Combat ! Approche-toi et appuie sur F)",
		]),
		func () -> void:
			_in_fight = true
	)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not _dead:
		_player_near = true
		if not _in_fight and _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(true, "Défier %s [E]" % npc_name)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(false)


func _die() -> void:
	_dead = true
	_in_fight = false
	_play_anim("Death_A")
	# Donne la clé tout de suite (même si le dialogue est coupé)
	Story.give_key()
	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)
	await get_tree().create_timer(0.8).timeout
	var ui := get_tree().get_first_node_in_group("story_ui")
	if ui and ui.has_method("start_dialogue"):
		var speaker := "Narek" if Story.narek_joined else "Héros"
		ui.start_dialogue(
			speaker,
			PackedStringArray([
				"Grak est vaincu…",
				"Sur lui : une étrange clé ancienne.",
				"Des ruines au pied de la colline, un peu plus au nord, semblent faites pour cette clé.",
				"Va vers le sud du camp — porte de pierre — et appuie sur E.",
			])
		)
	queue_free()


func _play_anim(anim_name: String) -> void:
	if anim == null:
		return
	if anim.has_animation(anim_name):
		anim.play(anim_name)
