extends Node3D

## Sortie de la crypte → retour près de l'entrée des ruines.

const OUTSIDE_SPAWN := Vector3(132.3, 0.2, -96.0)
const INTERACT_DIST := 4.0

var _player_near := false
var _story_ui: CanvasLayer


func _ready() -> void:
	add_to_group("crypt_exit")
	add_to_group("interactable")
	call_deferred("_find_ui")


func _find_ui() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	var near_now := dist <= INTERACT_DIST
	if near_now and not _player_near:
		_player_near = true
		_show_prompt()
	elif not near_now and _player_near:
		_player_near = false
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(false)


func _input(event: InputEvent) -> void:
	if not _player_near or not Story.can_control_player():
		return
	if event.is_action_pressed("interact"):
		_leave()
		get_viewport().set_input_as_handled()


func _show_prompt() -> void:
	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(true, "Sortir de la crypte [E]")


func _leave() -> void:
	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)

	var player := get_tree().get_first_node_in_group("player") as Node3D
	var narek := get_tree().get_first_node_in_group("narek") as Node3D
	if player:
		player.global_position = OUTSIDE_SPAWN
		player.velocity = Vector3.ZERO
		player.rotation.y = 0.0
	if narek and Story.narek_joined:
		narek.global_position = OUTSIDE_SPAWN + Vector3(-1.5, 0, 1.0)

	if Story.crystal_found and Story.stage == "crystal_done":
		Story.set_quest("Retourner à Boisclair parler à Alden")
